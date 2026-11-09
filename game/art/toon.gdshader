shader_type spatial;
// Material único do jogo: cor por vértice (paleta), luz em degraus, rim light e animação procedural.
// COLOR.a < 1 marca partes emissivas (olhos, cristais, fogo): brilham no escuro.
// INSTANCE_CUSTOM (MultiMesh): x = brilho de impacto, y = andar (0..1), z = fase, w = investida do ataque (0..1).

uniform float rim_strength = 0.55;
uniform vec3 rim_color : source_color = vec3(0.7, 0.6, 1.0);
uniform float emission_boost = 0.0;
uniform float hop_height = 0.16;
uniform float flap = 0.0;       // 1 = asas batem (morcegos)
uniform float sway = 0.0;       // 1 = balança com o vento (vegetação)
uniform float glow_strength = 3.5;
uniform float flash = 0.0;      // brilho de impacto de objetos que não são MultiMesh

varying vec4 custom;
varying float glow;

void vertex() {
	custom = INSTANCE_CUSTOM;
	glow = 1.0 - COLOR.a;
	float hop = custom.y;
	if (hop > 0.001) {
		float b = abs(sin(TIME * 12.0 + custom.z));
		VERTEX.y *= 1.0 + (b - 0.5) * 0.16 * hop;
		VERTEX.xz *= 1.0 - (b - 0.5) * 0.09 * hop;
		VERTEX.y += b * hop_height * hop;
		VERTEX.x += sin(TIME * 6.0 + custom.z) * 0.04 * hop * VERTEX.y;
	}
	if (flap > 0.0) {
		float side = abs(VERTEX.x);
		if (side > 0.18) {
			VERTEX.y += sin(TIME * 22.0 + custom.z) * (side - 0.18) * 1.4;
		}
	}
	if (sway > 0.0) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float h = max(VERTEX.y, 0.0);
		VERTEX.x += sin(TIME * 1.3 + wp.x * 0.15 + wp.z * 0.1) * 0.035 * h * sway;
		VERTEX.z += cos(TIME * 1.1 + wp.z * 0.13) * 0.025 * h * sway;
	}
	// Investida: avança e se inclina ao atacar (frente = -Z local).
	float lunge = custom.w;
	if (lunge > 0.0) {
		VERTEX.z -= lunge * 0.35 * (0.4 + VERTEX.y * 0.4);
		VERTEX.y *= 1.0 - lunge * 0.08;
	}
}

void fragment() {
	vec3 base = pow(COLOR.rgb, vec3(2.2));
	float f = clamp(max(custom.x, flash), 0.0, 1.0);
	ALBEDO = mix(base, vec3(1.0, 0.96, 0.92), f);
	ROUGHNESS = 0.8;
	SPECULAR = 0.2;
	EMISSION = base * (emission_boost + glow * glow_strength) + vec3(1.0, 0.9, 0.85) * f * 1.2;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float ramp = smoothstep(-0.05, 0.05, ndl) * 0.5 + smoothstep(0.4, 0.5, ndl) * 0.35 + smoothstep(0.85, 0.9, ndl) * 0.15;
	// Luz pontual (lanternas, braseiros, herói): degraus em chão plano viravam elipses de borda dura.
	if (!LIGHT_IS_DIRECTIONAL) {
		ramp = smoothstep(-0.2, 0.7, ndl);
	}
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * rim_strength;
	DIFFUSE_LIGHT += rim * rim_color * ATTENUATION * smoothstep(-0.4, 0.2, ndl) * length(LIGHT_COLOR) * 0.25;
	vec3 h = normalize(LIGHT + VIEW);
	// Brilho em degrau só com luz direcional: com luz pontual ele desenhava elipses duras no chão.
	if (LIGHT_IS_DIRECTIONAL) {
		SPECULAR_LIGHT += step(0.96, dot(NORMAL, h)) * ATTENUATION * LIGHT_COLOR * 0.08 * SPECULAR_AMOUNT;
	}
}
