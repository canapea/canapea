const std = @import("std");

pub fn build(b: *std.Build) void {
    // const no_bin = b.option(
    //     bool,
    //     "no-bin",
    //     "skip emitting binary",
    // ) orelse false;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Expose public module via b.addModule
    const lib_mod = b.addModule("canapea", .{
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

    const janet_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    janet_mod.addCSourceFile(.{
        // Only needs C99 but tree-sitter is C11 anyway
        .file = b.path("./lib/janet/janet.c"),
        .flags = &[_][]const u8{"-std=c11"}, //, "-lm", "-ldl" },
    });
    lib_mod.addIncludePath(b.path("./lib/janet/"));
    lib_mod.addImport("janet", janet_mod);

    const canapea_codegen_es5_dep = b.dependency("canapea_codegen_es5", .{
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport(
        "canapea-codegen-es5",
        canapea_codegen_es5_dep.module("canapea-codegen-es5"),
    );

    const canapea_semantic_analyzer_dep = b.dependency("canapea_semantic_analyzer", .{
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport(
        "canapea-semantic-analyzer",
        canapea_semantic_analyzer_dep.module("canapea-semantic-analyzer"),
    );

    // const lib = b.addLibrary(.{
    //     .linkage = .static,
    //     .name = "canapea",
    //     .root_module = lib_mod,
    // });
    // FIXME: Why exactly can't I b.installArtifact or &lib_mod.step here without b.addLibrary?
    // b.installArtifact(lib_mod);
    // if (no_bin) {
    //     b.getInstallStep().dependOn(&lib_mod.step);
    // } else {
    //     b.installArtifact(lib_mod);
    // }

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
