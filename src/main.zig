const std = @import("std");

pub const ssl = @import("zigwolfssl");
pub const gemini = @import("gemini.zig");

/// Setup the underlying TLS library
///
pub fn init() !void {
    try ssl.init();
}

/// Cleanup the underlying TLS library
///
pub fn deinit() void {
    ssl.deinit();
}

test "test-server" {
    var listener = try gemini.Listener.init(
        std.testing.allocator,
        .{
            .private_key = "./key.rsa",
            .certificate = "cert.pem",
        },
    );
    defer listener.deinit();

    try listener.start();
    defer listener.stop();

    // var req = listener.accept();
    // std.debug.print(""
}
