shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float brightness_boost : hint_range(1.0, 3.0) = 1.8;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// Calculate luminance of the pixel
	float lum = max(tex.r, max(tex.g, tex.b));
	
	// Set alpha based on luminance so the black background is transparent
	float alpha = clamp(lum * 1.5, 0.0, 1.0);
	
	// Modulate RGB by target color and apply brightness boost
	vec3 final_rgb = target_color.rgb * lum * brightness_boost;
	
	COLOR = vec4(final_rgb, alpha * target_color.a);
}
