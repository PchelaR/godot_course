shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burn_color : source_color = vec4(0.91, 0.333, 0.184, 1.0);
uniform float burn_width = 0.08;
uniform float pixels = 32.0;

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
	float pattern = fbm(uv * 6.0);
	float threshold = progress * 1.2 - 0.1;
	if (pattern < threshold) {
		COLOR.a = 0.0;
	} else if (pattern < threshold + burn_width) {
		COLOR = burn_color;
	}
}
