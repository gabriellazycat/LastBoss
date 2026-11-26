shader_type canvas_item;
// Colcha de feltro do mapa da rota e do menu (26/11/2026), por cima do desenho já feito na SubViewport: a terra
// (cor `land`) vira retalhos irregulares em tons próximos, costurados com linha tracejada como o chão do jogo, e
// tudo ganha fibra de feltro e um relevo leve de aplique (luz de cima à esquerda).
uniform sampler2D scr : hint_screen_texture, filter_linear_mipmap;
uniform vec3 land : source_color = vec3(0.6, 0.7, 0.5);
uniform vec3 thread : source_color = vec3(0.94, 0.9, 0.82);
uniform float cell = 260.0;
// recorte de cantos redondos do retângulo (o menu); 0 = sem recorte (o mapa da rota)
uniform vec2 rect_size = vec2(1.0);
uniform float radius = 0.0;

// sorteio sem seno (o sin() de números grandes perde precisão na placa e quebrava as células em retângulos)
float h(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
vec2 h2(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}
float n(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}
float lum(vec3 c) { return dot(c, vec3(0.3, 0.59, 0.11)); }

// Voronoi: id da célula mais próxima, distância até a borda e a direção da borda (para o tracejado).
vec3 vor(vec2 p, out vec2 id) {
	vec2 g = floor(p);
	vec2 f = fract(p);
	float d1 = 9.0;
	vec2 mr = vec2(0.0);
	vec2 mg = vec2(0.0);
	for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
		vec2 o = vec2(float(i), float(j));
		vec2 r = o + 0.15 + 0.7 * h2(g + o) - f;
		float d = dot(r, r);
		if (d < d1) { d1 = d; mr = r; mg = o; }
	}
	float be = 9.0;
	vec2 bdir = vec2(1.0, 0.0);
	for (int j = -2; j <= 2; j++) for (int i = -2; i <= 2; i++) {
		vec2 o = mg + vec2(float(i), float(j));
		vec2 r = o + 0.15 + 0.7 * h2(g + o) - f;
		if (dot(mr - r, mr - r) > 0.00001) {
			float e = dot(0.5 * (mr + r), normalize(r - mr));
			if (e < be) { be = e; bdir = normalize(r - mr); }
		}
	}
	id = g + mg;
	return vec3(be, bdir);
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	if (radius > 0.0) {
		vec2 lp = abs(UV * rect_size - rect_size * 0.5) - (rect_size * 0.5 - radius);
		if (length(max(lp, 0.0)) > radius) discard;
	}
	vec3 c = textureLod(scr, SCREEN_UV, 0.0).rgb;
	vec2 q = SCREEN_UV / px;
	// só a terra lisa vira retalho (os desenhos por cima ficam como estão)
	float isl = 1.0 - smoothstep(0.03, 0.07, distance(c, land));
	vec2 id;
	vec2 pp = q / cell;
	pp += vec2(n(q * 0.006), n(q * 0.006 + 7.3)) * 0.35;
	vec3 v = vor(pp, id);
	float k = h(id);
	vec3 tone = land * (0.9 + 0.16 * k);
	tone = mix(tone, tone * vec3(1.06, 1.0, 0.86), step(0.7, h(id + 3.1)));   // alguns retalhos mais ocre
	float edge = v.x * cell;
	vec2 tg = vec2(-v.z, v.y);
	float along = dot(q, tg);
	float dash = step(0.45, fract(along / 16.0));
	float st = (1.0 - smoothstep(1.2, 2.2, abs(edge - 9.0))) * dash;
	float groove = 1.0 - smoothstep(0.0, 3.0, edge);
	vec3 felt = tone * (1.0 - 0.22 * groove);
	felt = mix(felt, thread, st * 0.85);
	c = mix(c, felt, isl);
	// relevo: os desenhos parecem recortes de feltro um pouco estufados (luz de cima à esquerda)
	float a = lum(textureLod(scr, SCREEN_UV - px * 3.0, 1.5).rgb);
	float b = lum(textureLod(scr, SCREEN_UV + px * 3.0, 1.5).rgb);
	float e = clamp((b - a) * 1.4, -0.22, 0.22) * (1.0 - isl * 0.7);
	c *= 1.0 - e;
	float f = n(q * 0.45) * 0.45 + n(q * vec2(1.6, 0.5)) * 0.3 + n(q * vec2(0.5, 1.6)) * 0.25;
	c *= 0.92 + 0.14 * f;
	COLOR = vec4(c, 1.0);
}
