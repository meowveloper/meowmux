const std = @import("std");

pub fn print(comptime fmt: []const u8, args: anytype) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print(fmt, args);
    try stdout.flush();
}

pub fn get_user_input(buffer: []u8) ![]const u8 {
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

    pub fn get_path(allocator: std.mem.Allocator, path: []const u8) !ExpandedPath {
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

pub fn get_suggested_path(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    const extended_path = try ExpandedPath.get_path(allocator, input);
    defer extended_path.deinit();

    const prefix: []const u8 = std.fs.path.basename(extended_path.path);
    var result: []const u8 = undefined;

    if (std.fs.path.dirname(extended_path.path)) |path| {
        var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
        defer dir.close();
        var iterator = dir.iterate();
        while (try iterator.next()) |entry| {
            if (std.mem.eql(u8, entry.name, prefix)) continue;
            if (std.mem.startsWith(u8, entry.name, prefix)) {
                result = entry.name;
                break;
            }
            result = "";
        }
    }
    return result;
}

test "get_suggested_path" {
    const allocator = std.testing.allocator;
    const result = try get_suggested_path(allocator, "/home/meowveloper");
    std.debug.print("res: {s}\n\n", .{result});
}
