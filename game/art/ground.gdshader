shader_type spatial;
// Chão dos looks de cenário: duas texturas em coordenadas do mundo, misturadas por ruído grande,
// com variação de cor em manchas e, opcionalmente, fendas que brilham (look 4).
uniform sampler2D tex_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nor_a : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nor_b : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float scale_a = 0.12;
uniform float scale_b = 0.1;
uniform vec3 tint_a : source_color = vec3(1.0);
uniform vec3 tint_b : source_color = vec3(1.0);
uniform vec3 patch_color : source_color = vec3(1.0);
uniform float patch_amount = 0.0;
uniform float b_amount = 0.5;
uniform float normal_strength = 0.8;
uniform float roughness_v = 0.9;
uniform float saturation = 1.0;
uniform vec3 crack_color : source_color = vec3(1.0, 0.3, 0.1);
uniform float crack_glow = 0.0;
uniform float crack_threshold = 0.18;
// 1 = textura com todo o detalhe; menos que 1 mistura com a média dela (mip alto): chão mais calmo.
uniform float detail = 1.0;

varying vec3 wp;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
// Todas as oitavas giradas e o domínio torcido: o ruído de valor alinhado ao mundo deixava
// manchas retangulares de borda reta no chão (a primeira oitava, a mais forte, não girava).
float fbm(vec2 p) {
	mat2 r0 = mat2(vec2(0.96, 0.28), vec2(-0.28, 0.96));
	mat2 r1 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	mat2 r2 = mat2(vec2(0.31, 0.95), vec2(-0.95, 0.31));
	p += vec2(vnoise(r2 * p * 0.7 + 5.0), vnoise(r1 * p * 0.7 + 9.0)) * 1.3;
	return vnoise(r0 * p) * 0.5 + vnoise(r1 * p * 2.03 + 17.0) * 0.3 + vnoise(r2 * p * 4.1 + 3.0) * 0.2;
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wp.xz;
	// Gira um pouco a segunda amostra para esconder a repetição.
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	vec3 a = mix(texture(tex_a, p * scale_a).rgb, texture(tex_a, r * p * scale_a * 0.37 + 0.31).rgb, 0.35) * tint_a;
	vec3 b = texture(tex_b, r * p * scale_b).rgb * tint_b;
	a = mix(textureLod(tex_a, p * scale_a, 7.0).rgb * tint_a, a, detail);
	b = mix(textureLod(tex_b, r * p * scale_b, 7.0).rgb * tint_b, b, detail);
	float n = fbm(p * 0.035);
	float m = smoothstep(0.42 - b_amount * 0.3, 0.42 + 0.4 - b_amount * 0.3, n);
	vec3 col = mix(a, b, m);
	float pn = fbm(p * 0.09 + 40.0);
	col = mix(col, col * patch_color * 1.6, smoothstep(0.45, 0.85, pn) * patch_amount);
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	ALBEDO = col;
	vec3 na = texture(nor_a, p * scale_a).rgb;
	vec3 nb = texture(nor_b, r * p * scale_b).rgb;
	NORMAL_MAP = mix(na, nb, m);
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = roughness_v;
	SPECULAR = 0.25;
	if (crack_glow > 0.0) {
		float dark = 1.0 - smoothstep(0.0, crack_threshold, l);
		float pulse = 0.65 + 0.35 * sin(TIME * 1.3 + fbm(p * 0.05) * 9.0);
		float zone = smoothstep(0.5, 0.85, fbm(p * 0.02 + 7.0));
		EMISSION = crack_color * dark * zone * pulse * crack_glow;
	}
}
