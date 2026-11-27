shader_type spatial;
// Material simples em cor chapada, sem pinceladas (26/11/2026): objetos da mesa do menu (velas, caveira, moedas,
// tinteiro), com a luz do paint.gdshaderinc. Substitui o StandardMaterial3D de DeskScene._mat.
#include "res://game/art/paint.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness = 0.8;
uniform float metallic = 0.0;

varying vec3 paint_p;   // usados pela luz (PAINT_LIGHT)
varying vec3 paint_n;

void vertex() {
	paint_p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	paint_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
	METALLIC = paint_on ? 0.0 : metallic;
}

void light() {
	PAINT_LIGHT
}
