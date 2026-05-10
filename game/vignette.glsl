extern vec2 resolution;
extern float radius;
extern float softness;

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
    vec4 currentColor = Texel(tex, texture_coords);

    vec2 offset = screen_coords.xy / resolution - vec2(0.5);

    float magnitude = length(offset);

    float vignette = smoothstep(radius, radius - softness, magnitude);

    return currentColor * vignette;
}