const std = @import("std");
const vec3 = @import("vec3.zig");
const hittable = @import("hittable.zig");
const ray = @import("ray.zig");

const Ray = ray.Ray;
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point;
const Hittable = hittable.Hittable;
const HitParameters = hittable.HitParameters;
const HitRecord = hittable.HitRecord;

// TODO: the rest of the owl
pub fn HittableList(comptime T: type) type {
    return struct {
        // the original code uses shared pointers,
        // but the objects are all const, so we don't
        // need atomic refcounting. Also we are confident in our ability
        // to manage memory manually in such a simple application.
        objects: std.ArrayList(*(Hittable(T))),

        pub fn hit(self: *@This(), r: Ray(T), t_min: T, t_max: T, rec: *HitRecord(T)) bool {
            var temp_rec: HitRecord(T) = rec.*; // copy values instead of undefined
            var hit_anything = false;
            var closest_so_far = t_max;

            for (self.objects.items) |*object| {
                if (object.*.hit(r, t_min, closest_so_far, &temp_rec)) {
                    hit_anything = true;
                    closest_so_far = temp_rec.t;
                    // error: cannot assign to constant
                    rec.* = temp_rec;
                }
            }
            return hit_anything;
        }

        pub fn add(self: *@This(), obj: *(Hittable(T))) !void {
            try self.objects.append(obj);
        }
    };
}
