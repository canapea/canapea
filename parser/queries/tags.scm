(function_declaration (function_parameter (identifier) @name)) @definition.function
(call_expression (call_target) @name) @reference.function

(qualified_access_expression segment: (identifier) @name) @reference.function
(type_annotation name: (_) @name) @reference.function

(custom_type_declaration (custom_type_constructor_name) @name) @definition.type

(module_export_opaque_type type: (_) @name) @reference.type
(module_export_type_with_constructors type: (_) @name) @reference.type

(custom_type_declaration (custom_type_constructor_name) @name) @definition.union

(call_target (custom_type_trivial_value_expression) @name) @reference.union

(module_declaration 
  name: (_) @name
) @definition.module
