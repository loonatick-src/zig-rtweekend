const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");
const Point3 = vec3.Point3;
const Ray = ray.Ray;
const Vec3 = vec3.Vec3;
const scale = vec3.scale;

pub const Camera = struct {
    origin: Point3,
    lower_left_corner: Point3,
    horizontal: Vec3,
    vertical: Vec3,

    pub fn init() @This() {
        const aspect_ratio = 16.0 / 9.0;
        const viewport_height = 2.0;
        const viewport_width = aspect_ratio * viewport_height;
        const focal_length = 1.0;
        const horizontal = Vec3{ viewport_width, 0, 0 };
        const vertical = Vec3{ 0, viewport_height, 0 };
        const half_hor = scale(0.5, horizontal);
        const half_vert = scale(0.5, vertical);
        const origin = Point3{ 0, 0, 0 };

        return .{
            .origin = origin,
            .horizontal = horizontal,
            .vertical = vertical,
            .lower_left_corner = origin - half_hor - half_vert - Vec3{ 0, 0, focal_length },
        };
    }

    pub fn get_ray(self: *const @This(), u: f32, v: f32) Ray {
        const uhor = scale(u, self.horizontal);
        const vvert = scale(v, self.vertical);
        return .{
            .orig = self.origin,
            .dir = self.lower_left_corner + uhor + vvert - self.origin,
        };
    }
};
