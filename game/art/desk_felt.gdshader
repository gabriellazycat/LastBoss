shader_type spatial;
// Tampo da mesa do menu (26/11/2026): toalha de feltro azul-noite, com fibra, leve variação de tom e um pesponto
// creme tracejado perto da borda. Procedural em coordenadas do mundo relativas a `origin`; sem pinceladas.

uniform vec3 origin = vec3(0.0);
uniform vec3 felt : source_color = vec3(0.13, 0.21, 0.34);
uniform vec3 thread : source_color = vec3(0.93, 0.89, 0.8);
uniform vec2 half_size = vec2(1.6, 1.1);
uniform vec2 center = vec2(0.0);

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - origin;
}

float h(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float n(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 p = wp.xz;
	// fibra: ruído fino em várias direções e manchas largas e macias de tom
	float fib = n(p * 900.0) * 0.4 + n(p * vec2(1400.0, 300.0)) * 0.3 + n(p * vec2(300.0, 1400.0)) * 0.3;
	float big = n(p * 3.0) * 0.6 + n(p * 7.0) * 0.4;
	vec3 col = felt * (0.86 + 0.2 * big) * (0.9 + 0.18 * fib);
	// pesponto creme a 6 cm da borda
	vec2 d = abs(p - center) - (half_size - vec2(0.06));
	float edge = max(d.x, d.y);
	float along = abs(d.x) > abs(d.y) ? p.y : p.x;
	float dash = step(0.45, fract(along / 0.03));
	float st = (1.0 - smoothstep(0.003, 0.006, abs(edge))) * dash;
	col = mix(col, thread, st * 0.85);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.15;
	// brilho de veludo nas bordas, como o feltro do mundo
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = felt * fres * 0.25;
}
