extends Node3D
## Prancha da direção nova (Blender v2): monstros e cenário juntos sobre o chão e a luz de um look de chão,
## com o herói da KayKit, na câmera do jogo e numa mais perto. Fotos em --out.
## godot --path . -s res://tools/art/capture_big.gd -- --scene=res://tools/art/board_v2.tscn --out=<pasta>/ [--ground=10]
## --units=rat,goblin_dynamiter,...  --props=tree,rock,...  --dir=v2

var args := {}
var cam: Camera3D
var t := 0.0
var shots: Array = []
var dir := "v2"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	dir = str(args.get("dir", "v2"))
	Settings.v["look_ground"] = int(args.get("ground", "10"))
	_env()
	if args.get("layout", "") == "locs":
		_locations()
		return
	if args.get("layout", "") == "anim":
		_anim_check()
		return
	var units: PackedStringArray = str(args.get("units", "rat,goblin_dynamiter,skeleton,ghost,ogre")).split(",")
	var props: PackedStringArray = str(args.get("props", "tree,rock,house,lantern,fence")).split(",")
	# Estrada em S passando pelo meio, como no jogo.
	var pts := PackedVector2Array()
	for i in 40:
		var z := -40.0 + i * 2.0
		pts.append(Vector2(sin(z * 0.06) * 4.0, z))
	var road := MeshInstance3D.new()
	road.mesh = GroundLooks.road_mesh(pts, 5.0)
	road.material_override = GroundLooks.road_material()
	add_child(road)
	# Cenário de um lado e de outro da estrada; monstros vindo pela estrada em direção ao herói.
	var spots := [Vector3(-9, 0, -8), Vector3(7, 0, -3), Vector3(-10, 0, 4), Vector3(6.5, 0, 5), Vector3(-5.5, 0, 0.5),
		Vector3(9, 0, -9), Vector3(-7, 0, -14), Vector3(11, 0, 1)]
	for i in props.size():
		_put(_mesh(props[i]), spots[i % spots.size()], 0.6 + i * 1.3, false)
	for k in 6:
		_put(_mesh("tree") if k % 2 == 0 else _mesh("tree_round") if _mesh("tree_round") else _mesh("tree"),
			Vector3(-16 + (k % 3) * 2.5, 0, -18 + k * 5.0), k * 0.7, false)
		_put(_mesh("bush"), Vector3(13 + (k % 2) * 1.5, 0, -14 + k * 5.5), k, false)
	for i in units.size():
		var x := (i - (units.size() - 1) * 0.5) * 2.2
		_put(_mesh(units[i]), Vector3(x + 0.5, 0, -4.5 - absf(x) * 0.25), PI, true)
	# Miudezas como no jogo: grama (MultiMesh com vento), pedrinhas na beira da estrada, flores e cogumelos.
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
	for k in 30:
		var z := rng.randf_range(-35, 12)
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		_put(_mesh("road_stone"), Vector3(sin(z * 0.06) * 4.0 + side * rng.randf_range(2.6, 3.4), 0, z), rng.randf() * TAU, false)
	for k in 14:
		var id := "flowers" if k % 2 == 0 else "mushroom"
		_put(_mesh(id), Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-20, 10)) + Vector3(6 if k % 3 == 0 else -6, 0, 0), rng.randf() * TAU, false)
	var hero_mat := Looks.material(5, 0.05)
	var r := HeroRig.make(5, hero_mat)
	if r:
		var h := HeroRig.texture(5)
		if h:
			hero_mat.set_shader_parameter("use_tex", true)
			hero_mat.set_shader_parameter("albedo_tex", h)
		r.scale = Vector3.ONE * 1.3
		r.position = Vector3(0.5, 0, 3.0)
		r.rotation.y = PI
		add_child(r)
		if r.ap:
			r.ap.play("Idle")
	shots = [[1.5, "jogo", 30.0, Vector3(0.5, 0, 0)], [2.5, "perto", 13.0, Vector3(0.5, 0, 0)], [3.5, "detalhe", 6.5, Vector3(0.5, 0, -3.0)]]
	_cam(30.0, Vector3(0.5, 0, 0))


