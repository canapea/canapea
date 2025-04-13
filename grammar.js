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
      $.module_declaration,
      optional($._declarations),
    ),

    comment: $ => token(seq('#', repeat(/[^\n]/))),

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
        $._function_declaration_with_type,
        $._toplevel_let_binding_with_type,
      ),
    ),

    _function_declaration_with_type: $ => seq(
      // optional($.type_annotation),
      $.function_declaration,
    ),

    _toplevel_let_binding_with_type: $ => seq(
      // optional($.type_annotation),
      $.let_expression,
    ),

    function_declaration: $ => seq(
      $.function,
      field("name", $.identifier),
      repeat($.function_param),
      $.eq, // TODO: Do we actually want the "=" for function declarations?
      field("body", $._expression),
    ),

    function_param: $ => choice(
      $.identifier,
      $.record_pattern,
    ),

    record_pattern: $ => seq(
      "{",
      sep1(",", $.simple_record_key),
      "}",
    ),

    sequence_pattern: $ => seq(
      "[",
      sep1(",", $.identifier),
      "]",
    ),

    _expression: $ => choice(
      $.let_expression,
      $.value_expression,
    ),

    value_expression: $ => choice(
      $.int_literal,
      $.identifier,
    ),

    let_expression: $ => seq(
      $.let,
      choice(
        $.record_pattern,
        $.sequence_pattern,
        $.identifier,
      ),
      $.eq,
      $._expression,
    ),

    // // See https://github.com/tree-sitter/tree-sitter-haskell/blob/master/grammar/literal.js#L36
    // string: $ => seq(
    //   '"',
    //   repeat(choice(
    //     /[^\\"\n]/,
    //     /\\(\^)?./,
    //     /\\\n\s*\\/,
    //   )),
    //   '"',
    // ),

    module: $ => "module",

    as: $ => "as",

    import: $ => "import",

    function: $ => "function",

    let: $ => "let",

    eq: $ => "=",

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

    simple_record_key: $ => alias($.identifier, "simple_record_key"),
    // simple_record_key: $ => /[_a-z][_a-zA-Z0-9]*/,

    uppercase_identifier: $ => /[A-Z][a-zA-Z0-9]*/,

    int_literal: $ => token(/-?[1-9][_\d]*/),
  }
});

function sep1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}
