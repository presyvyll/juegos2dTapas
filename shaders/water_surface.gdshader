shader_type canvas_item;
render_mode unshaded;

uniform vec4 water_color : source_color = vec4(0.08, 0.71, 0.77, 1.0);
uniform float shimmer_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float broad_wave = sin(UV.y * 0.010 + UV.x * 0.005 + TIME * 0.58);
	float crossing_wave = sin(UV.x * 0.020 - UV.y * 0.004 - TIME * 0.92);
	float caustics = 0.0;
	if (shimmer_strength > 0.8) {
		float caustic_pattern = sin(UV.x * 0.032 + TIME * 0.32) * sin(UV.y * 0.021 - TIME * 0.47);
		caustics = smoothstep(0.56, 0.94, caustic_pattern);
	}
	float light = broad_wave * 0.018 + crossing_wave * 0.012 + caustics * 0.045;
	vec3 tint = vec3(0.025, 0.105, 0.095) * light;
	COLOR = vec4(water_color.rgb + tint, water_color.a);
}
