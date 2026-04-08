const { randomUUID } = require('crypto');
const { onRequest } = require('firebase-functions/v2/https');
const { admin, db } = require('./admin');

const DEFAULT_BASE_URL = process.env.WEB_FALLBACK_BASE_URL || 'https://actora.app';
const INVITES_COLLECTION = 'invites';
const METRICS_COLLECTION = 'metrics';
const METRICS_DOC_ID = 'viral';

exports.viralApi = onRequest({ cors: true }, async (request, response) => {
  setCommonHeaders(response);

  if (request.method === 'OPTIONS') {
    response.status(204).end();
    return;
  }

  const route = getRoute(request);

  try {
    if (request.method === 'POST' && route === 'api/invites') {
      await createInvite(request, response);
      return;
    }

    if (request.method === 'POST' && route.startsWith('api/invites/') && route.endsWith('/accept')) {
      await acceptInvite(request, response, route);
      return;
    }

    if (request.method === 'GET' && route.startsWith('api/invites/')) {
      await getInvite(request, response, route);
      return;
    }

    if (request.method === 'GET' && route === 'api/metrics') {
      await getMetrics(response);
      return;
    }

    if (request.method === 'GET' && route.startsWith('invite/')) {
      await renderInviteLanding(request, response, route);
      return;
    }

    if (request.method === 'GET' && route.startsWith('r/')) {
      response.redirect(302, `${DEFAULT_BASE_URL}/invite/${route.split('/')[1]}`);
      return;
    }

    response.status(404).json({ error: 'not_found' });
  } catch (error) {
    console.error('viralApi error', error);
    response.status(500).json({ error: error?.message || 'internal_error' });
  }
});

async function createInvite(request, response) {
  const senderId = String(request.body?.sender_id || '').trim();
  const senderLabel = String(request.body?.sender_label || 'Bir arkadaşın').trim() || 'Bir arkadaşın';
  const inviteId = normalizeInviteId(String(request.body?.invite_id || '').trim()) || randomUUID();
  const senderStreak = toInt(request.body?.sender_streak);
  const dayIndex = toInt(request.body?.day_index);
  const channel = String(request.body?.channel || 'share_sheet').trim() || 'share_sheet';
  const variant = String(request.body?.variant || 'A').trim() || 'A';

  if (!senderId) {
    response.status(400).json({ error: 'sender_id is required' });
    return;
  }

  if (!Number.isFinite(senderStreak) || !Number.isFinite(dayIndex)) {
    response.status(400).json({ error: 'sender_streak and day_index are required' });
    return;
  }

  const inviteRef = db.collection(INVITES_COLLECTION).doc(inviteId);
  const result = await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(inviteRef);
    if (existing.exists) {
      return existing.data();
    }

    const now = new Date();
    const invite = {
      invite_id: inviteId,
      sender_id: senderId,
      sender_label: senderLabel,
      sender_streak: senderStreak,
      day_index: dayIndex,
      channel,
      variant,
      status: 'pending',
      created_at: now,
      accepted_by: null,
      accepted_at: null,
      invite_url: `${DEFAULT_BASE_URL}/invite/${inviteId}`,
      opened_at: null,
      accepted_count: 0,
    };

    transaction.set(inviteRef, invite, { merge: false });
    transaction.set(metricsDocRef(), {
      total_sent: admin.firestore.FieldValue.increment(1),
      updated_at: now,
    }, { merge: true });
    return invite;
  });

  response.status(200).json(serializeInvite(result));
}

