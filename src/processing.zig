const std = @import("std");

export fn process(value: u32) void {
    std.log.info("Processing {}\n", .{value});
}
