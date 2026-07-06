import { Component, computed, inject, signal } from "@angular/core";
import { PhoneShellComponent } from "../../shared/phone-shell/phone-shell.component";
import { ApplicationStateService } from "../../core/state/application-state.service";
import { GigsService } from "../../core/data/gigs.service";
import { tierMeetsMinimum } from "../../core/lib/scoring";
import { TIER_STYLES } from "../../core/lib/tier-style";
import type { Gig, GigType } from "../../core/lib/types";

type DashboardTab = "score" | "available" | "my-gigs";
type GigFilter = "All" | GigType;

@Component({
  selector: "app-gigs-dashboard",
  standalone: true,
  imports: [PhoneShellComponent],
  templateUrl: "./gigs-dashboard.component.html",
})
export class GigsDashboardComponent {
  readonly appState = inject(ApplicationStateService);
  private readonly gigsService = inject(GigsService);

  readonly tab = signal<DashboardTab>("score");
  readonly filter = signal<GigFilter>("All");
  readonly tierStyles = TIER_STYLES;
  readonly gigFilters: GigFilter[] = ["All", "Story coverage", "Attendance", "UGC", "Brand campaign"];

  private readonly allGigs = this.gigsService.getAll();

  readonly filteredGigs = computed(() => {
    const f = this.filter();
    return f === "All" ? this.allGigs : this.allGigs.filter((g) => g.type === f);
  });

  readonly myGigs = computed<Gig[]>(() => {
    const applied = this.appState.application().appliedGigs.map((a) => a.gigId);
    return this.allGigs.filter((g) => applied.includes(g.id));
  });

  setTab(tab: DashboardTab) {
    this.tab.set(tab);
  }

  setFilter(filter: GigFilter) {
    this.filter.set(filter);
  }

  isEligible(gig: Gig): boolean {
    return tierMeetsMinimum(this.appState.score().tier, gig.minTier);
  }

  hasApplied(gig: Gig): boolean {
    return this.appState.application().appliedGigs.some((a) => a.gigId === gig.id);
  }

  apply(gig: Gig) {
    if (this.isEligible(gig) && !this.hasApplied(gig)) {
      this.appState.applyToGig(gig.id);
    }
  }

  formatPayout(gig: Gig): string {
    const fmt = (n: number) => `₹${n.toLocaleString("en-IN")}`;
    return gig.payoutMin === gig.payoutMax ? fmt(gig.payoutMin) : `${fmt(gig.payoutMin)}–${fmt(gig.payoutMax)}`;
  }
}
