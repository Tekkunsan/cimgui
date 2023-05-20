const std = @import("std");

const cImgui = @import("../../build.zig");
const zglfw = @import("deps/zglfw/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "glfw_opengl3",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const zglfw_pkg = zglfw.package(b, target, optimize, .{});
    zglfw_pkg.link(exe);

    const cImgui_lib = cImgui.addCImgui(b, target, optimize, .{
        .window_backed = .GLFW{ .glfwIncludePath = "deps/zglfw/libs/include" },
        .gfxBackend = .OpenGL3,
    });

    exe.linkLibrary(cImgui_lib);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // const unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_unit_tests = b.addRunArtifact(unit_tests);

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_unit_tests.step);
}
