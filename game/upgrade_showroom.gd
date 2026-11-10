extends Control
## Vitrine dos upgrades de carta: a mesma carta (monstro e feitiço) em todos os estados, grande e compacta.
## godot --path . res://game/upgrade_showroom.tscn -- --variant=2        (teclas 0-3 trocam a proposta ao vivo)
## godot --path . --resolution 1600x900 res://game/upgrade_showroom.tscn -- --out=docs/decisoes_2026-11-10/upgrades/
##   (salva variante_0..3.png e sai). Propostas: game/card_fx_variants.gd; o padrão do jogo é a 0 (card_fx_variant).

const STATES := [
	["Base", 1, []], ["Nível 2", 2, []], ["Nível 3", 3, []],
	["Veterano", 1, ["veteran"]], ["Barato", 1, ["cheap"]], ["Explosivo", 1, ["explosive"]],
	["Amaldiçoado", 1, ["cursed"]], ["Sombrio", 1, ["shadowy"]],
	["N3 + Explosivo", 3, ["explosive"]], ["N2 + Amald. + Barato", 2, ["cursed", "cheap"]],
]
const VARIANT_NAMES := ["0 · Hoje", "1 · Encadernação", "2 · Tinta viva", "3 · Carimbos e condecorações"]
const BIG_W := 124.0
const MINI_W := 108.0
const SIZE := Vector2i(1600, 900)

var data: GameData
var variant := 0
var holder: Control
var sv: SubViewport


func _ready() -> void:
	Settings.load_all()
	Settings.v["look_hud"] = 6
	TranslationServer.set_locale("pt")
	UiSkins.apply()
	data = GameData.load_dir()
	Tips.data = data
	# A vitrine desenha num SubViewport de 1600x900 fixos: a captura sai do mesmo tamanho em qualquer monitor.
	var svc := SubViewportContainer.new()
	svc.stretch = false
	add_child(svc)
	sv = SubViewport.new()
	sv.size = SIZE
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)
	UiCovil.sync(sv)
	RenderingServer.global_shader_parameter_set("ui_px", 1.0)
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.13, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sv.add_child(bg)
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	variant = int(args.get("variant", Settings.v.get("card_fx_variant", 0)))
	if args.has("out"):
		for v in 4:
			_show(v)
			for i in 45:
				await get_tree().process_frame
			sv.get_texture().get_image().save_png(str(args["out"]) + "variante_%d.png" % v)
		get_tree().quit()
	else:
		_show(variant)


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode >= KEY_0 and e.keycode <= KEY_3:
		_show(e.keycode - KEY_0)


func _show(v: int) -> void:
	variant = v
	Settings.v["card_fx_variant"] = v
	if holder:
		holder.free()
	holder = VBoxContainer.new()
	holder.position = Vector2(30, 8)
	holder.add_theme_constant_override("separation", 0)
	sv.add_child(holder)
	var title := Label.new()
	title.text = "Upgrades de carta · proposta " + VARIANT_NAMES[v] + "   (teclas 0-3)"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.93, 0.87, 0.72))
	holder.add_child(title)
	for spec in [["ogre", true], ["ogre", false], ["shadow_bolt", true], ["shadow_bolt", false]]:
		holder.add_child(_row(spec[0], spec[1]))


func _row(id: String, big: bool) -> Control:
	var d: CardDef = data.card(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	for s in STATES:
		var names: Array = s[2].map(func(m): return TranslationServer.translate("MOD_" + m))
		var cost := maxi(d.cost_at(s[1]) - (1 if s[2].has("cheap") else 0), 1)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		var card: Control
		if big:
			card = UiKit.card(d, cost, names, "", BIG_W, s[1])
		else:
			card = UiKit.mini_card(d, cost, names, "", MINI_W, MINI_W * 1.26, true, s[1])
		# Espaço fixo para a carta (o texto do N3 estica a grande) e para o que pende do pé (fita, medalhas).
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(BIG_W, 214.0 if big else MINI_W * 1.26 + 26.0)
		slot.add_child(card)
		col.add_child(slot)
		var cap := Label.new()
		cap.text = s[0]
		cap.add_theme_font_size_override("font_size", 12)
		cap.add_theme_color_override("font_color", Color(0.85, 0.8, 0.68))
		cap.custom_minimum_size = Vector2(BIG_W, 0)
		col.add_child(cap)
		row.add_child(col)
	return row
