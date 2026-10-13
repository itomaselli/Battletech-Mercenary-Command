shader_type canvas_item;
render_mode unshaded;
uniform bool scanlines = true;
uniform bool vignette = true;
void fragment() {
 float line = scanlines ? (mod(FRAGCOORD.y, 3.0) < 1.0 ? 0.035 : 0.0) : 0.0;
 float edge = vignette ? smoothstep(0.35, 0.76, distance(UV, vec2(0.5))) * 0.08 : 0.0;
 COLOR = vec4(0.0, 0.0, 0.0, min(0.32, line + edge));
}
