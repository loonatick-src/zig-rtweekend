const std = @import("std");
const vec3 = @import("vec3.zig");
const clamp_vec3 = @import("rtweekend.zig").clamp_vec3;
const scale = vec3.scale;
const Color = vec3.Color;

// clamp(comptime T: type, x: T, lo: T, hi: T) T {
pub fn write_color(comptime WriterType: type, out: WriterType, comptime T: type, pixel_color: Color(T), samples_per_pixel: i32) !void {
    const a: T = 1.0 / @intToFloat(T, samples_per_pixel);
    const scaled_color = scale(T, a, pixel_color);
    const clamped_color = clamp_vec3(T, scaled_color, 0, 0.999);
    const r = @floatToInt(i32, clamped_color[0] * 255.999);
    const g = @floatToInt(i32, clamped_color[1] * 255.999);
    const b = @floatToInt(i32, clamped_color[2] * 255.999);
    try out.print("{} {} {}\n", .{ r, g, b });
}
