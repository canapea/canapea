const std = @import("std");

const ts = @import("zig-tree-sitter");

const defaults = @import("./defaults.zig");
const iterators = @import("./iterators.zig");
const DirectChildrenIterator = iterators.DirectChildrenIterator;
const generated = @import("canapea-common-generated");
const GrammarRule = generated.GrammarRule;

const NodeVisitedById = std.AutoHashMapUnmanaged(usize, void);

const Self = @This();

code: *[]const u8,
root_id: *const anyopaque,
tree_cursor: ts.TreeCursor,
visited: NodeVisitedById = NodeVisitedById.empty,

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    self.tree_cursor.destroy();
    self.visited.deinit(allocator);
}

pub fn isRoot(self: Self) bool {
    const n = self.tree_cursor.node();
    return n.id == self.root_id or n.parent() == null;
}

pub fn depth(self: Self) u32 {
    return self.tree_cursor.depth();
}

pub fn node(self: Self) ts.Node {
    return self.tree_cursor.node();
}

pub fn fieldName(self: Self) ?[]const u8 {
    return self.tree_cursor.fieldName();
}

pub fn hasVisits(self: Self) bool {
    return self.visited.size > 0;
}

pub fn hasVisitedCurrentNode(self: Self) bool {
    return self.visited.contains(@intFromPtr(self.tree_cursor.node().id));
}

pub fn gotoFirstChild(self: *Self) bool {
    return self.tree_cursor.gotoFirstChild();
}

pub fn gotoNextSibling(self: *Self) bool {
    return self.tree_cursor.gotoNextSibling();
}

pub fn gotoParent(self: *Self) bool {
    return self.tree_cursor.gotoParent();
}

pub fn markCurrentNodeVisited(self: *Self, allocator: std.mem.Allocator) !void {
    const current = self.tree_cursor.node();
    const id: usize = @intFromPtr(current.id);
    try self.visited.put(allocator, id, {});
}

fn nodeRule(current: ts.Node) ?GrammarRule {
    return std.meta.stringToEnum(GrammarRule, current.grammarKind());
}

pub fn nodeConstruct(self: Self, allocator: std.mem.Allocator) !void {
    // _ = allocator;
    // const current = self.tree_cursor.node();
    const rule = nodeRule(self.tree_cursor.node()) orelse {
        // std.debug.print("{s}^---? (\"{s}\")\n", .{ node.grammarKind() });
        // continue :traversal;
        return;
    };
    var out = try std.ArrayListUnmanaged([]const u8).initCapacity(
        allocator,
        defaults.INITIAL_CODEGEN_BUFFER_LINE_LENGTH,
    );
    defer out.deinit(allocator);
    gen: switch (rule) {
        .development_module_declaration => {
            std.debug.print("# > {}\n", .{rule});

            var cursor = self.tree_cursor.dupe();
            defer cursor.destroy();

            if (!cursor.gotoFirstChild()) {
                break :gen;
            }
            var name_start: ?u32 = null;
            var name_end: ?u32 = null;
            var ns_start: ?u32 = null;
            var ns_end: ?u32 = null;
            loop: while (true) {
                const n1 = cursor.node();
                if (cursor.fieldName()) |field_name| {
                    if (std.mem.eql(u8, "name", field_name)) {
                        if (name_start == null) {
                            name_start = n1.startByte();
                        } else {
                            name_end = n1.endByte();
                        }
                    }
                    if (std.mem.eql(u8, "core_namespace", field_name)) {
                        // std.debug.print("# >   .?: {s}\n", .{field_name});
                        // std.debug.print("# >   ...: {}\n", .{n});
                        ns_start = n1.startByte();
                        ns_end = n1.endByte();
                    }
                } else if (nodeRule(n1)) |subrule| {
                    if (subrule == .module_export_list) {
                        if (cursor.gotoFirstChild()) {
                            mods: while (true) {
                                var n2 = cursor.node();
                                if (nodeRule(n2)) |r| {
                                    switch (r) {
                                        .module_export_value, .module_export_opaque_type => {
                                            if (try self.extractSlice(allocator, n2.startByte(), n2.endByte())) |name| {
                                                defer allocator.free(name);
                                                std.debug.print("# >   {s}: {s}\n", .{ n2.grammarKind(), name });
                                            }
                                        },
                                        .module_export_type_with_constructors => {
                                            std.debug.print("# >   .?: {s}\n", .{n2.grammarKind()});
                                        },
                                        else => {},
                                    }
                                }
                                if (!cursor.gotoNextSibling()) {
                                    break :mods;
                                }
                            }
                            // We came here by descending, so we know there is a parent
                            _ = cursor.gotoParent();
                        }
                    }
                }
                if (!cursor.gotoNextSibling()) {
                    break :loop;
                }
            }

            if (try self.extractSlice(allocator, name_start, name_end)) |name| {
                defer allocator.free(name);
                std.debug.print("# >   name: {s}\n", .{name});
            }
            if (try self.extractSlice(allocator, ns_start, ns_end)) |ns| {
                defer allocator.free(ns);
                std.debug.print("# >   core_namespace: {s}\n", .{ns});
            }
        },
        else => {
            // std.debug.print("# {s}\n", .{current.grammarKind()});
        },
    }
}

/// Caller owns memory.
fn extractSlice(self: Self, allocator: std.mem.Allocator, start: ?u32, end: ?u32) !?[]const u8 {
    if (start) |s| {
        if (end) |e| {
            const c = try allocator.alloc(u8, e - s);
            for (0..c.len) |i| {
                c[i] = self.code.*[s + i];
            }
            return c;
        }
    }
    return null;
}

/// Cursor is copied. Caller needs to .deinit() the iterator.
fn traverseDirectChildren(self: Self) DirectChildrenIterator(Self) {
    const cursor = self.tree_cursor.dupe();
    return .{
        .cursor = .{
            .code = self.code,
            .tree_cursor = cursor,
            .root_id = cursor.node().id,
        },
    };
}
