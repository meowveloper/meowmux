const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("consts.zig");
const types = @import("types.zig");


pub fn get_projects (allocator: std.mem.Allocator) !std.json.Parsed([]types.Project) {
    var string: std.io.Writer.Allocating = .init(allocator);
    defer string.deinit();

    const expanded = try utils.ExpandedPath.get_path(allocator, constants.file_path);
    defer expanded.deinit();

    const file = std.fs.cwd().openFile(expanded.path, .{ .mode = .read_only }) catch {
        try utils.print("cannot open the file at {s}\n", .{expanded.path});
        return error.FileNotFound;
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
        []types.Project,
        allocator,
        result,
        .{},
    ) catch {
        try utils.print("invalid json structure\n", .{});
        return error.InvalidJSON;
    };
    return parsed;
}
