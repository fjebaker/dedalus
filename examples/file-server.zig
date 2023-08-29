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

    var buffer: [2048]u8 = undefined;
    while (true) {
        var req = try server.accept();
        defer req.deinit();

        const size = try req.ssl.read(&buffer);
        std.debug.print("R: {d} {s}\n", .{ size, buffer[0..size] });

        const out = try req.ssl.write("Thanks you!\n");
        std.debug.print("W: {d}\n", .{out});
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
