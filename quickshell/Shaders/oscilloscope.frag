#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float lineHalf;
    float texel;
    vec4 tint;
};

layout(binding = 1) uniform sampler2D source;

void main()
{
    vec2 uv = qt_TexCoord0;
    float y0 = texture(source, vec2(uv.x, 0.5)).r;
    float y1 = texture(source, vec2(min(uv.x + texel, 1.0), 0.5)).r;
    float ymin = min(y0, y1);
    float ymax = max(y0, y1);
    float d = 0.0;
    if (uv.y < ymin)
        d = ymin - uv.y;
    else if (uv.y > ymax)
        d = uv.y - ymax;
    float a = 1.0 - smoothstep(0.0, max(lineHalf, 0.00075), d);
    fragColor = vec4(tint.rgb, tint.a * a) * qt_Opacity;
}
