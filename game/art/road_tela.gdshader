shader_type spatial;
// Estrada dos chãos pintados (ground_tela.gdshader, 22/11/2026): cópia da road_paint (mesmo campo da estrada, mesma
// luz, mesmo recorte) com a terra pintada em cada estilo do chão e a paleta das cartas (menos vermelha):
//   1 guache chapado: dois tons nítidos, trilha do meio mais clara, arraste de pincel ao longo da estrada;
//   2 relva pincelada: terra macia com arrastes compridos ao longo da estrada;
//   3 mosaico: manchas de pincel em tons vizinhos;   4 liso: terra em degradê macio.
// Borda: nítida e tremida (1 e 3) ou macia (2 e 4), sem o contorno escuro largo de antes.
// UV.x: metros através (0 no centro); UV.y: metros ao longo; COLOR.a = 0 na borda de fora.
// bands = 0: borda que se dissolve na grama (pintado); bands > 0: borda nítida com contorno escuro (cartum).
// Opaca com recorte (alpha scissor): trechos que se sobrepõem (bifurcações, emendas) não somam transparência,
// que deixava manchas claras de borda reta no chão.
render_mode cull_disabled;
uniform vec3 c_road : source_color = vec3(0.36, 0.3, 0.27);
uniform vec3 c_road_dark : source_color = vec3(0.25, 0.2, 0.2);
uniform vec3 c_edge : source_color = vec3(0.12, 0.14, 0.12);
uniform float bands = 0.0;
uniform int estilo = 1;
uniform float sand = 0.8;   // quanto a terra puxa para o ocre dos caminhos das cartas (por ato: GroundLooks.road_material)
uniform float emission_boost = 0.0;
// Ramo fechado: escurece sem sair da passada opaca (transparência fazia os ramos piscarem).
uniform float dim = 0.0;
uniform vec3 warm : source_color = vec3(1.0, 0.92, 0.8);
uniform vec3 cool : source_color = vec3(0.62, 0.6, 0.7);   // menos lilás que a road_paint: a terra não fica rosada
uniform vec3 shadow_tint : source_color = vec3(0.55, 0.45, 0.85);

// Campo da estrada (look de chão): em vez de uma fita por trecho, o mundo guarda UMA máscara do ato com a
// distância ao eixo da estrada mais próxima (união de todos os trechos), então onde eles se encontram ou correm
// lado a lado a terra se funde sem emenda. road_ids: qual trecho é o mais próximo (para realce/escurecer);
// road_state: por trecho, R = escurecido (ramo fechado), G = brilho (ramo planejado).
uniform bool use_mask = false;
uniform sampler2D road_mask : filter_linear, repeat_disable;
uniform sampler2D road_ids : filter_nearest, repeat_disable;
uniform sampler2D road_state : filter_nearest, repeat_disable;
uniform vec4 mask_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float mask_dmax = 4.0;

varying vec3 wp;

// Hash sem sin(): o sin() de argumento grande perde precisão na GPU e criava bordas retas e blocos no chão.
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

// R = escurecido, G = brilho do trecho cujo eixo é o mais próximo do texel p.
vec2 road_piece_state(ivec2 p, ivec2 sz) {
	vec4 idc = texelFetch(road_ids, clamp(p, ivec2(0), sz - 1), 0);
	int id = int(idc.r * 255.0 + 0.5) + 256 * int(idc.g * 255.0 + 0.5);
	return texelFetch(road_state, ivec2(id, 0), 0).rg;
}

// Estado bilinear entre os 4 texels em volta de tp (coordenada em texels).
vec2 road_state_bilinear(vec2 tp, ivec2 sz) {
	ivec2 i0 = ivec2(floor(tp));
	vec2 f = fract(tp);
	vec2 s00 = road_piece_state(i0, sz);
	vec2 s10 = road_piece_state(i0 + ivec2(1, 0), sz);
	vec2 s01 = road_piece_state(i0 + ivec2(0, 1), sz);
	vec2 s11 = road_piece_state(i0 + ivec2(1, 1), sz);
	return mix(mix(s00, s10, f.x), mix(s01, s11, f.x), f.y);
}

// Distância (m) ao eixo, alfa de borda (1 no miolo, 0 em 3,7 m, igual à fita antiga) e estado do trecho.
void road_field(vec3 world, out float d, out float edge_a, out float dimv, out float glow) {
	vec2 muv = (world.xz - mask_rect.xy) / mask_rect.zw;
	d = texture(road_mask, muv).r * mask_dmax;
	edge_a = clamp((3.7 - d) / 2.0, 0.0, 1.0);
	// Estado do trecho mais próximo, com bilinear à mão entre os 4 texels (senão a divisa entre um ramo
	// escurecido e outro normal sai em degraus de 0,5 m). Onde dois trechos se sobrepõem (bifurcação, ponte) o id
	// alternava de texel em texel e a bilinear sozinha virava mosaico: 4 bilineares deslocadas de 0,8 texel
	// (desfoque de ~1 m) apagam o degrau (16/11/2026).
	ivec2 sz = textureSize(road_ids, 0);
	vec2 tp = muv * vec2(sz) - 0.5;
	vec2 s = 0.25 * (road_state_bilinear(tp + vec2(-0.8, -0.8), sz) + road_state_bilinear(tp + vec2(0.8, -0.8), sz)
		+ road_state_bilinear(tp + vec2(-0.8, 0.8), sz) + road_state_bilinear(tp + vec2(0.8, 0.8), sz));
	dimv = s.x;
	glow = s.y * 0.35;
}

