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

pub const ListenerError = error{NotListening};

pub const Listener = struct {
    allocator: std.mem.Allocator,
    // options
    context: ssl.Context,
    server: std.net.StreamServer,
    address: std.net.Address,

    listening: bool = false,

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
        if (self.listening) self.stop();
        self.server.deinit();
        self.context.deinit();
        self.* = undefined;
    }

    pub fn start(self: *Listener) !void {
        try self.server.listen(self.address);
        self.listening = true;
        std.debug.print("L: listening...\n", .{});
    }

    pub fn stop(self: *Listener) void {
        std.debug.print("L: Closed\n", .{});
        self.listening = false;
        self.server.close();
    }

    pub fn accept(self: *Listener) !Request {
        if (!self.listening) return ListenerError.NotListening;

        var mem = std.heap.ArenaAllocator.init(self.allocator);
        errdefer mem.deinit();
        var alloc = mem.allocator();

        const tcp_conn = try self.server.accept();
        var conn = self.context.newSslConnection(tcp_conn.stream);
        errdefer conn.close();

        std.debug.print("L: TLS connection accepted\n", .{});

        var message = try conn.reader().readAllAlloc(alloc, 4096);
        errdefer self.allocator.free(message);

        _ = try conn.write("Thanks!");

        std.debug.print("L: {d} read : {s}\n", .{ message.len, message });

        return .{
            .mem = mem,
            .conn = conn,
            .content = message,
        };
    }
};

pub const Request = struct {
    mem: std.heap.ArenaAllocator,
    conn: ssl.SslConnection,
    content: []u8,

    pub fn deinit(self: *Request) void {
        std.debug.print("R: destroyed\n", .{});
        self.conn.close();
        self.mem.deinit();
        self.* = undefined;
    }
};
