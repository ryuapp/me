// Copyright (C) 2023-2024 ryu. All rights reserved. MIT license.
const std = @import("std");
const cat = @import("cat.zig").cat;

const fs = std.fs;
const debug = std.debug;
const is_windows = @import("builtin").os.tag == .windows;

const NAME = "me";
const VERSION = "0.1.1";
const USAGE = "Usage: " ++ NAME ++ " [OPTION]... [FILE]...";
const DESCRIPTION = "Print FILE(s) to standard output.";
const INFO = NAME ++ ": try \'me --help\' for more information";

// TODO: To local scope
var default_cp: c_uint = 65001;

fn printUsage() void {
    debug.print("{s}\n", .{USAGE});
    debug.print("{s}", .{INFO});
}
fn printHelp() !void {
    const stdout = std.io.getStdOut().writer();
    const options =
        \\  -n, --number   Print number all output lines
        \\      --help     Print help
        \\      --version  Print version
    ;

    try stdout.print("{s}\n{s}\n\n{s}", .{ USAGE, DESCRIPTION, options });
}
fn printVersion() !void {
    try std.io.getStdOut().writer().print("me {s}", .{VERSION});
}

fn exit(code: u8) void {
    if (comptime is_windows) {
        _ = std.os.windows.kernel32.SetConsoleOutputCP(default_cp);
    }
    std.os.exit(code);
}

// Make a console output code is the same as before execution
fn setAbortSignalHandler(comptime handler: *const fn () void) !void {
    const handler_routine = struct {
        fn handler_routine(dwCtrlType: std.os.windows.DWORD) callconv(std.os.windows.WINAPI) std.os.windows.BOOL {
            if (dwCtrlType == std.os.windows.CTRL_C_EVENT) {
                handler();
                return std.os.windows.TRUE;
            } else {
                return std.os.windows.FALSE;
            }
        }
    }.handler_routine;

    try std.os.windows.SetConsoleCtrlHandler(handler_routine, true);
}
fn abortSignalHandler() void {
    exit(0);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();
    const args = try std.process.argsAlloc(alc);

    // Set a console output code page to UTF-8
    if (comptime is_windows) {
        default_cp = std.os.windows.kernel32.GetConsoleOutputCP();
        try setAbortSignalHandler(abortSignalHandler);
        _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
    }

    defer std.process.argsFree(alc, args);
    if (args.len < 2) {
        printUsage();
        exit(2);
    }

    var files = std.ArrayList([]const u8).init(alc);
    // Arguments
    var has_numbers_flag = false;
    for (args[1..args.len]) |arg| {
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "--help")) {
                try printHelp();
                exit(0);
            } else if (std.mem.eql(u8, arg, "--version")) {
                try printVersion();
                exit(0);
            } else if (std.mem.eql(u8, arg, "-n") or std.mem.eql(u8, arg, "--number")) {
                has_numbers_flag = true;
            } else {
                debug.print("{s}: invalid option {s}\n", .{ NAME, arg });
                debug.print("{s}", .{INFO});
                exit(2);
            }
        } else {
            try files.append(arg);
        }
    }
    for (files.items) |filename| {
        try cat(alc, filename, .{ .number = has_numbers_flag });
    }
    files.deinit();
    exit(0);
}

test {
    _ = @import("cat.zig");
}
