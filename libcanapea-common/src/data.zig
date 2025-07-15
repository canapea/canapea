const std = @import("std");
const Allocator = std.mem.Allocator;

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
