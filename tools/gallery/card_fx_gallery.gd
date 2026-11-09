extends Control
## Galeria dos visuais de upgrade (nível, modificadores, combos): carta grande e compacta lado a lado.
## godot --path . res://tools/gallery/card_fx_gallery.tscn -- --out=<pasta>/   (salva card_fx.png e sai)

var data: GameData


func _ready() -> void:
	Settings.load_all()
	Settings.v["look_hud"] = 6
	UiSkins.apply()
	data = GameData.load_dir()
	Tips.data = data
	UiCovil.sync(get_viewport())
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.13, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cases := [
		["skeleton_archers", 1, []], ["skeleton_archers", 2, []], ["skeleton_archers", 3, []],
		["dark_forge", 2, []], ["skeleton_archers", 1, ["cheap"]], ["skeleton_archers", 1, ["veteran"]],
		["skeleton_archers", 1, ["explosive"]], ["skeleton_archers", 1, ["cursed"]], ["skeleton_archers", 1, ["shadowy"]],
		["skeleton_archers", 3, ["explosive", "cheap"]], ["rat_horde", 2, ["veteran", "cursed"]], ["shadow_bolt", 3, ["shadowy"]],
	]
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 22)
	grid.position = Vector2(24, 20)
	add_child(grid)
	for c in cases:
		var d: CardDef = data.card(c[0])
		if d == null:
			d = data.card("skeleton_archers")
		var names: Array = c[2].map(func(m): return TranslationServer.translate("MOD_" + m))
		var cost := d.cost_at(c[1]) - (1 if c[2].has("cheap") else 0)
		cost = maxi(cost, 1)
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 8)
		cell.add_child(UiKit.card(d, cost, names, "", 168.0, c[1]))
		grid.add_child(cell)
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	if args.has("out"):
		for i in 40:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(str(args["out"]) + "card_fx.png")
		await get_tree().create_timer(0.35).timeout
		get_viewport().get_texture().get_image().save_png(str(args["out"]) + "card_fx_b.png")
		get_tree().quit()
