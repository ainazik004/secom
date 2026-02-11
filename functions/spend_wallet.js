/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

const REGION = "europe-west1";

function asString(v) {
  if (v === undefined || v === null) return "";
  return String(v);
}

function asInt(v) {
  const n = Number(v);
  if (!Number.isFinite(n)) return NaN;
  return Math.trunc(n);
}

function walletRef(uid) {
  return admin.firestore().doc(`users/${uid}/wallet/main`);
}

function txRef(uid, idempotencyKey) {
  // Use idempotencyKey as doc id to guarantee dedupe
  return admin.firestore().doc(`users/${uid}/wallet_tx/${idempotencyKey}`);
}

async function getCostByActionKey(actionKey) {
  const snap = await admin.firestore().doc("config/pricing").get();
  if (!snap.exists) throw new HttpsError("failed-precondition", "Missing config/pricing");

  const data = snap.data() || {};
  const actions = data.actions || {};
  const action = actions[actionKey];

  if (!action) throw new HttpsError("invalid-argument", `Unknown actionKey: ${actionKey}`);
  if (action.enabled === false) throw new HttpsError("failed-precondition", `Action disabled: ${actionKey}`);

  const cost = asInt(action.cost);
  if (!Number.isFinite(cost) || cost <= 0) {
    throw new HttpsError("failed-precondition", `Invalid cost for actionKey: ${actionKey}`);
  }
  return cost;
}

exports.spendZhalbyraks = onCall(
  {
    region: REGION,
    // Optional: if you enforce App Check on functions, keep this true.
    // If you want to allow calls without App Check temporarily, set to false.
    enforceAppCheck: true,
  },
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "Sign in required");

    const uid = req.auth.uid;
    const body = req.data || {};

    const actionKey = asString(body.actionKey).trim();
    const idempotencyKey = asString(body.idempotencyKey).trim();
    const ref = asString(body.ref).trim(); // optional
    const amountRaw = body.amount; // optional (if you want manual spend)
    const reason = asString(body.reason).trim();

    if (!idempotencyKey) {
      throw new HttpsError("invalid-argument", "Missing idempotencyKey");
    }

    // Determine cost
    let cost = NaN;
    let finalReason = reason || actionKey || "spend";

    if (actionKey) {
      cost = await getCostByActionKey(actionKey);
      finalReason = actionKey;
    } else {
      // Allow manual amount spend (optional mode)
      const amt = asInt(amountRaw);
      if (!Number.isFinite(amt) || amt <= 0) {
        throw new HttpsError("invalid-argument", "Provide actionKey or a positive amount");
      }
      cost = amt;
      if (!finalReason) finalReason = "manual";
    }

    const wRef = walletRef(uid);
    const tRef = txRef(uid, idempotencyKey);
    const now = admin.firestore.FieldValue.serverTimestamp();

    const out = await admin.firestore().runTransaction(async (tx) => {
      // Idempotency check first
      const tSnap = await tx.get(tRef);
      if (tSnap.exists) {
        const t = tSnap.data() || {};
        return {
          ok: true,
          idempotent: true,
          balance: asInt(t.balanceAfter),
          spent: asInt(t.amount),
          actionKey: t.actionKey || null,
          txId: idempotencyKey,
        };
      }

      const wSnap = await tx.get(wRef);
      if (!wSnap.exists) {
        // Wallet missing -> create it (safe for edge cases)
        tx.set(wRef, {
          balance: 0,
          earnedTotal: 0,
          spentTotal: 0,
          createdAt: now,
          updatedAt: now,
          limits: {dailyEarned: 0, dailySpent: 0, dayKey: null},
        }, {merge: true});
      }

      const wData = (wSnap.exists ? (wSnap.data() || {}) : {});
      const balance = Number.isFinite(asInt(wData.balance)) ? asInt(wData.balance) : 0;

      if (balance < cost) {
        throw new HttpsError("failed-precondition", "NOT_ENOUGH_ZHALBYRAKS");
      }

      const newBalance = balance - cost;

      // Update wallet totals
      const spentTotal = Number.isFinite(asInt(wData.spentTotal)) ? asInt(wData.spentTotal) : 0;

      tx.set(wRef, {
        balance: newBalance,
        spentTotal: spentTotal + cost,
        updatedAt: now,
      }, {merge: true});

      // Write tx log
      tx.set(tRef, {
        type: "spend",
        amount: cost,
        actionKey: actionKey || null,
        reason: finalReason,
        ref: ref || null,
        createdAt: now,
        idempotencyKey,
        balanceBefore: balance,
        balanceAfter: newBalance,
      }, {merge: false});

      return {
        ok: true,
        idempotent: false,
        balance: newBalance,
        spent: cost,
        actionKey: actionKey || null,
        txId: idempotencyKey,
      };
    });

    return out;
  },
);
