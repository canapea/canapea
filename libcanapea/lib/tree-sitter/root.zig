/// The latest ABI version that is supported by the current version of the library.
///
/// The Tree-sitter library is generally backwards-compatible with
/// languages generated using older CLI versions, but is not forwards-compatible.
pub const LANGUAGE_VERSION = 15;

/// The earliest ABI version that is supported by the current version of the library.
pub const MIN_COMPATIBLE_LANGUAGE_VERSION = 13;

// pub const LookaheadIterator = @import("lookahead_iterator.zig").LookaheadIterator;

const language = @import("./language.zig");
pub const Language = language.Language;
pub const LanguageMetadata = language.LanguageMetadata;
const parser = @import("./parser.zig");
pub const Input = parser.Input;
pub const Logger = parser.Logger;
pub const Parser = parser.Parser;
const tree = @import("./tree.zig");
pub const InputEdit = tree.InputEdit;
pub const Tree = tree.Tree;
pub const Node = @import("node.zig").Node;
pub const Query = @import("query.zig").Query;
pub const QueryCursor = @import("query_cursor.zig").QueryCursor;
pub const set_allocator = @import("alloc.zig").ts_set_allocator;
const structs = @import("point.zig");
pub const Point = structs.Point;
pub const Range = structs.Range;
pub const TreeCursor = @import("tree_cursor.zig").TreeCursor;
