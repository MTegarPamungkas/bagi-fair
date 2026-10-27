# Architecture decisions

This file records the decisions behind Bagi Fair and the trade-offs accepted. It is written as a lightweight ADR log: context → decision → alternatives → consequences.

---

## ADR-001 — Flutter with Bloc, Equatable, GetIt, and GoRouter

**Context.** The app needs to run on Android and Web from one codebase and be consistent with the existing `dompetektif` reference architecture.

**Decision.** Use Flutter with `flutter_bloc` (full Bloc, not Cubit), `equatable` for value objects, `get_it` for dependency injection, and `go_router` for navigation. Feature folders follow `features/<feature>/presentation/{bloc,pages,widgets}`; domain and data layers are shared.

**Alternatives considered.** Riverpod (less similar to the reference), provider + setState (too weak for realtime/sync state), auto_route (GoRouter has first-class deep-link and redirect support).

**Consequences.** Every state change is explicit and testable. The cost is more boilerplate per feature. Blocs that need route arguments are registered as factories and resolved from `getIt` inside page constructors.

---

## ADR-002 — Local-first storage with an outbox, not online-only

**Context.** Shared bills are frequently edited while travelling or on flaky connections. Losing an expense is unacceptable.

**Decision.** All reads come from Hive CE. Writes update Hive immediately and append a row to the `outbox`. `SyncEngine` replays the outbox when online. Supabase pull + realtime keep the cache fresh.

**Alternatives considered.** Online-only with optimistic UI (loses data offline); SQLite/Drift (heavier for web, and the reference uses Hive).

**Consequences.** The UI is instant and survives restarts/offline. Complexity moves into sync: ordering, retries, and de-duplication. Because ids are app-generated UUIDs, replaying an insert is idempotent.

---

## ADR-003 — Pull-based reconciliation, realtime as a trigger

**Context.** Supabase Realtime can deliver change events, but using the payloads directly would create a second, subtly different source of truth.

**Decision.** Realtime subscriptions only signal that something changed. The engine performs a debounced incremental pull (`updated_at` cursor) and upserts into Hive. The same path runs on start, reconnect, manual sync, and after every outbox flush.

**Alternatives considered.** Apply realtime payloads directly (fast, but ordering and RLS-filtered payloads complicate cache consistency), polling only (wasteful and laggy).

**Consequences.** One reconciliation path, easier reasoning, naturally recoverable after missed events. Slightly more network traffic than pure payload application.

---

## ADR-004 — App-generated UUID primary keys

**Context.** Offline creation needs an id before the server sees the row, and outbox retries must not duplicate rows.

**Decision.** Generate UUIDs on the client for groups, expenses, settlements, receipts, activities, and notifications. Use them as primary keys and upserts for replay.

**Alternatives considered.** Server-generated identities (forces a round trip and complicates offline references), temporary negative ids (requires an id-remap pass).

**Consequences.** Offline flows are simple and idempotent. The server must trust client ids; RLS constrains who can write them.

---

## ADR-005 — Last-write-wins with tombstones

**Context.** Two devices may edit the same expense or settlement while offline. Field-level merging is disproportionate to the product.

**Decision.** Every syncable table carries `updated_at` (maintained by a trigger) and most carry `deleted_at` tombstones. Pulls take the newest `updated_at`; deletes are soft. `group_members` is intentionally a hard delete because membership is presence, not content, and the RLS policy mirrors that.

**Alternatives considered.** CRDTs (overkill), server-authoritative locking (blocks offline edits), per-field history (large scope).

**Consequences.** Predictable and cheap. A stale edit can overwrite a newer one; the activity log makes changes visible, and exports act as a snapshot.

---

## ADR-006 — Money as integer minor units

**Context.** Floating-point rupiah drift is unacceptable in a bill splitter, especially after tax and repeated splits.

**Decision.** Store integer minor units everywhere (`int`). `IDR`, `JPY`, `KRW`, and `VND` use 0 decimals; other supported currencies use 2. Conversions happen only at the UI edge (`MoneyFormatter`) and when applying an FX rate.

**Alternatives considered.** `decimal` package (extra dependency; still needs allocation rules), doubles (rounding bugs), storing formatted strings (unusable for math).

