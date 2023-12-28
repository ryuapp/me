const std = @import("std");

pub fn main() !void {
    const alc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alc);
    var buf: [1024]u8 = undefined;

    defer std.process.argsFree(alc, args);
    if (args.len < 2) {
        std.debug.print("Usage: miru [FILE]...\n", .{});
        std.os.exit(1);
    }
    for (args, 0..) |value, i| {
        if (i == 0) continue;
        const filename = value;
        const content = std.fs.cwd().readFile(filename, &buf) catch |err| {
            std.debug.print("\"{s}\" is not found.\n", .{filename});
            std.log.debug("{}", .{err});
            continue;
        };

        try std.io.getStdOut().writer().print("{s}\n", .{content});
    }
}
