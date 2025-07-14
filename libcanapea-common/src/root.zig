const std = @import("std");
const testing = std.testing;
const crypto = std.crypto;

pub const defaults = struct {
    pub const INITIAL_NURSERY_SIZE = 512;
    pub const MAX_FILE_SIZE_BYTES = 4096;
    pub const MAX_PARSER_ARTIFACT_SIZE_BYTES: comptime_int = 16 * 1024 * 1024;
};

const ts = @import("zig-tree-sitter");
extern fn tree_sitter_canapea() callconv(.c) *const ts.Language;

const generated = @import("canapea-common-generated");

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

    /// Never mutate the cursor. Caller needs to .deinit() the iterator
    pub fn traverse(self: Self) DepthFirstIterator(ts.TreeCursor) {
        const cursor = self.parse_tree.walk();
        const visited = NodeVisitedById.empty;
        // std.debug.print("{s}\n\n", .{cursor.node().toSexp()});
        return .{
            .cursor = cursor,
            .visited = visited,
        };
    }

    // TODO: Maybe we want our own cursor type instead of exposing the tree-sitter cursor
    fn DepthFirstIterator(comptime Cursor: type) type {
        return struct {
            count: usize = 0,
            cursor: Cursor,
            visited: NodeVisitedById,

            const Iter = @This();

            pub fn deinit(self: *Iter, allocator: std.mem.Allocator) void {
                self.cursor.destroy();
                self.visited.deinit(allocator);
            }

            pub fn next(self: *Iter, allocator: std.mem.Allocator) !?*Cursor {
                var outcome: CandidateSearchOutcome = .unknown;

                if (self.visited.size == 0 and self.cursor.node().parent() == null) {
                    // Unvisited root, no candidate search necessary
                    outcome = .initial_root_unvisited;
                } else {
                    outcome = search: while (true) {
                        const down = self.cursor.gotoFirstChild();
                        if (down and !self.visited.contains(@intFromPtr(self.cursor.node().id))) {
                            break :search .first_child_unvisited;
                        }
                        lateral: while (true) {
                            const right = self.cursor.gotoNextSibling();
                            if (right and !self.visited.contains(@intFromPtr(self.cursor.node().id))) {
                                break :search .next_sibling_unvisited;
                            }
                            if (!right) {
                                const up = self.cursor.gotoParent();
                                if (up) {
                                    // FIXME: Continue nextSibling search after known node, no need to re-check all former siblings again
                                    // const parent = cursor.node();
                                    // const src_child = parent.
                                    continue :lateral;
                                } else {
                                    // We're in root, we should be done.
                                    break :search .back_in_visited_root;
                                }
                            }
                            if (right) {
                                // Next sibling has already been visited, we should be done.
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

                const node = self.cursor.node();
                const id: usize = @intFromPtr(node.id);
                try self.visited.put(allocator, id, {});

                return &self.cursor;
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
