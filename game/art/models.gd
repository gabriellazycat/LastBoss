class_name Models
extends RefCounted
## Modelos low-poly montados por código a partir de primitivas, com cor por vértice (paleta única).
## Frente = -Z, chão em y = 0. Tudo usa o mesmo material (toon.gdshader).

const C_BONE := Color(0.88, 0.85, 0.74)
const C_RAT := Color(0.47, 0.4, 0.36)
const C_PINK := Color(0.9, 0.55, 0.6)
const C_RED_EYE := Color(1.0, 0.15, 0.1)
const C_GOB := Color(0.42, 0.7, 0.25)
const C_SLIME := Color(0.3, 0.92, 0.5)
const C_PURPLE := Color(0.45, 0.22, 0.6)
const C_DARK := Color(0.12, 0.1, 0.14)
const C_GOLD := Color(1.0, 0.78, 0.25)
const C_WOOD := Color(0.42, 0.27, 0.16)
const C_STONE := Color(0.46, 0.46, 0.52)
const C_STEEL := Color(0.72, 0.75, 0.82)
const C_CLOTH_RED := Color(0.6, 0.12, 0.2)
const C_LEAF := Color(0.16, 0.36, 0.3)
const C_LEAF2 := Color(0.2, 0.42, 0.34)
const C_GHOST := Color(0.65, 0.85, 1.0)
const C_RUST := Color(0.6, 0.38, 0.22)
const C_OGRE := Color(0.52, 0.58, 0.32)
const C_FUR := Color(0.36, 0.28, 0.24)

static var _cache: Dictionary = {}
static var _mat: ShaderMaterial


static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://game/art/toon.gdshader")
	return _mat


