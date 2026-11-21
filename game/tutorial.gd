class_name Tutorial
extends Control
## Fase 0 (tutorial guiado, rodada autônoma de 09/11/2026): caixas que param o jogo na hora certa e explicam
## uma coisa por vez. A run em si é normal (3 Escudeiros fracos, 1 ato); só as caixas são do tutorial.

const STEPS := ["TUT_welcome", "TUT_play", "TUT_deck", "TUT_temp", "TUT_pack", "TUT_call", "TUT_shield", "TUT_location",
	"TUT_fall", "TUT_arena", "TUT_done"]

var sim: Sim
var shown: Dictionary = {}
var holding := false          # o jogo fica parado enquanto a caixa está aberta
var panel: PanelContainer
var body: RichTextLabel
var skip_all := false


func bind(s: Sim) -> void:
	sim = s
	shown = {}
	holding = false
	skip_all = false
	visible = true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.12, 0.95)
	sb.border_color = Color(0.95, 0.78, 0.35)
	sb.set_border_width_all(3)
	sb.set_content_margin_all(UiKit.SP_XL)
	UiKit.fit_margins(sb)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.custom_minimum_size = Vector2(576, 0)
	body.add_theme_font_size_override("normal_font_size", 22)
	v.add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var skip := Button.new()
	skip.text = "UI_SKIP_TUTORIAL"
	skip.custom_minimum_size = Vector2(200, 46)
	skip.pressed.connect(func():
		skip_all = true
		_close())
	row.add_child(skip)
	var ok := Button.new()
	ok.name = "Ok"
	ok.text = "UI_TUT_OK"
	ok.custom_minimum_size = Vector2(180, 46)
	ok.pressed.connect(_close)
	row.add_child(ok)
	panel.visible = false


func _close() -> void:
	panel.visible = false
	holding = false


func _show(key: String) -> void:
	if shown.has(key) or skip_all:
		return
	shown[key] = true
	body.text = Tips.rich(tr(key), false)
	panel.visible = true
	holding = key != "TUT_done"
	panel.reset_size()
	panel.position = Vector2((size.x - panel.size.x) * 0.5, size.y * 0.22)
	(panel.find_child("Ok", true, false) as Button).grab_focus.call_deferred()


## Chamado a cada quadro pelo main: decide se alguma dica vale agora.
func tick() -> void:
	if sim == null or not visible or panel.visible:
		return
	var st: Dictionary = sim.stats
	if sim.phase == K.Phase.OVER:
		if str(st["result"]) in ["win", "win_early"]:
			_show("TUT_done")
		return
	if sim.t > 0.3:
		_show("TUT_welcome")
	if shown.has("TUT_welcome") and sim.t > 1.5:
		_show("TUT_play")
	if shown.has("TUT_play") and sim.t > 20.0:
		_show("TUT_deck")
	var hand_ids: Array = sim.hand.filter(func(c): return c != null).map(func(c): return c.def.id)
	if sim.t > 8.0 and hand_ids.has("rabid_rats"):
		_show("TUT_pack")
	if sim.t > 4.0 and sim.hand.any(func(c): return c != null and c.def.category == "lair"):
		_show("TUT_temp")
	if sim.units.n_pack >= 6 and hand_ids.has("pack_call"):
		_show("TUT_call")
	if int(st["shield_breaks"]) > 0 or sim.t > 70.0:
		_show("TUT_shield")
	if sim.contest.size() > 0:
		_show("TUT_location")
	if int(st["heroes_fallen"]) >= 1:
		_show("TUT_fall")
	if sim.phase == K.Phase.ARENA:
		_show("TUT_arena")
