// Big thanks to https://github.com/kristoff-it/ziggy

const std = @import("std");
const assert = std.debug.assert;

const lsp = @import("zig-lsp-kit");

const model = @import("canapea-common");

const TransportKind = model.TransportKind;
const TransportKindTag = model.TranpsortKindTag;

const types = lsp.types;
const offsets = lsp.offsets;
const ResultType = lsp.server.ResultType;
const Message = lsp.server.Message;

const log = std.log.scoped(.canapea_lsp);

const LanguageServer = lsp.server.Server(Handler);

pub fn run(gpa: std.mem.Allocator, transport_kind: TransportKind) !void {
    if (transport_kind != .stdio) {
        // FIXME: Support TransportKinds other than STDIO
        unreachable;
    }

    log.debug("Canapea Language Server started!", .{});

    var transport = lsp.Transport.init(
        std.io.getStdIn().reader(),
        std.io.getStdOut().writer(),
    );
    transport.message_tracing = false;

    var server: LanguageServer = undefined;
    var handler: Handler = .{
        .gpa = gpa,
        // .parser = parser,
        .server = &server,
    };
    server = try LanguageServer.init(gpa, &transport, &handler);

    try server.loop();
}

const Document = struct {
    const Self = @This();

    pub fn deinit(_: Self) void {}
};

