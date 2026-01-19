module.exports = {
  env: {
    es6: true,
    node: true,
  },

  // 🔧 Allow modern JS so deploy-time parser error disappears
  parserOptions: {
    ecmaVersion: 2020,
  },

  extends: [
    "eslint:recommended",
    "google",
  ],

  rules: {
    // ---- Keep your existing intent ----
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", {allowTemplateLiterals: true}],

    // ---- Disable rules that break Firebase Functions on Windows ----
    "require-jsdoc": "off",
    "max-len": "off",
    "linebreak-style": "off",

    // ---- Optional sanity ----
    "object-curly-spacing": ["error", "never"],

    "indent": "off",
    "comma-dangle": "off",
  },

  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],

  globals: {},
};
