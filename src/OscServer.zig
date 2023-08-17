const std = @import("std");
const network = @import("network");
const OscMessage = @import("./main.zig").OscMessage;

const Self = @This();

socket: network.Socket = undefined,
port_number: u16 = 7777,
comptime buffer_size: u32 = 4096,

pub fn serve(self: *Self, allocator: std.mem.Allocator) !void {
    try network.init();
    self.socket = try network.Socket.create(.ipv4, .udp);
    try self.socket.enablePortReuse(true);
    const incoming_endpoint = network.EndPoint{
        .address = network.Address{ .ipv4 = network.Address.IPv4.multicast_all },
        .port = self.port_number,
    };
    self.socket.bind(incoming_endpoint) catch |err| {
        std.log.err("Failed to bind to {}\n{}", .{ incoming_endpoint, err });
    };
    std.log.info("Serving on {}\n", .{ incoming_endpoint });
    var buffer: [self.buffer_size]u8 = undefined;
    var reader = self.socket.reader();
    while(true) {
        std.debug.print(">> Serving on port {}\n", .{ self.port_number });
        const bytes = try reader.read(buffer[0..buffer.len]);
        if (bytes > 0) {
            const msg = OscMessage.from(buffer[0..bytes], allocator);
            std.debug.print("\n>> got {d} bytes:\n{?}\n", .{ bytes, msg });
        }
    }
}

pub fn close(self: *Self) void {
    defer self.socket.close();
    defer network.deinit();
}
