extends Node3D
## Prancha da rodada "miniaturas pintadas" (15/11/2026): 2 heróis, 10 inimigos e 10 cenários de UMA versão, no chão,
## na estrada e na luz do jogo (guache S1), em três distâncias de câmera. Fotos em --out.
## godot --path . -s res://tools/art/capture_big.gd -- --scene=res://tools/art/board_g.tscn --geom=n --tex=dabs --out=<pasta>/
## --geom: n normal, c gorducha, f facetada · --tex: vc (cor por vértice, controle), dabs, wash, dry, flat · --shots=perto,jogo,detalhe

const HEROES := ["escudeiro", "mago"]
const UNITS := ["rat", "rat_king", "goblin_dynamiter", "slime", "skeleton", "ogre", "werewolf", "bat", "ghost", "mimic"]
const PROPS := ["tree", "tree_round", "rock", "bush", "house", "tavern", "fountain", "gravestone", "lantern", "fence"]

var args := {}
var cam: Camera3D
var t := 0.0
var shots: Array = []
var geom := "n"
var tex := "vc"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	geom = str(args.get("geom", "n"))
	tex = str(args.get("tex", "vc"))
	Settings.v["look_ground"] = 10
	Settings.v["paint_look"] = int(args.get("paint", "1"))
	PaintLook.apply()
	_env()
	var pts := PackedVector2Array()
	for i in 40:
		var z := -40.0 + i * 2.0
		pts.append(Vector2(sin(z * 0.06) * 4.0, z))
	var road := MeshInstance3D.new()
	road.mesh = GroundLooks.road_mesh(pts, 5.0)
	road.material_override = GroundLooks.road_material()
	add_child(road)
	# Cenário em volta da estrada: dez peças de cada lado, em duas fileiras.
	var spots := [Vector3(-10, 0, -7), Vector3(9, 0, -9), Vector3(-7, 0, 3), Vector3(8, 0, 4), Vector3(-13, 0, -1),
		Vector3(13, 0, -2), Vector3(-5.5, 0, -12), Vector3(6.5, 0, -14), Vector3(-9.5, 0, 9), Vector3(10.5, 0, 8)]
	for i in PROPS.size():
		_put(PROPS[i], spots[i], 0.6 + i * 1.1, false)
	# Inimigos vindo pela estrada em direção aos heróis, que esperam em baixo.
	for i in UNITS.size():
		var row := i / 5
		var col := i % 5
		_put(UNITS[i], Vector3((col - 2) * 2.4 + 0.5, 0, -4.5 + row * 3.2), PI, true)
	for i in HEROES.size():
		_put(HEROES[i], Vector3(-1.2 + i * 2.4 + 0.5, 0, 6.0), 0.0, true)
	# Grama como no jogo.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var gm := MultiMesh.new()
	gm.transform_format = MultiMesh.TRANSFORM_3D
	gm.mesh = GroundLooks.grass_mesh()
	gm.instance_count = 900
	for k in 900:
		var q := Vector3(rng.randf_range(-30, 30), 0, rng.randf_range(-35, 15))
		if absf(q.x - sin(q.z * 0.06) * 4.0) < 3.5:
			q.x += 8.0 * signf(q.x + 0.01)
		gm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.7, 1.3)), q))
	var gi := MultiMeshInstance3D.new()
	gi.multimesh = gm
	gi.material_override = GroundLooks.grass_material()
	add_child(gi)
	var names := str(args.get("shots", "jogo,perto,detalhe")).split(",")
	var table := {"jogo": [30.0, Vector3(0.5, 0, 0)], "perto": [14.0, Vector3(0.5, 0, 0.5)], "detalhe": [7.0, Vector3(0.5, 0, 1.5)],
		"herois": [6.0, Vector3(0.5, 0, 6.0)], "cenario": [22.0, Vector3(0, 0, -2)]}
	var tt := 3.0
	for n in names:
		shots.append([tt, n, table[n][0], table[n][1]])
		tt += 1.0
	_cam(shots[0][2], shots[0][3])


func _mesh(id: String) -> Mesh:
	var d := "g_%s" % geom if tex == "vc" else "g_%s_a" % geom
	var p := "res://assets/models/%s/%s.res" % [d, id]
	if ResourceLoader.exists(p):
		return load(p)
	# Sem a geometria desta variante (ex.: gorducha só tem corpos): a normal.
	p = "res://assets/models/%s/%s.res" % ["g_n" if tex == "vc" else "g_n_a", id]
	return load(p) if ResourceLoader.exists(p) else null


func _mat(m: Mesh, id: String, unit: bool) -> ShaderMaterial:
	var mat := Looks.material(5, 0.0, false, m)
	if m.has_meta("vat"):
		mat.set_shader_parameter("pose_frame", 0.3)
	if tex != "vc":
		var g := geom if _has_tex(id, geom) else "n"
		var p := "res://assets/models/g_tex/%s_%s/%s.png" % [tex if g == geom else "dabs", g, id]
		if g != geom:
			p = "res://assets/models/g_tex/%s_n/%s.png" % [tex if tex != "dabs" else "dabs", id]
		var tx: Texture2D = load(p) if ResourceLoader.exists(p) else null
		if tx:
			mat.set_shader_parameter("use_tex", true)
			mat.set_shader_parameter("albedo_tex", tx)
			mat.set_shader_parameter("atlas", true)
		if tex == "flat":
			mat.set_shader_parameter("ink", 0.85)
	return mat


func _has_tex(id: String, g: String) -> bool:
	return ResourceLoader.exists("res://assets/models/g_tex/%s_%s/%s.png" % [tex, g, id])


func _put(id: String, pos: Vector3, yaw: float, unit: bool) -> void:
	var m := _mesh(id)
	if m == null:
		push_warning("sem malha: " + id)
		return
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = _mat(m, id, unit)
	mi.position = pos
	mi.rotation.y = yaw
	if unit and (id in HEROES):
		mi.scale = Vector3.ONE * 1.3
	add_child(mi)


func _cam(dist: float, target: Vector3) -> void:
	cam.position = target + Vector3(0, dist * 0.8, dist * 0.6)
	cam.look_at(target + Vector3(0, 0, -2), Vector3.UP)


func _env() -> void:
	cam = Camera3D.new()
	cam.fov = 50
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.sky = Sky.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.ssao_enabled = true
	env.glow_enabled = true
	env.adjustment_enabled = true
	we.environment = env
	add_child(we)
	GroundLooks.apply_env(env, sun)
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	pm.subdivide_width = 16
	pm.subdivide_depth = 16
	var g := MeshInstance3D.new()
	g.mesh = pm
	g.material_override = GroundLooks.ground_material()
	g.position = Vector3(60, 0, 60)
	add_child(g)


func _process(delta: float) -> void:
	t += delta
	if shots.size() > 0 and t >= shots[0][0]:
		var s: Array = shots.pop_front()
		var out := str(args.get("out", "user://"))
		get_viewport().get_texture().get_image().save_png(out + "board_%s.png" % s[1])
		if shots.size() > 0:
			_cam(shots[0][2], shots[0][3])
		else:
			get_tree().quit()
