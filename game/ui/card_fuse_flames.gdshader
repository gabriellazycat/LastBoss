shader_type canvas_item;
// Chamas lambendo o pé da carta Explosiva de nível 3 (game/card_mold.gd, _explosive_fx).
// Faixa baixa sob a borda: a base fica fora da carta e só as pontas sobem sobre a margem de baixo.
// `hole` abaixa as chamas no meio (a placa "III" da carta grande fica à mostra).
uniform float motion = 1.0;
uniform float hole = 0.0;
uniform float seed = 0.0;

// hash sem sin (o de sin perde precisão em GPU de float médio e as chamas saíam em degraus)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	float t = mod(TIME, 600.0) * motion + seed;
	float x = UV.x;
	float y = 1.0 - UV.y;   // 0 na base, 1 no topo da faixa
	// línguas de fogo: colunas em triângulo, cada uma com a sua altura (ruído no tempo), entortadas por um ruído que sobe
	float xs = x + (noise(vec2(x * 9.0, y * 4.0 - t * 3.2)) - 0.5) * 0.05 * (0.3 + y);
	float cell = xs * 15.0;
	float tri = 1.0 - abs(fract(cell) - 0.5) * 2.0;
	float hc = 0.28 + 0.72 * pow(noise(vec2(floor(cell) * 1.7 + seed, t * 1.8)), 1.3);
	float hgt = max(hc * pow(tri, 0.8), 0.2);
	hgt *= 1.0 - hole * (1.0 - smoothstep(0.08, 0.17, abs(x - 0.5)));
	hgt *= smoothstep(0.0, 0.07, x) * smoothstep(1.0, 0.93, x);
	float f = hgt - y + (noise(vec2(x * 30.0, UV.y * 6.0 + t * 5.0)) - 0.5) * 0.12;
	float a = smoothstep(0.0, 0.08, f) * smoothstep(0.0, 0.22, y + 0.02);
	float heat = clamp(f / max(hgt, 0.05), 0.0, 1.0);
	vec3 col = mix(vec3(0.78, 0.14, 0.02), vec3(1.0, 0.56, 0.1), smoothstep(0.05, 0.4, heat));
	col = mix(col, vec3(1.0, 0.93, 0.62), smoothstep(0.55, 0.95, heat));
	// bafo quente: um halo laranja fraco logo acima das chamas, que esquenta o pé da carta
	float haze = exp(-max(y - hgt, 0.0) * 7.0) * 0.3 * smoothstep(0.0, 0.3, y) * (1.0 - a);
	col = mix(vec3(1.0, 0.45, 0.08), col, a / max(a + haze, 0.001));
	COLOR = vec4(col, (a * 0.95 + haze)) * COLOR;
}
