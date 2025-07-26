const std = @import("std");
const Allocator = std.mem.Allocator;

const ts = @import("zig-tree-sitter");

const defaults = @import("./defaults.zig");
const Sapling = @import("./Sapling.zig");

pub const Module = struct {
    name: ?[]const u8,
    privileged_namespace: ?[]const u8,
    exposing: ?[]const ModuleExport,
    docs: ?[][]const u8,

    const Self = @This();

    pub fn deinit(self: Self, allocator: Allocator) void {
        if (self.name) |name| {
            allocator.free(name);
        }
        if (self.privileged_namespace) |ns| {
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

    // FIXME: Create intermediate representation of AST for codegen?
    pub fn from(alloc: Allocator, sapling: Sapling) !Module {
        var maybe_module_signature: ?ts.Node = null;
        const name: ?[]const u8 = blk: {
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
                //     item.capture.node,
                // });
                maybe_module_signature = item.capture.node.parent();
                break :blk item.value;
            }
            break :blk null;
        };

        const module_exports = blk: {
            if (maybe_module_signature) |sig| {
                const it = sapling.queryNode(
                    sig,
                    \\ (module_export_value) @p0
                    \\ (module_export_opaque_type) @p1
                    \\ (module_export_type_with_constructors) @p2
                    ,
                );
                defer it.deinit();
                var exports = try std.ArrayListUnmanaged(ModuleExport).initCapacity(
                    alloc,
                    defaults.INITIAL_CODEGEN_PARSED_LIST_SIZE,
                );
                defer exports.deinit(alloc);

                while (try it.next(alloc)) |item| {
                    // defer if (item.value) |val| allocator.free(val);
                    // std.debug.print("match: id({}), val({?s}) in {}\n", .{
                    //     item.pattern_index,
                    //     item.value,
                    //     item.capture.node,
                    // });
                    switch (item.pattern_index) {
                        0 => if (item.value) |constant| {
                            try exports.append(alloc, ModuleExport.constant(constant));
                        },
                        1 => if (item.value) |type_name| {
                            try exports.append(alloc, ModuleExport.opaqueType(type_name));
                        },
                        2 => {
                            defer if (item.value) |val| alloc.free(val);

                            const node = item.capture.node;
                            if (node.childByFieldName("type")) |child| {
                                const type_name = try sapling.nodeValue(alloc, child);
                                // FIXME: Look for constructors of this type
                                try exports.append(
                                    alloc,
                                    ModuleExport.typeWithConstructors(type_name.?, &[0]TypeConstructor{}),
                                );
                            } else unreachable;
                        },
                        else => unreachable,
                    }
                }
                break :blk try exports.toOwnedSlice(alloc);
            } else break :blk &[0]ModuleExport{};
        };

        return .{
            .name = name,
            .privileged_namespace = null,
            .exposing = module_exports,
            .docs = null,
        };
    }
};

pub const ModuleExportType = enum {
    export_constant,
    export_opaque_type,
    export_type,
};

pub const ModuleExport = struct {
    export_type: ModuleExportType,
    name: []const u8,
    type_constructors: ?[]const TypeConstructor,

    const Self = @This();

    pub fn constant(name: []const u8) ModuleExport {
        return .{
            .export_type = .export_constant,
            .name = name,
            .type_constructors = null,
        };
    }

    pub fn opaqueType(name: []const u8) ModuleExport {
        return .{
            .export_type = .export_opaque_type,
            .name = name,
            .type_constructors = null,
        };
    }

    pub fn typeWithConstructors(name: []const u8, constructors: []const TypeConstructor) ModuleExport {
        return .{
            .export_type = .export_type,
            .name = name,
            .type_constructors = constructors,
        };
    }

    pub fn deinit(self: Self, allocator: Allocator) void {
        allocator.free(self.name);
        if (self.type_constructors) |constructors| {
            for (constructors) |c| {
                c.deinit(allocator);
            }
            allocator.free(constructors);
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
