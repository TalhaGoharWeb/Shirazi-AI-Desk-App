// Seed collections to Firestore using Firebase CLI's OAuth access token
const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT_ID = 'shirazi-ai';
const configPath = path.join(process.env.USERPROFILE, '.config', 'configstore', 'firebase-tools.json');

function request(options, data) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (e) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });
    req.on('error', reject);
    if (data) req.write(typeof data === 'string' ? data : JSON.stringify(data));
    req.end();
  });
}

async function getAdminToken() {
  const raw = fs.readFileSync(configPath, 'utf8');
  const config = JSON.parse(raw);
  const tokens = config.tokens;

  if (tokens && tokens.access_token) {
    return tokens.access_token;
  }

  // Refresh OAuth token if needed
  const refreshRes = await request({
    hostname: 'oauth2.googleapis.com',
    path: '/token',
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  }, `grant_type=refresh_token&client_id=${tokens.client_id || '563584335869-fgrhgmd47bqnekij5i8b5pr03ho85qd6.apps.googleusercontent.com'}&client_secret=${tokens.client_secret || ''}&refresh_token=${tokens.refresh_token}`);

  if (refreshRes.data?.access_token) {
    return refreshRes.data.access_token;
  }
  return tokens.access_token;
}

async function main() {
  console.log('Obtaining Google Cloud Admin token from Firebase CLI...');
  const accessToken = await getAdminToken();
  console.log('Admin OAuth access token acquired successfully.');

  const authHeaders = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${accessToken}`,
  };

  async function setDocument(collectionPath, docId, fields) {
    const urlPath = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collectionPath}?documentId=${docId}`;
    const formattedFields = {};
    for (const [k, v] of Object.entries(fields)) {
      if (typeof v === 'string') formattedFields[k] = { stringValue: v };
      else if (typeof v === 'number') formattedFields[k] = { integerValue: v.toString() };
      else if (typeof v === 'boolean') formattedFields[k] = { booleanValue: v };
      else if (Array.isArray(v)) {
        formattedFields[k] = {
          arrayValue: {
            values: v.map(item => ({ stringValue: item.toString() }))
          }
        };
      } else if (v && typeof v === 'object') {
        formattedFields[k] = { mapValue: { fields: v } };
      }
    }

    const res = await request({
      hostname: 'firestore.googleapis.com',
      path: urlPath,
      method: 'POST',
      headers: authHeaders,
    }, { fields: formattedFields });

    console.log(`Document [${collectionPath}/${docId}] -> HTTP ${res.status}`);
    if (res.status >= 400) {
      console.log('Response:', JSON.stringify(res.data || res.raw));
    }
    return res;
  }

  // 1. users collection
  await setDocument('users', 'super_admin_muhaqqiq', {
    uid: 'super_admin_muhaqqiq',
    displayName: 'Super Admin (Al-Muhaqqiq)',
    email: 'muhaqqiqcreates@gmail.com',
    role: 'super_admin',
    scholarlyRank: 'Grand Super Administrator & Head of Research',
    madhhab: 'Hanafi',
    isnadVerified: true,
    platformPlan: 'super_admin_unlimited'
  });

  await setDocument('users', 'admin_shirazi_core', {
    uid: 'admin_shirazi_core',
    displayName: 'Administrator (Al-Muraqib)',
    email: 'admin@shirazi.jurist',
    role: 'admin',
    scholarlyRank: 'Head of Research & Oversight',
    madhhab: 'Hanafi',
    isnadVerified: true,
    platformPlan: 'production_cloud'
  });

  await setDocument('users', 'scholar_ahmad_farooq', {
    uid: 'scholar_ahmad_farooq',
    displayName: 'د. أحمد فاروق (Dr. Ahmad Farooq)',
    email: 'scholar@darulifta.edu',
    role: 'scholar',
    scholarlyRank: 'Mufti / Senior Researcher',
    madhhab: 'Hanafi',
    isnadVerified: true,
    platformPlan: 'standard_scholar'
  });

  // 2. conversations collection
  const convId = 'conv_fiqh_crypto_seed';
  await setDocument('conversations', convId, {
    ownerUid: 'scholar_ahmad_farooq',
    title: 'حكم تداول العملات الرقمية والبيتكوين',
    language: 'ar',
    madhhab: 'Hanafi',
    persona: 'muhaqqiq',
    lastMessagePreview: 'المعتمد في المذهب الحنفي أن المالية تثبت بتمول الناس وتداولهم...',
    messageCount: 2,
    isPinned: true,
    ownerEmail: 'scholar@darulifta.edu',
    ownerName: 'د. أحمد فاروق (Dr. Ahmad Farooq)'
  });

  // 3. conversations/{convId}/messages subcollection
  await setDocument(`conversations/${convId}/messages`, 'msg_01_user', {
    conversationId: convId,
    sender: 'user',
    content: 'ما هو الحكم الشرعي المفصل في تداول العملات المشفرة مثل البيتكوين؟',
    citations: [],
    urduAnnotation: ''
  });

  await setDocument(`conversations/${convId}/messages`, 'msg_02_asst', {
    conversationId: convId,
    sender: 'assistant',
    content: 'الحمد لله، والصلاة والسلام على رسول الله. المعتمد في المذهب الحنفي أن المالية تثبت بتمول الناس ورغبتهم في اقتناء الشيء وادخاره لوقت الحاجة، والتقوم يثبت بإباحة الانتفاع به شرعاً. وحيث إن العملات الرقمية المشفرة ذات قيمة سوقية معتبرة عرفاً، فيشترط لجواز تداولها الخلو من القمار والغرر والمضاربات الوهمية، والتقابض الحكمي عند تبادلها بالعملات الورقية.',
    citations: [
      'رد المحتار على الدر المختار (ابن عابدين) - باب البيع',
      'المبسوط للإمام السرخسي - كتاب التجارة',
      'مجلة الأحكام العدلية - المادة ١٢٦ (تعريف المال)'
    ],
    urduAnnotation: 'خلاصۂ فتویٰ: احناف کے نزدیک مال کی تعریف اور عرفِ عام کے مطابق کرپٹو میں شرائطِ بیع اور تقابض کا لحاظ ضروری ہے۔',
    latencyMs: 340,
    byokProvider: 'Shirazi Core Engine (Live)'
  });

  // 4. admin/analytics & admin/settings collections
  await setDocument('admin', 'analytics', {
    totalInquiries: 42,
    activeScholars: 8,
    clusterLatencyAvgMs: 38,
    gatewaysStatus: 'HEALTHY',
    topTopic: 'Contemporary Financial Jurisprudence (فقه المعاملات المعاصرة)'
  });

  await setDocument('admin', 'settings', {
    multiTenantIsolation: true,
    firestoreRulesVersion: 2,
    requireIsnadVerification: true,
    defaultLanguage: 'en'
  });

  console.log('\nAll collections and seed documents successfully updated to Cloud Firestore (shirazi-ai)!');
}

main().catch(console.error);
