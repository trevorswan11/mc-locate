#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json biome = {
        {"biome", "minecraft:plains"},
        {"temperature", 0.7}
    };

    std::cout << biome.dump(4) << "\n";
    return 0;
}
