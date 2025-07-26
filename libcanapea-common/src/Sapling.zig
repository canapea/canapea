const std = @import("std");
const crypto = std.crypto;

const ts = @import("zig-tree-sitter");
extern fn tree_sitter_canapea() callconv(.c) *const ts.Language;

const SaplingCursor = @import("SaplingCursor.zig");
const iterators = @import("./iterators.zig");
const DepthFirstIterator = iterators.DepthFirstIterator;

pub const CodeFragment = []const u8;
pub const FileUri = []const u8;
pub const CodeDigest = []const u8;

const HASH_DIGEST_SIZE_BYTES = 32;

code_digest: CodeDigest,
file_uri: ?FileUri,
parse_tree: *ts.Tree,
language: *const ts.Language,
src_code: CodeFragment,

const Sapling = @This();

pub fn deinit(self: Sapling) void {
    self.parse_tree.destroy();
    self.language.destroy();
}

/// Caller owns the memory.
pub fn toCompactSexpr(self: Sapling, allocator: std.mem.Allocator) ![]const u8 {
    const root = self.parse_tree.rootNode();
    const sexpr = root.toSexp();
    defer ts.Node.freeSexp(sexpr);

    return try allocator.dupe(u8, sexpr);
}

/// Caller owns the memory.
pub fn toSexpr(self: Sapling, allocator: std.mem.Allocator) ![]const u8 {
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
        .language = parser.getLanguage().?,
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
    // parser.getLanguage().?.
    return .{
        .code_digest = codeDigestFrom(code),
        .file_uri = uri,
        .language = parser.getLanguage().?,
        .parse_tree = tree,
        .src_code = code,
    };
}

fn codeDigestFrom(code: CodeFragment) CodeDigest {
    var digest: [HASH_DIGEST_SIZE_BYTES]u8 = [_]u8{0} ** HASH_DIGEST_SIZE_BYTES;
    crypto.hash.sha2.Sha256.hash(code, &digest, .{});
    return &digest;
}

/// Caller is in charge to destroy the parser and language after use.
fn createParser() !*ts.Parser {
    const language = tree_sitter_canapea();

    const parser = ts.Parser.create();
    try parser.setLanguage(language);

    return parser;
}

/// Never mutate the cursor, .dupe() it. Caller needs to .deinit() the iterator
pub fn traverse(self: *Sapling) DepthFirstIterator(SaplingCursor) {
    // const code = try allocator.dupe(u8, self.src_code);
    const cursor = self.parse_tree.walk();
    // std.debug.print("{s}\n\n", .{cursor.node().toSexp()});
    return .{
        .cursor = .{
            .code = &self.src_code,
            .tree_cursor = cursor,
            .root_id = cursor.node().id,
        },
    };
}

pub const QueryIteratorItem = struct {
    pattern_index: u16,
    capture: ts.Query.Capture,
    value: ?[]const u8,
};

fn QueryIterator(comptime Cursor: type) type {
    return struct {
        sapling: Sapling,
        query: *ts.Query,
        cursor: Cursor,

        const Iter = @This();

        pub fn deinit(self: Iter) void {
            self.query.destroy();
            self.cursor.destroy();
        }

        /// Caller owns string memory, capture is immutable.
        pub fn next(self: Iter, allocator: std.mem.Allocator) !?QueryIteratorItem {
            if (self.cursor.nextMatch()) |match| {
                for (match.captures) |capture| {
                    const value = try self.sapling.nodeValue(allocator, capture.node);
                    defer if (value) |v| allocator.free(v);

                    const s = blk: {
                        if (value) |val| {
                            // std.debug.print("... {}: {?s}\n", .{ capture.index, value });
                            break :blk try allocator.dupe(u8, val);
                        }
                        break :blk null;
                    };
                    return .{
                        .pattern_index = match.pattern_index,
                        .capture = capture,
                        .value = s,
                    };
                }
            }
            return null;
        }
    };
}

pub fn queryNode(self: Sapling, node: ts.Node, source: []const u8) QueryIterator(*ts.QueryCursor) {
    var error_offset: u32 = 0;
    const q = ts.Query.create(self.language, source, &error_offset) catch |err|
        std.debug.panic("{s} error at position {d}", .{
            @errorName(err),
            error_offset,
        });

    var cursor = ts.QueryCursor.create();
    cursor.exec(q, node);

    return .{
        .sapling = self,
        .query = q,
        .cursor = cursor,
    };
}

pub fn queryRoot(self: Sapling, source: []const u8) QueryIterator(*ts.QueryCursor) {
    return self.queryNode(self.parse_tree.rootNode(), source);
}

/// Caller owns memory.
pub fn nodeValue(self: Sapling, allocator: std.mem.Allocator, node: ts.Node) !?[]const u8 {
    return self.extractSlice(allocator, node.startByte(), node.endByte());
}

/// Caller owns memory.
fn extractSlice(self: Sapling, allocator: std.mem.Allocator, start: ?u32, end: ?u32) !?[]const u8 {
    if (start) |s| {
        if (end) |e| {
            const c = try allocator.alloc(u8, e - s);
            for (0..c.len) |i| {
                c[i] = self.src_code[s + i];
            }
            return c;
        }
    }
    return null;
}
