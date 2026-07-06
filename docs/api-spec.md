# Affiliate/Gigs API Spec (Laravel 10 / PHP 8.2)

This documents the backend contract the Angular frontend in this repo expects.
Right now every mutation lives in `ApplicationStateService`
(`src/app/core/state/application-state.service.ts`) against `localStorage`, so
the app runs standalone with no backend. Swapping that service's method
bodies from `localStorage` reads/writes to `HttpClient` calls against the
endpoints below is the entire integration step — no component changes needed.

The scoring rubric is implemented once, in TypeScript, at
`src/app/core/lib/scoring.ts`. Port `computeScore()` to a PHP service
(`App\Services\AffiliateScoringService`) with identical band tables so the
frontend's optimistic/preview numbers never drift from the backend's
authoritative score. Treat `scoring.ts` as the spec for that port.

## Data model

### `affiliate_applications`

| column | type | notes |
|---|---|---|
| id | bigint pk | |
| user_id | bigint fk -> users.id | one application per user |
| instagram_handle | string | stored without leading `@` |
| platforms | json | array of `Instagram\|YouTube\|Snapchat\|Twitter / X` |
| city | string | one of the 8 supported cities |
| niche | string | one of the 6 supported niches |
| followers | unsigned int | self-reported, verified manually against screenshot |
| engagement_rate | decimal(4,1) | percent |
| content_format | string | `Reels / Short video\|Photos / Carousel\|Stories only\|Long-form video` |
| audience_india_percent | unsigned tinyint | 0-100 |
| screenshot_path | string, nullable | storage disk path for the uploaded insights screenshot |
| status | enum | `under_review`, `approved`, `rejected` |
| submitted_at | timestamp, nullable | |
| scored_at | timestamp, nullable | set when a reviewer approves/rejects, not at submission time |
| reviewed_by | bigint fk -> users.id, nullable | the Skillbox team member who approved/rejected |
| created_at / updated_at | timestamp | |

Gig-marketplace access (browsing eligible-tier gigs, applying to them) gates
on `status = 'approved'`. There is no separate "scored" state — the AI score
is always computed and previewable client-side the moment enough of the
form is filled in (see `computeScore()`), but it only becomes the *official*
tier once a reviewer approves the profile. This mirrors
`ApplicationStateService.submitApplication()` / `.approveApplication()` /
`.rejectApplication()` in the current frontend exactly.

### `affiliate_performance`

Tracks the "Skillbox Performance" half of the score, which updates over time
as the affiliate uses the platform (separate from the one-time application
data above).

| column | type | notes |
|---|---|---|
| id | bigint pk | |
| user_id | bigint fk -> users.id | |
| tickets_sold | unsigned int | attributed via affiliate/referral links |
| content_approval_rate | decimal(5,2) | percent of submitted gig content approved |
| gigs_completed | unsigned int | |
| active_last_60_days | boolean | computed nightly from last login/content activity |
| updated_at | timestamp | |

### `gigs`

| column | type | notes |
|---|---|---|
| id | bigint pk | |
| type | enum | `Story coverage`, `Attendance`, `UGC`, `Brand campaign` |
| min_tier | enum | `Bronze`, `Silver`, `Gold`, `Platinum` |
| min_score | unsigned tinyint | 0-100, shown to users alongside min_tier |
| title | string | |
| location | string, nullable | |
| event_date | string, nullable | free-text display date (e.g. "22 Feb", "14-16 Mar") |
| spots_left | unsigned int, nullable | |
| deliverable | string, nullable | e.g. "3 Reels · 30 sec each" |
| payout_min | unsigned int | in paise or whole rupees, pick one convention |
| payout_max | unsigned int | |
| ticket_price | unsigned int, nullable | set only for gigs paid via per-ticket referral commission |
| commission_rate | decimal(4,1), nullable | percent of ticket_price earned per ticket sold through the creator's link |
| created_at / updated_at | timestamp | |

