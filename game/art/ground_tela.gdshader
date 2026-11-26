shader_type spatial;
// Chão pintado como as cartas (22/11/2026, docs/ARVORES_E_CHAO.md): o designer achou feia a textura do chão de antes
// (ground_ror: manchas em várias escalas, relevo falso por ruído, salpicos e as pinceladas genéricas do paint_albedo
// por cima, tudo junto virava borrão). Aqui cada estilo é UMA ideia de pintura, sem relevo falso (o chão é plano e a
// luz não desenha manchas nele) e sem salpico miúdo:
//   1 guache chapado: campos grandes de cor lisa com borda pintada nítida, três valores, pinceladas largas e deitadas
//     que só clareiam (como os fundos das cartas);
//   2 relva pincelada: campos macios + pinceladas de relva largas e afinando, todas para o mesmo lado (vento);
//   3 mosaico de pinceladas: manchas de pincel chato de ~1,5 m, cada uma num tom vizinho (combina com as copas novas);
//   4 liso: só os campos grandes, em degradê macio, nada por cima (o cenário e as unidades aparecem mais).
// Mesmas cores por ato dos looks 10/11/12 (c_grass, c_grass2, c_dirt, c_rock) e o mesmo "mundo" (manchas de cor).
uniform int estilo = 1;
uniform vec3 c_grass : source_color = vec3(0.24, 0.42, 0.3);
uniform vec3 c_grass2 : source_color = vec3(0.42, 0.48, 0.26);
uniform vec3 c_dirt : source_color = vec3(0.52, 0.43, 0.31);
uniform vec3 c_rock : source_color = vec3(0.6, 0.58, 0.55);
uniform vec3 c_fleck : source_color = vec3(0.95, 0.85, 0.55);   // não usado aqui (os salpicos saíram); fica pelos looks
uniform float dirt_amount = 0.35;
uniform float rock_amount = 0.25;
uniform float fleck_amount = 0.5;
uniform float bump = 0.6;
uniform float roughness = 0.95;
uniform float mundo = 0.0;

varying vec3 wp;
varying vec3 paint_p;
#define DIO
#include "res://game/art/paint.gdshaderinc"

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	mat2 r0 = mat2(vec2(0.96, 0.28), vec2(-0.28, 0.96));
	mat2 r1 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	mat2 r2 = mat2(vec2(0.31, 0.95), vec2(-0.95, 0.31));
	p += vec2(vnoise(r2 * p * 0.7 + 5.0), vnoise(r1 * p * 0.7 + 9.0)) * 1.1;
	return vnoise(r0 * p) * 0.5 + vnoise(r1 * p * 2.03 + 17.0) * 0.3 + vnoise(r2 * p * 4.1 + 3.0) * 0.2;
}
// Borda pintada: limiar nítido (meio palmo de transição) com a borda tremida como a de um pincel.
float edge(float v, float t, vec2 p) {
	float j = (vnoise(p * 0.9) - 0.5) * 0.035 + (vnoise(p * 3.1 + 7.0) - 0.5) * 0.012;
	float w = max(fwidth(v), 0.004);
	return smoothstep(t - w, t + w, v + j);
}
// Manchas de pincel chato em células: x = valor da mancha, y = cobertura (0/1 com borda curta), z = sorteio.
// ang: direção base; jit: quanto cada mancha gira; sz: semi-eixos em células.
vec3 dabs(vec2 q, float ang0, float jit, vec2 sz) {
	vec2 c0 = floor(q);
	float best = -1.0;
	vec3 res = vec3(0.5, 0.0, 0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cell = c0 + vec2(float(i), float(j));
			vec2 ctr = cell + 0.5 + (vec2(hash(cell + 3.1), hash(cell + 5.3)) - 0.5) * 0.8;
			float ang = ang0 + (hash(cell) - 0.5) * jit;
			vec2 d = q - ctr;
			d = vec2(cos(ang) * d.x + sin(ang) * d.y, -sin(ang) * d.x + cos(ang) * d.y) / sz;
			// ponta do pincel: a mancha afina num dos lados (como a pincelada que termina)
			d.y *= 1.0 + max(d.x, 0.0) * 0.45;
			float r = length(d) + (vnoise(q * 2.7 + cell * 1.3) - 0.5) * 0.16;
			float order = hash(cell + 9.7);
			if (r < 1.0 && order > best) {
				best = order;
				res = vec3(hash(cell + 13.3), smoothstep(1.0, 0.9, r), hash(cell + 21.1));
			}
		}
	}
	return res;
}
// Pincelada de relva: lente comprida que afina na ponta, uma por célula, todas viradas para o mesmo lado.
// Devolve (cobertura, posição ao longo 0 na base..1 na ponta).
vec2 blade(vec2 q, float ang0) {
	vec2 c0 = floor(q);
	vec2 best = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cell = c0 + vec2(float(i), float(j));
			vec2 ctr = cell + 0.5 + (vec2(hash(cell + 1.7), hash(cell + 4.9)) - 0.5) * 0.9;
			float ang = ang0 + (hash(cell + 2.3) - 0.5) * 0.7;
			vec2 d = q - ctr;
			d = vec2(cos(ang) * d.x + sin(ang) * d.y, -sin(ang) * d.x + cos(ang) * d.y);
			float len = 0.62 + hash(cell + 6.1) * 0.3;
			float t = d.y / len + 0.5;                       // 0 base, 1 ponta
			float w = 0.15 * (1.0 - t * t) * step(0.0, t) * step(t, 1.0);
			float cov = smoothstep(w, w * 0.7, abs(d.x)) * step(0.0, t) * step(t, 1.0);
			if (cov > best.x) {
				best = vec2(cov, t);
			}
		}
	}
	return best;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	paint_p = wp;
}

