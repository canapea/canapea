//! This is the build process for the whole CLI which includes everything
//! you need to use the Canapea programming language in one single binary.
//!
//! The compiler toolchain itself is bundled into a single re-usable library
//! and can be used without the CLI dependencies, see [libcanapea](./libcanapea)
//! for details.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const no_bin = b.option(
        bool,
        "no-bin",
        "skip emitting binary",
    ) orelse false;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const parser_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    parser_mod.addCSourceFile(.{
        .file = b.path("./parser/src/parser.c"),
        .flags = &[_][]const u8{"-std=c11"},
    });
    parser_mod.addCSourceFile(.{
        .file = b.path("./parser/src/scanner.c"),
        .flags = &[_][]const u8{"-std=c11"},
    });
    // parser_mod.addCSourceFile(.{
    //     .file = b.path("./parser/bindings/c/tree_sitter/tree-sitter-canapea.h"),
    //     .flags = &[_][]const u8{"-std=c2x"},
    // });
    // parser_mod.addIncludePath(b.path("../parser/bindings/c/tree_sitter/"));
    const zig_tree_sitter_mod = b.dependency("tree_sitter", .{
        .target = target,
        .optimize = optimize,
        // .link_libc = true,
    });
    const generated_mod = b.createModule(.{
        .root_source_file = b.path("./libcanapea/common/generated/types.zig"),
        .target = target,
        .optimize = optimize,
    });
    const generate_lang_types_mod = b.createModule(.{
        .root_source_file = b.path("./libcanapea/common/support/generate-types.zig"),
        .target = target,
        .optimize = optimize,
    });
    const common_mod = b.createModule(.{
        .root_source_file = b.path("./libcanapea/common/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    generate_lang_types_mod.addImport("canapea-common", common_mod);
    common_mod.addImport("tree-sitter-canapea", parser_mod);
    common_mod.addImport("zig-tree-sitter", zig_tree_sitter_mod.module("tree-sitter"));
    common_mod.addImport("canapea-common-generated", generated_mod);

    const codegen_es5_mod = b.createModule(.{
        .root_source_file = b.path("./libcanapea/codegen-es5/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    codegen_es5_mod.addImport("canapea-common", common_mod);

    const semantic_analyzer_mod = b.createModule(.{
        .root_source_file = b.path("./libcanapea/semantic-analyzer/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    semantic_analyzer_mod.addImport("canapea-common", common_mod);

    // Expose public module via b.addModule
    const libcanapea_mod = b.addModule("canapea", .{
        .root_source_file = b.path("./libcanapea/src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    libcanapea_mod.addImport("canapea-common", common_mod);
    libcanapea_mod.addImport(
        "canapea-codegen-es5",
        codegen_es5_mod,
    );
    libcanapea_mod.addImport(
        "canapea-semantic-analyzer",
        semantic_analyzer_mod,
    );

    const zig_lsp_kit_mod = b.dependency("lsp_kit", .{
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("./cli/src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("canapea", libcanapea_mod);
    exe_mod.addImport("zig-lsp-kit", zig_lsp_kit_mod.module("lsp"));

    const exe = b.addExecutable(.{
        .name = "canapea",
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

    const common_unit_tests = b.addTest(.{
        .root_module = common_mod,
    });
    const codegen_es5_unit_tests = b.addTest(.{
        .root_module = codegen_es5_mod,
    });
    const semantic_analyzer_unit_tests = b.addTest(.{
        .root_module = semantic_analyzer_mod,
    });
    const libcanapea_unit_tests = b.addTest(.{
        .root_module = libcanapea_mod,
    });
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_common_unit_tests = b.addRunArtifact(common_unit_tests);
    const run_codegen_es5_unit_tests = b.addRunArtifact(codegen_es5_unit_tests);
    const run_semantic_analyzer_unit_tests = b.addRunArtifact(semantic_analyzer_unit_tests);
    const run_libcanapea_unit_tests = b.addRunArtifact(libcanapea_unit_tests);

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_common_unit_tests.step);
    test_step.dependOn(&run_codegen_es5_unit_tests.step);
    test_step.dependOn(&run_semantic_analyzer_unit_tests.step);
    test_step.dependOn(&run_libcanapea_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);

    const generate_lang_types_step = b.step("generate-types", "Generate language types");

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
    generate_lang_types_cmd.addDirectoryArg(b.path("./libcanapea/common/"));
    generate_lang_types_cmd.addDirectoryArg(b.path("./libcanapea/common/generated/"));
    generate_lang_types_cmd.addFileArg(b.path("./parser/src/grammar.json"));
    generate_lang_types_cmd.addFileArg(b.path("./parser/src/node-types.json"));
    if (b.args) |args| {
        generate_lang_types_cmd.addArgs(args);
    }
    generate_lang_types_step.dependOn(&generate_lang_types_cmd.step);
}
