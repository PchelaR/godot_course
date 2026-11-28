shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.0;
uniform float thickness = 0.08;
uniform float strength = 0.05;
uniform float aspect = 1.7778;

void fragment() {
	vec2 offset = UV - center;
	offset.x *= aspect;
	float distance_to_center = length(offset);
	float ring = smoothstep(radius - thickness, radius, distance_to_center);
	ring *= 1.0 - smoothstep(radius, radius + thickness, distance_to_center);
	vec2 direction = offset / max(distance_to_center, 0.0001);
	direction.x /= aspect;
	vec2 shift = direction * ring * strength * (1.0 - radius);
	COLOR = texture(screen_texture, SCREEN_UV - shift);
}
