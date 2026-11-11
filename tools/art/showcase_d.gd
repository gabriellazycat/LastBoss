extends SceneTree
## Vitrine da etapa D: as 9 criaturas próprias e as variantes lado a lado (mesmo caminho de carga do jogo).
## godot --path . --script res://tools/art/showcase_d.gd -- --out=docs/visual/d_modelos/vitrine.png


func _initialize() -> void:
	root.size = Vector2i(1360, 760)
	var out := "docs/visual/d_modelos/vitrine.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var ids := ["ogre", "werewolf", "wolf_pack", "war_boar", "alpha_beast", "treasure_guard", "elder_dragon", "cave_troll", "death_knight", "bone_colossus", "ruin_titan",
		"rat", "rat_brute", "bat", "bat_cloud", "fire_imp", "brood_mother", "corrupt_piper", "kobold_scavengers", "raised_servant", "ghoul",
		"trap_chest", "furnace", "rat_trap", "rat_burrow", "sewer_flood", "barricade", "war_banner"]
	var world := Node3D.new()
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	world.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.3, 0.35)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	world.add_child(env)
	var cols := 11
	for i in ids.size():
		var id: String = ids[i]
		var mesh := Looks.unit_mesh(id)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = Looks.unit_material(0.0, false, id)
		var s := Looks.scale_of(id)
		mi.scale = Vector3(s, s, s)
		var r := i / cols
		mi.position = Vector3((i % cols - cols / 2.0) * 3.4, 0.0, r * 6.5)
		if id in ["elder_dragon", "bat", "bat_cloud", "fire_imp"]:
			mi.position.y = 1.0
		world.add_child(mi)
		print("%s tris=%d h=%.2f" % [id, _tris(mesh), mesh.get_aabb().size.y * s])
	var cam := Camera3D.new()
	cam.fov = 40
	world.add_child(cam)
	var cam_pos := Vector3(0, 24, 30)
	cam.look_at_from_position(cam_pos, Vector3(0, 0.5, 6.0))
	for f in 12:
		await process_frame
	root.get_texture().get_image().save_png(out)
	quit()


func _tris(m: Mesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		var a := m.surface_get_arrays(s)
		n += (a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX] != null else a[Mesh.ARRAY_VERTEX].size()) / 3
	return n
