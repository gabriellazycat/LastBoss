extends Control
## Captura da tela de revelação das cartas liberadas (fim da fase), com 3 cartas de exemplo.
## godot --path . res://tools/gallery/unlock_reveal_shot.tscn -- --out=<pasta>/   (salva unlock_1_costas.png, _2_meio.png, _3_todas.png)
## Sem --out fica aberta para testar com mouse e teclado. --none mostra o caso sem cartas ("Quase lá").

var data: GameData


func _ready() -> void:
	Settings.load_all()
	Settings.v["look_hud"] = 7   # a pele padrão (Mapa aberto)
	UiSkins.apply()
	data = GameData.load_dir()
	Tips.data = data
	UiCovil.sync(get_viewport())
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.17, 0.13)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var result := {"done": [{"id": "ogre", "v": 67.0, "g": 60.0}, {"id": "cave_troll", "v": 1.0, "g": 1.0},
		{"id": "corrupt_piper", "v": 214.0, "g": 200.0}],
		"near": [{"id": "rat_tide", "v": 11.0, "g": 15.0}, {"id": "alpha_beast", "v": 22.0, "g": 30.0}]}
	if args.has("many"):   # muitas cartas e relíquias de uma vez: a lista tem de caber (quebra em linhas e rola)
		var n := int(args["many"]) if str(args["many"]) != "" else 18
		var ids: Array = ["ogre", "cave_troll", "corrupt_piper", "rat_tide"]
		for rid in data.relic_ids:
			ids.append("r:" + rid)
		result["done"] = ids.slice(0, n).map(func(i): return {"id": i, "v": 3.0, "g": 3.0})
	if args.has("none"):
		result["done"] = []
		var l := UiKit.label(20, UiKit.TEXT, 3)
		l.text = UnlockReveal.near_text(result)
		l.position = Vector2(40, 40)
		add_child(l)
		print("near: ", l.text)
	var rv := UnlockReveal.build(data, result)
	if rv == null:
		return
	add_child(rv)
	if args.has("out"):
		var out := str(args["out"])
		await get_tree().create_timer(0.5).timeout
		get_viewport().get_texture().get_image().save_png(out + "unlock_1_costas.png")
		rv.btn.pressed.emit()
		await get_tree().create_timer(1.2).timeout
		get_viewport().get_texture().get_image().save_png(out + "unlock_2_meio.png")
		rv.btn.pressed.emit()
		rv.btn.pressed.emit()
		await get_tree().create_timer(1.4).timeout
		get_viewport().get_texture().get_image().save_png(out + "unlock_3_todas.png")
		get_tree().quit()
