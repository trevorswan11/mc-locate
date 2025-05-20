const std = @import("std");
const c = @cImport({
    @cInclude("generator.h");
    @cInclude("finders.h");
});

const globals = @import("globals.zig");
const structures = @import("regions.zig").StructureID;

// Search specific information
pub const Query = struct {
    seed: u64,
    dim: c_int,
    structure_id: c_int,
    x: c_int,
    z: c_int,
    radius: c_int = globals.SEARCH_RADIUS,
    count: bool,
};

// Packs a successful search for the user
pub const Result = struct {
    x: c_int,
    z: c_int,
};

// All information needed for a thread to search in its region for a structure
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
    var rand: u64 = undefined;
    c.setSeed(&rand, ctx.query.seed);
    c.setupGenerator(&g, globals.MC_VER, 0);
    c.applySeed(&g, ctx.query.dim, ctx.query.seed);

    // Follows the guide of test.c in cubiomes
    var local_best: ?c.Pos = null;
    var local_best_dist_sq: u64 = std.math.maxInt(u64);

    const min_z = ctx.center_region_z - ctx.max_radius;
    const max_z = ctx.center_region_z + ctx.max_radius;

    // Search the threads alloted region in the radii
    var rx = ctx.start_rx;
    while (rx <= ctx.end_rx) : (rx += 1) {
        var rz = min_z;
        while (rz <= max_z) : (rz += 1) {
            if (counting) {
                ctx.count += 1;
            }
            if (checkRegion(rx, rz, ctx.query, &g, sconf) catch null) |pos| {
                const dist_sq = distanceSquared(pos, ctx.query);
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

pub fn find(query: Query) !?Result {
    // Strongholds generate differently, this is constant per seed regardless of Query
    if (query.structure_id == @intFromEnum(structures.stronghold)) {
        return findNearestStronghold(query.seed, query.x, query.z);
    }

    var sconf: c.StructureConfig = undefined;
    if (c.getStructureConfig(query.structure_id, globals.MC_VER, &sconf) != 1) {
        return null;
    }
    const shift_val: i32 = @as(i32, @intCast(sconf.regionSize)) * 16;

    const center_rx = @divFloor(query.x, shift_val);
    const center_rz = @divFloor(query.z, shift_val);
    const max_r = @divFloor(query.radius, shift_val);

    var best_mutex = std.Thread.Mutex{};
    var best_pos: ?c.Pos = null;
    var best_dist_sq: u64 = std.math.maxInt(u64);

    const total_width = max_r * 2 + 1;
    const step = @divFloor(total_width + globals.NUM_THREADS - 1, globals.NUM_THREADS);
    var threads: [globals.NUM_THREADS]std.Thread = undefined;
    var thread_ctx: [globals.NUM_THREADS]*ThreadContext = undefined;

    // Kick off each thread by calculating the radius range and initializing its context
    var i: usize = 0;
    while (i < globals.NUM_THREADS) : (i += 1) {
        const start_rx = center_rx - max_r + @as(i32, @intCast(i)) * @as(i32, @intCast(step));
        const end_rx = @min(center_rx - max_r + (@as(i32, @intCast((i))) + 1) * @as(i32, @intCast(step)) - 1, center_rx + max_r);

        const ctx = try std.heap.page_allocator.create(ThreadContext);
        ctx.* = ThreadContext{
            .query = query,
            .start_rx = start_rx,
            .end_rx = end_rx,
            .center_region_z = center_rz,
            .max_radius = max_r,
            .best_mutex = &best_mutex,
            .best_pos = &best_pos,
            .best_dist_sq = &best_dist_sq,
        };

        threads[i] = try std.Thread.spawn(.{}, worker, .{ ctx, sconf, query.count });
        thread_ctx[i] = ctx;
    }

    for (threads) |t| {
        t.join();
    }

    // Print count info if requested
    if (query.count) {
        var total: u64 = 0;
        inline for (thread_ctx, 1..) |tx, j| {
            total += tx.count;
            std.debug.print("Thread {d}: {d} checks\n", .{ j, tx.count });
        }
        std.debug.print("Total checks: {d}\n", .{total});
    }

    return if (best_pos) |pos| Result{
        .x = pos.x,
        .z = pos.z,
    } else null;
}

/// Uses a custom, single threaded approach for finding strongholds as they are uniquely generated
fn findNearestStronghold(
    seed: u64,
    x: c_int,
    z: c_int,
) !?Result {
    var g: c.Generator = undefined;
    c.setupGenerator(&g, globals.MC_VER, 0);
    c.applySeed(&g, c.DIM_OVERWORLD, seed);

    var sh_iter: c.StrongholdIter = undefined;
    _ = c.initFirstStronghold(&sh_iter, globals.MC_VER, seed);

    var best_pos: ?c.Pos = null;
    var best_dist_sq: u64 = std.math.maxInt(u64);

    // There are only 128 total strongholds generated by minecraft
    var i: usize = 0;
    while (i < 128) : (i += 1) {
        const pos = sh_iter.pos;

        const dx = @as(i64, pos.x) - @as(i64, x);
        const dz = @as(i64, pos.z) - @as(i64, z);
        const dist_sq: u64 = @intCast(dx * dx + dz * dz);

        if (dist_sq < best_dist_sq) {
            best_dist_sq = dist_sq;
            best_pos = pos;
        }

        const more = c.nextStronghold(&sh_iter, &g);
        if (more <= 0) break;
    }

    return if (best_pos) |p| Result{
        .x = p.x,
        .z = p.z,
    } else null;
}

/// Follows the comments in test.c regarding valid structure generation
fn checkRegion(region_x: i32, region_z: i32, query: Query, g: *c.Generator, sconf: c.StructureConfig) !?c.Pos {
    var pos: c.Pos = undefined;
    const found = c.getStructurePos(query.structure_id, globals.MC_VER, query.seed, region_x, region_z, &pos) == 1;
    if (!found) return null;

    const block_x = region_x * sconf.regionSize * 16;
    const block_z = region_z * sconf.regionSize * 16;

    var is_valid = c.isViableStructurePos(query.structure_id, g, block_x, block_z, 0) == 1;
    is_valid = is_valid and (c.isViableStructureTerrain(query.structure_id, g, block_x, block_z) == 1);

    if (query.structure_id == c.End_City) {
        var sn: c.SurfaceNoise = undefined;
        c.initSurfaceNoise(&sn, c.DIM_END, query.seed);
        is_valid = is_valid and (c.isViableEndCityTerrain(g, &sn, block_x, block_z) == 1);
    }

    return if (is_valid) pos else null;
}

fn distanceSquared(pos: c.Pos, query: Query) u64 {
    const dx = @as(i64, pos.x) - @as(i64, query.x);
    const dz = @as(i64, pos.z) - @as(i64, query.z);
    return @as(u64, @intCast(dx * dx + dz * dz));
}