static func glow_material(emit: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/toon.gdshader")
	m.set_shader_parameter("emission_boost", emit)
	return m


# ---------------------------------------------------------------- construtor

class Kit:
	var st := SurfaceTool.new()

	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_smooth_group(-1)

	func add(prim: PrimitiveMesh, pos: Vector3, col: Color, rot := Vector3.ZERO, scl := Vector3.ONE) -> Kit:
		var b := Basis.from_euler(rot * (PI / 180.0)) * Basis.from_scale(scl)
		var xf := Transform3D(b, pos)
		var arr := prim.get_mesh_arrays()
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx = arr[Mesh.ARRAY_INDEX]
		st.set_color(col)
		if idx != null and idx.size() > 0:
			for i in idx:
				st.add_vertex(xf * v[i])
		else:
			for p in v:
				st.add_vertex(xf * p)
		return self

	func done() -> ArrayMesh:
		st.generate_normals()
		return st.commit()


static func box(x: float, y: float, z: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m


static func sph(r: float, seg := 7, rings := 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = rings
	return m


static func cyl(top: float, bottom: float, h: float, seg := 7) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


static func cone(r: float, h: float, seg := 6) -> CylinderMesh:
	return cyl(0.0, r, h, seg)


static func eyes(k: Kit, y: float, z: float, dx: float, r: float, col := C_RED_EYE) -> void:
	k.add(sph(r, 5, 3), Vector3(-dx, y, z), col)
	k.add(sph(r, 5, 3), Vector3(dx, y, z), col)


# ---------------------------------------------------------------- unidades

static func unit(id: String) -> ArrayMesh:
	if _cache.has(id):
		return _cache[id]
	var m: ArrayMesh
	match id:
		"rat", "rat_horde":
			m = _rat(1.0, false)
		"rat_king":
			m = _rat(2.0, true)
		"bat":
			m = _bat()
		"skeleton_archers":
			m = _skeleton(true)
		"skeleton":
			m = _skeleton(false)
		"goblin_dynamiter":
			m = _goblin()
		"slime":
			m = _slime()
		"bat_nest":
			m = _nest()
		"bone_totem":
			m = _totem()
		"cultists":
			m = _cultist()
		"ogre":
			m = _ogre()
		"mimic":
			m = _mimic()
		"ghost":
			m = _ghost(C_GHOST)
		"spectre":
			m = _ghost(Color(0.35, 1.0, 0.85))
		"gargoyle_tower":
			m = _tower()
		"werewolf":
			m = _werewolf()
		"scrap_golem":
			m = _golem()
		_:
			m = Kit.new().add(cyl(0.35, 0.35, 1.2), Vector3(0, 0.6, 0), C_STONE).done()
	_cache[id] = m
	return m


static func _rat(s: float, crown: bool) -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(0.28 * s), Vector3(0, 0.26 * s, 0.05 * s), C_RAT, Vector3.ZERO, Vector3(1.0, 0.85, 1.35))
	k.add(sph(0.18 * s), Vector3(0, 0.33 * s, -0.33 * s), C_RAT.lightened(0.08))
	k.add(cone(0.08 * s, 0.18 * s, 5), Vector3(0, 0.3 * s, -0.53 * s), C_PINK, Vector3(-90, 0, 0))
	k.add(sph(0.09 * s, 5, 3), Vector3(-0.12 * s, 0.5 * s, -0.3 * s), C_PINK, Vector3.ZERO, Vector3(1, 1, 0.4))
	k.add(sph(0.09 * s, 5, 3), Vector3(0.12 * s, 0.5 * s, -0.3 * s), C_PINK, Vector3.ZERO, Vector3(1, 1, 0.4))
	eyes(k, 0.38 * s, -0.45 * s, 0.07 * s, 0.035 * s)
	k.add(cyl(0.02 * s, 0.04 * s, 0.55 * s, 4), Vector3(0, 0.18 * s, 0.55 * s), C_PINK, Vector3(70, 0, 0))
	if crown:
		k.add(cyl(0.16, 0.14, 0.14, 6), Vector3(0, 0.95, -0.62), C_GOLD)
		for i in 5:
			var a := TAU * i / 5.0
			k.add(cone(0.05, 0.14, 4), Vector3(cos(a) * 0.14, 1.08, -0.62 + sin(a) * 0.14), C_GOLD)
		k.add(box(0.5, 0.06, 0.4), Vector3(0, 0.62, 0.3), Color(0.5, 0.1, 0.2), Vector3(-10, 0, 0))
	return k.done()


static func _bat() -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(0.2), Vector3(0, 0, 0), C_PURPLE)
	k.add(box(0.55, 0.04, 0.3), Vector3(-0.32, 0.05, 0.02), C_PURPLE.darkened(0.3), Vector3(0, 0, 20))
	k.add(box(0.55, 0.04, 0.3), Vector3(0.32, 0.05, 0.02), C_PURPLE.darkened(0.3), Vector3(0, 0, -20))
	k.add(cone(0.06, 0.16, 4), Vector3(-0.09, 0.22, -0.02), C_PURPLE)
	k.add(cone(0.06, 0.16, 4), Vector3(0.09, 0.22, -0.02), C_PURPLE)
	eyes(k, 0.05, -0.17, 0.07, 0.035, Color(1, 0.9, 0.2))
	return k.done()


static func _skeleton(bow: bool) -> ArrayMesh:
	var k := Kit.new()
	k.add(box(0.1, 0.55, 0.1), Vector3(-0.13, 0.28, 0), C_BONE)
	k.add(box(0.1, 0.55, 0.1), Vector3(0.13, 0.28, 0), C_BONE)
	k.add(box(0.38, 0.12, 0.2), Vector3(0, 0.6, 0), C_BONE)
	k.add(box(0.08, 0.45, 0.08), Vector3(0, 0.85, 0), C_BONE)
	for i in 3:
		k.add(box(0.42 - i * 0.06, 0.06, 0.24), Vector3(0, 0.8 + i * 0.13, 0), C_BONE)
	k.add(sph(0.2), Vector3(0, 1.32, 0), C_BONE)
	eyes(k, 1.34, -0.16, 0.08, 0.05, Color(0.2, 1.0, 0.6))
	k.add(box(0.08, 0.45, 0.08), Vector3(-0.3, 0.95, -0.1), C_BONE, Vector3(-30, 0, 15))
	k.add(box(0.08, 0.45, 0.08), Vector3(0.3, 0.95, -0.1), C_BONE, Vector3(-30, 0, -15))
	if bow:
		k.add(box(0.05, 0.9, 0.05), Vector3(0.0, 1.0, -0.45), C_WOOD, Vector3(0, 0, 0))
		k.add(box(0.04, 0.35, 0.04), Vector3(0.0, 1.5, -0.38), C_WOOD, Vector3(-25, 0, 0))
		k.add(box(0.04, 0.35, 0.04), Vector3(0.0, 0.5, -0.38), C_WOOD, Vector3(25, 0, 0))
	else:
		k.add(box(0.06, 0.6, 0.06), Vector3(0.32, 1.0, -0.35), C_STEEL.darkened(0.4), Vector3(-60, 0, 0))
	return k.done()


static func _goblin() -> ArrayMesh:
	var k := Kit.new()
	k.add(cyl(0.18, 0.26, 0.55), Vector3(0, 0.45, 0), Color(0.45, 0.32, 0.2))
	k.add(box(0.1, 0.3, 0.1), Vector3(-0.1, 0.12, 0), C_GOB)
	k.add(box(0.1, 0.3, 0.1), Vector3(0.1, 0.12, 0), C_GOB)
	k.add(sph(0.3), Vector3(0, 0.95, -0.05), C_GOB)
	k.add(cone(0.1, 0.45, 4), Vector3(-0.38, 1.0, 0), C_GOB, Vector3(0, 0, 70))
	k.add(cone(0.1, 0.45, 4), Vector3(0.38, 1.0, 0), C_GOB, Vector3(0, 0, -70))
	k.add(cone(0.06, 0.2, 4), Vector3(0, 0.92, -0.38), C_GOB.darkened(0.15), Vector3(-90, 0, 0))
	eyes(k, 1.02, -0.26, 0.11, 0.06, Color(1, 0.9, 0.1))
	k.add(cyl(0.08, 0.08, 0.5, 6), Vector3(0.0, 1.45, -0.05), Color(0.85, 0.15, 0.1), Vector3(0, 0, 25))
	k.add(cyl(0.015, 0.015, 0.2, 4), Vector3(-0.12, 1.75, -0.05), Color(0.9, 0.85, 0.7), Vector3(0, 0, 25))
	k.add(sph(0.05, 5, 3), Vector3(-0.17, 1.86, -0.05), Color(1, 0.8, 0.2))
	return k.done()


static func _slime() -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(0.75, 9, 5), Vector3(0, 0.5, 0), C_SLIME, Vector3.ZERO, Vector3(1, 0.7, 1))
	k.add(sph(0.35, 7, 4), Vector3(0.2, 0.85, 0.1), C_SLIME.lightened(0.25))
	eyes(k, 0.7, -0.62, 0.2, 0.11, Color(0.05, 0.05, 0.05))
	k.add(sph(0.04, 4, 2), Vector3(-0.17, 0.74, -0.71), Color.WHITE)
	k.add(sph(0.04, 4, 2), Vector3(0.23, 0.74, -0.71), Color.WHITE)
	return k.done()


static func _nest() -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(1.0, 8, 4), Vector3(0, 0.6, 0), Color(0.25, 0.18, 0.22), Vector3.ZERO, Vector3(1, 1.2, 1))
	k.add(cone(0.8, 1.2, 7), Vector3(0, 1.8, 0), Color(0.2, 0.14, 0.18))
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		k.add(sph(0.22, 5, 3), Vector3(cos(a) * 0.85, 0.9 + (i % 2) * 0.4, sin(a) * 0.85), Color(0.03, 0.02, 0.05))
	k.add(sph(0.12, 5, 3), Vector3(0, 2.4, 0), Color(0.9, 0.3, 1.0))
	return k.done()


