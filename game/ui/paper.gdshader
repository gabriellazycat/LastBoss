shader_type canvas_item;
// Papel da interface na direção "Diário" (docs/variacoes/cartas/ui.html e mesa.html): papel sujo com borda
// rasgada, grão, manchas, marca de caneca e sombra; fita crepe com pontas rasgadas; folha pautada; caixa a lápis.
// Mesmo truque do frame.gdshader: só desenha os quads de StyleBoxTexture com a textura-marcador do UiDiario
// (9x9..13x13 px). Nos botões (state_mode 1) o tamanho do marcador diz o estado: 9 normal, 10 sobre,
// 11 pressionado, 12 desligado, 13 foco. Texto e o que o Control desenha sozinho passam sem mudança.

global uniform float ui_px;              // pixels de tela por unidade de interface (UiCovil.sync)

uniform int kind = 0;                    // 0 papel, 1 fita, 2 pautada, 3 caixa a lápis, 4 carta, 5 etiqueta, 6 contrato
uniform vec4 paper_a : source_color = vec4(0.87, 0.82, 0.72, 1.0);
uniform vec4 paper_b : source_color = vec4(0.77, 0.71, 0.57, 1.0);
uniform vec4 tint : source_color = vec4(0.89, 0.83, 0.63, 0.92);   // fita; na carta, a faixa do topo
uniform vec4 ink : source_color = vec4(0.11, 0.1, 0.08, 1.0);
uniform float grime = 0.6;               // 0 limpo .. 1 imundo
uniform float seed = 0.0;
uniform float shadow = 8.0;              // = expand margin da StyleBox
uniform float rough = 2.2;               // amplitude do rasgo da borda
uniform float band = 0.0;                // carta: altura da faixa de fita no topo (unidades de interface)
uniform float hot = 0.0;                 // 0..1: aceso (seleção, foco)
uniform float state_mode = 0.0;
uniform int mat_id = 0;                  // carta (kind 4): 0 papel, 1 ferro, 2 ouro, 3 obsidiana, 4 pedra rachada, 5 ferro em brasa, 6 madeira, 7 aço gravado

varying vec2 quv;

void vertex() {
	quv = UV;
}

float hash(vec2 p) {
	p = mod(p, 289.0);
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + 7.1) * 0.3 + vnoise(p * 4.07 + 3.3) * 0.15;
}

float n1(float x) {
	return vnoise(vec2(x, seed * 13.7));
}


// ---- Materiais das cartas (variante 4 do visual de upgrade; game/card_fx.gd escolhe o `mat_id`). Tudo procedural.
// p = posição em unidades de interface dentro da carta, R = tamanho, e = distância da borda para dentro.
vec2 cell_hash2(vec2 c) {
	return vec2(hash(c), hash(c + 17.31));
}

// Diferença entre o 2º e o 1º ponto de Voronoi mais próximos: perto de 0 = linha entre células (rachadura).
float vor_edge(vec2 p) {
	vec2 ip = floor(p);
	vec2 fp = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = cell_hash2(ip + g);
			float d = length(g + o - fp);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return d2 - d1;
}

float rivet(vec2 p, vec2 pos, out float cap) {
	float d = length(p - pos);
	cap = 1.0 - smoothstep(2.1, 2.7, d);
	return 1.0 - smoothstep(3.0, 3.9, d);
}

