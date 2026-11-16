class_name Models
extends RefCounted
## Modelos low-poly montados por código a partir de primitivas, com cor por vértice (paleta única).
## Frente = -Z, chão em y = 0. Tudo usa o mesmo material (toon.gdshader).
## Cor com alfa < 1 = parte emissiva (olhos, cristais, fogo).

const C_BONE := Color(0.9, 0.86, 0.74)
const C_RAT := Color(0.5, 0.42, 0.4)
const C_RAT_BELLY := Color(0.72, 0.62, 0.56)
const C_PINK := Color(0.95, 0.6, 0.66)
const C_GOB := Color(0.45, 0.75, 0.28)
const C_SLIME := Color(0.3, 0.95, 0.55)
const C_PURPLE := Color(0.48, 0.24, 0.62)
const C_DARK := Color(0.1, 0.08, 0.12)
const C_GOLD := Color(1.0, 0.78, 0.25)
const C_WOOD := Color(0.45, 0.29, 0.17)
const C_STONE := Color(0.5, 0.5, 0.56)
const C_STEEL := Color(0.75, 0.78, 0.86)
const C_LEAF := Color(0.16, 0.38, 0.3)
const C_LEAF2 := Color(0.22, 0.46, 0.34)
const C_GHOST := Color(0.7, 0.88, 1.0)
const C_RUST := Color(0.62, 0.4, 0.24)
const C_OGRE := Color(0.55, 0.62, 0.34)
const C_FUR := Color(0.38, 0.3, 0.26)
const C_WHITE := Color(0.97, 0.96, 0.92)
const C_RED_EYE := Color(1.0, 0.15, 0.1)

static var _cache: Dictionary = {}
static var _mat: ShaderMaterial
static var _mat_look := -1


## Numa direção de arte única (look de chão 5 ou 6) prédios, cenário e chefe usam o shader dela.
static func material() -> ShaderMaterial:
	var wl := GroundLooks.world_shader_look()
	if _mat == null or _mat_look != wl:
		_mat_look = wl
		if wl > 0:
			_mat = Looks.material(wl)
		else:
			_mat = ShaderMaterial.new()
			_mat.shader = load("res://game/art/toon.gdshader")
	return _mat


static func glow_material(emit: float) -> ShaderMaterial:
	var wl := GroundLooks.world_shader_look()
	if wl > 0:
		return Looks.material(wl, emit)
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/toon.gdshader")
	m.set_shader_parameter("emission_boost", emit)
	return m


static func G(c: Color) -> Color:
	return Color(c.r, c.g, c.b, 0.0)


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


static func sph(r: float, seg := 9, rings := 5) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = rings
	return m


static func cyl(top: float, bottom: float, h: float, seg := 8) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


static func cone(r: float, h: float, seg := 6) -> CylinderMesh:
	return cyl(0.0, r, h, seg)


## Olhos de desenho animado: esclera branca e pupila escura olhando para a frente.
static func eyes(k: Kit, y: float, z: float, dx: float, r: float, col := Color(0.05, 0.03, 0.06)) -> void:
	for sx in [-1.0, 1.0]:
		k.add(sph(r, 8, 5), Vector3(sx * dx, y, z), C_WHITE)
		k.add(sph(r * 0.55, 6, 4), Vector3(sx * dx * 1.05, y - r * 0.1, z - r * 0.7), col)


## Olhos brilhantes (emissivos).
static func geyes(k: Kit, y: float, z: float, dx: float, r: float, col: Color) -> void:
	for sx in [-1.0, 1.0]:
		k.add(sph(r, 6, 4), Vector3(sx * dx, y, z), G(col), Vector3.ZERO, Vector3(1, 0.75, 0.6))


# ---------------------------------------------------------------- unidades

static func unit(id: String) -> ArrayMesh:
	id = CardModel.of(id)
	if _cache.has(id):
		return _cache[id]
	var m: ArrayMesh
	match id:
		"rat", "rat_horde":
			m = _rat(1.0, false)
		"rat_king":
			m = _rat(1.9, true)
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


static func _rat(s: float, king: bool) -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(0.3 * s, 10, 6), Vector3(0, 0.27 * s, 0.06 * s), C_RAT, Vector3.ZERO, Vector3(1.0, 0.85, 1.3))
	k.add(sph(0.24 * s, 9, 5), Vector3(0, 0.2 * s, -0.04 * s), C_RAT_BELLY, Vector3.ZERO, Vector3(0.9, 0.8, 1.1))
	k.add(sph(0.21 * s, 10, 6), Vector3(0, 0.38 * s, -0.32 * s), C_RAT.lightened(0.06))
	k.add(cone(0.11 * s, 0.24 * s, 7), Vector3(0, 0.34 * s, -0.55 * s), C_RAT.lightened(0.1), Vector3(-90, 0, 0))
	k.add(sph(0.045 * s, 6, 4), Vector3(0, 0.34 * s, -0.68 * s), C_PINK)
	for sx in [-1.0, 1.0]:
		k.add(cyl(0.12 * s, 0.12 * s, 0.03 * s, 10), Vector3(sx * 0.15 * s, 0.56 * s, -0.27 * s), C_RAT, Vector3(80, 0, sx * 20))
		k.add(cyl(0.08 * s, 0.08 * s, 0.035 * s, 10), Vector3(sx * 0.15 * s, 0.56 * s, -0.29 * s), C_PINK, Vector3(80, 0, sx * 20))
		k.add(sph(0.06 * s, 6, 4), Vector3(sx * 0.15 * s, 0.06 * s, -0.2 * s), C_PINK)
		k.add(sph(0.06 * s, 6, 4), Vector3(sx * 0.15 * s, 0.06 * s, 0.25 * s), C_PINK)
	eyes(k, 0.44 * s, -0.47 * s, 0.085 * s, 0.05 * s, Color(0.6, 0.05, 0.05))
	k.add(box(0.07 * s, 0.06 * s, 0.02 * s), Vector3(0, 0.27 * s, -0.63 * s), C_WHITE)
	for i in 4:
		k.add(cyl(0.025 * s, 0.035 * s, 0.22 * s, 5), Vector3(0, 0.18 * s + i * 0.05 * s, 0.45 * s + i * 0.17 * s), C_PINK, Vector3(70 - i * 25, 0, 0))
	if king:
		k.add(cyl(0.2, 0.17, 0.18, 8), Vector3(0, 1.0, -0.6), C_GOLD)
		for i in 5:
			var a := TAU * i / 5.0
			k.add(cone(0.06, 0.18, 4), Vector3(cos(a) * 0.17, 1.17, -0.6 + sin(a) * 0.17), C_GOLD)
			k.add(sph(0.035, 5, 3), Vector3(cos(a) * 0.19, 1.02, -0.6 + sin(a) * 0.19), G(Color(1, 0.2, 0.3)))
		k.add(box(0.75, 0.08, 0.7), Vector3(0, 0.72, 0.25), Color(0.6, 0.1, 0.2), Vector3(-12, 0, 0))
		k.add(box(0.8, 0.1, 0.12), Vector3(0, 0.76, -0.12), C_WHITE)
		k.add(cyl(0.03, 0.03, 1.0, 5), Vector3(0.55, 0.75, -0.3), C_GOLD)
		k.add(sph(0.1, 6, 4), Vector3(0.55, 1.28, -0.3), G(Color(1, 0.3, 0.4)))
	return k.done()


static func _bat() -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(0.22, 9, 5), Vector3(0, 0, 0), C_PURPLE)
	k.add(sph(0.16, 8, 5), Vector3(0, 0.12, -0.12), C_PURPLE.lightened(0.08))
	for sx in [-1.0, 1.0]:
		k.add(box(0.36, 0.03, 0.34), Vector3(sx * 0.36, 0.06, 0.02), C_PURPLE.darkened(0.35), Vector3(0, sx * 10, sx * -15))
		k.add(box(0.3, 0.03, 0.26), Vector3(sx * 0.66, 0.14, 0.06), C_PURPLE.darkened(0.45), Vector3(0, sx * 20, sx * -30))
		k.add(cone(0.07, 0.2, 4), Vector3(sx * 0.1, 0.33, -0.1), C_PURPLE)
		k.add(cone(0.02, 0.07, 3), Vector3(sx * 0.04, 0.0, -0.25), C_WHITE, Vector3(180, 0, 0))
	geyes(k, 0.15, -0.25, 0.07, 0.045, Color(1, 0.85, 0.2))
	return k.done()


