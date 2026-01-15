const std = @import("std");
const utils = @import("utils.zig");
const read = @import("read.zig");
const tmux = @import("tmux.zig");
const tui = @import("tui.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const parsed_projects = try read.get_projects(allocator);
    defer parsed_projects.deinit();
    const projects = parsed_projects.value;

    var ui = try tui.Tui.init(allocator);
    defer ui.deinit();

    var selected_index: usize = 0;

    while (true) {
        try ui.render(projects, selected_index);
        const key = try ui.read_key();

        switch (key) {
            .up => {
                if (selected_index > 0) {
                    selected_index -= 1;
                } else {
                    selected_index = projects.len - 1;
                }
            },
            .down => {
                if (selected_index < projects.len - 1) {
                    selected_index += 1;
                } else {
                    selected_index = 0;
                }
            },
            .char => |c| {
                if (c == 'k') {
                    if (selected_index > 0) {
                        selected_index -= 1;
                    } else {
                        selected_index = projects.len - 1;
                    }
                } else if (c == 'j') {
                    if (selected_index < projects.len - 1) {
                        selected_index += 1;
                    } else {
                        selected_index = 0;
                    }
                } else if (c == 'q') {
                    return;
                }
            },
            .enter => {
                // Restore terminal before spawning tmux
                ui.deinit();
                try tmux.open_tmux_session(allocator, projects[selected_index].name, projects[selected_index].path);
                // After tmux exits, re-init TUI
                ui = try tui.Tui.init(allocator);
            },
            .ctrl_c => return,
            else => {},
        }
    }
}
