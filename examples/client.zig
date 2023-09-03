const std = @import("std");
const dedalus = @import("dedalus");

pub fn main() !void {
    try dedalus.init();
    defer dedalus.deinit();

    var alloc = std.heap.c_allocator;

    var args = std.process.args();
    // lose program name
    _ = args.next();

    var uri = try std.Uri.parse(args.next() orelse "gemini://localhost:1965");
    if (uri.port == null) uri.port = 1965;
    std.debug.print(
        "Connecting to '{?s}:{d}{s}'\n",
        .{ uri.host.?, uri.port.?, uri.path },
    );

    var client = try dedalus.Client.init(alloc, uri);
    defer client.deinit();

    var resp = try client.fetch();

    std.debug.print(
        "Repsonse: {any}\nContent:\n{s}\n",
        .{ resp.status, resp.content },
    );
}
