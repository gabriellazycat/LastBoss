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