static func _skeleton(bow: bool) -> ArrayMesh:
	var k := Kit.new()
	for sx in [-1.0, 1.0]:
		k.add(cyl(0.05, 0.06, 0.55, 5), Vector3(sx * 0.12, 0.28, 0), C_BONE)
		k.add(box(0.12, 0.06, 0.2), Vector3(sx * 0.12, 0.03, -0.04), C_BONE)
		k.add(cyl(0.04, 0.05, 0.45, 5), Vector3(sx * 0.3, 0.92, -0.08), C_BONE, Vector3(-30, 0, sx * 15))
	k.add(cyl(0.18, 0.12, 0.14, 7), Vector3(0, 0.6, 0), C_BONE)
	k.add(cyl(0.04, 0.04, 0.5, 5), Vector3(0, 0.85, 0.02), C_BONE)
	for i in 3:
		k.add(cyl(0.2 - i * 0.025, 0.2 - i * 0.025, 0.05, 8), Vector3(0, 0.8 + i * 0.12, 0), C_BONE, Vector3.ZERO, Vector3(1, 1, 0.7))
	k.add(sph(0.26, 10, 6), Vector3(0, 1.38, 0), C_BONE)
	k.add(box(0.26, 0.12, 0.2), Vector3(0, 1.2, -0.08), C_BONE)
	for sx in [-1.0, 1.0]:
		k.add(sph(0.075, 6, 4), Vector3(sx * 0.1, 1.4, -0.2), C_DARK)
	geyes(k, 1.4, -0.24, 0.1, 0.04, Color(0.3, 1.0, 0.6))
	if bow:
		for i in 5:
			var a := deg_to_rad(-60 + i * 30)
			k.add(box(0.05, 0.28, 0.05), Vector3(0.0, 1.0 + sin(a) * 0.5, -0.4 - cos(a) * 0.12), C_WOOD, Vector3(-rad_to_deg(a) * 0.5, 0, 0))
		k.add(cyl(0.008, 0.008, 1.0, 3), Vector3(0, 1.0, -0.3), C_WHITE)
		k.add(cyl(0.09, 0.08, 0.6, 6), Vector3(-0.15, 1.0, 0.18), C_WOOD.darkened(0.2), Vector3(15, 0, 10))
		for i in 3:
			k.add(cone(0.04, 0.1, 4), Vector3(-0.2 + i * 0.05, 1.35, 0.22), Color(0.8, 0.2, 0.2))
	else:
		k.add(box(0.07, 0.75, 0.04), Vector3(0.32, 1.1, -0.35), C_STEEL.darkened(0.3), Vector3(-60, 0, 0))
		k.add(cyl(0.25, 0.25, 0.05, 7), Vector3(-0.35, 0.95, -0.15), C_WOOD, Vector3(90, 0, 0))
	return k.done()


static func _goblin() -> ArrayMesh:
	var k := Kit.new()
	for sx in [-1.0, 1.0]:
		k.add(cyl(0.06, 0.07, 0.3, 6), Vector3(sx * 0.11, 0.15, 0), C_GOB)
		k.add(sph(0.09, 6, 4), Vector3(sx * 0.11, 0.03, -0.06), C_WOOD.darkened(0.3), Vector3.ZERO, Vector3(1, 0.6, 1.4))
		k.add(cyl(0.05, 0.06, 0.35, 5), Vector3(sx * 0.3, 0.55, -0.05), C_GOB, Vector3(0, 0, sx * 25))
		k.add(cone(0.13, 0.55, 5), Vector3(sx * 0.48, 1.05, 0.02), C_GOB, Vector3(10, 0, sx * -72))
		k.add(cone(0.07, 0.4, 5), Vector3(sx * 0.46, 1.05, 0.0), C_PINK.darkened(0.2), Vector3(10, 0, sx * -72))
	k.add(sph(0.26, 9, 5), Vector3(0, 0.5, 0), Color(0.5, 0.33, 0.2), Vector3.ZERO, Vector3(1, 1.1, 0.9))
	k.add(sph(0.34, 10, 6), Vector3(0, 1.0, -0.03), C_GOB)
	k.add(cone(0.08, 0.25, 6), Vector3(0, 0.98, -0.42), C_GOB.darkened(0.1), Vector3(-80, 0, 0))
	eyes(k, 1.1, -0.28, 0.13, 0.085, Color(0.6, 0.1, 0.0))
	k.add(box(0.3, 0.05, 0.04), Vector3(0, 0.84, -0.3), C_DARK)
	for i in 4:
		k.add(box(0.045, 0.05, 0.03), Vector3(-0.09 + i * 0.06, 0.82, -0.31), C_WHITE)
	k.add(cyl(0.09, 0.09, 0.55, 8), Vector3(0.3, 1.5, -0.05), Color(0.9, 0.15, 0.1), Vector3(0, 0, 30))
	k.add(cyl(0.095, 0.095, 0.06, 8), Vector3(0.3, 1.5, -0.05), C_WOOD, Vector3(0, 0, 30))
	k.add(cyl(0.015, 0.015, 0.2, 4), Vector3(0.15, 1.8, -0.05), C_WHITE, Vector3(0, 0, 30))
	k.add(sph(0.07, 6, 4), Vector3(0.09, 1.9, -0.05), G(Color(1, 0.75, 0.2)))
	return k.done()


static func _slime() -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(0.78, 12, 7), Vector3(0, 0.5, 0), C_SLIME, Vector3.ZERO, Vector3(1.05, 0.72, 1.05))
	k.add(sph(0.4, 9, 5), Vector3(0.1, 0.5, 0.1), C_SLIME.darkened(0.25))
	k.add(sph(0.2, 8, 4), Vector3(-0.3, 0.88, -0.25), C_WHITE.lerp(C_SLIME, 0.3), Vector3.ZERO, Vector3(1, 0.5, 1))
	eyes(k, 0.72, -0.6, 0.22, 0.14)
	k.add(cyl(0.16, 0.16, 0.05, 10), Vector3(0, 0.48, -0.74), C_DARK, Vector3(80, 0, 0), Vector3(1, 1, 0.5))
	return k.done()


static func _nest() -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(1.0, 10, 5), Vector3(0, 0.6, 0), Color(0.27, 0.19, 0.24), Vector3.ZERO, Vector3(1, 1.2, 1))
	k.add(cone(0.85, 1.4, 8), Vector3(0, 1.9, 0), Color(0.22, 0.15, 0.2), Vector3(0, 0, 6))
	for i in 5:
		var a := TAU * i / 5.0 + 0.4
		k.add(sph(0.22, 7, 4), Vector3(cos(a) * 0.86, 0.8 + (i % 2) * 0.5, sin(a) * 0.86), G(Color(0.55, 0.15, 0.7)))
		k.add(box(0.08, 0.5, 0.08), Vector3(cos(a) * 1.0, 0.2, sin(a) * 1.0), C_BONE, Vector3(0, rad_to_deg(a), 35))
	k.add(sph(0.14, 6, 4), Vector3(0, 2.65, 0), G(Color(0.9, 0.3, 1.0)))
	return k.done()


static func _totem() -> ArrayMesh:
	var k := Kit.new()
	k.add(cyl(0.7, 0.8, 0.2, 8), Vector3(0, 0.1, 0), C_STONE.darkened(0.35))
	k.add(cyl(0.12, 0.16, 2.6, 6), Vector3(0, 1.3, 0), C_WOOD.darkened(0.35))
	for i in 3:
		k.add(sph(0.32, 9, 5), Vector3(0, 0.75 + i * 0.68, 0), C_BONE, Vector3(0, i * 35, 0), Vector3(1, 0.9, 1))
		k.add(box(0.3, 0.12, 0.2), Vector3(0, 0.6 + i * 0.68, -0.15), C_BONE.darkened(0.1))
		geyes(k, 0.8 + i * 0.68, -0.27, 0.11, 0.06, Color(0.3, 1.0, 0.7))
	for sx in [-1.0, 1.0]:
		k.add(box(0.06, 0.5, 0.15), Vector3(sx * 0.3, 2.55, 0), Color(0.8, 0.2, 0.25), Vector3(0, 0, sx * -25))
	k.add(box(1.3, 0.1, 0.1), Vector3(0, 2.35, 0), C_BONE, Vector3(0, 0, 8))
	return k.done()


