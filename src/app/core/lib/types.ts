export type Platform = "Instagram" | "YouTube" | "Snapchat" | "Twitter / X";

export type ContentFormat = "Reels / Short video" | "Photos / Carousel" | "Stories only" | "Long-form video";

export type City =
  | "Delhi"
  | "Mumbai"
  | "Bengaluru"
  | "Hyderabad"
  | "Pune"
  | "Goa"
  | "Chennai"
  | "Kolkata";

export type Niche =
  | "Nightlife"
  | "Music"
  | "Lifestyle"
  | "Food & Drink"
  | "Fashion"
  | "Travel";

export type Tier = "Bronze" | "Silver" | "Gold" | "Platinum";

export type ApplicationStatus = "not_applied" | "submitted" | "scored";

export interface SocialsInfo {
  instagramHandle: string;
  platforms: Platform[];
}

export interface LocationNicheInfo {
  city: City | null;
  niche: Niche | null;
}

export interface InsightsInfo {
  followers: number;
  engagementRate: number; // percent, e.g. 3.2
  contentFormat: ContentFormat | null;
  audienceIndiaPercent: number; // percent, e.g. 78
  screenshotFileName: string | null;
}

export interface SkillboxPerformance {
  ticketsSold: number;
  contentApprovalRate: number; // percent
  gigsCompleted: number;
  activeLast60Days: boolean;
}

export interface ScoreBreakdownItem {
  label: string;
  detail: string;
  earned: number;
  max: number;
}

export interface ScoreBreakdown {
  total: number;
  tier: Tier;
  platformMetrics: ScoreBreakdownItem[];
  skillboxPerformance: ScoreBreakdownItem[];
}

export type GigType = "Story coverage" | "Attendance" | "UGC" | "Brand campaign";

export interface Gig {
  id: string;
  type: GigType;
  minTier: Tier;
  minScore: number;
  title: string;
  location?: string;
  date?: string;
  spotsLeft?: number;
  deliverable?: string;
  payoutMin: number;
  payoutMax: number;
}

export interface AppliedGig {
  gigId: string;
  appliedAt: string;
}

export interface AffiliateApplication {
  status: ApplicationStatus;
  socials: SocialsInfo;
  locationNiche: LocationNicheInfo;
  insights: InsightsInfo;
  performance: SkillboxPerformance;
  submittedAt: string | null;
  scoredAt: string | null;
  appliedGigs: AppliedGig[];
}
