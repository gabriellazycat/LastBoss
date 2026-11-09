extends SceneTree
## Converte tools/art/out/{look,ground}<N>/*.lbm (gerados por build_models.py na Blender) em assets/models/.../*.res.
## godot --headless --path . -s res://tools/art/import_models.gd


func _init() -> void:
	var n := 0
	for dir in ["look1", "look2", "look3", "look4", "ground1", "ground2", "ground3", "ground4"]:
		var src := "res://tools/art/out/%s/" % dir
		var dst := "res://assets/models/%s/" % dir
		var d := DirAccess.open(src)
		if d == null:
			continue
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst))
		for f in d.get_files():
			if not f.ends_with(".lbm"):
				continue
			var m := read_lbm(src + f)
			if m == null:
				push_error("falhou: " + f)
				continue
			ResourceSaver.save(m, dst + f.get_basename() + ".res", ResourceSaver.FLAG_COMPRESS)
			n += 1
	print("importados: ", n)
	quit()


static func read_lbm(path: String) -> ArrayMesh:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_buffer(4).get_string_from_ascii() != "LBM1":
		return null
	var nv := f.get_32()
	var ni := f.get_32()
	var pos := f.get_buffer(nv * 12).to_float32_array()
	var nrm := f.get_buffer(nv * 12).to_float32_array()
	var col := f.get_buffer(nv * 16).to_float32_array()
	var uv2 := f.get_buffer(nv * 8).to_float32_array()
	var idx := f.get_buffer(ni * 4).to_int32_array()
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var C := PackedColorArray()
	var U := PackedVector2Array()
	V.resize(nv)
	N.resize(nv)
	C.resize(nv)
	U.resize(nv)
	for i in nv:
		V[i] = Vector3(pos[i * 3], pos[i * 3 + 1], pos[i * 3 + 2])
		var n := Vector3(nrm[i * 3], nrm[i * 3 + 1], nrm[i * 3 + 2])
		N[i] = n.normalized() if n.length_squared() > 1e-10 and n.is_finite() else Vector3.UP
		C[i] = Color(col[i * 4], col[i * 4 + 1], col[i * 4 + 2], col[i * 4 + 3])
		U[i] = Vector2(uv2[i * 2], uv2[i * 2 + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = V
	arr[Mesh.ARRAY_NORMAL] = N
	arr[Mesh.ARRAY_COLOR] = C
	arr[Mesh.ARRAY_TEX_UV2] = U
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m
