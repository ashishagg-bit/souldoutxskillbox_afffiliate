# skillbox_affiliate (mobile)

Flutter port of the Skillbox creator/affiliate program feature — apply, get
AI-scored into a tier (Bronze/Silver/Gold/Platinum), browse and apply to
gigs, track referral links, and manage everything from an in-app admin
panel. This is a direct feature-parity port of the Angular reference app in
`../src`, built for merging into the existing Skillbox Flutter app.

## Structure

- `lib/core/models` — data classes ported from the Angular `types.ts`
- `lib/core/scoring` — score/tier calculation engine
- `lib/core/referral` — referral link + mock click/commission stats
- `lib/core/providers` — `ChangeNotifier` state (Provider package), one per
  Angular service: application state, gigs, tier settings, scoring weights,
  admin auth
- `lib/core/persistence` — `SharedPreferences`-backed local store
- `lib/features` — screens: more menu, gigs landing, apply wizard,
  application status, gigs dashboard, and the admin panel (overview,
  applications, shows, analytics, settings)

## State management

Uses `provider` (`ChangeNotifier`), matching the state management pattern
already used in the production Skillbox Flutter app, so these
providers/screens can be merged directly.

## Running

```
flutter pub get
flutter run
```

## Notes

- Admin auth is a local passphrase gate only (`skillbox2026`), not real
  security — same caveat as the Angular reference implementation.
- All data is stored locally via `SharedPreferences`; there is no backend
  integration yet. See `../docs/api-spec.md` for the intended Laravel API
  contract this should eventually call into.
