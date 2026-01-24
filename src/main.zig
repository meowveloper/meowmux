const std = @import("std");
const utils = @import("utils.zig");
const tmux = @import("tmux.zig");
const config = @import("config.zig");
const constants = @import("consts.zig");
const app = @import("app.zig");
const types = @import("types.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const app_state = try app.open_app_state_selector_ui(allocator);

    const parsed_projects = try config.get_projects(allocator, constants.config_file_path);
    defer parsed_projects.deinit();
    const projects = parsed_projects.value;

    if (app_state) |as| {
        switch (as) {
            .open => {
                const selected_index = try app.open_selector_ui(allocator, projects);

                if (selected_index) |index| {
                    try tmux.open_tmux_session(allocator, projects[index].name, projects[index].path);
                }
            },
            .delete => {
                const selected_index = try app.open_selector_ui(allocator, projects);

                if (selected_index) |index| {
                    try config.delete_project(allocator, projects, index, constants.config_file_path);
                }
            },
            .add => {
                try utils.print("add a new project\n", .{});
                try utils.print("name: ", .{});
                var name_buffer: [1024]u8 = undefined;
                const name = try utils.get_user_input(&name_buffer);
                try utils.print("path:  ", .{});
                var path_buffer: [1024]u8 = undefined;
                const path = try utils.get_user_input(&path_buffer);
                const new_project: types.Project = .{
                    .name = name,
                    .path = path
                };
                try config.add_project(allocator, projects, new_project, constants.config_file_path);
            },
            .edit => {
                const selected_index = try app.open_selector_ui(allocator, projects);
                if(selected_index) |index| {
                    var name : std.ArrayList(u8) = .empty;
                    defer name.deinit(allocator);
                    try name.appendSlice(allocator, projects[index].name);
                    try app.open_input(allocator, &name, "name: ");

                    var path: std.ArrayList(u8) = .empty;
                    defer path.deinit(allocator);
                    try path.appendSlice(allocator, projects[index].path);
                    try app.open_input(allocator, &path, "path: ");

                    const new_project: types.Project = .{
                        .name = name.items,
                        .path = path.items
                    };

                    try config.edit_project(allocator, projects, new_project, index, constants.config_file_path);
                }
            }
        }
    }
}
