// Hey this is Hei! This shader "fakes" a 3D-camera perspective on CanvasItems.
// Modified to support Sprite Sheets (Texture Atlases) for AnimatedSprite2D.
// Extended to support palette swapping based on source and replacement textures.
// License: MIT
shader_type canvas_item;

// --- SPRITE SHEET UNIFORMS ---
uniform int columns : hint_range(1, 64) = 1;
uniform int rows : hint_range(1, 64) = 1;
uniform int frame : hint_range(0, 4096) = 0;

// Camera FOV
uniform float fov : hint_range(1, 179) = 45;
uniform bool cull_back = true;
uniform float y_rot : hint_range(-180, 180) = 0.0;
uniform float x_rot : hint_range(-180, 180) = 0.0;
uniform float z_rot : hint_range(-180, 180) = 0.0;

// At 0, the image retains its size when unrotated.
// At 1, the image is resized so that it can do a full
// rotation without clipping inside its rect.
uniform float inset : hint_range(0, 1) = 0.0;

// --- PALETTE SWAP UNIFORMS ---
uniform sampler2D original_palette : filter_nearest;
uniform sampler2D target_palette : filter_nearest;
uniform float precision : hint_range(0.001, 0.1) = 0.01;

varying flat vec2 o;
varying vec3 p;
varying vec2 frame_uv_offset;
varying vec2 frame_uv_size;

void vertex(){
	// 1. Calculate the size and position of the current frame inside the sheet
	frame_uv_size = vec2(1.0 / float(columns), 1.0 / float(rows));

	float frame_x = float(frame % columns);
	float frame_y = float(frame / columns);
	frame_uv_offset = vec2(frame_x, frame_y) * frame_uv_size;

	// 2. Normalize the local UV to a 0.0 - 1.0 range for just this frame
	vec2 local_uv = (UV - frame_uv_offset) / frame_uv_size;

	float sin_b = sin(y_rot / 180.0 * PI);
	float cos_b = cos(y_rot / 180.0 * PI);
	float sin_c = sin(x_rot / 180.0 * PI);
	float cos_c = cos(x_rot / 180.0 * PI);

	mat3 inv_rot_mat;
	inv_rot_mat[0][0] = cos_b;
	inv_rot_mat[0][1] = 0.0;
	inv_rot_mat[0][2] = -sin_b;

	inv_rot_mat[1][0] = sin_b * sin_c;
	inv_rot_mat[1][1] = cos_c;
	inv_rot_mat[1][2] = cos_b * sin_c;

	inv_rot_mat[2][0] = sin_b * cos_c;
	inv_rot_mat[2][1] = -sin_c;
	inv_rot_mat[2][2] = cos_b * cos_c;

	float t = tan(fov / 360.0 * PI);

	// Use local_uv instead of global UV
	p = inv_rot_mat * vec3((local_uv - 0.5), 0.5 / t);
	float v = (0.5 / t) + 0.5;
	p.xy *= v * inv_rot_mat[2].z;
	o = v * inv_rot_mat[2].xy;

	VERTEX += (local_uv - 0.5) / (TEXTURE_PIXEL_SIZE / frame_uv_size) * t * (1.0 - inset);
}

void fragment(){
	if (cull_back && p.z <= 0.0) discard;
	vec2 uv = (p.xy / p.z).xy - o;

	float sin_a = sin(z_rot / 180.0 * PI);
	float cos_a = cos(z_rot / 180.0 * PI);
	mat2 rot_z = mat2(vec2(cos_a, sin_a), vec2(-sin_a, cos_a));
	uv = rot_z * uv;

	// Check local bounds to crop pixels bleeding outside the frame boundaries
	if (max(abs(uv.x), abs(uv.y)) > 0.5) {
		discard;
	}

	// Convert the 3D-adjusted local UV back into the global atlas UV space
	vec2 final_uv = frame_uv_offset + (uv + 0.5) * frame_uv_size;

	vec4 tex_color = texture(TEXTURE, final_uv);

	// --- PALETTE SWAP LOGIC ---
	ivec2 pal_size = textureSize(original_palette, 0);
	vec4 final_color = tex_color;

	for (int y = 0; y < pal_size.y; y++) {
		for (int x = 0; x < pal_size.x; x++) {
			vec2 pal_uv = (vec2(float(x), float(y)) + 0.5) / vec2(pal_size);
			vec4 orig_color = texture(original_palette, pal_uv);

			if (distance(tex_color.rgb, orig_color.rgb) < precision) {
				vec4 target_color = texture(target_palette, pal_uv);
				final_color = vec4(target_color.rgb, tex_color.a * target_color.a);
				x = pal_size.x;
				y = pal_size.y;
			}
		}
	}

	COLOR = final_color;
}