extends SceneTree
## Converte os modelos CC0 baixados por tools/art/fetch_cc0.py em recursos do jogo (assets/models/cc0/).
## godot --headless --path . -s res://tools/art/import_cc0.gd -- --src=<pasta do fetch_cc0>
##
## Monstros: uma malha só por tipo (para a MultiMesh), com a cor dos materiais nos vértices, o índice do vértice
## em UV2.x e a animação de andar + ataque gravada numa textura (VAT: posição e normal por vértice e quadro).
## O shader cc0_unit.gdshader toca a animação por instância. Cenário: malha estática com a textura amostrada
## nos vértices (os atlas da KayKit são faixas de cor). Herói: cena com esqueleto e animações (PackedScene).

const OUT := "res://assets/models/cc0/"
const WALK_FRAMES := 12
const ATK_FRAMES := 8

var src := ""

# id -> [arquivo relativo a --src, animação de andar, animação de ataque, altura alvo (m), cor multiplicada]
var UNITS := {
	"skeleton": ["kk-Character-Pack-Skeletons-1.0/addons/kaykit_character_pack_skeletons/characters/gltf/Skeleton_Minion.glb", "Walking_A", "1H_Melee_Attack_Chop", 1.25, Color(1, 1, 1)],
	"skeleton_archers": ["kk-Character-Pack-Skeletons-1.0/addons/kaykit_character_pack_skeletons/characters/gltf/Skeleton_Rogue.glb", "Walking_A", "1H_Ranged_Shoot", 1.3, Color(1, 1, 1)],
	"cultists": ["kk-Character-Pack-Adventures-1.0/addons/kaykit_character_pack_adventures/Characters/gltf/Rogue_Hooded.glb", "Walking_B", "Spellcast_Shoot", 1.45, Color(0.78, 0.62, 1.0)],
	"bat": ["quaternius/bat.glb", "Bat_Flying", "Bat_Attack", 0.75, Color(1, 1, 1)],
	"rat": ["quaternius/rat.glb", "Rat_Walk", "Rat_Attack", 0.5, Color(1, 1, 1)],
	"rat_king": ["quaternius/rat.glb", "Rat_Walk", "Rat_Attack", 0.95, Color(1.15, 0.95, 0.6)],
	"slime": ["quaternius/slime.glb", "Slime_Walk", "Slime_Attack", 0.8, Color(1, 1, 1)],
	"ghost": ["quaternius/ghost.glb", "Flying_Idle", "Punch", 1.3, Color(1, 1, 1)],
	"spectre": ["quaternius/ghost_skull.glb", "Flying_Idle", "Headbutt", 1.1, Color(1, 1, 1)],
	"goblin_dynamiter": ["quaternius/goblin.glb", "Walk", "Attack", 1.0, Color(1, 1, 1)],
	"ogre": ["quaternius/orc.glb", "Walk", "Bite_Front", 2.3, Color(1, 1, 1)],
	"werewolf": ["quaternius/wolf.glb", "AnimalArmature|Gallop", "AnimalArmature|Attack", 1.8, Color(0.62, 0.55, 0.6)],
	"scrap_golem": ["quaternius/giant.glb", "Walk", "Attack", 2.3, Color(0.78, 0.82, 0.92)],
	"mimic": ["quaternius/mimic.glb", "", "", 1.0, Color(1, 1, 1)],
	"bone_totem": ["kk-Halloween-Bits-1.0/addons/kaykit_halloween_bits/Assets/gltf/post_skull.gltf", "", "", 1.9, Color(1, 1, 1)],
	"bat_nest": ["kk-Halloween-Bits-1.0/addons/kaykit_halloween_bits/Assets/gltf/tree_dead_large_decorated.gltf", "", "", 3.0, Color(1, 1, 1)],
	"gargoyle_tower": ["kk-Halloween-Bits-1.0/addons/kaykit_halloween_bits/Assets/gltf/shrine_candles.gltf", "", "", 2.6, Color(1, 1, 1)],
}

const HEX := "kk-Medieval-Hexagon-Pack-1.0/addons/kaykit_medieval_hexagon_pack/Assets/gltf/decoration/nature/"
const HAL := "kk-Halloween-Bits-1.0/addons/kaykit_halloween_bits/Assets/gltf/"
# id -> [arquivo, altura alvo]. "<id>_n" = variante noturna (Halloween).
var PROPS := {
	"tree": [HEX + "tree_single_A.gltf", 5.5], "tree_round": [HEX + "tree_single_B.gltf", 4.6],
	"dead_tree": [HAL + "tree_dead_medium.gltf", 4.0], "bush": [HEX + "trees_A_small.gltf", 1.6],
	"rock": [HEX + "rock_single_C.gltf", 1.1],
	"tree_n": [HAL + "tree_pine_yellow_large.gltf", 5.5], "tree_round_n": [HAL + "tree_pine_orange_medium.gltf", 4.4],
	"dead_tree_n": [HAL + "tree_dead_large.gltf", 4.6], "bush_n": [HAL + "pumpkin_orange_jackolantern.gltf", 0.8],
	"rock_n": [HAL + "grave_A.gltf", 1.2],
}

var HEROES := {
	"hero_knight": "kk-Character-Pack-Adventures-1.0/addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb",
	# Classes da campanha (rodada autônoma de 09/11/2026): Arqueira e Mago/Clériga.
	"hero_rogue_hooded": "kk-Character-Pack-Adventures-1.0/addons/kaykit_character_pack_adventures/Characters/gltf/Rogue_Hooded.glb",
	"hero_mage": "kk-Character-Pack-Adventures-1.0/addons/kaykit_character_pack_adventures/Characters/gltf/Mage.glb",
}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--src="):
			src = a.trim_prefix("--src=").replace("\\", "/")
	if src == "":
		push_error("faltou --src=<pasta>")
		quit(1)
		return
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
	print("cc0: pronto")
	quit()


func _load(rel: String) -> Node3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var err := doc.append_from_file(src + "/" + rel, st)
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
				if cs:
					c *= cs[i]
				c.a = 1.0
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
	print("cc0 %s: %d vértices, %d tris, quadros %s" % [id, nv, first["idx"].size() / 3, counts])
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
		c.a = 1.0
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
	print("cc0 prop %s: %d tris" % [id, g["idx"].size() / 3])
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
	print("cc0 herói %s: malhas %s" % [id, names])
	scene.free()
