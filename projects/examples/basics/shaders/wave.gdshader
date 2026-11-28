shader_type canvas_item;

uniform float amplitude = 0.03;
uniform float frequency = 12.0;
uniform float speed = 4.0;

void fragment() {
	vec2 uv = UV;
	uv.x += sin(TIME * speed + UV.y * frequency) * amplitude;
	COLOR = texture(TEXTURE, uv);
}
