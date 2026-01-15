const std = @import("std");
const types = @import("types.zig");
const utils = @import("utils.zig");

pub fn open_tmux_session (allocator: std.mem.Allocator, name: []const u8, path: []const u8) !void {
    const expanded = try utils.ExpandedPath.get_path(allocator, path);
    defer expanded.deinit();
    const argv = [_][]const u8{"tmux", "new-session", "-A", "-s", name, "-c", expanded.path};
    var child = std.process.Child.init(&argv, allocator);
    _ = try child.spawnAndWait();
}
