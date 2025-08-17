const std = @import("std");
const Writer = std.io.Writer;
const crypto = std.crypto;
const Allocator = std.mem.Allocator;

const model = @import("canapea-common");
const defaults = model.defaults;
const Node = model.Sapling.Node;

const Self = @This();

pub fn streamAllInto(alloc: Allocator, nursery: model.Nursery, writer: anytype) !void {
    try writer.print(
        \\;(function __canapea__shell__(globalThis, code) {{
        \\  "use strict";
        \\
        \\  const pure = {{$:"+RunPureCode"}};
        \\  const impure = {{$:"+RunImpureCode"}};
        \\
        \\  function setup() {{
        \\  }}
        \\  setup.produceMain = function () {{ throw "No entry point found"; }};
        \\
        \\  code(setup);
        \\
        \\  const main = setup.produceMain();
        \\  main.call(null, {{}});
        \\
        \\}}(typeof globalThis !== "undefined" ? globalThis : self, function __canapea__(__$setup, undefined) {{
        \\
        \\
    , .{});

    for (nursery.saplings, 0..) |sapling, i| {
        // FIXME: Allow header/footer/runtime writers?
        try streamInto(alloc, sapling, i, writer);
    }

    try writer.print(
        \\
        \\}}));
        \\
    , .{});
}

