const std = @import("std");
const rand = std.rand;

const ArrayList = std.ArrayList;
const File = std.fs.File;
const BufferedWriter = std.io.BufferedWriter;
const inf = std.math.inf;

const vec3 = @import("vec3.zig");
const rtweekend = @import("rtweekend.zig");
const ray = @import("ray.zig");
const hittable = @import("hittable.zig");
const hittable_list = @import("hittable_list.zig");
const material = @import("material.zig");
const sphere = @import("sphere.zig");
const color = @import("color.zig");
const camera = @import("camera.zig");

const Camera = camera.Camera;
const write_color = color.write_color;
const Sphere = sphere.Sphere;
const Ray = ray.Ray;
const Vec3 = vec3.Vec3(f32);
const Point3 = vec3.Point3;
const Color = vec3.Color;
const dot = vec3.dot;
const length_squared = vec3.length_squared;
const HitRecord = hittable.HitRecord;
const Hittable = hittable.Hittable;
const HittableList = hittable_list.HittableList;
const HitParameters = hittable.HitParameters;
const Material = material.Material;

const unit_vector = vec3.unit_vector;
const scale = vec3.scale;
const buffer_size: usize = 4096;

fn ray_color(r: *Ray, world: *Hittable, depth: i32, rng: rand.Random) Color {
    if (depth <= 0) {
        return Color{ 0, 0, 0 };
    }
    var rec: HitRecord = undefined;
    if (world.hit(r.*, 0.001, inf(f32), &rec)) {
        var scattered: Ray = undefined;
        var attenuation: Color = undefined;
        if (rec.mat_ptr.scatter(r, rec, attenuation, scattered, rng)) {
            return scale(attenuation, ray_color(scattered, world, depth - 1, rng));
        }
        return Color{ 0, 0, 0 };
    }

    const unit_direction = unit_vector(r.dir);
    const t = 0.5 * (unit_direction[1] + 1.0);
    const gray = scale(1.0 - t, Color{ 1.0, 1.0, 1.0 });
    const blue = scale(t, Color{ 0.5, 0.7, 1.0 });
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
    const cam = Camera.init();

    // Initialize the world along with its geometric entities
    // start with a general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // initialize array list for storing `Hittable(T)` objects
    var objects = ArrayList(*Hittable).init(allocator);
    defer objects.deinit();

    // construct world object using the hittables
    var world_hlist: HittableList = .{ .objects = objects };
    defer world_hlist.objects.deinit();

    // the world has two spheres, a small one and a large one
    // Initialize the small sphere first

    // Initialize and add the sphere to the array_list of objects in the world
    // const small_sphere_ptr = @ptrCast(*(Sphere), small_sphere_allocd);
    // TODO: create an init function
    // small_sphere_ptr.center = Point3{ 0, 0, -1 };
    // small_sphere_ptr.radius = @as(f32, 0.5);
    const ground_lambert = material.Lambertian{ .albedo = Color{ 0.8, 0.8, 0.0 } };
    const center_lambert = material.Lambertian{ .albedo = Color{ 0.7, 0.3, 0.3 } };
    const left_metal = material.Metal{ .albedo = Color{ 0.8, 0.8, 0.8 } };
    const right_metal = material.Metal{ .albedo = Color{ 0.8, 0.6, 0.2 } };

    const ground_mat = ground_lambert.material();
    const center_mat = ground_lambert.material();
    const left_mat = left_metal.material();
    const right_mat = right_metal.material();

    const ground_sphere = Sphere{ .center = Point3{ 0.0, -100.5, -1.0 }, .radius = 100.0, .mat_ptr = &ground_mat };
    // TODO: correct the coords and dimensions of the following three spheres
    const center_sphere = Sphere{ .center = Point3{ 0.0, 0.0, 0.0 }, .radius = 1.0, .mat_ptr = &center_mat };
    const left_sphere = Sphere{ .center = Point3{ 0.0, 0.0, 0.0 }, .radius = 1.0, .mat_ptr = &left_mat };
    const right_sphere = Sphere{ .center = Point3{ 0.0, 0.0, 0.0 }, .radius = 1.0, .mat_ptr = &right_mat };

    const ground_sphere_hittable = ground_sphere.hittable();
    world_hlist.add(ground_sphere_hittable);
    var large_sphere: Sphere = .{
        .center = Point3{ 0, -100.5, -1 },
        .radius = @as(f32, 100),
    };

    world_hlist.add(center_sphere_hittable);
    world_hlist.add(left_sphere_hittable);
    world_hlist.add(right_sphere_hittbable);

    // TODO: the rest of the spheres
    // make a Hittable out of the HittableList object that is the world
    var world = world_hlist.hittable();

    try bufout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    const seed: u64 = 0xc0ffee;
    const rng = rand.DefaultPrng.init(seed).random();
    var j = image_height - 1;

    const dw = @as(f32, image_width - 1);
    const dh = @as(f32, image_height - 1);
    const max_depth: i32 = 50;
    while (j >= 0) : (j -= 1) {
        std.debug.print("{} out of {} lines remaining\n", .{ j + 1, image_height });
        var i: i32 = 0;
        while (i < image_width) : (i += 1) {
            var pixel_color = Color{ 0, 0, 0 };
            var s: i32 = 0;
            while (s < samples_per_pixel) : (s += 1) {
                const u = (@intToFloat(f32, i) + vec3.random(rng)) / dw;
                const v = (@intToFloat(f32, j) + vec3.random(rng)) / dh;
                var r = cam.get_ray(u, v);
                pixel_color += ray_color(&r, &world, max_depth, rand);
            }
            try write_color(@TypeOf(bufout), bufout, pixel_color, samples_per_pixel);
        }
    }

    try buffer.flush();
}
