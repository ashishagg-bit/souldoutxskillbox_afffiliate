import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/types.dart';
import '../../core/providers/application_state_provider.dart';
import '../../core/providers/gigs_provider.dart';
import '../../core/providers/scoring_weights_provider.dart';
import '../../core/providers/tier_settings_provider.dart';
import '../../core/referral/referral.dart';
import '../../core/scoring/scoring.dart';
import '../../shared/app_colors.dart';
import '../../shared/tier_style.dart';
import '../../shared/widgets/bottom_nav.dart';

/// Direct port of `features/dashboard/gigs-dashboard.component.ts`.
class GigsDashboardPage extends StatefulWidget {
  const GigsDashboardPage({super.key});

  @override
  State<GigsDashboardPage> createState() => _GigsDashboardPageState();
}

enum _DashTab { score, available, myGigs }

class _GigsDashboardPageState extends State<GigsDashboardPage> {
  _DashTab _tab = _DashTab.score;
  GigType? _filter; // null = All

  static const List<GigType?> _filters = [null, ...GigType.values];

  String _fmtCurrency(num n) => '₹${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  String _formatPayout(Gig g) => g.payoutMin == g.payoutMax ? _fmtCurrency(g.payoutMin) : '${_fmtCurrency(g.payoutMin)}–${_fmtCurrency(g.payoutMax)}';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ApplicationStateProvider>();
    final gigsProvider = context.watch<GigsProvider>();
    final tierBands = context.watch<TierSettingsProvider>().tierBands;
    final weights = context.watch<ScoringWeightsProvider>().weights;
    final app = appState.application;
    final score = computeScore(app.insights, app.performance, tierBands: tierBands, weights: weights);
    final profileApproved = app.status == ApplicationStatus.approved;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                _TabButton(label: 'My Score', selected: _tab == _DashTab.score, onTap: () => setState(() => _tab = _DashTab.score)),
                _TabButton(label: 'Available', selected: _tab == _DashTab.available, onTap: () => setState(() => _tab = _DashTab.available)),
                _TabButton(label: 'My Gigs', selected: _tab == _DashTab.myGigs, onTap: () => setState(() => _tab = _DashTab.myGigs)),
              ],
            ),
            const Divider(height: 1, color: AppColors.line),
            if (!profileApproved && _tab != _DashTab.score)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  "Your profile is still pending Skillbox review. You can preview gigs below, but Apply stays locked until you're approved.",
                  style: TextStyle(fontSize: 13, color: AppColors.amber900),
                ),
              ),
            Expanded(
              child: switch (_tab) {
                _DashTab.score => _buildScoreTab(context, score, profileApproved, app.status),
                _DashTab.available => _buildAvailableTab(context, appState, gigsProvider, score.tier, profileApproved),
                _DashTab.myGigs => _buildMyGigsTab(context, appState, gigsProvider),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(active: NavTab.more),
    );
  }

  Widget _buildScoreTab(BuildContext context, ScoreBreakdown score, bool profileApproved, ApplicationStatus status) {
    final style = tierStyles[score.tier]!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (!profileApproved)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(12)),
            child: Text(
              status == ApplicationStatus.rejected
                  ? 'Your profile was not approved. This score is a preview only.'
                  : 'This score is a live preview based on what you entered — it becomes official once a Skillbox reviewer approves your profile.',
              style: const TextStyle(fontSize: 13, color: AppColors.amber900),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: style.solid, borderRadius: BorderRadius.circular(20)),
                child: Text('${score.tier.label.toUpperCase()} TIER',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 16),
              Text('${score.total}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
              const SizedBox(height: 4),
              const Text('YOUR INFLUENCER SCORE', style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (score.total / 100).clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: const Color(0xFF374151),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bronze', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('Silver', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('Gold', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('Platinum', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _scoreCard('PLATFORM METRICS · 60 PTS', score.platformMetrics),
        const SizedBox(height: 16),
        _scoreCard('SKILLBOX PERFORMANCE · 40 PTS', score.skillboxPerformance),
      ],
    );
  }

  Widget _scoreCard(String title, List<ScoreBreakdownItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.faint, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: item.label, style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
                            if (item.detail.isNotEmpty)
                              TextSpan(text: ' ${item.detail}', style: const TextStyle(fontSize: 13.5, color: AppColors.faint)),
                          ])),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: item.max > 0 ? (item.earned / item.max).clamp(0, 1) : 0,
                              minHeight: 4,
                              backgroundColor: AppColors.panel,
                              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 56,
                      child: Text('${item.earned}/${item.max}',
                          textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAvailableTab(
    BuildContext context,
    ApplicationStateProvider appState,
    GigsProvider gigsProvider,
    Tier userTier,
    bool profileApproved,
  ) {
    final allGigs = gigsProvider.gigs;
    final filtered = _filter == null ? allGigs : allGigs.where((g) => g.type == _filter).toList();

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: _filters.map((f) {
              final selected = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f?.label ?? 'All'),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: Colors.black,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontSize: 13.5),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: selected ? Colors.black : AppColors.line),
                  shape: const StadiumBorder(),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final gig = filtered[i];
              final eligible = profileApproved && tierMeetsMinimum(userTier, gig.minTier);
              final applied = appState.application.appliedGigs.where((a) => a.gigId == gig.id).firstOrNull;

              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: eligible ? Colors.black : AppColors.gray400,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(gig.type.label.toUpperCase(),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: eligible ? AppColors.emerald100 : AppColors.gray100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(eligible ? '${gig.minTier.label}+' : '${gig.minTier.label} only',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600, color: eligible ? AppColors.emerald800 : AppColors.gray600)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(gig.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            children: [
                              if (gig.location != null) Text('📍 ${gig.location}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                              if (gig.date != null) Text('📅 ${gig.date}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                              if (gig.deliverable != null) Text(gig.deliverable!, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                              if (gig.spotsLeft != null) Text('${gig.spotsLeft} spots left', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                            ],
                          ),
                          if (gig.ticketPrice != null && gig.commissionRate != null) ...[
                            const SizedBox(height: 4),
                            Text('Promote with your unique link · earn ${gig.commissionRate}% per ticket sold',
                                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatPayout(gig),
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent, fontFamily: 'monospace')),
                                    Text(
                                      eligible ? 'Min score: ${gig.minScore}' : 'Requires ${gig.minTier.label} · score ${gig.minScore}+',
                                      style: TextStyle(fontSize: 12, color: eligible ? AppColors.faint : AppColors.accent),
                                    ),
                                  ],
                                ),
                              ),
                              _availableActionButton(context, appState, gig, eligible, applied),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _availableActionButton(BuildContext context, ApplicationStateProvider appState, Gig gig, bool eligible, AppliedGig? applied) {
    String label;
    Color bg;
    Color fg;
    VoidCallback? onTap;

    if (!eligible) {
      label = 'Locked';
      bg = AppColors.gray200;
      fg = AppColors.gray400;
    } else if (applied == null) {
      label = 'Apply';
      bg = Colors.black;
      fg = Colors.white;
      onTap = () => appState.applyToGig(gig.id);
    } else {
      switch (applied.status) {
        case GigApplicationStatus.pending:
          label = 'Pending';
          bg = AppColors.amber100;
          fg = AppColors.amber800;
        case GigApplicationStatus.approved:
          label = 'Approved';
          bg = AppColors.emerald100;
          fg = AppColors.emerald800;
        case GigApplicationStatus.rejected:
          label = 'Not approved';
          bg = AppColors.gray100;
          fg = AppColors.gray500;
      }
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg,
        disabledForegroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMyGigsTab(BuildContext context, ApplicationStateProvider appState, GigsProvider gigsProvider) {
    final appliedIds = appState.application.appliedGigs.map((a) => a.gigId).toSet();
    final myGigs = gigsProvider.gigs.where((g) => appliedIds.contains(g.id)).toList();

    if (myGigs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 40, color: AppColors.gray200),
            const SizedBox(height: 16),
            const Text('No active gigs yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 4),
            const Text('Apply from the Available tab to get started', style: TextStyle(fontSize: 13.5, color: AppColors.faint)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: myGigs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final gig = myGigs[i];
        final applied = appState.application.appliedGigs.firstWhere((a) => a.gigId == gig.id);
        MockLinkStats? stats;
        if (applied.status == GigApplicationStatus.approved && applied.referralCode != null) {
          stats = mockLinkStats(applied.referralCode!, ticketPrice: gig.ticketPrice, commissionRate: gig.commissionRate);
        }

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(gig.type.label.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    _myGigsBadge(applied.status),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gig.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Text(_formatPayout(gig),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent, fontFamily: 'monospace')),
                    if (applied.status == GigApplicationStatus.pending) ...[
                      const SizedBox(height: 8),
                      const Text("Awaiting Skillbox approval to promote this show — you'll get your unique tracking link once approved.",
                          style: TextStyle(fontSize: 13, color: AppColors.muted)),
                    ],
                    if (applied.status == GigApplicationStatus.rejected) ...[
                      const SizedBox(height: 8),
                      const Text("You weren't approved to promote this show.", style: TextStyle(fontSize: 13, color: AppColors.muted)),
                    ],
                    if (applied.status == GigApplicationStatus.approved) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('YOUR TRACKING LINK',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.faint, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(referralLink(applied.referralCode!),
                                      overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Link copied'), duration: Duration(seconds: 1)),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('Post this in your stories, posts, or reels. Anyone who buys a ticket through it earns you commission.',
                                style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      if (stats != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _statTile('${stats.clicks}', 'Clicks')),
                            const SizedBox(width: 8),
                            Expanded(child: _statTile('${stats.ticketsSold}', 'Tickets sold')),
                            const SizedBox(width: 8),
                            Expanded(child: _statTile(_fmtCurrency(stats.commissionEarned), 'Commission', accent: true)),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _myGigsBadge(GigApplicationStatus status) {
    final (label, bg, fg) = switch (status) {
      GigApplicationStatus.pending => ('Pending approval', AppColors.amber100, AppColors.amber800),
      GigApplicationStatus.approved => ('Approved', AppColors.emerald100, AppColors.emerald800),
      GigApplicationStatus.rejected => ('Not approved', AppColors.gray200, AppColors.gray600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _statTile(String value, String label, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent ? AppColors.accent : AppColors.ink)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.faint)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? AppColors.accent : Colors.transparent, width: 2)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? AppColors.ink : AppColors.faint)),
        ),
      ),
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
