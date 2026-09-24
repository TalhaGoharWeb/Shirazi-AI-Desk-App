# Shirazi Oracle Integration Contract

This document is the single source of truth for how the Shirazi AI Desk App
talks to the Shirazi Oracle Server. It is based on **observed behavior** against
the live server (`https://shirazi-oracle.140-238-250-139.sslip.io`, hardened and verified 2026-09-24 UTC), not on
assumptions. Anything not observed is marked as such.

## Core guarantee

> The app MUST ALWAYS obtain its Islamic research answers through the Shirazi
> Oracle Server. It NEVER silently uses a generic AI, local/mock/hardcoded
> response, or a direct provider API. User-provided provider keys are only ever
> transmitted to the Oracle, which runs its own research / retrieval /
> verification pipeline with them.

- The old direct client-side provider path (`_executeDirectClientByok`, direct
  Groq/Gemini/OpenRouter REST calls) has been **deleted** from the codebase.
- If the Oracle cannot answer, the app shows an honest, localized failure
  notice, preserves the question for 1-tap retry, and never substitutes an AI
  answer.

## Oracle endpoints (observed)

| Endpoint | Method | Auth | Observed behavior |
|---|---|---|---|
| `/api/health` | GET | none | 200 `{ok, gateway, channels, services}` |
| `/api/scholar/fatwas` | GET | none | 200 `{ok, count, fatwas}` |
| `/api/scholar/fatwa/{id}` | GET | none | assumed by client; detail contract not fully tested |
| `/api/chat` | POST | none | assumed; server-side BYOK contract untested against server source |
| Socket.IO `/socket.io/` | socket.io | none | `emit("chat", {text, persona, lang, madhhab, user_keys, provider_priority, channel})`; receives `agent-progress` and `assistant-message` events |

- Socket.IO works over **polling**; websocket upgrade failed through the test
  environment's proxy (may be environment-specific).
- Typical research request takes **30–90s** (observed 44.8s). Client timeout is
  **150s** — never shorter than a realistic research cycle.
- Answers are complete and displayed **without truncation or rewriting**;
  Urdu/Arabic/English, Markdown, RTL/LTR, citations, tables are preserved.
- The server currently issues **no request IDs, response IDs, API version, or
  signature**. Client-side provenance fields (`source`, `request_id`,
  `transport`, `oracle_url`, `answered_at`, `latency_ms`) are **client-observed
  transport metadata** — they prove the answer arrived over the Oracle channel
  but do not cryptographically authenticate the server. Labels in the UI must
  not imply more.

## Failure taxonomy

| Result status | Meaning | App behavior |
|---|---|---|
| `SUCCESS` | Oracle answer via pipeline | Displayed verbatim; requires `source == 'shirazi-oracle'` |
| `QUOTA_EXHAUSTED` | Oracle pipeline ran but inference capacity spent (or HTTP 429 / outage text) | Localized notice, no substitute answer, question preserved, optional retry via Shirazi pipeline with user's key |
| `EXHAUSTED` | Transport failed + no verified fatwa matched; auth rejected (401/403); untrusted result refused | Localized notice, question preserved for retry |
| madhhab mismatch | Server cached answer contradicts requested madhhab | Rejected as untrusted; never displayed |

- `isLimitOrOutage()` detects outage wording in Urdu, Arabic, and English.
- After a **delivered-but-unanswered** socket attempt, the app does **not**
  auto-resubmit over HTTP (avoids duplicate research jobs); the user retries
  explicitly. HTTP transport is used only when the socket channel itself was
  never established.

## BYOK policy

- Keys are stored on-device, obfuscated with a device-bound XOR cipher
  (`enc_` prefix). Plaintext keys from older builds still read back.
- The settings screen copy is explicit: keys are sent **only to your Shirazi
  Oracle server** (which runs its research pipeline with them) — never for
  direct AI answers, and never while a no-key Oracle answer is possible.
- Keys travel to the Oracle inside the `user_keys` payload. **Current transport
  is plain HTTP — keys and questions are not TLS-protected.** Do not use with
  real keys until the Oracle is served over HTTPS (server-side work required).

## Firebase / Firestore

- Rules enforce per-user isolation: `ownerUid` must equal the caller's
  `request.auth.uid` on every conversation, message, and inquiry document.
- Known issue: users can write their own `/users/{uid}` doc and `isAdmin()`
  trusts its `role` field — a user can self-promote to admin. Fix requires
  protected custom claims or server-controlled role docs (not yet done).
- A super-admin email is hardcoded in the rules.

## What is NOT yet done (server-side access needed)

1. Oracle authentication (Firebase ID token or other) on chat/health/fatwa calls.
2. Server-issued request/response IDs, API version, and source metadata.
3. Verified server-side BYOK handling (`POST /api/chat` contract per server source).
4. HTTPS termination for the Oracle.
5. Firestore admin-claims fix.
6. Release build + Firebase-emulator two-user isolation tests + full mock-Oracle
   failure matrix (401/403/404/408/429/5xx, timeout, malformed, cancellation,
   duplicate prevention).

## Running / testing

1. `flutter pub get`
2. `flutter analyze` / `flutter test`
3. Debug: `flutter run`; release APK: `flutter build apk --release`
4. Firebase: configure `google-services.json` / `GoogleService-Info.plist`,
   enable Email/Google auth, create `conversations`, `inquiries`, `users`
   collections (rules in `firestore.rules`).
