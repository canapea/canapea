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

pub const GrammarRule = generated.GrammarRule;

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

    pub const SaplingCursor = struct {
        code: *[]const u8,
        tree_cursor: ts.TreeCursor,
        visited: NodeVisitedById,

        pub fn destroy(self: *SaplingCursor, allocator: std.mem.Allocator) void {
            self.tree_cursor.destroy();
            self.visited.deinit(allocator);
        }

        pub fn isRoot(self: SaplingCursor) bool {
            return self.tree_cursor.node().parent() == null;
        }

        pub fn depth(self: SaplingCursor) u32 {
            return self.tree_cursor.depth();
        }

        pub fn node(self: SaplingCursor) ts.Node {
            return self.tree_cursor.node();
        }

        pub fn fieldName(self: SaplingCursor) ?[]const u8 {
            return self.tree_cursor.fieldName();
        }

        pub fn hasVisits(self: SaplingCursor) bool {
            return self.visited.size > 0;
        }

        pub fn hasVisitedCurrentNode(self: SaplingCursor) bool {
            return self.visited.contains(@intFromPtr(self.tree_cursor.node().id));
        }

        pub fn gotoFirstChild(self: *SaplingCursor) bool {
            return self.tree_cursor.gotoFirstChild();
        }

        pub fn gotoNextSibling(self: *SaplingCursor) bool {
            return self.tree_cursor.gotoNextSibling();
        }

        pub fn gotoParent(self: *SaplingCursor) bool {
            return self.tree_cursor.gotoParent();
        }

        pub fn markCurrentNodeVisited(self: *SaplingCursor, allocator: std.mem.Allocator) !void {
            const current = self.tree_cursor.node();
            const id: usize = @intFromPtr(current.id);
            try self.visited.put(allocator, id, {});
        }

        pub fn nodeRule(self: SaplingCursor) ?GrammarRule {
            const current = self.tree_cursor.node();
            return std.meta.stringToEnum(GrammarRule, current.grammarKind());
        }

        pub fn nodeConstruct(self: SaplingCursor, allocator: std.mem.Allocator) !void {
            // _ = allocator;
            const current = self.tree_cursor.node();
            const rule = self.nodeRule() orelse {
                // std.debug.print("{s}^---? (\"{s}\")\n", .{ node.grammarKind() });
                // continue :traversal;
                return;
            };
            switch (rule) {
                .development_module_declaration => {
                    std.debug.print("# {s}\n", .{current.grammarKind()});
                    // var cursor = self.tree_cursor.dupe();
                    // defer cursor.destroy();

                    // const field_id: u16 = @intCast(cursor.tree.getLanguage().fieldIdForName("name"));
                    // const list = try cursor.node().childrenByFieldId(
                    //     field_id,
                    //     &cursor,
                    //     allocator,
                    // );
                    // const list = try current.childrenByFieldName(
                    //     "name",
                    //     &curs,
                    //     allocator,
                    // );
                    // defer list.deinit();

                    // FIXME: This can't be the only way to get at the actual node content
                    var cursor = self.tree_cursor.dupe();
                    defer cursor.destroy();

                    var start: ?u32 = null;
                    var end: ?u32 = null;
                    if (cursor.gotoFirstChild()) {
                        if (cursor.fieldName()) |field_name| {
                            if (std.mem.eql(u8, "name", field_name)) {
                                if (start == null) {
                                    start = cursor.node().startByte();
                                } else {
                                    end = cursor.node().endByte();
                                }
                            }
                        }
                    }
                    while (cursor.gotoNextSibling()) {
                        if (cursor.fieldName()) |field_name| {
                            if (std.mem.eql(u8, "name", field_name)) {
                                if (start == null) {
                                    start = cursor.node().startByte();
                                } else {
                                    end = cursor.node().endByte();
                                }
                            }
                        }
                    }
                    if (start) |s| {
                        if (end) |e| {
                            const c = try allocator.alloc(u8, e - s);
                            defer allocator.free(c);

                            for (0..c.len) |i| {
                                c[i] = self.code.*[s + i];
                            }
                            std.debug.print("#   name: {s}\n", .{c});
                        }
                    }
                },
                else => {
                    // std.debug.print("# {s}\n", .{current.grammarKind()});
                },
            }
        }

        // pub fn nodeValue(self: SaplingCursor, allocator: std.mem.Allocator) []const u8 {
        //     const current = self.tree_cursor.node();
        //     current.
        // }
    };

    /// Never mutate the cursor. Caller needs to .deinit() the iterator
    pub fn traverse(self: *Self, allocator: std.mem.Allocator) DepthFirstIterator(SaplingCursor) {
        _ = allocator;
        // const code = try allocator.dupe(u8, self.src_code);
        const cursor = self.parse_tree.walk();
        const visited = NodeVisitedById.empty;
        // std.debug.print("{s}\n\n", .{cursor.node().toSexp()});
        return .{
            .cursor = .{
                .code = &self.src_code,
                .tree_cursor = cursor,
                .visited = visited,
            },
        };
    }

    fn DepthFirstIterator(comptime Cursor: type) type {
        return struct {
            cursor: Cursor,

            const Iter = @This();

            pub fn deinit(self: *Iter, allocator: std.mem.Allocator) void {
                self.cursor.destroy(allocator);
                // We don't own self.code so we don't free it
            }

            pub fn next(self: *Iter, allocator: std.mem.Allocator) !?*Cursor {
                var outcome: CandidateSearchOutcome = .unknown;

                if (!self.cursor.hasVisits() and self.cursor.isRoot()) {
                    // Unvisited root, no candidate search necessary
                    outcome = .initial_root_unvisited;
                } else {
                    outcome = search: while (true) {
                        const down = self.cursor.gotoFirstChild();
                        if (down and !self.cursor.hasVisitedCurrentNode()) {
                            break :search .first_child_unvisited;
                        }
                        lateral: while (true) {
                            const right = self.cursor.gotoNextSibling();
                            if (right and !self.cursor.hasVisitedCurrentNode()) {
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

                try self.cursor.markCurrentNodeVisited(allocator);

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
