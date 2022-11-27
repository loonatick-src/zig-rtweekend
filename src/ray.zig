const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const scale = vec3.scale;

pub const Ray = struct {
    orig: Point3,
    dir: Vec3,

    pub fn at(self: *const @This(), t: f32) Vec3 {
        return self.orig + scale(t, self.dir);
    }
};
