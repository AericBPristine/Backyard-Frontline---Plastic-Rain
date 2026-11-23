shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 point = (UV - vec2(0.5)) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0) / 0.445;
	float radius = length(point);
	vec2 p = abs(point);
	vec2 edge = max(fwidth(point), vec2(0.001));
	float mask = smoothstep(0.985, 0.997, radius);
	float hair_x = 1.0 - smoothstep(0.0026, 0.0026 + edge.x, p.x);
	float hair_y = 1.0 - smoothstep(0.0026, 0.0026 + edge.y, p.y);
	float post_x = (1.0 - smoothstep(0.013, 0.013 + edge.x, p.x)) * smoothstep(0.652, 0.660, p.y);
	float post_y = (1.0 - smoothstep(0.013, 0.013 + edge.y, p.y)) * smoothstep(0.652, 0.660, p.x);
	float marks = 0.0;
	for (int i = 1; i <= 4; i++) {
		// Layout is in lens-relative UI space, independent of the camera.
		float center = float(i) * 0.134;
		float along_x = length(vec2(p.x - center, p.y));
		float along_y = length(vec2(p.x, p.y - center));
		marks = max(marks, 1.0 - smoothstep(0.014, 0.019, min(along_x, along_y)));
	}
	float reticle = max(max(hair_x, hair_y), max(max(post_x, post_y), marks));
	float vignette = smoothstep(0.74, 0.98, radius) * 0.19;
	COLOR = vec4(vec3(0.0), max(mask, max(reticle, vignette)));
}

