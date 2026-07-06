import { Component, computed, inject } from "@angular/core";
import { ApplicationStateService } from "../../core/state/application-state.service";
import { GigsService } from "../../core/data/gigs.service";
import { mockLinkStats, referralLink } from "../../core/lib/referral";
import type { Gig } from "../../core/lib/types";

interface LinkRow {
  creatorHandle: string;
  gig: Gig;
  referralCode: string;
  link: string;
  clicks: number;
  ticketsSold: number;
  commissionEarned: number;
}

@Component({
  selector: "app-admin-analytics",
  standalone: true,
  templateUrl: "./admin-analytics.component.html",
})
export class AdminAnalyticsComponent {
  private readonly appState = inject(ApplicationStateService);
  private readonly gigsService = inject(GigsService);

  readonly rows = computed<LinkRow[]>(() => {
    const app = this.appState.application();
    return app.appliedGigs
      .filter((a) => a.status === "approved" && a.referralCode)
      .map((a): LinkRow | null => {
        const gig = this.gigsService.getById(a.gigId);
        if (!gig || !a.referralCode) return null;
        const stats = mockLinkStats(a.referralCode, gig.ticketPrice, gig.commissionRate);
        return {
          creatorHandle: app.socials.instagramHandle,
          gig,
          referralCode: a.referralCode,
          link: referralLink(a.referralCode),
          ...stats,
        };
      })
      .filter((r): r is LinkRow => r !== null);
  });

  readonly totals = computed(() => {
    const rows = this.rows();
    return {
      clicks: rows.reduce((sum, r) => sum + r.clicks, 0),
      ticketsSold: rows.reduce((sum, r) => sum + r.ticketsSold, 0),
      commission: rows.reduce((sum, r) => sum + r.commissionEarned, 0),
    };
  });

  formatCurrency(n: number): string {
    return `₹${n.toLocaleString("en-IN")}`;
  }
}
