shader_type canvas_item;

uniform float fov : hint_range(1.0, 179.0) = 90.0;
uniform float x_rot : hint_range(-90.0, 90.0) = 0.0;
uniform float y_rot : hint_range(-90.0, 90.0) = 0.0;

varying flat vec2 shift;
varying vec3 ray;

void vertex() {
	float sin_y = sin(radians(y_rot));
	float cos_y = cos(radians(y_rot));
	float sin_x = sin(radians(x_rot));
	float cos_x = cos(radians(x_rot));
	mat3 rotation = mat3(
		vec3(cos_y, 0.0, -sin_y),
		vec3(sin_y * sin_x, cos_x, cos_y * sin_x),
		vec3(sin_y * cos_x, -sin_x, cos_y * cos_x)
	);
	float spread = tan(radians(fov) / 2.0);
	ray = rotation * vec3(UV - 0.5, 0.5 / spread);
	float depth = 0.5 / spread + 0.5;
	ray.xy *= depth * rotation[2].z;
	shift = depth * rotation[2].xy;
	VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * spread;
}

void fragment() {
	if (ray.z <= 0.0) {
		discard;
	}
	vec2 uv = ray.xy / ray.z - shift;
	COLOR = texture(TEXTURE, uv + 0.5);
	COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);
}
