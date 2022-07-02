const std = @import("std");
const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");

// how does a guy export, yea?
const Ray = ray.Ray;
const Vec3 = vec3.Vec3;
const Vec3_init = vec3.Vec3_init;
const Color = vec3.Color;
const Color_init = vec3.Color_init;
const Point3_init = vec3.Point3_init;

const unit_vector = vec3.unit_vector;
const scale = vec3.scale;

// TODO: Ray struct is not generic
fn ray_color(r: Ray) Color(f32) {
    const unit_direction = unit_vector(f32, r.dir);
    const one = @as(f32, 1.0);
    const t = @as(f32, 0.5) * (unit_direction[1] + one);
    const grayscale_component = scale(f32, t, Color_init(f32, one, one, one));
    const color_component = scale(f32, one - t, Color_init(f32, 0.5, 0.7, 1.0));
    return grayscale_component + color_component;
}

pub fn main() anyerror!void {
    // TODO: add buffering
    const stdout = std.io.getStdOut().writer();

    const aspect_ratio = @as(f32, 16.0 / 9.0);
    const image_width: i32 = 400;
    const image_height = @floatToInt(i32, @as(f32, image_width) / aspect_ratio);
    const dw = @as(f32, image_width - 1);
    const dh = @as(f32, image_height - 1);

    const viewport_height: f32 = 2.0;
    const viewport_width = aspect_ratio * viewport_height;
    const focal_length: f32 = 1.0;

    const origin = Point3_init(f32, 0, 0, 0);
    const horizontal = Vec3_init(f32, viewport_width, 0, 0);
    const vertical = Vec3_init(f32, 0, viewport_height, 0);
    const horizontal_midpoint = scale(f32, 0.5, horizontal);
    const vertical_midpoint = scale(f32, 0.5, horizontal);
    const lower_left_corner = origin - horizontal_midpoint - vertical_midpoint - Vec3_init(f32, 0, 0, focal_length);

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var j = image_height - 1;
    while (j >= 0) : (j -= 1) {
        var i: i32 = 0;
        while (i < image_width) : (i += 1) {
            const u = @intToFloat(f32, i) / dw;
            const v = @intToFloat(f32, j) / dh;
            const r = Ray{
                .orig = origin,
                .dir = lower_left_corner + scale(@TypeOf(u), u, horizontal) + scale(@TypeOf(v), v, vertical) - origin,
            };
            const pixel_color = ray_color(r);
            const scaling_factor: f32 = 255.999;
            const red = @floatToInt(i32, scaling_factor * pixel_color[0]);
            const green = @floatToInt(i32, scaling_factor * pixel_color[1]);
            const blue = @floatToInt(i32, scaling_factor * pixel_color[2]);
            try stdout.print("{} {} {}\n", .{ red, green, blue });
        }
    }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
