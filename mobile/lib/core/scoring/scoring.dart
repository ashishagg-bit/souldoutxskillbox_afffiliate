/// Direct port of the Angular prototype's `core/lib/scoring.ts`. This is the
/// single source of truth for the 0-100 influencer score. Keep the band
/// tables and weighting logic identical to the web reference unless the
/// scoring model itself is intentionally changed.
library;

import '../models/types.dart';

class Band {
  final String label;
  final num min;
  final num max; // use double.infinity for the open-ended last band
  final double scoreMin;
  final double scoreMax;

  const Band({required this.label, required this.min, required this.max, required this.scoreMin, required this.scoreMax});
}

class _BandResult {
  final double earned;
  final String label;
  const _BandResult(this.earned, this.label);
}

_BandResult _scoreFromBands(num value, List<Band> bands) {
  final band = bands.firstWhere(
    (b) => value >= b.min && value < b.max,
    orElse: () => bands.last,
  );
  final span = band.max == double.infinity ? band.min * 2 : band.max - band.min;
  final progress = band.max == double.infinity ? 1.0 : ((value - band.min) / span).clamp(0.0, 1.0);
  final earned = band.scoreMin + progress * (band.scoreMax - band.scoreMin);
  return _BandResult((earned * 10).round() / 10, band.label);
}

final List<Band> _followerBands = [
  const Band(label: '0-5k', min: 0, max: 5000, scoreMin: 0, scoreMax: 4),
  const Band(label: '5k-20k', min: 5000, max: 20000, scoreMin: 4, scoreMax: 8),
  const Band(label: '20k-50k', min: 20000, max: 50000, scoreMin: 8, scoreMax: 12),
  const Band(label: '50k-200k', min: 50000, max: 200000, scoreMin: 12, scoreMax: 16),
  const Band(label: '200k-500k', min: 200000, max: 500000, scoreMin: 16, scoreMax: 18),
  Band(label: '500k+', min: 500000, max: double.infinity, scoreMin: 18, scoreMax: 20),
];

final List<Band> _engagementBands = [
  const Band(label: '<1%', min: 0, max: 1, scoreMin: 0, scoreMax: 6),
  const Band(label: '1-3%', min: 1, max: 3, scoreMin: 6, scoreMax: 12),
  const Band(label: '3-6%', min: 3, max: 6, scoreMin: 12, scoreMax: 16),
  Band(label: '6%+', min: 6, max: double.infinity, scoreMin: 16, scoreMax: 18),
];

const Map<ContentFormat, double> _contentFormatScore = {
  ContentFormat.reels: 12,
  ContentFormat.longForm: 10,
  ContentFormat.photos: 8,
  ContentFormat.stories: 6,
};

class TierBand {
  final Tier tier;
  final int min;
  final int max;
  final String payout;

  const TierBand({required this.tier, required this.min, required this.max, required this.payout});

  TierBand copyWith({int? min, int? max, String? payout}) =>
      TierBand(tier: tier, min: min ?? this.min, max: max ?? this.max, payout: payout ?? this.payout);

  Map<String, dynamic> toJson() => {'tier': tier.name, 'min': min, 'max': max, 'payout': payout};

  factory TierBand.fromJson(Map<String, dynamic> json) => TierBand(
        tier: Tier.values.byName(json['tier'] as String),
        min: json['min'] as int,
        max: json['max'] as int,
        payout: json['payout'] as String,
      );
}

const List<TierBand> defaultTierBands = [
  TierBand(tier: Tier.bronze, min: 0, max: 39, payout: '₹2k–₹8k / gig'),
  TierBand(tier: Tier.silver, min: 40, max: 59, payout: '₹5k–₹25k / gig'),
  TierBand(tier: Tier.gold, min: 60, max: 79, payout: '₹12k–₹75k / gig'),
  TierBand(tier: Tier.platinum, min: 80, max: 100, payout: '₹30k–₹3L / gig'),
];

class ScoringWeights {
  final double followers;
  final double engagementRate;
  final double platform;
  final double audienceQuality;
  final double ticketsSold;
  final double contentApprovalRate;
  final double gigsCompleted;
  final double active;

  const ScoringWeights({
    required this.followers,
    required this.engagementRate,
    required this.platform,
    required this.audienceQuality,
    required this.ticketsSold,
    required this.contentApprovalRate,
    required this.gigsCompleted,
    required this.active,
  });

  ScoringWeights copyWithField(String key, double value) {
    return ScoringWeights(
      followers: key == 'followers' ? value : followers,
      engagementRate: key == 'engagementRate' ? value : engagementRate,
      platform: key == 'platform' ? value : platform,
      audienceQuality: key == 'audienceQuality' ? value : audienceQuality,
      ticketsSold: key == 'ticketsSold' ? value : ticketsSold,
      contentApprovalRate: key == 'contentApprovalRate' ? value : contentApprovalRate,
      gigsCompleted: key == 'gigsCompleted' ? value : gigsCompleted,
      active: key == 'active' ? value : active,
    );
  }

  double operator [](String key) => switch (key) {
        'followers' => followers,
        'engagementRate' => engagementRate,
        'platform' => platform,
        'audienceQuality' => audienceQuality,
        'ticketsSold' => ticketsSold,
        'contentApprovalRate' => contentApprovalRate,
        'gigsCompleted' => gigsCompleted,
        'active' => active,
        _ => throw ArgumentError('Unknown weight key: $key'),
      };

  Map<String, dynamic> toJson() => {
        'followers': followers,
        'engagementRate': engagementRate,
        'platform': platform,
        'audienceQuality': audienceQuality,
        'ticketsSold': ticketsSold,
        'contentApprovalRate': contentApprovalRate,
        'gigsCompleted': gigsCompleted,
        'active': active,
      };

