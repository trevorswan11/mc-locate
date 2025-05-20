const std = @import("std");
const c = @cImport({
    @cInclude("generator.h");
    @cInclude("finders.h");
});

const globals = @import("globals.zig");

// Check every 8 blocks (half of a chunk)
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

// Internal struct to track help with returning
const FoundBiome = struct {
    x: c_int,
    z: c_int,
    found: bool,
};

// Thread safe way to track progress
const SharedResult = struct {
    mutex: std.Thread.Mutex = .{},
    result: FoundBiome = .{
        .x = 0,
        .z = 0,
        .found = false,
    },
};

// Helper struct to define search regions
const PartitionBox = struct {
    min_x: i32,
    max_x: i32,
    min_z: i32,
    max_z: i32,
};

// All information needed for a thread to search in its region for a biome
const ThreadContext = struct {
    seed: u64,
    dim: c_int,
    biome_id: c_int,
    center_x: c_int,
    center_z: c_int,
    min_x: c_int,
    max_x: c_int,
    min_z: c_int,
    max_z: c_int,
    shared: *SharedResult,
    count: u64 = 0,
};

/// Defines the work to be done per thread to find the specific biome id
fn worker(ctx: *ThreadContext, counting: bool) void {
    var g: c.Generator = undefined;
    var rand: u64 = undefined;
    c.setSeed(&rand, ctx.seed);
    c.setupGenerator(&g, globals.MC_VER, 0);
    c.applySeed(&g, ctx.dim, ctx.seed);

    // Search the threads alloted region in the partition
    var z = ctx.min_z;
    while (z <= ctx.max_z) : (z += STEP) {
        var x = ctx.min_x;
        while (x <= ctx.max_x) : (x += STEP) {
            // We can stop the threads work if another thread has found something
            ctx.shared.mutex.lock();
            const should_stop = ctx.shared.result.found;
            ctx.shared.mutex.unlock();
            if (should_stop) return;

            // Use cubiomes to poll the biome at the coordinate, use default y value as it does not matter
            const id = c.getBiomeAt(&g, 1, x, 60, z);
            if (counting) {
                ctx.count += 1;
            }
            if (id == ctx.biome_id) {
                // Lock the shared data temporarily to prevent race conditions
                ctx.shared.mutex.lock();
                if (!ctx.shared.result.found) {
                    ctx.shared.result = .{ .x = x, .z = z, .found = true };
                }
                ctx.shared.mutex.unlock();
                return;
            }
        }
    }
}

/// Attempts to locate a biome in the given square radius about a center coordinate
pub fn find(allocator: std.mem.Allocator, query: Query) !?Result {
    var shared = SharedResult{};
    var threads: [globals.NUM_THREADS]std.Thread = undefined;
    var thread_ctx: [globals.NUM_THREADS]ThreadContext = undefined;

    const boxes = try generatePartitions(
        allocator,
        globals.NUM_THREADS,
        query.x,
        query.z,
        query.radius,
    );
    defer allocator.free(boxes);

    for (&threads, 0..) |*t, i| {
        const box = boxes[i];
        thread_ctx[i] = ThreadContext{
            .seed = query.seed,
            .dim = query.dim,
            .biome_id = query.biome_id,
            .center_x = query.x,
            .center_z = query.z,
            .min_x = box.min_x,
            .max_x = box.max_x,
            .min_z = box.min_z,
            .max_z = box.max_z,
            .shared = &shared,
        };

        // Prevents negative coordinate errors if the inputs were flipped
        if (thread_ctx[i].min_x > thread_ctx[i].max_x) {
            std.mem.swap(c_int, &thread_ctx[i].min_x, &thread_ctx[i].max_x);
        }
        if (thread_ctx[i].min_z > thread_ctx[i].max_z) {
            std.mem.swap(c_int, &thread_ctx[i].min_z, &thread_ctx[i].max_z);
        }

        t.* = try std.Thread.spawn(.{}, worker, .{ &thread_ctx[i], query.count });
    }

    for (&threads) |*t| {
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

    return if (shared.result.found) Result{
        .x = shared.result.x,
        .z = shared.result.z,
    } else null;
}

pub fn generatePartitions(
    allocator: std.mem.Allocator,
    num_threads: usize,
    center_x: i32,
    center_z: i32,
    radius: i32,
) ![]PartitionBox {
    const boxes = try allocator.alloc(PartitionBox, num_threads);
    var w: usize = std.math.sqrt(num_threads);
    while (num_threads % w != 0) : (w -= 1) {}
    const h = num_threads / w;

    // generate tile dimensions for the threads
    const tile_width: i32 = @divFloor((radius * 2 + (@as(i32, @intCast(w))) - 1), @as(i32, @intCast(w)));
    const tile_height: i32 = @divFloor((radius * 2 + (@as(i32, @intCast(h))) - 1), @as(i32, @intCast(h)));

    var i: usize = 0;
    var row: usize = 0;
    while (row < h) : (row += 1) {
        var col: usize = 0;
        while (col < w) : (col += 1) {
            // Compute the coordinates of the box for the thread
            const left = center_x - radius + tile_width * @as(i32, @intCast(col));
            const right = @min(left + tile_width - 1, center_x + radius);
            const top = center_z - radius + tile_height * @as(i32, @intCast(row));
            const bottom = @min(top + tile_height - 1, center_z + radius);

            boxes[i] = .{
                .min_x = left,
                .max_x = right,
                .min_z = top,
                .max_z = bottom,
            };
            i += 1;
        }
    }

    return boxes;
}