static func _totem() -> ArrayMesh:
	var k := Kit.new()
	k.add(cyl(0.12, 0.16, 2.4, 6), Vector3(0, 1.2, 0), C_WOOD.darkened(0.3))
	for i in 3:
		k.add(sph(0.3), Vector3(0, 0.8 + i * 0.65, 0), C_BONE, Vector3(0, i * 40, 0), Vector3(1, 0.85, 1))
		eyes(k, 0.82 + i * 0.65, -0.24, 0.1, 0.06, Color(0.3, 1.0, 0.7))
	k.add(box(1.2, 0.1, 0.1), Vector3(0, 2.3, 0), C_BONE, Vector3(0, 0, 10))
	k.add(cyl(0.6, 0.7, 0.15, 7), Vector3(0, 0.07, 0), C_STONE.darkened(0.3))
	return k.done()


static func _cultist() -> ArrayMesh:
	var k := Kit.new()
	k.add(cone(0.42, 1.2, 7), Vector3(0, 0.6, 0), Color(0.35, 0.08, 0.2))
	k.add(sph(0.26), Vector3(0, 1.25, 0), Color(0.3, 0.06, 0.17))
	k.add(cone(0.22, 0.4, 6), Vector3(0, 1.55, 0.05), Color(0.3, 0.06, 0.17), Vector3(15, 0, 0))
	k.add(sph(0.17, 5, 3), Vector3(0, 1.2, -0.13), C_DARK)
	eyes(k, 1.23, -0.27, 0.07, 0.045, Color(1.0, 0.3, 0.9))
	k.add(cyl(0.03, 0.03, 1.5, 4), Vector3(0.38, 0.85, -0.15), C_WOOD)
	k.add(sph(0.12, 5, 3), Vector3(0.38, 1.65, -0.15), Color(0.9, 0.3, 1.0))
	return k.done()


static func _ogre() -> ArrayMesh:
	var k := Kit.new()
	k.add(box(0.35, 0.7, 0.35), Vector3(-0.35, 0.35, 0), C_OGRE.darkened(0.2))
	k.add(box(0.35, 0.7, 0.35), Vector3(0.35, 0.35, 0), C_OGRE.darkened(0.2))
	k.add(sph(0.9, 8, 5), Vector3(0, 1.35, 0), C_OGRE, Vector3.ZERO, Vector3(1.05, 0.9, 0.85))
	k.add(box(1.4, 0.35, 0.9), Vector3(0, 0.85, 0), Color(0.4, 0.28, 0.18))
	k.add(sph(0.38), Vector3(0, 2.15, -0.25), C_OGRE.lightened(0.05))
	eyes(k, 2.2, -0.58, 0.14, 0.06, Color(1, 0.8, 0.2))
	k.add(cone(0.06, 0.18, 4), Vector3(-0.12, 2.0, -0.6), C_BONE, Vector3(-60, 0, 0))
	k.add(cone(0.06, 0.18, 4), Vector3(0.12, 2.0, -0.6), C_BONE, Vector3(-60, 0, 0))
	k.add(box(0.3, 0.9, 0.3), Vector3(-1.0, 1.4, 0), C_OGRE, Vector3(0, 0, 15))
	k.add(box(0.3, 0.9, 0.3), Vector3(1.0, 1.4, -0.1), C_OGRE, Vector3(-30, 0, -15))
	k.add(cyl(0.18, 0.08, 1.4, 6), Vector3(1.15, 1.4, -0.75), C_WOOD, Vector3(-70, 0, 0))
	return k.done()


static func _mimic() -> ArrayMesh:
	var k := Kit.new()
	k.add(box(1.3, 0.7, 0.9), Vector3(0, 0.35, 0), C_WOOD)
	k.add(box(1.36, 0.1, 0.96), Vector3(0, 0.15, 0), C_GOLD.darkened(0.3))
	k.add(box(1.3, 0.35, 0.9), Vector3(0, 0.95, 0.25), C_WOOD.lightened(0.1), Vector3(-35, 0, 0))
	for i in 6:
		k.add(cone(0.07, 0.2, 4), Vector3(-0.5 + i * 0.2, 0.78, -0.42), Color.WHITE, Vector3(180, 0, 0))
	k.add(box(0.3, 0.06, 0.6), Vector3(0, 0.72, -0.55), Color(0.85, 0.2, 0.3), Vector3(20, 0, 0))
	k.add(box(0.2, 0.25, 0.06), Vector3(0, 0.5, -0.47), C_GOLD)
	eyes(k, 0.95, -0.2, 0.3, 0.07, Color(1, 0.2, 0.1))
	return k.done()


static func _ghost(col: Color) -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(0.45, 8, 5), Vector3(0, 1.4, 0), col)
	k.add(cone(0.45, 1.1, 8), Vector3(0, 0.75, 0), col, Vector3(180, 0, 0))
	k.add(box(0.2, 0.35, 0.15), Vector3(-0.5, 1.15, -0.1), col, Vector3(0, 0, 40))
	k.add(box(0.2, 0.35, 0.15), Vector3(0.5, 1.15, -0.1), col, Vector3(0, 0, -40))
	k.add(sph(0.1, 5, 3), Vector3(-0.15, 1.5, -0.38), C_DARK, Vector3.ZERO, Vector3(1, 1.5, 0.5))
	k.add(sph(0.1, 5, 3), Vector3(0.15, 1.5, -0.38), C_DARK, Vector3.ZERO, Vector3(1, 1.5, 0.5))
	k.add(sph(0.12, 5, 3), Vector3(0, 1.25, -0.4), C_DARK, Vector3.ZERO, Vector3(1, 1.3, 0.4))
	return k.done()


