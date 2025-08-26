const std = @import("std");
const zosc = @import("zosc");

var server: zosc.Server = undefined;

const OscRecord = struct {
    time: i64,
    address: []const u8,
    args: []const zosc.Argument,

    pub fn format(self: OscRecord, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{d}, {any}, {any}", .{ self.time, self.address, self.args });
    }
};

const Recorder = struct {
    start_time: i64 = undefined,
    osc_subscriber: zosc.Subscriber = undefined,
    recording: std.array_list.Managed(OscRecord) = undefined,
    recording_length: u64 = 100,

    pub fn init(allocator: std.mem.Allocator) !Recorder {
        const impl = struct {
            pub fn onNext(ptr: *zosc.Subscriber, msg: *const zosc.Message) void {
                const self: *Recorder = @fieldParentPtr("osc_subscriber", ptr);
                return self.recordOscMessage(msg);
            }
        };

        const instance = Recorder{
            .recording = std.array_list.Managed(OscRecord).init(allocator),
            .osc_subscriber = zosc.Subscriber{
                .id = 0,
                .onNextFn = impl.onNext,
            },
        };
        return instance;
    }

    pub fn recordOscMessage(self: *Recorder, msg: *const zosc.Message) void {
        self.recording.append(OscRecord{
            .time = std.time.timestamp(),
            .address = msg.address,
            .args = msg.arguments,
        }) catch |err| {
            std.debug.print("Could not append OSC message to recording: {any}", .{err});
        };
        if (self.recording.items.len > self.recording_length) {
            server.kill();
        }
    }

    pub fn saveAndDeinit(self: *Recorder) void {
        const filename = "recording.osc";
        std.debug.print("\nSave recording file {s}...", .{filename});
        const file = std.fs.cwd().createFile(filename, .{}) catch {
            @panic("Could not write recording file!");
        };
        var line_buffer: [128]u8 = undefined;
        for (0..self.recording.items.len) |i| {
            const record = self.recording.items[i];
            const line = std.fmt.bufPrint(&line_buffer, "{any}\n", .{record}) catch {
                @panic("Could not use bufPrint!");
            };
            _ = file.write(line) catch {
                @panic("Could not write line!");
            };
        }
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try zosc.init();
    defer zosc.deinit();

    server = zosc.Server{
        .port = 7001,
    };
    try server.init(allocator);

    var recorder_sub = try Recorder.init(allocator);
    try server.subscribe(&recorder_sub.osc_subscriber);
    defer recorder_sub.saveAndDeinit();

    try server.serve();
}
