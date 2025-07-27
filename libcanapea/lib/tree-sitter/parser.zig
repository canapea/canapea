const std = @import("std");

const Language = @import("./language.zig").Language;
const Node = @import("./node.zig").Node;
const Point = @import("./point.zig").Point;
const Range = @import("./range.zig").Range;
const InputEdit = @import("./tree.zig").InputEdit;
const Tree = @import("./tree.zig").Tree;

pub const Parser = struct {
    /// Create a new parser.
    pub fn create() *Parser {
        return ts_parser_new();
    }

    /// Destroy the parser, freeing all of the memory that it used.
    pub fn destroy(self: *Parser) void {
        ts_parser_delete(self);
    }

    /// Get the parser's current language.
    pub fn getLanguage(self: *const Parser) ?*const Language {
        return ts_parser_language(self);
    }

    /// Set the language that the parser should use for parsing.
    ///
    /// Returns an error if the language was not successfully assigned.
    /// The error means that the language was generated with an incompatible
    /// version of the Tree-sitter CLI.
    pub fn setLanguage(self: *Parser, language: ?*const Language) error{IncompatibleVersion}!void {
        if (!ts_parser_set_language(self, language)) {
            return error.IncompatibleVersion;
        }
    }

    /// Use the parser to parse some source code and create a syntax tree.
    ///
    /// If you are parsing this document for the first time, pass `null` for the
    /// `old_tree` parameter. Otherwise, if you have already parsed an earlier
    /// version of this document and the document has since been edited, pass the
    /// previous syntax tree so that the unchanged parts of it can be reused.
    /// This will save time and memory. For this to work correctly, you must have
    /// already edited the old syntax tree using the `Tree.edit()` function in a
    /// way that exactly matches the source code changes.
    ///
    /// This function returns a syntax tree on success, and `null` on failure. There
    /// are four possible reasons for failure:
    /// 1. The parser does not have a language assigned. Check for this using the
    ///    `Parser.getLanguage()` method.
    /// 2. Parsing was cancelled due to a timeout that was set by an earlier call to
    ///    the `Parser.setTimeoutMicros()` function. You can resume parsing from
    ///    where the parser left out by calling `Parser.parse()` again with the
    ///    same arguments. Or you can start parsing from scratch by first calling
    ///    `Parser.reset()`.
    /// 3. Parsing was cancelled using a cancellation flag that was set by an
    ///    earlier call to `Parser.setCancellationFlag()`. You can resume parsing
    ///    from where the parser left out by calling `Parser.parse()` again with
    ///    the same arguments.
    /// 4. Parsing was cancelled due to the progress callback returning true. This callback
    ///    is passed in `Parser.parseWithOptions()` inside the `Parser.Options` struct.
    pub fn parse(
        self: *Parser,
        input: Input,
        old_tree: ?*const Tree,
    ) ?*Tree {
        return ts_parser_parse(self, old_tree, input);
    }

    /// Use the parser to parse some source code and create a syntax tree, with some options.
    ///
    /// See `Parser.parse()` for more details.
    ///
    /// See `Parser.Options` for more details on the options.
    pub fn parseWithOptions(
        self: *Parser,
        input: Input,
        old_tree: ?*const Tree,
        options: Parser.Options,
    ) ?*Tree {
        return ts_parser_parse_with_options(self, old_tree, input, options);
    }

    /// Use the parser to parse some source code stored in one contiguous buffer.
    /// The first two parameters are the same as in the `Parser.parse()` function
    /// above. The second two parameters indicate the location of the buffer and its
    /// length in bytes.
    pub fn parseString(
        self: *Parser,
        string: []const u8,
        old_tree: ?*const Tree,
    ) ?*Tree {
        return ts_parser_parse_string_encoding(
            self,
            old_tree,
            string.ptr,
            @intCast(string.len),
            Input.Encoding.UTF_8,
        );
    }
};

/// A struct that specifies how to read input text.
pub const Input = extern struct {
    /// The encoding of source code.
    pub const Encoding = enum(c_uint) {
        UTF_8,
        UTF_16LE,
        UTF_16BE,
        Custom,
    };

    /// An arbitrary pointer that will be passed
    /// to each invocation of the `read` method.
    payload: ?*anyopaque,

    /// A function to retrieve a chunk of text at a given byte offset
    /// and (row, column) position. The function should return a pointer
    /// to the text and write its length to the `bytes_read` pointer.
    /// The parser does not take ownership of this buffer, it just borrows
    /// it until it has finished reading it. The function should write a `0`
    /// value to the `bytes_read` pointer to indicate the end of the document.
    read: *const fn (
        payload: ?*anyopaque,
        byte_index: u32,
        position: Point,
        bytes_read: *u32,
    ) callconv(.c) [*c]const u8,

    /// An indication of how the text is encoded.
    encoding: Input.Encoding = .UTF_8,

    // This function reads one code point from the given string, returning
    /// the number of bytes consumed. It should write the code point to
    /// the `code_point` pointer, or write `-1` if the input is invalid.
    decode: ?*const fn (
        string: [*c]const u8,
        length: u32,
        code_point: *i32,
    ) callconv(.c) u32 = null,
};

const Logger = struct {
    /// The type of a log message.
    pub const LogType = enum(c_uint) {
        Parse,
        Lex,
    };

    /// The payload of the function.
    payload: ?*anyopaque = null,

    /// The callback function.
    log: ?*const fn (
        payload: ?*anyopaque,
        log_type: LogType,
        buffer: [*:0]const u8,
    ) callconv(.C) void = null,
};

extern fn ts_parser_new() *Parser;
extern fn ts_parser_delete(self: *Parser) void;
extern fn ts_parser_language(self: *const Parser) ?*const Language;
extern fn ts_parser_set_language(self: *Parser, language: ?*const Language) bool;
extern fn ts_parser_set_included_ranges(self: *Parser, ranges: [*c]const Range, count: u32) bool;
extern fn ts_parser_included_ranges(self: *const Parser, count: *u32) [*c]const Range;
extern fn ts_parser_parse(self: *Parser, old_tree: ?*const Tree, input: Input) ?*Tree;
extern fn ts_parser_parse_with_options(
    self: *Parser,
    old_tree: ?*const Tree,
    input: Input,
    options: Parser.Options,
) ?*Tree;
// extern fn ts_parser_parse_string(self: *Parser, old_tree: ?*const Tree, string: [*c]const u8, length: u32) ?*Tree;
extern fn ts_parser_parse_string_encoding(
    self: *Parser,
    old_tree: ?*const Tree,
    string: [*c]const u8,
    length: u32,
    encoding: Input.Encoding,
) ?*Tree;
extern fn ts_parser_reset(self: *Parser) void;
extern fn ts_parser_set_timeout_micros(self: *Parser, timeout_micros: u64) void;
extern fn ts_parser_timeout_micros(self: *const Parser) u64;
extern fn ts_parser_set_cancellation_flag(self: *Parser, flag: ?*const usize) void;
extern fn ts_parser_cancellation_flag(self: *const Parser) ?*const usize;
extern fn ts_parser_set_logger(self: *Parser, logger: Logger) void;
extern fn ts_parser_logger(self: *const Parser) Logger;
extern fn ts_parser_print_dot_graphs(self: *Parser, fd: c_int) void;
