shader_type spatial;
// Rio pintado (16/11/2026, docs/RIO_E_PONTES.md): guache chapado (S1), poucas manchas de cor, pinceladas largas
// que correm no sentido do rio e uma margem de terra que se desfaz na grama.
// UV.x: -1..1 através da fita inteira (água + margens); UV.y: metros ao longo do rio.
render_mode cull_disabled;

uniform vec3 c_deep : source_color = vec3(0.2, 0.38, 0.47);
uniform vec3 c_mid : source_color = vec3(0.29, 0.49, 0.56);
uniform vec3 c_light : source_color = vec3(0.44, 0.62, 0.65);
uniform vec3 c_bank : source_color = vec3(0.47, 0.39, 0.27);
uniform vec3 c_bank_dark : source_color = vec3(0.33, 0.27, 0.19);
uniform float water_frac = 0.74;   // |UV.x| abaixo disso é água
uniform float speed = 0.45;        // m/s da correnteza pintada
uniform float emission_boost = 0.0;

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

// Ruído suave em duas oitavas, girado (sem contornos em degrau alinhados ao rio).
float fbm(vec2 p) {
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	return vnoise(r * p) * 0.65 + vnoise(r * r * p * 2.1 + 3.7) * 0.35;
}

void fragment() {
	float ax = abs(UV.x);
	float along = UV.y;
	// Beira da água irregular, como pincel (cada margem com o seu ruído).
	float wf = water_frac + (fbm(vec2(along * 0.12, sign(UV.x) * 5.0)) - 0.5) * 0.08;
	// Água: tons chapados em faixas paralelas às margens (fundo no meio, raso na beira), com a divisa
	// ondulada por um ruído suave; pinceladas finas e compridas descem o rio.
	float depth = 1.0 - ax / wf;
	float wob = (fbm(vec2(UV.x * 1.2, along * 0.05)) - 0.5) * 0.35;
	float tone = depth + wob;
	vec3 water = tone > 0.5 ? c_deep : (tone > 0.16 ? c_mid : c_light);
	float flow = fbm(vec2(UV.x * 6.0, along * 0.07 - TIME * speed * 0.07));
	float streak = smoothstep(0.66, 0.69, flow) * (1.0 - smoothstep(0.76, 0.8, flow)) * smoothstep(0.1, 0.35, depth);
	water = mix(water, c_light, streak * 0.7);
	// Margem: terra em duas manchas, que se desfaz na grama por fora (recorte com ruído).
	float bn = fbm(wp.xz * 0.3);
	vec3 bank = bn > 0.5 ? c_bank : c_bank_dark;
	float is_water = step(ax, wf);
	ALBEDO = mix(bank, water, is_water);
	ROUGHNESS = mix(1.0, 0.6, is_water);
	SPECULAR = 0.12 * is_water;
	EMISSION = ALBEDO * emission_boost;
	float outer = 1.0 - smoothstep(0.88, 0.98, ax + (fbm(wp.xz * 0.5) - 0.5) * 0.16);
	ALPHA = outer;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
