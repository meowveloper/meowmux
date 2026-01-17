const std = @import("std");
const config = @import("config.zig");
const tui = @import("tui.zig");
const types = @import("types.zig");
const constants = @import("consts.zig");

test "save_projects" {
    const allocator = std.testing.allocator;
    var pro_arr : std.ArrayList(types.Project) = .empty;
    defer pro_arr.deinit(allocator);
    try pro_arr.append(allocator, .{ .name = "newly added 1", .path = "/newly-added-path-1"});
    try pro_arr.append(allocator, .{ .name = "newly added 2", .path = "/newly-added-path-2"});
    const pro_slice: []types.Project = pro_arr.items;
    try config.save_projects(allocator, pro_slice, constants.test_json_file_path);
}

test "get_projects" {
    const allocator = std.testing.allocator;
    const parsed_projects = try config.get_projects(allocator, constants.test_json_file_path);
    defer parsed_projects.deinit();
    const projects = parsed_projects.value;
    for(projects) |project| {
        std.debug.print("{s} ({s})\n", .{project.name, project.path});
    }
}

test "parse_sequence keys" {
    const testing = std.testing;

    // Arrows
    try testing.expectEqual(tui.Key.up, tui.parse_sequence("\x1b[A"));
    try testing.expectEqual(tui.Key.down, tui.parse_sequence("\x1b[B"));

    // Special
    try testing.expectEqual(tui.Key.esc, tui.parse_sequence("\x1b"));
    try testing.expectEqual(tui.Key.enter, tui.parse_sequence("\r"));
    try testing.expectEqual(tui.Key.enter, tui.parse_sequence("\n"));
    try testing.expectEqual(tui.Key.ctrl_c, tui.parse_sequence(&[_]u8{3}));

    // Chars
    const q_key = tui.parse_sequence("q");
    try testing.expectEqual(tui.Key{ .char = 'q' }, q_key);
}
