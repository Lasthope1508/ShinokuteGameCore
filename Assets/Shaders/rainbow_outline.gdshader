shader_type canvas_item;
render_mode blend_add;

uniform float speed = 1.0;
uniform float frequency = 1.0;
uniform float glow_power = 2.0;
uniform bool use_lightning = false;
uniform vec4 block_color : source_color = vec4(1.0);

void fragment() {
	// 7-color rainbow hue running along the Line2D path
	float hue = mod(UV.x * frequency - TIME * speed, 1.0);
	
	// Convert hue to RGB (standard HSV to RGB conversion)
	vec3 rainbow = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	
	// Soft glow profile across the width of the line (highest at center UV.y = 0.5)
	float glow = sin(UV.y * 3.14159265);
	glow = pow(glow, glow_power);
	
	vec4 final_color = vec4(rainbow, glow);
	
	if (use_lightning) {
		// Sample the lightning video texture
		vec4 tex = texture(TEXTURE, UV);
		// Combine: texture color modulated by both the block color and the rainbow colors
		// Boost brightness for a vibrant lightning strike effect
		final_color.rgb = tex.rgb * block_color.rgb * rainbow * 3.0;
		final_color.a = tex.a * glow;
	}
	
	COLOR = final_color;
}
