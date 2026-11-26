class_name Cenario
extends RefCounted
## Cenário com propósito (pedido de 21/11/2026): no lugar do salpicado (cada ponto sorteava um tipo), o chão é
## dividido em REGIÕES com tema — bosque com borda, campo de flores de uma cor, trigal, pedreira, clareira, e no ato 3
## bosque morto, cemitério e círculos de cogumelos — e a estrada ganha uma MARGEM florida em trechos.
## Regras de lugar (decididas com o usuário):
##  - nada na estrada: toda peça mede a distância a TODOS os trechos (antes as cercas e o trigo de uma casa caíam
##    em cima de outro trecho, e flores/pedras ficavam a 2,9 m do eixo, dentro dos 3,7 m da pista);
##  - a câmera fica ao sul (+z): até ~9 m abaixo da estrada só entram coisas baixas (flor, arbusto, cogumelo, lápide);
##  - cerca de 30% menos peças que o cenário de antes (_build_scatter + MundoVivo densa).
## Também liga o vento com rajadas (wind.gdshaderinc).

const ROAD_HW := 3.7          # meia largura da pista (a máscara da estrada passa de 3,7 m)
const CLEAR := 4.3            # nada a menos disso do eixo
const MARGIN := 6.2           # faixa da margem florida: CLEAR..MARGIN
const LOW_SOUTH := 9.0        # lado da câmera: só coisa baixa até aqui
const TALL_NORTH := 5.8       # lado de cima: árvore a partir daqui
const REACH := 48.0           # cenário até essa distância da estrada
const STEP := 2.5             # grade de amostras (com tremida)
const SEG_CELL := 6.0

# Regiões por ato: peso de cada tema (0 primavera, 1 outono, 2 terra amaldiçoada).
const REGIONS := [
	{"bosque": 0.34, "flores": 0.26, "clareira": 0.14, "pedreira": 0.10, "moita": 0.16},
	{"bosque": 0.34, "trigal": 0.20, "flores": 0.14, "clareira": 0.14, "pedreira": 0.12, "moita": 0.06},
	{"morto": 0.34, "cemiterio": 0.15, "cogumelos": 0.12, "flores": 0.12, "clareira": 0.12, "pedreira": 0.15},
]


# ---------------------------------------------------------------- distância à estrada (todos os trechos)

class RoadIndex:
	var cells: Dictionary = {}   # Vector2i -> Array de [a, b]

	func _init(sim: Sim, other: SimRoad = null) -> void:
		var legs: Array = sim.road.legs.duplicate()
		if other:
			legs.append_array(other.legs)   # o ato vivo durante a montagem do seguinte (crossfade)
		for leg in legs:
			for pts in leg["pts"]:
				for i in range(1, pts.size()):
					var a: Vector2 = pts[i - 1]
					var b: Vector2 = pts[i]
					var n := maxi(1, ceili(a.distance_to(b) / 3.0))
					for k in n + 1:
						var q := a.lerp(b, float(k) / n)
						var c := Vector2i(int(floor(q.x / Cenario.SEG_CELL)), int(floor(q.y / Cenario.SEG_CELL)))
						if not cells.has(c):
							cells[c] = []
						var arr: Array = cells[c]
						if arr.is_empty() or arr[-1][0] != a or arr[-1][1] != b:
							arr.append([a, b])

	## [distância, ponto mais próximo no eixo] até r metros; distância INF se não há estrada perto.
	func near(p: Vector2, r: float) -> Array:
		var best := INF
		var bq := Vector2.ZERO
		var c := Vector2i(int(floor(p.x / Cenario.SEG_CELL)), int(floor(p.y / Cenario.SEG_CELL)))
		var k := ceili(r / Cenario.SEG_CELL)
		for dy in range(-k, k + 1):
			for dx in range(-k, k + 1):
				for s in cells.get(c + Vector2i(dx, dy), []):
					var a: Vector2 = s[0]
					var b: Vector2 = s[1]
					var ab := b - a
					var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
					var q := a + ab * t
					var d := p.distance_to(q)
					if d < best:
						best = d
						bq = q
		return [best if best <= r else INF, bq]


