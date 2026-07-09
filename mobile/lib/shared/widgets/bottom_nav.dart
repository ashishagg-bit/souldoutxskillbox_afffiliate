import 'package:flutter/material.dart';
import '../app_colors.dart';

enum NavTab { home, events, search, more }

/// Direct port of `shared/bottom-nav/bottom-nav.component.ts`. Home/Events/
/// Search are out of scope for this feature (same as the web prototype) -
/// tapping any of them just returns to the More menu, same as tapping More.
class BottomNav extends StatelessWidget {
  final NavTab active;

  const BottomNav({super.key, this.active = NavTab.more});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(label: 'Home', icon: Icons.home_outlined, tab: NavTab.home, active: active),
            _NavItem(label: 'Events', icon: Icons.confirmation_number_outlined, tab: NavTab.events, active: active),
            _NavItem(label: 'Search', icon: Icons.search, tab: NavTab.search, active: active),
            _NavItem(label: 'More', icon: Icons.grid_view_outlined, tab: NavTab.more, active: active),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final NavTab tab;
  final NavTab active;

  const _NavItem({required this.label, required this.icon, required this.tab, required this.active});

  @override
  Widget build(BuildContext context) {
    final isActive = tab == active;
    final color = isActive ? AppColors.ink : AppColors.faint;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (ModalRoute.of(context)?.settings.name != '/more') {
            Navigator.of(context).pushNamedAndRemoveUntil('/more', (route) => false);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