pub const Handler = struct {
    gpa: std.mem.Allocator,
    server: *LanguageServer,
    // parser: *ts.Parser,
    files: std.StringHashMapUnmanaged(Handler.File) = .{},

    const SupportedLanguage = enum { canapea, cnp };
    const File = union(SupportedLanguage) {
        canapea: Document,
        cnp: Document,
        // ziggy: Document,
        // ziggy_schema: Schema,
        // supermd: Document,

        pub fn deinit(f: *File) void {
            switch (f.*) {
                inline else => |*x| x.deinit(),
            }
        }
        // // Clamps the returned value to code.len
        // pub fn offsetFromPosition(f: File, line: u32, col: u32) u32 {
        //     const code = switch (f) {
        //         inline else => |d| d.bytes,
        //     };

        //     var count: u32 = 0;
        //     var idx: u32 = 0;
        //     while (count < line) : (idx += 1) {
        //         if (code[idx] == '\n') {
        //             count += 1;
        //         }
        //     }

        //     return @min(code.len, idx + col);
        // }
    };

    pub fn initialize(
        self: Handler,
        _: std.mem.Allocator,
        request: types.InitializeParams,
        offset_encoding: offsets.Encoding,
    ) !lsp.types.InitializeResult {
        _ = self;

        if (request.clientInfo) |clientInfo| {
            log.info("client is '{s}-{s}'", .{ clientInfo.name, clientInfo.version orelse "<no version>" });
        }

        // FIXME: Get language-server version from module metadata
        return .{
            .serverInfo = .{
                .name = "Canapea Language Server",
                .version = "0.0.0",
            },
            .capabilities = .{
                .positionEncoding = switch (offset_encoding) {
                    .@"utf-8" => .@"utf-8",
                    .@"utf-16" => .@"utf-16",
                    .@"utf-32" => .@"utf-32",
                },
                .textDocumentSync = .{
                    .TextDocumentSyncOptions = .{
                        .openClose = true,
                        // FIXME: TextDocumentSyncKind.Incremental
                        .change = .Full,
                        .save = .{ .bool = true },
                    },
                },
                // .completionProvider = .{
                //     .triggerCharacters = &[_][]const u8{ ".", ":", "@", "\"" },
                // },
                // .hoverProvider = .{ .bool = true },
                // .definitionProvider = .{ .bool = true },
                // .referencesProvider = .{ .bool = true },
                // .documentFormattingProvider = .{ .bool = true },
                // .semanticTokensProvider = .{
                //     .SemanticTokensOptions = .{
                //         .full = .{ .bool = true },
                //         .legend = .{
                //             .tokenTypes = std.meta.fieldNames(types.SemanticTokenTypes),
                //             .tokenModifiers = std.meta.fieldNames(types.SemanticTokenModifiers),
                //         },
                //     },
                // },
                // .inlayHintProvider = .{ .bool = true },
            },
        };
    }

    pub fn initialized(
        self: Handler,
        _: std.mem.Allocator,
        notification: types.InitializedParams,
    ) !void {
        _ = self;
        _ = notification;
    }

    pub fn shutdown(
        _: Handler,
        _: std.mem.Allocator,
        notification: void,
    ) !?void {
        _ = notification;
    }

    pub fn documentSymbol(
        _: Handler,
        _: std.mem.Allocator,
        _: types.DocumentSymbolParams,
    ) !ResultType("textDocument/documentSymbol") {
        return null;
    }

    pub fn exit(
        _: Handler,
        _: std.mem.Allocator,
        notification: void,
    ) !void {
        _ = notification;
    }

    pub fn openDocument(
        self: *Handler,
        arena: std.mem.Allocator,
        notification: types.DidOpenTextDocumentParams,
    ) !void {
        // FIXME: We informed the client that we only do full document syncs
        const new_text = try self.gpa.dupeZ(u8, notification.textDocument.text);
        errdefer self.gpa.free(new_text);

        const language_id = notification.textDocument.languageId;
        const language = std.meta.stringToEnum(Handler.SupportedLanguage, language_id) orelse {
            log.debug("unrecognized language id: '{s}'", .{language_id});
            return;
        };
        try self.loadFile(
            arena,
            new_text,
            notification.textDocument.uri,
            language,
        );
    }

    pub fn changeDocument(
        self: *Handler,
        arena: std.mem.Allocator,
        notification: types.DidChangeTextDocumentParams,
    ) !void {
        if (notification.contentChanges.len == 0) return;

        // We informed the client that we only do full document syncs
        const new_text = try self.gpa.dupeZ(u8, notification.contentChanges[notification.contentChanges.len - 1].literal_1.text);
        errdefer self.gpa.free(new_text);

        // TODO: this is a hack while we wait for actual incremental reloads
        const file = self.files.get(notification.textDocument.uri) orelse return;

        log.debug("LOAD FILE URI: {s}, file tag = {s}", .{
            notification.textDocument.uri,
            @tagName(file),
        });
        try self.loadFile(
            arena,
            new_text,
            notification.textDocument.uri,
            file,
        );
    }

    pub fn saveDocument(
        _: Handler,
        arena: std.mem.Allocator,
        notification: types.DidSaveTextDocumentParams,
    ) !void {
        _ = arena;
        _ = notification;
    }

    pub fn closeDocument(
        self: *Handler,
        _: std.mem.Allocator,
        notification: types.DidCloseTextDocumentParams,
    ) error{}!void {
        var kv = self.files.fetchRemove(notification.textDocument.uri) orelse return;
        self.gpa.free(kv.key);
        kv.value.deinit();
    }

    pub fn completion(
        _: Handler,
        arena: std.mem.Allocator,
        request: types.CompletionParams,
    ) !ResultType("textDocument/completion") {
        _ = arena;
        _ = request;
        return null;
        // const file = self.files.get(request.textDocument.uri) orelse return .{
        //     .CompletionList = types.CompletionList{
        //         .isIncomplete = false,
        //         .items = &.{},
        //     },
        // };
        // const offset = file.offsetFromPosition(
        //     request.position.line,
        //     request.position.character,
        // );

        // log.debug("completion at offset {}", .{offset});

        // switch (file) {
        //     .supermd, .ziggy => |z| {
        //         const ast = z.ast orelse return .{
        //             .CompletionList = types.CompletionList{
        //                 .isIncomplete = false,
        //                 .items = &.{},
        //             },
        //         };

        //         const ziggy_completion = ast.completionsForOffset(offset);

        //         const completions = try arena.alloc(
        //             types.CompletionItem,
        //             ziggy_completion.len,
        //         );

        //         for (completions, ziggy_completion) |*c, zc| {
        //             c.* = .{
        //                 .label = zc.name,
        //                 .labelDetails = .{ .detail = zc.type },
        //                 .kind = .Field,
        //                 .insertText = zc.snippet,
        //                 .insertTextFormat = .Snippet,
        //                 .documentation = .{
        //                     .MarkupContent = .{
        //                         .kind = .markdown,
        //                         .value = zc.desc,
        //                     },
        //                 },
        //             };
        //         }

        //         return .{
        //             .CompletionList = types.CompletionList{
        //                 .isIncomplete = false,
        //                 .items = completions,
        //             },
        //         };
        //     },
        //     .ziggy_schema => return .{
        //         .CompletionList = types.CompletionList{
        //             .isIncomplete = false,
        //             .items = &.{},
        //         },
        //     },
        // }
    }

    pub fn gotoDefinition(
        _: Handler,
        arena: std.mem.Allocator,
        request: types.DefinitionParams,
    ) !ResultType("textDocument/definition") {
        _ = arena;
        _ = request;
        return null;
        //     const file = self.files.get(request.textDocument.uri) orelse return null;
        //     if (file == .ziggy_schema) return null;

        //     return .{
        //         .Definition = types.Definition{
        //             .Location = .{
        //                 .uri = try std.fmt.allocPrint(arena, "{s}-schema", .{request.textDocument.uri}),
        //                 .range = .{
        //                     .start = .{ .line = 0, .character = 0 },
        //                     .end = .{ .line = 0, .character = 0 },
        //                 },
        //             },
        //         },
        //     };
    }

    pub fn hover(
        _: Handler,
        arena: std.mem.Allocator,
        request: types.HoverParams,
        offset_encoding: offsets.Encoding,
    ) !?types.Hover {
        _ = arena;
        _ = request;
        _ = offset_encoding;
        return null;
        //     _ = offset_encoding; // autofix
        //     _ = arena; // autofix

        //     const file = self.files.get(request.textDocument.uri) orelse return null;

        //     const doc = switch (file) {
        //         .supermd, .ziggy => |doc| doc,
        //         .ziggy_schema => return null,
        //     };

        //     const offset = file.offsetFromPosition(
        //         request.position.line,
        //         request.position.character,
        //     );
        //     log.debug("hover at offset {}", .{offset});

        //     const ast = doc.ast orelse return null;
        //     const h = ast.hoverForOffset(offset) orelse return null;

        //     return types.Hover{
        //         .contents = .{
        //             .MarkupContent = .{
        //                 .kind = .markdown,
        //                 .value = h,
        //             },
        //         },
        //     };
    }

    pub fn references(
        _: Handler,
        arena: std.mem.Allocator,
        request: types.ReferenceParams,
    ) !?[]types.Location {
        _ = arena;
        _ = request;
        return null;
    }

    pub fn formatting(
        _: Handler,
        arena: std.mem.Allocator,
        request: types.DocumentFormattingParams,
    ) !?[]types.TextEdit {
        _ = arena;
        _ = request;
        return null;
    }

    pub fn semanticTokensFull(
        _: Handler,
        arena: std.mem.Allocator,
        request: types.SemanticTokensParams,
    ) !?types.SemanticTokens {
        _ = arena;
        _ = request;
        return null;
    }

    pub fn inlayHint(
        _: Handler,
        arena: std.mem.Allocator,
        request: types.InlayHintParams,
    ) !?[]types.InlayHint {
        _ = arena;
        _ = request;
        return null;
    }

    /// Handle a reponse that we have received from the client.
    /// Doesn't usually happen unless we explicitly send a request to the client.
    pub fn response(self: Handler, _response: Message.Response) !void {
        _ = self;
        const id: []const u8 = switch (_response.id) {
            .string => |id| id,
            .number => |id| {
                log.warn("received response from client with id '{d}' that has no handler!", .{id});
                return;
            },
        };

        if (_response.data == .@"error") {
            const err = _response.data.@"error";
            log.err("Error response for '{s}': {}, {s}", .{ id, err.code, err.message });
            return;
        }

        log.warn("received response from client with id '{s}' that has no handler!", .{id});
    }

    // logic.zig

    pub fn loadFile(
        self: *Handler,
        arena: std.mem.Allocator,
        new_text: [:0]const u8,
        uri: []const u8,
        language: SupportedLanguage,
    ) !void {
        _ = arena;
        _ = new_text;
        _ = language;

        const res: lsp.types.PublishDiagnosticsParams = .{
            .uri = uri,
            .diagnostics = &.{},
        };

        // switch (language) {
        //     .ziggy_schema => {
        //         var sk = Schema.init(self.gpa, new_text);
        //         errdefer sk.deinit();

        //         const gop = try self.files.getOrPut(self.gpa, uri);
        //         errdefer _ = self.files.remove(uri);

        //         if (gop.found_existing) {
        //             gop.value_ptr.deinit();
        //         } else {
        //             gop.key_ptr.* = try self.gpa.dupe(u8, uri);
        //         }

        //         gop.value_ptr.* = .{ .ziggy_schema = sk };

        //         switch (sk.diagnostic.err) {
        //             .none => {},
        //             else => {
        //                 const msg = try std.fmt.allocPrint(arena, "{lsp}", .{sk.diagnostic});
        //                 const sel = sk.diagnostic.tok.loc.getSelection(sk.bytes);
        //                 res.diagnostics = &.{
        //                     .{
        //                         .range = .{
        //                             .start = .{
        //                                 .line = sel.start.line - 1,
        //                                 .character = sel.start.col - 1,
        //                             },
        //                             .end = .{
        //                                 .line = sel.end.line - 1,
        //                                 .character = sel.end.col - 1,
        //                             },
        //                         },
        //                         .severity = .Error,
        //                         .message = msg,
        //                     },
        //                 };
        //             },
        //         }
        //     },
        //     .supermd, .ziggy => {
        //         const schema = try schemaForZiggy(self, arena, uri);

        //         var doc = try Document.init(
        //             self.gpa,
        //             new_text,
        //             language == .supermd,
        //             schema,
        //         );
        //         errdefer doc.deinit();

        //         log.debug("document init", .{});

        //         const gop = try self.files.getOrPut(self.gpa, uri);
        //         errdefer _ = self.files.remove(uri);

        //         if (gop.found_existing) {
        //             gop.value_ptr.deinit();
        //         } else {
        //             gop.key_ptr.* = try self.gpa.dupe(u8, uri);
        //         }

        //         gop.value_ptr.* = switch (language) {
        //             else => unreachable,
        //             .supermd => .{ .supermd = doc },
        //             .ziggy => .{ .ziggy = doc },
        //         };

        //         log.debug("sending {} diagnostic errors", .{doc.diagnostic.errors.items.len});

        //         const diags = try arena.alloc(lsp.types.Diagnostic, doc.diagnostic.errors.items.len);
        //         for (doc.diagnostic.errors.items, 0..) |e, idx| {
        //             const msg = try std.fmt.allocPrint(arena, "{lsp}", .{e.fmt(doc.bytes, null)});
        //             const sel = e.getErrorSelection();
        //             diags[idx] = .{
        //                 .range = .{
        //                     .start = .{
        //                         .line = sel.start.line - 1,
        //                         .character = sel.start.col - 1,
        //                     },
        //                     .end = .{
        //                         .line = sel.end.line - 1,
        //                         .character = sel.end.col - 1,
        //                     },
        //                 },
        //                 .severity = .Error,
        //                 .message = msg,
        //             };
        //         }

        //         res.diagnostics = diags;
        //     },
        // }
        log.debug("sending diags!", .{});
        const msg = try self.server.sendToClientNotification(
            "textDocument/publishDiagnostics",
            res,
        );

        defer self.gpa.free(msg);
    }
};

// const log = std.log.scoped(.canapea_lsp);

// pub fn schemaForZiggy(self: *Handler, arena: std.mem.Allocator, uri: []const u8) !?Schema {
//     const path = try std.fmt.allocPrint(arena, "{s}-schema", .{uri["file://".len..]});
//     log.debug("trying to find schema at '{s}'", .{path});
//     const result = self.files.get(path) orelse {
//         const bytes = std.fs.cwd().readFileAllocOptions(
//             self.gpa,
//             path,
//             ziggy.max_size,
//             null,
//             1,
//             0,
//         ) catch return null;
//         log.debug("schema loaded", .{});
//         var schema = Schema.init(self.gpa, bytes);
//         errdefer schema.deinit();

//         const gpa_path = try self.gpa.dupe(u8, path);
//         errdefer self.gpa.free(gpa_path);

//         try self.files.putNoClobber(
//             self.gpa,
//             gpa_path,
//             .{ .ziggy_schema = schema },
//         );
//         return schema;
//     };

//     if (result == .ziggy_schema) return result.ziggy_schema;
//     return null;
// }
