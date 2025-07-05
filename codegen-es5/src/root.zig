const std = @import("std");
const StringBuilder = std.ArrayListUnmanaged([]const u8);
const fs = std.fs;
const testing = std.testing;

const model = @import("canapea-common");

const CodeFragment = model.CodeFragment;
const Sapling = model.Sapling;
const Nursery = model.Nursery;

const Lines = [][]const u8;
const INITIAL_GENERATED_LINES_CAPACITY = 1024;

/// Caller owns the returned memory.
pub fn generateNaiveES5(allocator: std.mem.Allocator, nursery: Nursery) !Lines {
    var out = try StringBuilder.initCapacity(
        allocator,
        INITIAL_GENERATED_LINES_CAPACITY,
    );
    defer out.deinit(allocator);

    try out.append(allocator, try allocator.dupe(
        u8,
        "(function __canapea__(window, globalThis, undefined) {",
    ));
    try out.append(allocator, try allocator.dupe(
        u8,
        "\"use strict\";",
    ));

    var it = nursery.iterator();
    while (it.next()) |sapling| {
        const uri = sapling.file_uri orelse "<anonymous>";
        // std.debug.print(":: {s}\n", uri);
        // std.debug.print("{s}\n\n", sapling.src_code);

        const line = try std.fmt.allocPrint(
            allocator,
            "// {s}",
            .{uri},
        );

        try out.append(allocator, line);
    }

    try out.append(allocator, try allocator.dupe(
        u8,
        "}(self, typeof globalThis !== 'undefined' ? globalThis : self));\n",
    ));

    return try out.toOwnedSlice(allocator);
}

test "using Canapea as a simple ECMAScript5 dialect" {
    const allocator = testing.allocator;

    const code = [_]CodeFragment{
        \\module
        \\
        \\let x = "x"
        ,
        \\module "acme/lib"
        \\  exposing
        \\    Type
        \\    identity
        \\    value
        \\
        \\type Type = Type
        \\
        \\function identity x =
        \\  x
        \\
        \\let value = "a value"
        ,
    };

    const nursery = Nursery.from(&[_]Sapling{
        try Sapling.fromFragment(code[0]),
        try Sapling.fromFragment(code[1]),
    });

    const lines = try generateNaiveES5(allocator, nursery);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    const actual = try std.mem.join(allocator, "\n", lines);
    defer allocator.free(actual);

    try testing.expectEqualStrings(
        \\(function __canapea__(window, globalThis, undefined) {
        \\"use strict";
        \\// <anonymous>
        \\// <anonymous>
        \\}(self, typeof globalThis !== 'undefined' ? globalThis : self));
        \\
    ,
        actual,
    );
}
