const std = @import("std");
const expectEqual = std.testing.expectEqual;

const Vector = std.meta.Vector;

// looks ugly
pub fn Vec3(comptime T: type) type {
    return Vector(3, T);
}

pub fn Vec3_init(comptime T: type, x: T, y: T, z: T) Vector(3, T) {
    return Vector(3, T){ x, y, z };
}

pub fn scale(comptime T: type, t: T, v: Vec3(T)) Vec3(T) {
    return [_]T{ t * v[0], t * v[1], t * v[2] };
}

pub fn dot(comptime T: type, v1: Vec3(T), v2: Vec3(T)) T {
    return @reduce(.Add, v1 * v2);
}

pub fn cross(comptime T: type, v1: Vec3(T), v2: Vec3(T)) Vec3(T) {
    // 12 - 21, 20 - 02, 01 - 10
    return [_]T{ v1[1] * v2[2] - v1[2] * v2[1], v1[2] * v2[0] - v1[0] * v2[2], v1[0] * v2[1] - v1[1] * v2[0] };
}

pub fn magnitude(comptime T: type, v: Vec3(T)) T {
    return @sqrt(dot(T, v, v));
}

pub fn unit_vector(comptime T: type, v: Vec3(T)) Vec3(T) {
    const m: T = magnitude(T, v);
    const rv: Vec3(T) = scale(T, 1.0 / m, v);
    return rv;
}

pub fn length_squared(comptime T: type, v: Vec3(T)) T {
    return dot(T, v, v);
}

pub const Point3 = Vec3;
pub const Color = Vec3;

pub const Point3_init = Vec3_init;
pub const Color_init = Vec3_init;

test "Builtin Vector tests" {
    // how to float literal?
    const x = @as(f32, 1.1);
    const y = @as(f32, 2.2);
    const z = @as(f32, 3.3);
    const w = @as(f32, 4.4);

    const v1 = Vec3_init(f32, x, y, z);
    const v2 = Vec3_init(f32, y, z, w);

    const add_result: Vec3(f32) = [_]f32{ x + y, y + z, z + w };
    try expectEqual(v1 + v2, add_result);

    const sub_result: Vec3(f32) = [_]f32{ x - y, y - z, z - w };
    try expectEqual(v1 - v2, sub_result);

    const t = 2.5;
    const scale_result: Vec3(f32) = [_]f32{ t * x, t * y, t * z };
    try expectEqual(scale_result, scale(f32, t, v1));
}
