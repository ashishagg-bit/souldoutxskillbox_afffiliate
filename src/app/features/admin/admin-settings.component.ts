import { Component, inject } from "@angular/core";
import { TierSettingsService } from "../../core/state/tier-settings.service";
import { ScoringWeightsService } from "../../core/state/scoring-weights.service";
import type { ScoringWeights } from "../../core/lib/scoring";
import type { Tier } from "../../core/lib/types";

const WEIGHT_LABELS: { key: keyof ScoringWeights; label: string; group: "Platform Metrics" | "Skillbox Performance" }[] = [
  { key: "followers", label: "Followers", group: "Platform Metrics" },
  { key: "engagementRate", label: "Engagement rate", group: "Platform Metrics" },
  { key: "platform", label: "Platform (content format)", group: "Platform Metrics" },
  { key: "audienceQuality", label: "Audience quality", group: "Platform Metrics" },
  { key: "ticketsSold", label: "Tickets sold", group: "Skillbox Performance" },
  { key: "contentApprovalRate", label: "Content approval rate", group: "Skillbox Performance" },
  { key: "gigsCompleted", label: "Gigs completed", group: "Skillbox Performance" },
  { key: "active", label: "Active in last 60 days", group: "Skillbox Performance" },
];

@Component({
  selector: "app-admin-settings",
  standalone: true,
  templateUrl: "./admin-settings.component.html",
})
export class AdminSettingsComponent {
  readonly tierSettings = inject(TierSettingsService);
  readonly scoringWeights = inject(ScoringWeightsService);
  readonly weightLabels = WEIGHT_LABELS;

  updateMin(tier: Tier, value: string) {
    this.tierSettings.updateBand(tier, { min: Number(value) || 0 });
  }

  updateMax(tier: Tier, value: string) {
    this.tierSettings.updateBand(tier, { max: Number(value) || 0 });
  }

  updatePayout(tier: Tier, value: string) {
    this.tierSettings.updateBand(tier, { payout: value });
  }

  reset() {
    if (confirm("Reset tier thresholds and payout ranges to defaults?")) {
      this.tierSettings.resetToDefaults();
    }
  }

  updateWeight(key: keyof ScoringWeights, value: string) {
    this.scoringWeights.updateWeight(key, Number(value) || 0);
  }

  resetWeights() {
    if (confirm("Reset scoring weights to defaults (60/40 platform/performance split)?")) {
      this.scoringWeights.resetToDefaults();
    }
  }

  get totalPoints(): number {
    const w = this.scoringWeights.weights();
    return Object.values(w).reduce((sum, v) => sum + v, 0);
  }

  get platformTotal(): number {
    const w = this.scoringWeights.weights();
    return w.followers + w.engagementRate + w.platform + w.audienceQuality;
  }

  get performanceTotal(): number {
    const w = this.scoringWeights.weights();
    return w.ticketsSold + w.contentApprovalRate + w.gigsCompleted + w.active;
  }
}
