/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

// functions/submitMistakeReport.js
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// IMPORTANT: do NOT call admin.initializeApp() here.
// index.js already initializes it.

exports.submitMistakeReport = onCall(
  {
    region: "europe-west1",
    cors: true,
  },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required.");

    const data = req.data || {};

    const message = String(data.message || "").trim();
    const questionId = String(data.questionId || "").trim();
    const stem = String(data.stem || "").trim();
    const correct = String(data.correct || "").trim();

    const picked = data.picked == null ? "" : String(data.picked).trim();
    const options = data.options && typeof data.options === "object" ? data.options : {};

    const topic = data.topic == null ? "" : String(data.topic).trim();
    const section = data.section == null ? "" : String(data.section).trim();
    const language = data.language == null ? "" : String(data.language).trim();
    const left = data.left == null ? "" : String(data.left).trim();
    const right = data.right == null ? "" : String(data.right).trim();

    const MIN_LEN = 10;
    const MAX_LEN = 400;

    if (message.length < MIN_LEN || message.length > MAX_LEN) {
      throw new HttpsError("invalid-argument", "Invalid message length.");
    }
    if (!questionId || !stem || !correct) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }
    if (/(http:\/\/|https:\/\/|www\.)/i.test(message)) {
      throw new HttpsError("invalid-argument", "Links are not allowed.");
    }

    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const nowMs = Date.now();

    const dayMs = 24 * 60 * 60 * 1000;

    const countersRef = db.collection("rate_limits").doc(uid);
    const snap = await countersRef.get();

    let dayStart = 0;
    let dayCount = 0;

    if (snap.exists) {
      const d = snap.data() || {};
      dayStart = d.dayStartMs || 0;
      dayCount = d.dayCount || 0;
    }

    // day reset
    if (nowMs - dayStart > dayMs) {
      dayStart = nowMs;
      dayCount = 0;
    }

    if (dayCount >= 10) {
      throw new HttpsError("resource-exhausted", "Daily limit reached.");
    }

    await db.runTransaction(async (tx) => {
      tx.set(
        countersRef,
        {
          dayStartMs: dayStart,
          dayCount: dayCount + 1,
          updatedAt: now,
        },
        {merge: true}
      );

      const reportRef = db.collection("mistake_reports").doc();
      tx.set(reportRef, {
        createdAt: now,
        userId: uid,

        questionId,
        stem,
        correct,
        picked,
        options,
        message,
        topic,
        section,
        language,
        left,
        right,

        locale: String(data.locale || ""),
        appVersion: String(data.appVersion || ""),
        platform: String(data.platform || ""),
      });
    });

    return {ok: true};
  }
);
