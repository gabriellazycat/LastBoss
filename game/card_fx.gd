class_name CardFx
extends Control
## Camada por cima de uma carta desenhada que mostra os upgrades: o nível e o primeiro modificador trocam o material
## do fundo da carta (mat_id do paper.gdshader, ver material_for) e o desenho (filete do nível, carimbo de cada
## modificador) fica em CardFxV (game/card_fx_variants.gd). Não pega o mouse.

## Cor de cada modificador (também usada pela HUD no brilho das ofertas).
const MOD_COLOR := {
	"cheap": Color(0.08, 0.65, 0.7),
	"veteran": Color(0.24, 0.44, 0.75),
	"explosive": Color(0.9, 0.44, 0.16),
	"cursed": Color(0.5, 0.2, 0.66),
	"shadowy": Color(0.17, 0.16, 0.2),
	"leech": Color(0.78, 0.1, 0.2),
}

var level := 1
var mids: Array = []
var k := 1.0                # escala da carta (1 = carta compacta de 116 px)
var t := 0.0
var big := false            # carta grande (a compacta não tem texto embaixo)


## Põe a camada na carta `p` (PanelContainer) e troca o material do fundo pelo do nível/modificador.
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
	var m := p.material as ShaderMaterial
	if m:
		m.set_shader_parameter("mat_id", material_for(level_, mids_))
	p.add_child(fx)
	return fx


## Material da carta (`mat_id` do paper.gdshader): o nível manda (N2 ferro, N3 ouro); no N1 vale o do
## primeiro modificador. 0 = papel.
const MOD_MATERIAL := {"shadowy": 3, "cursed": 4, "explosive": 5, "cheap": 6, "veteran": 7, "leech": 4}


static func material_for(level_: int, mids_: Array) -> int:
	if level_ >= 3:
		return 2
	if level_ == 2:
		return 1
	return int(MOD_MATERIAL.get(mids_[0], 0)) if mids_.size() > 0 else 0


## Fundo escuro (ferro, aço, obsidiana, pedra, brasa): texto claro nas legendas fora da etiqueta.
static func is_dark(mids_: Array, level_ := 1) -> bool:
	return material_for(level_, mids_) in [1, 3, 4, 5, 6, 7]


func _ready() -> void:
	t = randf() * 10.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _motion() -> float:
	return clampf(float(Settings.v.get("shake", 1.0)), 0.0, 1.0)


func _draw() -> void:
	CardFxV.draw(self, Rect2(Vector2.ZERO, size).grow(-2.0 * k), _motion())
