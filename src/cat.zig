// Copyright (C) 2023-2024 ryu. All rights reserved. MIT license.
const std = @import("std");
const debug = std.debug;

const NAME = "me";
var is_printed = false;
var has_numbers_flag = false;

fn printFileLine(contents: []const u8, line_no: usize) !void {
    const stdout = std.io.getStdOut().writer();
    if (is_printed) try std.io.getStdErr().writer().print("\n", .{}) else is_printed = true;

    if (has_numbers_flag) {
        try stdout.print("{: >5} {s}", .{ line_no, contents });
    } else {
        try stdout.print("{s}", .{contents});
    }
}
fn printErrorMessage(filename: []const u8, err: anyerror) !void {
    if (is_printed) try std.io.getStdErr().writer().print("\n", .{}) else is_printed = true;

    switch (err) {
        error.FileNotFound => try std.io.getStdErr().writer().print("{s}: {s}: No such file or directory", .{ NAME, filename }),
        error.IsDir => try std.io.getStdErr().writer().print("{s}: {s}: Is a directory", .{ NAME, filename }),
        else => try std.io.getStdErr().writer().print("{s}: {s}: {any}", .{ NAME, filename, err }),
    }
}

pub fn cat(alc: std.mem.Allocator, filename: []const u8, options: anytype) !void {
    if (options.number)
        has_numbers_flag = true;

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
            error.EndOfStream => try printFileLine(line.items, line_no),
            else => try printErrorMessage(filename, err),
        }
    } else |err| {
        try printErrorMessage(filename, err);
    }
}

test "read a file" {
    debug.print("\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();
    const filename = "src/testdata/hello.txt";
    const options = .{ .number = false };
    try cat(alc, filename, options);
}

test "read a file with line numbers" {
    debug.print("\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();
    const filename = "src/testdata/hello.txt";
    const options = .{ .number = true };
    try cat(alc, filename, options);
}

test "read a japanaese file" {
    debug.print("\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();
    const filename = "src/testdata/hello_ja.txt";
    const options = .{ .number = false };
    try cat(alc, filename, options);
}

test "read a japanaese file with line numbers" {
    debug.print("\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alc = gpa.allocator();
    const filename = "src/testdata/hello_ja.txt";
    const options = .{ .number = true };
    try cat(alc, filename, options);
}
