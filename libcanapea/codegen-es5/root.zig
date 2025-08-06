const std = @import("std");
const testing = std.testing;

const model = @import("canapea-common");
const CodeFragment = model.CodeFragment;
const Sapling = model.Sapling;
const Nursery = model.Nursery;

const Emitter = @import("./Emitter.zig");

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

test "using Canapea as a simple ECMAScript5 dialect: lib" {
    const allocator = testing.allocator;

    var list = try std.ArrayListUnmanaged(u8).initCapacity(
        allocator,
        INITIAL_GENERATED_LINES_CAPACITY,
    );
    defer list.deinit(allocator);

    var stream = std.io.multiWriter(.{
        std.io.getStdErr().writer(),
        list.writer(allocator),
    });

    const sap1 = try Sapling.fromFragment(
        @embedFile("./fixtures/app.cnp"),
    );
    defer sap1.deinit();
    const sap2 = try Sapling.fromFragment(
        @embedFile("./fixtures/app/lib.cnp"),
    );
    defer sap2.deinit();
    const sap3 = try Sapling.fromFragment(
        @embedFile("./fixtures/app/int.cnp"),
    );
    defer sap3.deinit();
    const sap4 = try Sapling.fromFragment(
        @embedFile("./fixtures/app/io.cnp"),
    );
    defer sap4.deinit();
    const sap5 = try Sapling.fromFragment(
        @embedFile("./fixtures/app/stdout.cnp"),
    );
    defer sap5.deinit();
    try generateNaiveES5(
        allocator,
        Nursery.from(&[5]Sapling{ sap1, sap2, sap3, sap4, sap5 }),
        stream.writer(),
    );

    const actual = try list.toOwnedSlice(allocator);
    defer allocator.free(actual);

    const expected = @embedFile("./fixtures/app.js");
    try testing.expectEqualSlices(u8, expected, actual);
}

test "using Canapea as a simple ECMAScript5 dialect: hello" {
    return error.SkipZigTest;
    // const allocator = testing.allocator;
    // var sapling = try Sapling.fromFragment(
    //     @embedFile("./fixtures/hello.cnp"),
    // );
    // defer sapling.deinit();
    // const expected = @embedFile("./fixtures/hello.js");

    // var list = try std.ArrayListUnmanaged(u8).initCapacity(
    //     allocator,
    //     INITIAL_GENERATED_LINES_CAPACITY,
    // );
    // defer list.deinit(allocator);

    // var stream = std.io.multiWriter(.{
    //     std.io.getStdErr().writer(),
    //     list.writer(allocator),
    // });

    // try generateNaiveES5(
    //     allocator,
    //     Nursery.from(&[1]Sapling{sapling}),
    //     stream.writer(),
    // );

    // const actual = try list.toOwnedSlice(allocator);
    // defer allocator.free(actual);

    // try testing.expectEqualSlices(u8, expected, actual);
}

test "Traversing Sapling tree structure smoketests" {
    var allocator = testing.allocator;
    var sapling = try Sapling.fromFragment(
        \\module "canapea::misc"
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
