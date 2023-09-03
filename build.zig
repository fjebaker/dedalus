const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigwolfssl = b.dependency(
        "zigwolfssl",
        .{ .optimize = optimize, .target = target, .@"wolfssl-debug" = false },
    );
    b.installArtifact(zigwolfssl.artifact("wolfssl"));

    const mod = b.addModule("dedalus", .{
        .source_file = .{ .path = "src/main.zig" },
        .dependencies = &[_]std.build.ModuleDependency{
            .{
                .name = "zigwolfssl",
                .module = zigwolfssl.module("zigwolfssl"),
            },
        },
    });

    // unit tests
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    main_tests.addModule("zigwolfssl", zigwolfssl.module("zigwolfssl"));
    main_tests.linkLibrary(zigwolfssl.artifact("wolfssl"));

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    // example 1
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

    const client = buildExample(b, mod, zigwolfssl, .{
        .name = "client",
        .root_source_file = .{ .path = "examples/client.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_client = b.addRunArtifact(client);
    if (b.args) |args| {
        run_client.addArgs(args);
    }
    const install_client = b.addInstallArtifact(client, .{});
    const client_step = b.step("client", "Run client example");
    client_step.dependOn(&run_client.step);
    client_step.dependOn(&install_client.step);
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
    exe.addModule("dedalus", mod);
    return exe;
}
