shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 inner_color : source_color = vec4(1.0, 0.72, 0.2, 1.0);
uniform vec4 outer_color : source_color = vec4(0.45, 0.14, 0.03, 1.0);
uniform float opacity = 1.0;
uniform float variation = 0.0;
uniform bool white_flash = false;

float hash21(vec2 p) {
	vec3 b = fract(vec3(p.xyx) * 0.1031);
	b += dot(b, b.yzx + 33.33);
	return fract((b.x + b.y) * b.z);
}

float noise2(vec2 at) {
	vec2 cell = floor(at);
	vec2 f = fract(at);
	vec2 t = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(cell), hash21(cell + vec2(1, 0)), t.x),
		mix(hash21(cell + vec2(0, 1)), hash21(cell + vec2(1, 1)), t.x), t.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float broad = noise2(p * 3.3 + variation);
	float small = noise2(p * 9.5 + variation * 0.73);
	float cloud = broad * 0.69 + small * 0.31;
	float edge = 1.0 - smoothstep(0.53, 1.0, length(p) + (cloud - 0.5) * 0.45);
	float center = smoothstep(0.24, 0.81, 1.0 - length(p) * 0.76 + (cloud - 0.5) * 0.47);
	ALBEDO = mix(outer_color.rgb, inner_color.rgb, center);
	ALPHA = edge * opacity * mix(0.54, 1.0, cloud);
	if (white_flash) {
		float core = 1.0 - smoothstep(0.36, 0.71, length(p) + (cloud - 0.5) * 0.17);
		ALPHA = max(ALPHA, core * opacity);
		EMISSION = vec3(core * opacity * 1.5);
	}
}