# ---------------------------------------------------------------- montagem

static func build(w: Node3D, sim: Sim) -> void:
	var act_i := clampi(sim.act, 0, 2)
	var lk := GroundLooks.look()
	if lk == 11:
		act_i = 1
	elif lk == 12:
		act_i = 2
	var C: Dictionary = MundoVivo.ACTS[act_i]
	var R: Dictionary = REGIONS[act_i]
	var idx := RoadIndex.new(sim, w.other_road)
	var rng := RandomNumberGenerator.new()
	rng.seed = sim.run_seed + 3101 + sim.act * 19
	var reg := FastNoiseLite.new()
	reg.noise_type = FastNoiseLite.TYPE_CELLULAR
	reg.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	reg.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	reg.fractal_type = FastNoiseLite.FRACTAL_NONE   # o padrão (FBM) soma oitavas e picota a célula em ruído de 2 m
	reg.seed = sim.run_seed + 31
	reg.frequency = 0.024                    # regiões de ~40 m
	reg.domain_warp_enabled = true           # bordas orgânicas, não polígonos retos
	reg.domain_warp_amplitude = 14.0
	reg.domain_warp_frequency = 0.035
	var drift := FastNoiseLite.new()         # manchas dentro de um campo (não um tapete uniforme)
	drift.seed = sim.run_seed + 32
	drift.frequency = 0.09
	var runs := FastNoiseLite.new()          # trechos da margem com flor / sem flor
	runs.seed = sim.run_seed + 33
	runs.frequency = 0.06
	var locs: Array = sim.road.locations
	var lair: Vector2 = sim.road.lair
	var bag := MundoVivo.Bag.new()
	var A := {}
	for id in ["bush", "rock", "tree", "tree_round", "dead_tree", "mushroom", "gravestone", "fence"]:
		A[id] = MundoVivo._atlas_pair(id)
	# Árvores por estilo ("tree#5", "tree_round#6"...).
	var styles := Arvores.STYLES
	for st in styles:
		for id in ["tree", "tree_round"]:
			var am := Arvores.mesh(id, act_i, st)
			A["%s#%d" % [id, st]] = [am, Looks.g_material(am, GroundLooks.prop_material(true))] if am else A[id]
	var bush_mat: Material = A["bush"][1]
	if bush_mat is ShaderMaterial:
		bush_mat = bush_mat.duplicate()
		(bush_mat as ShaderMaterial).set_shader_parameter("wind_amt", 0.25)
		A["bush"] = [A["bush"][0], bush_mat]
	var own := {"stump": [MundoVivo.stump_mesh(), MundoVivo._own_mat(0.0)], "log": [MundoVivo.log_mesh(), MundoVivo._own_mat(0.0)],
		"wheat": [MundoVivo.wheat_mesh(), _wind_mat(0.7)], "hay": [MundoVivo.hay_mesh(), MundoVivo._own_mat(0.0)]}
	if act_i == 0:
		for k in ["stump", "log", "hay"]:
			if Diorama.mesh(k):
				own[k] = [Diorama.mesh(k), GroundLooks.prop_material(false)]
	var fmat := _wind_mat(1.0)
	var fl_cols: Array = C["flowers"]
	var tree_tint: Array = [Color.WHITE]
	# Tipo de região por valor da célula: sorteio pelos pesos do ato.
	var keys: Array = R.keys()
	var wsum := 0.0
	for k in keys:
		wsum += float(R[k])
	var region_of := func(v: float) -> String:
		# O valor da célula não se espalha por igual em -1..1: um hash dele dá a cada tema a fatia certa.
		var u := fposmod(v * 7919.37 + 0.31, 1.0) * wsum
		for k in keys:
			u -= float(R[k])
			if u <= 0.0:
				return k
		return keys[-1]
	# Amostras: blocos de 8 m até REACH da estrada (o resto do mapa a câmera não vê).
	var blocks := {}
	var reach_b := ceili(REACH / 8.0)
	var seen := {}
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for p in pts:
				var bk := Vector2i(int(floor(p.x / 8.0)), int(floor(p.y / 8.0)))
				if seen.has(bk):
					continue
				seen[bk] = true
				for dy in range(-reach_b, reach_b + 1):
					for dx in range(-reach_b, reach_b + 1):
						blocks[bk + Vector2i(dx, dy)] = true
	var n := roundi(8.0 / STEP)
	var stp := 8.0 / n
	var count := 0
	var kinds := {}
	for bk in blocks:
		for iy in n:
			for ix in n:
				var cell_v := 0.0
				var p := Vector2(bk.x * 8.0 + (ix + 0.5) * stp, bk.y * 8.0 + (iy + 0.5) * stp)
				cell_v = reg.get_noise_2dv(p)
				var kind: String = region_of.call(cell_v)
				kinds[kind] = int(kinds.get(kind, 0)) + 1
				var jit := 0.12 if kind == "cemiterio" else 0.9
				p += Vector2(rng.randf_range(-jit, jit), rng.randf_range(-jit, jit)) * stp * 0.5
				var rn: Array = idx.near(p, 12.0)
				var d: float = rn[0]   # INF = a mais de 12 m: longe da pista, vale tudo
				if d < CLEAR:
					continue
				var south: bool = d < LOW_SOUTH and (p.y - (rn[1] as Vector2).y) > 0.0
				var tall_ok: bool = not south and d >= TALL_NORTH
				if _blocked(w, p, locs, lair):
					continue
				# Borda da região: algum vizinho a 4 m pertence a outra célula.
				var border := false
				for o in [Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4)]:
					if region_of.call(reg.get_noise_2dv(p + o)) != kind:
						border = true
						break
				var h := fposmod(cell_v * 1373.17 + 0.77, 1.0)   # sorteio fixo por região (cor, ângulo)
				var h2 := fposmod(cell_v * 3271.9 + 0.13, 1.0)   # estilo das árvores do bosque (um por bosque)
				var yaw := rng.randf() * TAU
				# Margem florida: trechos de flores perto da pista, de uma cor por trecho.
				if d < MARGIN:
					if runs.get_noise_2dv(p) > -0.05 and rng.randf() < 0.85:
						var mc: Color = fl_cols[int(floor((runs.get_noise_2dv(p * 0.3) * 0.5 + 0.5) * fl_cols.size() * 0.999))]
						_flower(bag, w, p, mc, fmat, rng, 1.1)
						count += 1
					continue
				var r := rng.randf()
				match kind:
					"bosque", "morto":
						var dead: bool = kind == "morto"
						if border:
							if r < 0.3:
								_bush(bag, A, C, p, yaw, rng)
							elif r < 0.38:
								bag.add("stump", own["stump"][0], own["stump"][1], false, p, yaw, Vector3.ONE * rng.randf_range(0.9, 1.4), Color.WHITE)
							elif r < 0.43 and act_i >= 1:
								bag.add("log", own["log"][0], own["log"][1], false, p, yaw, Vector3.ONE * rng.randf_range(0.8, 1.2), Color.WHITE)
							elif r < 0.58 and tall_ok:
								_tree(bag, A, tree_tint, p, yaw, rng, dead, styles[int(h2 * styles.size())])
							else:
								continue
						else:
							if r < 0.5 and tall_ok:
								_tree(bag, A, tree_tint, p, yaw, rng, dead and rng.randf() < 0.7, styles[int(h2 * styles.size())])
							elif r < 0.62:
								_bush(bag, A, C, p, yaw, rng)
							elif r < 0.67 or (dead and r < 0.74):
								_mush(bag, A, p, rng, 1 + rng.randi() % 3)
							else:
								continue
					"flores":
						var fade := 0.5 if border else 1.0
						if drift.get_noise_2dv(p) > -0.3 and rng.randf() < 0.9 * fade:
							var col: Color = fl_cols[int(h * fl_cols.size())] if rng.randf() < 0.88 else fl_cols[rng.randi() % fl_cols.size()]
							_flower(bag, w, p, col, fmat, rng, 1.3)
						else:
							continue
					"trigal":
						if border or south:
							if r < 0.04:
								bag.add("hay", own["hay"][0], own["hay"][1], false, p, h * TAU + rng.randf_range(-0.3, 0.3), Vector3.ONE * rng.randf_range(0.95, 1.2), Color.WHITE)
							else:
								continue
						else:
							# Fileiras: 3 maços por amostra ao longo da direção do campo.
							var dir := Vector2.from_angle(h * PI)
							for j in 3:
								var q := p + dir * (j - 1) * 0.8
								var s := rng.randf_range(0.95, 1.25)
								var v := rng.randf_range(0.9, 1.1)
								bag.add("wheat", own["wheat"][0], own["wheat"][1], false, q, rng.randf() * TAU, Vector3(s, s * rng.randf_range(0.9, 1.15), s), Color(v, v, v))
					"clareira":
						# Clareira: o respiro entre as regiões, quase só a grama do chão.
						if r < 0.015:
							_rocks(bag, w, A, C, p, yaw, rng, false)
						else:
							continue
					"pedreira":
						if r < (0.14 if border else 0.28):
							_rocks(bag, w, A, C, p, yaw, rng, not south)
						elif r < 0.31:
							_bush(bag, A, C, p, yaw, rng)
						else:
							continue
					"moita":
						if r < 0.38:
							_bush(bag, A, C, p, yaw, rng)
						elif r < 0.52:
							_flower(bag, w, p, fl_cols[int(h * fl_cols.size())], fmat, rng, 0.9)
						else:
							continue
					"cemiterio":
						if border:
							if r < 0.06 and tall_ok:
								_tree(bag, A, tree_tint, p, yaw, rng, true, styles[0])
							else:
								continue
						elif r < 0.45:
							# Lápides em fileiras: todas viradas para o mesmo lado, pouco tremidas (jit pequeno acima).
							var s := rng.randf_range(0.9, 1.2)
							bag.add("grave", A["gravestone"][0], A["gravestone"][1], false, p, h * TAU + rng.randf_range(-0.12, 0.12), Vector3.ONE * s, Color.WHITE, Vector3(rng.randf_range(-0.1, 0.1), 0, rng.randf_range(-0.15, 0.15)))
						else:
							continue
					"cogumelos":
						if r < 0.05:
							# Círculo de fada: 7 a 9 cogumelos numa roda.
							var cnt := 7 + rng.randi() % 3
							var rr := rng.randf_range(1.1, 1.6)
							for j in cnt:
								var q := p + Vector2.from_angle(TAU * j / cnt + rng.randf_range(-0.15, 0.15)) * rr
								bag.add("mush", A["mushroom"][0], A["mushroom"][1], false, q, rng.randf() * TAU, Vector3.ONE * rng.randf_range(1.2, 1.8), Color.WHITE)
						elif r < 0.2:
							_flower(bag, w, p, fl_cols[int(h * fl_cols.size())], fmat, rng, 0.9)
						else:
							continue
				count += 1
	if "--cenario_map" in OS.get_cmdline_user_args() and w.other_road == null:
		_debug_map(sim, reg, region_of, idx)
	for loc in locs:
		if str(loc["type"]) in ["shop", "tavern", "event", "helper"]:
			_house_yard(w, bag, idx, loc, rng, A, own, act_i)
	MundoVivo._commit(w, bag)
	if OS.is_debug_build() and "--cenario_log" in OS.get_cmdline_user_args():
		var tot := 0
		for k in bag.parts:
			tot += (bag.parts[k]["xf"] as Array).size()
		print("cenario: %d amostras com peça, %d instâncias, %d blocos, regiões %s" % [count, tot, blocks.size(), kinds])


