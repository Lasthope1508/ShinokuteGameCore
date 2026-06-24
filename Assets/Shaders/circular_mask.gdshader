shader_type canvas_item;

void fragment() {
    float dist = distance(UV, vec2(0.5));
    // smoothstep(0.5, 0.48, dist) provides smooth anti-aliased edges
    COLOR.a = COLOR.a * smoothstep(0.5, 0.48, dist);
}