`ticket_price`/`commission_rate` being set is what distinguishes "promote
this show with a trackable link, earn a cut of ticket sales" gigs (Story
coverage, Attendance) from flat-fee deliverable gigs (UGC, Brand campaign)
that get paid `payout_min`-`payout_max` directly for the content itself, no
link involved.

### `gig_applications`

| column | type | notes |
|---|---|---|
| id | bigint pk | |
| user_id | bigint fk -> users.id | |
| gig_id | bigint fk -> gigs.id | |
| status | enum | `pending`, `approved`, `rejected` |
| referral_code | string, nullable, unique | generated on approval, see below |
| applied_at | timestamp | |
| reviewed_at | timestamp, nullable | |
| reviewed_by | bigint fk -> users.id, nullable | |
| created_at / updated_at | timestamp | |
| | | unique index on (user_id, gig_id) |

Each show a creator wants to promote is its own approval — "profile
approved" (above) only unlocks *browsing* the marketplace; every individual
gig application still needs a reviewer to say yes, mirroring limited
`spots_left` and per-show brand fit. `referral_code` is only ever set once,
at approval time, and never changes — it's the identity of that creator's
promo link for that specific show for its whole lifetime.

### `referral_clicks`

| column | type | notes |
|---|---|---|
| id | bigint pk | |
| gig_application_id | bigint fk -> gig_applications.id | |
| clicked_at | timestamp | |
| ip_hash | string | hashed, not raw IP, for basic bot/dedup filtering |
| user_agent | string, nullable | |

Written by the redirect endpoint below on every hit. Keep it write-only and
cheap (no joins) since it's on the hot path of someone's Instagram story
swipe-up.

### `referral_conversions`

| column | type | notes |
|---|---|---|
| id | bigint pk | |
| gig_application_id | bigint fk -> gig_applications.id | |
| order_id | bigint fk -> (whatever the existing ticket/order table is) | the actual ticket purchase this is attributed to |
| ticket_count | unsigned int | tickets in that order |
| commission_amount | unsigned int | `ticket_count * gigs.ticket_price * gigs.commission_rate / 100`, snapshotted at purchase time so later price/rate changes don't retroactively change past payouts |
| payout_status | enum | `pending`, `paid` |
| created_at | timestamp | |

This is the table that turns "someone bought a ticket through the link"
into money owed to the creator. It requires hooking into whatever the
existing Skillbox checkout flow already does when an order completes —
this repo has no visibility into that table/flow, so the integration point
is: **whatever finalizes a ticket order needs to check for a referral
cookie/query-param and, if present and valid, insert a row here.** This is
the one piece of this whole spec that depends on code outside this
affiliate module.

## Endpoints

Creator-facing endpoints are authenticated (Sanctum/session, matching
however the existing Skillbox API authenticates the Angular app today) and
scoped to the current user. Admin endpoints (further below) additionally
require a reviewer/staff role check.

### `GET /api/affiliate/application`
Returns the current user's application, or `404` if they haven't applied yet.

```json
{
  "status": "under_review",
  "instagram_handle": "avadhcreates",
  "platforms": ["Instagram", "YouTube"],
  "city": "Delhi",
  "niche": "Nightlife",
  "submitted_at": "2026-07-06T10:15:00Z"
}
```

### `POST /api/affiliate/application`
Creates the application (the step-4 "Submit application" action). Body is
`multipart/form-data` because of the screenshot upload.

```
instagram_handle: string, required
platforms[]: string[], required, min 1
city: string, required, one of CITY_OPTIONS
niche: string, required, one of NICHE_OPTIONS
followers: integer, required, min 0
engagement_rate: numeric, required, min 0
content_format: string, required, one of CONTENT_FORMAT_OPTIONS
audience_india_percent: integer, required, 0-100
screenshot: file, required, image, max 8mb
```

Sets `status = 'under_review'`, `submitted_at = now()`. Sits in the admin
queue (`GET /api/admin/affiliate-applications`) until a reviewer approves
or rejects it — see the Admin section below.

### `PATCH /api/affiliate/application`
Lets the creator edit and resubmit fields after a rejection (re-apply
without starting a whole new record). Same body shape as the POST above;
sets `status` back to `under_review`.

