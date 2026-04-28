import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/assets/pages/add_asset_page.dart';
import '../../features/assets/pages/assets_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/signup_page.dart';
import '../../features/budget/pages/budget_page.dart';
import '../../features/budget/pages/budget_history_page.dart';
import '../../features/cards/pages/add_card_page.dart';
import '../../features/cards/pages/cards_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/income/pages/add_income_page.dart';
import '../../features/income/pages/income_page.dart';
import '../../features/insights/pages/insights_page.dart';
import '../../features/legal/pages/ai_disclosure_template_page.dart';
import '../../features/legal/pages/privacy_policy_page.dart';
import '../../features/legal/pages/terms_of_service_page.dart';
import '../../features/notifications/pages/notification_settings_page.dart';
import '../../features/onboarding/pages/budget_setup_page.dart';
import '../../features/onboarding/pages/first_asset_page.dart';
import '../../features/onboarding/pages/risk_questionnaire_page.dart';
import '../../features/onboarding/pages/target_allocation_page.dart';
import '../../features/onboarding/pages/welcome_page.dart';
import '../../features/portfolio/pages/allocation_page.dart';
import '../../features/portfolio/pages/performance_page.dart';
import '../../features/settings/pages/account_page.dart';
import '../../features/settings/pages/export_page.dart';
import '../../features/settings/pages/pwa_install_page.dart';
import '../../features/settings/pages/profile_page.dart';
import '../../features/settings/pages/privacy_page.dart';
import '../../features/subscriptions/pages/subscriptions_page.dart';
import '../../features/transactions/import/pages/transaction_import_flow_page.dart';
import '../../features/transactions/pages/manual_transaction_page.dart';
import '../../features/transactions/pages/transactions_page.dart';
import '../../shared/widgets/app_shell/app_shell.dart';
import 'route_paths.dart';

final appRouter = createAppRouter();

GoRouter createAppRouter({String initialLocation = RoutePaths.dashboard}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.path, child: child);
        },
        routes: [
          _route(path: RoutePaths.dashboard, child: const DashboardPage()),
          _route(path: RoutePaths.authLogin, child: const LoginPage()),
          _route(path: RoutePaths.authSignup, child: const SignupPage()),
          _route(
            path: RoutePaths.onboardingWelcome,
            child: const WelcomePage(),
          ),
          _route(
            path: RoutePaths.onboardingRiskQuestionnaire,
            child: const RiskQuestionnairePage(),
          ),
          _route(
            path: RoutePaths.onboardingTargetAllocation,
            child: const TargetAllocationPage(),
          ),
          _route(
            path: RoutePaths.onboardingBudgetSetup,
            child: const BudgetSetupPage(),
          ),
          _route(
            path: RoutePaths.onboardingFirstAsset,
            child: const FirstAssetPage(),
          ),
          _route(path: RoutePaths.assets, child: const AssetsPage()),
          _route(path: RoutePaths.assetsAdd, child: const AddAssetPage()),
          _route(
            path: RoutePaths.transactions,
            child: const TransactionsPage(),
          ),
          _route(
            path: RoutePaths.transactionsImport,
            child: const TransactionImportFlowPage(),
          ),
          _route(
            path: RoutePaths.transactionsManual,
            child: const ManualTransactionPage(),
          ),
          _route(
            path: RoutePaths.subscriptions,
            child: const SubscriptionsPage(),
          ),
          _route(path: RoutePaths.income, child: const IncomePage()),
          _route(path: RoutePaths.incomeAdd, child: const AddIncomePage()),
          _route(path: RoutePaths.cards, child: const CardsPage()),
          _route(path: RoutePaths.cardsAdd, child: const AddCardPage()),
          _route(path: RoutePaths.budget, child: const BudgetPage()),
          _route(
            path: RoutePaths.budgetHistory,
            child: const BudgetHistoryPage(),
          ),
          _route(
            path: RoutePaths.portfolioAllocation,
            child: const AllocationPage(),
          ),
          _route(
            path: RoutePaths.portfolioPerformance,
            child: const PortfolioPerformancePage(),
          ),
          _route(path: RoutePaths.insights, child: const InsightsPage()),
          _route(path: RoutePaths.settingsPrivacy, child: const PrivacyPage()),
          _route(path: RoutePaths.settingsProfile, child: const ProfilePage()),
          _route(path: RoutePaths.settingsExport, child: const ExportPage()),
          _route(path: RoutePaths.settingsAccount, child: const AccountPage()),
          _route(
            path: RoutePaths.settingsNotifications,
            child: const NotificationSettingsPage(),
          ),
          _route(
            path: RoutePaths.settingsPwaInstall,
            child: const PwaInstallPage(),
          ),
          _route(
            path: RoutePaths.legalPrivacy,
            child: const PrivacyPolicyPage(),
          ),
          _route(
            path: RoutePaths.legalTerms,
            child: const TermsOfServicePage(),
          ),
          _route(
            path: RoutePaths.legalAiTemplate,
            child: const AiDisclosureTemplatePage(),
          ),
        ],
      ),
    ],
  );
}

GoRoute _route({required String path, required Widget child}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        NoTransitionPage<void>(key: state.pageKey, child: child),
  );
}
