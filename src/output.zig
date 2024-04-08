// Copyright (C) 2023-2024 ryu. All rights reserved. MIT license.
const std = @import("std");
const os = std.os;

const is_windows = @import("builtin").os.tag == .windows;

pub const Output = struct {
    pub fn init() !void {
        if (comptime is_windows) {
            try WindowsOutput.init();
        }
    }
    pub fn restore() void {
        if (comptime is_windows) {
            WindowsOutput.restore();
        }
    }
};
const WindowsOutput = struct {
    const win = os.windows;
    const k32 = win.kernel32;
    var console_output_cp: c_uint = @as(u32, 0);

    // Make a console output code is the same as before execution
    fn setAbortSignalHandler(comptime handler: *const fn () void) !void {
        const handler_routine = struct {
            fn handler_routine(dwCtrlType: win.DWORD) callconv(win.WINAPI) win.BOOL {
                if (dwCtrlType == win.CTRL_C_EVENT) {
                    handler();
                    return win.TRUE;
                } else {
                    return win.FALSE;
                }
            }
        }.handler_routine;

        try win.SetConsoleCtrlHandler(handler_routine, true);
    }
    fn abortSignalHandler() void {
        restore();
        os.exit(0);
    }

    pub fn init() !void {
        // Set a console output code page to UTF-8
        const CP_UTF8 = 65001;
        console_output_cp = k32.GetConsoleOutputCP();
        try setAbortSignalHandler(abortSignalHandler);
        _ = k32.SetConsoleOutputCP(CP_UTF8);
    }
    pub fn restore() void {
        if (console_output_cp != 0)
            _ = k32.SetConsoleOutputCP(console_output_cp);
    }
};
