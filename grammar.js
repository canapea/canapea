/**
 * @file Lang0 grammar for tree-sitter
 * @author Martin Feineis <mfeineis@users.noreply.github.com>
 * @license UPL
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "lang0",

  // See https://github.com/elm-tooling/tree-sitter-elm/blob/main/grammar.js#L33
  extras: $ => [
    $.comment,
    /[\s\uFEFF\u2060\u200B]|\\\r?\n/,
  ],

  word: $ => $.identifier,

  rules: {
    source_file: $ => seq(
      choice(
        $.app_declaration,
        $.module_declaration,
      ),
      optional($._declarations),
    ),

    comment: $ => token(seq('#', repeat(/[^\n]/))),

    ignored_type_annotation: $ => seq($.identifier, token(seq(":", /[^\n]*/))),

    app_declaration: $ => seq(
      $.app,
      "with",
      $.record_expression,
      optional($.module_imports),
    ),

    module_declaration: $ => seq(
      $.module,
      optional(seq(
        $.as,
        $.module_name_definition,
      )),
      optional($.module_export_list),
      optional($.module_imports),
    ),

    module_export_list: $ => seq(
      "|",
      sep1("|", $.identifier),
    ),

    module_imports: $ => repeat1($.import_clause),

    import_clause: $ => seq(
      $.import,
      $.module_import_name,
      // There are no side-effect modules so import qualified
      // and/or import types from the module
      choice(
        $.import_expose_list,
        seq(
          $._import_qualified,
          $.import_expose_list,
        ),
        $._import_qualified,
      ),
    ),

    _import_qualified: $ => seq($.as, field("qualified", $.identifier)),

    import_expose_list: $ => seq(
      "|",
      sep1("|", $.import_expose_item),
    ),

    import_expose_item: $ => alias($.uppercase_identifier, "import_expose_item"),

    _declarations: $ => repeat1(
      choice(
        $.ignored_type_annotation,
        $.function_declaration,
        $.let_expression,
        // $._function_declaration_with_type,
        // $._toplevel_let_binding_with_type,
      ),
    ),

    // _function_declaration_with_type: $ => seq(
    //   // optional($.type_annotation),
    //   $.function_declaration,
    // ),

    // _toplevel_let_binding_with_type: $ => seq(
    //   // optional($.type_annotation),
    //   // optional($.ignored_type_annotation),
    //   $.let_expression,
    // ),

    function_declaration: $ => seq(
      $.function,
      field("name", $.identifier),
      repeat($.function_param),
      $.eq, // TODO: Do we actually want the "=" for function declarations?
      field("body", $._expression),
    ),

    function_param: $ => choice(
      $.record_pattern,
      $.identifier,
    ),

    record_pattern: $ => seq(
      "{",
      sep1(",", $.simple_record_key),
      "}",
    ),

    sequence_pattern: $ => seq(
      "[",
      sep1(",", $.identifier),
      optional(seq(",", $.rest_args)),
      "]",
    ),

    _expression: $ => choice(
      $.let_expression,
      $.value_expression,
      $.lambda_expression,
    ),

    value_expression: $ => choice(
      $.int_literal,
      $.identifier,
      $.record_expression,
      $.sequence_expression,
      $.string_literal,
    ),

    let_expression: $ => seq(
      $.let,
      choice(
        $.record_pattern,
        $.sequence_pattern,
        $.identifier,
      ),
      $.eq,
      field("body", $._expression),
    ),

    lambda_expression: $ => seq(
      "{",
      optional(seq(
        sep1(",", $.function_param),
        "->",
      )),
      repeat($.let_expression),
      $._expression,
      "}",
    ),

    record_expression: $ => seq(
      "{",
      sep1(",", seq(
        $.simple_record_key,
        $.eq,
        $.value_expression,
      )),
      "}",
    ),

    sequence_expression: $ => seq(
      "[",
      sep1(",", $.value_expression),
      "]",
    ),

    conditional_expression: $ => seq(
      $.value_expression,
      $.eqeq,
      $.value_expression,
    ),

    when_expression: $ => seq(
      $.when,
      $.value_expression,
      $.is,
      "|",
      sep1("|", seq(
        $._when_pattern,
        optional(seq(
          $.where,
          $.when_pattern_guard,
        )),
        "->",
        $.value_expression,
      )),
    ),

    _when_pattern: $ => choice(
      $.else,
      $.record_pattern,
      $.sequence_pattern,
      $.string_literal,
      $.int_literal,
    ),

    when_pattern_guard: $ => choice(
      $.conditional_expression,
    ),

    app: $ => "app",

    module: $ => "module",

    as: $ => "as",

    import: $ => "import",

    function: $ => "function",

    let: $ => "let",

    dotdotdot: $ => "...",

    eq: $ => "=",

    eqeq: $ => "==",

    when: $ => "when",

    is: $ => "is",

    where: $ => "where",

    else: $ => "else",

    // Module name definitions are very simple file paths
    module_name_definition: $ => seq(
      '"',
      sep1("/", $.module_name_path_fragment),
      '"',
    ),

    // Module imports can contain version information so
    module_import_name: $ => seq(
      '"',
      sep1("/", $.module_name_path_fragment),
      optional(seq("@", $.module_version)),
      '"',
    ),

    module_version: $ => choice(
      field("name", /[-a-z]+/),
      field("version", /\d+(?:\.\d+){0,2}(?:\-[a-zA-Z][a-zA-Z0-9]*)?/),
    ),

    identifier: $ => /[_a-z][_a-zA-Z0-9]*/,

    module_name_path_fragment: $ => /[a-z][a-z0-9]*/,

    // FIXME: Had to declare precedence to disambiguate, probably because of the
    //        regex match being exactly the same and the parser not being able
    //        to choose although it should be able to do so in this context...
    // function x =
    //   { { x, y, z } -> x }
    //        ^-- (function_param identifier) X (simple_record_key identifier)
    simple_record_key: $ => prec(1, alias($.identifier, "simple_record_key")),
    // simple_record_key: $ => /[_a-z][_a-zA-Z0-9]*/,

    uppercase_identifier: $ => /[A-Z][a-zA-Z0-9]*/,

    int_literal: $ => token(/0|-?[1-9][_\d]*/),

    // See https://github.com/tree-sitter/tree-sitter-haskell/blob/master/grammar/literal.js#L36
    string_literal: $ => seq(
      '"',
      repeat(choice(
        /[^\\"\n]/,
        /\\(\^)?./,
        /\\\n\s*\\/,
      )),
      '"',
    ),

    rest_args: $ => seq($.dotdotdot, $.rest_args_identifier),
    
    rest_args_identifier: $ => token.immediate(/[_a-z][_a-zA-Z0-9]*/),
  }
});

function sep1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}
