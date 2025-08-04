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
    // FIXME: The indentation problem with qualified function calls is probably
    //        due to the manual scanner always inserting an implicit_block_open
    //        after the token just before the `.` and error correction does
    //        the rest and corrupts the parser state even more
    $.implicit_block_open,
    $.implicit_block_close,
    $.is_in_error_recovery, // Unused in grammar, just convenience for scanner
  ],

  // word: $ => $.identifier, //_keyword_extraction,

  rules: {
    source_file: $ => choice(
      $.application_declaration,
      $.module_declaration,
      $.experimental_module_declaration,
      seq(
        // TODO: Remove the ability to have an application and kernel modules in one file?
        optional($.application_declaration),
        repeat1(
          // TODO: Remove the ability to have multiple kernel modules in one file?
          // Source files can have multiple kernel modules
          // just for convenience right now
          $.kernel_module_expression,
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
        seq(
          $.operator,
          "(",
          choice(
            // TODO: Do we actually need more operators?
            $.boolean_operator,
            $.maths_operator,
          ),
          ")",
        ),
      ),
      token(prec(1, seq(":", /[^\n]*/))),
    ),

    application_declaration: $ => prec.left(
      seq(
        alias($.application_signature, $.module_signature),
        optional($._application_toplevel_declarations),
      ),
    ),

    application_signature: $ => prec.right(
      seq(
        optional($.toplevel_docs),
        $.application,
        optional($.application_imports),
        optional($.application_config_declaration),
      ),
    ),

    application_config_declaration: $ => seq(
      optional($.toplevel_docs),
      $.application,
      $.config,
      choice(
        $.anonymous_function_expression,
        $.application_config_record_expression,
      ),
    ),

    application_config_record_expression: $ => choice(
      field("empty", seq("{", "}")),
      seq(
        "{",
        sep1(",", $.record_expression_entry),
        "}",
      ),
    ),

    module_declaration: $ => seq(
      $.module_signature,
      optional($._toplevel_declarations),
    ),

    module_signature: $ => seq(
      optional($.toplevel_docs),
      $.module,
      field("name", optional($.module_name_definition)),
      optional($.module_export_list),
      optional($.module_imports),
    ),

    // Module name definitions are very simple file paths
    module_name_definition: $ => seq(
      '"',
      sep1("/", $.module_name_path_fragment),
      '"',
    ),

    kernel_module_expression: $ => prec.right(
      seq(
        alias($.kernel_module_signature, $.module_signature),
        optional($._kernel_toplevel_declarations),
      ),
    ),

    kernel_module_name_definition: $ => seq(
      '"',
      field("privileged_namespace", $.canapea),
      "/",
      sep1("/", $.module_name_path_fragment),
      '"',
    ),

    kernel_module_signature: $ => prec.right(
      seq(
        optional($.toplevel_docs),
        $.module,
        field("name",
          alias($.kernel_module_name_definition, $.module_name_definition),
        ),
        optional($.module_export_list),
        optional($.module_imports),
        optional($.module_build_declaration),
      ),
    ),

    module_build_declaration: $ => seq(
      $.module,
      $.build,
      $.anonymous_function_expression,
    ),

    // Experimental modules are just kernel modules with a
    // different namespace right now
    experimental_module_declaration: $ => prec.right(
      seq(
        alias($.experimental_module_signature, $.module_signature),
        optional($._kernel_toplevel_declarations),
      ),
    ),

    experimental_module_name_definition: $ => seq(
      '"',
      field("privileged_namespace", $.experimental),
      "/",
      sep1("/", $.module_name_path_fragment),
      '"',
    ),

    experimental_module_signature: $ => prec.right(
      seq(
        optional($.toplevel_docs),
        $.module,
        field("name",
          alias($.experimental_module_name_definition, $.module_name_definition),
        ),
        optional($.module_export_list),
        optional($.module_imports),
        optional($.module_build_declaration),
      ),
    ),

    module_export_list: $ => seq(
      $.exposing,
      "|",
      choice(
        sep1("|", $._module_export_type),
        sep1("|", $.module_export_value),
        seq(
          sep1("|", $._module_export_type),
          "|",
          sep1("|", $.module_export_value),
        ),
      ),
    ),

    _module_export_type: $ => choice(
      $.module_export_opaque_type,
      $.module_export_type_with_constructors,
      $.module_export_capability,
    ),

    module_export_type_with_constructors: $ => seq(
      field("type", $.custom_type_name),
      token("(..)"),
    ),

    module_export_opaque_type: $ => seq(
      field("type", $.custom_type_name),
    ),

    module_export_capability: $ => seq(
      field("capability", $.capability_name),
    ),

    // FIXME: Remove this module_export_value alias?
    module_export_value: $ => alias($.identifier, "module_export_value"),

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
      $.import_capability_expose_list,
    ),

    import_capability_expose_list: $ => seq(
      $.exposing,
      $.implicit_block_open,
      "|",
      sep1("|", $.import_expose_capability),
      $.implicit_block_close,
    ),

    import_expose_capability: $ => seq(
      field("capability", $.capability_name),
    ),

    module_imports: $ => choice(
      seq(
        repeat1($.import_capability_clause),
        repeat($.import_clause),
      ),
      seq(
        repeat($.import_capability_clause),
        repeat1($.import_clause),
      ),
    ),

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
      "|",
      sep1("|", $.import_expose_type),
      $.implicit_block_close,
    ),

    import_expose_type: $ => seq(
      choice(
        field("type", $.custom_type_name),
        seq(
          field("type", $.custom_type_name),
          $.as,
          field("exposed_as", $.custom_type_name),
        ),
      ),
      optional(
        seq(
          "(",
          sep1(",", $.import_expose_type_constructor),
          ")",
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

    // Application custom type declarations can be augmented
    // with capabilities
    _application_toplevel_declarations: $ => repeat1(
      choice(
        $._free_type_annotation,
        $.function_declaration,
        $.let_declaration,
        $.toplevel_docs,
        alias($.augmented_custom_type_declaration, $.custom_type_declaration),
        $.record_declaration,
        field("expect", $.test_expectation),
        field("livedoc", $.livedoc_expression),
      ),
    ),

    _toplevel_declarations: $ => repeat1(
      choice(
        $._free_type_annotation,
        $.function_declaration,
        $.let_declaration,
        $.toplevel_docs,
        $.custom_type_declaration,
        $.record_declaration,
        field("expect", $.test_expectation),
        field("livedoc", $.livedoc_expression),
        // field("assert", $.local_assertion),
        // field("invariant", $.invariant_assertion),
      ),
    ),

    _kernel_toplevel_declarations: $ => prec.right(
      repeat1(
        choice(
          prec.left($._toplevel_declarations),
          field("concept", $.type_concept_declaration),
          field("constructor_concept", $.type_constructor_concept_declaration),
          field("concept_instance", $.type_concept_instance_declaration),
        ),
      ),
    ),

    _free_type_annotation: $ => prec.left(
      -1,
      $.type_annotation,
    ),

    // local_assertion: $ => seq(
    //   $.assert,
    //   $.conditional_expression,
    // ),

    // invariant_assertion: $ => seq(
    //   $.assert,
    //   token.immediate("."),
    //   $.invariant,
    //   $.conditional_expression,
    // ),

    // unreachable_assertion: $ => seq(
    //   $.assert,
    //   token.immediate("."),
    //   $.unreachable,
    // ),

    record_pattern: $ => prec(
      5,
      seq(
        "{",
        sep1(",", $.simple_record_key),
        "}",
      ),
    ),

    // TODO: Recursive sequence patterns?
    sequence_pattern: $ => prec.right(
      5,
      seq(
        "[",
        sep1(
          ",",
          choice(
            $.dont_care,
            $._literal_expression,
            $.record_pattern,
            $.custom_type_pattern,
            $.identifier,
          ),
        ),
        optional(seq(",", $.rest_args)),
        "]",
      ),
    ),

    custom_type_pattern: $ => prec.left(
      5,
      seq(
        $.custom_type_constructor_name,
        repeat(
          prec(2,
            choice(
              $.custom_type_constructor_name,
              $.sequence_pattern,
              $.record_pattern,
              prec(2, $.identifier),
              // $.custom_type_pattern,
              $.dont_care,
              seq("(", $.custom_type_pattern, ")"),
            ),
          ),
        ),
      ),
    ),

    test_expectation: $ => prec.right(
      2,
      seq(
        $.expect,
        $.conditional_expression,
      ),
    ),

    todo_expression: $ => seq(
      $.debug_todo,
      token.immediate(/\s+/),
      field("topic",
        choice(
          $.string_literal,
          $.dont_care,
        ),
      ),
    ),

    livedoc_expression: $ => choice(
      $._livedoc_active_expression,
      $._livedoc_passive_expression,
    ),

    _livedoc_active_expression: $ => seq(
      field("category", $.debug),
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    _livedoc_passive_expression: $ => seq(
      field("category", choice(
        // TODO: Do we actually want other livedoc categories than `stash`?
        // $.debug_example,
        // $.debug_reminder,
        // $.debug_sketch,
        $.debug_stash,
      )),
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    function_declaration: $ => seq(
      optional($.type_annotation),
      $.let,
      field("name", $.identifier),
      repeat1(prec(1, $.function_parameter)),
      $.eq,
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    function_parameter: $ => choice(
      $.dont_care,
      $.record_pattern,
      $.sequence_pattern,
      seq("(", $.custom_type_pattern, ")"),
      field("name", prec(2, $.identifier)),
    ),

    // A couple of local bindings
    _block_body: $ => choice(
      seq(
        repeat1(
          choice(
            field("binding", $.let_expression),
            field("expect", $.test_expectation),
            field("livedoc", $.livedoc_expression),
            // field("assert", $.local_assertion),
            // field("invariant", $.invariant_assertion),
            // field("unreachable", $.unreachable_assertion),
          ),
        ),
        field("return", $._value_or_atom),
      ),
      field("single_return", $._value_or_atom),
    ),

    _value_or_atom: $ => prec.left(
      choice(
        $.metadata_access_expression,
        $._value_expression_in_parens,
        $.value_expression,
        $._atom,
      ),
    ),

    _value_expression_in_parens: $ => seq(
      "(",
      $.value_expression,
      ")",
    ),

    _call_or_ref_expression: $ => seq(
      choice(
        $.call_expression,
        $.qualified_function_ref_expression,
      ),
    ),

    _atom: $ => choice(
      $._atom_in_parens,
      $._atom_not_in_parens
    ),

    // TODO: Do we actually need the parens in the AST? Might be useful for editors
    _atom_in_parens: $ => seq(
      "(",
      $._atom_not_in_parens,
      ")",
    ),

    _atom_not_in_parens: $ => prec.left(
      choice(
        $.when_expression,
        $.binary_operator_expression,
        $.binary_pipe_expression,
        $.conditional_expression,
        $.record_expression,
        $.sequence_expression,
        $.custom_type_value_expression,
        $._call_or_ref_expression,
        $.anonymous_function_expression,
        field("todo", $.todo_expression),
        field("livedoc", $.livedoc_expression),
        field("expect", $.test_expectation),
        // field("unreachable", $.unreachable_assertion),
      ),
    ),

    // Disallow anonymous functions as entries, we can't
    // track indirect usage inside the parser but
    // preventing this should be worth it
    _record_entry_value_or_atom: $ => choice(
      $.value_expression,
      $.metadata_access_expression,
      $.when_expression,
      $.binary_operator_expression,
      $.binary_pipe_expression,
      $.record_expression,
      $.sequence_expression,
      $.custom_type_value_expression,
      $.call_expression,
    ),

    _literal_expression: $ => choice(
      $.string_literal,
      $.int_literal,
      $.decimal_literal,
      $.multiline_string_literal,
      $._custom_literal,
    ),

    value_expression: $ => prec(
      1,
      choice(
        $.qualified_access_expression,
        $.identifier,
        $._literal_expression,
      ),
    ),

    // TODO: let_declaration doesn't support patterns, do we need that?
    let_declaration: $ => seq(
      optional($.type_annotation),
      $.let,
      field("name", $.identifier),
      $.eq,
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    let_expression: $ => seq(
      optional($.type_annotation),
      $.let,
      field("pattern", choice(
        $.record_pattern,
        $.sequence_pattern,
        seq("(", $.custom_type_pattern, ")"),
        field("name", $.identifier),
        $.dont_care,
      )),
      $.eq,
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    anonymous_function_expression: $ => seq(
      "{",
      choice(
        seq(
          repeat1($.function_parameter),
          $.arrow,
          $._block_body,
        ),
        $._block_body,
      ),
      "}",
    ),

    conditional_expression: $ => prec.left(
      seq(
        field("left", $._value_or_atom),
        field("op", $.boolean_operator),
        field("right", $._value_or_atom),
      ),
    ),

    qualified_function_ref_expression: $ => prec.left(
      seq(
        field("qualified", $.identifier),
        alias($._dot_without_leading_whitespace, $.dot),
        field("target",
          alias($._identifier_without_leading_whitespace, $.identifier),
        ),
      ),
    ),

    application_metadata_access_expression: $ => seq(
      field("context", $.application),
      repeat1(
        seq(
          alias($._dot_without_leading_whitespace, $.dot),
          field("target",
            alias($._identifier_without_leading_whitespace, $.identifier),
          ),
        ),
      ),
    ),

    module_metadata_access_expression: $ => seq(
      field("context", $.module),
      repeat1(
        seq(
          alias($._dot_without_leading_whitespace, $.dot),
          field("target",
            alias($._identifier_without_leading_whitespace, $.identifier),
          ),
        ),
      ),
    ),

    metadata_access_expression: $ => choice(
      $._application_metadata_access_expression,
      $._module_metadata_access_expression,
    ),

    _application_metadata_access_expression: $ => alias(
      $.application_metadata_access_expression,
      "_application_metadata_access_expression",
    ),
    _module_metadata_access_expression: $ => alias(
      $.module_metadata_access_expression,
      "_module_metadata_access_expression",
    ),

    call_expression: $ => prec.left(
      seq(
        choice(
          field("immediate_target", $.identifier),
          seq(
            field("qualified", $.identifier),
            alias($._dot_without_leading_whitespace, $.dot),
            field("target",
              alias($._identifier_without_leading_whitespace, $.identifier),
            ),
          ),
        ),
        repeat1(field("parameter", $.call_parameter)),
      ),
    ),

    call_parameter: $ => prec.left(
      choice(
        $.dont_care,
        $._value_or_atom,
      ),
    ),

    // TODO: Do we actually want to enable "train wreck" a.b.c.d.e accessors?
    qualified_access_expression: $ => prec.right(
      seq(
        field("target", $.field_access_target),
        repeat1(
          seq(
            choice(
              alias($._dot_without_leading_whitespace, $.dot),
              $.dot,
            ),
            // $.dot,
            field("segment", $.field_access_segment),
          ),
        ),
      ),
    ),

    // Record splats are only allowed as the first entry
    record_expression: $ => choice(
      field("empty", seq("{", "}")), // empty records
      seq(
        "{",
        optional(seq(
          $.record_expression_splat,
          ",",
        )),
        sep1(",", $.record_expression_entry),
        "}",
      ),
    ),

    record_expression_entry: $ => seq(
      field("key", $.simple_record_key),
      $.eq,
      field("value", $._record_entry_value_or_atom),
    ),

    sequence_expression: $ => seq(
      "[",
      sep1(",", $.sequence_expression_entry),
      "]",
    ),

    sequence_expression_entry: $ => choice(
      $._value_or_atom,
      $.sequence_expression_splat,
    ),

    when_expression: $ => seq(
      $.when,
      field("subject", $._value_or_atom),
      $.is,
      repeat1($.when_branch),
      choice(
        $.when_branch,
        $.when_branch_catchall,
      ),
    ),

    when_branch: $ => seq(
      "|",
      $.when_branch_pattern,
      optional(seq(
        $.where,
        $.when_branch_pattern_guard,
      )),
      $.arrow,
      $.when_branch_consequence,
    ),

    when_branch_catchall: $ => seq(
      "|",
      $.else,
      choice(
        seq(
          $.identifier,
          $.arrow,
          $.when_branch_consequence,
        ),
        seq(
          $.arrow,
          $.when_branch_consequence,
        ),
      ),
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
      $._value_or_atom,
      $.implicit_block_close,
    ),

    capability_value_expression: $ => prec.left(
      choice(
        field("capability", $.capability_name),
        seq(
          field("capability", $.capability_name),
          repeat1(prec(1,
            choice(
              $.call_parameter,
              $.application_metadata_access_expression,
            ),
          )),
        ),
      ),
    ),

    custom_type_value_expression: $ => prec.left(
      choice(
        field("constructor", $.custom_type_constructor_name),
        seq(
          field("constructor", $.custom_type_constructor_name),
          repeat1($.call_parameter),
        ),
      ),
    ),

    custom_type_declaration: $ => seq(
      $.type,
      field("name", $.custom_type_name),
      repeat($.type_variable),
      $.eq,
      $._implicit_block_open,
      "|",
      sep1(
        "|",
        choice(
          $.custom_type_constructor_declaration,
          $.custom_type_constructor,
        ),
      ),
      $._implicit_block_close,
    ),

    augmented_custom_type_declaration: $ => seq(
      $.type,
      field("name", $.custom_type_name),
      repeat($.type_variable),
      $.eq,
      $._implicit_block_open,
      "|",
      sep1(
        "|",
        choice(
          alias(
            $.augmented_custom_type_constructor_declaration,
            $.custom_type_constructor_declaration,
          ),
          $.custom_type_constructor,
        ),
      ),
      $._implicit_block_close,
    ),

    custom_type_constructor_declaration: $ => seq(
      $.custom_type_constructor,
      $.is,
      "[",
      sep1(",", $.custom_type_value_expression),
      "]",
    ),

    augmented_custom_type_constructor_declaration: $ => seq(
      $.custom_type_constructor,
      $.is,
      "[",
      sep1(",", $.custom_type_constructor_applied_concept),
      "]",
    ),

    custom_type_constructor_applied_concept: $ => choice(
      $.custom_type_value_expression,
      $.capability_value_expression,
    ),

    custom_type_constructor: $ => choice(
      field("name", $.custom_type_constructor_name),
      seq(
        field("name", $.custom_type_constructor_name),
        repeat1(
          choice(
            $.custom_type_constructor_name,
            $.type_variable,
            $.record_type_expression,
            seq("(", repeat1($.custom_type_expression), ")"),
          ),
        ),
      ),
    ),

    custom_type_expression: $ => prec.left(
      seq(
        field("name", $.custom_type_name),
        repeat(
          choice(
            $.custom_type_name,
            $.type_variable,
            $.record_type_expression,
            seq("(", repeat1($.custom_type_expression), ")"),
          ),
        ),
      ),
    ),

    record_declaration: $ => seq(
      $.type,
      $.record,
      field("name", $.record_name),
      repeat($.type_variable),
      $.eq,
      $.record_type_expression,
    ),

    record_type_expression: $ => seq(
      "{",
      sep1(",", $.record_type_entry),
      "}",
    ),

    record_type_entry: $ => seq(
      // TODO: Do we really want complex record keys? Could be useful for deserialization
      // choice($.simple_record_key, $.complex_record_key),
      $.simple_record_key,
      $.colon,
      choice(
        $.type_variable,
        $.custom_type_expression,
      ),
    ),

    // Module imports can contain version information so
    module_import_name: $ => seq(
      '"',
      sep1("/", $.module_name_path_fragment),
      '"',
    ),

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
      choice(
        $.type_concept_name,
        $.capability_name,
      ),
      repeat(choice(
        $.type_variable,
        $.custom_type_expression,
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
      "[",
      sep1(",", $.type_concept_constraint),
      "]",
    ),

    type_concept_constraint: $ => seq(
      $.type_concept_name,
      repeat(
        choice(
          $.type_variable,
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
      field("name", seq(
        "(",
        choice(
          $.boolean_operator,
          $.maths_operator,
        ),
        ")",
      )),
      repeat1($.function_parameter),
      $.eq,
      $.implicit_block_open,
      $._block_body,
      $.implicit_block_close,
    ),

    // TODO: Bake binary operator precedence into the parser?
    binary_operator_expression: $ => prec.left(
      2,
      choice(
        seq(
          $._value_or_atom,
          $.maths_operator,
          $._value_or_atom,
        ),
      ),
    ),

    binary_pipe_expression: $ => prec.left(
      -1,
      seq(
        $._value_or_atom,
        $.pipe_operator,
        $._value_or_atom,
      ),
    ),

    type_concept_instance_declaration: $ => seq(
      $.type,
      $.concept,
      $.instance,
      $.type_concept_name,
      field("type", repeat1($.custom_type_expression)),
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

    // FIXME: This needs to be moved into an ADR reg. https://github.com/canapea/canapea/issues/85
    // These are under discussion to not be part of the core language
    // but may be pulled in via an external library. The syntax is designed
    // to stand out visually and be very regular so it's clear that they are
    // handled a bit different than the built-in basic types. Maybe we actually want
    // these to be "untyped" until use like Odin does it?
    // FIXME: Proper UTF8 Grapheme based String?
    _custom_literal: $ => choice(
      $.binary_float_iso754_literal,
      $.date_iso8601_literal,
      $.instant_iso8601_literal,
      $.semantic_version_literal,
      $.hex_literal,
      $.octal_literal
    ),

    octal_literal: $ => seq(
      field("literal_type", token(prec(1, "Octal"))),
      token.immediate("|"),
      field("value", token.immediate(/[0-7]+/)),
    ),

    hex_literal: $ => seq(
      field("literal_type", token(prec(1, "Hex"))),
      token.immediate("|"),
      field("value", token.immediate(/[\da-fA-F_]+/)),
    ),

    // Official JavaScript RegExp see https://semver.org
    // ^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$
    // =
    // ^
    //   (0|[1-9]\d*) - major
    // \.(0|[1-9]\d*) - minor
    // \.(0|[1-9]\d*) - patch
    // (?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))? - prerelease
    // (?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))? - build
    // $
    semantic_version_literal: $ => seq(
      field("literal_type", token(prec(1, "V"))),
      token.immediate("|"),
      field("major", token.immediate(/0|[1-9]\d*/)),
      token.immediate("."),
      field("minor", token.immediate(/0|[1-9]\d*/)),
      token.immediate("."),
      field("patch", token.immediate(/0|[1-9]\d*/)),
      optional(seq(
        token.immediate("-"),
        field("prerelease",
          token.immediate(/((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)/),
        ),
      )),
      optional(seq(
        token.immediate("+"),
        field("build",
          token.immediate(/(?:([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))/),
        ),
      )),
    ),

    // FIXME: We could actually enforce proper days per month on the parser level
    date_iso8601_literal: $ => seq(
      field("literal_type", token(prec(1, "Date"))),
      token.immediate("|"),
      field("year", token.immediate(/\d\d\d\d{1,}/)),
      token.immediate("-"),
      field("month", token.immediate(/\d\d/)),
      token.immediate("-"),
      field("day", token.immediate(/\d\d/)),
    ),

    // FIXME: We could actually enforce proper days per month on the parser level
    instant_iso8601_literal: $ => seq(
      field("literal_type", token(prec(1, "Instant"))),
      token.immediate("|"),
      optional(field("sign", token.immediate("-"))),
      field("year", token.immediate(/\d\d\d\d{1,}/)),
      token.immediate("-"),
      field("month", token.immediate(/\d\d/)),
      token.immediate("-"),
      field("day", token.immediate(/\d\d/)),
      token.immediate("T"),
      field("hours", token.immediate(/\d\d/)),
      token.immediate(":"),
      field("minutes", token.immediate(/\d\d/)),
      optional(seq(
        token.immediate(":"),
        field("seconds", token.immediate(/\d\d/)),
        optional(seq(
          token.immediate("."),
          field("milliseconds", token.immediate(/\d+/)),
        )),
      )),
    ),

    // Binary floating point numbers are what most people will expect coming
    // from other languages descending from C
    // FIXME: How to handle quiet and signaling NaN? Do we even want to support quiet operations?
    binary_float_iso754_literal: $ => seq(
      field("literal_type",
        token(prec(1, choice(
          "F32",
          "F64",
          "F128",
        ))),
      ),
      token.immediate("|"),
      field("sign", optional(token.immediate("-"))),
      choice(
        "0",
        "Infinity",
        "NaN", "qNaN", // default is "quiet" Not-a-Number per spec
        "sNaN",
        seq(
          token.immediate(/(?:\d[\d_]*)?\.\d[\d_]*/),
          field("scientific", optional($._scientific_number_postfix)),
        ),
      ),
    ),

    _scientific_number_postfix: $ => seq(
      token.immediate("e"),
      field("exponent_sign", optional(token.immediate("-"))),
      field("exponent", token.immediate(/[1-9]\d*/)),
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
    build: $ => "build",
    type: $ => "type",
    record: $ => "record",
    let: $ => "let",
    when: $ => "when",
    is: $ => "is",
    else: $ => "else",
    where: $ => "where",
    // assert: $ => "assert",
    debug: $ => "debug",
    debug_todo: $ => "debug.todo",
    // debug_example: $ => "debug.example",
    // debug_reminder: $ => "debug.reminder",
    // debug_sketch: $ => "debug.sketch",
    debug_stash: $ => "debug.stash",
    expect: $ => "expect",
    // todo: $ => token.immediate("todo"),
    // invariant: $ => token.immediate("invariant"),
    // unreachable: $ => token.immediate("unreachable"),
    canapea: $ => "canapea",
    experimental: $ => "experimental",
    concept: $ => "concept",
    constructor: $ => "constructor",
    instance: $ => "instance",
    contract: $ => "contract",
    operator: $ => "operator",
    capability: $ => "capability",
    dot: $ => ".",
    colon: $ => ":",
    eq: $ => "=",
    arrow: $ => "->",

    pipe_operator: $ => prec(1, token("|>")),
    // maths_operator: $ => /[@!?&+\-*\/%;.><]|[@!?&|=+\-*\/%;.><]+/,
    maths_operator: $ => prec(15, token(choice(
      "+",
      "-",
      "*",
      "/",
      "%",
    ))),
    boolean_operator: $ => prec(10, token(choice(
      "==",
      "/=",
      "<=",
      ">=",
      ">",
      "<",
      "and",
      "or",
    ))),
    module_name_path_fragment: $ => /[a-z][a-z0-9]*/,

    // FIXME: Had to declare precedence to disambiguate, probably because of the
    //        regex match being exactly the same and the parser not being able
    //        to choose although it should be able to do so in this context...
    simple_record_key: $ => prec(2, alias($.identifier, "simple_record_key")),
    // simple_record_key: $ => /[_a-z][_a-zA-Z0-9]*/,
    // complex_record_key: $ => token(prec(0, /"[^"]+"/)),

    int_literal: $ => seq(/0|-?[1-9][_\d]*/, optional($._scientific_number_postfix)),

    decimal_literal: $ => seq(/-?[_\d]+\.[_\d]+/, optional($._scientific_number_postfix)),

    // FIXME: We want "simple" utf-8 in the end so this string escape needs to be adjusted, Elm supports something different
    // See https://github.com/elm-tooling/tree-sitter-elm/blob/main/grammar.js#L699
    string_escape: $ => /\\(u\{[0-9A-Fa-f]{4,6}\}|[nrt\"'\\])/,
    invalid_string_escape: $ => /\\(u\{[^}]*\}|[^nrt\"'\\])/,

    rest_args: $ => seq("...", $.identifier),
    sequence_expression_splat: $ => seq("...", $.identifier),
    record_expression_splat: $ => seq("...", $.identifier),

    // TODO: Clean up all the identifier mess including other terminal nodes
    // identifier_keyword_extraction: $ => /[_a-zA-Z]([a-zA-Z0-9]+)?/,
    identifier: $ => /_[a-zA-Z0-9]([a-zA-Z0-9]+)?|[a-z]([a-zA-Z0-9]+)?/,

    // token(prec(x, ...)) gives the token lexical precedence instead of parse precedence
    custom_type_constructor_name: $ => token(prec(1, /[A-Z][a-zA-Z0-9]*/)),
    custom_type_name: $ => alias($.custom_type_constructor_name, "custom_type_name"),
    type_concept_name: $ => alias($.custom_type_constructor_name, "type_concept_name"),
    capability_name: $ => token(prec(1, /\+[A-Z][a-zA-Z0-9]*/)),
    // capability_name: $ => alias($.custom_type_constructor_name, "capability_name"),
    record_name: $ => alias($.custom_type_name, "record_name"),

    // FIXME: qualified_access_expression can't be told apart from qualified_function_ref_expression properly
    field_access_target: $ => prec.right(alias($.identifier, "field_access_target")),
    field_access_segment: $ => alias($._identifier_without_leading_whitespace, $.identifier),

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
