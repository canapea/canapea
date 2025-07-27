const std = @import("std");

const Language = @import("./language.zig").Language;
const Node = @import("./node.zig").Node;

const QueryError = enum(c_uint) {
    None,
    Syntax,
    NodeType,
    Field,
    Capture,
    Structure,
    Language,
};

/// A set of patterns that match nodes in a syntax tree.
pub const Query = opaque {
    /// Create a new query from a string containing one or more S-expression
    /// patterns.
    ///
    /// The query is associated with a particular language, and can only be run
    /// on syntax nodes parsed with that language. References to Queries can be
    /// shared between multiple threads.
    ///
    /// If a pattern is invalid, this returns a `Query.Error` and writes
    /// the byte offset of the error to the `error_offset` parameter.
    ///
    /// Example:
    ///
    /// ```zig
    /// var error_offset: u32 = 0;
    /// const query = Query.create(language, "(identifier) @variable", &error_offset)
    ///     catch |err| std.debug.panic("{s} error at position {d}", . { @errorName(err), error_offset });
    /// ```
    pub fn create(language: *const Language, source: []const u8, error_offset: *u32) Error!*Query {
        var error_type: QueryError = .None;
        const query = ts_query_new(language, source.ptr, @intCast(source.len), error_offset, &error_type);
        return query orelse switch (error_type) {
            .Syntax => error.InvalidSyntax,
            .NodeType => error.InvalidNodeType,
            .Field => error.InvalidField,
            .Capture => error.InvalidCapture,
            .Structure => error.InvalidStructure,
            .Language => error.InvalidLanguage,
            else => unreachable,
        };
    }

    /// Destroy the query, freeing all of the memory that it used.
    pub fn destroy(self: *Query) void {
        ts_query_delete(self);
    }

    /// The kind of error that occurred while creating a `Query`.
    pub const Error = error{
        InvalidSyntax,
        InvalidNodeType,
        InvalidField,
        InvalidCapture,
        InvalidStructure,
        InvalidLanguage,
    };

    /// A particular `Node` that has been captured within a query.
    pub const Capture = extern struct {
        node: Node,
        index: u32,
    };

    /// A match that corresponds to a certain pattern in the query.
    pub const Match = struct {
        id: u32,
        pattern_index: u16,
        captures: []const Query.Capture,
    };
};

extern fn ts_query_new(
    language: ?*const Language,
    source: [*c]const u8,
    source_len: u32,
    error_offset: *u32,
    error_type: *QueryError,
) ?*Query;
extern fn ts_query_delete(self: *Query) void;
extern fn ts_query_pattern_count(self: *const Query) u32;
extern fn ts_query_capture_count(self: *const Query) u32;
extern fn ts_query_string_count(self: *const Query) u32;
extern fn ts_query_start_byte_for_pattern(self: *const Query, pattern_index: u32) u32;
extern fn ts_query_end_byte_for_pattern(self: *const Query, pattern_index: u32) u32;
extern fn ts_query_is_pattern_rooted(self: *const Query, pattern_index: u32) bool;
extern fn ts_query_is_pattern_non_local(self: *const Query, pattern_index: u32) bool;
extern fn ts_query_is_pattern_guaranteed_at_step(self: *const Query, byte_offset: u32) bool;
extern fn ts_query_capture_name_for_id(self: *const Query, index: u32, length: *u32) [*c]const u8;
extern fn ts_query_capture_quantifier_for_id(
    self: *const Query,
    pattern_index: u32,
    capture_index: u32,
) Query.Quantifier;
extern fn ts_query_string_value_for_id(self: *const Query, index: u32, length: *u32) [*c]const u8;
extern fn ts_query_disable_capture(self: *Query, name: [*c]const u8, length: u32) void;
extern fn ts_query_disable_pattern(self: *Query, pattern_index: u32) void;
extern fn ts_query_predicates_for_pattern(
    self: *const Query,
    pattern_index: u32,
    step_count: *u32,
) [*c]const Query.PredicateStep;
