import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/export/file_export_service.dart';
import 'budget_repository.dart';
import 'portfolio_repository.dart';

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  return ExportRepositoryImpl(
    budgetRepository: ref.watch(budgetRepositoryProvider),
    portfolioRepository: ref.watch(portfolioRepositoryProvider),
    fileService: ref.watch(exportFileServiceProvider),
  );
});

abstract interface class ExportRepository {
  Future<ExportArtifact> exportData({required ExportDataFormat format});

  List<ExportArtifact> getHistory();
}

enum ExportDataFormat { csv, json }

extension ExportDataFormatX on ExportDataFormat {
  String get label => switch (this) {
    ExportDataFormat.csv => 'CSV',
    ExportDataFormat.json => 'JSON',
  };

  String get extension => switch (this) {
    ExportDataFormat.csv => 'csv',
    ExportDataFormat.json => 'json',
  };

  String get mimeType => switch (this) {
    ExportDataFormat.csv => 'text/csv;charset=utf-8',
    ExportDataFormat.json => 'application/json;charset=utf-8',
  };
}

class ExportArtifact {
  const ExportArtifact({
    required this.id,
    required this.format,
    required this.fileName,
    required this.createdAt,
    required this.byteLength,
    required this.outputLocation,
    required this.downloadTriggered,
  });

  final String id;
  final ExportDataFormat format;
  final String fileName;
  final DateTime createdAt;
  final int byteLength;
  final String outputLocation;
  final bool downloadTriggered;
}

