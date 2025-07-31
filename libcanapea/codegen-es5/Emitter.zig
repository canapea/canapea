const std = @import("std");
const Writer = std.io.Writer;
const crypto = std.crypto;
const Allocator = std.mem.Allocator;

const model = @import("canapea-common");
const defaults = model.defaults;
const Node = model.Sapling.Node;

const Self = @This();

pub fn streamAllInto(alloc: Allocator, nursery: model.Nursery, writer: anytype) !void {
    // TODO: Sort modules beforehand so they can just be instantiated from top to bottom
    // for (nursery.saplings) |sapling| {
    //     // std.sort.insertion([]const u8, items: []T, context: anytype, comptime lessThanFn: fn(@TypeOf(context), lhs:T, rhs:T)bool)
    //     const it = sapling.queryRoot(
    //         \\ [
    //         \\   (module_signature
    //         \\     name: (_) @modname
    //         \\   )
    //         \\   (module_import_name) @impname
    //         \\ ]
    //         ,
    //     );
    //     defer it.deinit();
    // }

    try writer.print(
        \\;(function __canapea__(globalThis, undefined, __$rt) {{
        \\  "use strict";
        \\
        \\
    , .{});

    for (nursery.saplings, 0..) |sapling, i| {
        try streamInto(alloc, sapling, i, writer);
    }

    try writer.print(
        \\}}(typeof globalThis !== "undefined" ? globalThis : self, void 0, (function runtime(pure, impure) {{
        \\
        \\  // Canapea Runtime
        \\
        \\}}({{$cap:"RunPureCode"}},{{$cap:"RunImpureCode"}}))));
        \\
    , .{});
}

