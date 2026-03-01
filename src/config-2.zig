const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("consts.zig");
const types = @import("types.zig");


pub fn save_to_config(gpa: std.mem.Allocator, projects: types.Projects, config_path: []const u8) !void {
    const extended_path = try utils.ExpandedPath.get_path(gpa, config_path);
    defer extended_path.deinit();
    const path = extended_path.path;

    if(projects.json_str) |data| {
        try std.fs.cwd().writeFile(.{
            .data = data,
            .flags = .{},
            .sub_path = path
        });
    }
}

pub fn get_projects_from_config(gpa: std.mem.Allocator, config_path: []const u8) !types.Projects {
    const extended_path = try utils.ExpandedPath.get_path(gpa, config_path);
    defer extended_path.deinit();
    const path = extended_path.path;
    const file_contents = try std.fs.cwd().readFileAlloc(gpa, path, 1024 * 20);
    defer gpa.free(file_contents);
    return try types.Projects.init_from_json(gpa, file_contents);
}

var test_projects = [_]types.Project{
    .{ .name = "hello1", .path = "/world1" },
    .{ .name = "hello2", .path = "/world2" },
};

test "save" {
    const gpa = std.testing.allocator;
    var projects = types.Projects.init(gpa);
    defer projects.deinit();
    try projects.add_many(&test_projects);
    try save_to_config(gpa, projects, constants.test_json_file_path);
    const file_contents = try std.fs.cwd().readFileAlloc(gpa, constants.test_json_file_path, 1024 * 20);
    defer gpa.free(file_contents);
    std.debug.print("{s}\n", .{ file_contents });
}

test "get" {
    const gpa = std.testing.allocator;
    var projects = try get_projects_from_config(gpa, constants.test_json_file_path);
    defer projects.deinit();
    if (projects.json_str) |str| std.debug.print("{s}\n", .{str})
    else std.debug.print("no projects found\n", .{});
}
