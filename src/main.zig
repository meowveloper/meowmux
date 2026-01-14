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
}
