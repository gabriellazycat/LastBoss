shader_type spatial;
// Look 5 "Aventura (CC0)": modelos da KayKit e da Quaternius (assets/models/cc0, tools/art/import_cc0.gd).
// Luz no espírito do Risk of Rain 2: difusa larga (lambert com envoltório), especular baixa e larga, contorno
// de fresnel puxado para a cor do céu, nada de faixas de toon. A forma vem da silhueta e da cor, não do traço.
// Animação: se a malha tem VAT (use_vat), a posição e a normal de cada vértice vêm da textura (andar + ataque),
// por instância; senão, a animação procedural dos outros looks (anim.gdshaderinc).
render_mode diffuse_lambert_wrap, specular_schlick_ggx;
#include "res://game/art/anim.gdshaderinc"

uniform float emission_boost = 0.0;
uniform float flash = 0.0;
uniform float glow_strength = 3.0;
uniform bool use_tex = false;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform bool use_vat = false;
uniform highp sampler2D vat : filter_nearest, repeat_disable;
uniform int walk_frames = 0;
uniform int atk_frames = 0;
uniform float walk_rate = 1.1;     // ciclos por segundo andando
uniform float idle_rate = 0.45;    // parado (voadores batem asa sempre: idle_rate = walk_rate)
uniform float pose_frame = 0.0;    // fora da MultiMesh (cartas, menu): quadro fixo do andar
uniform float pose_lunge = 0.0;    // fora da MultiMesh: quanto do ataque (0..1), para retratos com ação
uniform vec3 rim_color : source_color = vec3(0.75, 0.82, 1.0);
uniform float rim_strength = 0.35;
uniform vec3 tint : source_color = vec3(1.0);

varying vec4 custom;
varying float glow;

vec3 vat_row(int v, int row) {
	return texelFetch(vat, ivec2(v, row), 0).xyz;
}

void vertex() {
	custom = lb_custom(INSTANCE_CUSTOM);
	glow = clamp(1.0 - COLOR.a, 0.0, 1.0);
	if (use_vat && walk_frames > 0) {
		int v = int(UV2.x + 0.5);
		int total = walk_frames + atk_frames;
		float moving = clamp(custom.y * 2.0, 0.0, 1.0);
		float rate = mix(idle_rate, walk_rate, moving);
		float ph = multimesh ? fract(TIME * rate + custom.z * 0.137) : fract(pose_frame);
		float fw = ph * float(walk_frames);
		int f0 = int(floor(fw)) % walk_frames;
		int f1 = (f0 + 1) % walk_frames;
		float k = fract(fw);
		vec3 p = mix(vat_row(v, f0), vat_row(v, f1), k);
		vec3 n = mix(vat_row(v, total + f0), vat_row(v, total + f1), k);
		float lunge = multimesh ? custom.w : pose_lunge;
		if (atk_frames > 1 && lunge > 0.0) {
			float fa = lunge * float(atk_frames - 1);
			int a0 = walk_frames + int(floor(fa));
			int a1 = walk_frames + min(int(floor(fa)) + 1, atk_frames - 1);
			float ka = fract(fa);
			vec3 pa = mix(vat_row(v, a0), vat_row(v, a1), ka);
			vec3 na = mix(vat_row(v, total + a0), vat_row(v, total + a1), ka);
			float w = smoothstep(0.0, 0.2, lunge) * (1.0 - smoothstep(0.85, 1.0, lunge));
			p = mix(p, pa, w);
			n = mix(n, na, w);
		}
		VERTEX = p;
		NORMAL = normalize(n);
		// Um saltinho leve por cima da caminhada dá peso aos enxames, sem esmagar o modelo.
		VERTEX.y += abs(sin(TIME * 12.0 + custom.z)) * 0.05 * custom.y;
	} else {
		lb_animate(VERTEX, custom, MODEL_MATRIX, TIME);
	}
}

void fragment() {
	vec3 base = pow(clamp(COLOR.rgb, vec3(0.0), vec3(1.0)), vec3(2.2)) * tint;
	if (use_tex && UV.x >= 0.0) {
		base *= texture(albedo_tex, UV).rgb;
	}
	float f = clamp(max(custom.x, flash), 0.0, 1.0);
	ALBEDO = mix(base, vec3(1.0, 0.96, 0.92), f);
	ROUGHNESS = 0.72;
	SPECULAR = 0.3;
	// Contorno de céu: fresnel suave, mais forte no alto do modelo (luz que vem de cima).
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float up = clamp((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y * 0.5 + 0.5, 0.0, 1.0);
	EMISSION = base * (emission_boost + glow * glow_strength) + rim_color * fr * up * rim_strength * 0.25
		+ vec3(1.0, 0.9, 0.85) * f * 1.2;
}
