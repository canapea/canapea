(application_declaration
    (module_signature
        (application) @keyword.other.canapea
    )
)
(module_signature
  (module) @keyword.other.canapea
  name: (_) @string.canapea
)
; (experimental_module_declaration (module) @keyword.other.canapea name: (_) @string.canapea)
; (experimental_module_declaration name: (_) @string.canapea)
; (kernel_module_expression (module) @keyword.other.canapea name: (_) @string.canapea)
; (kernel_module_expression name: (_) @string.canapea)
(module_name_definition privileged_namespace: (_) @keyword.type.canapea)
;(exposing) @keyword.other.canapea
(module_export_list (exposing) @keyword.other.canapea)
(import_capability_clause (import) @meta.import.canapea (capability) @keyword.other.canapea)
(import_clause (import) @meta.import.canapea)
;(as)
(import_clause (as) @keyword.other.canapea)
;(exposing)
(import_expose_list (exposing) @keyword.other.canapea)
(application_config_declaration (application) @keyword.other.canapea (config) @keyword.control.canapea)
(module_build_declaration (module) @keyword.other.canapea (build) @keyword.control.canapea)

;(expect)
(test_expectation (expect) @keyword.operator.canapea)
(todo_expression (debug_todo) @keyword.operator.canapea)
(livedoc_expression category: (_) @keyword.control.canapea)
;(invariant_assertion (assert) @keyword.operator.canapea (invariant) @keyword.other.canapea)
;(unreachable_assertion (assert) @keyword.operator.canapea (unreachable) @keyword.other.canapea)
;(local_assertion (assert) @keyword.operator.canapea)

(dont_care) @keyword.unused.canapea
(let) @keyword.control.canapea
(when) @keyword.control.canapea
;(is)
(when_expression (is) @keyword.control.canapea)
(when_expression (when_branch_catchall (else) @keyword.control.canapea))
(custom_type_declaration (custom_type_constructor_declaration (is) @keyword.control.canapea))
(custom_type_declaration (custom_type_constructor_declaration (custom_type_constructor_applied_concept) @union.canapea))

(let_expression name: (_) @constant)

(colon) @keyword.other.canapea
;(capability) @keyword.other.canapea
(type_concept_declaration (concept) @keyword.other.canapea)
(type_concept_declaration (type_concept_name) @storage.type.canapea)
(type_concept_declaration (type_variable) @storage.type.canapea)
;(instance) @keyword.other.canapea
(type_concept_instance_declaration (concept) @keyword.other.canapea (instance) @keyword.control.canapea)
(type_constructor_concept_declaration (type) @keyword.other.canapea)
(type_constructor_concept_declaration (constructor) @keyword.control.canapea)
(type_constructor_concept_declaration (concept) @keyword.other.canapea)
;(exposing)
(type_concept_implementation (exposing) @keyword.other.canapea)

(arrow) @keyword.operator.arrow.canapea

(type_annotation name: (_) @function.canapea)
(function_declaration name: (_) @function.canapea)
(call_expression target: (_) @local.function.canapea)
(call_expression immediate_target: (_) @local.function.canapea)
(qualified_function_ref_expression target: (_) @local.function.canapea)
(qualified_access_expression target: (_) @local.function.canapea)
(qualified_access_expression segment: (_) @property.canapea)
(function_parameter name: (_)) @local.function.canapea

(pipe_operator) @keyword.operator.canapea
(maths_operator) @keyword.operator.canapea
(eq) @keyword.operator.assignment.canapea
(boolean_operator) @keyword.operator.canapea

[
"("
")"
] @punctuation.section.braces

[
  "["
  "]"
  "{"
  "}"
] @punctuation.section.bracket

"|" @keyword.other.canapea
"," @punctuation.separator.comma.canapea
(dot) @punctuation.delimiter.canapea

(int_literal) @constant.numeric.canapea
(decimal_literal) @constant.numeric.canapea

(type) @keyword.type.canapea
;(function) @keyword.type.canapea
;(operator) @keyword.type.canapea
(binary_operator_declaration (operator) @keyword.type.canapea)
(record_declaration (type) @keyword.type.canapea (record) @keyword.type.canapea)
(record_declaration name: (_) @storage.type.canapea)

;(type_declaration(upper_case_identifier) @storage.type.canapea)
(custom_type_constructor_name) @union.canapea
(custom_type_name) @storage.type.canapea
(custom_type_declaration name: (_) @storage.type.canapea)
;(type_ref) @storage.type.canapea
;(type_alias_declaration name: (upper_case_identifier) @storage.type.canapea)

; (custom_type_constructor (custom_type_constructor_name) @union.canapea)
;(custom_type_constructor_name) @union.canapea
(custom_type_pattern) @union.canapea

(comment) @comment.canapea

(string_escape) @character.escape.canapea

(open_quote) @string.canapea
(close_quote) @string.canapea
(regular_string_part) @string.canapea
(string_literal) @string.canapea

;;; ...rest_args, ...splat
(sequence_expression_splat_identifier) @constant.other.canapea
(record_expression_splat_identifier) @constant.other.canapea
(rest_args_identifier) @constant.other.canapea

(custom_type_pattern (identifier) @constant.other.canapea)
(record_pattern (simple_record_key) @constant.other.canapea)
(sequence_pattern (identifier) @constant.other.canapea)

;(open_char) @char.canapea
;(close_char) @char.canapea
