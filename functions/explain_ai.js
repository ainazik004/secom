/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

require("dotenv").config();

// ✅ FORCE v1 import so .region() exists
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const OpenAI = require("openai").default;

// IMPORTANT: DO NOT call admin.initializeApp() here.
// index.js already initializes it.
const db = admin.firestore();

/**
 * @param {*} v
 * @param {string=} fallback
 * @return {string}
 */
function asString(v, fallback) {
  if (v === undefined || v === null) return fallback || "";
  return String(v);
}

/**
 * @return {OpenAI}
 */
function getClient() {
  const key = process.env.OPENAI_API_KEY;
  if (!key) throw new Error("Missing OPENAI_API_KEY in environment");
  return new OpenAI({apiKey: key});
}

/**
 * @param {Array<Object>} history
 * @return {Array<{role: string, content: string}>}
 */
function normalizeHistory(history) {
  if (!Array.isArray(history)) return [];
  const slice = history.slice(Math.max(0, history.length - 14));
  return slice
    .map((m) => {
      const role = (m && m.role) ? String(m.role) : "";
      const content = (m && m.content) ? String(m.content) : "";
      if (!content.trim()) return null;
      if (role !== "user" && role !== "assistant") return null;
      return {role: role, content: content.trim()};
    })
    .filter(Boolean);
}

/**
 * @param {string} userMessage
 * @param {Object|null} problem
 * @return {boolean}
 */
function isProblemRelated(userMessage, problem) {
  const t = String(userMessage || "").trim().toLowerCase();
  if (!t) return false;
  if (!problem || !problem.stem) return false;

  const triggers = [
    /(\bобъясни\b|\bобъяснение\b|\bреши\b|\bрешение\b|\bразбор\b|\bпочему\b|\bкак решить\b|\bкак решается\b)/,
    /(\bexplain\b|\bsolution\b|\bsolve\b|\bwhy\b|\bhow to solve\b|\bshow steps\b|\bwalk me through\b)/,
    /(түшүндүр|түшүндүрүп бер|чеч|чечип бер|эмне үчүн|кантип чечилет)/,
  ];
  if (triggers.some((re) => re.test(t))) return true;

  if (/(вариант|ответ|жооп)\s*[a-eа-е]\b/i.test(userMessage)) return true;
  if (/\b[a-e]\)\b/i.test(userMessage)) return true;

  if (/(правильн|неправильн|мой ответ|я выбрал|я выбрала|сен тандадың|мен тандадым)/.test(t)) return true;

  const stem = String(problem.stem || "").toLowerCase();
  const optionLines = String(problem.optionLines || "").toLowerCase();
  const answer = String(problem.answer || "").toLowerCase();

  const bag = `${stem}\n${optionLines}\n${answer}`
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .split(/\s+/)
    .filter((w) => w.length >= 5)
    .slice(0, 80);

  for (const w of bag) {
    if (t.includes(w)) return true;
  }

  return false;
}

/**
 * @param {string} uid
 * @param {Object} payload
 * @return {Promise<void>}
 */
