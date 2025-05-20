const std = @import("std");

pub const Dimensions = enum(i4) {
    nether = -1,
    overworld = 0,
    end = 1,
};

// --- BIOMES ---

pub const BiomeID = enum(i16) {
    none = -1,
    ocean = 0,
    plains,
    desert,
    mountains,
    forest,
    taiga,
    swamp,
    river,
    nether_wastes,
    the_end,
    frozen_ocean,
    frozen_river,
    snowy_tundra,
    snowy_mountains,
    mushroom_fields,
    mushroom_field_shore,
    beach,
    desert_hills,
    wooded_hills,
    taiga_hills,
    mountain_edge,
    jungle,
    jungle_hills,
    jungle_edge,
    deep_ocean,
    stone_shore,
    snowy_beach,
    birch_forest,
    birch_forest_hills,
    dark_forest,
    snowy_taiga,
    snowy_taiga_hills,
    giant_tree_taiga,
    giant_tree_taiga_hills,
    wooded_mountains,
    savanna,
    savanna_plateau,
    badlands,
    wooded_badlands_plateau,
    badlands_plateau,
    small_end_islands,
    end_midlands,
    end_highlands,
    end_barrens,
    warm_ocean,
    lukewarm_ocean,
    cold_ocean,
    deep_warm_ocean,
    deep_lukewarm_ocean,
    deep_cold_ocean,
    deep_frozen_ocean,
    seasonal_forest,
    rainforest,
    shrubland,
    the_void = 127,

    // Mutated/variant
    sunflower_plains = 129,
    desert_lakes = 130,
    gravelly_mountains = 131,
    flower_forest = 132,
    taiga_mountains = 133,
    swamp_hills = 134,
    ice_spikes = 140,
    modified_jungle = 149,
    modified_jungle_edge = 151,
    tall_birch_forest = 155,
    tall_birch_hills = 156,
    dark_forest_hills = 157,
    snowy_taiga_mountains = 158,
    giant_spruce_taiga = 160,
    giant_spruce_taiga_hills = 161,
    modified_gravelly_mountains = 162,
    shattered_savanna = 163,
    shattered_savanna_plateau = 164,
    eroded_badlands = 165,
    modified_wooded_badlands_plateau = 166,
    modified_badlands_plateau = 167,

    bamboo_jungle = 168,
    bamboo_jungle_hills = 169,
    soul_sand_valley = 170,
    crimson_forest = 171,
    warped_forest = 172,
    basalt_deltas = 173,
    dripstone_caves = 174,
    lush_caves = 175,
    meadow = 177,
    grove = 178,
    snowy_slopes = 179,
    jagged_peaks = 180,
    frozen_peaks = 181,
    stony_peaks = 182,
    deep_dark = 183,
    mangrove_swamp = 184,
    cherry_grove = 185,
    pale_garden = 186,
};

