extends SceneTree
## Importador do diorama (26/11/2026, branches diorama-*): o mesmo do tools/art/import_cc0.gd (glTF -> malha com cor
## nos vértices; monstros com a animação gravada em textura, VAT), com a lista e a saída num JSON por versão.
## godot --headless --path . -s res://tools/art/import_dio.gd -- --list=res://tools/art/dio_a.json [--only=id,id]
## JSON: {"src": pasta dos .glb, "out": "res://assets/models/dio/",
##        "units": {id: [arquivo, anim andar, anim ataque, altura (m), [r,g,b]]},
##        "props": {id: [arquivo, altura (m)]}, "heroes": {id: arquivo}}
## Os créditos de cada arquivo ficam em <out>/CREDITOS.md.

const WALK_FRAMES := 12
const ATK_FRAMES := 8

var src := ""
var OUT := ""
var UNITS := {}
var PROPS := {}
var HEROES := {}

func _init() -> void:
	var list := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--list="):
			list = a.trim_prefix("--list=")
	var cfg = JSON.parse_string(FileAccess.get_file_as_string(list)) if list != "" else null
	if not cfg is Dictionary:
		push_error("faltou --list=<json> válido")
		quit(1)
		return
	src = str(cfg["src"])
	OUT = str(cfg["out"])
	UNITS = cfg.get("units", {})
	PROPS = cfg.get("props", {})
	HEROES = cfg.get("heroes", {})
	for id in UNITS:
		var c: Array = UNITS[id]
		c[4] = Color(c[4][0], c[4][1], c[4][2])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_run.call_deferred()


func _run() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	for id in UNITS:
		if only == "" or id in only.split(","):
			await _unit(id)
	for id in PROPS:
		if only == "" or id in only.split(","):
			_prop(id)
	for id in HEROES:
		if only == "" or id in only.split(","):
			_hero(id)
	print("dio: pronto")
	quit()


func _load(rel: String) -> Node3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var path := rel if rel.is_absolute_path() else src + "/" + rel
	if path.begins_with("res://"):
		path = ProjectSettings.globalize_path(path)
	var err := doc.append_from_file(path, st)
	if err != OK:
		push_error("não abriu: " + rel)
		return null
	return doc.generate_scene(st) as Node3D


func _meshes(n: Node) -> Array:
	var out: Array = []
	for c in n.find_children("*", "MeshInstance3D", true, false):
		if (c as MeshInstance3D).visible and (c as MeshInstance3D).mesh:
			out.append(c)
	return out


## Nome exato, ou o que termina em "|<nome>" (a Quaternius prefixa com o nome da armadura).
func _find_anim(ap: AnimationPlayer, a: String) -> String:
	if a == "":
		return ""
	if ap.has_animation(a):
		return a
	for n in ap.get_animation_list():
		if String(n).ends_with("|" + a):
			return n
	return ""


func _anim_player(n: Node) -> AnimationPlayer:
	var a := n.find_children("*", "AnimationPlayer", true, false)
	return a[0] if a.size() > 0 else null


