shader_type spatial;
// Estrada das direções de arte únicas (looks de chão 5 e 6): terra pintada, sem textura de foto.
// UV.x: metros através (0 no centro); UV.y: metros ao longo; COLOR.a = 0 na borda de fora.
// bands = 0: borda que se dissolve na grama (pintado); bands > 0: borda nítida com contorno escuro (cartum).
// Opaca com recorte (alpha scissor): trechos que se sobrepõem (bifurcações, emendas) não somam transparência,
// que deixava manchas claras de borda reta no chão.
render_mode cull_disabled;
uniform vec3 c_road : source_color = vec3(0.36, 0.3, 0.27);
uniform vec3 c_road_dark : source_color = vec3(0.25, 0.2, 0.2);
uniform vec3 c_edge : source_color = vec3(0.12, 0.14, 0.12);
uniform float bands = 0.0;
uniform float emission_boost = 0.0;
// Ramo fechado: escurece sem sair da passada opaca (transparência fazia os ramos piscarem).
uniform float dim = 0.0;
uniform vec3 warm : source_color = vec3(1.0, 0.92, 0.8);
uniform vec3 cool : source_color = vec3(0.45, 0.4, 0.85);
uniform vec3 shadow_tint : source_color = vec3(0.55, 0.45, 0.85);

varying vec3 wp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	float n = vnoise(r * wp.xz * 0.12) * 0.6 + vnoise(r * wp.xz * 0.37 + 7.0) * 0.4;
	if (bands > 0.0) {
		n = step(0.5, n);
	}
	vec3 c = mix(c_road_dark, c_road, smoothstep(0.3, 0.7, n));
	// Pedrinhas: manchas pequenas mais claras.
	float pebble = smoothstep(0.84, 0.88, vnoise(r * wp.xz * 2.1 + 3.0));
	c = mix(c, c_road * 1.3, pebble * 0.5);
	float across = abs(UV.x);
	c *= 1.0 - smoothstep(0.35, 0.0, abs(across - 0.85)) * 0.16;
	float e = clamp(COLOR.a + (vnoise(wp.xz * 1.3) - 0.5) * (bands > 0.0 ? 0.25 : 0.7), 0.0, 1.0);
	float a;
	if (bands > 0.0) {
		a = smoothstep(0.36, 0.4, e);
		// Contorno: uma faixa escura logo dentro da borda.
		c = mix(c_edge, c, smoothstep(0.42, 0.47, e));
	} else {
		a = smoothstep(0.25, 0.5, e);
		c = mix(c_edge * 1.4 + c * 0.3, c, smoothstep(0.2, 0.9, COLOR.a));
	}
	ALBEDO = c;
	ALPHA = a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALBEDO *= mix(1.0, 0.35, dim);
	EMISSION = c * emission_boost;
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
