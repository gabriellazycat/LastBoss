class_name SimRoad
extends RefCounted
## Estrada gerada por semente: uma rede de nós em fileiras (como um mapa de nós), do início ao covil.
## Cada fileira tem 2 ou 3 nós, e cada nó guarda um local; as ligações levam à fileira seguinte, se abrem
## e se reencontram, nunca se cruzam. Todas as rotas têm o mesmo comprimento: a escolha é só de prêmio.
## O jogador escolhe o ramo (`plan_to`); o herói anda pela rota já decidida, que cresce ligação por ligação.
## Coordenadas no plano (x, y); o herói anda no sentido -y.

const LOC_TYPES := ["shop", "tavern", "fountain", "ritual", "shrine", "bridge", "event", "helper"]
enum LocState { ACTIVE, USED, DESTROYED, WON }

var nodes: Array = []       # {"row", "lane", "pos", "out": [ligação], "in": [ligação], "loc"}; 0 = início, último = covil
var legs: Array = []        # ligações: {"kind": "edge", "a", "b", "pts": [PackedVector2Array], "len": [float], "chosen", "closed"}
var locations: Array = []   # {"type", "pos", "node", "leg", "branch", "d", "state", "r", "t", "hp", "max_hp", "entered"}
var rows := 0
var plan: Dictionary = {}   # nó com mais de uma saída -> ligação escolhida pelo jogador
var path: Array = []        # nós da rota já decidida, do início até `head`
var head := 0               # nó no fim da rota já decidida
var reach: Dictionary = {}  # nós ainda alcançáveis a partir de `head` (inclui `head`)
var route := PackedVector2Array()
var cum := PackedFloat32Array()
var complete := false
var lair := Vector2.ZERO
var lair_dir := Vector2(0, -1)


var shop_row := -1          # fileira de um nó só com a Loja: toda rota passa por ela (rodada 09/11/2026)
var rivers: Array = []      # rios do ato (SimRivers, 15/11/2026): {"kind", "bridges": [nó], "ctrl": [ponto], "pts"}


## `cfg` sobrepõe rules.road (cada ato tem o seu comprimento e número de locais).
func generate(rng: RandomNumberGenerator, rules: Dictionary, cfg: Dictionary = {}) -> void:
	var R: Dictionary = rules["road"].duplicate()
	R.merge(cfg, true)
	# Rios (15/11/2026): se a estrada sorteada não comporta nenhum rio, sorteia outra (mesmo rng: determinístico).
	var row_nodes: Array = []
	for attempt in int(R.get("river", {}).get("road_attempts", 6)):
		nodes = []
		legs = []
		row_nodes = _build_graph(rng, R)
		# river.enabled = false: estrada como antes dos rios (comparação de balanço); a Ponte volta ao sorteio.
		if not bool(R.get("river", {}).get("enabled", true)):
			rivers = []
			break
		rivers = SimRivers.generate(self, R, row_nodes)
		if not rivers.is_empty():
			break
	var last: PackedVector2Array = legs[nodes[-1]["in"][0]]["pts"][0]
	lair = nodes[-1]["pos"]
	lair_dir = (lair - last[last.size() - 2]).normalized()
	_place_locations(rng, rules, R)
	path = [0]
	head = 0
	route.append(Vector2.ZERO)
	cum.append(0.0)
	_refresh()