## Junta todas as superfícies (já na pose atual) em listas de vértices no espaço da raiz.
## Retorna {pos, nrm, uv, col, idx} na mesma ordem a cada chamada.
func _gather(root: Node3D, mis: Array, tint: Color) -> Dictionary:
	var P := PackedVector3Array()
	var N := PackedVector3Array()
	var U := PackedVector2Array()
	var C := PackedColorArray()
	var I := PackedInt32Array()
	var tex: Texture2D = null
	for mi: MeshInstance3D in mis:
		var mesh: Mesh = mi.mesh
		var xf := root.global_transform.affine_inverse() * mi.global_transform
		# Pele: a pose é aplicada na CPU (bake_mesh_from_current_skeleton_pose precisa do renderizador).
		var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D if mi.skin else null
		var bind_xf: Array = []
		if skel:
			var sk_xf := root.global_transform.affine_inverse() * skel.global_transform
			for b in mi.skin.get_bind_count():
				var bone := mi.skin.get_bind_bone(b)
				if bone < 0:
					bone = skel.find_bone(mi.skin.get_bind_name(b))
				bind_xf.append(sk_xf * skel.get_bone_global_pose(maxi(bone, 0)) * mi.skin.get_bind_pose(b))
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var mat := mi.get_active_material(s)
			var col := Color.WHITE
			var stex: Texture2D = null
			if mat is BaseMaterial3D:
				col = (mat as BaseMaterial3D).albedo_color
				stex = (mat as BaseMaterial3D).albedo_texture
			if stex and not tex:
				tex = stex
			var base := P.size()
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ns = arr[Mesh.ARRAY_NORMAL]
			var us = arr[Mesh.ARRAY_TEX_UV]
			var cs = arr[Mesh.ARRAY_COLOR]
			var bones = arr[Mesh.ARRAY_BONES] if skel else null
			var wts = arr[Mesh.ARRAY_WEIGHTS] if skel else null
			var per := 0
			if bones:
				per = bones.size() / vs.size()
			for i in vs.size():
				var nn: Vector3 = ns[i] if ns else Vector3.UP
				if per > 0:
					var acc := Vector3.ZERO
					var accn := Vector3.ZERO
					for k in per:
						var w: float = wts[i * per + k]
						if w <= 0.0:
							continue
						var bx: Transform3D = bind_xf[bones[i * per + k]]
						acc += (bx * vs[i]) * w
						accn += (bx.basis * nn) * w
					P.append(acc)
					N.append(accn.normalized())
				else:
					P.append(xf * vs[i])
					N.append((xf.basis * nn).normalized())
				U.append(us[i] if (us and stex) else Vector2(-1, -1))
				var c := col * tint
				var va := 1.0
				if cs:
					# A cor de vértice do glTF vem linear; o look5 espera sRGB (faz pow 2,2).
					c *= (cs[i] as Color).linear_to_srgb()
					va = (cs[i] as Color).a
				c.a = va   # alfa < 1 = brilho no look5 (só as peças com "keep_alpha" ficam com ele)
				C.append(c)
			var ix = arr[Mesh.ARRAY_INDEX]
			if ix:
				for k in ix:
					I.append(base + k)
			else:
				for k in vs.size():
					I.append(base + k)
	return {"pos": P, "nrm": N, "uv": U, "col": C, "idx": I, "tex": tex}


## Escala e gira (frente para -Z, pés em y = 0, centro em x/z = 0) a partir da AABB do primeiro quadro.
func _norm_xf(P: PackedVector3Array, height: float) -> Transform3D:
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for p in P:
		lo = lo.min(p)
		hi = hi.max(p)
	var s := height / maxf(hi.y - lo.y, 0.001)
	var c := (lo + hi) * 0.5
	var xf := Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * s), Vector3.ZERO)
	return xf * Transform3D(Basis.IDENTITY, Vector3(-c.x, -lo.y, -c.z))


func _sample_tex(tex: Texture2D, uv: Vector2, img: Image) -> Color:
	if uv.x < -0.5 or img == null:
		return Color.WHITE
	var x := clampi(int(fposmod(uv.x, 1.0) * img.get_width()), 0, img.get_width() - 1)
	var y := clampi(int(fposmod(uv.y, 1.0) * img.get_height()), 0, img.get_height() - 1)
	return img.get_pixel(x, y)


