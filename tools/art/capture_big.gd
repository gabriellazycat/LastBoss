extends SceneTree
## Abre o jogo numa janela de 1920x1080 mesmo num monitor menor (o --resolution é cortado pela tela;
## mudar o tamanho depois de criada a janela não é). Repassa os argumentos do jogo (--shots, --set...).
## godot --path . -s res://tools/art/capture_big.gd -- --start=horde --shots=5 --quit=6 --out=<pasta>/
## Com --size=WxH escolhe outro tamanho; com --scene=res://... abre outra cena (vitrines, pranchas).

func _init() -> void:
	_go.call_deferred()


func _go() -> void:
	var size := Vector2i(1920, 1080)
	var scene := "res://game/main.tscn"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = a.trim_prefix("--scene=")
		if a.begins_with("--size="):
			var p := a.trim_prefix("--size=").split("x")
			size = Vector2i(int(p[0]), int(p[1]))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i.ZERO)
	DisplayServer.window_set_size(size)
	for i in 3:
		await process_frame
	change_scene_to_file(scene)
