// Copyright (C) 2023-2024 ryu. All rights reserved. MIT license.
const std = @import("std");
const cat = @import("cat.zig").cat;

const fs = std.fs;
const os = std.os;
const debug = std.debug;

const NAME = "me";
const VERSION = "0.1.0";
const USAGE = "Usage: " ++ NAME ++ " [OPTION]... [FILE]...";
const DESCRIPTION = "Print FILE(s) to standard output.";
const INFO = NAME ++ ": try \'me --help\' for more information";

fn printUsage() void {
    debug.print("{s}\n", .{USAGE});
    debug.print("{s}", .{INFO});
}
fn printHelp() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{USAGE});
    try stdout.print("{s}\n\n", .{DESCRIPTION});
    try stdout.print(" -n, --number\t Print number all output lines\n", .{});
    try stdout.print("     --help\t Print help\n", .{});
    try stdout.print("     --version\t Print version", .{});
}
fn printVersion() !void {
    try std.io.getStdOut().writer().print("me {s}", .{VERSION});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();
    const args = try std.process.argsAlloc(alc);

    defer std.process.argsFree(alc, args);
    if (args.len < 2) {
        printUsage();
        os.exit(2);
    }

    var files = std.ArrayList([]const u8).init(alc);
    // Arguments
    var has_numbers_flag = false;
    for (args[1..args.len]) |arg| {
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "--help")) {
                try printHelp();
                os.exit(0);
            } else if (std.mem.eql(u8, arg, "--version")) {
                try printVersion();
                os.exit(0);
            } else if (std.mem.eql(u8, arg, "-n") or std.mem.eql(u8, arg, "--number")) {
                has_numbers_flag = true;
            } else {
                debug.print("{s}: invalid option {s}\n", .{ NAME, arg });
                debug.print("{s}", .{INFO});
                os.exit(2);
            }
        } else {
            try files.append(arg);
        }
    }
    for (files.items) |filename| {
        try cat(filename, .{ .number = has_numbers_flag });
    }
    files.deinit();
}
