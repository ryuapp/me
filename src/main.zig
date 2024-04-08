// Copyright (C) 2023-2024 ryu. All rights reserved. MIT license.
const std = @import("std");
const Output = @import("output.zig").Output;
const cat = @import("cat.zig").cat;

const os = std.os;
const fs = std.fs;
const mem = std.mem;
const debug = std.debug;
const is_windows = @import("builtin").os.tag == .windows;

const NAME = "me";
const VERSION = "0.1.1";
const USAGE = "Usage: " ++ NAME ++ " [OPTION]... [FILE]...";
const DESCRIPTION = "Print FILE(s) to standard output.";
const INFO = NAME ++ ": try \'me --help\' for more information";

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
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();
    const args = try std.process.argsAlloc(alc);

    try Output.init();

    defer std.process.argsFree(alc, args);
    if (args.len < 2)
        printUsage();

    var files = std.ArrayList([]const u8).init(alc);
    // Arguments
    var has_numbers_flag = false;
    for (args[1..args.len]) |arg| {
        if (mem.startsWith(u8, arg, "-")) {
            var is_invalid_options = false;
            if (mem.eql(u8, arg, "-n") or mem.eql(u8, arg, "--number")) {
                has_numbers_flag = true;
                continue;
            } else if (mem.eql(u8, arg, "--help")) {
                try printHelp();
            } else if (mem.eql(u8, arg, "--version")) {
                try printVersion();
            } else {
                debug.print("{s}: invalid option {s}\n", .{ NAME, arg });
                debug.print("{s}", .{INFO});
                is_invalid_options = true;
            }

            Output.restore();
            if (is_invalid_options) {
                os.exit(2);
            } else {
                os.exit(0);
            }
        } else {
            try files.append(arg);
        }
    }
    for (files.items) |filename| {
        try cat(alc, filename, .{ .number = has_numbers_flag });
    }
    files.deinit();

    Output.restore();
    os.exit(0);
}

test {
    _ = @import("cat.zig");
}
