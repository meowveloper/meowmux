const std = @import("std");
const types = @import("types.zig");
const utils = @import("utils.zig");
const config = @import("config.zig");
const constants = @import("consts.zig");

pub const Key = union(enum) {
    char: u8,
    up,
    down,
    enter,
    esc,
    ctrl_c,
    unknown,
    backspace,
    tab,
};

pub const Tui = struct {
    allocator: std.mem.Allocator,
    original_termios: std.posix.termios,
    stdin: std.fs.File,

    fn clear_screen(_: *Tui) !void {
        try utils.print("\x1b[2J\x1b[H", .{});
    }

    pub fn init(allocator: std.mem.Allocator) !Tui {
        const stdin = std.fs.File.stdin();
        const original = try std.posix.tcgetattr(stdin.handle);

        var raw = original;
        // Local flags: disable echo, canonical mode, extended functions, and signals
        raw.lflag.ECHO = false;
        raw.lflag.ICANON = false;
        raw.lflag.IEXTEN = false;
        raw.lflag.ISIG = false;

        // Input flags: disable break condition, parity, strip, and flow control
        raw.iflag.IXON = false;
        raw.iflag.ICRNL = false;
        raw.iflag.BRKINT = false;
        raw.iflag.INPCK = false;
        raw.iflag.ISTRIP = false;

        // Output flags: disable post-processing
        raw.oflag.OPOST = false;

        // Control flags: set character size to 8 bits
        raw.cflag.CSIZE = .CS8;

        // VMIN and VTIME
        raw.cc[@intFromEnum(std.posix.V.MIN)] = 0;
        raw.cc[@intFromEnum(std.posix.V.TIME)] = 1;

        try std.posix.tcsetattr(stdin.handle, .FLUSH, raw);

        return Tui{
            .allocator = allocator,
            .original_termios = original,
            .stdin = stdin,
        };
    }

    pub fn deinit(self: *Tui) void {
        std.posix.tcsetattr(self.stdin.handle, .FLUSH, self.original_termios) catch {};
        utils.print("\n", .{}) catch {};
    }

    pub fn read_key(self: *Tui) !Key {
        var buf: [8]u8 = undefined;
        const n = try self.stdin.read(&buf);
        return parse_sequence(buf[0..n]);
    }


    pub fn render_list(self: *Tui, projects: []types.Project, selected_index: usize, info: []const u8) !void {
        try self.clear_screen();
        try utils.print("\r\n{s}\r\n\r\n", .{constants.app_title_str});
        try utils.print("{s}\r\n\r\n", .{info});

        for (projects, 0..) |project, i| {
            if (i == selected_index) {
                try utils.print("> {s} ({s})\r\n", .{ project.name, project.path });
            } else {
                try utils.print("  {s} ({s})\r\n", .{ project.name, project.path });
            }
        }
    }

    pub fn render_input(_: *Tui, value: std.ArrayList(u8), prompt: []const u8) !void {
        try utils.print("\r\x1b[K{s}{s}", .{ prompt, value.items });
    }

    pub fn render_app_states (self: *Tui) !void {
        try self.clear_screen();
        try utils.print("\r\n{s}\r\n", .{constants.app_state_str});
    }
};

pub fn parse_sequence (buf: []const u8) Key {
    if(buf.len == 0) return .unknown; 
    if(buf[0] == 27) {
        if (buf.len == 1) return .esc;
        if (buf.len >= 3 and buf[1] == '[') {
            switch (buf[2]) {
                'A' => return .up,
                'B' => return .down,
                else => {},
            }
        }
        return .esc;
    }
    switch (buf[0]) {
        '\r', '\n' => return .enter,
        3 => return .ctrl_c,
        9 => return .tab,
        32...126 => return .{ .char = buf[0] },
        127 => return .backspace,
        else => return .unknown,
    }
}

test "parse_sequence" {
    const testing = std.testing;

    // Arrows
    try testing.expectEqual(Key.up, parse_sequence("\x1b[A"));
    try testing.expectEqual(Key.down, parse_sequence("\x1b[B"));

    // Special
    try testing.expectEqual(Key.esc, parse_sequence("\x1b"));
    try testing.expectEqual(Key.enter, parse_sequence("\r"));
    try testing.expectEqual(Key.enter, parse_sequence("\n"));
    try testing.expectEqual(Key.ctrl_c, parse_sequence(&[_]u8{3}));

    // Chars
    const q_key = parse_sequence("q");
    try testing.expectEqual(Key{ .char = 'q' }, q_key);
}
