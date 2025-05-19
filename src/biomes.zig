const std = @import("std");

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

pub fn getBiomeMap(allocator: std.mem.Allocator) !std.StringHashMap(BiomeID) {
    var map = std.StringHashMap(BiomeID).init(allocator);

    try map.put("none", .none);
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
    try map.put("nether_wastes", .nether_wastes);
    try map.put("hell", .nether_wastes);
    try map.put("the_end", .the_end);
    try map.put("sky", .the_end);
    try map.put("frozen_ocean", .frozen_ocean);
    try map.put("frozenOcean", .frozen_ocean);
    try map.put("frozen_river", .frozen_river);
    try map.put("frozenRiver", .frozen_river);
    try map.put("snowy_tundra", .snowy_tundra);
    try map.put("icePlains", .snowy_tundra);
    try map.put("snowy_mountains", .snowy_mountains);
    try map.put("iceMountains", .snowy_mountains);
    try map.put("mushroom_fields", .mushroom_fields);
    try map.put("mushroomIsland", .mushroom_fields);
    try map.put("mushroom_field_shore", .mushroom_field_shore);
    try map.put("mushroomIslandShore", .mushroom_field_shore);
    try map.put("beach", .beach);
    try map.put("desert_hills", .desert_hills);
    try map.put("desertHills", .desert_hills);
    try map.put("wooded_hills", .wooded_hills);
    try map.put("forestHills", .wooded_hills);
    try map.put("taiga_hills", .taiga_hills);
    try map.put("taigaHills", .taiga_hills);
    try map.put("mountain_edge", .mountain_edge);
    try map.put("extremeHillsEdge", .mountain_edge);
    try map.put("jungle", .jungle);
    try map.put("jungle_hills", .jungle_hills);
    try map.put("jungleHills", .jungle_hills);
    try map.put("jungle_edge", .jungle_edge);
    try map.put("jungleEdge", .jungle_edge);
    try map.put("deep_ocean", .deep_ocean);
    try map.put("deepOcean", .deep_ocean);
    try map.put("stone_shore", .stone_shore);
    try map.put("stoneBeach", .stone_shore);
    try map.put("snowy_beach", .snowy_beach);
    try map.put("coldBeach", .snowy_beach);
    try map.put("birch_forest", .birch_forest);
    try map.put("birchForest", .birch_forest);
    try map.put("birch_forest_hills", .birch_forest_hills);
    try map.put("birchForestHills", .birch_forest_hills);
    try map.put("dark_forest", .dark_forest);
    try map.put("roofedForest", .dark_forest);
    try map.put("snowy_taiga", .snowy_taiga);
    try map.put("coldTaiga", .snowy_taiga);
    try map.put("snowy_taiga_hills", .snowy_taiga_hills);
    try map.put("coldTaigaHills", .snowy_taiga_hills);
    try map.put("giant_tree_taiga", .giant_tree_taiga);
    try map.put("megaTaiga", .giant_tree_taiga);
    try map.put("giant_tree_taiga_hills", .giant_tree_taiga_hills);
    try map.put("megaTaigaHills", .giant_tree_taiga_hills);
    try map.put("wooded_mountains", .wooded_mountains);
    try map.put("extremeHillsPlus", .wooded_mountains);
    try map.put("savanna", .savanna);
    try map.put("savanna_plateau", .savanna_plateau);
    try map.put("savannaPlateau", .savanna_plateau);
    try map.put("badlands", .badlands);
    try map.put("mesa", .badlands);
    try map.put("wooded_badlands_plateau", .wooded_badlands_plateau);
    try map.put("mesaPlateau_F", .wooded_badlands_plateau);
    try map.put("badlands_plateau", .badlands_plateau);
    try map.put("mesaPlateau", .badlands_plateau);
    try map.put("small_end_islands", .small_end_islands);
    try map.put("end_midlands", .end_midlands);
    try map.put("end_highlands", .end_highlands);
    try map.put("end_barrens", .end_barrens);
    try map.put("warm_ocean", .warm_ocean);
    try map.put("warmOcean", .warm_ocean);
    try map.put("lukewarm_ocean", .lukewarm_ocean);
    try map.put("lukewarmOcean", .lukewarm_ocean);
    try map.put("cold_ocean", .cold_ocean);
    try map.put("coldOcean", .cold_ocean);
    try map.put("deep_warm_ocean", .deep_warm_ocean);
    try map.put("warmDeepOcean", .deep_warm_ocean);
    try map.put("deep_lukewarm_ocean", .deep_lukewarm_ocean);
    try map.put("lukewarmDeepOcean", .deep_lukewarm_ocean);
    try map.put("deep_cold_ocean", .deep_cold_ocean);
    try map.put("coldDeepOcean", .deep_cold_ocean);
    try map.put("deep_frozen_ocean", .deep_frozen_ocean);
    try map.put("frozenDeepOcean", .deep_frozen_ocean);
    try map.put("seasonal_forest", .seasonal_forest);
    try map.put("rainforest", .rainforest);
    try map.put("shrubland", .shrubland);
    try map.put("the_void", .the_void);
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
    try map.put("soul_sand_valley", .soul_sand_valley);
    try map.put("crimson_forest", .crimson_forest);
    try map.put("warped_forest", .warped_forest);
    try map.put("basalt_deltas", .basalt_deltas);
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
