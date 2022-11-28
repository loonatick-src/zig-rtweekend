# zig-rtweekend
Following along with "Ray Tracing in One Weekend" (https://raytracing.github.io) in Zig. Mostly an exericise in learning Zig.

A key difference is that while the original code C++ code avoided
templates completely, I am trying to make all functions generic.
The code might not be particularly idiomatic due to the more-or-less
direct translation from C++, but I have tried to look up and come up
with programming patterns better suited for Zig.

# Progress
[Diffuse Materials](https://github.com/loonatick-src/zig-rtweekend/blob/master/images/chapter08_init.png?raw=true)
## Ray Tracing in One Weekend
1. Overview
2. [X] Output an Image
3. [X] The `vec3` class
4. [X] Rays, a Simple Camera, and Background
5. [X] Adding a Sphere
6. [X] Surface normals and Multiple Objects
7. [X] Antialiasing
8. [X] Diffuse Materials
9. [ ] Metal
10. [ ] Dielectrics
11. [ ] Positionable Camera
12. [ ] Defocus Blur
13. [ ] Final Render

## Ray Tracing: The Next Week
TODO
## Ray Tracing: The Rest of Your Life
TODO


## TODO
- [ ] Try different polymorphism patterns: see [this showtime](https://www.youtube.com/watch?v=AHc4x1uXBQE). Specifically, it would be nicer to do `const s1 = Sphere { ... }; const s1_h = s1.hittable();` instead of the `make` thing that we have going on right now
- [ ] Parallelize
    - [ ] Load-balancing
- [ ] GPU Acceleration? See Mach engine and Zig gamedev scene in general for inspiration maybe?

