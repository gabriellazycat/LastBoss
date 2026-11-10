class_name CardFx
extends Control
## Camada por cima de uma carta desenhada que mostra os upgrades (rodada 09/11/2026, "visual de upgrade"):
## - o NÍVEL é dono da moldura e da croma: N2 aço frio; N3 ouro pulsando com reflexo holográfico passando;
## - cada MODIFICADOR tem papel (aplicado no material da carta, ver `paper_for`), selo no canto e um efeito
##   animado. Em combo, o papel é o do primeiro modificador ganho; selos e efeitos se somam.
## Não pega o mouse.

const STEEL := Color(0.74, 0.82, 0.9)
const GOLD := Color(0.98, 0.76, 0.27)
## Cor do selo e do efeito de cada modificador.
const MOD_COLOR := {
	"cheap": Color(0.08, 0.65, 0.7),
	"veteran": Color(0.24, 0.44, 0.75),
	"explosive": Color(0.9, 0.44, 0.16),
	"cursed": Color(0.5, 0.2, 0.66),
	"shadowy": Color(0.17, 0.16, 0.2),
}
## Papel de cada modificador: [claro, escuro] (paper_a, paper_b do shader) e se é papel escuro (texto claro).
const PAPER := {
	"cheap": [Color(0.8, 0.92, 0.88), Color(0.6, 0.8, 0.76), false],
	"veteran": [Color(0.24, 0.32, 0.52), Color(0.14, 0.2, 0.37), true],
	"explosive": [Color(0.86, 0.73, 0.55), Color(0.42, 0.24, 0.12), false],
	"cursed": [Color(0.33, 0.2, 0.42), Color(0.17, 0.08, 0.23), true],
	"shadowy": [Color(0.17, 0.16, 0.2), Color(0.07, 0.07, 0.09), true],
}
const CREAM := Color(0.95, 0.9, 0.8)

var level := 1
var mids: Array = []
var k := 1.0                # escala da carta (1 = carta compacta de 116 px)
var t := 0.0
var gem: Control = null     # gema de custo (o Barato faz ela pulsar)
var big := false            # carta grande (a compacta não tem texto embaixo)


static func paper_for(mids_: Array) -> Array:
	return PAPER.get(mids_[0], []) if mids_.size() > 0 else []


## Põe a camada na carta `p` (PanelContainer) e troca o papel pelo do primeiro modificador.
static func attach(p: Control, level_: int, mids_: Array, k_: float, big_ := false) -> CardFx:
	if level_ <= 1 and mids_.is_empty():
		return null
	var fx := CardFx.new()
	fx.level = level_
	fx.mids = mids_
	fx.k = k_
	fx.big = big_
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.name = "CardFx"
	var pp := paper_for(mids_)
	var m := p.material as ShaderMaterial
	if m and pp.size() > 0 and variant() == 0:
		m.set_shader_parameter("paper_a", pp[0])
		m.set_shader_parameter("paper_b", pp[1])
	if m and variant() == 4:
		m.set_shader_parameter("mat_id", material_for(level_, mids_))
	p.add_child(fx)
	return fx


## Material da carta na variante 4 (`mat_id` do paper.gdshader): o nível manda (N2 ferro, N3 ouro); no N1 vale o do
## primeiro modificador. 0 = papel.
const MOD_MATERIAL := {"shadowy": 3, "cursed": 4, "explosive": 5, "cheap": 6, "veteran": 7}


static func material_for(level_: int, mids_: Array) -> int:
	if level_ >= 3:
		return 2
	if level_ == 2:
		return 1
	return int(MOD_MATERIAL.get(mids_[0], 0)) if mids_.size() > 0 else 0


## Proposta visual dos upgrades (Settings `card_fx_variant`): 0 = a de hoje; 1 Encadernação, 2 Tinta viva,
## 3 Carimbos e condecorações, 4 Carimbo + material do fundo (game/card_fx_variants.gd; vitrine em game/upgrade_showroom.tscn).
static func variant() -> int:
	return int(Settings.v.get("card_fx_variant", 0))


static func is_dark(mids_: Array, level_ := 1) -> bool:
	if variant() == 4:   # fundo escuro (ferro, aço, obsidiana, pedra, brasa): texto claro nas legendas fora da etiqueta
		return material_for(level_, mids_) in [1, 3, 4, 5, 6, 7]
	if variant() != 0:
		return false
	var pp := paper_for(mids_)
	return pp.size() > 0 and pp[2]


func _ready() -> void:
	gem = get_parent().find_child("Gem", true, false) as Control
	t = randf() * 10.0


func _process(delta: float) -> void:
	t += delta
	if gem and mids.has("cheap") and variant() == 0:
		gem.pivot_offset = gem.size * 0.5
		gem.scale = Vector2.ONE * (1.0 + 0.09 * maxf(0.0, sin(t * 4.0)) * _motion())
	queue_redraw()


