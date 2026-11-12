shader_type canvas_item;
render_mode blend_add;
// Raios girando atrás da carta de nível 2 (gelo) e 3 (ouro).
uniform vec4 col : source_color = vec4(1.0, 0.84, 0.43, 1.0);
uniform float count = 14.0;
uniform float speed = 0.12;
uniform float motion = 1.0;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p) * 2.0;
	float a = atan(p.y, p.x) + TIME * speed * motion;
	float f = fract(a / 6.2831853 * count);
	float ray = 1.0 - smoothstep(0.35, 0.65, abs(f * 2.0 - 1.0));
	float mask = 1.0 - smoothstep(0.28, 1.0, r);
	COLOR = vec4(col.rgb * ray * mask * 0.55, 1.0);
}
