const math = @import("std").math;
pub const pi = math.pi;

pub fn degrees_to_radians(comptime T: type, degrees: T) T {
    return degrees * @as(T, pi) / @as(T, 180.0);
}
