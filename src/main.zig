const std = @import("std");
const File = std.fs.File;
const ArrayList = std.ArrayList;
const BufferedWriter = std.io.BufferedWriter;
const inf = std.math.inf;

const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");
const hittable = @import("hittable.zig");
const hittable_list = @import("hittable_list.zig");
const sphere = @import("sphere.zig");

const Sphere = sphere.Sphere;
const Ray = ray.Ray;
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Vec3_init = vec3.Vec3_init;
const Color = vec3.Color;
const Color_init = vec3.Color_init;
const Point3_init = vec3.Point3_init;
const Ray_init = ray.Ray_init;
const dot = vec3.dot;
const length_squared = vec3.length_squared;
const HitRecord = hittable.HitRecord;
const Hittable = hittable.Hittable;
const HittableList = hittable_list.HittableList;
const HitParameters = hittable.HitParameters;

const unit_vector = vec3.unit_vector;
const scale = vec3.scale;
const buffer_size: usize = 4096;

fn write_color(comptime WriterType: type, out: WriterType, comptime T: type, color: Color(T)) !void {
    const s: T = 255.999;
    const pixel_color = scale(T, s, color);
    const red = @floatToInt(i32, pixel_color[0]);
    const green = @floatToInt(i32, pixel_color[1]);
    const blue = @floatToInt(i32, pixel_color[2]);
    try out.print("{} {} {}\n", .{ red, green, blue });
}

fn ray_color(comptime T: type, r: *Ray(T), world: *Hittable(T)) Color(T) {
    var rec: HitRecord(T) = undefined;
    var hit_parameters: HitParameters(T) = .{ .r = r.*, .t_min = 0, .t_max = inf(T), .hit_record = &rec };
    if (world.hit(&hit_parameters)) {
        return scale(T, @as(T, 0.5), rec.normal + Color(T){ 1, 1, 1 });
    }

    const unit_direction = unit_vector(T, r.dir);
    const t = 0.5 * (unit_direction[1] + 1.0);
    return scale(T, 1.0 - t, Color(T){ 1, 1, 1 }) + scale(T, t, Color(T){ 0.5, 0.7, 1.0 });
}

pub fn main() anyerror!void {
    var stdout = std.io.getStdOut().writer();
    // there are probably builtins for retrieving
    // comptime info from polymorphic types
    var buffer = std.io.BufferedWriter(buffer_size, @TypeOf(stdout)){ .unbuffered_writer = stdout };
    var bufout = buffer.writer();

    // image properties
    const aspect_ratio = @as(f32, 16.0 / 9.0);
    const image_width: i32 = 400;
    const image_height = @floatToInt(i32, @as(f32, image_width) / aspect_ratio);
    const dw = @as(f32, image_width - 1);
    const dh = @as(f32, image_height - 1);

    // World
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        // TODO: is this fine? Might be better things to do
        _ = gpa.deinit();
    }
    var objects = ArrayList(*(Hittable(f32))).init(allocator);
    defer objects.deinit();

    var world_hlist: HittableList(f32) = .{ .objects = objects };
    const small_sphere_allocd = try allocator.alloc(Sphere(f32), 1);
    const small_sphere_ptr = @ptrCast(*(Sphere(f32)), small_sphere_allocd);
    small_sphere_ptr.center = Point3(f32){ 0, 0, -1 };
    small_sphere_ptr.radius = @as(f32, 0.5);
    var small_sphere_hittable = Hittable(f32).make(small_sphere_ptr);
    try world_hlist.add(&small_sphere_hittable);
    const large_sphere_allocd = try allocator.alloc(Sphere(f32), 1);
    const large_sphere_ptr = @ptrCast(*(Sphere(f32)), large_sphere_allocd);
    large_sphere_ptr.center = Point3(f32){ 0, -100.5, -1 };
    large_sphere_ptr.radius = @as(f32, 100);
    var large_sphere_hittable = Hittable(f32).make(large_sphere_ptr);
    try world_hlist.add(&large_sphere_hittable);
    var world = Hittable(f32).make(&world_hlist);

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

    try bufout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var j = image_height - 1;
    while (j >= 0) : (j -= 1) {
        std.debug.print("{} out of {} lines remaining\n", .{ j + 1, image_height });
        var i: i32 = 0;
        while (i < image_width) : (i += 1) {
            const u = @intToFloat(f32, i) / dw;
            const v = @intToFloat(f32, j) / dh;
            var r: Ray(f32) = .{ .orig = origin, .dir = lower_left_corner + scale(f32, u, horizontal) + scale(f32, v, vertical) - origin };
            const pixel_color = ray_color(f32, &r, &world);
            try write_color(@TypeOf(bufout), bufout, f32, pixel_color);
        }
    }

    try buffer.flush();
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