**Consequences.** Exact sums and predictable exports. UI code must be disciplined about minor vs major units; this is centralized in `MoneyFormatter`.

---

## ADR-007 — Largest-remainder allocation for every split

**Context.** `100.000 / 3` cannot be represented exactly. Someone must absorb the remaining minor unit, and the choice must be consistent across devices and re-renders.

**Decision.** Compute fractional shares, floor them, then distribute the remainder by largest fractional part, tie-breaking by participant order.

**Alternatives considered.** Naive rounding per person (sum may drift), assigning the remainder to the payer (arbitrary and surprising), fractional shares (invalid for settlement).

**Consequences.** The sum always equals the total and the result is deterministic. A participant can receive one unit more than another; the explanation sheet makes this visible.

---

## ADR-008 — Greedy debt simplification

**Context.** Group balances form a directed debt graph. Users want the fewest, simplest transfers.

**Decision.** Net each member's balance, then repeatedly settle the largest debtor against the largest creditor.

**Alternatives considered.** Exact minimum transfers (NP-hard; exponential search for larger groups), pairwise original debts (up to n² transfers and confusing), a flow solver (extra dependency, still not guaranteed minimal in all formulations).

**Consequences.** At most _n − 1_ transfers, deterministic, easy to explain, and trivial to test. In rare balance distributions it can use one more transfer than the theoretical optimum.

---

## ADR-009 — Per-item tax/service allocated by item subtotal

**Context.** For itemized receipts, splitting tax equally punishes people who ordered less. Indonesian bills commonly add PB1/PPN and a service charge.

**Decision.** Assign item subtotals to participants (shared items split equally), then allocate tax, service, and discount in proportion to each participant's item subtotal using the same largest-remainder allocator. Any receipt rounding is booked as an explicit adjustment line.

**Alternatives considered.** Equal tax per person (unfair), tax attached to each item (impossible when the receipt only shows a total), ignoring rounding (shares would not sum to the paid total).

**Consequences.** Shares reconcile exactly with the receipt. The UI must explain proportional tax, which the per-expense explanation sheet does.

---

## ADR-010 — Multi-currency at the expense level, base currency for balances

**Context.** A trip can be planned in IDR but have a hotel charge in USD or SGD. Balances must still settle in one currency.

**Decision.** Each group has one base currency. An expense stores `currency`, `amount_minor`, `fx_rate`, and `amount_base_minor`. Shares and settlements are always in base currency. The original amount remains visible.

**Alternatives considered.** Currency per member (complex settlement graph), live FX API (network dependency and rate ambiguity), converting at settlement time (retroactive balance changes).

**Consequences.** Settlement stays simple and auditable. The FX rate is captured at entry time, so historical balances do not drift. There is no automatic rate lookup; users enter or confirm the rate.

---

## ADR-011 — AI OCR through a Supabase Edge Function with Gemini

**Context.** Receipt scanning is a core differentiator, but an AI API key must never ship in a mobile app, and free-tier quotas must be protected.

**Decision.** The client sends base64 image bytes to the `scan-receipt` Edge Function. The function:

1. Verifies the caller's JWT.
2. Verifies membership of the supplied `group_id`.
3. Claims a per-user slot in `ai_usage` via `claim_ai_scan` (10/hour, service-role only).
4. Calls Gemini with a strict JSON schema prompt (`gemini-2.0-flash` by default).
5. Converts major units to minor units server-side and returns structured JSON.

The app never sees the key. OCR output is always editable before saving, and manual entry is always available.

**Alternatives considered.** On-device ML Kit (poor receipt structure, platform-specific), direct client calls to Gemini (key leakage), paid OCR (cost), a custom backend (unnecessary infrastructure).

**Consequences.** The key stays server-side and quota is enforceable. Cold starts add latency. Gemini free-tier quality varies, so the review step is mandatory. Uploaded images are sent to Google's API; the UI documents this.

---

## ADR-012 — Private receipt bucket with signed URLs

**Context.** Receipts can contain personal spending information and must not be publicly listable.

**Decision.** Store images in a private `receipts` bucket with a 6 MB limit and a MIME allowlist. Paths are `<group_id>/<user_id>/<receipt_id>.jpg`. Storage RLS derives the group segment and checks membership. The app creates a 7-day signed URL at upload time.

