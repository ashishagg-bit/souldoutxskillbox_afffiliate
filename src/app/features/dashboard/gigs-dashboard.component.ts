import { Component, computed, inject, signal } from "@angular/core";
import { PhoneShellComponent } from "../../shared/phone-shell/phone-shell.component";
import { ApplicationStateService } from "../../core/state/application-state.service";
import { GigsService } from "../../core/data/gigs.service";
import { tierMeetsMinimum } from "../../core/lib/scoring";
import { TIER_STYLES } from "../../core/lib/tier-style";
import { mockLinkStats, referralLink } from "../../core/lib/referral";
import type { AppliedGig, Gig, GigApplicationStatus, GigType } from "../../core/lib/types";

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

  readonly profileApproved = computed(() => this.appState.application().status === "approved");

  readonly filteredGigs = computed(() => {
    const f = this.filter();
    return f === "All" ? this.allGigs : this.allGigs.filter((g) => g.type === f);
  });

  readonly myGigs = computed<Gig[]>(() => {
    const appliedIds = this.appState.application().appliedGigs.map((a) => a.gigId);
    return this.allGigs.filter((g) => appliedIds.includes(g.id));
  });

  setTab(tab: DashboardTab) {
    this.tab.set(tab);
  }

  setFilter(filter: GigFilter) {
    this.filter.set(filter);
  }

  isEligible(gig: Gig): boolean {
    return this.profileApproved() && tierMeetsMinimum(this.appState.score().tier, gig.minTier);
  }

  private appliedGigRecord(gigId: string): AppliedGig | undefined {
    return this.appState.application().appliedGigs.find((a) => a.gigId === gigId);
  }

  hasApplied(gig: Gig): boolean {
    return !!this.appliedGigRecord(gig.id);
  }

  gigStatus(gig: Gig): GigApplicationStatus | null {
    return this.appliedGigRecord(gig.id)?.status ?? null;
  }

  apply(gig: Gig) {
    if (this.isEligible(gig) && !this.hasApplied(gig)) {
      this.appState.applyToGig(gig.id);
    }
  }

  referralUrl(gig: Gig): string | null {
    const code = this.appliedGigRecord(gig.id)?.referralCode;
    return code ? referralLink(code) : null;
  }

  linkStats(gig: Gig) {
    const code = this.appliedGigRecord(gig.id)?.referralCode;
    return code ? mockLinkStats(code, gig.ticketPrice, gig.commissionRate) : null;
  }

  formatPayout(gig: Gig): string {
    const fmt = (n: number) => `₹${n.toLocaleString("en-IN")}`;
    return gig.payoutMin === gig.payoutMax ? fmt(gig.payoutMin) : `${fmt(gig.payoutMin)}–${fmt(gig.payoutMax)}`;
  }

  formatCurrency(n: number): string {
    return `₹${n.toLocaleString("en-IN")}`;
  }

  readonly copiedGigId = signal<string | null>(null);

  copyLink(gig: Gig) {
    const url = this.referralUrl(gig);
    if (!url) return;
    navigator.clipboard?.writeText(url);
    this.copiedGigId.set(gig.id);
    setTimeout(() => {
      if (this.copiedGigId() === gig.id) this.copiedGigId.set(null);
    }, 1500);
  }
}
