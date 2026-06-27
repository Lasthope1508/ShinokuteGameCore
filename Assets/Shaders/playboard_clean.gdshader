shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.88, 0.25, 0.98, 1.0); // Default neon pink
uniform vec4 bg_color : source_color = vec4(0.08, 0.06, 0.15, 0.47); // Dark dimmed background
uniform float threshold : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Calculate brightness of the pixel
	float brightness = (tex_color.r + tex_color.g + tex_color.b) / 3.0;
	
	if (brightness < threshold) {
		// It's a grid line! Apply the line color and preserve the texture alpha.
		COLOR = vec4(line_color.rgb, tex_color.a);
	} else {
		// It's the background of the playboard. Draw translucent bg_color modulated by the texture's alpha.
		COLOR = vec4(bg_color.rgb, bg_color.a * tex_color.a);
	}
}