**Alternatives considered.** Public bucket with unguessable paths (still public), proxying every read through an Edge Function (more secure, more latency/cost), no image retention (loses audit value).

**Consequences.** Images are protected at rest and via RLS. The stored signed URL expires after 7 days; re-signing on read is a documented follow-up.

---

## ADR-013 — Invite RPCs instead of direct table writes

**Context.** Joining by code must not let a user enumerate or forge memberships. The invite code is a capability, not a public row.

**Decision.** `create_group_invite` and `join_group_by_code` are `security definer` RPCs. `group_invites` is not part of the generic sync table list; the client calls the RPCs and then pulls the resulting membership. Codes are short, uppercase, expiry-bound, and revocable.

**Alternatives considered.** Client inserts into `group_invites` (RLS gets complicated and exposes invite rows), invite links containing a group UUID (guessable, no expiry).

**Consequences.** Clear, testable server-side authority. The client needs a network round trip to redeem a code, which is acceptable for an invite action.

---

## ADR-014 — Demo mode as a first-class gateway

**Superseded by ADR-025.** Kept for history: the demo gateway was removed so the app always runs against Supabase.

**Context.** Reviewers and new users should be able to try every flow without configuring Supabase or exposing a shared project.

**Decision.** `CloudGateway` has two implementations: `SupabaseCloudGateway` and `DemoCloudGateway`. When Supabase config is absent, the demo gateway, seeded Hive data, and a visible "Demo" chip take over. Email/Google auth is disabled in demo mode; the demo user is a fixed UUID.

**Alternatives considered.** Requiring a backend to run (bad for review), mocking inside widgets (does not exercise repositories/sync), a separate demo build flavor (drift).

**Consequences.** The full product is reviewable offline. Demo data is device-local. Code paths that assume a server must remain optional everywhere.

---

## ADR-015 — Client-side PDF/CSV export

**Context.** Users want a record for reimbursement or trip archives. Exporting on a server adds an endpoint, storage, and cleanup.

**Decision.** Build PDF and CSV in the app from the local cache using the `pdf` package, then save/share with `file_saver` and `share_plus`.

**Alternatives considered.** Edge Function export (server cost, auth complexity), pre-generated reports stored in Storage (stale data).

**Consequences.** Export works offline and contains exactly what the user sees. Large groups are bounded by the local cache, not by a server response.

---

## ADR-016 — Notifications: in-app + local, remote push deferred

**Context.** Realtime notifications and gentle reminders are required; remote push infrastructure (FCM/APNs, device tokens, Edge Function fan-out) is a larger project.

**Decision.** Persist notifications in the `notifications` table, sync them via the normal pull path, and show them in-app with an unread badge. Use `flutter_local_notifications` for device reminders scheduled by the app. "Colek Halus" writes an in-app notification for the target member.

**Alternatives considered.** FCM now (needs Firebase project, platform config, token table, server fan-out), email reminders (spammy, slow).

**Consequences.** In-app behavior is complete and testable. Closed-app delivery depends on local scheduling and is not equivalent to server push; this is called out in the README.

---

## ADR-017 — Material 3 with custom design tokens

**Visual specifics superseded by ADR-027.** The token architecture still holds; the palette, type, and surface treatment were replaced.

**Context.** The app must feel friendly and distinctive while remaining accessible and consistent across light/dark and phone/desktop.

**Decision.** Define `FairColors` as a `ThemeExtension` with semantic roles (accent, blue, positive, negative, warning, surfaces, lines), plus spacing and radius tokens. Build both themes from the same token set. Use Plus Jakarta Sans, tabular figures for money, 48 dp minimum touch targets, and responsive breakpoints at 720 and 1040 px.

**Alternatives considered.** Raw `ColorScheme` usage (too generic), per-screen colors (inconsistent), a third-party design system (extra dependency and visual mismatch).

**Consequences.** Screens stay visually coherent and dark mode is automatic. New colors require a token, which is intentional friction.

---

## ADR-018 — Compile-safe ID/EN localization

**Context.** The product is Indonesian-first with English support, and missing translations should fail at build time rather than in production.

**Decision.** Hand-written `AppLocalizations` with typed getters and a `t(id, en)` helper, exposed through a `BuildContext` extension. No generated ARB pipeline.

