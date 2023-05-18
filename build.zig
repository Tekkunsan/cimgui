const std = @import("std");

pub fn addCImgui(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const flags = if (target.getOsTag() == .windows) &[_][]const u8{
        "-std=c++11",
        "-D_GNU_SOURCE",
        // "-DCIMGUI_DEFINE_ENUMS_AND_STRUCTS",
        "-DIMGUI_IMPL_API=extern \"C\" __declspec(dllexport)",
        "-fno-sanitize=undefined",
    } else &[_][]const u8{
        "-std=c++11",
        "-D_GNU_SOURCE",
        // "-DCIMGUI_DEFINE_ENUMS_AND_STRUCTS",
        "-DIMGUI_IMPL_API=extern \"C\"",
        "-fno-sanitize=undefined",
    };

    const cImgui = b.addStaticLibrary(.{
        .name = "cimgui",
        .target = target,
        .optimize = optimize,
    });
    cImgui.linkLibCpp();
    addCimguiHeader(cImgui);

    // I'll Assume that we'll be using glfw and opengl
    cImgui.addCSourceFiles(&.{
        srcdir ++ "/cimgui.cpp",
        srcdir ++ "/imgui/imgui.cpp",
        srcdir ++ "/imgui/imgui_draw.cpp",
        srcdir ++ "/imgui/imgui_demo.cpp",
        srcdir ++ "/imgui/imgui_widgets.cpp",
        srcdir ++ "/imgui/imgui_tables.cpp",
        // If you want another backend change this line
        srcdir ++ "/imgui/backends/imgui_impl_glfw.cpp",
        srcdir ++ "/imgui/backends/imgui_impl_opengl3.cpp",
    }, flags);

    return cImgui;
}

pub fn addCimguiHeader(exe: *std.Build.Step.Compile) void {
    exe.addIncludePath(srcdir);
}

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = addCImgui(b, target, optimize);
    lib.installHeader(srcdir ++ "/cimgui.h", "cimgui.h");
    b.installArtifact(lib);
}

const srcdir = struct {
    fn getSrcDir() []const u8 {
        return std.fs.path.dirname(@src().file).?;
    }
}.getSrcDir();
