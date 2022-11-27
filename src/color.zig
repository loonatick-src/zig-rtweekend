const std = @import("std");
const vec3 = @import("vec3.zig");
const scale = vec3.scale;
const Color = vec3.Color;

const clamp = @import("rtweekend.zig").clamp;

// clamp(comptime T: type, x: T, lo: T, hi: T) T {

fn pgm_scale(c: f32) i32 {
    return @floatToInt(i32, 256 * clamp(f32, c, 0.0, 0.999));
}

pub fn write_color(comptime WriterType: type, out: WriterType, pixel_color: Color, samples_per_pixel: i32) !void {
    var rf = pixel_color[0];
    var gf = pixel_color[1];
    var bf = pixel_color[2];

    const s = 1.0 / @intToFloat(f32, samples_per_pixel);
    rf = @sqrt(s * rf);
    gf = @sqrt(s * gf);
    bf = @sqrt(s * bf);

    const r = pgm_scale(rf);
    const g = pgm_scale(gf);
    const b = pgm_scale(bf);

    try out.print("{} {} {}\n", .{ r, g, b });
}
