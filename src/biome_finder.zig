const std = @import("std");
const c = @cImport({
    @cInclude("generator.h");
    @cInclude("finders.h");
});

const globals = @import("globals.zig");

pub const STEP = 8;

// Search specific information
pub const Query = struct {
    seed: u64,
    dim: c_int,
    biome_id: c_int,
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
    start_x: i32,
    end_x: i32,
    center_z: i32,
    max_radius: i32,
    shared_mutex: *std.Thread.Mutex,
    shared_found: *bool,
    result: *?Result,
    count: u64 = 0,
};

/// Defines the work to be done per thread to find the specific structure id
fn worker(ctx: *ThreadContext, counting: bool) void {
    var g: c.Generator = undefined;
    var rand: u64 = undefined;
    c.setSeed(&rand, ctx.query.seed);
    c.setupGenerator(&g, globals.MC_VER, 0);
    c.applySeed(&g, ctx.query.dim, ctx.query.seed);

    const min_z = ctx.center_z - ctx.max_radius;
    const max_z = ctx.center_z + ctx.max_radius;

    // Search the threads alloted region in the radii
    var x = ctx.start_x;
    while (x <= ctx.end_x) : (x += STEP) {
        var z = min_z;
        while (z <= max_z) : (z += STEP) {
            // Check shared state before wasting more work
            ctx.shared_mutex.lock();
            const should_stop = ctx.shared_found.*;
            ctx.shared_mutex.unlock();
            if (should_stop) {
                return;
            }

            if (counting) {
                ctx.count += 1;
            }

            const biome = c.getBiomeAt(&g, 1, x, 60, z);
            if (biome == ctx.query.biome_id) {
                ctx.shared_mutex.lock();
                defer ctx.shared_mutex.unlock();
                if (!ctx.shared_found.*) {
                    ctx.shared_found.* = true;
                    ctx.result.* = Result{ .x = x, .z = z };
                }
                return;
            }
        }
    }
}

pub fn find(query: Query) !?Result {
    // Check the center first
    var g: c.Generator = undefined;
    c.setupGenerator(&g, globals.MC_VER, 0);
    c.applySeed(&g, query.dim, query.seed);
    const biome_at_center = c.getBiomeAt(&g, 1, query.x, 60, query.z);
    if (biome_at_center == query.biome_id) {
        return Result{
            .x = query.x,
            .z = query.z,
        };
    }

    const total_width = query.radius * 2 + 1;
    const step = @divFloor(total_width + globals.NUM_THREADS - 1, globals.NUM_THREADS);

    var mutex = std.Thread.Mutex{};
    var found = false;
    var result: ?Result = null;

    var threads: [globals.NUM_THREADS]std.Thread = undefined;
    var thread_ctx: [globals.NUM_THREADS]*ThreadContext = undefined;

    var i: usize = 0;
    while (i < globals.NUM_THREADS) : (i += 1) {
        const start_x = query.x - query.radius + @as(i32, @intCast(i)) * @as(i32, @intCast(step));
        const end_x = @min(
            query.x - query.radius + @as(i32, @intCast(i + 1)) * @as(i32, @intCast(step)) - 1,
            query.x + query.radius,
        );

        const ctx = try std.heap.page_allocator.create(ThreadContext);
        ctx.* = ThreadContext{
            .query = query,
            .start_x = start_x,
            .end_x = end_x,
            .center_z = query.z,
            .max_radius = query.radius,
            .shared_mutex = &mutex,
            .shared_found = &found,
            .result = &result,
        };

        threads[i] = try std.Thread.spawn(.{}, worker, .{ ctx, query.count });
        thread_ctx[i] = ctx;
    }

    for (threads) |t| {
        t.join();
    }

    if (query.count) {
        var total: u64 = 0;
        inline for (thread_ctx, 1..) |tx, j| {
            total += tx.count;
            std.debug.print("Thread {d}: {d} checks\n", .{ j, tx.count });
        }
        std.debug.print("Total checks: {d}\n", .{total});
    }

    return result;
}
