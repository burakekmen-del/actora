const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { admin, db } = require('./admin');

exports.bootstrapUserProfile = onDocumentCreated('users/{userId}', async (event) => {
  const userId = event.params.userId;
  const userRef = db.collection('users').doc(userId);
  const snapshot = await userRef.get();

  if (!snapshot.exists) {
    return;
  }

  await userRef.set(
    {
      freezeCount: 1,
      consistencyModeActive: false,
      premiumExpiryDate: null,
      premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
});