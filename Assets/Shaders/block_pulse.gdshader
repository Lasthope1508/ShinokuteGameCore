// Pulses a CanvasItem's color toward white based on a sine wave driven by
// the engine TIME. The Cell script toggles `pulse_strength` between 0 and 1
// to enable / disable the effect on a per-block basis.
shader_type canvas_item;

uniform float pulse_strength : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(1.0, 30.0) = 9.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.65;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// 0..1 sine wave.
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	// How strongly to push the pixel toward white this frame.
	float mix_amount = pulse * pulse_strength * pulse_intensity;
	// Apply Godot's default modulate (COLOR) before mixing toward white,
	// then keep the texture's alpha so transparent pixels stay invisible.
	vec3 base = tex.rgb * COLOR.rgb;
	vec3 final_rgb = mix(base, vec3(1.0), mix_amount * tex.a);
	COLOR = vec4(final_rgb, tex.a * COLOR.a);
}
