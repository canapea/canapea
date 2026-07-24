export const LANG = "sol3";
export const SCHEMA_VERSION = 1;
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
  exposing: "exposing",
  let: "let",
  expect: "expect",
  reporting: "reporting",
  line_comment: "#",
  string_open: '"',
  string_close: '"',
  multi_string_open: '"""',
  multi_string_close: '"""',
  seq_open: "[",
  seq_close: "]",
  lcurly: "{",
  rcurly: "}",
  dont_care: "_",
  type: "type",
  import_caps: "capabilities",
  cap_prefix: "+",
  format: "format",
  yield: "yield",
  debug: "debug",
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
  declaration: [sym.application, sym.module, sym.exposing, sym.let],
  import: [sym.importing],
  storage: [sym.type],
  control: [
    // "when",
  ],
  io: [
    // "error"
  ],
  modifier: [
    sym.format,
    sym.yield,
    // "as",
    // "record",
    // "is",
    sym.reporting,
  ],
  meta: [sym.debug, sym.expect],
  unused: [sym.dont_care],
};

// semanticToken: "enumMember",
export const scopes = {
  comments: {
    line: {
      comment: "line_comment",
      hlt: "comment",
      tsg: "comment",
      tmg: "comment.line.number-sign",
    },
    region: {
      comment: "region_comment_block",
      hlt: "comment",
      tmg: "comment.block",
    },
  },
  keywords: {
    declaration: {
      comment: "keyword_declaration",
      hlt: "keyword.other.declaration",
      tmg: "keyword.other.declaration",
      // semanticToken: "keyword",
      no_hlt_yet: {
        [sym.exposing]: true,
      },
      to_tsg: {
        [sym.application]: "application_decl",
        [sym.module]: [
          "script_decl",
          "module_decl",
          "experimental_module_decl",
          "kernel_module_decl",
        ],
        [sym.let]: "let_decl",
      },
    },
    import: {
      comment: "keyword_import",
      hlt: "meta.import",
      tmg: "keyword.other.import",
      to_tsg: {
        [sym.importing]: "import_decl",
      },
    },
    storage: {
      comment: "keyword_storage",
      hlt: "keyword.type",
      tmg: "storage.type",
      no_hlt_yet: {
        [sym.type]: true,
      },
    },
    control: {
      comment: "keyword_control",
      // hlt: "keyword",
      tmg: "keyword.control",
    },
    io: {
      comment: "keyword_io",
      hlt: "keyword",
      tmg: "keyword.other.io",
    },
    meta: {
      comment: "keyword_meta",
      hlt: "keyword.operator",
      tmg: "keyword.other.meta",
      no_hlt_yet: {
        [sym.debug]: true,
      },
      to_tsg: {
        [sym.expect]: "expect_decl",
      },
    },
    modifier: {
      comment: "keyword_modifier",
      hlt: "keyword",
      tmg: "keyword.other.modifier",
      no_hlt_yet: {
        [sym.format]: true,
        [sym.yield]: true,
      },
    },
    unused: {
      comment: "keyword_unused",
      hlt: "keyword",
      tmg: "keyword.unused",
      to_tsg: {
        [sym.dont_care]: "dont_care",
      },
    },
  },
  literals: {
    string: {
      comment: "string",
      hlt: "string",
      tsg: "string_literal",
      tmg: "string.quoted.double",
      // semanticToken: "string",
    },
    doc_string: {
      comment: "doc_string",
      hlt: "string.documentation",
      tsg: "doc_string",
      tmg: "string.quoted.triple",
    },
    multi_string: {
      comment: "multi_string",
      hlt: "string",
      tmg: "string.quoted.triple",
      // semanticToken: "string",
    },
    int: {
      comment: "int_literal",
      hlt: "constant.numeric",
      tsg: "int_literal",
      tmg: "constant.numeric",
    },
    decimal: {
      comment: "decimal_literal",
      hlt: "constant.numeric",
      tmg: "constant.numeric",
      tsg: "decimal_literal",
    },
  },
  operators: {
    assignment: {
      comment: "assignment_operator",
      hlt: "keyword.operator.assignment",
      tmg: "keyword.operator.assignment",
    },
    arrow: {
      comment: "arrow_operator",
      // hlt: "keyword.operator.arrow",
      tmg: "keyword.operator.arrow",
    },
    other: {
      comment: "other_operators",
      hlt: "keyword.operator",
      tmg: "keyword.operator.other",
      no_hlt_yet: {
        [op.and]: true,
        [op.bang]: true,
        [op.equals]: true,
        [op.field_def]: true,
        [op.module_access]: true,
        [op.not_equals]: true,
        [op.or]: true,
      },
    },
    pipe: {
      comment: "pipe_operator",
      // hlt: "keyword.operator.pipe",
      tmg: "keyword.operator.pipe",
    },
  },
  punctuation: {
    bracket: {
      comment: "punctuation_bracket",
      hlt: "punctuation.section.bracket",
      tmg: "punctuation.bracket",
    },
    sequence: {
      comment: "punctuation_sequence",
      hlt: "punctuation.section.bracket",
      tmg: "punctuation.definition.sequence",
    },
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

export const other_operators = operators.filter(
  (x) => ![op.eq, op.arrow, op.pipe].includes(x),
);
