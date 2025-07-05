const std = @import("std");

pub fn build(b: *std.Build) void {
    const no_bin = b.option(
        bool,
        "no-bin",
        "skip emitting binary",
    ) orelse false;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Expose public module via b.addModule
    const lib_mod = b.addModule("canapea-language-server", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const canapea_common_dep = b.dependency("canapea_common", .{
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport(
        "canapea-common",
        canapea_common_dep.module("canapea-common"),
    );

    const zig_lsp_kit_mod = b.dependency("lsp_kit", .{
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("zig-lsp-kit", zig_lsp_kit_mod.module("lsp"));

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("lib", lib_mod);

    // const lib = b.addLibrary(.{
    //     .linkage = .static,
    //     .name = "canapea_language_server",
    //     .root_module = lib_mod,
    // });
    // FIXME: Why exactly can't I b.installArtifact or &lib_mod.step here without b.addLibrary?
    // if (no_bin) {
    //     b.getInstallStep().dependOn(&lib.step);
    // } else {
    //     b.installArtifact(lib);
    // }

    const exe = b.addExecutable(.{
        .name = "canapea_language_server_exe",
        .root_module = exe_mod,
    });
    if (no_bin) {
        b.getInstallStep().dependOn(&exe.step);
    } else {
        b.installArtifact(exe);
    }

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
