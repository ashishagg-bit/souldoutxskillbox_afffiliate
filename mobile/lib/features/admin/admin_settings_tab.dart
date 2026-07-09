import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/types.dart';
import '../../core/providers/scoring_weights_provider.dart';
import '../../core/providers/tier_settings_provider.dart';
import '../../core/scoring/scoring.dart';
import '../../shared/app_colors.dart';

/// Direct port of `features/admin/admin-settings.component.ts`. Tier score
/// cutoffs/payout text, and per-metric scoring weights.
class AdminSettingsTab extends StatelessWidget {
  const AdminSettingsTab({super.key});

  static const _weightLabels = [
    ('followers', 'Followers', true),
    ('engagementRate', 'Engagement rate', true),
    ('platform', 'Platform (content format)', true),
    ('audienceQuality', 'Audience quality', true),
    ('ticketsSold', 'Tickets sold', false),
    ('contentApprovalRate', 'Content approval rate', false),
    ('gigsCompleted', 'Gigs completed', false),
    ('active', 'Active in last 60 days', false),
  ];

  Future<void> _confirmReset(BuildContext context, String message, VoidCallback onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final tierSettings = context.watch<TierSettingsProvider>();
    final scoringWeights = context.watch<ScoringWeightsProvider>();
    final weights = scoringWeights.weights;

    final platformTotal = weights.followers + weights.engagementRate + weights.platform + weights.audienceQuality;
    final performanceTotal = weights.ticketsSold + weights.contentApprovalRate + weights.gigsCompleted + weights.active;
    final total = platformTotal + performanceTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
                child: Text('Influencer tier thresholds', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink))),
            OutlinedButton(
              onPressed: () => _confirmReset(context, 'Reset tier thresholds and payout ranges to defaults?', tierSettings.resetToDefaults),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Reset to defaults', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Score cutoffs (0–100) that decide which tier a creator lands in, and the payout range shown on the Gigs landing page. '
          "Changes take effect immediately for every creator's score.",
          style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.panel),
              columns: const [
                DataColumn(label: Text('Tier')),
                DataColumn(label: Text('Min score')),
                DataColumn(label: Text('Max score')),
                DataColumn(label: Text('Payout range')),
              ],
              rows: tierSettings.tierBands.map((band) {
                return DataRow(cells: [
                  DataCell(Text(band.tier.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(_numberCell('${band.min}', (v) => tierSettings.updateBand(band.tier, min: int.tryParse(v) ?? band.min))),
                  DataCell(_numberCell('${band.max}', (v) => tierSettings.updateBand(band.tier, max: int.tryParse(v) ?? band.max))),
                  DataCell(_textCell(band.payout, (v) => tierSettings.updateBand(band.tier, payout: v))),
                ]);
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
                child: Text('Scoring weights', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink))),
            OutlinedButton(
              onPressed: () => _confirmReset(
                  context, 'Reset scoring weights to defaults (60/40 platform/performance split)?', scoringWeights.resetToDefaults),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Reset to defaults', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'How many points each metric can contribute to a 0–100 score. The banding logic within each metric stays fixed — '
          'this only controls how much that metric is worth relative to the others.',
          style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;
          final platformCard = _weightsCard('PLATFORM METRICS', platformTotal, true, weights, scoringWeights);
          final performanceCard = _weightsCard('SKILLBOX PERFORMANCE', performanceTotal, false, weights, scoringWeights);
          if (isNarrow) {
            return Column(children: [platformCard, const SizedBox(height: 12), performanceCard]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: platformCard), const SizedBox(width: 16), Expanded(child: performanceCard)],
          );
        }),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
          child: Text.rich(TextSpan(children: [
            const TextSpan(text: 'Total possible score right now: ', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            TextSpan(text: '$total pts', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
            if (total != 100)
              TextSpan(
                text:
                    ' — not 100. Tier cutoffs above are still on a 0–100 scale, so scores will feel ${total > 100 ? 'inflated' : 'compressed'} against them until the weights sum back to 100.',
                style: const TextStyle(fontSize: 13, color: AppColors.accent),
              )
            else
              const TextSpan(text: ' — matches the 0–100 tier scale above.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          ])),
        ),
      ],
    );
  }

  Widget _weightsCard(String title, double totalPts, bool platform, ScoringWeights weights, ScoringWeightsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.faint, letterSpacing: 0.3)),
              Text('${totalPts.toStringAsFixed(totalPts == totalPts.roundToDouble() ? 0 : 1)} pts',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 12),
          ..._weightLabels.where((w) => w.$3 == platform).map((w) {
            final key = w.$1;
            final label = w.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.ink))),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      key: ValueKey('$key-${weights[key]}'),
                      initialValue: '${weights[key]}',
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onFieldSubmitted: (v) => provider.updateWeight(key, double.tryParse(v) ?? weights[key]),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) provider.updateWeight(key, parsed);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
                        enabledBorder:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _numberCell(String value, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 70,
      child: TextFormField(
        key: ValueKey(value),
        initialValue: value,
        keyboardType: TextInputType.number,
        onFieldSubmitted: onChanged,
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
        ),
      ),
    );
  }

  Widget _textCell(String value, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 130,
      child: TextFormField(
        key: ValueKey(value),
        initialValue: value,
        onFieldSubmitted: onChanged,
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.line)),
        ),
      ),
    );
  }
}
