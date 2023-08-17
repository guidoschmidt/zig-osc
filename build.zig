const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module_network = b.addModule("network", .{
        .source_file = .{ .path = "./libs/zig-network/network.zig" }
    });

    const module_osc = b.addModule("osc", .{
        .source_file = .{ .path = "./src/main.zig" },
        .dependencies = &.{
            .{ .name = "network", .module = module_network }
        }
    });

    // Example: simple
    const example_simple = b.addExecutable(.{
        .name = "example_simple",
        .root_source_file = .{ .path = "examples/simple.zig" },
        .target = target,
        .optimize = optimize,
    });
    example_simple.addModule("osc", module_osc);
    b.installArtifact(example_simple);

    const run_example_simple = b.addRunArtifact(example_simple);
    run_example_simple.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_example_simple.step);

    // Example: simple
    const example_server = b.addExecutable(.{
        .name = "server",
        .root_source_file = .{ .path = "examples/server.zig" },
        .target = target,
        .optimize = optimize
    });
    example_server.addModule("osc", module_osc);
    b.installArtifact(example_server);

    const run_example_server = b.addRunArtifact(example_server);
    run_example_server.step.dependOn(b.getInstallStep());
    const run_example_server_step = b.step("run-server", "Run server example");
    run_example_server_step.dependOn(&run_example_server.step);

    // Tests
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize
    });
    tests.addModule("osc", module_osc);
    tests.addModule("network", module_network);
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
