pub const Project = struct { name: []const u8, path: []const u8 };

pub const App_State = union(enum) {
    open,
    delete,
    edit,
    add
};