static func _cultist() -> ArrayMesh:
	var k := Kit.new()
	var robe := Color(0.38, 0.09, 0.22)
	k.add(cyl(0.18, 0.46, 1.15, 8), Vector3(0, 0.58, 0), robe)
	k.add(cyl(0.47, 0.47, 0.06, 8), Vector3(0, 0.05, 0), C_GOLD.darkened(0.25))
	k.add(box(0.08, 0.9, 0.05), Vector3(0, 0.6, -0.25), C_GOLD.darkened(0.2), Vector3(-12, 0, 0))
	k.add(sph(0.3, 9, 5), Vector3(0, 1.28, 0), robe.darkened(0.1))
	k.add(cone(0.2, 0.45, 6), Vector3(0, 1.62, 0.1), robe.darkened(0.1), Vector3(25, 0, 0))
	k.add(sph(0.2, 8, 5), Vector3(0, 1.24, -0.15), C_DARK)
	geyes(k, 1.27, -0.32, 0.075, 0.05, Color(1.0, 0.3, 0.95))
	for sx in [-1.0, 1.0]:
		k.add(cyl(0.08, 0.12, 0.5, 6), Vector3(sx * 0.32, 0.95, -0.1), robe, Vector3(-40, 0, sx * 20))
	k.add(cyl(0.03, 0.03, 1.7, 5), Vector3(0.42, 0.85, -0.2), C_WOOD)
	k.add(sph(0.13, 4, 2), Vector3(0.42, 1.78, -0.2), G(Color(0.85, 0.3, 1.0)), Vector3.ZERO, Vector3(1, 1.6, 1))
	return k.done()


static func _ogre() -> ArrayMesh:
	var k := Kit.new()
	for sx in [-1.0, 1.0]:
		k.add(cyl(0.2, 0.24, 0.7, 7), Vector3(sx * 0.38, 0.35, 0), C_OGRE.darkened(0.2))
		k.add(cyl(0.18, 0.28, 1.0, 7), Vector3(sx * 1.05, 1.35, -0.1), C_OGRE, Vector3(-20, 0, sx * 20))
		k.add(sph(0.25, 7, 4), Vector3(sx * 1.25, 0.85, -0.3), C_OGRE.lightened(0.05))
	k.add(sph(0.95, 11, 6), Vector3(0, 1.35, 0), C_OGRE, Vector3.ZERO, Vector3(1.05, 0.95, 0.88))
	k.add(sph(0.65, 10, 5), Vector3(0, 1.15, -0.35), C_OGRE.lightened(0.12), Vector3.ZERO, Vector3(1, 0.9, 0.6))
	k.add(cyl(0.95, 1.0, 0.4, 9), Vector3(0, 0.8, 0), Color(0.42, 0.3, 0.18))
	k.add(sph(0.4, 9, 5), Vector3(0, 2.25, -0.3), C_OGRE.lightened(0.05))
	k.add(box(0.5, 0.18, 0.25), Vector3(0, 2.08, -0.55), C_OGRE.darkened(0.05))
	eyes(k, 2.33, -0.6, 0.14, 0.07, Color(0.5, 0.2, 0.0))
	for sx in [-1.0, 1.0]:
		k.add(cone(0.06, 0.22, 5), Vector3(sx * 0.15, 2.22, -0.68), C_WHITE)
	k.add(cyl(0.24, 0.1, 1.5, 7), Vector3(1.3, 1.25, -0.85), C_WOOD, Vector3(-70, 0, 0))
	for i in 4:
		k.add(cone(0.06, 0.18, 4), Vector3(1.3 + cos(i * 1.6) * 0.2, 1.0 + sin(i * 1.6) * 0.2, -1.45), C_STEEL, Vector3(-70, 0, i * 90))
	return k.done()


static func _mimic() -> ArrayMesh:
	var k := Kit.new()
	k.add(box(1.3, 0.7, 0.9), Vector3(0, 0.35, 0), C_WOOD)
	for x in [-0.6, 0.6]:
		k.add(box(0.1, 0.74, 0.94), Vector3(x, 0.35, 0), C_GOLD.darkened(0.25))
	k.add(box(1.36, 0.1, 0.96), Vector3(0, 0.12, 0), C_GOLD.darkened(0.3))
	k.add(box(1.3, 0.4, 0.9), Vector3(0, 1.0, 0.3), C_WOOD.lightened(0.1), Vector3(-38, 0, 0))
	k.add(box(1.0, 0.25, 0.5), Vector3(0, 0.66, 0.0), Color(0.4, 0.05, 0.12))
	for i in 7:
		k.add(cone(0.06, 0.22, 4), Vector3(-0.54 + i * 0.18, 0.78, -0.42), C_WHITE, Vector3(180, 0, 0))
		k.add(cone(0.05, 0.16, 4), Vector3(-0.48 + i * 0.16, 0.92, -0.32), C_WHITE, Vector3(-30, 0, 0))
	k.add(box(0.3, 0.06, 0.7), Vector3(0.1, 0.72, -0.6), Color(0.9, 0.25, 0.35), Vector3(15, 15, 0))
	k.add(box(0.22, 0.28, 0.06), Vector3(0, 0.45, -0.47), C_GOLD)
	geyes(k, 0.98, -0.12, 0.3, 0.08, Color(1, 0.3, 0.1))
	return k.done()


static func _ghost(col: Color) -> ArrayMesh:
	var k := Kit.new()
	k.add(sph(0.5, 11, 6), Vector3(0, 1.45, 0), col)
	k.add(cyl(0.5, 0.35, 0.7, 10), Vector3(0, 0.95, 0), col)
	for i in 5:
		var a := TAU * i / 5.0
		k.add(cone(0.18, 0.45, 5), Vector3(cos(a) * 0.3, 0.45, sin(a) * 0.3), col, Vector3(180, 0, 0))
	for sx in [-1.0, 1.0]:
		k.add(cyl(0.06, 0.12, 0.45, 6), Vector3(sx * 0.55, 1.2, -0.15), col, Vector3(-20, 0, sx * -55))
		k.add(sph(0.12, 6, 4), Vector3(sx * 0.17, 1.55, -0.42), C_DARK, Vector3.ZERO, Vector3(0.9, 1.4, 0.5))
	k.add(sph(0.14, 7, 4), Vector3(0, 1.28, -0.45), C_DARK, Vector3.ZERO, Vector3(1, 1.2, 0.4))
	return k.done()


static func _tower() -> ArrayMesh:
	var k := Kit.new()
	k.add(cyl(0.75, 0.95, 0.4, 7), Vector3(0, 0.2, 0), C_STONE.darkened(0.25))
	k.add(cyl(0.5, 0.65, 2.2, 7), Vector3(0, 1.5, 0), C_STONE)
	for i in 3:
		k.add(cyl(0.68 - i * 0.04, 0.68 - i * 0.04, 0.08, 7), Vector3(0, 0.8 + i * 0.6, 0), C_STONE.darkened(0.15))
	k.add(cyl(0.78, 0.62, 0.3, 7), Vector3(0, 2.7, 0), C_STONE.darkened(0.1))
	k.add(sph(0.45, 9, 5), Vector3(0, 3.2, 0.05), C_STONE.darkened(0.1), Vector3.ZERO, Vector3(1, 0.9, 1.1))
	k.add(sph(0.3, 8, 5), Vector3(0, 3.55, -0.25), C_STONE.darkened(0.05))
	k.add(box(0.2, 0.15, 0.3), Vector3(0, 3.45, -0.5), C_STONE.darkened(0.15))
	for sx in [-1.0, 1.0]:
		k.add(box(0.9, 0.06, 0.5), Vector3(sx * 0.6, 3.45, 0.15), C_STONE.darkened(0.3), Vector3(0, sx * -20, sx * -35))
		k.add(cone(0.07, 0.35, 4), Vector3(sx * 0.17, 3.85, -0.2), C_STONE.darkened(0.2), Vector3(-20, 0, sx * -20))
	geyes(k, 3.6, -0.5, 0.12, 0.06, Color(1, 0.45, 0.1))
	return k.done()


