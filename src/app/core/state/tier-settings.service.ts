import { Injectable, effect, signal } from "@angular/core";
import { DEFAULT_TIER_BANDS, type TierBand } from "../lib/scoring";

const STORAGE_KEY = "skillbox.affiliate.tier-settings.v1";

function loadInitial(): TierBand[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : structuredClone(DEFAULT_TIER_BANDS);
  } catch {
    return structuredClone(DEFAULT_TIER_BANDS);
  }
}

/**
 * Admin-editable tier score cutoffs + display payout ranges. Real backend
 * equivalent would be a `tier_settings` table (or just config) the reviewer
 * dashboard writes to and AffiliateScoringService reads at score time -
 * see docs/api-spec.md.
 */
@Injectable({ providedIn: "root" })
export class TierSettingsService {
  private readonly state = signal<TierBand[]>(loadInitial());

  readonly tierBands = this.state.asReadonly();

  constructor() {
    effect(() => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state()));
    });

    window.addEventListener("storage", (event) => {
      if (event.key === STORAGE_KEY && event.newValue) {
        this.state.set(JSON.parse(event.newValue));
      }
    });
  }

  updateBand(tier: TierBand["tier"], patch: Partial<Pick<TierBand, "min" | "max" | "payout">>) {
    this.state.update((prev) => prev.map((b) => (b.tier === tier ? { ...b, ...patch } : b)));
  }

  resetToDefaults() {
    this.state.set(structuredClone(DEFAULT_TIER_BANDS));
  }
}
