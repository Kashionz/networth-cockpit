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
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: RoutePaths.authLogin,
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: RoutePaths.authSignup,
            builder: (context, state) => const SignupPage(),
          ),
          GoRoute(
            path: RoutePaths.onboardingWelcome,
            builder: (context, state) => const WelcomePage(),
          ),
          GoRoute(
            path: RoutePaths.onboardingRiskQuestionnaire,
            builder: (context, state) => const RiskQuestionnairePage(),
          ),
          GoRoute(
            path: RoutePaths.onboardingTargetAllocation,
            builder: (context, state) => const TargetAllocationPage(),
          ),
          GoRoute(
            path: RoutePaths.onboardingBudgetSetup,
            builder: (context, state) => const BudgetSetupPage(),
          ),
          GoRoute(
            path: RoutePaths.onboardingFirstAsset,
            builder: (context, state) => const FirstAssetPage(),
          ),
          GoRoute(
            path: RoutePaths.assets,
            builder: (context, state) => const AssetsPage(),
          ),
          GoRoute(
            path: RoutePaths.assetsAdd,
            builder: (context, state) => const AddAssetPage(),
          ),
          GoRoute(
            path: RoutePaths.transactions,
            builder: (context, state) => const TransactionsPage(),
          ),
          GoRoute(
            path: RoutePaths.transactionsImport,
            builder: (context, state) => const TransactionImportFlowPage(),
          ),
          GoRoute(
            path: RoutePaths.transactionsManual,
            builder: (context, state) => const ManualTransactionPage(),
          ),
          GoRoute(
            path: RoutePaths.cards,
            builder: (context, state) => const CardsPage(),
          ),
          GoRoute(
            path: RoutePaths.cardsAdd,
            builder: (context, state) => const AddCardPage(),
          ),
          GoRoute(
            path: RoutePaths.budget,
            builder: (context, state) => const BudgetPage(),
          ),
          GoRoute(
            path: RoutePaths.budgetHistory,
            builder: (context, state) => const BudgetHistoryPage(),
          ),
          GoRoute(
            path: RoutePaths.portfolioAllocation,
            builder: (context, state) => const AllocationPage(),
          ),
          GoRoute(
            path: RoutePaths.portfolioPerformance,
            builder: (context, state) => const PortfolioPerformancePage(),
          ),
          GoRoute(
            path: RoutePaths.insights,
            builder: (context, state) => const InsightsPage(),
          ),
          GoRoute(
            path: RoutePaths.settingsPrivacy,
            builder: (context, state) => const PrivacyPage(),
          ),
          GoRoute(
            path: RoutePaths.settingsProfile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: RoutePaths.settingsExport,
            builder: (context, state) => const ExportPage(),
          ),
          GoRoute(
            path: RoutePaths.settingsAccount,
            builder: (context, state) => const AccountPage(),
          ),
          GoRoute(
            path: RoutePaths.settingsNotifications,
            builder: (context, state) => const NotificationSettingsPage(),
          ),
          GoRoute(
            path: RoutePaths.settingsPwaInstall,
            builder: (context, state) => const PwaInstallPage(),
          ),
          GoRoute(
            path: RoutePaths.legalPrivacy,
            builder: (context, state) => const PrivacyPolicyPage(),
          ),
          GoRoute(
            path: RoutePaths.legalTerms,
            builder: (context, state) => const TermsOfServicePage(),
          ),
          GoRoute(
            path: RoutePaths.legalAiTemplate,
            builder: (context, state) => const AiDisclosureTemplatePage(),
          ),
        ],
      ),
    ],
  );
}
