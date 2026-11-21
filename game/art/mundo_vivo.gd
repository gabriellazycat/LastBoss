class_name MundoVivo
extends RefCounted
## Mundo vivo (rodada visual de 20/11/2026): flores, arbustos, pedras, tocos, troncos, cogumelos, lápides, cercas e trigo
## espalhados em MultiMesh ao longo da estrada, por ato, e manchas de cor no chão.
## VAR = 0: o jogo de hoje, nada muda (padrão). --mundo=N em game/main.gd.
##   1 discreta, 2 média, 3 densa.
## Fora da estrada (mínimo de 3 m do eixo), dos locais (70% do raio), da água e das pontes; desenhados em pedaços de
## 48 m (a Godot só desenha os que a câmera vê) e sem sombra, menos as peças grandes.

static var VAR := 3   # padrão aprovado em 20/11/2026 na página de revisão (0 = como era antes)

const NAMES := ["Atual", "Discreta", "Média", "Densa"]
const DENS := [0.0, 0.45, 0.85, 1.45]            # multiplicador de 0,06 prop por metro quadrado
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


## Cor extra das manchas do chão (ground_ror.gdshader, uniform "mundo"): 0 desliga.
static func ground_amount() -> float:
	return [0.0, 0.5, 0.8, 1.0][clampi(VAR, 0, 3)]


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


