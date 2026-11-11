extends Node3D
## Monta o chefe atual e os 3 chefes finais lado a lado (BossModels.boss_full) com a câmera do jogo (55°, fov 40)
## e grava a foto. Uso (janela, não headless):
##   godot --path . res://docs/decisoes_2026-11-10/chefes/final/captura_chefes.tscn -- [--view=game|front|back] [--out=<arquivo.png>]

const ORDER := ["cur", "plague", "dragon", "lich"]
const TITLES := {"cur": "Lorde (atual)", "plague": "Rainha da Praga", "dragon": "Dragão Avarento", "lich": "Lich"}
var args := {}
var t := 0.0
var shot := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i.ZERO)
	DisplayServer.window_set_size(Vector2i(1800, 800))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 30, 0)
	sun.light_energy = 1.1
	sun.light_color = Color(0.7, 0.75, 1.0)
	sun.shadow_enabled = true
	add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-28, 165, 0)
	rim.light_energy = 0.7
	rim.light_color = Color(0.55, 0.65, 1.0)
	rim.light_specular = 0.0
	add_child(rim)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.1, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.42, 0.55)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_bloom = 0.1
	env.glow_hdr_threshold = 0.9
	env.sky = Sky.new()
	GroundLooks.apply_env(env, sun, rim)
	env.fog_enabled = false
	we.environment = env
	add_child(we)
	var floor_ := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 40)
	floor_.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.3, 0.29, 0.27)
	fm.roughness = 1.0
	floor_.material_override = fm
	add_child(floor_)
	var view: String = args.get("view", "game")
	for i in ORDER.size():
		var v: String = ORDER[i]
		var b: Node3D = Models.boss_full() if v == "cur" else BossModels.boss_full(v)
		b.position = Vector3(-9.75 + i * 6.5, 0, 0)
		# A frente do chefe é -Z; na arena ele encara o herói (e a câmera), então gira 180° (menos na vista de costas).
		if view != "back":
			b.rotation_degrees.y = 180
		add_child(b)
		var lab := Label3D.new()
		lab.text = TITLES[v] + ("" if v == "cur" or BossModels.has_model(v) else " (faltou modelo)")
		lab.font_size = 96
		lab.outline_size = 18
		lab.position = b.position + Vector3(0, 0.05, 3.2)
		lab.rotation_degrees = Vector3(-90, 0, 0)
		add_child(lab)
		# régua de 5,6 m (altura do chefe atual)
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.06, 5.6, 0.06)
		bar.mesh = bm
		bar.position = b.position + Vector3(2.9, 2.8, 0)
		bar.visible = view != "game"
		add_child(bar)
	var cam := Camera3D.new()
	cam.fov = 40
	cam.far = 500
	add_child(cam)
	var tgt := Vector3(0, 2.2, 0)
	if view == "front" or view == "back":
		cam.position = Vector3(0, 3.5, 26)
	else:
		var d := 19.5
		cam.position = tgt + Vector3(0, sin(deg_to_rad(55.0)) * d, cos(deg_to_rad(55.0)) * d)
	cam.look_at(tgt, Vector3.UP)
	cam.current = true


func _process(delta: float) -> void:
	t += delta
	if t > 1.5 and not shot:
		shot = true
		var out := str(args.get("out", "res://docs/decisoes_2026-11-10/chefes/final/chefes_jogo.png"))
		if out.begins_with("res://"):
			out = ProjectSettings.globalize_path(out)
		get_viewport().get_texture().get_image().save_png(out)
		print("captura: ", out)
		get_tree().quit()
