import 'package:flutter/material.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/bottom_nav.dart';

/// Direct port of `features/more/more-page.component.ts`.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  static const _plainTiles = [
    ('Profile', Icons.person_outline),
    ('My Tickets', Icons.confirmation_number_outlined),
    ('Settings', Icons.settings_outlined),
    ('Invite Friends', Icons.ios_share_outlined),
    ('Ticket Scanner', Icons.qr_code_scanner_outlined),
    ('Manage Sales', Icons.bar_chart_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.gray100,
                          child: Icon(Icons.person_outline, size: 26, color: AppColors.gray400),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Avadh Nagpal',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            Text('avadh@souldout.in', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        for (var row = 0; row < _plainTiles.length; row += 3) ...[
                          if (row > 0) const SizedBox(height: 24),
                          Row(
                            children: _plainTiles.skip(row).take(3).map((t) {
                              return Expanded(child: _PlainTile(label: t.$1, icon: t.$2));
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CardTile(
                            label: 'Earn',
                            icon: Icons.attach_money,
                            iconColor: AppColors.accent,
                            onTap: null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CardTile(
                            label: 'Gigs',
                            icon: Icons.groups_outlined,
                            iconColor: AppColors.accent,
                            onTap: () => Navigator.of(context).pushNamed('/gigs'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CardTile(
                            label: 'Crew Dashboard',
                            icon: Icons.grid_view_outlined,
                            iconColor: AppColors.gray600,
                            onTap: null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const BottomNav(active: NavTab.more),
          ],
        ),
      ),
    );
  }
}

class _PlainTile extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PlainTile({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: AppColors.gray600),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _CardTile({required this.label, required this.icon, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
