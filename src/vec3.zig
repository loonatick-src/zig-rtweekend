const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

const Vector = std.meta.Vector;

pub const Vec3 = Vector(3, f32);

pub fn scale(t: f32, v: Vec3) Vec3 {
    return [_]f32{ t * v[0], t * v[1], t * v[2] };
}

pub fn dot(v1: Vec3, v2: Vec3) f32 {
    return @reduce(.Add, v1 * v2);
}

pub fn cross(v1: Vec3, v2: Vec3) Vec3 {
    // 12 - 21, 20 - 02, 01 - 10
    return [_]f32{ v1[1] * v2[2] - v1[2] * v2[1], v1[2] * v2[0] - v1[0] * v2[2], v1[0] * v2[1] - v1[1] * v2[0] };
}

pub fn magnitude(v: Vec3) f32 {
    return @sqrt(dot(v, v));
}

pub fn unit_vector(v: Vec3) Vec3 {
    const m: f32 = magnitude(v);
    const rv: Vec3 = scale(1.0 / m, v);
    return rv;
}

pub fn length_squared(v: Vec3) f32 {
    return dot(v, v);
}

pub fn RandFloatFn(comptime T: type) type {
    return struct {
        const Self = @This();
        pub fn random(rand: anytype) T {
            return rand.float(T);
        }

        pub fn random_scaled(min: T, max: T, rand: anytype) T {
            const rv = Self.random(rand);
            return min + (max - min) * rv;
        }
    };
}

pub fn RandVecFn(comptime T: type) type {
    return struct {
        const Self = @This();
        fn random(rand: anytype) Vec3 {
            return Vec3{ rand.float(T), rand.float(T), rand.float(T) };
        }

        pub fn random_scaled(min: T, max: T, rand: anytype) T {
            // TODO: are there better ways of broadcasting a scalar
            // into a vector?
            const s = (max - min);
            const nrv = Self.random(rand);
            const base = Vec3{ min, min, min };
            const sv = Vec3{ s, s, s };
            return base + sv * nrv;
        }

        pub fn random_in_unit_sphere(rand: anytype) Vec3 {
            const x = RandFloatFn(T).random(rand);
            const ylim_sq = 1 - x * x;
            const ylim = @sqrt(ylim_sq);
            const y = RandFloatFn(T).random_scaled(-ylim, ylim, rand);
            const zlim = @sqrt(ylim_sq - y * y);
            const z = RandFloatFn(T).random_scaled(-zlim, zlim, rand);
            return Vec3{ x, y, z };
        }

        pub fn random_unit_vector(rand: anytype) Vec3 {
            return unit_vector(random_in_unit_sphere(rand));
        }

        pub fn random_in_hemisphere(normal: Vec3, rand: anytype) Vec3 {
            const in_unit_sphere = Self.random_in_unit_sphere(rand);
            if (dot(in_unit_sphere, normal) > 0.0) {
                return in_unit_sphere;
            } else {
                return -in_unit_sphere;
            }
        }
    };
}

pub const Point3 = Vec3;
pub const Color = Vec3;

test "Builtin Vector tests" {
    // how to float literal?
    const x = @as(f32, 1.1);
    const y = @as(f32, 2.2);
    const z = @as(f32, 3.3);
    const w = @as(f32, 4.4);

    const v1 = Vec3(f32){ x, y, z };
    const v2 = Vec3(f32){ y, z, w };

    const add_result: Vec3(f32) = [_]f32{ x + y, y + z, z + w };
    try expectEqual(v1 + v2, add_result);

    const sub_result: Vec3(f32) = [_]f32{ x - y, y - z, z - w };
    try expectEqual(v1 - v2, sub_result);

    const t = 2.5;
    const scale_result: Vec3(f32) = [_]f32{ t * x, t * y, t * z };
    try expectEqual(scale_result, scale(f32, t, v1));
}

test "RNG functions" {
    const rf_funcs = RandFloatFn(f32);
    const random_float = rf_funcs.random;

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    const rf32 = random_float(rand);
    try expect((0 < rf32) and (rf32 < 1));

    const random_float_scaled = rf_funcs.random_scaled;
    const min = -1.0;
    const max = 3.0;
    const rand_scaled = random_float_scaled(min, max, rand);

    try expect((rand_scaled > min) and (rand_scaled < max));
}
