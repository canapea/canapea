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
pub fn fromFragment(code: CodeFragment) !Self {
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
pub fn fromFragmentAndUri(code: CodeFragment, uri: FileUri) !Self {
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

/// Never mutate the cursor, .dupe() it. Caller needs to .deinit() the iterator
pub fn traverse(self: *Self) DepthFirstIterator(SaplingCursor) {
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
