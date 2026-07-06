import { Injectable, effect, signal } from "@angular/core";
import { DEFAULT_SCORING_WEIGHTS, type ScoringWeights } from "../lib/scoring";

const STORAGE_KEY = "skillbox.affiliate.scoring-weights.v1";

function loadInitial(): ScoringWeights {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? { ...DEFAULT_SCORING_WEIGHTS, ...JSON.parse(raw) } : { ...DEFAULT_SCORING_WEIGHTS };
  } catch {
    return { ...DEFAULT_SCORING_WEIGHTS };
  }
}

/**
 * Admin-editable point weight (ceiling) for each of the 8 scoring metrics.
 * Band *shapes* (e.g. which follower count lands in which bracket) stay
 * fixed in scoring.ts - only how many points that bracket is worth is
 * configurable here. Real backend equivalent: a `scoring_weights` table/
 * config AffiliateScoringService reads at score time - see docs/api-spec.md.
 */
@Injectable({ providedIn: "root" })
export class ScoringWeightsService {
  private readonly state = signal<ScoringWeights>(loadInitial());

  readonly weights = this.state.asReadonly();

  constructor() {
    effect(() => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state()));
    });

    window.addEventListener("storage", (event) => {
      if (event.key === STORAGE_KEY && event.newValue) {
        this.state.set({ ...DEFAULT_SCORING_WEIGHTS, ...JSON.parse(event.newValue) });
      }
    });
  }

  updateWeight(key: keyof ScoringWeights, value: number) {
    this.state.update((prev) => ({ ...prev, [key]: Math.max(0, value) }));
  }

  resetToDefaults() {
    this.state.set({ ...DEFAULT_SCORING_WEIGHTS });
  }
}
