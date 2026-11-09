shader_type spatial;
// Look 3 "Pintado": a pintura está nas cores dos vértices (oclusão, céu, bordas); a luz só aquece e esfria.
#include "res://game/art/anim.gdshaderinc"
uniform float emission_boost = 0.0;
uniform float flash = 0.0;
uniform float glow_strength = 3.0;
uniform vec3 warm : source_color = vec3(1.0, 0.92, 0.8);
uniform vec3 cool : source_color = vec3(0.55, 0.55, 0.85);
varying vec4 custom;
varying float glow;

void vertex() {
	custom = lb_custom(INSTANCE_CUSTOM);
	glow = clamp(1.0 - COLOR.a, 0.0, 1.0);
	lb_animate(VERTEX, custom, MODEL_MATRIX, TIME);
}

void fragment() {
	vec3 base = pow(clamp(COLOR.rgb, vec3(0.0), vec3(1.0)), vec3(2.2));
	float f = clamp(max(custom.x, flash), 0.0, 1.0);
	ALBEDO = mix(base, vec3(1.0, 0.96, 0.92), f);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = base * (emission_boost + glow * glow_strength) + vec3(1.0, 0.9, 0.85) * f * 1.2;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float l = smoothstep(-0.6, 1.0, ndl) * ATTENUATION;
	// A parte fria só vem do sol/lua: de uma luz pontual ela clareava tudo no alcance, sem cair com a distância.
	DIFFUSE_LIGHT += mix(cool * 0.75 * (LIGHT_IS_DIRECTIONAL ? 1.0 : 0.0), warm, l) * LIGHT_COLOR / PI;
}
