const std = @import("std");

const fs = std.fs;
const os = std.os;
const debug = std.debug;

const VERSION = "0.1.0";
const USAGE = "Usage: me [FILE]...";
const HELP = USAGE ++ "\n --help\t\tPrint help\n --version\tPrint version";

var hasPrinted = false;

fn printUsage() void {
    debug.print("{s}", .{USAGE});
}
fn printHelp() !void {
    try std.io.getStdOut().writer().print("{s}", .{HELP});
}
fn printVersion() !void {
    try std.io.getStdOut().writer().print("me {s}", .{VERSION});
}
fn printErrorMessage(filename: [:0]u8, err: anyerror) void {
    if (hasPrinted) debug.print("\n", .{}) else hasPrinted = true;
    if (err == error.FileNotFound) {
        debug.print("me: {s}: No such file or directory", .{filename});
        return;
    } else if (err == error.IsDir) {
        debug.print("me: {s}: Is a directory", .{filename});
        return;
    }
    debug.print("me: {s}: {any}", .{ filename, err });
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

    // Arguments
    for (args[1..args.len]) |filename| {
        if (std.mem.eql(u8, filename, "--help")) {
            try printHelp();
            os.exit(0);
        } else if (std.mem.eql(u8, filename, "--version")) {
            try printVersion();
            os.exit(0);
        }
    }

    for (args[1..args.len]) |filename| {
        if (std.fs.cwd().openFile(filename, .{})) |file| {
            defer file.close();

            var buf_reader = std.io.bufferedReader(file.reader());
            const reader = buf_reader.reader();

            var line = std.ArrayList(u8).init(alc);
            defer line.deinit();

            const writer = line.writer();
            var line_no: usize = 1;

            const stdout = std.io.getStdOut().writer();

            if (hasPrinted) try stdout.print("{s}:\n", .{filename}) else hasPrinted = true;

            while (reader.streamUntilDelimiter(writer, '\n', null)) : (line_no += 1) {
                // Clear the line so we can reuse it.
                defer line.clearRetainingCapacity();

                try stdout.print("{s}\n", .{line.items});
            } else |err| switch (err) {
                error.EndOfStream => {
                    try stdout.print("{s}", .{line.items});
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
