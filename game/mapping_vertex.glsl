uniform float W;
uniform float H;
uniform float Rinner;
uniform float Router;
uniform vec2 center;
uniform float zoom;
uniform vec2 camera;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    float i = vertex_position.x - camera.x;
    float j = vertex_position.y;

    float theta = 6.2831853 * (i / W);
    float r = Rinner + (j / H) * (Router - Rinner);

    vec2 pos = center + vec2(0, camera.y) + vec2(cos(theta), sin(theta)) * r * zoom;
    

    return transform_projection * vec4(pos, 0.0, 1.0);
}