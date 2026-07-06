import type { Tier } from "./types";

export const TIER_STYLES: Record<Tier, { bg: string; text: string; solid: string }> = {
  Bronze: { bg: "bg-orange-50", text: "text-orange-700", solid: "bg-orange-700" },
  Silver: { bg: "bg-rose-50", text: "text-rose-800", solid: "bg-rose-900" },
  Gold: { bg: "bg-amber-50", text: "text-amber-700", solid: "bg-amber-600" },
  Platinum: { bg: "bg-slate-100", text: "text-slate-700", solid: "bg-slate-800" },
};
