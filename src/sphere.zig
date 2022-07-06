const std = @import("std");
const hittable = @import("hittable.zig");
const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");
const scale = vec3.scale;

const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Ray = ray.Ray;
const dot = vec3.dot;
const length_squared = vec3.length_squared;
const HitRecord = hittable.HitRecord;
const Hittable = hittable.Hittable;
const HitParameters = hittable.HitParameters;

pub fn Sphere(comptime T: type) type {
    return struct {
        center: Point3(T),
        radius: T,

        pub fn hit(self: *@This(), hit_parameters: *(HitParameters(T))) bool {
            const r: Ray(T) = hit_parameters.r;
            const oc = r.orig - self.center;
            const a = length_squared(T, r.dir);
            const half_b = dot(T, oc, r.dir);
            const c = length_squared(T, oc) - self.radius * self.radius;

            const discriminant = half_b * half_b - a * c;
            if (discriminant < 0) {
                return false;
            }
            const sqrtd = @sqrt(discriminant);
            const t_min = hit_parameters.t_min;
            const t_max = hit_parameters.t_max;
            var root = (-half_b - sqrtd) / a;
            if ((root < t_min) or (t_max < root)) {
                return false;
            }
            const rec = hit_parameters.hit_record;
            rec.t = root;
            rec.p = r.at(rec.t);
            const outward_normal: Vec3(T) = scale(T, 1 / self.radius, rec.p - self.center);
            rec.set_face_normal(r, outward_normal);

            return true;
        }
    };
}
