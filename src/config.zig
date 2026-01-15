const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("consts.zig");
const types = @import("types.zig");

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

pub fn save_projects(allocator: std.mem.Allocator, projects: []const types.Project, config_path: []const u8) !void {
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

const test_json_file_path = "test.json";

test "save_projects" {
    const allocator = std.testing.allocator;
    const project_a = types.Project{
        .name = "test a",
        .path = "/test-path-a"
    };
    const project_b = types.Project{
        .name = "test b",
        .path = "/test-path-b"
    };
    const projs : [2]types.Project = .{project_a, project_b};

    try save_projects(allocator, &projs, test_json_file_path);
}

test "get_projects" {
    const allocator = std.testing.allocator;
    const parsed_projects = try get_projects(allocator, test_json_file_path);
    defer parsed_projects.deinit();
    const projects = parsed_projects.value;
    for(projects, 0..) |project, i| {
        std.debug.print("{d}. {s} ({s})\n", .{ i + 1, project.name, project.path});
    }
}

