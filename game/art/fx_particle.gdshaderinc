// Efeitos novos (rodada visual 20/11/2026, docs/RODADA_VISUAL_2026-11-20.md): partículas desenhadas no shader, em vez
// da bolinha de 64 px. Cada quad é uma figura feita por conta (chama, fumaça, faísca, brasa, estrela, lasca, cruz),
// recortada por ruído que corre com o tempo e com a idade da partícula (INSTANCE_CUSTOM.y), então fica nítida em qualquer
// tamanho. Incluído por fx_particle_add.gdshader (brilho, soma) e fx_particle_mix.gdshader (pintado, tinta por cima).
// paint = 1: bordas duras e faixas de cor (guache das cartas); paint = 0: bordas macias e brilho que entra no bloom.
// axis_mode: 0 billboard (gira com INSTANCE_CUSTOM.x); 1 alinhado ao eixo Y do nó (partícula com align_y = velocidade);
// 2 alinhado ao eixo Z do nó (rastro de projétil: o nó olha para o alvo).

uniform int shape = 0;          // 0 chama, 1 fumaça, 2 faísca, 3 brasa, 4 estrela, 5 lasca, 6 cruz, 7 anel, 8 fio, 9 núcleo, 10 moeda
uniform float paint = 0.0;
uniform float glow = 1.0;
uniform int axis_mode = 0;
uniform float width = 1.0;      // largura do quad nos modos 1 e 2 (o comprimento vem da escala do eixo)
uniform vec4 tint : source_color = vec4(1.0);

varying vec2 vq;
varying float age;
varying float seed;
varying vec4 vcol;
varying float spin;

