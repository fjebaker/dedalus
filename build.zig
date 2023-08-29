const std = @import("std");

pub fn linkWolfSSL(
    b: *std.Build,
    s: *std.build.CompileStep,
    wolfssl: anytype,
) void {
    _ = b;
    s.addIncludePath(std.build.LazyPath.relative("../wolfssl/zig-out/include"));
    s.addLibraryPath(std.build.LazyPath.relative("../wolfssl/zig-out/lib"));
    s.linkSystemLibrary("wolfssl");
    s.linkLibC();
    _ = wolfssl;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigwolfssl = b.dependency(
        "zigwolfssl",
        .{ .optimize = optimize, .target = target, .@"wolfssl-debug" = true },
    );

    const mod = b.addModule("dedalus", .{
        .source_file = .{ .path = "src/main.zig" },
        .dependencies = &[_]std.build.ModuleDependency{
            .{
                .name = "zigwolfssl",
                .module = zigwolfssl.module("zigwolfssl"),
            },
        },
    });

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    main_tests.addModule("zigwolfssl", zigwolfssl.module("zigwolfssl"));
    // linkWolfSSL(b, main_tests, zigwolfssl);
    main_tests.linkLibrary(zigwolfssl.artifact("wolfssl"));

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    const file_server = buildExample(b, mod, zigwolfssl, .{
        .name = "file-server",
        .root_source_file = .{ .path = "examples/file-server.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_file_server = b.addRunArtifact(file_server);
    const install_file_server = b.addInstallArtifact(file_server, .{});
    const file_server_step = b.step("server", "Run file server example");
    file_server_step.dependOn(&run_file_server.step);
    file_server_step.dependOn(&install_file_server.step);
}

pub fn buildExample(
    b: *std.Build,
    mod: *std.build.Module,
    zigwolfssl: *std.build.Dependency,
    opts: anytype,
) *std.build.CompileStep {
    const exe = b.addExecutable(opts);
    exe.addModule("zigwolfssl", zigwolfssl.module("zigwolfssl"));
    exe.linkLibrary(zigwolfssl.artifact("wolfssl"));
    // linkWolfSSL(b, exe, zigwolfssl);
    exe.addModule("dedalus", mod);
    return exe;
}