## --layout=locs: um local de cada tipo montado como o WorldView monta (_build_locations, _build_lair) ao lado
## de um trecho de estrada, cada um com a sua foto na câmera do jogo; mais o castelo do covil e a arena.
func _locations() -> void:
	var kinds := ["shop", "tavern", "fountain", "ritual", "shrine", "bridge", "event", "lair", "arena"]
	shots = []
	for i in kinds.size():
		var c := Vector3((i % 3) * 60.0, 0, (i / 3) * 60.0)
		var pts := PackedVector2Array()
		for k in 20:
			pts.append(Vector2(c.x, c.z - 20.0 + k * 2.0))
		if kinds[i] != "arena" and kinds[i] != "lair":
			var road := MeshInstance3D.new()
			road.mesh = GroundLooks.road_mesh(pts, 5.0)
			road.material_override = GroundLooks.road_material()
			add_child(road)
		var off := Vector3(1, 0, 0)
		var fwd := Vector3(0, 0, -1)
		var yaw := 0.0
		match kinds[i]:
			"shop":
				_put(_mesh("house"), c + off * 7.0, yaw + PI * 0.5, false)
				_put(_mesh("fence"), c + off * 4.2 - fwd * 2.5, yaw, false)
				_put(_mesh("coins"), c + off * 4.6 + fwd * 1.2 + Vector3(0, 0.6, 0), 0.0, false)
				_put(_mesh("lantern"), c + off * 4.0 + fwd * 3.5, yaw, false)
			"tavern":
				_put(_mesh("tavern"), c + off * 7.0, yaw + PI * 0.5, false)
				_put(_mesh("fence"), c + off * 4.0 + fwd * 4.0, yaw, false)
			"fountain":
				_put(_mesh("fountain"), c + off * 5.0, 0.0, false)
			"ritual":
				_put(_mesh("ritual"), c, 0.0, false)
				for k in 3:
					_put(_mesh("gravestone"), c + off * (7.0 + k) + fwd * (k * 3.0 - 3.0), yaw + 0.3 * k, false)
			"shrine":
				_put(_mesh("shrine"), c + off * 3.5, 0.0, false)
			"bridge":
				_put(_mesh("water"), c, yaw + PI * 0.5, false)
				_put(_mesh("bridge"), c, yaw, false)
			"event":
				_put(_mesh("fence"), c + off * 3.5, yaw, false)
				_put(_mesh("gravestone"), c + off * 4.5 + fwd * 1.5, yaw + 0.4, false)
				_put(_mesh("lantern"), c + off * 3.0 - fwd * 2.0, yaw, false)
			"lair":
				_put(_mesh("castle"), c + Vector3(0, 0, -8), PI, false)
			"arena":
				var fl := MeshInstance3D.new()
				fl.mesh = _mesh("arena")
				fl.material_override = Looks.material(5)
				fl.scale = Vector3(15, 1, 15)
				fl.position = c
				add_child(fl)
				for k in 10:
					var a := TAU * k / 10.0
					_put(_mesh("pillar" if k % 2 == 0 else "brazier"), c + Vector3(cos(a), 0, sin(a)) * 16.5, 0.0, false)
				for k in 3:
					var a2 := TAU * k / 3.0 + 0.5
					_put(_mesh("altar"), c + Vector3(cos(a2), 0, sin(a2)) * 9.0, 0.0, false)
				var parts := {"core": Vector3(0, 0, 0), "head": Vector3(0, 4.3, 0), "left_arm": Vector3(-1.6, 2.4, 0), "right_arm": Vector3(1.6, 2.4, 0)}
				for id in parts:
					_put(_mesh("boss_" + id), c + Vector3(0, 0, -4) + (parts[id] as Vector3).rotated(Vector3.UP, PI), PI, false)
		var dist := 34.0 if kinds[i] in ["arena", "lair"] else 17.0
		shots.append([1.5 + i * 0.6, "local_" + kinds[i], dist, c + Vector3(4.0 if kinds[i] in ["shop", "tavern", "fountain", "ritual"] else 0.0, 0, 0 if kinds[i] != "lair" else -6.0)])
	_cam(shots[0][2], shots[0][3])


## --layout=anim: cada monstro numa MultiMesh como no jogo, em três instâncias: parado, andando e no meio do
## ataque (INSTANCE_CUSTOM: y = andar, z = fase, w = investida). Duas fotos em tempos diferentes.
const ALL_UNITS := ["rat", "rat_king", "bat", "skeleton", "skeleton_archers", "goblin_dynamiter", "slime", "cultists", "ghost",
	"spectre", "werewolf", "ogre", "scrap_golem", "mimic", "bone_totem", "bat_nest", "gargoyle_tower"]


func _anim_check() -> void:
	for i in ALL_UNITS.size():
		var m := _mesh(ALL_UNITS[i])
		if m == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = m
		mm.instance_count = 3
		var x := (i % 9 - 4) * 4.2
		var z := -5.0 if i < 9 else 4.0
		for k in 3:
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, PI), Vector3(x + (k - 1) * 1.3 * (1.0 + m.get_aabb().size.x * 0.4), 0, z)))
			mm.set_instance_custom_data(k, Color(0, 0.0 if k == 0 else 1.0, i * 0.7, 0.55 if k == 2 else 0.0))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = Looks.material(5, 0.0, true, m)
		add_child(mi)
	shots = [[1.5, "anim_a", 26.0, Vector3(0, 0, 0)], [1.8, "anim_b", 26.0, Vector3(0, 0, 0)]]
	_cam(26.0, Vector3(0, 0, 0))


func _mesh(id: String) -> Mesh:
	var p := "res://assets/models/%s/%s.res" % [dir, id]
	return load(p) if ResourceLoader.exists(p) else null


func _put(m: Mesh, pos: Vector3, yaw: float, unit: bool) -> void:
	if m == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = Looks.material(5, 0.0, false, m)
	mi.position = pos
	mi.rotation.y = yaw
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
