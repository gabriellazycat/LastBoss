shader_type spatial;
// Look 1 "Argila": massinha fosca, luz envolvente macia, um brilho de cera no topo.
#include "res://game/art/anim.gdshaderinc"
uniform float emission_boost = 0.0;
uniform float flash = 0.0;
uniform float glow_strength = 3.0;
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
	ROUGHNESS = 0.55;
	SPECULAR = 0.3;
	EMISSION = base * (emission_boost + glow * glow_strength) + vec3(1.0, 0.9, 0.85) * f * 1.2;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrap = clamp((ndl + 0.45) / 1.45, 0.0, 1.0);
	wrap = wrap * wrap * (3.0 - 2.0 * wrap);
	// Terminador quente (efeito de luz passando pela massa).
	float term = exp(-ndl * ndl * 9.0) * 0.22;
	DIFFUSE_LIGHT += (wrap + term * vec3(1.0, 0.45, 0.3) * 2.0) * ATTENUATION * LIGHT_COLOR / PI;
	vec3 h = normalize(LIGHT + VIEW);
	SPECULAR_LIGHT += pow(max(dot(NORMAL, h), 0.0), 24.0) * 0.18 * ATTENUATION * LIGHT_COLOR * SPECULAR_AMOUNT;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	DIFFUSE_LIGHT += rim * 0.25 * ATTENUATION * LIGHT_COLOR * smoothstep(-0.3, 0.3, ndl) * 0.3;
}
