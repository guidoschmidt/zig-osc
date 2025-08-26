const std = @import("std");
const zosc = @import("zosc");

const slog = std.log.scoped(.tracker);

// f(n) = 440 * 2 ^ { (n - 69) / 12 }
// https://www.music.mcgill.ca/~gary/307/week1/node28.html
fn midiToFreq(n: u8) f32 {
    return 440 * std.math.pow(f32, 2, (@as(f32, @floatFromInt(n)) - 69) / 12.0);
}

fn freqToMidi(f: f32) f32 {
    return (69 + 12 * std.math.log2(f / 440.0));
}

const Pattern = [8]?f32;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const bpm = 270;

    try zosc.init();
    defer zosc.deinit();

    var client = zosc.Client{
        .port = 7001,
        .allocator = allocator,
    };
    try client.connect(true, "255.255.255.255");

    const pattern_list = [_]Pattern{
        .{ 20, null, 100, 220, 200, null, null, null },
        .{ 40, null, 100, 240, null, null, null, null },
        .{ null, null, 100, 180, null, null, null, null },
        .{ 30, null, 200, 220, 150, null, null, null },
        .{ 50, null, 200, 220, 120, null, null, null },
        .{ null, null, 200, 240, null, null, null, null },
        .{ 20, null, 300, 260, 220, null, null, null },
        .{ 50, null, 300, 280, 280, null, null, null },
        .{ 70, null, 300, 200, null, null, null, null },
        .{ null, 220, 100, 180, 220, null, null, null },
        .{ 30, null, 100, 280, 240, null, null, null },
        .{ 50, null, 100, 280, null, null, null, null },
        .{ null, 270, 400, 200, 180, null, null, null },
        .{ 50, null, 400, 220, 140, null, null, null },
        .{ 50, 120, 400, null, null, null, null, null },
        .{ null, null, null, 240, 150, null, null, null },
        .{ null, null, null, 260, 120, null, null, null },
        .{ null, null, null, 280, null, null, null, null },
        .{ null, null, null, 200, null, null, null, null },
        .{ null, null, null, null, null, null, null, null },
        .{ null, null, null, null, null, null, null, null },
        .{ 50, null, null, 480, null, null, null, null },
        .{ 20, null, null, 400, null, null, null, null },
    };

    var buf: [32]u8 = undefined;

    while (true) {
        try client.sendMessage(.{ .address = "/ch/8", .arguments = &.{.{ .i = 1 }} });

        std.debug.print("\x1b[2J\x1b[H", .{});
        for (0..pattern_list.len) |j| {
            const pattern = pattern_list[j];
            if (j == 0) {
                for (0..pattern.len) |i| {
                    std.debug.print("\x1B[{d};{d}H", .{ 0, 10 * i });
                    std.debug.print("\x1B[31m{d: ^10}", .{i + 1});
                }
            }
            std.debug.print("\x1B[0m", .{});
            for (0..pattern.len) |i| {
                if (pattern[i]) |freq| {
                    std.debug.print("\x1B[{d};{d}H", .{ j + 2, 10 * i });
                    const ch = try std.fmt.bufPrint(&buf, "/ch/{d}", .{i + 1});
                    const midi_note = freqToMidi(freq);
                    std.debug.print("{d: ^10.2}", .{midi_note});
                    try client.sendMessage(.{ .address = ch, .arguments = &.{.{ .f = midi_note }} });
                }
            }
            std.Thread.sleep(std.time.ns_per_min / bpm);
        }
    }
}