static func _wind_mat(amt: float) -> Material:
	var sm := Models.glow_material(0.0)
	Looks.set_param(sm, "sway", 0.0)
	Looks.set_param(sm, "wind_amt", amt)
	return sm


static func _blocked(w: Node3D, p: Vector2, locs: Array, lair: Vector2) -> bool:
	for loc in locs:
		if p.distance_squared_to(loc["pos"]) < pow(float(loc["r"]) * 0.8, 2.0):
			return true
	return p.distance_squared_to(lair) < 28.0 * 28.0 or w._near_water(p, 2.0)


static func _flower(bag: MundoVivo.Bag, w: Node3D, p: Vector2, col: Color, mat: Material, rng: RandomNumberGenerator, sc: float) -> void:
	for j in 1 + rng.randi() % 3:
		var q := p + (Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) if j > 0 else Vector2.ZERO)
		if w._near_water(q, 1.0):
			continue
		var s := rng.randf_range(1.2, 1.9) * sc
		bag.add("flower_" + col.to_html(), MundoVivo.flower_mesh(col), mat, false, q, rng.randf() * TAU, Vector3(s, s * rng.randf_range(0.9, 1.25), s), Color.WHITE)


static func _bush(bag: MundoVivo.Bag, A: Dictionary, C: Dictionary, p: Vector2, yaw: float, rng: RandomNumberGenerator) -> void:
	var s := rng.randf_range(0.8, 1.4)
	bag.add("bush", A["bush"][0], A["bush"][1], false, p, yaw, Vector3(s, s * rng.randf_range(0.8, 1.1), s), Color.WHITE)   # já tem a cor do ato


