shader_type spatial;
// Tufos de grama (MultiMesh): cor da base para a ponta, vento em ondas, sem sombra própria.
render_mode cull_disabled;
uniform vec3 base_color : source_color = vec3(0.12, 0.25, 0.08);
uniform vec3 tip_color : source_color = vec3(0.55, 0.7, 0.25);
uniform float wind = 1.0;
uniform float translucency = 0.35;
varying float hgt;
varying vec3 tint;

void vertex() {
	hgt = clamp(VERTEX.y / 0.6, 0.0, 1.0);
	tint = COLOR.rgb;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w = sin(TIME * 1.7 + wp.x * 0.21 + wp.z * 0.13) * 0.6 + sin(TIME * 3.1 + wp.x * 0.7) * 0.25;
	VERTEX.x += w * 0.12 * hgt * hgt * wind;
	VERTEX.z += cos(TIME * 1.3 + wp.z * 0.19) * 0.08 * hgt * hgt * wind;
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.7));
}

void fragment() {
	vec3 c = mix(base_color, tip_color, hgt) * tint;
	ALBEDO = c;
	ROUGHNESS = 0.8;
	SPECULAR = 0.15;
	BACKLIGHT = vec3(translucency) * c;
	AO = mix(0.35, 1.0, hgt);
	AO_LIGHT_AFFECT = 0.6;
}
