import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/admin_auth_provider.dart';
import 'core/providers/application_state_provider.dart';
import 'core/providers/gigs_provider.dart';
import 'core/providers/scoring_weights_provider.dart';
import 'core/providers/tier_settings_provider.dart';
import 'features/admin/admin_login_page.dart';
import 'features/admin/admin_panel_page.dart';
import 'features/application_status/application_status_page.dart';
import 'features/apply/apply_wizard_page.dart';
import 'features/dashboard/gigs_dashboard_page.dart';
import 'features/gigs_landing/gigs_landing_page.dart';
import 'features/more/more_page.dart';
import 'shared/app_colors.dart';

void main() {
  runApp(const SkillboxAffiliateApp());
}

/// Flutter port of the Angular prototype at the repo root - see
/// `docs/api-spec.md` at the repo root for the backend contract this whole
/// feature expects. Provider is used for state management to match the
/// existing Skillbox Flutter app's pattern.
class SkillboxAffiliateApp extends StatelessWidget {
  const SkillboxAffiliateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApplicationStateProvider()),
        ChangeNotifierProvider(create: (_) => GigsProvider()),
        ChangeNotifierProvider(create: (_) => TierSettingsProvider()),
        ChangeNotifierProvider(create: (_) => ScoringWeightsProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
      ],
      child: MaterialApp(
        title: 'Skillbox Affiliate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent, primary: AppColors.accent),
          textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.ink)),
        ),
        initialRoute: '/more',
        routes: {
          '/more': (_) => const MorePage(),
          '/gigs': (_) => const GigsLandingPage(),
          '/gigs/apply': (_) => const ApplyWizardPage(),
          '/gigs/status': (_) => const ApplicationStatusPage(),
          '/gigs/dashboard': (_) => const GigsDashboardPage(),
          '/admin-login': (_) => const AdminLoginPage(),
          '/admin': (_) => const AdminPanelPage(),
        },
      ),
    );
  }
}
