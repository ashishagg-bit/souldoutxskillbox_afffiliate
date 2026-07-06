import { Injectable, computed, effect, signal } from "@angular/core";
import { computeScore } from "../lib/scoring";
import type {
  AffiliateApplication,
  City,
  ContentFormat,
  Niche,
  Platform,
  ScoreBreakdown,
} from "../lib/types";

const STORAGE_KEY = "skillbox.affiliate.application.v1";

const EMPTY_APPLICATION: AffiliateApplication = {
  status: "not_applied",
  socials: { instagramHandle: "", platforms: [] },
  locationNiche: { city: null, niche: null },
  insights: {
    followers: 0,
    engagementRate: 0,
    contentFormat: null,
    audienceIndiaPercent: 70,
    screenshotFileName: null,
  },
  performance: {
    ticketsSold: 0,
    contentApprovalRate: 0,
    gigsCompleted: 0,
    activeLast60Days: true,
  },
  submittedAt: null,
  scoredAt: null,
  appliedGigs: [],
};

function loadInitial(): AffiliateApplication {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return structuredClone(EMPTY_APPLICATION);
    return { ...structuredClone(EMPTY_APPLICATION), ...JSON.parse(raw) };
  } catch {
    return structuredClone(EMPTY_APPLICATION);
  }
}

/**
 * Holds affiliate-application state client-side (localStorage) so the UI flow
 * is fully demoable without a backend. Every mutation here has a 1:1 candidate
 * Laravel endpoint documented in docs/api-spec.md - swap the bodies for HTTP
 * calls once that API exists, the component layer doesn't need to change.
 */
@Injectable({ providedIn: "root" })
export class ApplicationStateService {
  private readonly state = signal<AffiliateApplication>(loadInitial());

  readonly application = this.state.asReadonly();

  readonly score = computed<ScoreBreakdown>(() =>
    computeScore(this.state().insights, this.state().performance),
  );

  constructor() {
    effect(() => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state()));
    });
  }

  setInstagramHandle(handle: string) {
    this.state.update((prev) => ({ ...prev, socials: { ...prev.socials, instagramHandle: handle } }));
  }

  togglePlatform(platform: Platform) {
    this.state.update((prev) => {
      const has = prev.socials.platforms.includes(platform);
      const platforms = has
        ? prev.socials.platforms.filter((p) => p !== platform)
        : [...prev.socials.platforms, platform];
      return { ...prev, socials: { ...prev.socials, platforms } };
    });
  }

  setCity(city: City) {
    this.state.update((prev) => ({ ...prev, locationNiche: { ...prev.locationNiche, city } }));
  }

  setNiche(niche: Niche) {
    this.state.update((prev) => ({ ...prev, locationNiche: { ...prev.locationNiche, niche } }));
  }

  setInsights(patch: Partial<AffiliateApplication["insights"]>) {
    this.state.update((prev) => ({ ...prev, insights: { ...prev.insights, ...patch } }));
  }

  setContentFormat(format: ContentFormat) {
    this.state.update((prev) => ({ ...prev, insights: { ...prev.insights, contentFormat: format } }));
  }

  submitApplication() {
    const now = new Date().toISOString();
    this.state.update((prev) => ({ ...prev, status: "scored", submittedAt: now, scoredAt: now }));
  }

  applyToGig(gigId: string) {
    this.state.update((prev) => {
      if (prev.appliedGigs.some((g) => g.gigId === gigId)) return prev;
      return { ...prev, appliedGigs: [...prev.appliedGigs, { gigId, appliedAt: new Date().toISOString() }] };
    });
  }

  resetApplication() {
    this.state.set(structuredClone(EMPTY_APPLICATION));
  }
}
