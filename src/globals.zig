const c = @cImport({
    @cInclude("generator.h");
    @cInclude("finders.h");
});

/// The total threads used. Most stable with 4 threads, but works with 6 usually
pub const NUM_THREADS = 4;

/// The minecraft version to use with the query
pub const MC_VER = c.MC_NEWEST;

/// Square radius, in blocks, to search around query point
pub const SEARCH_RADIUS: c_int = 10_000;

/// The block-based increment to use in qualifying searches (e.g. biomes)
pub const SEARCH_STEP = 16;

/// Search specific information
pub const Query = struct {
    seed: u64,
    dim: c_int,
    id: c_int,
    x: c_int,
    z: c_int,
    radius: c_int = SEARCH_RADIUS,
    count: bool,
};

/// Packed coordinate result information
pub const Result = struct {
    x: c_int,
    z: c_int,
    message: []u8 = "",
};

/// Returns the magnitude squared of the displacement vector between the positions
pub fn distanceSquared(pos1: c.Pos, pos2: c.Pos) u64 {
    const dx = @as(i64, pos1.x) - @as(i64, pos2.x);
    const dz = @as(i64, pos1.z) - @as(i64, pos2.z);
    return @as(u64, @intCast(dx * dx + dz * dz));
}
