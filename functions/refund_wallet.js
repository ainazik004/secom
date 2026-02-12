/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

const admin = require("firebase-admin");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

const REGION = "europe-west1";

exports.refundZhalbyraks = onCall(
  {
    region: REGION,
    enforceAppCheck: true,
  },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError("unauthenticated", "Sign in required");
    }

    const uid = req.auth.uid;
    const { idempotencyKey, reason } = req.data || {};

    if (!idempotencyKey) {
      throw new HttpsError("invalid-argument", "Missing idempotencyKey");
    }

    const txRef = admin.firestore()
      .doc(`users/${uid}/wallet_tx/${idempotencyKey}`);
    const walletRef = admin.firestore()
      .doc(`users/${uid}/wallet/main`);

    await admin.firestore().runTransaction(async (tx) => {
      const txSnap = await tx.get(txRef);
      if (!txSnap.exists) return;

      const txData = txSnap.data();
      if (txData.refunded === true) return;

      const amount = Number(txData.amount || 0);
      if (amount <= 0) return;

      const walletSnap = await tx.get(walletRef);
      const balance = Number(walletSnap.data()?.balance || 0);

      tx.update(walletRef, {
        balance: balance + amount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(txRef, {
        refunded: true,
        refundReason: reason || "ACTION_FAILED",
        refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return { ok: true };
  }
);