### `GET /api/affiliate/score`
Returns the computed score breakdown — output of
`AffiliateScoringService::computeScore()`, shaped to match
`ScoreBreakdown` in `src/app/core/lib/types.ts` exactly:

```json
{
  "total": 51,
  "tier": "Silver",
  "platform_metrics": [
    { "label": "Followers", "detail": "(50k-200k)", "earned": 12.5, "max": 20 },
    { "label": "Engagement rate", "detail": "(3.2%)", "earned": 12.3, "max": 18 },
    { "label": "Platform", "detail": "(Reels / Short video)", "earned": 12, "max": 12 },
    { "label": "Audience quality", "detail": "(India 78%)", "earned": 7.8, "max": 10 }
  ],
  "skillbox_performance": [
    { "label": "Tickets sold", "detail": "", "earned": 0, "max": 15 },
    { "label": "Content approval rate", "detail": "", "earned": 0, "max": 10 },
    { "label": "Gigs completed", "detail": "", "earned": 0, "max": 9 },
    { "label": "Active in last 60 days", "detail": "", "earned": 6, "max": 6 }
  ]
}
```

### `POST /api/affiliate/parse-insights-screenshot`

Reads the uploaded Instagram insights screenshot with a vision-capable LLM
and extracts the numbers the step-3 form asks for, so the user doesn't have
to type them by hand. Called as soon as the file is selected in step 3,
before the "Continue" button — the extracted values pre-fill the form
fields but remain editable; nothing here is auto-submitted without the user
seeing and being able to correct it first.

```
screenshot: file, required, image, max 8mb
```

```json
{
  "followers": 68000,
  "engagement_rate": 3.2,
  "audience_india_percent": 78,
  "confidence": "high"
}
```

`confidence` is `"low"` when the model isn't sure it read a field correctly
(cropped screenshot, unusual layout, glare, etc.) — the frontend should
visually flag any pre-filled field paired with `"low"` confidence (e.g. a
small "double-check this" hint) rather than silently trusting it. Fields
the model couldn't find at all should come back `null` and simply leave
that input blank for the user to fill in themselves.

This is not implemented in the current build (there's no backend yet to
call a vision model from, and an API key can never live in this repo's
client-side code since it deploys to public static hosting). Step 3 today
only has manual number entry; wiring this in later is a frontend change in
`apply-wizard.component.ts::onFileSelected()` plus this one backend
endpoint — no other screens change.

### `GET /api/gigs?type=&min_tier=`
Lists gigs, optionally filtered by `type`. Response includes an
`eligible: boolean` computed against the caller's current tier so the
frontend doesn't need to duplicate `tierMeetsMinimum()` server logic.

```json
{
  "data": [
    {
      "id": 1,
      "type": "Story coverage",
      "min_tier": "Silver",
      "min_score": 40,
      "title": "Sunburn Arena Delhi — Feb 2025",
      "location": "JLN Stadium",
      "event_date": "22 Feb",
      "spots_left": 3,
      "payout_min": 8000,
      "payout_max": 12000,
      "eligible": true,
      "applied": false
    }
  ]
}
```

### `POST /api/gigs/{gig}/apply`
Creates a `gig_applications` row (`status = 'pending'`) for the current
user. `409` if already applied, `403` if not eligible (tier below
`min_tier`, or profile not yet `approved`).

### `GET /api/gigs/my`
Lists gigs the current user has applied to, same shape as `GET /api/gigs`
plus `gig_applications.status`. For rows where `status = 'approved'`,
also include the link + live stats:

```json
{
  "data": [
    {
      "id": 1,
      "title": "Sunburn Arena Delhi — Feb 2025",
      "gig_application_status": "approved",
      "referral_link": "https://slb.link/avadhcreates-8f2k1",
      "stats": { "clicks": 240, "tickets_sold": 12, "commission_earned": 2700 }
    }
  ]
}
```

