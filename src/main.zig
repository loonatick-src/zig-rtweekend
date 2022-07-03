const std = @import("std");
const Type = std.builtin.Type;
const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");

// how does a guy export, yea?
const Ray = ray.Ray;
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Vec3_init = vec3.Vec3_init;
const Color = vec3.Color;
const Color_init = vec3.Color_init;
const Point3_init = vec3.Point3_init;
const Ray_init = ray.Ray_init;
const dot = vec3.dot;

const unit_vector = vec3.unit_vector;
const scale = vec3.scale;

// TODO: Ray struct is not generic
fn ray_color(comptime T: type, r: Ray(T)) Color(T) {
    if (hit_sphere(T, Point3_init(T, 0, 0, -1), 0.5, r)) {
        return Color_init(T, 1, 0, 0);
    }
    const unit_direction = unit_vector(T, r.dir);
    const one = @as(T, 1.0);
    const t = @as(T, 0.5) * (unit_direction[1] + one);
    const grayscale_component = scale(T, t, Color_init(T, one, one, one));
    const color_component = scale(T, one - t, Color_init(T, 0.5, 0.7, 1.0));
    return grayscale_component + color_component;
}

fn hit_sphere(comptime T: type, center: Point3(T), radius: T, r: Ray(T)) bool {
    const oc = r.orig - center;
    const a = dot(T, r.dir, r.dir);
    const b = 2.0 * dot(T, oc, r.dir);
    const c = dot(T, oc, oc) - radius * radius;
    const discriminant = b * b - 4 * a * c;
    return (discriminant > 0);
}

pub fn main() anyerror!void {
    // TODO: add buffering
    const stdout = std.io.getStdOut().writer();

    // image properties
    const aspect_ratio = @as(f32, 16.0 / 9.0);
    const image_width: i32 = 400;
    const image_height = @floatToInt(i32, @as(f32, image_width) / aspect_ratio);
    const dw = @as(f32, image_width - 1);
    const dh = @as(f32, image_height - 1);

    // viewport config
    const viewport_height: f32 = 2.0;
    const viewport_width = aspect_ratio * viewport_height;
    const focal_length: f32 = 1.0;

    // orient ourselves with respect to the viewport
    const origin = Point3_init(f32, 0, 0, 0);
    const horizontal = Vec3_init(f32, viewport_width, 0, 0);
    const vertical = Vec3_init(f32, 0, viewport_height, 0);
    const horizontal_midpoint = scale(f32, 0.5, horizontal);
    const vertical_midpoint = scale(f32, 0.5, vertical);
    const lower_left_corner = origin - horizontal_midpoint - vertical_midpoint - Vec3_init(f32, 0, 0, focal_length);

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var j = image_height - 1;
    while (j >= 0) : (j -= 1) {
        var i: i32 = 0;
        while (i < image_width) : (i += 1) {
            const u = @intToFloat(f32, i) / dw;
            const v = @intToFloat(f32, j) / dh;
            const r = Ray_init(f32, origin, lower_left_corner + scale(f32, u, horizontal) + scale(f32, v, vertical) - origin);
            const pixel_color = ray_color(f32, r);
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
