shader_type spatial;
// Estrada dos looks de cenário: textura ao longo do caminho, bordas que se dissolvem na grama
// (COLOR.a = 0 na borda externa), sulcos de roda mais escuros.
// Opaca com recorte (alpha scissor): trechos que se sobrepõem (bifurcações, emendas) não somam transparência,
// que deixava manchas claras de borda reta no chão.
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nor : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float scale = 0.25;
uniform vec3 tint : source_color = vec3(1.0);
uniform float rut = 0.25;
uniform float normal_strength = 1.0;
uniform float emission_boost = 0.0;
// Ramo fechado: escurece sem sair da passada opaca (transparência fazia os ramos piscarem).
uniform float dim = 0.0;
uniform vec3 edge_color : source_color = vec3(0.4, 0.35, 0.3);

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
	// UV.x: metros através (0 no centro), UV.y: metros ao longo.
	vec2 uv = vec2(UV.x, UV.y) * scale;
	vec3 c = texture(tex, uv).rgb * tint;
	float across = abs(UV.x);
	float ruts = smoothstep(0.35, 0.0, abs(across - 0.85)) * rut;
	c *= 1.0 - ruts;
	// Borda irregular: o ruído recorta a transparência.
	float e = clamp(COLOR.a + (vnoise(wp.xz * 1.3) - 0.5) * 0.7, 0.0, 1.0);
	c = mix(edge_color * c * 1.4, c, smoothstep(0.2, 0.9, COLOR.a));
	ALBEDO = c;
	NORMAL_MAP = texture(nor, uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	ALPHA = smoothstep(0.25, 0.5, e);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALBEDO *= mix(1.0, 0.35, dim);
	EMISSION = c * emission_boost;
}
