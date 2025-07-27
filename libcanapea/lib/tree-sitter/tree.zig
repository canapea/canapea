const std = @import("std");

const Language = @import("./language.zig").Language;
const Node = @import("./node.zig").Node;
const Point = @import("./point.zig").Point;
const Range = @import("./range.zig").Range;

/// An edit to a text document.
pub const InputEdit = extern struct {
    start_byte: u32,
    old_end_byte: u32,
    new_end_byte: u32,
    start_point: Point,
    old_end_point: Point,
    new_end_point: Point,
};

pub const Tree = opaque {
    /// Destroy the syntax tree, freeing all of the memory that it used.
    pub fn destroy(self: *Tree) void {
        ts_tree_delete(self);
    }

    /// Get the root node of the syntax tree.
    pub fn rootNode(self: *const Tree) Node {
        return ts_tree_root_node(self);
    }
};

extern var ts_current_free: *const fn ([*]u8) callconv(.c) void;
extern fn ts_node_is_null(self: Node) bool;
extern fn ts_tree_copy(self: *const Tree) *Tree;
extern fn ts_tree_delete(self: *Tree) void;
extern fn ts_tree_root_node(self: *const Tree) Node;
extern fn ts_tree_root_node_with_offset(self: *const Tree, offset_bytes: u32, offset_extent: Point) Node;
extern fn ts_tree_language(self: *const Tree) *const Language;
extern fn ts_tree_included_ranges(self: *const Tree, length: *u32) [*c]Range;
extern fn ts_tree_edit(self: *Tree, edit: *const InputEdit) void;
extern fn ts_tree_get_changed_ranges(old_tree: *const Tree, new_tree: *const Tree, length: *u32) [*c]Range;
extern fn ts_tree_print_dot_graph(self: *const Tree, file_descriptor: c_int) void;
