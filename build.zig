const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });
    const exe = b.addExecutable(.{
        .name = "mclocate",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const c_files = getCSourceFiles(std.heap.page_allocator, "cubiomes") catch {
        std.debug.print("Fuck you.\n", .{});
        return;
    };
    exe.addCSourceFiles(.{
        .files = c_files.items,
        .flags = &.{ "-std=c99", "-O3" },
    });
    exe.addIncludePath(.{ .cwd_relative = "cubiomes" });
    exe.linkLibC();

    addRunStep(b, exe);
    b.installArtifact(exe);
}

fn addRunStep(b: *std.Build, exe: *std.Build.Step.Compile) void {
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn getCSourceFiles(allocator: std.mem.Allocator, directory: []const u8) !std.ArrayList([]const u8) {
    const cwd = std.fs.cwd();
    var dir = try cwd.openDir(directory, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var paths = std.ArrayList([]const u8).init(allocator);

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.basename, ".c")) continue;
        if (std.mem.eql(u8, entry.basename, "tests.c")) continue;

        const full_path = try std.fs.path.join(allocator, &.{ directory, entry.path });
        try paths.append(full_path);
    }

    return paths;
}
