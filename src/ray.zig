const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const scale = vec3.scale;

pub fn Ray(comptime T: type) type {
    return struct {
        orig: Point3(T),
        dir: Vec3(T),

        pub fn at(self: *const @This(), t: T) Vec3(T) {
            return self.orig + scale(T, t, self.dir);
        }
    };
}

// TODO: change this to take a reference as first arg?
// pub fn at(comptime T: type, t: T, r: Ray(T)) Vec3(T) {
//    return r.orig + scale(T, t, r.dir);
// }

pub fn Ray_init(comptime T: type, orig: Point3(T), dir: Vec3(T)) Ray(T) {
    return Ray(T){
        .orig = orig,
        .dir = dir,
    };
}