float fx_h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float fx_vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(fx_h21(i), fx_h21(i + vec2(1.0, 0.0)), f.x), mix(fx_h21(i + vec2(0.0, 1.0)), fx_h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fx_fbm(vec2 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * fx_vn(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	age = INSTANCE_CUSTOM.y;
	spin = INSTANCE_CUSTOM.x;
	seed = fract(float(INSTANCE_ID) * 0.618034 + MODEL_MATRIX[3].x * 0.137);
	vcol = COLOR * tint;
	vq = VERTEX.xy * 2.0;
	vec3 center = MODEL_MATRIX[3].xyz;
	vec3 cam_pos = INV_VIEW_MATRIX[3].xyz;
	vec3 world;
	if (axis_mode == 0) {
		float s = length(MODEL_MATRIX[0].xyz);
		float ca = cos(INSTANCE_CUSTOM.x);
		float sa = sin(INSTANCE_CUSTOM.x);
		vec2 v = vec2(VERTEX.x * ca - VERTEX.y * sa, VERTEX.x * sa + VERTEX.y * ca) * s;
		world = center + INV_VIEW_MATRIX[0].xyz * v.x + INV_VIEW_MATRIX[1].xyz * v.y;
	} else {
		vec3 ax = axis_mode == 1 ? MODEL_MATRIX[1].xyz : MODEL_MATRIX[2].xyz;
		float len = length(ax);
		vec3 dir = ax / max(len, 0.0001);
		vec3 right = normalize(cross(dir, normalize(cam_pos - center)) + vec3(0.0001));
		float w = width * (axis_mode == 1 ? length(MODEL_MATRIX[0].xyz) : 1.0);
		world = center + right * VERTEX.x * w + dir * VERTEX.y * len;
	}
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
}

vec3 fx_fire_ramp(float h) {
	vec3 c0 = vec3(0.55, 0.07, 0.03);
	vec3 c1 = vec3(1.0, 0.38, 0.07);
	vec3 c2 = vec3(1.0, 0.78, 0.28);
	vec3 c3 = vec3(1.0, 0.97, 0.82);
	if (h < 0.33) return mix(c0, c1, h / 0.33);
	if (h < 0.66) return mix(c1, c2, (h - 0.33) / 0.33);
	return mix(c2, c3, (h - 0.66) / 0.34);
}

void fragment() {
	vec2 q = vq;
	float d = length(q);
	float a = 0.0;
	vec3 c = vcol.rgb;
	float hot = 0.0;   // quanto da cor passa do branco (entra no bloom no modo brilhante)
	bool hard = paint > 0.5;
	if (shape == 0) {
		// Chama: gota com a ponta para cima, lambida por ruído que sobe.
		float y = q.y * 0.5 + 0.5;
		float w = mix(0.9, 0.06, pow(clamp(y, 0.0, 1.0), 0.85));
		float bottom = y < 0.32 ? (0.32 - y) / 0.32 : 0.0;
		float body = 1.0 - length(vec2(q.x / max(w, 0.04), bottom));
		float n = fx_fbm(vec2(q.x * 1.7 + seed * 17.0, q.y * 1.3 - TIME * 2.8 - seed * 5.0));
		float m = body + (n - 0.5) * 0.95 - age * 0.8 + 0.18;
		a = hard ? smoothstep(0.0, 0.03, m) : smoothstep(0.0, 0.3, m);
		float h = clamp(m * 1.05 + (1.0 - y) * 0.2, 0.0, 1.0) * (1.0 - age * 0.6);
		if (hard) {
			h = floor(h * 4.0) / 3.0;
		}
		c = fx_fire_ramp(h) * vcol.rgb;
		hot = h;
	} else if (shape == 1) {
		// Fumaça / poeira: nuvem roída pelo ruído, mais clara em cima.
		float n = fx_fbm(q * 1.7 + seed * 13.0 + vec2(0.0, -TIME * 0.35));
		float m = 1.0 - d + (n - 0.5) * 0.85 - age * 0.55;
		a = hard ? smoothstep(0.0, 0.04, m) : smoothstep(0.0, 0.45, m);
		float sh = clamp(0.5 + q.y * 0.35 + (n - 0.5) * 0.5, 0.0, 1.0);
		if (hard) {
			sh = floor(sh * 3.0) / 2.0;
		}
		c = vcol.rgb * mix(0.62, 1.12, sh);
	} else if (shape == 2) {
		// Faísca / rastro: risco fino com núcleo claro.
		float m = 1.0 - length(vec2(q.x, max(abs(q.y) - 0.15, 0.0) * 1.15));
		a = hard ? smoothstep(0.0, 0.06, m) : smoothstep(0.0, 0.6, m);
		float core = smoothstep(0.35, 0.8, m);
		c = mix(vcol.rgb, vec3(1.0, 0.98, 0.9), core);
		hot = 0.6 + core * 0.4;
	} else if (shape == 3) {
		// Brasa / centelha: ponto com halo.
		float m = 1.0 - d;
		float core = smoothstep(0.45, 0.62, m);
		float halo = pow(max(m, 0.0), 2.2) * 0.65;
		a = hard ? core : max(core, halo);
		c = mix(vcol.rgb, vec3(1.0), core * 0.55);
		hot = core;
	} else if (shape == 4) {
		// Estrela de quatro pontas (brilho de magia, cura, nível).
		vec2 aq = abs(q);
		float st = 1.0 - (sqrt(aq.x) + sqrt(aq.y));
		float halo = (1.0 - d) * 0.35;
		a = hard ? smoothstep(0.0, 0.04, st) : clamp(smoothstep(0.0, 0.25, st) + max(halo, 0.0) * (1.0 - age), 0.0, 1.0);
		c = mix(vcol.rgb, vec3(1.0), smoothstep(0.2, 0.6, st));
		hot = 0.8;
	} else if (shape == 5) {
		// Lasca: polígono irregular com um lado claro e outro escuro (madeira, pedra, osso, escudo).
		float ang = atan(q.y, q.x);
		float r = 0.55 + 0.4 * fx_vn(vec2(ang * 1.3 + seed * 31.0, seed * 7.0));
		a = hard ? step(d, r) : smoothstep(r, r - 0.08, d);
		float lit = step(0.0, q.x * 0.6 + q.y * 0.8 + (seed - 0.5) * 0.4);
		c = vcol.rgb * mix(0.62, 1.08, lit);
	} else if (shape == 6) {
		// Cruz (cura).
		vec2 aq = abs(q);
		float m = min(max(0.82 - aq.y, 0.0) * step(aq.x, 0.26), 1.0);
		m = max(m, max(0.82 - aq.x, 0.0) * step(aq.y, 0.26));
		float edge = min(0.26 - min(aq.x, aq.y), 0.82 - max(aq.x, aq.y));
		a = hard ? step(0.0, edge) : smoothstep(-0.02, 0.08, edge);
		c = mix(vcol.rgb, vec3(1.0), smoothstep(0.1, 0.25, edge) * 0.2);
		hot = 0.5;
	} else if (shape == 7) {
		// Anel fino (onda de magia).
		float rd = abs(d - 0.8);
		a = hard ? step(rd, 0.08) : smoothstep(0.16, 0.0, rd);
		hot = 0.7;
	} else if (shape == 9) {
		// Núcleo de impacto (27/11/2026): bola de luz macia com miolo quase branco; a borda tremula com ruído.
		float n = fx_vn(vec2(atan(q.y, q.x) * 2.5 + seed * 11.0, TIME * 6.0));
		float m = 1.0 - d / (0.82 + n * 0.18);
		float core = smoothstep(0.35, 0.85, m);
		a = hard ? step(0.0, m) : clamp(pow(max(m, 0.0), 1.6) * 1.4, 0.0, 1.0);
		c = mix(vcol.rgb, vec3(1.0, 0.98, 0.92), core * 0.8);
		hot = 0.7 + core * 0.3;
	} else if (shape == 10) {
		// Moeda: disco dourado que gira (a largura acompanha o giro), borda escura e brilho.
		float sx = abs(cos(spin * 3.0 + seed * 6.0)) * 0.85 + 0.15;
		vec2 p = vec2(q.x / sx, q.y);
		float r = length(p);
		a = hard ? step(r, 0.8) : smoothstep(0.82, 0.74, r);
		float rim = smoothstep(0.6, 0.72, r);
		c = mix(vec3(1.0, 0.84, 0.35), vec3(0.62, 0.4, 0.1), rim) * vcol.rgb;
		c += vec3(1.0, 0.95, 0.7) * smoothstep(0.85, 1.0, sx) * (1.0 - rim) * 0.5;
		hot = 0.5 * (1.0 - rim);
	} else {
		// Fio (seda de teia): linha fina vertical.
		a = smoothstep(0.25, 0.0, abs(q.x)) * smoothstep(1.0, 0.7, abs(q.y));
		c = vcol.rgb;
	}
	a *= vcol.a;
	if (a < 0.01) {
		discard;
	}
	ALBEDO = c * (hard ? 1.0 : mix(1.0, glow, hot));
	ALPHA = clamp(a, 0.0, 1.0);
}
