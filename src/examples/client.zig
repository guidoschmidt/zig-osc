const std = @import("std");
const zosc = @import("zosc");

const l = std.log.scoped(.@"zosc-example-client");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try zosc.init();
    defer zosc.deinit();

    var client = zosc.Client{ .port = 7001, .allocator = allocator };
    try client.connect();

    var i: usize = 0;
    while (i < 300) {
        if (i < 100) {
            const msg = zosc.Message{ .address = "/ch/1", .arguments = &[_]zosc.Argument{.{ .f = std.math.sin(@as(f32, @floatFromInt(i)) * 0.1) * 3.0 }} };
            l.info("\n{any}", .{msg});
            try client.sendMessage(msg);
        } else {
            const msg = zosc.Message{ .address = "/red", .arguments = &[_]zosc.Argument{.{ .f = std.math.sin(@as(f32, @floatFromInt(i)) * 0.1) * 3.0 }} };
            l.info("\n{any}", .{msg});
            try client.sendMessage(msg);
        }

        i += 1;
        std.time.sleep(std.time.ns_per_ms * 16);
    }
}
