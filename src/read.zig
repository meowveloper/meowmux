const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("consts.zig");

const Project = struct { name: []u8, path: []u8 };

pub fn get_projects (allocator: std.mem.Allocator) !void {
    var string: std.io.Writer.Allocating = .init(allocator);
    defer string.deinit();

    const file = std.fs.cwd().openFile(constants.file_path, .{ .mode = .read_only }) catch {
        try utils.print("cannot open the file at {s}\n", .{constants.file_path});
        return;
    };
    defer file.close();

    var buffer: [4096]u8 = undefined;
    var reader = file.reader(&buffer);

    try file.seekTo(0);
    while (try reader.interface.takeDelimiter('\n')) |line| {
        try string.writer.print("{s}\n", .{line});
    }

    const result = string.written();

    const parsed = std.json.parseFromSlice(
        []Project,
        allocator,
        result,
        .{},
    ) catch {
        try utils.print("invalid json structure\n", .{});
        return;
    };
    defer parsed.deinit();
    const projects: []Project = parsed.value;

    for(projects, 0..projects.len) |project, i| {
        try utils.print("{d}. name: {s}, path: {s}\n", .{i + 1, project.name, project.path});
    }
}
