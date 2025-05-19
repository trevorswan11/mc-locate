const std = @import("std");

const parser = @import("parser.zig");
const finder = @import("finder.zig");
const regions = @import("regions.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = parser.parseArgs(allocator) catch |err| switch (err) {
        error.HelpNeeded => {
            const help = try regions.helpMessage();
            std.debug.print("{s}\n", .{help});
            std.debug.print("Usage: mclocate <seed> <dim> <biome> <x> <z>\n", .{});
            return;
        },
        error.InvalidBiome => {
            std.debug.print("Biome could not be found in the given dimension\n", .{});
            return;
        },
        else => {
            std.debug.print("Usage: mclocate <seed> <dim> <biome> <x> <z>\n", .{});
            return;
        },
    };

    const query = finder.Query{
        .seed = args.seed,
        .dim = args.dim,
        .biome_id = args.biome,
        .x = args.center_x,
        .z = args.center_z,
    };

    const result = try finder.find(allocator, query);
    if (result) |r| {
        std.debug.print("Found biome at ({d}, {d})", .{ r.x, r.z });
    }
}
