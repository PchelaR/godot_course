shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 frame_color : source_color = vec4(0.169, 0.129, 0.11, 1.0);
uniform float curvature = 4.0;
uniform float scanlines = 216.0;
uniform float scanline_strength = 0.3;
uniform float aberration = 0.003;
uniform float vignette = 0.35;

void fragment() {
	vec2 uv = SCREEN_UV * 2.0 - 1.0;
	vec2 bend = uv.yx / curvature;
	uv = (uv + uv * bend * bend) * 0.5 + 0.5;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = frame_color;
	} else {
		float red = texture(screen_texture, uv + vec2(aberration, 0.0)).r;
		float green = texture(screen_texture, uv).g;
		float blue = texture(screen_texture, uv - vec2(aberration, 0.0)).b;
		vec3 color = vec3(red, green, blue);
		float line = sin(uv.y * scanlines * PI) * 0.5 + 0.5;
		color *= 1.0 - scanline_strength * line;
		vec2 edge = uv * (1.0 - uv.yx);
		color *= pow(clamp(edge.x * edge.y * 16.0, 0.0, 1.0), vignette);
		COLOR = vec4(color, 1.0);
	}
}
