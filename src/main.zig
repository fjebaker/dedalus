const std = @import("std");

pub const zzl = @import("zigwolfssl");

/// Setup the underlying TLS library
///
pub fn init() !void {
    try zzl.init();
}

/// Cleanup the underlying TLS library
///
pub fn deinit() void {
    zzl.deinit();
}

pub const Request = struct {
    ssl: zzl.Ssl,
    conn: std.net.StreamServer.Connection,

    pub fn deinit(self: *Request) void {
        self.ssl.deinit();
        self.conn.stream.close();
        self.* = undefined;
    }
};

pub const Server = struct {
    pub const ServerErrors = error{NotStarted};
    allocator: std.mem.Allocator,
    context: zzl.Context,
    server: std.net.StreamServer,
    address: std.net.Address,

    listening: bool = false,

    pub const Options = struct {
        address: std.net.Address =
            std.net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 1961),
        server_options: std.net.StreamServer.Options =
            .{ .reuse_address = true },
        private_key: [:0]const u8,
        certificate: [:0]const u8,
    };

    pub fn init(allocator: std.mem.Allocator, opts: Options) !Server {
        var context = try zzl.Context.init(.TLSv1_3_Server);
        errdefer context.deinit();

        try context.usePrivateKey(opts.private_key);
        try context.useCertificate(opts.certificate);

        var server = std.net.StreamServer.init(opts.server_options);
        return .{
            .allocator = allocator,
            .server = server,
            .context = context,
            .address = opts.address,
        };
    }

    pub fn deinit(self: *Server) void {
        if (self.listening) self.stop();
        self.server.deinit();
        self.context.deinit();
        self.* = undefined;
    }

    pub fn start(self: *Server) !void {
        try self.server.listen(self.address);
        self.listening = true;
    }

    pub fn stop(self: *Server) void {
        self.listening = false;
        self.server.close();
    }

    pub fn accept(self: *Server) !Request {
        if (!self.listening) return ServerErrors.NotStarted;

        var conn = try self.server.accept();
        errdefer conn.stream.close();

        var ssl = zzl.Ssl.init(self.context, conn.stream);
        errdefer ssl.deinit();

        return .{ .conn = conn, .ssl = ssl };
    }
};