static func _werewolf() -> ArrayMesh:
	var k := Kit.new()
	for sx in [-1.0, 1.0]:
		k.add(cyl(0.12, 0.16, 0.75, 6), Vector3(sx * 0.22, 0.38, 0.12), C_FUR, Vector3(15, 0, 0))
		k.add(cyl(0.08, 0.14, 0.85, 6), Vector3(sx * 0.6, 1.0, -0.3), C_FUR, Vector3(-45, 0, sx * 15))
		for c in 3:
			k.add(cone(0.03, 0.14, 3), Vector3(sx * 0.62 + (c - 1) * 0.05, 0.62, -0.62), C_WHITE, Vector3(-120, 0, 0))
		k.add(cone(0.1, 0.32, 4), Vector3(sx * 0.18, 1.98, -0.42), C_FUR.darkened(0.1))
	k.add(sph(0.6, 10, 5), Vector3(0, 1.12, 0), C_FUR, Vector3(-25, 0, 0), Vector3(1, 1.2, 0.9))
	k.add(sph(0.38, 8, 4), Vector3(0, 1.05, -0.35), C_FUR.lightened(0.18), Vector3(-25, 0, 0), Vector3(0.9, 1, 0.5))
	k.add(sph(0.33, 9, 5), Vector3(0, 1.65, -0.45), C_FUR.lightened(0.05))
	k.add(box(0.22, 0.2, 0.42), Vector3(0, 1.55, -0.78), C_FUR.lightened(0.15))
	k.add(sph(0.05, 5, 3), Vector3(0, 1.62, -1.0), C_DARK)
	for sx in [-1.0, 1.0]:
		k.add(cone(0.025, 0.09, 3), Vector3(sx * 0.07, 1.43, -0.92), C_WHITE, Vector3(180, 0, 0))
	geyes(k, 1.74, -0.72, 0.13, 0.055, Color(1, 0.85, 0.1))
	k.add(box(0.7, 0.3, 0.5), Vector3(0, 0.75, 0.1), Color(0.3, 0.32, 0.5))
	return k.done()


static func _golem() -> ArrayMesh:
	var k := Kit.new()
	for sx in [-1.0, 1.0]:
		k.add(box(0.42, 0.75, 0.42), Vector3(sx * 0.36, 0.38, 0), C_RUST.darkened(0.2))
		k.add(box(0.42, 1.05, 0.42), Vector3(sx * 1.0, 1.15, 0), C_STEEL.darkened(0.4), Vector3(0, 0, sx * -10))
		k.add(box(0.55, 0.4, 0.55), Vector3(sx * 1.08, 0.55, -0.05), C_RUST.darkened(0.1))
		k.add(cyl(0.3, 0.3, 0.12, 8), Vector3(sx * 0.82, 1.75, 0), C_STEEL.darkened(0.3), Vector3(0, 0, 90))
	k.add(box(1.35, 1.15, 0.95), Vector3(0, 1.28, 0), C_RUST, Vector3(0, 0, 3))
	k.add(box(1.0, 0.25, 0.97), Vector3(0, 1.5, 0), C_RUST.darkened(0.2))
	k.add(cyl(0.22, 0.22, 0.1, 8), Vector3(0, 1.2, -0.5), G(Color(0.3, 0.9, 1.0)), Vector3(90, 0, 0))
	k.add(box(0.65, 0.52, 0.58), Vector3(0, 2.1, -0.1), C_RUST.lightened(0.06))
	k.add(box(0.45, 0.09, 0.06), Vector3(0, 2.15, -0.41), G(Color(0.3, 0.9, 1.0)))
	for i in 5:
		k.add(sph(0.06, 4, 2), Vector3(-0.5 + i * 0.25, 1.75, -0.48), C_STEEL)
	k.add(cyl(0.05, 0.05, 0.7, 4), Vector3(0.25, 2.6, 0.2), C_STEEL.darkened(0.3), Vector3(0, 0, 20))
	return k.done()


# ---------------------------------------------------------------- herói (peças articuladas) e chefe

## Peças do herói com a origem na articulação: "torso", "head", "leg", "arm_sword", "arm_shield", "cape".
static func hero_part(id: String) -> ArrayMesh:
	if _cache.has("h_" + id):
		return _cache["h_" + id]
	var k := Kit.new()
	var blue := Color(0.2, 0.38, 0.85)
	match id:
		"torso":
			k.add(cyl(0.34, 0.3, 0.7, 9), Vector3(0, 0.35, 0), C_STEEL, Vector3.ZERO, Vector3(1, 1, 0.75))
			k.add(box(0.5, 0.45, 0.06), Vector3(0, 0.38, -0.22), blue)
			k.add(box(0.1, 0.4, 0.07), Vector3(0, 0.38, -0.25), C_GOLD)
			k.add(box(0.36, 0.1, 0.07), Vector3(0, 0.45, -0.25), C_GOLD)
			k.add(cyl(0.36, 0.36, 0.12, 9), Vector3(0, 0.0, 0), C_WOOD, Vector3.ZERO, Vector3(1, 1, 0.8))
			k.add(box(0.1, 0.1, 0.05), Vector3(0, 0.0, -0.3), C_GOLD)
			for sx in [-1.0, 1.0]:
				k.add(sph(0.2, 8, 5), Vector3(sx * 0.4, 0.6, 0), C_STEEL.lightened(0.1), Vector3.ZERO, Vector3(1, 0.8, 1))
				k.add(cone(0.06, 0.18, 4), Vector3(sx * 0.42, 0.78, 0), C_GOLD)
		"head":
			k.add(sph(0.34, 10, 6), Vector3(0, 0.3, 0), C_STEEL.lightened(0.12))
			k.add(cyl(0.35, 0.35, 0.12, 10), Vector3(0, 0.2, 0), C_STEEL.lightened(0.05))
			k.add(box(0.46, 0.07, 0.05), Vector3(0, 0.3, -0.33), C_DARK)
			k.add(box(0.05, 0.25, 0.05), Vector3(0, 0.22, -0.34), C_DARK)
			geyes(k, 0.3, -0.33, 0.1, 0.035, Color(0.6, 0.9, 1.0))
			k.add(box(0.07, 0.25, 0.08), Vector3(0, 0.65, 0), C_GOLD)
			for i in 4:
				k.add(sph(0.1, 6, 4), Vector3(0, 0.75 - i * 0.03, 0.08 + i * 0.12), Color(0.95, 0.15, 0.15), Vector3.ZERO, Vector3(0.6, 1, 1.3))
		"leg":
			k.add(cyl(0.11, 0.13, 0.5, 7), Vector3(0, -0.25, 0), C_STEEL.darkened(0.25))
			k.add(sph(0.12, 6, 4), Vector3(0, -0.28, -0.08), C_STEEL)
			k.add(box(0.22, 0.14, 0.32), Vector3(0, -0.6, -0.05), C_WOOD.darkened(0.25))
		"arm_sword":
			k.add(cyl(0.09, 0.11, 0.5, 7), Vector3(0, -0.25, 0), C_STEEL.darkened(0.1))
			k.add(sph(0.12, 6, 4), Vector3(0, -0.52, 0), C_WOOD.darkened(0.2))
			k.add(cyl(0.04, 0.04, 0.3, 5), Vector3(0, -0.55, 0.0), C_WOOD, Vector3(90, 0, 0))
			k.add(box(0.36, 0.06, 0.08), Vector3(0, -0.55, -0.15), C_GOLD)
			k.add(box(0.12, 0.035, 1.25), Vector3(0, -0.55, -0.8), Color(0.9, 0.94, 1.0, 0.75))
			k.add(cone(0.06, 0.15, 4), Vector3(0, -0.55, -1.48), Color(0.9, 0.94, 1.0, 0.75), Vector3(-90, 0, 0), Vector3(1, 1, 0.3))
		"arm_shield":
			k.add(cyl(0.09, 0.11, 0.5, 7), Vector3(0, -0.25, 0), C_STEEL.darkened(0.1))
			k.add(cyl(0.38, 0.32, 0.08, 10), Vector3(0, -0.35, -0.2), blue, Vector3(90, 0, 0), Vector3(1, 1, 1.25))
			k.add(cyl(0.4, 0.34, 0.05, 10), Vector3(0, -0.35, -0.17), C_GOLD, Vector3(90, 0, 0), Vector3(1, 1, 1.25))
			k.add(box(0.08, 0.6, 0.06), Vector3(0, -0.35, -0.26), C_GOLD)
			k.add(box(0.4, 0.08, 0.06), Vector3(0, -0.25, -0.26), C_GOLD)
		"cape":
			k.add(box(0.62, 1.05, 0.05), Vector3(0, -0.52, 0), Color(0.6, 0.1, 0.18))
			k.add(box(0.66, 0.06, 0.08), Vector3(0, -1.04, 0), C_GOLD.darkened(0.2))
	var m := k.done()
	_cache["h_" + id] = m
	return m


