const std = @import("std");
const network = @import("network");

pub const OscServer = @import("OscServer.zig");

pub const OscClient = struct {
    const Self = @This();

    socket: network.Socket = undefined,
    destAddress: network.EndPoint = undefined,

    pub fn connect(self: *Self, port: u16) !void {
        try network.init();

        self.socket = try network.Socket.create(.ipv4, .udp);
        try self.socket.setBroadcast(true);

        const bindAddress = network.EndPoint{
            .address = network.Address{ .ipv4 = network.Address.IPv4.any },
            .port = 0
        };

        self.destAddress = network.EndPoint{
            .address = network.Address{ .ipv4 = network.Address.IPv4.multicast_all },
            .port = port
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
    arguments: []OscArgument = undefined,
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

    pub fn from(buffer: []u8, allocator: std.mem.Allocator) OscMessage {
        var i: u16 = 0;
        while(i < buffer.len and buffer[i] != ',') {
            i += 1;
        }
        var j: u16 = 0;
        while(j < buffer.len) : (j += 4) {}
        const address_length = i;
        var argument_count: u16 = 0;
        i += 1;
        while(i < buffer.len and buffer[i] != 0) : (i += 1) {
            var tag_type = buffer[i]; 
            switch(tag_type) {
                'i' => |_| {
                    argument_count += 1;
                },
                'f' => |_| {
                    argument_count += 1;
                },
                else => |_| std.debug.print("", .{}), 
            }
        }
        while(i < buffer.len) : (i += 1) {}
        var osc_arguments: []OscArgument = allocator.alloc(OscArgument, argument_count) catch {
            std.log.err("Could not allocate memory", .{});
            return OscMessage{
                .address = ""
            };
        };
        var msg = OscMessage{
            .address = buffer[0..address_length],
            .arguments = osc_arguments
        };
        return msg;
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
            .f => |s| try writer.print("f {d:.3}", .{ s }),
            .i => |s| try writer.print("i {d}", .{ s }),
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
    var client = OscClient{};
    try client.connect();

    var args: [1]OscArgument = undefined;
    args[0] = .{ .i = 31419 };
    const address = "/test";
    const msg = OscMessage {
        .address = address,
        .arguments = &args,
        .argument_count = args.len,
    };
    const byte_buffer = msg.toPacket(allocator);
    std.debug.print("{s}\n", .{byte_buffer});

    var parsed_msg = OscMessage.from(byte_buffer, allocator);
    std.debug.print("\n\n{?}", .{ parsed_msg });
}
