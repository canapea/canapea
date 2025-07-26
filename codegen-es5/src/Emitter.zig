const std = @import("std");
const Allocator = std.mem.Allocator;

const model = @import("canapea-common");
const defaults = model.defaults;
const Node = model.Sapling.Node;

const Self = @This();

pub fn streamAllInto(alloc: Allocator, nursery: model.Nursery, writer: anytype) !void {
    try writer.print("(function __canapea__(window, globalThis, undefined) {{\n", .{});
    try writer.print("  'use strict';\n", .{});

    _ = alloc;
    _ = nursery;

    try writer.print("}}(self, typeof globalThis !== 'undefined' ? globalThis : self));\n\n", .{});
}

fn streamInto(alloc: Allocator, sapling: model.Sapling, writer: anytype) !void {
    var module_id: [64]u8 = undefined;
    std.Random.bytes(&module_id);
    defer alloc.free(module_id);

    var maybe_module_signature: ?Node = null;

    {
        const it = sapling.queryRoot(
            \\ (module_signature
            \\   name: (_) @p0
            \\ )
        );
        defer it.deinit();
        while (try it.next(alloc)) |item| {
            std.debug.print("match: index({}), val({?s}) in {}\n", .{
                item.pattern_index,
                item.value,
                item.node,
            });
            maybe_module_signature = item.node.parent();
            if (item.value) |value| {
                module_id = alloc.dupe(u8, value);
            }
        }
    }

    const sig = blk: {
        if (maybe_module_signature) |sig| {
            break :blk sig;
        }
        return error.NoModuleSignatureFound;
    };

    const gen_prefix = std.fmt.allocPrint(alloc, "__$$canapea_module__${s}$__", .{module_id});
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
            std.debug.print("match: id({}), val({?s}) in {}\n", .{
                item.pattern_index,
                item.value,
                item.node,
            });
            switch (item.pattern_index) {
                0 => if (item.value) |constant| {
                    defer alloc.free(constant);

                    try writer.print("// Value: {s}\n", .{constant});
                    try writer.print("const {s}{s} = null;\n", .{ gen_prefix, constant });
                },
                1 => if (item.value) |type_name| {
                    defer alloc.free(type_name);

                    try writer.print("// OpaqueCustomType: {s}\n", .{type_name});
                    try writer.print("function {s}{s}{{ }};\n", .{ gen_prefix, type_name });
                },
                2 => {
                    defer if (item.value) |val| alloc.free(val);

                    if (item.node.childByFieldName("type")) |child| {
                        const type_name = try sapling.stringValue(alloc, child);
                        defer alloc.free(type_name);

                        try writer.print("// CustomTypeWithConstructors: {s}\n", .{type_name});
                        try writer.print("function {s}{s}{{ }};\n", .{ gen_prefix, type_name });
                    } else unreachable;
                },
                else => unreachable,
            }
        }
    }
}
