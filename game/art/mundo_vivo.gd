class_name MundoVivo
extends RefCounted
## Peças do mundo vivo usadas pelo Cenario (game/art/cenario.gd): malhas de flor, toco, tronco, trigo e feno, a paleta
## por ato (ACTS), o tom dos tufos de grama e o Bag que junta as instâncias em MultiMesh por pedaços de 48 m (a Godot
## só desenha os que a câmera vê).

const CHUNK := 48.0
const BLOCK := 8.0
const REACH := 5                                 # blocos de 8 m ao redor da estrada com cenário (40 m)
const VIS_END := 120.0

# Paleta por ato (0 primavera, 1 outono, 2 terra amaldiçoada). "w" = peso de cada tipo de peça.
const ACTS := [
	{"flowers": [Color(1.0, 0.95, 0.85), Color(1.0, 0.82, 0.25), Color(0.95, 0.5, 0.65), Color(0.55, 0.65, 1.0)],
		"bush": [Color(1, 1, 1), Color(0.88, 1.08, 0.9), Color(1.1, 1.02, 0.85)], "rock": [Color(1, 1, 1), Color(0.9, 1.0, 0.85)],
		"tree": [Color(1, 1, 1), Color(0.92, 1.04, 0.95)],
		"w": {"flower": 1.0, "bush": 0.7, "rock": 0.6, "stump": 0.25, "log": 0.12, "mush": 0.08, "grave": 0.0, "dead": 0.0, "tree": 0.5},
		"wheat": true, "hay": true},
	{"flowers": [Color(1.0, 0.55, 0.2), Color(0.9, 0.25, 0.15), Color(1.0, 0.82, 0.3), Color(0.95, 0.9, 0.8)],
		"bush": [Color(1.7, 0.95, 0.5), Color(1.4, 0.75, 0.4), Color(1.2, 1.0, 0.55), Color(1.9, 0.6, 0.35)],
		"rock": [Color(1.1, 1.0, 0.9), Color(1.0, 0.9, 0.8)],
		"tree": [Color(1.8, 0.95, 0.5), Color(1.5, 0.8, 0.4), Color(1.3, 1.1, 0.6)],
		"w": {"flower": 0.6, "bush": 0.8, "rock": 0.6, "stump": 0.5, "log": 0.3, "mush": 0.2, "grave": 0.0, "dead": 0.1, "tree": 0.5},
		"wheat": true, "hay": true},
	{"flowers": [Color(0.8, 0.5, 1.0), Color(0.75, 0.8, 0.95), Color(1.0, 0.45, 0.6), Color(0.5, 0.9, 0.85)],
		"bush": [Color(0.85, 0.7, 1.05), Color(0.7, 0.7, 0.85), Color(1.0, 0.6, 0.9)], "rock": [Color(0.9, 0.85, 1.0), Color(0.8, 0.8, 0.95)],
		"tree": [Color(1.1, 0.7, 1.3), Color(0.85, 0.8, 1.0)],
		"w": {"flower": 0.4, "bush": 0.5, "rock": 0.8, "stump": 0.3, "log": 0.2, "mush": 0.45, "grave": 0.22, "dead": 0.4, "tree": 0.3},
		"wheat": false, "hay": false},
]

static var _mesh: Dictionary = {}


## Cor extra das manchas do chão (uniform "mundo" do shader do chão).
static func ground_amount() -> float:
	return 1.0


## Tamanho e tom dos tufos de grama: 3 tamanhos e 3 tons em vez de um só.
static func tuft(rng: RandomNumberGenerator) -> Array:
	var r := rng.randf()
	var sz := 0.62 if r < 0.34 else (1.0 if r < 0.74 else 1.55)
	var t := rng.randf()
	var tone := Color(1.0, 0.98, 0.9) if t < 0.3 else (Color(0.8, 0.95, 0.9) if t < 0.55 else Color(1.1, 1.12, 0.95))
	return [sz, tone]


# ---------------------------------------------------------------- malhas de código (guache: formas grandes, cor chapada)

static func _k() -> Models.Kit:
	return Models.Kit.new()


static func flower_mesh(col: Color) -> ArrayMesh:
	var key := "flower_%s" % col.to_html()
	if _mesh.has(key):
		return _mesh[key]
	var k := _k()
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 7:
		var a := i * 2.4 + rng.randf()
		var rr := 0.12 + rng.randf() * 0.26
		var h := 0.28 + rng.randf() * 0.2
		var x := cos(a) * rr
		var z := sin(a) * rr
		k.add(Models.cyl(0.018, 0.022, h, 3), Vector3(x, h * 0.5, z), Color(0.22, 0.46, 0.2))
		k.add(Models.sph(0.1, 6, 3), Vector3(x, h + 0.03, z), col, Vector3.ZERO, Vector3(1, 0.55, 1))
		k.add(Models.sph(0.045, 5, 3), Vector3(x, h + 0.08, z), Color(1.0, 0.85, 0.3))
	_mesh[key] = k.done()
	return _mesh[key]


