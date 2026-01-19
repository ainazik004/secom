/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const OpenAI = require("openai");
require("dotenv").config();

admin.initializeApp();

const db = admin.firestore();

function mustGetEnv(name) {
  const v = process.env[name];
  if (!v || !String(v).trim()) {
    throw new Error(`Missing ${name} in environment`);
  }
  return String(v).trim();
}

const openai = new OpenAI({apiKey: mustGetEnv("OPENAI_API_KEY")});

// ---------- Friendly error helpers ----------

function safeLogError(tag, err, extra = {}) {
  // Logs to Firebase (you see details in console), but user never sees this.
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
    console.error("[AI]", JSON.stringify(payload));
  } catch (_) {
    console.error("[AI]", tag, err);
  }
}

function toFriendlyHttpsError(err) {
  // Default fallback
  let code = "internal";
  let message = "AI temporarily unavailable. Please try again.";

  const status = err?.status; // OpenAI SDK often sets .status
  const ecode = err?.code; // can be 'insufficient_quota', 'rate_limit_exceeded', etc.

  // Hard quota / billing disabled / credits ended
  if (ecode === "insufficient_quota") {
    code = "resource-exhausted";
    message = "AI is temporarily unavailable. Please try later.";
    return new HttpsError(code, message);
  }

  // Rate-limited (real 429, but not quota)
  if (ecode === "rate_limit_exceeded" || status === 429) {
    code = "resource-exhausted";
    message = "Too many requests. Please try again in a moment.";
    return new HttpsError(code, message);
  }

  // Invalid key / auth issue
  if (status === 401 || ecode === "invalid_api_key" || ecode === "authentication_error") {
    // Do not expose this to users
    code = "internal";
    message = "AI temporarily unavailable. Please try later.";
    return new HttpsError(code, message);
  }

  // Content policy / safety refusal
  // (This can happen depending on prompt; keep message neutral)
  if (status === 400 && (ecode === "invalid_request_error" || ecode === "content_policy_violation")) {
    code = "failed-precondition";
    message = "AI cannot answer this request.";
    return new HttpsError(code, message);
  }

  // Timeouts / network
  if (ecode === "ETIMEDOUT" || ecode === "ECONNRESET" || ecode === "ENOTFOUND" || status === 408) {
    code = "deadline-exceeded";
    message = "AI is taking too long. Please try again.";
    return new HttpsError(code, message);
  }

  return new HttpsError(code, message);
}

// ---- Helpers: Asia/Bishkek "local date" as YYYY-MM-DD ----

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

// ✅ Callable function for Flutter (AI explain)
exports.aiExplainQuestion = onCall(
  {
    region: "europe-west1",
    cors: true,
  },
  async (request) => {
    try {
      // ---- Auth guard ----
      if (!request.auth) {
        // Friendly but clear
        throw new HttpsError("unauthenticated", "Please sign in to use AI explanations.");
      }

      const data = request.data || {};
      const q = data.question;

      if (!q || typeof q !== "object") {
        // Friendly input error
        throw new HttpsError("invalid-argument", "Question data is missing.");
      }

      const stem = String(q.stem || "").trim();
      const options = (q.options && typeof q.options === "object") ? q.options : {};
      const answer = String(q.answer || "").trim();
      const picked = String(q.picked || "").trim();

      const langRaw = String(data.language || "ru").toLowerCase();
      const lang = langRaw.indexOf("ky") === 0 ? "ky" : "ru";

      if (stem.length < 3 || stem.length > 2000) {
        throw new HttpsError("invalid-argument", "Question text looks invalid.");
      }

      const optionLines = Object.entries(options)
        .map(([k, v]) => `${String(k)}) ${String(v)}`)
        .join("\n");

      const instructions = lang === "ky" ?
        "Сен мугалимсиң. Кыска жана түшүнүктүү түшүндүр. 3–6 кадам менен чечип бер. Акырында туура вариантты айт." :
        "Ты учитель. Объясни кратко и понятно. Реши в 3–6 шагах. В конце укажи правильный вариант.";

      const prompt = `${instructions}

Вопрос:
${stem}

Варианты:
${optionLines}

Правильный вариант: ${answer}
Выбранный пользователем: ${picked || "(не выбран)"}
`;

      // ---- OpenAI call ----
      const resp = await openai.responses.create({
        model: "gpt-4.1-mini",
        input: prompt,
        max_output_tokens: 350,
      });

      const text = String(resp.output_text || "").trim() || "—";
      return {text};
    } catch (err) {
      // Log details for you
      safeLogError("aiExplainQuestion", err, {
        uid: request?.auth?.uid || null,
      });

      // If it's already an HttpsError (our own validation/auth)
      if (err instanceof HttpsError) {
        // Ensure message is friendly
        return Promise.reject(err);
      }

      // Convert any other error (OpenAI, network, etc.) to friendly
      return Promise.reject(toFriendlyHttpsError(err));
    }
  }
);

// ✅ Scheduled streak reset (keep logs internal; no user exposure anyway)
exports.resetStreakIfNoStudyToday = onSchedule(
  {
    schedule: "59 23 * * *",
    timeZone: "Asia/Bishkek",
    region: "europe-west1",
    memory: "512MiB",
  },
  async () => {
    try {
      const todayLocal = getBishkekLocalDateISO(new Date());
      const usersRef = db.collection("users");

      let lastDoc = null;
      const pageSize = 500;

      let totalScanned = 0;
      let totalReset = 0;

      let hasMore = true;
      while (hasMore) {
        let q = usersRef
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(pageSize);

        if (lastDoc) {
          q = q.startAfter(lastDoc);
        }

        const snap = await q.get();

        if (snap.empty) {
          hasMore = false;
        } else {
          const batch = db.batch();

          snap.docs.forEach((doc) => {
            totalScanned += 1;

            const data = doc.data() || {};

            const current = typeof data.currentStreakDays === "number" ?
              data.currentStreakDays : 0;

            const longest = typeof data.longestStreakDays === "number" ?
              data.longestStreakDays : 0;

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
              totalReset += 1;
            } else if (studiedToday && current > longest) {
              batch.update(doc.ref, {
                longestStreakDays: current,
              });
            }
          });

          await batch.commit();
          lastDoc = snap.docs[snap.docs.length - 1];
        }
      }

      console.log(
        `[resetStreakIfNoStudyToday] done. todayLocal=${todayLocal} scanned=${totalScanned} reset=${totalReset}`
      );
    } catch (err) {
      // Scheduled function: only logs matter
      safeLogError("resetStreakIfNoStudyToday", err);
    }
  }
);
