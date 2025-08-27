const std = @import("std");
const network = @import("network");
const OscSubscriber = @import("OscSubscriber.zig");
const Allocator = std.mem.Allocator;

const l = std.log.scoped(.OscServer);

const OscMessage = @import("./OscMessage.zig");

const OscServer = @This();

subscribers: std.AutoHashMap(usize, *OscSubscriber) = undefined,

allocator: std.mem.Allocator = undefined,
port: u16 = 7777,
socket: network.Socket = undefined,
comptime buffer_size: u32 = 4096,
active: bool = true,

pub fn init(self: *OscServer, allocator: Allocator) !void {
    self.allocator = allocator;
    self.subscribers = std.AutoHashMap(usize, *OscSubscriber).init(allocator);

    self.socket = try network.Socket.create(.ipv4, .udp);
    try self.socket.enablePortReuse(true);
    const incoming_endpoint = network.EndPoint{
        .address = network.Address{ .ipv4 = network.Address.IPv4.any },
        .port = self.port,
    };
    self.socket.bind(incoming_endpoint) catch |err| {
        l.err("[OscServer] Failed to bind to {any}\n{any}", .{ incoming_endpoint, err });
    };
}

pub fn subscribe(self: *OscServer, subscriber: *OscSubscriber) !void {
    try self.subscribers.put(subscriber.id, subscriber);
}

pub fn unsubscribe(self: *OscServer, id: []const u8) void {
    self.subscribers.remove(id);
}

fn next(self: *OscServer, msg: *const OscMessage) void {
    var val_it = self.subscribers.valueIterator();
    while (val_it.next()) |sub| {
        if (sub.*.topic) |topic| {
            // @TODO impl. partial match or even regex, e.g. /topic1/*/velocity
            if (std.mem.containsAtLeast(u8, msg.address, 1, topic)) {
                if (sub.*.onNextFn) |onNextFn| onNextFn(sub.*, msg);
            }
        } else {
            if (sub.*.onNextFn) |onNextFn| onNextFn(sub.*, msg);
        }
    }
}

pub fn serve(self: *OscServer) !void {
    l.info("\n[OscServer] Serving on port {}", .{self.port});

    defer self.subscribers.deinit();

    var buffer: [self.buffer_size]u8 = undefined;
    self.active = true;
    while (true) {
        if (!self.active) break;
        const len = try self.socket.receive(&buffer);
        if (len > 0) {
            const osc_msg = try OscMessage.decode(buffer[0..len], self.allocator);
            self.next(&osc_msg);
        }
    }
    if (!self.active) {
        l.info("\n[OscServer] shutting down ...", .{});
    }
}

pub fn kill(self: *OscServer) void {
    self.active = false;
}
