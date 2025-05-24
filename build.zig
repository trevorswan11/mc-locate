const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    // Exe module configuration
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "mclocate",
        .root_module = exe_mod,
    });

    // Unit tests
    const test_step = b.step("test", "Run unit tests");
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    test_step.dependOn(&run_exe_unit_tests.step);

    // Interop with c
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
    addFmtStep(b);
    b.installArtifact(exe);
}

/// Allows the user to use zig build run with command line arguments following '--'
fn addRunStep(b: *std.Build, exe: *std.Build.Step.Compile) void {
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

/// Formats all source files to abide by Zig's formatting rules
fn addFmtStep(b: *std.Build) void {
    const lint = b.addSystemCommand(&[_][]const u8{
        "zig", "fmt", "src/",
    });

    const step = b.step("lint", "Check formatting of Zig source files");
    step.dependOn(&lint.step);
}

/// Gathers all c source files the given directory
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
