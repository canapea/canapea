const std = @import("std");

const ts = @import("zig-tree-sitter");

const generated = @import("canapea-common-generated");
const GrammarRule = generated.GrammarRule;
const data = @import("./data.zig");
const ModuleExport = data.ModuleExport;
const defaults = @import("./defaults.zig");
const iterators = @import("./iterators.zig");
const DirectChildrenIterator = iterators.DirectChildrenIterator;
const StringBuilder = @import("./StringBuilder.zig");

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

pub fn nodeConstruct(self: Self, allocator: std.mem.Allocator) !?StringBuilder.Slice {
    // _ = allocator;
    // const current = self.tree_cursor.node();
    const rule = nodeRule(self.tree_cursor.node()) orelse {
        // std.debug.print("{s}^---? (\"{s}\")\n", .{ node.grammarKind() });
        // continue :traversal;
        return null;
    };
    var out = try StringBuilder.initCapacity(
        allocator,
        defaults.INITIAL_CODEGEN_BUFFER_LINE_LENGTH,
    );
    defer out.deinit(allocator);

    var mod: ?data.Module = null;
    defer if (mod) |m| m.deinit(allocator);

    var visitors = try std.ArrayListUnmanaged(Visitor).initCapacity(
        allocator,
        defaults.INITIAL_VISITOR_LIST_SIZE,
    );
    defer {
        for (visitors.items) |vis| {
            vis.deinit(allocator);
        }
        visitors.deinit(allocator);
    }

    if (Visitor.from(rule)) |vis| {
        try visitors.append(allocator, vis);
    }

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
                            if (try self.extractSlice(allocator, name_start, name_end)) |name| {
                                // defer allocator.free(name);
                                std.debug.print("# >   name: {s}\n", .{name});
                                const name_mut: []u8 = try allocator.alloc(u8, name.len);
                                defer allocator.free(name_mut);
                                std.mem.copyForwards(u8, name_mut, name);
                                try out.appendFormat(
                                    allocator,
                                    \\
                                    \\// Module: {s}
                                    \\function __{s}(exports, module) {{
                                    \\
                                ,
                                    .{ name, normalizeFunctionName(u8, name_mut) },
                                );
                                mod = data.Module.init(name);
                            }
                            if (try self.extractSlice(allocator, ns_start, ns_end)) |ns| {
                                // defer allocator.free(ns);
                                std.debug.print("# >   core_namespace: {s}\n", .{ns});
                                mod.?.dev_namespace = ns;
                            }

                            var list = try std.ArrayListUnmanaged(ModuleExport).initCapacity(
                                allocator,
                                defaults.INITIAL_EXPORT_LIST_SIZE,
                            );
                            defer list.deinit(allocator);

                            mods: while (true) {
                                var n2 = cursor.node();
                                if (nodeRule(n2)) |r| {
                                    switch (r) {
                                        .module_export_value, .module_export_opaque_type => {
                                            if (try self.extractSlice(allocator, n2.startByte(), n2.endByte())) |name| {
                                                // defer allocator.free(name);
                                                std.debug.print("# >   {s}: {s}\n", .{ n2.grammarKind(), name });
                                                try out.appendFormat(
                                                    allocator,
                                                    \\  // Node: {s}
                                                    \\  exports.{s} = {s};
                                                    \\
                                                ,
                                                    .{ n2.grammarKind(), name, name },
                                                );

                                                // const name_dupe = try allocator.dupe(u8, name);
                                                try list.append(allocator, switch (r) {
                                                    .module_export_opaque_type => ModuleExport.exportType(name),
                                                    else => ModuleExport.exportConstant(name),
                                                });
                                            }
                                        },
                                        .module_export_type_with_constructors => {
                                            std.debug.print("# >   .?: {s}\n", .{n2.grammarKind()});
                                            try out.appendFormat(
                                                allocator,
                                                \\  // TODO: Node: {s}
                                                \\
                                            ,
                                                .{n2.grammarKind()},
                                            );
                                        },
                                        else => {},
                                    }
                                }
                                if (!cursor.gotoNextSibling()) {
                                    break :mods;
                                }
                            }
                            try out.appendFormat(
                                allocator,
                                \\}}
                                \\
                            ,
                                .{},
                            );
                            mod.?.exposing = try list.toOwnedSlice(allocator);

                            // We came here by descending, so we know there is a parent
                            _ = cursor.gotoParent();
                        }
                    }
                }
                if (!cursor.gotoNextSibling()) {
                    break :loop;
                }
            }
        },
        else => {
            // std.debug.print("# {s}\n", .{current.grammarKind()});
        },
    }
    return try out.toOwnedSlice(allocator);
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

fn normalizeFunctionName(comptime T: type, slice: []T) []T {
    const replacement = '_';
    for (slice) |*e| {
        const ch = e.*;
        e.* = switch (ch) {
            'A'...'Z' => ch,
            'a'...'z' => ch,
            '0'...'9' => ch,
            // '-' => ch,
            else => replacement,
        };
    }
    return slice;
}

pub const RuleKind = enum {
    on_visit_descendant,
    on_leave,
    child_name,
    // descend_into,
    extract_names,
    child_node_value,
};

pub const RuleInstruction = enum {
    keep_alive,
    flush,
};

pub const Rule = struct {
    kind: RuleKind,
    name_selector: ?[]const u8 = null,
    node_selector: ?GrammarRule = null,
    instruction: ?RuleInstruction = null,
};

pub const Visitor = struct {
    root: GrammarRule,
    /// Intended to be accessed directly
    rules: []const Rule,

    pub fn deinit(self: Visitor, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
    }

    pub fn from(rule: GrammarRule) ?Visitor {
        return switch (rule) {
            .development_module_declaration => {
                return .{
                    .root = rule,
                    .rules = &[_]Rule{
                        .{ .kind = .on_visit_descendant, .node_selector = .module_export_list, .instruction = .keep_alive },
                        .{ .kind = .child_name, .name_selector = "name" },
                        .{ .kind = .child_name, .name_selector = "core_namespace" },
                        .{ .kind = .extract_names },
                        .{ .kind = .child_node_value, .node_selector = .module_export_value },
                        .{ .kind = .child_node_value, .node_selector = .module_export_opaque_type },
                        .{ .kind = .child_node_value, .node_selector = .module_export_type_with_constructors },
                        .{ .kind = .on_leave, .instruction = .flush },
                    },
                };
            },
            else => null,
        };
    }

    pub fn visit(self: Visitor, allocator: std.mem.Allocator, g_rule: GrammarRule, kind: RuleKind, str: []const u8) bool {
        _ = self;
        _ = allocator;
        _ = g_rule;
        _ = kind;
        _ = str;
    }

    pub fn flush(self: Visitor) void {
        _ = self;
    }
};
