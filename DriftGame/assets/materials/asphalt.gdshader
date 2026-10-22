
shader_type spatial;

// render_mode diffuse_burley, specular_schlick_ggx;
render_mode diffuse_burley, specular_disabled;

uniform float direct_light_strength : hint_range(0.0, 1.0) = 0.25;
uniform float ambient_fill : hint_range(0.0, 1.0) = 0.25;
// Base asphalt colour
uniform vec3 asphalt_color : source_color = vec3(0.40, 0.41, 0.42);

// New asphalt texture
uniform sampler2D asphalt_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

// Texture tiling
uniform float texture_scale : hint_range(0.1, 30.0) = 1.0;

// Blend between the original shader and textured asphalt
uniform float texture_strength : hint_range(0.0, 1.0) = 1.0;

// Existing noise texture
uniform sampler2D asphalt_noise : filter_nearest, repeat_enable;

uniform float grain_strength : hint_range(0.0, 0.2) = 0.025;


void fragment() {
	// Original asphalt colour
	vec3 base_color = asphalt_color;

	// Sample asphalt texture
	vec2 asphalt_uv = UV * texture_scale;

	// First texture sample
	vec3 texture_a = texture(asphalt_texture, asphalt_uv).rgb;

	// Second sample, rotated and offset to break up repetition
	vec2 rotated_uv = vec2(
		asphalt_uv.y,
		-asphalt_uv.x
	) + vec2(0.37, 0.61);

	vec3 texture_b = texture(asphalt_texture, rotated_uv).rgb;

	// Blend both samples
	vec3 texture_color = mix(texture_a, texture_b, 0.5);

	// Blend original colour with texture
	vec3 asphalt = mix(
		base_color,
		texture_color * asphalt_color * 2.0,
		texture_strength
	);

	// Existing broad noise variation
	float broad_noise = texture(
		asphalt_noise,
		UV
	).r;

	float broad_variation = (
		broad_noise - 0.5
	) * 0.025;

	// Fine grain
	vec2 grain_position_a = floor(
		UV * vec2(1700.0, 1137.0)
	);

	vec2 grain_position_b = floor(
		UV.yx * vec2(913.0, 1421.0)
	);

	float grain_a = fract(
		sin(dot(grain_position_a, vec2(12.9898, 78.233)))
		* 43758.5453
	);

	float grain_b = fract(
		sin(dot(grain_position_b, vec2(39.3467, 11.1351)))
		* 24634.6345
	);

	float fine_grain = grain_a * 0.65 + grain_b * 0.35;

	float fine_variation = (
		fine_grain - 0.5
	) * grain_strength;

	float variation = broad_variation + fine_variation;

	vec3 final_asphalt = asphalt + vec3(variation);

	ALBEDO = final_asphalt;
	EMISSION = final_asphalt * ambient_fill;

	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
