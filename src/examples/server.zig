const std = @import("std");
const zosc = @import("zosc");

const l = std.log.scoped(.@"zosc-example-server");
pub const io_mode = .evented;

var server: zosc.Server = undefined;

const ExampleSub = struct {
    osc_subscriber: zosc.Subscriber = undefined,

    pub fn init(id: usize, topic: []const u8) ExampleSub {
        const impl = struct {
            pub fn onNext(ptr: *zosc.Subscriber, msg: *const zosc.Message) void {
                const self: *ExampleSub = @fieldParentPtr("osc_subscriber", ptr);
                return self.handleOscMessage(msg);
            }
        };

        return ExampleSub{ .osc_subscriber = zosc.Subscriber{
            .id = id,
            .topic = topic,
            .onNextFn = impl.onNext,
        } };
    }

    pub fn subscribe(self: *ExampleSub, publisher: *zosc.Server) !void {
        try publisher.subscribe(&self.osc_subscriber);
    }

    pub fn handleOscMessage(self: *ExampleSub, msg: *const zosc.Message) void {
        l.info("\n{f}\n    -> {f}", .{ self, msg });
    }

    pub fn format(self: ExampleSub, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("{f}", .{self.osc_subscriber});
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try zosc.init();
    defer zosc.deinit();

    server = zosc.Server{
        .port = 8001,
    };
    try server.init(allocator);

    var osc_sub = ExampleSub.init(0, "/two/strings");
    try osc_sub.subscribe(&server);

    // var osc_sub_2 = ExampleSub.init(1, "/red");
    // try osc_sub_2.subscribe(&server);

    // var osc_sub_3 = ExampleSub.init(1, "/io/0/knob/2/btn");
    // try osc_sub_3.subscribe(&server);

    l.info("{f}", .{osc_sub});
    // l.info("{any}", .{osc_sub_2});
    // l.info("{any}", .{osc_sub_3});

    try server.serve();
}
