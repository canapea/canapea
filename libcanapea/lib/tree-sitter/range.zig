const std = @import("std");

const Point = @import("./point.zig").Point;

/// A range of positions in a text document,
/// both in terms of bytes and of row-column points.
pub const Range = extern struct {
    start_point: Point = .{ .row = 0, .column = 0 },
    end_point: Point = .{ .row = 0xFFFFFFFF, .column = 0xFFFFFFFF },
    start_byte: u32 = 0,
    end_byte: u32 = 0xFFFFFFFF,
};