pub fn getOverworldBiomes(allocator: std.mem.Allocator) !std.StringHashMap(BiomeID) {
    var map = std.StringHashMap(BiomeID).init(allocator);

    // try map.put("none", .none);
    try map.put("ocean", .ocean);
    try map.put("plains", .plains);
    try map.put("desert", .desert);
    try map.put("mountains", .mountains);
    try map.put("extremeHills", .mountains);
    try map.put("forest", .forest);
    try map.put("taiga", .taiga);
    try map.put("swamp", .swamp);
    try map.put("swampland", .swamp);
    try map.put("river", .river);
    try map.put("frozen_ocean", .frozen_ocean);
    try map.put("frozen_river", .frozen_river);
    try map.put("snowy_tundra", .snowy_tundra);
    try map.put("ice_plains", .snowy_tundra);
    try map.put("snowy_mountains", .snowy_mountains);
    try map.put("ice_mountains", .snowy_mountains);
    try map.put("mushroom_fields", .mushroom_fields);
    try map.put("mushroom_island", .mushroom_fields);
    try map.put("mushroom_field_shore", .mushroom_field_shore);
    try map.put("mushroom_island_shore", .mushroom_field_shore);
    try map.put("beach", .beach);
    try map.put("desert_hills", .desert_hills);
    try map.put("wooded_hills", .wooded_hills);
    try map.put("forest_hills", .wooded_hills);
    try map.put("taiga_hills", .taiga_hills);
    try map.put("mountain_edge", .mountain_edge);
    try map.put("extreme_hills_edge", .mountain_edge);
    try map.put("jungle", .jungle);
    try map.put("jungle_hills", .jungle_hills);
    try map.put("jungle_edge", .jungle_edge);
    try map.put("deep_ocean", .deep_ocean);
    try map.put("stone_shore", .stone_shore);
    try map.put("stone_beach", .stone_shore);
    try map.put("snowy_beach", .snowy_beach);
    try map.put("coldBeach", .snowy_beach);
    try map.put("birch_forest", .birch_forest);
    try map.put("birch_forest_hills", .birch_forest_hills);
    try map.put("dark_forest", .dark_forest);
    try map.put("roofed_forest", .dark_forest);
    try map.put("snowy_taiga", .snowy_taiga);
    try map.put("cold_taiga", .snowy_taiga);
    try map.put("snowy_taiga_hills", .snowy_taiga_hills);
    try map.put("cold_taiga_hills", .snowy_taiga_hills);
    try map.put("giant_tree_taiga", .giant_tree_taiga);
    try map.put("mega_taiga", .giant_tree_taiga);
    try map.put("giant_tree_taiga_hills", .giant_tree_taiga_hills);
    try map.put("mega_taiga_hills", .giant_tree_taiga_hills);
    try map.put("wooded_mountains", .wooded_mountains);
    try map.put("extreme_hills_plus", .wooded_mountains);
    try map.put("savanna", .savanna);
    try map.put("savanna_plateau", .savanna_plateau);
    try map.put("badlands", .badlands);
    try map.put("mesa", .badlands);
    try map.put("wooded_badlands_plateau", .wooded_badlands_plateau);
    try map.put("badlands_plateau", .badlands_plateau);
    try map.put("mesa_plateau", .badlands_plateau);
    try map.put("warm_ocean", .warm_ocean);
    try map.put("lukewarm_ocean", .lukewarm_ocean);
    try map.put("cold_ocean", .cold_ocean);
    try map.put("deep_warm_ocean", .deep_warm_ocean);
    try map.put("deep_lukewarm_ocean", .deep_lukewarm_ocean);
    try map.put("deep_cold_ocean", .deep_cold_ocean);
    try map.put("deep_frozen_ocean", .deep_frozen_ocean);
    try map.put("seasonal_forest", .seasonal_forest);
    try map.put("rainforest", .rainforest);
    try map.put("shrubland", .shrubland);
    // try map.put("the_void", .the_void);
    try map.put("sunflower_plains", .sunflower_plains);
    try map.put("desert_lakes", .desert_lakes);
    try map.put("gravelly_mountains", .gravelly_mountains);
    try map.put("flower_forest", .flower_forest);
    try map.put("taiga_mountains", .taiga_mountains);
    try map.put("swamp_hills", .swamp_hills);
    try map.put("ice_spikes", .ice_spikes);
    try map.put("modified_jungle", .modified_jungle);
    try map.put("modified_jungle_edge", .modified_jungle_edge);
    try map.put("tall_birch_forest", .tall_birch_forest);
    try map.put("tall_birch_hills", .tall_birch_hills);
    try map.put("dark_forest_hills", .dark_forest_hills);
    try map.put("snowy_taiga_mountains", .snowy_taiga_mountains);
    try map.put("giant_spruce_taiga", .giant_spruce_taiga);
    try map.put("giant_spruce_taiga_hills", .giant_spruce_taiga_hills);
    try map.put("modified_gravelly_mountains", .modified_gravelly_mountains);
    try map.put("shattered_savanna", .shattered_savanna);
    try map.put("shattered_savanna_plateau", .shattered_savanna_plateau);
    try map.put("eroded_badlands", .eroded_badlands);
    try map.put("modified_wooded_badlands_plateau", .modified_wooded_badlands_plateau);
    try map.put("modified_badlands_plateau", .modified_badlands_plateau);
    try map.put("bamboo_jungle", .bamboo_jungle);
    try map.put("bamboo_jungle_hills", .bamboo_jungle_hills);
    try map.put("dripstone_caves", .dripstone_caves);
    try map.put("lush_caves", .lush_caves);
    try map.put("meadow", .meadow);
    try map.put("grove", .grove);
    try map.put("snowy_slopes", .snowy_slopes);
    try map.put("jagged_peaks", .jagged_peaks);
    try map.put("frozen_peaks", .frozen_peaks);
    try map.put("stony_peaks", .stony_peaks);
    try map.put("old_growth_birch_forest", .tall_birch_forest);
    try map.put("old_growth_pine_taiga", .giant_tree_taiga);
    try map.put("old_growth_spruce_taiga", .giant_spruce_taiga);
    try map.put("snowy_plains", .snowy_tundra);
    try map.put("sparse_jungle", .jungle_edge);
    try map.put("stony_shore", .stone_shore);
    try map.put("windswept_hills", .mountains);
    try map.put("windswept_forest", .wooded_mountains);
    try map.put("windswept_gravelly_hills", .gravelly_mountains);
    try map.put("windswept_savanna", .shattered_savanna);
    try map.put("wooded_badlands", .wooded_badlands_plateau);
    try map.put("deep_dark", .deep_dark);
    try map.put("mangrove_swamp", .mangrove_swamp);
    try map.put("cherry_grove", .cherry_grove);
    try map.put("pale_garden", .pale_garden);

    return map;
}

