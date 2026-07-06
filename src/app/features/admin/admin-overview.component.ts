import { Component, computed, inject } from "@angular/core";
import { ApplicationStateService } from "../../core/state/application-state.service";
import { GigsService } from "../../core/data/gigs.service";
import { mockLinkStats } from "../../core/lib/referral";

@Component({
  selector: "app-admin-overview",
  standalone: true,
  templateUrl: "./admin-overview.component.html",
})
export class AdminOverviewComponent {
  private readonly appState = inject(ApplicationStateService);
  private readonly gigsService = inject(GigsService);

  readonly profileStatus = computed(() => this.appState.application().status);

  readonly pendingShowRequests = computed(
    () => this.appState.application().appliedGigs.filter((a) => a.status === "pending").length,
  );

  readonly approvedLinks = computed(() =>
    this.appState.application().appliedGigs.filter((a) => a.status === "approved" && a.referralCode),
  );

  readonly totalShows = computed(() => this.gigsService.gigs().length);

  readonly aggregateStats = computed(() => {
    const rows = this.approvedLinks();
    let clicks = 0;
    let ticketsSold = 0;
    let commission = 0;
    for (const row of rows) {
      const gig = this.gigsService.getById(row.gigId);
      if (!gig || !row.referralCode) continue;
      const stats = mockLinkStats(row.referralCode, gig.ticketPrice, gig.commissionRate);
      clicks += stats.clicks;
      ticketsSold += stats.ticketsSold;
      commission += stats.commissionEarned;
    }
    return { clicks, ticketsSold, commission };
  });

  formatCurrency(n: number): string {
    return `₹${n.toLocaleString("en-IN")}`;
  }
}
