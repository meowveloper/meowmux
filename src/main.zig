const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("consts.zig");
const read = @import("read.zig");


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try read.get_projects(allocator);
}
