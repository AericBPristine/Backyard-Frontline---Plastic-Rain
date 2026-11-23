shader_type sky;

uniform sampler2D weather_noise : filter_linear_mipmap, repeat_enable;
uniform vec3 horizon : source_color = vec3(0.57, 0.62, 0.63);
uniform vec3 high_cloud : source_color = vec3(0.39, 0.43, 0.46);
uniform vec3 cloud_shadow : source_color = vec3(0.20, 0.24, 0.28);

void sky() {
	float altitude = max(0.0, EYEDIR.y);
	vec2 plane = EYEDIR.xz / (0.24 + altitude);
	vec2 patch = plane * vec2(0.26, 0.19) + vec2(0.22, 0.38);
	float clouds = texture(weather_noise, patch).r * 0.68;
	clouds += texture(weather_noise, patch * 2.08 + vec2(0.71, 0.13)).r * 0.26;
	clouds += texture(weather_noise, patch * 4.30 + vec2(0.27, 0.81)).r * 0.06;
	vec3 cloud = mix(cloud_shadow, high_cloud, smoothstep(0.23, 0.79, clouds));
	float bank = smoothstep(-0.025, 0.44, EYEDIR.y);
	float break_light = 0.09 * pow(max(0.0, dot(EYEDIR, normalize(vec3(-0.64, 0.12, -0.74)))), 12.0);
	COLOR = mix(horizon, cloud, bank * 0.93) + break_light * vec3(0.72, 0.77, 0.80);
}

