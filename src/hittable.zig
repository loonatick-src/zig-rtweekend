const std = @import("std");
const ray = @import("ray.zig");
const vec3 = @import("vec3.zig");
const material = @import("material.zig");

const assert = std.debug.assert;
const inf = std.math.inf;

const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;
const Ray = ray.Ray;
const Material = material.Material;

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    mat_ptr: *Material,
    t: f32,
    front_face: bool,

    pub fn set_face_normal(self: *@This(), r: Ray, outward_normal: Vec3) void {
        const front_face = dot(r.dir, outward_normal) < 0;
        self.normal = outward_normal;
        if (!front_face) {
            self.normal = (Vec3{ 0, 0, 0 }) - outward_normal;
        }
    }
};

// Ladies and gentlemen, runtime polymorphism. Check out the following lovely showtime
// https://www.youtube.com/watch?v=AHc4x1uXBQE&t=2126s
// With my understanding of Zig at the time of working on this project, I
// highly doubt I could have come up with this on my own.
// `fn (usize, r: Ray, t_min: f32, t_max: f32, rec: *HitRecord) bool`
pub const Hittable = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub fn hit(ptr: *@This(), r: Ray, t_min: f32, t_max: f32, rec: *HitRecord) bool {
        _ = ptr;
        _ = r;
        _ = t_min;
        _ = t_max;
        _ = rec;

        return false;
    }

    pub const VTable = struct {
        hit: fn (ptr: *anyopaque, r: Ray, t_min: f32, t_max: f32, rec: *HitRecord) bool,
    };

    pub fn init(pointer: anytype, comptime hitFn: fn (ptr: @TypeOf(pointer), r: Ray, t_min: f32, t_max: f32, rec: *HitRecord) bool) Hittable {
        const Ptr = @TypeOf(pointer);
        const ptr_info = @typeInfo(Ptr);

        assert(ptr_info == .Pointer); // Must be a pointer
        assert(ptr_info.Pointer.size == .One); // Must be a single-item pointer

        const alignment = ptr_info.Pointer.alignment;

        const gen = struct {
            fn hitImpl(ptr: *anyopaque, r: Ray, t_min: f32, t_max: f32, rec: *HitRecord) bool {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, hitFn, .{ self, r, t_min, t_max, rec });
            }

            const vtable = VTable{
                .hit = hitImpl,
            };
        };

        return .{
            .ptr = pointer,
            .vtable = &gen.vtable,
        };
    }
};
