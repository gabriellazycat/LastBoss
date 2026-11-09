shader_type canvas_item;
// Moldura da interface na direção "Covil" (ver docs/REVISAO_VISUAL.md): placa de ferro escuro com textura,
// aro de metal com chanfro e luz vinda do alto à esquerda, sulco, sombra interna, brilho interno, rebites
// nos cantos e sombra projetada. Tudo procedural, nítido em qualquer tamanho.
//
// Só desenha os quads das StyleBoxTexture com a textura-marcador do UiCovil (9x9..13x13 px). O texto de um
// botão e o que o Control desenha por conta própria passam pelo mesmo material e seguem sem mudança.
// Nos botões o estado vem do tamanho do marcador: 9 normal, 10 sobre, 11 pressionado, 12 desligado, 13 foco.

global uniform float ui_px;              // pixels de tela por unidade de interface (UiCovil.sync)

uniform vec4 bg_top : source_color = vec4(0.11, 0.09, 0.115, 0.95);
uniform vec4 bg_bot : source_color = vec4(0.05, 0.04, 0.055, 0.95);
uniform vec4 trim : source_color = vec4(0.76, 0.58, 0.34, 1.0);
uniform vec4 glow : source_color = vec4(0.0);   // brilho interno; a = força
uniform float trim_w = 3.0;              // largura do aro, em unidades de interface
uniform float cut = 8.0;                 // chanfro dos cantos
uniform float shadow = 8.0;              // = expand margin da StyleBox
uniform float noise_amt = 0.05;
uniform float studs = 1.0;               // rebites nos cantos
uniform float glow_w = 16.0;
uniform float inset = 0.0;               // 1 = janela: centro transparente, sombra interna forte (arte das cartas)
uniform float hot = 0.0;                 // 0..1: aro aceso (seleção)
uniform float state_mode = 0.0;          // 1 = estado pelo marcador (botões)

// UV cru do quad, linear de 0 a 1. O UV do fragment passa pelo remapeamento do nine-patch da Godot, que o
// achata junto das bordas; derivadas dele davam traços finos ao lado das peças.
varying vec2 quv;

void vertex() {
	quv = UV;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.03 + 7.1) * 0.3 + vnoise(p * 4.07 + 3.3) * 0.15;
}

// Distância com sinal até o retângulo chanfrado (negativa dentro) e a normal de saída.
float sd_frame(vec2 c, vec2 half_size, float k, out vec2 nrm) {
	vec2 q = abs(c) - half_size;
	float dbox = max(q.x, q.y);
	float dch = (q.x + q.y + k) * 0.70710678;
	vec2 s = vec2(c.x < 0.0 ? -1.0 : 1.0, c.y < 0.0 ? -1.0 : 1.0);
	if (dch > dbox) {
		nrm = s * 0.70710678;
		return dch;
	}
	nrm = q.x > q.y ? vec2(s.x, 0.0) : vec2(0.0, s.y);
	return dbox;
}

