const std = @import("std");
const c = @cImport({
    @cInclude("generator.h");
    @cInclude("finders.h");
});

// Typedef / function imports
const globals = @import("globals.zig");
const structures = @import("regions.zig").StructureID;
pub const Query = globals.Query;
pub const Result = globals.Result;
const distanceSquared = globals.distanceSquared;

// Global constants
const MC_VER = globals.MC_VER;
const NUM_THREADS = globals.NUM_THREADS;

/// All information needed for a thread to search in its region for a structure
const ThreadContext = struct {
    query: Query,
    start_rx: i32,
    end_rx: i32,
    center_region_z: i32,
    max_radius: i32,
    best_mutex: *std.Thread.Mutex,
    best_pos: *?c.Pos,
    best_dist_sq: *u64,
    count: u64 = 0,
};

/// Defines the work to be done per thread to find the specific structure id
fn worker(ctx: *ThreadContext, sconf: c.StructureConfig, counting: bool) void {
    var g: c.Generator = undefined;
    c.setupGenerator(&g, MC_VER, 0);
    c.applySeed(&g, ctx.query.dim, ctx.query.seed);

    // Follows the guide of test.c in cubiomes
    var local_best: ?c.Pos = null;
    var local_best_dist_sq: u64 = std.math.maxInt(u64);

    const min_z = ctx.center_region_z - ctx.max_radius;
    const max_z = ctx.center_region_z + ctx.max_radius;

    // Search the threads alloted region in the radii
    var rx = ctx.start_rx;
    while (rx <= ctx.end_rx) : (rx += 1) {
        // Unlike biomes, regions are already scaled down and can use a step of 1
        var rz = min_z;
        while (rz <= max_z) : (rz += 1) {
            if (counting) {
                ctx.count += 1;
            }

            // Check region takes in region coordinates, but returns block coordinates for packing
            if (checkRegion(rx, rz, ctx.query, &g, sconf) catch null) |pos| {
                const dist_sq = distanceSquared(pos, .{
                    .x = ctx.query.x,
                    .z = ctx.query.z,
                });
                if (dist_sq < local_best_dist_sq) {
                    local_best_dist_sq = dist_sq;
                    local_best = pos;
                }
            }
        }
    }

    // Threads should safely update best distances to prevent unnecessary overlaps
    if (local_best) |pos| {
        ctx.best_mutex.lock();
        defer ctx.best_mutex.unlock();

        if (local_best_dist_sq < ctx.best_dist_sq.*) {
            ctx.best_dist_sq.* = local_best_dist_sq;
            ctx.best_pos.* = pos;
        }
    }
}

