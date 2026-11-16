class_name PaintLook
extends RefCounted
## Variações do mundo pintado em guache (docs/MUNDO_PINTADO.md). Settings "paint_look":
##   0 = desligado (o jogo de antes)
##   1..3 = S1..S3: shader nos materiais (luz em manchas + pinceladas procedurais)
##   4..6 = T1..T3: folhas de pincel geradas por IA (assets/textures/paint/T<n>), luz de sempre
##   7..9 = C1..C3: as duas juntas (S<n> + T<n>)
## Tudo passa pelas variáveis globais de shader de game/art/paint.gdshaderinc: trocar de variação não recompila nada.

const NAMES := ["Desligado", "S1 · Guache chapado", "S2 · Aguado", "S3 · Pincel largo",
	"T1 · IA dabs largos", "T2 · IA aguado", "T3 · IA pincel seco",
	"C1 · Chapado + IA dabs", "C2 · Aguado + IA aguado", "C3 · Pincel largo + IA pincel seco"]
const KINDS := ["grass", "dirt", "stone", "foliage", "fur", "metal", "wood", "cloth"]
const DIR := "res://assets/textures/paint/"


static func light_of(i: int) -> int:
	if i >= 1 and i <= 3:
		return i
	if i >= 7:
		return i - 6
	return 0


static func tex_of(i: int) -> int:
	if i >= 4 and i <= 6:
		return i - 3
	if i >= 7:
		return i - 6
	return 0


static func apply() -> void:
	var i := int(Settings.v.get("paint_look", 0))
	RenderingServer.global_shader_parameter_set("paint_on", i > 0)
	RenderingServer.global_shader_parameter_set("paint_light", light_of(i))
	var t := tex_of(i)
	var ok := t > 0
	# Cada material usa a sua folha; sem ela, a folha de grama do mesmo estilo (o shader só lê o valor, não a cor).
	var base_path := "%sT%d/grass_v.png" % [DIR, t]
	var base: Texture2D = load(base_path) if ok and ResourceLoader.exists(base_path) else null
	ok = ok and base != null
	for k in KINDS:
		var path := "%sT%d/%s_v.png" % [DIR, t, k]
		var tx: Texture2D = load(path) if ok and ResourceLoader.exists(path) else base
		RenderingServer.global_shader_parameter_set("paint_t_" + k, tx)
	# Sem as folhas da IA (ainda não geradas), cai nas pinceladas procedurais.
	RenderingServer.global_shader_parameter_set("paint_tex", t if ok else 0)
	# Mundo como as cartas (docs/MUNDO_COMO_CARTAS.md): A cor, B escuros, C papel.
	RenderingServer.global_shader_parameter_set("paint_cor", bool(Settings.v.get("mundo_cor", true)))
	RenderingServer.global_shader_parameter_set("paint_escuro", bool(Settings.v.get("mundo_escuro", true)))
	RenderingServer.global_shader_parameter_set("paint_papel", bool(Settings.v.get("mundo_papel", true)))
	RenderingServer.global_shader_parameter_set("paint_t_papel", load(DIR + "papel.png"))


## B · escuros no ambiente: sem a névoa leitosa e com menos brilho, os escuros das sombras aparecem.
## Guarda os valores do chão na primeira vez (meta) para poder desligar sem recarregar a cena.
## A · cor: tira o reforço de saturação final (as unidades mantêm a cor delas).
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
	env.adjustment_color_correction = null
	if bool(Settings.v.get("mundo_escuro", true)):
		env.glow_intensity = b["glow_intensity"] * 0.7
		env.adjustment_color_correction = _lut()
	if bool(Settings.v.get("mundo_cor", true)):
		env.adjustment_saturation = minf(b["adjustment_saturation"], 1.0)


static var _lut_tex: ImageTexture3D


## LUT 3D do B: a imagem tem as 33 fatias (azul) lado a lado, cada uma 33x33 (vermelho em x, verde em y).
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


## F6/F7/F8 no jogo: liga e desliga A, B e C na hora. Devolve o texto do aviso.
static func toggle(key: String, env: Environment) -> String:
	Settings.v[key] = not bool(Settings.v.get(key, true))
	Settings.save()
	apply()
	apply_env(env)
	return "%s: %s" % [TranslationServer.translate("SET_" + key), TranslationServer.translate("UI_ON" if Settings.v[key] else "UI_OFF")]