async function getInvite(request, response, route) {
  const inviteId = normalizeInviteId(route.replace(/^api\/invites\//, '').split('?')[0]);
  if (!inviteId) {
    response.status(400).json({ error: 'invite_id is required' });
    return;
  }

  const snapshot = await db.collection(INVITES_COLLECTION).doc(inviteId).get();
  if (!snapshot.exists) {
    response.status(404).json({ error: 'invite_not_found' });
    return;
  }

  response.status(200).json(serializeInvite(snapshot.data()));
}

async function acceptInvite(request, response, route) {
  const inviteId = normalizeInviteId(
    route.replace(/^api\/invites\//, '').replace(/\/accept$/, '').split('?')[0],
  );
  const acceptedBy = String(request.body?.accepted_by || '').trim();
  const acceptedLabel = String(request.body?.accepted_label || 'accepted').trim();

  if (!inviteId) {
    response.status(400).json({ error: 'invite_id is required' });
    return;
  }

  if (!acceptedBy) {
    response.status(400).json({ error: 'accepted_by is required' });
    return;
  }

  const inviteRef = db.collection(INVITES_COLLECTION).doc(inviteId);
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(inviteRef);
    if (!snapshot.exists) {
      return null;
    }

    const data = snapshot.data() || {};
    if (data.status === 'accepted') {
      if (data.accepted_by && data.accepted_by !== acceptedBy) {
        return data;
      }

      return data;
    }

    const now = new Date();
    const updated = {
      ...data,
      status: 'accepted',
      accepted_by: acceptedBy,
      accepted_label: acceptedLabel,
      accepted_at: now,
      accepted_count: (toInt(data.accepted_count) || 0) + 1,
    };

    transaction.set(inviteRef, updated, { merge: true });
    transaction.set(metricsDocRef(), {
      total_accepted: admin.firestore.FieldValue.increment(1),
      updated_at: now,
    }, { merge: true });
    return updated;
  });

  if (!result) {
    response.status(404).json({ error: 'invite_not_found' });
    return;
  }

  response.status(200).json(serializeInvite(result));
}

async function getMetrics(response) {
  const snapshot = await metricsDocRef().get();
  const data = snapshot.data() || {};
  const totalSent = toInt(data.total_sent) || 0;
  const totalAccepted = toInt(data.total_accepted) || 0;
  const viralCoefficient = totalSent === 0 ? 0 : totalAccepted / totalSent;

  response.status(200).json({
    total_sent: totalSent,
    total_accepted: totalAccepted,
    viral_coefficient: viralCoefficient,
    updated_at: serializeTimestamp(data.updated_at),
  });
}

async function renderInviteLanding(request, response, route) {
  const inviteId = normalizeInviteId(route.replace('invite/', '').split('?')[0]);
  const snapshot = await db.collection(INVITES_COLLECTION).doc(inviteId).get();
  const invite = snapshot.exists ? serializeInvite(snapshot.data()) : null;
  const title = invite
    ? `${invite.sender_label} seni meydan okudu`
    : 'Actora challenge';
  const body = invite
    ? `Gün ${invite.day_index}. Share üzerinden geldi. Uygulamayı aç ve devam et.`
    : 'Invite not found.';

  response.set('Content-Type', 'text/html; charset=utf-8');
  response.status(200).send(`<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Actora Invite</title>
  <style>
    :root { color-scheme: dark; }
    body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #050505; color: #fff; min-height: 100vh; display: grid; place-items: center; }
    main { width: min(560px, calc(100vw - 32px)); background: linear-gradient(180deg, rgba(255,255,255,0.06), rgba(255,255,255,0.03)); border: 1px solid rgba(255,255,255,0.1); border-radius: 28px; padding: 28px; box-sizing: border-box; }
    h1 { margin: 0 0 12px; font-size: 34px; line-height: 1.05; }
    p { margin: 0 0 16px; color: rgba(255,255,255,0.78); line-height: 1.5; }
    .pill { display: inline-flex; padding: 8px 12px; border-radius: 999px; background: rgba(255,255,255,0.08); margin-bottom: 18px; font-size: 12px; letter-spacing: 0.08em; text-transform: uppercase; }
    .actions { display: grid; gap: 12px; margin-top: 20px; }
    a, button { appearance: none; border: 0; border-radius: 16px; padding: 14px 16px; font-size: 16px; font-weight: 700; text-decoration: none; text-align: center; cursor: pointer; }
    .primary { background: #fff; color: #000; }
    .secondary { background: transparent; color: #fff; border: 1px solid rgba(255,255,255,0.18); }
    code { word-break: break-all; }
  </style>
</head>
<body>
  <main>
    <div class="pill">Actora challenge</div>
    <h1>${escapeHtml(title)}</h1>
    <p>${escapeHtml(body)}</p>
    <p>Invite: <code>${escapeHtml(inviteId || '')}</code></p>
    <div class="actions">
      <a class="primary" href="actora://actora/challenge?invite_id=${encodeURIComponent(inviteId || '')}">Open app</a>
      <button class="secondary" id="copy-link">Copy invite link</button>
    </div>
  </main>
  <script>
    const inviteId = ${JSON.stringify(inviteId || '')};
    const inviteUrl = ${JSON.stringify(invite ? invite.invite_url : `${DEFAULT_BASE_URL}/invite/${inviteId || ''}`)};
    try { if (inviteId) localStorage.setItem('actora_pending_invite_id', inviteId); } catch (_) {}
    const button = document.getElementById('copy-link');
    if (button) {
      button.addEventListener('click', async () => {
        try {
          await navigator.clipboard.writeText(inviteUrl);
          button.textContent = 'Copied';
        } catch (_) {
          window.prompt('Copy this link', inviteUrl);
        }
      });
    }
  </script>
</body>
</html>`);
}

function serializeInvite(data) {
  if (!data) {
    return null;
  }

  return {
    invite_id: data.invite_id || '',
    sender_id: data.sender_id || '',
    sender_label: data.sender_label || 'Bir arkadaşın',
    sender_streak: toInt(data.sender_streak) || 0,
    day_index: toInt(data.day_index) || 0,
    channel: data.channel || 'share_sheet',
    variant: data.variant || 'A',
    status: data.status || 'pending',
    created_at: serializeTimestamp(data.created_at),
    accepted_by: data.accepted_by || null,
    accepted_at: serializeTimestamp(data.accepted_at),
    invite_url: data.invite_url || `${DEFAULT_BASE_URL}/invite/${data.invite_id || ''}`,
  };
}

function serializeTimestamp(value) {
  if (!value) {
    return null;
  }

  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  return value;
}

function metricsDocRef() {
  return db.collection(METRICS_COLLECTION).doc(METRICS_DOC_ID);
}

function getRoute(request) {
  const url = new URL(
    request.path || request.originalUrl || request.url || '/',
    'https://actora.app',
  );
  return url.pathname.replace(/^\/+/, '');
}

function normalizeInviteId(value) {
  return /^[0-9a-f-]{8,36}$/i.test(value) ? value : '';
}

function toInt(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.trunc(parsed) : 0;
}

function setCommonHeaders(response) {
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.set('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  response.set('Cache-Control', 'no-store');
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
