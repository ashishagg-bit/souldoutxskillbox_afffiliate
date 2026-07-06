import { Component, inject } from "@angular/core";
import { TierSettingsService } from "../../core/state/tier-settings.service";
import type { Tier } from "../../core/lib/types";

@Component({
  selector: "app-admin-settings",
  standalone: true,
  templateUrl: "./admin-settings.component.html",
})
export class AdminSettingsComponent {
  readonly tierSettings = inject(TierSettingsService);

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
}
