/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

require("dotenv").config();

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const OpenAI = require("openai").default;

// IMPORTANT: admin.initializeApp() is done in index.js
const db = admin.firestore();

/* ------------------ helpers ------------------ */

function asString(v, fallback) {
  if (v === undefined || v === null) return fallback || "";
  return String(v);
}

function getClient() {
  const key = process.env.OPENAI_API_KEY;
  if (!key) throw new Error("Missing OPENAI_API_KEY");
  return new OpenAI({apiKey: key});
}

function isKy(lang) {
  return String(lang).toLowerCase().startsWith("ky");
}

function colA(lang) {
  return isKy(lang) ? "А Колонкасы" : "Колонка А";
}

function colB(lang) {
  return isKy(lang) ? "Б Колонкасы" : "Колонка Б";
}

/* ------------------ system prompt ------------------ */

function buildSystem(lang, kind) {
  const ky = isKy(lang);

  const base = ky ? [
    "Сенин атың Джинни.",
    "Сен жардамчы-мугалимсиң.",
    "Максат — туура жоопко КАНТИП жетүүнү түшүндүрүү.",
    "Эсептөөлөрдү, салыштырууну, ой жүгүртүүнү көрсөт.",
    "Жоопту кайталаба, жыйынтыкты бир эле жолу жаз.",
    "Өтө кыска кылба.",
    "Markdown колдонбо, '*' '_' '`' жок.",
    "LaTeX колдонбо.",
  ] : [
    "Тебя зовут Джинни.",
    "Ты помощник-учитель.",
    "Цель — объяснить, КАК прийти к правильному ответу.",
    "Показывай вычисления и ход рассуждений.",
    "Не дублируй вывод.",
    "Не делай слишком коротко.",
    "Без markdown (* _ `).",
    "Без LaTeX.",
  ];

  if (kind === "comparison") {
    if (ky) {
      base.push("Колонкаларды так 'А Колонкасы' жана 'Б Колонкасы' деп ата.");
    } else {
      base.push("Используй строго названия 'Колонка А' и 'Колонка Б'.");
    }
  }

  return base.join("\n");
}

/* ------------------ prompts ------------------ */

function buildOptionLines(options) {
  if (!options || typeof options !== "object") return "—";
  return Object.entries(options)
    .map(([k, v]) => `${k}) ${asString(v, "")}`)
    .join("\n");
}

function buildMathPrompt(lang, q) {
  return [
    "Математика.",
    "",
    `Вопрос: ${asString(q.stem, "")}`,
    "Варианты:",
    buildOptionLines(q.options),
    "",
    "Объясни решение пошагово.",
    "Покажи вычисления.",
    "В конце сделай один краткий вывод.",
  ].join("\n");
}

function buildAnalogyPrompt(lang, q) {
  return [
    "Аналогия.",
    "",
    `Вопрос: ${asString(q.stem, "")}`,
    "Варианты:",
    buildOptionLines(q.options),
    "",
    "Объясни тип связи.",
    "Почему правильный вариант подходит.",
    "Один финальный вывод.",
  ].join("\n");
}

function buildLanguagePrompt(lang, q) {
  return [
    "Язык.",
    "",
    `Вопрос: ${asString(q.stem, "")}`,
    "Варианты:",
    buildOptionLines(q.options),
    "",
    "Объясни правило.",
    "Почему правильный вариант верный.",
    "Короткий вывод в конце.",
  ].join("\n");
}

