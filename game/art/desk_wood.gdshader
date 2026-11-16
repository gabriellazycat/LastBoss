shader_type spatial;
// Tampo da mesa do menu (direção Diário): tábuas largas ao longo de X, veio da madeira, frestas escuras,
// arranhões e um verniz gasto. Tudo procedural em coordenadas do mundo, relativas a `origin`.

uniform vec3 origin = vec3(0.0);
uniform vec3 dark : source_color = vec3(0.16, 0.085, 0.045);
uniform vec3 light_wood : source_color = vec3(0.36, 0.21, 0.11);
uniform float plank_w = 0.21;

varying vec3 wp;
varying vec3 paint_p;
#include "res://game/art/paint.gdshaderinc"

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - origin;
	paint_p = wp * 6.0;
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
	return vnoise(p) * 0.5 + vnoise(p * 2.1 + 3.7) * 0.3 + vnoise(p * 4.3 + 1.1) * 0.2;
}

void fragment() {
	vec2 p = wp.xz;
	float k = floor(p.y / plank_w);
	float v = fract(p.y / plank_w);
	float off = hash(vec2(k, 1.0)) * 7.0;
	// Veio: ondas ao longo da tábua, com nós de vez em quando.
	float g = fbm(vec2(p.x * 1.6 + off, v * 6.0 + k * 3.0));
	float rings = sin((v * 18.0 + g * 6.0 + p.x * 0.6) * 3.14159) * 0.5 + 0.5;
	float tone = mix(0.25, 0.85, g) * 0.7 + rings * 0.18 + hash(vec2(k, 9.0)) * 0.22;
	vec3 col = mix(dark, light_wood, clamp(tone, 0.0, 1.0));
	// Frestas entre as tábuas e as pontas.
	float gap = smoothstep(0.0, 0.035, v) * smoothstep(1.0, 0.965, v);
	col *= mix(0.25, 1.0, gap);
	float joint = abs(fract((p.x + hash(vec2(k, 4.0)) * 2.0) / 1.7) - 0.5);
	col *= mix(0.4, 1.0, smoothstep(0.0, 0.004, joint - 0.0));
	// Arranhões finos e manchas escuras.
	float scr = smoothstep(0.985, 1.0, vnoise(vec2(p.x * 3.0 + p.y * 40.0, p.y * 3.0)));
	col = mix(col, col * 1.35, scr * 0.5);
	col *= 1.0 - smoothstep(0.6, 0.85, fbm(p * 2.2 + 11.0)) * 0.35;
	ALBEDO = paint_albedo(col, wp * 6.0, vec3(0.0, 1.0, 0.0), 6, 0.5);
	PAINT_PAPER
	ROUGHNESS = mix(0.45, 0.8, g);
	SPECULAR = 0.35;
}

void light() {
	PAINT_LIGHT
}
