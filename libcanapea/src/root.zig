const std = @import("std");
const fs = std.fs;
const testing = std.testing;

const model = @import("canapea-common");
const defaults = model.defaults;
const sem = @import("canapea-semantic-analyzer");
const codegen_es5 = @import("canapea-codegen-es5");
const ast_tests = @import("./ast_tests.zig");
const cli_util = @import("./cli_util.zig");

// FIXME: replace std.mem.cpy with for loops over slices

const DirectoryTreatment = cli_util.DirectoryTreatment;
const FileEnvelope = cli_util.FileEnvelope;
const FileIterator = cli_util.makeFileIterator(FileEnvelope).iterator;
const FileTreatment = cli_util.FileTreatment;
const Nursery = model.Nursery;
const Sapling = model.Sapling;

// TODO: Do we really want to expose libcanapea-common from libcanapea?
pub const common = model;
pub const util = struct {
    pub const parseCliArgs = cli_util.parseCliArgs;
};
pub const unstable = struct {
    pub const generateAstTests = ast_tests.generateAstTests;
    pub fn generateNaiveES5(allocator: std.mem.Allocator, pattern: []const u8, base_directory: fs.Dir, writer: anytype) !void {
        var iter = try FileIterator(allocator, pattern, base_directory);
        defer iter.deinit(allocator);

        var list = try std.ArrayListUnmanaged(Sapling).initCapacity(
            allocator,
            defaults.INITIAL_NURSERY_SIZE,
        );
        defer list.deinit(allocator);

        while (try iter.next(allocator)) |it| {
            defer it.deinit(allocator);

            const file = it.file;
            const relative_path: []const u8 = it.relative_path;

            const code = try file.readToEndAlloc(allocator, defaults.MAX_FILE_SIZE_BYTES);
            defer allocator.free(code);

            const uri = try base_directory.realpathAlloc(allocator, relative_path);

            const sapling = try Sapling.fromFragmentAndUri(code, uri);
            defer sapling.deinit();

            try list.append(allocator, sapling);
        }

        const nursery = Nursery.from(list.items);
        try codegen_es5.generateNaiveES5(allocator, nursery, writer);
    }
};

comptime {
    _ = sem;
}
test {
    std.testing.refAllDecls(@This());
}
