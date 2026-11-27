extends Node3D
## Vitrine dos modelos 3D: cada unidade (monstros, enxames, estruturas), herói, chefe e peça de cenário,
## com a luz do ato 1 (Diorama) e o shader do jogo, um PNG por modelo e um manifest.json.
## godot --position -6000,0 --path . -s res://tools/art/capture_big.gd -- --scene=res://tools/gallery/models_gallery.tscn --size=560x560 --out=<pasta>/
## --only=id1,id2 renderiza só esses ids (o manifest guarda só eles). --act=N: luz do ato N (0 a 2).

const CARD_FILES := ["res://data/cards.json", "res://data/cards_common.json", "res://data/cards_plague.json",
	"res://data/cards_dragon.json", "res://data/cards_lich.json"]
const UNIT_TYPES := ["monster", "swarm", "structure"]
const HERO_CLASSES := ["escudeiro", "arqueira", "cleriga", "mago", "assassino", "barbaro", "besteiro", "guardiao"]
const BOSSES := ["plague", "dragon", "lich"]
## Peças de Models.prop(...) usadas pelo WorldView (grep das chamadas) e a arena.
const PROPS := ["tavern", "house", "house_b", "fence", "lantern", "coins", "fountain", "ritual", "gravestone", "shrine",
	"brazier", "rock", "dead_tree", "bridge", "castle", "gate", "pillar", "altar", "arena"]
## Cenário espalhado pelo mundo (MundoVivo/Cenario: malha e material do GroundLooks, árvores arv5/arv6).
const SCENERY := ["tree", "tree_round", "bush", "rock", "flowers", "grass"]

var cam: Camera3D
var holder: Node3D
var out := "user://models_gallery/"
var only: PackedStringArray = []
var act := 0
var lod := -1.0          # --atlaslod=N: testa outro mipmap do atlas (sem mexer no jogo)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",", false)
		if a.begins_with("--gdir="):
			_override_g(a.trim_prefix("--gdir="))
		if a.begins_with("--act="):
			act = int(a.trim_prefix("--act="))
		if a.begins_with("--atlaslod="):
			lod = float(a.trim_prefix("--atlaslod="))
	DirAccess.make_dir_recursive_absolute(out)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.sky = Sky.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	add_child(sun)
	var rim := DirectionalLight3D.new()
	add_child(rim)
	# A mesma sequência do main.gd (_build_env): pintura global, chão, luz, qualidade e o diorama do ato 1.
	PaintLook.apply()
	GroundLooks.apply_env(env, sun, rim)
	LuzLook.apply(env, sun, rim)
	Settings.apply_quality(env, sun, get_viewport())
	Diorama.apply_env(env, sun, rim, act)
	# Luz quente de lanterna, como as do mundo, para ver o modelo como ele aparece perto do herói.
	var warm := OmniLight3D.new()
	warm.light_color = Color(1.0, 0.72, 0.42)
	warm.light_energy = 1.1 * Diorama.LIGHT_K
	warm.omni_range = 11.0 * Diorama.LIGHT_R
	warm.position = Vector3(3.0, 3.0, -2.5)
	add_child(warm)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	ground.mesh = pm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.43, 0.5, 0.36)
	gmat.roughness = 1.0
	ground.material_override = gmat
	add_child(ground)
	cam = Camera3D.new()
	cam.fov = 30.0
	add_child(cam)
	cam.current = true
	holder = Node3D.new()
	add_child(holder)
	_run.call_deferred()


