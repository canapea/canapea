const std = @import("std");
const StringBuilder = std.ArrayListUnmanaged([]const u8);

builder: StringBuilder,

const Self = @This();

pub const Slice = StringBuilder.Slice;

/// Initialize with capacity to hold num elements. The resulting capacity will equal num exactly. Deinitialize with deinit or use toOwnedSlice.
pub fn initCapacity(allocator: std.mem.Allocator, num: usize) !Self {
    return .{
        .builder = try StringBuilder.initCapacity(allocator, num),
    };
}

/// Release all allocated memory.
pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    self.builder.deinit(allocator);
}

/// Extend the list by 1 element. Allocates more memory as necessary. Invalidates element pointers if additional memory is needed.
pub fn append(self: *Self, allocator: std.mem.Allocator, item: []const u8) !void {
    try self.builder.append(allocator, item);
}

/// Extend the list by 1 element. Allocates more memory as necessary. Invalidates element pointers if additional memory is needed.
pub fn appendFormat(self: *Self, allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
    const s = try std.fmt.allocPrint(allocator, fmt, args);
    try self.builder.append(allocator, s);
}

/// The caller owns the returned memory. Empties this ArrayList. Its capacity is cleared, making deinit() safe but unnecessary to call.
pub fn toOwnedSlice(self: *Self, allocator: std.mem.Allocator) !Slice {
    return try self.builder.toOwnedSlice(allocator);
}
