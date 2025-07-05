const std = @import("std");
const testing = std.testing;
const fs = std.fs;

const model = @import("canapea-common");
const TransportKind = model.TransportKind;

pub const FileTreatment = enum {
    unknown,
    preserve,
    overwrite,
};

pub const DirectoryTreatment = enum {
    unknown,
    mirror_directory_structure,
    flatten_into_target,
};

pub const FileEnvelope = struct {
    file: fs.File,
    relative_path: []const u8,

    const Self = @This();

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.file.close();
        allocator.free(self.relative_path);
    }
};

pub fn makeFileIterator(comptime Envelope: type) type {
    return struct {
        pub fn iterator(allocator: std.mem.Allocator, pattern: []const u8, base_directory: fs.Dir) !Iterator {
            var up: usize = 0;
            var i: usize = 0;
            search: for (pattern) |ch| {
                // Look for ../ relative path inside pattern
                if (ch == '.' and pattern.len > i and pattern[i + 1] == '.') {
                    up += 1;
                    i += 2 + 1; // Include path delimiter
                    continue :search;
                }
                break :search;
            }
            const adjusted_pattern = pattern[i..];

            var relative_path: []u8 = undefined;
            if (up == 0) {
                relative_path = try allocator.dupe(u8, ".");
            } else {
                const repeated = try repeat(allocator, "../", up);
                defer allocator.free(repeated);

                relative_path = try std.mem.join(
                    allocator,
                    "",
                    repeated,
                );
            }
            defer allocator.free(relative_path);
            const base_str_dir = try base_directory.realpathAlloc(allocator, relative_path);
            defer allocator.free(base_str_dir);

            // std.debug.print("base_directory: {s}\nrelative_path: {s}\n", .{ base_str_dir, relative_path });
            const paths = try glob(allocator, adjusted_pattern, base_str_dir);
            // defer {
            //     for (paths) |p| {
            //         allocator.free(p);
            //     }
            //     allocator.free(paths);
            // }

            if (paths.len == 0) {
                return error.NoMatchingFilesFound;
            }

            const relative_path_to_base_dir = try allocator.dupe(u8, relative_path);

            return .{
                .paths = paths,
                .base_dir = base_directory,
                .relative_path_to_base_dir = relative_path_to_base_dir,
            };
        }

        const Iterator = struct {
            index: usize = 0,
            paths: [][]const u8,
            base_dir: fs.Dir,
            relative_path_to_base_dir: []const u8,

            const Self = @This();

            pub fn deinit(self: Self, gpa: std.mem.Allocator) void {
                for (self.paths) |p| {
                    gpa.free(p);
                }
                gpa.free(self.paths);

                // self.base_dir.close();
                gpa.free(self.relative_path_to_base_dir);
            }

            /// Caller owns memory and needs to call .deinit()
            pub fn next(self: *Self, allocator: std.mem.Allocator) !?Envelope {
                if (self.index >= self.paths.len) {
                    return null;
                }

                const adjusted_path = self.paths[self.index];
                self.index += 1;

                // std.debug.print("....adjusted_path: {s}\n", .{adjusted_path});
                const sub_path = try std.fmt.allocPrint(
                    allocator,
                    "{s}{s}",
                    .{ self.relative_path_to_base_dir, adjusted_path },
                );
                // std.debug.print("....sub_path: {s}\n", .{sub_path});
                // defer allocator.free(sub_path);

                const file = try self.base_dir.openFile(sub_path, .{});
                // defer file.close();

                return Envelope{
                    .file = file,
                    .relative_path = sub_path,
                };
            }
        };
    };
}

/// Caller owns the memory.
fn repeat(allocator: std.mem.Allocator, slice: []const u8, num: usize) ![][]const u8 {
    var list = try std.ArrayListUnmanaged([]const u8).initCapacity(allocator, num);
    defer list.deinit(allocator);

    try list.appendNTimes(allocator, slice, num);
    return list.toOwnedSlice(allocator);
}