varying vec3 paint_p;
#define DIO
#include "res://game/art/paint.gdshaderinc"

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

// Direção da estrada no ponto (pelo gradiente da máscara de distância); sem máscara, a do eixo z.
float road_angle(vec3 world) {
	if (!use_mask) {
		return 0.0;
	}
	vec2 e = vec2(0.6, 0.0);
	vec2 muv = (world.xz - mask_rect.xy) / mask_rect.zw;
	vec2 ex = e.xy / mask_rect.zw;
	vec2 ez = e.yx / mask_rect.zw;
	vec2 g = vec2(texture(road_mask, muv + ex).r - texture(road_mask, muv - ex).r, texture(road_mask, muv + ez).r - texture(road_mask, muv - ez).r);
	return atan(g.x, -g.y);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	paint_p = wp;
}

void fragment() {
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	vec2 p = wp.xz;
	float n = vnoise(r * p * 0.09) * 0.6 + vnoise(r * p * 0.29 + 7.0) * 0.4;
	float across = abs(UV.x);
	float ea = COLOR.a;
	float dimv = dim;
	float glow = emission_boost;
	if (use_mask) {
		road_field(wp, across, ea, dimv, glow);
	}
	float ang = road_angle(wp);
	vec3 c;
	bool crisp = estilo == 1 || estilo == 3;
	if (crisp) {
		float w = max(fwidth(n), 0.004);
		c = mix(c_road_dark, c_road, 0.35 + 0.65 * smoothstep(0.34 - w, 0.34 + w, n + (vnoise(p * 1.1) - 0.5) * 0.04));
	} else {
		c = mix(c_road_dark, c_road, smoothstep(0.25, 0.75, n));
	}
	// Trilha do meio gasta e mais clara; trilhas das rodas um pouco mais escuras.
	float mid = 1.0 - smoothstep(0.7, 1.5, across + (vnoise(p * 0.7) - 0.5) * 0.5);
	c *= 1.0 + (crisp ? step(0.5, mid) * 0.07 : mid * 0.06);
	c *= 1.0 - smoothstep(0.3, 0.0, abs(across - 1.25)) * 0.07;
	if (estilo == 1 || estilo == 2) {
		// Arraste de pincel ao longo da estrada (só clareia).
		vec3 s = dabs(p / (estilo == 1 ? 1.7 : 1.3), ang + 1.5708, 0.25, vec2(1.0, 0.24));
		c *= 1.0 + s.y * smoothstep(0.4, 1.0, s.x) * (estilo == 1 ? 0.1 : 0.08);
	} else if (estilo == 3) {
		vec3 a = dabs(p / 1.2, 0.0, 6.28, vec2(0.6, 0.36));
		vec3 t1 = a.z < 0.3 ? vec3(1.08, 1.04, 0.92) : (a.z < 0.6 ? vec3(0.94, 0.96, 1.03) : vec3(1.05));
		c = mix(c, c * t1, a.y);
	}
	if (estilo == 6) {
		// Madeira crua (diorama B): veio ao longo da estrada e linhas de tábua.
		float g1 = vnoise(vec2(UV.x * 6.0, UV.y * 0.35)) * 0.6 + vnoise(vec2(UV.x * 14.0, UV.y * 0.8)) * 0.4;
		c *= 0.9 + g1 * 0.2;
		float lane = abs(fract(UV.x / 1.1 + 0.5) - 0.5) * 1.1;
		c *= mix(0.72, 1.0, smoothstep(0.0, 0.03, lane));
	}
	float e = clamp(ea + (vnoise(p * 0.8) - 0.5) * 0.35 + (vnoise(p * 2.6) - 0.5) * 0.12, 0.0, 1.0);
	float a = crisp ? smoothstep(0.42, 0.47, e) : smoothstep(0.25, 0.5, e);
	// Beirada: um tom mais escuro e frio, estreito (a sombra da relva sobre a terra), sem contorno preto.
	c = mix(mix(c * 0.78, c_edge, 0.25), c, smoothstep(crisp ? 0.47 : 0.25, crisp ? 0.6 : 0.8, e));
	// Terra de caminho das cartas: ocre/areia, não o vermelho-tijolo (a paleta puxava o vermelho para o rosa).
	float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(c, lum * vec3(1.3, 1.14, 0.52) * 1.12, sand);   // puxado para o amarelo: a luz quente, a névoa azulada e a LUT dos escuros somam um rosado
	ALBEDO = pt_flat_card(c);
	ALPHA = a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALBEDO *= mix(1.0, 0.35, dimv);
	EMISSION = ALBEDO * glow;
}

void light() {
	DIFFUSE_LIGHT += dio_diffuse(NORMAL, LIGHT, ATTENUATION, LIGHT_COLOR, LIGHT_IS_DIRECTIONAL);
}
