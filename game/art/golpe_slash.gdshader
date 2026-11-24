shader_type spatial;
// Arco de corte dos golpes dos monstros (game/art/golpes.gd).
// A malha é uma faixa em arco: UV.x corre ao longo do arco (0 no começo do golpe, 1 no fim), UV.y atravessa a faixa
// (0 por dentro, 1 na borda de fora). A ponta corre pelo arco na primeira metade da vida e deixa um rastro em
// crescente que afina e some. Bordas duras e duas faixas de cor, no guache das cartas (sem degradê de brilho).
// Sem teste de profundidade: o golpe acontece colado no herói e ficava escondido atrás do corpo dele.
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, blend_mix, shadows_disabled, fog_disabled;

uniform float age = 1.0;                                    // 0..1 da vida do arco
uniform vec4 tint : source_color = vec4(1.0, 0.9, 0.75, 1.0);
uniform float fat = 1.0;                                    // espessura relativa (golpes pesados mais grossos)

void fragment() {
	float u = UV.x;
	float v = UV.y;
	float head = smoothstep(0.0, 0.42, age) * 1.15;          // a ponta passa um pouco do fim e o rastro sai junto
	float s = (head - u) / 0.75;                             // 0 na ponta, 1 no fim do rastro
	float thick = 0.0;
	if (s >= 0.0 && s <= 1.0) {
		thick = pow(1.0 - s, 0.7) * smoothstep(0.0, 0.06, s) * fat;
	}
	thick *= 1.0 - smoothstep(0.35, 1.0, age);              // afina até sumir
	float edge = 1.0 - thick;
	float a = smoothstep(edge - 0.015, edge + 0.015, v) * step(0.02, thick);
	float core = smoothstep(edge + thick * 0.45 - 0.015, edge + thick * 0.45 + 0.015, v);
	// Contorno escuro na borda de dentro: lê sobre o herói claro e sobre o chão.
	float rim = 1.0 - smoothstep(edge + thick * 0.16 - 0.012, edge + thick * 0.16 + 0.012, v);
	ALBEDO = mix(mix(tint.rgb, vec3(1.0, 0.97, 0.88), core), tint.rgb * 0.28, rim);
	ALPHA = a * tint.a;
}
