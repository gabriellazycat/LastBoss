extends SceneTree
## Carrega todos os .gd de game/, sim/, bots/, headless/ e tests/ e sai com o número dos que não compilam.
## godot --headless --path . --script res://tools/check_scripts.gd
func _init() -> void:
	var bad := 0
	var n := 0
	for d in ["res://game", "res://sim", "res://bots", "res://headless", "res://tests"]:
		for f in _list(d):
			n += 1
			var s = load(f)
			if s == null or (s is GDScript and not (s as GDScript).can_instantiate()):
				bad += 1
				print("FALHOU ", f)
	print("scripts: ", n, " falhas: ", bad)
	quit(bad)

func _list(d: String) -> Array:
	var out: Array = []
	var da := DirAccess.open(d)
	if da == null:
		return out
	for f in da.get_files():
		if f.ends_with(".gd"):
			out.append(d + "/" + f)
	for sub in da.get_directories():
		out += _list(d + "/" + sub)
	return out