fn streamInto(alloc: Allocator, sapling: model.Sapling, index: usize, writer: anytype) !void {
    const module_id: []const u8, const sig, const is_app = blk: {
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
            const is_app = sig.parent().?.kind().? == .application_declaration;
            if (sig.childByFieldName("name")) |nameNode| {
                const value = try sapling.stringValue(alloc, nameNode);
                defer alloc.free(value);

                const dupe = try alloc.dupe(u8, value);
                break :blk .{ normalizeName(u8, dupe), sig, is_app };
            } else {
                // FIXME: There has to be an easier way to create random strings
                // const gen = try alloc.alloc(u8, 16);
                // for (gen) |*ch| {
                //     ch.* = crypto.random.intRangeAtMost(u8, 141, 172);
                // }
                const gen = try std.fmt.allocPrint(alloc, "anonymous{}", .{index});
                break :blk .{ gen, sig, is_app };
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
    try writer.print("    if ({s}.$) return {s}.$;\n", .{ gen_prefix, gen_prefix });
    try writer.print("    __exports__ = __exports__ || {{}};\n\n", .{});

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
            var gen_module_name: ?[]const u8 = null;
            defer if (gen_module_name) |n| alloc.free(n);

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
                        if (gen_module_name) |n| alloc.free(n);
                        imp_mod = try alloc.dupe(u8, value);
                        gen_module_name = try createModuleName(alloc, imp_mod.?);
                    },
                    .named_module_import => {
                        const namespace = value;
                        try writer.print("    // {}: {s} as {s}\n", .{ .named_module_import, imp_mod.?, namespace });
                        // try writer.print("    const {s} = {s};\n\n", .{ namespace, gen_module_name });
                        try writer.print("    const {s} = {s}();\n\n", .{ namespace, gen_module_name.? });
                    },
                    .import_expose_capability => {
                        const capability = value;
                        try writer.print("    // {}: {s} from {s}\n", .{ .import_expose_capability, item.value.?, imp_mod.? });
                        try writer.print("    const {s} = {s}{s}{s};\n\n", .{ capability, gen_module_name.?, "_capability_", capability });
                    },
                    .import_expose_type => {
                        const typ = value;
                        try writer.print("    // {}: {s} from {s}\n", .{ .import_expose_type, item.value.?, imp_mod.? });
                        try writer.print("    const {s} = {s}{s}{s};\n\n", .{ typ, gen_module_name.?, "_type_", typ });
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

        // var lookup = std.StringArrayHashMapUnmanaged(Node).empty;
        // defer {
        //     for (lookup.keys()) |key| {
        //         alloc.free(key);
        //     }
        //     lookup.deinit(alloc);
        // }
        // fn generateCode(alloc: Allocator, node: Node) ![]const u8 {
        //     switch (node.kind().?) {
        //         else => return alloc.dupe(u8, "void 0"),
        //     }
        // }

        while (try decls.next(alloc)) |item| {
            switch (item.node.kind().?) {
                .function_declaration => if (item.value) |f| {
                    defer alloc.free(f);

                    if (item.node.childByFieldName("name")) |child| {
                        const name = try sapling.stringValue(alloc, child);
                        defer alloc.free(name);

                        // try lookup.put(alloc, name, item.node);
                        try writer.print("    // Decl found: {s}={}\n", .{ name, item.node.kind().? });

                        const params = sapling.queryNode(
                            item.node,
                            \\
                            \\ (function_parameter
                            \\   [
                            \\     (dont_care)
                            \\     (identifier)
                            \\   ]
                            \\ ) @params
                            \\
                            ,
                        );
                        defer params.deinit();

                        try writer.print("    function {s}(", .{name});
                        var i: usize = 0;
                        while (try params.next(alloc)) |param| {
                            defer if (param.value) |val| alloc.free(val);
                            if (i > 0) {
                                try writer.print(", ", .{});
                            }
                            if (std.mem.eql(u8, "_", param.value.?)) {
                                // Support multiple "dont_care"s by numbering them
                                try writer.print("{s}{}", .{ param.value.?, i });
                            } else {
                                try writer.print("{s}", .{param.value.?});
                            }
                            i += 1;
                        }
                        try writer.print(") {{\n", .{});

                        if (item.node.childByFieldName("body")) |body| {
                            try writer.print("      return (function ($ret) {{\n", .{});
                            try streamBlockInto(alloc, sapling, body, writer);
                            try writer.print(";\n        return $ret;\n", .{});
                            try writer.print("      }}(null));\n", .{});
                        } else unreachable;
                        try writer.print("    }}\n\n", .{});

                        if (is_app and std.mem.eql(u8, "main", name)) {
                            try writer.print(
                                \\    // Sneakily export application main entry point for later usage
                                \\    Object.defineProperty(__exports__, '__main__', {{ get() {{ return {s}; }}, configurable: false, enumerable: false }});
                                \\
                                \\
                            ,
                                .{name},
                            );
                        }
                    }
                },
                .let_declaration => if (item.value) |f| {
                    defer alloc.free(f);

                    if (item.node.childByFieldName("name")) |child| {
                        const name = try sapling.stringValue(alloc, child);
                        defer alloc.free(name);
                        // try lookup.put(alloc, name, item.node);
                        try writer.print("    // Decl found: {s}={}\n", .{ name, item.node.kind().? });
                        if (item.node.childByFieldName("body")) |body| {
                            try writer.print("    const {s} = (function ($ret) {{\n", .{name});
                            // if (body.childByFieldName("single_return")) |single| {
                            try streamBlockInto(alloc, sapling, body, writer);
                            try writer.print(";\n      return $ret;\n", .{});
                            try writer.print("    }}(null));\n\n", .{});
                        } else unreachable;
                    }
                },
                .custom_type_declaration, .record_declaration => if (item.value) |f| {
                    defer alloc.free(f);

                    if (item.node.childByFieldName("name")) |child| {
                        const name = try sapling.stringValue(alloc, child);
                        defer alloc.free(name);
                        // try lookup.put(alloc, name, item.node);
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
                    // try writer.print("    __exports__['{s}'] = {s};\n\n", .{ constant, constant });
                    try writer.print(
                        "    Object.defineProperty(__exports__, '{s}', {{ get() {{ return {s}; }}, configurable: false }});\n\n",
                        .{ constant, constant },
                    );
                },
                else => unreachable,
            }
        }
    }

    try writer.print("    return ({s}.$ = __exports__);\n", .{gen_prefix});
    try writer.print("  }}\n", .{});
    if (is_app) {
        try writer.print(
            \\
            \\  // Build the module graph and return application entrypoint
            \\  __$setup.produceMain = function () {{
            \\    return {s}().__main__;
            \\  }};
            \\
            \\
        ,
            .{gen_prefix},
        );
    }
    try writer.print("  // Module Body Close\n\n", .{});
}

fn streamBlockInto(alloc: Allocator, sapling: model.Sapling, node: Node, writer: anytype) error{ OutOfMemory, DiskQuota, FileTooBig, InputOutput, NoSpaceLeft, DeviceBusy, InvalidArgument, AccessDenied, BrokenPipe, SystemResources, OperationAborted, NotOpenForWriting, LockViolation, WouldBlock, ConnectionResetByPeer, ProcessNotFound, NoDevice, Unexpected }!void {
    // std.debug.print("streamBlockInto {}\n", .{node});
    var it = sapling.queryNodeWithOptions(
        node,
        \\
        \\ (block
        \\   [
        \\     (debug_print_expression) @dbgprint
        \\     (value_expression
        \\       [
        \\         (string_literal)
        \\         (int_literal)
        \\         (decimal_literal)
        \\       ] @val
        \\     )
        \\     (let_expression) @let
        \\   ]
        \\ )
        \\
    ,
        1,
    );
    var i: usize = 0;
    while (try it.next(alloc)) |item| {
        defer if (item.value) |val| alloc.free(val);
        if (i > 0) {
            try writer.print("; ", .{});
        }
        try streamNodeInto(alloc, sapling, item.node, item.value, writer);
        i += 1;
    }
}

fn streamNodeInto(alloc: Allocator, sapling: model.Sapling, node: Node, str: ?[]const u8, writer: anytype) !void {
    // std.debug.print("streamNodeInto {}\n", .{node});
    const kind = node.kind() orelse blk: {
        // FIXME: Nodes without kind()?
        break :blk .comment;
    };
    switch (kind) {
        .debug_print_expression => {
            try writer.print("$ret = console.log(", .{});
            if (node.childByFieldName("format")) |format| {
                const fmt_str = try sapling.stringValue(alloc, format);
                defer alloc.free(fmt_str);
                try writer.print("{s}", .{fmt_str});
            }
            if (node.childByFieldName("arguments")) |args| {
                try writer.print(", ", .{});
                try streamNodeInto(alloc, sapling, args, null, writer);
            }
            try writer.print(")", .{});
        },
        .string_literal => {
            try writer.print("$ret = {s}", .{str.?});
        },
        .int_literal => {
            try writer.print("$ret = {s}", .{str.?});
        },
        .decimal_literal => {
            try writer.print("$ret = {s}", .{str.?});
        },
        .let_expression => {
            if (node.childByFieldName("body")) |body| {
                if (node.childByFieldName("name")) |nameNode| {
                    const name = try sapling.stringValue(alloc, nameNode);
                    defer alloc.free(name);
                    try writer.print("const {s} = $ret = (function ($ret) {{ ", .{name});
                    try streamBlockInto(alloc, sapling, body, writer);
                    try writer.print(" ; return $ret; }}(null))", .{});
                } else unreachable;
            } else unreachable;
        },
        .record_expression => {
            var it = sapling.queryNode(node,
                \\
                \\ [
                \\   (record_expression_splat) @splat
                \\   (record_expression_entry) @entry
                \\ ]
                \\
            );
            try writer.print("{{", .{});
            while (try it.next(alloc)) |splat_or_entry| {
                defer if (splat_or_entry.value) |val| alloc.free(val);

                switch (splat_or_entry.node.kind().?) {
                    .record_expression_splat => {
                        try writer.print("{s}", .{splat_or_entry.value.?});
                    },
                    .record_expression_entry => {
                        try writer.print("/* TODO: record_expression_entry */", .{});
                    },
                    else => unreachable,
                }
            }
            try writer.print("}}", .{});
        },
        .call_expression => {
            if (node.childByFieldName("immediate_target")) |target| {
                const name = try sapling.stringValue(alloc, target);
                defer alloc.free(name);

                try writer.print("({s}(\n", .{name});
            } else if (node.childByFieldName("qualified")) |qualified| {
                const target = node.childByFieldName("target").?;
                const q = try sapling.stringValue(alloc, qualified);
                defer alloc.free(q);
                const t = try sapling.stringValue(alloc, target);
                defer alloc.free(t);

                try writer.print("({s}.{s}(\n", .{ q, t });
            } else unreachable;
            try writer.print("/* TODO: call_params */", .{});
            try writer.print("))\n", .{});
        },
        else => {
            try writer.print("/* TODO: {} */\n", .{kind});
        },
    }
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
