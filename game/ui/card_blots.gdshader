shader_type canvas_item;
// Manchas de nanquim do modificador Sombrio: respingos que crescem das bordas e se mexem devagar.
// `motion` 0 = parado.
uniform vec4 ink : source_color = vec4(0.03, 0.03, 0.05, 1.0);
uniform vec2 scale = vec2(3.2, 3.0);
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
		p = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p * 2.03 + vec2(11.7, 5.3);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float t = TIME * motion;
	float edge = 1.0 - smoothstep(0.0, 0.5, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	// a mancha respira: o limiar sobe e desce, e o ruído deriva
	float breathe = 0.5 + 0.5 * sin(t * 0.9);
	vec2 p = UV * scale + vec2(t * 0.05, t * 0.035);
	float n = fbm(p) + edge * (0.2 + 0.07 * breathe);
	float blot = smoothstep(0.74, 0.77, n);
	// respingos miúdos em volta (mudam de lugar a cada poucos segundos, com fade)
	vec2 q = UV * vec2(34.0, 32.0);
	vec2 cell = floor(q);
	float phase = floor(t * 0.35);
	float fade = 1.0 - abs(fract(t * 0.35) * 2.0 - 1.0);
	float r = hash(cell + phase * 7.1);
	float dot_ = step(0.955 - edge * 0.05, r) * (1.0 - smoothstep(0.12, 0.42, length(fract(q) - 0.5))) * fade;
	float a = max(blot, dot_) * (0.55 + 0.45 * edge);
	COLOR = vec4(ink.rgb, a * 0.96);
}
