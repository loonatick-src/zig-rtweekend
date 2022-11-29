const std = @import("std");
const rand = std.rand;

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

const Vector = std.meta.Vector;

pub const Vec3 = Vector(3, f32);

pub fn near_zero(self: Vec3) bool {
    const abstol: f32 = 1.0e-8;
    return @fabs(self[0]) < abstol and @fabs(self[1]) < abstol and @fabs(self[2]) < abstol;
}

pub fn reflect(v: Vec3, n: Vec3) Vec3 {
    return v - scale(2 * dot(v, n), n);
}

pub fn scale(t: f32, v: Vec3) Vec3 {
    return Vec3{ t * v[0], t * v[1], t * v[2] };
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

pub fn random_unit_vector(rng: rand.Random) Vec3 {
    return unit_vector(random_in_unit_sphere(rng));
}

pub fn length_squared(v: Vec3) f32 {
    return dot(v, v);
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

pub fn random(rng: rand.Random) f32 {
    return rng.float(f32);
}

pub fn random_scaled(rng: rand.Random, lo: f32, hi: f32) f32 {
    const r = random(rng);
    return lo + (hi - lo) * r;
}

pub fn random_in_unit_sphere(rng: rand.Random) Vec3 {
    const x = rng.float(f32);
    const ylim_sq = 1 - x * x;
    const ylim = @sqrt(ylim_sq);
    const y = random_scaled(rng, -ylim, ylim);
    const zlim = @sqrt(ylim_sq - y * y);
    const z = random_scaled(rng, -zlim, zlim);
    return Vec3{ x, y, z };
}

pub fn random_in_hemisphere(rng: rand.Random, normal: Vec3) Vec3 {
    const in_unit_sphere = random_in_unit_sphere(rng);
    if (dot(in_unit_sphere, normal) > 0.0) {
        return in_unit_sphere;
    } else {
        return -in_unit_sphere;
    }
}

test "RNG functions" {
    const seed: u64 = 1337;
    const default_rng = rand.DefaultPrng.init(seed);
    var rng = default_rng.random();

    const r01 = random(rng);
    try expect(r01 < 1.0 and r01 >= 0.0);
    const lo = -5.0;
    const hi = 3.0;
    const r_lo_hi = random_scaled(rng, lo, hi);
    try expect(r_lo_hi >= lo and r_lo_hi < hi);
}
