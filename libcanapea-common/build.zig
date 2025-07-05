const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.addModule("canapea-common", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const parser_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    parser_mod.addCSourceFile(.{
        .file = b.path("../parser/src/parser.c"),
        .flags = &[_][]const u8{"-std=c11"},
    });
    parser_mod.addCSourceFile(.{
        .file = b.path("../parser/src/scanner.c"),
        .flags = &[_][]const u8{"-std=c11"},
    });
    // parser_mod.addCSourceFile(.{
    //     .file = b.path("../parser/bindings/c/tree_sitter/tree-sitter-canapea.h"),
    //     .flags = &[_][]const u8{"-std=c2x"},
    // });
    // parser_mod.addIncludePath(b.path("../parser/bindings/c/tree_sitter/"));
    lib_mod.addImport("tree-sitter-canapea", parser_mod);

    const zig_tree_sitter_mod = b.dependency("tree_sitter", .{
        .target = target,
        .optimize = optimize,
        // .link_libc = true,
    });
    lib_mod.addImport("zig-tree-sitter", zig_tree_sitter_mod.module("tree-sitter"));
    // lib_mod.linkLibrary(zig_tree_sitter_mod.artifact("zig-tree-sitter"));

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
