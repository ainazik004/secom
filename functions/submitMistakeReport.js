// functions/submit_mistake_report.js
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
admin.initializeApp();

exports.submitMistakeReport = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Login required.");

  const data = req.data || {};
  const message = String(data.message || "").trim();
  const questionId = String(data.questionId || "").trim();
  const stem = String(data.stem || "").trim();
  const correct = String(data.correct || "").trim();
  const picked = data.picked == null ? "" : String(data.picked).trim();
  const options = data.options && typeof data.options === "object" ? data.options : {};

  if (message.length < 10 || message.length > 800) {
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

  // --- rate limiting counters ---
  // 1) short window: 3 per 10 minutes
  // 2) daily cap: 15 per day
  const countersRef = db.collection("rate_limits").doc(uid);
  const snap = await countersRef.get();

  const tenMinMs = 10 * 60 * 1000;
  const dayMs = 24 * 60 * 60 * 1000;

  let lastWindowStart = 0;
  let windowCount = 0;
  let dayStart = 0;
  let dayCount = 0;

  if (snap.exists) {
    const d = snap.data() || {};
    lastWindowStart = d.windowStartMs || 0;
    windowCount = d.windowCount || 0;
    dayStart = d.dayStartMs || 0;
    dayCount = d.dayCount || 0;
  }

  const nowMs = Date.now();

  // window reset
  if (nowMs - lastWindowStart > tenMinMs) {
    lastWindowStart = nowMs;
    windowCount = 0;
  }

  // day reset
  if (nowMs - dayStart > dayMs) {
    dayStart = nowMs;
    dayCount = 0;
  }

  if (windowCount >= 3) {
    throw new HttpsError("resource-exhausted", "Too many reports. Try later.");
  }
  if (dayCount >= 15) {
    throw new HttpsError("resource-exhausted", "Daily limit reached.");
  }

  // write report + update counters atomically
  await db.runTransaction(async (tx) => {
    tx.set(
      countersRef,
      {
        windowStartMs: lastWindowStart,
        windowCount: windowCount + 1,
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
      // optional metadata
      locale: String(data.locale || ""),
      appVersion: String(data.appVersion || ""),
      platform: String(data.platform || ""),
    });
  });

  return {ok: true};
});
