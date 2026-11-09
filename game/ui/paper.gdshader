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
			if (kind == 2) {
				float ly = mod(p.y - 34.0, 24.0);
				col = mix(col, vec3(0.32, 0.42, 0.68), (1.0 - smoothstep(0.0, 1.2 * w + 0.6, abs(ly - 0.6))) * 0.38 * step(30.0, p.y));
				col = mix(col, vec3(0.75, 0.22, 0.2), (1.0 - smoothstep(0.0, w + 0.5, abs(p.x - 38.0))) * 0.5);
			}
			// Sujeira: manchas largas, borrão de grafite e marca de caneca, conforme a semente.
			float bl = smoothstep(0.55, 0.85, fbm(sp * 0.012 + 4.0));
			col *= 1.0 - bl * 0.22 * grime;
			vec2 ring_c = vec2(hash(vec2(seed, 1.3)), hash(vec2(seed, 7.9))) * R;
			float ring_r = min(R.x, R.y) * (0.18 + hash(vec2(seed, 3.1)) * 0.14);
			float rd = abs(length(p - ring_c) - ring_r) - 1.2 - n1(atan(p.y - ring_c.y, p.x - ring_c.x) * 6.0) * 1.6;
			float arc = step(0.25, n1(atan(p.y - ring_c.y, p.x - ring_c.x) * 1.5 + 5.0));
			col *= 1.0 - (1.0 - smoothstep(0.0, 1.5, rd)) * 0.28 * grime * arc * step(0.35, grime);
			// Borda queimada/encardida para dentro.
			col *= mix(0.62, 1.0, smoothstep(0.0, mix(10.0, 26.0, grime), e));
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
