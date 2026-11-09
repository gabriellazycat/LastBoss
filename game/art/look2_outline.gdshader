shader_type spatial;
// Contorno do look 2: casca de faces de trás, empurrada pela normal em espessura constante na tela.
render_mode unshaded, cull_front, depth_draw_opaque;
#include "res://game/art/anim.gdshaderinc"
uniform float width = 5.0;
uniform vec4 line_color : source_color = vec4(0.07, 0.04, 0.1, 1.0);

void vertex() {
	vec3 v = VERTEX;
	lb_animate(v, lb_custom(INSTANCE_CUSTOM), MODEL_MATRIX, TIME);
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(v, 1.0));
	vec3 nv = mat3(MODELVIEW_MATRIX) * NORMAL;
	vec2 dir = normalize((PROJECTION_MATRIX * vec4(nv, 0.0)).xy + vec2(1e-5));
	clip.xy += dir * width * clip.w * 2.0 / VIEWPORT_SIZE;
	POSITION = clip;
	// Na passada de sombra (projeção ortográfica do sol) o contorno não existe: a casca empurrada
	// projetava sombras grandes e falsas no chão.
	if (PROJECTION_MATRIX[3][3] > 0.5) {
		POSITION = vec4(0.0, 0.0, -10.0, 1.0);
	}
}

void fragment() {
	ALBEDO = line_color.rgb;
}
