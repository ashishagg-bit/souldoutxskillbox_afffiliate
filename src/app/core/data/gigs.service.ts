import { Injectable, effect, signal } from "@angular/core";
import { GIGS as SEED_GIGS } from "./gigs";
import type { Gig } from "../lib/types";

const STORAGE_KEY = "skillbox.affiliate.gigs.v1";

function loadInitial(): Gig[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : structuredClone(SEED_GIGS);
  } catch {
    return structuredClone(SEED_GIGS);
  }
}

function slugify(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

/**
 * Shows (gigs) available in the marketplace. Reactive + localStorage-backed
 * so the admin panel's "Shows" tab can create/edit/delete them, standing in
 * for `gigs` CRUD endpoints against the real backend (see docs/api-spec.md).
 */
@Injectable({ providedIn: "root" })
export class GigsService {
  private readonly state = signal<Gig[]>(loadInitial());

  readonly gigs = this.state.asReadonly();

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

  getAll(): Gig[] {
    return this.state();
  }

  getById(id: string): Gig | undefined {
    return this.state().find((g) => g.id === id);
  }

  addGig(gig: Omit<Gig, "id">): Gig {
    const base = slugify(gig.title) || "show";
    let id = base;
    let n = 2;
    while (this.state().some((g) => g.id === id)) {
      id = `${base}-${n++}`;
    }
    const created: Gig = { ...gig, id };
    this.state.update((prev) => [...prev, created]);
    return created;
  }

  updateGig(id: string, patch: Partial<Omit<Gig, "id">>) {
    this.state.update((prev) => prev.map((g) => (g.id === id ? { ...g, ...patch } : g)));
  }

  deleteGig(id: string) {
    this.state.update((prev) => prev.filter((g) => g.id !== id));
  }

  resetToSeed() {
    this.state.set(structuredClone(SEED_GIGS));
  }
}
