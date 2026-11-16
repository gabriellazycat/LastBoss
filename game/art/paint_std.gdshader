shader_type spatial;
// Material simples (cor chapada) com o guache dos materiais (paint.gdshaderinc): objetos da mesa do menu
// (velas, caveira, moedas, tinteiro). Substitui o StandardMaterial3D de DeskScene._mat.
#include "res://game/art/paint.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness = 0.8;
uniform float metallic = 0.0;
uniform float brush = 0.04;   // largura do pincel em metros (objetos pequenos)

varying vec3 paint_p;
varying vec3 paint_n;

void vertex() {
	paint_p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	paint_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	ALBEDO = paint_albedo(albedo.rgb, paint_p, paint_n, -1, brush);
	PAINT_PAPER
	ROUGHNESS = roughness;
	METALLIC = paint_on ? 0.0 : metallic;
}

void light() {
	PAINT_LIGHT
}
