const std = @import("std");

fn createExample(b: *std.Build,
                 target: *const std.Build.ResolvedTarget,
                 optimize: *const std.builtin.OptimizeMode,
                 name: []const u8,
                 src: []const u8,
                 zosc_module: *std.Build.Module) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path(src),
        .target = target.*,
        .optimize = optimize.*,
    });

    exe.root_module.addImport("zosc", zosc_module);

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    var buf: [32]u8 = undefined;
    const run_name = std.fmt.bufPrint(&buf, "run-{s}", .{name}) catch @panic("Could not print to buffer!");

    const run_step = b.step(run_name, "Run example");
    run_step.dependOn(&run_cmd.step);
}

pub fn build(b: *std.Build) !void {
    const network_module = b.dependency("network", .{}).module("network");

    const zosc_module = b.addModule("zosc", .{
        .root_source_file = b.path("src/lib.zig"),
        .imports = &.{
            .{ .name = "network", .module = network_module },
        },
    });

    // Examples
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();


    const examples_path = try std.fs.path.join(allocator, &.{ "src", "examples" });
    defer allocator.free(examples_path);
    const examples_dir = try std.fs.cwd().openDir(examples_path, .{ .iterate = true });
    var examples_it = examples_dir.iterate();
    while (try examples_it.next()) |file| {
        const example_name = try std.mem.replaceOwned(u8, allocator, file.name, ".zig", "");
        const example_path = try std.fs.path.joinZ(allocator, &.{ examples_path, file.name });
        createExample(b, &target, &optimize, example_name, example_path, zosc_module);
    }

    // Tests
    const tests = b.addTest(.{ .root_source_file = b.path("./src/testing.zig"), .target = target, .optimize = optimize });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
