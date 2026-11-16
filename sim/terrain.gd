class_name SimTerrain
extends RefCounted
## Água dos rios na simulação (16/11/2026, docs/RIO_E_PONTES.md, passo 3). Feito a partir de SimRoad.rivers: uma
## grade de 1 m marca terra, água e tabuleiro de ponte. As margens viram regiões (terra ligada sem passar pela
## água) e as pontes, passagens entre duas regiões. Nada aqui vai para o save: refaz-se da estrada.
##
## Regras: monstro de chão e herói nunca ficam na água (o passo final os devolve para a margem); quem está em
## outra margem anda até a cabeceira da ponte que leva lá; voadores ignoram tudo isso.

const LAND := 0
const WATER := 1
const DECK := 2
const CELL := 1.0
const UNKNOWN := -1        # fora da grade (longe dos rios): sem regra de água
const ON_DECK := -2        # em cima de uma ponte (a região é a das duas cabeceiras)

var ok := false
var org := Vector2.ZERO    # canto da grade (mundo)
var w := 0
var h := 0
var kind := PackedByteArray()
var region := PackedInt32Array()
var deck_of := PackedInt32Array()   # célula de tabuleiro -> índice da ponte
var bridges: Array = []    # {"node", "c": centro, "ax": eixo, "a": cabeceira, "b": cabeceira, "ra", "rb"}
var hw := 5.0              # meia largura do rio (colisão)
var _route_cache := {}


func build(road: SimRoad, R: Dictionary) -> void:
	var RV: Dictionary = R.get("road", {}).get("river", {})
	hw = float(RV.get("half_width", 5.0))
	var deck_half_w := float(RV.get("deck_half_width", 2.6))
	var deck_half_l := hw + float(RV.get("deck_overhang", 2.5))
	ok = false
	bridges.clear()
	_route_cache.clear()
	if road == null or road.rivers.is_empty():
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for rv in road.rivers:
		for p in rv["pts"]:
			lo = lo.min(p)
			hi = hi.max(p)
	# A grade acaba onde o rio acaba (sem margem além das pontas): senão a beirada liga as duas margens.
	org = lo
	w = int(ceil((hi.x - lo.x) / CELL)) + 1
	h = int(ceil((hi.y - lo.y) / CELL)) + 1
	kind = PackedByteArray()
	kind.resize(w * h)
	kind.fill(LAND)
	region = PackedInt32Array()
	region.resize(w * h)
	region.fill(-1)
	deck_of = PackedInt32Array()
	deck_of.resize(w * h)
	deck_of.fill(-1)
	# Água: cápsulas de meia largura hw em volta de cada trecho do rio.
	for rv in road.rivers:
		var pts: PackedVector2Array = rv["pts"]
		for i in pts.size() - 1:
			_capsule(pts[i], pts[i + 1], hw)
	# Tabuleiros: um retângulo no eixo da estrada, centrado no nó-ponte.
	for rv in road.rivers:
		for n in rv["bridges"]:
			var c: Vector2 = road.nodes[n]["pos"]
			var ax := SimRivers.bridge_axis(road, n)
			var k := bridges.size()
			bridges.append({"node": n, "c": c, "ax": ax, "a": c - ax * (deck_half_l + 1.5), "b": c + ax * (deck_half_l + 1.5)})
			_rect(c, ax, deck_half_l, deck_half_w, k)
	# Regiões: terra ligada (4 vizinhos) sem atravessar água nem tabuleiro.
	var next := 0
	for idx in w * h:
		if kind[idx] == LAND and region[idx] < 0:
			_flood(idx, next)
			next += 1
	ok = true
	for b in bridges:
		b["ra"] = region_at(b["a"].x, b["a"].y)
		b["rb"] = region_at(b["b"].x, b["b"].y)


