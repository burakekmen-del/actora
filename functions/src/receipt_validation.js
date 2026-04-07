const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const { google } = require('googleapis');
const { admin, db } = require('./admin');

const appleSharedSecret = defineSecret('APPLE_SHARED_SECRET');
const appleBundleId = defineString('APPLE_BUNDLE_ID', { default: '' });
const googlePackageName = defineString('GOOGLE_PACKAGE_NAME', { default: '' });

exports.validatePurchase = onCall({ secrets: [appleSharedSecret] }, async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const platform = normalizePlatform(request.data?.platform);
  const productId = String(request.data?.productId || '').trim();

  if (!platform || !productId) {
    throw new HttpsError('invalid-argument', 'platform and productId are required.');
  }

  if (platform === 'ios') {
    const receipt = String(request.data?.receipt || '').trim();
    if (!receipt) {
      throw new HttpsError('invalid-argument', 'receipt is required for iOS validation.');
    }

    const validation = await validateAppleReceipt({
      receipt,
      productId,
      sharedSecret: appleSharedSecret.value(),
    });

    await writePremiumState({ userId, validation });
    return validation;
  }

  if (platform === 'android') {
    const purchaseToken = String(request.data?.purchaseToken || '').trim();
    if (!purchaseToken) {
      throw new HttpsError('invalid-argument', 'purchaseToken is required for Android validation.');
    }

    const packageName = googlePackageName.value();
    if (!packageName) {
      throw new HttpsError('failed-precondition', 'GOOGLE_PACKAGE_NAME is not configured.');
    }

    const validation = await validateGoogleSubscription({
      packageName,
      productId,
      purchaseToken,
    });

    await writePremiumState({ userId, validation });
    return validation;
  }

  throw new HttpsError('invalid-argument', 'Unsupported platform.');
});

async function validateAppleReceipt({ receipt, productId, sharedSecret }) {
  const production = await callAppleVerifyReceipt({ receipt, sharedSecret, endpoint: 'https://buy.itunes.apple.com/verifyReceipt' });

  if (production.status === 21007) {
    return callAppleVerifyReceipt({
      receipt,
      sharedSecret,
      endpoint: 'https://sandbox.itunes.apple.com/verifyReceipt',
      isSandbox: true,
      fallbackProductId: productId,
    });
  }

  if (production.status !== 0) {
    return {
      isValid: false,
      expiryDate: null,
      isPremium: false,
      isSandbox: false,
      message: `Apple validation failed with status ${production.status}`,
    };
  }

  return extractAppleValidation({ response: production, productId, isSandbox: false });
}

async function callAppleVerifyReceipt({ receipt, sharedSecret, endpoint, isSandbox = false }) {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      'receipt-data': receipt,
      password: sharedSecret,
      'exclude-old-transactions': false,
    }),
  });

  const body = await response.json();
  return {
    status: body.status,
    body,
    isSandbox,
  };
}

function extractAppleValidation({ response, productId, isSandbox }) {
  const configuredBundleId = appleBundleId.value();
  const receiptBundleId = response.body?.receipt?.bundle_id || response.body?.receipt?.bundleId;

  if (configuredBundleId && receiptBundleId && receiptBundleId !== configuredBundleId) {
    return {
      isValid: false,
      expiryDate: null,
      isPremium: false,
      isSandbox,
      message: 'Bundle ID mismatch.',
    };
  }

  const latest = [...(response.body.latest_receipt_info || []), ...(response.body.receipt?.in_app || [])]
    .filter((item) => item.product_id === productId)
    .sort((a, b) => Number(b.expires_date_ms || b.expiration_date_ms || 0) - Number(a.expires_date_ms || a.expiration_date_ms || 0))[0];

  const expiryMs = Number(latest?.expires_date_ms || latest?.expiration_date_ms || 0);
  const canceled = Boolean(latest?.cancellation_date_ms);
  const isPremium = expiryMs > Date.now() && !canceled;

  return {
    isValid: isPremium,
    expiryDate: expiryMs ? new Date(expiryMs).toISOString() : null,
    isPremium,
    isSandbox,
    message: isPremium ? null : 'Subscription is inactive or expired.',
  };
}

async function validateGoogleSubscription({ packageName, productId, purchaseToken }) {
  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  const client = await auth.getClient();
  const androidpublisher = google.androidpublisher({ version: 'v3', auth: client });

  const response = await androidpublisher.purchases.subscriptions.get({
    packageName,
    subscriptionId: productId,
    token: purchaseToken,
  });

  const expiryMs = Number(response.data.expiryTimeMillis || 0);
  const isPremium = expiryMs > Date.now();

  return {
    isValid: isPremium,
    expiryDate: expiryMs ? new Date(expiryMs).toISOString() : null,
    isPremium,
    isSandbox: false,
    message: isPremium ? null : 'Subscription is inactive or expired.',
  };
}

async function writePremiumState({ userId, validation }) {
  const userRef = db.collection('users').doc(userId);

  await userRef.set(
    {
      consistencyModeActive: validation.isPremium,
      premiumExpiryDate: validation.expiryDate ? admin.firestore.Timestamp.fromDate(new Date(validation.expiryDate)) : null,
      premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

function normalizePlatform(platform) {
  const value = String(platform || '').toLowerCase();
  if (value === 'ios' || value === 'android') {
    return value;
  }
  return null;
}