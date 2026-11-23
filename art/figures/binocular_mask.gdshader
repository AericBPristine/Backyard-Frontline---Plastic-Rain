shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 point = (UV - vec2(0.5, 0.5)) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float distance_to_center = length(point);
	float housing = smoothstep(0.439, 0.443, distance_to_center);
	float edge = smoothstep(0.401, 0.439, distance_to_center);
	float rim = smoothstep(0.426, 0.435, distance_to_center) * (1.0 - smoothstep(0.438, 0.443, distance_to_center));
	vec3 shade = mix(vec3(0.015, 0.025, 0.021), vec3(0.25, 0.29, 0.21), rim * 0.62);
	COLOR = vec4(shade, mix(edge * 0.75, 1.0, housing));
}
