const std = @import("std");

const PartitionBox = struct {
    min_x: i32,
    max_x: i32,
    min_z: i32,
    max_z: i32,
};

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
