// Guache nos materiais (13/11/2026, docs/MUNDO_PINTADO.md): o mundo 3D pintado como as cartas, sem nenhuma camada
// por cima da tela. Cada shader do mundo inclui este arquivo e chama:
//   paint_albedo(cor, pos, normal, tipo)  no fragment(): paleta das cartas + valor das pinceladas (procedural ou da IA);
//   PAINT_LIGHT                            como corpo do light(): luz em manchas de tinta (ou a luz de sempre).
// Variáveis globais (project.godot [shader_globals], PaintLook.apply escolhe a variação):
//   paint_on     liga a paleta das cartas (todas as 9 variações);
//   paint_light  0 = luz de sempre, 1 = guache chapado, 2 = aguado, 3 = pincel largo;
//   paint_tex    0 = pinceladas procedurais (S), 1..3 = folhas de pincel geradas por IA (T1..T3).
// "tipo" escolhe a folha de pincel: 0 grama, 1 terra, 2 pedra, 3 folhagem, 4 pelo, 5 metal, 6 madeira, 7 tecido;
// -1 = adivinha pela cor (modelos coloridos por vértice).
// Regra do designer: nada escuro salpicado por cima (o filtro de tela "parecia um noise preto"). As pinceladas aqui
// clareiam mais do que escurecem e são do tamanho de um pincel largo, nunca grão fino.

global uniform bool paint_on;
global uniform int paint_light;
global uniform int paint_tex;
global uniform sampler2D paint_t_grass : hint_default_white, filter_linear_mipmap, repeat_enable;
global uniform sampler2D paint_t_dirt : hint_default_white, filter_linear_mipmap, repeat_enable;
global uniform sampler2D paint_t_stone : hint_default_white, filter_linear_mipmap, repeat_enable;
global uniform sampler2D paint_t_foliage : hint_default_white, filter_linear_mipmap, repeat_enable;
global uniform sampler2D paint_t_fur : hint_default_white, filter_linear_mipmap, repeat_enable;
global uniform sampler2D paint_t_metal : hint_default_white, filter_linear_mipmap, repeat_enable;
global uniform sampler2D paint_t_wood : hint_default_white, filter_linear_mipmap, repeat_enable;
global uniform sampler2D paint_t_cloth : hint_default_white, filter_linear_mipmap, repeat_enable;

float pt_hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float pt_noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(pt_hash(i), pt_hash(i + vec3(1, 0, 0)), f.x), mix(pt_hash(i + vec3(0, 1, 0)), pt_hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(pt_hash(i + vec3(0, 0, 1)), pt_hash(i + vec3(1, 0, 1)), f.x), mix(pt_hash(i + vec3(0, 1, 1)), pt_hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// Pinceladas procedurais: manchas de pincel chato. Cada célula tem uma pincelada (centro, ângulo, valor próprios);
// onde elas se sobrepõem fica a de cima. Dá manchas chapadas de borda definida, como o guache das cartas.
float pt_h2(vec2 p) {
	return pt_hash(vec3(p, 1.7));
}

float pt_dabs(vec2 q, float elong) {
	vec2 c0 = floor(q);
	float best = -1.0;
	float val = 0.5;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cell = c0 + vec2(float(i), float(j));
			vec2 ctr = cell + 0.5 + (vec2(pt_h2(cell + 3.1), pt_h2(cell + 5.3)) - 0.5) * 0.8;
			float ang = pt_h2(cell) * 6.2832;
			vec2 d = q - ctr;
			d = vec2(cos(ang) * d.x + sin(ang) * d.y, -sin(ang) * d.x + cos(ang) * d.y);
			d /= vec2(0.62 * elong, 0.62 / sqrt(elong));
			// borda do pincel levemente irregular
			float r = length(d) + (pt_noise(vec3(q * 3.0, cell.x)) - 0.5) * 0.18;
			float order = pt_h2(cell + 9.7);
			if (r < 1.0 && order > best) {
				best = order;
				val = pt_h2(cell + 13.3);
			}
		}
	}
	return val;
}

float pt_strokes(vec3 p, vec3 n, float size) {
	vec3 a = abs(n);
	vec2 q = a.y > max(a.x, a.z) ? p.xz : (a.x > a.z ? p.zy : p.xy);
	q /= size;
	if (paint_light == 2) {
		// aguado: lavagem larga e mole, sem borda
		return pt_noise(vec3(q * 0.35, 5.0)) * 0.7 + pt_noise(vec3(q * 0.9, 9.0)) * 0.3;
	}
	return pt_dabs(q, paint_light == 3 ? 3.2 : 1.4);
}

// Folha de pincel da IA, projetada nos três planos (triplanar), em valor (0,5 = neutro).
float pt_tri(sampler2D t, vec3 p, vec3 n, float size) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 1e-4);
	return texture(t, p.zy / size).r * w.x + texture(t, p.xz / size).r * w.y + texture(t, p.xy / size).r * w.z;
}

float pt_ai(int kind, vec3 p, vec3 n, float size) {
	if (kind == 0) return pt_tri(paint_t_grass, p, n, size);
	if (kind == 1) return pt_tri(paint_t_dirt, p, n, size);
	if (kind == 2) return pt_tri(paint_t_stone, p, n, size);
	if (kind == 3) return pt_tri(paint_t_foliage, p, n, size);
	if (kind == 4) return pt_tri(paint_t_fur, p, n, size);
	if (kind == 5) return pt_tri(paint_t_metal, p, n, size);
	if (kind == 6) return pt_tri(paint_t_wood, p, n, size);
	return pt_tri(paint_t_cloth, p, n, size);
}

