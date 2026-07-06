import type {
  ContentFormat,
  InsightsInfo,
  ScoreBreakdown,
  ScoreBreakdownItem,
  SkillboxPerformance,
  Tier,
} from "./types";

interface Band {
  label: string;
  min: number;
  max: number; // exclusive upper bound, Infinity for last band
  scoreMin: number;
  scoreMax: number;
}

function scoreFromBands(value: number, bands: Band[]): { earned: number; label: string } {
  const band = bands.find((b) => value >= b.min && value < b.max) ?? bands[bands.length - 1];
  const span = band.max === Infinity ? band.min * 2 : band.max - band.min;
  const progress = band.max === Infinity ? 1 : Math.min(1, Math.max(0, (value - band.min) / span));
  const earned = band.scoreMin + progress * (band.scoreMax - band.scoreMin);
  return { earned: Math.round(earned * 10) / 10, label: band.label };
}

const FOLLOWER_BANDS: Band[] = [
  { label: "0-5k", min: 0, max: 5_000, scoreMin: 0, scoreMax: 4 },
  { label: "5k-20k", min: 5_000, max: 20_000, scoreMin: 4, scoreMax: 8 },
  { label: "20k-50k", min: 20_000, max: 50_000, scoreMin: 8, scoreMax: 12 },
  { label: "50k-200k", min: 50_000, max: 200_000, scoreMin: 12, scoreMax: 16 },
  { label: "200k-500k", min: 200_000, max: 500_000, scoreMin: 16, scoreMax: 18 },
  { label: "500k+", min: 500_000, max: Infinity, scoreMin: 18, scoreMax: 20 },
];

const ENGAGEMENT_BANDS: Band[] = [
  { label: "<1%", min: 0, max: 1, scoreMin: 0, scoreMax: 6 },
  { label: "1-3%", min: 1, max: 3, scoreMin: 6, scoreMax: 12 },
  { label: "3-6%", min: 3, max: 6, scoreMin: 12, scoreMax: 16 },
  { label: "6%+", min: 6, max: Infinity, scoreMin: 16, scoreMax: 18 },
];

const CONTENT_FORMAT_SCORE: Record<ContentFormat, number> = {
  "Reels / Short video": 12,
  "Long-form video": 10,
  "Photos / Carousel": 8,
  "Stories only": 6,
};

export interface TierBand {
  tier: Tier;
  min: number;
  max: number;
  payout: string;
}

export const DEFAULT_TIER_BANDS: TierBand[] = [
  { tier: "Bronze", min: 0, max: 39, payout: "₹2k–₹8k / gig" },
  { tier: "Silver", min: 40, max: 59, payout: "₹5k–₹25k / gig" },
  { tier: "Gold", min: 60, max: 79, payout: "₹12k–₹75k / gig" },
  { tier: "Platinum", min: 80, max: 100, payout: "₹30k–₹3L / gig" },
];

export function computeScore(
  insights: InsightsInfo,
  performance: SkillboxPerformance,
  tierBands: TierBand[] = DEFAULT_TIER_BANDS,
): ScoreBreakdown {
  const followers = scoreFromBands(insights.followers, FOLLOWER_BANDS);
  const engagement = scoreFromBands(insights.engagementRate, ENGAGEMENT_BANDS);
  const contentFormatScore = insights.contentFormat ? CONTENT_FORMAT_SCORE[insights.contentFormat] : 0;
  const audienceScore = Math.round((Math.min(100, insights.audienceIndiaPercent) / 100) * 10 * 10) / 10;

  const platformMetrics: ScoreBreakdownItem[] = [
    {
      label: "Followers",
      detail: `(${followers.label})`,
      earned: followers.earned,
      max: 20,
    },
    {
      label: "Engagement rate",
      detail: `(${insights.engagementRate.toFixed(1)}%)`,
      earned: engagement.earned,
      max: 18,
    },
    {
      label: "Platform",
      detail: insights.contentFormat ? `(${insights.contentFormat})` : "(not set)",
      earned: contentFormatScore,
      max: 12,
    },
    {
      label: "Audience quality",
      detail: `(India ${insights.audienceIndiaPercent}%)`,
      earned: audienceScore,
      max: 10,
    },
  ];

  const ticketsSoldScore = Math.round(Math.min(15, (performance.ticketsSold / 50) * 15) * 10) / 10;
  const approvalScore = Math.round((performance.contentApprovalRate / 100) * 10 * 10) / 10;
  const gigsCompletedScore = Math.round(Math.min(9, (performance.gigsCompleted / 12) * 9) * 10) / 10;
  const activeScore = performance.activeLast60Days ? 6 : 0;

  const skillboxPerformance: ScoreBreakdownItem[] = [
    { label: "Tickets sold", detail: "", earned: ticketsSoldScore, max: 15 },
    { label: "Content approval rate", detail: "", earned: approvalScore, max: 10 },
    { label: "Gigs completed", detail: "", earned: gigsCompletedScore, max: 9 },
    { label: "Active in last 60 days", detail: "", earned: activeScore, max: 6 },
  ];

  const total = Math.round(
    [...platformMetrics, ...skillboxPerformance].reduce((sum, item) => sum + item.earned, 0),
  );

  return {
    total,
    tier: tierForScore(total, tierBands),
    platformMetrics,
    skillboxPerformance,
  };
}

export function tierForScore(score: number, tierBands: TierBand[] = DEFAULT_TIER_BANDS): Tier {
  const band = tierBands.find((b) => score >= b.min && score <= b.max);
  return band?.tier ?? tierBands[0].tier;
}

export const TIER_ORDER: Tier[] = ["Bronze", "Silver", "Gold", "Platinum"];

export function tierMeetsMinimum(userTier: Tier, minTier: Tier): boolean {
  return TIER_ORDER.indexOf(userTier) >= TIER_ORDER.indexOf(minTier);
}
