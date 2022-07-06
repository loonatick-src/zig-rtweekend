const std = @import("std");
const ray = @import("ray.zig");
const vec3 = @import("vec3.zig");
const inf = std.math.inf;

const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;
const Ray = ray.Ray;

// Gentlemen, runtime polymorphism, check out the following lovely showtime
// https://www.youtube.com/watch?v=AHc4x1uXBQE&t=2126s
// With my understanding of Zig at the time of working on this project, I
// highly doubt I could have come up with this on my own.
// Kind of excited about the future of comptime

pub fn HitRecord(comptime T: type) type {
    return struct {
        p: Point3(T),
        normal: Vec3(T),
        t: T,
        front_face: bool,

        pub fn set_face_normal(self: *@This(), r: Ray(T), outward_normal: Vec3(T)) void {
            const front_face = dot(T, r.dir, outward_normal) < 0;
            self.normal = outward_normal;
            if (!front_face) {
                self.normal = (Vec3(T){ 0, 0, 0 }) - outward_normal;
            }
        }
    };
}

// decided to package the paramters in a struct because if I recall correctly
// some hit functions in the original code do not use all parameters,
// which is not allowed in Zig.
pub fn HitParameters(comptime T: type) type {
    return struct {
        r: Ray(T),
        // TODO: consider changing default value to slightly negative
        t_min: T = @as(T, 0),
        t_max: T,
        hit_record: *(HitRecord(T)),
    };
}

pub fn Hittable(comptime T: type) type {
    return struct {
        const VTable = struct { hit: fn (usize, *HitParameters(T)) bool };
        vtable: *const VTable,
        object: usize,

        pub fn hit(self: @This(), hit_parameters: *HitParameters(T)) bool {
            return self.vtable.hit(self.object, hit_parameters);
        }

        pub fn make(obj: anytype) @This() {
            const PtrType = @TypeOf(obj);
            return .{
                .vtable = &comptime VTable{
                    .hit = struct {
                        pub fn hit(ptr: usize, hit_parameters: *(HitParameters(T))) bool {
                            const self = @intToPtr(PtrType, ptr);
                            return @call(.{ .modifier = .always_inline }, std.meta.Child(PtrType).hit, .{ self, hit_parameters });
                        } // fn hit
                    }.hit, // .hit
                }, // .vtable
                .object = @ptrToInt(obj),
            };
        } // fn make
    };
}
