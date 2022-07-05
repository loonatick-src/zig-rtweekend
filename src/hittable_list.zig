const std = @import("std");
const vec3 = @import("vec3.zig");
const hittable = @import("hittable.zig");

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

        pub fn hit(self: *@This(), hit_parameters: *HitParameters) bool {
            var temp_rec: HitRecord = *(hit_parameters.hit_record);
            var temp_hit_params = *hit_parameters;
            temp_hit_params.hit_record = &temp_rec;
            var hit_anything = false;
            var closest_so_far = hit_parameters.t_max;

            for (self.objects) |*object| {
                if (object.*.hit(&temp_hit_params)) {
                    hit_anything = true;
                    closest_so_far = temp_hit_params.hit_record.t;
                    hit_parameters.hit_record = temp_hit_params.hit_record;
                }
            }

            return hit_anything;
        }
    };
}
