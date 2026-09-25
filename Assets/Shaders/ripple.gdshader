shader_type canvas_item;

// Set this to your game's canvas target size (e.g., 64.0, 128.0, 256.0)
uniform float base_resolution : hint_range(16.0, 512.0, 1.0) = 128.0;

// Controls the pixel art grid size directly from the inspector
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 4.0;

// Uniforms for the two solid water colors (no background color, fully opaque puddle)
uniform sampler2D noise_texture : hint_default_black, repeat_enable;
uniform vec4 outer_water_color : source_color = vec4(0.1, 0.3, 0.5, 1.0); // Outer shade
uniform vec4 inner_water_color : source_color = vec4(0.2, 0.5, 0.8, 1.0); // Inner shade

// Controls to look and hollow center of the puddle
uniform float irregularity : hint_range(0.0, 1.0) = 0.35; // How ragged the outer edge is
uniform float base_inner_radius : hint_range(0.0, 0.7) = 0.1; // Starting hole size

// Passes particle lifetime progress from vertex to fragment function
varying float particle_lifetime_progress;

void vertex() {
	// INSTANCE_CUSTOM.y tracks particle lifetime progress from 0.0 (spawn) to 1.0 (death)
	particle_lifetime_progress = INSTANCE_CUSTOM.y;
}

void fragment() {
	// Use a fixed resolution grid instead of textureSize to guarantee visibility
	float grid_scale = base_resolution / pixel_size;
	vec2 pixel_uv = floor(UV * grid_scale) / grid_scale;
	
	// Center the pixelated UV coordinates (-0.5 to 0.5)
	vec2 centered_uv = pixel_uv - vec2(0.5);
	float dist = length(centered_uv) * 2.0; // Distance from center (0 to 1)
	
	// Sample noise using pixelated angles and distance
	float angle = atan(centered_uv.y, centered_uv.x);
	vec2 noise_uv = vec2(angle / 6.28318 + 0.5, dist);
	float noise_val = texture(noise_texture, noise_uv).r;
	
	// Displace the effective outer radius dynamically using the noise
	float outer_radius = 1.0 - (noise_val * irregularity);
	
	// 1. Outer edge mask: completely sharp pixel art threshold
	float outer_mask = step(dist, outer_radius);
	
	// 2. Expand inner radius over particle lifetime
	float dynamic_inner_radius = mix(base_inner_radius, 1.2, particle_lifetime_progress);
	float inner_masked_radius = dynamic_inner_radius + (noise_val * 0.1); 
	
	// Inner edge mask: sharp center cutout
	float inner_mask = step(inner_masked_radius, dist);
	
	// Combine masks to isolate the ring body
	float puddle_mask = outer_mask * inner_mask;
	
	// Determine the transition point between inner and outer shades inside the ring
	float mid_radius = mix(inner_masked_radius, outer_radius, 0.5);
	float shade_transition = step(mid_radius, dist);
	
	// Blend between inner and outer water colors based on distance from center
	vec4 selected_water_color = mix(inner_water_color, outer_water_color, shade_transition);
	
	// Output color using the puddle mask for transparency outside the shape
	COLOR = selected_water_color;
	COLOR.a *= puddle_mask;
}