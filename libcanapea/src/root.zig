const std = @import("std");
const fs = std.fs;
const crypto = std.crypto;
const testing = std.testing;

const es5codegen = @import("canapea-codegen-es5");
const sem = @import("canapea-semantic-analyzer");
const ast_tests = @import("./ast_tests.zig");
const cli_util = @import("./cli_util.zig");
pub const util = struct {
    pub const parseCliArgs = cli_util.parseCliArgs;
};
pub const unstable = struct {
    pub const generateAstTests = ast_tests.generateAstTests;
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
