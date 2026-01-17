const std = @import("std");
const tui = @import("tui.zig");
const types = @import("types.zig");

pub fn open_app_state_selector_ui (allocator: std.mem.Allocator) !?types.App_State {
    var ui = try tui.Tui.init(allocator);
    defer ui.deinit();

    while(true) {
        try ui.render_app_states();
        const key = try ui.read_key();
        switch (key) {
            .ctrl_c => return null,
            .enter => return .open,
            .esc => return null,
            .char => |c| {
                switch (c) {
                    'o' => return .open,
                    'd' => return .delete,
                    'e' => return .edit,
                    'a' => return .add,
                    'q' => return null,
                    else => {}
                }
            },
            else => {}
        }
    }
}

pub fn open_selector_ui(allocator: std.mem.Allocator, projects: []types.Project) !?usize {
    var ui = try tui.Tui.init(allocator);
    defer ui.deinit();

    var selected_index: usize = 0;

    while (true) {
        try ui.render_list(projects, selected_index);
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
                    return null;
                }
            },
            .enter => {
                return selected_index;
            },
            .ctrl_c => return null,
            else => {},
        }
    }
}
