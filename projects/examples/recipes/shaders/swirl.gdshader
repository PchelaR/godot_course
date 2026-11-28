shader_type canvas_item;

uniform vec4 first_color : source_color = vec4(0.91, 0.333, 0.184, 1.0);
uniform vec4 second_color : source_color = vec4(0.784, 0.651, 0.863, 1.0);
uniform vec4 third_color : source_color = vec4(0.169, 0.129, 0.11, 1.0);
uniform float spin = 3.0;
uniform float speed = 0.25;
uniform float pixels = 120.0;
uniform float aspect = 1.7778;

void fragment() {
	vec2 grid = vec2(pixels * aspect, pixels);
	vec2 uv = floor(UV * grid) / grid;
	vec2 point = (uv - 0.5) * vec2(aspect, 1.0);
	float radius = length(point);
	float angle = atan(point.y, point.x) + spin * radius - TIME * speed;
	point = radius * vec2(cos(angle), sin(angle)) * 4.0;
	for (int step_index = 0; step_index < 5; step_index++) {
		point += vec2(sin(point.y * 1.3 + TIME * 0.4), cos(point.x * 1.1 - TIME * 0.3)) * 0.6;
	}
	float bands = sin(point.x) * 0.5 + 0.5;
	float stripes = sin(point.y) * 0.5 + 0.5;
	vec4 color = mix(first_color, second_color, smoothstep(0.35, 0.65, bands));
	COLOR = mix(color, third_color, smoothstep(0.6, 0.85, stripes) * 0.85);
}
