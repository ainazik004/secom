/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

// functions/streak_reset.js
function safeLogError(tag, err, extra = {}) {
  try {
    const payload = {
      tag,
      message: err && err.message ? String(err.message) : String(err),
      name: err && err.name ? String(err.name) : undefined,
      code: err && err.code ? String(err.code) : undefined,
      status: err && err.status ? String(err.status) : undefined,
      type: err && err.type ? String(err.type) : undefined,
      extra,
    };
    console.error("[streak_reset]", JSON.stringify(payload));
  } catch (_) {
    console.error("[streak_reset]", tag, err);
  }
}

function getBishkekLocalDateISO(date = new Date()) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Bishkek",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);

  let y = "";
  let m = "";
  let d = "";

  for (let i = 0; i < parts.length; i++) {
    const p = parts[i];
    if (p.type === "year") y = p.value;
    if (p.type === "month") m = p.value;
    if (p.type === "day") d = p.value;
  }
  return `${y}-${m}-${d}`;
}

function normalizeLocalDate(value) {
  if (!value) return null;

  if (typeof value === "string") {
    if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value;
    return null;
  }

  if (typeof value === "object" && typeof value.toDate === "function") {
    return getBishkekLocalDateISO(value.toDate());
  }

  if (value instanceof Date) {
    return getBishkekLocalDateISO(value);
  }

  return null;
}

async function runStreakResetJob({admin, db}) {
  const todayLocal = getBishkekLocalDateISO(new Date());
  const usersRef = db.collection("users");

  let lastDoc = null;
  const pageSize = 450; // keep < 500 to avoid batch limits

  let totalScanned = 0;
  let totalReset = 0;

  try {
    let hasMore = true;

    while (hasMore) {
      let q = usersRef
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(pageSize);

      if (lastDoc) q = q.startAfter(lastDoc);

      const snap = await q.get();

      if (snap.empty) {
        hasMore = false;
        break;
      }

      const batch = db.batch();
      let writes = 0;

      for (const doc of snap.docs) {
        totalScanned += 1;

        const data = doc.data() || {};
        const current = typeof data.currentStreakDays === "number" ? data.currentStreakDays : 0;
        const longest = typeof data.longestStreakDays === "number" ? data.longestStreakDays : 0;

        const lastLocal = normalizeLocalDate(data.lastStudyLocalDate);
        const lastLocalFromTs = normalizeLocalDate(data.lastStudyDate);
        const lastStudyLocal = lastLocal || lastLocalFromTs;

        const studiedToday = lastStudyLocal === todayLocal;

        if (!studiedToday && current !== 0) {
          batch.update(doc.ref, {
            currentStreakDays: 0,
            longestStreakDays: Math.max(longest, current),
            streakResetAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          writes += 1;
          totalReset += 1;
        } else if (studiedToday && current > longest) {
          batch.update(doc.ref, {
            longestStreakDays: current,
          });
          writes += 1;
        }
      }

      if (writes > 0) {
        await batch.commit();
      }

      lastDoc = snap.docs[snap.docs.length - 1];

      // stop without an extra empty read
      if (snap.size < pageSize) {
        hasMore = false;
      }
    }

    console.log(
      `[resetStreakIfNoStudyToday] done. todayLocal=${todayLocal} scanned=${totalScanned} reset=${totalReset}`
    );
  } catch (err) {
    safeLogError("resetStreakIfNoStudyToday", err, {todayLocal, totalScanned, totalReset});
    throw err; // so Cloud Scheduler sees failure and can retry/log properly
  }
}

module.exports = {runStreakResetJob};