5. Point the app at your Oracle in Settings → Server URL.

## Test evidence (2026-09-22 UTC)

- Real end-to-end Socket.IO test with an Urdu fiqh question: transport,
  persona, progress pipeline verified; server returned its standard capacity
  notice after ~44s (`{answer, route}` only) — a genuine answer was not
  producible that day due to upstream quota. Re-run after quota recovery.
- Static checks: brace/paren balance clean on all edited files; no remaining
  references to removed direct-provider code.
- Not yet run: `flutter analyze` / `flutter test` (no Flutter toolchain in the
  audit sandbox); release build; Firebase emulator tests.

## Production hardening (2026-09-22, branch `oracle-production-hardening`)

### Transport security (§1, §5)
- `lib/services/oracle_protocol.dart` (new, pure Dart, zero Flutter imports):
  `OracleEndpoint` parsing/validation, `isSecure`, `socketScheme` (wss/ws),
  log-safe `redacted` form, `SUPPORTED_BYOK_PROVIDERS` allowlist, HTTP →
  `OracleFailure` taxonomy, UUID v4 `generateRequestId()`, `hasOracleProvenance()`
  gate, `requestIdMatches()`, allowlist-filtered `priorityListFor()`, plus all
  localized failure messages.
- `ApiService` REFUSES to transmit user API keys over plain HTTP, unconditionally
  in release builds (the old user-facing `allowInsecureHttp` toggle has been
  removed; only a debug-build-only test hook remains, with no UI). Questions
  without keys still work over HTTP with a warning.
- Socket.IO: Firebase ID token attached via `setAuth({'token': idToken})` on
  connect (§11); `request_id` (UUID v4) sent in the `chat` payload and POST body;
  echoed request IDs are validated (§9).
- Settings shows a live transport banner: "Secure connection (HTTPS/WSS)" vs
  "Insecure connection (HTTP)" (§1).
- Live verification 2026-09-24: the Oracle serves HTTPS at
  `https://shirazi-oracle.140-238-250-139.sslip.io` (Let's Encrypt, HSTS);
  public ports are 443/80 only — 4040/8000/8020/8080 are closed externally.

### BYOK key storage (§7) — honest security model
- The old device-bound XOR `enc_` cipher was obfuscation, not encryption. It is
  gone for new writes.
- Keys now live in `flutter_secure_storage` (Android Keystore / iOS Keychain,
  `encryptedSharedPreferences` on Android), cached in memory after
  `loadSecureKeys()`. Legacy prefs values migrate once, then are deleted.
- UI copy corrected: "secure device storage", never "encrypted" as a
  cryptographic claim beyond what the platform provides.
- In transit: HTTPS only (enforced). Never logged, never in Firestore, never in
  analytics/crash reports. Key validation uses header-based auth
  (`x-goog-api-key`), never URL query params; errors never print exceptions.

### Provenance & request tracing (§9, §10)
- Every request carries a UUID v4 `request_id` through socket + HTTP fallback.
- `hasOracleProvenance()`: a `SUCCESS` result without `source == 'shirazi-oracle'`
  is refused. Server-issued IDs/signatures still require Oracle changes.

### Firestore authorization (§2, §3, §12, §13)
- `firestore.rules` rewritten: roles ONLY from custom claims
  (`request.auth.token.role` / `.admin` / `.superAdmin`). The old rules trusted
  `users/{uid}.role`, which users could write themselves — fixed.
- Profile writes whitelisted to non-privileged fields; `role`/`isAdmin`/etc.
  rejected on every client write. Conversations/messages/inquiries enforce
  `ownerUid == request.auth.uid`. Default-deny everything else.
- `tools/set_super_admin_claim.mjs`: Admin-SDK script assigning the
  `super_admin` claim to `muhaqqiqcreates@gmail.com` (verifies the account
  exists; never creates users; never commits credentials).
- Client `checkIsAdmin()`/`isSuperAdmin` now read custom claims only (plus a
  verified-email bootstrap for the designated super-admin); the Firestore role
  lookup and substring email matching are removed.

### Failure-matrix tests (§19) — ACTUALLY RUN
- `test/oracle_protocol_test.dart`: 46 tests, all passing, executed with the
  standalone Dart SDK 3.13.4 (`dart test`) on 2026-09-22. `dart analyze` clean.
- Covers: full HTTP status taxonomy, quota/outage detection (ur/ar/en,
  including the exact live-server Urdu message), provenance gate, request-ID
  matching, BYOK allowlist (rejects arbitrary URLs), endpoint parsing/redaction,
  UUID v4 shape, message honesty.

### Bitcoin re-test (§18) — 2026-09-22
- Re-ran the exact question. Pipeline progress events observed (~44s), then the
  same quota-exhaustion notice. No genuine answer — Oracle upstream capacity
  still exhausted. §18 success criteria remain blocked on the server side.

### Still requires server access (not done, documented in docs/DEPLOYMENT.md)
HTTPS/WSS on the host, token verification + per-user socket rooms, server-issued
request/response IDs, `SUPPORTED_PROVIDERS` enforcement, encrypted server-side
BYOK handling, rate limits, honest progress states, quota→BYOK→notice flow.