static func _tower() -> ArrayMesh:
	var k := Kit.new()
	k.add(cyl(0.7, 0.9, 0.4, 6), Vector3(0, 0.2, 0), C_STONE.darkened(0.2))
	k.add(cyl(0.5, 0.65, 2.2, 6), Vector3(0, 1.5, 0), C_STONE)
	k.add(cyl(0.75, 0.6, 0.3, 6), Vector3(0, 2.7, 0), C_STONE.darkened(0.1))
	k.add(sph(0.45), Vector3(0, 3.2, 0), C_STONE.darkened(0.15), Vector3.ZERO, Vector3(1, 0.9, 1.1))
	k.add(box(1.0, 0.08, 0.5), Vector3(-0.55, 3.35, 0.1), C_STONE.darkened(0.3), Vector3(0, 20, 30))
	k.add(box(1.0, 0.08, 0.5), Vector3(0.55, 3.35, 0.1), C_STONE.darkened(0.3), Vector3(0, -20, -30))
	k.add(cone(0.08, 0.3, 4), Vector3(-0.2, 3.65, 0), C_STONE)
	k.add(cone(0.08, 0.3, 4), Vector3(0.2, 3.65, 0), C_STONE)
	eyes(k, 3.25, -0.4, 0.15, 0.07, Color(1, 0.4, 0.1))
	return k.done()


static func _werewolf() -> ArrayMesh:
	var k := Kit.new()
	k.add(box(0.25, 0.7, 0.3), Vector3(-0.22, 0.35, 0.1), C_FUR, Vector3(15, 0, 0))
	k.add(box(0.25, 0.7, 0.3), Vector3(0.22, 0.35, 0.1), C_FUR, Vector3(15, 0, 0))
	k.add(sph(0.55, 7, 4), Vector3(0, 1.1, 0), C_FUR, Vector3(-25, 0, 0), Vector3(1, 1.2, 0.9))
	k.add(sph(0.3), Vector3(0, 1.55, -0.45), C_FUR.lightened(0.05))
	k.add(box(0.2, 0.18, 0.35), Vector3(0, 1.48, -0.75), C_FUR.lightened(0.15))
	k.add(cone(0.1, 0.3, 4), Vector3(-0.18, 1.85, -0.4), C_FUR)
	k.add(cone(0.1, 0.3, 4), Vector3(0.18, 1.85, -0.4), C_FUR)
	eyes(k, 1.62, -0.7, 0.12, 0.05, Color(1, 0.85, 0.1))
	k.add(box(0.18, 0.75, 0.18), Vector3(-0.6, 0.95, -0.25), C_FUR, Vector3(-40, 0, 15))
	k.add(box(0.18, 0.75, 0.18), Vector3(0.6, 0.95, -0.25), C_FUR, Vector3(-40, 0, -15))
	return k.done()


static func _golem() -> ArrayMesh:
	var k := Kit.new()
	k.add(box(0.4, 0.7, 0.4), Vector3(-0.35, 0.35, 0), C_RUST.darkened(0.2))
	k.add(box(0.4, 0.7, 0.4), Vector3(0.35, 0.35, 0), C_RUST.darkened(0.2))
	k.add(box(1.3, 1.1, 0.9), Vector3(0, 1.25, 0), C_RUST, Vector3(0, 0, 3))
	k.add(box(0.6, 0.5, 0.55), Vector3(0, 2.05, -0.1), C_RUST.lightened(0.08))
	k.add(box(0.4, 0.08, 0.05), Vector3(0, 2.1, -0.39), Color(0.3, 0.9, 1.0))
	k.add(box(0.4, 1.0, 0.4), Vector3(-0.95, 1.2, 0), C_STEEL.darkened(0.35), Vector3(0, 0, 10))
	k.add(box(0.4, 1.0, 0.4), Vector3(0.95, 1.2, 0), C_STEEL.darkened(0.35), Vector3(0, 0, -10))
	for i in 4:
		k.add(sph(0.07, 4, 2), Vector3(-0.45 + i * 0.3, 1.55, -0.46), C_STEEL)
	k.add(cyl(0.05, 0.05, 0.6, 4), Vector3(0.3, 2.5, 0.2), C_STEEL.darkened(0.3), Vector3(0, 0, 20))
	return k.done()


# ---------------------------------------------------------------- herói e chefe

static func hero_body() -> ArrayMesh:
	var k := Kit.new()
	k.add(box(0.26, 0.75, 0.3), Vector3(-0.18, 0.38, 0), C_STEEL.darkened(0.25))
	k.add(box(0.26, 0.75, 0.3), Vector3(0.18, 0.38, 0), C_STEEL.darkened(0.25))
	k.add(box(0.7, 0.75, 0.42), Vector3(0, 1.1, 0), C_STEEL)
	k.add(box(0.74, 0.12, 0.46), Vector3(0, 0.78, 0), C_WOOD)
	k.add(box(0.06, 0.6, 0.4), Vector3(0, 1.15, -0.2), Color(0.2, 0.35, 0.8))
	k.add(sph(0.22), Vector3(-0.45, 1.4, 0), C_STEEL.lightened(0.1))
	k.add(sph(0.22), Vector3(0.45, 1.4, 0), C_STEEL.lightened(0.1))
	k.add(box(0.2, 0.6, 0.2), Vector3(-0.5, 1.05, 0), C_STEEL.darkened(0.1))
	k.add(box(0.75, 1.1, 0.06), Vector3(0, 1.0, 0.27), Color(0.18, 0.3, 0.75), Vector3(8, 0, 0))
	k.add(cyl(0.27, 0.3, 0.45, 8), Vector3(0, 1.72, 0), C_STEEL.lightened(0.1))
	k.add(sph(0.29, 8, 4), Vector3(0, 1.95, 0), C_STEEL.lightened(0.15), Vector3.ZERO, Vector3(1, 0.7, 1))
	k.add(box(0.4, 0.06, 0.05), Vector3(0, 1.75, -0.28), C_DARK)
	k.add(box(0.08, 0.25, 0.5), Vector3(0, 2.2, 0.05), Color(0.9, 0.15, 0.15))
	return k.done()


