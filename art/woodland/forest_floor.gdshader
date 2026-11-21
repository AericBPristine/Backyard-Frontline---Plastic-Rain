shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D mottling : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 moss : source_color = vec3(0.286, 0.365, 0.188);
uniform vec3 grass : source_color = vec3(0.344, 0.423, 0.235);
uniform vec3 earth : source_color = vec3(0.259, 0.233, 0.157);
uniform vec3 grit : source_color = vec3(0.494, 0.458, 0.335);
uniform vec3 track_earth : source_color = vec3(0.402, 0.351, 0.252);
uniform vec2 track_center = vec2(-5.0, -296.0);
uniform float track_half_length = 176.5;
uniform float track_half_width = 2.75;
uniform bool crater_surface = false;
uniform int crater_count = 0;
uniform vec3 crater_cutouts[24];

varying vec2 ground_position;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ground_position = world.xz;
}

void fragment() {
	vec2 p = ground_position;
	vec2 from_impact = (UV - vec2(0.5)) * 3.7;
	float crater_radius = length(from_impact);
	if (crater_surface) {
		if (crater_radius > 1.85) {
			discard;
		}
	} else {
		for (int i = 0; i < crater_count; i++) {
			vec2 offset = p - crater_cutouts[i].xy;
			if (dot(offset, offset) < crater_cutouts[i].z * crater_cutouts[i].z) {
				discard;
			}
		}
	}
	float broad = texture(mottling, p * 0.013 + vec2(0.15, 0.37)).r;
	float broken = texture(mottling, p * 0.075).r;
	vec2 track = p - track_center;
	float track_edge = abs(track.x + track.y * 0.035 + (broken - 0.5) * 2.3);
	float wear = (1.0 - smoothstep(track_half_width - 0.8, track_half_width + 0.65, track_edge));
	wear *= 1.0 - smoothstep(track_half_length - 5.0, track_half_length, abs(track.y));
	float patches = broad * 0.67 + broken * 0.33;
	vec3 green = mix(moss, grass, smoothstep(0.28, 0.73, patches));
	float soil_amount = 1.0 - smoothstep(0.37, 0.58, patches);
	float clearing = 1.0 - smoothstep(3.6, 8.0, length((p - vec2(1.0, -1.8)) * vec2(1.0, 0.86)) + (broken - 0.5) * 3.5);
	soil_amount = max(soil_amount, clearing * 0.82);
	vec3 ground = mix(mix(green, earth, soil_amount * 0.88), track_earth, wear * 0.92);

	float distance_to_camera = distance(p, CAMERA_POSITION_WORLD.xz);
	float detail_fade = 1.0 - smoothstep(32.0, 105.0, distance_to_camera);
	float grain = texture(mottling, p * 1.75 + vec2(0.41, 0.27)).r;
	float gravel = smoothstep(0.67, 0.79, grain) * smoothstep(0.28, 0.51, broken);
	ground *= mix(1.0, 0.76 + 0.48 * grain, detail_fade);
	ground = mix(ground, grit, gravel * detail_fade * mix(0.25, 0.66, wear));
	if (crater_surface) {
		vec2 center = p - from_impact * 1.75;
		float angle = atan(from_impact.y + 0.00001, from_impact.x);
		float outline = 0.76 + sin(angle * 3.0 + center.x) * 0.12 + cos(angle * 5.0 + center.y) * 0.09;
		float torn = 1.0 - smoothstep(outline - 0.23, outline + 0.28, crater_radius + (grain - 0.5) * 0.21);
		vec3 disturbed = earth * mix(0.72, 1.18, smoothstep(0.06, outline, crater_radius));
		disturbed *= 0.82 + grain * 0.38;
		ground = mix(ground, disturbed, torn);
		float spokes = (angle + 3.14159) * 1.91;
		float lane = floor(spokes);
		float bias = fract(sin(lane * 18.17 + center.x * 0.53 + center.y * 0.77) * 437.6);
		float scratch_x = abs(fract(spokes) - mix(0.24, 0.76, bias) + (broken - 0.5) * 0.15);
		float streak = (1.0 - smoothstep(0.017, mix(0.085, 0.23, bias), scratch_x));
		float tail = mix(1.08, 1.81, bias);
		streak *= smoothstep(0.34, 0.61, crater_radius) * (1.0 - smoothstep(tail - 0.33, tail, crater_radius));
		streak *= smoothstep(0.27, 0.59, grain);
		ground = mix(ground, earth * (0.64 + grain * 0.37), streak * 0.85);
	}

	float aerial = smoothstep(12.0, 95.0, CAMERA_POSITION_WORLD.y);
	ALBEDO = ground * mix(0.77, 0.54, aerial);
	ROUGHNESS = 0.97;
}