## Nós em fileiras e as ligações entre elas (sem os locais). Devolve os nós por nível (início, fileiras, covil).
func _build_graph(rng: RandomNumberGenerator, R: Dictionary) -> Array:
	rows = rng.randi_range(int(R["route_locations"][0]), int(R["route_locations"][1]))
	shop_row = rng.randi_range(2, maxi(2, rows - 3)) if int(R["shops"][1]) > 0 else -1
	var lanes := int(R["lanes"])
	var lane_w: float = R["lane_width"]
	var gap: float = float(R["target_length"]) / (rows + 1)
	# Linha central: avança no sentido -y com curvas leves; cada fileira fica perpendicular a ela.
	var c := Vector2.ZERO
	var ang := 0.0
	nodes.append(_node(-1, lanes / 2, Vector2.ZERO))
	var row_nodes: Array = [[0]]
	for r in rows:
		ang = clampf(ang + rng.randf_range(-0.22, 0.22), -0.45, 0.45)
		var dir := Vector2(sin(ang), -cos(ang))
		c += dir * gap
		var perp := Vector2(-dir.y, dir.x)
		var count := 1 if r == shop_row else rng.randi_range(int(R["row_nodes"][0]), mini(int(R["row_nodes"][1]), lanes))
		var pick: Array = range(lanes)
		while pick.size() > count:
			pick.remove_at(rng.randi_range(0, pick.size() - 1))
		var ids: Array = []
		for ln in pick:
			var off := (float(ln) - (lanes - 1) * 0.5) * lane_w
			var jit := perp * rng.randf_range(-3.0, 3.0) + dir * rng.randf_range(-4.0, 4.0)
			ids.append(nodes.size())
			nodes.append(_node(r, ln, c + perp * off + jit))
		row_nodes.append(ids)
	ang = clampf(ang + rng.randf_range(-0.15, 0.15), -0.45, 0.45)
	c += Vector2(sin(ang), -cos(ang)) * gap
	nodes.append(_node(rows, lanes / 2, c))
	row_nodes.append([nodes.size() - 1])
	# Ligações de uma fileira para a seguinte, uma transição por vez, todas com o mesmo comprimento.
	for r in row_nodes.size() - 1:
		var pairs := _link_rows(rng, row_nodes[r], row_nodes[r + 1], float(R["extra_link"]))
		var target := 0.0
		for p in pairs:
			target = maxf(target, nodes[p[0]]["pos"].distance_to(nodes[p[1]]["pos"]))
		target = target * float(R["length_slack"]) + 3.0
		var sgn := 1.0 if rng.randf() < 0.5 else -1.0
		for p in pairs:
			var pts := _kinked(rng, nodes[p[0]]["pos"], nodes[p[1]]["pos"], target, R["point_step"], sgn)
			var e := legs.size()
			legs.append({"kind": "edge", "a": p[0], "b": p[1], "pts": [pts], "len": [_length(pts)], "chosen": -1, "closed": -1})
			nodes[p[0]]["out"].append(e)
			nodes[p[1]]["in"].append(e)
	# Saídas da esquerda para a direita (as teclas 1, 2, 3 seguem essa ordem).
	for n in nodes:
		n["out"].sort_custom(func(a, b): return nodes[legs[a]["b"]]["lane"] < nodes[legs[b]["b"]]["lane"])
	return row_nodes


func _node(row: int, lane: int, pos: Vector2) -> Dictionary:
	return {"row": row, "lane": lane, "pos": pos, "out": [], "in": [], "loc": -1}


## Liga duas fileiras sem cruzar: primeiro uma escada que cobre todos os nós (cada nó com uma saída
## e uma entrada), depois ligações diagonais extras, que são as bifurcações.
func _link_rows(rng: RandomNumberGenerator, A: Array, B: Array, extra: float) -> Array:
	var lane := func(i): return int(nodes[i]["lane"])
	var a := A.duplicate()
	var b := B.duplicate()
	a.sort_custom(func(x, y): return lane.call(x) < lane.call(y))
	b.sort_custom(func(x, y): return lane.call(x) < lane.call(y))
	var pairs: Array = [[a[0], b[0]]]
	var i := 0
	var j := 0
	while i < a.size() - 1 or j < b.size() - 1:
		if i == a.size() - 1:
			j += 1
		elif j == b.size() - 1:
			i += 1
		else:
			var la: int = lane.call(a[i + 1])
			var lb: int = lane.call(b[j + 1])
			if la == lb:
				i += 1
				j += 1
			elif la < lb:
				i += 1
			else:
				j += 1
		pairs.append([a[i], b[j]])
	# Início e fim (uma fileira de um nó só) ficam como estão; no meio, diagonais extras.
	if a.size() > 1 and b.size() > 1:
		for ai in a.size():
			for bj in b.size():
				if absi(lane.call(a[ai]) - lane.call(b[bj])) != 1 or _has_pair(pairs, a[ai], b[bj]):
					continue
				if _outs(pairs, a[ai]) >= 2 or rng.randf() >= extra:
					continue
				if not _crosses(pairs, a[ai], b[bj], lane):
					pairs.append([a[ai], b[bj]])
	return pairs