static func hero_sword() -> ArrayMesh:
	var k := Kit.new()
	k.add(box(0.1, 0.1, 0.25), Vector3(0, 0, 0.1), C_WOOD)
	k.add(box(0.4, 0.06, 0.08), Vector3(0, 0, -0.05), C_GOLD)
	k.add(box(0.1, 0.03, 1.2), Vector3(0, 0, -0.65), Color(0.85, 0.9, 1.0))
	return k.done()


static func hero_shield() -> ArrayMesh:
	var k := Kit.new()
	k.add(box(0.75, 0.95, 0.1), Vector3(0, 0, 0), Color(0.2, 0.35, 0.8))
	k.add(box(0.8, 0.08, 0.12), Vector3(0, 0.45, 0), C_GOLD)
	k.add(box(0.12, 0.85, 0.13), Vector3(0, 0, -0.01), C_GOLD)
	k.add(box(0.6, 0.12, 0.13), Vector3(0, 0.1, -0.01), C_GOLD)
	return k.done()


static func boss_part(id: String) -> ArrayMesh:
	var k := Kit.new()
	var robe := Color(0.18, 0.08, 0.26)
	match id:
		"core":
			k.add(cone(1.6, 3.2, 8), Vector3(0, 1.6, 0), robe)
			k.add(box(1.8, 1.0, 1.1), Vector3(0, 3.0, 0), robe.lightened(0.08))
			k.add(sph(0.45, 8, 5), Vector3(0, 2.6, -0.65), Color(0.85, 0.2, 1.0))
			k.add(cyl(0.6, 0.6, 0.12, 8), Vector3(0, 2.6, -0.6), C_GOLD, Vector3(90, 0, 0))
			k.add(box(2.6, 0.25, 0.9), Vector3(0, 3.55, 0), C_DARK)
			for sx in [-1.2, 1.2]:
				k.add(cone(0.25, 0.8, 5), Vector3(sx, 3.9, 0), C_BONE, Vector3(0, 0, -sx * 20))
		"head":
			k.add(sph(0.6, 8, 5), Vector3(0, 0, 0), Color(0.5, 0.45, 0.55))
			k.add(box(0.8, 0.15, 0.1), Vector3(0, 0.05, -0.55), Color(1.0, 0.3, 0.15))
			k.add(cone(0.18, 1.0, 5), Vector3(-0.45, 0.6, 0), C_DARK, Vector3(0, 0, 30))
			k.add(cone(0.18, 1.0, 5), Vector3(0.45, 0.6, 0), C_DARK, Vector3(0, 0, -30))
			k.add(cyl(0.5, 0.45, 0.25, 8), Vector3(0, 0.55, 0), C_GOLD)
			for i in 5:
				var a := TAU * i / 5.0
				k.add(cone(0.08, 0.3, 4), Vector3(cos(a) * 0.45, 0.8, sin(a) * 0.45), C_GOLD)
		"left_arm":
			k.add(box(0.5, 1.8, 0.5), Vector3(0, 0, 0), robe.lightened(0.05), Vector3(0, 0, 15))
			k.add(sph(0.35), Vector3(-0.25, 1.0, 0), robe.lightened(0.1))
			k.add(sph(0.45, 8, 4), Vector3(0.15, -1.2, -0.3), Color(0.3, 0.5, 1.0))
		"right_arm":
			k.add(box(0.5, 1.8, 0.5), Vector3(0, 0, 0), robe.lightened(0.05), Vector3(0, 0, -15))
			k.add(sph(0.35), Vector3(0.25, 1.0, 0), robe.lightened(0.1))
			for i in 3:
				k.add(cone(0.1, 0.7, 4), Vector3(-0.2 + i * 0.2, -1.3, -0.2), Color(1.0, 0.35, 0.25), Vector3(170, 0, 0))
	return k.done()


static func boss_full() -> Node3D:
	var n := Node3D.new()
	var offs := {"core": Vector3(0, 0, 0), "head": Vector3(0, 4.4, 0), "left_arm": Vector3(-1.7, 2.4, 0), "right_arm": Vector3(1.7, 2.4, 0)}
	for id in offs:
		var mi := MeshInstance3D.new()
		mi.mesh = boss_part(id)
		mi.material_override = material()
		mi.position = offs[id]
		n.add_child(mi)
	return n


# ---------------------------------------------------------------- cenário

