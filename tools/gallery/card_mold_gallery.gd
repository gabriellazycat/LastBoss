extends Control
## Galeria do molde único de cartas (game/card_mold.gd): carta grande e compacta, níveis, modificadores e combos.
## godot --path . res://tools/gallery/card_mold_gallery.tscn -- --out=<pasta>/ [--page=1|2]   (salva card_mold_<page>.png e sai)

var data: GameData


func _ready() -> void:
	Settings.load_all()
	TranslationServer.set_locale("pt")
	Settings.v["look_hud"] = 6
	UiSkins.apply()
	data = GameData.load_dir()
	Tips.data = data
	UiCovil.sync(get_viewport())
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var page := int(args.get("page", "1"))
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.13, 0.1) if page == 1 else Color(0.13, 0.19, 0.17)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cases := [
		["rat_horde", 1, []], ["rat_burrow", 1, []], ["rat_king", 3, []], ["rat_king", 1, ["cheap"]], ["rat_king", 1, ["veteran"]],
		["rat_king", 1, ["explosive"]], ["rat_king", 1, ["cursed"]], ["rat_king", 1, ["shadowy"]], ["rat_king", 3, ["explosive"]], ["rat_king", 2, ["veteran", "cursed"]],
	]
	var grid := GridContainer.new()
	grid.columns = 5 if page == 1 else 10
	grid.add_theme_constant_override("h_separation", 30 if page == 1 else 10)
	grid.add_theme_constant_override("v_separation", 26)
	grid.position = Vector2(34, 24)
	add_child(grid)
	for c in cases:
		var d: CardDef = data.card(c[0])
		var names: Array = c[2].map(func(m): return TranslationServer.translate("MOD_" + m))
		var cost := maxi(d.cost_at(c[1]) - (1 if c[2].has("cheap") else 0), 0)
		if page == 1:
			grid.add_child(UiKit.card(d, cost, names, "", 250.0, c[1]))
		else:
			grid.add_child(UiKit.mini_card(d, cost, names, "1", 124.0, 158.0, true, c[1]))
	if page == 2:
		var row2 := HBoxContainer.new()
		row2.position = Vector2(34, 330)
		row2.add_theme_constant_override("separation", 22)
		add_child(row2)
		for id in ["skeleton_archers", "shadow_bolt", "bone_totem", "elder_dragon", "dark_forge", "web"]:
			var d2: CardDef = data.card(id)
			if d2 != null:
				row2.add_child(UiKit.card(d2, d2.cost, [], "", 210.0, 1))
	if args.has("out"):
		for i in 50:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(str(args["out"]) + "card_mold_%d.png" % page)
		get_tree().quit()