static func stump_mesh() -> ArrayMesh:
	if _mesh.has("stump"):
		return _mesh["stump"]
	var k := _k()
	k.add(Models.cyl(0.3, 0.38, 0.5, 7), Vector3(0, 0.25, 0), Models.C_WOOD.darkened(0.15))
	k.add(Models.cyl(0.27, 0.27, 0.05, 7), Vector3(0, 0.51, 0), Models.C_WOOD.lightened(0.45))
	k.add(Models.cyl(0.15, 0.15, 0.06, 7), Vector3(0, 0.54, 0), Models.C_WOOD.lightened(0.25))
	for i in 3:
		var a := i * 2.1
		k.add(Models.cone(0.1, 0.3, 4), Vector3(cos(a) * 0.34, 0.1, sin(a) * 0.34), Models.C_WOOD.darkened(0.25))
	k.add(Models.sph(0.2, 5, 3), Vector3(0.18, 0.5, 0.1), Color(0.3, 0.55, 0.25), Vector3.ZERO, Vector3(1, 0.4, 1))
	_mesh["stump"] = k.done()
	return _mesh["stump"]


static func log_mesh() -> ArrayMesh:
	if _mesh.has("log"):
		return _mesh["log"]
	var k := _k()
	k.add(Models.cyl(0.22, 0.25, 2.4, 7), Vector3(0, 0.24, 0), Models.C_WOOD.darkened(0.1), Vector3(0, 0, 90))
	k.add(Models.cyl(0.2, 0.2, 0.04, 7), Vector3(1.2, 0.24, 0), Models.C_WOOD.lightened(0.45), Vector3(0, 0, 90))
	k.add(Models.sph(0.3, 5, 3), Vector3(-0.3, 0.42, 0.05), Color(0.3, 0.55, 0.25), Vector3.ZERO, Vector3(1.6, 0.4, 1))
	_mesh["log"] = k.done()
	return _mesh["log"]


static func wheat_mesh() -> ArrayMesh:
	if _mesh.has("wheat"):
		return _mesh["wheat"]
	var k := _k()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 16:
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * 0.5
		var h := 0.85 + rng.randf() * 0.25
		var lean := Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12))
		var base := Vector3(cos(a) * rr, h * 0.5, sin(a) * rr)
		var c := Color(0.85, 0.7, 0.28).lerp(Color(0.95, 0.82, 0.4), rng.randf())
		k.add(Models.cyl(0.015, 0.025, h, 3), base, c.darkened(0.2), lean)
		k.add(Models.sph(0.055, 5, 3), base + Vector3(0, h * 0.5 + 0.04, 0), c, lean, Vector3(1, 2.8, 1))
	_mesh["wheat"] = k.done()
	return _mesh["wheat"]


static func hay_mesh() -> ArrayMesh:
	if _mesh.has("hay"):
		return _mesh["hay"]
	var k := _k()
	k.add(Models.cyl(0.55, 0.55, 0.9, 9), Vector3(0, 0.55, 0), Color(0.88, 0.7, 0.3), Vector3(0, 0, 90))
	k.add(Models.cyl(0.5, 0.5, 0.05, 9), Vector3(0.46, 0.55, 0), Color(0.7, 0.52, 0.2), Vector3(0, 0, 90))
	k.add(Models.cyl(0.5, 0.5, 0.05, 9), Vector3(-0.46, 0.55, 0), Color(0.7, 0.52, 0.2), Vector3(0, 0, 90))
	_mesh["hay"] = k.done()
	return _mesh["hay"]


# ---------------------------------------------------------------- espalhamento

class Bag:
	var parts: Dictionary = {}   # "tipo|pedaço" -> {mesh, mat, shadow, xf: [], col: []}

	func add(kind: String, mesh: Mesh, mat: Material, shadow: bool, p: Vector2, yaw: float, s: Vector3, col: Color, tilt := Vector3.ZERO) -> void:
		var ck := Vector2i(int(floor(p.x / MundoVivo.CHUNK)), int(floor(p.y / MundoVivo.CHUNK)))
		var key := "%s|%d|%d" % [kind, ck.x, ck.y]
		if not parts.has(key):
			parts[key] = {"mesh": mesh, "mat": mat, "shadow": shadow, "xf": [], "col": []}
		var b := Basis.from_euler(tilt) * Basis(Vector3.UP, yaw)
		(parts[key]["xf"] as Array).append(Transform3D(b.scaled(s), Vector3(p.x, 0, p.y)))
		(parts[key]["col"] as Array).append(col)


static func _atlas_pair(id: String) -> Array:
	var m: Mesh = GroundLooks.prop_mesh(id)
	var mat: Material
	if m:
		mat = GroundLooks.prop_material(id in ["tree", "tree_round", "bush"])
	else:
		m = Models.prop(id)
		mat = Models.material()
	return [m, Looks.g_material(m, mat)]


static func _own_mat(sway: float) -> Material:
	var sm := Models.glow_material(0.0)
	Looks.set_param(sm, "sway", sway)
	return sm


static func _pick(rng: RandomNumberGenerator, a: Array) -> Color:
	return a[rng.randi() % a.size()]


static func _commit(w: Node3D, bag: Bag) -> void:
	for key in bag.parts:
		var d: Dictionary = bag.parts[key]
		var xf: Array = d["xf"]
		var col: Array = d["col"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = d["mesh"]
		mm.instance_count = xf.size()
		for i in xf.size():
			mm.set_instance_transform(i, xf[i])
			mm.set_instance_color(i, col[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = d["mat"]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if d["shadow"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = VIS_END
		w.add_child(mmi)