static func boss_part(id: String) -> ArrayMesh:
	# Direção com chefe próprio (Blender v2): mesmas partes, mesma origem e tamanho (tools/art/blender_v2/boss.py).
	if has_dir_prop("boss_" + id):
		return prop("boss_" + id)
	var k := Kit.new()
	var robe := Color(0.2, 0.08, 0.28)
	match id:
		"core":
			k.add(cyl(0.9, 1.7, 3.2, 10), Vector3(0, 1.6, 0), robe)
			k.add(cyl(1.72, 1.72, 0.12, 10), Vector3(0, 0.06, 0), C_GOLD.darkened(0.3))
			k.add(box(1.9, 1.1, 1.2), Vector3(0, 3.0, 0), robe.lightened(0.08))
			k.add(box(1.5, 0.9, 0.2), Vector3(0, 2.95, -0.58), C_DARK.lightened(0.1))
			k.add(sph(0.48, 10, 6), Vector3(0, 2.6, -0.68), G(Color(0.85, 0.2, 1.0)))
			k.add(cyl(0.65, 0.65, 0.12, 10), Vector3(0, 2.6, -0.62), C_GOLD, Vector3(90, 0, 0))
			for i in 4:
				k.add(sph(0.18, 7, 4), Vector3(-0.75 + i * 0.5, 1.75, -1.05), C_BONE)
			k.add(cyl(1.15, 1.15, 0.15, 10), Vector3(0, 1.75, 0), C_DARK, Vector3.ZERO, Vector3(1, 1, 0.95))
			for sx in [-1.0, 1.0]:
				k.add(sph(0.55, 8, 4), Vector3(sx * 1.1, 3.5, 0), C_DARK.lightened(0.15), Vector3.ZERO, Vector3(1, 0.7, 1))
				for i in 3:
					k.add(cone(0.12, 0.6, 5), Vector3(sx * (0.9 + i * 0.25), 3.85, -0.1 + i * 0.1), C_BONE, Vector3(0, 0, -sx * 25))
		"head":
			k.add(sph(0.62, 10, 6), Vector3(0, 0, 0), Color(0.55, 0.5, 0.6))
			k.add(box(0.6, 0.35, 0.3), Vector3(0, -0.4, -0.25), Color(0.5, 0.45, 0.55))
			for sx in [-1.0, 1.0]:
				k.add(sph(0.17, 7, 4), Vector3(sx * 0.22, 0.05, -0.5), C_DARK)
				k.add(sph(0.08, 6, 4), Vector3(sx * 0.22, 0.05, -0.62), G(Color(1.0, 0.25, 0.1)))
				k.add(cone(0.2, 1.1, 6), Vector3(sx * 0.5, 0.65, 0), C_DARK, Vector3(0, 0, sx * -30))
			for i in 5:
				k.add(box(0.07, 0.12, 0.05), Vector3(-0.2 + i * 0.1, -0.5, -0.42), C_WHITE)
			k.add(cyl(0.52, 0.45, 0.28, 10), Vector3(0, 0.55, 0), C_GOLD)
			for i in 6:
				var a := TAU * i / 6.0
				k.add(cone(0.08, 0.35, 4), Vector3(cos(a) * 0.46, 0.82, sin(a) * 0.46), C_GOLD)
				k.add(sph(0.05, 5, 3), Vector3(cos(a) * 0.5, 0.55, sin(a) * 0.5), G(Color(0.9, 0.2, 1.0)))
		"left_arm":
			k.add(sph(0.45, 9, 5), Vector3(0, 0.9, 0), C_DARK.lightened(0.12))
			k.add(cyl(0.25, 0.32, 1.7, 8), Vector3(0, 0, 0), robe.lightened(0.06), Vector3(0, 0, 15))
			k.add(sph(0.22, 7, 4), Vector3(0.2, -0.95, -0.15), Color(0.55, 0.5, 0.6))
			k.add(sph(0.42, 9, 5), Vector3(0.25, -1.35, -0.35), G(Color(0.3, 0.55, 1.0)))
		"right_arm":
			k.add(sph(0.45, 9, 5), Vector3(0, 0.9, 0), C_DARK.lightened(0.12))
			k.add(cyl(0.25, 0.32, 1.7, 8), Vector3(0, 0, 0), robe.lightened(0.06), Vector3(0, 0, -15))
			k.add(sph(0.24, 7, 4), Vector3(-0.2, -0.95, -0.15), Color(0.55, 0.5, 0.6))
			for i in 3:
				k.add(cone(0.09, 0.8, 4), Vector3(-0.35 + i * 0.18, -1.45, -0.25), G(Color(1.0, 0.35, 0.2)), Vector3(165, 0, 0))
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

## A direção de arte atual tem uma peça própria com esse id (ex.: o piso "arena" do Blender v2)?
static func has_dir_prop(id: String) -> bool:
	var pd: String = GroundLooks.preset().get("props_dir", "")
	return pd != "" and pd != "cc0" and ResourceLoader.exists("res://assets/models/%s/%s.res" % [pd, id])


