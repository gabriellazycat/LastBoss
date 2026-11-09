shader_type canvas_item;
// Degradê de metal nos títulos grandes (direção "Covil"): ouro claro em cima, bronze embaixo, com um brilho
// estreito na altura do olho. O texto usa font_color branco; contorno e sombra (pretos) não mudam.

uniform vec4 top_col : source_color = vec4(1.0, 0.94, 0.74, 1.0);
uniform vec4 bot_col : source_color = vec4(0.78, 0.5, 0.22, 1.0);
uniform float y0 = 0.0;      // topo das maiúsculas, em coordenadas locais do Label
uniform float y1 = 100.0;    // linha de base
uniform float sheen = 0.35;

varying float ly;

void vertex() {
	ly = VERTEX.y;
}

void fragment() {
	float t = clamp((ly - y0) / max(y1 - y0, 1.0), 0.0, 1.0);
	vec3 g = mix(top_col.rgb, bot_col.rgb, smoothstep(0.1, 1.0, t));
	g += vec3(1.0, 0.97, 0.88) * sheen * exp(-pow((t - 0.42) * 9.0, 2.0));
	g = mix(g, g * 0.75, smoothstep(0.85, 1.0, t));
	COLOR.rgb *= g;
}