func _capsule(a: Vector2, b: Vector2, r: float) -> void:
	var lo := a.min(b) - Vector2(r, r)
	var hi := a.max(b) + Vector2(r, r)
	for gy in range(maxi(0, int(floor((lo.y - org.y) / CELL))), mini(h - 1, int(ceil((hi.y - org.y) / CELL))) + 1):
		for gx in range(maxi(0, int(floor((lo.x - org.x) / CELL))), mini(w - 1, int(ceil((hi.x - org.x) / CELL))) + 1):
			var p := org + Vector2(gx + 0.5, gy + 0.5) * CELL
			if Geometry2D.get_closest_point_to_segment(p, a, b).distance_squared_to(p) <= r * r:
				kind[gy * w + gx] = WATER


func _rect(c: Vector2, ax: Vector2, half_l: float, half_w: float, k: int) -> void:
	var side := Vector2(-ax.y, ax.x)
	var r := half_l + half_w
	for gy in range(maxi(0, int(floor((c.y - r - org.y) / CELL))), mini(h - 1, int(ceil((c.y + r - org.y) / CELL))) + 1):
		for gx in range(maxi(0, int(floor((c.x - r - org.x) / CELL))), mini(w - 1, int(ceil((c.x + r - org.x) / CELL))) + 1):
			var p := org + Vector2(gx + 0.5, gy + 0.5) * CELL - c
			if absf(p.dot(ax)) <= half_l and absf(p.dot(side)) <= half_w:
				var idx := gy * w + gx
				kind[idx] = DECK
				deck_of[idx] = k


func _flood(start: int, id: int) -> void:
	var stack := PackedInt32Array([start])
	region[start] = id
	while stack.size() > 0:
		var idx: int = stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		var x := idx % w
		var y := idx / w
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = x + d.x
			var ny: int = y + d.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var ni := ny * w + nx
			if kind[ni] == LAND and region[ni] < 0:
				region[ni] = id
				stack.append(ni)


func _idx(x: float, y: float) -> int:
	var gx := int(floor((x - org.x) / CELL))
	var gy := int(floor((y - org.y) / CELL))
	if gx < 0 or gy < 0 or gx >= w or gy >= h:
		return -1
	return gy * w + gx


func is_water(x: float, y: float) -> bool:
	if not ok:
		return false
	var i := _idx(x, y)
	return i >= 0 and kind[i] == WATER


## Região da margem em (x, y); ON_DECK em cima de uma ponte; UNKNOWN fora da grade (e na água).
func region_at(x: float, y: float) -> int:
	if not ok:
		return UNKNOWN
	var i := _idx(x, y)
	if i < 0:
		return UNKNOWN
	if kind[i] == DECK:
		return ON_DECK
	return region[i] if kind[i] == LAND else UNKNOWN


func deck_at(x: float, y: float) -> int:
	if not ok:
		return -1
	var i := _idx(x, y)
	return deck_of[i] if i >= 0 else -1


## Os dois pontos estão do mesmo lado (ou um deles está numa ponte que dá no lado do outro)? Fora da grade: sim.
func same_side(x1: float, y1: float, x2: float, y2: float) -> bool:
	if not ok:
		return true
	var r1 := region_at(x1, y1)
	var r2 := region_at(x2, y2)
	if r1 == UNKNOWN or r2 == UNKNOWN or r1 == r2:
		return true
	if r1 == ON_DECK:
		var b: Dictionary = bridges[deck_at(x1, y1)]
		return r2 == ON_DECK or r2 == int(b["ra"]) or r2 == int(b["rb"])
	if r2 == ON_DECK:
		var b2: Dictionary = bridges[deck_at(x2, y2)]
		return r1 == int(b2["ra"]) or r1 == int(b2["rb"])
	return false


