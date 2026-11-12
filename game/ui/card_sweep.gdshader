shader_type canvas_item;
render_mode blend_add;
// Reflexo holográfico que atravessa a carta de nível 3 na diagonal, de tempos em tempos.
uniform float motion = 1.0;
uniform float period = 3.4;

void fragment() {
	float ph = motion > 0.0 ? fract(TIME / period) : 0.45;
	float x = (UV.x + UV.y * 0.32) / 1.32;
	float pos = -0.25 + ph * 1.6;
	float d = (x - pos) / 0.11;
	float band = exp(-d * d);
	vec3 rainbow = mix(vec3(1.0, 0.9, 0.55), vec3(0.55, 0.95, 1.0), smoothstep(-1.0, 1.0, d));
	rainbow = mix(rainbow, vec3(1.0, 0.65, 0.9), smoothstep(0.3, 1.4, d));
	COLOR = vec4(rainbow * band * 0.42, 1.0);
}
