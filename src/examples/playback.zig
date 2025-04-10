const std = @import("std");
const zosc = @import("zosc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("recording.osc", .{ .mode = .read_only });
    const stats = try file.stat();
    const content = try file.readToEndAlloc(allocator, stats.size);
    std.debug.print("\n{s}", .{content});

    try zosc.init();
    defer zosc.deinit();

    var client = zosc.Client{
        .port = 7001,
        .allocator = allocator,
    };
    try client.connect(false, "127.0.0.1");
}
