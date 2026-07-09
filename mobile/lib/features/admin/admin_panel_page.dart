import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/admin_auth_provider.dart';
import '../../shared/app_colors.dart';
import 'admin_analytics_tab.dart';
import 'admin_applications_tab.dart';
import 'admin_overview_tab.dart';
import 'admin_settings_tab.dart';
import 'admin_shows_tab.dart';

enum AdminTab { overview, applications, shows, analytics, settings }

/// Direct port of `features/admin/admin-panel.component.ts`. Route-level
/// auth guard: redirects to /admin-login if not authenticated (mirrors
/// `adminAuthGuard` in the Angular routes).
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  AdminTab _tab = AdminTab.overview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<AdminAuthProvider>().isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/admin-login');
      }
    });
  }

  void _logout() {
    context.read<AdminAuthProvider>().logout();
    Navigator.of(context).pushReplacementNamed('/admin-login');
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AdminAuthProvider>().isAuthenticated;
    if (!isAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SKILLBOX INTERNAL',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.faint, letterSpacing: 0.5)),
                        Text('Affiliate admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Sign out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: AdminTab.values.map((t) {
                    final selected = t == _tab;
                    return InkWell(
                      onTap: () => setState(() => _tab = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: selected ? AppColors.accent : Colors.transparent, width: 2)),
                        ),
                        child: Text(_tabLabel(t),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? AppColors.ink : AppColors.faint)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: switch (_tab) {
                  AdminTab.overview => const AdminOverviewTab(),
                  AdminTab.applications => const AdminApplicationsTab(),
                  AdminTab.shows => const AdminShowsTab(),
                  AdminTab.analytics => const AdminAnalyticsTab(),
                  AdminTab.settings => const AdminSettingsTab(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tabLabel(AdminTab t) => switch (t) {
        AdminTab.overview => 'Overview',
        AdminTab.applications => 'Applications',
        AdminTab.shows => 'Shows',
        AdminTab.analytics => 'Analytics',
        AdminTab.settings => 'Settings',
      };
}