func _has_pair(pairs: Array, x: int, y: int) -> bool:
	for p in pairs:
		if p[0] == x and p[1] == y:
			return true
	return false


func _outs(pairs: Array, x: int) -> int:
	var n := 0
	for p in pairs:
		if p[0] == x:
			n += 1
	return n


func _crosses(pairs: Array, x: int, y: int, lane: Callable) -> bool:
	for p in pairs:
		var d1: int = lane.call(p[0]) - lane.call(x)
		var d2: int = lane.call(p[1]) - lane.call(y)
		if d1 * d2 < 0:
			return true
	return false


## Caminho de a até b com o comprimento `target`, em trechos retos: a sobra vira um desvio lateral
## de altura h (a → canto → canto → b), achado por bissecção. `sgn` é o lado do desvio (o mesmo para
## todas as ligações de uma transição, para os ramos vizinhos não se cruzarem).
func _kinked(rng: RandomNumberGenerator, a: Vector2, b: Vector2, target: float, step: float, sgn: float) -> PackedVector2Array:
	var t1 := rng.randf_range(0.25, 0.4)
	var t2 := rng.randf_range(0.6, 0.75)
	var lo := 0.0
	var hi := 60.0
	var h := 0.0
	for it in 40:
		h = (lo + hi) * 0.5
		var l := _length(_dogleg(a, b, h * sgn, t1, t2))
		if absf(l - target) < 0.02:
			break
		if l < target:
			lo = h
		else:
			hi = h
	return _resample(_dogleg(a, b, h * sgn, t1, t2), step)


static func _dogleg(a: Vector2, b: Vector2, h: float, t1: float, t2: float) -> PackedVector2Array:
	var d := b - a
	var perp := d.normalized().orthogonal()
	return PackedVector2Array([a, a + d * t1 + perp * h, a + d * t2 + perp * h, b])


