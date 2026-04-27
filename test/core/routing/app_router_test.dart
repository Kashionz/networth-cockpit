import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/routing/app_router.dart';
import 'package:networth_cockpit/core/routing/route_paths.dart';

void main() {
  final routeExpectations = <String, String>{
    RoutePaths.authLogin: '登入',
    RoutePaths.authSignup: '註冊',
    RoutePaths.onboardingWelcome: '開始設定',
    RoutePaths.onboardingRiskQuestionnaire: '風險屬性問卷',
    RoutePaths.onboardingTargetAllocation: '目標配置',
    RoutePaths.onboardingBudgetSetup: '預算設定',
    RoutePaths.onboardingFirstAsset: '第一筆資產',
    RoutePaths.assets: '資產總覽',
    RoutePaths.assetsAdd: '新增資產',
    RoutePaths.transactions: '交易紀錄',
    RoutePaths.transactionsManual: '手動記錄大額支出',
    RoutePaths.cards: '信用卡',
    RoutePaths.cardsAdd: '新增信用卡',
    RoutePaths.budgetHistory: '預算歷史',
    RoutePaths.portfolioPerformance: '配置表現',
    RoutePaths.insights: '月度報告',
    RoutePaths.settingsPrivacy: '隱私模式',
    RoutePaths.settingsProfile: '個人資料',
    RoutePaths.settingsExport: '資料匯出',
    RoutePaths.settingsAccount: '帳號設定',
    RoutePaths.settingsNotifications: '提醒與推播',
    RoutePaths.settingsPwaInstall: '安裝 App（PWA）',
    RoutePaths.legalPrivacy: '隱私政策',
    RoutePaths.legalTerms: '使用者條款',
    RoutePaths.legalAiTemplate: 'AI 解讀模板與揭露',
  };

  for (final entry in routeExpectations.entries) {
    testWidgets('opens ${entry.key}', (tester) async {
      final router = createAppRouter(initialLocation: entry.key);

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsAtLeastNWidgets(1));
    });
  }
}
