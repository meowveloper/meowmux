const std = @import("std");
const utils = @import("utils.zig");
const types = @import("types.zig");
const constants = @import("consts.zig");

pub fn ensure_config_exists(allocator: std.mem.Allocator, config_path: []const u8) !void {
    const expanded_path = try utils.ExpandedPath.get_path(allocator, config_path);
    defer expanded_path.deinit();

    if (std.fs.path.dirname(expanded_path.path)) |dir_path| {
        try std.fs.cwd().makePath(dir_path);
    }

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

pub fn delete_project(allocator: std.mem.Allocator, projects: []types.Project, index: usize, config_path: []const u8) !void {
    var proj_arr : std.ArrayList(types.Project) = .empty;
    defer proj_arr.deinit(allocator);
    try proj_arr.appendSlice(allocator, projects);
    _ = proj_arr.orderedRemove(index);
    try save_projects(allocator, proj_arr.items, config_path);
}

pub fn add_project(allocator: std.mem.Allocator, projects: []types.Project, new_project: types.Project, config_path: []const u8) !void {
    var proj_arr : std.ArrayList(types.Project) = .empty;
    defer proj_arr.deinit(allocator);
    try proj_arr.appendSlice(allocator, projects);
    try proj_arr.append(allocator, new_project);
    try save_projects(allocator, proj_arr.items, config_path);
}

pub fn edit_project(allocator: std.mem.Allocator, projects: []types.Project, new_project: types.Project, index: usize, config_path: []const u8) !void {
    var proj_arr : std.ArrayList(types.Project) = .empty;
    defer proj_arr.deinit(allocator);
    try proj_arr.appendSlice(allocator, projects);
    _ = proj_arr.orderedRemove(index);
    try proj_arr.insert(allocator, index, new_project);
    try save_projects(allocator, proj_arr.items, config_path);
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

test "save_projects" {
    const allocator = std.testing.allocator;
    var pro_arr : std.ArrayList(types.Project) = .empty;
    defer pro_arr.deinit(allocator);
    try pro_arr.append(allocator, .{ .name = "newly added 1", .path = "/newly-added-path-1"});
    try pro_arr.append(allocator, .{ .name = "newly added 2", .path = "/newly-added-path-2"});
    const pro_slice: []types.Project = pro_arr.items;
    try save_projects(allocator, pro_slice, constants.test_json_file_path);
}

test "delete_project" {
    const allocator = std.testing.allocator;
    var pro_arr : std.ArrayList(types.Project) = .empty;
    defer pro_arr.deinit(allocator);
    try pro_arr.append(allocator, .{ .name = "newly added 1", .path = "/newly-added-path-1"});
    try pro_arr.append(allocator, .{ .name = "newly added 2", .path = "/newly-added-path-2"});
    try delete_project(allocator, pro_arr.items, 0, constants.test_json_file_path);
}

test "edit_project" {
    const allocator = std.testing.allocator;
    var pro_arr : std.ArrayList(types.Project) = .empty;
    defer pro_arr.deinit(allocator);
    try pro_arr.append(allocator, .{ .name = "newly added 1", .path = "/newly-added-path-1"});
    try pro_arr.append(allocator, .{ .name = "newly added 2", .path = "/newly-added-path-2"});
    const edited_project: types.Project = .{
        .name = "edited",
        .path = "/mmm/edited"
    };
    try edit_project(allocator, pro_arr.items, edited_project, 0, constants.test_json_file_path);
}


test "add_project" {
    const allocator = std.testing.allocator;
    var pro_arr : std.ArrayList(types.Project) = .empty;
    defer pro_arr.deinit(allocator);
    try pro_arr.append(allocator, .{ .name = "newly added 1", .path = "/newly-added-path-1"});
    try pro_arr.append(allocator, .{ .name = "newly added 2", .path = "/newly-added-path-2"});
    const new_project: types.Project = .{
        .name = "added",
        .path = "/mmm/added"
    };
    try add_project(allocator, pro_arr.items, new_project, constants.test_json_file_path);
}
