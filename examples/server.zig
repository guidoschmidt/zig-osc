const std = @import("std");
const osc = @import("osc");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    var server = osc.OscServer{};
    try server.serve(allocator);
}