async function saveLastProblem(uid, payload) {
  const ref = db.collection("users").doc(uid).collection("ai").doc("lastProblem");
  await ref.set(
    {
      ...payload,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );
}

/**
 * @param {string} uid
 * @return {Promise<Object|null>}
 */
async function loadLastProblem(uid) {
  const ref = db.collection("users").doc(uid).collection("ai").doc("lastProblem");
  const snap = await ref.get();
  if (!snap.exists) return null;
  return snap.data() || null;
}

/**
 * @param {string} lang
 * @return {string}
 */
function buildSystem(lang) {
  const isKy = String(lang).toLowerCase().startsWith("ky");

  const systemKy = [
    "Сенин атың Джинни.",
    "Сен жардамчы-мугалимсиң жана КОЛДОНУУЧУ берген АКЫРКЫ суроого дайыма жооп бер (каалаган тема).",
    "ЭЧ КАЧАН LaTeX колдонбо: \\[, \\], \\frac, \\text, \\times, \\approx сыяктуу белгилер болбосун.",
    "Формулаларды кадимки текст менен жаз: бөлчөк = a/b, көбөйтүү = ×, квадрат = ^2. 'π' белгисин колдонсо болот.",
    "",
    "Эреже:",
    "1) Колдонуучунун акыркы билдирүүсү — эң негизги.",
    "2) Эгер билим берүүчү тапшырма контекст берилсе, аны ТЕК гана ошол тапшырмага байланышкан учурда колдон.",
    "3) Эгер суроо башка тема болсо, ошол темага жооп бер.",
  ].join("\n");

  const systemRu = [
    "Тебя зовут Джинни.",
    "Ты помощник-учитель и ВСЕГДА отвечаешь на ПОСЛЕДНИЙ вопрос пользователя (любая тема).",
    "НИКОГДА не используй LaTeX: никаких \\[, \\], \\frac, \\text, \\times, \\approx и подобных.",
    "Формулы пиши обычным текстом: дробь = a/b, умножение = ×, степень = ^2. Символ 'π' можно.",
    "",
    "Правила:",
    "1) Последнее сообщение пользователя — главный приоритет.",
    "2) Если дан контекст учебной задачи, используй его ТОЛЬКО когда вопрос связан с задачей.",
    "3) Если вопрос на другую тему — отвечай по этой теме.",
  ].join("\n");

  return isKy ? systemKy : systemRu;
}

/**
 * @param {string} lang
 * @param {Object} problem
 * @return {string}
 */
function buildReference(lang, problem) {
  const isKy = String(lang).toLowerCase().startsWith("ky");

  const stem = asString(problem.stem, "");
  const optionLines = asString(problem.optionLines, "");
  const answer = asString(problem.answer, "");
  const picked = asString(problem.picked, "");

  const refKy = [
    "BACKGROUND КОНТЕКСТ (бул маалыматты ТЕК тапшырмага байланышкан суроо болсо колдон):",
    "Суроо:",
    stem,
    "",
    "Варианттар:",
    optionLines,
    "",
    `Туура жооп: ${answer}`,
    `Колдонуучу тандаганы: ${picked ? picked : "(тандалган эмес)"}`,
  ].join("\n");

  const refRu = [
    "BACKGROUND КОНТЕКСТ (используй ТОЛЬКО если вопрос связан с задачей):",
    "Вопрос:",
    stem,
    "",
    "Варианты:",
    optionLines,
    "",
    `Правильный вариант: ${answer}`,
    `Выбранный пользователем: ${picked ? picked : "(не выбран)"}`,
  ].join("\n");

  return isKy ? refKy : refRu;
}

/**
 * @param {string} text
 * @return {string}
 */
function sanitizeNoLatex(text) {
  return String(text || "")
    .replace(/\\\[/g, "")
    .replace(/\\\]/g, "")
    .replace(/\\text\{([^}]*)\}/g, "$1")
    .replace(/\\frac\{([^}]*)\}\{([^}]*)\}/g, "$1/$2")
    .replace(/\\times/g, "×")
    .replace(/\\approx/g, "≈")
    .replace(/\\pi/g, "π")
    .replace(/\\quad/g, " ")
    .replace(/\\,/g, " ")
    .replace(/\\\\/g, "")
    .trim();
}

// ✅ v1 callable + explicit region
exports.aiExplainQuestion = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context || !context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Login required.");
    }

    const uid = context.auth.uid;

    const q = data && data.question;
    if (!q || typeof q !== "object") {
      throw new functions.https.HttpsError("invalid-argument", "Missing question.");
    }

    const stem = asString(q.stem, "");
    const options = q.options;
    const answer = asString(q.answer, "");
    const picked = asString(q.picked, "");

    const lang = asString((data && data.language) ? data.language : "ru", "ru");

    if (stem.length < 3 || stem.length > 2000) {
      throw new functions.https.HttpsError("invalid-argument", "Bad stem length.");
    }
    if (!options || typeof options !== "object") {
      throw new functions.https.HttpsError("invalid-argument", "Bad options type.");
    }

    const optionLines = Object.entries(options)
      .map(([k, v]) => `${k}) ${asString(v, "")}`)
      .join("\n");

    const userMessage = asString(data && data.userMessage, "").trim();
    const history = (data && data.history) ? data.history : [];

    await saveLastProblem(uid, {
      stem: stem,
      optionLines: optionLines,
      answer: answer,
      picked: picked,
      lang: lang,
    });

    const lastProblem = await loadLastProblem(uid);
    const attachProblemContext = isProblemRelated(userMessage, lastProblem);

    const system = buildSystem(lang);
    const messages = [{role: "system", content: system}];

    if (attachProblemContext && lastProblem) {
      messages.push({role: "system", content: buildReference(lang, lastProblem)});
    }

    const effectiveHistory = attachProblemContext ? history : [];
    const h = normalizeHistory(effectiveHistory);
    for (const m of h) {
      messages.push({role: m.role, content: m.content});
    }

    const isKy = String(lang).toLowerCase().startsWith("ky");
    const finalPrompt = userMessage || (isKy ? "Сураныч, жооп бер." : "Пожалуйста, ответь.");
    messages.push({role: "user", content: finalPrompt});

    try {
      const client = getClient();

      const resp = await client.responses.create({
        model: "gpt-5.1",
        input: messages,
        max_output_tokens: 1000,
      });

      let text = (resp && resp.output_text ? String(resp.output_text) : "").trim();
      if (!text) text = "—";
      text = sanitizeNoLatex(text);

      return {text: text, usedProblemContext: attachProblemContext};
    } catch (e) {
      console.error("aiExplainQuestion error:", e);
      throw new functions.https.HttpsError("internal", "AI error.");
    }
  });
