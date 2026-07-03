shader_type canvas_item;

uniform float pulse_strength : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(1.0, 30.0) = 9.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.65;

uniform float dissolve_cutoff : hint_range(0.0, 1.0) = 0.0;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.0;
uniform float glow_flare : hint_range(1.0, 3.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(1.0);
uniform float glow_spread : hint_range(0.01, 0.2) = 0.08;
uniform float shrink_factor : hint_range(1.0, 2.0) = 1.0;

void fragment() {
	vec2 uv = (UV - vec2(0.5)) * shrink_factor + vec2(0.5);

	vec4 tex = vec4(0.0);
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		tex = texture(TEXTURE, uv);
	}
	
	// Dissolve from center outwards
	float dist_from_center = length(uv - vec2(0.5));
	// Max distance from center to corner of a square is sqrt(0.5^2 + 0.5^2) = sqrt(0.5) ≈ 0.7071
	float norm_dist = dist_from_center / 0.7071;
	
	if (norm_dist < dissolve_cutoff) {
		discard;
	}
	
	vec4 base_color = tex * COLOR;
	
	// Apply soft feathered aura glow
	if (glow_strength > 0.01) {
		// Glow breathing animation (smooth, slow breathing)
		float glow_wave = sin(TIME * 2.5) * 0.12 + 0.88;
		float current_glow = glow_strength * glow_flare * glow_wave;
		
		// Sample neighboring pixels at 8 directions and 3 distance levels to construct a soft glow
		float outline = 0.0;
		int samples = 0;
		for (float dx = -1.0; dx <= 1.0; dx += 1.0) {
			for (float dy = -1.0; dy <= 1.0; dy += 1.0) {
				if (dx != 0.0 || dy != 0.0) {
					// 3 levels of distance sampling (1px, 2px, 3px)
					for (float dist = 1.0; dist <= 3.0; dist += 1.0) {
						vec2 offset = vec2(dx, dy) * (dist / 3.0) * glow_spread;
						vec2 sample_uv = uv + offset;
						float sample_alpha = 0.0;
						if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
							sample_alpha = texture(TEXTURE, sample_uv).a;
						}
						outline += sample_alpha * (1.0 - (dist - 1.0) * 0.3);
						samples++;
					}
				}
			}
		}
		outline = outline / float(samples);
		// Subtract the block itself so it's an outer glow
		float outer_glow = max(outline - tex.a, 0.0);
		
		// Boost the outer glow opacity and shape the falloff for a vibrant neon look
		float glow_boosted = pow(outer_glow, 0.8) * 3.5;
		float glow_intensity_factor = clamp(glow_boosted * current_glow, 0.0, 1.0);
		
		// Blending: mix inner texture with glow, and draw the soft outer outline
		vec3 inner_mixed = mix(base_color.rgb, glow_color.rgb * 1.8, glow_strength * 0.45);
		vec3 final_rgb = mix(inner_mixed, glow_color.rgb * 2.5, glow_intensity_factor);
		float final_alpha = max(base_color.a, glow_intensity_factor * 0.95);
		base_color = vec4(final_rgb, final_alpha);
	}
	
	// Apply pulse flash
	if (pulse_strength > 0.01) {
		float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
		float mix_amount = pulse * pulse_strength * pulse_intensity;
		vec3 final_rgb = mix(base_color.rgb, vec3(1.0), mix_amount * base_color.a);
		COLOR = vec4(final_rgb, base_color.a);
	} else {
		COLOR = base_color;
	}
}
