const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("consts.zig");
const read = @import("read.zig");


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const parsed_projects = try read.get_projects(allocator);
    defer parsed_projects.deinit();
    const projects = parsed_projects.value;

    for(projects, 0..projects.len) |project, i| {
        try utils.print("{d}. name: {s}, path: {s}\n", .{i + 1, project.name, project.path});
    }

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    try utils.print("choose a number: ", .{});
    const num_raw = try stdin.takeDelimiter('\n');
    const num_str = std.mem.trim(u8, num_raw.?, &std.ascii.whitespace);
    const index = try std.fmt.parseInt(usize, num_str, 10);
    try open_tmux_session(allocator, projects[index - 1].name, projects[index - 1].path);
}

fn open_tmux_session (allocator: std.mem.Allocator, name: []u8, path: []u8) !void {
    const expanded = try utils.ExpandedPath.get_path(allocator, path);
    defer expanded.deinit();
    const argv = [_][]const u8{"tmux", "new-session", "-A", "-s", name, "-c", expanded.path};
    var child = std.process.Child.init(&argv, allocator);
    _ = try child.spawnAndWait();
}
