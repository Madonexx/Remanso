shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.46, 0.34, 0.21, 0.94);
uniform vec4 deep_color : source_color = vec4(0.28, 0.19, 0.11, 0.98);
uniform vec4 foam_color : source_color = vec4(0.76, 0.66, 0.50, 1.0);
uniform float wave_speed : hint_range(0.1, 4.0) = 1.15;
uniform float wave_height : hint_range(0.0, 1.0) = 0.14;
uniform float wake_turbulence : hint_range(0.0, 2.0) = 0.0;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.22;

varying vec3 world_pos;
varying float wave_crest;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * wave_speed;
	float w1 = sin(world_pos.x * 0.35 + t * 1.3) * cos(world_pos.z * 0.28 + t * 0.9);
	float w2 = sin((world_pos.x * 0.6 - world_pos.z * 0.5) + t * 1.9) * 0.5;
	float wake = sin(world_pos.x * 1.1 - t * 4.2) * wake_turbulence * 0.35;
	float total_wave = (w1 + w2) * wave_height + wake;
	VERTEX.y += total_wave;
	wave_crest = clamp((w1 + w2) * 0.5 + 0.5 + wake_turbulence * 0.3, 0.0, 1.0);
}

void fragment() {
	float t = TIME * wave_speed * 0.4;
	vec2 uv1 = world_pos.xz * 0.18 + vec2(t * 0.4, -t * 0.7);
	vec2 uv2 = world_pos.xz * 0.37 + vec2(-t * 0.3, t * 0.5);
	float n1 = value_noise(uv1);
	float n2 = value_noise(uv2);
	float sediment = clamp(n1 * 0.6 + n2 * 0.4, 0.0, 1.0);

	vec3 base_col = mix(deep_color.rgb, shallow_color.rgb, sediment * 0.75 + wave_crest * 0.25);
	float foam_mask = smoothstep(0.76 - wake_turbulence * 0.15, 0.86, sediment * 0.6 + wave_crest * 0.5);
	ALBEDO = mix(base_col, foam_color.rgb, foam_mask * 0.45);

	vec3 n_offset = normalize(vec3((n1 - 0.5) * 0.28, 1.0, (n2 - 0.5) * 0.28));
	NORMAL = normalize(mix(NORMAL, n_offset, 0.35));
	ROUGHNESS = mix(roughness_val, 0.65, foam_mask);
	METALLIC = 0.08;
	SPECULAR = 0.55;
}