static func prop(id: String) -> ArrayMesh:
	if Looks.g_on():
		var gm := Looks.g_mesh(id)
		if gm is ArrayMesh:
			return gm
	# Direção com cenário próprio (look de chão com "props_dir", ex.: Blender v2): a peça de lá, se existir.
	var pd: String = GroundLooks.preset().get("props_dir", "")
	if pd != "" and pd != "cc0":
		var key := "pd_%s_%s" % [pd, id]
		if not _cache.has(key):
			var p := "res://assets/models/%s/%s.res" % [pd, id]
			_cache[key] = load(p) if ResourceLoader.exists(p) else null
		if _cache[key]:
			return _cache[key]
	if _cache.has("p_" + id):
		return _cache["p_" + id]
	var k := Kit.new()
	match id:
		"tree":
			k.add(cyl(0.16, 0.26, 1.4, 6), Vector3(0, 0.7, 0), C_WOOD.darkened(0.3))
			for i in 4:
				var r := 1.5 - i * 0.32
				k.add(cone(r, 1.3, 7), Vector3(0, 1.7 + i * 0.85, 0), C_LEAF.lerp(C_LEAF2, i * 0.3), Vector3(0, i * 25, 0))
		"tree_round":
			k.add(cyl(0.18, 0.3, 1.8, 6), Vector3(0, 0.9, 0), C_WOOD.darkened(0.2))
			k.add(cyl(0.06, 0.1, 0.9, 5), Vector3(0.4, 1.7, 0), C_WOOD.darkened(0.2), Vector3(0, 0, -40))
			k.add(sph(1.25, 8, 5), Vector3(0, 2.9, 0), Color(0.24, 0.32, 0.42))
			k.add(sph(0.85, 8, 5), Vector3(0.8, 2.6, 0.3), Color(0.28, 0.36, 0.46))
			k.add(sph(0.8, 8, 5), Vector3(-0.7, 2.5, -0.3), Color(0.22, 0.3, 0.4))
		"bush":
			for i in 3:
				k.add(sph(0.55 - i * 0.1, 7, 4), Vector3((i - 1) * 0.45, 0.35, (i % 2) * 0.25), C_LEAF2.darkened(0.1 * i))
			k.add(sph(0.08, 5, 3), Vector3(0.2, 0.75, -0.3), G(Color(0.9, 0.3, 0.5)))
		"flowers":
			for i in 5:
				var a := i * 1.3
				k.add(cyl(0.015, 0.015, 0.35, 3), Vector3(cos(a) * 0.25, 0.17, sin(a) * 0.25), Color(0.25, 0.5, 0.3))
				k.add(sph(0.07, 5, 3), Vector3(cos(a) * 0.25, 0.37, sin(a) * 0.25), G(Color(0.5, 0.7, 1.0) if i % 2 == 0 else Color(0.95, 0.5, 1.0)))
		"gravestone":
			k.add(box(0.7, 1.0, 0.18), Vector3(0, 0.5, 0), C_STONE.darkened(0.1), Vector3(0, 0, 6))
			k.add(cyl(0.35, 0.35, 0.18, 8), Vector3(-0.05, 1.0, 0), C_STONE.darkened(0.1), Vector3(90, 0, 6))
			k.add(box(0.9, 0.12, 0.5), Vector3(0, 0.05, 0.2), C_STONE.darkened(0.3))
			k.add(box(0.3, 0.06, 0.04), Vector3(0, 0.75, -0.1), C_DARK)
		"fence":
			for x in [-1.0, 0.0, 1.0]:
				k.add(box(0.12, 1.0, 0.12), Vector3(x, 0.5, 0), C_WOOD.darkened(0.35))
				k.add(cone(0.08, 0.15, 4), Vector3(x, 1.07, 0), C_WOOD.darkened(0.35))
			k.add(box(2.2, 0.1, 0.06), Vector3(0, 0.75, 0), C_WOOD.darkened(0.25), Vector3(0, 0, 4))
			k.add(box(2.2, 0.1, 0.06), Vector3(0, 0.35, 0), C_WOOD.darkened(0.25), Vector3(0, 0, -3))
		"lantern":
			k.add(cyl(0.07, 0.1, 2.4, 6), Vector3(0, 1.2, 0), C_DARK.lightened(0.15))
			k.add(box(0.6, 0.06, 0.06), Vector3(0.25, 2.35, 0), C_DARK.lightened(0.15))
			k.add(cyl(0.12, 0.16, 0.3, 6), Vector3(0.5, 2.15, 0), G(Color(1.0, 0.7, 0.3)))
			k.add(cone(0.18, 0.15, 6), Vector3(0.5, 2.35, 0), C_DARK.lightened(0.2))
		"road_stone":
			k.add(sph(0.3, 5, 3), Vector3(0, 0.08, 0), C_STONE.darkened(0.2), Vector3(0, 30, 0), Vector3(1.4, 0.4, 1))
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
			k.add(sph(0.18, 6, 3), Vector3(0, 0.32, 0), G(Color(0.3, 0.9, 1.0)), Vector3.ZERO, Vector3(1, 0.5, 1))
		"house":
			k.add(box(3.0, 2.0, 2.6), Vector3(0, 1.0, 0), Color(0.55, 0.45, 0.35))
			k.add(cyl(0.0, 2.3, 1.6, 4), Vector3(0, 2.8, 0), Color(0.5, 0.18, 0.15), Vector3(0, 45, 0), Vector3(1.0, 1, 0.85))
			k.add(box(0.7, 1.2, 0.1), Vector3(0, 0.6, -1.32), C_WOOD.darkened(0.3))
			k.add(box(0.5, 0.5, 0.1), Vector3(-0.9, 1.3, -1.32), G(Color(1.0, 0.8, 0.4)))
			k.add(box(0.5, 0.5, 0.1), Vector3(0.9, 1.3, -1.32), G(Color(1.0, 0.8, 0.4)))
		"tavern":
			k.add(box(4.0, 2.6, 3.0), Vector3(0, 1.3, 0), Color(0.45, 0.32, 0.22))
			k.add(cyl(0.0, 3.0, 1.8, 4), Vector3(0, 3.5, 0), Color(0.3, 0.2, 0.15), Vector3(0, 45, 0), Vector3(1.0, 1, 0.75))
			k.add(box(1.2, 0.7, 0.1), Vector3(1.4, 2.0, -1.8), C_GOLD.darkened(0.2))
			k.add(cyl(0.3, 0.3, 0.6, 7), Vector3(-1.3, 0.3, -1.9), C_WOOD, Vector3(0, 0, 90))
			for x in [-1.0, 0.0, 1.0]:
				k.add(box(0.5, 0.5, 0.1), Vector3(x, 1.4, -1.52), G(Color(1.0, 0.75, 0.35)))
		"fountain":
			k.add(cyl(2.2, 2.4, 0.6, 10), Vector3(0, 0.3, 0), C_STONE)
			k.add(cyl(1.9, 1.9, 0.1, 10), Vector3(0, 0.58, 0), G(Color(0.3, 0.7, 1.0)))
			k.add(cyl(0.3, 0.4, 1.8, 7), Vector3(0, 1.2, 0), C_STONE.lightened(0.1))
			k.add(cyl(0.8, 0.5, 0.3, 8), Vector3(0, 2.1, 0), C_STONE.lightened(0.1))
			k.add(sph(0.3, 6, 3), Vector3(0, 2.5, 0), Color(0.5, 0.85, 1.0))
		"ritual":
			var tm := TorusMesh.new()
			tm.inner_radius = 4.6
			tm.outer_radius = 5.0
			tm.rings = 24
			tm.ring_segments = 4
			k.add(tm, Vector3(0, 0.05, 0), G(Color(0.8, 0.25, 1.0)), Vector3.ZERO, Vector3(1, 0.2, 1))
			for i in 5:
				var a := TAU * i / 5.0
				k.add(cyl(0.12, 0.15, 0.5, 5), Vector3(cos(a) * 4.0, 0.25, sin(a) * 4.0), Color(0.9, 0.85, 0.7))
				k.add(sph(0.1, 4, 2), Vector3(cos(a) * 4.0, 0.6, sin(a) * 4.0), G(Color(1.0, 0.6, 0.2)))
				var b := TAU * (i + 2) / 5.0
				var p0 := Vector3(cos(a), 0, sin(a)) * 4.4
				var p1 := Vector3(cos(b), 0, sin(b)) * 4.4
				var mid := (p0 + p1) * 0.5
				k.add(box(0.12, 0.04, p0.distance_to(p1)), mid + Vector3(0, 0.04, 0), Color(0.8, 0.25, 1.0), Vector3(0, rad_to_deg(atan2(p1.x - p0.x, p1.z - p0.z)), 0))
		"shrine":
			k.add(cyl(1.4, 1.6, 0.4, 6), Vector3(0, 0.2, 0), C_STONE.darkened(0.1))
			k.add(cyl(0.3, 0.55, 3.0, 4), Vector3(0, 1.9, 0), C_STONE.lightened(0.05))
			k.add(sph(0.45, 4, 2), Vector3(0, 3.8, 0), G(Color(0.3, 1.0, 0.6)), Vector3.ZERO, Vector3(1, 1.6, 1))
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
				k.add(box(0.6, 1.0, 0.2), Vector3(-6.5 + i * 2.6, 5.0, -2.05), G(Color(1.0, 0.5, 0.9)))
			for i in 8:
				k.add(box(1.2, 1.0, 4.2), Vector3(-7.0 + i * 2.0, 7.5, 0), Color(0.22, 0.17, 0.28))
		"pillar":
			k.add(cyl(0.7, 0.8, 0.4, 6), Vector3(0, 0.2, 0), C_STONE.darkened(0.2))
			k.add(cyl(0.5, 0.55, 4.0, 6), Vector3(0, 2.4, 0), C_STONE.darkened(0.05))
			k.add(cyl(0.75, 0.6, 0.4, 6), Vector3(0, 4.5, 0), C_STONE.darkened(0.2))
		"gate":
			# Portão de passagem (fim de ato): dois pilares, verga com ameias e um selo que brilha no centro.
			for sx in [-4.6, 4.6]:
				k.add(box(2.0, 0.5, 2.0), Vector3(sx, 0.25, 0), C_STONE.darkened(0.3))
				k.add(box(1.5, 6.0, 1.5), Vector3(sx, 3.4, 0), C_STONE.darkened(0.08))
				k.add(box(2.0, 0.5, 2.0), Vector3(sx, 6.65, 0), C_STONE.darkened(0.25))
				k.add(cone(0.9, 1.4, 4), Vector3(sx, 7.6, 0), C_STONE.darkened(0.3), Vector3(0, 45, 0))
			k.add(box(11.0, 1.3, 1.7), Vector3(0, 6.3, 0), C_STONE.darkened(0.15))
			for i in 5:
				k.add(box(1.2, 0.7, 1.7), Vector3(-4.0 + i * 2.0, 7.3, 0), C_STONE.darkened(0.22))
			k.add(sph(0.38, 6, 3), Vector3(0, 6.3, -0.9), G(Color(1.0, 0.75, 0.3)), Vector3.ZERO, Vector3(1, 1.4, 0.5))
		"brazier":
			k.add(cyl(0.12, 0.2, 1.4, 5), Vector3(0, 0.7, 0), C_DARK.lightened(0.1))
			k.add(cyl(0.6, 0.3, 0.4, 7), Vector3(0, 1.5, 0), C_DARK.lightened(0.15))
			k.add(cone(0.4, 0.8, 5), Vector3(0, 2.0, 0), G(Color(1.0, 0.55, 0.15)))
		"altar":
			k.add(cyl(1.1, 1.3, 0.5, 6), Vector3(0, 0.25, 0), C_STONE.darkened(0.3))
			k.add(cyl(0.8, 0.9, 0.3, 6), Vector3(0, 0.65, 0), C_STONE.darkened(0.15))
			var tm2 := TorusMesh.new()
			tm2.inner_radius = 0.9
			tm2.outer_radius = 1.05
			tm2.rings = 16
			tm2.ring_segments = 4
			k.add(tm2, Vector3(0, 0.85, 0), G(Color(0.6, 0.3, 1.0)), Vector3.ZERO, Vector3(1, 0.3, 1))
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

static func tor(inner: float, outer: float, rings := 24, sides := 6) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = rings
	m.ring_segments = sides
	return m


