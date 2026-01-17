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

pub fn delete_project(allocator: std.mem.Allocator, projects: []types.Project, index: usize, config_path: []const u8) !void {
    const proj_arr : std.ArrayList(types.Project) = .empty;
    defer proj_arr.deinit(allocator);
    for (projects, 0..projects.len) |pro, i| {
        if(i != index) try proj_arr.append(allocator, pro);
    }
    try save_projects(allocator, proj_arr.items, config_path);
}



