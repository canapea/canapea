const std = @import("std");
const fs = std.fs;
const builtin = @import("builtin");

const canapea = @import("canapea");
const lsp = @import("canapea-language-server");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var arg_it = try std.process.argsWithAllocator(allocator);
    defer arg_it.deinit();

    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    while (arg_it.next()) |arg| {
        try list.append(try allocator.dupe(u8, arg));
    }

    const args = try list.toOwnedSlice();

    const parsed = try canapea.util.parseCliArgs(allocator, args);
    defer parsed.deinit(allocator);

    for (parsed.stderr.?) |err| {
        std.debug.print("{s}\n", .{err});
    }
    for (parsed.stdout.?) |line| {
        try std.io.getStdOut().writeAll(line);
    }

    if (parsed.exit_code == .depends_on_cmd) {
        if (parsed.language_server.selected == .selected) {
            // Arena Allocator isn't a good fit for our long running language server
            arena.deinit();

            // See https://ziglang.org/download/0.14.0/release-notes.html#SmpAllocator
            const gpa, const is_debug = gpa: {
                if (builtin.target.os.tag == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
                break :gpa switch (builtin.mode) {
                    .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
                    .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
                };
            };
            defer if (is_debug) {
                _ = debug_allocator.deinit();
            };

            try lsp.run(gpa, parsed.language_server.transport);
            return std.process.cleanExit();
        } else if (parsed.unstable.selected == .selected) {
            if (parsed.unstable.generate_ast_tests.selected == .selected) {
                const cmd_args = parsed.unstable.generate_ast_tests;

                const base_dir_name = try std.process.getCwdAlloc(allocator);
                defer allocator.free(base_dir_name);
                var base_dir = try fs.openDirAbsolute(base_dir_name, .{
                    .iterate = true,
                });
                defer base_dir.close();
                const abs_target_dir = switch (cmd_args.target.?[0]) {
                    '.' => try fs.path.join(allocator, &[_][]const u8{ base_dir_name, cmd_args.target.? }),
                    else => cmd_args.target.?,
                };
                var target_dir = try fs.openDirAbsolute(abs_target_dir, .{
                    .iterate = true,
                });
                defer target_dir.close();

                // std.debug.print("pattern: {s}, base: {s}, target: {s}\n", .{ cmd_args.pattern.?, base_dir_name, abs_target_dir });
                try canapea.unstable.generateAstTests(
                    allocator,
                    cmd_args.pattern.?,
                    base_dir,
                    target_dir,
                    .flatten_into_target,
                    .overwrite,
                );

                return std.process.cleanExit();
            } else if (parsed.unstable.codegen.selected == .selected) {
                const cmd_args = parsed.unstable.codegen;

                const base_dir_name = try std.process.getCwdAlloc(allocator);
                defer allocator.free(base_dir_name);
                var base_dir = try fs.openDirAbsolute(base_dir_name, .{
                    .iterate = true,
                });
                defer base_dir.close();

                switch (cmd_args.target) {
                    .es5 => {
                        try canapea.unstable.generateNaiveES5(
                            allocator,
                            cmd_args.pattern.?,
                            base_dir,
                            std.io.getStdOut().writer(),
                        );
                        return std.process.cleanExit();
                    },
                    else => unreachable,
                }
            } else {
                std.debug.print("TODO: run command {}\n", .{parsed});
            }
        } else {
            unreachable;
        }
    }
    std.process.exit(@intFromEnum(parsed.exit_code));
}
