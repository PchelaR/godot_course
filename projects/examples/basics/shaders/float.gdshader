shader_type canvas_item;

uniform float height = 12.0;
uniform float speed = 3.0;

void vertex() {
	VERTEX.y += sin(TIME * speed) * height;
}
