const std = @import("std");
const types = @import("types.zig");
const utils = @import("utils.zig");

pub const Key = union(enum) {
    char: u8,
    up,
    down,
    enter,
    esc,
    ctrl_c,
    unknown,
};

pub const Tui = struct {
    allocator: std.mem.Allocator,
    original_termios: std.posix.termios,
    stdin: std.fs.File,

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
    }

    pub fn read_key(self: *Tui) !Key {
        var buf: [8]u8 = undefined;
        const n = try self.stdin.read(&buf);
        if (n == 0) return .unknown;

        if (buf[0] == 27) { // ESC
            if (n == 1) return .esc;
            if (n >= 3 and buf[1] == '[') {
                switch (buf[2]) {
                    'A' => return .up,
                    'B' => return .down,
                    else => {},
                }
            }
            return .esc;
        }

        if (buf[0] == '\r' or buf[0] == '\n') return .enter;
        if (buf[0] == 3) return .ctrl_c; // Ctrl+C
        if (buf[0] >= 32 and buf[0] <= 126) return .{ .char = buf[0] };

        return .unknown;
    }

    fn clear_screen(_: *Tui) !void {
        try utils.print("\x1b[2J\x1b[H", .{});
    }

    pub fn render(self: *Tui, projects: []types.Project, selected_index: usize) !void {
        try self.clear_screen();
        try utils.print("MEOWMUX - Select a Project (j/k or arrows, Enter to select, q to quit)\r\n\r\n", .{});

        for (projects, 0..) |project, i| {
            if (i == selected_index) {
                try utils.print("> {s} ({s})\r\n", .{ project.name, project.path });
            } else {
                try utils.print("  {s} ({s})\r\n", .{ project.name, project.path });
            }
        }
    }
};
