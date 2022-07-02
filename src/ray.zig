const vec3 = @import("vec3.zig");
const Vector3 = vec3.Vector3;
const Point3 = vec3.Point3;
const scale = vec3.scale;

const Ray = struct {
    comptime T: type = f32,
    orig: Vector3(.T),
    dir: Point3(.T),

    fn at(t: .T) Vector3 {
        return .orig + scale(t, .dir);
    }
};
