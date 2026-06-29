shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 4.0;
uniform vec4 tint_color : source_color = vec4(0.09, 0.06, 0.20, 1.0); // Cosmic purple tint
uniform float tint_factor : hint_range(0.0, 1.0) = 0.65;
uniform float brightness : hint_range(0.0, 2.0) = 0.6;
uniform float contrast : hint_range(0.0, 2.0) = 0.8;

void fragment() {
    vec2 uv = UV;
    vec4 col = vec4(0.0);
    float total_weight = 0.0;
    
    // Sample textures with a simple Gaussian-like distribution
    // 5x5 sample grid
    vec2 size = vec2(textureSize(TEXTURE, 0));
    float step_x = blur_amount / size.x;
    float step_y = blur_amount / size.y;
    
    for (float x = -2.0; x <= 2.0; x += 1.0) {
        for (float y = -2.0; y <= 2.0; y += 1.0) {
            // Weight decreases as we get further from center
            float weight = 1.0 - (abs(x) + abs(y)) * 0.2;
            if (weight > 0.0) {
                vec2 offset = vec2(x * step_x, y * step_y);
                col += texture(TEXTURE, uv + offset) * weight;
                total_weight += weight;
            }
        }
    }
    
    if (total_weight > 0.0) {
        col /= total_weight;
    } else {
        col = texture(TEXTURE, uv);
    }
    
    // Blend the original blurred color with the silhouette tint color
    vec3 blended = mix(col.rgb, tint_color.rgb, tint_factor);
    
    // Apply contrast
    blended = (blended - 0.5) * contrast + 0.5;
    
    // Apply brightness
    blended *= brightness;
    
    COLOR = vec4(blended, col.a);
}
