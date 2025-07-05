const std = @import("std");
const fs = std.fs;
const testing = std.testing;

const model = @import("canapea-common");
const defaults = model.defaults;
const cli_util = @import("./cli_util.zig");

const DirectoryTreatment = cli_util.DirectoryTreatment;
const FileEnvelope = cli_util.FileEnvelope;
const FileIterator = cli_util.makeFileIterator(FileEnvelope).iterator;
const FileTreatment = cli_util.FileTreatment;
const Sapling = model.Sapling;

pub fn generateAstTests(allocator: std.mem.Allocator, pattern: []const u8, base_directory: fs.Dir, target: fs.Dir, directory_treatment: DirectoryTreatment, file_treatment: FileTreatment) !void {
    var iter = try FileIterator(allocator, pattern, base_directory);
    defer iter.deinit(allocator);

    while (try iter.next(allocator)) |it| {
        defer it.deinit(allocator);

        const code = try it.file.readToEndAlloc(allocator, defaults.MAX_FILE_SIZE_BYTES);
        defer allocator.free(code);

        const sapling = try Sapling.fromFragment(code);
        defer sapling.deinit();

        const sexpr = try sapling.toSexpr(allocator);
        defer allocator.free(sexpr);

        const target_file_name = try allocator.dupe(u8, it.relative_path);
        defer allocator.free(target_file_name);
        normalizeFlatPathInPlace(u8, target_file_name[0..]);

        const ast_file_name = try std.fmt.allocPrint(
            allocator,
            "{s}.ast.txt",
            .{target_file_name},
        );

        const flags: fs.File.CreateFlags = .{
            .truncate = file_treatment == .overwrite,
        };
        const target_file = try target.createFile(ast_file_name, flags);
        defer target_file.close();

        if (directory_treatment != .flatten_into_target) {
            return error.NotImplemented;
        }

        try target_file.writeAll(sexpr);
    }
}

fn normalizeFlatPathInPlace(comptime T: type, slice: []T) void {
    const replacement = '_';
    for (slice) |*e| {
        const ch = e.*;
        e.* = switch (ch) {
            'A'...'Z' => ch,
            'a'...'z' => ch,
            '0'...'9' => ch,
            '-' => ch,
            else => replacement,
        };
        // if (e.* == '.')
        //     e.* = replacement;
    }
}
