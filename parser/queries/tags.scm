;(function_declaration (function_parameter (function_parameter_name) @name)) @definition.function
(function_declaration (identifier) @name) @definition.function
(call_expression immediate_target: (_) @name) @reference.function
(call_expression target: (_) @name) @reference.function
(qualified_function_ref_expression target: (_) @name) @reference.function

(qualified_access_expression segment: (_) @name) @reference.function
(type_annotation name: (_) @name) @reference.function

(custom_type_declaration (custom_type_name) @name) @definition.type

(module_export_opaque_type type: (_) @name) @reference.type
(module_export_type_with_constructors type: (_) @name) @reference.type

(custom_type_declaration (custom_type_name) @name) @definition.union

(custom_type_value_expression constructor: (_) @name) @reference.union

(module_declaration
  (module_signature name: (_) @name)
) @definition.module

(experimental_module_declaration
  (module_signature name: (_) @name)
) @definition.module

(kernel_module_expression
  (module_signature name: (_) @name)
) @definition.module

(application_declaration) @definition.module