vec3 material_col(int m, vec2 p, vec2 R, float e, float nz, float g, float tm) {
	vec3 col = vec3(0.5);
	float streak = vnoise(vec2(p.x * 0.012, p.y * 0.85));
	float lift = clamp(1.0 - length((p / R - vec2(0.5, 0.58)) * vec2(1.7, 1.3)), 0.0, 1.0);   // clareia o meio, onde fica o desenho
	if (m == 1) {
		// Ferro: chapa fria escovada, bisel e rebites.
		col = mix(vec3(0.27, 0.285, 0.32), vec3(0.5, 0.52, 0.57), streak * 0.65 + nz * 0.3);
		col *= 1.0 + 0.18 * (0.5 - g);
		col += vec3(0.08) * lift;
		col += vec3(0.16) * (smoothstep(2.4, 3.2, e) - smoothstep(3.6, 4.6, e));
		col -= vec3(0.13) * (smoothstep(4.6, 5.4, e) - smoothstep(5.8, 6.8, e));
		float cap;
		float sh = 0.0;
		vec2 pts[6] = vec2[](vec2(8.0, 8.0), vec2(R.x - 8.0, 8.0), vec2(8.0, R.y - 8.0), vec2(R.x - 8.0, R.y - 8.0), vec2(8.0, R.y * 0.5), vec2(R.x - 8.0, R.y * 0.5));
		for (int i = 0; i < 6; i++) {
			sh = rivet(p, pts[i], cap);
			col *= 1.0 - 0.45 * sh * (1.0 - cap);
			float hl = smoothstep(2.4, 0.0, length(p - pts[i] + vec2(0.9, 0.9)));
			col = mix(col, vec3(0.62, 0.65, 0.7) + vec3(0.3) * hl, cap);
		}
	} else if (m == 2) {
		// Ouro: metal quente com um brilho diagonal que passa de tempos em tempos.
		float sw = 0.5 + 0.5 * sin(p.x * 0.035 + p.y * 0.06 + nz * 3.0);
		col = mix(vec3(0.56, 0.35, 0.07), vec3(0.96, 0.77, 0.3), clamp(nz * 0.5 + sw * 0.35 + (1.0 - g) * 0.25, 0.0, 1.0));
		col += vec3(0.1, 0.08, 0.02) * lift;
		col += vec3(0.2, 0.17, 0.06) * (smoothstep(2.0, 2.8, e) - smoothstep(3.2, 4.2, e));
		col -= vec3(0.2, 0.15, 0.05) * (smoothstep(5.0, 5.8, e) - smoothstep(6.2, 7.0, e));
		float ph = fract(tm / 4.2 + seed * 3.7);
		float tt = clamp(ph / 0.38, 0.0, 1.0);
		float act = step(ph, 0.38);
		float pos = -30.0 + tt * (R.x + R.y * 0.6 + 60.0);
		float d = p.x + p.y * 0.6 - pos;
		float gl = exp(-(d * d) / 110.0) * act;
		float gl2 = exp(-((d + 18.0) * (d + 18.0)) / 30.0) * act;
		col += vec3(1.0, 0.96, 0.72) * (gl * 0.5 + gl2 * 0.3);
	} else if (m == 3) {
		// Obsidiana: vidro escuro com facetas, reflexos longos e borda arroxeada.
		col = vec3(0.075, 0.07, 0.11);
		col += vec3(0.05, 0.04, 0.075) * hash(floor(vec2(p.x * 0.05 + p.y * 0.03, p.y * 0.06 - p.x * 0.02)));
		float s = pow(max(sin((p.x - p.y * 0.8) * 0.12 + nz * 2.0), 0.0), 7.0);
		col += vec3(0.2, 0.18, 0.32) * s * 0.7;
		col += vec3(0.28, 0.16, 0.45) * (1.0 - smoothstep(0.0, 13.0, e)) * 0.5;
		col += vec3(0.16, 0.15, 0.22) * lift;
	} else if (m == 4) {
		// Pedra rachada: rocha cinza com rachaduras e um brilho roxo lá dentro.
		float rock = fbm(p * 0.09 + 3.0);
		col = mix(vec3(0.24, 0.23, 0.24), vec3(0.47, 0.45, 0.43), rock);
		col *= 1.0 + (hash(floor(p * 1.6)) - 0.5) * 0.12;
		float ed = vor_edge(p * 0.034);
		float mask = step(0.32, vnoise(p * 0.045 + 9.0));
		float crack = (1.0 - smoothstep(0.012, 0.05, ed)) * mask;
		float glow = (1.0 - smoothstep(0.0, 0.16, ed)) * mask;
		float pulse = 0.65 + 0.35 * sin(tm * 2.0 + p.y * 0.04);
		col = mix(col, col * 0.55, glow * 0.5);
		col = mix(col, vec3(0.06, 0.02, 0.09), crack);
		col += vec3(0.4, 0.1, 0.62) * crack * 0.35 * pulse;
		col += vec3(0.07) * lift;
	} else if (m == 5) {
		// Ferro em brasa: chapa escura com veios incandescentes e a borda acesa.
		float h = fbm(p * 0.045 + vec2(0.0, tm * 0.06));
		col = mix(vec3(0.17, 0.11, 0.1), vec3(0.33, 0.2, 0.15), streak * 0.7 + nz * 0.3);
		float vein = 1.0 - smoothstep(0.0, 0.05, abs(h - 0.5));
		float pulse = 0.75 + 0.25 * sin(tm * 3.0 + h * 9.0);
		col += vec3(1.0, 0.42, 0.08) * vein * 0.85 * pulse;
		col += vec3(1.0, 0.35, 0.05) * (1.0 - smoothstep(0.0, 16.0, e)) * 0.5 * pulse;
		col += vec3(0.9, 0.3, 0.05) * pow(g, 3.0) * 0.4;
		col += vec3(0.13, 0.07, 0.04) * lift;
	} else if (m == 6) {
		// Madeira barata: tábuas com veio, juntas e pregos.
		float plank = floor(p.y / 38.0);
		float off = hash(vec2(plank, 5.0)) * 40.0;
		float ring = sin((p.y + nz * 14.0 + vnoise(vec2(p.x * 0.03 + off, plank)) * 10.0) * 0.55);
		float grain = vnoise(vec2((p.x + off) * 0.02, p.y * 0.8)) * 0.6 + ring * 0.12 + 0.2;
		vec3 wc = mix(vec3(0.38, 0.24, 0.12), vec3(0.64, 0.46, 0.25), clamp(grain, 0.0, 1.0));
		wc *= 0.88 + 0.24 * hash(vec2(plank, 2.0));
		col = wc;
		float seam = abs(mod(p.y, 38.0) - 0.5);
		col *= 1.0 - 0.5 * (1.0 - smoothstep(0.4, 1.4, seam));
		float nail = 0.0;
		for (int i = 0; i < 2; i++) {
			float nx = (i == 0) ? 7.0 : R.x - 7.0;
			float ny = plank * 38.0 + 19.0;
			float dn = length(p - vec2(nx, ny));
			nail = max(nail, 1.0 - smoothstep(1.5, 2.2, dn));
		}
		col = mix(col, vec3(0.22, 0.2, 0.2), nail);
		col += vec3(0.07, 0.06, 0.04) * lift;
	} else if (m == 7) {
		// Aço gravado: aço azulado com trama de losangos gravada e filete na borda.
		col = mix(vec3(0.24, 0.3, 0.42), vec3(0.47, 0.54, 0.66), streak * 0.6 + nz * 0.3);
		col *= 1.0 + 0.15 * (0.5 - g);
		float a = abs(fract((p.x + p.y) * 0.045) - 0.5);
		float b = abs(fract((p.x - p.y) * 0.045) - 0.5);
		float ln = 1.0 - smoothstep(0.0, 0.05, min(a, b));
		col *= 1.0 - 0.2 * ln;
		col += vec3(0.07, 0.08, 0.1) * lift;
		col -= vec3(0.2) * (smoothstep(4.4, 5.0, e) - smoothstep(5.4, 6.0, e));
		col += vec3(0.15) * (smoothstep(6.0, 6.6, e) - smoothstep(7.0, 7.6, e));
	}
	return clamp(col, 0.0, 1.0);
}