/// Searches the given `directory` recursively for files matching `pattern`.
/// The caller is responsible for freeing both the individual file names and the slice
pub fn glob(allocator: std.mem.Allocator, pattern: []const u8, directory: []const u8) ![][]const u8 {
    if (pattern.len == 0) {
        return error.PatternCannotBeEmpty;
    }
    if (directory.len == 0) {
        return error.DirectoryCannotBeEmpty;
    }

    var dir = switch (directory[0]) {
        '.' => try fs.cwd().openDir(directory, .{ .iterate = true }),
        else => try fs.openDirAbsolute(directory, .{ .iterate = true }),
    };
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var file_names = std.ArrayList([]const u8).init(allocator);
    errdefer file_names.deinit();

    // FIXME: Only walk directories that match the glob
    while (try walker.next()) |entry| {
        // std.debug.print("{s}?\n", .{entry.path});
        if (entry.kind == .file and match(pattern, entry.path)) {
            // std.debug.print("  match for {s} on {s}\n", .{ pattern, entry.path });
            try file_names.append(try allocator.dupe(u8, entry.path));
        }
    }

    return try file_names.toOwnedSlice();
}

fn match(pattern: []const u8, name: []const u8) bool {
    var pattern_i: usize = 0;
    var name_i: usize = 0;
    var next_pattern_i: usize = 0;
    var next_name_i: usize = 0;

    search: while (pattern_i < pattern.len or name_i < name.len) {
        if (pattern_i < pattern.len) {
            const ch = pattern[pattern_i];
            switch (ch) {
                '?' => {
                    if (name_i < name.len) {
                        pattern_i += 1;
                        name_i += 1;
                        continue :search;
                    }
                },
                '*' => {
                    next_pattern_i = pattern_i;
                    next_name_i = name_i + 1;
                    pattern_i += 1;
                    continue :search;
                },
                else => {
                    if (name_i < name.len and name[name_i] == ch) {
                        pattern_i += 1;
                        name_i += 1;
                        continue :search;
                    }
                },
            }
        }
        if (next_name_i > 0 and next_name_i <= name.len) {
            pattern_i = next_pattern_i;
            name_i = next_name_i;
            continue :search;
        }
        return false;
    }
    return true;
}

test "glob finds all .cnp files in ../parser/test/hightlight" {
    const allocator = testing.allocator;

    const found_files = try glob(allocator, "highlight/*.cnp", "../parser/test/");
    // std.debug.print("found_files: {s}", .{found_files});
    defer {
        for (found_files) |f| {
            allocator.free(f);
        }
        allocator.free(found_files);
    }

    const files = &[_][]const u8{ "highlight/application.cnp", "highlight/basic.cnp", "highlight/complex.cnp" };
    try testing.expect(found_files.len == files.len);

    var expected_files = try std.StringArrayHashMapUnmanaged([]const u8).init(allocator, files, files);
    defer expected_files.deinit(allocator);

    for (found_files) |actual| {
        // std.debug.print("glob check actual file {s}\n", .{actual});
        const expected = expected_files.get(actual).?;
        // std.debug.print("  expected {s}\n", .{expected});
        try testing.expectEqualStrings(expected, actual);
    }
}

const USAGE =
    \\Usage: canapea [command]
    \\
    \\Commands:
    \\  language-server     Launch the official Canapea language server
    \\  unstable            Unstable commands, do not use!
    \\
    \\Options:
    \\  --help              Show this usage hint
    \\
;
const USAGE_LSP =
    \\Usage: canapea language-server [options]
    \\
    \\Options:
    \\  --stdio             Use STDIO for client communication (default when no option is set)
    // \\  --pipe <name>       Use named UNIX pipe for client communication
    // \\  --socket <port>     TCP socket to use for client communication
    // \\  --host <name>       TCP hostname to use for client communication (default: 127.0.0.1)
    \\
