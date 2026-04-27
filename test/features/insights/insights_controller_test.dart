import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/services/ai/l2_analysis_client.dart';
import 'package:networth_cockpit/features/insights/controllers/insights_controller.dart';

void main() {
  test(
    'insights controller uses deterministic fallback without backend',
    () async {
      final fakeClient = L2AnalysisClient(
        baseUrl: null,
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );
      final container = ProviderContainer(
        overrides: [l2AnalysisClientProvider.overrideWithValue(fakeClient)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(insightsControllerProvider.notifier);
      final initial = container.read(insightsControllerProvider);

      await notifier.refresh(seed: initial.fallbackInsight);

      final state = container.read(insightsControllerProvider);
      expect(state.usedFallback, isTrue);
      expect(state.displayInsight.aiInterpretation, hasLength(3));
      expect(state.statusMessage, contains('FASTAPI_BASE_URL'));
    },
  );
}