**Alternatives considered.** `flutter gen-l10n`/ARB (good for large teams, more files and codegen), hardcoded strings (not acceptable).

**Consequences.** Instant lookups and compiler-checked usage. Translators need to edit Dart, and pluralization is manual (Indonesian has no plural inflection; English helpers are explicit).

---

## ADR-019 — Tests around the money core, widgets around the shell

**Context.** The highest-risk logic is arithmetic and allocation, not pixel rendering. Widget tests should protect the parts users touch first.

**Decision.** Unit-test the split engine, debt simplifier, and money formatter exhaustively. Widget-test shared surfaces, group cards, and the auth screen, including a 320 px layout and the wide auth layout.

**Alternatives considered.** Golden tests (valuable but high-maintenance for a portfolio project), full integration tests (slow, need a backend).

**Consequences.** Fast, deterministic CI. Regressions in allocation are caught immediately. Navigation and backend integration still rely on manual smoke testing.

---

## ADR-020 — GitHub Actions for analyze, test, web, and APK

**Context.** A single command should prove the project is healthy on every change.

**Decision.** CI runs `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web`, and `flutter build apk --debug` on pushes and pull requests, and uploads both artifacts.

**Alternatives considered.** Codemagic (paid tiers), local-only checks (easy to skip).

**Consequences.** Build breakage is visible early. CI time is dominated by the first Flutter/Gradle download; caching mitigates repeat runs.

---

## ADR-021 — The Supabase project is managed as code through the CLI

**Context.** The schema, RLS, storage bucket, auth URLs, and the OCR function all have to exist consistently in the cloud, not just as files in the repo.

**Decision.** Keep the project linked through `supabase/config.toml` and ship three versioned migrations plus the `scan-receipt` function. Apply changes with `supabase db push --linked`, `supabase functions deploy`, and `supabase config push`. Identity settings (site URL, redirect allow-list, confirmation policy) are declared in `config.toml` rather than clicked in the dashboard, so `supabase config diff` shows drift before it is pushed. The read-only `supabase db query --linked` command is used to verify policies and data during development.

**Alternatives considered.** Dashboard-only setup (undocumented and unrepeatable), a single "paste this SQL" script (no history), Terraform (heavier than the scope).

**Consequences.** A fresh environment can be rebuilt from the repo. Some settings stay dashboard-only (OAuth client secrets, MFA), which the README calls out. `scripts/cloud-smoke.ps1` verifies the deployed project through the public REST API after every schema change.

---

## ADR-022 — SQL helper functions are declared after the tables they read

**Context.** `create or replace function ... language sql` validates its body at creation time. The first version of the initial migration declared `is_group_member()` and `is_group_owner()` in a "helpers" block above the `CREATE TABLE` statements, so `supabase db push` aborted with `relation "public.group_members" does not exist`.

**Decision.** Keep only table-independent helpers (`set_updated_at`, `storage_path_group`) at the top. Declare the membership helpers after the tables, in a clearly labelled section, before the RLS policies that use them.

**Alternatives considered.** `set check_function_bodies = off` (hides real mistakes), `plpgsql` bodies (deferred validation, but loses the planner-friendly SQL function), duplicating table definitions.

**Consequences.** Migration order is explicit and the file remains declarative. Anyone adding a helper that reads a table must place it below that table.

---

## ADR-023 — Group visibility does not require the membership row to exist first

**Context.** The initial `groups_select_member` and `group_members_select_member` policies only allowed rows visible through `is_group_member()`. The app creates a group and then writes the owner's membership; between those two statements the creator could not read their own group. PostgREST surfaced this as `42501 new row violates row-level security policy` whenever a write asked for `return=representation`, and a queued/offline membership write could make the group disappear from the creator's list.

**Decision.** Migration `20261027000100_owner_visibility.sql` widens both read policies:

- `groups`: `owner_id = auth.uid() or is_group_member(id)`
- `group_members`: `user_id = auth.uid() or is_group_member(group_id)`

**Alternatives considered.** Insert the membership first (impossible, it references the group), wrap creation in an RPC (a valid future step, but the read policy would still be wrong), rely on `return=minimal` in the client (fragile).

