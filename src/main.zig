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
const at = ray.at;
const length_squared = vec3.length_squared;

const unit_vector = vec3.unit_vector;
const scale = vec3.scale;

// TODO: Ray struct is not generic
fn ray_color(comptime T: type, r: Ray(T)) Color(T) {
    // TOOD: see if better quadratic formula should be used
    var t = hit_sphere(T, Point3_init(T, 0, 0, -1), 0.5, r);

    if (t > 0.0) {
        // sphere was hit
        // calculate normal vector at point of contact
        const N = unit_vector(T, at(T, t, r) - Vec3_init(T, 0, 0, -1));
        // calculate color from normal vector
        return scale(T, 0.5, Color_init(T, N[0] + 1, N[1] + 1, N[2] + 1));
    }

    const unit_direction = unit_vector(T, r.dir);
    const one = @as(T, 1.0);
    // t = 0.5 * (unit_direction.y() + 1.0);
    t = @as(T, 0.5) * (unit_direction[1] + one);

    const white = Color_init(T, one, one, one);
    const gray = scale(T, 1.0 - t, white);
    var blue = Color_init(T, 0.5, 0.7, 1.0);
    blue = scale(T, t, blue);
    return gray + blue;
}

fn hit_sphere(comptime T: type, center: Point3(T), radius: T, r: Ray(T)) T {
    const oc = r.orig - center;
    const a = length_squared(T, r.dir);
    const half_b = dot(T, oc, r.dir);
    const c = length_squared(T, oc) - radius * radius;
    const discriminant = half_b * half_b - a * c;
    if (discriminant < 0) {
        return -1.0;
    } else {
        return (-half_b - @sqrt(discriminant)) / a;
    }
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
            // r = Ray(f32) { .orig = origin, .dir = lower_left_corner + u*horizontal + v*vertical - origin };
            const r = Ray_init(f32, origin, lower_left_corner + scale(f32, u, horizontal) + scale(f32, v, vertical) - origin);
            const pixel_color = ray_color(f32, r);
            const s: f32 = 255.999;
            const red = @floatToInt(i32, s * pixel_color[0]);
            const green = @floatToInt(i32, s * pixel_color[1]);
            const blue = @floatToInt(i32, s * pixel_color[2]);
            try stdout.print("{} {} {}\n", .{ red, green, blue });
        }
    }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
