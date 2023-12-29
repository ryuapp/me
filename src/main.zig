const std = @import("std");

const fs = std.fs;
const os = std.os;
const debug = std.debug;

fn printUsage() void {
    debug.print("Usage: miru [FILE]...\n", .{});
}
fn printErrorMessage(filename: [:0]u8, err: anyerror) void {
    debug.print("\"{s}\": {any}\n", .{ filename, err });
}

pub fn main() !void {
    const alc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alc);
    var buf: [std.mem.page_size]u8 = undefined;

    defer std.process.argsFree(alc, args);
    if (args.len < 2) {
        printUsage();
        os.exit(1);
    }

    for (args[1..args.len]) |filename| {
        const content = fs.cwd().readFile(filename, &buf) catch |err| {
            printErrorMessage(filename, err);
            continue;
        };

        try std.io.getStdOut().writer().print("{s}\n", .{content});
    }
}
