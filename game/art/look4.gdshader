shader_type spatial;
// Look 4 "Sombrio": PBR (rugosidade e metal por vértice em UV2), contorno frio e brilhos fortes.
#include "res://game/art/anim.gdshaderinc"
uniform float emission_boost = 0.0;
uniform float flash = 0.0;
uniform float glow_strength = 5.0;
uniform vec3 rim_color : source_color = vec3(0.55, 0.7, 1.0);
uniform float rim_strength = 0.6;
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
	ROUGHNESS = clamp(UV2.x, 0.05, 1.0);
	METALLIC = UV2.y;
	RIM = rim_strength;
	RIM_TINT = 0.3;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = base * (emission_boost + glow * glow_strength) + rim_color * fr * 0.12 * (1.0 - glow) + vec3(1.0, 0.9, 0.85) * f * 1.2;
}
