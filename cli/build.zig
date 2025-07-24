const std = @import("std");

pub fn build(b: *std.Build) void {
    const no_bin = b.option(
        bool,
        "no-bin",
        "skip emitting binary",
    ) orelse false;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const canapea_dep = b.dependency("canapea", .{
        .target = target,
        .optimize = optimize,
    });

    const canapea_lsp_dep = b.dependency("canapea_language_server", .{
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport(
        "canapea",
        canapea_dep.module("canapea"),
    );
    exe_mod.addImport(
        "canapea-language-server",
        canapea_lsp_dep.module("canapea-language-server"),
    );

    const exe = b.addExecutable(.{
        .name = "canapea_cli_exe",
        .root_module = exe_mod,
    });
    if (no_bin) {
        b.getInstallStep().dependOn(&exe.step);
    } else {
        b.installArtifact(exe);
    }

    const lib_docs_mod = b.addInstallDirectory(.{
        .source_dir = exe.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const lib_docs_step = b.step("docs", "Intall docs into zig-out/docs");
    lib_docs_step.dependOn(&lib_docs_mod.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