void fragment() {
	// Marcadores de 9 a 13 px. A textura branca padrão (draw_rect, polígonos; 1 a 4 px), as texturas de 32 px
	// ou mais (líquido das barras, ícones) e os atlas de fonte passam direto.
	if (TEXTURE_PIXEL_SIZE.x > 0.07 && TEXTURE_PIXEL_SIZE.x < 0.12) {
		// Cor de entrada = modulate do Control (e da StyleBox): fades e cartas apagadas continuam valendo.
		vec4 inc = COLOR;
		float st = floor(1.0 / TEXTURE_PIXEL_SIZE.x + 0.5);
		float on = hot;
		float press = 0.0;
		float dis = 0.0;
		if (state_mode > 0.5) {
			on = max(on, (st == 10.0 || st == 13.0) ? 1.0 : 0.0);
			press = st == 11.0 ? 1.0 : 0.0;
			on = max(on, press * 0.8);
			dis = st == 12.0 ? 1.0 : 0.0;
		}
		float px = max(ui_px, 0.05);
		vec2 full = vec2(1.0 / max(length(vec2(dFdx(quv.x), dFdy(quv.x))), 1e-5), 1.0 / max(length(vec2(dFdx(quv.y), dFdy(quv.y))), 1e-5)) / px;
		// Proteção: se a derivada sumir (quad degenerado), não desenha nada.
		if (full.x > 20000.0 || full.y > 20000.0) {
			COLOR = vec4(0.0);
		} else {
		vec2 R = max(full - 2.0 * shadow, vec2(4.0));
		vec2 p = quv * full - shadow;
		vec2 c = p - R * 0.5;
		float k = min(cut, min(R.x, R.y) * 0.45);
		float w = 1.0 / px;                       // um pixel de tela
		vec2 nrm;
		float e = -sd_frame(c, R * 0.5, k, nrm);  // distância para dentro
		float tw = trim_w;
		float inner = 1.0 + tw + 1.0;
		float ei = e - inner;

		// Fundo: ferro com grão e manchas, degradê vertical, sombra junto do aro.
		float g = clamp(p.y / R.y, 0.0, 1.0);
		vec4 bg = mix(bg_top, bg_bot, g);
		float nz = fbm(p * 0.07) - 0.5;
		float grain = hash(floor(p * px)) - 0.5;
		vec3 col = bg.rgb * (1.0 + nz * noise_amt * 5.0 + grain * noise_amt * 0.8);
		col *= mix(0.62, 1.0, smoothstep(0.0, 9.0, ei));
		col += vec3(1.0, 0.95, 0.85) * 0.045 * exp(-max(p.y - inner, 0.0) / 5.0) * step(0.0, ei);
		float alpha = bg.a;
		if (inset > 0.5) {
			float v = 1.0 - smoothstep(0.0, 26.0, ei);
			col = vec3(0.0);
			alpha = v * v * 0.9;
		}
		col = mix(col, col * 0.82, press);
		// Brilho interno (raridade, seleção, foco).
		vec3 gc = mix(glow.rgb, trim.rgb * 1.25, on * (1.0 - glow.a));
		float ga = max(glow.a, on * (0.42 + 0.08 * sin(TIME * 5.0)));
		float gl = ga * exp(-max(ei, 0.0) / glow_w);
		col += gc * gl;
		alpha = max(alpha, gl * 0.8);

		// Aro de metal: perfil abaulado, luz do alto à esquerda, brilho especular, grão.
		float t = clamp((e - 1.0) / tw, 0.0, 1.0);
		vec2 L = vec2(-0.5, -0.866);
		float slope = cos(t * 3.14159);
		float lit = dot(nrm * slope, -L) * 0.9 + (0.5 - abs(t - 0.5)) * 0.25;
		vec3 tc = trim.rgb * (1.0 + on * 0.45);
		vec3 metal = tc * (0.58 + 0.62 * lit) + vec3(1.0, 0.94, 0.8) * pow(max(lit, 0.0), 5.0) * 0.55;
		metal *= 0.93 + 0.14 * hash(floor(p * px * 0.5));

		float f_groove = 1.0 - smoothstep(inner - w, inner, e);
		col = mix(col, vec3(0.015, 0.01, 0.02), f_groove * 0.9);
		alpha = mix(alpha, 1.0, f_groove);
		float f_trim = 1.0 - smoothstep(1.0 + tw - w, 1.0 + tw, e);
		col = mix(col, metal, f_trim);
		float f_line = 1.0 - smoothstep(1.0 - w, 1.0, e);
		col = mix(col, vec3(0.02, 0.015, 0.02), f_line * 0.9);

		// Rebites em losango nos quatro cantos.
		if (studs > 0.5 && min(R.x, R.y) > 40.0) {
			vec2 corner = R * 0.5 - vec2(k * 0.5 + tw * 0.35 + 1.0);
			vec2 sp = abs(c) - corner;
			float r = tw * 0.9 + 2.2;
			float dd = (abs(sp.x) + abs(sp.y)) - r;
			float fs = 1.0 - smoothstep(-w, 0.0, dd);
			vec2 sn = vec2(sp.x * sign(c.x), sp.y * sign(c.y));
			float sl = clamp(0.6 - dot(normalize(sn + vec2(0.001)), L) * 0.5, 0.2, 1.3);
			vec3 stud = tc * 1.15 * sl + vec3(1.0, 0.95, 0.8) * 0.4 * step(dd, -r * 0.55) * step(sn.x + sn.y, 0.0);
			col = mix(col, vec3(0.02), (1.0 - smoothstep(-w, 0.0, dd - 1.0)) * 0.8);
			col = mix(col, stud, fs);
			alpha = max(alpha, 1.0 - smoothstep(-w, 0.0, dd - 1.0));
		}

		if (dis > 0.5) {
			float l = dot(col, vec3(0.3, 0.55, 0.15));
			col = mix(col, vec3(l), 0.75) * 0.6;
		}

		// Borda de fora (antisserrilhada) e sombra projetada.
		float fa = alpha * smoothstep(-w, 0.0, e);
		vec2 n2;
		float es = -sd_frame(c - vec2(0.0, shadow * 0.35), R * 0.5, k, n2);
		float sa = 0.6 * pow(clamp(1.0 + es / max(shadow, 0.001), 0.0, 1.0), 2.0) * step(0.001, shadow);
		float oa = fa + sa * (1.0 - fa);
		COLOR = vec4(col * fa / max(oa, 1e-4), oa) * inc;
		}
	}
}
