const std = @import("std");

const assert = std.debug.assert;
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
const near_zero = vec3.near_zero;

pub const Material = struct {
    const VTable = struct { scatter: fn (ptr: *anyopaque, r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool };

    ptr: *anyopaque,
    vtable: *const VTable,

    pub fn scatter(pointer: *@This(), r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool {
        _ = pointer;
        _ = r;
        _ = rec;
        _ = attenuation;
        _ = scattered;
        _ = rng;
        return false;
    }

    pub fn init(pointer: anytype, comptime scatterFn: fn (ptr: @TypeOf(pointer), r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool) @This() {
        const Ptr = @TypeOf(pointer);
        const ptr_info = @typeInfo(Ptr);

        assert(ptr_info == .Pointer);
        assert(ptr_info.Pointer.size == .One);

        const alignment = ptr_info.Pointer.alignment;

        const gen = struct {
            fn scatterImpl(ptr: *anyopaque, r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, scatterFn, .{ self, r, rec, attenuation, scattered, rng });
            }
            const vtable = VTable{
                .scatter = scatterImpl,
            };
        };

        return .{
            .ptr = pointer,
            .vtable = &gen.vtable,
        };
    }
};

pub const Lambertian = struct {
    albedo: Color,

    pub fn scatter(self: *@This(), r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool {
        //  unused parameters
        _ = r;
        var scatter_direction = rec.normal + random_unit_vector(rng);
        if (near_zero(scatter_direction)) {
            scatter_direction = rec.normal;
        }
        scattered.* = Ray{ .orig = rec.p, .dir = scatter_direction };
        attenuation.* = self.albedo;
        return true;
    }

    pub fn material(self: *@This()) Material {
        return Material.init(self, scatter);
    }
};

pub const Metal = struct {
    albedo: Color,
    pub fn scatter(self: *@This(), r: *Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray, rng: rand.Random) bool {
        _ = rng;
        const reflected = reflect(unit_vector(r.dir), rec.normal);
        scattered.* = Ray{ .orig = rec.p, .dir = reflected };
        attenuation.* = self.albedo;
        return (vec3.dot(scattered.dir, rec.normal) > 0);
    }

    pub fn material(self: *@This()) Material {
        return Material.init(self, scatter);
    }
};
