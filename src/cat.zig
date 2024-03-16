// Copyright (C) 2023-2024 ryu. All rights reserved. MIT license.
const std = @import("std");
const debug = std.debug;

const NAME = "me";
var is_printed = false;
var has_numbers_flag = false;

fn printFileLine(contents: []const u8, line_no: usize) !void {
    const stdout = std.io.getStdOut().writer();
    if (is_printed) try stdout.print("\n", .{}) else is_printed = true;
    if (has_numbers_flag) {
        try stdout.print("{: >5} {s}", .{ line_no, contents });
    } else {
        try stdout.print("{s}", .{contents});
    }
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

pub fn cat(filename: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();

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
