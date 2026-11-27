shader_type spatial;
// Luz no chão dos efeitos (27/11/2026): disco de luz somada, macio, que acompanha as luzes de impacto e das zonas
// (fx2.gd). Garante a poça de cor no chão mesmo onde a luz real pega pouco (feltro claro, qualidade baixa).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.6, 0.25, 1.0);
uniform float energy = 0.0;

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	float d = length(q);
	float a = pow(clamp(1.0 - d, 0.0, 1.0), 2.0);
	if (a * energy < 0.002) {
		discard;
	}
	ALBEDO = tint.rgb;
	ALPHA = clamp(a * energy, 0.0, 1.0);
}
