shader_type spatial;
// Material único do jogo: cor por vértice (paleta), luz em degraus, rim light,
// brilho de impacto e animação de enxame no shader (sem esqueleto).
// INSTANCE_CUSTOM: x = brilho de impacto, y = quanto está andando (0..1), z = fase, w = emissão extra.

uniform float rim_strength = 0.45;
uniform vec3 rim_color : source_color = vec3(0.75, 0.65, 1.0);
uniform float emission_boost = 0.0;
uniform float hop_height = 0.16;

varying vec4 custom;

void vertex() {
	custom = INSTANCE_CUSTOM;
	float hop = custom.y;
	if (hop > 0.001) {
		float b = abs(sin(TIME * 13.0 + custom.z));
		VERTEX.y *= 1.0 + (b - 0.5) * 0.14 * hop;
		VERTEX.xz *= 1.0 - (b - 0.5) * 0.08 * hop;
		VERTEX.y += b * hop_height * hop;
	}
}

void fragment() {
	vec3 base = pow(COLOR.rgb, vec3(2.2)); // cor por vértice vem em sRGB
	ALBEDO = mix(base, vec3(1.0, 0.95, 0.9), clamp(custom.x, 0.0, 1.0));
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
	EMISSION = base * (emission_boost + custom.w) + vec3(1.0, 0.85, 0.8) * custom.x * 0.8;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float ramp = smoothstep(-0.05, 0.05, ndl) * 0.55 + smoothstep(0.45, 0.55, ndl) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * rim_strength;
	DIFFUSE_LIGHT += rim * rim_color * ATTENUATION * smoothstep(-0.3, 0.2, ndl) / PI * length(LIGHT_COLOR) * 0.6;
}
