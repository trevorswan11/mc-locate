const std = @import("std");
const c = @cImport({
    @cInclude("generator.h");
    @cInclude("finders.h");
});

const partition = @import("partition.zig");

// Check every 8 blocks (half of a chunk) on 4 threads
pub const NUM_THREADS = 4; // Most stable with 4 threads, but works with 6 usually
pub const STEP = 8;

pub const Query = struct {
    seed: u64,
    dim: c_int = c.DIM_OVERWORLD,
    biome_id: c_int,
    x: c_int,
    z: c_int,
    radius: c_int = 10000,
};

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

// All information needed for a thread to search in its region for a biome
const ThreadData = struct {
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
};

/// Defines the work to be done per thread to find the specific biome id
fn workerThread(data: *ThreadData) void {
    var g: c.Generator = undefined;
    var rand: u64 = undefined;
    c.setSeed(&rand, data.seed);
    c.setupGenerator(&g, c.MC_1_21, 0);
    c.applySeed(&g, data.dim, data.seed);

    // Search the threads alloted region in the partition
    var z = data.min_z;
    while (z <= data.max_z) : (z += STEP) {
        var x = data.min_x;
        while (x <= data.max_x) : (x += STEP) {
            // We can stop the threads work if another thread has found something
            data.shared.mutex.lock();
            const should_stop = data.shared.result.found;
            data.shared.mutex.unlock();
            if (should_stop) return;

            // Use cubiomes to poll the biome at the coordinate, use default y value as it does not matter
            const id = c.getBiomeAt(&g, 1, x, 60, z);
            if (id == data.biome_id) {
                // Lock the shared data temporarily to prevent race conditions
                data.shared.mutex.lock();
                if (!data.shared.result.found) {
                    data.shared.result = .{ .x = x, .z = z, .found = true };
                }
                data.shared.mutex.unlock();
                return;
            }
        }
    }
}

/// Attempts to locate a biome in the given square radius about a center coordinate
pub fn find(allocator: std.mem.Allocator, query: Query) !?Result {
    var shared = SharedResult{};
    var threads: [NUM_THREADS]std.Thread = undefined;
    var thread_data: [NUM_THREADS]ThreadData = undefined;

    const boxes = try partition.generatePartitions(
        allocator,
        NUM_THREADS,
        query.x,
        query.z,
        query.radius,
    );
    defer allocator.free(boxes);

    for (&threads, 0..) |*t, i| {
        const box = boxes[i];
        thread_data[i] = ThreadData{
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
        if (thread_data[i].min_x > thread_data[i].max_x) {
            std.mem.swap(c_int, &thread_data[i].min_x, &thread_data[i].max_x);
        }
        if (thread_data[i].min_z > thread_data[i].max_z) {
            std.mem.swap(c_int, &thread_data[i].min_z, &thread_data[i].max_z);
        }

        t.* = try std.Thread.spawn(.{}, workerThread, .{&thread_data[i]});
    }

    for (&threads) |*t| {
        t.join();
    }

    if (shared.result.found) {
        return Result{
            .x = shared.result.x,
            .z = shared.result.z,
        };
    } else {
        return null;
    }
}
