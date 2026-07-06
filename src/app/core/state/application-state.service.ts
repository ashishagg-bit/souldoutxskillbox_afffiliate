import { Injectable, computed, effect, signal } from "@angular/core";
import { computeScore } from "../lib/scoring";
import { generateReferralCode } from "../lib/referral";
import type {
  AffiliateApplication,
  City,
  ContentFormat,
  Niche,
  Platform,
  ScoreBreakdown,
} from "../lib/types";

const STORAGE_KEY = "skillbox.affiliate.application.v2";

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
 *
 * There's only ever one applicant in this local store (no real accounts yet),
 * so the "admin" review screen reads and mutates this same state - it's
 * standing in for what would be a separate reviewer looking at a queue of
 * many applicants' rows in the real backend.
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

    // Cross-tab sync for this demo's local store: the "storage" event only fires in
    // OTHER tabs than the one that wrote the change, so an admin approving in one tab
    // reflects live in a creator tab open on the same browser, without a reload.
    // A real backend would replace this with polling/websockets against the API.
    window.addEventListener("storage", (event) => {
      if (event.key === STORAGE_KEY && event.newValue) {
        this.state.set({ ...structuredClone(EMPTY_APPLICATION), ...JSON.parse(event.newValue) });
      }
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

  /** Creator action: step-4 "Submit application" - profile now awaits Skillbox review. */
  submitApplication() {
    const now = new Date().toISOString();
    this.state.update((prev) => ({ ...prev, status: "under_review", submittedAt: now, scoredAt: null }));
  }

  /** Admin action: reviewer confirms the AI-derived tier is right and unlocks the marketplace. */
  approveApplication() {
    this.state.update((prev) => ({ ...prev, status: "approved", scoredAt: new Date().toISOString() }));
  }

  /** Admin action: reviewer rejects the profile (bad-fit audience, fake followers, etc). */
  rejectApplication() {
    this.state.update((prev) => ({ ...prev, status: "rejected", scoredAt: new Date().toISOString() }));
  }

  /** Creator action: apply to promote a specific show - starts pending, not yet approved. */
  applyToGig(gigId: string) {
    this.state.update((prev) => {
      if (prev.appliedGigs.some((g) => g.gigId === gigId)) return prev;
      const applied: AffiliateApplication["appliedGigs"][number] = {
        gigId,
        appliedAt: new Date().toISOString(),
        status: "pending",
        reviewedAt: null,
        referralCode: null,
      };
      return { ...prev, appliedGigs: [...prev.appliedGigs, applied] };
    });
  }

  /** Admin action: approves a creator to promote this show and issues their unique tracking link. */
  approveGigApplication(gigId: string) {
    this.state.update((prev) => ({
      ...prev,
      appliedGigs: prev.appliedGigs.map((g) =>
        g.gigId === gigId
          ? {
              ...g,
              status: "approved",
              reviewedAt: new Date().toISOString(),
              referralCode: generateReferralCode(prev.socials.instagramHandle, gigId),
            }
          : g,
      ),
    }));
  }

  /** Admin action: rejects a creator's request to promote this specific show. */
  rejectGigApplication(gigId: string) {
    this.state.update((prev) => ({
      ...prev,
      appliedGigs: prev.appliedGigs.map((g) =>
        g.gigId === gigId ? { ...g, status: "rejected", reviewedAt: new Date().toISOString() } : g,
      ),
    }));
  }

  resetApplication() {
    this.state.set(structuredClone(EMPTY_APPLICATION));
  }
}
