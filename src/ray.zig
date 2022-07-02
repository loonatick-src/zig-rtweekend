const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;
const scale = vec3.scale;

// TODO: how do I make this generic?
pub const Ray = struct {
    const Self = @This();
    const T: type = f32;

    orig: Vec3(T),
    dir: Point3(T),

    fn init(orig: Vec3(T), dir: Point3(T)) Self {
        return Self{
            .T = T,
            .orig = orig,
            .dir = dir,
        };
    }

    fn at(t: .T) Vec3 {
        return .orig + scale(t, .dir);
    }
};
