const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const c = @import("c.zig");

const log = std.log;

const WIDTH = 1280;
const HEIGHT = 720;

pub fn main() !void {
    if (!glfw.init(.{})) {
        log.err("Failed to initialize GLFW!", .{});
        return error.FailedToInitializeGLFW;
    }
    defer glfw.terminate();

    var window = glfw.Window.create(WIDTH, HEIGHT, "ImGui Window", null, null, .{
        // General Settings
        .resizable = false,

        // Use OpenGL 3.2
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 3,
        .context_version_minor = 2,
    }) orelse {
        log.err("Failed to create window", .{});
        return;
    };
    defer window.destroy();

    const vidMode = glfw.Monitor.getVideoMode(glfw.Monitor.getPrimary().?).?;
    window.setPos(.{ .x = (vidMode.getWidth() - WIDTH) / 2, .y = (vidMode.getHeight() - HEIGHT) / 2 });

    glfw.swapInterval(1); // Vsync
    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    const glslVersion = "#version 150";
    _ = c.igCreateContext(null);
    defer c.igDestroyContext(null);

    var ioPtr: *c.ImGuiIO = c.igGetIO();
    ioPtr.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard;
    ioPtr.ConfigFlags |= c.ImGuiConfigFlags_DockingEnable;

    _ = c.ImGui_ImplGlfw_InitForOpenGL(@ptrCast(*c.GLFWwindow, window.handle), true);
    defer c.ImGui_ImplGlfw_Shutdown();
    _ = c.ImGui_ImplOpenGL3_Init(glslVersion);
    defer c.ImGui_ImplOpenGL3_Shutdown();

    _ = c.igStyleColorsDark(null);

    while (!window.shouldClose()) {
        c.ImGui_ImplOpenGL3_NewFrame();
        c.ImGui_ImplGlfw_NewFrame();
        c.igNewFrame();

        _ = c.igBegin("Test", null, 0);

        c.igText("Hello, world!");

        c.igEnd();

        c.igEndFrame();

        glfw.pollEvents();

        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        gl.clearColor(1.0, 0.5, 0.5, 1.0);
        c.igRender();
        c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());

        window.swapBuffers();
    }
}

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}
