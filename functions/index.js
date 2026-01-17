/* eslint-disable max-len */
const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/v2/scheduler");

admin.initializeApp();

/**
 * Left-pad a number to 2 digits.
 * @param {number} n Number.
 * @return {string} Two-digit string.
 */
function pad2(n) {
  return String(n).padStart(2, "0");
}

/**
 * Returns Kyrgyzstan day key "YYYY-MM-DD" for a given date, using UTC+6.
 * @param {Date=} date JS Date (defaults to now).
 * @return {string} Day key.
 */
function dayKeyUtcPlus6(date = new Date()) {
  const offsetMinutes = 6 * 60;
  const utcMillis = date.getTime();
  const localMillis = utcMillis + offsetMinutes * 60 * 1000;
  const local = new Date(localMillis);

  const y = local.getUTCFullYear();
  const m = pad2(local.getUTCMonth() + 1);
  const d = pad2(local.getUTCDate());
  return `${y}-${m}-${d}`;
}

/**
 * Resets currentStreakDays to 0 if the user did NOT study today (UTC+6),
 * based on users/{uid}.lastTestDate stored as "YYYY-MM-DD".
 */
exports.resetStreakIfNoStudyToday = onSchedule(
    {
      schedule: "59 23 * * *", // 23:59 daily
      timeZone: "Asia/Bishkek",
      region: "europe-west1",
      memory: "512MiB",
    },
    async () => {
      const db = admin.firestore();
      const todayKey = dayKeyUtcPlus6(new Date());

      const batchLimit = 450;
      let totalUpdated = 0;

      /**
         * Commits updates in batches.
         * @param {Array<FirebaseFirestore.QueryDocumentSnapshot>} docs Docs to update.
         * @return {Promise<void>} Promise.
         */
      const commitDocs = async (docs) => {
        let batch = db.batch();
        let ops = 0;

        for (const doc of docs) {
          batch.update(doc.ref, {currentStreakDays: 0});
          ops += 1;

          if (ops >= batchLimit) {
            await batch.commit();
            batch = db.batch();
            ops = 0;
          }
        }

        if (ops > 0) {
          await batch.commit();
        }
      };

      // PASS 1: lastTestDate < todayKey (did not study today)
      let lastDoc1 = null;
      let hasMore1 = true;

      while (hasMore1) {
        let q = db
            .collection("users")
            .where("lastTestDate", "<", todayKey)
            .orderBy("lastTestDate")
            .limit(1000);

        if (lastDoc1) {
          q = q.startAfter(lastDoc1);
        }

        const snap = await q.get();
        if (snap.empty) {
          hasMore1 = false;
          break;
        }

        await commitDocs(snap.docs);
        totalUpdated += snap.size;
        lastDoc1 = snap.docs[snap.docs.length - 1];
      }

      // PASS 2: lastTestDate missing or null
      let lastDoc2 = null;
      let hasMore2 = true;

      while (hasMore2) {
        let q = db
            .collection("users")
            .where("lastTestDate", "==", null)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(1000);

        if (lastDoc2) {
          q = q.startAfter(lastDoc2);
        }

        const snap = await q.get();
        if (snap.empty) {
          hasMore2 = false;
          break;
        }

        await commitDocs(snap.docs);
        totalUpdated += snap.size;
        lastDoc2 = snap.docs[snap.docs.length - 1];
      }

      console.log(JSON.stringify({
        message: "resetStreakIfNoStudyToday finished",
        todayKey,
        totalUpdated,
      }));

      return null;
    },
);
