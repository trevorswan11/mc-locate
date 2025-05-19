const std = @import("std");

const regions = @import("regions.zig");
const dims = regions.Dimensions;

pub const Args = struct {
    seed: u64,
    dim: c_int,
    biome: c_int,
    center_x: c_int,
    center_z: c_int,
};

/// Parses the command line args according to:
/// Usage: mclocate <seed> <dim> <biome> <x> <z>
pub fn parseArgs(allocator: std.mem.Allocator) !Args {
    // Define the target parameters for the process
    var seed: ?u64 = null;
    var dim: ?c_int = null;
    var biome_id: ?c_int = null;
    var x: ?c_int = null;
    var z: ?c_int = null;

    // Initialize and unpack the args -- Skip index 0 to avoid call
    const args = try std.process.argsAlloc(allocator);

    // Convert all of the args to their lowercase value
    for (args) |a| {
        for (a) |*c| {
            c.* = std.ascii.toLower(c.*);
        }
    }

    // Check if the user requested help or used the incorrect number of params
    if (std.mem.eql(u8, args[1], "help")) {
        return error.HelpNeeded;
    } else if (args.len < 6) {
        return error.InvalidArgs;
    }

    seed = std.fmt.parseInt(u64, args[1], 10) catch null;

    // Convert the input letter to an int
    if (args[2].len != 1) {
        return error.InvalidDimension;
    }
    dim = switch (@as(u8, args[2][0])) {
        'n' => @intFromEnum(dims.nether),
        'o' => @intFromEnum(dims.overworld),
        'e' => @intFromEnum(dims.end),
        else => null,
    };

    // Convert the string name of the biome map to a BiomeID / c_int
    if (dim) |d| {
        if (d != -1 and d != 0 and d != 1) {
            return error.InvalidDimension;
        }

        // Get the hash map based on the valid dimension
        var biome_map = switch (d) {
            -1 => regions.getNetherBiomes(allocator),
            0 => regions.getOverworldBiomes(allocator),
            1 => regions.getEndBiomes(allocator),
            else => unreachable,
        } catch {
            return error.HashMapAllocationError;
        };
        defer biome_map.deinit();

        const input = args[3];
        if (biome_map.contains(input)) {
            biome_id = @intCast(@intFromEnum(biome_map.get(input).?));
        } else {
            return error.InvalidBiome;
        }
    } else {
        return error.InvalidDimension;
    }

    // Parse the coordinates
    x = std.fmt.parseInt(c_int, args[4], 10) catch null;
    z = std.fmt.parseInt(c_int, args[5], 10) catch null;

    // The command line arguments may be formatted incorrectly
    if (seed == null) {
        return error.SeedParse;
    } else if (dim == null) {
        return error.InvalidDimension;
    } else if (biome_id == null) {
        return error.BiomeIDParse;
    } else if (x == null or z == null) {
        return error.CoordinateParse;
    }

    // Repack the args in a useable format (all optional types must now have a value)
    return Args{
        .seed = seed.?,
        .dim = dim.?,
        .biome = biome_id.?,
        .center_x = x.?,
        .center_z = z.?,
    };
}
