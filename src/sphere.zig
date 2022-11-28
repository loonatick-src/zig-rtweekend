const std = @import("std");

const hittable = @import("hittable.zig");
const material = @import("material.zig");
const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");
const scale = vec3.scale;

const Material = material.Material;
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const Ray = ray.Ray;
const dot = vec3.dot;
const length_squared = vec3.length_squared;
const HitRecord = hittable.HitRecord;
const Hittable = hittable.Hittable;

pub const Sphere = struct {
    center: Point3,
    radius: f32,
    mat_ptr: *Material,

    pub fn hit(self: *@This(), r: Ray, t_min: f32, t_max: f32, rec: *HitRecord) bool {
        const oc = r.orig - self.center;
        const a = length_squared(r.dir);
        const half_b = dot(oc, r.dir);
        const c = length_squared(oc) - self.radius * self.radius;

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
        const outward_normal: Vec3 = scale(1 / self.radius, rec.p - self.center);
        rec.set_face_normal(r, outward_normal);
        rec.mat_ptr = self.mat_ptr;

        return true;
    }
};