func _run() -> void:
	var manifest := {"units": [], "heroes": [], "bosses": [], "props": []}
	# Unidades: uma imagem por malha; as cartas que dividem a mesma malha vão juntas.
	var by_mesh := {}
	var order: Array = []
	for path in CARD_FILES:
		var j = JSON.parse_string(FileAccess.get_file_as_string(path))
		for c in j.get("cards", []):
			if str(c.get("type", "")) not in UNIT_TYPES:
				continue
			var id := str(c["id"])
			var m: Mesh = Looks.unit_mesh(id)
			var key := _mesh_key(m) + "|" + str(Looks.scale_of(id))
			if not by_mesh.has(key):
				by_mesh[key] = {"id": id, "cards": [], "src": _src_of(id, m), "mesh": key.split("|")[0]}
				order.append(key)
			by_mesh[key]["cards"].append(id)
	for key in order:
		var e: Dictionary = by_mesh[key]
		if not _want(e["id"]):
			continue
		var n := Node3D.new()
		var mi := MeshInstance3D.new()
		mi.mesh = Looks.unit_mesh(e["id"])
		mi.material_override = Looks.unit_material(0.3 if e["id"] in ["ghost", "spectre"] else 0.0, false, e["id"])
		mi.scale = Vector3.ONE * Looks.scale_of(e["id"])
		n.add_child(mi)
		e["file"] = "unit_%s.png" % e["id"]
		await _shot(n, e["file"])
		manifest["units"].append(e)
	for cls in HERO_CLASSES:
		if not _want("hero_" + cls):
			continue
		var rig := Looks.hero_rig(Looks.hero_material(0.0), cls)
		var n := Node3D.new()
		n.add_child(rig)
		var src := HeroRig.scene_path(Looks.hero(), cls)
		var e := {"id": "hero_" + cls, "cards": [cls], "src": src.get_file(), "file": "hero_%s.png" % cls}
		await _shot(n, e["file"], true)
		manifest["heroes"].append(e)
	for v in BOSSES:
		if not _want("boss_" + v):
			continue
		var n := Node3D.new()
		var offs := BossModels.part_offsets(v)
		for id in BossModels.PARTS:
			var mi := MeshInstance3D.new()
			mi.mesh = BossModels.part(v, id)
			mi.material_override = Looks.g_material(mi.mesh, Models.glow_material(0.15))
			mi.position = offs[id]
			n.add_child(mi)
		for ex in BossModels.EXTRAS.get(v, []):
			var mi := MeshInstance3D.new()
			mi.mesh = BossModels.part(v, ex)
			mi.material_override = Looks.g_material(mi.mesh, Models.glow_material(0.15))
			n.add_child(mi)
		var e := {"id": "boss_" + v, "cards": [v], "src": "v2/g_n_a", "file": "boss_%s.png" % v}
		await _shot(n, e["file"])
		manifest["bosses"].append(e)
	for id in PROPS:
		if not _want("prop_" + id):
			continue
		var m: Mesh = Models.prop(id)
		var n := Node3D.new()
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = Looks.g_material(m, Models.material())
		n.add_child(mi)
		var e := {"id": "prop_" + id, "cards": [id], "src": _prop_src(id, m), "file": "prop_%s.png" % id}
		await _shot(n, e["file"])
		manifest["props"].append(e)
	manifest["scenery"] = []
	for id in SCENERY:
		if not _want("scen_" + id):
			continue
		var pair: Array = MundoVivo._atlas_pair(id)
		var n := Node3D.new()
		var mi := MeshInstance3D.new()
		mi.mesh = pair[0]
		mi.material_override = pair[1]
		n.add_child(mi)
		var e := {"id": "scen_" + id, "cards": [id], "src": _prop_src(id, pair[0]), "file": "scen_%s.png" % id}
		await _shot(n, e["file"])
		manifest["scenery"].append(e)
	var f := FileAccess.open(out.path_join("manifest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, " "))
	f.close()
	print("vitrine: ", out)
	get_tree().quit()


## --gdir=res://<pasta do import_g>/: usa as malhas e atlas de lá no lugar dos de assets (prova de um lote novo
## sem mexer em assets/models). Preenche o cache do Looks antes de qualquer pedido.
func _override_g(dir: String) -> void:
	# g_n_a (miniaturas e chefes) e m2_a (feitos à mão), cada um com a pasta de atlas dele.
	for pair in [["g_n_a", "g_tex/dry_n", "g/"], ["m2_a", "g_tex/m2", "m2/"]]:
		var md := dir.path_join(pair[0])
		if not DirAccess.dir_exists_absolute(md):
			continue
		for f in DirAccess.get_files_at(md):
			if not f.ends_with(".res"):
				continue
			var id := f.get_basename()
			var m: Mesh = load(md.path_join(f))
			var tp := dir.path_join("%s/%s.png" % [pair[1], id])
			if FileAccess.file_exists(tp):
				var img := Image.load_from_file(ProjectSettings.globalize_path(tp))
				img.generate_mipmaps()
				m.set_meta("gtex", ImageTexture.create_from_image(img))
			m.set_meta("gink", 0.0)
			Looks._mesh[pair[2] + id] = m


func _want(id: String) -> bool:
	return only.is_empty() or id in only or id.trim_prefix("hero_").trim_prefix("boss_").trim_prefix("prop_").trim_prefix("scen_") in only


func _mesh_key(m: Mesh) -> String:
	if m == null:
		return "null"
	return m.resource_path if m.resource_path != "" else "proc:%d" % m.get_instance_id()


func _src_of(id: String, m: Mesh) -> String:
	if Diorama.unit_id(id) != "":
		return "dio"
	if Looks.m2_unit_id(id) != "":
		return "m2_a"
	var p := m.resource_path if m else ""
	if p.contains("/g_n_a/"):
		return "g_n_a"
	if p.contains("/v2/"):
		return "v2"
	return "procedural"


func _prop_src(id: String, m: Mesh) -> String:
	var p := m.resource_path if m else ""
	for d in ["dio", "m2_a", "g_n_a", "v2", "arv5", "arv6"]:
		if p.contains("/%s/" % d):
			return d
	return "procedural"


## Enquadra o nó em 3/4 de frente (a frente dos modelos é -Z), espera a luz assentar e grava o PNG.
func _shot(n: Node3D, file: String, rig := false) -> void:
	for c in holder.get_children():
		c.queue_free()
	holder.add_child(n)
	if lod >= 0.0:
		for g in n.find_children("*", "GeometryInstance3D", true, false):
			var sm := (g as GeometryInstance3D).material_override as ShaderMaterial
			if sm:
				sm.set_shader_parameter("atlas_lod", lod)
	await get_tree().process_frame
	var aabb := _aabb(n)
	var center := aabb.get_center()
	var radius := maxf(aabb.size.length() * 0.5, 0.3)
	var dist := radius / sin(deg_to_rad(cam.fov * 0.5)) * 1.05
	var yaw := deg_to_rad(-32.0)
	var pitch := deg_to_rad(24.0)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	cam.position = center + dir * dist
	cam.look_at(center, Vector3.UP)
	cam.near = maxf(dist * 0.02, 0.02)
	for i in 8:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(file))


func _aabb(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var g := mi as MeshInstance3D
		if not g.is_visible_in_tree() or g.mesh == null:
			continue
		var b: AABB = g.global_transform * g.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
