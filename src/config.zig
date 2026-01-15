const std = @import("std");
const utils = @import("utils.zig");
const types = @import("types.zig");
const constants = @import("consts.zig");

pub fn ensure_config_exists(allocator: std.mem.Allocator, config_path: []const u8) !void {
    const expanded_path = try utils.ExpandedPath.get_path(allocator, config_path);
    defer expanded_path.deinit();

    const file = std.fs.cwd().createFile(expanded_path.path, .{ .exclusive = true }) catch |err| {
        if (err == error.PathAlreadyExists) return;
        return err;
    };
    defer file.close();
    try file.writeAll("[]\n");
}

pub fn get_projects(allocator: std.mem.Allocator, config_file_path: []const u8) !std.json.Parsed([]types.Project) {
    try ensure_config_exists(allocator, config_file_path);

    const expanded = try utils.ExpandedPath.get_path(allocator, config_file_path);
    defer expanded.deinit();

    const file = try std.fs.cwd().openFile(expanded.path, .{ .mode = .read_only });
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024); // 1MB limit
    defer allocator.free(content);

    return std.json.parseFromSlice([]types.Project, allocator, content, .{ 
        .allocate = .alloc_always
    });
}

pub fn save_projects(allocator: std.mem.Allocator, projects: []types.Project, config_path: []const u8) !void {
    const expanded_path = try utils.ExpandedPath.get_path(allocator, config_path);
    defer expanded_path.deinit();

    const file = try std.fs.cwd().createFile(expanded_path.path, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;
    var writer_impl = file.writer(&buffer);
    const writer = &writer_impl.interface;

    try writer.print("{f}\n", .{std.json.fmt(projects, .{ .whitespace = .indent_4 })});
    try writer.flush();
}

test "save_projects" {
    const allocator = std.testing.allocator;
    var pro_arr : std.ArrayList(types.Project) = .empty;
    defer pro_arr.deinit(allocator);
    try pro_arr.append(allocator, .{ .name = "newly added 1", .path = "/newly-added-path-1"});
    try pro_arr.append(allocator, .{ .name = "newly added 2", .path = "/newly-added-path-2"});
    const pro_slice: []types.Project = pro_arr.items;
    try save_projects(allocator, pro_slice, constants.test_json_file_path);
}

test "get_projects" {
    const allocator = std.testing.allocator;
    const parsed_projects = try get_projects(allocator, constants.test_json_file_path);
    defer parsed_projects.deinit();
    const projects = parsed_projects.value;
    for(projects) |project| {
        std.debug.print("{s} ({s})\n", .{project.name, project.path});
    }
}

