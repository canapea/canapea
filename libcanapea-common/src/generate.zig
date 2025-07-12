const std = @import("std");
const fs = std.fs;
const json = std.json;

const model = @import("canapea-common");
const defaults = model.defaults;

const runtime_log = std.log.scoped(.type_gen);

const StringBuilder = std.ArrayListUnmanaged([]const u8);
const INITIAL_GENERATED_LINES_CAPACITY = 1024;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arg_it = try std.process.argsWithAllocator(allocator);
    defer arg_it.deinit();

    var gen = Generator{
        .root = undefined,
        .target = undefined,
        .grammar = undefined,
        .node_types = undefined,
        .output_mode = .quiet,
    };

    var i: usize = 0;
    while (arg_it.next()) |arg| {
        try gen.readArg(allocator, arg, i);
        i += 1;
    }

    try gen.run(allocator);
}

fn readParserJsonArtifact(allocator: std.mem.Allocator, absolute_path: []const u8) !json.Value {
    const f = try fs.openFileAbsolute(absolute_path, .{});
    defer f.close();
    const s = try f.readToEndAlloc(allocator, defaults.MAX_PARSER_ARTIFACT_SIZE_BYTES);
    const value = try json.parseFromSliceLeaky(json.Value, allocator, s, .{});
    return value;
}

const Generator = struct {
    root: fs.Dir,
    target: fs.Dir,
    grammar: json.Value,
    node_types: json.Value,
    output_mode: OutputMode,

    const OutputMode = enum {
        quiet,
        verbose,
    };

    const Self = @This();

    pub fn readArg(self: *Self, allocator: std.mem.Allocator, arg: []const u8, index: usize) !void {
        // runtime_log.info("  arg[{}]: {s}\n", .{ i, arg });
        blk: switch (index) {
            0 => break :blk, // runtime_log.info("{s}\n", .{arg}), // <program name>
            1 => self.root = try fs.openDirAbsolute(arg, .{}),
            2 => self.target = try fs.openDirAbsolute(arg, .{}),
            3 => self.grammar = try readParserJsonArtifact(allocator, arg),
            4 => self.node_types = try readParserJsonArtifact(allocator, arg),
            5 => if (std.mem.eql(u8, arg, "--verbose")) {
                self.output_mode = .verbose;
            } else {
                unreachable;
            },
            else => unreachable,
        }
    }

    pub fn run(self: Self, allocator: std.mem.Allocator) !void {
        var types_file = try self.target.createFile(
            "types.zig",
            .{},
        );
        defer types_file.close();

        try types_file.writeAll(
            \\//! Generated code from internal parser artifacts
            \\//! DO NOT MODIFY BY HAND
            \\
            \\const std = @import("std");
            \\const testing = std.testing;
            \\
            \\test GrammarRule {
            \\    try testing.expect(1 == 1);
            \\}
            \\
        );

        self.log("Generating 'types.zig'...", .{});
        {
            var buf = types_file;
            try buf.writeAll("\n/// Generated from parser artifacts");
            try buf.writeAll("\nconst GrammarRule = enum {");

            const rules =
                self.grammar.object.get("rules").?.object;
            for (rules.keys()) |rule_name| {
                if (std.mem.eql(u8, "unreachable", rule_name)) {
                    try buf.writeAll("\n    @\"unreachable\",");
                } else {
                    const rule = try std.fmt.allocPrint(
                        allocator,
                        "\n    {s},",
                        .{rule_name},
                    );
                    defer allocator.free(rule);
                    try buf.writeAll(rule);
                }
            }

            try buf.writeAll("\n};");
            try buf.writeAll("\n");
        }
        self.log("done.", .{});
    }

    fn log(self: Self, comptime format: []const u8, args: anytype) void {
        if (self.output_mode == .quiet) {
            return;
        }

        runtime_log.info(format, args);
    }
};