;
const USAGE_UNSTABLE =
    \\Usage: canapea unstable [command]
    \\
    \\Commands:
    \\  codegen             Generate code from Canapea source matched by the given pattern and write the result to STDOUT
    \\  generate-ast-tests  Generates AST test data from Canapea source matched by the given pattern
    \\
;
const USAGE_UNSTABLE_CODEGEN =
    \\Usage: canapea unstable codegen <pattern> [options]
    \\  pattern             A glob pattern to match Canapea source files
    \\
    \\Options:
    \\  --target <name>     The codegen target [es5]
    \\
;
const USAGE_UNSTABLE_ASTGEN =
    \\Usage: canapea unstable generate-ast-tests <pattern> [options]
    \\  pattern             A glob pattern to match Canapea source files
    \\
    \\Options:
    \\  --target <dir>      The target directory to save the generated tests into
    // \\  --flatten           Saves all generated tests flat into a target directory instead of putting them beside the source files (default: false)
    // \\  --force             Forces existing files to be overwritten (default: false)
    \\
;

test "'cli' requires a program name" {
    const allocator = testing.allocator;
    const args: [0][]const u8 = .{};

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.exit_code = .err;
    try testing.expectEqual(expected, actual);
}

test "'cli' prints usage" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [1][]const u8 = .{cli};

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage;
    try testing.expectEqual(expected, actual);
}

test "'cli language-server' starts server with TransportKind stdio" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [2][]const u8 = .{ cli, "language-server" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .depends_on_cmd;
    expected.language_server.selected = .selected;
    expected.language_server.transport = .stdio;
    try testing.expectEqual(expected, actual);
}

test "'cli language-server --stdio' starts server with TransportKind stdio" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [3][]const u8 = .{ cli, "language-server", "--stdio" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .depends_on_cmd;
    expected.language_server.selected = .selected;
    expected.language_server.transport = .stdio;
    try testing.expectEqual(expected, actual);
}

test "'cli language-server --help' prints command usage" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [3][]const u8 = .{ cli, "language-server", "--help" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_lsp;
    expected.language_server.selected = .selected;
    try testing.expectEqual(expected, actual);
}

test "'cli unstable' prints command usage" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [2][]const u8 = .{ cli, "unstable" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_unstable;
    expected.unstable.selected = .selected;
    try testing.expectEqual(expected, actual);
}

test "'cli unstable --help' prints command usage" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [3][]const u8 = .{ cli, "unstable", "--help" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_unstable;
    expected.unstable.selected = .selected;
    try testing.expectEqual(expected, actual);
}

test "'cli unstable codegen' prints command usage" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [3][]const u8 = .{ cli, "unstable", "codegen" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_unstable_codegen;
    expected.unstable.selected = .selected;
    expected.unstable.codegen.selected = .selected;
    try testing.expectEqual(expected, actual);
}

test "'cli unstable codegen --help' prints command usage" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [4][]const u8 = .{ cli, "unstable", "codegen", "--help" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_unstable_codegen;
    expected.unstable.selected = .selected;
    expected.unstable.codegen.selected = .selected;
    try testing.expectEqual(expected, actual);
}

test "'cli unstable codegen --target es5' prints command usage, because it's missing <pattern>" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [5][]const u8 = .{ cli, "unstable", "codegen", "--target", "es5" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_unstable_codegen;
    expected.unstable.selected = .selected;
    expected.unstable.codegen.selected = .selected;
    expected.unstable.codegen.target = .es5;
    try testing.expectEqual(expected, actual);
}

test "'cli unstable codegen <pattern>' prints command usage, because it's missing --target" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [4][]const u8 = .{ cli, "unstable", "codegen", "\"*.cnp\"" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_unstable_codegen;
    expected.unstable.selected = .selected;
    expected.unstable.codegen.selected = .selected;
    expected.unstable.codegen.pattern = "\"*.cnp\"";
    try testing.expectEqual(expected, actual);
}

