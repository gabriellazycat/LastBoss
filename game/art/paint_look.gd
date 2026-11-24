class_name PaintLook
extends RefCounted
## Mundo pintado em guache chapado (S1, 13/11/2026) nos próprios materiais: luz em manchas + pinceladas procedurais,
## pelas variáveis globais de shader de game/art/paint.gdshaderinc. Por cima, os escuros como os das cartas (17/11/2026):
## sombra mais funda e fria no shader (paint_escuro) e uma LUT que estica o valor no ambiente (apply_env).

const DIR := "res://assets/textures/paint/"


static func apply() -> void:
	RenderingServer.global_shader_parameter_set("paint_on", true)
	RenderingServer.global_shader_parameter_set("paint_light", 1)
	RenderingServer.global_shader_parameter_set("paint_tex", 0)
	RenderingServer.global_shader_parameter_set("paint_cor", false)
	RenderingServer.global_shader_parameter_set("paint_escuro", true)
	RenderingServer.global_shader_parameter_set("paint_papel", false)


## Escuros no ambiente: menos brilho e a LUT do escuro, para os escuros das sombras aparecerem.
## Guarda os valores do chão na primeira vez (meta) e parte deles a cada chamada.
static func apply_env(env: Environment) -> void:
	if env == null:
		return
	if not env.has_meta("pl_base"):
		env.set_meta("pl_base", {"fog_density": env.fog_density, "volumetric_fog_density": env.volumetric_fog_density,
			"glow_intensity": env.glow_intensity, "adjustment_contrast": env.adjustment_contrast,
			"adjustment_saturation": env.adjustment_saturation, "tonemap_exposure": env.tonemap_exposure,
			"adjustment_brightness": env.adjustment_brightness})
	var b: Dictionary = env.get_meta("pl_base")
	for k in b:
		env.set(k, b[k])
	# A névoa fica: é ela que segura a cor (sem ela a estrada vira laranja, croma 17 -> 29 na medição de 15/11).
	# O escuro vem da sombra do shader (paint_escuro) e de um pouco mais de contraste.
	# O contraste do Godot gira em torno do cinza médio e clareava o mundo (que fica quase todo acima dele): o escuro vem
	# de uma LUT que estica só o valor no Lab, como a simulação (tools/art/make_lut_escuro.py).
	env.glow_intensity = b["glow_intensity"] * 0.7
	env.adjustment_color_correction = _lut()


static var _lut_tex: ImageTexture3D


## LUT 3D do escuro: a imagem tem as 33 fatias (azul) lado a lado, cada uma 33x33 (vermelho em x, verde em y).
static func _lut() -> ImageTexture3D:
	if _lut_tex:
		return _lut_tex
	var src: Texture2D = load(DIR + "lut_escuro.png")
	if src == null:
		return null
	var img := src.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var n := img.get_height()
	var slices: Array[Image] = []
	for k in n:
		slices.append(img.get_region(Rect2i(k * n, 0, n, n)))
	_lut_tex = ImageTexture3D.new()
	_lut_tex.create(Image.FORMAT_RGBA8, n, n, n, false, slices)
	return _lut_tex
