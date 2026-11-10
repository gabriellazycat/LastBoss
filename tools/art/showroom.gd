extends Node3D
## Vitrine das variações: alinha monstros ou o herói de um look e tira fotos.
## godot --path . res://tools/art/showroom.tscn -- --look=1 --what=units --out=C:/pasta/
## --what=units|hero  --view=close|game  (look 0 = arte atual)

const UNITS := ["rat", "rat_king", "bat", "skeleton", "skeleton_archers", "goblin_dynamiter", "slime", "cultists", "ghost",
	"spectre", "werewolf", "ogre", "scrap_golem", "mimic", "bone_totem", "bat_nest", "gargoyle_tower"]
const HERO_PIVOTS := {"leg_l": ["leg", Vector3(-0.16, 0.72, 0)], "leg_r": ["leg", Vector3(0.16, 0.72, 0)], "torso": ["torso", Vector3(0, 0.75, 0)],
	"head": ["head", Vector3(0, 1.4, 0)], "arm_s": ["arm_sword", Vector3(0.48, 1.33, 0)], "arm_h": ["arm_shield", Vector3(-0.48, 1.33, 0)],
	"cape": ["cape", Vector3(0, 1.4, 0.24)]}

var args := {}
var cam: Camera3D
var t := 0.0
var shots: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var look := int(args.get("look", "1"))
	if args.has("norl"):
		RenderingServer.screen_space_roughness_limiter_set_active(false, 0.25, 0.18)
	_env()
	if args.get("what", "units") == "props":
		_props(look)
		return
	_floor()
	if args.has("only"):
		_single(look, str(args["only"]))
	elif args.get("what", "units") == "hero":
		_hero_row(look)
	else:
		_units(look)


## Cenário de um look de chão: as 5 peças sobre o chão do look, com a luz e a névoa dele.
func _props(g: int) -> void:
	Settings.v["look_ground"] = g
	var we: WorldEnvironment = find_children("*", "WorldEnvironment", false, false)[0]
	var sun: DirectionalLight3D = find_children("*", "DirectionalLight3D", false, false)[0]
	if g > 0:
		we.environment.fog_enabled = true
		GroundLooks.apply_env(we.environment, sun)
		var pm := PlaneMesh.new()
		pm.size = Vector2(80, 80)
		pm.subdivide_width = 8
		pm.subdivide_depth = 8
		var gm := MeshInstance3D.new()
		gm.mesh = pm
		gm.material_override = GroundLooks.ground_material()
		add_child(gm)
	else:
		_floor()
	var ids := ["tree", "tree_round", "dead_tree", "bush", "rock", "tree"]
	for i in ids.size():
		var mi := MeshInstance3D.new()
		var lm := GroundLooks.prop_mesh(ids[i])
		mi.mesh = lm if lm else Models.prop(ids[i])
		mi.material_override = GroundLooks.prop_material(false) if lm else Models.material()
		mi.position = Vector3((i - 2.5) * 3.6, 0, -2.0 if i % 2 == 0 else 1.0)
		mi.rotation.y = i * 0.9
		add_child(mi)
	cam.fov = 38
	cam.position = Vector3(0, 9, 17)
	cam.look_at(Vector3(0, 1.6, -0.5), Vector3.UP)
	args["what"] = "props"
	shots = [1.5]


func _mat(look: int, emit := 0.0, src: Mesh = null) -> Material:
	var m: ShaderMaterial = Models.glow_material(emit) if look == 0 else Looks.material(look, emit, false, src)
	return m


func _unit_mesh(look: int, id: String) -> Mesh:
	if look == 0:
		return Models.unit(id)
	var m := Looks.mesh(look, id)
	return m if m else Models.unit(id)


func _units(look: int) -> void:
	# Fileira de trás: os grandes; da frente: os pequenos.
	var rows := [["bat_nest", "gargoyle_tower", "bone_totem", "ogre", "scrap_golem", "werewolf", "mimic", "rat_king"],
		["rat", "bat", "skeleton", "skeleton_archers", "goblin_dynamiter", "slime", "cultists", "ghost", "spectre"]]
	var close: bool = args.get("view", "close") == "close"
	for r in rows.size():
		var ids: Array = rows[r]
		var cell := 3.3 if r == 0 else 2.3
		for i in ids.size():
			var id: String = ids[i]
			var mi := MeshInstance3D.new()
			mi.mesh = _unit_mesh(look, id)
			mi.material_override = _mat(look, 0.3 if id in ["ghost", "spectre"] else 0.0, mi.mesh)
			mi.position = Vector3((i - (ids.size() - 1) * 0.5) * cell, 1.3 if id == "bat" else 0.0, -4.5 if r == 0 else 0.0)
			mi.rotation.y = deg_to_rad(165)
			add_child(mi)
	if close:
		cam.fov = 34
		cam.position = Vector3(0, 10.5, 21.5)
		cam.look_at(Vector3(0, 0.9, -2.3), Vector3.UP)
	else:
		cam.fov = 42
		cam.position = Vector3(0, 26, 15)
		cam.look_at(Vector3(0, 0, -4), Vector3.UP)
	shots = [1.5]