pub fn getNetherBiomes(allocator: std.mem.Allocator) !std.StringHashMap(BiomeID) {
    var map = std.StringHashMap(BiomeID).init(allocator);

    try map.put("nether_wastes", .nether_wastes);
    try map.put("soul_sand_valley", .soul_sand_valley);
    try map.put("crimson_forest", .crimson_forest);
    try map.put("warped_forest", .warped_forest);
    try map.put("basalt_deltas", .basalt_deltas);

    return map;
}

pub fn getEndBiomes(allocator: std.mem.Allocator) !std.StringHashMap(BiomeID) {
    var map = std.StringHashMap(BiomeID).init(allocator);

    try map.put("the_end", .the_end);
    try map.put("sky", .the_end);
    try map.put("small_end_islands", .small_end_islands);
    try map.put("end_midlands", .end_midlands);
    try map.put("end_highlands", .end_highlands);
    try map.put("end_barrens", .end_barrens);

    return map;
}

pub fn biomeHelpMessage() ![]const u8 {
    const allocator = std.heap.page_allocator;

    var overworld = try getOverworldBiomes(allocator);
    defer overworld.deinit();
    var oveitr = overworld.keyIterator();

    var nether = try getNetherBiomes(allocator);
    defer nether.deinit();
    var netitr = nether.keyIterator();

    var end = try getEndBiomes(allocator);
    defer end.deinit();
    var enditr = end.keyIterator();

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    try result.appendSlice("**All Accepted Dimensions for 1.21.x:**\n");
    try result.appendSlice("- The Nether: use <dim> = 'n'\n");
    try result.appendSlice("- The Overworld: use <dim> = 'o'\n");
    try result.appendSlice("- The End: use <dim> = 'e'\n\n");

    try result.appendSlice("**All Accepted Biomes for 1.21.x:**\n");
    try result.appendSlice("__The Overworld__\n");

    while (oveitr.next()) |key| {
        try result.appendSlice("- ");
        try result.appendSlice(key.*);
        try result.appendSlice("\n");
    }

    try result.appendSlice("\n__The Nether__\n");
    while (netitr.next()) |key| {
        try result.appendSlice("- ");
        try result.appendSlice(key.*);
        try result.appendSlice("\n");
    }

    try result.appendSlice("\n__The End__\n");
    while (enditr.next()) |key| {
        try result.appendSlice("- ");
        try result.appendSlice(key.*);
        try result.appendSlice("\n");
    }

    return try result.toOwnedSlice();
}

