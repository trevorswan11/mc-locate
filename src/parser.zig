const std = @import("std");

const regions = @import("regions.zig");
const dims = regions.Dimensions;

// Cubiomes supports both biome and structure searching
pub const SearchType = enum(u8) {
    BIOME,
    STRUCTURE,
};

// A wrapper for the useful command line args
pub const Args = struct {
    seed: u64,
    dim: c_int,
    biome: c_int = -1, // While you could consolidate into one id field, this is more explicit for parsing
    structure: c_int = -1,
    center_x: c_int,
    center_z: c_int,
    search: SearchType,
    benchmark: bool,
    count: bool,
};

/// Parses the command line args according to:
/// Usage: mclocate <seed> <dim> <biome> <x> <z>
pub fn parseArgs(allocator: std.mem.Allocator) !Args {
    // Define the target parameters for the process
    var seed: ?u64 = null;
    var dim: ?c_int = null;
    var biome_id: ?c_int = null;
    var structure_id: ?c_int = null;
    var x: ?c_int = null;
    var z: ?c_int = null;
    var search_type: ?SearchType = null;
    var bench = false;
    var count = false;

    // Initialize and unpack the args -- Skip index 0 to avoid call
    const args = try std.process.argsAlloc(allocator);
    if (args.len == 1) {
        return error.NoArgsError;
    }

    // Convert all of the args to their lowercase value
    for (args) |a| {
        for (a) |*c| {
            c.* = std.ascii.toLower(c.*);
        }
    }

    // Check what the user requested or used the incorrect number of params
    if (std.mem.eql(u8, args[1], "help-biome")) {
        return error.BiomeHelpNeeded;
    } else if (std.mem.eql(u8, args[1], "help-structure")) {
        return error.StructureHelpNeeded;
    } else if (args.len < 7) {
        return error.InvalidArgs;
    } else if (std.mem.eql(u8, args[1], "biome")) {
        search_type = SearchType.BIOME;
    } else if (std.mem.eql(u8, args[1], "structure")) {
        search_type = SearchType.STRUCTURE;
    }

    seed = std.fmt.parseInt(u64, args[2], 10) catch null;

    // Convert the input letter to an int
    if (args[3].len != 1) {
        return error.InvalidDimension;
    }
    dim = switch (@as(u8, args[3][0])) {
        'n' => @intFromEnum(dims.nether),
        'o' => @intFromEnum(dims.overworld),
        'e' => @intFromEnum(dims.end),
        else => null,
    };

    // Convert the string name of the biome map to a BiomeID / c_int
    if (dim) |d| {
        const input = args[4];
        if (d != -1 and d != 0 and d != 1) {
            return error.InvalidDimension;
        } else if (search_type == null) {
            return error.InvalidSearchType;
        }

        // Get the hash map based on the valid dimension and query type
        if (search_type == SearchType.BIOME) {
            var biome_map = switch (d) {
                -1 => regions.getNetherBiomes(allocator),
                0 => regions.getOverworldBiomes(allocator),
                1 => regions.getEndBiomes(allocator),
                else => unreachable,
            } catch {
                return error.HashMapAllocationError;
            };
            defer biome_map.deinit();

            if (biome_map.contains(input)) {
                biome_id = @intCast(@intFromEnum(biome_map.get(input).?));
            } else {
                return error.InvalidBiome;
            }
        } else if (search_type == SearchType.STRUCTURE) {
            var structure_map = switch (d) {
                -1 => regions.getNetherStructures(allocator),
                0 => regions.getOverworldStructures(allocator),
                1 => regions.getEndStructures(allocator),
                else => unreachable,
            } catch {
                return error.HashMapAllocationError;
            };
            defer structure_map.deinit();

            if (structure_map.contains(input)) {
                structure_id = @intCast(@intFromEnum(structure_map.get(input).?));
            } else {
                return error.InvalidStructure;
            }
        } else {
            return error.InvalidSearchType;
        }
    } else {
        return error.InvalidDimension;
    }

    // Parse the coordinates
    x = std.fmt.parseInt(c_int, args[5], 10) catch null;
    z = std.fmt.parseInt(c_int, args[6], 10) catch null;

    // The command line arguments may be formatted incorrectly
    if (seed == null) {
        return error.SeedParse;
    } else if (dim == null) {
        return error.InvalidDimension;
    } else if (biome_id == null and structure_id == null) {
        return error.IDParse;
    } else if (x == null or z == null) {
        return error.CoordinateParse;
    } else if (search_type == null) {
        return error.SearchTypeParse;
    }

    // There is builtin benchmarking and thread counting if requested in the last argument
    if (std.mem.eql(u8, args[args.len - 1], "bench")) {
        bench = true;
    } else if (std.mem.eql(u8, args[args.len - 1], "count")) {
        count = true;
    } else if (std.mem.eql(u8, args[args.len - 1], "cb") or
        std.mem.eql(u8, args[args.len - 1], "bc"))
    {
        count = true;
        bench = true;
    }

    // Repack the args in a useable format (all optional types must now have a value)
    return switch (search_type.?) {
        .BIOME => Args{
            .seed = seed.?,
            .dim = dim.?,
            .biome = biome_id.?,
            .center_x = x.?,
            .center_z = z.?,
            .search = search_type.?,
            .benchmark = bench,
            .count = count,
        },
        .STRUCTURE => Args{
            .seed = seed.?,
            .dim = dim.?,
            .structure = structure_id.?,
            .center_x = x.?,
            .center_z = z.?,
            .search = search_type.?,
            .benchmark = bench,
            .count = count,
        },
    };
}
