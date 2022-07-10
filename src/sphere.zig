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
const Material = @import("material.zig").Material;

pub fn Sphere(comptime T: type) type {
    return struct {
        const Self = @This();
        center: Point3(T),
        radius: T,
        mat_ptr: *Material(T),

        pub fn hit(self: *@This(), r: Ray(T), t_min: T, t_max: T, rec: *(HitRecord(T))) bool {
            const oc = r.orig - self.center;
            const a = length_squared(T, r.dir);
            const half_b = dot(T, oc, r.dir);
            const c = length_squared(T, oc) - self.radius * self.radius;

            const discriminant = half_b * half_b - a * c;
            if (discriminant < 0) {
                return false;
            }
            const sqrtd = @sqrt(discriminant);
            var root = (-half_b - sqrtd) / a;
            if ((root < t_min) or (t_max < root)) {
                return false;
            }
            rec.t = root;
            rec.p = r.at(rec.t);
            const outward_normal: Vec3(T) = scale(T, 1 / self.radius, rec.p - self.center);
            rec.set_face_normal(r, outward_normal);
            rec.mat_ptr = self.mat_ptr;

            return true;
        }

        pub fn init(cen: Point3(T), r: T, m: *Material) Self {
            return .{
                .center = cen,
                .radius = r,
                .m = m,
            };
        }
    };
}
