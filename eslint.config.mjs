import globals from 'globals';
import js from '@eslint/js';

export default [
  // The first object defines files to ignore globally.
  {
    ignores: [
      '**/node_modules/',
      '**/vendor/',
      '**/public/',
      '**/tmp/',
      '**/bin/',
      '**/config/',
      '**/db/'
    ]
  },
  // Directly includes the rules from 'eslint:recommended'.
  js.configs.recommended,
  // Defines parser options and your custom, non-strict rules.
  {
    languageOptions: {
      // Sets the runtime environment for global variables.
      globals: {
        ...globals.browser,
        // Add other globals here (e.g., ...globals.node)
      },
      // Uses the latest ECMAScript version.
      ecmaVersion: 'latest',
      // Specifies the code is using ES Modules syntax (import/export).
      sourceType: 'module',
    },
    rules: {
      // JS Standard: Enforce single quotes (matches your Ruby convention)
      'quotes': ['error', 'single', { 'avoidEscape': true, 'allowTemplateLiterals': true }],

      // JS Standard: Enforce semicolons
      'semi': ['error', 'always'],

      // Logic readability: 120 chars max (matches your Ruby convention)
      'max-len': ['error', {
        'code': 120,
        'ignoreComments': true,
        'ignoreTrailingComments': true,
        'ignoreUrls': true,
        'ignoreStrings': true,
        'ignoreTemplateLiterals': true,
        'ignoreRegExpLiterals': true
      }]
    },
  }
];
