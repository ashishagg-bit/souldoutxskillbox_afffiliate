import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/types.dart';
import '../../core/providers/application_state_provider.dart';
import '../../core/providers/gigs_provider.dart';
import '../../core/referral/referral.dart';
import '../../shared/app_colors.dart';

/// Direct port of `features/admin/admin-overview.component.ts`.
class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({super.key});

  String _fmtCurrency(num n) => '₹${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  String _statusLabel(ApplicationStatus s) => switch (s) {
        ApplicationStatus.notApplied => 'Not applied',
        ApplicationStatus.underReview => 'Under review',
        ApplicationStatus.approved => 'Approved',
        ApplicationStatus.rejected => 'Rejected',
      };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationStateProvider>();
    final gigsProvider = context.watch<GigsProvider>();
    final app = appState.application;

    final pendingShowRequests = app.appliedGigs.where((a) => a.status == GigApplicationStatus.pending).length;
    final approvedLinks = app.appliedGigs.where((a) => a.status == GigApplicationStatus.approved && a.referralCode != null).toList();

    var totalClicks = 0;
    var totalTickets = 0;
    var totalCommission = 0;
    for (final row in approvedLinks) {
      final gig = gigsProvider.getById(row.gigId);
      if (gig == null || row.referralCode == null) continue;
      final stats = mockLinkStats(row.referralCode!, ticketPrice: gig.ticketPrice, commissionRate: gig.commissionRate);
      totalClicks += stats.clicks;
      totalTickets += stats.ticketsSold;
      totalCommission += stats.commissionEarned;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _statCard('PROFILE STATUS', _statusLabel(app.status))),
            const SizedBox(width: 12),
            Expanded(child: _statCard('PENDING SHOW REQUESTS', '$pendingShowRequests')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _statCard('ACTIVE PROMO LINKS', '${approvedLinks.length}')),
            const SizedBox(width: 12),
            Expanded(child: _statCard('SHOWS LISTED', '${gigsProvider.gigs.length}')),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LINK PERFORMANCE (ALL CREATORS)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.faint, letterSpacing: 0.5)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _bigStat('$totalClicks', 'Total clicks')),
                  Expanded(child: _bigStat('$totalTickets', 'Tickets sold')),
                  Expanded(child: _bigStat(_fmtCurrency(totalCommission), 'Commission owed', accent: true)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
          child: const Text(
            "This is a single-applicant local demo, so these numbers reflect just the one creator/application in this device's storage. "
            "In the real backend this aggregates across every applicant and gig application — see docs/api-spec.md for the endpoint shapes.",
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.faint, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _bigStat(String value, String label, {bool accent = false}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accent ? AppColors.accent : AppColors.ink)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.faint)),
      ],
    );
  }
}
