/**
 * @file Lang0 grammar for tree-sitter
 * @author Martin Feineis <mfeineis@users.noreply.github.com>
 * @license UPL
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "lang0",

  // extras: $ => [
  //   $.comment,
  // ],

  word: $ => $.identifier,

  rules: {
    source_file: $ => seq(
      $.module_declaration,
      optional($._declarations),
    ),

    // comment: $ => token(seq('#', repeat(/[^\n]/), '\n')),

    module_declaration: $ => seq(
      $.keyword_module,
      optional(seq(
        $.keyword_as,
        $.module_name_definition,
      )),
      optional($.module_export_list),
    ),

    module_export_list: $ => seq(
      "|",
      sep1("|", $.identifier),
    ),

    _declarations: $ => repeat1(
      $._function_declaration_with_type,
    ),

    _function_declaration_with_type: $ => seq(
      // optional($.type_annotation),
      $.function_declaration,
    ),

    function_declaration: $ => seq(
      $.keyword_function,
      field("name", $.identifier),
      repeat($.function_param),
      // $.eq, // TODO: Do we actually want the "=" for function declarations?
      field("body", $.expression),
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

    expression: $ => choice(
      $.value_expression,
    ),

    value_expression: $ => choice(
      $.identifier,
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

    keyword_module: $ => "module",

    keyword_as: $ => "as",

    keyword_function: $ => "function",

    eq: $ => "=",

    // Module name definitions are very simple file paths
    module_name_definition: $ => seq(
      '"',
      sep1("/", $.module_name_path_fragment),
      '"',
    ),

    identifier: $ => /[_a-z][_a-zA-Z0-9]*/,

    module_name_path_fragment: $ => /[a-z][a-z0-9]*/,

    simple_record_key: $ => alias($.identifier, "simple_record_key"),
    // simple_record_key: $ => /[_a-z][_a-zA-Z0-9]*/,

    // uppercase_identifier: $ => /[A-Z][_0-9a-zA-Z]*/,

    // number: $ => /[1-9][\d]*/,
  }
});

function sep1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}
