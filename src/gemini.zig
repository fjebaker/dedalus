const std = @import("std");
const ssl = @import("zigwolfssl");

pub const ListenerOptions = struct {
    address: std.net.Address =
        std.net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 1961),
    server_options: std.net.StreamServer.Options =
        .{ .reuse_address = true },
    private_key: [:0]const u8,
    certificate: [:0]const u8,
};

pub const Listener = struct {
    allocator: std.mem.Allocator,
    // options
    context: ssl.Context,
    server: std.net.StreamServer,
    address: std.net.Address,

    pub fn init(allocator: std.mem.Allocator, opts: ListenerOptions) !Listener {
        var context = try ssl.Context.init(.TLSv1_3_Server);
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

    pub fn deinit(self: *Listener) void {
        self.stop();
        self.server.deinit();
        self.context.deinit();
        self.* = undefined;
    }

    pub fn start(self: *Listener) !void {
        try self.server.listen(self.address);
    }

    pub fn stop(self: *Listener) void {
        self.server.close();
    }

    pub fn accept(self: *Listener) !Request {
        const tcp_conn = try self.server.accept();
        const conn = self.context.newSslConnection(tcp_conn.stream);
        errdefer conn.close();

        var mem = std.heap.ArenaAllocator.init(self.allocator);
        errdefer mem.deinit();
        return Request.init(mem, conn);
    }
};

pub const Request = struct {
    mem: std.heap.ArenaAllocator,
    conn: ssl.SslConnection,

    content: []u8 = "",

    fn readRequest(self: *Request) !void {
        var reader = self.conn.reader();
        self.content = try reader.readAllAlloc(self.mem.allocator(), 4096);
    }

    pub fn init(mem: std.heap.ArenaAllocator, conn: ssl.SslConnection) !Request {
        var self: Request = .{
            .mem = mem,
            .conn = conn,
        };
        self.readRequest();
        return self;
    }

    pub fn deinit(self: *Request) void {
        self.conn.close();
        self.mem.deinit();
        self.* = undefined;
    }
};
