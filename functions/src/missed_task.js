const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { admin, db } = require('./admin');

exports.resolveMissedTask = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const userRef = db.collection('users').doc(userId);

  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const data = snapshot.data() || {};
    const now = new Date();

    const premiumExpiry = data.premiumExpiryDate?.toDate ? data.premiumExpiryDate.toDate() : null;
    const premiumActive = data.consistencyModeActive === true ||
      (premiumExpiry && premiumExpiry.getTime() > now.getTime());

    const currentStreak = asNumber(data.streakCount) ?? 0;
    const currentFreezeCount = asNumber(data.freezeCount) ?? 1;

    if (premiumActive) {
      transaction.set(
        userRef,
        {
          lastFreezeUsedAt: admin.firestore.FieldValue.serverTimestamp(),
          consistencyModeActive: true,
          premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return {
        freezeUsed: true,
        isPremium: true,
        streakReset: false,
        updatedStreakCount: currentStreak,
      };
    }

    if (currentFreezeCount > 0) {
      transaction.set(
        userRef,
        {
          freezeCount: currentFreezeCount - 1,
          lastFreezeUsedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return {
        freezeUsed: true,
        isPremium: false,
        streakReset: false,
        updatedStreakCount: currentStreak,
      };
    }

    transaction.set(
      userRef,
      {
        streakCount: 0,
        streakResetAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      freezeUsed: false,
      isPremium: false,
      streakReset: true,
      updatedStreakCount: 0,
    };
  });

  return result;
});

function asNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}