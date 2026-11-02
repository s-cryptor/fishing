shader_type spatial;
render_mode cull_disabled;

uniform vec4 deep_color : source_color = vec4(0.18, 0.37, 0.41, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.43, 0.64, 0.6, 1.0);
varying vec3 world_position;
uniform vec3 shore_waves = vec3(0.9, 0.38, 0.3);
uniform vec3 shore_cove = vec3(0.35, 0.34, 2.8);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float radius_at(float angle) {
	float cove_angle = atan(sin(angle - shore_cove.x), cos(angle - shore_cove.x));
	float distance_to_cove = cove_angle / shore_cove.y;
	float cove = exp(-distance_to_cove * distance_to_cove) * shore_cove.z;
	return 12.8 + sin(angle * 3.0 + 0.4) * shore_waves.x + sin(angle * 5.0 - 0.7) * shore_waves.y + cos(angle * 2.0) * shore_waves.z - cove;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	vec2 relative = p;
	if (length(p - vec2(80.0, 0.0)) < length(relative)) { relative = p - vec2(80.0, 0.0); }
	if (length(p - vec2(160.0, 0.0)) < length(relative)) { relative = p - vec2(160.0, 0.0); }
	float shore = length(relative) - radius_at(atan(relative.y, relative.x));
	float shallow = 1.0 - smoothstep(0.0, 11.0, shore);
	float broad = noise(p * 0.18 + vec2(TIME * 0.015, 0.0));
	float wave = sin(p.y * 3.5 + p.x * 0.32 + sin(p.x * 0.5) * 0.5 - TIME * 0.55);
	float glint = smoothstep(0.97, 1.0, wave) * smoothstep(0.6, 0.85, noise(p * vec2(0.8, 0.4) + TIME * 0.025)) * 0.065;
	float foam_band = abs(shore - 0.4 - sin(TIME * 0.7 + broad * 4.0) * 0.16);
	float foam = (1.0 - smoothstep(0.025, 0.11, foam_band)) * (0.16 + broad * 0.24);
	float wash = (1.0 - smoothstep(0.1, 0.8, foam_band)) * 0.035;
	vec3 local_shallow = mix(shallow_color.rgb, vec3(0.48, 0.65, 0.7), smoothstep(125.0, 150.0, p.x));
	ALBEDO = mix(deep_color.rgb, local_shallow, shallow * 0.8) + vec3((broad - 0.5) * 0.045 + glint + wash) + foam * vec3(0.45, 0.47, 0.4);
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
}
