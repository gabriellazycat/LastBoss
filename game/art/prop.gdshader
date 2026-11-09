shader_type spatial;
// Cenário dos looks de chão (árvores, arbustos, pedras): cor pintada nos vértices, luz padrão,
// vento (sway) e um pouco de luz atravessando as folhas. COLOR.a < 1 = parte que brilha.
#include "res://game/art/anim.gdshaderinc"
uniform float emission_boost = 0.0;
uniform float glow_strength = 3.0;
varying float glow;

void vertex() {
	glow = clamp(1.0 - COLOR.a, 0.0, 1.0);
	lb_animate(VERTEX, vec4(0.0), MODEL_MATRIX, TIME);
}

void fragment() {
	vec3 base = pow(clamp(COLOR.rgb, vec3(0.0), vec3(1.0)), vec3(2.2));
	ALBEDO = base;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	BACKLIGHT = base * 0.3;
	EMISSION = base * (emission_boost + glow * glow_strength);
}
