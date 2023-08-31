const std = @import("std");

const WHITESPACE = [_]u8{ ' ', '\n', '\r', '\t', 10, 13 };

pub fn trimWhitespaces(s: []const u8) []const u8 {
    const start: usize = blk: {
        for (s, 0..) |c, i| {
            if (std.mem.indexOfScalar(u8, &WHITESPACE, c) == null)
                break :blk i;
        }
        // only whitespace
        return "";
    };
    const end: usize = blk: {
        for (s[start..], start..) |c, i| {
            if (std.mem.indexOfScalar(u8, &WHITESPACE, c) != null) {
                break :blk i;
            }
        }
        break :blk s.len;
    };
    return s[start..end];
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

test "whitespace-cleaning" {
    try std.testing.expectEqualStrings("hello", trimWhitespaces("hello    "));
    try std.testing.expectEqualStrings("hello", trimWhitespaces("hello \n \r   \t   "));
    try std.testing.expectEqualStrings("hello", trimWhitespaces("hello\r\r\n"));
}
