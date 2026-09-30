shader_type spatial;

uniform vec3 grass_dark : source_color = vec3(0.10, 0.22, 0.055);
uniform vec3 grass_mid : source_color = vec3(0.18, 0.34, 0.09);
uniform vec3 grass_light : source_color = vec3(0.30, 0.46, 0.13);

float hash(vec2 p) {
	return fract(
		sin(dot(p, vec2(127.1, 311.7))) * 43758.5453
	);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(
		mix(a, b, f.x),
		mix(c, d, f.x),
		f.y
	);
}

void fragment() {
	vec2 p = UV * 60.0;

	float large = noise(p * 0.35);
	float medium = noise(p * 1.8);
	float fine = noise(p * 7.0);

	float grass = (
		large * 0.35 +
		medium * 0.40 +
		fine * 0.25
	);

	vec3 color = mix(
		grass_dark,
		grass_mid,
		smoothstep(0.20, 0.65, grass)
	);

	color = mix(
		color,
		grass_light,
		smoothstep(0.62, 0.90, grass)
	);

	ALBEDO = color;
	ROUGHNESS = 0.95;
}