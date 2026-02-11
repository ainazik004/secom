/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

const admin = require("firebase-admin");

// IMPORTANT: v1 import (gives functions.region + auth triggers)
const functions = require("firebase-functions/v1");

const REGION = "europe-west1"; // keep consistent with your project

exports.initWalletOnUserCreate = functions
  .region(REGION)
  .auth.user()
  .onCreate(async (user) => {
    if (!user || !user.uid) return;

    const uid = user.uid;
    const ref = admin.firestore().doc(`users/${uid}/wallet/main`);
    const now = admin.firestore.FieldValue.serverTimestamp();

    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) return;

      tx.set(ref, {
        balance: 0,
        earnedTotal: 0,
        spentTotal: 0,
        createdAt: now,
        updatedAt: now,
        limits: {
          dailyEarned: 0,
          dailySpent: 0,
          dayKey: null,
        },
      }, {merge: true});
    });
  });
