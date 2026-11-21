// Vento do cenário (rodada do cenário com propósito, 21/11/2026): balanço suave + rajadas em onda que atravessam
// o campo na mesma direção. Deslocamento em espaço de mundo, proporcional ao quadrado da altura (curva, não inclina).
// O chão do mundo fica em y = 0, então a altura de mundo do vértice é a altura dele acima do chão.
const vec2 LB_WIND_DIR = vec2(0.83, 0.56);

// Pulso estreito que anda ~11 m/s pelo campo, com a frente da onda irregular.
float lb_gust(vec2 xz, float t) {
	float ph = dot(xz, LB_WIND_DIR) * 0.075 - t * 0.85;
	float g = pow(max(sin(ph), 0.0), 5.0);
	float front = 0.55 + 0.45 * sin(dot(xz, vec2(-LB_WIND_DIR.y, LB_WIND_DIR.x)) * 0.045 + t * 0.15);
	return g * front;
}

// Deslocamento (mundo) de um vértice na posição de mundo wp; amt = força (flor 1, arbusto ~0,3).
vec3 lb_wind_offset(vec3 wp, float t, float amt) {
	float h = max(wp.y, 0.0);
	float base = sin(t * 1.7 + wp.x * 0.45 + wp.z * 0.31) * 0.6 + sin(t * 2.9 + wp.x * 1.3 - wp.z * 0.7) * 0.25;
	float g = lb_gust(wp.xz, t);
	float lean = (0.07 + 0.05 * base + 0.55 * g) * h * h * amt;
	float side = (0.06 * base + 0.08 * g * sin(t * 6.0 + wp.x * 2.0)) * h * h * amt;
	vec2 d = LB_WIND_DIR * lean + vec2(-LB_WIND_DIR.y, LB_WIND_DIR.x) * side;
	float drop = (lean * lean) / max(h * 2.5, 0.2);   // a ponta desce um pouco ao curvar
	return vec3(d.x, -drop, d.y);
}
