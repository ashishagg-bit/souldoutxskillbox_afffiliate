# Skillbox Affiliate / Gigs

A creator affiliate program for Skillbox (the event-ticketing platform):
creators apply, connect their Instagram/socials, get scored 0-100 into a
Bronze/Silver/Gold/Platinum tier, and — once a Skillbox reviewer approves
their profile — unlock a gig marketplace (event attendance, story coverage,
UGC, brand campaigns) matched to that tier. For shows promoted via a
trackable link (story coverage / attendance gigs), each creator's request
to promote a specific show is its own approval step too; once approved they
get a unique link to post in their content, and earn commission on ticket
sales attributed to it.

The production target is the existing Skillbox **Flutter** mobile app
(Laravel 10 / PHP 8.2 backend). The feature is implemented twice in this
repo:

- **[`mobile/`](mobile/)** — the Flutter port (Provider state management,
  matching the existing Skillbox app's pattern) meant to be merged directly
  into the production mobile app. This is the primary, up-to-date
  implementation.
- **`src/`** (this Angular 19 app, described below) — the original
  browser-based prototype, kept as-is since it's already built and
  deployed live. No longer the primary target, but still useful as a
  fast-iterating reference/demo.

Both read/write the same shape of local mock data and implement the same
flows; see [`docs/api-spec.md`](docs/api-spec.md) for the backend contract
either one expects once wired to real data.

## Status

Fully clickable prototype against local mock data (`localStorage` +
in-memory gig list) — no backend required to run it. Every state mutation
goes through `ApplicationStateService`, so swapping mock data for real API
calls is a single-file change (see the "Frontend integration notes" section
of the API spec).

The full loop works end to end in the browser: submit a profile
application → a reviewer approves it at `/admin` → the creator's dashboard
unlocks → they apply to a show → the reviewer approves that too → the
creator gets a unique tracking link with (fabricated, hash-based) click and
commission stats.

## Running it

```bash
npm install
npm start        # ng serve, http://localhost:4200
```

```bash
npm run build     # production build to dist/
```

## Structure

```
src/app/
  core/
    lib/            # framework-agnostic types + the scoring rubric (scoring.ts)
    data/            # mock gigs list, dropdown option lists
    state/           # ApplicationStateService (signals + localStorage)
  shared/
    phone-shell/     # mobile app frame (status bar + bottom nav) all pages render inside
    bottom-nav/
    step-progress/   # 4-segment progress bar used in the apply wizard
  features/
    more/            # "More" menu (entry point: More > Gigs)
    gigs-landing/     # "Get paid to show up" landing + payout-by-tier table
    apply/            # 4-step apply wizard (socials -> city/niche -> insights -> review)
    application-status/ # post-submit status tracker
    dashboard/        # My Score / Available / My Gigs tabs
    admin/            # admin panel: Overview / Applications / Shows / Analytics / Settings
```

`core/lib/referral.ts` generates each creator's unique per-gig tracking
link and — since there's no click-tracking backend yet — fabricates
plausible clicks/tickets-sold/commission numbers from a hash of the
referral code, so "My Gigs" has something to show once a gig application
is approved. Both are placeholders; see the API spec's "Admin endpoints"
and `referral_clicks`/`referral_conversions` sections for the real design.

`core/lib/scoring.ts` is the single source of truth for the scoring rubric
(60 pts platform metrics + 40 pts Skillbox performance). Port it to PHP
verbatim when building the real backend so client-side previews and
server-side authoritative scores never disagree — see the API spec for
details.

## Routes

| path | screen |
|---|---|
| `/more` | More menu |
| `/gigs` | Gigs landing page |
| `/gigs/apply` | 4-step apply wizard |
| `/gigs/status` | Post-submit status tracker |
| `/gigs/dashboard` | My Score / Available / My Gigs |
| `/admin` | Admin panel — Overview, Applications, Shows, Analytics, Settings (see below) |

## Admin panel

`/admin` is a full internal tool, tabbed:

- **Overview** — profile status, pending show requests, active promo links, shows listed, and aggregate link performance (clicks/tickets sold/commission owed).
- **Applications** — approve/reject the profile application, and approve/reject pending per-show promotion requests (issues the creator's unique tracking link on approval).
- **Shows** — full CRUD on the gigs/shows in the marketplace: title, type, min tier/score, payout range, location/date/spots, and the per-ticket commission model (ticket price + commission rate) for link-promotable shows.
- **Analytics** — a table of every active creator tracking link with clicks, tickets sold, and commission owed, plus totals.
- **Settings** — edit the Bronze/Silver/Gold/Platinum score cutoffs and payout display text; takes effect immediately across the app (verified: changing a cutoff live-flips an already-computed score's tier label with no reload).

All of it is backed by reactive services (`GigsService`, `TierSettingsService`, `ApplicationStateService`) persisted to `localStorage`, with a cross-tab `storage` event listener so changes made in the admin tab show up live in a creator tab open in the same browser — useful for testing both roles yourself without needing two accounts.

### Admin access

`/admin` is gated by `/admin-login`, a single shared passphrase (default
`skillbox2026`, change it in `src/app/core/state/admin-auth.service.ts`
before sharing the deployed link with anyone). This is **not real
authentication** — it's compared client-side and visible to anyone who
reads the deployed JS bundle, so it only deters casual/accidental access
to a public demo link. Sign-in persists for the browser tab's session
(`sessionStorage`) until "Sign out" is clicked. Real staff accounts with
server-side auth need to come from the Laravel backend — see
`docs/api-spec.md`'s "Admin endpoints" section, which already assumes a
real role check in front of every admin route.
