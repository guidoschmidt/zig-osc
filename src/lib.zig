const std = @import("std");
const network = @import("network");

pub const Message = @import("./OscMessage.zig");
pub const Argument = Message.OscArgument;
pub const Client = @import("./OscClient.zig");
pub const Server = @import("./OscServer.zig");
pub const Subscriber = @import("./OscSubscriber.zig");

const Allocator = std.mem.Allocator;

pub fn init() !void {
    try network.init();
}

pub fn deinit() void {
    defer network.deinit();
}