### `GET /r/{referral_code}` (public, unauthenticated, short-domain e.g. `slb.link`)
The link creators actually paste into their stories/posts/reels. On hit:
1. Look up the `gig_applications` row by `referral_code` (404 if unknown or
   the gig application isn't `approved`).
2. Insert a `referral_clicks` row.
3. Set a short-lived signed cookie (or append a query param, whichever the
   existing checkout flow can read) carrying the `referral_code`.
4. Redirect (302) to the actual event/ticket page for that gig.

Whatever completes a ticket order needs to check for that referral
cookie/param and write a `referral_conversions` row if present — see that
table's notes above for why this is the one part of the spec that reaches
into code outside this affiliate module.

## Admin endpoints

Everything below requires a reviewer/staff role. There's no dedicated
admin authentication scheme specified here — reuse whatever Skillbox
already uses to gate internal tooling.

### `GET /api/admin/affiliate-applications?status=under_review`
Lists applications for the review queue (the frontend's `/admin` route,
`AdminReviewComponent`), each with its computed score breakdown attached so
the reviewer can sanity-check the AI-derived tier before approving:

```json
{
  "data": [
    {
      "id": 42,
      "instagram_handle": "avadhcreates",
      "platforms": ["Instagram", "YouTube"],
      "city": "Delhi",
      "niche": "Nightlife",
      "submitted_at": "2026-07-06T10:15:00Z",
      "score": { "total": 51, "tier": "Silver", "platform_metrics": [ /* ... */ ] }
    }
  ]
}
```

### `POST /api/admin/affiliate-applications/{id}/approve`
Sets `status = 'approved'`, `scored_at = now()`, `reviewed_by = <admin user id>`.
This is the action that unlocks the creator's gig marketplace.

### `POST /api/admin/affiliate-applications/{id}/reject`
Sets `status = 'rejected'`, same timestamp/reviewer fields.

### `GET /api/admin/gig-applications?status=pending`
Lists pending per-show promotion requests across all creators, for the
"Pending show-promotion requests" queue on the same `/admin` screen.

### `POST /api/admin/gig-applications/{id}/approve`
Sets `status = 'approved'`, `reviewed_at = now()`, `reviewed_by = <admin user id>`,
and generates `referral_code` (see `generateReferralCode()` in
`src/app/core/lib/referral.ts` for the current client-side placeholder
algorithm — port the same shape server-side: derived from the creator's
handle plus the gig id, collision-checked against the unique index before
insert).

### `POST /api/admin/gig-applications/{id}/reject`
Sets `status = 'rejected'`, same timestamp/reviewer fields. No referral
code is ever generated for a rejected application.

### Shows CRUD
Backs the admin panel's "Shows" tab (`AdminShowsComponent`) — full CRUD on
the `gigs` table:

- `POST /api/admin/gigs` — create, body matches the `gigs` columns above
  (`ticket_price`/`commission_rate` optional; this is where the commission
  model per show gets decided).
- `PATCH /api/admin/gigs/{id}` — partial update, same shape.
- `DELETE /api/admin/gigs/{id}` — remove a show from the marketplace.
  Consider soft-deleting instead if any creators already have approved gig
  applications against it, so their existing links/stats don't orphan.

### Tier settings

- `GET /api/admin/tier-settings` — returns the four `{ tier, min, max, payout }`
  rows backing the "Settings" tab (`AdminSettingsComponent`).
- `PATCH /api/admin/tier-settings/{tier}` — update one tier's `min`/`max`/`payout`.
  `AffiliateScoringService::tierForScore()` should read these at score time
  rather than hardcoding the cutoffs, mirroring `tierForScore(score, tierBands)`
  in `core/lib/scoring.ts` — a settings change here immediately changes every
  creator's tier on next score computation, with no migration needed.

### Scoring weights

- `GET /api/admin/scoring-weights` — returns the 8 point-ceiling values
  (`followers`, `engagement_rate`, `platform`, `audience_quality`,
  `tickets_sold`, `content_approval_rate`, `gigs_completed`, `active`) that
  back the "Scoring weights" section of the Settings tab.
- `PATCH /api/admin/scoring-weights` — update one or more of them.

These are the `max` values in `GET /api/affiliate/score`'s response
(`ScoreBreakdownItem.max`) - a weight change immediately changes every
creator's `total` on next computation. `AffiliateScoringService` should
rescale each metric's raw earned value against its base ceiling the same
way `rescale()` does in `core/lib/scoring.ts` (never redefine the band
*shapes* themselves - only the ceiling each band's progress is measured
against). The frontend deliberately warns the admin in-UI when the 8
weights don't sum to 100, since the tier cutoffs above are meant to read
against a 0-100 scale - keep that validation (or a hard constraint) on the
backend too if you don't want reviewers accidentally creating a confusing
scoring model.

## Frontend integration notes

- `ApplicationStateService` currently persists to `localStorage` under key
  `skillbox.affiliate.application.v2`. Replace its internals with an
  `HttpClient`-backed service; keep the public method signatures
  (`submitApplication()`, `applyToGig()`, `approveApplication()`,
  `approveGigApplication()`, etc.) so components don't change. Also drop the
  `window.addEventListener("storage", ...)` cross-tab sync block in its
  constructor once real data comes from the network instead of
  `localStorage` — polling or a websocket subscription replaces it.
- `GigsService` now holds gigs in a signal seeded from
  `src/app/core/data/gigs.ts` and persisted to `localStorage`
  (`addGig()`/`updateGig()`/`deleteGig()` back the admin "Shows" tab).
  Point `getAll()`/`getById()` at `GET /api/gigs`/`GET /api/gigs/{id}` and
  the three mutators at the Shows CRUD endpoints above; drop its
  `localStorage`/`storage`-event plumbing the same way as
  `ApplicationStateService`.
- `TierSettingsService` similarly holds the tier cutoffs in a
  `localStorage`-backed signal. Point `tierBands()` at
  `GET /api/admin/tier-settings` and `updateBand()` at
  `PATCH /api/admin/tier-settings/{tier}`.
- `ScoringWeightsService` (`core/state/scoring-weights.service.ts`) holds
  the 8 metric point-ceilings the same way. Point `weights()` at
  `GET /api/admin/scoring-weights` and `updateWeight()` at
  `PATCH /api/admin/scoring-weights`.
- The score `computed()` signal in `ApplicationStateService` currently runs
  `computeScore()` client-side against locally-entered numbers. Once the
  backend is live, prefer `GET /api/affiliate/score` as the source of truth
  post-approval, and keep the client-side `computeScore()` only as a live
  preview during the step-3 "Upload insights" form (so users see an
  estimate before submitting) and on the pending-review dashboard banner.
- Screenshot upload: the step-3 file input already collects a `File` object
  (`onFileSelected()` in `apply-wizard.component.ts`) but doesn't do
  anything with it yet. Two things to wire up once the backend exists:
  1. Send it to `POST /api/affiliate/parse-insights-screenshot` right away
     to pre-fill the followers/engagement/audience fields (see that
     endpoint's docs above for the confidence-flagging behavior).
  2. Include the same file in the final `POST /api/affiliate/application`
     multipart request on submit, since the reviewer needs it too.
- `AdminReviewComponent` (`src/app/features/admin/`) currently reads and
  mutates the same single-applicant `ApplicationStateService` directly,
  standing in for a real reviewer queue. Once the backend exists, it should
  instead call `GET /api/admin/affiliate-applications` /
  `GET /api/admin/gig-applications` for the queue lists and the
  corresponding approve/reject endpoints — and the route needs a real
  staff-only guard, since right now `/admin` is reachable by anyone who
  knows the URL.
- `referral.ts`'s `generateReferralCode()` and `mockLinkStats()` are
  placeholders: the former's collision handling is not production-safe
  (no uniqueness check against real data), and the latter fabricates
  clicks/tickets-sold/commission from a hash so the "My Gigs" screen has
  something to show. Both get fully replaced by
  `POST /api/admin/gig-applications/{id}/approve` (real code generation)
  and `GET /api/gigs/my` (real stats from `referral_clicks` /
  `referral_conversions`).