static func _tree(bag: MundoVivo.Bag, A: Dictionary, tint: Array, p: Vector2, yaw: float, rng: RandomNumberGenerator, dead: bool, style: int) -> void:
	var s := rng.randf_range(0.85, 1.25)
	if dead:
		bag.add("dead", A["dead_tree"][0], A["dead_tree"][1], true, p, yaw, Vector3(s, s * rng.randf_range(0.9, 1.2), s), MundoVivo._pick(rng, tint))
		return
	var id := "%s#%d" % ["tree" if rng.randf() < 0.55 else "tree_round", style]
	bag.add(id, A[id][0], A[id][1], true, p, yaw, Vector3(s, s * rng.randf_range(0.92, 1.12), s), MundoVivo._pick(rng, tint))


static func _mush(bag: MundoVivo.Bag, A: Dictionary, p: Vector2, rng: RandomNumberGenerator, cnt: int) -> void:
	var s := rng.randf_range(1.2, 2.0)
	for j in cnt:
		var q := p + Vector2(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.7, 0.7))
		bag.add("mush", A["mushroom"][0], A["mushroom"][1], false, q, rng.randf() * TAU, Vector3.ONE * s, Color.WHITE)


static func _rocks(bag: MundoVivo.Bag, w: Node3D, A: Dictionary, C: Dictionary, p: Vector2, yaw: float, rng: RandomNumberGenerator, big_ok: bool) -> void:
	var s := rng.randf_range(0.55, 1.1) * (1.8 if big_ok and rng.randf() < 0.15 else 1.0)
	bag.add("rock", A["rock"][0], A["rock"][1], s > 1.4, p, yaw, Vector3(s, s * rng.randf_range(0.7, 1.05), s), MundoVivo._pick(rng, C["rock"]))
	for j in 1 + rng.randi() % 3:
		var q := p + Vector2(rng.randf_range(-1.4, 1.4), rng.randf_range(-1.4, 1.4))
		var s2 := rng.randf_range(0.22, 0.45)
		if not w._near_water(q, 1.0):
			bag.add("rock", A["rock"][0], A["rock"][1], false, q, rng.randf() * TAU, Vector3(s2, s2 * 0.8, s2), MundoVivo._pick(rng, C["rock"]))


