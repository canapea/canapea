const std = @import("std");
const crypto = std.crypto;
const Allocator = std.mem.Allocator;

const model = @import("canapea-common");
const defaults = model.defaults;
const Node = model.Sapling.Node;

const Self = @This();

pub fn streamAllInto(alloc: Allocator, nursery: model.Nursery, writer: anytype) !void {
    try writer.print("(function __canapea__(window, globalThis, undefined) {{\n", .{});
    try writer.print("  'use strict';\n\n", .{});

    for (nursery.saplings) |sapling| {
        try streamInto(alloc, sapling, writer);
    }

    try writer.print("}}(self, typeof globalThis !== 'undefined' ? globalThis : self));\n\n", .{});
}

fn streamInto(alloc: Allocator, sapling: model.Sapling, writer: anytype) !void {
    const module_id: []const u8, const sig = blk: {
        // FIXME: Module name has to be optional!
        const it = sapling.queryRoot(
            \\ (module_signature
            \\   name: (_) @p0
            \\ )
        );
        defer it.deinit();
        while (try it.next(alloc)) |item| {
            // std.debug.print("match: index({}), val({?s}) in {}\n", .{
            //     item.pattern_index,
            //     item.value,
            //     item.node,
            // });
            const parent = item.node.parent() orelse {
                return error.ModuleSignatureMissing;
            };
            if (item.value) |value| {
                defer alloc.free(value);

                const dupe = try alloc.dupe(u8, value);
                break :blk .{ normalizeName(u8, dupe), parent };
            } else {
                // FIXME: There has to be an easier way to create random strings
                const gen = try alloc.alloc(u8, 16);
                for (gen) |*ch| {
                    ch.* = crypto.random.intRangeAtMost(u8, 0, 255);
                }
                break :blk .{ gen, parent };
            }
        }
        return error.ModuleHasUnexpectedStructure;
    };
    defer alloc.free(module_id);

    const gen_prefix = try std.fmt.allocPrint(alloc, "__$$canapea_module$$__${?s}$__", .{module_id});
    defer alloc.free(gen_prefix);

    {
        const it = sapling.queryNode(
            sig,
            \\ (module_export_value) @p0
            \\ (module_export_opaque_type) @p1
            \\ (module_export_type_with_constructors) @p2
            ,
        );
        defer it.deinit();

        while (try it.next(alloc)) |item| {
            // std.debug.print("match: id({}), val({?s}) in {}\n", .{
            //     item.pattern_index,
            //     item.value,
            //     item.node,
            // });
            switch (item.pattern_index) {
                0 => if (item.value) |constant| {
                    defer alloc.free(constant);

                    try writer.print("  // Value: {s}\n", .{constant});
                    try writer.print("  const {s}{s} = null;\n\n", .{ gen_prefix, constant });
                },
                1 => if (item.value) |type_name| {
                    defer alloc.free(type_name);

                    try writer.print("  // OpaqueCustomType: {s}\n", .{type_name});
                    try writer.print("  function {s}{s}() {{ }}\n\n", .{ gen_prefix, type_name });
                },
                2 => {
                    defer if (item.value) |val| alloc.free(val);

                    if (item.node.childByFieldName("type")) |child| {
                        const type_name = try sapling.stringValue(alloc, child);
                        defer alloc.free(type_name);

                        try writer.print("  // CustomTypeWithConstructors: {s}\n", .{type_name});
                        try writer.print("  function {s}{s}() {{ }}\n\n", .{ gen_prefix, type_name });
                    } else unreachable;
                },
                else => unreachable,
            }
        }
    }
}

fn normalizeName(comptime T: type, slice: []T) []T {
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
