const std = @import("std");

pub const config_file_path = "~/.config/meowmux/projects.json";
pub const test_json_file_path = "test.json";


pub const app_title_str = "MEOWMUX - Select a Project (j/k or arrows, Enter to select, q to quit)\r\n\r\n";

pub const indent = "    ";

// for raw mode, we cannot use multilinne strings.
pub const app_state_str = 
    indent ++ "MEOWMUX - Select a Project (j/k or arrows, Enter to select, q to quit)" ++
    "\r\n\r\n" ++
    indent ++ "choose action (type one: o, Enter, a, d, e)" ++
    "\r\n\r\n" ++
    indent ++ "open(o, Enter),   add project(a),   delete project(d),   edit project(e)" ++
    "\r\n\r\n"
;

test "test print" {
    std.debug.print("{s}", .{app_state_str});
}


