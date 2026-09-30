shader_type spatial;

render_mode diffuse_burley, specular_schlick_ggx;

uniform vec3 asphalt_color : source_color = vec3(
	0.40,
	0.41,
	0.42
);

uniform sampler2D asphalt_noise : filter_nearest;

uniform float grain_strength : hint_range(0.0, 0.2) = 0.06;


void fragment() {
	// ------------------------------------------------------------
	// BROAD ASPHALT VARIATION
	// ------------------------------------------------------------

	float broad_noise = texture(
		asphalt_noise,
		UV
	).r;

	float broad_variation = (
		broad_noise - 0.5
	) * 0.025;


	// ------------------------------------------------------------
	// FINE ASPHALT GRAIN
	// ------------------------------------------------------------

	// High-frequency random grain generated directly from UV.
// ------------------------------------------------------------
// FINE ASPHALT GRAIN
// ------------------------------------------------------------

// Two differently-scaled grain patterns.
// Combining them breaks up visible directional/grid patterns.

vec2 grain_position_a = floor(
	UV * vec2(1700.0, 1137.0)
);

vec2 grain_position_b = floor(
	UV.yx * vec2(913.0, 1421.0)
);


float grain_a = fract(
	sin(
		dot(
			grain_position_a,
			vec2(12.9898, 78.233)
		)
	) * 43758.5453
);


float grain_b = fract(
	sin(
		dot(
			grain_position_b,
			vec2(39.3467, 11.1351)
		)
	) * 24634.6345
);


float fine_grain = (
	grain_a * 0.65
	+ grain_b * 0.35
);


float fine_variation = (
	fine_grain - 0.5
) * 0.055;


	// ------------------------------------------------------------
	// FINAL ASPHALT
	// ------------------------------------------------------------

	float variation = (
		broad_variation
		+ fine_variation
	);

	ALBEDO = asphalt_color + vec3(
		variation
	);

	ROUGHNESS = 0.92;
	METALLIC = 0.0;
}