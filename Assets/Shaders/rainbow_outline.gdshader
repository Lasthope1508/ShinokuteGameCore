shader_type canvas_item;
render_mode blend_add;

uniform float speed = 1.0;
uniform float frequency = 1.0;
uniform float glow_power = 2.0;

void fragment() {
	// UV.x represents the path length when Line2D texture mode is set to STRETCH.
	float hue = mod(UV.x * frequency - TIME * speed, 1.0);
	
	// Convert hue to RGB (standard HSV to RGB conversion)
	vec3 rgb = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	
	// Soft glow profile across the width of the line (highest at center UV.y = 0.5)
	float glow = sin(UV.y * 3.14159265);
	glow = pow(glow, glow_power);
	
	COLOR = vec4(rgb, glow);
}