func _motion() -> float:
	return clampf(float(Settings.v.get("shake", 1.0)), 0.0, 1.0)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-2.0 * k)
	var mo := _motion()
	if variant() != 0:
		CardFxV.draw(self, r, mo)
		return
	_draw_mod_fx(r, mo)
	if level == 2:
		draw_rect(r.grow(2.0 * k), Color(0.72, 0.86, 1.0, 0.22), false, 5.0 * k)
		draw_rect(r, STEEL, false, 2.6 * k)
		draw_rect(r.grow(-2.6 * k), Color(1, 1, 1, 0.35), false, 1.0)
	elif level >= 3:
		var pulse := 0.5 + 0.5 * sin(t * 3.2) * mo
		draw_rect(r.grow(3.0 * k), Color(1.0, 0.85, 0.4, 0.18 + 0.22 * pulse), false, 7.0 * k)
		_holo(r, mo)
		draw_rect(r, GOLD, false, 3.0 * k)
		draw_rect(r.grow(-3.0 * k), Color(1.0, 0.95, 0.7, 0.55), false, 1.0)
	_pips(r)
	_seals(r)


## Faixa de reflexo arco-íris que atravessa a carta na diagonal (cortada no retângulo da carta).
func _holo(r: Rect2, mo: float) -> void:
	var period := 2.6
	var ph := fmod(t, period) / period
	if mo <= 0.0:
		ph = 0.45
	var span := r.size.x + r.size.y
	var x0 := r.position.x - r.size.y + ph * (span + r.size.x * 0.6)
	var bands := [Color(1.0, 0.93, 0.6, 0.0), Color(1.0, 0.92, 0.6, 0.28), Color(0.7, 0.95, 1.0, 0.26), Color(1.0, 0.7, 0.95, 0.22), Color(1.0, 0.8, 0.9, 0.0)]
	var bw := 10.0 * k
	var rect_poly := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	for i in bands.size() - 1:
		var a := x0 + i * bw
		var poly := PackedVector2Array([Vector2(a, r.end.y), Vector2(a + bw, r.end.y), Vector2(a + bw + r.size.y * 0.6, r.position.y), Vector2(a + r.size.y * 0.6, r.position.y)])
		for piece in Geometry2D.intersect_polygons(poly, rect_poly):
			_poly(piece, bands[i].lerp(bands[i + 1], 0.5))


## Losangos do nível no pé da carta, à esquerda: cheios até o nível.
func _pips(r: Rect2) -> void:
	if level <= 1:
		return
	var s := 4.4 * k
	var col := GOLD if level >= 3 else STEEL
	for i in 3:
		var c := Vector2(r.position.x + 7.0 * k + i * s * 2.4, r.end.y - 6.0 * k)
		var pts := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)])
		draw_colored_polygon(pts, Color(0.1, 0.08, 0.06, 0.75))
		var inner := PackedVector2Array([c + Vector2(0, -s * 0.7), c + Vector2(s * 0.7, 0), c + Vector2(0, s * 0.7), c + Vector2(-s * 0.7, 0)])
		if i < level:
			draw_colored_polygon(inner, col)


## Selos dos modificadores no canto de baixo à direita, da direita para a esquerda.
func _seals(r: Rect2) -> void:
	var rad := 7.5 * k
	for i in mids.size():
		var c := Vector2(r.end.x - rad - 3.0 * k - i * (rad * 2.0 + 2.0 * k), r.end.y - rad - 3.0 * k)
		var col: Color = MOD_COLOR.get(mids[i], Color.GRAY)
		draw_circle(c, rad + 1.6 * k, CREAM)
		draw_circle(c, rad, col)
		_seal_icon(mids[i], c, rad * 0.62)