test "'cli unstable codegen --target es5 <pattern>' generates naive ECMAScript5 code from the files matched by <pattern>" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [6][]const u8 = .{ cli, "unstable", "codegen", "--target", "es5", "\"*.cnp\"" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .depends_on_cmd;
    expected.unstable.selected = .selected;
    expected.unstable.codegen.selected = .selected;
    expected.unstable.codegen.pattern = "\"*.cnp\"";
    expected.unstable.codegen.target = .es5;

    try testing.expectEqual(expected, actual);
}

test "'cli unstable generate-ast-tests' prints command usage" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [3][]const u8 = .{ cli, "unstable", "generate-ast-tests" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_unstable_astgen;
    expected.unstable.selected = .selected;
    expected.unstable.generate_ast_tests.selected = .selected;
    try testing.expectEqual(expected, actual);
}

test "'cli unstable generate-ast-tests --help' prints command usage" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [4][]const u8 = .{ cli, "unstable", "generate-ast-tests", "--help" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_unstable_astgen;
    expected.unstable.selected = .selected;
    expected.unstable.generate_ast_tests.selected = .selected;
    try testing.expectEqual(expected, actual);
}

test "'cli unstable generate-ast-tests <pattern>' prints command usage due to missing --target" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [4][]const u8 = .{ cli, "unstable", "generate-ast-tests", "\"*.cnp\"" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .usage_unstable_astgen;
    expected.unstable.selected = .selected;
    expected.unstable.generate_ast_tests.selected = .selected;
    expected.unstable.generate_ast_tests.pattern = "\"*.cnp\"";
    try testing.expectEqual(expected, actual);
}

test "'cli unstable generate-ast-tests --target target/dir \"*.cnp\"' runs ast test generator subcommand with glob pattern \"*.cnp\" and target directory \"target/dir\"" {
    const allocator = testing.allocator;
    const cli = "cli";
    var args: [6][]const u8 = .{ cli, "unstable", "generate-ast-tests", "--target", "target/dir", "\"*.cnp\"" };

    var actual = try parseCliArgs(allocator, &args);
    actual.deinit(allocator);
    // TODO: Actually check stderr/stdout?
    actual.stderr = null;
    actual.stdout = null;

    var expected = CliArgs.empty;
    expected.program_name = cli;
    expected.exit_code = .depends_on_cmd;
    expected.unstable.selected = .selected;
    expected.unstable.generate_ast_tests.selected = .selected;
    expected.unstable.generate_ast_tests.pattern = "\"*.cnp\"";
    expected.unstable.generate_ast_tests.target = "target/dir";
    expected.unstable.generate_ast_tests.directory_treatment = .flatten_into_target;
    expected.unstable.generate_ast_tests.file_treatment = .overwrite;
    try testing.expectEqual(expected, actual);
}

// TODO: Slice libcanapea into readonly/mutable (cqs)?
// FIXME: Move parsing logic into some namespace

// FIXME: Simplify arg parser?
// pub fn main() !void {
//     var gpa_impl: std.heap.GeneralPurposeAllocator(.{}) = .{};
//     const gpa = gpa_impl.allocator();

//     logging.setup(gpa);

//     const args = std.process.argsAlloc(gpa) catch fatal("oom\n", .{});
//     defer std.process.argsFree(gpa, args);

//     if (args.len < 2) fatalHelp();

//     const cmd = std.meta.stringToEnum(Command, args[1]) orelse {
//         std.debug.print("unrecognized subcommand: '{s}'\n\n", .{args[1]});
//         fatalHelp();
//     };

//     if (cmd == .lsp) lsp_mode = true;

//     _ = switch (cmd) {
//         .lsp => lsp_exe.run(gpa, args[2..]),
//         .fmt => fmt_exe.run(gpa, args[2..]),
//         .check => check_exe.run(gpa, args[2..]),
//         .convert => convert_exe.run(gpa, args[2..]),
//         .help => fatalHelp(),
//         else => std.debug.panic("TODO cmd={s}", .{@tagName(cmd)}),
//     } catch |err| fatal("unexpected error: {s}\n", .{@errorName(err)});
// }

// fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
//     std.debug.print(fmt, args);
//     std.process.exit(1);
// }

pub const CodegenTarget = enum {
    unknown,
    es5,
};

pub const CommandSelection = enum {
    selected,
    unselected,
};

pub const CliExitCode = enum(u8) {
    ok = 0,
    unknown = 1,
    err = 2,
    depends_on_cmd = 3,
    usage = 4,
    usage_lsp = 5,
    usage_unstable = 6,
    usage_unstable_astgen = 7,
    usage_unstable_codegen = 8,
};

pub const CliArgs = struct {
    exit_code: CliExitCode,
    program_name: ?[]const u8,
    stdout: ?[][]const u8,
    stderr: ?[][]const u8,
    language_server: struct {
        selected: CommandSelection,
        transport: TransportKind,
    },
    unstable: struct {
        selected: CommandSelection,
        codegen: struct {
            selected: CommandSelection,
            pattern: ?[]const u8,
            target: CodegenTarget,
        },
        generate_ast_tests: struct {
            selected: CommandSelection,
            pattern: ?[]const u8,
            target: ?[]const u8,
            directory_treatment: DirectoryTreatment,
            file_treatment: FileTreatment,
        },
    },

    pub fn deinit(self: CliArgs, allocator: std.mem.Allocator) void {
        if (self.stderr != null) {
            allocator.free(self.stderr.?);
        }
        if (self.stdout != null) {
            allocator.free(self.stdout.?);
        }
    }

    const empty: CliArgs = .{
        .exit_code = .unknown,
        .program_name = null,
        .stdout = null,
        .stderr = null,
        .language_server = .{
            .selected = .unselected,
            .transport = .unknown,
        },
        .unstable = .{
            .selected = .unselected,
            .codegen = .{
                .selected = .unselected,
                .pattern = null,
                .target = .unknown,
            },
            .generate_ast_tests = .{
                .selected = .unselected,
                .pattern = null,
                .target = null,
                .directory_treatment = .unknown,
                .file_treatment = .unknown,
            },
        },
    };
};