**Consequences.** Owners always see their own groups, members always see their own membership row, and `insert ... returning` works. Neither clause exposes data the caller does not already own. Verified by the cloud smoke test.

---

## ADR-024 — Deleting an account cascades to the rows it authored

**Context.** `expenses.paid_by`, `expenses.created_by`, `settlements.*`, `activities.actor_id`, and `notifications.actor_id` referenced `auth.users(id)` without an `ON DELETE` action. Any user who had ever created an expense or settlement could not be deleted — the admin API returned 500 — which also made test cleanup impossible.

**Decision.** Migration `20261027000200_account_deletion.sql` recreates those foreign keys with `on delete cascade`, keeping the columns `NOT NULL`.

**Alternatives considered.** `ON DELETE SET NULL` (needs nullable columns and breaks "who paid"), archiving a tombstone profile (correct for a production ledger, but a bigger feature than this project needs), leaving `RESTRICT` and documenting manual cleanup (breaks account deletion entirely).

**Consequences.** Account deletion works and leaves no orphans. The trade-off is explicit: removing a user also removes the expenses and settlements they authored, so remaining members' balances change. A product that must preserve financial history should archive a tombstone user instead; the migration comment says so.

---

## ADR-025 — Cloud-only data path; no demo database

**Supersedes ADR-014.**

**Context.** Running `flutter run` without `--dart-define-from-file=env.json` silently booted a fake local demo with seeded people and groups. To a reviewer this looked like “the app is not connected to Supabase”, and it made the real cloud path the one nobody exercised.

**Decision.** Bake the linked project's URL and **public anon key** into `AppConfig` defaults, delete `DemoCloudGateway` and `DemoSeeder`, remove every demo entry point, and make `configureDependencies` require a real `SupabaseClient`. If the client cannot be constructed (bad URL/key), show a dedicated connection screen rather than fake data. Hive stays as the cache and offline outbox.

**Alternatives considered.** Keep demo as an opt-in flag (still two data paths and dead code); read `env.json` at runtime (Flutter has no runtime env file; it would become an asset); require flags forever (the original problem).

**Consequences.** A plain `flutter run` is a cloud run. The anon key is public by design; RLS is the security boundary, and no secret enters the app. Forks override the two values with `--dart-define`. There is no offline sample mode.

---

## ADR-026 — Email/password first; Google deferred

**Context.** The project has Google OAuth disabled. A Google button that always fails is worse than no button, and the ask was to skip it for now.

**Decision.** Remove the Google button, the `AuthGoogleRequested` event, `SignInWithGoogle`, and the repository method. Ship one auth path: email/password. Keep the rest of the `AuthBloc` untouched.

**Alternatives considered.** Leave the button disabled with a tooltip (still confusing); keep the code path dormant (analyzer-visible dead code).

**Consequences.** The auth screen is simpler and every button works. Re-enabling Google later means enabling the provider, restoring the method/event/button, and adding a redirect URI — documented in the README.

---

## ADR-027 — A paper-receipt identity, not a dashboard skin

**Supersedes the token specifics of ADR-017.**

**Context.** The first UI inherited the reference app's visual language: dark mint gradients, soft glowing cards, uppercase eyebrows, pill everything. The result was competent but close to `dompetektif` and to every finance dashboard.

**Decision.** Rebuild the identity around the product metaphor of a **shared receipt**:

- Warm paper background with a faint dot grid instead of radial glows.
- Pine green + tangerine + ink; full dark scheme from the same semantic tokens.
- *Bricolage Grotesque* headlines, *Outfit* UI text, *JetBrains Mono* amounts.
- Flat paper cards with a 1.2 px ink outline and a **hard 3 px offset shadow**.
- Perforated dashed rules, rubber-stamp “IMPAS”, and a painted three-wedge split mark (no stock wallet/coin icon).
- A global tangerine **Catat** action as the single “add” entry point.

