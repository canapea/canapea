const std = @import("std");

pub fn build(b: *std.Build) void {
    const no_bin = b.option(
        bool,
        "no-bin",
        "skip emitting binary",
    ) orelse false;

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

    const generated_mod = b.createModule(.{
        .root_source_file = b.path("generated/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("canapea-common-generated", generated_mod);

    const generate_lang_types_mod = b.createModule(.{
        .root_source_file = b.path("src/generate-types.zig"),
        .target = target,
        .optimize = optimize,
    });
    generate_lang_types_mod.addImport("canapea-common", lib_mod);
    const generate_lang_types_exe = b.addExecutable(.{
        .name = "generate_lang_types_exe",
        .root_module = generate_lang_types_mod,
    });
    if (no_bin) {
        b.getInstallStep().dependOn(&generate_lang_types_exe.step);
    } else {
        b.installArtifact(generate_lang_types_exe);
    }

    const generate_lang_types_cmd = b.addRunArtifact(generate_lang_types_exe);
    generate_lang_types_cmd.step.dependOn(b.getInstallStep());
    // First args point to necessary files
    generate_lang_types_cmd.addDirectoryArg(b.path("."));
    generate_lang_types_cmd.addDirectoryArg(b.path("./generated/"));
    generate_lang_types_cmd.addFileArg(b.path("../parser/src/grammar.json"));
    generate_lang_types_cmd.addFileArg(b.path("../parser/src/node-types.json"));
    if (b.args) |args| {
        generate_lang_types_cmd.addArgs(args);
    }

    const generate_lang_types_step = b.step("generate-types", "Generate language types");
    generate_lang_types_step.dependOn(&generate_lang_types_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const generated_unit_tests = b.addTest(.{
        .root_module = generated_mod,
    });
    const run_generated_unit_tests = b.addRunArtifact(generated_unit_tests);

    const generate_exe_unit_tests = b.addTest(.{
        .root_module = generate_lang_types_mod,
    });
    const run_generate_exe_unit_tests = b.addRunArtifact(generate_exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_generated_unit_tests.step);
    test_step.dependOn(&run_generate_exe_unit_tests.step);
}