static func prop(id: String) -> ArrayMesh:
	if _cache.has("p_" + id):
		return _cache["p_" + id]
	var k := Kit.new()
	match id:
		"tree":
			k.add(cyl(0.18, 0.28, 1.6, 5), Vector3(0, 0.8, 0), C_WOOD.darkened(0.3))
			k.add(cone(1.4, 2.0, 6), Vector3(0, 2.2, 0), C_LEAF)
			k.add(cone(1.1, 1.7, 6), Vector3(0, 3.2, 0), C_LEAF2)
			k.add(cone(0.7, 1.3, 6), Vector3(0, 4.1, 0), C_LEAF2.lightened(0.05))
		"dead_tree":
			k.add(cyl(0.12, 0.25, 3.0, 5), Vector3(0, 1.5, 0), Color(0.25, 0.2, 0.2))
			k.add(cyl(0.05, 0.1, 1.4, 4), Vector3(0.5, 2.5, 0), Color(0.25, 0.2, 0.2), Vector3(0, 0, -50))
			k.add(cyl(0.05, 0.1, 1.2, 4), Vector3(-0.45, 2.0, 0.1), Color(0.25, 0.2, 0.2), Vector3(0, 0, 55))
		"rock":
			k.add(sph(0.8, 6, 3), Vector3(0, 0.3, 0), C_STONE.darkened(0.25), Vector3(0, 20, 0), Vector3(1.3, 0.7, 1))
			k.add(sph(0.45, 5, 3), Vector3(0.7, 0.2, 0.3), C_STONE.darkened(0.15))
		"grass":
			for i in 3:
				k.add(cone(0.06, 0.5, 3), Vector3((i - 1) * 0.12, 0.25, (i % 2) * 0.1), Color(0.3, 0.5, 0.3), Vector3(0, 0, (i - 1) * 18))
		"mushroom":
			k.add(cyl(0.05, 0.07, 0.3, 5), Vector3(0, 0.15, 0), Color(0.85, 0.85, 0.8))
			k.add(sph(0.18, 6, 3), Vector3(0, 0.32, 0), Color(0.3, 0.9, 1.0), Vector3.ZERO, Vector3(1, 0.5, 1))
		"house":
			k.add(box(3.0, 2.0, 2.6), Vector3(0, 1.0, 0), Color(0.55, 0.45, 0.35))
			k.add(cyl(0.0, 2.3, 1.6, 4), Vector3(0, 2.8, 0), Color(0.5, 0.18, 0.15), Vector3(0, 45, 0), Vector3(1.0, 1, 0.85))
			k.add(box(0.7, 1.2, 0.1), Vector3(0, 0.6, -1.32), C_WOOD.darkened(0.3))
			k.add(box(0.5, 0.5, 0.1), Vector3(-0.9, 1.3, -1.32), Color(1.0, 0.8, 0.4))
			k.add(box(0.5, 0.5, 0.1), Vector3(0.9, 1.3, -1.32), Color(1.0, 0.8, 0.4))
		"tavern":
			k.add(box(4.0, 2.6, 3.0), Vector3(0, 1.3, 0), Color(0.45, 0.32, 0.22))
			k.add(cyl(0.0, 3.0, 1.8, 4), Vector3(0, 3.5, 0), Color(0.3, 0.2, 0.15), Vector3(0, 45, 0), Vector3(1.0, 1, 0.75))
			k.add(box(1.2, 0.7, 0.1), Vector3(1.4, 2.0, -1.8), C_GOLD.darkened(0.2))
			k.add(cyl(0.3, 0.3, 0.6, 7), Vector3(-1.3, 0.3, -1.9), C_WOOD, Vector3(0, 0, 90))
			for x in [-1.0, 0.0, 1.0]:
				k.add(box(0.5, 0.5, 0.1), Vector3(x, 1.4, -1.52), Color(1.0, 0.75, 0.35))
		"fountain":
			k.add(cyl(2.2, 2.4, 0.6, 10), Vector3(0, 0.3, 0), C_STONE)
			k.add(cyl(1.9, 1.9, 0.1, 10), Vector3(0, 0.58, 0), Color(0.3, 0.7, 1.0))
			k.add(cyl(0.3, 0.4, 1.8, 7), Vector3(0, 1.2, 0), C_STONE.lightened(0.1))
			k.add(cyl(0.8, 0.5, 0.3, 8), Vector3(0, 2.1, 0), C_STONE.lightened(0.1))
			k.add(sph(0.3, 6, 3), Vector3(0, 2.5, 0), Color(0.5, 0.85, 1.0))
		"ritual":
			var tm := TorusMesh.new()
			tm.inner_radius = 4.6
			tm.outer_radius = 5.0
			tm.rings = 24
			tm.ring_segments = 4
			k.add(tm, Vector3(0, 0.05, 0), Color(0.8, 0.25, 1.0), Vector3.ZERO, Vector3(1, 0.2, 1))
			for i in 5:
				var a := TAU * i / 5.0
				k.add(cyl(0.12, 0.15, 0.5, 5), Vector3(cos(a) * 4.0, 0.25, sin(a) * 4.0), Color(0.9, 0.85, 0.7))
				k.add(sph(0.1, 4, 2), Vector3(cos(a) * 4.0, 0.6, sin(a) * 4.0), Color(1.0, 0.6, 0.2))
				var b := TAU * (i + 2) / 5.0
				var p0 := Vector3(cos(a), 0, sin(a)) * 4.4
				var p1 := Vector3(cos(b), 0, sin(b)) * 4.4
				var mid := (p0 + p1) * 0.5
				k.add(box(0.12, 0.04, p0.distance_to(p1)), mid + Vector3(0, 0.04, 0), Color(0.8, 0.25, 1.0), Vector3(0, rad_to_deg(atan2(p1.x - p0.x, p1.z - p0.z)), 0))
		"shrine":
			k.add(cyl(1.4, 1.6, 0.4, 6), Vector3(0, 0.2, 0), C_STONE.darkened(0.1))
			k.add(cyl(0.3, 0.55, 3.0, 4), Vector3(0, 1.9, 0), C_STONE.lightened(0.05))
			k.add(sph(0.45, 4, 2), Vector3(0, 3.8, 0), Color(0.3, 1.0, 0.6), Vector3.ZERO, Vector3(1, 1.6, 1))
		"bridge":
			k.add(box(5.0, 0.3, 14.0), Vector3(0, 0.12, 0), C_WOOD)
			for z in range(-6, 7, 2):
				k.add(box(5.2, 0.08, 0.3), Vector3(0, 0.3, z), C_WOOD.darkened(0.25))
			for sx in [-2.6, 2.6]:
				k.add(box(0.15, 0.8, 14.0), Vector3(sx, 0.7, 0), C_WOOD.darkened(0.15))
				for z in range(-6, 7, 3):
					k.add(box(0.25, 1.1, 0.25), Vector3(sx, 0.55, z), C_WOOD.darkened(0.3))
		"water":
			k.add(box(30.0, 0.05, 9.0), Vector3(0, -0.15, 0), Color(0.1, 0.25, 0.45))
		"castle":
			k.add(box(16.0, 7.0, 4.0), Vector3(0, 3.5, 0), Color(0.22, 0.17, 0.28))
			for sx in [-9.0, 9.0]:
				k.add(cyl(2.2, 2.6, 11.0, 8), Vector3(sx, 5.5, 0), Color(0.25, 0.19, 0.31))
				k.add(cone(2.8, 4.0, 8), Vector3(sx, 13.0, 0), Color(0.35, 0.1, 0.35))
			k.add(cyl(2.8, 3.2, 14.0, 8), Vector3(0, 7.0, 3.0), Color(0.2, 0.15, 0.26))
			k.add(cone(3.4, 6.0, 8), Vector3(0, 17.0, 3.0), Color(0.4, 0.1, 0.4))
			k.add(box(4.0, 5.0, 0.3), Vector3(0, 2.5, -2.1), C_DARK)
			for i in 6:
				k.add(box(0.6, 1.0, 0.2), Vector3(-6.5 + i * 2.6, 5.0, -2.05), Color(1.0, 0.5, 0.9))
			for i in 8:
				k.add(box(1.2, 1.0, 4.2), Vector3(-7.0 + i * 2.0, 7.5, 0), Color(0.22, 0.17, 0.28))
		"pillar":
			k.add(cyl(0.7, 0.8, 0.4, 6), Vector3(0, 0.2, 0), C_STONE.darkened(0.2))
			k.add(cyl(0.5, 0.55, 4.0, 6), Vector3(0, 2.4, 0), C_STONE.darkened(0.05))
			k.add(cyl(0.75, 0.6, 0.4, 6), Vector3(0, 4.5, 0), C_STONE.darkened(0.2))
		"brazier":
			k.add(cyl(0.12, 0.2, 1.4, 5), Vector3(0, 0.7, 0), C_DARK.lightened(0.1))
			k.add(cyl(0.6, 0.3, 0.4, 7), Vector3(0, 1.5, 0), C_DARK.lightened(0.15))
			k.add(cone(0.4, 0.8, 5), Vector3(0, 2.0, 0), Color(1.0, 0.55, 0.15))
		"altar":
			k.add(cyl(1.1, 1.3, 0.5, 6), Vector3(0, 0.25, 0), C_STONE.darkened(0.3))
			k.add(cyl(0.8, 0.9, 0.3, 6), Vector3(0, 0.65, 0), C_STONE.darkened(0.15))
			var tm2 := TorusMesh.new()
			tm2.inner_radius = 0.9
			tm2.outer_radius = 1.05
			tm2.rings = 16
			tm2.ring_segments = 4
			k.add(tm2, Vector3(0, 0.85, 0), Color(0.6, 0.3, 1.0), Vector3.ZERO, Vector3(1, 0.3, 1))
		"throne":
			k.add(box(3.0, 1.0, 2.5), Vector3(0, 0.5, 0), C_DARK.lightened(0.1))
			k.add(box(3.0, 5.0, 0.6), Vector3(0, 3.0, 1.0), Color(0.3, 0.1, 0.35))
			for sx in [-1.4, 0.0, 1.4]:
				k.add(cone(0.35, 1.4, 4), Vector3(sx, 6.0 + (0.6 if sx == 0.0 else 0.0), 1.0), C_GOLD.darkened(0.2))
		"coins":
			for i in 7:
				var a := i * 2.3
				k.add(cyl(0.18, 0.18, 0.06, 7), Vector3(cos(a) * 0.25 * (i % 3), 0.05 + i * 0.05, sin(a) * 0.25 * (i % 3)), C_GOLD)
		_:
			k.add(box(1, 1, 1), Vector3(0, 0.5, 0), C_STONE)
	var m := k.done()
	_cache["p_" + id] = m
	return m


