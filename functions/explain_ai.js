require("dotenv").config();

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const OpenAI = require("openai").default;

function get(obj, key, fallback) {
  if (!obj) return fallback;
  const v = obj[key];
  return v === undefined || v === null ? fallback : v;
}

function asString(v, fallback) {
  if (v === undefined || v === null) return fallback || "";
  return String(v);
}

function getClient() {
  const key = process.env.OPENAI_API_KEY;
  if (!key) throw new Error("Missing OPENAI_API_KEY in environment");
  return new OpenAI({apiKey: key});
}

exports.aiExplainQuestion = functions.https.onCall(async (data, context) => {
  if (!context || !context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }

  const q = data && data.question;
  if (!q || typeof q !== "object") {
    throw new functions.https.HttpsError("invalid-argument", "Missing question.");
  }

  const stem = asString(get(q, "stem", ""), "");
  const options = get(q, "options", {});
  const answer = asString(get(q, "answer", ""), "");
  const picked = asString(get(q, "picked", ""), "");

  const lang = asString((data && data.language) ? data.language : "ru", "ru"); // "ru" or "ky"

  if (stem.length < 3 || stem.length > 2000) {
    throw new functions.https.HttpsError("invalid-argument", "Bad stem length.");
  }

  if (!options || typeof options !== "object") {
    throw new functions.https.HttpsError("invalid-argument", "Bad options type.");
  }

  const optionLines = Object.entries(options)
      .map((kv) => {
        const k = kv[0];
        const v = kv[1];
        return k + ") " + asString(v, "");
      })
      .join("\n");

  const instructions =
    lang === "ky" ?
      "Сен мугалимсиң. Кыска, түшүнүктүү түшүндүр. Жоопту кантип табууну 3–6 кадам менен айт. Формулаларды жөнөкөй бер. Акырында туура жоопту айт." :
      "Ты учитель. Объясни кратко и понятно. Дай 3–6 шагов как получить ответ. Формулы — простые. В конце укажи правильный вариант.";

  const prompt = [
    instructions,
    "",
    "Вопрос:",
    stem,
    "",
    "Варианты:",
    optionLines,
    "",
    "Правильный вариант: " + answer,
    "Выбранный пользователем: " + (picked ? picked : "(не выбран)"),
    "",
    "Ответ:",
  ].join("\n");

  try {
    const client = getClient();

    const resp = await client.responses.create({
      model: "gpt-4.1-mini",
      input: prompt,
      max_output_tokens: 350,
    });

    const text = (resp && resp.output_text ? String(resp.output_text) : "").trim() || "—";
    return {text};
  } catch (e) {
    console.error("aiExplainQuestion error:", e);
    throw new functions.https.HttpsError("internal", "AI error.");
  }
});
