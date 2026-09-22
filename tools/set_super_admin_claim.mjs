#!/usr/bin/env node
/**
 * set_super_admin_claim.mjs — Assign the super_admin custom claim (§3).
 *
 * Usage:
 *   node tools/set_super_admin_claim.mjs --email muhaqqiqcreates@gmail.com
 *   node tools/set_super_admin_claim.mjs --email user@example.com --remove
 *   node tools/set_super_admin_claim.mjs --email user@example.com --role admin
 *
 * Auth: set GOOGLE_APPLICATION_CREDENTIALS to a Firebase service-account
 * JSON key file, OR pass --service-account /path/to/key.json.
 *
 * NEVER commit the service-account key to the repository.
 *
 * What it does:
 * 1. Looks up the Firebase Authentication user by email (verifies the
 *    account exists — it will NOT create one).
 * 2. Sets (or removes) server-controlled custom claims:
 *      { role: 'super_admin', superAdmin: true }
 *    These claims are what firestore.rules and the Oracle server check.
 *    Client-writable Firestore fields are never trusted for authorization.
 * 3. Prints a redacted confirmation (uid prefix only, no secrets).
 */

import { readFileSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
let admin;
try {
  admin = require('firebase-admin');
} catch {
  console.error(
    'Missing dependency: firebase-admin.\n' +
    'Run: npm install firebase-admin   (inside tools/ or with NODE_PATH set)'
  );
  process.exit(1);
}

function arg(name) {
  const i = process.argv.indexOf(name);
  return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : null;
}
function has(name) {
  return process.argv.includes(name);
}

async function main() {
  const email = arg('--email');
  const serviceAccountPath =
    arg('--service-account') || process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const remove = has('--remove');
  const role = arg('--role') || 'super_admin';

  if (!email) {
    console.error('Usage: node tools/set_super_admin_claim.mjs --email <address> [--remove] [--role admin|super_admin]');
    process.exit(1);
  }
  if (!['admin', 'super_admin'].includes(role)) {
    console.error(`Invalid --role "${role}". Use admin or super_admin.`);
    process.exit(1);
  }

  if (serviceAccountPath) {
    if (!existsSync(serviceAccountPath)) {
      console.error(`Service account file not found: ${serviceAccountPath}`);
      process.exit(1);
    }
    const key = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({ credential: admin.credential.cert(key) });
    console.log(`Using service account: ${key.client_email ?? '(unknown client_email)'}`);
  } else {
    // Application Default Credentials (gcloud / metadata server)
    admin.initializeApp();
    console.log('Using Application Default Credentials.');
  }

  const auth = admin.auth();

  // 1. Verify the Firebase Authentication account exists.
  let user;
  try {
    user = await auth.getUserByEmail(email);
  } catch (e) {
    console.error(`No Firebase Authentication account found for ${email}.`);
    console.error('Create / verify the account in the Firebase console first — this script never creates users.');
    process.exit(1);
  }
  if (!user.emailVerified) {
    console.warn(
      `WARNING: ${email} has NOT verified its email address. ` +
      'Consider requiring verification before granting super_admin.'
    );
  }

  // 2. Merge custom claims (preserve any unrelated existing claims).
  const existing = user.customClaims || {};
  let next;
  if (remove) {
    next = { ...existing };
    delete next.role;
    delete next.admin;
    delete next.superAdmin;
    console.log(`Removing admin claims from ${email} ...`);
  } else {
    next = {
      ...existing,
      role,
      admin: true,
      ...(role === 'super_admin' ? { superAdmin: true } : {}),
    };
    if (role === 'admin') delete next.superAdmin;
    console.log(`Setting claims on ${email}: role=${role}`);
  }

  await auth.setCustomUserClaims(user.uid, next);

  // 3. Redacted confirmation — uid prefix only, no secrets, no keys.
  const refreshed = await auth.getUser(user.uid);
  console.log('Done.');
  console.log(`  uid: ${user.uid.slice(0, 8)}…`);
  console.log(`  email: ${email}`);
  console.log(`  emailVerified: ${!!refreshed.emailVerified}`);
  console.log(`  customClaims: ${JSON.stringify(refreshed.customClaims)}`);
  console.log('Note: the user must sign out and back in (or refresh their ID token) for claims to take effect.');
}

main().catch((e) => {
  console.error('FAILED:', e.message);
  process.exit(1);
});
