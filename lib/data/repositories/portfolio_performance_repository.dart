import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../features/portfolio/models/performance_milestone.dart';
import '../../features/portfolio/models/performance_timeline_point.dart';
import '../services/supabase/supabase_client_factory.dart';
import '../services/supabase/supabase_dashboard_service.dart';
import '../services/supabase/supabase_insights_service.dart';
import 'dashboard_repository.dart';

const _milestoneInsightType = 'milestone';

final portfolioPerformanceRepositoryProvider =
    Provider<PortfolioPerformanceRepository>((ref) {
      final env = ref.watch(appEnvProvider);
      final client = SupabaseClientFactory.create(env);
      final dashboardService = client == null
          ? null
          : SupabaseDashboardService(client: client);
      final insightsService = client == null
          ? null
          : SupabaseInsightsService(client: client);
      final dashboardRepository = ref.watch(dashboardRepositoryProvider);

      return PortfolioPerformanceRepositoryImpl(
        dashboardService: dashboardService,
        insightsService: insightsService,
        dashboardRepository: dashboardRepository,
      );
    });

abstract interface class PortfolioPerformanceRepository {
  Future<PortfolioPerformanceSnapshot> fetchSnapshot();
}

class PortfolioPerformanceSnapshot {
  const PortfolioPerformanceSnapshot({
    required this.timeline,
    required this.milestones,
    required this.usedFallback,
  });

  final List<PerformanceTimelinePoint> timeline;
  final List<PerformanceMilestone> milestones;
  final bool usedFallback;
}

