const std = @import("std");
const c = @cImport({
    @cInclude("generator.h");
    @cInclude("stdio.h");
    @cInclude("inttypes.h");
});

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Set up a biome generator for Minecraft 1.18
    var g: c.Generator = undefined;
    _ = c.setupGenerator(&g, c.MC_1_18, 0);

    var seed: u64 = 0;
    const scale: c_int = 1; // block coordinates
    const x: c_int = 0;
    const y: c_int = 63;
    const z: c_int = 0;

    while (true) : (seed += 1) {
        _ = c.applySeed(&g, c.DIM_OVERWORLD, seed);

        const biomeID = c.getBiomeAt(&g, scale, x, y, z);
        if (biomeID == c.mushroom_fields) {
            try stdout.print(
                "Seed {d} has a Mushroom Fields biome at block position ({d}, {d}).\n",
                .{ seed, x, z }
            );
            break;
        }
    }
}
