const std = @import("std");

pub const Project = struct { name: []const u8, path: []const u8 };

pub const Projects = struct {
    gpa: std.mem.Allocator,
    list: std.ArrayList(Project),
    json_str: ?[]u8 = null,

    const Self = @This();

    pub fn init(gpa: std.mem.Allocator) Self {
        return .{ .list = std.ArrayList(Project).empty, .gpa = gpa };
    }

    pub fn init_from_json(gpa: std.mem.Allocator, json: []u8) !Self {
        var projects = init(gpa);
        const parsed_projects: std.json.Parsed([]Project) = std.json.parseFromSlice([]Project, gpa, json, .{ 
            .allocate = .alloc_always
        }) catch return projects;
        defer parsed_projects.deinit();

        try projects.add_many(parsed_projects.value);
        return projects;
    }

    pub fn deinit(self: *Self) void {
        self.list.deinit(self.gpa);
        if(self.json_str) |js| {
            self.gpa.free(js);
        }
    }

    pub fn add(self: *Self, project: Project) !void {
        try self.list.append(self.gpa, project);
        try self.to_json();
    }

    pub fn edit(self: *Self, index: usize, new_pro: Project) !void {
        _ = self.list.orderedRemove(index);
        try self.list.insert(self.gpa, index, new_pro);
        try self.to_json();
    }

    pub fn add_many(self: *Self, projects: []Project) !void {
        try self.list.appendSlice(self.gpa, projects);
        try self.to_json();
    }

    pub fn delete(self: *Self, index: usize) !void {
        _ = self.list.orderedRemove(index);
        try self.to_json();
    }

    pub fn items(self: *Self) []Project {
        return self.list.items;
    }

    fn to_json(self: *Self) !void {
        if(self.json_str) |js| {
            self.gpa.free(js);
        }
        const json = try std.fmt.allocPrint(self.gpa, "{f}\n", .{std.json.fmt(self.items(), .{ .whitespace = .indent_4 })});
        self.json_str = json;
    }
};

pub const App_State = union(enum) { open, delete, edit, add };


var test_projects = [_]Project{
    .{ .name = "hello1", .path = "/world1" },
    .{ .name = "hello2", .path = "/world2" },
};

test "add" {
    const gpa = std.testing.allocator;
    var projects = Projects.init(gpa);
    defer projects.deinit();
    try projects.add_many(&test_projects);
    std.debug.print("{s}\n", .{projects.json_str.?});
}

test "delete" {
    const gpa = std.testing.allocator;
    var projects = Projects.init(gpa);
    defer projects.deinit();
    try projects.add_many(&test_projects);
    try projects.delete(1);
    std.debug.print("{s}\n", .{projects.json_str.?});
}

test "edit" {
    const gpa = std.testing.allocator;
    var projects = Projects.init(gpa);
    defer projects.deinit();
    try projects.add_many(&test_projects);
    try projects.edit(1, .{ .name = "edited", .path = "/world" });
    std.debug.print("{s}\n", .{projects.json_str.?});
}
