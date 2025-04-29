const std = @import("std");
const OscMessage = @import("./OscMessage.zig");

const OscSubscriber = @This();

id: usize,
topic: ?[]const u8 = undefined,
onNextFn: ?*const fn (*OscSubscriber, *const OscMessage) void = undefined,

pub fn onNext(self: *OscSubscriber, msg: *const OscMessage) void {
    if (self.onNextFn) |onNextFn| {
        onNextFn(*@This(), msg);
    }
}

pub fn format(self: OscSubscriber, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try writer.print("OscSubscriber {d}", .{self.id});
    try writer.print("\n{s}", .{self.topic.?});
}
