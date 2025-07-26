const std = @import("std");
const Allocator = std.mem.Allocator;

const defaults = @import("./defaults.zig");
const Sapling = @import("./Sapling.zig");
const Node = Sapling.Node;

// TODO: Augmented AST

const Module = struct {
    name: ?[]const u8,
    privileged_namespace: ?[]const u8 = null,
    exposing: ?[]const ModuleExport = null,
    docs: ?[]const u8 = null,

    pub fn deinit(self: Module, allocator: Allocator) void {
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
};

const ModuleExportType = enum {
    export_constant,
    export_opaque_type,
    export_type,
};

const ModuleExport = struct {
    export_type: ModuleExportType,
    name: []const u8,
    type_constructors: ?[]const TypeConstructor,

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

    pub fn deinit(self: ModuleExport, allocator: Allocator) void {
        allocator.free(self.name);
        if (self.type_constructors) |constructors| {
            for (constructors) |c| {
                c.deinit(allocator);
            }
            allocator.free(constructors);
        }
    }
};

const TypeConstructor = struct {
    name: []const u8,

    pub fn deinit(self: TypeConstructor, allocator: Allocator) void {
        allocator.free(self.name);
    }
};