## Para onde andar para chegar a (tx, ty) sem atravessar a água: o próprio alvo, ou a cabeceira da ponte do
## caminho (do lado de quem anda; já na cabeceira, a do outro lado).
func waypoint(x: float, y: float, tx: float, ty: float) -> Vector2:
	var target := Vector2(tx, ty)
	if not ok:
		return target
	var r0 := region_at(x, y)
	var r1 := region_at(tx, ty)
	if r0 == UNKNOWN or r1 == UNKNOWN or r0 == r1:
		return target
	var here := Vector2(x, y)
	if r0 == ON_DECK:
		var b: Dictionary = bridges[deck_at(x, y)]
		if r1 == ON_DECK:
			return target
		# Sai pela cabeceira do lado do alvo (ou a que leva até ele).
		var ga := _hops(int(b["ra"]), r1)
		var gb := _hops(int(b["rb"]), r1)
		return b["a"] if ga <= gb else b["b"]
	var goal_set: Array = [r1]
	if r1 == ON_DECK:
		var bt: Dictionary = bridges[deck_at(tx, ty)]
		if r0 == int(bt["ra"]) or r0 == int(bt["rb"]):
			# A ponte do alvo sai deste lado: vai à cabeceira dela e sobe.
			var end: Vector2 = bt["a"] if r0 == int(bt["ra"]) else bt["b"]
			return target if dry_line(here, target) else end
		goal_set = [int(bt["ra"]), int(bt["rb"])]
	var best := -1
	var best_cost := INF
	var best_near := Vector2.ZERO
	var best_far := Vector2.ZERO
	for k in bridges.size():
		var b: Dictionary = bridges[k]
		for s in 2:
			var rn: int = b["ra"] if s == 0 else b["rb"]
			var rf: int = b["rb"] if s == 0 else b["ra"]
			if rn != r0 or rf == r0:
				continue
			var hops := INF
			for g in goal_set:
				hops = minf(hops, _hops(rf, int(g)))
			if hops == INF:
				continue
			var near: Vector2 = b["a"] if s == 0 else b["b"]
			var far: Vector2 = b["b"] if s == 0 else b["a"]
			var cost := here.distance_to(near) + near.distance_to(far) + hops * 1000.0 + (far.distance_to(target) if hops == 0 else 0.0)
			if cost < best_cost:
				best_cost = cost
				best = k
				best_near = near
				best_far = far
	if best < 0:
		return target
	# Já dá para ir reto até a outra cabeceira (pelo tabuleiro) sem pisar na água? Então vai; senão, a de cá.
	return best_far if dry_line(here, best_far) else best_near


## O segmento de p a q não passa pela água (amostras a cada 0,5 m).
func dry_line(p: Vector2, q: Vector2) -> bool:
	var n := maxi(1, int(ceil(p.distance_to(q) / 0.5)))
	for k in range(n + 1):
		var r := p.lerp(q, float(k) / n)
		if is_water(r.x, r.y):
			return false
	return true


## Quantas pontes de r0 até r1 (0 = mesma região; INF = não dá).
func _hops(r0: int, r1: int) -> float:
	if r0 == r1:
		return 0.0
	var key := r0 * 100003 + r1
	if _route_cache.has(key):
		return _route_cache[key]
	var dist := {r0: 0}
	var q: Array = [r0]
	while not q.is_empty():
		var r: int = q.pop_front()
		for b in bridges:
			for s in 2:
				var a: int = b["ra"] if s == 0 else b["rb"]
				var o: int = b["rb"] if s == 0 else b["ra"]
				if a == r and o >= 0 and not dist.has(o):
					dist[o] = int(dist[r]) + 1
					q.append(o)
	var res: float = float(dist[r1]) if dist.has(r1) else INF
	_route_cache[key] = res
	return res


## Tira (x, y) da água: tenta ficar perto de onde estava (desliza na margem); senão, a terra mais perto.
func resolve(x: float, y: float, px: float, py: float) -> Vector2:
	if not is_water(x, y):
		return Vector2(x, y)
	if not is_water(x, py):
		return Vector2(x, py)
	if not is_water(px, y):
		return Vector2(px, y)
	if not is_water(px, py):
		return Vector2(px, py)
	return nearest_dry(x, y)


func nearest_dry(x: float, y: float) -> Vector2:
	for r in range(1, int(hw * 2.0 + 6.0)):
		var best := Vector2.INF
		var bd := INF
		for k in 16:
			var a := TAU * k / 16.0
			var p := Vector2(x + cos(a) * r, y + sin(a) * r)
			if not is_water(p.x, p.y):
				var d := p.distance_squared_to(Vector2(x, y))
				if d < bd:
					bd = d
					best = p
		if bd < INF:
			return best
	return Vector2(x, y)
