extends SceneTree
func _init() -> void:
	var out := ProjectSettings.globalize_path("res://tools/art/out/cmp/")
	DirAccess.make_dir_recursive_absolute(out)
	for id in ["goblin_dynamiter", "slime", "ogre"]:
		var r = load("res://assets/models/cc0/%s.res" % id)
		print(id, " -> ", r)
		var mesh: Mesh = r if r is Mesh else null
		if mesh == null and r is Resource:
			for p in r.get_property_list():
				var v = r.get(p.name)
				if v is Mesh: mesh = v
		if mesh == null: print("no mesh for ", id); continue
		var root := Node3D.new()
		var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.name = id
		if mesh.has_meta("tex"):
			var sm := StandardMaterial3D.new(); sm.albedo_texture = mesh.get_meta("tex"); sm.vertex_color_use_as_albedo = true
			mi.material_override = sm
			print(id, " tex ", mesh.get_meta("tex"))
		root.add_child(mi); mi.owner = root
		_save(root, out + id + ".glb")
	quit()
func _save(n: Node, path: String) -> void:
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	var e := doc.append_from_scene(n, st)
	print(path, " append=", e, " write=", doc.write_to_filesystem(st, path))
