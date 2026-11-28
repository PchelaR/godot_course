shader_type canvas_item;

uniform vec4 core_color : source_color = vec4(0.992, 0.957, 0.89, 1.0);
uniform vec4 flame_color : source_color = vec4(0.91, 0.333, 0.184, 1.0);
uniform vec4 edge_color : source_color = vec4(0.169, 0.129, 0.11, 1.0);
uniform float speed = 1.6;
uniform float pixels = 40.0;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	vec2 blend = local * local * (3.0 - 2.0 * local);
	float bottom = mix(hash(cell), hash(cell + vec2(1.0, 0.0)), blend.x);
	float top = mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), blend.x);
	return mix(bottom, top, blend.y);
}

float fbm(vec2 point) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < 5; octave++) {
		value += amplitude * noise(point);
		point *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = floor(UV * pixels) / pixels;
	float width = abs(uv.x - 0.5) * 2.0;
	float detail = fbm(vec2(uv.x * 4.0, uv.y * 3.0 + TIME * speed));
	float taper = 0.9 + 0.6 * (1.0 - uv.y);
	float heat = uv.y + 0.3 - width * taper + (detail - 0.5) * (0.6 + (1.0 - uv.y));
	if (heat > 0.9) {
		COLOR = core_color;
	} else if (heat > 0.5) {
		COLOR = flame_color;
	} else if (heat > 0.4) {
		COLOR = edge_color;
	} else {
		COLOR = vec4(0.0);
	}
}
