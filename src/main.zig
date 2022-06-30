const std = @import("std");

/// WTF
/// ```zig
/// for (range(10)) |_, i| {
///     ...
/// }```
// pub fn range(len: usize) []const void {
//    return @as([*]void, undefined)[0..len];
// }

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const image_width: i32 = 256;
    const image_height: i32 = 256;
    const dw: f32 = @as(f32, image_width - 1);
    const dh: f32 = @as(f32, image_height - 1);

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var j = image_height - 1;
    while (j >= 0) : (j -= 1) {
        var i: i32 = 0;
        while (i < image_width) : (i += 1) {
            const r = @intToFloat(f32, i) / dw;
            const g = @intToFloat(f32, j) / dh;
            const b: f32 = 0.25;
            const ir = @floatToInt(i32, 255.999 * r);
            const ig = @floatToInt(i32, 255.999 * g);
            const ib = @floatToInt(i32, 255.999 * b);

            try stdout.print("{} {} {}\n", .{ ir, ig, ib });
        }
    }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
