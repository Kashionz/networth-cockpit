import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/income_stream_repository.dart';
import 'package:networth_cockpit/data/services/supabase/supabase_income_service.dart';
import 'package:networth_cockpit/features/income/models/income_stream.dart';

void main() {
  test(
    'fetchIncomeStreams pulls remote data and computes monthly total',
    () async {
      final now = DateTime.now().toUtc();
      final thisMonthDate = DateTime.utc(now.year, now.month, 15);
      final nextMonthDate = DateTime.utc(now.year, now.month + 1, 15);
      final service = _FakeIncomeRemoteService(
        currentUserId: 'user-1',
        fetchRows: [
          _row(
            id: 'monthly',
            name: '薪資',
            amount: 50000,
            frequency: 'monthly',
            nextDate: thisMonthDate,
            active: true,
          ),
          _row(
            id: 'yearly',
            name: '獎金',
            amount: 12000,
            frequency: 'yearly',
            nextDate: thisMonthDate,
            active: true,
          ),
          _row(
            id: 'one-time-this',
            name: '專案獎勵',
            amount: 3000,
            frequency: 'one_time',
            nextDate: thisMonthDate,
            active: true,
          ),
          _row(
            id: 'one-time-next',
            name: '下月專案',
            amount: 3000,
            frequency: 'one_time',
            nextDate: nextMonthDate,
            active: true,
          ),
          _row(
            id: 'inactive',
            name: '停用收入',
            amount: 99999,
            frequency: 'monthly',
            nextDate: thisMonthDate,
            active: false,
          ),
        ],
      );
      final repository = IncomeStreamRepositoryImpl(remoteService: service);

      final streams = await repository.fetchIncomeStreams();

      expect(service.fetchUserIds, ['user-1']);
      expect(streams, hasLength(5));
      expect(repository.totalMonthlyIncome(), closeTo(54000, 0.0001));
    },
  );

  test(
    'upsertIncomeStream writes through remote service and caches result',
    () async {
      final now = DateTime.now().toUtc();
      final service = _FakeIncomeRemoteService(
        currentUserId: 'user-2',
        upsertResponse: _row(
          id: '11111111-2222-4333-a444-555555555555',
          name: '接案',
          amount: 8800,
          frequency: 'monthly',
          nextDate: now,
        ),
      );
      final repository = IncomeStreamRepositoryImpl(remoteService: service);

      final saved = await repository.upsertIncomeStream(
        IncomeStream(
          id: 'temp-id',
          userId: '',
          name: '  接案  ',
          amount: 8800,
          frequency: IncomeFrequency.monthly,
          nextDate: now,
          active: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(service.upsertPayloads, hasLength(1));
      final payload = service.upsertPayloads.single;
      expect(payload.containsKey('id'), isFalse);
      expect(payload['user_id'], 'user-2');
      expect(payload['name'], '接案');
      expect(saved.id, '11111111-2222-4333-a444-555555555555');
      expect(repository.totalMonthlyIncome(), closeTo(8800, 0.0001));
    },
  );

  test(
    'deleteIncomeStream calls remote service and removes local stream',
    () async {
      final now = DateTime.now().toUtc();
      final service = _FakeIncomeRemoteService(currentUserId: 'user-3');
      final repository = IncomeStreamRepositoryImpl(
        remoteService: service,
        seedStreams: [
          IncomeStream(
            id: 'stream-a',
            userId: 'user-3',
            name: '薪資',
            amount: 60000,
            frequency: IncomeFrequency.monthly,
            nextDate: now,
            active: true,
            createdAt: now,
            updatedAt: now,
          ),
          IncomeStream(
            id: 'stream-b',
            userId: 'user-3',
            name: '租金收入',
            amount: 8000,
            frequency: IncomeFrequency.monthly,
            nextDate: now,
            active: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      await repository.deleteIncomeStream('stream-a');

      expect(service.deleteCalls, [
        {'user_id': 'user-3', 'id': 'stream-a'},
      ]);
      expect(repository.totalMonthlyIncome(), closeTo(8000, 0.0001));
    },
  );
}

Map<String, dynamic> _row({
  required String id,
  required String name,
  required num amount,
  required String frequency,
  required DateTime nextDate,
  bool active = true,
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  return {
    'id': id,
    'name': name,
    'amount': amount,
    'frequency': frequency,
    'next_date': nextDate.toIso8601String().substring(0, 10),
    'active': active,
    'created_at': now,
    'updated_at': now,
  };
}

class _FakeIncomeRemoteService implements IncomeStreamRemoteService {
  _FakeIncomeRemoteService({
    this.currentUserId,
    this.fetchRows = const [],
    this.upsertResponse,
  });

  @override
  final String? currentUserId;

  final List<Map<String, dynamic>> fetchRows;
  final Map<String, dynamic>? upsertResponse;
  final List<String> fetchUserIds = [];
  final List<Map<String, dynamic>> upsertPayloads = [];
  final List<Map<String, String>> deleteCalls = [];

  @override
  Future<List<Map<String, dynamic>>> fetchIncomeStreams(String userId) async {
    fetchUserIds.add(userId);
    return List<Map<String, dynamic>>.from(fetchRows);
  }

  @override
  Future<Map<String, dynamic>> upsertIncomeStream(
    Map<String, dynamic> payload,
  ) async {
    upsertPayloads.add(Map<String, dynamic>.from(payload));
    return upsertResponse ?? payload;
  }

  @override
  Future<void> deleteIncomeStream({
    required String userId,
    required String id,
  }) async {
    deleteCalls.add({'user_id': userId, 'id': id});
  }
}
