// Copyright (C) 2023-2024 ryu. All rights reserved. MIT license.
const std = @import("std");

const fs = std.fs;
const os = std.os;
const debug = std.debug;

const NAME = "me";
const VERSION = "0.1.0";
const USAGE = "Usage: " ++ NAME ++ " [OPTION]... [FILE]...";
const DESCRIPTION = "Print FILE(s) to standard output.";
const INFO = NAME ++ ": try \'me --help\' for more information";

var is_printed = false;
var has_numbers_flag = false;

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
fn printErrorMessage(filename: []const u8, err: anyerror) void {
    if (is_printed) debug.print("\n", .{}) else is_printed = true;
    if (err == error.FileNotFound) {
        debug.print("{s}: {s}: No such file or directory", .{ NAME, filename });
        return;
    } else if (err == error.IsDir) {
        debug.print("{s}: {s}: Is a directory", .{ NAME, filename });
        return;
    }
    debug.print("{s}: {s}: {any}", .{ NAME, filename, err });
}

fn printFileLine(contents: []const u8, line_no: usize) !void {
    const stdout = std.io.getStdOut().writer();
    if (is_printed) try stdout.print("\n", .{}) else is_printed = true;
    if (has_numbers_flag) {
        try stdout.print("{: >5} {s}", .{ line_no, contents });
    } else {
        try stdout.print("{s}", .{contents});
    }
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

    var filenames = std.ArrayList([]const u8).init(alc);
    // Arguments
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
            try filenames.append(arg);
        }
    }

    for (filenames.items) |filename| {
        if (std.fs.cwd().openFile(filename, .{})) |file| {
            defer file.close();

            var buf_reader = std.io.bufferedReader(file.reader());
            const reader = buf_reader.reader();

            var line = std.ArrayList(u8).init(alc);
            defer line.deinit();

            const writer = line.writer();
            var line_no: usize = 1;

            while (reader.streamUntilDelimiter(writer, '\n', null)) : (line_no += 1) {
                // Clear the line so we can reuse it.
                defer line.clearRetainingCapacity();
                try printFileLine(line.items, line_no);
            } else |err| switch (err) {
                error.EndOfStream => {
                    try printFileLine(line.items, line_no);
                },
                else => {
                    printErrorMessage(filename, err);
                },
            }
        } else |err| {
            printErrorMessage(filename, err);
        }
    }
}