/// Procedurally dispatches threads to find the closest structure to the query
pub fn find(query: Query) !?Result {
    var message: []u8 = "";
    // Strongholds generate differently, this is constant per seed regardless of Query
    if (query.id == @intFromEnum(structures.stronghold)) {
        return findNearestStronghold(query.seed, query.x, query.z);
    } else if (query.id == @intFromEnum(structures.jungle_temple)) {
        message = @constCast("WARNING: Jungle Temples cannot be found consistently!\n");
    } else if (query.id == @intFromEnum(structures.mansion)) {
        message = @constCast("WARNING: Woodland Mansions cannot be found consistently!\n");
    } else if (query.id == @intFromEnum(structures.desert_pyramid)) {
        message = @constCast("WARNING: Desert Pyramids cannot be found consistently!\n");
    }

    // Use cubiomes structure tooling to define the query's custom regional shift value
    var sconf: c.StructureConfig = undefined;
    if (c.getStructureConfig(query.id, MC_VER, &sconf) != 1) {
        return null;
    }
    const shift_val: i32 = @as(i32, @intCast(sconf.regionSize)) * 16;

    // Use the shift value to convert the query (blockspace) to the appropriate regionspace coordinates
    const center_rx = @divFloor(query.x, shift_val);
    const center_rz = @divFloor(query.z, shift_val);
    const max_r = @divFloor(query.radius, shift_val);

    // Initialize struct members that will be used in the search
    var best_mutex = std.Thread.Mutex{};
    var best_pos: ?c.Pos = null; // While results could be used here, Pos structs align better with cubiomes
    var best_dist_sq: u64 = std.math.maxInt(u64);

    // Initialize values that will be passed around for creating and observing desired behavior
    const total_width = max_r * 2 + 1;
    const step = @divFloor(total_width + NUM_THREADS - 1, NUM_THREADS);
    var threads: [NUM_THREADS]std.Thread = undefined;
    var thread_ctx: [NUM_THREADS]*ThreadContext = undefined;

    // Kick off each thread by calculating the radius range and initializing its context
    var i: usize = 0;
    while (i < NUM_THREADS) : (i += 1) {
        // Use the center region to derive the start and end regions for the given thread
        const start_rx = center_rx - max_r + @as(i32, @intCast(i)) * @as(i32, @intCast(step));
        const end_rx = @min(center_rx - max_r + (@as(i32, @intCast((i))) + 1) * @as(i32, @intCast(step)) - 1, center_rx + max_r);

        // Allocate memory for a new thread's data and ship it
        const ctx = try std.heap.page_allocator.create(ThreadContext);
        ctx.* = ThreadContext{
            .query = query,
            .start_rx = start_rx,
            .end_rx = end_rx,
            .center_region_z = center_rz,
            .max_radius = max_r,
            .best_mutex = &best_mutex,
            .best_dist_sq = &best_dist_sq,
            .best_pos = &best_pos,
        };

        threads[i] = try std.Thread.spawn(.{}, worker, .{ ctx, sconf, query.count });
        thread_ctx[i] = ctx;
    }

    for (threads) |t| {
        t.join();
    }

    // Print count info if requested
    const stdout = std.io.getStdOut().writer();
    if (query.count) {
        var total: u64 = 0;
        inline for (thread_ctx, 1..) |tx, j| {
            total += tx.count;
            try stdout.print("Thread {d}: {d} checks\n", .{ j, tx.count });
        }
        try stdout.print("Total checks: {d}\n", .{total});
    }

    // Repack the result as pos does not play nice with result
    return if (best_pos) |pos| Result{
        .x = pos.x,
        .z = pos.z,
        .message = message,
    } else null;
}

/// Uses a custom, single threaded approach for finding strongholds as they are uniquely generated
fn findNearestStronghold(
    seed: u64,
    x: c_int,
    z: c_int,
) !?Result {
    // Initialize the custom stronghold generators
    var g: c.Generator = undefined;
    c.setupGenerator(&g, MC_VER, 0);
    c.applySeed(&g, c.DIM_OVERWORLD, seed);

    var sh_iter: c.StrongholdIter = undefined;
    _ = c.initFirstStronghold(&sh_iter, MC_VER, seed);

    var best_pos: ?c.Pos = null;
    var best_dist_sq: u64 = std.math.maxInt(u64);

    // There are only 128 total strongholds generated by minecraft
    var i: usize = 0;
    while (i < 128) : (i += 1) {
        // Compare the current iterator distance to the next stronghold
        const pos = sh_iter.pos;
        const dist_sq: u64 = distanceSquared(pos, .{
            .x = x,
            .z = z,
        });

        if (dist_sq < best_dist_sq) {
            best_dist_sq = dist_sq;
            best_pos = pos;
        }

        const next_sh = c.nextStronghold(&sh_iter, &g);
        if (next_sh <= 0) break;
    }

    // Repack the result as pos does not play nice with result
    return if (best_pos) |p| Result{
        .x = p.x,
        .z = p.z,
    } else null;
}

/// Follows the comments in test.c regarding valid structure generation
fn checkRegion(region_x: i32, region_z: i32, query: Query, g: *c.Generator, sconf: c.StructureConfig) !?c.Pos {
    // Ensure that the structure can even attempt to be generated in the given region
    var pos: c.Pos = undefined;
    const found = c.getStructurePos(query.id, MC_VER, query.seed, region_x, region_z, &pos) == 1;
    if (!found) {
        return null;
    }

    // Convert the regionspace coordinates back to blockspace
    const block_x = region_x * sconf.regionSize * 16;
    const block_z = region_z * sconf.regionSize * 16;

    var is_valid = c.isViableStructurePos(query.id, g, block_x, block_z, 0) == 1;
    is_valid = is_valid and (c.isViableStructureTerrain(query.id, g, block_x, block_z) == 1);

    // End cities, per cubiomes documentation, have special generation requirements
    if (query.id == c.End_City) {
        var sn: c.SurfaceNoise = undefined;
        c.initSurfaceNoise(&sn, c.DIM_END, query.seed);
        is_valid = is_valid and (c.isViableEndCityTerrain(g, &sn, block_x, block_z) == 1);
    }

    return if (is_valid) pos else null;
}
