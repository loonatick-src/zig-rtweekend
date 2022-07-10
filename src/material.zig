const std = @import("std");
const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");

const Ray = ray.Ray;
const Vec3 = vec3.Vec3;
const Color = vec3.Color;
const HitRecord = @import("hittable.zig").HitRecord;

const scale = vec3.scale;
const dot = vec3.dot;
const reflect = vec3.reflect;
const unit_vector = vec3.unit_vector;
const near_zero = vec3.near_zero;

// scatter: fn (usize, Ray(T), *HitRecord(T), Color(T), Ray(T)) bool
pub fn Material(comptime T: type) type {
    return struct {
        const VTable = struct { scatter: fn (usize, Ray(T), *HitRecord(T), Color(T), Ray(T), rand: anytype) bool };

        vtable: *const VTable,
        object: usize,

        pub fn scatter(self: @This(), r_in: Ray(T), rec: *HitRecord(T), attenuation: Color(T), scattered: *Ray(T), rand: anytype) bool {
            return self.vtable.scatter(self.object, r_in, rec, attenuation, scattered, rand);
        }

        pub fn make(obj: anytype) @This() {
            const PtrType = @TypeOf(obj);
            return .{
                .vtable = &comptime VTable{
                    .scatter = struct {
                        pub fn scatter(ptr: usize, r_in: Ray(T), rec: *HitRecord(T), attenuation: *Color(T), scattered: *Ray(T), rand: anytype) bool {
                            const self = @intToPtr(PtrType, ptr);
                            return @call(.{ .modifier = .always_inline }, std.meta.Child(PtrType).scatter, .{ self, r_in, rec, attenuation, scattered, rand });
                        }
                    }.scatter,
                },
                .object = @ptrToInt(obj),
            };
        }
    };
}

// scatter: fn (usize, Ray(T), *HitRecord(T), Color(T), Ray(T)) bool
pub fn Lambertian(comptime T: type) type {
    const random_unit_vector = vec3.RandVecFn(T).random_unit_vector;
    return struct {
        const Self = @This();
        albedo: Color(T),

        pub fn scatter(self: *Self, r_in: Ray(T), rec: *HitRecord(T), attenuation: *Color(T), scattered: *Ray(T), rand: anytype) bool {
            // I must use `r_in` as well, hence the zero
            // TODO: refactor Material's scatter function to take a pointer to a struct instead of a list of arguments
            const scatter_direction = rec.normal + random_unit_vector(rand) + scale(T, 0, r_in.dir);

            if (near_zero(T, scatter_direction)) {
                scatter_direction = rec.normal;
            }

            scattered.* = Ray(T).init(rec.p, scatter_direction);
            attenuation.* = self.albedo;
            return true;
        }
    };
}

pub fn Metal(comptime T: type) type {
    return struct {
        const Self = @This();

        albedo: Color(T),

        pub fn scatter(self: *Self, r_in: Ray(T), rec: *HitRecord(T), attenuation: *Color(T), scattered: *Ray(T), rand: anytype) bool {
            const reflected: Vec3(T) = reflect(T, unit_vector(r_in.dir), rec.normal);
            scattered.* = Ray(T).init(rec.p, reflected);
            attenuation.* = self.albedo + (0 * rand.float(T));
            return (dot(T, scattered.dir, rec.normal) > 0);
        }
    };
}
