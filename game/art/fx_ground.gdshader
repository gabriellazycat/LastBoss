shader_type spatial;
// Marcas no chão dos efeitos novos (rodada visual 20/11/2026): substituem o anel genérico (ring.gdshader) quando
// Efeitos no chão (fx2.gd). Um PlaneMesh 2x2 escalado pelo raio; kind escolhe o desenho:
//   0 onda de choque (age 0..1 vinda do script), 1 teia, 2 óleo em chamas, 3 chão em brasa, 4 fonte/água,
//   5 círculo de feitiço (age 0..1), 6 área genérica (borda pintada), 7 marca que fica depois do impacto (variant:
//   1 sombra, 2 morte, 3 controle, 4 ouro), 8 raio do feitiço enquanto a carta voa (age 0..1), 9 zona de moedas.
// life (0..1) apaga a marca/zona inteira (entrada e saída animadas pelo script).
// paint = 1: bordas duras e faixas (guache); 0: macio e com brilho.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform int kind = 0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float age = 0.0;
uniform float paint = 0.0;
uniform float glow = 1.0;
uniform float seed = 0.0;
uniform int variant = 0;
uniform float life = 1.0;

float g_h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float g_vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(g_h21(i), g_h21(i + vec2(1.0, 0.0)), f.x), mix(g_h21(i + vec2(0.0, 1.0)), g_h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float g_fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * g_vn(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

float g_line(float dist, float w) {
	float aa = fwidth(dist) * 1.2;
	return 1.0 - smoothstep(w, w + aa, dist);
}

void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	float d = length(q);
	float ang = atan(q.y, q.x);
	bool hard = paint > 0.5;
	vec3 c = tint.rgb;
	float a = 0.0;
	float hot = 0.0;
	if (kind == 0) {
		// Onda de choque (27/11/2026): clarão no centro, frente rápida e brilhante, segunda onda de poeira mais lenta
		// e riscos que saem do centro.
		float k = age;
		float r = mix(0.1, 1.0, 1.0 - pow(1.0 - k, 3.0));
		float r2 = mix(0.05, 0.82, 1.0 - pow(1.0 - k, 2.0));
		float n = g_fbm(vec2(ang * 2.2 + seed * 9.0, d * 3.0 + seed));
		float w = mix(0.22, 0.03, k) * (0.6 + n * 0.8);
		float ring = hard ? step(abs(d - r), w) : smoothstep(w, 0.0, abs(d - r));
		float ring2 = (hard ? step(abs(d - r2), w * 0.7) : smoothstep(w * 0.7, 0.0, abs(d - r2))) * 0.45 * step(0.4, n);
		float rays = smoothstep(0.72, 0.95, g_vn(vec2(ang * 9.0 + seed * 5.0, seed))) * step(d, r) * smoothstep(r * 0.15, r * 0.9, d);
		if (hard) rays = step(0.5, rays);
		float flash = smoothstep(r, 0.0, d) * (1.0 - smoothstep(0.0, 0.3, k));
		float dust = smoothstep(r, r * 0.4, d) * 0.3 * step(0.45, n);
		a = (max(ring, ring2) + dust + rays * 0.55 + flash * 0.65) * (1.0 - k * k);
		c = mix(tint.rgb, vec3(1.0), max(ring * 0.45, flash * 0.7));
		hot = max(ring, flash);
	} else if (kind == 1) {
		// Teia: raios e espiral poligonal entre eles, fios finos com gotas de orvalho.
		if (d > 1.0) discard;
		float N = 12.0;
		float sec = TAU / N;
		float aa = mod(ang + PI + seed, sec);
		float to_spoke = min(aa, sec - aa);
		float spoke = g_line(d * sin(to_spoke), 0.006 + 0.008 * (1.0 - d)) * step(0.03, d);
		float dp = d * cos(aa - sec * 0.5) / cos(sec * 0.5);
		float sag = 0.025 * sin(aa / sec * PI);
		float rf = (dp + sag) * 7.0;
		float rd = abs(fract(rf) - 0.5) / 7.0;
		float ring = g_line(rd, 0.0045) * step(0.1, dp) * step(dp, 0.95);
		float hub = g_line(abs(d - 0.06), 0.012);
		float th = max(max(spoke, ring), hub);
		float dew = step(0.94, g_h21(floor(vec2(rf, ang * 4.0)))) * g_line(length(vec2(fract(rf) - 0.5, fract(ang * 4.0) - 0.5)), 0.12) * ring;
		float shadow = g_line(rd, 0.012) * step(0.1, dp) * 0.18;
		float fade = smoothstep(1.0, 0.85, d);
		a = max(th * 0.92, shadow) * fade + dew;
		c = mix(vec3(0.08, 0.07, 0.1), mix(tint.rgb, vec3(1.0), 0.4), step(0.5, th + dew));
		hot = dew;
	} else if (kind == 2) {
		// Óleo fervendo em chamas: poça escura de borda irregular, brilho furta-cor, veios em brasa e borda acesa.
		float n = g_fbm(q * 2.6 + seed * 5.0);
		float edge = 0.86 + (n - 0.5) * 0.28;
		float m = edge - d;
		if (m < 0.0) discard;
		vec3 oil = vec3(0.07, 0.045, 0.03);
		float sh = g_fbm(q * 3.5 + vec2(TIME * 0.12, -TIME * 0.07));
		vec3 irid = 0.5 + 0.5 * cos(6.2831 * (sh * 1.6 + vec3(0.0, 0.33, 0.67)));
		c = oil + irid * 0.12 * smoothstep(0.45, 0.7, sh);
		float veins = smoothstep(0.58, 0.72, g_fbm(q * 4.5 - vec2(0.0, TIME * 0.25) + seed));
		float rim = smoothstep(0.12, 0.0, m);
		float heat = max(veins * 0.85, rim) * (0.85 + 0.15 * sin(TIME * 7.0 + n * 12.0));
		if (hard) heat = floor(heat * 3.0) / 2.0;
		c = mix(c, mix(vec3(0.9, 0.25, 0.05), vec3(1.0, 0.75, 0.25), heat), heat);
		float hi = smoothstep(0.82, 0.9, g_vn(q * 6.0 + TIME * 0.3)) * 0.4;
		c += hi;
		a = (hard ? 0.95 : smoothstep(0.0, 0.05, m) * 0.95);
		hot = heat;
	} else if (kind == 3) {
		// Chão queimando: terra escura com rachaduras em brasa que pulsam.
		float n = g_fbm(q * 2.0 + seed * 3.0);
		float edge = 0.9 + (n - 0.5) * 0.3;
		float m = edge - d;
		if (m < 0.0) discard;
		vec2 cell = q * 5.0;
		float cr = abs(g_vn(cell + seed) - 0.5) * 2.0;
		float crack = smoothstep(0.12, 0.0, cr) * (0.6 + 0.4 * sin(TIME * 3.0 + n * 9.0));
		if (hard) crack = step(0.5, crack);
		c = mix(vec3(0.1, 0.06, 0.05), vec3(1.0, 0.45, 0.1), crack);
		a = mix(0.55, 0.9, crack) * smoothstep(0.0, 0.12, m);
		hot = crack;
	} else if (kind == 4) {
		// Água: ondas que saem do centro, espuma na borda, brilhos.
		float n = g_fbm(q * 3.0 + TIME * 0.2);
		float edge = 0.92 + (n - 0.5) * 0.12;
		float m = edge - d;
		if (m < 0.0) discard;
		float rip = smoothstep(0.08, 0.0, abs(fract(d * 4.0 - TIME * 0.6) - 0.5) - 0.38);
		float foam = smoothstep(0.08, 0.0, m);
		float spark = smoothstep(0.9, 0.97, g_vn(q * 9.0 + TIME * 0.8));
		if (hard) { rip = step(0.5, rip); foam = step(0.5, foam); }
		c = mix(tint.rgb * 0.7, vec3(0.85, 0.95, 1.0), max(max(rip * 0.6, foam), spark));
		a = 0.55 + 0.35 * max(rip, foam);
		hot = spark;
	} else if (kind == 5) {
		// Círculo de feitiço: dois anéis, runas em volta e um raio que gira; acende e some com age.
		float k = age;
		float r1 = g_line(abs(d - 0.92), 0.025);
		float r2 = g_line(abs(d - 0.7), 0.015);
		float seg = floor((ang + PI + TIME * 0.6) / TAU * 16.0);
		float glyph = step(0.35, g_h21(vec2(seg, seed))) * step(0.74, d) * step(d, 0.88) * step(0.25, fract((ang + PI + TIME * 0.6) / TAU * 16.0)) * step(fract((ang + PI + TIME * 0.6) / TAU * 16.0), 0.75);
		float tri = g_line(abs(d * cos(mod(ang - TIME * 0.4, TAU / 3.0) - PI / 3.0) - 0.35), 0.012) * step(d, 0.7);
		float th = max(max(r1, r2), max(glyph * 0.8, tri));
		float in_a = smoothstep(0.0, 0.15, k) * (1.0 - smoothstep(0.6, 1.0, k));
		a = th * in_a + smoothstep(1.0, 0.0, d) * 0.12 * in_a;
		c = mix(tint.rgb, vec3(1.0), th * 0.4);
		hot = th;
	} else if (kind == 7) {
		// Marca do impacto: chão marcado na cor da família, com rachaduras acesas que esfriam (life vai a 0).
		float n = g_fbm(q * 2.2 + seed * 3.0);
		float edge = 0.9 + (n - 0.5) * (variant == 3 ? 0.55 : 0.28);
		float m = edge - d;
		if (m < 0.0) discard;
		float cr = abs(g_vn(vec2(ang * 5.0 + seed * 3.0, d * 2.5 + seed)) - 0.5) * 2.0;
		float crack = smoothstep(0.09, 0.0, cr) * smoothstep(0.08, 0.3, d) * smoothstep(0.0, 0.15, m);
		float rim = smoothstep(0.1, 0.0, abs(d - 0.7 - (n - 0.5) * 0.1));
		vec3 base = mix(vec3(0.06, 0.05, 0.06), tint.rgb * 0.25, 0.5);
		float heat = life * life;
		if (variant == 1) {
			// Sombra: anel de runas queimado e rachaduras roxas.
			float seg = fract((ang + PI) / TAU * 14.0 + seed);
			float glyph = step(0.3, g_h21(vec2(floor((ang + PI) / TAU * 14.0 + seed), seed))) * step(0.2, seg) * step(seg, 0.8) * smoothstep(0.05, 0.0, abs(d - 0.7));
			crack = max(crack, max(glyph, rim * 0.6));
		} else if (variant == 2) {
			// Morte: mancha tóxica com bolhas claras.
			float bub = step(0.93, g_h21(floor(q * 9.0 + seed))) * smoothstep(0.35, 0.1, length(fract(q * 9.0 + seed) - 0.5));
			crack = max(crack, bub);
			base = mix(base, tint.rgb * 0.35, 0.5);
		} else if (variant == 3) {
			// Controle: piche brilhante, sem rachadura acesa; reflexo claro em manchas.
			crack = smoothstep(0.84, 0.9, g_vn(q * 5.0 + seed)) * 0.6;
			base = vec3(0.04, 0.035, 0.05);
			heat = 1.0;
		} else if (variant == 4) {
			// Ouro: purpurina dourada que pisca.
			float gl = step(0.9, g_h21(floor(q * 14.0 + seed))) * (0.5 + 0.5 * sin(TIME * 9.0 + g_h21(floor(q * 14.0)) * 30.0));
			crack = max(crack * 0.5, gl);
			base = mix(base, tint.rgb * 0.5, 0.4);
		}
		if (hard) crack = step(0.5, crack);
		c = mix(base, mix(tint.rgb, vec3(1.0), 0.25), crack * heat);
		a = mix(0.6, 0.95, crack) * smoothstep(0.0, 0.1, m);
		hot = crack * heat;
	} else if (kind == 8) {
		// Raio exato do feitiço enquanto a carta voa: borda firme na distância do raio, uma frente que fecha para o
		// centro e marcas que giram; acende conforme age vai a 1 (pouso).
		if (d > 1.0) discard;
		float k = age;
		float rim = g_line(abs(d - 0.965), 0.03);
		float sweep = smoothstep(0.14, 0.0, abs(d - mix(1.0, 0.0, k)));
		float tick = step(0.5, fract((ang + PI) / TAU * 24.0 + TIME * 0.6)) * step(0.87, d) * step(d, 0.92);
		float fill = (0.1 + 0.25 * k) * step(d, 0.95);
		a = rim + sweep * 0.7 + tick * 0.55 + fill;
		c = mix(tint.rgb, vec3(1.0), max(rim * 0.35, sweep * 0.5));
		hot = max(rim, sweep);
	} else if (kind == 9) {
		// Zona das moedas amaldiçoadas: borda dourada e purpurina.
		if (d > 1.0) discard;
		float n = g_fbm(vec2(ang * 3.0 + seed * 7.0, TIME * 0.2));
		float edge = 0.93 + (n - 0.5) * 0.08;
		float rim = hard ? step(abs(d - edge), 0.04) : smoothstep(0.06, 0.0, abs(d - edge));
		float gl = step(0.92, g_h21(floor(q * 12.0 + seed))) * (0.5 + 0.5 * sin(TIME * 7.0 + g_h21(floor(q * 12.0)) * 40.0)) * step(d, edge);
		a = rim * 0.9 + gl * 0.9 + smoothstep(edge, 0.0, d) * 0.16 * step(d, edge);
		c = mix(tint.rgb, vec3(1.0, 0.95, 0.75), gl);
		hot = max(rim, gl);
	} else {
		// Área genérica: preenchimento leve e borda pintada irregular.
		float n = g_fbm(vec2(ang * 3.0 + seed * 7.0, TIME * 0.2));
		float edge = 0.93 + (n - 0.5) * 0.08;
		if (d > 1.0) discard;
		float rim = hard ? step(abs(d - edge), 0.04) : smoothstep(0.06, 0.0, abs(d - edge));
		a = rim * 0.9 + smoothstep(edge, 0.0, d) * 0.14 * step(d, edge);
		hot = rim;
	}
	a *= tint.a * life;
	if (a < 0.01) discard;
	ALBEDO = c * (hard ? 1.0 : mix(1.0, glow, hot));
	ALPHA = clamp(a, 0.0, 1.0);
}