## Modelo do retrato das cartas sem unidade (feitiços, rota, covil, finalizações). Só a arte das cartas usa.
## G(cor) = parte que brilha.
static func icon(id: String) -> ArrayMesh:
	id = CardModel.of(id)
	var k := Kit.new()
	match id:
		"shadow_bolt":
			# Raio em zigue-zague saindo de uma esfera escura, com faíscas.
			k.add(sph(0.32, 8, 5), Vector3(-0.1, 1.75, 0), C_DARK.lightened(0.15))
			k.add(sph(0.2, 6, 4), Vector3(-0.1, 1.75, -0.18), G(Color(0.75, 0.35, 1.0)))
			var pts := [Vector3(-0.1, 1.6, 0), Vector3(0.35, 1.15, 0), Vector3(-0.2, 0.75, 0), Vector3(0.25, 0.2, 0)]
			for n in 3:
				var a: Vector3 = pts[n]
				var b: Vector3 = pts[n + 1]
				var d := b - a
				var ang := rad_to_deg(atan2(-d.x, d.y))
				k.add(box(0.16, d.length() + 0.12, 0.16), (a + b) * 0.5, G(Color(0.7, 0.3, 1.0)), Vector3(0, 0, ang))
				k.add(box(0.07, d.length() + 0.14, 0.2), (a + b) * 0.5, G(Color(0.95, 0.8, 1.0)), Vector3(0, 0, ang))
			for n in 5:
				k.add(sph(0.05, 4, 3), Vector3(0.45 * cos(n * 1.7), 0.2 + 0.08 * n, 0.3 * sin(n * 1.7)), G(Color(0.85, 0.6, 1.0)))
		"web":
			for i in 4:
				k.add(box(1.8, 0.04, 0.04), Vector3(0, 0.9, 0), Color(0.92, 0.92, 0.95), Vector3(0, 0, i * 45.0))
			for r in [0.3, 0.55, 0.8]:
				k.add(tor(r, r + 0.035, 8, 3), Vector3(0, 0.9, 0), Color(0.88, 0.88, 0.94), Vector3(90, 22.5, 0))
			# Aranha no centro.
			k.add(sph(0.2, 8, 5), Vector3(0.05, 0.75, -0.1), C_DARK.lightened(0.1), Vector3.ZERO, Vector3(1, 1.2, 0.9))
			k.add(sph(0.12, 6, 4), Vector3(0.05, 1.0, -0.14), C_DARK.lightened(0.15))
			geyes(k, 1.03, -0.24, 0.05, 0.035, Color(1.0, 0.2, 0.15))
			for sx in [-1.0, 1.0]:
				for n in 4:
					k.add(cyl(0.02, 0.02, 0.5, 4), Vector3(0.05 + sx * 0.25, 0.92 - n * 0.09, -0.12), C_DARK.lightened(0.2), Vector3(0, 0, sx * (70 - n * 22)))
		"boiling_oil":
			# Caldeirão em três pés sobre o fogo, óleo em brasa e bolhas.
			k.add(sph(0.6, 10, 6), Vector3(0, 0.75, 0), C_DARK.lightened(0.18), Vector3.ZERO, Vector3(1, 0.8, 1))
			k.add(tor(0.52, 0.62, 16, 5), Vector3(0, 1.15, 0), C_DARK.lightened(0.3))
			k.add(cyl(0.52, 0.52, 0.04, 12), Vector3(0, 1.13, 0), G(Color(1.0, 0.5, 0.08)))
			for i in 3:
				var a := TAU * i / 3.0
				k.add(cyl(0.05, 0.04, 0.5, 4), Vector3(cos(a) * 0.4, 0.22, sin(a) * 0.4), C_DARK.lightened(0.25))
				k.add(sph(0.11, 5, 3), Vector3(cos(a + 0.6) * 0.25, 1.25 + 0.06 * i, sin(a + 0.6) * 0.25), G(Color(1.0, 0.75, 0.25)))
			for i in 4:
				k.add(cone(0.16, 0.45, 5), Vector3(-0.3 + i * 0.2, 0.2, 0.05 * (i % 2)), G(Color(1.0, 0.45 + 0.1 * i, 0.1)))
		"soul_feast":
			# Taça dourada com três almas subindo.
			k.add(cyl(0.3, 0.42, 0.12, 10), Vector3(0, 0.06, 0), C_GOLD.darkened(0.35))
			k.add(cyl(0.08, 0.12, 0.45, 6), Vector3(0, 0.33, 0), C_GOLD.darkened(0.25))
			k.add(cyl(0.6, 0.25, 0.35, 10), Vector3(0, 0.72, 0), C_GOLD.darkened(0.1))
			k.add(cyl(0.55, 0.55, 0.03, 10), Vector3(0, 0.88, 0), G(Color(0.4, 1.0, 0.85)))
			for i in 3:
				var x := -0.32 + i * 0.32
				k.add(sph(0.17, 7, 4), Vector3(x, 1.25 + 0.2 * (i % 2), 0), G(Color(0.55, 1.0, 0.9)))
				k.add(cone(0.12, 0.4, 5), Vector3(x, 0.98 + 0.2 * (i % 2), 0), G(Color(0.4, 0.9, 0.85)), Vector3(180, 0, 0))
		"gold_bait":
			return prop("coins")
		"burn_village":
			k.add(box(0.9, 0.6, 0.8), Vector3(0, 0.3, 0), Color(0.36, 0.26, 0.2))
			k.add(cyl(0.0, 0.75, 0.55, 4), Vector3(0, 0.88, 0), Color(0.3, 0.16, 0.12), Vector3(0, 45, 0))
			k.add(box(0.2, 0.3, 0.05), Vector3(0, 0.15, -0.41), G(Color(1.0, 0.55, 0.15)))
			for i in 5:
				k.add(cone(0.22 - i * 0.02, 0.8 - i * 0.08, 5), Vector3(-0.4 + i * 0.2, 1.1 + 0.08 * (i % 2), 0.05 * (i % 3)), G(Color(1.0, 0.4 + 0.1 * i, 0.08)))
			for i in 4:
				k.add(sph(0.04, 4, 3), Vector3(-0.3 + i * 0.25, 1.75 + 0.12 * (i % 2), 0), G(Color(1.0, 0.7, 0.3)))
		"soul_collector":
			# Lanterna de almas: base e teto de ouro, gaiola, alma acesa dentro.
			k.add(cyl(0.45, 0.5, 0.15, 8), Vector3(0, 0.08, 0), C_GOLD.darkened(0.3))
			k.add(cyl(0.38, 0.42, 0.1, 8), Vector3(0, 0.2, 0), C_GOLD.darkened(0.1))
			k.add(cyl(0.4, 0.4, 0.1, 8), Vector3(0, 1.2, 0), C_GOLD.darkened(0.1))
			k.add(cone(0.42, 0.4, 8), Vector3(0, 1.45, 0), C_GOLD.darkened(0.25))
			k.add(tor(0.08, 0.13, 10, 4), Vector3(0, 1.72, 0), C_GOLD, Vector3(90, 0, 0))
			for i in 8:
				var a := TAU * i / 8.0
				k.add(cyl(0.025, 0.025, 1.0, 4), Vector3(cos(a) * 0.36, 0.7, sin(a) * 0.36), C_GOLD.darkened(0.2))
			k.add(sph(0.24, 8, 5), Vector3(0, 0.7, 0), G(Color(0.55, 1.0, 1.0)), Vector3.ZERO, Vector3(1, 1.3, 1))
			k.add(cone(0.14, 0.4, 6), Vector3(0, 1.02, 0), G(Color(0.8, 1.0, 1.0)))
		"forbidden_library":
			# Atril com o livro aberto e acorrentado, runas flutuando e uma vela.
			k.add(box(0.35, 0.7, 0.35), Vector3(0, 0.35, 0), C_WOOD.darkened(0.3))
			k.add(box(1.0, 0.08, 0.7), Vector3(0, 0.78, 0), C_WOOD.darkened(0.2), Vector3(-20, 0, 0))
			for sx in [-1.0, 1.0]:
				k.add(box(0.48, 0.06, 0.62), Vector3(sx * 0.25, 0.86, 0), Color(0.5, 0.08, 0.14), Vector3(-20, 0, sx * -6))
				k.add(box(0.44, 0.05, 0.56), Vector3(sx * 0.24, 0.9, 0), C_WHITE.darkened(0.08), Vector3(-20, 0, sx * -10))
			for i in 5:
				k.add(tor(0.05, 0.08, 8, 4), Vector3(-0.55 + i * 0.07, 0.75 - i * 0.12, -0.2), Color(0.55, 0.55, 0.6), Vector3(90 * (i % 2), 0, 30))
			for i in 4:
				k.add(box(0.1, 0.1, 0.02), Vector3(-0.3 + i * 0.2, 1.25 + 0.12 * (i % 2), 0), G(Color(0.6, 0.4, 1.0)), Vector3(0, 0, 45))
			k.add(cyl(0.06, 0.06, 0.25, 6), Vector3(0.62, 0.9, 0.1), C_WHITE)
			k.add(cone(0.05, 0.14, 5), Vector3(0.62, 1.09, 0.1), G(Color(1.0, 0.8, 0.3)))
		"dark_forge":
			# Bigorna com metal em brasa e martelo, faíscas.
			k.add(box(0.6, 0.15, 0.5), Vector3(0, 0.08, 0), C_DARK.lightened(0.18))
			k.add(box(0.35, 0.45, 0.32), Vector3(0, 0.38, 0), C_DARK.lightened(0.24))
			k.add(box(1.0, 0.25, 0.45), Vector3(0.05, 0.72, 0), C_STEEL.darkened(0.45))
			k.add(cone(0.22, 0.5, 6), Vector3(-0.68, 0.72, 0), C_STEEL.darkened(0.45), Vector3(0, 0, 90))
			k.add(box(0.45, 0.08, 0.16), Vector3(0.1, 0.89, 0), G(Color(1.0, 0.45, 0.1)))
			k.add(cyl(0.035, 0.04, 0.9, 5), Vector3(0.55, 1.15, 0.1), C_WOOD, Vector3(0, 0, -50))
			k.add(box(0.36, 0.2, 0.2), Vector3(0.22, 1.42, 0.1), C_STEEL.darkened(0.3), Vector3(0, 0, -50))
			for i in 6:
				k.add(sph(0.035, 4, 3), Vector3(-0.1 + 0.12 * i, 1.0 + 0.1 * (i % 3), -0.1 + 0.05 * (i % 2)), G(Color(1.0, 0.7, 0.25)))
		"lair_walls":
			k.add(box(1.6, 0.85, 0.45), Vector3(0, 0.43, 0), Color(0.3, 0.25, 0.36))
			for i in 5:
				k.add(box(0.2, 0.2, 0.45), Vector3(-0.7 + i * 0.35, 0.95, 0), Color(0.33, 0.27, 0.4))
			for sx in [-1.0, 1.0]:
				k.add(cyl(0.3, 0.33, 1.3, 8), Vector3(sx * 0.95, 0.65, 0), Color(0.28, 0.23, 0.34))
				k.add(cone(0.38, 0.6, 8), Vector3(sx * 0.95, 1.6, 0), Color(0.42, 0.12, 0.2))
				k.add(cone(0.06, 0.18, 5), Vector3(sx * 0.55, 0.85, -0.3), G(Color(1.0, 0.6, 0.2)))
			k.add(box(0.45, 0.6, 0.06), Vector3(0, 0.3, -0.24), Color(0.08, 0.05, 0.08))
			k.add(sph(0.23, 8, 4), Vector3(0, 0.6, -0.24), Color(0.08, 0.05, 0.08), Vector3.ZERO, Vector3(1, 0.6, 0.2))
		"cosmic_ray":
			k.add(sph(0.38, 10, 6), Vector3(-0.55, 1.6, 0), G(Color(1.0, 0.9, 0.5)))
			k.add(tor(0.5, 0.56, 24, 4), Vector3(-0.55, 1.6, 0), G(Color(1.0, 0.75, 0.35)), Vector3(70, 0, 20))
			k.add(cyl(0.16, 0.16, 1.8, 8), Vector3(0.0, 0.85, 0), G(Color(1.0, 0.85, 0.35)), Vector3(0, 0, 32))
			k.add(cyl(0.06, 0.06, 1.85, 6), Vector3(0.0, 0.85, -0.05), G(Color(1.0, 1.0, 0.9)), Vector3(0, 0, 32))
			k.add(tor(0.25, 0.32, 20, 4), Vector3(0.45, 0.05, 0), G(Color(1.0, 0.6, 0.2)))
			k.add(tor(0.45, 0.49, 20, 4), Vector3(0.45, 0.05, 0), G(Color(1.0, 0.45, 0.15)))
		"bone_prison":
			k.add(tor(0.48, 0.6, 16, 5), Vector3(0, 0.06, 0), C_BONE.darkened(0.15))
			for i in 7:
				var a := TAU * i / 7.0
				k.add(cyl(0.05, 0.07, 1.3, 5), Vector3(cos(a) * 0.52, 0.7, sin(a) * 0.52), C_BONE, Vector3(sin(a) * 6, 0, -cos(a) * 6))
				k.add(sph(0.08, 5, 3), Vector3(cos(a) * 0.5, 1.37, sin(a) * 0.5), C_BONE.lightened(0.1))
			k.add(sph(0.27, 8, 5), Vector3(0, 1.55, 0), C_BONE)
			k.add(box(0.26, 0.14, 0.2), Vector3(0, 1.36, -0.05), C_BONE.darkened(0.08))
			geyes(k, 1.58, -0.22, 0.1, 0.06, Color(0.4, 1.0, 0.6))
		"petrifying_gaze":
			# Olho enorme com pálpebras, íris verde acesa e pedras flutuando.
			k.add(sph(0.62, 12, 7), Vector3(0, 0.85, 0), Color(0.92, 0.9, 0.82), Vector3.ZERO, Vector3(1.2, 0.75, 0.6))
			k.add(sph(0.66, 12, 6), Vector3(0, 1.08, 0.03), Color(0.38, 0.4, 0.34), Vector3.ZERO, Vector3(1.25, 0.35, 0.68))
			k.add(sph(0.66, 12, 6), Vector3(0, 0.62, 0.03), Color(0.34, 0.36, 0.3), Vector3.ZERO, Vector3(1.25, 0.3, 0.68))
			k.add(sph(0.27, 10, 6), Vector3(0, 0.85, -0.3), G(Color(0.35, 1.0, 0.45)), Vector3.ZERO, Vector3(1, 1, 0.4))
			k.add(box(0.07, 0.36, 0.05), Vector3(0, 0.85, -0.42), C_DARK)
			for i in 5:
				var a := TAU * i / 5.0 + 0.3
				k.add(box(0.18, 0.22, 0.15), Vector3(cos(a) * 1.0, 0.85 + sin(a) * 0.65, 0.1), C_STONE.darkened(0.05 * i), Vector3(20 * i, 35 * i, 15 * i))
		"damned_army":
			for i in 3:
				var x := -0.55 + i * 0.55
				var y := 0.85 + (i % 2) * 0.3
				k.add(cone(0.22, 0.75, 6), Vector3(x, y - 0.42, 0.05), G(Color(0.3, 0.85, 0.75)), Vector3(180, 0, 0))
				k.add(sph(0.26, 8, 5), Vector3(x, y, 0), Color(0.75, 1.0, 0.95))
				geyes(k, y + 0.03, -0.2, 0.09, 0.07, Color(0.2, 1.0, 0.8))
				k.add(cyl(0.03, 0.03, 0.9, 4), Vector3(x + 0.2, 0.35, 0.25), C_STEEL.darkened(0.2), Vector3(0, 0, 12 - i * 12))
				k.add(box(0.2, 0.04, 0.04), Vector3(x + 0.25, 0.65, 0.25), C_STEEL.darkened(0.3), Vector3(0, 0, 12 - i * 12))
		"dark_fury":
			k.add(cone(0.6, 1.4, 7), Vector3(0, 0.7, 0), G(Color(0.75, 0.2, 1.0)))
			k.add(cone(0.38, 1.0, 7), Vector3(0.1, 0.6, -0.25), G(Color(1.0, 0.5, 1.0)))
			k.add(cone(0.3, 0.8, 6), Vector3(-0.4, 0.45, 0.1), G(Color(0.6, 0.15, 0.9)))
			k.add(sph(0.2, 7, 4), Vector3(0, 0.35, -0.3), G(Color(1.0, 0.85, 1.0)))
		"dark_pact":
			k.add(sph(0.45, 8, 5), Vector3(-0.2, 0.8, 0), Color(0.8, 0.1, 0.2))
			k.add(sph(0.45, 8, 5), Vector3(0.2, 0.8, 0), Color(0.8, 0.1, 0.2))
			k.add(cone(0.55, 0.7, 7), Vector3(0, 0.3, 0), Color(0.8, 0.1, 0.2), Vector3(180, 0, 0))
			k.add(sph(0.18, 6, 4), Vector3(0, 0.75, -0.38), G(Color(1.0, 0.3, 0.3)))
			for i in 6:
				k.add(tor(0.06, 0.1, 8, 4), Vector3(-0.75 + i * 0.3, 0.6 + 0.1 * (i % 2), -0.42), Color(0.55, 0.55, 0.6), Vector3(90 * (i % 2), 0, 15))
		_:
			k.add(box(0.8, 0.8, 0.8), Vector3(0, 0.4, 0), C_STONE)
	return k.done()
