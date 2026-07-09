import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/types.dart';
import '../../core/providers/application_state_provider.dart';
import '../../core/providers/tier_settings_provider.dart';
import '../../shared/app_colors.dart';
import '../../shared/widgets/bottom_nav.dart';

/// Direct port of `features/gigs-landing/gigs-landing.component.ts`.
class GigsLandingPage extends StatelessWidget {
  const GigsLandingPage({super.key});

  static const _categories = [
    (
      'Event attendance',
      'Get on guest lists or VIP. Your presence = crowd quality signal.',
      Icons.person_outline,
      Color(0xFFFFF7ED),
      Color(0xFFC2410C),
    ),
    (
      'Story coverage',
      'Live stories during events. Real-time reach for organisers.',
      Icons.public,
      Color(0xFFEFF6FF),
      Color(0xFF1D4ED8),
    ),
    (
      'UGC content',
      'Create reels, posts, or ads for Skillbox and organiser brands.',
      Icons.videocam_outlined,
      Color(0xFFECFDF5),
      Color(0xFF047857),
    ),
    (
      'Brand campaigns',
      'Longer-form brand deals posted by organisers directly.',
      Icons.favorite_border,
      Color(0xFFFAF5FF),
      Color(0xFF7E22CE),
    ),
  ];

  void _goToApply(BuildContext context) {
    final status = context.read<ApplicationStateProvider>().application.status;
    switch (status) {
      case ApplicationStatus.approved:
        Navigator.of(context).pushNamed('/gigs/dashboard');
      case ApplicationStatus.underReview:
      case ApplicationStatus.rejected:
        Navigator.of(context).pushNamed('/gigs/status');
      case ApplicationStatus.notApplied:
        Navigator.of(context).pushNamed('/gigs/apply');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierBands = context.watch<TierSettingsProvider>().tierBands;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.groups_outlined, color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 20),
                        const Text('Get paid to show up',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.ink)),
                        const SizedBox(height: 12),
                        const Text(
                          'Attend events, cover them on your stories, or create content for brands. '
                          'Gigs matched to your audience size and engagement.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: AppColors.muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        for (var i = 0; i < _categories.length; i += 2) ...[
                          if (i > 0) const SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _CategoryCard(_categories[i])),
                                const SizedBox(width: 12),
                                if (i + 1 < _categories.length)
                                  Expanded(child: _CategoryCard(_categories[i + 1]))
                                else
                                  const Expanded(child: SizedBox()),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GIG PAYOUTS BY TIER',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.faint, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        ...tierBands.map((band) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${band.tier.label} · Score ${band.min}–${band.max}',
                                      style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                                  Text(band.payout,
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent, fontFamily: 'monospace')),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _goToApply(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Apply to join', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
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

class _CategoryCard extends StatelessWidget {
  final (String, String, IconData, Color, Color) category;

  const _CategoryCard(this.category);

  @override
  Widget build(BuildContext context) {
    final (title, desc, icon, bg, iconColor) = category;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.3)),
        ],
      ),
    );
  }
}
