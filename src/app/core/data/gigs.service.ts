import { Injectable } from "@angular/core";
import { GIGS } from "./gigs";
import type { Gig } from "../lib/types";

@Injectable({ providedIn: "root" })
export class GigsService {
  getAll(): Gig[] {
    return GIGS;
  }

  getById(id: string): Gig | undefined {
    return GIGS.find((g) => g.id === id);
  }
}
