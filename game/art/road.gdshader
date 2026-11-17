shader_type spatial;
// Estrada dos looks de cenário: textura ao longo do caminho, bordas que se dissolvem na grama
// (COLOR.a = 0 na borda externa), sulcos de roda mais escuros.
// Opaca com recorte (alpha scissor): trechos que se sobrepõem (bifurcações, emendas) não somam transparência,
// que deixava manchas claras de borda reta no chão.
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nor : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float scale = 0.25;
uniform vec3 tint : source_color = vec3(1.0);
uniform float rut = 0.25;
uniform float normal_strength = 1.0;
uniform float emission_boost = 0.0;
// Ramo fechado: escurece sem sair da passada opaca (transparência fazia os ramos piscarem).
uniform float dim = 0.0;
uniform vec3 edge_color : source_color = vec3(0.4, 0.35, 0.3);

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
varying vec3 paint_p;
#include "res://game/art/paint.gdshaderinc"

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

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	paint_p = wp;
}

void fragment() {
	// UV.x: metros através (0 no centro), UV.y: metros ao longo.
	vec2 uv = vec2(UV.x, UV.y) * scale;
	float across = abs(UV.x);
	float ea = COLOR.a;
	float dimv = dim;
	float glow = emission_boost;
	if (use_mask) {
		// Sem eixo de fita: a textura corre pelo mundo.
		road_field(wp, across, ea, dimv, glow);
		uv = wp.xz * scale;
	}
	vec3 c = texture(tex, uv).rgb * tint;
	float ruts = smoothstep(0.35, 0.0, abs(across - 0.85)) * rut;
	c *= 1.0 - ruts;
	// Borda irregular: o ruído recorta a transparência.
	float e = clamp(ea + (vnoise(wp.xz * 1.3) - 0.5) * 0.7, 0.0, 1.0);
	c = mix(edge_color * c * 1.4, c, smoothstep(0.2, 0.9, ea));
	c = paint_albedo(c, wp, vec3(0.0, 1.0, 0.0), 1, 1.2);
	ALBEDO = c;
	PAINT_PAPER
	NORMAL_MAP = texture(nor, uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	ALPHA = smoothstep(0.25, 0.5, e);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALBEDO *= mix(1.0, 0.35, dimv);
	EMISSION = c * glow;
}

void light() {
	PAINT_LIGHT
}
