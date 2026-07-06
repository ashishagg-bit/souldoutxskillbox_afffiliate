/**
 * Referral code + link generation, and deterministic mock click/conversion
 * stats so the "My Gigs" screen has something to show without a real
 * click-tracking backend. See docs/api-spec.md for the real design
 * (a redirect/attribution service tied to actual ticket checkout).
 */

function hashString(input: string): number {
  let hash = 0;
  for (let i = 0; i < input.length; i++) {
    hash = (hash << 5) - hash + input.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
}

export function generateReferralCode(instagramHandle: string, gigId: string): string {
  const handlePart = instagramHandle.toLowerCase().replace(/[^a-z0-9]/g, "").slice(0, 12) || "creator";
  const suffix = hashString(`${instagramHandle}:${gigId}`).toString(36).slice(0, 5);
  return `${handlePart}-${suffix}`;
}

export function referralLink(referralCode: string): string {
  return `https://slb.link/${referralCode}`;
}

export interface MockLinkStats {
  clicks: number;
  ticketsSold: number;
  commissionEarned: number;
}

/**
 * Stable pseudo-random stats derived from the referral code, so the same
 * link always shows the same numbers across reloads (no backend to persist
 * real clicks yet). Only meaningful for gigs with ticketPrice/commissionRate set.
 */
export function mockLinkStats(referralCode: string, ticketPrice?: number, commissionRate?: number): MockLinkStats {
  const seed = hashString(referralCode);
  const clicks = 40 + (seed % 260);
  const conversionRate = 0.03 + ((seed >> 4) % 12) / 100; // ~3%-15%
  const ticketsSold = Math.round(clicks * conversionRate);
  const commissionEarned =
    ticketPrice && commissionRate ? Math.round(ticketsSold * ticketPrice * (commissionRate / 100)) : 0;
  return { clicks, ticketsSold, commissionEarned };
}