void fragment() {
	vec2 p = wp.xz;
	// Coordenada torcida: os campos têm borda orgânica, não de ruído redondo.
	vec2 w = p + vec2(fbm(p * 0.018 + 3.0), fbm(p * 0.018 + 11.0)) * 16.0;
	float zone = fbm(w * 0.012);
	float val = fbm(w * 0.028 + 7.0);
	float dz = fbm(w * 0.02 + 41.0);
	float rz = fbm(w * 0.045 + 93.0);
	float dt = 0.77 - dirt_amount * 0.15;   // clareiras de terra pequenas: terra grande lê como estrada
	float rt = 0.78 - rock_amount * 0.15;
	vec3 col;
	float dirt;
	float rock;
	if (estilo == 1 || estilo == 3) {
		// Campos nítidos.
		// Três campos: verde fundo, verde frio, verde-amarelo (como as áreas grandes de cor das cartas).
		vec3 cool = c_grass * vec3(0.86, 1.02, 1.16);
		col = mix(c_grass, cool, edge(fbm(w * 0.016 + 51.0), 0.5, p + 2.0));
		col = mix(col, c_grass2, edge(zone, 0.55, p));
		float dk = 1.0 - edge(val, 0.38, p + 17.0);
		float lt = edge(val, 0.63, p + 31.0);
		col *= 1.0 - dk * 0.13;
		col = mix(col, col * vec3(1.1, 1.1, 1.0), lt);
		dirt = edge(dz, dt, p + 5.0);
		rock = edge(rz, rt, p + 9.0);
	} else {
		// Campos macios.
		vec3 cool = c_grass * vec3(0.86, 1.02, 1.16);
		col = mix(c_grass, cool, smoothstep(0.4, 0.6, fbm(w * 0.016 + 51.0)));
		col = mix(col, c_grass2, smoothstep(0.45, 0.66, zone) * 0.9);
		col *= 0.88 + 0.22 * smoothstep(0.25, 0.75, val);
		dirt = smoothstep(dt - 0.03, dt + 0.04, dz);
		rock = smoothstep(rt - 0.02, rt + 0.03, rz);
	}
	if (mundo > 0.0) {
		float m1 = estilo == 1 || estilo == 3 ? edge(fbm(w * 0.03 + 61.0), 0.6, p) : smoothstep(0.5, 0.68, fbm(w * 0.03 + 61.0));
		float m2 = estilo == 1 || estilo == 3 ? edge(fbm(w * 0.045 + 83.0), 0.62, p) : smoothstep(0.52, 0.7, fbm(w * 0.045 + 83.0));
		col = mix(col, col * vec3(1.22, 1.14, 0.78), m1 * 0.6 * mundo);
		col = mix(col, col * vec3(0.82, 1.0, 1.14), m2 * 0.5 * mundo);
	}
	vec3 dcol = c_dirt * (estilo == 1 || estilo == 3 ? mix(0.9, 1.06, edge(val, 0.5, p + 3.0)) : (0.9 + 0.18 * val));
	vec3 rcol = c_rock * (0.92 + 0.12 * vnoise(w * 0.5));
	if (estilo == 1) {
		// Pinceladas largas deitadas (pincel chato ~2,5 m x 0,7 m), todas quase na mesma direção; só clareiam.
		vec3 s = dabs(p / 2.8, 0.35, 0.5, vec2(1.05, 0.3));
		float up = s.y * smoothstep(0.35, 1.0, s.x) * 0.17;
		col *= 1.0 + up;
		dcol *= 1.0 + up * 0.8;
	} else if (estilo == 2) {
		// Relva: duas camadas de pinceladas afinando, viradas para o alto da tela (o norte), ponta mais clara.
		vec2 b1 = blade(p / 1.15, 0.12);
		vec2 b2 = blade(p / 0.85 + 13.7, -0.1);
		vec3 tip = mix(c_grass2, vec3(dot(c_grass2, vec3(0.33))), 0.1) * 1.32;
		vec3 base = col * 0.8;
		vec3 g1 = mix(base, tip, smoothstep(0.1, 1.0, b1.y));
		vec3 g2 = mix(col * 0.92, tip * 0.95, smoothstep(0.2, 1.0, b2.y));
		col = mix(col, g2, b2.x * 0.7);
		col = mix(col, g1, b1.x * 0.9);
		// a terra leva arraste de pincel comprido
		vec3 s = dabs(p / 1.8, 0.2, 0.6, vec2(0.9, 0.25));
		dcol *= 1.0 + s.y * (s.x - 0.4) * 0.12;
	} else if (estilo == 3) {
		// Mosaico: duas camadas de manchas, cada uma num tom vizinho (quente claro, frio, claro, meio).
		vec3 a = dabs(p / 1.5, 0.0, 6.28, vec2(0.62, 0.36));
		vec3 b = dabs(p / 0.95 + 21.0, 0.0, 6.28, vec2(0.6, 0.34));
		vec3 t1 = a.z < 0.25 ? vec3(1.17, 1.12, 0.82) : (a.z < 0.5 ? vec3(0.85, 0.97, 1.12) : (a.z < 0.75 ? vec3(1.12) : vec3(0.9, 0.92, 0.9)));
		vec3 t2 = b.z < 0.3 ? vec3(1.13, 1.09, 0.86) : (b.z < 0.6 ? vec3(0.88, 0.98, 1.09) : vec3(1.08));
		col = mix(col, col * t1, a.y);
		col = mix(col, col * t2, b.y * step(0.55, b.x));
		dcol = mix(dcol, dcol * mix(t1, vec3(1.0), 0.4), a.y);
	}
	col = mix(col, dcol, dirt * 0.6);   // relva gasta, nunca a cor cheia da estrada
	col = mix(col, mix(col, rcol * 0.72, 0.55), rock);   // cascalho: pedra misturada à relva, não uma placa clara
	if (estilo == 5) {
		// Diorama (como o chão do Holy Sheep): manchado em três escalas presas ao mundo e manchas de sol quentes,
		// macio, sem pincelada.
		float mn = vnoise(p * 0.8) * 0.55 + vnoise(p * 2.7 + 13.0) * 0.3 + vnoise(p * 7.0) * 0.15;
		col *= 1.0 + (mn - 0.5) * 0.34;
		float sunp = smoothstep(0.5, 0.85, vnoise(p * 0.07 + 5.0));
		col = mix(col, col * vec3(1.08, 1.04, 0.86), sunp * 0.6);
	}
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALBEDO = pt_flat_card(col);
	PAINT_PAPER
	ROUGHNESS = roughness;
	SPECULAR = 0.1;
}

void light() {
	PAINT_LIGHT
}