## Reamostra a polilinha a cada `step` metros, mantendo os cantos (a projeção do herói usa pontos curtos).
static func _resample(poly: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array([poly[0]])
	for i in poly.size() - 1:
		var p0 := poly[i]
		var p1 := poly[i + 1]
		var n := maxi(1, int(ceil(p0.distance_to(p1) / step)))
		for k in range(1, n + 1):
			out.append(p0.lerp(p1, float(k) / n))
	return out


static func _length(pts: PackedVector2Array) -> float:
	var s := 0.0
	for i in pts.size() - 1:
		s += pts[i].distance_to(pts[i + 1])
	return s


static func _point_on(pts: PackedVector2Array, d: float) -> Vector2:
	var s := 0.0
	for i in pts.size() - 1:
		var l := pts[i].distance_to(pts[i + 1])
		if s + l >= d:
			return pts[i].lerp(pts[i + 1], (d - s) / maxf(l, 0.001))
		s += l
	return pts[pts.size() - 1]


# ---------------------------------------------------------------- locais

## Um local por nó. Os nós da mesma fileira têm tipos diferentes (a escolha é de prêmio); toda rota passa
## por `shrines` Santuários e por exatamente uma Loja (a fileira `shop_row` tem um nó só).
func _place_locations(rng: RandomNumberGenerator, rules: Dictionary, R: Dictionary) -> void:
	# A Ponte só nasce do rio (15/11/2026): sai do sorteio, e os nós por onde um rio passa já são Ponte.
	var w: Dictionary = R["location_weights"].duplicate()
	if bool(R.get("river", {}).get("enabled", true)):
		w.erase("bridge")
	var fixed := {}
	for rv in rivers:
		for n in rv["bridges"]:
			fixed[n] = "bridge"
	var members: Array = []
	for r in rows:
		members.append([])
	for ni in range(1, nodes.size() - 1):
		members[nodes[ni]["row"]].append(ni)
	var best: Dictionary = {}
	var best_err := INF
	for attempt in 400:
		var types := {}
		var shop_rows: Array = [shop_row] if shop_row >= 0 else []
		var shrine_p := float(R["shrine_chance"])
		for row in rows:
			var m: Array = members[row].duplicate()
			for i in range(m.size() - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var tmp = m[i]
				m[i] = m[j]
				m[j] = tmp
			var used: Array = []
			for ni in m:
				var t := ""
				if fixed.has(ni):
					t = fixed[ni]
				elif shop_rows.has(row) and not used.has("shop"):
					t = "shop"
				elif row > 0 and not used.has("shrine") and rng.randf() < shrine_p:
					t = "shrine"
				else:
					t = _weighted(rng, w, used)
				used.append(t)
				types[ni] = t
		# Erro = fração das rotas fora do número de Santuários + Lojas repetidas numa rota.
		var sh := _path_hist(types, "shrine")
		var sp := _path_hist(types, "shop")
		var total := 0.0
		var off := 0.0
		for k in sh.size():
			total += sh[k]
			if k < int(R["shrines"][0]) or k > int(R["shrines"][1]):
				off += sh[k]
		var nshop := 0
		for k in types:
			if types[k] == "shop":
				nshop += 1
		var err := off / maxf(total, 1.0)
		for k in range(2, sp.size()):
			err += 2.0 if sp[k] > 0.0 else 0.0
		err += 3.0 if nshop < int(R["shops"][0]) else 0.0
		if err < best_err:
			best_err = err
			best = types
			if err <= 0.0:
				break
	_place_helpers(rng, R, best, members)
	var L: Dictionary = rules["locations"]
	for ni in range(1, nodes.size() - 1):
		var t: String = best[ni]
		var hp := float(L[t].get("hp", 0))
		var e: int = nodes[ni]["in"][0]
		nodes[ni]["loc"] = locations.size()
		locations.append({"type": t, "pos": nodes[ni]["pos"], "node": ni, "leg": e, "branch": 0, "d": legs[e]["len"][0],
			"state": LocState.ACTIVE, "r": float(L[t]["radius"]), "t": 0.0, "hp": hp, "max_hp": hp, "entered": false})
	_mark_hard(rng, R)


## Disputa difícil (11/11/2026): `hard_contests` locais de disputa por ato ganham "hard" (caveira no mapa).
## Vencer as 3 etapas dele dá também 1 de 3 relíquias (Sim._resolve_contest); as metas sobem `hard_goal_mult`.
## Fileiras diferentes quando dá, para que rotas diferentes tenham a sua.
func _mark_hard(rng: RandomNumberGenerator, R: Dictionary) -> void:
	var cand: Array = []
	for k in locations.size():
		if locations[k]["type"] in ["tavern", "fountain", "ritual", "shrine", "bridge"]:
			cand.append(k)
	var rows_used: Array = []
	for n in int(R.get("hard_contests", 0)):
		var pick: Array = cand.filter(func(k): return not rows_used.has(nodes[locations[k]["node"]]["row"]))
		if pick.is_empty():
			pick = cand
		if pick.is_empty():
			return
		var k: int = pick[rng.randi_range(0, pick.size() - 1)]
		cand.erase(k)
		rows_used.append(nodes[locations[k]["node"]]["row"])
		locations[k]["hard"] = true


## Herói Ajudante (11/11/2026): `helpers` por ato, cada um num nó de uma fileira com 2+ nós (um ramo de
## bifurcação) entre `helper_rows`. Troca um local comum: Loja e Santuário ficam onde estão (as contas de
## Santuário e Loja por rota não mudam). Sorteio pelo rng da estrada: a mesma semente dá o mesmo mapa.
func _place_helpers(rng: RandomNumberGenerator, R: Dictionary, types: Dictionary, members: Array) -> void:
	var want := int(R.get("helpers", 0))
	var hr: Array = R.get("helper_rows", [2, 4])
	for k in want:
		var cand: Array = []
		for row in range(maxi(0, int(hr[0])), mini(rows - 1, int(hr[1])) + 1):
			if members[row].size() < 2 or row == shop_row:
				continue
			var has_helper := false
			for ni in members[row]:
				has_helper = has_helper or types.get(ni, "") == "helper"
			if has_helper:
				continue
			for ni in members[row]:
				if not types.get(ni, "") in ["shop", "shrine", "helper", "bridge"]:
					cand.append(ni)
		if cand.is_empty():
			return
		types[cand[rng.randi_range(0, cand.size() - 1)]] = "helper"


func _weighted(rng: RandomNumberGenerator, w: Dictionary, used: Array) -> String:
	var tot := 0.0
	for k in w:
		if not used.has(k):
			tot += float(w[k])
	var r := rng.randf() * tot
	for k in w:
		if used.has(k):
			continue
		r -= float(w[k])
		if r <= 0.0:
			return k
	for k in w:
		if not used.has(k):
			return k
	return w.keys()[0]


## Quantas rotas completas passam por k locais do tipo `ty`, para k = 0, 1, 2... (índice = k).
func _path_hist(types: Dictionary, ty: String) -> Array:
	var h := {0: [1.0]}
	for ni in range(1, nodes.size()):
		var v := 1 if types.get(ni, "") == ty else 0
		var acc: Array = []
		for e in nodes[ni]["in"]:
			var src: Array = h[legs[e]["a"]]
			for k in src.size():
				while acc.size() <= k + v:
					acc.append(0.0)
				acc[k + v] += src[k]
		h[ni] = acc
	return h[nodes.size() - 1]


# ---------------------------------------------------------------- rota do herói

func _append(pts: PackedVector2Array) -> void:
	for i in range(1, pts.size()):
		var p := pts[i]
		cum.append(cum[cum.size() - 1] + route[route.size() - 1].distance_to(p))
		route.append(p)


func length() -> float:
	return cum[cum.size() - 1]


## Ligação que o herói segue a partir de `head`: a única, a do plano do jogador, ou -1 (falta escolher).
func next_edge() -> int:
	if complete:
		return -1
	var outs: Array = nodes[head]["out"]
	if outs.size() == 1:
		return outs[0]
	return int(plan.get(head, -1))


## Acrescenta a ligação e à rota (e precisa sair de `head`).
func advance(e: int) -> void:
	if complete or not nodes[head]["out"].has(e):
		return
	legs[e]["chosen"] = 0
	_append(legs[e]["pts"][0])
	head = legs[e]["b"]
	path.append(head)
	if nodes[head]["out"].is_empty():
		complete = true
	_refresh()


## Escolha do jogador: o herói vai passar pelo nó n. Marca no plano cada bifurcação até lá.
func plan_to(n: int) -> bool:
	if n < 0 or n >= nodes.size() or not reach.has(n) or n == head:
		return false
	# Busca em largura de head até n; guarda por qual ligação chegou em cada nó.
	var via := {head: -1}
	var q: Array = [head]
	while q.size() > 0 and not via.has(n):
		var x: int = q.pop_front()
		for e in nodes[x]["out"]:
			var y: int = legs[e]["b"]
			if not via.has(y):
				via[y] = e
				q.append(y)
	if not via.has(n):
		return false
	var cur := n
	while cur != head:
		var e: int = via[cur]
		var a: int = legs[e]["a"]
		if nodes[a]["out"].size() > 1:
			plan[a] = e
		cur = a
	_refresh()
	return true


## O nó n ainda está no caminho do herói: já na rota decidida ou alcançável a partir dela.
func on_route_node(n: int) -> bool:
	return reach.has(n) or path.has(n)


## Recalcula o que ainda é alcançável e marca as ligações fora do caminho como fechadas.
func _refresh() -> void:
	reach = {head: true}
	var q: Array = [head]
	while q.size() > 0:
		var x: int = q.pop_front()
		for e in nodes[x]["out"]:
			var y: int = legs[e]["b"]
			if not reach.has(y):
				reach[y] = true
				q.append(y)
	for e in legs.size():
		var g: Dictionary = legs[e]
		if g["chosen"] == 0:
			g["closed"] = -1
		else:
			g["closed"] = -1 if reach.has(g["a"]) else 0


## Próximo nó com escolha pendente seguindo as ligações únicas a partir de head (ou -1).
func next_fork_node() -> int:
	var n := head
	var guard := 0
	while guard < nodes.size():
		guard += 1
		var outs: Array = nodes[n]["out"]
		if outs.is_empty():
			return -1
		if outs.size() > 1 and not plan.has(n):
			return n
		var e: int = outs[0] if outs.size() == 1 else plan[n]
		n = legs[e]["b"]
	return -1


## Distância pela estrada (a partir do começo da rota) até o nó n, seguindo a rota decidida e o plano.
## -1 se o nó não está no caminho já determinado.
func s_of_node(n: int) -> float:
	var s := 0.0
	for k in path.size():
		if path[k] == n:
			return s
		if k + 1 < path.size():
			s += _edge_len(path[k], path[k + 1])
	var x: int = path[-1]
	var guard := 0
	while guard < nodes.size():
		guard += 1
		var outs: Array = nodes[x]["out"]
		if outs.is_empty():
			return -1.0
		var e: int = outs[0] if outs.size() == 1 else int(plan.get(x, -1))
		if e < 0:
			return -1.0
		s += float(legs[e]["len"][0])
		x = legs[e]["b"]
		if x == n:
			return s
	return -1.0


func _edge_len(a: int, b: int) -> float:
	for e in nodes[a]["out"]:
		if legs[e]["b"] == b:
			return float(legs[e]["len"][0])
	return 0.0


## Comprimento de qualquer rota completa (todas têm o mesmo).
func total_length() -> float:
	var s := 0.0
	var x := 0
	while not nodes[x]["out"].is_empty():
		var e: int = nodes[x]["out"][0]
		s += float(legs[e]["len"][0])
		x = legs[e]["b"]
	return s


func point_at(s: float) -> Vector2:
	if s <= 0.0:
		return route[0]
	var n := cum.size()
	if s >= cum[n - 1]:
		return route[n - 1]
	var lo := 0
	var hi := n - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if cum[mid] <= s:
			lo = mid
		else:
			hi = mid
	var l := cum[hi] - cum[lo]
	return route[lo].lerp(route[hi], (s - cum[lo]) / maxf(l, 0.0001))


func seg_at(s: float) -> int:
	var lo := 0
	var hi := cum.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if cum[mid] <= s:
			lo = mid
		else:
			hi = mid
	return lo


## Projeta pos na rota perto do segmento hint, nunca antes de min_s. Devolve Vector3(s, seg, dist).
func project(pos: Vector2, hint: int, min_s := 0.0) -> Vector3:
	var best_d := INF
	var best_s := 0.0
	var best_seg := hint
	if route.size() < 2:
		return Vector3(0.0, 0, pos.distance_to(route[0]))
	var a := maxi(maxi(0, hint - 3), seg_at(min_s))
	var b := maxi(a, mini(route.size() - 2, hint + 10))
	for i in range(a, b + 1):
		var p0 := route[i]
		var p1 := route[i + 1]
		var seg := p1 - p0
		var l2 := seg.length_squared()
		var t := 0.0
		if l2 > 0.0:
			var t0 := clampf((min_s - cum[i]) / sqrt(l2), 0.0, 1.0)
			t = clampf((pos - p0).dot(seg) / l2, t0, 1.0)
		var q := p0 + seg * t
		var d := pos.distance_squared_to(q)
		if d < best_d:
			best_d = d
			best_seg = i
			best_s = cum[i] + sqrt(l2) * t
	return Vector3(best_s, best_seg, sqrt(best_d))


## O local ainda está no caminho do herói (na rota decidida ou alcançável).
func is_on_route(loc: Dictionary) -> bool:
	return on_route_node(int(loc["node"]))
