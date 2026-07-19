/**
 * @file The sol3 Programming Language
 * @author Martin Feineis
 * @license UPL-1.0
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

import {
  LANG,
  keywords,
  operators,
  sym,
  op,
  pkg,
  comparison_operators,
} from "./syntax/spec.mjs";

export default grammar({
  name: LANG,

  word: ($) => $.identifier,

  extras: ($) => [/\s/, $.comment],

  rules: {
    source_file: ($) =>
      choice(
        // One-off scripts without modules
        $.script_decl,
        // One-module-per-file normal modules
        $.module_decl,
        // Applications
        $.application_decl,
        // Experimental modules
        seq(
          $.experimental_module_decl,
          repeat(choice($.experimental_module_decl, $.module_decl)),
        ),
        // Kernel modules
        seq(
          $.kernel_module_decl,
          repeat(
            choice(
              $.kernel_module_decl,
              $.experimental_module_decl,
              $.module_decl,
            ),
          ),
        ),
      ),

    comment: ($) => token(seq(sym.line_comment, /.*/)),

    doc_string: ($) => $._multiline_string_literal,

    keyword: (_) => choice(...Object.values(keywords).flat()),

    operator: (_) => token(choice(...operators)),

    /// Modules and Applications

    script_decl: ($) => repeat1($._toplevel_decl),

    module_decl: ($) =>
      seq(
        optional(field("docs", repeat1($.doc_string))),
        field("signature", $.module_signature),
        repeat($._toplevel_decl),
      ),

    experimental_module_decl: ($) =>
      seq(
        optional(field("docs", repeat1($.doc_string))),
        field("signature", $.experimental_module_signature),
        repeat($._toplevel_decl),
      ),

    kernel_module_decl: ($) =>
      seq(
        optional(field("docs", repeat1($.doc_string))),
        field("signature", $.kernel_module_signature),
        repeat($._toplevel_decl),
      ),

    application_decl: ($) =>
      seq(
        field("docs", repeat1($.doc_string)),
        field("signature", $.application_signature),
        repeat($._toplevel_decl),
      ),

    module_signature: ($) =>
      seq(
        sym.module,
        choice(
          seq($.package_identifier, token.immediate(":"), $.module_identifier),
          alias(/[a-z0-9_]+(\/[a-z0-9_]+)*/, $.module_identifier),
        ),
      ),

    package_identifier: ($) =>
      /[a-zA-Z][a-zA-Z0-9_\-]*(\.[a-zA-Z][a-zA-Z0-9_\-]*)+/,

    module_identifier: ($) => token.immediate(/[a-z0-9_]+(\/[a-z0-9_]+)*/),

    experimental_module_signature: ($) =>
      seq(
        sym.module,
        seq(
          alias(pkg.experimental, $.package_identifier),
          token.immediate(":"),
          $.module_identifier,
        ),
      ),

    kernel_module_signature: ($) =>
      seq(
        sym.module,
        seq(
          alias(pkg.lang, $.package_identifier),
          token.immediate(":"),
          $.module_identifier,
        ),
      ),

    application_signature: ($) =>
      seq(
        sym.application,
        seq($.package_identifier, token.immediate(":"), $.module_identifier),
      ),

    /// Top-level Declarations

    _toplevel_decl: ($) => choice($.let_decl, $.expect_decl),

    _kernel_toplevel_decl: ($) => $._toplevel_decl,

    let_decl: ($) =>
      seq(
        sym.let,
        field("binding", $.identifier),
        op.eq,
        field("value", $._complex_expression),
      ),

    expect_decl: ($) =>
      seq(
        sym.expect,
        field("condition", $.comparison_expression),
        field("warning", optional(seq(sym.otherwise, $._expression))),
      ),

    _complex_expression: ($) => choice($._expression, $.function_expression),

    _expression: ($) => choice($._primitive_value, $.identifier),

    comparison_expression: ($) =>
      seq(
        field("left", $._expression),
        choice(...comparison_operators),
        field("right", $._expression),
      ),

    function_expression: ($) =>
      seq(
        sym.lcurly,
        field("params", $.function_params),
        op.arrow,
        field("body", repeat($._toplevel_decl)),
        field("implicit_return", $._complex_expression),
        sym.rlcurly,
      ),

    function_params: ($) =>
      repeat1(choice($.dont_care, $.identifier, $.ignore)),

    _primitive_value: ($) =>
      choice($.string_literal, $.int_literal, $.decimal_literal),

    /// Terminals

    identifier: (_) => /[a-z][a-zA-Z0-9_]*/,

    int_literal: ($) => /0|-?[1-9]\d*/,

    decimal_literal: ($) => /0|-?\d+\.\d+/,

    dont_care: (_) => sym.dont_care,

    ignore: (_) => token(seq(sym.dont_care, /[a-z][a-zA-Z0-9_]*/)),

    // See https://github.com/tree-sitter/tree-sitter-haskell/blob/master/grammar/literal.js#L36
    string_literal: ($) =>
      seq('"', repeat(choice(/[^\\"\n]/, /\\(\^)?./, /\\\n\s*\\/)), '"'),

    // FIXME: We want "simple" utf-8 in the end so this string escape needs to be adjusted, Elm supports something different
    // See https://github.com/elm-tooling/tree-sitter-elm/blob/main/grammar.js#L699
    _multiline_string_literal: ($) =>
      token(
        seq(
          sym.multi_string_open,
          repeat(
            choice(
              alias(
                token.immediate(repeat1(choice(/[^\\"]/, /"[^"]/, /""[^"]/))),
                $.regular_string_part,
              ),
              /\\(u\{[0-9A-Fa-f]{4,6}\}|[nrt\"'\\])/, // valid string escape
              /\\(u\{[^}]*\}|[^nrt\"'\\])/, // invalid string escape
            ),
          ),
          sym.multi_string_close,
        ),
      ),
  },
});

/**
 * @param {RuleOrLiteral} separator
 * @param {RuleOrLiteral} rule
 */
function sep1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}
