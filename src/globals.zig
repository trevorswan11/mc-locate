const c = @cImport({
    @cInclude("generator.h");
    @cInclude("finders.h");
});

// Most stable with 4 threads, but works with 6 usually
pub const NUM_THREADS = 4;

// Only tested so far with 1.21.x
pub const MC_VER = c.MC_1_21;

// Consistent with a radius of 10_000
pub const SEARCH_RADIUS: c_int = 10_000;