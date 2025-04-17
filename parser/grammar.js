/**
 * @file Canapea grammar for tree-sitter
 * @author Martin Feineis
 * @license UPL-1.0
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "canapea",

  // See https://github.com/elm-tooling/tree-sitter-elm/blob/main/grammar.js#L33
  extras: $ => [
    $.comment,
    /[\s\uFEFF\u2060\u200B]|\\\r?\n/,
  ],

  // Order is significant(!) for custom src/scanner.c:TokenType
  externals: $ => [
    $.implicit_block_open,
    $.implicit_block_close,
    $.is_in_error_recovery, // Unused in grammar, just convenience for scanner
  ],

  // externals: $ => [$.if_keyword],
  // then using it in a rule like so:
  //if_statement: $ => seq(alias($.if_keyword, 'if'), ...),

  word: $ => $.identifier,

  rules: {
    source_file: $ => seq(
      optional($.toplevel_docs),
      choice(
        $.app_declaration,
        $.module_declaration,
      ),
      optional($._toplevel_declarations),
    ),

    comment: $ => token(seq('#', repeat(/[^\n]/))),

    toplevel_docs: $ => $.multiline_string_literal,

    ignored_type_annotation: $ => seq($.identifier, token(seq(":", /[^\n]*/))),

    app_declaration: $ => seq(
      $.app,
      $.with,
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

    _toplevel_declarations: $ => repeat1(
      choice(
        $.function_declaration,
        $.let_expression,
        $.toplevel_docs,
        // $._function_declaration_with_type,
        // $._toplevel_let_binding_with_type,
      ),
    ),

    // TODO: We're keeping ourselves open to introduce explicit blocks, if we really need to
    _implicit_block_open: $ => $.implicit_block_open,
    _implicit_block_close: $ => $.implicit_block_close,

    function_declaration: $ => seq(
      optional($.ignored_type_annotation),
      $.function,
      field("name", $.identifier),
      repeat($.function_parameter),
      $.eq, // TODO: Do we actually want the "=" for function declarations?
      $._implicit_block_open,
      $._block_body,
      $._implicit_block_close,
    ),

    // TODO: Implement "don't care" _ parameter
    function_parameter: $ => choice(
      $.record_pattern,
      $.sequence_pattern,
      $.identifier,
    ),

    // A couple of local bindings, the last expression is the return value
    _block_body: $ => choice(
      seq(
        field("binding", repeat1($.let_expression)),
        field("return", $._atom),
      ),
      field("return", $._atom),
    ),

    record_pattern: $ => seq(
      "{",
      sep1(",", $.simple_record_key),
      "}",
    ),

    // TODO: Implement special "don't care" _ parameter
    sequence_pattern: $ => prec(
      1,
      seq(
        "[",
        sep1(",",
          choice(
            $.int_literal,
            $.string_literal,
            $.identifier,
          ),
        ),
        optional(seq(",", $.rest_args)),
        "]",
      ),
    ),

    _atom: $ => choice(
      $._atom_in_parens,
      $._atom_not_in_parens
    ),

    // TODO: Do we actually need the parens in the AST? Might be useful for editors
    _atom_in_parens: $ => seq(
      $.parenL,
      $._atom_not_in_parens,
      $.parenR,
    ),

    _atom_not_in_parens: $ => choice(
      $.anonymous_function_expression,
      $.when_expression,
      $.operator_expression,
      $.value_expression,
      $.int_literal,
      $.record_expression,
      $.sequence_expression,
      $.string_literal,
      $.call_expression,
    ),

    // TODO: Pulling back operator precedence seems to work for (|>), no idea what to do about other operators
    operator_expression: $ => prec(
      0,
      prec.left(
        seq(
          $._atom,
          $.operator,
          $._atom,
        ),
      ),
    ),
    // operator_expression: $ => prec(
    //   1,
    //   prec.right(
    //     seq(
    //       $._atom,
    //       repeat1(seq($.operator, $._atom)),
    //     ),
    //   ),
    // ),

    operator: $ => $.operator_identifier,

    value_expression: $ => choice(
      $.identifier,
      $.qualified_accessor,
    ),

    let_expression: $ => seq(
      optional($.ignored_type_annotation),
      $.let,
      choice(
        $.record_pattern,
        $.sequence_pattern,
        $.identifier,
      ),
      $.eq,
      $._implicit_block_open,
      $._block_body,
      $._implicit_block_close,
    ),

    anonymous_function_expression: $ => seq(
      "{",
      optional(seq(
        sep1(",", $.function_parameter),
        $.arrow,
      )),
      $._block_body,
      "}",
    ),

    // Record splats are only allowed as the first entry
    record_expression: $ => seq(
      "{",
      optional(seq(
        $.record_expression_splat,
        ",",
      )),
      sep1(",", $.record_expression_entry),
      "}",
    ),

    record_expression_entry: $ => seq(
      field("key", $.simple_record_key),
      $.eq,
      field("value", $._atom),
    ),

    sequence_expression: $ => seq(
      "[",
      sep1(",", $.sequence_expression_entry),
      "]",
    ),

    sequence_expression_entry: $ => choice(
      $._atom,
      $.sequence_expression_splat,
    ),

    conditional_expression: $ => seq(
      field("left", $._atom),
      $.eqeq,
      field("right", $._atom),
    ),

    // When matches as many branches as it can
    when_expression: $ => prec.right(
      seq(
        $.when,
        field("subject", $._atom),
        $.is,
        repeat(seq("|", $.when_branch)),
        optional(seq("|", $.when_branch_catchall)),
      ),
    ),

    when_branch: $ => seq(
      $.when_branch_pattern,
      optional(seq(
        $.where,
        $.when_branch_pattern_guard,
      )),
      $.arrow,
      $.when_branch_consequence,
    ),

    when_branch_catchall: $ => seq(
      $.else,
      $.arrow,
      $.when_branch_consequence,
    ),

    when_branch_pattern: $ => choice(
      $.record_pattern,
      $.sequence_pattern,
      $.string_literal,
      $.int_literal,
    ),

    when_branch_pattern_guard: $ => choice(
      $.conditional_expression,
    ),

    when_branch_consequence: $ => prec(1, choice(
      $._atom,
    )),

    call_expression: $ => prec(
      0,
      prec.left(
        seq(
          $.call_target,
          repeat1($.call_parameter),
        ),
      ),
    ),

    call_target: $ => prec(
      2,
      $.value_expression,
    ),

    call_parameter: $ => prec(
      3,
      choice(
        $.value_expression,
        $._atom,
      ),
    ),

    app: $ => "app",
    with: $ => "with",
    module: $ => "module",
    as: $ => "as",
    import: $ => "import",
    function: $ => "function",
    let: $ => "let",
    dot: $ => ".",
    dotdotdot: $ => "...",
    eq: $ => "=",
    eqeq: $ => "==",
    when: $ => "when",
    is: $ => "is",
    where: $ => "where",
    else: $ => "else",
    arrow: $ => "->",
    parenL: $ => "(",
    parenR: $ => ")",
    pathSep: $ => "/",
    versionAt: $ => "@",
    // colon: $ => ":",

    // Module name definitions are very simple file paths
    module_name_definition: $ => seq(
      '"',
      sep1($.pathSep, $.module_name_path_fragment),
      '"',
    ),

    // Module imports can contain version information so
    module_import_name: $ => seq(
      '"',
      sep1($.pathSep, $.module_name_path_fragment),
      optional(seq($.versionAt, $.module_version)),
      '"',
    ),

    module_version: $ => choice(
      field("name", /[-a-z]+/),
      field("version", /\d+(?:\.\d+){0,2}(?:\-[a-zA-Z][a-zA-Z0-9]*)?/),
    ),

    identifier: $ => /[_a-z][_a-zA-Z0-9]*/,

    qualified_accessor: $ => seq(
      $.identifier,
      $.dot,
      $.identifier,
    ),

    module_name_path_fragment: $ => /[a-z][a-z0-9]*/,

    // FIXME: Had to declare precedence to disambiguate, probably because of the
    //        regex match being exactly the same and the parser not being able
    //        to choose although it should be able to do so in this context...
    // function x =
    //   { { x, y, z } -> x }
    //        ^-- (function_parameter identifier) X (simple_record_key identifier)
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

    multiline_string_literal: $ => seq(
      alias('"""', $.open_quote),
      repeat(
        choice(
          alias(
            token.immediate(
              repeat1(choice(/[^\\"]/, /"[^"]/, /""[^"]/))
            ),
            $.regular_string_part
          ),
          $.string_escape,
          $.invalid_string_escape
        )
      ),
      alias('"""', $.close_quote)
    ),

    // FIXME: We want "simple" utf-8 in the end so this string escape needs to be adjusted, Elm supports something different
    // See https://github.com/elm-tooling/tree-sitter-elm/blob/main/grammar.js#L699
    string_escape: $ => /\\(u\{[0-9A-Fa-f]{4,6}\}|[nrt\"'\\])/,
    invalid_string_escape: $ => /\\(u\{[^}]*\}|[^nrt\"'\\])/,

    // FIXME: All the rest args and splats only support simple identifiers right now!
    rest_args: $ => seq($.dotdotdot, $.rest_args_identifier),
    rest_args_identifier: $ => token.immediate(/[_a-z][_a-zA-Z0-9]*/),

    sequence_expression_splat: $ => seq($.dotdotdot, $.sequence_expression_splat_identifier),
    sequence_expression_splat_identifier: $ => token.immediate(/[_a-z][_a-zA-Z0-9]*/),

    record_expression_splat: $ => seq($.dotdotdot, $.record_expression_splat_identifier),
    record_expression_splat_identifier: $ => token.immediate(/[_a-z][_a-zA-Z0-9]*/),

    operator_identifier: $ => "|>",
  }
});

function sep1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}
