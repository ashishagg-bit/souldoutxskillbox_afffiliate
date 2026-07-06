# Skillbox Affiliate / Gigs

A creator affiliate program for Skillbox (the event-ticketing platform):
creators apply, connect their Instagram/socials, get scored 0-100 into a
Bronze/Silver/Gold/Platinum tier, and unlock a gig marketplace (event
attendance, story coverage, UGC, brand campaigns) matched to that tier.

Built as an Angular 19 standalone-component app so it can be lifted directly
into the existing Skillbox Angular 19 web frontend (Laravel 10 / PHP 8.2
backend, Flutter 3.4 mobile — this feature targets web only for now). See
[`docs/api-spec.md`](docs/api-spec.md) for the backend contract this
frontend expects once it's wired to real data.

## Status

Fully clickable prototype against local mock data (`localStorage` +
in-memory gig list) — no backend required to run it. Every state mutation
goes through `ApplicationStateService`, so swapping mock data for real API
calls is a single-file change (see the "Frontend integration notes" section
of the API spec).

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
```

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
