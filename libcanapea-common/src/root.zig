const std = @import("std");
const testing = std.testing;
const crypto = std.crypto;

pub const defaults = struct {
    pub const INITIAL_NURSERY_SIZE = 512;
    pub const MAX_FILE_SIZE_BYTES = 4096;
};

const ts = @import("zig-tree-sitter");
extern fn tree_sitter_canapea() callconv(.c) *const ts.Language;

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

pub const CodeFragment = []const u8;
pub const FileUri = []const u8;
pub const CodeDigest = []const u8;

const HASH_DIGEST_SIZE_BYTES = 32;

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

const NodeVisitedById = std.AutoHashMapUnmanaged(usize, void);

const CandidateSearchOutcome = enum {
    unknown,
    initial_root_unvisited,
    first_child_unvisited,
    next_sibling_unvisited,
    back_in_visited_root,
    next_sibling_visited,
};

pub const Sapling = struct {
    code_digest: CodeDigest,
    file_uri: ?FileUri,
    parse_tree: *ts.Tree,
    src_code: CodeFragment,

    const Self = @This();

    pub fn deinit(self: Self) void {
        self.parse_tree.destroy();
    }

    pub fn visit(self: Self) DepthFirstIterator(ts.TreeCursor) {
        var cursor = self.parse_tree.walk();
        std.debug.print("{s}\n\n", .{cursor.node().toSexp()});
        return .{
            .cursor = cursor,
            .visited = NodeVisitedById.empty,
        };
    }

    pub fn iter(self: Self, allocator: std.mem.Allocator) !void {
        var cursor = self.parse_tree.walk();
        defer cursor.destroy();

        var visited = NodeVisitedById.empty;
        defer visited.deinit(allocator);

        std.debug.print("{s}\n\n", .{cursor.node().toSexp()});
        var walking = true;
        loop: while (walking) : ({
            walking = search: while (true) {
                const down = cursor.gotoFirstChild();
                if (down and !visited.contains(@intFromPtr(cursor.node().id))) {
                    break :search true;
                }
                sub: while (true) {
                    const next = cursor.gotoNextSibling();
                    if (next and !visited.contains(@intFromPtr(cursor.node().id))) {
                        // Next sibling is free
                        break :search true;
                    }
                    if (!next) {
                        // const nid = cursor.node().id;
                        const up = cursor.gotoParent();
                        if (up) {
                            // FIXME: Continue nextSibling search after known node, no need to re-check all former siblings again
                            // const parent = cursor.node();
                            // const src_child = parent.
                            continue :sub;
                        } else {
                            // We're in root, we should be done.
                            break :search false;
                        }
                    }
                    if (next) {
                        // Next sibling has already been visited, we should be done.
                        break :search false;
                    }
                    // Check next sibling or parent with next iteration...
                    continue :sub;
                }
            };
        }) {
            const node = cursor.node();
            const id: usize = @intFromPtr(node.id);
            if (visited.contains(id)) {
                continue :loop;
            }
            try visited.put(allocator, id, {});

            const indent = try allocator.alloc(u8, cursor.depth() * 2);
            defer allocator.free(indent);
            for (0..cursor.depth() * 2) |i| {
                indent[i] = ' ';
            }
            if (cursor.fieldName()) |name| {
                std.debug.print("{s}{s}: {s}\n", .{ indent, name, node.grammarKind() });
            } else {
                std.debug.print("{s}{s}\n", .{ indent, node.grammarKind() });
            }

            // const is_leaf = node.childCount() == 0;
        }
    }

    /// Caller owns the memory.
    pub fn toCompactSexpr(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        const root = self.parse_tree.rootNode();
        const sexpr = root.toSexp();
        defer ts.Node.freeSexp(sexpr);

        return try allocator.dupe(u8, sexpr);
    }

    /// Caller owns the memory.
    pub fn toSexpr(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        // FIXME: Format SExpr from TreeSitter node, maybe via janet?
        return self.toCompactSexpr(allocator);
    }

    /// Caller needs to .deinit() themselves.
    pub fn fromFragment(code: CodeFragment) !Sapling {
        const parser = try createParser();
        defer parser.destroy();

        const unsafe_tree = parser.parseString(code, null);
        const tree = unsafe_tree.?;
        return .{
            .code_digest = codeDigestFrom(code),
            .file_uri = null,
            .parse_tree = tree,
            .src_code = code,
        };
    }

    /// Caller needs to .deinit() themselves.
    pub fn fromFragmentAndUri(code: CodeFragment, uri: FileUri) !Sapling {
        const parser = try createParser();
        defer parser.destroy();

        const unsafe_tree = parser.parseString(code, null);
        const tree = unsafe_tree.?;
        return .{
            .code_digest = codeDigestFrom(code),
            .file_uri = uri,
            .parse_tree = tree,
            .src_code = code,
        };
    }

    fn codeDigestFrom(code: CodeFragment) CodeDigest {
        var digest: [HASH_DIGEST_SIZE_BYTES]u8 = [_]u8{0} ** HASH_DIGEST_SIZE_BYTES;
        crypto.hash.sha2.Sha256.hash(code, &digest, .{});
        return &digest;
    }

    /// Caller is in charge to destroy the parser after use.
    fn createParser() !*ts.Parser {
        const language = tree_sitter_canapea();
        defer language.destroy();

        const parser = ts.Parser.create();
        try parser.setLanguage(language);

        return parser;
    }

    fn DepthFirstIterator(comptime Cursor: type) type {
        return struct {
            cursor: ts.TreeCursor,
            visited: NodeVisitedById,

            const Iter = @This();

            pub fn deinit(self: *Iter, allocator: std.mem.Allocator) void {
                self.cursor.destroy();
                self.visited.deinit(allocator);
            }

            pub fn next(self: Iter, allocator: std.mem.Allocator) !?Cursor {
                var visited = self.visited;
                var outcome: CandidateSearchOutcome = .unknown;

                if (visited.size == 0 and self.cursor.node().parent() == null) {
                    // Unvisited root, no candidate search necessary
                    outcome = .initial_root_unvisited;
                } else {
                    // Candidate search needs a mutable cursor
                    var cursor = self.cursor;
                    outcome = search: while (true) {
                        const down = cursor.gotoFirstChild();
                        if (down and !visited.contains(@intFromPtr(cursor.node().id))) {
                            // break :search true;
                            break :search .first_child_unvisited;
                        }
                        lateral: while (true) {
                            const right = cursor.gotoNextSibling();
                            if (right and !visited.contains(@intFromPtr(cursor.node().id))) {
                                // Next sibling is free
                                // break :search true;
                                break :search .next_sibling_unvisited;
                            }
                            if (!right) {
                                // const nid = cursor.node().id;
                                const up = cursor.gotoParent();
                                if (up) {
                                    // FIXME: Continue nextSibling search after known node, no need to re-check all former siblings again
                                    // const parent = cursor.node();
                                    // const src_child = parent.
                                    continue :lateral;
                                } else {
                                    // We're in root, we should be done.
                                    // break :search false;
                                    break :search .back_in_visited_root;
                                }
                            }
                            if (right) {
                                // Next sibling has already been visited, we should be done.
                                // break :search false;
                                break :search .next_sibling_visited;
                            }
                            // Check next sibling or parent with next iteration...
                            continue :lateral;
                        }
                    };
                }

                check_if_done: switch (outcome) {
                    .initial_root_unvisited, .first_child_unvisited, .next_sibling_unvisited => {
                        break :check_if_done;
                    },
                    .back_in_visited_root, .next_sibling_visited => {
                        return null;
                    },
                    else => unreachable,
                }

                // We're not done yet, cursor is immutable by this point
                const cursor = self.cursor;
                const node = cursor.node();
                const id: usize = @intFromPtr(node.id);
                if (visited.contains(id)) {
                    // continue :loop;
                    return null;
                }
                try visited.put(allocator, id, {});

                // const indent = try allocator.alloc(u8, cursor.depth() * 2);
                // defer allocator.free(indent);
                // for (0..cursor.depth() * 2) |i| {
                //     indent[i] = ' ';
                // }
                // if (cursor.fieldName()) |name| {
                //     std.debug.print("{s}{s}: {s}\n", .{ indent, name, node.grammarKind() });
                // } else {
                //     std.debug.print("{s}{s}\n", .{ indent, node.grammarKind() });
                // }

                // const is_leaf = node.childCount() == 0;
                return cursor;
            }
        };
    }
};

pub const Nursery = struct {
    saplings: []const Sapling,

    const Self = @This();

    const empty: Self = .{
        .saplings = [0]Sapling{},
    };

    // pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    //     allocator.free(self.saplings);
    // }

    pub fn from(saplings: []const Sapling) Nursery {
        return .{
            .saplings = saplings,
        };
    }

    pub fn iterator(self: Nursery) Iterator(Sapling) {
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
};
