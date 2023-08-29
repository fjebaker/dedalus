const std = @import("std");

pub const StatusCodes = enum(u8) {
    INPUT = 10,
    SENSITIVE_INPUT = 11,
    SUCCESS = 20,
    REDIRECT_TEMPORARY = 30,
    REDIRECT_PERMANENT = 31,
    TEMPORARY_FAILURE = 40,
    SERVER_UNAVAILABLE = 41,
    CGI_ERRO = 42,
    PROXY_ERROR = 43,
    SLOW_DOWN = 44,
    PERMANENT_FAILURE = 50,
    NOT_FOUND = 51,
    GONE = 52,
    PROXY_REQUEST_REFUSED = 53,
    BAD_REQUEST = 59,
    CLIENT_CERTIFICATE_REQUIRED = 60,
    CERTIFICATE_NOT_AUTHORISED = 61,
    CERTIFICATE_NOT_VALID = 62,

    pub fn toString(self: StatusCodes) []const u8 {
        switch (self) {
            else => |t| return @tagName(t),
        }
    }

    pub fn toInt(self: StatusCodes) u8 {
        return @intFromEnum(self);
    }
};

pub const StatusClass = enum(u8) {
    INPUT = 1,
    SUCCESS = 2,
    REDIRECT = 3,
    FAILURE_TEMPORARY = 4,
    FAILURE_PERMANENT = 5,
    CLIENT_CERTIFICATE_REQUIRED = 6,
};
