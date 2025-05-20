# mc-locate
A cli-based seed parsing tool for Java Minecraft. This repository serves as a wrapper, written in zig, of [Cubitect's cubiomes project](https://github.com/Cubitect/cubiomes). 

### Getting Started
1. Clone the repository and its submodules with `git clone --recursive https://github.com/trevorswan11/mc-locate`
2. Install [Zig](https://ziglang.org/) and include it in your systems path or somewhere else useable by your system
3. Build the binary with `zig build`. I used Zig 0.14.0, but other versions may work as well
4. After building, test functionality with `zig build run -- biome 262 o mushroom_island 0 0`. This should return "Found biome at (0, 0)"
5. Use `zig build run -- help` to see the help menu
6. To use this generally, you can either call the binary directly with `./mclocate <biome|structure> <seed> <dim> <id> <x> <z>`, or you can use zig directly and pass in the args following a '--' as `zig build run -- <biome|structure> <seed> <dim> <id> <x> <z>`

### Thread Safety
This project uses a multithreaded approach to efficiently query the given seed for the inputted biome. You are free to change the number of threads used by altering the `NUM_THREADS` global in the finder source files, but I have found the most consistency with 4 threads due to how the program divides work. Cubiomes is not inherently thread safe, so there may be some unanticipated behavior that will be investigated in the future. Similar steps are taken for finding structures.

### Practical Use
Minecraft servers are not multithreaded by default. This can cause lag while using the `/locate` command in certain server environments. As cubiomes works by generating its own virtual world, this wrapper can be used as a cli tool to perform biome searches away from the server thread. This can enhance server performance greatly, especially if you call the binary through a python or js hosted discord bot. If you are interested in the performance of the application, you can pass the word bench to the end of your command line arguments.

### Acknowledgements
Thank you to Cubitect for making such an easy to use API. While I know I probably didn't use it to its fullest, it was still a great way for me to continue learning Zig and to apply it to useful scenarios.