// --- STRUCTURES ---

pub const StructureID = enum(i16) {
    desert_pyramid = 1,
    jungle_temple,
    swamp_hut,
    igloo,
    village,
    ocean_ruin,
    shipwreck,
    monument,
    mansion,
    outpost,
    ruined_portal,
    ruined_portal_nether,
    ancient_city,
    treasure,
    mineshaft,
    desert_well,
    geode,
    fortress,
    bastion,
    end_city,
    end_gateway,
    end_island,
    trail_ruins,
    trial_chambers,
    stronghold,
};

pub fn getOverworldStructures(allocator: std.mem.Allocator) !std.StringHashMap(StructureID) {
    var map = std.StringHashMap(StructureID).init(allocator);

    try map.put("desert_pyramid", .desert_pyramid);
    try map.put("jungle_temple", .jungle_temple);
    try map.put("swamp_hut", .swamp_hut);
    try map.put("igloo", .igloo);
    try map.put("village", .village);
    try map.put("ocean_ruin", .ocean_ruin);
    try map.put("shipwreck", .shipwreck);
    try map.put("monument", .monument);
    try map.put("mansion", .mansion);
    try map.put("outpost", .outpost);
    try map.put("ruined_portal", .ruined_portal);
    try map.put("ancient_city", .ancient_city);
    try map.put("treasure", .treasure);
    try map.put("mineshaft", .mineshaft);
    try map.put("desert_well", .desert_well);
    try map.put("geode", .geode);
    try map.put("trail_ruins", .trail_ruins);
    try map.put("trial_chambers", .trial_chambers);
    try map.put("stronghold", .stronghold);

    return map;
}

pub fn getNetherStructures(allocator: std.mem.Allocator) !std.StringHashMap(StructureID) {
    var map = std.StringHashMap(StructureID).init(allocator);

    try map.put("ruined_portal_nether", .ruined_portal_nether);
    try map.put("fortress", .fortress);
    try map.put("bastion", .bastion);

    return map;
}

pub fn getEndStructures(allocator: std.mem.Allocator) !std.StringHashMap(StructureID) {
    var map = std.StringHashMap(StructureID).init(allocator);

    try map.put("end_city", .end_city);
    try map.put("end_gateway", .end_gateway);
    try map.put("end_island", .end_island);

    return map;
}

pub fn structureHelpMessage() ![]const u8 {
    const allocator = std.heap.page_allocator;

    var overworld = try getOverworldStructures(allocator);
    defer overworld.deinit();
    var oveitr = overworld.keyIterator();

    var nether = try getNetherStructures(allocator);
    defer nether.deinit();
    var netitr = nether.keyIterator();

    var end = try getEndStructures(allocator);
    defer end.deinit();
    var enditr = end.keyIterator();

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    try result.appendSlice("**All Accepted Dimensions for 1.21.x:**\n");
    try result.appendSlice("- The Nether: use <dim> = 'n'\n");
    try result.appendSlice("- The Overworld: use <dim> = 'o'\n");
    try result.appendSlice("- The End: use <dim> = 'e'\n\n");

    try result.appendSlice("**All Accepted Structures for 1.21.x:**\n");
    try result.appendSlice("__The Overworld__\n");

    while (oveitr.next()) |key| {
        try result.appendSlice("- ");
        try result.appendSlice(key.*);
        try result.appendSlice("\n");
    }

    try result.appendSlice("\n__The Nether__\n");
    while (netitr.next()) |key| {
        try result.appendSlice("- ");
        try result.appendSlice(key.*);
        try result.appendSlice("\n");
    }

    try result.appendSlice("\n__The End__\n");
    while (enditr.next()) |key| {
        try result.appendSlice("- ");
        try result.appendSlice(key.*);
        try result.appendSlice("\n");
    }

    return try result.toOwnedSlice();
}
