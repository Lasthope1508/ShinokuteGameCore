shader_type canvas_item;
render_mode blend_add;

uniform float speed = 1.0;
uniform float frequency = 1.0;
uniform float glow_power = 2.0;
uniform bool use_rainbow = true;
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
	
	vec4 final_color = vec4(0.0);
	
	if (use_rainbow) {
		final_color = vec4(rainbow, glow);
	}
	
	if (use_lightning) {
		// Sample texture using standard UV (which tiles naturally along the Line2D)
		vec4 tex = texture(TEXTURE, UV);
		
		// Modulate lightning by block color
		vec3 lightning_color = tex.rgb * block_color.rgb * 3.0;
		
		// Use the brightness of the lightning (length of RGB) as its luma key mask
		float lightning_mask = clamp(length(tex.rgb) * 1.5, 0.0, 1.0);
		
		if (use_rainbow) {
			final_color.rgb = mix(final_color.rgb, lightning_color, lightning_mask);
			final_color.a = max(final_color.a, lightning_mask * glow);
		} else {
			final_color.rgb = lightning_color;
			final_color.a = lightning_mask * glow;
		}
	}
	
	COLOR = final_color;
}
