shader_type spatial;
// Timer da carta no mundo (27/11/2026): o mesmo véu branco das cartas em vigor na tela (HandFan._make_held), por cima
// da carta deitada no chão. O que já passou fica limpo a partir do topo, no sentido horário; o véu cobre o que falta.
// O recorte é o alfa da face da carta (cantos redondos).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D mask : source_color, filter_linear_mipmap;
uniform float frac = 1.0;   // quanto falta (1 = cheio, 0 = acabou)

void fragment() {
	float a = texture(mask, UV).a;
	vec2 q = (UV - 0.5) * vec2(1.0, 1.4);
	float t = fract(atan(q.x, -q.y) / 6.2831853 + 1.0);   // 0 no topo, crescendo no sentido horário
	float aa = fwidth(t) * 1.5;
	float veil = smoothstep(1.0 - frac - aa, 1.0 - frac + aa, t) * step(0.001, frac);
	ALBEDO = vec3(1.0);
	ALPHA = 0.28 * veil * step(0.5, a);   // mais leve que o da tela: a arte da carta aparece por baixo
}
