shader_type canvas_item;
// Arte cheia da carta: a pintura vai até a base e some no papel do painel de texto (como a C da cartas_v4).
// `fade_from` é a fração da altura onde a arte começa a sumir (2.0 = não some, usado na mão).
uniform float fade_from = 0.82;
uniform float rect_h = 310.0;
varying float ny;

void vertex() {
	ny = VERTEX.y / rect_h;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (fade_from < 1.0) {
		c.a *= 1.0 - smoothstep(fade_from, 1.0, ny);
	}
	COLOR = c;
}
