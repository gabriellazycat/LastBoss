shader_type spatial;
// Marcas no chão: anel com borda clara, preenchimento suave e, opcionalmente, pulso ou desenho de teia.
// Usado nas zonas (óleo, teia), na prévia da carta e nos anéis de cor sob os monstros (MultiMesh:
// a cor vem por instância em COLOR; nas MeshInstance comuns COLOR é branco e vale o tint).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float edge = 0.12;      // espessura da borda, em fração do raio
uniform float fill = 0.18;      // opacidade do preenchimento
uniform float pulse = 0.0;      // 0..1: o preenchimento respira e uma onda corre para fora
uniform float pattern = 0.0;    // 1 = teia (raios e anéis)
uniform float glow = 1.0;       // brilho extra da borda (acima de 1 entra no bloom)
varying vec4 col;

void vertex() {
	col = COLOR;
}

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	float d = length(q);
	if (d > 1.0) {
		discard;
	}
	float aa = fwidth(d) * 1.5;
	// Feltro (26/11/2026): borda em costura tracejada (os pontos acompanham a volta), sem brilho no bloom.
	float ang = atan(q.y, q.x);
	float stitch = step(0.45, fract(ang / 6.2831853 * 48.0));
	float rim = smoothstep(1.0 - edge - aa, 1.0 - edge, d) * (1.0 - smoothstep(1.0 - aa, 1.0, d)) * stitch;
	float inner = fill * mix(0.45, 1.0, smoothstep(0.0, 1.0, d));
	if (pulse > 0.0) {
		float w = fract(TIME * 0.7);
		inner += pulse * 0.35 * smoothstep(0.12, 0.0, abs(d - w)) * (1.0 - w);
		inner *= 1.0 + pulse * 0.25 * sin(TIME * 5.0);
	}
	if (pattern > 0.5) {
		float a = atan(q.y, q.x);
		float spokes = smoothstep(0.05, 0.0, abs(sin(a * 4.0)) * d);
		float rings = smoothstep(0.07, 0.0, abs(fract(d * 4.0) - 0.5));
		inner += (spokes + rings) * 0.45;
	}
	vec4 c = tint * col;
	ALBEDO = c.rgb * mix(1.0, min(glow, 1.15), rim);   // feltro: material fosco, quase sem bloom
	ALPHA = clamp(rim * 0.9 + inner, 0.0, 1.0) * c.a;
}
