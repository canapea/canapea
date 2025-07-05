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
    pub fn generateNaiveES5(allocator: std.mem.Allocator, pattern: []const u8, base_directory: fs.Dir) ![][]const u8 {
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
        return try codegen_es5.generateNaiveES5(allocator, nursery);
    }
};

comptime {
    _ = sem;
}
test {
    std.testing.refAllDecls(@This());
}

const janetc = @cImport({
    @cInclude("janet.h");
});

test "janet has been embedded and hello world is working" {
    // FIXME: Use allocator to give the Janet VM memory
    // const allocator = testing.allocator;

    if (janetc.janet_init() != 0) {
        return error.JanetVmInitError;
    }
    defer janetc.janet_deinit();

    const env = janetc.janet_core_env(null).?;
    const hello: [:0]const u8 = "(print `Hello, Janet!`)";
    const sourcePath: [:0]const u8 = "main";
    if (janetc.janet_dostring(env, hello, sourcePath, null) != 0) {
        return error.JanetHelloError;
    }
}

// fn fatal(comptime format: []const u8, args: anytype) noreturn {
//     std.debug.print(format, args);
//     std.process.exit(1);
// }

// const Janet = opaque {};
// const JanetTable = opaque {};
// pub const JanetSignal = enum(c_int) {
//     ok = 0,
//     @"error" = 1,
//     debug = 2,
//     yield = 3,
//     user0 = 4,
//     user1 = 5,
//     user2 = 6,
//     user3 = 7,
//     user4 = 8,
//     user5 = 9,
//     user6 = 10,
//     user7 = 11,
//     user8 = 12,
//     user9 = 13,

//     pub const Error = error{
//         @"error",
//         debug,
//         yield,
//         user0,
//         user1,
//         user2,
//         user3,
//         user4,
//         user5,
//         user6,
//         user7,
//         user8,
//         user9,
//     };
// };
// extern fn janet_init() callconv(.c) JanetSignal; // JANET_API
// extern fn janet_deinit() callconv(.c) void; // JANET_API
// extern fn janet_core_env(replacements: ?*JanetTable) callconv(.c) ?*JanetTable;
// extern fn janet_dostring(env: ?*JanetTable, str: ?[*:0]const u8, sourcePath: ?[*:0]const u8, out: ?*Janet) callconv(.c) JanetSignal;
