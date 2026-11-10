extends SceneTree
## Converte os .lbm gravados pelo Blender (tools/art/blender_v2/build.py) em recursos do jogo.
## godot --headless --path . -s res://tools/art/import_v2.gd -- --src=<pasta dos .lbm> [--out=res://assets/models/v2/]
##
## Mesmo formato dos CC0 (tools/art/import_cc0.gd): uma malha por id, cor nos vértices (alfa < 1 = brilho),
## índice do vértice em UV2.x e, se animada, a textura de animação (VAT, posição + normal por quadro) em meta.

var src := ""
var out := "res://assets/models/v2/"


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--src="):
			src = a.trim_prefix("--src=").replace("\\", "/")
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	if src == "":
		push_error("faltou --src=<pasta>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var n := 0
	for f in DirAccess.get_files_at(src):
		if f.ends_with(".lbm"):
			_convert(src + "/" + f, out + f.get_basename() + ".res")
			n += 1
	print("v2: %d modelos" % n)
	quit()


func _vec3s(fa: FileAccess, n: int) -> PackedVector3Array:
	var b := fa.get_buffer(n * 12).to_float32_array()
	var out_ := PackedVector3Array()
	out_.resize(n)
	for i in n:
		out_[i] = Vector3(b[i * 3], b[i * 3 + 1], b[i * 3 + 2])
	return out_


func _convert(path: String, dst: String) -> void:
	var fa := FileAccess.open(path, FileAccess.READ)
	var hdr: Dictionary = JSON.parse_string(fa.get_line())
	var nv := int(hdr["nv"])
	var ni := int(hdr["ni"])
	var P := _vec3s(fa, nv)
	var N := _vec3s(fa, nv)
	var cb := fa.get_buffer(nv * 16).to_float32_array()
	var C := PackedColorArray()
	C.resize(nv)
	for i in nv:
		C[i] = Color(cb[i * 4], cb[i * 4 + 1], cb[i * 4 + 2], cb[i * 4 + 3])
	var I := fa.get_buffer(ni * 4).to_int32_array()
	# O Blender grava a frente no sentido anti-horário; a Godot considera frente o horário.
	for k in range(0, ni, 3):
		var tmp := I[k + 1]
		I[k + 1] = I[k + 2]
		I[k + 2] = tmp
	var U2 := PackedVector2Array()
	var U := PackedVector2Array()
	U2.resize(nv)
	U.resize(nv)
	for i in nv:
		U2[i] = Vector2(i, 0)
		U[i] = Vector2(-1, -1)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = P
	arr[Mesh.ARRAY_NORMAL] = N
	arr[Mesh.ARRAY_TEX_UV] = U
	arr[Mesh.ARRAY_TEX_UV2] = U2
	arr[Mesh.ARRAY_COLOR] = C
	arr[Mesh.ARRAY_INDEX] = I
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var nf := int(hdr["frames"])
	m.set_meta("walk", int(hdr["walk"]))
	m.set_meta("atk", int(hdr["atk"]))
	if nf > 0:
		if nv > 16384:
			push_error("%s: %d vértices, acima da largura máxima da textura" % [path, nv])
		var img := Image.create_empty(nv, nf * 2, false, Image.FORMAT_RGBAH)
		for f in nf:
			var fp := _vec3s(fa, nv)
			var fn := _vec3s(fa, nv)
			for i in nv:
				img.set_pixel(i, f, Color(fp[i].x, fp[i].y, fp[i].z, 1.0))
				img.set_pixel(i, nf + f, Color(fn[i].x, fn[i].y, fn[i].z, 1.0))
		m.set_meta("vat", ImageTexture.create_from_image(img))
	ResourceSaver.save(m, dst, ResourceSaver.FLAG_COMPRESS)
	print("v2 %s: %d vértices, %d tris, %d quadros" % [dst.get_file(), nv, ni / 3, nf])
