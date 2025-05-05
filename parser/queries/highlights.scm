(application) @keyword.other.canapea
;(where)
(application_declaration (where) @keyword.operator.assignment.canapea) 
(application_declaration (capability_request_list (capability_request (capability_name) @storage.type.canapea)))
(module_declaration (module) @keyword.other.canapea)
(module_declaration name: (_) @string.canapea)
(development_module_declaration (module) @keyword.other.canapea name: (_) @string.canapea)
(development_module_declaration core_namespace: (_) @keyword.type.canapea)
;(exposing) @keyword.other.canapea
(module_export_list (exposing) @keyword.other.canapea)
(import_clause (import) @meta.import.canapea)
;(as)
(import_clause (as) @keyword.other.canapea)
;(exposing)
(import_expose_list (exposing) @keyword.other.canapea)

(expect) @keyword.operator.canapea

(let) @keyword.control.canapea
(when) @keyword.control.canapea
;(is)
(when_expression (is)) @keyword.control.canapea
(custom_type_declaration (custom_type_constructor_declaration (is) @keyword.control.canapea))
(custom_type_declaration (custom_type_constructor_declaration (custom_type_constructor_applied_concept) @union.canapea))

(let_expression name: (_) @constant)

(colon) @keyword.other.canapea
(capability) @keyword.other.canapea
(type_concept_declaration (concept) @keyword.other.canapea)
(type_concept_declaration (type_concept_name) @storage.type.canapea)
(type_concept_declaration (type_variable) @storage.type.canapea)
;(instance) @keyword.other.canapea
(type_concept_instance_declaration (instance) @keyword.control.canapea)
(type_concept_declaration (constructor)) @keyword.other.canapea
;(exposing)
(type_concept_implementation (exposing) @keyword.other.canapea)

(arrow) @keyword.operator.arrow.canapea

(type_annotation name: (_) @function.canapea)
(function_declaration name: (_) @function.canapea)
(call_expression (call_target) @local.function.canapea)

(qualified_access_expression target: (_) @local.function.canapea)
(function_parameter (identifier)) @local.function.canapea

(pipe_operator) @keyword.operator.canapea
(maths_operator) @keyword.operator.canapea
(eq) @keyword.operator.assignment.canapea

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
"." @punctuation.delimiter.canapea

(int_literal) @constant.numeric.canapea
(decimal_literal) @constant.numeric.canapea

(type) @keyword.type.canapea
(function) @keyword.type.canapea
;(operator) @keyword.type.canapea
(binary_operator_declaration (operator) @keyword.type.canapea)
(record_declaration (type) @keyword.type.canapea (record) @keyword.type.canapea)
(record_declaration name: (_) @storage.type.canapea)

;(type_declaration(upper_case_identifier) @storage.type.canapea)
(custom_type_declaration name: (_) @storage.type.canapea)
;(type_ref) @storage.type.canapea
;(type_alias_declaration name: (upper_case_identifier) @storage.type.canapea)

(custom_type_constructor (custom_type_constructor_name) @union.canapea)
;(custom_type_constructor_name) @union.canapea
(custom_type_pattern) @union.canapea

(comment) @comment.canapea

(string_escape) @character.escape.canapea

(open_quote) @string.canapea
(close_quote) @string.canapea
(regular_string_part) @string.canapea
(string_literal) @string.canapea

;;; ...rest_args, ...splat
(sequence_expression_splat_identifier) @constant.other
(record_expression_splat_identifier) @constant.other
(rest_args_identifier) @constant.other

;(open_char) @char.canapea
;(close_char) @char.canapea
