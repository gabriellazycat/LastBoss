shader_type spatial;
// Chão da direção "Aventura" (looks de chão 7 e 8), no espírito do Risk of Rain 2: zonas grandes de cor bem
// separadas (relva, relva seca, terra, pedra), relevo falso pela derivada do ruído (a luz rasante desenha o
// terreno), salpicos pequenos de pedra e flores, sem textura de foto e sem pinceladas. Luz padrão da Godot,
// para o chão e os modelos dividirem a mesma luz, sombra e névoa.
uniform vec3 c_grass : source_color = vec3(0.24, 0.42, 0.3);
uniform vec3 c_grass2 : source_color = vec3(0.42, 0.48, 0.26);
uniform vec3 c_dirt : source_color = vec3(0.52, 0.43, 0.31);
uniform vec3 c_rock : source_color = vec3(0.6, 0.58, 0.55);
uniform vec3 c_fleck : source_color = vec3(0.95, 0.85, 0.55);
uniform float dirt_amount = 0.35;
uniform float rock_amount = 0.25;
uniform float fleck_amount = 0.5;
uniform float bump = 0.6;
uniform float roughness = 0.9;

varying vec3 wp;
varying vec3 paint_p;
#include "res://game/art/paint.gdshaderinc"

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
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
// Altura falsa do terreno (só para a luz).
float hgt(vec2 p) {
	return fbm(p * 0.05) * 1.0 + fbm(p * 0.22 + 31.0) * 0.25;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	paint_p = wp;
}

void fragment() {
	vec2 p = wp.xz;
	float zone = fbm(p * 0.012);
	float z2 = fbm(p * 0.035 + 7.0);
	vec3 col = mix(c_grass, c_grass2, smoothstep(0.42, 0.62, zone));
	// Variação de valor dentro da relva: manchas grandes um pouco mais claras e mais escuras.
	col *= 0.85 + 0.3 * z2;
	float dirt = smoothstep(0.62, 0.7, fbm(p * 0.02 + 41.0)) * dirt_amount * 2.0;
	col = mix(col, c_dirt * (0.85 + 0.3 * z2), clamp(dirt, 0.0, 1.0));
	float rk = smoothstep(0.7, 0.76, fbm(p * 0.045 + 93.0)) * rock_amount * 3.0;
	col = mix(col, c_rock * (0.8 + 0.4 * vnoise(p * 1.7)), clamp(rk, 0.0, 1.0));
	// Salpicos: pedrinhas e flores em células, só onde há relva.
	vec2 cell = floor(p * 1.6);
	float h = hash(cell);
	vec2 fp = fract(p * 1.6) - 0.5 - (vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5) * 0.6;
	float fl = (1.0 - smoothstep(0.05, 0.09, length(fp))) * step(0.93, h) * (1.0 - clamp(dirt + rk, 0.0, 1.0));
	col = mix(col, c_fleck, fl * fleck_amount);
	// Relevo: normal pela derivada da altura em espaço de mundo, convertida para o espaço da câmera.
	float e = 0.35;
	float hx = hgt(p + vec2(e, 0.0)) - hgt(p - vec2(e, 0.0));
	float hz = hgt(p + vec2(0.0, e)) - hgt(p - vec2(0.0, e));
	vec3 nw = normalize(vec3(-hx * bump * 3.0, 1.0, -hz * bump * 3.0));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
	int pk = dirt > 0.5 ? 1 : (rk > 0.5 ? 2 : 0);
	ALBEDO = paint_albedo(col, wp, vec3(0.0, 1.0, 0.0), pk, 1.4);
	PAINT_PAPER
	ROUGHNESS = roughness;
	SPECULAR = 0.15;
}

void light() {
	PAINT_LIGHT
}
