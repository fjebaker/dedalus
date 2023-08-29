const std = @import("std");

pub fn trimWhitespaces(s: []const u8) []const u8 {
    const out = std.mem.trim(u8, s, &[_]u8{ ' ', '\n', '\r', '\t' });
    return out;
}

pub fn cleanPath(s: []const u8) []const u8 {
    if (s.len == 0) return "/";
    const start = blk: {
        // deduplicate '/' at start of path
        var has_content: bool = false;
        for (s, 0..) |c, i| {
            if (i == 0) {
                if (c == '/') continue;
                break :blk i;
            } else {
                if (c != '/') {
                    has_content = true;
                    if (s[i - 1] == '/') {
                        break :blk i - 1;
                    }
                }
            }
        }
        if (has_content) break :blk 0;
        // everything is just '/'
        return "/";
    };

    return s[start..];
}

test "clean-paths" {
    try std.testing.expectEqualStrings("/", cleanPath("///"));
    try std.testing.expectEqualStrings("/asdasd/", cleanPath("//asdasd/"));
    try std.testing.expectEqualStrings("/", cleanPath("/"));
    try std.testing.expectEqualStrings("/", cleanPath(""));
    try std.testing.expectEqualStrings("/hello//world", cleanPath("///hello//world"));
}
