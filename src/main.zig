const std = @import("std");
const network = @import("network");

pub const OscServer = struct {
    const Self = @This();

    socket: network.Socket = undefined,
    port_number: u16 = 7777,
    comptime buffer_size: u32 = 4096,

    pub fn serve(self: *Self, _: std.mem.Allocator) !void {
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
            std.debug.print(">> {s}\n", .{ buffer[0..bytes] });
        }
    }

    pub fn close(self: *Self) void {
        defer self.socket.close();
        defer network.deinit();
    }
};

pub const OscClient = struct {
    const Self = @This();

    socket: network.Socket = undefined,
    destAddress: network.EndPoint = undefined,

    pub fn connect(self: *Self) !void {
        try network.init();

        self.socket = try network.Socket.create(.ipv4, .udp);
        try self.socket.setBroadcast(true);

        const bindAddress = network.EndPoint{
            .address = network.Address{ .ipv4 = network.Address.IPv4.any },
            .port = 0
        };

        self.destAddress = network.EndPoint{
            .address = network.Address{ .ipv4 = network.Address.IPv4.multicast_all },
            .port = 7777
        };
        try self.socket.bind(bindAddress);
    }

    pub fn close(self: *Self) void {
        defer self.socket.close();
        defer network.deinit();
    }

    pub fn sendMessage(self: *Self,
                       osc_message: OscMessage,
                       allocator: std.mem.Allocator) !void {
        const buffer = osc_message.toPacket(allocator);
        _ = try self.socket.sendTo(self.destAddress, buffer);
    }
};

const OscPacket = struct {
    contents: []u8 = undefined,
    len: u8 = undefined,
};

pub const OscMessage = struct {
    const Self = @This();

    address: []const u8,
    type_tag: OscTypeTag = .i32,
    arguments: [*]OscArgument = undefined,
    argument_count: usize = 0,

    pub fn addArguments(self: *Self, arguments: [*]OscArgument, argument_count: usize) void {
        self.arguments = arguments;
        self.argument_count = argument_count;
    }
  
    pub fn format(self: Self,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{s} ", .{ self.address });
        for (0..self.argument_count) |i| {
            try writer.print("{} ", .{ self.arguments[i] });
        }
    }

    pub fn toPacket(self: *const Self, allocator: std.mem.Allocator) []u8 {
        const div_address = @ceil(@as(f32, @floatFromInt(self.address.len)) / 4.0);
        const address_length: u32 = @as(u32, @intFromFloat(div_address)) * 4;
        const div_args = @ceil(@as(f32, @floatFromInt(self.argument_count)) / 4.0);
        const args_length: u32 = @as(u32, @intFromFloat(div_args)) * 4;
        var buffer: []u8 = allocator.alloc(u8, address_length +
                                               args_length +
                                               args_length * self.argument_count) catch {
            std.log.err("Could not allocate OSC Message memory", .{});
            var errbuff: [0]u8 = [0]u8{};
            return &errbuff;
        };
        const term = 0;
        std.debug.print("\nBuffer: {any} [{}, {}, {}]", .{ buffer.len,
                                                          address_length,
                                                          args_length,
                                                          args_length });
        for(0..self.address.len) |i| {
            buffer[i] = self.address[i];
        }
        for (self.address.len..address_length) |i| {
            buffer[i] = term;
        }
        var type_tag_offset = address_length;
        buffer[type_tag_offset] = ',';
        type_tag_offset += 1;
        var argument_offset = address_length + args_length;
        for (0..self.argument_count) |i| {
            const argument = self.arguments[i];
            switch(argument) {
                .f => |_| buffer[type_tag_offset + i] = 'f',
                .i => |_| buffer[type_tag_offset + i] = 'i',
            }
        }
        for(self.argument_count..args_length - 1) |i| {
            buffer[type_tag_offset + i] = term;
        }
        var idx: u32 = 0;
        for(0..self.argument_count) |i| {
            const argument = self.arguments[i];
            idx = @intCast(argument_offset + i * 4);
            std.debug.print("\n{d}", .{idx});
            switch(argument) {
                .i => |v| {
                    buffer[idx + 0] = @intCast((v >> 24) & 0xFF);
                    buffer[idx + 1] = @intCast((v >> 16) & 0xFF);
                    buffer[idx + 2] = @intCast((v >> 8) & 0xFF);
                    buffer[idx + 3] = @intCast(v & 0xFF);
                },
                .f => |v| {
                    const f32_buff = std.mem.asBytes(&v);
                    buffer[idx + 3] = f32_buff[0];
                    buffer[idx + 2] = f32_buff[1];
                    buffer[idx + 1] = f32_buff[2];
                    buffer[idx + 0] = f32_buff[3];
                }
            }
        }
        var i: u32 = 0;
        while(i < buffer.len) : (i += 4) {
            std.debug.print("\n{s}", .{ buffer[i..i+4] });
        }
        std.debug.print("\n{s}", .{ buffer });
        return buffer;
    }
};

pub const OscArgumentType = enum {
    i,
    f
};

pub const OscArgument = union(OscArgumentType) {
    const Self = @This();

    i: i32,
    f: f32,

    pub fn format(self: Self,
                  comptime fmt: []const u8,
                  options: std.fmt.FormatOptions,
                  writer: anytype) !void {
        _ = options;
        _ = fmt;
        switch(self) {
            .f => |s| try writer.print("{d:.3}", .{ s }),
            .i => |s| try writer.print("{d}", .{ s }),
        }
    }
};

const OscTypeTag = enum {
    i32,
    f32,
    string,
    blob,
};

test "simple test" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    _ = allocator;
    var client = OscClient{};
    try client.connect();
}
