shader_type canvas_item;
render_mode blend_add;
// Rachaduras de luz do modificador Amaldiçoado: linhas finas de um ruído, pulsando e escorrendo devagar.
// Mais fortes nas bordas da janela da arte (o rosto da criatura fica limpo). `motion` 0 = parado.
uniform vec4 col : source_color = vec4(0.72, 0.3, 1.0, 1.0);
uniform vec2 scale = vec2(4.0, 3.8);
uniform float motion = 1.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p * 2.03 + vec2(17.3, 9.1);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float t = TIME * motion;
	vec2 p = UV * scale + vec2(t * 0.035, -t * 0.02);
	float d = abs(fbm(p) - 0.5);
	float core = 1.0 - smoothstep(0.0, 0.014, d);
	float glow = 1.0 - smoothstep(0.0, 0.07, d);
	float edge = 1.0 - smoothstep(0.0, 0.42, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	float m = 0.22 + 0.78 * edge;
	// pulso que corre pelas rachaduras
	float wave = 0.55 + 0.45 * sin(t * 2.4 + fbm(p * 0.7) * 9.0);
	vec3 c = col.rgb * glow * 0.7 * wave + vec3(1.0, 0.86, 1.0) * core * (0.55 + 0.45 * wave);
	COLOR = vec4(c * m, 1.0);
}
