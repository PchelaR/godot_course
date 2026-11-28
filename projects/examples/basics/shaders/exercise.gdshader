shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(color.rgb, vec3(gray), strength), color.a);
}