# ---------------------------------------------------------------- ícones (cartas sem unidade)

static func icon(id: String) -> ArrayMesh:
	var k := Kit.new()
	match id:
		"shadow_bolt":
			for i in 4:
				k.add(box(0.25, 0.25, 0.7), Vector3(0.3 * (i % 2) - 0.15, 0.3 + i * 0.4, -0.5 + i * 0.35), Color(0.6, 0.2, 1.0), Vector3(30, 0, 25 - 50 * (i % 2)))
		"web":
			for i in 4:
				k.add(box(1.8, 0.05, 0.05), Vector3(0, 0.8, 0), Color(0.92, 0.92, 0.95), Vector3(0, 0, 0), Vector3.ONE)
				k.add(box(0.05, 0.05, 1.8), Vector3(0, 0.8, 0), Color(0.92, 0.92, 0.95), Vector3(0, i * 22, 0))
			var tm := TorusMesh.new()
			tm.inner_radius = 0.5
			tm.outer_radius = 0.56
			k.add(tm, Vector3(0, 0.8, 0), Color(0.92, 0.92, 0.95))
		"boiling_oil":
			k.add(cyl(0.7, 0.5, 0.8, 8), Vector3(0, 0.4, 0), C_DARK.lightened(0.15))
			k.add(cyl(0.6, 0.6, 0.06, 8), Vector3(0, 0.8, 0), Color(1.0, 0.55, 0.1))
			for i in 3:
				k.add(sph(0.12, 5, 3), Vector3(-0.3 + i * 0.3, 0.95 + (i % 2) * 0.2, 0), Color(1.0, 0.7, 0.2))
		"soul_feast":
			k.add(cyl(0.6, 0.4, 0.3, 8), Vector3(0, 0.15, 0), C_GOLD.darkened(0.3))
			for i in 3:
				k.add(sph(0.2, 6, 3), Vector3(-0.3 + i * 0.3, 0.5 + i * 0.15, 0), Color(0.5, 1.0, 0.9))
		"broken_bridge":
			k.add(box(1.0, 0.15, 0.6), Vector3(-0.6, 0.5, 0), C_WOOD, Vector3(0, 0, -15))
			k.add(box(1.0, 0.15, 0.6), Vector3(0.6, 0.5, 0), C_WOOD, Vector3(0, 0, 15))
		"false_sign":
			k.add(cyl(0.06, 0.06, 1.6, 5), Vector3(0, 0.8, 0), C_WOOD)
			k.add(box(1.0, 0.3, 0.08), Vector3(0.35, 1.3, 0), C_WOOD.lightened(0.15), Vector3(0, 0, 8))
			k.add(box(1.0, 0.3, 0.08), Vector3(-0.35, 0.95, 0), C_WOOD.lightened(0.1), Vector3(0, 0, -8))
		"gold_bait":
			return prop("coins")
		"burn_village":
			k.add(box(1.0, 0.7, 0.9), Vector3(0, 0.35, 0), Color(0.3, 0.22, 0.18))
			k.add(cone(0.5, 0.9, 5), Vector3(-0.2, 1.1, 0), Color(1.0, 0.45, 0.1))
			k.add(cone(0.35, 0.7, 5), Vector3(0.3, 1.0, 0.1), Color(1.0, 0.8, 0.2))
		"soul_collector":
			k.add(cyl(0.4, 0.5, 0.9, 7), Vector3(0, 0.45, 0), Color(0.5, 0.9, 1.0))
			k.add(cyl(0.45, 0.45, 0.15, 7), Vector3(0, 0.95, 0), C_GOLD)
			k.add(sph(0.2, 5, 3), Vector3(0, 0.5, 0), Color(0.9, 1.0, 1.0))
		"forbidden_library":
			k.add(box(1.1, 0.25, 0.8), Vector3(0, 0.15, 0), Color(0.45, 0.1, 0.2))
			k.add(box(1.0, 0.25, 0.75), Vector3(0.05, 0.42, 0), Color(0.2, 0.15, 0.4), Vector3(0, 12, 0))
			k.add(box(0.9, 0.22, 0.7), Vector3(-0.05, 0.66, 0), Color(0.15, 0.35, 0.25), Vector3(0, -10, 0))
		"dark_forge":
			k.add(box(1.2, 0.4, 0.6), Vector3(0, 0.6, 0), C_DARK.lightened(0.2))
			k.add(box(0.5, 0.5, 0.4), Vector3(0, 0.25, 0), C_DARK.lightened(0.1))
			k.add(cone(0.25, 0.4, 4), Vector3(-0.75, 0.62, 0), C_DARK.lightened(0.2), Vector3(0, 0, 90))
		"lair_walls":
			for i in 3:
				k.add(box(0.5, 1.0, 0.5), Vector3(-0.6 + i * 0.6, 0.5, 0), Color(0.3, 0.24, 0.38))
				k.add(box(0.2, 0.25, 0.5), Vector3(-0.6 + i * 0.6, 1.12, 0), Color(0.3, 0.24, 0.38))
		"cosmic_ray":
			k.add(cyl(0.25, 0.25, 2.2, 8), Vector3(0, 0.6, 0), Color(1.0, 0.85, 0.3), Vector3(0, 0, 70))
			k.add(sph(0.4, 7, 4), Vector3(-0.9, 0.3, 0), Color(1.0, 0.95, 0.6))
		"bone_prison":
			for i in 6:
				var a := TAU * i / 6.0
				k.add(cyl(0.05, 0.07, 1.4, 4), Vector3(cos(a) * 0.5, 0.7, sin(a) * 0.5), C_BONE)
			k.add(sph(0.25), Vector3(0, 1.5, 0), C_BONE)
		"petrifying_gaze":
			k.add(sph(0.6, 8, 4), Vector3(0, 0.7, 0), Color(0.9, 0.9, 0.8), Vector3.ZERO, Vector3(1, 0.7, 0.6))
			k.add(sph(0.3, 6, 3), Vector3(0, 0.7, -0.25), Color(0.4, 1.0, 0.4))
			k.add(sph(0.14, 5, 3), Vector3(0, 0.7, -0.45), C_DARK)
		"damned_army":
			for i in 3:
				k.add(sph(0.3), Vector3(-0.5 + i * 0.5, 0.5 + (i % 2) * 0.3, 0), Color(0.4, 1.0, 0.85))
		"dark_fury":
			k.add(cone(0.6, 1.4, 6), Vector3(0, 0.7, 0), Color(0.75, 0.2, 1.0))
			k.add(cone(0.35, 0.9, 6), Vector3(0, 0.6, -0.2), Color(1.0, 0.5, 1.0))
		"dark_pact":
			k.add(sph(0.45, 7, 4), Vector3(-0.2, 0.7, 0), Color(0.8, 0.1, 0.2))
			k.add(sph(0.45, 7, 4), Vector3(0.2, 0.7, 0), Color(0.8, 0.1, 0.2))
			k.add(cone(0.55, 0.7, 6), Vector3(0, 0.2, 0), Color(0.8, 0.1, 0.2), Vector3(180, 0, 0))
		_:
			k.add(box(0.8, 0.8, 0.8), Vector3(0, 0.4, 0), C_STONE)
	return k.done()