fn streamInto(alloc: Allocator, sapling: model.Sapling, index: usize, writer: anytype) !void {
    const module_id: []const u8, const sig = blk: {
        const it = sapling.queryRoot(
            \\
            \\ (module_signature) @sig
            \\
        );
        defer it.deinit();
        while (try it.next(alloc)) |item| {
            defer if (item.value) |val| alloc.free(val);
            // std.debug.print("match: index({}), val({?s}) in {}\n", .{
            //     item.pattern_index,
            //     item.value,
            //     item.node,
            // });
            const sig = item.node;
            if (sig.childByFieldName("name")) |nameNode| {
                const value = try sapling.stringValue(alloc, nameNode);
                defer alloc.free(value);

                const dupe = try alloc.dupe(u8, value);
                break :blk .{ normalizeName(u8, dupe), sig };
            } else {
                // FIXME: There has to be an easier way to create random strings
                // const gen = try alloc.alloc(u8, 16);
                // for (gen) |*ch| {
                //     ch.* = crypto.random.intRangeAtMost(u8, 141, 172);
                // }
                const gen = try std.fmt.allocPrint(alloc, "anonymous{}", .{index});
                break :blk .{ gen, sig };
            }
        }
        return error.ModuleHasUnexpectedStructure;
    };
    defer alloc.free(module_id);

    const gen_prefix = try createModuleName(alloc, module_id);
    defer alloc.free(gen_prefix);

    try writer.print("  //\n", .{});
    try writer.print("  // {} {s}\n", .{ .module_signature, module_id });
    try writer.print("  //\n\n", .{});

    // Type Exports
    {
        const it = sapling.queryRoot(
            \\  [
            \\   (module_export_opaque_type)
            \\   (module_export_type_with_constructors)
            \\   (module_export_capability)
            \\  ] @exports
            ,
        );
        defer it.deinit();

        while (try it.next(alloc)) |item| {
            // std.debug.print("match: id({}), val({?s}) in {}\n", .{
            //     item.pattern_index,
            //     item.value,
            //     item.node,
            // });
            switch (item.node.kind().?) {
                // .module_export_value => if (item.value) |constant| {
                //     defer alloc.free(constant);

                //     // if (lookup.get(constant)) |node| {
                //     //     std.debug.print("lookup: name({s}), node({})\n", .{
                //     //         constant,
                //     //         node,
                //     //     });
                //     // }

                //     try writer.print("    // {}: {s}\n", .{ .module_export_value, constant });
                //     // try writer.print("    let {s}{s}{s} = null;\n\n", .{ gen_prefix, "_export_", constant });
                //     try writer.print("    exports['{s}'] = {s};\n\n", .{ constant, constant });
                // },
                .module_export_opaque_type => if (item.value) |type_name| {
                    defer alloc.free(type_name);

                    // if (lookup.get(type_name)) |node| {
                    //     std.debug.print("lookup: name({s}), node({})\n", .{
                    //         type_name,
                    //         node,
                    //     });
                    // }

                    try writer.print("  // {}: {s}\n", .{ .module_export_opaque_type, type_name });
                    try writer.print("  function {s}_type_{s}() {{ }}\n\n", .{ gen_prefix, type_name });
                },
                .module_export_type_with_constructors => {
                    defer if (item.value) |val| alloc.free(val);

                    if (item.node.childByFieldName("type")) |child| {
                        const type_name = try sapling.stringValue(alloc, child);
                        defer alloc.free(type_name);

                        // if (lookup.get(type_name)) |node| {
                        //     std.debug.print("lookup: name({s}), node({})\n", .{
                        //         type_name,
                        //         node,
                        //     });
                        // }

                        try writer.print("  // {}: {s}\n", .{ .module_export_type_with_constructors, type_name });
                        try writer.print("  function {s}_type_{s}() {{ }}\n\n", .{ gen_prefix, type_name });
                    } else unreachable;
                },
                .module_export_capability => if (item.value) |type_name| {
                    const capability_name = normalizeName(u8, try alloc.dupe(u8, type_name));
                    defer alloc.free(type_name);
                    defer alloc.free(capability_name);

                    // if (lookup.get(type_name)) |node| {
                    //     std.debug.print("lookup: name({s}), node({})\n", .{
                    //         type_name,
                    //         node,
                    //     });
                    // }

                    try writer.print("  // {}: {s}\n", .{ .module_export_capability, capability_name });
                    try writer.print("  function {s}_capability_{s}() {{ }}\n\n", .{ gen_prefix, capability_name });
                },
                else => unreachable,
            }
        }
    }

    try writer.print("  // Module {s}\n", .{module_id});
    try writer.print("  function {s}(__exports__) {{\n", .{gen_prefix});
    try writer.print("    if ({s}.$) return {s}.$;\n\n", .{ gen_prefix, gen_prefix });

    // Imports
    {
        const it = sapling.queryNode(
            sig,
            \\
            \\ [
            \\   (module_import_name) @name
            \\   (named_module_import) @qualified
            \\   [
            \\     (import_capability_expose_list
            \\       (import_expose_capability) @cap
            \\     )
            \\     (import_expose_list
            \\       (import_expose_type) @type
            \\     )
            \\   ]
            \\ ]
            \\
            ,
        );
        defer it.deinit();

        {
            var imp_mod: ?[]u8 = null;
            defer if (imp_mod) |n| alloc.free(n);

            while (try it.next(alloc)) |item| {
                defer if (item.value) |val| alloc.free(val);

                // std.debug.print("match: id({}), val({s}) in {}\n", .{
                //     item.pattern_index,
                //     item.value orelse "",
                //     item.node,
                // });

                const value: []u8 = normalizeName(u8, try alloc.dupe(u8, item.value.?));
                defer alloc.free(value);
                switch (item.node.kind().?) {
                    .module_import_name => {
                        if (imp_mod) |n| alloc.free(n);
                        imp_mod = try alloc.dupe(u8, value);
                    },
                    .named_module_import => {
                        const namespace = value;
                        const gen_module_name = try createModuleName(alloc, imp_mod.?);
                        defer alloc.free(gen_module_name);
                        try writer.print("    // {}: {s} as {s}\n", .{ .named_module_import, imp_mod.?, namespace });
                        // try writer.print("    const {s} = {s};\n\n", .{ namespace, gen_module_name });
                        try writer.print("    const {s} = {s}({{}});\n\n", .{ namespace, gen_module_name });
                    },
                    .import_expose_capability => {
                        const capability = value;
                        try writer.print("    // {}: {s} from {s}\n", .{ .import_expose_capability, item.value.?, imp_mod.? });
                        try writer.print("    const {s} = {s}{s}{s}{s};\n\n", .{ capability, gen_prefix, imp_mod.?, "_capability_", capability });
                    },
                    .import_expose_type => {
                        const typ = value;
                        try writer.print("    // {}: {s} from {s}\n", .{ .import_expose_type, item.value.?, imp_mod.? });
                        try writer.print("    const {s} = {s}{s}{s}{s};\n\n", .{ typ, gen_prefix, imp_mod.?, "_type_", typ });
                    },
                    else => unreachable,
                }
            }
        }
    }

    // Declarations
    {
        const decls = sapling.queryRoot(
            \\ [
            \\   (_
            \\      [
            \\        (function_declaration)
            \\        (let_declaration)
            \\        (custom_type_declaration)
            \\        (record_declaration)
            \\      ] @decls
            \\   )
            \\ ]
        );
        defer decls.deinit();

        var lookup = std.StringArrayHashMapUnmanaged(Node).empty;
        defer {
            for (lookup.keys()) |key| {
                alloc.free(key);
            }
            lookup.deinit(alloc);
        }
        while (try decls.next(alloc)) |item| {
            switch (item.node.kind().?) {
                .function_declaration, .let_declaration, .custom_type_declaration, .record_declaration => if (item.value) |f| {
                    defer alloc.free(f);

                    if (item.node.childByFieldName("name")) |child| {
                        const name = try sapling.stringValue(alloc, child);
                        try lookup.put(alloc, name, item.node);
                        try writer.print("    // Decl found: {s}={}\n", .{ name, item.node.kind().? });
                        try writer.print("    const {s} = null;\n\n", .{name});
                    }
                },
                else => unreachable,
            }
        }
    }

    // Value Exports
    {
        const it = sapling.queryRoot(
            \\  [
            \\   (module_export_value)
            \\  ] @exports
            ,
        );
        defer it.deinit();

        while (try it.next(alloc)) |item| {
            // std.debug.print("match: id({}), val({?s}) in {}\n", .{
            //     item.pattern_index,
            //     item.value,
            //     item.node,
            // });
            switch (item.node.kind().?) {
                .module_export_value => if (item.value) |constant| {
                    defer alloc.free(constant);

                    // if (lookup.get(constant)) |node| {
                    //     std.debug.print("lookup: name({s}), node({})\n", .{
                    //         constant,
                    //         node,
                    //     });
                    // }

                    try writer.print("    // {}: {s}\n", .{ .module_export_value, constant });
                    // try writer.print("    let {s}{s}{s} = null;\n\n", .{ gen_prefix, "_export_", constant });
                    try writer.print("    __exports__['{s}'] = {s};\n\n", .{ constant, constant });
                },
                else => unreachable,
            }
        }
    }

    try writer.print("    return ({s}.$ = __exports__);\n", .{gen_prefix});
    try writer.print("  }}\n", .{});
    try writer.print("  // Module Body Close\n\n", .{});
}

/// Caller owns memory
fn createModuleName(alloc: Allocator, module_id: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(alloc, "__$$canapea_module$$__${s}$__", .{module_id});
}

fn mapNormalizeName(comptime T: type, value: ?[]T) ?[]T {
    if (value) |it| {
        return normalizeName(T, it);
    }
    return null;
}

fn normalizeName(comptime T: type, slice: []T) []T {
    const replacement = '$';
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
