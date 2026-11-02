shader_type spatial;
render_mode cull_disabled;

uniform vec4 deep_color : source_color = vec4(0.08, 0.35, 0.48, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.22, 0.7, 0.66, 1.0);
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	float shore = min(min(length(p), length(p - vec2(80.0, 0.0))), length(p - vec2(160.0, 0.0)));
	float shallow = 1.0 - smoothstep(13.0, 26.0, shore);
	float wave = sin(p.x * 1.5 + TIME * 0.65) * sin(p.y * 1.8 - TIME * 0.4);
	float glint = smoothstep(0.85, 1.0, wave) * 0.13;
	float foam = (1.0 - smoothstep(0.06, 0.24, abs(shore - 13.0 - sin(TIME + p.x) * 0.15))) * 0.48;
	vec3 local_shallow = mix(shallow_color.rgb, vec3(0.45, 0.7, 0.82), smoothstep(125.0, 150.0, p.x));
	ALBEDO = mix(deep_color.rgb, local_shallow, shallow) + vec3(glint + foam);
	ROUGHNESS = 0.65;
	SPECULAR = 0.25;
}
