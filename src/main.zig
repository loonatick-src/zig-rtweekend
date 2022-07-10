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

const unit_vector = vec3.unit_vector;
const scale = vec3.scale;
const buffer_size: usize = 4096;

const random_float = vec3.RandFloatFn(f32).random;

fn ray_color(comptime T: type, r: *Ray(T), world: *Hittable(T)) Color(T) {
    var rec: HitRecord(T) = undefined;
    if (world.hit(r.*, 0, inf(T), &rec)) {
        return scale(T, @as(T, 0.5), rec.normal + Color(T){ 1, 1, 1 });
    }

    const unit_direction = unit_vector(T, r.dir);
    const t = 0.5 * (unit_direction[1] + 1.0);
    const gray = scale(T, 1.0 - t, Color(T){ 1.0, 1.0, 1.0 });
    const blue = scale(T, t, Color(T){ 0.5, 0.7, 1.0 });
    const final_color = gray + blue;
    return final_color;
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
    const allocator = gpa.allocator();

    // initialize array list for storing `Hittable(T)` objects
    var objects = ArrayList(*(Hittable(f32))).init(allocator);
    defer objects.deinit();

    // construct world object using the hittables
    var world_hlist: HittableList(f32) = .{ .objects = objects };
    defer world_hlist.objects.deinit();

    // the world has two spheres, a small one and a large one
    // Initialize the small sphere first
    // const small_sphere_allocd = try allocator.alloc(Sphere(f32), 1);
    // defer allocator.free(small_sphere_allocd);

    // Initialize and add the sphere to the array_list of objects in the world
    // const small_sphere_ptr = @ptrCast(*(Sphere(f32)), small_sphere_allocd);
    // TODO: create an init function
    // small_sphere_ptr.center = Point3(f32){ 0, 0, -1 };
    // small_sphere_ptr.radius = @as(f32, 0.5);
    var small_sphere: Sphere(f32) = .{
        .center = Point3(f32){ 0, 0, -1 },
        .radius = @as(f32, 0.5),
    };
    var small_sphere_hittable = Hittable(f32).make(&small_sphere);
    try world_hlist.add(&small_sphere_hittable);

    // same for the larger sphere
    // const large_sphere_allocd = try allocator.alloc(Sphere(f32), 1);
    // defer allocator.free(large_sphere_allocd);
    // const large_sphere_ptr = @ptrCast(*(Sphere(f32)), large_sphere_allocd);
    // large_sphere_ptr.center = Point3(f32){ 0, -100.5, -1 };
    // large_sphere_ptr.radius = @as(f32, 100);
    var large_sphere: Sphere(f32) = .{
        .center = Point3(f32){ 0, -100.5, -1 },
        .radius = @as(f32, 100),
    };
    var large_sphere_hittable = Hittable(f32).make(&large_sphere);
    try world_hlist.add(&large_sphere_hittable);

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
                pixel_color += ray_color(f32, &r, &world);
            }
            try write_color(@TypeOf(bufout), bufout, f32, pixel_color, samples_per_pixel);
        }
    }

    try buffer.flush();
}
