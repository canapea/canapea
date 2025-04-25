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
    $.implicit_empty_block,
    $.implicit_block_close,
    $.terminator,
    $.is_in_error_recovery, // Unused in grammar, just convenience for scanner
  ],

  // word: $ => $.identifier, //_keyword_extraction,

  rules: {
    source_file: $ => seq(
      optional($.toplevel_docs),
      choice(
        seq(
          $.development_module_declaration,
          $._development_toplevel_declarations,
        ),
        seq(
          choice(
            $.app_declaration,
            $.module_declaration,
          ),
          optional($._toplevel_declarations),
        ),
      ),
      $._terminator,
    ),

    comment: $ => token(seq('#', repeat(/[^\n]/))),

    toplevel_docs: $ => $.multiline_string_literal,

    // TODO: Actually implement type annotations
    ignored_type_annotation: $ => seq(
      choice(
        $.identifier,
        seq($.operator, $._parenL, $.mathy_operator, $._parenR),
      ),
      token(prec(1, seq(":", /[^\n]*/))),
    ),

    app_declaration: $ => seq(
      $.app,
      $.with,
      $.record_expression,
      optional($.module_imports),
    ),

    module_declaration: $ => seq(
      $.module,
      optional($.module_name_definition),
      optional($.module_export_list),
      optional($.module_imports),
    ),

    development_module_declaration: $ => seq(
      $.module,
      '"',
      choice($.core, $.experimental),
      $.pathSep,
      sep1($.pathSep, $.module_name_path_fragment),
      '"',
      optional($.module_export_list),
      optional($.module_imports),
    ),

    module_export_list: $ => seq(
      $.exposing,
      // TODO: Optional leading "|"? after `exposing`?
      $._pipe,
      choice(
        sep1($._pipe, $.module_export_type),
        sep1($._pipe, $.module_export_function),
        seq(
          sep1($._pipe, $.module_export_type),
          $._pipe,
          sep1($._pipe, $.module_export_function),
        ),
      ),
    ),

    // TODO: Do we really want to support exporting only a subset of type constructors?
    module_export_type: $ => seq(
      field("type", $.custom_type_constructor_name),
      optional(
        choice(
          field("all_constructors", seq($._parenL, $.dotdot, $._parenR)),
          seq(
            $._parenL,
            sep1(
              $._comma,
              field("constructor", $.custom_type_constructor_name),
            ),
            $._parenR,
          ),
        ),
      ),
    ),

    module_export_function: $ => alias(
      $.identifier,
      "module_export_function",
    ),

    module_imports: $ => repeat1($.import_clause),

    // There are no side-effect modules so import qualified
    // and/or import types from the module
    import_clause: $ => seq(
      $.import,
      $.implicit_block_open,
      $.module_import_name,
      choice(
        seq(
          $._import_qualified,
          choice(
            $._implicit_empty_block,
            $.import_expose_list,
          ),
        ),
        $.import_expose_list,
      ),
      $.implicit_block_close,
    ),

    _import_qualified: $ => seq($.as, field("qualified", $.identifier)),

    import_expose_list: $ => seq(
      $.exposing,
      $.implicit_block_open,
      $._pipe,
      sep1($._pipe, $.import_expose_type),
      $.implicit_block_close,
    ),

    import_expose_type: $ => seq(
      choice(
        field("type", $.custom_type_constructor_name),
        seq(
          field("type", $.custom_type_constructor_name),
          $.as,
          field("exposed_as", $.custom_type_constructor_name),
        ),
      ),
      optional(
        seq(
          $._parenL,
          sep1($._comma, $.import_expose_type_constructor),
          $._parenR,
        ),
      ),
    ),

    import_expose_type_constructor: $ => seq(
      field("constructor", $.custom_type_constructor_name),
      optional(
        seq(
          $.as,
          field("exposed_as", $.custom_type_constructor_name),
        ),
      ),
    ),

    _toplevel_declarations: $ => repeat1(
      choice(
        $.function_declaration,
        $.let_expression,
        $.toplevel_docs,
        $.custom_type_declaration,
        $.record_declaration,
        field("expect", $.expect_assertion),
      ),
    ),

    _development_toplevel_declarations: $ => repeat1(
      choice(
        prec.left(
          $._toplevel_declarations,
        ),
        field("concept", $.type_concept_declaration),
        field("instance", $.type_concept_instance_declaration),
      ),
    ),

    expect_assertion: $ => seq(
      $.expect,
      $.conditional_expression,
    ),

    function_declaration: $ => seq(
      optional($.ignored_type_annotation),
      $.function,
      field("name", $.identifier),
      repeat1($.function_parameter),
      $.eq, // TODO: Do we actually want the "=" for function declarations?
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    function_parameter: $ => prec(
      1,
      choice(
        $.dont_care,
        $.record_pattern,
        $.sequence_pattern,
        seq($._parenL, $.custom_type_pattern, $._parenR),
        $.identifier,
      ),
    ),

    // A couple of local bindings, the last expression is the return value
    _block_body: $ => choice(
      seq(
        repeat1(
          choice(
            field("binding", $.let_expression),
            field("expect", $.expect_assertion),
          ),
        ),
        field("return", $._call_or_atom),
      ),
      field("single_return", $._call_or_atom),
    ),

    record_pattern: $ => seq(
      $._curlyL,
      sep1($._comma, $.simple_record_key),
      $._curlyR,
    ),

    sequence_pattern: $ => prec(
      1,
      seq(
        $._bracketL,
        sep1(
          $._comma,
          choice(
            $.dont_care,
            $._literal_expression,
            $.record_pattern,
            $.custom_type_pattern,
            $.identifier,
          ),
        ),
        optional(seq($._comma, $.rest_args)),
        $._bracketR,
      ),
    ),

    custom_type_pattern: $ => prec(
      1,
      choice(
        $.custom_type_trivial_value_expression,
        $._complex_custom_type_pattern,
      ),
    ),

    _complex_custom_type_pattern: $ => prec.right(
      seq(
        $.custom_type_constructor_name,
        repeat(
          choice(
            $.sequence_pattern,
            $.record_pattern,
            $.identifier,
            $.custom_type_pattern,
            $.dont_care,
            seq($._parenL, $.custom_type_pattern, $._parenR),
          ),
        ),
      ),
    ),

    _call_or_atom: $ => choice(
      seq($.parenL, $.call_expression, $.parenR),
      $.call_expression,
      $._atom,
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
      $.record_expression,
      $.sequence_expression,
      $._literal_expression,
      $.custom_type_trivial_value_expression,
    ),

    _literal_expression: $ => choice(
      $.string_literal,
      $.int_literal,
      $.decimal_literal,
    ),

    // TODO: Pulling back operator precedence seems to work for (|>), no idea what to do about other operators
    operator_expression: $ => prec.left(
      seq(
        $._call_or_atom,
        $.pipe_operator,
        $._call_or_atom,
      ),
    ),

    value_expression: $ => choice(
      $.qualified_access_expression,
      $.identifier,
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
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    anonymous_function_expression: $ => seq(
      $._curlyL,
      choice(
        seq(
          repeat1($.function_parameter),
          $.arrow,
          $._block_body,
        ),
        $._block_body,
      ),
      $._curlyR,
    ),

    // Record splats are only allowed as the first entry
    record_expression: $ => seq(
      $._curlyL,
      optional(seq(
        $.record_expression_splat,
        $._comma,
      )),
      sep1(",", $.record_expression_entry),
      $._curlyR,
    ),

    record_expression_entry: $ => seq(
      field("key", $.simple_record_key),
      $.eq,
      field("value", $._call_or_atom),
    ),

    sequence_expression: $ => seq(
      $._bracketL,
      sep1($._comma, $.sequence_expression_entry),
      $._bracketR,
    ),

    sequence_expression_entry: $ => choice(
      $._atom,
      $.sequence_expression_splat,
    ),

    conditional_expression: $ => seq(
      field("left", $._call_or_atom),
      $.eqeq,
      field("right", $._call_or_atom),
    ),

    when_expression: $ => seq(
      $.when,
      field("subject", $._call_or_atom),
      $.is,
      repeat1($.when_branch),
      choice(
        $.when_branch,
        $.when_branch_catchall,
      ),
    ),

    when_branch: $ => seq(
      $._pipe,
      $.when_branch_pattern,
      optional(seq(
        $.where,
        $.when_branch_pattern_guard,
      )),
      $.arrow,
      $.when_branch_consequence,
    ),

    when_branch_catchall: $ => seq(
      $._pipe,
      $.dont_care,
      $.arrow,
      $.when_branch_consequence,
    ),

    when_branch_pattern: $ => choice(
      $.record_pattern,
      $.sequence_pattern,
      $._literal_expression,
      $.custom_type_pattern,
    ),

    when_branch_pattern_guard: $ => choice(
      $.conditional_expression,
    ),

    when_branch_consequence: $ => seq(
      $.implicit_block_open,
      $._call_or_atom,
      $.implicit_block_close,
    ),

    call_expression: $ => prec.right(
      seq(
        $.call_target,
        repeat1($.call_parameter),
      ),
    ),

    call_target: $ => prec(
      1,
      choice(
        $.value_expression,
        $.custom_type_trivial_value_expression,
      ),
    ),

    call_parameter: $ => prec(
      2,
      choice(
        $.value_expression,
        $._call_or_atom,
      ),
    ),

    // TODO: Make first custom type "|" optional?
    custom_type_declaration: $ => seq(
      $.type,
      field("name", $.custom_type_constructor_name),
      repeat($.type_variable),
      $.eq,
      $._implicit_block_open,
      $._pipe, // optional($._pipe), 
      sep1(
        $._pipe,
        choice(
          $.custom_type_constructor_declaration,
          $.custom_type_constructor,
        ),
      ),
      $._implicit_block_close,
    ),

    custom_type_constructor_declaration: $ => seq(
      $.custom_type_constructor,
      $.is,
      $._bracketL,
      sep1($._comma, $.custom_type_constructor_applied_concept),
      $._bracketR,
    ),

    custom_type_constructor_applied_concept: $ => choice(
      $.custom_type_trivial_value_expression,
      $.call_expression,
    ),

    custom_type_constructor: $ => choice(
      field("name", $.custom_type_constructor_name),
      seq(
        field("name", $.custom_type_constructor_name),
        repeat1(
          choice(
            $.uppercase_identifier,
            $.type_variable,
            $.record_type_expression,
            seq($._parenL, repeat1($.custom_type_expression), $._parenR),
          ),
        ),
      ),
    ),

    custom_type_expression: $ => prec.right(
      seq(
        field("name", $.uppercase_identifier),
        repeat(
          choice(
            $.uppercase_identifier,
            $.type_variable,
            $.record_type_expression,
            seq($._parenL, repeat1($.custom_type_expression), $.parenR),
          ),
        ),
      ),
    ),

    custom_type_trivial_value_expression: $ => prec(
      1,
      alias(
        $.uppercase_identifier,
        "custom_type_trivial_value_expression",
      ),
    ),

    record_declaration: $ => seq(
      $.record,
      field("name", $.uppercase_identifier),
      $.eq,
      $.record_type_expression,
    ),

    record_type_expression: $ => seq(
      $._curlyL,
      sep1($._comma, $.record_type_entry),
      $._curlyR,
    ),

    record_type_entry: $ => seq(
      // TODO: Do we really want complex record keys?
      // choice($.simple_record_key, $.complex_record_key),
      $.simple_record_key,
      $.colon,
      $.custom_type_constructor,
    ),

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

    qualified_access_expression: $ => seq(
      field("target", $._field_access_target),
      // repeat1($._field_access_segment),
      // TODO: Do we actually want to enable "train wreck" a.b.c.d.e accessors?
      $._field_access_segment,
    ),

    _field_access_target: $ => $.identifier,

    _field_access_segment: $ => seq(
      alias($._dot_without_leading_whitespace, $.dot),
      field(
        "segment",
        alias($._identifier_without_leading_whitespace, $.identifier),
      ),
    ),

    type_concept_declaration: $ => seq(
      $.type,
      optional($.constructor),
      $.concept,
      $.type_concept_name,
      repeat($.type_variable),
      $.eq,
      $.implicit_block_open,
      $.type_concept_requirements,
      $.type_concept_implementation,
      $.implicit_block_close,
    ),

    type_concept_requirements: $ => seq(
      repeat1($.ignored_type_annotation),
    ),

    type_concept_implementation: $ => seq(
      $.exposing,
      repeat1(
        choice(
          $.function_declaration,
          $.binary_operator_declaration,
        ),
      ),
    ),

    binary_operator_declaration: $ => seq(
      optional($.ignored_type_annotation),
      $.operator,
      field("name", seq($._parenL, $.mathy_operator, $._parenR)),
      repeat1($.function_parameter),
      $.eq, // TODO: Do we actually want the "=" for function declarations?
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    type_concept_instance_declaration: $ => seq(
      $.type,
      $.concept,
      $.instance,
      $.type_concept_name,
      field("type", repeat1($.custom_type_constructor_name)),
      $.eq,
      $.implicit_block_open,
      $.type_concept_instance_implementation,
      $.implicit_block_close,
    ),

    type_concept_instance_implementation: $ => repeat1(
      choice(
        $.function_declaration,
        $.let_expression,
      ),
    ),

    //
    // Strings
    //

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

    //
    // Terminals
    //

    app: $ => token(prec(1, "app")),
    with: $ => token(prec(1, "with")),
    module: $ => token(prec(1, "module")),
    as: $ => token(prec(1, "as")),
    exposing: $ => token(prec(1, "exposing")),
    import: $ => token(prec(1, "import")),
    function: $ => token(prec(1, "function")),
    type: $ => token(prec(1, "type")),
    record: $ => token(prec(1, "record")),
    let: $ => token(prec(1, "let")),
    when: $ => token(prec(1, "when")),
    is: $ => token(prec(1, "is")),
    where: $ => token(prec(1, "where")),
    expect: $ => token(prec(1, "expect")),
    core: $ => "core",
    experimental: $ => "experimental",
    concept: $ => token(prec(1, "concept")),
    constructor: $ => token(prec(1, "constructor")),
    instance: $ => token(prec(1, "instance")),
    contract: $ => token(prec(1, "contract")),
    operator: $ => token(prec(1, "operator")),
    dot: $ => token(prec(1, ".")),
    dotdot: $ => token(prec(1, "..")),
    dotdotdot: $ => token(prec(1, "...")),
    eq: $ => token(prec(1, "=")),
    eqeq: $ => token(prec(1, "==")),
    _pipe: $ => token(prec(1, "|")),
    arrow: $ => token(prec(1, "->")),
    parenL: $ => alias($._parenL, "parenL"),
    _parenL: $ => token(prec(1, "(")),
    parenR: $ => alias($._parenR, "parenR"),
    _parenR: $ => token(prec(1, ")")),
    _curlyL: $ => token(prec(1, "{")),
    _curlyR: $ => "}",
    _bracketL: $ => token(prec(1, "[")),
    _bracketR: $ => token(prec(1, "]")),
    pathSep: $ => "/",
    versionAt: $ => "@",
    colon: $ => token(prec(1, ":")),
    _comma: $ => token(prec(0, ",")),

    pipe_operator: $ => token(prec(1, "|>")),
    mathy_operator: $ => token(prec(1, /[@!?&|=+\-*\/%;.><]+/)),

    module_name_path_fragment: $ => token(prec(0, /[a-z][a-z0-9]*/)),

    // FIXME: Had to declare precedence to disambiguate, probably because of the
    //        regex match being exactly the same and the parser not being able
    //        to choose although it should be able to do so in this context...
    // function x =
    //   { { x, y, z } -> x }
    //        ^-- (function_parameter identifier) X (simple_record_key identifier)
    simple_record_key: $ => prec(1, alias($.identifier, "simple_record_key")),
    // simple_record_key: $ => /[_a-z][_a-zA-Z0-9]*/,
    // complex_record_key: $ => token(prec(0, /"[^"]+"/)),

    int_literal: $ => token(prec(0, /0|-?[1-9][_\d]*/)),

    decimal_literal: $ => token(prec(0, /-?[_\d]+\.[_\d]+/)),

    // FIXME: We want "simple" utf-8 in the end so this string escape needs to be adjusted, Elm supports something different
    // See https://github.com/elm-tooling/tree-sitter-elm/blob/main/grammar.js#L699
    string_escape: $ => token(prec(0, /\\(u\{[0-9A-Fa-f]{4,6}\}|[nrt\"'\\])/)),
    invalid_string_escape: $ => token(prec(0, /\\(u\{[^}]*\}|[^nrt\"'\\])/)),

    // FIXME: All the rest args and splats only support simple identifiers right now!
    rest_args: $ => seq($.dotdotdot, $.rest_args_identifier),
    rest_args_identifier: $ => token.immediate(/[_a-z][_a-zA-Z0-9]*/),

    sequence_expression_splat: $ => seq($.dotdotdot, $.sequence_expression_splat_identifier),
    sequence_expression_splat_identifier: $ => token.immediate(/[_a-z][_a-zA-Z0-9]*/),

    record_expression_splat: $ => seq($.dotdotdot, $.record_expression_splat_identifier),
    record_expression_splat_identifier: $ => token.immediate(/[_a-z][_a-zA-Z0-9]*/),

    // TODO: Clean up all the identifier mess including other terminal nodes
    // identifier_keyword_extraction: $ => /[_a-zA-Z]([a-zA-Z0-9]+)?/,
    identifier: $ => token(prec(0, /_[a-zA-Z0-9]([a-zA-Z0-9]+)?|[a-z]([a-zA-Z0-9]+)?/)),

    // token(prec(x, ...)) gives the token lexical precedence instead of parse precedence
    uppercase_identifier: $ => token(prec(1, /[A-Z][a-zA-Z0-9]*/)),
    custom_type_constructor_name: $ => token(prec(2, /[A-Z][a-zA-Z0-9]*/)),
    type_concept_name: $ => token(prec(3, /[A-Z][a-zA-Z0-9]*/)),

    lowercase_identifier: $ => token(prec(1, /[a-z][a-zA-Z0-9]*/)),

    dont_care: $ => token(prec(0, "_")),

    _identifier_without_leading_whitespace: $ => token.immediate(/[_a-z][_a-zA-Z0-9]*/),
    _dot_without_leading_whitespace: $ => token.immediate("."),

    type_variable: $ => alias($.lowercase_identifier, "type_variable"),

    // TODO: We're keeping ourselves open to introduce explicit blocks, if we really need to
    _implicit_block_open: $ => alias($.implicit_block_open, "_implicit_block_open"),
    _implicit_empty_block: $ => alias($.implicit_empty_block, "_implicit_empty_block"),
    _implicit_block_close: $ => alias($.implicit_block_close, "_implicit_block_close"),
    _terminator: $ => alias($.terminator, "_terminator"),
  }
});

function sep1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}
