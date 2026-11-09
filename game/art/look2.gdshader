shader_type spatial;
// Look 2 "Cartum": sombra em duas faixas, brilho em ponto e linha de contorno (look2_outline).
#include "res://game/art/anim.gdshaderinc"
uniform float emission_boost = 0.0;
uniform float flash = 0.0;
uniform float glow_strength = 3.0;
uniform vec3 shadow_tint : source_color = vec3(0.55, 0.45, 0.85);
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
	ROUGHNESS = 0.9;
	SPECULAR = 0.0;
	EMISSION = base * (emission_boost + glow * glow_strength) + vec3(1.0, 0.9, 0.85) * f * 1.2;
}

void light() {
	float ndl = dot(NORMAL, LIGHT) * ATTENUATION;
	float band = smoothstep(0.0, 0.03, ndl) * 0.62 + smoothstep(0.55, 0.58, ndl) * 0.38;
	if (!LIGHT_IS_DIRECTIONAL) {
		band = smoothstep(0.0, 0.35, ndl);
	}
	vec3 lit = mix(shadow_tint * 0.55, vec3(1.0), band);
	DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;
	vec3 h = normalize(LIGHT + VIEW);
	// Brilho em degrau só com luz direcional: com luz pontual ele desenhava elipses duras no chão.
	if (LIGHT_IS_DIRECTIONAL) {
		SPECULAR_LIGHT += step(0.97, dot(NORMAL, h)) * ATTENUATION * LIGHT_COLOR * 0.35 * SPECULAR_AMOUNT;
	}
	float rim = step(0.72, 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0)) * step(0.1, ndl);
	DIFFUSE_LIGHT += rim * 0.35 * LIGHT_COLOR * (LIGHT_IS_DIRECTIONAL ? 1.0 : ATTENUATION);
}
