const std = @import("std");
const network = @import("network");

const OscMessage = @import("./OscMessage.zig");

const OscClient = @This();

allocator: std.mem.Allocator,
port: u16 = undefined,
address: network.Address = undefined,
socket: network.Socket = undefined,
send_to_endpoint: network.EndPoint = undefined,

pub fn connect(self: *OscClient, broadcast: bool, send_to_address: []const u8) !void {
    self.address = network.Address{ .ipv4 = network.Address.IPv4.any };

    self.socket = try network.Socket.create(.ipv4, .udp);
    try self.socket.setBroadcast(broadcast);

    const bind_address = network.EndPoint{
        .address = network.Address{ .ipv4 = network.Address.IPv4.any },
        .port = 0,
    };

    self.send_to_endpoint = network.EndPoint{
        .address = network.Address{ .ipv4 = try network.Address.IPv4.parse(send_to_address) },
        .port = self.port,
    };
    try self.socket.bind(bind_address);
}

pub fn close(self: *OscClient) void {
    self.socket.close();
}

pub fn sendMessage(self: *OscClient, osc_message: OscMessage) !void {
    const buffer = try osc_message.encode(self.allocator);
    _ = try self.socket.sendTo(self.send_to_endpoint, buffer);
}
