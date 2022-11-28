const std = @import("std");
const rand = std.rand;

const color = @import("color.zig");
const hittable = @import("hittable.zig");
const ray = @import("ray.zig");
const vec3 = @import("vec3.zig");

const Color = vec3.Color;
const HitRecord = hittable.HitRecord;
const Ray = ray.Ray;
const random_unit_vector = vec3.random_unit_vector;
const unit_vector = vec3.unit_vector;
const reflect = vec3.reflect;

pub const Material = struct {
    const VTable = struct { scatter: fn (usize, r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool };
    vtable: *const VTable,
    object: usize,

    pub fn make(obj: anytype) @This() {
        const PtrType = @TypeOf(obj);
        return .{
            .vtable = &comptime VTable{
                .scatter = struct {
                    pub fn scatter(ptr: usize, r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool {
                        const self = @intToPtr(PtrType, ptr);
                        return @call(.{ .modifier = .always_inline }, std.meta.Child(PtrType).hit, .{ self, r, rec, attenuation, scattered, rng });
                    } // fn scatter
                }.scatter, // .scatter
            }, // .vtable
            .object = @ptrToInt(obj),
        };
    }
};

pub const Lambertian = struct {
    albedo: Color,

    pub fn scatter(self: *@This(), r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool {
        //  unused parameters
        _ = .{r};
        var scatter_direction = rec.normal + random_unit_vector(rng);
        if (scatter_direction.near_zero()) {
            scatter_direction = rec.normal;
        }
        scattered.* = Ray{ .orig = rec.p, .dir = scatter_direction };
        attenuation.* = self.albedo;
        return true;
    }
};

pub const Metal = struct {
    albedo: Color,
    pub fn scatter(self: *@This(), r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool {
        _ = .{rng};
        const reflected = reflect(unit_vector(r.dir), rec.normal);
        scattered.* = Ray{ .orig = rec.p, .dir = reflected };
        attenuation.* = self.albedo;
        return (vec3.dot(scattered.dir, rec.normal) > 0);
    }
};
