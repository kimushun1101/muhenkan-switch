// eslint.config.js — Flat config (ESLint v10 + typescript-eslint v8)
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import eslintConfigPrettier from 'eslint-config-prettier/flat';
import globals from 'globals';

export default tseslint.config(
  { ignores: ['dist/**', 'node_modules/**', '**/*.config.js'] },

  js.configs.recommended,
  ...tseslint.configs.strict,
  ...tseslint.configs.stylistic,

  {
    files: ['src/**/*.ts'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: { ...globals.browser },
    },
  },

  eslintConfigPrettier,
);
