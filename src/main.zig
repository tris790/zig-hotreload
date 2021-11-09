const std = @import("std");
var process: (fn process(value: u32) void) = undefined;

const dll_pathname = "zig-out/lib/processing.dll";

fn load_fn(lib: *std.DynLib) void {
    if (lib.lookup(@TypeOf(process), "process")) |process_fn| {
        process = process_fn;
    }
}

pub fn main() anyerror!void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var lib = try std.DynLib.open(dll_pathname);
    defer lib.close();
    load_fn(&lib);

    while (true) {
        try stdout.print("A number command: ", .{});
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        const user_input_opt = try stdin.readUntilDelimiterOrEofAlloc(&arena.allocator, '\n', std.math.maxInt(usize));

        if (user_input_opt) |user_input| {
            if (std.mem.eql(u8, user_input[0..1], "e")) {
                process(100);
            } else if (std.mem.eql(u8, user_input[0..1], "r")) {
                try stdout.print("Reloading\n", .{});
                // unload dll
                lib.close();

                // compile
                _ = try std.ChildProcess.exec(.{
                    .allocator = &arena.allocator,
                    .argv = ([_][]const u8{ "zig", "build" })[0..],
                    .max_output_bytes = std.math.maxInt(usize),
                });

                std.debug.print("Compiled successfully\n", .{});

                // reload
                lib = try std.DynLib.open(dll_pathname);
                load_fn(&lib);
                process(100);
            } else {
                try stdout.print("Unknown\n", .{});
            }
        }
    }
}