class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl({
    required BudgetRepository budgetRepository,
    required PortfolioRepository portfolioRepository,
    required ExportFileService fileService,
    DateTime Function()? now,
  }) : _budgetRepository = budgetRepository,
       _portfolioRepository = portfolioRepository,
       _fileService = fileService,
       _now = now ?? DateTime.now;

  final BudgetRepository _budgetRepository;
  final PortfolioRepository _portfolioRepository;
  final ExportFileService _fileService;
  final DateTime Function() _now;
  final List<ExportArtifact> _history = <ExportArtifact>[];

  @override
  Future<ExportArtifact> exportData({required ExportDataFormat format}) async {
    final createdAt = _now().toUtc();
    final budget = _budgetRepository.getCurrentMonth();
    final allocations = _portfolioRepository.getAllocations();
    final holdings = _portfolioRepository.getTopHoldings(limit: 10);

    final content = switch (format) {
      ExportDataFormat.csv => _buildCsv(
        createdAt: createdAt,
        budget: budget,
        allocations: allocations,
        holdings: holdings,
      ),
      ExportDataFormat.json => _buildJson(
        createdAt: createdAt,
        budget: budget,
        allocations: allocations,
        holdings: holdings,
      ),
    };

    final bytes = Uint8List.fromList(utf8.encode(content));
    final fileName = _buildFileName(format: format, createdAt: createdAt);
    final saveResult = await _fileService.save(
      fileName: fileName,
      mimeType: format.mimeType,
      bytes: bytes,
    );

    final artifact = ExportArtifact(
      id: 'export-${createdAt.microsecondsSinceEpoch}',
      format: format,
      fileName: fileName,
      createdAt: createdAt,
      byteLength: bytes.length,
      outputLocation: saveResult.outputLocation,
      downloadTriggered: saveResult.downloadTriggered,
    );
    _history.insert(0, artifact);
    return artifact;
  }

  @override
  List<ExportArtifact> getHistory() => List<ExportArtifact>.unmodifiable(_history);

  String _buildFileName({
    required ExportDataFormat format,
    required DateTime createdAt,
  }) {
    final timestamp = DateFormat(
      'yyyyMMdd_HHmmss',
    ).format(createdAt.toLocal());
    return 'networth_export_$timestamp.${format.extension}';
  }

  String _buildJson({
    required DateTime createdAt,
    required BudgetMonth budget,
    required List<AssetAllocation> allocations,
    required List<Holding> holdings,
  }) {
    final payload = <String, Object?>{
      'generated_at': createdAt.toIso8601String(),
      'budget': <String, Object?>{
        'month': <String, Object?>{
          'year': budget.month.year,
          'month': budget.month.month,
          'label': budget.month.zhLabel,
        },
        'summary': <String, Object?>{
          'total_budget': budget.totalBudget.amount,
          'total_used': budget.totalUsed.amount,
          'total_remaining': budget.totalRemaining.amount,
          'usage_percent': budget.totalUsagePercent,
        },
        'categories': [
          for (final category in budget.categories)
            <String, Object?>{
              'id': category.id,
              'name': category.name,
              'type': _budgetTypeLabel(category.type),
              'budget_amount': category.budgetAmount.amount,
              'used_amount': category.usedAmount.amount,
              'remaining_amount': category.remainingAmount,
              'rollover': category.rollover,
            },
        ],
        'large_expenses': [
          for (final expense in budget.largeExpenses)
            <String, Object?>{
              'id': expense.id,
              'title': expense.title,
              'category_type': _budgetTypeLabel(expense.categoryType),
              'amount': expense.amount.amount,
              'recorded_at': expense.recordedAt.toIso8601String(),
            },
        ],
      },
      'portfolio': <String, Object?>{
        'allocations': [
          for (final allocation in allocations)
            <String, Object?>{
              'category': allocation.category.label,
              'current_ratio': allocation.currentRatio,
              'target_ratio': allocation.targetRatio,
              'drift_ratio': allocation.driftRatio,
            },
        ],
        'top_holdings': [
          for (final holding in holdings)
            <String, Object?>{
              'name': holding.name,
              'market_value': holding.marketValue.amount,
              'currency': holding.marketValue.currencyCode,
              'weight_ratio': holding.weightRatio,
            },
        ],
      },
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _buildCsv({
    required DateTime createdAt,
    required BudgetMonth budget,
    required List<AssetAllocation> allocations,
    required List<Holding> holdings,
  }) {
    final rows = <List<String>>[
      [
        'record_type',
        'field_1',
        'field_2',
        'field_3',
        'field_4',
        'field_5',
        'field_6',
        'field_7',
      ],
      ['meta', 'generated_at', createdAt.toIso8601String(), '', '', '', '', ''],
      [
        'budget_summary',
        budget.month.zhLabel,
        _numberText(budget.totalBudget.amount),
        _numberText(budget.totalUsed.amount),
        _numberText(budget.totalRemaining.amount),
        '${budget.totalUsagePercent}%',
        '',
        '',
      ],
    ];

    for (final category in budget.categories) {
      rows.add([
        'budget_category',
        category.id,
        category.name,
        _budgetTypeLabel(category.type),
        _numberText(category.budgetAmount.amount),
        _numberText(category.usedAmount.amount),
        _numberText(category.remainingAmount),
        category.rollover ? 'true' : 'false',
      ]);
    }

    for (final expense in budget.largeExpenses) {
      rows.add([
        'large_expense',
        expense.id,
        expense.title,
        _budgetTypeLabel(expense.categoryType),
        _numberText(expense.amount.amount),
        DateFormat('yyyy-MM-dd').format(expense.recordedAt),
        '',
        '',
      ]);
    }

    for (final allocation in allocations) {
      rows.add([
        'allocation',
        allocation.category.label,
        _numberText(allocation.currentRatio),
        _numberText(allocation.targetRatio),
        _numberText(allocation.driftRatio),
        '',
        '',
        '',
      ]);
    }

    for (final holding in holdings) {
      rows.add([
        'holding',
        holding.name,
        _numberText(holding.marketValue.amount),
        holding.marketValue.currencyCode,
        _numberText(holding.weightRatio),
        '',
        '',
        '',
      ]);
    }

    return rows.map(_csvRow).join('\n');
  }

  String _budgetTypeLabel(BudgetCategoryType type) {
    return switch (type) {
      BudgetCategoryType.fixed => '固定',
      BudgetCategoryType.living => '生活',
      BudgetCategoryType.flex => '彈性',
    };
  }

  String _numberText(num value) {
    if (value is int) {
      return value.toString();
    }
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _csvRow(List<String> columns) {
    return columns.map(_escapeCsvCell).join(',');
  }

  String _escapeCsvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
