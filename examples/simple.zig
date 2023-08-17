const std = @import("std");
const osc = @import("osc");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const rng_gen = std.rand.DefaultPrng;
var rng_inst: std.rand.Xoshiro256 = rng_gen.init(0);

pub fn main() !void {
    var client = osc.OscClient{};
    try client.connect(7777);
    defer client.close();

    for(0..100) |i| {
        std.log.info("\n>> {}", .{ i });
        var args: [1]osc.OscArgument = undefined;
        args[0] = .{ .i = 1 };
        // args[1] = .{ .i = -512 };
        // args[2] = .{ .i = -512 };
        // const address: []u8 = try std.fmt.allocPrint(
        //     allocator,
        //     "/ch/1",
        //     .{ i },
        // );
        // defer allocator.free(address);
        const msg = osc.OscMessage {
            .address = "/ch/1",
            .arguments = &args,
            .argument_count = args.len,
        };
        try client.sendMessage(msg, allocator);

        var args2: [1]osc.OscArgument = undefined;

        const rand_val: i32 = 100 + @as(i32, @intCast(i)) * 2000;
        args2[0] = .{ .i = rand_val };
        const msg2 = osc.OscMessage {
            .address = "/ch/2",
            .arguments = &args2,
            .argument_count = args2.len,
        };
        std.log.info("\n   {}", .{ msg2 });
        try client.sendMessage(msg2, allocator);
        std.time.sleep(60000000);
    }
}
