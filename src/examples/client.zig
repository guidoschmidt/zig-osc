const std = @import("std");
const zosc = @import("zosc");

const l = std.log.scoped(.@"zosc-example-client");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try zosc.init();
    defer zosc.deinit();

    var client = zosc.Client{ .port = 8001, .allocator = allocator };
    try client.connect(false, "127.0.0.1");

    const msg_count: usize = 200;
    var i: usize = 0;
    var curr: i16 = -250;
    // var rot_curr: i16 = -740;
    var zoom_curr: i16 = -740;
    while (i < msg_count) {
        // const rot_msg = zosc.Message{ .address = "/io/0/knob/0/enc", .arguments = &[_]zosc.Argument{.{ .i = rot_curr }} };
        // try client.sendMessage(rot_msg);
        // rot_curr += 5;
        // std.time.sleep(std.time.ns_per_ms * 30);

        // const zoom_msg = zosc.Message{ .address = "/io/0/knob/1/enc", .arguments = &[_]zosc.Argument{.{ .i = zoom_curr }} };
        // try client.sendMessage(zoom_msg);
        // std.time.sleep(std.time.ns_per_ms * 30);

        // const msg = zosc.Message{ .address = "/io/0/knob/2/enc", .arguments = &[_]zosc.Argument{.{ .i = curr }} };
        // try client.sendMessage(msg);
        // l.info("\n{any}", .{msg});
        if (i < msg_count / 2) {
            zoom_curr -= 3;
            curr += 1;
        } else {
            zoom_curr += 3;
            curr -= 1;
        }

        const str_msg = zosc.Message{
            .address = "/two/strings",
            .arguments = &.{
                .{ .i = 42 },
                .{ .s = "Hallo" },
                .{ .f = 3.14 },
                .{ .s = "Hallo Welt!" },
            },
        };
        l.info("\n{any}", .{str_msg});
        try client.sendMessage(str_msg);

        i += 1;
        std.time.sleep(std.time.ns_per_ms * 30);
    }
}
