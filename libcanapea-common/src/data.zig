const std = @import("std");
const Allocator = std.mem.Allocator;

const Sapling = @import("./Sapling.zig");

pub const Module = struct {
    name: []const u8,
    dev_namespace: ?[]const u8,
    exposing: ?[]const ModuleExport,
    docs: ?[][]const u8,

    const Self = @This();

    pub fn init(name: []const u8) Module {
        return .{
            .name = name,
            .dev_namespace = null,
            .exposing = null,
            .docs = null,
        };
    }

    // FIXME: Create intermediate representation of AST for codegen?
    pub fn from(allocator: std.mem.Allocator, sapling: Sapling) !u8 {
        const it = sapling.query(
            // \\(source_file) @it
            // \\  core_namespace: (_) @core_namespace
            // \\  name: (_) @name
            // \\    (module_export_opaque_type) @export-opaque-type
            // \\    (module_export_type_with_constructors) @export-type-with-constructors
            //
            // \\(development_module_declaration
            // \\  (module_export_list
            // \\    (module_export_value) @export-value
            // \\  )
            // \\)
            // \\(development_module_declaration
            // \\  core_namespace: (_) @core_namespace
            // \\)
            // \\(function_declaration name: (_) @function)
            // \\
            //
            // \\
            \\(function_declaration name: (_) @function)
            \\(let_expression name: (_) @binding)
            // \\
            // \\(development_module_declaration
            // \\  name: (_) @name
            // \\  core_namespace: (_) @core_namespace
            // \\)
        );
        defer it.deinit();
        var capture_count: u8 = 0;
        while (it.next()) |match| {
            // std.debug.print("match: {}\n", .{match});
            for (match.captures) |capture| {
                const value = try sapling.nodeValue(allocator, capture.node);
                defer if (value) |v| allocator.free(v);

                capture_count += 1;
                // std.debug.print("{}: {?s}\n", .{ capture.index, value });
            }
        }

        return capture_count;
    }

    pub fn deinit(self: Self, allocator: Allocator) void {
        allocator.free(self.name);
        if (self.dev_namespace) |ns| {
            allocator.free(ns);
        }
        if (self.exposing) |list| {
            for (list) |exp| {
                exp.deinit(allocator);
            }
            allocator.free(list);
        }
        if (self.docs) |docs| {
            allocator.free(docs);
        }
    }
};

pub const ModuleExportType = enum {
    export_constant,
    export_type,
};

pub const ModuleExport = struct {
    export_type: ModuleExportType,
    name: []const u8,
    type_constructors: ?[]const TypeConstructor,

    const Self = @This();

    pub fn exportConstant(name: []const u8) ModuleExport {
        return .{
            .export_type = .export_constant,
            .name = name,
            .type_constructors = null,
        };
    }

    pub fn exportType(name: []const u8) ModuleExport {
        return .{
            .export_type = .export_type,
            .name = name,
            .type_constructors = null,
        };
    }

    pub fn deinit(self: Self, allocator: Allocator) void {
        allocator.free(self.name);
        if (self.type_constructors) |ks| {
            for (ks) |k| {
                k.deinit(allocator);
            }
            allocator.free(ks);
        }
    }
};

pub const TypeConstructor = struct {
    name: []const u8,

    const Self = @This();

    pub fn deinit(self: Self, allocator: Allocator) void {
        allocator.free(self.name);
    }
};
