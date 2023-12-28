const std = @import("std");

pub fn main() !void {
    const alc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alc);
    var buf: [1024]u8 = undefined;

    defer std.process.argsFree(alc, args);
    if (args.len < 2) {
        std.debug.print("Usage: miru [FILE]\n", .{});
        std.os.exit(1);
    }

    const filename = args[1];
    const content = std.fs.cwd().readFile(filename, &buf) catch |err| {
        std.debug.print("\"{s}\" is not found.\n", .{filename});
        std.log.debug("{}", .{err});
        std.os.exit(1);
    };
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{content});
}
