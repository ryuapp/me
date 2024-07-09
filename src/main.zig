// Copyright (C) 2023-2024 ryu. All rights reserved. MIT license.
const std = @import("std");
const Output = @import("output.zig").Output;
const cat = @import("cat.zig").cat;

const mem = std.mem;
const debug = std.debug;
const process = std.process;

const NAME = "me";
const VERSION = "0.1.4";
const USAGE = "Usage: " ++ NAME ++ " [OPTION]... [FILE]...";
const DESCRIPTION = "Print FILE(s) to standard output.";
const INFO = NAME ++ ": try \'me --help\' for more information";

fn printUsage() !void {
    try std.io.getStdErr().writer().print("{s}\n", .{USAGE});
    try std.io.getStdErr().writer().print("{s}", .{INFO});
}
fn printHelp() !void {
    const options =
        \\  -n, --number   Print number all output lines
        \\      --help     Print help
        \\      --version  Print version
    ;
    try std.io.getStdOut().writer().print("{s}\n{s}\n\n{s}", .{ USAGE, DESCRIPTION, options });
}
fn printVersion() !void {
    try std.io.getStdOut().writer().print("me {s}", .{VERSION});
}
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();
    const args = try process.argsAlloc(alc);

    try Output.init();

    defer process.argsFree(alc, args);
    if (args.len < 2) {
        try printUsage();
        Output.restore();
        process.exit(2);
    }

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
                try std.io.getStdErr().writer().print("{s}: invalid option {s}\n", .{ NAME, arg });
                try std.io.getStdErr().writer().print("{s}", .{INFO});
                is_invalid_options = true;
            }

            Output.restore();
            if (is_invalid_options) {
                process.exit(2);
            } else {
                process.exit(0);
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
    process.exit(0);
}

test {
    _ = @import("cat.zig");
}