  factory ScoringWeights.fromJson(Map<String, dynamic> json) => ScoringWeights(
        followers: (json['followers'] as num?)?.toDouble() ?? baseWeights.followers,
        engagementRate: (json['engagementRate'] as num?)?.toDouble() ?? baseWeights.engagementRate,
        platform: (json['platform'] as num?)?.toDouble() ?? baseWeights.platform,
        audienceQuality: (json['audienceQuality'] as num?)?.toDouble() ?? baseWeights.audienceQuality,
        ticketsSold: (json['ticketsSold'] as num?)?.toDouble() ?? baseWeights.ticketsSold,
        contentApprovalRate: (json['contentApprovalRate'] as num?)?.toDouble() ?? baseWeights.contentApprovalRate,
        gigsCompleted: (json['gigsCompleted'] as num?)?.toDouble() ?? baseWeights.gigsCompleted,
        active: (json['active'] as num?)?.toDouble() ?? baseWeights.active,
      );
}

/// The point ceilings the band tables above are expressed against - never
/// change these, only a `ScoringWeights` instance passed into computeScore.
const ScoringWeights baseWeights = ScoringWeights(
  followers: 20,
  engagementRate: 18,
  platform: 12,
  audienceQuality: 10,
  ticketsSold: 15,
  contentApprovalRate: 10,
  gigsCompleted: 9,
  active: 6,
);

const ScoringWeights defaultScoringWeights = baseWeights;

double _rescale(double earnedAtBase, double baseMax, double weight) {
  if (baseMax <= 0) return 0;
  return ((earnedAtBase / baseMax) * weight * 10).round() / 10;
}

ScoreBreakdown computeScore(
  InsightsInfo insights,
  SkillboxPerformance performance, {
  List<TierBand> tierBands = defaultTierBands,
  ScoringWeights weights = defaultScoringWeights,
}) {
  final followers = _scoreFromBands(insights.followers, _followerBands);
  final engagement = _scoreFromBands(insights.engagementRate, _engagementBands);
  final contentFormatScore =
      insights.contentFormat != null ? _contentFormatScore[insights.contentFormat]! : 0.0;
  final audienceScoreAtBase = ((insights.audienceIndiaPercent.clamp(0, 100) / 100) * 10 * 10).round() / 10;

  final platformMetrics = [
    ScoreBreakdownItem(
      label: 'Followers',
      detail: '(${followers.label})',
      earned: _rescale(followers.earned, baseWeights.followers, weights.followers),
      max: weights.followers,
    ),
    ScoreBreakdownItem(
      label: 'Engagement rate',
      detail: '(${insights.engagementRate.toStringAsFixed(1)}%)',
      earned: _rescale(engagement.earned, baseWeights.engagementRate, weights.engagementRate),
      max: weights.engagementRate,
    ),
    ScoreBreakdownItem(
      label: 'Platform',
      detail: insights.contentFormat != null ? '(${insights.contentFormat!.label})' : '(not set)',
      earned: _rescale(contentFormatScore, baseWeights.platform, weights.platform),
      max: weights.platform,
    ),
    ScoreBreakdownItem(
      label: 'Audience quality',
      detail: '(India ${insights.audienceIndiaPercent}%)',
      earned: _rescale(audienceScoreAtBase, baseWeights.audienceQuality, weights.audienceQuality),
      max: weights.audienceQuality,
    ),
  ];

  final ticketsSoldAtBase = (((performance.ticketsSold / 50).clamp(0, 1) * 15) * 10).round() / 10;
  final approvalAtBase = ((performance.contentApprovalRate / 100) * 10 * 10).round() / 10;
  final gigsCompletedAtBase = (((performance.gigsCompleted / 12).clamp(0, 1) * 9) * 10).round() / 10;
  final activeAtBase = performance.activeLast60Days ? 6.0 : 0.0;

  final skillboxPerformance = [
    ScoreBreakdownItem(
      label: 'Tickets sold',
      detail: '',
      earned: _rescale(ticketsSoldAtBase, baseWeights.ticketsSold, weights.ticketsSold),
      max: weights.ticketsSold,
    ),
    ScoreBreakdownItem(
      label: 'Content approval rate',
      detail: '',
      earned: _rescale(approvalAtBase, baseWeights.contentApprovalRate, weights.contentApprovalRate),
      max: weights.contentApprovalRate,
    ),
    ScoreBreakdownItem(
      label: 'Gigs completed',
      detail: '',
      earned: _rescale(gigsCompletedAtBase, baseWeights.gigsCompleted, weights.gigsCompleted),
      max: weights.gigsCompleted,
    ),
    ScoreBreakdownItem(
      label: 'Active in last 60 days',
      detail: '',
      earned: _rescale(activeAtBase, baseWeights.active, weights.active),
      max: weights.active,
    ),
  ];

  final total = [...platformMetrics, ...skillboxPerformance].fold<double>(0, (sum, item) => sum + item.earned).round();

  return ScoreBreakdown(
    total: total,
    tier: tierForScore(total, tierBands: tierBands),
    platformMetrics: platformMetrics,
    skillboxPerformance: skillboxPerformance,
  );
}

Tier tierForScore(int score, {List<TierBand> tierBands = defaultTierBands}) {
  final band = tierBands.where((b) => score >= b.min && score <= b.max).firstOrNull;
  return band?.tier ?? tierBands.first.tier;
}

const List<Tier> tierOrder = [Tier.bronze, Tier.silver, Tier.gold, Tier.platinum];

bool tierMeetsMinimum(Tier userTier, Tier minTier) => tierOrder.indexOf(userTier) >= tierOrder.indexOf(minTier);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
