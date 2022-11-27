const std = @import("std");
const ray = @import("ray.zig");
const vec3 = @import("vec3.zig");
const inf = std.math.inf;

const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;
const Ray = ray.Ray;

// Ladies and gentlemen, runtime polymorphism. Check out the following lovely showtime
// https://www.youtube.com/watch?v=AHc4x1uXBQE&t=2126s
// With my understanding of Zig at the time of working on this project, I
// highly doubt I could have come up with this on my own.
// Kind of excited about the future of comptime

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    t: f32,
    front_face: bool,

    pub fn set_face_normal(self: *@This(), r: Ray, outward_normal: Vec3) void {
        const front_face = dot(r.dir, outward_normal) < 0;
        self.normal = outward_normal;
        if (!front_face) {
            self.normal = (Vec3{ 0, 0, 0 }) - outward_normal;
        }
    }
};

pub const Hittable = struct {
    const VTable = struct { hit: fn (usize, r: Ray, t_min: f32, t_max: f32, rec: *HitRecord) bool };
    vtable: *const VTable,
    object: usize,

    pub fn hit(self: @This(), r: Ray, t_min: f32, t_max: f32, rec: *HitRecord) bool {
        return self.vtable.hit(self.object, r, t_min, t_max, rec);
    }

    pub fn make(obj: anytype) @This() {
        const PtrType = @TypeOf(obj);
        return .{
            .vtable = &comptime VTable{
                .hit = struct {
                    pub fn hit(ptr: usize, r: Ray, t_min: f32, t_max: f32, rec: *HitRecord) bool {
                        const self = @intToPtr(PtrType, ptr);
                        return @call(.{ .modifier = .always_inline }, std.meta.Child(PtrType).hit, .{ self, r, t_min, t_max, rec });
                    } // fn hit
                }.hit, // .hit
            }, // .vtable
            .object = @ptrToInt(obj),
        };
    } // fn make
};
