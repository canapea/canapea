const Sapling = @import("./Sapling.zig");

saplings: []const Sapling,

const Self = @This();

const empty: Self = .{
    .saplings = [0]Sapling{},
};

// pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
//     allocator.free(self.saplings);
// }

pub fn from(saplings: []const Sapling) Self {
    return .{
        .saplings = saplings,
    };
}

pub fn iterator(self: Self) Iterator(Sapling) {
    return .{
        .index = 0,
        .items = self.saplings,
    };
}

fn Iterator(comptime T: type) type {
    return struct {
        index: usize,
        items: []const T,

        const Iter = @This();

        pub fn next(self: *Iter) ?T {
            if (self.index < self.items.len) {
                const item = self.items[self.index];
                self.index += 1;
                return item;
            }
            return null;
        }
    };
}
