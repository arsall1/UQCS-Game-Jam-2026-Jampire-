extern Image atlas;
extern vec2 atlasSize;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc)
{
    float id = color.r;

    float columns = atlasSize.x;

    float x = mod(id, columns);
    float y = floor(id / columns);

    vec2 cellSize = 1.0 / atlasSize;

    vec2 baseUV = vec2(x, y) * cellSize;

    return Texel(atlas, baseUV + uv * cellSize);
}