pub fn parseCliArgs(allocator: std.mem.Allocator, args: [][]const u8) !CliArgs {
    // // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("zig-cli:root.zig:parseCliArgs(...) {s}\n", .{"blubb"});

    var parsed: CliArgs = .empty;
    var stdout = std.ArrayList([]const u8).init(allocator);
    defer stdout.deinit();

    var stderr = std.ArrayList([]const u8).init(allocator);
    defer stderr.deinit();

    if (args.len < 1) {
        // Should never happen but you never know
        try stderr.append(std.fmt.comptimePrint("no program name found\n", .{}));
        parsed.exit_code = .err;
    } else if (args.len < 2) {
        // CLI root
        parsed.program_name = args[0];
        try stderr.append(std.fmt.comptimePrint(USAGE, .{}));
        parsed.exit_code = .usage;
    } else if (args.len >= 2) {
        // Cmds
        parsed.program_name = args[0];
        parsed.exit_code = .usage;
        const cmd = args[1];
        const cmd_args = args[2..];

        // TODO: build
        // TODO: install
        // TODO: format
        // TODO: version
        if (std.mem.eql(u8, "language-server", cmd)) {
            // language-server
            parsed.language_server.selected = .selected;
            parsed.exit_code = .usage_lsp;
            if (cmd_args.len == 0 or std.mem.eql(u8, "--stdio", cmd_args[0])) {
                // language-server --stdio (default)
                parsed.language_server.transport = .stdio;
                parsed.exit_code = .depends_on_cmd;
            } else if (std.mem.eql(u8, "--help", cmd_args[0])) {
                // language-server --help
                try stderr.append(std.fmt.comptimePrint(USAGE_LSP, .{}));
            } else {
                // TODO: language-server --pipe <name>
                // TODO: language-server --socket <port> --host <name>
                try stderr.append(std.fmt.comptimePrint(USAGE_LSP, .{}));
            }
        } else if (std.mem.eql(u8, "unstable", cmd)) {
            // unstable
            parsed.unstable.selected = .selected;
            parsed.exit_code = .usage_unstable;
            if (cmd_args.len == 0 or std.mem.eql(u8, "--help", cmd_args[0])) {
                // unstable --help (default)
                try stderr.append(std.fmt.comptimePrint(USAGE_UNSTABLE, .{}));
            } else if (cmd_args.len >= 1) {
                const subcmd = cmd_args[0];
                const subcmd_args = cmd_args[1..];
                if (std.mem.eql(u8, "codegen", subcmd)) {
                    parsed.unstable.codegen.selected = .selected;
                    parsed.exit_code = .usage_unstable_codegen;
                    if (subcmd_args.len == 0 or std.mem.eql(u8, "--help", subcmd_args[0])) {
                        // unstable codegen --help (default)
                        try stderr.append(std.fmt.comptimePrint(USAGE_UNSTABLE_CODEGEN, .{}));
                    } else {
                        var i: usize = 0;
                        while (i < subcmd_args.len) : (i += 1) {
                            const arg = subcmd_args[i];
                            if (std.mem.eql(u8, "--target", arg)) {
                                if (subcmd_args.len >= i + 1 and std.mem.eql(u8, "es5", subcmd_args[i + 1])) {
                                    parsed.unstable.codegen.target = .es5;
                                    i += 1;
                                }
                            } else {
                                parsed.unstable.codegen.pattern = arg;
                            }
                        }

                        if (parsed.unstable.codegen.target != .unknown and parsed.unstable.codegen.pattern != null) {
                            parsed.exit_code = .depends_on_cmd;
                        } else {
                            try stderr.append(std.fmt.comptimePrint(USAGE_UNSTABLE_CODEGEN, .{}));
                        }
                    }
                } else if (std.mem.eql(u8, "generate-ast-tests", subcmd)) {
                    parsed.unstable.generate_ast_tests.selected = .selected;
                    parsed.exit_code = .usage_unstable_astgen;
                    if (subcmd_args.len == 0 or std.mem.eql(u8, "--help", subcmd_args[0])) {
                        // unstable generate-ast-tests --help (default)
                        try stderr.append(std.fmt.comptimePrint(USAGE_UNSTABLE_ASTGEN, .{}));
                    } else {
                        var i: usize = 0;
                        while (i < subcmd_args.len) : (i += 1) {
                            const arg = subcmd_args[i];
                            if (std.mem.eql(u8, "--target", arg)) {
                                if (subcmd_args.len >= i + 1) {
                                    parsed.unstable.generate_ast_tests.target = subcmd_args[i + 1];
                                    i += 1;
                                }
                            } else {
                                parsed.unstable.generate_ast_tests.pattern = arg;
                            }
                        }

                        if (parsed.unstable.generate_ast_tests.target != null and parsed.unstable.generate_ast_tests.pattern != null) {
                            parsed.exit_code = .depends_on_cmd;

                            // TODO: unstable generate-ast-tests --flatten
                            parsed.unstable.generate_ast_tests.directory_treatment = .flatten_into_target;
                            // TODO: unstable generate-ast-tests --force
                            parsed.unstable.generate_ast_tests.file_treatment = .overwrite;
                        } else {
                            try stderr.append(std.fmt.comptimePrint(USAGE_UNSTABLE_ASTGEN, .{}));
                        }
                    }
                } else {
                    try stderr.append(std.fmt.comptimePrint(USAGE_UNSTABLE, .{}));
                }
            }
        }
    }

    parsed.stdout = try stdout.toOwnedSlice();
    parsed.stderr = try stderr.toOwnedSlice();

    return parsed;
}