void fragment() {
	if (TEXTURE_PIXEL_SIZE.x > 0.07 && TEXTURE_PIXEL_SIZE.x < 0.12) {
		vec4 inc = COLOR;
		float st = floor(1.0 / TEXTURE_PIXEL_SIZE.x + 0.5);
		float on = hot;
		float press = 0.0;
		float dis = 0.0;
		if (state_mode > 0.5) {
			on = max(on, (st == 10.0 || st == 13.0) ? 1.0 : 0.0);
			press = st == 11.0 ? 1.0 : 0.0;
			dis = st == 12.0 ? 1.0 : 0.0;
		}
		float px = max(ui_px, 0.05);
		vec2 full = vec2(1.0 / max(length(vec2(dFdx(quv.x), dFdy(quv.x))), 1e-5), 1.0 / max(length(vec2(dFdx(quv.y), dFdy(quv.y))), 1e-5)) / px;
		if (full.x > 20000.0 || full.y > 20000.0) {
			COLOR = vec4(0.0);
		} else {
		vec2 R = max(full - 2.0 * shadow, vec2(4.0));
		vec2 p = quv * full - shadow;
		vec2 c = p - R * 0.5;
		float w = 1.0 / px;

		// Borda rasgada: a distância até o retângulo leva ruído ao longo do contorno.
		vec2 q = abs(c) - R * 0.5;
		float e = -max(q.x, q.y);                       // distância para dentro
		float along = (abs(q.x) < abs(q.y)) ? p.x : p.y; // coordenada ao longo da borda mais próxima
		float rr = rough;
		if (kind == 1) {
			// Fita: lados retos (rasgo mínimo), pontas em zigue-zague.
			float endx = R.x * 0.5 - abs(c.x);
			float zz = abs(fract(p.y / 3.2 + seed) - 0.5) * 2.0;
			float tear = endx - (zz * 2.6 + n1(p.y * 0.7) * 1.4);
			float side = R.y * 0.5 - abs(c.y) - n1(p.x * 0.15) * 0.8;
			e = min(tear, side);
		} else {
			e -= (n1(along * 0.18) - 0.5) * rr * 2.0 + (n1(along * 0.9 + 3.0) - 0.5) * rr * 0.6;
		}

		// Cor de base.
		vec3 col;
		float g = clamp(p.y / R.y, 0.0, 1.0);
		vec2 sp = p + vec2(seed * 97.0, seed * 41.0);
		float nz = fbm(sp * 0.035);
		float grain = hash(floor(p * px * 0.7)) - 0.5;
		if (kind == 1) {
			col = tint.rgb * (0.92 + nz * 0.16 + grain * 0.06);
			col *= 1.0 - 0.08 * smoothstep(0.0, 1.0, abs(c.y) / (R.y * 0.5));
		} else {
			col = mix(paper_a.rgb, paper_b.rgb, g * 0.8 + nz * 0.35);
			col *= 1.0 + grain * 0.05;
			float gr = grime;
			if (kind == 4 && mat_id > 0) {
				col = material_col(mat_id, p, R, e, nz, g, TIME) * (1.0 + grain * 0.04);
				gr = grime * 0.3;
			}
			if (kind == 2) {
				float ly = mod(p.y - 34.0, 24.0);
				col = mix(col, vec3(0.32, 0.42, 0.68), (1.0 - smoothstep(0.0, 1.2 * w + 0.6, abs(ly - 0.6))) * 0.38 * step(30.0, p.y));
				col = mix(col, vec3(0.75, 0.22, 0.2), (1.0 - smoothstep(0.0, w + 0.5, abs(p.x - 38.0))) * 0.5);
			}
			// Sujeira: manchas largas, borrão de grafite e marca de caneca, conforme a semente.
			float bl = smoothstep(0.55, 0.85, fbm(sp * 0.012 + 4.0));
			col *= 1.0 - bl * 0.22 * gr;
			vec2 ring_c = vec2(hash(vec2(seed, 1.3)), hash(vec2(seed, 7.9))) * R;
			float ring_r = min(R.x, R.y) * (0.18 + hash(vec2(seed, 3.1)) * 0.14);
			float rd = abs(length(p - ring_c) - ring_r) - 1.2 - n1(atan(p.y - ring_c.y, p.x - ring_c.x) * 6.0) * 1.6;
			float arc = step(0.25, n1(atan(p.y - ring_c.y, p.x - ring_c.x) * 1.5 + 5.0));
			col *= 1.0 - (1.0 - smoothstep(0.0, 1.5, rd)) * 0.28 * gr * arc * step(0.35, gr);
			// Borda queimada/encardida para dentro.
			col *= mix(mat_id > 0 && kind == 4 ? 0.8 : 0.62, 1.0, smoothstep(0.0, mat_id > 0 && kind == 4 ? 7.0 : mix(10.0, 26.0, gr), e));
			if (kind == 6) {
				col *= mix(0.45, 1.0, smoothstep(0.0, 9.0, e));
			}
			if (kind == 5) {
				col = mix(col, vec3(0.96, 0.93, 0.85), 0.55);
			}
			// Faixa de fita no topo da carta, com a borda de baixo rasgada.
			if (kind == 4 && band > 0.0) {
				float bh = band + (n1(p.x * 0.35) - 0.5) * 2.2;
				float fb = 1.0 - smoothstep(bh - w, bh + w, p.y);
				vec3 tc = tint.rgb * (0.9 + nz * 0.2 + grain * 0.05);
				col = mix(col, tc, fb * tint.a);
				col *= 1.0 - (1.0 - smoothstep(0.0, 2.5, abs(p.y - bh))) * 0.18 * fb;
			}
		}

		// Caixa a lápis (trilho de barra): só o contorno tremido, centro transparente.
		float alpha = 1.0;
		if (kind == 3) {
			float lw = 1.6;
			float d = abs(e - lw * 0.5 - 0.5);
			float a = 1.0 - smoothstep(lw * 0.5, lw * 0.5 + w, d);
			col = ink.rgb;
			alpha = a * 0.9;
			alpha = max(alpha, 0.12 * step(0.0, e));
			col = mix(vec3(0.95, 0.9, 0.8), ink.rgb, a);
		}

		// Estados: sobre/foco clareia e acende a borda; pressionado escurece; desligado apaga.
		col *= 1.0 + on * 0.1 - press * 0.12;
		if (kind != 3) {
			float rim = 1.0 - smoothstep(0.0, 2.2, e - 0.6);
			col = mix(col, col * 0.55, rim * 0.6);
			col = mix(col, vec3(0.62, 0.12, 0.08), on * (1.0 - smoothstep(0.0, 3.0, e)) * 0.7 * step(0.5, hot + state_mode));
		}
		if (dis > 0.5) {
			float l = dot(col, vec3(0.3, 0.55, 0.15));
			col = mix(col, vec3(l), 0.7) * 0.85;
		}

		float fa = alpha * smoothstep(-w, w, e);
		// Sombra projetada, um pouco para baixo e para a direita.
		vec2 cs = c - vec2(shadow * 0.2, shadow * 0.45);
		vec2 qs = abs(cs) - R * 0.5;
		float es = -max(qs.x, qs.y);
		float sa = 0.5 * pow(clamp(1.0 + es / max(shadow, 0.001), 0.0, 1.0), 2.2) * step(0.001, shadow) * (1.0 + on * 0.3);
		if (kind == 3) {
			sa = 0.0;
		}
		float oa = fa + sa * (1.0 - fa);
		COLOR = vec4(col * fa / max(oa, 1e-4), oa) * inc;
		}
	}
}
