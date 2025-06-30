const std = @import("std");
const builtin = @import("builtin");

const lsp = @import("lib");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    // See https://ziglang.org/download/0.14.0/release-notes.html#SmpAllocator
    const gpa, const is_debug = gpa: {
        if (builtin.target.os.tag == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    try lsp.run(gpa, .stdio);
}