## Quintal de uma casa: cerca, trigo e feno do lado de cima da estrada (longe da câmera) e só onde não há outro trecho.
## Antes iam sempre a 10–15 m de um lado fixo, sem olhar os outros trechos, e caíam em cima da estrada.
static func _house_yard(w: Node3D, bag: MundoVivo.Bag, idx: RoadIndex, loc: Dictionary, rng: RandomNumberGenerator, A: Dictionary,
		own: Dictionary, act_i: int) -> void:
	var p: Vector2 = loc["pos"]
	var dir: Vector2 = w._road_dir_at(loc)
	var sides := [dir.orthogonal(), -dir.orthogonal()]
	if sides[0].y > sides[1].y:
		sides.reverse()   # primeiro o lado de cima (z menor, longe da câmera)
	var ok_at := func(q: Vector2, m: float) -> bool:
		return float(idx.near(q, m + 1.0)[0]) > m and not w._near_water(q, 1.5)
	for side: Vector2 in sides:
		# O quintal cabe deste lado? Confere os cantos da cerca e do trigal.
		var fits := true
		for q in [p + side * 10.8 + dir * -5.0, p + side * 10.8 + dir * 5.0, p + side * 17.0 + dir * -4.0, p + side * 17.0 + dir * 4.0]:
			if not ok_at.call(q, CLEAR + 0.6):
				fits = false
				break
		if not fits:
			continue
		var yaw := atan2(-dir.y, dir.x)
		for i in range(-2, 3):
			var q := p + side * 10.8 + dir * (i * 2.3)
			if not ok_at.call(q, CLEAR + 0.6):
				continue
			var tilt := Vector3(0, 0, rng.randf_range(-0.25, 0.25)) if act_i == 2 else Vector3.ZERO
			bag.add("fence", A["fence"][0], A["fence"][1], false, q, yaw + (rng.randf_range(-0.2, 0.2) if act_i == 2 else 0.0), Vector3.ONE, Color.WHITE, tilt)
		if act_i < 2:
			var c := p + side * 13.0
			for ix in 8:
				for iy in 3:
					var q := c + dir * ((ix - 3.5) * 1.15) + side * (iy * 1.15)
					if not ok_at.call(q, CLEAR):
						continue
					var s := rng.randf_range(0.95, 1.25)
					var v := rng.randf_range(0.9, 1.1)
					bag.add("wheat", own["wheat"][0], own["wheat"][1], false, q, rng.randf() * TAU, Vector3(s, s * rng.randf_range(0.9, 1.15), s), Color(v, v, v))
			var hq := p + side * 9.0 + dir * 5.0
			if ok_at.call(hq, CLEAR + 1.0):
				bag.add("hay", own["hay"][0], own["hay"][1], false, hq, yaw + rng.randf_range(-0.3, 0.3), Vector3.ONE * rng.randf_range(0.95, 1.2), Color.WHITE)
		return


