const std = @import("std");
const testing = std.testing;

const model = @import("canapea-common");
const Emitter = @import("./Emitter.zig");

const CodeFragment = model.CodeFragment;
const Sapling = model.Sapling;
const Nursery = model.Nursery;

const Lines = [][]const u8;
const INITIAL_GENERATED_LINES_CAPACITY = 1024;

test {
    std.testing.refAllDecls(@This());
}

/// Caller owns the returned memory.
pub fn generateNaiveES5(allocator: std.mem.Allocator, nursery: Nursery, writer: anytype) !void {
    try Emitter.streamAllInto(
        allocator,
        nursery,
        writer,
    );
}

test "using Canapea as a simple ECMAScript5 dialect smoketests" {
    const allocator = testing.allocator;
    var sapling = try Sapling.fromFragment(
        \\module "canapea/misc"
        \\  exposing
        \\    | R
        \\    | T(..)
        \\    | constant
        \\    | fn
        \\
        \\type record R a =
        \\  { key : a
        \\  }
        \\
        \\type T a b =
        \\  | A a
        \\  | B a
        \\
        \\let constant = 42
        \\
        \\let fn x y z =
        \\  x
        \\
    );
    defer sapling.deinit();
    const expected =
        \\(function __canapea__(window, globalThis, undefined) {
        \\  'use strict';
        \\
        \\  // OpaqueCustomType: R
        \\  function __$$canapea_module$$__$_canapea_misc_$__R() { }
        \\
        \\  // CustomTypeWithConstructors: T
        \\  function __$$canapea_module$$__$_canapea_misc_$__T() { }
        \\
        \\  // Value: constant
        \\  const __$$canapea_module$$__$_canapea_misc_$__constant = null;
        \\
        \\  // Value: fn
        \\  const __$$canapea_module$$__$_canapea_misc_$__fn = null;
        \\
        \\}(self, typeof globalThis !== 'undefined' ? globalThis : self));
        \\
        \\
    ;

    var list = try std.ArrayListUnmanaged(u8).initCapacity(
        allocator,
        INITIAL_GENERATED_LINES_CAPACITY,
    );
    defer list.deinit(allocator);

    var stream = std.io.multiWriter(.{
        // std.io.getStdErr().writer(),
        list.writer(allocator),
    });

    try generateNaiveES5(
        allocator,
        Nursery.from(&[1]Sapling{sapling}),
        stream.writer(),
    );

    const actual = try list.toOwnedSlice(allocator);
    defer allocator.free(actual);

    try testing.expectEqualSlices(u8, expected, actual);
}

test "Traversing Sapling tree structure smoketests" {
    var allocator = testing.allocator;
    var sapling = try Sapling.fromFragment(
        \\module "canapea/misc"
        \\  exposing
        \\    | constant
        \\    | fn
        \\
        \\let constant = 42
        \\
        \\let fn x =
        \\  x
        \\
    );

    var iter = sapling.traverse();
    defer iter.deinit(allocator);

    // const tree = std.HashMapUnmanaged(*const anyopaque, comptime V: type, comptime Context: type, comptime max_load_percentage: u64)
    // const tree = std.AutoHashMapUnmanaged(*const anyopaque, comptime V: type)
    traversal: while (try iter.next(allocator)) |cursor| {
        const node = cursor.node();
        // node.id
        _ = node;
        const indent = try allocator.alloc(u8, cursor.depth() * 2);
        defer allocator.free(indent);
        // for (0..cursor.depth() * 2) |i| {
        //     indent[i] = ' ';
        // }
        // // // const is_leaf = node.childCount() == 0;
        // if (cursor.fieldName()) |name| {
        //     std.debug.print("{s}{s}: {s}\n", .{ indent, name, node.grammarKind() });
        // } else {
        //     std.debug.print("{s}{s}\n", .{ indent, node.grammarKind() });
        // }

        // if (try cursor.nodeConstruct(allocator)) |lines| {
        //     defer {
        //         for (lines) |line| {
        //             allocator.free(line);
        //         }
        //         allocator.free(lines);
        //     }

        //     const code = try std.mem.concat(allocator, u8, lines);
        //     defer allocator.free(code);

        //     std.debug.print("{s}", .{code});
        // }

        continue :traversal;
    }

    if (sapling.parse_tree.rootNode().hasError()) {
        return error.InvalidProgram;
    }
}