## Um monstro de perto, de frente e de três quartos.
func _single(look: int, id: String) -> void:
	for i in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = _unit_mesh(look, id)
		mi.material_override = _mat(look, 0.0, mi.mesh)
		var s := mi.mesh.get_aabb().size
		mi.position = Vector3((i - 0.5) * maxf(s.x, s.z) * 1.4, 0, 0)
		mi.rotation.y = deg_to_rad(180 if i == 0 else 130)
		add_child(mi)
		cam.fov = 30
		var d := maxf(s.y, maxf(s.x, s.z) * 2.2) * 2.0
		cam.position = Vector3(0, s.y * 0.9 + d * 0.3, d)
		cam.look_at(Vector3(0, s.y * 0.45, 0), Vector3.UP)
	args["what"] = id
	shots = [1.0]


func _hero(look: int, pos: Vector3, yaw: float, pose: float) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	root.scale = Vector3.ONE * 1.3
	add_child(root)
	var mat := _mat(look, 0.05)
	for k in HERO_PIVOTS:
		var piv := Node3D.new()
		piv.position = HERO_PIVOTS[k][1]
		root.add_child(piv)
		var mi := MeshInstance3D.new()
		var part: String = HERO_PIVOTS[k][0]
		mi.mesh = Models.hero_part(part) if look == 0 else (Looks.mesh(look, "hero_" + part) if Looks.mesh(look, "hero_" + part) else Models.hero_part(part))
		mi.material_override = mat
		piv.add_child(mi)
		match k:
			"leg_l": piv.rotation.x = 0.5 * pose
			"leg_r": piv.rotation.x = -0.5 * pose
			"arm_s": piv.rotation.x = 0.3 - 0.4 * pose
			"arm_h": piv.rotation = Vector3(1.2 * pose + 0.2 * (1.0 - pose), 0.35 * pose, 0)
			"cape": piv.rotation.x = 0.15 + 0.4 * pose
	return root


func _hero_row(look: int) -> void:
	_hero(look, Vector3(-3.2, 0, 0), deg_to_rad(-25), 0.0)
	_hero(look, Vector3(0, 0, 0), deg_to_rad(155), 0.0)
	_hero(look, Vector3(3.2, 0, 0), deg_to_rad(-60), 1.0)
	cam.fov = 30
	cam.position = Vector3(0, 5.5, 11)
	cam.look_at(Vector3(0, 1.4, 0), Vector3.UP)
	shots = [1.5]


func _floor() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.26, 0.21)
	m.roughness = 1.0
	mi.material_override = m
	add_child(mi)


func _env() -> void:
	cam = Camera3D.new()
	add_child(cam)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-52, 30, 0)
	moon.light_energy = 1.1
	moon.light_color = Color(0.7, 0.75, 1.0)
	moon.shadow_enabled = true
	add_child(moon)
	var key := OmniLight3D.new()
	key.light_color = Color(1.0, 0.72, 0.42)
	key.light_energy = 1.4
	key.omni_range = 30
	key.position = Vector3(6, 6, 8)
	add_child(key)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.06, 0.04, 0.12)
	sm.sky_horizon_color = Color(0.22, 0.14, 0.3)
	sm.ground_bottom_color = Color(0.03, 0.03, 0.05)
	sm.ground_horizon_color = Color(0.22, 0.14, 0.3)
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.33, 0.55)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = args.get("noglow", "0") == "0"
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = args.get("nossao", "0") == "0"
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.05
	we.environment = env
	add_child(we)
	# --ground=N: luz, céu e névoa de um look de chão (ex.: 10 = direção G) no lugar da noite da vitrine.
	if args.has("ground") and args.get("what", "units") != "props":
		Settings.v["look_ground"] = int(args["ground"])
		env.fog_enabled = true
		GroundLooks.apply_env(env, moon)
		key.visible = false


func _process(delta: float) -> void:
	t += delta
	if shots.size() > 0 and t >= shots[0]:
		shots.pop_front()
		var out := str(args.get("out", "user://"))
		var img := get_viewport().get_texture().get_image()
		img.save_png(out + "%s_look%s.png" % [args.get("what", "units"), args.get("look", "1")])
		if shots.is_empty():
			get_tree().quit()
