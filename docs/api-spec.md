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
| status | enum | `submitted`, `under_review`, `scored`, `rejected` |
| submitted_at | timestamp, nullable | |
| scored_at | timestamp, nullable | |
| created_at / updated_at | timestamp | |

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
| created_at / updated_at | timestamp | |

### `gig_applications`

| column | type | notes |
|---|---|---|
| id | bigint pk | |
| user_id | bigint fk -> users.id | |
| gig_id | bigint fk -> gigs.id | |
| status | enum | `applied`, `approved`, `rejected`, `completed` |
| applied_at | timestamp | |
| created_at / updated_at | timestamp | |
| | | unique index on (user_id, gig_id) |

## Endpoints

All endpoints are authenticated (Sanctum/session, matching however the
existing Skillbox API authenticates the Angular app today) and scoped to the
current user — there is no admin surface here, that's a separate reviewer
dashboard out of scope for this feature.

### `GET /api/affiliate/application`
Returns the current user's application, or `404` if they haven't applied yet.

```json
{
  "status": "scored",
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

Sets `status = 'submitted'`, `submitted_at = now()`. A reviewer job/queue
later verifies the screenshot and flips status to `under_review` ->
`scored` or `rejected` (this is the "within 48 hours" step shown in the
app's status tracker). Until a reviewer workflow exists, it's fine to have
this endpoint synchronously set `status = 'scored'`, `scored_at = now()` to
match the current frontend's instant-preview behavior.

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
Creates a `gig_applications` row for the current user. `409` if already
applied, `403` if not eligible (tier below `min_tier`).

### `GET /api/gigs/my`
Lists gigs the current user has applied to, same shape as `GET /api/gigs`
plus `gig_applications.status`.

## Frontend integration notes

- `ApplicationStateService` currently persists to `localStorage` under key
  `skillbox.affiliate.application.v1`. Replace its internals with an
  `HttpClient`-backed service; keep the public method signatures
  (`submitApplication()`, `applyToGig()`, etc.) so components don't change.
- `GigsService.getAll()` currently returns the hardcoded array in
  `src/app/core/data/gigs.ts`. Point it at `GET /api/gigs` instead.
- The score `computed()` signal in `ApplicationStateService` currently runs
  `computeScore()` client-side against locally-entered numbers. Once the
  backend is live, prefer `GET /api/affiliate/score` as the source of truth
  post-submission, and keep the client-side `computeScore()` only as a
  live preview during the step-3 "Upload insights" form (so users see an
  estimate before submitting).
- Screenshot upload: the step-3 file input already collects a `File` object
  (`onFileSelected()` in `apply-wizard.component.ts`) but doesn't do
  anything with it yet — wire it into the `POST /api/affiliate/application`
  multipart request.
