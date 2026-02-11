/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

const db = admin.firestore();

exports.seedPricingIfMissing = onCall(
  {region: "europe-west1"},
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "Sign in required");

    const ref = db.doc("config/pricing");
    const snap = await ref.get();
    if (snap.exists) return {ok: true, existed: true};

    await ref.set({
      currencyName: "ZHALBYRAKS",
      currencyCode: "ZB",

      actions: {
        ai_explain: {
          cost: 3,
          enabled: true,
          title: {ru: "Объяснение ИИ", ky: "AI түшүндүрмө", en: "AI explanation"},
        },
        start_mock_test: {
          cost: 5,
          enabled: true,
          title: {ru: "Начать пробный тест", ky: "Сынама тестти баштоо", en: "Start mock test"},
        },
        review_mistakes: {
          cost: 2,
          enabled: true,
          title: {ru: "Разбор ошибок", ky: "Ката талдоо", en: "Review mistakes"},
        },
      },

      earning: {
        daily_login: {amount: 1, maxPerDay: 1, enabled: true},
        streak_complete: {amount: 3, enabled: true},
        mock_complete_base: {amount: 3, enabled: true},
        mock_score_bonus: {
          enabled: true,
          rules: [
            {min: 0, max: 49, bonus: 0},
            {min: 50, max: 74, bonus: 1},
            {min: 75, max: 89, bonus: 2},
            {min: 90, max: 100, bonus: 3},
          ],
        },
      },

      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {ok: true, existed: false};
  },
);
