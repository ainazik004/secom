/* eslint-disable max-len */
/* eslint-disable require-jsdoc */

// functions/index.js
const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/v2/scheduler");

// Init once (shared by all modules)
admin.initializeApp();
const db = admin.firestore();

// -------------------------------
// 1) AI EXPLAIN
// -------------------------------
const explain = require("./explain_ai");

exports.aiExplainMath = explain.aiExplainMath;
exports.aiExplainAnalogy = explain.aiExplainAnalogy;
exports.aiExplainLanguage = explain.aiExplainLanguage;
exports.aiExplainComparison = explain.aiExplainComparison;
exports.spendZhalbyraks = require("./spend_wallet").spendZhalbyraks;
exports.refundZhalbyraks = require("./refund_wallet").refundZhalbyraks;

// Wallet init (new users)
exports.initWalletOnUserCreate = require("./wallet").initWalletOnUserCreate;

// Optional one-time pricing seeder (callable)
exports.seedPricingIfMissing = require("./seed_pricing").seedPricingIfMissing;

// -------------------------------
// 2) Mistake report
// -------------------------------
exports.submitMistakeReport = require("./submitMistakeReport").submitMistakeReport;

// -------------------------------
// 3) Streak reset (scheduled)
// -------------------------------
const {runStreakResetJob} = require("./streak_reset");

exports.resetStreakIfNoStudyToday = onSchedule(
  {
    schedule: "59 23 * * *",
    timeZone: "Asia/Bishkek",
    region: "europe-west1",
    memory: "512MiB",
  },
  async () => {
    await runStreakResetJob({admin, db});
  }
);
