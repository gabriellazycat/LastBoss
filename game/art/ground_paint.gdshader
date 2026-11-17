shader_type spatial;
// Chão procedural das direções de arte únicas (looks de chão 5 e 6), sem textura de foto:
// manchas grandes de cor, pinceladas largas e pouco contraste, para os personagens ficarem na frente.
// bands = 0: pintado (cor contínua, luz que aquece e esfria, como o look 3 dos monstros);
// bands > 0: cartum (cores em faixas chapadas e sombra em degrau, como o look 2).
uniform vec3 c_dark : source_color = vec3(0.07, 0.12, 0.11);
uniform vec3 c_base : source_color = vec3(0.13, 0.2, 0.16);
uniform vec3 c_light : source_color = vec3(0.2, 0.27, 0.2);
uniform vec3 c_accent : source_color = vec3(0.2, 0.12, 0.25);
uniform float accent_amount = 0.3;
uniform float stroke = 0.35;
uniform float bands = 0.0;
uniform vec3 warm : source_color = vec3(1.0, 0.92, 0.8);
uniform vec3 cool : source_color = vec3(0.45, 0.4, 0.85);
uniform vec3 shadow_tint : source_color = vec3(0.55, 0.45, 0.85);

varying vec3 wp;

// Hash sem sin(): o sin() de argumento grande perde precisão na GPU e criava bordas retas e blocos no chão.
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
// Oitavas giradas e domínio torcido: sem isso o ruído de valor deixa manchas retangulares alinhadas ao mundo.
float fbm(vec2 p) {
	mat2 r0 = mat2(vec2(0.96, 0.28), vec2(-0.28, 0.96));
	mat2 r1 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	mat2 r2 = mat2(vec2(0.31, 0.95), vec2(-0.95, 0.31));
	p += vec2(vnoise(r2 * p * 0.7 + 5.0), vnoise(r1 * p * 0.7 + 9.0)) * 1.3;
	return vnoise(r0 * p) * 0.5 + vnoise(r1 * p * 2.03 + 17.0) * 0.3 + vnoise(r2 * p * 4.1 + 3.0) * 0.2;
}

// Degraus com borda curta (não serrilha como floor puro).
float quant(float v, float n) {
	float x = v * n;
	return (floor(x) + smoothstep(0.42, 0.58, fract(x))) / n;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wp.xz;
	float big = fbm(p * 0.018);
	float mid = fbm(p * 0.06 + 13.0);
	// Pinceladas: ruído esticado numa direção que gira devagar pelo mapa.
	float ang = fbm(p * 0.008 + 3.0) * 6.2832;
	vec2 dir = vec2(cos(ang), sin(ang));
	vec2 q = vec2(dot(p, dir), dot(p, vec2(-dir.y, dir.x)));
	float str = vnoise(vec2(q.x * 0.25, q.y * 1.2)) - 0.5;
	float v = big * 0.62 + mid * 0.38 + str * stroke * (1.0 - min(bands, 1.0));
	if (bands > 0.0) {
		v = quant(v, bands);
	}
	vec3 col = mix(c_dark, c_base, smoothstep(0.3, 0.48, v));
	col = mix(col, c_light, smoothstep(0.56, 0.72, v));
	float acc = fbm(p * 0.025 + 71.0);
	float am = bands > 0.0 ? step(0.62, acc) : smoothstep(0.52, 0.74, acc);
	col = mix(col, c_accent, am * accent_amount);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	if (bands > 0.0) {
		float k = ndl * ATTENUATION;
		float band = smoothstep(0.0, 0.03, k) * 0.62 + smoothstep(0.55, 0.58, k) * 0.38;
		if (!LIGHT_IS_DIRECTIONAL) {
			band = smoothstep(0.0, 0.35, k);
		}
		DIFFUSE_LIGHT += mix(shadow_tint * 0.55, vec3(1.0), band) * LIGHT_COLOR / PI * (LIGHT_IS_DIRECTIONAL ? 1.0 : ATTENUATION);
	} else {
		float l = smoothstep(-0.6, 1.0, ndl) * ATTENUATION;
		DIFFUSE_LIGHT += mix(cool * 0.75 * (LIGHT_IS_DIRECTIONAL ? 1.0 : 0.0), warm, l) * LIGHT_COLOR / PI;
	}
}
