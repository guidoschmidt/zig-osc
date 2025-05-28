const std = @import("std");
const osc = @import("./lib.zig");

const testing = std.testing;

test "simple messages" {
    const allocator = std.testing.allocator;

    const test_messages = [_]*const osc.Message{
        &osc.Message{ .address = "/test", .arguments = &.{.{ .i = 1 }} },
        &osc.Message{ .address = "/float", .arguments = &.{.{ .f = 3.1415 }} },
        &osc.Message{ .address = "/test/2", .arguments = &.{.{ .s = "Hello World!" }} },
    };

    const expected_sizes = [_]usize{
        16,
        16,
        28,
    };

    for (test_messages, expected_sizes) |msg, size| {
        const buffer = try msg.encode(allocator);
        try std.testing.expectEqual(size, buffer.len);
        defer allocator.free(buffer);
    }
}

test "complex messages (multiple arguments, different types)" {
    const allocator = std.testing.allocator;

    const test_messages = [_]*const osc.Message{
        &osc.Message{ .address = "/test/1", .arguments = &.{ .{ .i = 1 }, .{ .f = 3.1415 } } },
        &osc.Message{
            .address = "/test/3/complex",
            .arguments = &.{ .{ .i = 42 }, .{ .s = "Hello World!" } },
        },
        &osc.Message{
            .address = "/two/strings",
            .arguments = &.{ .{ .s = "A very long string to test." }, .{ .s = "Hello World!" } },
        },
    };

    const expected_sizes = [_]usize{
        20,
        40,
        64,
    };

    for (test_messages, expected_sizes) |msg, size| {
        const buffer = try msg.encode(allocator);
        try std.testing.expectEqual(size, buffer.len);
        defer allocator.free(buffer);
    }
}

test "Very long and complex message" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const long_msg = osc.Message{
        .address = "/two/strings",
        .arguments = &.{ .{ .i = 42 }, .{ .s = "A very long string to test." }, .{ .f = 3.14 }, .{ .s = "Hello World!" } },
    };
    const buffer = try long_msg.encode(allocator);
    defer allocator.free(buffer);
    try std.testing.expectEqual(long_msg.bufferSize(), 76);
}
