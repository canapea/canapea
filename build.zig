//! This is the build process for the whole CLI which includes everything
//! you need to use the Canapea programming language in one single binary.
//!
//! The compiler toolchain itself is bundled into a single re-usable library
//! and can be used without the CLI dependencies, see [libcanapea](./libcanapea)
//! for details.

const std = @import("std");

/// Import the `Translator` helper from the `translate_c` dependency.
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const no_bin = b.option(
        bool,
        "no-bin",
        "skip emitting binary",
    ) orelse false;

    const use_llvm = b.option(
        bool,
        "use-llvm",
        "use native target code generation, if available",
    ) orelse true;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Prepare the `translate-c` dependency.
    const translate_c = b.dependency("translate_c", .{});

    // Build the C library. In reality this would probably be done via the package manager.
    const parser_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const parser_lib = buildTreeSitterCanapea(b, parser_mod);

    // Create a `Translator` for C source code which `#include`s the needed headers.
    // If necessary, it could also include different headers, define macros, etc.
    const libparser_from_c: Translator = .init(translate_c, .{
        .c_source_file = b.addWriteFiles().add("c.h",
            \\#include <tree-sitter-canapea/tree-sitter-canapea.h>,
        ),
        .target = target,
        .optimize = optimize,
    });

    // Of course, we need to link against `libfoo`! This call tells `translate-c` where to
    // find the headers we included, but it also makes `trans_libfoo.mod` actually link the
    // library.
    libparser_from_c.linkLibrary(parser_lib);

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
    // common_mod.addImport("tree-sitter-canapea", parser_mod);
    common_mod.addImport("tree-sitter-canapea", libparser_from_c.mod);
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
        .use_llvm = use_llvm,
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
        .use_llvm = use_llvm,
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

fn buildTreeSitterCanapea(b: *std.Build, parser_mod: *std.Build.Module) *std.Build.Step.Compile {
    parser_mod.addCSourceFiles(.{
        .root = b.path("./parser/src/"),
        .files = &.{ "parser.c", "scanner.c" },
        .flags = &.{"-std=c11"},
    });
    // parser_mod.addCSourceFile(.{
    //     .file = b.path("./parser/bindings/c/tree_sitter/tree-sitter-canapea.h"),
    //     .flags = &[_][]const u8{"-std=c2x"},
    // });
    // parser_mod.addIncludePath(b.path("../parser/bindings/c/tree_sitter/"));

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "tree-sitter-canapea",
        .root_module = parser_mod,
    });
    // Install the headers, so that linking this library makes those headers available.
    lib.installHeader(b.path("./parser/src/tree_sitter/alloc.h"), "tree-sitter-canapea/alloc.h");
    lib.installHeader(b.path("./parser/src/tree_sitter/array.h"), "tree-sitter-canapea/array.h");
    lib.installHeader(b.path("./parser/src/tree_sitter/parser.h"), "tree-sitter-canapea/parser.h");
    lib.installHeader(
        b.path("./parser/bindings/c/tree_sitter/tree-sitter-canapea.h"),
        "tree-sitter-canapea/tree-sitter-canapea.h",
    );
    return lib;
}
