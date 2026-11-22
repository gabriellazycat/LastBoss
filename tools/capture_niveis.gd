extends SceneTree
## Captura de conferência dos níveis I a VI da carta (frente C). Uso (janela fora da tela):
## Godot --position -6000,0 --path . --script tools/capture_niveis.gd -- --out=docs/metaprogressao/niveis_I_a_VI.png

func _initialize() -> void:
	var out := "res://docs/metaprogressao/niveis_I_a_VI.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var data := GameData.load_dir()
	root.size = Vector2i(1800, 560)
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.14, 0.12)
	bg.size = Vector2(1800, 560)
	root.add_child(bg)
	var d: CardDef = data.card("soul_feast")
	for lv in range(1, 7):
		var c := CardMold.build(d, d.cost_at(lv), [], "", 270.0, 378.0, false, lv)
		c.position = Vector2(20 + (lv - 1) * 290, 90)
		root.add_child(c)
	await create_timer(1.0).timeout
	await process_frame
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out).get_base_dir())
	img.save_png(ProjectSettings.globalize_path(out))
	quit()
