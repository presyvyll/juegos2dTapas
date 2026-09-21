shader_type canvas_item;
render_mode unshaded;

uniform vec4 flash_color : source_color = vec4(1.0, 0.96, 0.82, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 source = COLOR;
	source.rgb = mix(source.rgb, flash_color.rgb, flash_amount);
	COLOR = source;
}
