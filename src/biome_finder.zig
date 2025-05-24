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
const SEARCH_STEP = globals.SEARCH_STEP;
const MC_VER = globals.MC_VER;
const NUM_THREADS = globals.NUM_THREADS;

/// All information needed for a thread to search in its region for a structure
const ThreadContext = struct {
    query: Query,
    start_x: i32,
    end_x: i32,
    center_z: i32,
    max_radius: i32,
    best_mutex: *std.Thread.Mutex,
    best_result: *?Result,
    best_dist_sq: *u64,
    count: u64 = 0,
};

/// Defines the work to be done per thread to find the specific structure id
fn worker(ctx: *ThreadContext, counting: bool) void {
    var g: c.Generator = undefined;
    c.setupGenerator(&g, MC_VER, 0);
    c.applySeed(&g, ctx.query.dim, ctx.query.seed);

    // Follows the guide of test.c in cubiomes
    var local_best: ?Result = null;
    var local_best_dist_sq: u64 = std.math.maxInt(u64);

    const min_z = ctx.center_z - ctx.max_radius;
    const max_z = ctx.center_z + ctx.max_radius;

    // Search the threads alloted region in the radii
    var x = ctx.start_x;
    while (x <= ctx.end_x) : (x += SEARCH_STEP) {
        var z = min_z;
        while (z <= max_z) : (z += SEARCH_STEP) {
            if (counting) {
                ctx.count += 1;
            }

            // All work done here is in blockspace, we can pass coordinates freely
            if (ctx.query.id == c.getBiomeAt(&g, 1, x, 60, z)) {
                const dist_sq = distanceSquared(.{
                    .x = x,
                    .z = z,
                }, .{
                    .x = ctx.query.x,
                    .z = ctx.query.z,
                });
                if (dist_sq < local_best_dist_sq) {
                    local_best_dist_sq = dist_sq;
                    local_best = .{
                        .x = x,
                        .z = z,
                    };
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
            ctx.best_result.* = pos;
        }
    }
}

/// Procedurally dispatches threads to find the closest structure to the query
pub fn find(query: Query) !?Result {
    // Perform a quick check at the input coordinates
    var g: c.Generator = undefined;
    c.setupGenerator(&g, MC_VER, 0);
    c.applySeed(&g, query.dim, query.seed);
    if (query.id == c.getBiomeAt(&g, 1, query.x, 60, query.z)) {
        return Result{
            .x = query.x,
            .z = query.z,
        };
    }

    // Declare local constants for thread work
    const center_x = query.x;
    const center_z = query.z;
    const max_r = query.radius;

    // Initialize struct members that will be used in the search
    var mutex = std.Thread.Mutex{};
    var best_dist_sq: u64 = std.math.maxInt(u64);
    var best_result: ?Result = null;

    // Initialize values that will be passed around for creating and observing desired behavior
    const total_width = max_r * 2 + 1;
    const step = @divFloor(total_width + NUM_THREADS - 1, NUM_THREADS);
    var threads: [NUM_THREADS]std.Thread = undefined;
    var thread_ctx: [NUM_THREADS]*ThreadContext = undefined;

    // Kick off each thread by calculating the radius range and initializing its context
    var i: usize = 0;
    while (i < NUM_THREADS) : (i += 1) {
        // Use the center block to derive the start and end blocks for the given thread
        const start_x = center_x - max_r + @as(i32, @intCast(i)) * @as(i32, @intCast(step));
        const end_x = @min(center_x - max_r + (@as(i32, @intCast((i))) + 1) * @as(i32, @intCast(step)) - 1, center_x + max_r);

        // Allocate memory for a new thread's data and ship it
        const ctx = try std.heap.page_allocator.create(ThreadContext);
        ctx.* = ThreadContext{
            .query = query,
            .start_x = start_x,
            .end_x = end_x,
            .center_z = center_z,
            .max_radius = max_r,
            .best_mutex = &mutex,
            .best_dist_sq = &best_dist_sq,
            .best_result = &best_result,
        };

        threads[i] = try std.Thread.spawn(.{}, worker, .{ ctx, query.count });
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

    return best_result;
}
