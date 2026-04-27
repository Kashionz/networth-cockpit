import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:networth_cockpit/core/routing/route_paths.dart';
import 'package:networth_cockpit/features/onboarding/pages/budget_setup_page.dart';
import 'package:networth_cockpit/features/onboarding/pages/first_asset_page.dart';
import 'package:networth_cockpit/features/onboarding/pages/risk_questionnaire_page.dart';
import 'package:networth_cockpit/features/onboarding/pages/target_allocation_page.dart';
import 'package:networth_cockpit/features/onboarding/pages/welcome_page.dart';

void main() {
  GoRouter createOnboardingRouter({required String initialLocation}) {
    Widget shell(Widget child) => Scaffold(body: child);

    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: RoutePaths.dashboard,
          builder: (context, state) =>
              shell(const Center(child: Text('總覽 Dashboard'))),
        ),
        GoRoute(
          path: RoutePaths.onboardingWelcome,
          builder: (context, state) => shell(const WelcomePage()),
        ),
        GoRoute(
          path: RoutePaths.onboardingRiskQuestionnaire,
          builder: (context, state) => shell(const RiskQuestionnairePage()),
        ),
        GoRoute(
          path: RoutePaths.onboardingTargetAllocation,
          builder: (context, state) => shell(const TargetAllocationPage()),
        ),
        GoRoute(
          path: RoutePaths.onboardingBudgetSetup,
          builder: (context, state) => shell(const BudgetSetupPage()),
        ),
        GoRoute(
          path: RoutePaths.onboardingFirstAsset,
          builder: (context, state) => shell(const FirstAssetPage()),
        ),
      ],
    );
  }

  Future<void> pumpOnboardingRouter(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    final router = createOnboardingRouter(initialLocation: initialLocation);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('onboarding flow supports skipping each step to dashboard', (
    tester,
  ) async {
    await pumpOnboardingRouter(
      tester,
      initialLocation: RoutePaths.onboardingWelcome,
    );

    expect(find.text('開始設定'), findsOneWidget);

    await tester.tap(find.text('跳過此步'));
    await tester.pumpAndSettle();
    expect(find.text('風險屬性問卷'), findsOneWidget);

    await tester.tap(find.text('跳過此步'));
    await tester.pumpAndSettle();
    expect(find.text('目標配置'), findsOneWidget);

    await tester.tap(find.text('跳過此步'));
    await tester.pumpAndSettle();
    expect(find.text('預算設定'), findsOneWidget);

    await tester.tap(find.text('跳過此步'));
    await tester.pumpAndSettle();
    expect(find.text('第一筆資產'), findsOneWidget);

    await tester.tap(find.text('跳過此步'));
    await tester.pumpAndSettle();
    expect(find.text('總覽 Dashboard'), findsOneWidget);
  });

  testWidgets('completing onboarding navigates to dashboard route', (
    tester,
  ) async {
    await pumpOnboardingRouter(
      tester,
      initialLocation: RoutePaths.onboardingFirstAsset,
    );

    expect(find.text('第一筆資產'), findsOneWidget);

    await tester.tap(find.text('完成設定'));
    await tester.pumpAndSettle();

    expect(find.text('總覽 Dashboard'), findsOneWidget);
  });
}