static func build(w: Node3D, sim: Sim) -> void:
	if VAR <= 0:
		return
	var dens: float = DENS[clampi(VAR, 0, 3)]
	var act_i := clampi(sim.act, 0, 2)
	var lk := GroundLooks.look()
	if lk == 11:
		act_i = 1
	elif lk == 12:
		act_i = 2
	var C: Dictionary = ACTS[act_i]
	var W: Dictionary = C["w"]
	var rng := RandomNumberGenerator.new()
	rng.seed = sim.run_seed + 2027 + sim.act * 17
	var fnoise := FastNoiseLite.new()
	fnoise.seed = sim.run_seed + 21
	fnoise.frequency = 0.03
	var rnoise := FastNoiseLite.new()
	rnoise.seed = sim.run_seed + 22
	rnoise.frequency = 0.055
	var wnoise := FastNoiseLite.new()
	wnoise.seed = sim.run_seed + 5
	wnoise.frequency = 0.018   # o mesmo ruído do bosque de _build_scatter: as árvores novas ficam nos bosques
	var cnoise := FastNoiseLite.new()
	cnoise.seed = sim.run_seed + 23
	cnoise.frequency = 0.012
	# Pontos da estrada: grade de 4 m para a distância, blocos de 8 m para o alcance.
	var near := {}
	var blocks := {}
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for p in pts:
				var gk := Vector2i(int(floor(p.x / 4.0)), int(floor(p.y / 4.0)))
				if not near.has(gk):
					near[gk] = []
				near[gk].append(p)
				blocks[Vector2i(int(floor(p.x / BLOCK)), int(floor(p.y / BLOCK)))] = 0
	var dist := {}
	for bk in blocks:
		for dy in range(-REACH, REACH + 1):
			for dx in range(-REACH, REACH + 1):
				var d := maxi(absi(dx), absi(dy))
				var k: Vector2i = bk + Vector2i(dx, dy)
				if not dist.has(k) or d < int(dist[k]):
					dist[k] = d
	var locs: Array = sim.road.locations
	var lair: Vector2 = sim.road.lair
	var bag := Bag.new()
	var A := {}
	for id in ["bush", "rock", "tree", "tree_round", "dead_tree", "mushroom", "gravestone", "fence"]:
		A[id] = _atlas_pair(id)
	var own := {"stump": [stump_mesh(), _own_mat(0.0)], "log": [log_mesh(), _own_mat(0.0)], "wheat": [wheat_mesh(), _own_mat(1.0)],
		"hay": [hay_mesh(), _own_mat(0.0)]}
	var fmat := _own_mat(1.0)
	var fl_cols: Array = C["flowers"]
	var wsum := 0.0
	for k in W:
		wsum += float(W[k])
	for bk in dist:
		var dd: int = dist[bk]
		var thin := lerpf(1.0, 0.4, float(dd) / REACH)
		var n_f := BLOCK * BLOCK * 0.06 * dens * thin
		var n := int(n_f) + (1 if rng.randf() < n_f - floor(n_f) else 0)
		for i in n:
			var p := Vector2((bk.x + rng.randf()) * BLOCK, (bk.y + rng.randf()) * BLOCK)
			var fn := fnoise.get_noise_2dv(p)
			var rn := rnoise.get_noise_2dv(p)
			var wn := wnoise.get_noise_2dv(p)
			var kind := ""
			var r := rng.randf() * wsum
			for k in W:
				r -= float(W[k])
				if r <= 0.0:
					kind = k
					break
			# Os ruídos puxam o tipo: campos de flores, pedreiras e bosques em vez de salpicado igual.
			if fn > 0.12 and rng.randf() < 0.75:
				kind = "flower"
			elif rn > 0.28 and rng.randf() < 0.65:
				kind = "rock"
			elif wn > 0.2 and rng.randf() < 0.5 and not kind in ["stump", "log", "mush"]:
				kind = "tree"
			var small: bool = kind in ["flower", "mush"]
			var dmin := 2.9 if small or kind == "rock" else 3.8
			if kind == "tree":
				dmin = 5.5
			var gk := Vector2i(int(floor(p.x / 4.0)), int(floor(p.y / 4.0)))
			var ok := true
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					for q in near.get(gk + Vector2i(dx, dy), []):
						if p.distance_squared_to(q) < dmin * dmin:
							ok = false
							break
					if not ok:
						break
				if not ok:
					break
			if not ok:
				continue
			for loc in locs:
				var lp: Vector2 = loc["pos"]
				if p.distance_squared_to(lp) < pow(float(loc["r"]) * 0.7, 2.0):
					ok = false
					break
			if not ok or p.distance_squared_to(lair) < 28.0 * 28.0 or w._near_water(p, 2.0):
				continue
			var yaw := rng.randf() * TAU
			match kind:
				"flower":
					# Um canteiro: 1 a 3 tufos, cor sorteada pelo campo (o ruído grande), com algumas exceções.
					var ci := int(floor((cnoise.get_noise_2dv(p) * 0.5 + 0.5) * fl_cols.size() * 0.999))
					var col: Color = fl_cols[ci] if rng.randf() < 0.8 else _pick(rng, fl_cols)
					var cnt := 1 + (rng.randi() % 3 if fn > 0.12 else 0)
					for j in cnt:
						var q := p + Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5)) * (1.0 if j > 0 else 0.0)
						if w._near_water(q, 1.0):
							continue
						var s := rng.randf_range(1.2, 2.1)
						bag.add("flower_" + col.to_html(), flower_mesh(col), fmat, false, q, rng.randf() * TAU, Vector3(s, s * rng.randf_range(0.9, 1.3), s), Color.WHITE)
				"bush":
					var s := rng.randf_range(0.8, 1.5)
					bag.add("bush", A["bush"][0], A["bush"][1], false, p, yaw, Vector3(s, s * rng.randf_range(0.8, 1.15), s), _pick(rng, C["bush"]))
				"rock":
					# Pedra com filhotes: uma maior e até três pequenas ao lado.
					var s := rng.randf_range(0.45, 1.1) * (1.9 if rng.randf() < 0.08 else 1.0)
					bag.add("rock", A["rock"][0], A["rock"][1], s > 1.4, p, yaw, Vector3(s, s * rng.randf_range(0.7, 1.1), s), _pick(rng, C["rock"]))
					for j in rng.randi() % 4:
						var q := p + Vector2(rng.randf_range(-1.4, 1.4), rng.randf_range(-1.4, 1.4))
						var s2 := rng.randf_range(0.22, 0.45)
						if not w._near_water(q, 1.0):
							bag.add("rock", A["rock"][0], A["rock"][1], false, q, rng.randf() * TAU, Vector3(s2, s2 * 0.8, s2), _pick(rng, C["rock"]))
				"stump":
					var s := rng.randf_range(0.9, 1.5)
					bag.add("stump", own["stump"][0], own["stump"][1], false, p, yaw, Vector3(s, s, s), Color.WHITE)
				"log":
					var s := rng.randf_range(0.8, 1.3)
					bag.add("log", own["log"][0], own["log"][1], false, p, yaw, Vector3(s, s, s), Color.WHITE)
				"mush":
					var s := rng.randf_range(1.2, 2.2)
					for j in 1 + rng.randi() % 3:
						var q := p + Vector2(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.7, 0.7))
						bag.add("mush", A["mushroom"][0], A["mushroom"][1], false, q, rng.randf() * TAU, Vector3(s, s, s), Color.WHITE)
				"grave":
					var s := rng.randf_range(0.9, 1.3)
					bag.add("grave", A["gravestone"][0], A["gravestone"][1], false, p, yaw, Vector3(s, s, s), Color.WHITE, Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.2, 0.2)))
				"dead":
					var s := rng.randf_range(0.8, 1.3)
					bag.add("dead", A["dead_tree"][0], A["dead_tree"][1], true, p, yaw, Vector3(s, s * rng.randf_range(0.9, 1.2), s), _pick(rng, C["tree"]))
				"tree":
					var id := "tree" if rng.randf() < 0.5 else "tree_round"
					var s := rng.randf_range(0.8, 1.3)
					bag.add(id, A[id][0], A[id][1], true, p, yaw, Vector3(s, s * rng.randf_range(0.9, 1.2), s), _pick(rng, C["tree"]))
	# Cercas e plantações ao redor das casas (tavernas, lojas, encruzilhadas e acampamentos).
	for loc in locs:
		if str(loc["type"]) in ["shop", "tavern", "event", "helper"]:
			_house_yard(w, bag, loc, rng, C, own, A, act_i, dens)
	_commit(w, bag)