## Mapa das regiões (depuração): user://cenario_mapa_ato<N>.png, 1 px = 2 m, estrada em preto.
static func _debug_map(sim: Sim, reg: FastNoiseLite, region_of: Callable, idx: RoadIndex) -> void:
	var cols := {"bosque": Color(0.1, 0.4, 0.1), "morto": Color(0.3, 0.2, 0.3), "flores": Color(1, 0.6, 0.8), "clareira": Color(0.7, 0.8, 0.5),
		"pedreira": Color(0.5, 0.5, 0.5), "moita": Color(0.4, 0.7, 0.3), "trigal": Color(0.9, 0.8, 0.3), "cemiterio": Color(0.6, 0.6, 0.8),
		"cogumelos": Color(0.8, 0.3, 0.3)}
	var b := Rect2(sim.road.route[0], Vector2.ZERO)
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for p in pts:
				b = b.expand(p)
	b = b.grow(40.0)
	var wpx := int(b.size.x / 2.0)
	var hpx := int(b.size.y / 2.0)
	var img := Image.create(wpx, hpx, false, Image.FORMAT_RGB8)
	for y in hpx:
		for x in wpx:
			var p := b.position + Vector2(x, y) * 2.0
			var c: Color = cols.get(region_of.call(reg.get_noise_2dv(p)), Color.WHITE)
			if float(idx.near(p, 4.0)[0]) < 3.7:
				c = Color.BLACK
			img.set_pixel(x, y, c)
	img.save_png("user://cenario_mapa_ato%d.png" % sim.act)
