const std = @import("std");

pub const Backend = union(enum) {
    OpenGL3,
    OpenGL2,
    Vulkan,
    Metal,
    Android,
    Allegro5,
    DirectX9,
    DirectX10,
    DirectX11,
    DirectX12,
    GLUT,
    GLFW: struct { glfwIncludePath: []const u8 },
    SDL2: struct { sdl2IncludePath: []const u8 },
};

pub fn addCImgui(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode, backend: struct { windowBackend: ?Backend, gfxBackend: ?Backend }) *std.Build.Step.Compile {
    const flags = if (target.getOsTag() == .windows) &[_][]const u8{
        "-std=c++11",
        "-D_GNU_SOURCE",
        "-DIMGUI_IMPL_API=extern \"C\" __declspec(dllexport)",
        "-fno-sanitize=undefined",
    } else &[_][]const u8{
        "-std=c++11",
        "-D_GNU_SOURCE",
        "-DIMGUI_IMPL_API=extern \"C\"",
        "-fno-sanitize=undefined",
    };

    const cImgui = b.addStaticLibrary(.{
        .name = "cimgui",
        .target = target,
        .optimize = optimize,
    });
    cImgui.linkLibCpp();
    cImgui.addIncludePath(srcdir ++ "/imgui");

    cImgui.addCSourceFiles(&.{
        srcdir ++ "/cimgui.cpp",
        srcdir ++ "/imgui/imgui.cpp",
        srcdir ++ "/imgui/imgui_draw.cpp",
        srcdir ++ "/imgui/imgui_demo.cpp",
        srcdir ++ "/imgui/imgui_widgets.cpp",
        srcdir ++ "/imgui/imgui_tables.cpp",
    }, flags);

    if (backend.windowBackend) |winBackend| {
        if (winBackend == .GLFW) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_glfw.cpp", flags);
            cImgui.addIncludePath(winBackend.GLFW.glfwIncludePath);
        } else if (winBackend == .SDL2) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_sdl2.cpp", flags);
            cImgui.addIncludePath(winBackend.SDL2.sdl2IncludePath);
        }
    }

    if (backend.gfxBackend) |gfxBackend| {
        if (gfxBackend == .OpenGL3) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_opengl3.cpp", flags);
        } else if (gfxBackend == .OpenGL2) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_opengl2.cpp", flags);
        } else if (gfxBackend == .Vulkan) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_vulkan.cpp", flags);
        } else if (gfxBackend == .Metal) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_metal.mm", flags);
        } else if (gfxBackend == .Android) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_android.cpp", flags);
        } else if (gfxBackend == .Allegro5) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_allegro5.cpp", flags);
        } else if (gfxBackend == .DirectX9) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_dx9.cpp", flags);
        } else if (gfxBackend == .DirectX10) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_dx10.cpp", flags);
        } else if (gfxBackend == .DirectX11) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_dx11.cpp", flags);
        } else if (gfxBackend == .DirectX12) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_dx12.cpp", flags);
        } else if (gfxBackend == .GLUT) {
            cImgui.addCSourceFile(srcdir ++ "/imgui/backends/imgui_impl_glut.cpp", flags);
        }
    }

    return cImgui;
}

pub fn addCimguiHeader(exe: *std.Build.Step.Compile) void {
    exe.addIncludePath(srcdir);
}

pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = addCImgui(b, target, optimize, .{
        .windowBackend = null,
        .gfxBackend = null,
    });
    lib.installHeader(srcdir ++ "/cimgui.h", "cimgui.h");
    lib.installHeader(srcdir ++ "/cimgui_impl.h", "cimgui_impl.h");
    b.installArtifact(lib);

    try addExamples(b, target, optimize);
}

fn addExamples(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) !void {
    const zgl = b.createModule(.{
        .source_file = .{ .path = "examples/deps/zgl.zig" },
    });

    var run_example_glfw = b.step("run_example_glfw", "Run the GLFW Example");

    var glfw_example = b.addExecutable(.{
        .name = "example_glfw",
        .root_source_file = .{ .path = "examples/glfw_opengl3/src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    glfw_example.addModule("gl", zgl);

    const glfw = @import("examples/deps/mach-glfw/build.zig");
    glfw_example.addModule("glfw", glfw.module(b));
    try glfw.link(b, glfw_example, .{});

    const cImgui_lib = addCImgui(b, target, optimize, .{
        .windowBackend = .{ .GLFW = .{ .glfwIncludePath = "examples/deps/mach-glfw/upstream/glfw/include" } },
        .gfxBackend = .OpenGL3,
    });
    addCimguiHeader(glfw_example);

    // std.build.FileSource

    glfw_example.linkLibrary(cImgui_lib);

    const run_cmd = b.addRunArtifact(glfw_example);
    b.installArtifact(glfw_example);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    run_example_glfw.dependOn(&run_cmd.step);
}

const srcdir = struct {
    fn getSrcDir() []const u8 {
        return std.fs.path.dirname(@src().file).?;
    }
}.getSrcDir();
