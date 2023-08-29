const std = @import("std");

pub const gemini = @import("gemini.zig");
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
    pub const RequestError = error{MalformedUri};

    mem: std.heap.ArenaAllocator,
    conn: std.net.StreamServer.Connection,
    ssl: zzl.Ssl,

    content: []u8,
    uri: std.Uri,

    pub fn init(
        mem: *std.heap.ArenaAllocator,
        conn: *std.net.StreamServer.Connection,
        ssl: *zzl.Ssl,
    ) !Request {
        var alloc = mem.allocator();

        var buff: [4096]u8 = undefined;
        const size = try ssl.read(&buff);
        std.debug.print("Read {d} bytes\n", .{size});

        var content = try alloc.dupe(u8, buff[0..size]);
        errdefer alloc.free(content);

        // parse URI
        var uri = std.Uri.parse(content) catch |err| {
            std.debug.print("ERR: {!}\n", .{err});
            try writeResponse(ssl.writer(), .{
                .status = .BAD_REQUEST,
                .content = "",
                .meta = "Malformed URI",
            });
            return RequestError.MalformedUri;
        };

        return .{
            .mem = mem.*,
            .conn = conn.*,
            .ssl = ssl.*,
            .content = content,
            .uri = uri,
        };
    }

    pub fn deinit(self: *Request) void {
        self.ssl.deinit();
        self.conn.stream.close();
        self.mem.deinit();
        self.* = undefined;
    }

    fn writeResponse(writer: anytype, response: Response) !void {
        try response.formatMeta(writer);
        try writer.writeAll(response.content);
    }

    pub fn respond(self: *Request, response: Response) !void {
        try writeResponse(self.ssl.writer(), response);
    }
};

pub const Response = struct {
    status: gemini.StatusCodes = .SUCCESS,
    content: []const u8,
    mime: []const u8 = "text/gemini; charset=utf8",
    meta: ?[]const u8 = null,

    pub fn formatMeta(self: *const Response, writer: anytype) !void {
        const meta = if (self.meta) |m| m else self.mime;
        try writer.print("{d:0>2} {s}\r\n", .{ @intFromEnum(self.status), meta });
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

        std.debug.print("Accepted connection\n", .{});

        var ssl = zzl.Ssl.init(self.context, conn.stream);
        errdefer ssl.deinit();

        var mem = std.heap.ArenaAllocator.init(self.allocator);
        errdefer mem.deinit();

        // pass pointers on the stack
        var req = try Request.init(&mem, &conn, &ssl);
        std.debug.print("Processed request\n", .{});
        return req;
    }
};
