# Shirazi Oracle — Production Deployment Runbook

Step-by-step deployment for the production hardening in branch
`oracle-production-hardening`. Server-side steps require access to the Oracle
host (129.154.242.136) — they cannot be done from the app repository alone.

---

## 1. HTTPS for the Oracle server (§1)

**Status: NOT DONE — requires server access. Verified 2026-09-22: the live
server answers HTTP 200 on port 4040 and offers no TLS.**

Recommended: Caddy (automatic Let's Encrypt) in front of the Oracle.

```bash
# On the Oracle host (Ubuntu example)
sudo apt install -y caddy

# /etc/caddy/Caddyfile  — replace oracle.example.com with your domain
oracle.example.com {
    reverse_proxy 127.0.0.1:4040
}
# Caddy obtains the certificate automatically and redirects HTTP -> HTTPS.

sudo systemctl reload caddy
```

Alternatives:
- **Nginx + certbot**: `sudo certbot --nginx -d oracle.example.com`, then
  `proxy_pass http://127.0.0.1:4040;` plus `proxy_set_header Upgrade $http_upgrade;`
  for the Socket.IO websocket upgrade.
- **Cloudflare**: point DNS at the host, enable "Full (strict)" SSL mode,
  install a Cloudflare Origin certificate on the host.

Verification (from any machine):
```bash
curl -sI https://oracle.example.com/api/health   # expect 200, valid cert
# In the app: Settings -> connection banner must show
# "Secure connection (HTTPS/WSS)"
```

Then update the app default: `StorageService.serverUrl` default and the
`ApiService(baseUrl: ...)` default to `https://oracle.example.com`, or set it
once in the app — it is stored in preferences.

**Do not** put the TLS private key or any credentials in the repository.

## 2. Firebase custom claims (§2, §3)

**Status: client + rules + tooling DONE. Claim assignment requires someone
with a Firebase service-account key to run the script once.**

```bash
cd <repo>
npm install firebase-admin   # one-time, inside tools/ or global NODE_PATH

# Assign super_admin to the designated account (verifies it exists first):
node tools/set_super_admin_claim.mjs \
  --email muhaqqiqcreates@gmail.com \
  --service-account /secure/path/serviceAccount.json

# Assign a plain admin:
node tools/set_super_admin_claim.mjs \
  --email someone@example.com --role admin \
  --service-account /secure/path/serviceAccount.json

# Remove admin claims:
node tools/set_super_admin_claim.mjs --email someone@example.com --remove \
  --service-account /secure/path/serviceAccount.json
```

The user must sign out/in (or refresh the ID token) afterwards.
Never commit `serviceAccount.json`.

## 3. Firestore rules (§2, §12, §13)

**Status: rules rewritten — needs `firebase deploy`.**

```bash
firebase deploy --only firestore:rules
```

What changed:
- `isAdmin()` / `isSuperAdmin()` check ONLY `request.auth.token.role`,
  `request.auth.token.admin`, `request.auth.token.superAdmin` (custom claims).
- Users can write ONLY whitelisted profile fields on their own document;
  `role`/`isAdmin`/`admin`/`superAdmin` are rejected on every client write.
- Conversations/messages/inquiries enforce `ownerUid == request.auth.uid`.
- Default-deny for all other paths.

Two-user isolation test (Firebase emulator, not yet run):
```bash
firebase emulators:start --only firestore
# then run the emulator test suite (to be added under test/)
# 1. user A creates a conversation -> user B reads -> expect PERMISSION_DENIED
# 2. user A writes {role:'admin'} to own profile -> expect PERMISSION_DENIED
# 3. super_admin claim can read /admin/*
```

## 4. Oracle server hardening checklist (§8–§17)

**Status: NOT DONE — requires Oracle source/host access.** Hand this to the
server owner:

- [ ] Serve HTTPS only (§1); Socket.IO over WSS.
- [ ] Verify Firebase ID tokens on socket connect AND on each HTTP request;
      derive user identity from the token — never trust client `userId`/`role`.
- [ ] Scope Socket.IO rooms per user; no cross-user subscription (§11, §12).
- [ ] Mint `request_id` (UUID) per request; echo it plus `response_id`,
      `source: "shirazi-oracle"`, `status`, timestamps, provider/model used —
      never the user's API key (§9, §10).
- [ ] Enforce `SUPPORTED_PROVIDERS = ["groq","gemini","openrouter"]`; reject
      arbitrary provider URLs / instructions (§8).
- [ ] Server-side BYOK: accept `{provider, model, credential, request_id,
      conversation_id}` over HTTPS only; use the key ONLY as inference
      capacity inside the existing Shamela → agents → verification → Shirazi
      instructions pipeline (§4, §6, §17). Never persist keys; never log them
      (redact as `sk-****abcd` or omit entirely) (§5).
- [ ] Quota-exhausted flow: primary exhausted → authorized user BYOK via the
      same pipeline → else honest capacity notice, question preserved (§16).
- [ ] Rate limiting per user/IP/endpoint that tolerates ~45s+ research jobs;
      heartbeats/progress events; cancellation support (§14, §15).
- [ ] Real progress states from the pipeline (never fabricated):
      `تحقیق جاری ہے... / تحلیل سوال... / تلاش در مصادر... / مقابلہ و تحقیق... /
      تحقق... / ترکیب جواب...` (§15).

## 5. Flutter production configuration

**Status: client code DONE — needs `flutter pub get` + build on the
user's Windows machine (no Flutter SDK in this environment).**

```powershell
flutter pub get
flutter analyze        # must pass
flutter test           # protocol tests (test/oracle_protocol_test.dart)
flutter build apk --release
```

Production notes:
- `flutter_secure_storage` added for BYOK keys (Android Keystore / iOS
  Keychain, encryptedSharedPreferences on Android). Run `flutter pub get`.
- `allowInsecureHttp` defaults to false: with the current HTTP-only Oracle,
  API keys will be BLOCKED from transmission until HTTPS is deployed —
  this is intentional (§5).
- The app keeps working for key-less questions over HTTP with a visible
  "Insecure connection" banner in Settings.

## 6. Verification matrix (run after deploy)

- [ ] `flutter analyze` / `flutter test` pass
- [ ] HTTPS health, HTTPS Socket.IO, WSS connect with Firebase ID token
- [ ] BYOK fallback over HTTPS: quota exhausted → user key → real pipeline answer
- [ ] Bitcoin question returns a Bitcoin-relevant, madhhab-consistent,
      citation-honest answer with provenance metadata
- [ ] Two-user Firestore isolation test passes
- [ ] Admin escalation attempt (self-written role) is denied
- [ ] No API key appears in any log, error, analytics, or crash report
