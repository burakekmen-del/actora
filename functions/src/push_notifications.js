const { onSchedule } = require('firebase-functions/v2/scheduler');
const { admin, db, messaging } = require('./admin');

const DEEP_LINK = process.env.APP_DEEP_LINK_URL || 'actora://today';

exports.sendDay2Push = onSchedule('every 60 minutes', async () => {
  await sendInactivePush({
    markerField: 'lastDay2PushLocalDate',
    title: 'Your streak is waiting 🔥',
    body: 'Just 2 minutes today.',
    pushType: 'day2_push',
    minAccountAgeDays: 1,
  });
});

exports.sendDay3Push = onSchedule('every 60 minutes', async () => {
  await sendInactivePush({
    markerField: 'lastDay3PushLocalDate',
    title: "Don't break the streak.",
    body: 'Keep the momentum alive.',
    pushType: 'day3_push',
    minAccountAgeDays: 3,
  });
});

exports.sendDay5Push = onSchedule('every 60 minutes', async () => {
  await sendInactivePush({
    markerField: 'lastDay5PushLocalDate',
    title: 'Still with us?',
    body: 'One small task. That is enough.',
    pushType: 'day5_push',
    minAccountAgeDays: 5,
  });
});

async function sendInactivePush({
  markerField,
  title,
  body,
  pushType,
  minAccountAgeDays,
}) {
  const snapshot = await db
    .collection('users')
    .where('onboardingCompleted', '==', true)
    .get();

  if (snapshot.empty) {
    return;
  }

  const nowUtc = new Date();
  const tasks = [];

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};
    const token = data.fcmToken;
    const offsetMinutes = Number(data.timezoneOffsetMinutes ?? 0);
    const createdAt = data.createdAt?.toDate ? data.createdAt.toDate() : null;

    if (!token || !Number.isFinite(offsetMinutes) || !createdAt) {
      continue;
    }

    const localNow = new Date(nowUtc.getTime() + offsetMinutes * 60 * 1000);
    if (localNow.getUTCHours() !== 9) {
      continue;
    }

    const todayLocal = formatDateKey(localNow);
    const lastOpenLocal = data.lastAppOpenLocalDate;
    const lastPushedLocal = data[markerField];

    if (lastOpenLocal === todayLocal || lastPushedLocal === todayLocal) {
      continue;
    }

    if (!hasReachedAccountAge(createdAt, nowUtc, minAccountAgeDays)) {
      continue;
    }

    const message = {
      token,
      notification: {
        title,
        body,
      },
      data: {
        type: pushType,
        deepLink: DEEP_LINK,
      },
      android: {
        priority: 'high',
        notification: {
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    tasks.push(
      messaging.send(message).then(async () => {
        await doc.ref.set(
          {
            [markerField]: todayLocal,
            [`${markerField.replace('LocalDate', '')}At`]: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }),
    );
  }

  if (tasks.length > 0) {
    await Promise.allSettled(tasks);
  }
}

function hasReachedAccountAge(createdAt, nowUtc, minAccountAgeDays) {
  const ageMs = nowUtc.getTime() - createdAt.getTime();
  return ageMs >= minAccountAgeDays * 24 * 60 * 60 * 1000;
}

function formatDateKey(date) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const day = String(date.getUTCDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}