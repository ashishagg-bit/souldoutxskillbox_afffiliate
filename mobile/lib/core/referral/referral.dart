/// Direct port of `core/lib/referral.ts`. Referral code + link generation,
/// and deterministic mock click/conversion stats so the "My Gigs" and admin
/// analytics screens have something to show without a real click-tracking
/// backend. See docs/api-spec.md for the real design (a redirect/attribution
/// service tied to actual ticket checkout).
library;

int _hashString(String input) {
  var hash = 0;
  for (final rune in input.runes) {
    hash = (hash << 5) - hash + rune;
    hash &= 0xFFFFFFFF;
  }
  // Emulate JS's `hash |= 0` (32-bit signed) then Math.abs.
  if (hash & 0x80000000 != 0) {
    hash = hash - 0x100000000;
  }
  return hash.abs();
}

String generateReferralCode(String instagramHandle, String gigId) {
  final handlePart = instagramHandle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final safeHandle = handlePart.isEmpty ? 'creator' : handlePart.substring(0, handlePart.length.clamp(0, 12));
  final suffix = _hashString('$instagramHandle:$gigId').toRadixString(36);
  return '$safeHandle-${suffix.substring(0, suffix.length.clamp(0, 5))}';
}

String referralLink(String referralCode) => 'https://slb.link/$referralCode';

class MockLinkStats {
  final int clicks;
  final int ticketsSold;
  final int commissionEarned;

  const MockLinkStats({required this.clicks, required this.ticketsSold, required this.commissionEarned});
}

/// Stable pseudo-random stats derived from the referral code, so the same
/// link always shows the same numbers across reloads (no backend to persist
/// real clicks yet). Only meaningful for gigs with ticketPrice/commissionRate set.
MockLinkStats mockLinkStats(String referralCode, {int? ticketPrice, double? commissionRate}) {
  final seed = _hashString(referralCode);
  final clicks = 40 + (seed % 260);
  final conversionRate = 0.03 + ((seed >> 4) % 12) / 100; // ~3%-15%
  final ticketsSold = (clicks * conversionRate).round();
  final commissionEarned =
      (ticketPrice != null && commissionRate != null) ? (ticketsSold * ticketPrice * (commissionRate / 100)).round() : 0;
  return MockLinkStats(clicks: clicks, ticketsSold: ticketsSold, commissionEarned: commissionEarned);
}
