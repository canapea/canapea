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

  // word: $ => $.identifier, //_keyword_extraction,

  rules: {
    source_file: $ => seq(
      optional($.toplevel_docs),
      choice(
        seq(
          $.development_module_declaration,
          optional($._development_toplevel_declarations),
        ),
        seq(
          choice(
            $.application_declaration,
            $.module_declaration,
          ),
          optional($._toplevel_declarations),
        ),
      ),
    ),

    comment: $ => token(seq('#', repeat(/[^\n]/))),

    toplevel_docs: $ => $.multiline_string_literal,

    // TODO: Actually implement type annotations
    type_annotation: $ => seq(
      $.let,
      field("name", $.identifier),
      token(prec(1, seq(":", /[^\n]*/))),
    ),

    // TODO: Actually implement type annotations
    operator_type_annotation: $ => seq(
      field("name",
        seq($.operator, $._parenL, $.maths_operator, $._parenR),
      ),
      token(prec(1, seq(":", /[^\n]*/))),
    ),

    application_declaration: $ => seq(
      $.application,
      optional($.application_imports),
      optional($.application_config_declaration),
    ),

    application_config_declaration: $ => seq(
      $.application,
      $.config,
      $.anonymous_function_expression,
    ),

    module_declaration: $ => seq(
      $.module,
      field("name", optional($.module_name_definition)),
      optional($.module_export_list),
      optional($.module_imports),
    ),

    development_module_declaration: $ => seq(
      $.module,
      field("name", seq(
        '"',
        field("core_namespace", choice($.canapea, $.experimental)),
        $.pathSep,
        sep1($.pathSep, $.module_name_path_fragment),
        '"',
      )),
      optional($.module_export_list),
      optional($.module_imports),
    ),

    module_export_list: $ => seq(
      $.exposing,
      $._pipe,
      choice(
        sep1($._pipe, $._module_export_type),
        sep1($._pipe, $.module_export_value),
        seq(
          sep1($._pipe, $._module_export_type),
          $._pipe,
          sep1($._pipe, $.module_export_value),
        ),
      ),
    ),

    _module_export_type: $ => choice(
      $.module_export_opaque_type,
      $.module_export_type_with_constructors,
    ),

    module_export_type_with_constructors: $ => seq(
      field("type", $.custom_type_constructor_name),
      seq($._parenL, $._dotdot, $._parenR),
    ),

    module_export_opaque_type: $ => seq(
      field("type", $.custom_type_constructor_name),
    ),

    module_export_value: $ => alias(
      $.identifier,
      "module_export_value",
    ),

    application_imports: $ => choice(
      seq(
        repeat1($.import_capability_clause),
        repeat($.import_clause),
      ),
      seq(
        repeat($.import_capability_clause),
        repeat1($.import_clause),
      ),
    ),

    import_capability_clause: $ => seq(
      $.import,
      $.capability,
      $.module_import_name,
      $.import_expose_list,
    ),

    module_imports: $ => repeat1($.import_clause),

    // There are no side-effect modules so import qualified
    // and/or import types from the module
    import_clause: $ => seq(
      $.import,
      $.module_import_name,
      choice(
        seq(
          $.as,
          field("qualified", $.named_module_import),
        ),
        seq(
          $.as,
          field("qualified", $.named_module_import),
          $.import_expose_list,
        ),
        $.import_expose_list,
      ),
    ),

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
        $._free_type_annotation,
        $.function_declaration,
        $.let_expression,
        $.toplevel_docs,
        $.custom_type_declaration,
        $.record_declaration,
        field("expect", $.test_expectation),
        field("assert", $.local_assertion),
        field("invariant", $.invariant_assertion),
      ),
    ),

    _free_type_annotation: $ => prec(
      -1,
      $.type_annotation,
    ),

    _development_toplevel_declarations: $ => repeat1(
      choice(
        prec.left(
          $._toplevel_declarations,
        ),
        field("concept", $.type_concept_declaration),
        field("constructor_concept", $.type_constructor_concept_declaration),
        field("concept_instance", $.type_concept_instance_declaration),
      ),
    ),

    local_assertion: $ => seq(
      $.assert,
      $.conditional_expression,
    ),

    invariant_assertion: $ => seq(
      $.assert,
      token.immediate("."),
      $.invariant,
      $.conditional_expression,
    ),

    unreachable_assertion: $ => seq(
      $.assert,
      token.immediate("."),
      $.unreachable,
    ),

    test_expectation: $ => seq(
      $.expect,
      $.conditional_expression,
    ),

    todo_expression: $ => seq(
      $.debug,
      choice(
        seq(
          token.immediate("."),
          $.todo,
          token.immediate(/\s+/),
          field("topic", $.string_literal),
        ),
        seq(
          token.immediate("."),
          $.todo,
          token.immediate(/\s+/),
          field("topic", $.dont_care),
        )
      ),
    ),

    function_declaration: $ => seq(
      optional($.type_annotation),
      $.let,
      field("name", $.identifier),
      repeat1($.function_parameter),
      $.eq,
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
            field("expect", $.test_expectation),
            field("assert", $.local_assertion),
            field("invariant", $.invariant_assertion),
            field("unreachable", $.unreachable_assertion),
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

    // TODO: Recursive sequence patterns?
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

    // FIXME: Custom Type patterns are weirdly parenthesized rn
    custom_type_pattern: $ => prec.left(
      1,
      choice(
        $.custom_type_trivial_value_expression,
        $._complex_custom_type_pattern,
        seq($._parenL, $._complex_custom_type_pattern, $._parenR),
      ),
    ),

    _complex_custom_type_pattern: $ => prec.left(
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
      $.binary_operator_expression,
      $.value_expression,
      $.record_expression,
      $.sequence_expression,
      $._literal_expression,
      $.custom_type_trivial_value_expression,
      field("todo", $.todo_expression),
      field("unreachable", $.unreachable_assertion),
    ),

    _literal_expression: $ => choice(
      $.string_literal,
      $.int_literal,
      $.decimal_literal,
      $.multiline_string_literal,
    ),

    value_expression: $ => choice(
      $.qualified_access_expression,
      $.identifier,
    ),

    // TODO: Custom Type pattern in let_expression
    let_expression: $ => seq(
      optional($.type_annotation),
      $.let,
      choice(
        $.record_pattern,
        $.sequence_pattern,
        field("name", $.identifier),
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
      $.maths_operator,
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

    custom_type_declaration: $ => seq(
      $.type,
      field("name", $.custom_type_constructor_name),
      repeat($.type_variable),
      $.eq,
      $._implicit_block_open,
      $._pipe,
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

    // FIXME: Applied concepts can't take generic call_expressions!
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
      $.type,
      $.record,
      field("name", $.uppercase_identifier),
      repeat($.type_variable),
      $.eq,
      $.record_type_expression,
    ),

    record_type_expression: $ => seq(
      $._curlyL,
      sep1($._comma, $.record_type_entry),
      $._curlyR,
    ),

    // FIXME: This record type entry is probably a $.custom_type_expression
    record_type_entry: $ => seq(
      // TODO: Do we really want complex record keys?
      // choice($.simple_record_key, $.complex_record_key),
      $.simple_record_key,
      $.colon,
      choice(
        $.type_variable,
        $.custom_type_constructor,
      ),
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
      '"',
    ),

    // FIXME: $._field_access_target should probably have a different name
    qualified_access_expression: $ => seq(
      field("target", $._field_access_target),
      // repeat1($._field_access_segment),
      // TODO: Do we actually want to enable "train wreck" a.b.c.d.e accessors?
      alias($._dot_without_leading_whitespace, $.dot),
      field(
        "segment",
        alias($._identifier_without_leading_whitespace, $.identifier),
      ),
    ),

    _field_access_target: $ => $.identifier,

    type_concept_declaration: $ => seq(
      $.type,
      $.concept,
      $.type_concept_name,
      repeat1($.type_variable),
      $.eq,
      $.implicit_block_open,
      $.type_concept_requirements,
      $.type_concept_implementation,
      $.implicit_block_close,
    ),

    type_constructor_concept_declaration: $ => seq(
      $.type,
      $.constructor,
      $.concept,
      $.type_concept_name,
      repeat(choice(
        $.type_variable,
        $.custom_type_constructor_name,
      )),
      $.eq,
      $.implicit_block_open,
      $.type_concept_requirements,
      optional($.type_constructor_concept_implementation),
      $.implicit_block_close,
    ),

    type_concept_requirements: $ => choice(
      $._type_concept_required_constraints,
      seq(
        optional($._type_concept_required_constraints),
        repeat1($.type_concept_required_declaration),
      ),
    ),

    _type_concept_required_constraints: $ => seq(
      $.where,
      $._bracketL,
      sep1($._comma, $.type_concept_constraint),
      $._bracketR,
    ),

    type_concept_constraint: $ => seq(
      $.type_concept_name,
      repeat(
        choice(
          $.type_variable,
          $.custom_type_trivial_value_expression,
          $.custom_type_expression,
        ),
      ),
    ),

    type_concept_required_declaration: $ => choice(
      $.type_annotation,
    ),

    type_concept_implementation: $ => seq(
      $.exposing,
      repeat1(
        choice(
          $.function_declaration,
          $.let_expression,
          $.binary_operator_declaration,
        ),
      ),
    ),

    type_constructor_concept_implementation: $ => seq(
      $.exposing,
      repeat1(
        choice(
          $.function_declaration,
          $.let_expression,
        ),
      ),
    ),

    binary_operator_declaration: $ => seq(
      optional($.operator_type_annotation),
      $.operator,
      field("name", seq($._parenL, $.maths_operator, $._parenR)),
      repeat1($.function_parameter),
      $.eq,
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    binary_operator_expression: $ => prec.left(
      seq(
        $._call_or_atom,
        choice(
          $.pipe_operator,
          $.maths_operator,
        ),
        $._call_or_atom,
      ),
    ),

    // TODO: Do we actually need multiple instance types for type concept instances?
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

    // FIXME: Extract """language marker for multiline strings in parser
    multiline_string_literal: $ => seq(
      alias('"""', $.open_quote),
      optional(field("language_id", token.immediate(/[^\t\s\n\r]+/))),
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

    application: $ => "application",
    config: $ => "config",
    module: $ => "module",
    as: $ => "as",
    exposing: $ => "exposing",
    import: $ => "import",
    type: $ => "type",
    record: $ => "record",
    let: $ => "let",
    when: $ => "when",
    is: $ => "is",
    where: $ => "where",
    assert: $ => "assert",
    debug: $ => "debug",
    expect: $ => "expect",
    todo: $ => token.immediate("todo"),
    invariant: $ => token.immediate("invariant"),
    unreachable: $ => token.immediate("unreachable"),
    canapea: $ => "canapea",
    experimental: $ => "experimental",
    concept: $ => "concept",
    constructor: $ => "constructor",
    instance: $ => "instance",
    contract: $ => "contract",
    operator: $ => "operator",
    capability: $ => "capability",
    dot: $ => ".",
    _dotdot: $ => "..",
    dotdotdot: $ => "...",
    eq: $ => "=",
    _pipe: $ => "|",
    arrow: $ => "->",
    parenL: $ => alias($._parenL, "parenL"),
    _parenL: $ => "(",
    parenR: $ => alias($._parenR, "parenR"),
    _parenR: $ => ")",
    _curlyL: $ => "{",
    _curlyR: $ => "}",
    _bracketL: $ => "[",
    _bracketR: $ => "]",
    pathSep: $ => "/",
    colon: $ => ":",
    _comma: $ => ",",

    pipe_operator: $ => "|>",
    maths_operator: $ => /[@!?&+\-*\/%;.><]|[@!?&|=+\-*\/%;.><]+/,

    module_name_path_fragment: $ => /[a-z][a-z0-9]*/,

    // FIXME: Had to declare precedence to disambiguate, probably because of the
    //        regex match being exactly the same and the parser not being able
    //        to choose although it should be able to do so in this context...
    simple_record_key: $ => prec(1, alias($.identifier, "simple_record_key")),
    // simple_record_key: $ => /[_a-z][_a-zA-Z0-9]*/,
    // complex_record_key: $ => token(prec(0, /"[^"]+"/)),

    int_literal: $ => /0|-?[1-9][_\d]*/,

    decimal_literal: $ => /-?[_\d]+\.[_\d]+/,

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

    // TODO: Clean up all the identifier mess including other terminal nodes
    // identifier_keyword_extraction: $ => /[_a-zA-Z]([a-zA-Z0-9]+)?/,
    identifier: $ => /_[a-zA-Z0-9]([a-zA-Z0-9]+)?|[a-z]([a-zA-Z0-9]+)?/,

    // token(prec(x, ...)) gives the token lexical precedence instead of parse precedence
    uppercase_identifier: $ => /[A-Z][a-zA-Z0-9]*/,
    custom_type_constructor_name: $ => token(prec(1, /[A-Z][a-zA-Z0-9]*/)),
    type_concept_name: $ => /[A-Z][a-zA-Z0-9]*/,
    capability_name: $ => alias($.custom_type_constructor_name, "capability_name"),

    named_module_import: $ => /[a-z][a-zA-Z0-9]*/,

    dont_care: $ => "_",

    _identifier_without_leading_whitespace: $ => token.immediate(/[_a-z][_a-zA-Z0-9]*/),
    _dot_without_leading_whitespace: $ => token.immediate("."),

    type_variable: $ => /[a-z][a-zA-Z0-9]*/,

    // TODO: We're keeping ourselves open to introduce explicit blocks, if we really need to
    _implicit_block_open: $ => alias($.implicit_block_open, "_implicit_block_open"),
    // _implicit_empty_block: $ => alias($.implicit_empty_block, "_implicit_empty_block"),
    _implicit_block_close: $ => alias($.implicit_block_close, "_implicit_block_close"),
    // _terminator: $ => alias($.terminator, "_terminator"),
  }
});

function sep1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}
