const math = @import("std").math;
const Vec3 = @import("vec3.zig").Vec3;
pub const pi = math.pi;

pub fn degrees_to_radians(comptime T: type, degrees: T) T {
    return degrees * @as(T, pi) / @as(T, 180.0);
}

pub fn random_float(comptime T: type, rand: anytype) T {
    return rand.float(T);
}

pub fn random_float_scaled(comptime T: type, lo: T, hi: T, rand: anytype) T {
    const r = rand.float(T);
    return lo + (hi - lo) * r;
}

pub fn clamp(comptime T: type, x: T, lo: T, hi: T) T {
    if (x < lo) return lo;
    if (x > hi) return hi;
    return x;
}

pub fn clamp_vec3(comptime T: type, v: Vec3(T), lo: T, hi: T) Vec3(T) {
    var rv: Vec3(T) = undefined;
    rv[0] = clamp(T, v[0], lo, hi);
    rv[1] = clamp(T, v[1], lo, hi);
    rv[2] = clamp(T, v[2], lo, hi);
    return rv;
}
