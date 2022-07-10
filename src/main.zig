const std = @import("std");

const ArrayList = std.ArrayList;
const File = std.fs.File;
const BufferedWriter = std.io.BufferedWriter;
const inf = std.math.inf;

const vec3 = @import("vec3.zig");
const rtweekend = @import("rtweekend.zig");
const ray = @import("ray.zig");
const hittable = @import("hittable.zig");
const hittable_list = @import("hittable_list.zig");
const sphere = @import("sphere.zig");
const color = @import("color.zig");
const camera = @import("camera.zig");
const material = @import("material.zig");

const Camera = camera.Camera;
const write_color = color.write_color;
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
const Material = material.Material;
const Lambertian = material.Lambertian;
const Metal = material.Metal;

const unit_vector = vec3.unit_vector;
const scale = vec3.scale;
const buffer_size: usize = 4096;

const random_float = vec3.RandFloatFn(f32).random;
const random_in_hemisphere = vec3.RandVecFn(f32).random_in_hemisphere;

fn ray_color(comptime T: type, r: *Ray(T), world: *Hittable(T), depth: i32, rand: anytype) Color(T) {
    if (depth <= 0) {
        return Color(T){ 0, 0, 0 };
    }
    var rec: HitRecord(T) = undefined;
    if (world.hit(r.*, 0.001, inf(T), &rec)) {
        var scattered: Ray(T) = undefined;
        var attenuation: Color(T) = undefined;
        if (rec.mat_ptr.scatter(r, &rec, &attenuation, &scattered, rand)) {
            return scale(T, attenuation, ray_color(T, &scattered, world, depth - 1, rand));
        }
        const target: Point3(T) = rec.p + random_in_hemisphere(rec.normal, rand);
        var ri = Ray_init(T, rec.p, target - rec.p);
        const rc = ray_color(T, &ri, world, depth - 1, rand);
        return scale(T, @as(T, 0.5), rc);
    }
    return Color(T){ 0, 0, 0 };
}

pub fn main() anyerror!void {
    // Be writing the PPM file to stdout
    var stdout = std.io.getStdOut().writer();
    var buffer = std.io.BufferedWriter(buffer_size, @TypeOf(stdout)){ .unbuffered_writer = stdout };
    var bufout = buffer.writer();

    // image properties
    const aspect_ratio = @as(f32, 16.0 / 9.0);
    const image_width: i32 = 400;
    const image_height = @floatToInt(i32, @as(f32, image_width) / aspect_ratio);
    const samples_per_pixel: i32 = 100;

    // Camera
    const cam = Camera(f32).init();

    // Initialize the world along with its geometric entities
    // start with a general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    // initialize array list for storing `Hittable(T)` objects
    // TODO: Fix this error:
    // error: unable to evaluate constant expression
    //    var objects = ArrayList(*(Hittable(f32))).init(allocator);
    var objects = ArrayList(*(Hittable(f32))).init(allocator);
    defer objects.deinit();

    // construct world object using the hittables
    var world_hlist: HittableList(f32) = .{ .objects = objects };
    defer world_hlist.objects.deinit();

    const lamb_ground: Lambertian(f32) = .{ .albedo = Color(f32){ 0.8, 0.8, 0.0 } };
    const lamb_center: Lambertian(f32) = .{ .albedo = Color(f32){ 0.7, 0.3, 0.3 } };
    const metal_right: Metal(f32) = .{ .albedo = Color(f32){ 0.8, 0.6, 0.2 } };
    const metal_left: Metal(f32) = .{ .albedo = Color(f32){ 0.8, 0.8, 0.8 } };

    const mat_ground = Material.make(&lamb_ground);
    const mat_left = Material.make(&metal_left);
    const mat_center = Material.make(&lamb_center);
    const mat_right = Material.make(&metal_right);

    const ground_sphere: Sphere(f32) = .{
        .center = Point3(f32){ 0.0, -100.5, -1.0 },
        .radius = 100.0,
        .mat_ptr = &mat_ground,
    };
    const center_sphere: Sphere(f32) = .{
        .center = Point3(f32){ 0.0, 0.0, -1.0 },
        .radius = 0.5,
        .mat_ptr = &mat_center,
    };
    const left_sphere: Sphere(f32) = .{
        .center = Point3(f32){ -1.0, 0.0, -1.0 },
        .radius = 0.5,
        .mat_ptr = &mat_left,
    };
    const right_sphere: Sphere(f32) = .{
        .center = Point3(f32){ 1.0, 0.0, -1.0 },
        .radius = 0.5,
        .mat_ptr = &mat_right,
    };

    const ground_sphere_hittable = Hittable.make(&ground_sphere);
    const center_sphere_hittable = Hittable.make(&center_sphere);
    const left_sphere_hittable = Hittable.make(&left_sphere);
    const right_sphere_hittable = Hittable.make(&right_sphere);

    try world_hlist.add(&ground_sphere_hittable);
    try world_hlist.add(&center_sphere_hittable);
    try world_hlist.add(&left_sphere_hittable);
    try world_hlist.add(&right_sphere_hittable);

    // make a Hittable(f32) out of the HittableList(f32) object that is the world
    var world = Hittable(f32).make(&world_hlist);

    try bufout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    var j = image_height - 1;

    const dw = @as(f32, image_width - 1);
    const dh = @as(f32, image_height - 1);
    const max_depth: i32 = 50;
    while (j >= 0) : (j -= 1) {
        std.debug.print("{} out of {} lines remaining\n", .{ j + 1, image_height });
        var i: i32 = 0;
        while (i < image_width) : (i += 1) {
            var pixel_color = Color(f32){ 0, 0, 0 };
            var s: i32 = 0;
            while (s < samples_per_pixel) : (s += 1) {
                const u = (@intToFloat(f32, i) + random_float(rand)) / dw;
                const v = (@intToFloat(f32, j) + random_float(rand)) / dh;
                var r = cam.get_ray(u, v);
                pixel_color += ray_color(f32, &r, &world, max_depth, rand);
            }
            try write_color(@TypeOf(bufout), bufout, f32, pixel_color, samples_per_pixel);
        }
    }

    try buffer.flush();
}
