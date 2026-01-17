const std = @import("std");
const utils = @import("utils.zig");
const tmux = @import("tmux.zig");
const tui = @import("tui.zig");
const config = @import("config.zig");
const constants = @import("consts.zig");
const app = @import("app.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const app_state = try app.open_app_state_selector_ui(allocator);
    _ = app_state;

    const parsed_projects = try config.get_projects(allocator, constants.config_file_path);
    defer parsed_projects.deinit();
    const projects = parsed_projects.value;

    const selected_index = try app.open_selector_ui(allocator, projects);

    if(selected_index) |index| {
        try tmux.open_tmux_session(allocator, projects[index].name, projects[index].path);
    } 
}
