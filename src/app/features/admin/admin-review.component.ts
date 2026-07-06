import { Component, computed, inject } from "@angular/core";
import { DatePipe } from "@angular/common";
import { ApplicationStateService } from "../../core/state/application-state.service";
import { GigsService } from "../../core/data/gigs.service";
import { TIER_STYLES } from "../../core/lib/tier-style";
import type { AppliedGig, Gig } from "../../core/lib/types";

/**
 * Reviewer-facing screen: approve/reject the one profile in this local demo
 * store, and approve/reject its pending gig applications. In the real
 * product this is a queue of many applicants (see docs/api-spec.md for the
 * admin endpoints) - this stands in for that queue with a single row so the
 * approve/reject/link-issuance flow is demoable end-to-end without a
 * backend or a second user account.
 */
@Component({
  selector: "app-admin-review",
  standalone: true,
  imports: [DatePipe],
  templateUrl: "./admin-review.component.html",
})
export class AdminReviewComponent {
  readonly appState = inject(ApplicationStateService);
  private readonly gigsService = inject(GigsService);
  readonly tierStyles = TIER_STYLES;

  readonly pendingGigApplications = computed<{ gig: Gig; applied: AppliedGig }[]>(() =>
    this.appState
      .application()
      .appliedGigs.filter((a) => a.status === "pending")
      .map((applied) => ({ gig: this.gigsService.getById(applied.gigId)!, applied }))
      .filter((row) => !!row.gig),
  );

  readonly reviewedGigApplications = computed<{ gig: Gig; applied: AppliedGig }[]>(() =>
    this.appState
      .application()
      .appliedGigs.filter((a) => a.status !== "pending")
      .map((applied) => ({ gig: this.gigsService.getById(applied.gigId)!, applied }))
      .filter((row) => !!row.gig),
  );

  approveProfile() {
    this.appState.approveApplication();
  }

  rejectProfile() {
    this.appState.rejectApplication();
  }

  approveGig(gigId: string) {
    this.appState.approveGigApplication(gigId);
  }

  rejectGig(gigId: string) {
    this.appState.rejectGigApplication(gigId);
  }
}