## Quintal de uma casa: cerca atrás, trigo e fardos de feno ao lado (primavera e outono); no ato 3, cerca torta.
static func _house_yard(w: Node3D, bag: Bag, loc: Dictionary, rng: RandomNumberGenerator, C: Dictionary, own: Dictionary,
		A: Dictionary, act_i: int, dens: float) -> void:
	var p: Vector2 = loc["pos"]
	var dir: Vector2 = w._road_dir_at(loc)
	var side := dir.orthogonal()
	var yaw := atan2(-dir.y, dir.x)   # o comprimento da cerca (eixo X do modelo) segue a estrada
	for i in range(-2, 3):
		var q := p + side * 10.8 + dir * (i * 2.3)
		if w._near_water(q, 1.5):
			continue
		var tilt := Vector3(0, 0, rng.randf_range(-0.25, 0.25)) if act_i == 2 else Vector3.ZERO
		bag.add("fence", A["fence"][0], A["fence"][1], false, q, yaw + (rng.randf_range(-0.2, 0.2) if act_i == 2 else 0.0), Vector3.ONE, Color.WHITE, tilt)
	# Retornos da cerca, em direção à estrada.
	if dens > 0.7:
		for e: float in [-1.0, 1.0]:
			for j in 2:
				var q := p + side * (10.8 - 2.3 * (j + 1)) + dir * (e * 5.0)
				if not w._near_water(q, 1.5):
					bag.add("fence", A["fence"][0], A["fence"][1], false, q, yaw + PI * 0.5, Vector3.ONE, Color.WHITE)
	if C["wheat"]:
		var c := p + side * 15.5
		var nx := 3 + (1 if dens > 0.7 else 0) + (1 if dens > 1.2 else 0)
		for ix in nx * 2:
			for iy in 3:
				var q := c + dir * ((ix - nx + 0.5) * 1.15) + side * (iy * 1.15)
				if w._near_water(q, 1.0):
					continue
				var s := rng.randf_range(0.95, 1.25)
				var v := rng.randf_range(0.9, 1.1)
				bag.add("wheat", own["wheat"][0], own["wheat"][1], false, q, rng.randf() * TAU, Vector3(s, s * rng.randf_range(0.9, 1.15), s), Color(v, v, v))
	if C["hay"]:
		for j in 1 + int(dens > 0.7):
			var q := p + side * 9.0 + dir * (4.6 + j * 1.5)
			if not w._near_water(q, 1.0):
				bag.add("hay", own["hay"][0], own["hay"][1], false, q, yaw + rng.randf_range(-0.3, 0.3), Vector3.ONE * rng.randf_range(0.95, 1.2), Color.WHITE)


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
