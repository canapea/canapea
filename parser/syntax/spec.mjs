export const LANG = "sol3";
export const EXT = `${LANG}`;
export const SCOPE = `source.${LANG}`;
export const NAME = `${LANG} Programming Language`;

export const pkg = {
  lang: LANG,
  experimental: "experimental",
};

export const sym = {
  application: "application",
  module: "module",
  importing: "importing",
  exporting: "exporting",
  let: "let",
  expect: "expect",
  otherwise: "otherwise",
  line_comment: "#",
  string_open: '"',
  string_close: '"',
  multi_string_open: '"""',
  multi_string_close: '"""',
  seq_open: "[",
  seq_close: "]",
  lcurly: "{",
  rlcurly: "}",
  dont_care: "_",
  type: "type",
};

export const op = {
  eq: "=",
  equals: "==",
  not_equals: "!=",
  arrow: "->",
  or: "or",
  and: "and",
  bang: "!",
  pipe: "|>",
  module_access: "::",
  field_def: ":",
};

export const keywords = {
  declaration: [
    sym.application,
    sym.module,
    sym.importing,
    sym.exporting,
    sym.let,
  ],
  storage: [sym.type],
  control: ["when"],
  io: ["error"],
  modifier: ["format", "yield", "as", "record", "is", sym.otherwise],
  meta: ["debug", sym.expect],
  unused: [sym.dont_care],
};

export const scopes = {
  declarationKeyword: {
    treeSitter: "keyword",
    textMate: `keyword.declaration.${LANG}`,
    semanticToken: "keyword",
  },
  constructor: {
    treeSitter: "type.enum.variant",
    textMate: `entity.name.type.variant.${LANG}`,
    semanticToken: "enumMember",
  },
};

export const comparison_operators = [op.equals, op.not_equals];

export const boolean_operators = [op.or, op.and];

export const effect_operators = [op.bang];

export const operators = [
  op.arrow,
  op.pipe,
  op.eq,
  op.module_access,
  op.field_def,
  ...comparison_operators,
  ...boolean_operators,
  ...effect_operators,
];
