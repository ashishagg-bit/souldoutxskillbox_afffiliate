import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/types.dart';
import '../../core/providers/application_state_provider.dart';
import '../../core/providers/gigs_provider.dart';
import '../../core/referral/referral.dart';
import '../../shared/app_colors.dart';

class _LinkRow {
  final String creatorHandle;
  final Gig gig;
  final String referralCode;
  final String link;
  final int clicks;
  final int ticketsSold;
  final int commissionEarned;

  const _LinkRow({
    required this.creatorHandle,
    required this.gig,
    required this.referralCode,
    required this.link,
    required this.clicks,
    required this.ticketsSold,
    required this.commissionEarned,
  });
}

/// Direct port of `features/admin/admin-analytics.component.ts`.
class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({super.key});

  String _fmtCurrency(num n) => '₹${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationStateProvider>();
    final gigsProvider = context.watch<GigsProvider>();
    final app = appState.application;

    final rows = <_LinkRow>[];
    for (final a in app.appliedGigs) {
      if (a.status != GigApplicationStatus.approved || a.referralCode == null) continue;
      final gig = gigsProvider.getById(a.gigId);
      if (gig == null) continue;
      final stats = mockLinkStats(a.referralCode!, ticketPrice: gig.ticketPrice, commissionRate: gig.commissionRate);
      rows.add(_LinkRow(
        creatorHandle: app.socials.instagramHandle,
        gig: gig,
        referralCode: a.referralCode!,
        link: referralLink(a.referralCode!),
        clicks: stats.clicks,
        ticketsSold: stats.ticketsSold,
        commissionEarned: stats.commissionEarned,
      ));
    }

    final totalClicks = rows.fold<int>(0, (s, r) => s + r.clicks);
    final totalTickets = rows.fold<int>(0, (s, r) => s + r.ticketsSold);
    final totalCommission = rows.fold<int>(0, (s, r) => s + r.commissionEarned);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Link performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 4),
        const Text('Every active creator tracking link, with clicks, tickets sold, and commission owed.',
            style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const Text('No approved promo links yet.', style: TextStyle(fontSize: 14, color: AppColors.muted))
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.panel),
                columns: const [
                  DataColumn(label: Text('Creator')),
                  DataColumn(label: Text('Show')),
                  DataColumn(label: Text('Link')),
                  DataColumn(label: Text('Clicks'), numeric: true),
                  DataColumn(label: Text('Tickets sold'), numeric: true),
                  DataColumn(label: Text('Commission'), numeric: true),
                ],
                rows: [
                  ...rows.map((r) => DataRow(cells: [
                        DataCell(Text('@${r.creatorHandle}')),
                        DataCell(Text(r.gig.title)),
                        DataCell(Text(r.link, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
                        DataCell(Text('${r.clicks}')),
                        DataCell(Text('${r.ticketsSold}')),
                        DataCell(Text(_fmtCurrency(r.commissionEarned),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent))),
                      ])),
                  DataRow(
                    color: WidgetStateProperty.all(AppColors.panel),
                    cells: [
                      const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      DataCell(Text('$totalClicks', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('$totalTickets', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_fmtCurrency(totalCommission),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
          child: const Text(
            'Clicks/tickets-sold/commission here are deterministically fabricated from each referral code (mockLinkStats() in '
            'core/referral/referral.dart), not real click tracking. See the referral_clicks / referral_conversions tables in '
            'docs/api-spec.md for the real design.',
            style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
          ),
        ),
      ],
    );
  }
}
