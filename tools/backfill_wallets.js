/* eslint-disable no-console */
const admin = require("firebase-admin");

// Put your service account json here:
const serviceAccount = require("./serviceAccount.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id,
});

const db = admin.firestore();

function walletRef(uid) {
  return db.doc(`users/${uid}/wallet/main`);
}

async function run() {
  const usersCol = db.collection("users");

  let last = null;
  let processed = 0;
  let created = 0;
  let patched = 0;

  while (true) {
    let q = usersCol.orderBy(admin.firestore.FieldPath.documentId()).limit(400);
    if (last) q = q.startAfter(last);

    const snap = await q.get();
    if (snap.empty) break;

    const batch = db.batch();
    const now = admin.firestore.FieldValue.serverTimestamp();

    for (const u of snap.docs) {
      const uid = u.id;
      const ref = walletRef(uid);
      const wSnap = await ref.get();

      if (!wSnap.exists) {
        batch.set(ref, {
          balance: 0,
          earnedTotal: 0,
          spentTotal: 0,
          createdAt: now,
          updatedAt: now,
          limits: {dailyEarned: 0, dailySpent: 0, dayKey: null},
        }, {merge: true});
        created++;
      } else {
        const cur = wSnap.data() || {};
        const patch = {updatedAt: now};

        if (typeof cur.balance !== "number") patch.balance = 0;
        if (typeof cur.earnedTotal !== "number") patch.earnedTotal = 0;
        if (typeof cur.spentTotal !== "number") patch.spentTotal = 0;
        if (!cur.createdAt) patch.createdAt = now;

        if (!cur.limits || typeof cur.limits !== "object") {
          patch.limits = {dailyEarned: 0, dailySpent: 0, dayKey: null};
        } else {
          patch.limits = {
            dailyEarned: typeof cur.limits.dailyEarned === "number" ? cur.limits.dailyEarned : 0,
            dailySpent: typeof cur.limits.dailySpent === "number" ? cur.limits.dailySpent : 0,
            dayKey: cur.limits.dayKey ?? null,
          };
        }

        batch.set(ref, patch, {merge: true});
        patched++;
      }

      processed++;
    }

    await batch.commit();
    last = snap.docs[snap.docs.length - 1].id;

    console.log(`Processed=${processed} Created=${created} Patched=${patched}`);
  }

  console.log("DONE", {processed, created, patched});
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
