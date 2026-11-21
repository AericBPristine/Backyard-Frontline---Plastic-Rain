shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 point = (UV - vec2(0.5, 0.48)) * vec2(16.0 / 9.0, 1.0);
	float distance_to_center = min(length(point - vec2(0.22, 0.0)), length(point + vec2(0.22, 0.0)));
	float housing = smoothstep(0.366, 0.369, distance_to_center);
	float edge = smoothstep(0.335, 0.366, distance_to_center);
	float rim = smoothstep(0.354, 0.359, distance_to_center) * (1.0 - smoothstep(0.362, 0.367, distance_to_center));
	vec3 shade = mix(vec3(0.015, 0.025, 0.021), vec3(0.25, 0.29, 0.21), rim * 0.62);
	COLOR = vec4(shade, mix(edge * 0.75, 1.0, housing));
}