function buildComparisonPrompt(lang, q) {
  const ky = isKy(lang);

  // ✅ Expect payload keys from Flutter: left / right
  const left = asString(q.left, "");
  const right = asString(q.right, "");

  const A = colA(lang);
  const B = colB(lang);

  if (ky) {
    return [
      "САЛЫШТЫРУУ ТАПШЫРМАСЫ.",
      "",
      `${A}: ${left}`,
      `${B}: ${right}`,
      "",
      "ТАЛАП (ТАК АТКАР):",
      "• АЛГАЧ дробдорду МҮМКҮН БОЛСО кыскарт.",
      "• Эгер бирдей болуп калса — тең деп айт.",
      "• Эгер кыскартуудан кийин айырма калса — айкаш көбөйтүү колдон.",
      "• Ондук сандарды колдонбо.",
      "• Кадам сайын түшүндүр.",
      "• Акырында гана жыйынтык жаз.",
    ].join("\n");
  }

  return [
    "ЗАДАЧА НА СРАВНЕНИЕ.",
    "",
    `${A}: ${left}`,
    `${B}: ${right}`,
    "",
    "СТРОГОЕ ТРЕБОВАНИЕ:",
    "• СНАЧАЛА сократи дроби, ЕСЛИ ЭТО ВОЗМОЖНО.",
    "• Если после сокращения дроби совпадают — они равны.",
    "• Если не совпадают — сравни через перекрёстное умножение.",
    "• НЕ используй десятичные числа.",
    "• Покажи рассуждение шаг за шагом.",
    "• Итог напиши только в конце.",
  ].join("\n");
}

/* ------------------ sanitize ------------------ */

function sanitizeForClient(text) {
  let s = String(text || "");

  // convert multiplication
  s = s.replace(
    /([0-9A-Za-zА-Яа-яπ)])\s*\*\s*([0-9A-Za-zА-Яа-яπ(])/g,
    "$1 × $2"
  );

  // remove markdown
  s = s.replace(/[`_*]/g, "");

  // normalize whitespace
  s = s.replace(/\r\n/g, "\n");
  s = s.replace(/[ \t]+\n/g, "\n");
  s = s.replace(/\n{3,}/g, "\n\n");
  s = s.trim();

  return s || "—";
}

/* ------------------ cache ------------------ */

function makeCacheKey(kind, qid, lang, picked) {
  const safe = (v) => String(v || "").replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 60);
  return `${safe(kind)}_${safe(qid)}_${safe(lang)}_${safe(picked)}`;
}

async function tryGetCache(uid, key) {
  if (process.env.ENABLE_EXPLAIN_CACHE !== "true") return null;
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection("ai")
    .doc(`explain_${key}`)
    .get();
  return snap.exists ? asString(snap.data().text, "") : null;
}

async function setCache(uid, key, text) {
  if (process.env.ENABLE_EXPLAIN_CACHE !== "true") return;
  await db
    .collection("users")
    .doc(uid)
    .collection("ai")
    .doc(`explain_${key}`)
    .set({
      text,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/* ------------------ callable ------------------ */

function makeCallable(kind) {
  return functions.region("europe-west1").https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Login required");
    }

    const lang = asString(data && data.language, "ru");
    const q = data && data.question;
    if (!q) {
      throw new functions.https.HttpsError("invalid-argument", "Missing question");
    }

    // ✅ picked comes from top-level payload (NOT q.picked)
    const picked = asString(data && data.picked, "");

    const system = buildSystem(lang, kind);

    let prompt = "";
    if (kind === "math") {
      prompt = buildMathPrompt(lang, q);
    } else if (kind === "analogy") {
      prompt = buildAnalogyPrompt(lang, q);
    } else if (kind === "language") {
      prompt = buildLanguagePrompt(lang, q);
    } else {
      prompt = buildComparisonPrompt(lang, q);
    }

    const cacheKey = makeCacheKey(kind, asString(q.id, "noid"), lang, picked);
    const cached = await tryGetCache(context.auth.uid, cacheKey);
    if (cached) return {text: cached, cached: true};

    const client = getClient();
    const resp = await client.responses.create({
      model: "gpt-4.1-mini",
      input: [
        {role: "system", content: system},
        {role: "user", content: prompt},
      ],
      max_output_tokens: 700,
    });

    const text = sanitizeForClient(resp.output_text || "");
    await setCache(context.auth.uid, cacheKey, text);

    return {text, cached: false};
  });
}

/* ------------------ exports ------------------ */

exports.aiExplainMath = makeCallable("math");
exports.aiExplainAnalogy = makeCallable("analogy");
exports.aiExplainLanguage = makeCallable("language");
exports.aiExplainComparison = makeCallable("comparison");
