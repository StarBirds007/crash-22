shader_type canvas_item;

// Uniforms for customization
uniform sampler2D noise_texture : repeat_enable;

// Starting Colors (Birth)
uniform vec4 smoke_color_1 : source_color = vec4(0.5, 0.5, 0.5, 1.0); // Darker starting shade
uniform vec4 smoke_color_2 : source_color = vec4(0.9, 0.9, 0.9, 1.0); // Lighter starting shade

// Ending Colors (Death)
uniform vec4 end_color_1 : source_color = vec4(0.2, 0.2, 0.2, 0.0);   // Darker ending shade (fades out)
uniform vec4 end_color_2 : source_color = vec4(0.4, 0.4, 0.4, 0.0);   // Lighter ending shade (fades out)

uniform float distortion_speed : hint_range(0.0, 5.0) = 0.2;
uniform float density : hint_range(0.0, 1.0) = 1.0;
uniform float spread : hint_range(0.0, 1.0) = 0.4;   // Controls how far the smoke reaches
uniform float erosion : hint_range(0.0, 1.0) = 0.3;  // Controls how jagged/organic the outer edges are
uniform float pixel_size : hint_range(1.0, 64.0) = 16.0; // Controls the pixel art grid resolution
uniform float color_threshold : hint_range(0.0, 1.0) = 0.5; // Split point between the two colors

// Varying variable to pass lifetime from vertex processor to fragment processor
varying float life_percent;

void vertex() {
    // INSTANCE_CUSTOM.y automatically holds the GPUParticle lifetime ratio (0.0 to 1.0)
    life_percent = INSTANCE_CUSTOM.y;
}

void fragment() {
    // Pixelate UV coordinates to create a chunky pixel art look
    vec2 p_uv = floor(UV * pixel_size) / pixel_size;
    
    // Pre-calculate time-based offsets
    float time_offset_1 = TIME * distortion_speed * 0.1;
    float time_offset_2 = TIME * distortion_speed * 0.2;
    
    // Sample noise with distortion for the internal texture using pixelated UV
    vec4 noise = texture(noise_texture, p_uv + time_offset_1);
    
    // Create distorted UV and sample final noise
    vec2 distorted_uv = p_uv + noise.rg * 0.1 - 0.05 + time_offset_2;
    float final_noise = texture(noise_texture, distorted_uv).r;
    
    // Calculate distance from the center (0.5, 0.5) using pixelated UV
    float dist = distance(p_uv, vec2(0.5));
    
    // Sample the noise texture to erode the edges organically
    float edge_noise = texture(noise_texture, (p_uv * 0.7) + (time_offset_1 * 0.5)).r;
    
    // Modulate the distance check with the noise texture
    float organic_mask = dist + (edge_noise - 0.5) * erosion;
    
    // Create a sharp step cutoff for pixel art instead of smoothstep
    float radial_mask = step(organic_mask, spread);
    
    // Combine noise, density, and the organic erosion mask
    float smoke_alpha = final_noise * density * radial_mask;
    
    // Linearly interpolate between birth colors and death colors based on particle age
    vec4 active_color_1 = mix(smoke_color_1, end_color_1, life_percent);
    vec4 active_color_2 = mix(smoke_color_2, end_color_2, life_percent);
    
    // Posterize to two distinct shades or transparent
    vec4 final_color = vec4(0.0);
    if (smoke_alpha > 0.01) {
        if (final_noise > color_threshold) {
            final_color = active_color_2;
        } else {
            final_color = active_color_1;
        }
        // Multiply by the density/radial mask or incorporate color alpha
        final_color.a *= radial_mask;
    }
    
    // Output color
    COLOR = final_color;
}