// Tipo pela cor: verde -> folhagem, cinza claro azulado -> metal, cinza -> pedra, castanho -> madeira/pelo.
int pt_guess(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = (mx - mn) / max(mx, 1e-3);
	if (c.g > c.r * 1.08 && c.g > c.b * 1.05 && sat > 0.18) return 3;
	if (sat < 0.14) return c.b > c.r ? 5 : 2;
	if (c.r > c.b * 1.25) return mx > 0.35 ? 6 : 4;
	return 7;
}

// Paleta das cartas: menos saturado, verde puxado para sálvia azulada, azul vivo para petróleo, pretos levantados.
// Trabalha numa versão "de tela" (raiz ~ gama) e devolve linear.
vec3 pt_palette(vec3 lin) {
	vec3 g = sqrt(max(lin, vec3(0.0)));
	float greenness = clamp((g.g - max(g.r, g.b)) * 3.0, 0.0, 1.0);
	g.b += (g.g - g.b) * greenness * 0.33;
	g.r += (g.g - g.r) * greenness * 0.09;
	g.g -= (g.g - max(g.r, g.b)) * greenness * 0.18;
	float blueness = clamp((g.b - max(g.r, g.g)) * 3.0, 0.0, 1.0);
	g = mix(g, vec3(g.r + 0.05, g.g + 0.04, g.b * 0.88), blueness * 0.55);
	float l = dot(g, vec3(0.2126, 0.7152, 0.0722));
	g = mix(vec3(l), g, 0.72);
	g = g * 0.94 + 0.04;
	return g * g;
}

// Cor final do material. `size` = largura do pincel em metros (no espaço de `p`).
vec3 paint_albedo(vec3 lin, vec3 p, vec3 n, int kind, float size) {
	if (!paint_on) {
		return lin;
	}
	vec3 c = pt_palette(lin);
	int k = kind < 0 ? pt_guess(sqrt(max(lin, vec3(0.0)))) : kind;
	float v;
	if (paint_tex > 0) {
		v = pt_ai(k, p, n, size * 4.0) - 0.5;          // folha da IA: média 0,5
	} else {
		v = pt_strokes(p, n, size) - 0.5;
		v *= paint_light == 2 ? 0.7 : 0.55;            // manchas: valor de -0,5 a 0,5, mais largo que o ruído
	}
	// Mais claro que escuro: nunca um salpico escuro por cima (pedido do designer).
	float gain = paint_tex > 0 ? 1.0 : 2.0;               // o ruído procedural é mais estreito que a folha da IA
	v = v > 0.0 ? v * 0.42 * gain : v * 0.2 * gain;
	return c * (1.0 + v);
}

// Luz pintada. Ruído de borda de pincel em espaço de `pp` (posição do material).
vec3 paint_diffuse(vec3 N, vec3 L, vec3 V, float atten, vec3 lcol, vec3 pp, bool directional) {
	float ndl = dot(N, L);
	if (!paint_on || paint_light == 0) {
		// Luz de sempre (lambert com envoltório leve, como o look 5).
		float w = clamp((ndl + 0.25) / 1.25, 0.0, 1.0);
		return lcol * atten * w / PI;
	}
	float a = clamp(atten, 0.0, 1.0);
	float edge = pt_noise(pp * 1.6) - 0.5;              // borda da mancha tremida como pincel
	vec3 shade = vec3(0.52, 0.56, 0.7);                // sombra cinza fria das cartas (fração da luz)
	float lit;
	if (paint_light == 1) {
		// Guache chapado: duas manchas (luz e sombra) com borda curta e tremida.
		lit = smoothstep(0.05, 0.2, ndl + edge * 0.35) * a;
	} else if (paint_light == 2) {
		// Aguado: passagem larga e suave, com a borda molhada um pouco mais escura no meio do caminho.
		float t = smoothstep(-0.25, 0.55, ndl + edge * 0.25) * mix(0.35, 1.0, a);
		float wet = exp(-pow((t - 0.45) * 7.0, 2.0)) * 0.12;
		lit = clamp(t - wet, 0.0, 1.0);
	} else {
		// Pincel largo: três valores (sombra, meio-tom, luz) com bordas arrastadas.
		float s = pt_strokes(pp, N, 0.45) - 0.5;
		float x = ndl + s * 0.5 + edge * 0.2;
		lit = (smoothstep(-0.15, -0.02, x) * 0.5 + smoothstep(0.35, 0.5, x) * 0.5) * mix(0.3, 1.0, a);
	}
	vec3 k = mix(shade, vec3(1.0), lit);
	// A parte em sombra ainda recebe a luz difusa da cena pela cor fria; a iluminada, a luz inteira.
	// Luz pontual (lanternas, brilhos) cai com a distância: o preenchimento da sombra só existe perto dela.
	float fill = directional ? 0.28 : 0.28 * clamp(atten * 3.0, 0.0, 1.0);
	return lcol * k * (fill + (1.0 - fill) * lit) / PI;
}

// Corpo padrão do light(): o material que inclui define `varying vec3 paint_p;` com a posição usada nas pinceladas.
#define PAINT_LIGHT DIFFUSE_LIGHT += paint_diffuse(NORMAL, LIGHT, VIEW, ATTENUATION, LIGHT_COLOR, paint_p, LIGHT_IS_DIRECTIONAL); \
	if (!paint_on || paint_light == 0) { \
		vec3 h = normalize(LIGHT + VIEW); \
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * pow(clamp(dot(NORMAL, h), 0.0, 1.0), 24.0) * SPECULAR_AMOUNT * 0.12; \
	}
