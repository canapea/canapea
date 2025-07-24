const std = @import("std");
const testing = std.testing;

const ts = @import("zig-tree-sitter");
extern fn tree_sitter_canapea() callconv(.c) *const ts.Language;

const generated = @import("canapea-common-generated");

pub const defaults = @import("./defaults.zig");
pub const data = @import("./data.zig");

pub const Sapling = @import("./Sapling.zig");
pub const CodeFragment = Sapling.CodeFragment;
pub const SaplingCursor = @import("./SaplingCursor.zig");
pub const Nursery = @import("./Nursery.zig");

comptime {
    _ = generated;
}

test {
    std.testing.refAllDecls(@This());
}

test "zig-tree-sitter ABI compatibility with language parser" {
    try testing.expect(ts.MIN_COMPATIBLE_LANGUAGE_VERSION == 13);
    try testing.expect(ts.LANGUAGE_VERSION == 15);

    const language = tree_sitter_canapea();
    defer language.destroy();

    try testing.expect(language.abiVersion() == 15);
}

test "language parser can be loaded and works" {
    // Create a parser for the canapea language
    const language = tree_sitter_canapea();
    defer language.destroy();

    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(language);

    // Parse some source code and get the root node
    const unsafe_tree = parser.parseString(
        "module \n\nlet one = 1\n",
        null,
    );
    const tree = unsafe_tree.?;
    defer tree.destroy();

    const root = tree.rootNode();
    const end_point = root.endPoint();
    // std.debug.print("(source_file).endPoint() = {}", .{end_point});
    try testing.expect(std.mem.eql(u8, root.kind(), "source_file"));
    try testing.expect(end_point.cmp(.{ .row = 3, .column = 0 }) == .eq);
}

// TODO: Namespace language-server related types?
pub const TransportKindTag = enum {
    unknown,
    stdio,
    unix_socket,
    tcp_socket,
};
pub const TransportKind = union(TransportKindTag) {
    unknown: void,
    stdio: void,
    unix_socket: []const u8,
    tcp_socket: struct { []const u8, u16 },
};