func _unit(id: String) -> void:
	var cfg: Array = UNITS[id]
	var scene := _load(cfg[0])
	if scene == null:
		return
	root.add_child(scene)
	await process_frame
	await process_frame
	var mis := _meshes(scene)
	var ap := _anim_player(scene)
	var anims: Array = []
	if ap and cfg[1] != "":
		for a in [cfg[1], cfg[2]]:
			anims.append(_find_anim(ap, a))
		if anims[0] == "":
			push_warning("%s: sem animação %s (tem: %s)" % [id, cfg[1], ap.get_animation_list()])
	var frames: Array = []  # cada um: [pos, nrm]
	var first: Dictionary = {}
	var counts := [0, 0]
	for k in 2:
		if anims.size() <= k or anims[k] == "":
			continue
		var anim: Animation = ap.get_animation(anims[k])
		var nf := WALK_FRAMES if k == 0 else ATK_FRAMES
		ap.play(anims[k])
		for f in nf:
			var t := anim.length * f / float(nf if k == 0 else nf - 1)
			ap.seek(minf(t, anim.length - 0.001), true)
			var g := _gather(scene, mis, cfg[4])
			if first.is_empty():
				first = g
			frames.append([g["pos"], g["nrm"]])
		counts[k] = nf
	if first.is_empty():
		first = _gather(scene, mis, cfg[4])
	var opaque: PackedColorArray = first["col"]
	for i in opaque.size():
		var oc := opaque[i]
		oc.a = 1.0
		opaque[i] = oc
	first["col"] = opaque
	var xf := _norm_xf(first["pos"], cfg[3])
	var nv: int = first["pos"].size()
	var P := PackedVector3Array()
	var N := PackedVector3Array()
	var U2 := PackedVector2Array()
	for i in nv:
		P.append(xf * first["pos"][i])
		N.append((xf.basis.orthonormalized() * first["nrm"][i]).normalized())
		U2.append(Vector2(i, 0))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = P
	arr[Mesh.ARRAY_NORMAL] = N
	arr[Mesh.ARRAY_TEX_UV] = first["uv"]
	arr[Mesh.ARRAY_TEX_UV2] = U2
	arr[Mesh.ARRAY_COLOR] = first["col"]
	arr[Mesh.ARRAY_INDEX] = first["idx"]
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	m.set_meta("walk", counts[0])
	m.set_meta("atk", counts[1])
	if first["tex"]:
		var img: Image = (first["tex"] as Texture2D).get_image()
		if img.is_compressed():
			img.decompress()
		m.set_meta("tex", ImageTexture.create_from_image(img))
	if frames.size() > 0:
		if nv > 16384:
			push_error("%s: %d vértices, acima da largura máxima da textura" % [id, nv])
		var img := Image.create_empty(nv, frames.size() * 2, false, Image.FORMAT_RGBAH)
		for f in frames.size():
			var fp: PackedVector3Array = frames[f][0]
			var fn: PackedVector3Array = frames[f][1]
			for i in nv:
				var p: Vector3 = xf * fp[i]
				var n: Vector3 = (xf.basis.orthonormalized() * fn[i]).normalized()
				img.set_pixel(i, f, Color(p.x, p.y, p.z, 1.0))
				img.set_pixel(i, frames.size() + f, Color(n.x, n.y, n.z, 1.0))
		m.set_meta("vat", ImageTexture.create_from_image(img))
	ResourceSaver.save(m, OUT + id + ".res", ResourceSaver.FLAG_COMPRESS)
	print("dio %s: %d vértices, %d tris, quadros %s" % [id, nv, first["idx"].size() / 3, counts])
	scene.queue_free()
	await process_frame


func _prop(id: String) -> void:
	var cfg: Array = PROPS[id]
	var scene := _load(cfg[0])
	if scene == null:
		return
	root.add_child(scene)
	var g := _gather(scene, _meshes(scene), Color.WHITE)
	var img: Image = null
	if g["tex"]:
		img = (g["tex"] as Texture2D).get_image()
		if img.is_compressed():
			img.decompress()
	var xf := _norm_xf(g["pos"], cfg[1])
	var P := PackedVector3Array()
	var N := PackedVector3Array()
	var C := PackedColorArray()
	for i in g["pos"].size():
		P.append(xf * g["pos"][i])
		N.append((xf.basis.orthonormalized() * g["nrm"][i]).normalized())
		var c: Color = g["col"][i] * _sample_tex(g["tex"], g["uv"][i], img)
		c.a = g["col"][i].a if cfg.size() > 2 and cfg[2] else 1.0
		C.append(c)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = P
	arr[Mesh.ARRAY_NORMAL] = N
	arr[Mesh.ARRAY_COLOR] = C
	arr[Mesh.ARRAY_INDEX] = g["idx"]
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	ResourceSaver.save(m, OUT + id + ".res", ResourceSaver.FLAG_COMPRESS)
	print("dio prop %s: %d tris" % [id, g["idx"].size() / 3])
	scene.queue_free()


func _hero(id: String) -> void:
	var scene := _load(HEROES[id])
	if scene == null:
		return
	for c in scene.find_children("*", "", true, false):
		c.owner = scene
	var ps := PackedScene.new()
	ps.pack(scene)
	ResourceSaver.save(ps, OUT + id + ".scn", ResourceSaver.FLAG_COMPRESS)
	var names: Array = []
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		names.append("%s%s" % [mi.name, "" if mi.visible else "(oculto)"])
	print("dio herói %s: malhas %s" % [id, names])
	scene.free()