func _seal_icon(mid: String, c: Vector2, s: float, ic := CREAM) -> void:
	var w := maxf(1.2, s * 0.28)
	match mid:
		"cheap":   # moeda
			draw_arc(c, s * 0.85, 0, TAU, 16, ic, w, true)
			draw_line(c + Vector2(0, -s * 0.45), c + Vector2(0, s * 0.45), ic, w, true)
		"veteran":   # divisas
			for dy in [-0.35, 0.25]:
				draw_polyline(PackedVector2Array([c + Vector2(-s * 0.75, s * (dy + 0.35)), c + Vector2(0, s * (dy - 0.25)), c + Vector2(s * 0.75, s * (dy + 0.35))]), ic, w, true)
		"explosive":   # bomba com pavio
			draw_circle(c + Vector2(-s * 0.1, s * 0.15), s * 0.62, ic)
			draw_line(c + Vector2(s * 0.3, -s * 0.3), c + Vector2(s * 0.7, -s * 0.75), ic, w, true)
			draw_circle(c + Vector2(s * 0.78, -s * 0.85), s * 0.18, Color(1.0, 0.85, 0.3))
		"cursed":   # olho
			draw_arc(c + Vector2(0, s * 0.55), s * 0.95, -PI * 0.82, -PI * 0.18, 10, ic, w, true)
			draw_arc(c + Vector2(0, -s * 0.55), s * 0.95, PI * 0.18, PI * 0.82, 10, ic, w, true)
			draw_circle(c, s * 0.3, ic)
		"shadowy":   # fantasma
			var pts := PackedVector2Array()
			for i in 9:
				var a := PI + PI * i / 8.0
				pts.append(c + Vector2(cos(a), sin(a)) * s * 0.7 + Vector2(0, -s * 0.05))
			pts.append(c + Vector2(s * 0.7, s * 0.75))
			pts.append(c + Vector2(s * 0.35, s * 0.5))
			pts.append(c + Vector2(0, s * 0.75))
			pts.append(c + Vector2(-s * 0.35, s * 0.5))
			pts.append(c + Vector2(-s * 0.7, s * 0.75))
			_poly(pts, ic)


## Efeitos animados de cada modificador (somam-se em combo).
func _draw_mod_fx(r: Rect2, mo: float) -> void:
	for mid in mids:
		var col: Color = MOD_COLOR[mid]
		match mid:
			"explosive":   # faíscas subindo do pé da carta e borda em brasa
				draw_rect(r, Color(1.0, 0.45, 0.12, 0.35 + 0.2 * sin(t * 6.0) * mo), false, 2.0 * k)
				if mo > 0.0:
					for i in 9:
						var life := fmod(t * 0.8 + i * 0.137, 1.0)
						var x := r.position.x + fmod(i * 0.381 + 0.11, 1.0) * r.size.x + sin(t * 3.0 + i) * 4.0 * k
						var y := r.end.y - life * r.size.y * 0.45
						draw_circle(Vector2(x, y), (1.6 - life) * 1.3 * k, Color(1.0, 0.8 - life * 0.4, 0.3, 1.0 - life))
			"cursed":   # tinta escorrendo do topo e aura pulsando
				var a := 0.35 + 0.3 * sin(t * 2.6) * mo
				draw_rect(r.grow(2.0 * k), Color(0.7, 0.3, 1.0, a * 0.6), false, 4.0 * k)
				for i in 4:
					var x := r.position.x + (0.14 + i * 0.24) * r.size.x
					var dl := (6.0 + 6.0 * fmod(i * 0.53, 1.0) + 4.0 * sin(t * 1.3 + i * 2.0) * mo) * k
					var dw := (2.4 + fmod(i * 0.71, 1.0) * 1.6) * k
					draw_rect(Rect2(x - dw * 0.5, r.position.y, dw, dl), Color(0.16, 0.05, 0.22, 0.9))
					draw_circle(Vector2(x, r.position.y + dl), dw * 0.75, Color(0.16, 0.05, 0.22, 0.9))
			"shadowy":   # fumaça escura passando por cima do desenho
				for i in 5:
					var ph := fmod(t * 0.12 * mo + i * 0.2, 1.0)
					var c := Vector2(r.position.x + ph * r.size.x, r.position.y + r.size.y * (0.3 + 0.08 * sin(i * 2.3 + t * mo)))
					draw_circle(c, (9.0 + i * 2.0) * k, Color(0.05, 0.04, 0.08, 0.22 * sin(ph * PI)))
			"veteran":   # reflexo metálico azul atravessando de tempos em tempos
				var ph := fmod(t / 3.0, 1.0)
				if mo > 0.0 and ph < 0.4:
					var x := r.position.x - r.size.x * 0.3 + ph / 0.4 * r.size.x * 1.6
					var poly := PackedVector2Array([Vector2(x, r.end.y), Vector2(x + 8.0 * k, r.end.y), Vector2(x + 8.0 * k + r.size.y * 0.4, r.position.y), Vector2(x + r.size.y * 0.4, r.position.y)])
					var rect_poly := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
					for piece in Geometry2D.intersect_polygons(poly, rect_poly):
						_poly(piece, Color(0.85, 0.92, 1.0, 0.3))
				draw_rect(r, Color(col.r, col.g, col.b, 0.8), false, 1.6 * k)
			"cheap":   # borda verde-água fina (a gema pulsa em _process)
				draw_rect(r, Color(col.r, col.g, col.b, 0.75), false, 1.6 * k)


## Polígono só se triangula (recortes finos na borda da carta às vezes degeneram e a Godot reclama).
func _poly(pts: PackedVector2Array, col: Color) -> void:
	if pts.size() >= 3 and Geometry2D.triangulate_polygon(pts).size() >= 3:
		draw_colored_polygon(pts, col)
