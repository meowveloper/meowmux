const std = @import("std");
const types = @import("types.zig");
const utils = @import("utils.zig");

pub fn init_tmux_session (allocator: std.mem.Allocator, projects: []types.Project) !void {
    for(projects, 0..projects.len) |project, i| {
        try utils.print("{d}. name: {s}, path: {s}\n", .{i + 1, project.name, project.path});
    }

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    try utils.print("\nchoose a number: ", .{});
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
