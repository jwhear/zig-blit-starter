const std = @import("std");
usingnamespace @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    _ = glfwSetErrorCallback(errorCallback);

    if (glfwInit() != GL_TRUE) {
        return error.glfw_init_failed;
    }
    defer glfwTerminate();

    var windowW: u32 = 400;
    var windowH: u32 = 300;
    var window = glfwCreateWindow(@intCast(c_int, windowW),
                                  @intCast(c_int, windowH),
                                  "Raycaster", null, null);
    if (window == null) {
        return error.create_window_failed;
    }

    glfwMakeContextCurrent(window);
    glClearColor(0.1, 0.1, 0.1, 1.0);

    var mainAllocator = std.heap.c_allocator;

    var bXOR = try Bitmap.init(mainAllocator, windowW, windowH);
    var y : u32 = 0;
    while (y < bXOR.height) : (y += 1) {
        var x : u32 = 0;
        while (x < bXOR.width) : (x += 1) {
            const lum = @truncate(u8, x ^ y);
            bXOR.set(x, y, Color.gray(lum));
        }
    }

    while (glfwWindowShouldClose(window) == GL_FALSE) {
        glClear(GL_COLOR_BUFFER_BIT);

        // Draw here
        glDrawPixels(@intCast(c_int, bXOR.width),
                     @intCast(c_int, bXOR.height),
                     GL_RGBA, GL_UNSIGNED_BYTE,
                     bXOR.data.ptr);

        glfwSwapBuffers(window);

        glfwPollEvents();
    }
}

export fn errorCallback(err: c_int, description: [*c]const u8) void {
    _ = err;
    std.debug.panic("Error: {s}\n", .{description});
}

const Color = packed struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 255,

    pub fn gray(value: u8) Color {
        return .{.r = value, .g = value, .b = value};
    }
};

const Red = Color{.r=255};
const Green = Color{.g=255};
const Blue = Color{.b=255};
const DebugColor = Color{.r=255, .b=255};

const Bitmap = struct {
    width: u32,
    height: u32,
    data: []Color,

    pub fn init(allocator: *std.mem.Allocator, w: u32, h: u32) !Bitmap {
        var data = try allocator.alloc(Color, w * h);
        std.mem.set(Color, data, DebugColor);
        return Bitmap{
            .width = w,
            .height = h,
            .data = data,
        };
    }

    pub fn set(self: *Bitmap, x: u32, y: u32, color: Color) void {
        //self.index(x,y).* = color;
        self.data[y*self.width+x] = color;
    }

    pub fn get(self: *const Bitmap, x: u32, y: u32) Color {
        return self.index(x, y).*;
    }

    fn index(self: *const Bitmap, x: u32, y: u32) *Color {
        std.debug.assert(x < self.width);
        std.debug.assert(y < self.height);
        const i = y * self.width + x;
        std.debug.assert(i < self.data.len);
        return &self.data[i];
    }
};

const Texture = struct {
    handle: GLuint,

    pub fn init() Texture {
        var ret = Texture{ .handle = undefined };
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &ret.handle);
        return ret;
    }

    pub fn setBitmap(self: *Texture, b: Bitmap) void {
        glBindTexture(GL_TEXTURE_2D, self.handle);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
                     @intCast(c_int, b.width),
                     @intCast(c_int, b.height), 0, GL_RGBA,
                     GL_UNSIGNED_BYTE, b.data.ptr);
    }
};
