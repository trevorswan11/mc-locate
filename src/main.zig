const std = @import("std");

const parser = @import("parser.zig");
const biome = @import("biome_finder.zig");
const structure = @import("structure_finder.zig");
const regions = @import("regions.zig");

pub fn main() !void {
    // Parse the input and decide whether it is safe to proceed
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

    // Perform the search and print the output
    const t0 = std.time.nanoTimestamp();
    switch (args.search) {
        .BIOME => {
            const query = biome.Query{
                .seed = args.seed,
                .dim = args.dim,
                .id = args.biome,
                .x = args.center_x,
                .z = args.center_z,
                .count = args.count,
            };

            const result = try biome.find(query);
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
                .id = args.structure,
                .x = args.center_x,
                .z = args.center_z,
                .count = args.count,
            };

            const result = try structure.find(query);
            if (result) |r| {
                try stdout.print("{s}Found structure at ({d}, {d})", .{ r.message, r.x, r.z });
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

const testing = std.testing;
test "basic functionality - 4 threads" {
    // Biome - From cubiomes, should return (0, 0)
    const biome_query = biome.Query{
        .seed = 262,
        .dim = 0,
        .id = @intFromEnum(regions.BiomeID.mushroom_fields),
        .x = 0,
        .z = 0,
        .count = false,
    };
    try if (biome.find(biome_query) catch null) |result| {
        try testing.expectEqual(biome_query.x, result.x);
        try testing.expectEqual(biome_query.z, result.z);
    } else testing.expect(false);

    // Structure - Should return (-288, 176)
    const structure_query = structure.Query{
        .seed = 262,
        .dim = 0,
        .id = @intFromEnum(regions.StructureID.monument),
        .x = 0,
        .z = 0,
        .count = false,
    };
    try if (structure.find(structure_query) catch null) |result| {
        try testing.expectEqual(-288, result.x);
        try testing.expectEqual(176, result.z);
    } else testing.expect(false);

    // Buggy Structure - Should return a message with (-352, -2224)
    const buggy_structure = structure.Query{
        .seed = 262,
        .dim = 0,
        .id = @intFromEnum(regions.StructureID.jungle_temple),
        .x = 0,
        .z = 0,
        .count = false,
    };
    try if (structure.find(buggy_structure) catch null) |result| {
        try testing.expectEqual(-352, result.x);
        try testing.expectEqual(-2224, result.z);
        try testing.expectEqualSlices(u8, "WARNING: Jungle Temples cannot be found consistently!\n", result.message);
    } else testing.expect(false);

    // Stronghold - Should return (0, 0)
    const stronghold_query = structure.Query{
        .seed = 262,
        .dim = 0,
        .id = @intFromEnum(regions.StructureID.stronghold),
        .x = 0,
        .z = 0,
        .count = false,
    };
    try if (structure.find(stronghold_query) catch null) |result| {
        try testing.expectEqual(stronghold_query.x, result.x);
        try testing.expectEqual(stronghold_query.z, result.z);
    } else testing.expect(false);
}
