shader_type canvas_item;
// Sangue do modificador Rouba-vida: pingos escorrendo do topo, borda pulsando como veia e gotas subindo.
// `motion` 0 = parado.
uniform vec4 blood : source_color = vec4(0.66, 0.03, 0.1, 1.0);
uniform vec2 scale = vec2(4.0, 4.0);
uniform float motion = 1.0;

float hash(float n) { return fract(sin(n * 127.1) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	float t = TIME * motion;
	// pingos do topo: cada coluna tem comprimento e largura próprios e o comprimento respira
	float cols = 13.0;
	float cx = floor(UV.x * cols);
	float fx = fract(UV.x * cols) - 0.5;
	float len = 0.06 + 0.2 * hash(cx + 1.0) + 0.03 * sin(t * 0.9 + cx * 2.1);
	float w = 0.1 + 0.13 * hash(cx + 7.0);
	float stem = step(UV.y, len) * (1.0 - smoothstep(w - 0.04, w, abs(fx)));
	float rad = (w + 0.06) / cols;
	float bulb = 1.0 - smoothstep(rad * 0.8, rad * 1.25, length(vec2(fx / cols, (UV.y - len) * 0.9)));
	float drip = max(stem, bulb);
	// borda de veia pulsando
	float edge_d = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float edge = 1.0 - smoothstep(0.0, 0.16, edge_d);
	float pulse = 0.5 + 0.5 * sin(t * 3.2);
	float vein = edge * (0.28 + 0.22 * pulse);
	// gotas subindo (a vida que volta para a unidade)
	vec2 q = vec2(UV.x * 18.0, UV.y * 20.0 + t * 1.6);
	vec2 cell = floor(q);
	float r = hash2(cell);
	float rise = step(0.94, r) * (1.0 - smoothstep(0.1, 0.34, length(fract(q) - 0.5))) * smoothstep(0.1, 0.9, UV.y);
	float a = max(max(drip * 0.95, vein), rise * 0.85);
	COLOR = vec4(blood.rgb, clamp(a, 0.0, 1.0));
}
