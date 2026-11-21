// AnimaÃ§Ã£o procedural compartilhada pelos looks (igual Ã  do toon.gdshader).
// INSTANCE_CUSTOM (MultiMesh): x = brilho de impacto, y = andar (0..1), z = fase, w = investida do ataque (0..1).
uniform float hop_height = 0.16;
uniform float flap = 0.0;
uniform float sway = 0.0;
uniform float wind_amt = 0.0;   // vento com rajadas (wind.gdshaderinc); 0 = só o sway antigo
// INSTANCE_CUSTOM só existe nas MultiMesh; numa MeshInstance comum ele traz lixo por vértice (NaN que o bloom espalha).
uniform bool multimesh = false;

vec4 lb_custom(vec4 c) {
	return multimesh ? c : vec4(0.0);
}

#include "res://game/art/wind.gdshaderinc"

void lb_animate(inout vec3 v, vec4 c, mat4 model, float t) {
	float hop = c.y;
	if (hop > 0.001) {
		float b = abs(sin(t * 12.0 + c.z));
		v.y *= 1.0 + (b - 0.5) * 0.16 * hop;
		v.xz *= 1.0 - (b - 0.5) * 0.09 * hop;
		v.y += b * hop_height * hop;
		v.x += sin(t * 6.0 + c.z) * 0.04 * hop * v.y;
	}
	if (flap > 0.0) {
		float side = abs(v.x);
		if (side > 0.18) {
			v.y += sin(t * 22.0 + c.z) * (side - 0.18) * 1.4;
		}
	}
	if (sway > 0.0) {
		vec3 wp = (model * vec4(v, 1.0)).xyz;
		float h = max(v.y, 0.0);
		v.x += sin(t * 1.3 + wp.x * 0.15 + wp.z * 0.1) * 0.035 * h * sway;
		v.z += cos(t * 1.1 + wp.z * 0.13) * 0.025 * h * sway;
	}
	if (wind_amt > 0.0) {
		vec3 wpw = (model * vec4(v, 1.0)).xyz;
		v += inverse(mat3(model)) * lb_wind_offset(wpw, t, wind_amt);
	}
	float lunge = c.w;
	if (lunge > 0.0) {
		v.z -= lunge * 0.35 * (0.4 + v.y * 0.4);
		v.y *= 1.0 - lunge * 0.08;
	}
}
