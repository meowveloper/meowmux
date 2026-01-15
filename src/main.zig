const std = @import("std");
const utils = @import("utils.zig");
const read = @import("read.zig");
const tmux = @import("tmux.zig");


pub fn main() !void {
    try utils.print("MEOWMUX\n\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const parsed_projects = try read.get_projects(allocator);
    defer parsed_projects.deinit();
    const projects = parsed_projects.value;

    while(true) {
        try tmux.init_tmux_session(allocator, projects);
    }
}
