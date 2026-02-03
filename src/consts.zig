const std = @import("std");

pub const config_file_path = "~/.config/meowmux/projects.json";
pub const test_json_file_path = "test/test.json";


pub const app_title_str = "Select a Project (j/k or arrows, Enter to select, q to quit)";

pub const indent = "    ";

// for raw mode, we cannot use multilinne strings.
pub const app_state_str = 
    indent ++ "MEOWMUX - tmux project manager" ++
    "\r\n\r\n" ++
    indent ++ "choose action (type one: o, Enter, a, d, e) (quit: type 'q' or 'ctrl c')" ++
    "\r\n\r\n" ++
    indent ++ "open project(o, Enter),   add project(a),   delete project(d),   edit project(e)"
;



