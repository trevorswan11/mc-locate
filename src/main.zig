const std = @import("std");

const parser = @import("parser.zig");
const biome = @import("biome_finder.zig");
const structure = @import("structure_finder.zig");
const regions = @import("regions.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();
    const args = parser.parseArgs(allocator) catch |err| switch (err) {
        error.BiomeHelpNeeded => {
            const help = try regions.biomeHelpMessage();
            try stdout.print("{s}", .{help});
            return;
        },
        error.StructureHelpNeeded => {
            const help = try regions.structureHelpMessage();
            try stdout.print("{s}", .{help});
            return;
        },
        error.InvalidBiome => {
            try stdout.print("Biome could not be found in the given dimension\n", .{});
            return;
        },
        error.InvalidStructure => {
            try stdout.print("Structure could not be found in the given dimension\n", .{});
            return;
        },
        error.InvalidSearchType => {
            try stdout.print("You must specify either biome or structure as the first argument\n", .{});
            return;
        },
        else => {
            try stdout.print("Usage: mclocate <biome/structure> <seed> <dim> <biome> <x> <z>\n", .{});
            return;
        },
    };

    const t0 = std.time.nanoTimestamp();
    switch (args.search) {
        .BIOME => {
            const query = biome.Query{
                .seed = args.seed,
                .dim = args.dim,
                .biome_id = args.biome,
                .x = args.center_x,
                .z = args.center_z,
                .count = args.count,
            };

            const result = try biome.find(allocator, query);
            if (result) |r| {
                try stdout.print("Found biome at ({d}, {d})", .{ r.x, r.z });
            } else {
                try stdout.print("Could not find biome", .{});
            }
        },
        .STRUCTURE => {
            const query = structure.Query{
                .seed = args.seed,
                .dim = args.dim,
                .structure_id = args.structure,
                .x = args.center_x,
                .z = args.center_z,
                .count = args.count,
            };

            const result = try structure.find(query);
            if (result) |r| {
                try stdout.print("Found structure at ({d}, {d})", .{ r.x, r.z });
            } else {
                try stdout.print("Could not find structure", .{});
            }
        },
    }
    const t1 = std.time.nanoTimestamp();
    if (args.benchmark) {
        try stdout.print("\nSearch took {d} ms\n", .{@as(f128, @floatFromInt(t1 - t0)) / 1_000_000.0});
    }
}
