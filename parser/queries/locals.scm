(type_annotation) @local.scope
(custom_type_declaration) @local.scope
(record_declaration) @local.scope
(let_expression) @local.scope
(function_declaration) @local.scope
(binary_operator_declaration) @local.scope
(anonymous_function_expression) @local.scope
(type_concept_declaration) @local.scope
(type_concept_requirements) @local.scope
(type_concept_implementation) @local.scope
(type_concept_instance_implementation) @local.scope

(function_declaration (function_parameter (identifier) @name) @local.definition)
(function_declaration (function_parameter (record_pattern (simple_record_key) @name)) @local.definition)
(function_declaration (function_parameter (sequence_pattern (identifier) @name)) @local.definition)
(function_declaration (function_parameter (sequence_pattern (custom_type_pattern (identifier) @name))) @local.definition)

(anonymous_function_expression (function_parameter (identifier) @name) @local.definition)
(anonymous_function_expression (function_parameter (record_pattern (simple_record_key) @name)) @local.definition)
(anonymous_function_expression (function_parameter (sequence_pattern (identifier) @name)) @local.definition)
(anonymous_function_expression (function_parameter (sequence_pattern (custom_type_pattern (identifier) @name))) @local.definition)

(qualified_access_expression segment: (_) @local.reference)
(custom_type_constructor) @local.reference
(custom_type_constructor_applied_concept) @local.reference
