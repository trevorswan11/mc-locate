const std = @import("std");
const c = @cImport({
    @cInclude("generator.h");
    @cInclude("finders.h");
});

const structures = @import("regions.zig").StructureID;

// I have found success with 4 threads, but more or less should work in theory
const NUM_THREADS = 4;

// Search specific information
pub const Query = struct {
    seed: u64,
    dim: c_int,
    structure_id: c_int,
    x: c_int,
    z: c_int,
    radius: c_int = 1000,
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
};

/// Defines the work to be done per thread to find the specific structure id
fn threadWorker(ctx: *ThreadContext) void {
    var g: c.Generator = undefined;
    var rand: u64 = undefined;
    c.setSeed(&rand, ctx.query.seed);
    c.setupGenerator(&g, c.MC_1_21, 0);
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
            if (checkRegion(rx, rz, ctx.query, &g) catch null) |pos| {
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
        const pos = c.initFirstStronghold(null, c.MC_1_21, query.seed);
        return Result{ .x = pos.x, .z = pos.z };
    }

    const region_shift = getStructureRegionShift(query.structure_id);
    const shift_val = std.math.shl(i32, 1, region_shift);

    const center_rx = @divFloor(query.x, shift_val);
    const center_rz = @divFloor(query.z, shift_val);
    const max_r = @divFloor(query.radius, shift_val);

    var best_mutex = std.Thread.Mutex{};
    var best_pos: ?c.Pos = null;
    var best_dist_sq: u64 = std.math.maxInt(u64);

    const total_width = max_r * 2 + 1;
    const step = @divFloor(total_width + NUM_THREADS - 1, NUM_THREADS);
    var threads: [NUM_THREADS]std.Thread = undefined;

    // Kick off each thread by calculating the radius range and initializing its context
    var i: usize = 0;
    while (i < NUM_THREADS) : (i += 1) {
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

        threads[i] = try std.Thread.spawn(.{}, threadWorker, .{ctx});
    }

    for (threads) |t| {
        t.join();
    }

    return if (best_pos) |pos| Result{ .x = pos.x, .z = pos.z } else null;
}

/// Helps distinguish structures that generate in such a way that require different bit shifts
fn getStructureRegionShift(id: c_int) u5 {
    return switch (id) {
        c.Village => 5,
        c.Bastion => 4,
        c.Monument => 6,
        c.Igloo => 4,
        c.Mansion => 6,
        c.Ruined_Portal => 4,
        c.Ruined_Portal_N => 4,
        c.Outpost => 5,
        c.Desert_Well => 4,
        c.Geode => 3,
        else => 9,
    };
}

/// Follows the comments in test.c regarding valid structure generation
fn checkRegion(x: i32, z: i32, query: Query, g: *c.Generator) !?c.Pos {
    var pos: c.Pos = undefined;
    const found = c.getStructurePos(query.structure_id, c.MC_1_21, query.seed, x, z, &pos) == 1;
    if (!found) return null;

    var is_valid = c.isViableStructurePos(query.structure_id, g, x, z, 0) == 1;
    is_valid = is_valid and (c.isViableStructureTerrain(query.structure_id, g, x, z) == 1);

    if (query.structure_id == c.End_City) {
        var sn: c.SurfaceNoise = undefined;
        c.initSurfaceNoise(&sn, c.DIM_END, query.seed);
        is_valid = is_valid and (c.isViableEndCityTerrain(g, &sn, x, z) == 1);
    }

    return if (is_valid) pos else null;
}

fn distanceSquared(pos: c.Pos, query: Query) u64 {
    const dx = @as(i64, pos.x) - @as(i64, query.x);
    const dz = @as(i64, pos.z) - @as(i64, query.z);
    return @as(u64, @intCast(dx * dx + dz * dz));
}

fn tryRegionUpdateNearest(
    x: i32,
    z: i32,
    query: Query,
    g: *c.Generator,
    best_dist_sq: *u64,
    nearest: *?c.Pos,
) void {
    if (checkRegion(x, z, query, g) catch null) |pos| {
        const dist_sq = distanceSquared(pos, query);
        if (dist_sq < best_dist_sq.*) {
            best_dist_sq.* = dist_sq;
            nearest.* = pos;
        }
    }
}
