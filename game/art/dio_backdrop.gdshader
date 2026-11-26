// Fundo do diorama (do Holy Sheep, shaders/backdrop.gdshader): a câmera olha para baixo, então atrás do chão fica
// um degradê radial macio (mais claro no meio, mais fundo nas bordas da tela). Os reflexos veem um céu simples.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.45, 0.62, 0.82);
uniform vec3 horizon_color : source_color = vec3(0.86, 0.84, 0.78);
uniform vec3 center_color : source_color = vec3(0.9, 0.86, 0.78);
uniform vec3 edge_color : source_color = vec3(0.55, 0.6, 0.66);

void sky() {
	if (AT_CUBEMAP_PASS) {
		COLOR = mix(horizon_color, top_color, clamp(EYEDIR.y * 1.5, 0.0, 1.0));
	} else {
		vec2 uv = SCREEN_UV - vec2(0.5, 0.42);
		uv.x *= 1.5;
		float r = length(uv);
		vec3 c = mix(center_color, edge_color, smoothstep(0.05, 0.9, r));
		// Dither so the gradient doesn't band.
		c += (fract(sin(dot(SCREEN_UV * 731.0, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) / 255.0;
		COLOR = c;
	}
}
