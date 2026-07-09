import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/types.dart';
import '../../core/providers/application_state_provider.dart';
import '../../core/providers/gigs_provider.dart';
import '../../core/providers/scoring_weights_provider.dart';
import '../../core/providers/tier_settings_provider.dart';
import '../../core/scoring/scoring.dart';
import '../../shared/app_colors.dart';
import '../../shared/tier_style.dart';

/// Direct port of `features/admin/admin-review.component.ts`. Reviewer-
/// facing screen: approve/reject the one profile in this local demo store,
/// and approve/reject its pending gig applications. In the real product
/// this is a queue of many applicants (see docs/api-spec.md) - this stands
/// in for that queue with a single row.
class AdminApplicationsTab extends StatelessWidget {
  const AdminApplicationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationStateProvider>();
    final gigsProvider = context.watch<GigsProvider>();
    final tierBands = context.watch<TierSettingsProvider>().tierBands;
    final weights = context.watch<ScoringWeightsProvider>().weights;
    final app = appState.application;
    final score = computeScore(app.insights, app.performance, tierBands: tierBands, weights: weights);
    final style = tierStyles[score.tier]!;

    final pending = app.appliedGigs.where((a) => a.status == GigApplicationStatus.pending).toList();
    final reviewed = app.appliedGigs.where((a) => a.status != GigApplicationStatus.pending).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profile application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 4),
              const Text('Reviewer tools for approving creator profiles and their per-show promotion requests.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
              if (app.status == ApplicationStatus.notApplied) ...[
                const SizedBox(height: 12),
                const Text('No application submitted yet.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
              ] else ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _field('Instagram', '@${app.socials.instagramHandle}'),
                    _field('Platforms', app.socials.platforms.map((p) => p.label).join(', ')),
                    _field('City / Niche', '${app.locationNiche.city?.label ?? '—'} · ${app.locationNiche.niche?.label ?? '—'}'),
                    _field('AI score', '${score.total}/100', valueColor: style.text),
                    Text(score.tier.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: style.text)),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: score.platformMetrics
                      .map((item) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.label, style: const TextStyle(fontSize: 11, color: AppColors.faint)),
                                Text('${item.earned}/${item.max}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statusPill(app.status),
                    const Spacer(),
                    if (app.status == ApplicationStatus.underReview) ...[
                      ElevatedButton(
                        onPressed: () => appState.approveApplication(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Approve profile', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => appState.rejectApplication(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pending show-promotion requests (${pending.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
              if (pending.isEmpty) ...[
                const SizedBox(height: 12),
                const Text('Nothing waiting on review.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
              ] else ...[
                const SizedBox(height: 16),
                ...pending.map((row) {
                  final gig = gigsProvider.getById(row.gigId);
                  if (gig == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gig.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                              const SizedBox(height: 2),
                              Text(
                                '${gig.type.label} · requires ${gig.minTier.label}+ · applied ${DateFormat('MMM d, h:mm a').format(row.appliedAt)}',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => appState.approveGigApplication(gig.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Approve', style: TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => appState.rejectGigApplication(gig.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Reject', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (reviewed.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Already reviewed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.faint)),
                const SizedBox(height: 8),
                ...reviewed.map((row) {
                  final gig = gigsProvider.getById(row.gigId);
                  if (gig == null) return const SizedBox.shrink();
                  final approved = row.status == GigApplicationStatus.approved;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(child: Text(gig.title, style: const TextStyle(fontSize: 13.5, color: AppColors.ink))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: approved ? AppColors.emerald100 : AppColors.gray200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(approved ? 'Approved' : 'Rejected',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: approved ? AppColors.emerald800 : AppColors.gray700)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(String label, String value, {Color? valueColor}) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.faint)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? AppColors.ink)),
        ],
      ),
    );
  }

  Widget _statusPill(ApplicationStatus status) {
    final (label, bg, fg) = switch (status) {
      ApplicationStatus.underReview => ('Pending review', AppColors.amber100, AppColors.amber800),
      ApplicationStatus.approved => ('Approved', AppColors.emerald100, AppColors.emerald800),
      ApplicationStatus.rejected => ('Rejected', AppColors.gray200, AppColors.gray700),
      ApplicationStatus.notApplied => ('Not applied', AppColors.gray200, AppColors.gray700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
