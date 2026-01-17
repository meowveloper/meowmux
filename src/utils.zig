const std = @import("std");

pub fn print(comptime fmt: []const u8, args: anytype) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print(fmt, args);
    try stdout.flush(); 
}

pub fn get_user_input (buffer: []u8) ![]const u8 {
    var stdin_reader = std.fs.File.stdin().reader(buffer);
    const stdin = &stdin_reader.interface;
    const line_raw = try stdin.takeDelimiter('\n');
    const line = std.mem.trim(u8, line_raw.?, &std.ascii.whitespace);
    return line;
}


pub const ExpandedPath = struct {
    path: []u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: ExpandedPath) void {
        self.allocator.free(self.path);
    }
    
    pub fn get_path (allocator: std.mem.Allocator, path: []const u8) !ExpandedPath {
        var result_path: []u8 = undefined;
        if (std.mem.startsWith(u8, path, "~/")) {
            const home = std.posix.getenv("HOME") orelse return error.HomeNotFound;
            result_path = try std.fs.path.join(allocator, &[_][]const u8{ home, path[1..] });
        } else {
            result_path = try allocator.dupe(u8, path);
        }
        return ExpandedPath{ .path = result_path, .allocator = allocator };
    }
};