class PortfolioPerformanceRepositoryImpl
    implements PortfolioPerformanceRepository {
  PortfolioPerformanceRepositoryImpl({
    required DashboardRepository dashboardRepository,
    SupabaseDashboardService? dashboardService,
    SupabaseInsightsService? insightsService,
    DateTime Function()? now,
  }) : _dashboardRepository = dashboardRepository,
       _dashboardService = dashboardService,
       _insightsService = insightsService,
       _now = now ?? DateTime.now;

  final DashboardRepository _dashboardRepository;
  final SupabaseDashboardService? _dashboardService;
  final SupabaseInsightsService? _insightsService;
  final DateTime Function() _now;

  final List<PerformanceMilestone> _localMilestones = <PerformanceMilestone>[];

  @override
  Future<PortfolioPerformanceSnapshot> fetchSnapshot() async {
    final service = _dashboardService;
    final insights = _insightsService;
    final userId = service?.currentUser?.id;

    final fallbackTimeline = await _buildFallbackTimeline();
    if (service == null || insights == null || userId == null) {
      final localMilestones = _applyLocalMilestones(
        latestPoint: fallbackTimeline.isEmpty ? null : fallbackTimeline.last,
      );
      return PortfolioPerformanceSnapshot(
        timeline: fallbackTimeline,
        milestones: localMilestones,
        usedFallback: true,
      );
    }

    try {
      final timeline = await _buildRemoteTimeline(
        service: service,
        userId: userId,
        fallback: fallbackTimeline,
      );
      final milestones = await _syncRemoteMilestones(
        insights: insights,
        userId: userId,
        latestPoint: timeline.isEmpty ? null : timeline.last,
      );

      return PortfolioPerformanceSnapshot(
        timeline: timeline,
        milestones: milestones,
        usedFallback: false,
      );
    } catch (error, stackTrace) {
      developer.log(
        'fetch performance snapshot failed',
        name: 'PortfolioPerformanceRepository',
        error: error,
        stackTrace: stackTrace,
      );
      final localMilestones = _applyLocalMilestones(
        latestPoint: fallbackTimeline.isEmpty ? null : fallbackTimeline.last,
      );
      return PortfolioPerformanceSnapshot(
        timeline: fallbackTimeline,
        milestones: localMilestones,
        usedFallback: true,
      );
    }
  }

  Future<List<PerformanceTimelinePoint>> _buildRemoteTimeline({
    required SupabaseDashboardService service,
    required String userId,
    required List<PerformanceTimelinePoint> fallback,
  }) async {
    final snapshotRows = await service.fetchLatestPortfolioSnapshotsByUserId(
      userId,
      limit: 18,
    );
    final statementRows = await service.fetchLatestCardStatementsByUserId(
      userId,
      limit: 36,
    );

    if (snapshotRows.isEmpty) {
      return fallback;
    }

    final sortedSnapshots = List<Map<String, dynamic>>.from(snapshotRows)
      ..sort((left, right) {
        final leftDate =
            _parseDateTime(left['snapshot_date']) ?? DateTime(1970);
        final rightDate =
            _parseDateTime(right['snapshot_date']) ?? DateTime(1970);
        return leftDate.compareTo(rightDate);
      });

    final liabilitiesByDate = <DateTime, double>{};
    for (final row in statementRows) {
      final date = _parseDateTime(
        row['statement_period_end'] ?? row['statement_due_date'],
      );
      final balance = _toDouble(row['statement_balance']);
      if (date == null || balance == null || balance < 0) {
        continue;
      }
      liabilitiesByDate[_dateOnly(date)] = balance;
    }

    final timeline = <PerformanceTimelinePoint>[];
    var latestLiabilities = 0.0;
    for (final row in sortedSnapshots) {
      final date = _parseDateTime(row['snapshot_date']);
      final assetsValue = _toDouble(
        row['total_value'] ?? _metadataMap(row)['total_value'],
      );
      if (date == null || assetsValue == null || assetsValue <= 0) {
        continue;
      }

      latestLiabilities = _resolveLiabilitiesForDate(
        date: date,
        liabilitiesByDate: liabilitiesByDate,
        fallback: latestLiabilities,
      );
      timeline.add(
        PerformanceTimelinePoint(
          date: _dateOnly(date),
          assets: assetsValue,
          liabilities: latestLiabilities,
          netWorth: assetsValue - latestLiabilities,
        ),
      );
    }

    if (timeline.isEmpty) {
      return fallback;
    }
    return timeline;
  }

  Future<List<PerformanceTimelinePoint>> _buildFallbackTimeline() async {
    DashboardSnapshot snapshot;
    try {
      snapshot = await _dashboardRepository.fetchSnapshot();
    } catch (_) {
      snapshot = _dashboardRepository.fallbackSnapshot;
    }

    final trend = snapshot.netWorthTrend;
    if (trend.isEmpty) {
      return [
        PerformanceTimelinePoint(
          date: _dateOnly(_now()),
          assets:
              snapshot.netWorth.amount.toDouble() +
              snapshot.statementSummary.amount.toDouble(),
          liabilities: snapshot.statementSummary.amount.toDouble(),
          netWorth: snapshot.netWorth.amount.toDouble(),
        ),
      ];
    }

    final anchor = DateTime(snapshot.month.year, snapshot.month.month, 1);
    final totalPoints = trend.length;
    final baseLiability = snapshot.statementSummary.amount.toDouble();

    final points = <PerformanceTimelinePoint>[];
    for (var index = 0; index < totalPoints; index += 1) {
      final monthOffset = index - (totalPoints - 1);
      final date = _shiftMonth(anchor, monthOffset);
      final netWorth = trend[index].toDouble();
      final ratio = totalPoints <= 1 ? 0.0 : index / (totalPoints - 1);
      final liabilities = baseLiability * (0.8 + ratio * 0.35);
      points.add(
        PerformanceTimelinePoint(
          date: _dateOnly(date),
          assets: netWorth + liabilities,
          liabilities: liabilities,
          netWorth: netWorth,
        ),
      );
    }

    return points;
  }

  List<PerformanceMilestone> _evaluateMilestones(
    PerformanceTimelinePoint latest,
  ) {
    final candidates = <PerformanceMilestone>[];

    if (latest.netWorth >= 1000000) {
      candidates.add(
        PerformanceMilestone(
          code: 'networth_1m',
          title: '淨值達成 NT\$1,000,000',
          description: '達到第一個百萬淨值里程碑，繼續維持紀律投入。',
          achievedAt: latest.date,
          netWorth: latest.netWorth,
        ),
      );
    }
    if (latest.netWorth >= 3000000) {
      candidates.add(
        PerformanceMilestone(
          code: 'networth_3m',
          title: '淨值達成 NT\$3,000,000',
          description: '淨值邁向三百萬，可評估下一階段資產配置目標。',
          achievedAt: latest.date,
          netWorth: latest.netWorth,
        ),
      );
    }

    final liabilityRatio = latest.assets <= 0
        ? 1.0
        : latest.liabilities / latest.assets;
    if (liabilityRatio <= 0.2) {
      candidates.add(
        PerformanceMilestone(
          code: 'liability_under_20pct',
          title: '負債占比低於 20%',
          description: '負債壓力顯著下降，現金流緩衝更健康。',
          achievedAt: latest.date,
          netWorth: latest.netWorth,
        ),
      );
    }

    return candidates;
  }

  List<PerformanceMilestone> _applyLocalMilestones({
    required PerformanceTimelinePoint? latestPoint,
  }) {
    if (latestPoint == null) {
      return List<PerformanceMilestone>.unmodifiable(_localMilestones);
    }
    final existingCodes = _localMilestones.map((item) => item.code).toSet();
    final candidates = _evaluateMilestones(latestPoint);
    for (final candidate in candidates) {
      if (existingCodes.contains(candidate.code)) {
        continue;
      }
      _localMilestones.add(candidate);
      existingCodes.add(candidate.code);
    }

    final sorted = List<PerformanceMilestone>.from(_localMilestones)
      ..sort((left, right) => right.achievedAt.compareTo(left.achievedAt));
    return List<PerformanceMilestone>.unmodifiable(sorted);
  }

  Future<List<PerformanceMilestone>> _syncRemoteMilestones({
    required SupabaseInsightsService insights,
    required String userId,
    required PerformanceTimelinePoint? latestPoint,
  }) async {
    final rows = await insights.fetchMilestoneInsightsByUserId(userId);
    final parsed = _parseMilestones(rows);
    final existingCodes = parsed.map((item) => item.code).toSet();

    if (latestPoint != null) {
      final candidates = _evaluateMilestones(latestPoint);
      for (final candidate in candidates) {
        if (existingCodes.contains(candidate.code)) {
          continue;
        }
        try {
          await insights.insertInsight(
            _buildMilestoneInsertPayload(userId: userId, milestone: candidate),
          );
          parsed.add(candidate);
          existingCodes.add(candidate.code);
        } catch (error, stackTrace) {
          developer.log(
            'insert milestone failed',
            name: 'PortfolioPerformanceRepository',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }

    final sorted = List<PerformanceMilestone>.from(parsed)
      ..sort((left, right) => right.achievedAt.compareTo(left.achievedAt));
    return List<PerformanceMilestone>.unmodifiable(sorted);
  }

  List<PerformanceMilestone> _parseMilestones(List<Map<String, dynamic>> rows) {
    final milestones = <PerformanceMilestone>[];
    final seenCodes = <String>{};
    for (final row in rows) {
      final payload = _payloadMap(row['payload']);
      final code = payload['milestone_code']?.toString().trim();
      if (code == null || code.isEmpty || seenCodes.contains(code)) {
        continue;
      }

      final achievedAt =
          _parseDateTime(row['snapshot_date']) ??
          _parseDateTime(payload['achieved_at']) ??
          _parseDateTime(row['created_at']) ??
          _now();
      final title = row['title']?.toString().trim().isNotEmpty == true
          ? row['title'].toString().trim()
          : _titleForMilestoneCode(code);
      final description = row['summary']?.toString().trim().isNotEmpty == true
          ? row['summary'].toString().trim()
          : _descriptionForMilestoneCode(code);
      final netWorth = _toDouble(payload['net_worth']) ?? 0;

      milestones.add(
        PerformanceMilestone(
          code: code,
          title: title,
          description: description,
          achievedAt: achievedAt,
          netWorth: netWorth,
        ),
      );
      seenCodes.add(code);
    }
    return milestones;
  }

  Map<String, dynamic> _buildMilestoneInsertPayload({
    required String userId,
    required PerformanceMilestone milestone,
  }) {
    return {
      'user_id': userId,
      'snapshot_date': _toIsoDate(milestone.achievedAt),
      'insight_type': _milestoneInsightType,
      'title': milestone.title,
      'summary': milestone.description,
      'severity': 'info',
      'payload': {
        'milestone_code': milestone.code,
        'net_worth': milestone.netWorth,
        'achieved_at': milestone.achievedAt.toUtc().toIso8601String(),
      },
    };
  }

  double _resolveLiabilitiesForDate({
    required DateTime date,
    required Map<DateTime, double> liabilitiesByDate,
    required double fallback,
  }) {
    if (liabilitiesByDate.isEmpty) {
      return fallback;
    }

    final target = _dateOnly(date);
    if (liabilitiesByDate.containsKey(target)) {
      return liabilitiesByDate[target] ?? fallback;
    }

    final keys = liabilitiesByDate.keys.toList()
      ..sort((left, right) => left.compareTo(right));
    double? previous;
    for (final key in keys) {
      if (!key.isAfter(target)) {
        previous = liabilitiesByDate[key];
      }
    }

    if (previous != null) {
      return previous;
    }

    return liabilitiesByDate[keys.first] ?? fallback;
  }

  String _titleForMilestoneCode(String code) {
    return switch (code) {
      'networth_1m' => '淨值達成 NT\$1,000,000',
      'networth_3m' => '淨值達成 NT\$3,000,000',
      'liability_under_20pct' => '負債占比低於 20%',
      _ => '里程碑',
    };
  }

  String _descriptionForMilestoneCode(String code) {
    return switch (code) {
      'networth_1m' => '達到第一個百萬淨值里程碑，繼續維持紀律投入。',
      'networth_3m' => '淨值邁向三百萬，可評估下一階段資產配置目標。',
      'liability_under_20pct' => '負債壓力顯著下降，現金流緩衝更健康。',
      _ => '已達成新的財務里程碑。',
    };
  }

  String _toIsoDate(DateTime value) {
    final date = _dateOnly(value.toUtc());
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime _shiftMonth(DateTime date, int delta) {
    final totalMonths = date.year * 12 + date.month - 1 + delta;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    return DateTime(year, month, 1);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  double? _toDouble(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw.toString());
  }

  DateTime? _parseDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw.toLocal();
    }
    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text)?.toLocal();
  }

  Map<String, dynamic> _metadataMap(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    if (metadata is Map) {
      return Map<String, dynamic>.from(metadata);
    }
    if (metadata is String && metadata.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return const <String, dynamic>{};
      }
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _payloadMap(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return const <String, dynamic>{};
      }
    }
    return const <String, dynamic>{};
  }
}
