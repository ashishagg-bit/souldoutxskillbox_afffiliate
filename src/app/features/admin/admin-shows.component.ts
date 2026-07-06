import { Component, inject, signal } from "@angular/core";
import { GigsService } from "../../core/data/gigs.service";
import type { Gig, GigType, Tier } from "../../core/lib/types";

const GIG_TYPES: GigType[] = ["Story coverage", "Attendance", "UGC", "Brand campaign"];
const TIERS: Tier[] = ["Bronze", "Silver", "Gold", "Platinum"];

type DraftGig = Omit<Gig, "id">;

function emptyDraft(): DraftGig {
  return {
    type: "Story coverage",
    minTier: "Bronze",
    minScore: 0,
    title: "",
    location: "",
    date: "",
    spotsLeft: undefined,
    deliverable: "",
    payoutMin: 0,
    payoutMax: 0,
    ticketPrice: undefined,
    commissionRate: undefined,
  };
}

@Component({
  selector: "app-admin-shows",
  standalone: true,
  templateUrl: "./admin-shows.component.html",
})
export class AdminShowsComponent {
  readonly gigsService = inject(GigsService);

  readonly gigTypes = GIG_TYPES;
  readonly tiers = TIERS;

  readonly formOpen = signal(false);
  readonly editingId = signal<string | null>(null);
  readonly draft = signal<DraftGig>(emptyDraft());

  startCreate() {
    this.editingId.set(null);
    this.draft.set(emptyDraft());
    this.formOpen.set(true);
  }

  startEdit(gig: Gig) {
    this.editingId.set(gig.id);
    const { id, ...rest } = gig;
    this.draft.set({ ...rest });
    this.formOpen.set(true);
  }

  cancel() {
    this.formOpen.set(false);
    this.editingId.set(null);
  }

  updateDraft(patch: Partial<DraftGig>) {
    this.draft.update((prev) => ({ ...prev, ...patch }));
  }

  toNumber(value: string): number {
    return Number(value) || 0;
  }

  save() {
    const d = this.draft();
    if (!d.title.trim() || d.payoutMax < d.payoutMin) return;

    const cleaned: DraftGig = {
      ...d,
      location: d.location?.trim() || undefined,
      date: d.date?.trim() || undefined,
      deliverable: d.deliverable?.trim() || undefined,
      spotsLeft: d.spotsLeft || undefined,
      ticketPrice: d.ticketPrice || undefined,
      commissionRate: d.commissionRate || undefined,
    };

    const editing = this.editingId();
    if (editing) {
      this.gigsService.updateGig(editing, cleaned);
    } else {
      this.gigsService.addGig(cleaned);
    }
    this.cancel();
  }

  remove(gig: Gig) {
    if (confirm(`Remove "${gig.title}" from the marketplace?`)) {
      this.gigsService.deleteGig(gig.id);
    }
  }

  formatPayout(gig: Gig): string {
    const fmt = (n: number) => `₹${n.toLocaleString("en-IN")}`;
    return gig.payoutMin === gig.payoutMax ? fmt(gig.payoutMin) : `${fmt(gig.payoutMin)}–${fmt(gig.payoutMax)}`;
  }
}