**Alternatives considered.** Another green Material 3 theme (indistinguishable); a dark-first neon look (same as the reference); a serif “editorial” direction (too close to the reference's case-file serif).

**Consequences.** The app is recognisable at a glance and shares no signature surface with the reference. Fonts add ~260 KB. New colours must be added as tokens in `theme/app_theme.dart`.

---

## ADR-028 — One global add action; no duplicated chrome

**Context.** The shell rendered a page title, a notification bell, and an avatar, while every page rendered its own header and some rendered a second bell. On phones the group list header was squeezed into a one-word-per-line column by its action buttons.

**Decision.** The mobile chrome is a slim brand strip (mark + wordmark + sync + avatar) with **no page title and no bell**; the page below owns the heading. Destinations become Beranda, Grup, Notifikasi, Kamu. A single tangerine “Catat” FAB opens a quick-add sheet that asks *what* (manual expense / scan / new group) before *which group*. `PageHeader` stacks its actions below the title on narrow widths. Desktop uses a side rail with the same action.

**Alternatives considered.** Keep four tabs plus a second title bar (wastes ~90 px), put add inside each page (harder to find), a modal “+” menu in the nav (unusual on web).

**Consequences.** Less vertical chrome, one obvious add path, and the group header no longer collapses. The settings tab is labelled “Kamu” but still contains the full settings page.

---

## ADR-029 — One widget per file; pages orchestrate

**Context.** `core/widgets/fair_ui.dart` was ~930 lines, and four pages (expense form ~1,300 lines, receipt scan ~1,300, group detail ~1,000, home ~650) built every section as private methods in one file. Reviewing or changing one section meant scrolling through all of them.

**Decision.** Split the UI kit into 13 focused files behind a `fair_ui.dart` barrel, and move each page section into `features/<feature>/presentation/widgets/`. Pages keep only bloc wiring, routing, controllers, and layout. The expense form gets an `ExpenseFormControllers` bag so sections can own their own files without losing the page's state.

**Alternatives considered.** Dart `part` files (still one library, private state leaks); one giant `Widget build` per page (worse); a third-party design system (visual mismatch).

**Consequences.** Every screen now has a short page file and named, testable sections. The barrel keeps feature imports tidy. The cost is more files and some parameter passing.

---

## ADR-030 — A failed sync must not look synced

**Context.** `_pushOutbox` set an error status when a queued row failed, then `syncNow` unconditionally overwrote it with `idle` and cleared the message. Users saw a green “Tersinkron” chip while their expense was still in the outbox.

**Decision.** Stop the cycle on a failed push, keep the concrete error and pending count, and only emit `idle` when the push succeeded and `pullChanges` did not set an error.

**Alternatives considered.** Retry forever (battery/network cost, hides the problem); drop the row (data loss).

**Consequences.** The chip is honest, the pending badge stays, and tapping sync retries. A transient failure is visible until the next success.

---

## ADR-031 — Debt language and signs are explicit

**Context.** Two defects made balances easy to misread: the hero always rendered `+` because it passed `abs()` into a signed formatter, and the group card drew “Kamu utang” twice on narrow widths. “Kamu ditagih” was also used for money owed **to** the user, which is backwards.

**Decision.** Pass the signed value into `AmountText` and let the formatter choose `+`/`−`. Use **“Kamu menagih”** for credit and **“Kamu utang”** for debt. Label a member with positive net as **“Dihutangi”**. Remove the duplicate label from the compact group card. Add widget tests for the minus sign, plus sign, and Impas stamp.

**Alternatives considered.** Always show absolute values (ambiguous); colour-only signalling (inaccessible).

**Consequences.** Direction is readable from the sign and the words, not just colour. Tests lock the behaviour.

---

## ADR-032 — Enum columns tolerate both naming styles

**Context.** SQL RPCs write `member_joined` / `settlement_added`, while Dart's `kind.name` wrote `memberJoined`. The activity timeline silently fell back to a generic icon because parsing only matched camelCase.

**Decision.** Add `parseEnum` / `enumToSnake` helpers. Parsing normalises underscores and case; serialisation emits snake_case to match the server. Apply to activities and notifications. Test both directions.

**Alternatives considered.** Change the SQL RPCs (already deployed and used by seeds); accept only snake_case (breaks the existing local cache).

**Consequences.** Old local rows, server RPC rows, and new writes all parse. New rows are consistent with the server.

---

## ADR-033 — Conditional save bars live in the body, not in Scaffold.bottomNavigationBar

**Context.** Two screens changed their action bar at runtime: the profile page showed a save bar only after loading, and the receipt page showed one only after entering review. On Flutter Web both produced a blank body in Chrome (the engine also logged a negative `viewInsets` assertion from a browser resize) even though the same widgets rendered correctly in a widget test. Rewriting the profile page to a always-present body + inline save button fixed it; moving the scan save bar into a `Column` under the list fixed the review stage too.

**Decision.** Do not toggle `Scaffold.bottomNavigationBar` between null and a widget for a page's normal state changes. Persistent bars (the expense form) stay where they are; conditional bars are rendered inside the body, below an `Expanded(ListView)`, so they remain sticky without changing the Scaffold's slot structure. Hydrate text controllers when the stage that owns them becomes active, not on the page's first frame.

**Alternatives considered.** Keep the conditional bottom bars and ignore the web issue (unacceptable); render the action as a normal list item (loses the always-visible total); fill controllers on every build (would overwrite user edits).

**Consequences.** Save actions remain visible and the pages render on web and mobile. The receipt review now also shows the AI merchant/tax/service values instead of empty fields.

---

## ADR-034 — Notification writes use INSERT and PATCH, never upsert

**Context.** Two writes used the generic upsert and broke differently against PostgREST:

- Marking a received notification read re-sent the whole row. The INSERT policy requires `actor_id = auth.uid()`, but a received notification's actor is a friend, so the write failed with `42501`.
- Sending an expense notification to another member also used upsert. PostgREST's `resolution=merge-duplicates` needs SELECT access to the conflict target; the sender cannot read a notification addressed to someone else, so the INSERT policy chain failed with `42501` even for a brand-new row.

Both were reproduced against the live project: the same notification body returns 201 with a plain INSERT, 403 with `resolution=merge-duplicates`, and 204 with PATCH.

**Decision.** Add explicit `insert`, `patch`, and keep `upsert` as three outbox operations. `send` uses **insert** (duplicate key 23505 is treated as an idempotent replay). `markRead` uses **patch** with only `{read_at}`. The sync engine self-heals older queued items: a 42501 on a notification upsert is retried as a patch when `user_id` is the signed-in user and `read_at` is set, or as an insert when the notification is addressed to someone else. Permission failures surface as a short message, not a raw PostgREST string.

**Alternatives considered.** Broaden notification policies so senders can SELECT rows they created (works, but also makes upsert possible and exposes content unnecessarily); a security-definer RPC for both operations (valid, but the three generic operations are useful elsewhere); drop the queued item on failure (silently loses data).

**Consequences.** Read state and outbound notifications both sync. Old stuck queue items recover without user action. The outbox is explicit about create vs update, which is also easier to reason about during replay.

---

## ADR-035 — GitHub Pages is a branch deploy because Actions runners are blocked

**Context.** The account's Actions jobs are refused before any step with “The job was not started because your account is locked due to a billing issue.” The workflows themselves are valid; both the CI job and the Pages build fail at runner allocation. Pages still works when it builds from a branch, which does not consume Actions minutes.

**Decision.** Build the web bundle locally with `--base-href /bagi-fair/`, publish it to an orphan `gh-pages` branch with a `.nojekyll` file, and point Pages at that branch (`build_type: legacy`, source `gh-pages:/`). Keep `.github/workflows/pages.yml` and `ci.yml` in the repository, disabled, as the automation path once billing is resolved. Web invite links use GoRouter's hash route (`#/join/CODE`) so they work on a static host without a path-rewrite fallback.

**Alternatives considered.** Netlify/Vercel deploy (adds a third-party dependency to a GitHub Pages request); committing `build/web` to `main` and serving `/docs` (pollutes the source tree and requires a second build layout); waiting for billing (blocks delivery).

**Consequences.** The live site is current and deploys with plain `git push`. Automated CI is paused until the account is unbilled; the commands to re-enable it are in the README. Any web-only change needs a rebuild + `gh-pages` push.

---

## Deliberate non-goals (for now)

- Google sign-in (provider disabled; email/password only).
- Remote push notifications (FCM/APNs).
- iOS/macOS/Linux/Windows targets.
- Server-side PDF generation.
- Live FX-rate lookup.
- Field-level conflict merging.
- Receipt re-signing after the 7-day URL expiry.
- Bank/payment-provider integrations for actual money movement.
- An in-app account-deletion screen (the DB cascade exists).
