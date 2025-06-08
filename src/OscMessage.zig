const std = @import("std");

const OscTypeTag = enum {
    i32,
    f32,
    string,
    blob,
};

pub const OscArgumentType = enum {
    i,
    f,
    s,
    b,
};

pub const OscArgument = union(OscArgumentType) {
    i: i32,
    f: f32,
    s: []const u8,
    b: bool,

    pub fn setFloat(self: *OscArgument, f: f32) void {
        self.f = f;
    }

    pub fn setInt(self: *OscArgument, i: i32) void {
        self.i = i;
    }

    pub fn setBlob(self: *OscArgument) void {
        _ = self;
        @panic("Not yet implemented");
    }

    pub fn setString(self: *OscArgument, s: []const u8) void {
        self.s = s;
    }

    pub fn format(self: OscArgument, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;
        switch (self) {
            .f => |s| try writer.print("f {d:.3}", .{s}),
            .i => |s| try writer.print("i {d}", .{s}),
            .b => |s| try writer.print("b {any}", .{s}),
            .s => |s| try writer.print("s {s}", .{s}),
        }
    }
};

const OscMessage = @This();

address: []const u8,
arguments: []const OscArgument = undefined,

pub fn addArguments(self: *OscMessage, arguments: []const OscArgument) void {
    self.arguments = arguments;
}

pub fn bufferSize(self: OscMessage) usize {
    var size: usize = 0;
    size = self.address.len + 4 - @mod(self.address.len, 4); // address
    size += 1 + self.arguments.len + 4 - @mod(1 + self.address.len, 4);
    for (0..self.arguments.len) |i| {
        switch (self.arguments[i]) {
            .i, .f => {
                size += 1;
                if (i < self.arguments.len - 1 and self.arguments[i + 1] == .s) {
                    size += 1;
                }
            },
            .s => {
                const str_len = self.arguments[i].s.len + 1;
                size += str_len;
                if (i < self.arguments.len - 1 and self.arguments[i + 1] != .s) {
                    size += 4 - @mod(str_len, 4);
                }
            },
            else => {},
        }
    }
    size += 4 - @mod(size, 4);
    return size;
}

pub fn format(self: OscMessage, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try writer.print("\n{s} [{d}]", .{ self.address, self.arguments.len });
    for (0..self.arguments.len) |i| {
        try writer.print("\n + {d}", .{self.arguments[i]});
    }
}

pub fn encode(self: *const OscMessage, allocator: std.mem.Allocator) ![]u8 {
    const buffer: []u8 = try allocator.alloc(u8, self.bufferSize());

    var stream = std.io.fixedBufferStream(buffer);
    var writer = stream.writer();

    var pos = try writer.write(self.address);
    var skip = try std.math.mod(usize, pos, 4);
    for (0..(4 - skip)) |_| try writer.writeByte(0);
    try writer.writeByte(',');
    for (self.arguments) |arg| {
        switch (arg) {
            .i => try writer.writeByte('i'),
            .f => try writer.writeByte('f'),
            .s => try writer.writeByte('s'),
            else => {},
        }
    }
    pos = stream.pos;
    skip = try std.math.mod(usize, pos, 4);
    for (0..(4 - skip)) |_| try writer.writeByte(0);
    for (self.arguments) |arg| {
        switch (arg) {
            .i => {
                try writer.writeInt(i32, arg.i, .big);
            },
            .f => {
                try writer.writeInt(i32, @bitCast(arg.f), .big);
            },
            .s => {
                try writer.writeAll(arg.s);
                const rest = 4 - @mod(arg.s.len, 4);
                for (0..rest) |_| {
                    try writer.writeByte(0);
                }
            },
            else => {},
        }
    }
    return buffer;
}

pub fn decode(buffer: []u8, allocator: std.mem.Allocator) !OscMessage {
    var stream = std.io.fixedBufferStream(buffer);
    var reader = stream.reader();

    const address = try reader.readUntilDelimiter(buffer, ',');
    const eof = try stream.getEndPos();
    var pos = try stream.getPos();

    var arguments = std.ArrayList(OscArgument).init(allocator);
    defer arguments.deinit();

    while (pos < eof) : (pos = try stream.getPos()) {
        const type_tag = try reader.readByte();
        switch (type_tag) {
            'f' => {
                try arguments.append(OscArgument{
                    .f = 0,
                });
            },
            'i' => {
                try arguments.append(OscArgument{
                    .i = 0,
                });
            },
            's' => {
                try arguments.append(OscArgument{ .s = "" });
            },
            else => break,
        }
    }

    pos = try stream.getPos();
    const skip: usize = try std.math.mod(usize, pos, 4);
    if (skip > 0)
        try reader.skipBytes(4 - skip, .{});

    for (0..arguments.items.len) |i| {
        const arg = arguments.items[i];
        switch (arg) {
            .f => {
                const bytes = try reader.readBytesNoEof(4);
                const value = std.mem.bytesAsValue(i32, bytes[0..]);
                const value_native = std.mem.bigToNative(i32, value.*);
                const float_arg: f32 = @bitCast(value_native);
                arguments.items[i].f = float_arg;
            },
            .i => {
                const int_arg = try reader.readInt(i32, .big);
                arguments.items[i].i = int_arg;
            },
            .s => {
                if (try reader.readUntilDelimiterOrEofAlloc(allocator, 0, stream.buffer.len + 1)) |str_arg| {
                    arguments.items[i].s = str_arg;
                    pos = try stream.getPos();
                }
            },
            else => @panic("Not yet implemented"),
        }
    }
    return OscMessage{
        .address = try allocator.dupe(u8, address[0..]),
        .arguments = try allocator.dupe(OscArgument, arguments.items),
    };
}

pub fn free(self: *const OscMessage, allocator: std.mem.Allocator) void {
    allocator.free(self.arguments);
}
