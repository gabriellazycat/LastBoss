extends SceneTree
## Teste rápido dos rios (t_rivers e t_water), sem a suíte inteira: godot --headless -s res://tools/river/quick.gd
func _init() -> void:
	SimRivers.DEBUG = true
	var T = load("res://tests/tests.gd").new()
	T.data = GameData.load_dir()
	if not OS.get_cmdline_user_args().has("--so-agua"):
		T.t_rivers()
	T.t_water()
	print("motivos: ", SimRivers.STATS)
	print("falhas: ", T.fails)
	quit(T.fails)
