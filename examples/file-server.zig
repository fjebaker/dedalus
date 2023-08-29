const std = @import("std");
const dedalus = @import("dedalus");

const address = std.net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 8044);

fn startServer() !void {
    var alloc = std.heap.c_allocator;

    var server = try dedalus.Server.init(
        alloc,
        .{
            .private_key = "key.rsa",
            .certificate = "cert.pem",
            .address = address,
        },
    );
    defer server.deinit();

    try server.start();
    std.debug.print("Listening\n", .{});

    while (true) {
        var req = server.accept() catch {
            continue;
        };
        defer req.deinit();

        if (std.mem.eql(u8, req.uri.path, "/")) {
            try req.respond(.{ .content = "Hello" });
        } else {
            try req.respond(.{ .status = .NOT_FOUND });
        }
    }
}

pub fn main() !void {
    try dedalus.init();
    defer dedalus.deinit();

    // const ret = dedalus.zzl.c.wolfSSL_Debugging_ON();
    // std.debug.print("DEBUG: {d}\n", .{ret});
    // defer dedalus.zzl.c.wolfSSL_Debugging_OFF();

    try startServer();
}
