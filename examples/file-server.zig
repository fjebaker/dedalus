const std = @import("std");
const dedalus = @import("dedalus");

pub fn main() !void {
    try dedalus.init();
    defer dedalus.deinit();
}
