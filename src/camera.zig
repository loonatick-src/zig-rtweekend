const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");
const Point3 = vec3.Point3;
const Ray = ray.Ray;
const Vec3 = vec3.Vec3;
const scale = vec3.scale;

pub fn Camera(comptime T: type) type {
    return struct {
        origin: Point3(T),
        lower_left_corner: Point3(T),
        horizontal: Vec3(T),
        vertical: Vec3(T),

        pub fn init() @This() {
            const aspect_ratio = 16.0 / 9.0;
            const viewport_height = 2.0;
            const viewport_width = aspect_ratio * viewport_height;
            const focal_length = 1.0;
            const horizontal = Vec3(T){ viewport_width, 0, 0 };
            const vertical = Vec3(T){ 0, viewport_height, 0 };
            const half_hor = scale(T, 0.5, horizontal);
            const half_vert = scale(T, 0.5, vertical);
            const origin = Point3(T){ 0, 0, 0 };

            return .{
                .origin = origin,
                .horizontal = horizontal,
                .vertical = vertical,
                .lower_left_corner = origin - half_hor - half_vert - Vec3(T){ 0, 0, focal_length },
            };
        }

        pub fn get_ray(self: *const @This(), u: T, v: T) Ray(T) {
            const uhor = scale(T, u, self.horizontal);
            const vvert = scale(T, v, self.vertical);
            return .{
                .orig = self.origin,
                .dir = self.lower_left_corner + uhor + vvert - self.origin,
            };
        }
    };
}
