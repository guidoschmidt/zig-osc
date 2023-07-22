const std = @import("std");
const osc = @import("osc");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const rng_gen = std.rand.DefaultPrng;
var rng_inst: std.rand.Xoshiro256 = rng_gen.init(0);

pub fn main() !void {
    var client = osc.OscClient{};
    try client.connect();
    defer client.close();

    for(0..1) |i| {
        var args: [1]osc.OscArgument = undefined;
        const rand_val = rng_inst.random()
            .intRangeAtMost(i32,
                            -1 * @as(i32, @intCast(i * 1000)),
                            @as(i32, @intCast(i * 1000)));
        _ = rand_val;
        args[0] = .{ .i = 31419 };
        // args[1] = .{ .i = -512 };
        // args[2] = .{ .i = -512 };
        const address: []u8 = try std.fmt.allocPrint(
            allocator,
            "/test/{any}/value",
            .{ i },
        );
        defer allocator.free(address);
        const msg = osc.OscMessage {
            .address = address,
            .arguments = &args,
            .argument_count = args.len,
        };
        try client.sendMessage(msg, allocator);
    }
}
