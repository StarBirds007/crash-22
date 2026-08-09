shader_type canvas_item;
render_mode blend_mix;

// --- 3-Layer Color Depth ---
uniform vec4 foam_color_base : source_color = vec4(0.3, 0.7, 0.9, 0.9);   // Darkest/Base depth
uniform vec4 foam_color_mid  : source_color = vec4(0.65, 0.88, 0.98, 0.95); // Midtone depth
uniform vec4 foam_color_high : source_color = vec4(1.0, 1.0, 1.0, 1.0);    // Top highlight (white)

// --- Noise & Motion ---
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec2 noise_scale = vec2(3.0, 1.0);
uniform float flow_speed : hint_range(0.0, 1000.0) = 3.0;

// --- Foam Tuning ---
uniform float foam_thickness : hint_range(0.01, 0.5) = 0.25;

// --- Taper & Expansion Controls ---
uniform float min_start_width : hint_range(0.05, 0.6) = 0.15; // Width multiplier right at plane head (0.0 to 1.0)
uniform float expansion_rate  : hint_range(0.5, 3.0)  = 1.5;  // How quickly the trail spreads out

// --- Natural Erosion / Dissolve Settings ---
uniform float tail_erosion_start : hint_range(0.2, 1.0) = 0.55;

// --- Resolution / Pixelation ---
uniform float pixel_resolution : hint_range(8.0, 256.0) = 64.0;
uniform bool pixelate = false;

void fragment() {
    vec2 uv = UV;
    if (pixelate) {
        uv = floor(uv * pixel_resolution) / pixel_resolution;
    }

    // 1. Scroll noise texture along the trail
    vec2 animated_uv = (uv * noise_scale) - vec2(TIME * flow_speed * 0.2, 0.0);
    float noise = texture(noise_texture, animated_uv).r;

    // 2. Center-to-edge distance (0.0 in center, 1.0 at outer boundaries)
    float dist_from_center = abs(uv.y - 0.5) * 2.0;

    // 3. Progressive V-Shape Width Expansion
    // At UV.x = 0.0 (Plane Head), trail width is narrow (min_start_width).
    // As UV.x increases toward 1.0 (Tail), the trail expands outward.
    float width_expansion = mix(min_start_width, 1.0, clamp(pow(uv.x, 1.0 / expansion_rate), 0.0, 1.0));

    // Normalize distance relative to expanding width profile
    float expanded_dist = dist_from_center / max(width_expansion, 0.01);

    // Wobbly wave distortion applied to expanded boundary
    float distorted_edge = expanded_dist + (noise - 0.5) * 0.25;

    // Outer boundary mask
    float outer_mask = step(distorted_edge, 1.0);

    // 4. Hollow Outer Foam Tracks
    float foam_outer_edge = 1.0 - foam_thickness;
    float main_foam_mask = step(foam_outer_edge, distorted_edge) * outer_mask;

    // 5. Foam Erosion at Tail End (UV.x = 1.0)
    float tail_factor = 1.0 - uv.x;
    float erosion_factor = smoothstep(0.0, 1.0 - tail_erosion_start, tail_factor);

    // Noise threshold punches holes near tail tip
    float dissolve_mask = step(1.0 - erosion_factor, noise * 1.2);

    // Combine foam with noise dissolve mask
    float final_foam_shape = main_foam_mask * dissolve_mask;

    // Discard empty pixels
    if (final_foam_shape < 0.01) {
        discard;
    }

    // 6. 3-Layer Color Depth Shading
    float depth_factor = clamp(noise * 0.5 + (distorted_edge - foam_outer_edge) / foam_thickness * 0.5, 0.0, 1.0);
    depth_factor *= erosion_factor; // Fade top white highlights first near tail tip

    vec4 final_color;
    if (depth_factor < 0.35) {
        final_color = foam_color_base;
    } else if (depth_factor < 0.7) {
        final_color = foam_color_mid;
    } else {
        final_color = foam_color_high;
    }

    COLOR = final_color;
}