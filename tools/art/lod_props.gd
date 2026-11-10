extends SceneTree
## Copia o cenário de um look de chão gerando níveis de detalhe (LOD) automáticos da Godot.
## godot --headless --path . -s res://tools/art/lod_props.gd -- --from=ground1 --to=ground9
## As árvores próprias têm até 2,6 mil triângulos e aparecem às centenas: de longe, o LOD corta a maior parte.
## --only=tree,bush,... só esses ids; --keep=0.45 fração de triângulos que fica (padrão 0,2).
## Blender v2: rodar UMA vez depois do import_v2.gd, no lugar: --from=v2 --to=v2 --only=<peças espalhadas> --keep=0.45

var KEEP := 0.2


func _init() -> void:
	var from := "ground1"
	var to := "ground9"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="):
			from = a.trim_prefix("--from=")
		elif a.begins_with("--to="):
			to = a.trim_prefix("--to=")
		elif a.begins_with("--keep="):
			KEEP = float(a.trim_prefix("--keep="))
	var src := "res://assets/models/%s/" % from
	var dst := "res://assets/models/%s/" % to
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst))
	var only: PackedStringArray = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	for f in DirAccess.get_files_at(src):
		if not f.ends_with(".res") or (only.size() > 0 and not f.get_basename() in only):
			continue
		var m: ArrayMesh = load(src + f)
		var im := ImporterMesh.new()
		for s in m.get_surface_count():
			im.add_surface(m.surface_get_primitive_type(s), m.surface_get_arrays(s), [], {}, m.surface_get_material(s))
		im.generate_lods(25.0, 60.0, [])
		# O cenário é desenhado numa MultiMesh do mapa inteiro, que não escolhe LOD por árvore: grava direto o
		# nível que fica perto de KEEP do original (a câmera do jogo fica a ~30 m).
		var out := ArrayMesh.new()
		var report := []
		for s in im.get_surface_count():
			var arr := im.get_surface_arrays(s)
			var n0: int = (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size()
			var best: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for l in im.get_surface_lod_count(s):
				var ix := im.get_surface_lod_indices(s, l)
				if ix.size() >= n0 * KEEP:
					best = ix
			arr[Mesh.ARRAY_INDEX] = best
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			report.append("%d -> %d tris" % [n0 / 3, best.size() / 3])
		ResourceSaver.save(out, dst + f, ResourceSaver.FLAG_COMPRESS)
		print("%s: %s" % [f, report])
	quit()
