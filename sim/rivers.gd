class_name SimRivers
extends RefCounted
## Rios do mapa (15/11/2026). Cada ato tem 1 ou 2 rios e no máximo `max_bridges` pontes.
## Um rio vai de uma borda do mapa à outra (lado a lado ou na diagonal) ou volta para a mesma borda, e só corta
## a estrada em locais: esses locais viram Ponte (disputa). No resto ele corre pelos vãos entre os ramos.
##
## Topologia: a estrada é um grafo plano em níveis (0 = início, último = covil). Entre dois níveis, as ligações
## (que nunca se cruzam) dividem a faixa em "fatias"; no nível, os "vãos" entre nós vizinhos juntam a fatia de
## baixo com a de cima. As fatias ligadas por vãos formam as faces do grafo; E e D são as faces de fora (esquerda
## e direita). Uma ponte no nó v liga a face do vão à esquerda de v com a do vão à direita: o rio passa pelo nó
## de lado, com as ligações que chegam numa margem e as que saem na outra. Um rio é um caminho nesse grafo de
## faces: E -> ... -> D (atravessa) ou E -> ... -> E (vai e volta, um bolsão). O desenho no mundo e no minimapa
## sai dos mesmos pontos de controle (nó, vão, fatia, fora), cada um com as suas posições.

const DEF := {
	"max_bridges": 5,
	"second_chance": 0.35,
	"u_chance": 0.4,
	"half_width": 5.0,
	"clearance": 3.0,
	"node_clear": 13.0,
	"end_clear": 25.0,
	"edge_out": 60.0,
	"bridge_half": 8.0,
	"stub": 12.0,
	"tries": 80,
}

static var STATS := {}         # contagem de motivos de recusa (só para o teste e a prancha)
static var FAILS: Array = []   # depuração da prancha: rios recusados por encostar na estrada
static var DEBUG := false      # só as ferramentas (tools/river) ligam: no jogo nada disso é guardado


static func _stat(k: String) -> void:
	if not DEBUG:
		return
	STATS[k] = int(STATS.get(k, 0)) + 1


## Gera os rios. `levels`: ids dos nós por nível, cada nível em ordem de pista. Pode refazer as ligações que
## tocam as pontes (um trecho reto pela ponte, mesmo comprimento). Devolve a lista de rios.
static func generate(road: SimRoad, R: Dictionary, levels: Array) -> Array:
	var RV: Dictionary = DEF.duplicate()
	RV.merge(R.get("river", {}), true)
	var rr := RandomNumberGenerator.new()
	var key := ""
	for n in road.nodes:
		key += "%.2f,%.2f;" % [n["pos"].x, n["pos"].y]
	rr.seed = key.hash()
	var T := _topology(road, levels)
	if T.is_empty():
		return []
	var out: Array = []
	var budget := int(RV["max_bridges"])
	for which in 2:
		if which == 1 and (rr.randf() >= float(RV["second_chance"]) or budget < 2):
			break
		var used := {}
		for r in out:
			for n in r["bridges"]:
				used[n] = true
		var cands := _candidates(T, budget, used)
		var want_u := rr.randf() < float(RV["u_chance"])
		var pool: Array = cands.filter(func(c): return (c["kind"] == "u") == want_u)
		if pool.is_empty():
			pool = cands
		# Diagonal (16/11/2026, pedido dele): quase todo rio que atravessa sobe inclinado; o lado para onde sobe é sorteado.
		var tilt_want := 1 if rr.randf() < 0.5 else -1
		var diag := float(RV.get("diagonal_weight", 4.0))
		var pref := func(c: Dictionary) -> float:
			if c["kind"] != "cross":
				return 1.0
			var sl := _slope(T, c)
			if sl == 0:
				return float(RV.get("flat_weight", 0.5))
			return diag if signi(sl) == tilt_want else float(RV.get("other_diagonal_weight", 0.6))
		var tries := 0
		while not pool.is_empty() and tries < int(RV["tries"]):
			tries += 1
			var c: Dictionary = _pick(rr, pool, pref)
			pool.erase(c)
			if not _routes_ok(road, levels, c):
				_stat("routes")
				continue
			if _helper_room(road, levels, R, []) and not _helper_room(road, levels, R, c["bridges"] + used.keys()):
				_stat("helper_room")
				continue
			# Pontas inclinadas: a da esquerda mais perto do início e a da direita mais perto do covil (ou o contrário).
			var sl := _slope(T, c)
			c["tilt"] = (signi(sl) if sl != 0 else tilt_want) if c["kind"] == "cross" else 0
			var river := _realize(road, T, c, RV, rr, out)
			if not river.is_empty():
				out.append(river)
				budget -= c["bridges"].size()
				break
		if out.size() == which:
			_stat("act_without" if which == 0 else "no_second")
			_stat("pool_left_%d" % mini(pool.size(), 3))
			break   # o primeiro rio não coube: o ato fica sem rio (o teste conta quantas vezes)
	return out


# ---------------------------------------------------------------- topologia

static func _topology(road: SimRoad, levels: Array) -> Dictionary:
	var nl := levels.size()
	var at := {}    # nó -> [nível, índice]
	for l in nl:
		for j in levels[l].size():
			at[levels[l][j]] = [l, j]
	var trans: Array = []
	for t in nl - 1:
		var ls: Array = []
		for n in levels[t]:
			ls.append_array(road.nodes[n]["out"])
		ls.sort_custom(func(a, b):
			var ia: int = at[road.legs[a]["a"]][1]
			var ib: int = at[road.legs[b]["a"]][1]
			if ia != ib:
				return ia < ib
			return int(at[road.legs[a]["b"]][1]) < int(at[road.legs[b]["b"]][1]))
		trans.append(ls)
	var T := {"nl": nl, "at": at, "levels": levels, "trans": trans, "parent": {}}
	# Vão j do nível l: fatia de cima e de baixo; as duas são a mesma face.
	for l in nl:
		for j in levels[l].size() + 1:
			var u := _up(T, road, l, j)
			var d := _down(T, road, l, j)
			if u >= 0 and d >= 0:
				_union(T, u, d)
			elif u >= 0:
				_find(T, u)
			elif d >= 0:
				_find(T, d)
	T["E"] = _gap_face(T, road, 0, 0)
	T["D"] = _gap_face(T, road, 0, levels[0].size())
	if T["E"] == T["D"]:
		return {}
	# Arestas do grafo de faces: uma ponte possível por nó (nunca início, covil nem a fileira da Loja).
	var adj := {}
	for l in range(1, nl - 1):
		for i in levels[l].size():
			var n: int = levels[l][i]
			if int(road.nodes[n]["row"]) == road.shop_row:
				continue
			var fa := _gap_face(T, road, l, i)
			var fb := _gap_face(T, road, l, i + 1)
			if fa == fb:
				continue
			if not adj.has(fa):
				adj[fa] = []
			if not adj.has(fb):
				adj[fb] = []
			adj[fa].append({"n": n, "to": fb, "g_in": [l, i], "g_out": [l, i + 1]})
			adj[fb].append({"n": n, "to": fa, "g_in": [l, i + 1], "g_out": [l, i]})
	T["adj"] = adj
	return T


static func _slot_key(t: int, k: int) -> int:
	return t * 64 + k


## Fatia acima do vão (l, j): quantas ligações saem de nós à esquerda dele.
static func _up(T: Dictionary, road: SimRoad, l: int, j: int) -> int:
	if l >= int(T["nl"]) - 1:
		return -1
	var k := 0
	for e in T["trans"][l]:
		if int(T["at"][road.legs[e]["a"]][1]) < j:
			k += 1
	return _slot_key(l, k)


## Fatia abaixo do vão (l, j): quantas ligações chegam em nós à esquerda dele.
static func _down(T: Dictionary, road: SimRoad, l: int, j: int) -> int:
	if l <= 0:
		return -1
	var k := 0
	for e in T["trans"][l - 1]:
		if int(T["at"][road.legs[e]["b"]][1]) < j:
			k += 1
	return _slot_key(l - 1, k)


static func _gap_face(T: Dictionary, road: SimRoad, l: int, j: int) -> int:
	var u := _up(T, road, l, j)
	return _find(T, u if u >= 0 else _down(T, road, l, j))


static func _find(T: Dictionary, x: int) -> int:
	var P: Dictionary = T["parent"]
	if not P.has(x):
		P[x] = x
	var r := x
	while P[r] != r:
		r = P[r]
	while P[x] != r:
		var nx: int = P[x]
		P[x] = r
		x = nx
	return r


static func _union(T: Dictionary, a: int, b: int) -> void:
	var ra := _find(T, a)
	var rb := _find(T, b)
	if ra != rb:
		T["parent"][ra] = rb


# ---------------------------------------------------------------- candidatos

## Todos os caminhos no grafo de faces com até `budget` pontes: E -> D (atravessa) e E -> E / D -> D (vai e volta).
static func _candidates(T: Dictionary, budget: int, used: Dictionary) -> Array:
	var out: Array = []
	var maxb := mini(budget, 5)
	for side in [T["E"], T["D"]]:
		var other: int = T["D"] if side == T["E"] else T["E"]
		_dfs(T, side, side, other, [], {side: true}, maxb, used, out)
	return out


static func _dfs(T: Dictionary, f: int, side: int, other: int, path: Array, seen: Dictionary, maxb: int, used: Dictionary, out: Array) -> void:
	var adj: Dictionary = T["adj"]
	for ed in adj.get(f, []):
		if used.has(ed["n"]) or path.any(func(p): return p["n"] == ed["n"]):
			continue
		var to: int = ed["to"]
		var np: Array = path + [ed]
		if to == other:
			if side == T["E"]:   # D -> E é o mesmo rio de trás para a frente
				out.append({"kind": "cross", "side": side, "edges": np, "bridges": np.map(func(p): return p["n"])})
			continue
		if to == side:
			if np.size() >= 2:
				out.append({"kind": "u", "side": side, "edges": np, "bridges": np.map(func(p): return p["n"])})
			continue
		if seen.has(to) or np.size() >= maxb:
			continue
		seen[to] = true
		_dfs(T, to, side, other, np, seen, maxb, used, out)
		seen.erase(to)


## Sorteio com peso pelo número de pontes: 2 e 3 são o normal; 4 e 5 aparecem menos.
static func _pick(rr: RandomNumberGenerator, pool: Array, pref := Callable()) -> Dictionary:
	var W := {1: 0.2, 2: 1.0, 3: 1.0, 4: 0.45, 5: 0.2}
	var by_n := {}
	for c in pool:
		var n: int = c["bridges"].size()
		by_n[n] = int(by_n.get(n, 0)) + 1
	var ws: Array = []
	var tot := 0.0
	for c in pool:
		var n: int = c["bridges"].size()
		var w := float(W.get(n, 0.1)) / float(by_n[n]) * (float(pref.call(c)) if pref.is_valid() else 1.0)
		ws.append(w)
		tot += w
	var r := rr.randf() * tot
	for i in pool.size():
		r -= float(ws[i])
		if r <= 0.0:
			return pool[i]
	return pool[-1]


## Inclinação de um rio que atravessa (da esquerda para a direita): nível da última ponte menos o da primeira.
## Positivo = sobe para a direita (a direita fica mais perto do covil).
static func _slope(T: Dictionary, c: Dictionary) -> int:
	var b: Array = c["bridges"]
	var l0: int = T["at"][b[0]][0]
	var l1: int = T["at"][b[-1]][0]
	return l1 - l0 if c["side"] == T["E"] else l0 - l1


## O Herói Ajudante (SimRoad._place_helpers) precisa de um local comum numa fileira de 2+ locais entre
## `helper_rows`, fora da Loja. Uma fileira tem no máximo um Santuário, então basta sobrar uma fileira dessas com
## 2 locais que não são ponte.
static func _helper_room(road: SimRoad, levels: Array, R: Dictionary, bridges: Array) -> bool:
	if int(R.get("helpers", 0)) <= 0:
		return true
	var hr: Array = R.get("helper_rows", [2, 4])
	for l in range(1, levels.size() - 1):
		var row := int(road.nodes[levels[l][0]]["row"])
		if row < int(hr[0]) or row > int(hr[1]) or row == road.shop_row or levels[l].size() < 2:
			continue
		var free := 0
		for n in levels[l]:
			if not bridges.has(n):
				free += 1
		if free >= 2:
			return true
	return false


## Rio que atravessa: toda rota do início ao covil passa por exatamente uma ponte dele (duas deixariam o herói
## na margem errada). Vai e volta: 0 ou 2 (entra no bolsão por uma ponte e sai pela outra).
static func _routes_ok(road: SimRoad, levels: Array, c: Dictionary) -> bool:
	var is_b := {}
	for n in c["bridges"]:
		is_b[n] = true
	var cnt := {levels[0][0]: {0: true}}
	for l in levels.size():
		for n in levels[l]:
			var here: Dictionary = cnt.get(n, {})
			for e in road.nodes[n]["out"]:
				var b: int = road.legs[e]["b"]
				if not cnt.has(b):
					cnt[b] = {}
				var add := 1 if is_b.has(b) else 0
				for k in here:
					cnt[b][int(k) + add] = true
	var fin: Dictionary = cnt.get(levels[-1][0], {})
	for k in fin:
		if c["kind"] == "cross" and int(k) != 1:
			return false
		if c["kind"] == "u" and int(k) != 0 and int(k) != 2:
			return false
	return true


## Duas pontes ligadas direto por uma ligação não cabem: a ligação é curta demais para as duas cabeceiras retas
## e o rio teria de voltar logo para trás. A diagonal continua possível pulando uma fileira.
static func _linked_bridges(road: SimRoad, bridges: Array, used: Dictionary) -> bool:
	var all := {}
	for n in bridges:
		all[n] = true
	for n in used:
		all[n] = true
	for n in bridges:
		for e in road.nodes[n]["out"] + road.nodes[n]["in"]:
			var o: int = road.legs[e]["b"] if road.legs[e]["a"] == n else road.legs[e]["a"]
			if all.has(o):
				return true
	return false


# ---------------------------------------------------------------- desenho e validação

## Pontos de controle do rio: ["o", nó da ponta, outro nó do nível, lado] fora do mapa; ["n", nó] ponte;
## ["g", nóA, nóB] vão entre dois nós vizinhos; ["s", ligaçãoA, ligaçãoB] fatia entre duas ligações.
static func _ctrl(road: SimRoad, T: Dictionary, c: Dictionary) -> Array:
	var levels: Array = T["levels"]
	var E: Array = c["edges"]
	var ctrl: Array = []
	var s0: int = -1 if c["side"] == T["E"] else 1
	ctrl.append(_outside(levels, E[0]["g_in"][0], s0))
	for i in E.size():
		ctrl.append(["n", E[i]["n"]])
		if i + 1 < E.size():
			var fr := _face_route(road, T, E[i]["g_out"], E[i + 1]["g_in"])
			if fr.is_empty():
				return []
			ctrl.append_array(fr)
	var last: Dictionary = E[-1]
	var s1 := s0 if c["kind"] == "u" else -s0
	ctrl.append(_outside(levels, last["g_out"][0], s1))
	return ctrl


static func _outside(levels: Array, l: int, side: int) -> Array:
	var L: Array = levels[l]
	return ["o", L[0] if side < 0 else L[-1], L[-1] if side < 0 else L[0], side]


static func _gap_desc(T: Dictionary, g: Array) -> Array:
	var L: Array = T["levels"][g[0]]
	return ["g", L[g[1] - 1], L[g[1]]]


## Menor sequência vão -> fatia -> vão ... dentro de uma face, de vão a vão.
static func _face_route(road: SimRoad, T: Dictionary, ga: Array, gb: Array) -> Array:
	if ga == gb:
		return [_gap_desc(T, ga)]
	var levels: Array = T["levels"]
	var nl: int = T["nl"]
	var start := "g:%d:%d" % [ga[0], ga[1]]
	var goal := "g:%d:%d" % [gb[0], gb[1]]
	var prev := {start: ""}
	var q: Array = [start]
	while not q.is_empty() and not prev.has(goal):
		var x: String = q.pop_front()
		var p := x.split(":")
		var nb: Array = []
		if p[0] == "g":
			var l := int(p[1])
			var j := int(p[2])
			var u := _up(T, road, l, j)
			var d := _down(T, road, l, j)
			if u >= 0:
				nb.append("s:%d:%d" % [l, u % 64])
			if d >= 0:
				nb.append("s:%d:%d" % [l - 1, d % 64])
		else:
			var t := int(p[1])
			var k := int(p[2])
			for j in range(1, levels[t].size()):
				if _up(T, road, t, j) == _slot_key(t, k):
					nb.append("g:%d:%d" % [t, j])
			if t + 1 < nl:
				for j in range(1, levels[t + 1].size()):
					if _down(T, road, t + 1, j) == _slot_key(t, k):
						nb.append("g:%d:%d" % [t + 1, j])
		for y in nb:
			if not prev.has(y):
				prev[y] = x
				q.append(y)
	if not prev.has(goal):
		return []
	var chain: Array = []
	var cur := goal
	while cur != "":
		chain.push_front(cur)
		cur = prev[cur]
	var out: Array = []
	for s in chain:
		var p: PackedStringArray = str(s).split(":")
		if p[0] == "g":
			out.append(_gap_desc(T, [int(p[1]), int(p[2])]))
		else:
			var ls: Array = T["trans"][int(p[1])]
			var k := int(p[2])
			if k <= 0 or k >= ls.size():
				return []   # fatia de fora: não acontece entre duas pontes
			out.append(["s", ls[k - 1], ls[k]])
	return out


## Posição de um ponto de controle. `npos(n)` dá a posição do nó; `lmid(e)` o meio da ligação e.
static func ctrl_point(d: Array, npos: Callable, lmid: Callable, edge_out: float) -> Vector2:
	match str(d[0]):
		"n":
			return npos.call(d[1])
		"g":
			return (npos.call(d[1]) + npos.call(d[2])) * 0.5
		"s":
			return (lmid.call(d[1]) + lmid.call(d[2])) * 0.5
		"o":
			var a: Vector2 = npos.call(d[1])
			var b: Vector2 = npos.call(d[2])
			var across := (a - b).normalized() if a.distance_to(b) > 0.1 else Vector2(float(d[3]), 0.0)
			var p := a + across * edge_out
			if d.size() > 4 and int(d[4]) != 0:
				# Ponta inclinada: anda no sentido da estrada (-y no mundo e no mapa), para a frente do lado que sobe.
				var fwd := Vector2(0, -1) - across * across.dot(Vector2(0, -1))
				p += fwd.normalized() * float(d[3]) * float(d[4]) * edge_out * 0.6
			return p
	return Vector2.ZERO


## Linha do meio do rio: pontos de controle, um trecho reto de `bridge_half` de cada lado de cada ponte
## (atravessa a estrada de lado) e uma curva suave (Catmull-Rom) reamostrada a cada `step`.
static func polyline(ctrl: Array, npos: Callable, lmid: Callable, edge_out: float, bridge_half: float, step: float, axis_of := Callable()) -> PackedVector2Array:
	var P: Array = []
	for i in ctrl.size():
		P.append(ctrl_point(ctrl[i], npos, lmid, edge_out))
	var pts: Array = []
	for i in ctrl.size():
		if str(ctrl[i][0]) == "n":
			var u: Vector2 = (P[i + 1] - P[i - 1]).normalized()
			if axis_of.is_valid():
				var ax: Vector2 = axis_of.call(ctrl[i][1])
				var across := Vector2(-ax.y, ax.x)
				u = across if across.dot(u) >= 0.0 else -across
			pts.append(P[i] - u * bridge_half)
			pts.append(P[i])
			pts.append(P[i] + u * bridge_half)
		else:
			pts.append(P[i])
	# As pontas seguem mais um pouco para fora.
	pts.push_front(pts[0] + (pts[0] - pts[1]).normalized() * edge_out * 0.5)
	pts.append(pts[-1] + (pts[-1] - pts[-2]).normalized() * edge_out * 0.5)
	return _catmull(pts, step)


static func _catmull(p: Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array([p[0]])
	for i in p.size() - 1:
		var p0: Vector2 = p[maxi(0, i - 1)]
		var p1: Vector2 = p[i]
		var p2: Vector2 = p[i + 1]
		var p3: Vector2 = p[mini(p.size() - 1, i + 2)]
		var n := maxi(1, int(ceil(p1.distance_to(p2) / step)))
		for k in range(1, n + 1):
			var t := float(k) / n
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	return out


## Eixo da ponte no nó n: o sentido da estrada ali (do nível de baixo para o de cima).
static func bridge_axis(road: SimRoad, n: int) -> Vector2:
	var p: Vector2 = road.nodes[n]["pos"]
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	for e in road.nodes[n]["in"]:
		a += road.nodes[road.legs[e]["a"]]["pos"]
	for e in road.nodes[n]["out"]:
		b += road.nodes[road.legs[e]["b"]]["pos"]
	a /= maxf(1.0, road.nodes[n]["in"].size())
	b /= maxf(1.0, road.nodes[n]["out"].size())
	var d := (b - a)
	return d.normalized() if d.length() > 0.1 else (p - a).normalized()


static func _realize(road: SimRoad, T: Dictionary, c: Dictionary, RV: Dictionary, rr: RandomNumberGenerator, others: Array) -> Dictionary:
	var ctrl := _ctrl(road, T, c)
	if ctrl.is_empty():
		_stat("ctrl")
		return {}
	ctrl[0].append(int(c.get("tilt", 0)))
	ctrl[-1].append(int(c.get("tilt", 0)))
	# Ligações que tocam as pontes: um trecho reto pela ponte (o mesmo comprimento de antes).
	var bridges: Array = c["bridges"]
	# Refaz a transição inteira (todas as ligações entre os dois níveis) com um comprimento comum que caiba
	# os trechos retos: as rotas continuam todas do mesmo tamanho.
	var all_b: Array = bridges.duplicate()
	for o in others:
		all_b.append_array(o["bridges"])
	var tset := {}
	for n in bridges:
		for e in road.nodes[n]["in"] + road.nodes[n]["out"]:
			tset[_trans_of(T, e)] = true
	var touched := {}
	for t in tset:
		for e in T["trans"][t]:
			touched[e] = true
	var saved := {}
	for e in touched:
		saved[e] = [road.legs[e]["pts"][0], road.legs[e]["len"][0]]
	# A estrada de hoje já tem alguns cruzamentos no desenho: só recusa se a ponte criar um novo.
	var before := _legs_cross(road, touched, all_b, RV)
	# Rascunho do rio (pontos de controle, sem as fatias) para escolher o lado das curvas: em cada transição, as
	# ligações refeitas desviam todas para o mesmo lado (não se cruzam), o que fica mais longe do rio.
	var npos0 := func(n): return road.nodes[n]["pos"]
	var lmid0 := func(e): return SimRoad._point_on(road.legs[e]["pts"][0], float(road.legs[e]["len"][0]) * 0.5)
	var draft := polyline(ctrl, npos0, lmid0, float(RV["edge_out"]), float(RV["bridge_half"]), 4.0)
	var ok := true
	for t in tset:
		var target := 0.0
		for e in T["trans"][t]:
			target = maxf(target, maxf(float(road.legs[e]["len"][0]), _min_len(road, e, all_b, RV) * 1.04 + 3.0))
		var best_sgn := 0.0
		var best_score := -INF
		var seed_ := rr.randi()
		for sg in [1.0, -1.0]:
			var r2 := RandomNumberGenerator.new()
			r2.seed = seed_
			var fine := true
			for e in T["trans"][t]:
				if not _straighten(road, e, all_b, RV, r2, target, sg):
					fine = false
					break
			if fine:
				var sc := _score(road, T["trans"][t], all_b, draft, RV)
				if sc > best_score:
					best_score = sc
					best_sgn = sg
		if best_sgn == 0.0:
			_stat("straighten")
			ok = false
			break
		var r3 := RandomNumberGenerator.new()
		r3.seed = seed_
		for e in T["trans"][t]:
			_straighten(road, e, all_b, RV, r3, target, best_sgn)
	if ok:
		ok = _legs_cross(road, touched, all_b, RV) <= before
		if not ok:
			_stat("legs_cross")
	var pts := PackedVector2Array()
	if ok:
		pts = _route_world(road, T, c, ctrl, RV)
		if pts.is_empty():
			_stat("astar")
			ok = false
	if ok:
		# Meandro (16/11/2026): rio natural, sem trechos retos. Tenta a curva cheia, depois mais calma, depois a linha
		# do A*; fica a primeira que continua longe da estrada.
		var anchors: Array = bridges.map(func(n): return road.nodes[n]["pos"])
		var mseed := rr.randi()
		var fine := false
		for k in [1.0, 0.6, 0.3, 0.0]:
			var m := meander(pts, anchors, float(RV.get("meander_amp", 9.0)) * k, float(RV.get("meander_wl", 48.0)), mseed, float(RV["bridge_half"]) + 6.0, 3.0) if k > 0.0 else pts
			if _clear(road, m, bridges, RV, others):
				pts = m
				fine = true
				break
		ok = fine
	if not ok:
		for e in saved:
			road.legs[e]["pts"][0] = saved[e][0]
			road.legs[e]["len"][0] = saved[e][1]
		return {}
	return {"kind": c["kind"], "tilt": int(c.get("tilt", 0)), "slope": _slope(T, c) if c["kind"] == "cross" else 0, "bridges": bridges.duplicate(), "ctrl": ctrl, "pts": pts}


# ---------------------------------------------------------------- caminho no mundo

## Linha do meio no mundo: de fora do mapa até a 1ª ponte, de ponte em ponte e de volta para fora, cada trecho
## achado por A* numa grade que evita a estrada (e prefere o meio do corredor livre). Como as ligações fecham
## as faces, o caminho livre fica na mesma face do grafo; na ponte, o rio cruza reto, de lado.
static func _route_world(road: SimRoad, T: Dictionary, c: Dictionary, ctrl: Array, RV: Dictionary) -> PackedVector2Array:
	var F := _field(road, RV)
	var npos := func(n): return road.nodes[n]["pos"]
	var lmid := func(e): return SimRoad._point_on(road.legs[e]["pts"][0], float(road.legs[e]["len"][0]) * 0.5)
	var eo: float = RV["edge_out"]
	var bh: float = RV["bridge_half"]
	var far0 := ctrl_point(ctrl[0], npos, lmid, eo)
	var far1 := ctrl_point(ctrl[-1], npos, lmid, eo)
	var E: Array = c["edges"]
	var chain := PackedVector2Array([far0 + (far0 - ctrl_point(ctrl[1], npos, lmid, eo)).normalized() * eo * 0.5, far0])
	var cur := far0
	for ed in E:
		var n: int = ed["n"]
		var p: Vector2 = road.nodes[n]["pos"]
		var right := _right(road, T, n)
		var from_left: bool = int(ed["g_in"][1]) == int(T["at"][n][1])
		var u := right if from_left else -right
		var a := p - u * bh
		var b := p + u * bh
		var seg := _astar(F, cur, a)
		if seg.is_empty():
			return PackedVector2Array()
		chain.append_array(seg)
		chain.append(a)
		chain.append(p)
		chain.append(b)
		cur = b
	var last := _astar(F, cur, far1)
	if last.is_empty():
		return PackedVector2Array()
	chain.append_array(last)
	chain.append(far1)
	chain.append(far1 + (far1 - ctrl_point(ctrl[-2], npos, lmid, eo)).normalized() * eo * 0.5)
	return _resample_arr(_chaikin(_simplify(chain, 2.5), 3), 3.0)


## Chaikin: corta os cantos `it` vezes (as pontas ficam).
static func _chaikin(p: Array, it: int) -> Array:
	var cur := p
	for k in it:
		var nx: Array = [cur[0]]
		for i in cur.size() - 1:
			var a: Vector2 = cur[i]
			var b: Vector2 = cur[i + 1]
			nx.append(a.lerp(b, 0.25))
			nx.append(a.lerp(b, 0.75))
		nx.append(cur[-1])
		cur = nx
	return cur


## Meandro: desloca a linha para os lados com curvas alternadas (duas senoides de períodos diferentes e uma
## amplitude que varia devagar), como um rio de verdade. Perto das âncoras (as pontes) a curva some: a
## travessia fica reta. `step` é o espaçamento da linha reamostrada (o resultado tem o mesmo número de pontos).
## `room(p)`, se dado, é o espaço livre em volta do ponto p da linha original: o desvio nunca passa dele.
static func meander(pts: PackedVector2Array, anchors: Array, amp: float, wl: float, seed_: int, calm: float, step: float, room := Callable()) -> PackedVector2Array:
	var base := SimRoad._resample(_dedupe(pts), step)
	var r := RandomNumberGenerator.new()
	r.seed = seed_
	var f1 := r.randf() * TAU
	var f2 := r.randf() * TAU
	var f3 := r.randf() * TAU
	var wl2 := wl * r.randf_range(0.45, 0.6)
	var wl3 := wl * r.randf_range(2.4, 3.2)
	var out := PackedVector2Array()
	var s := 0.0
	for i in base.size():
		if i > 0:
			s += base[i].distance_to(base[i - 1])
		var a := base[maxi(0, i - 1)]
		var b := base[mini(base.size() - 1, i + 1)]
		var nrm := (b - a).normalized().orthogonal()
		var dmin := INF
		for q in anchors:
			dmin = minf(dmin, base[i].distance_to(q))
		var t := clampf((dmin - calm) / maxf(calm, 1.0), 0.0, 1.0)
		var fade := t * t * (3.0 - 2.0 * t)
		# Curvas irregulares: a fase acelera e freia (curvas longas e fechadas), a altura de cada curva varia
		# e um desvio bem longo leva o rio de um lado para o outro.
		var ph := TAU * s / wl + f1 + 1.3 * sin(TAU * s / (wl * 2.2) + f3)
		var w := sin(ph) * 0.85 + sin(TAU * s / wl2 + f2) * 0.08
		var big := 0.45 + 0.55 * (0.5 + 0.5 * sin(TAU * s / wl3 + f3 * 1.7))
		var drift := 0.6 * sin(TAU * s / (wl * 4.5) + f2 * 1.3)
		var d := amp * fade * (big * w + drift)
		if room.is_valid():
			var lim: float = maxf(0.0, float(room.call(base[i])))
			d = clampf(d, -lim, lim)
		out.append(base[i] + nrm * d)
	# Uma passada de média tira qualquer quina.
	var sm := out.duplicate()
	for i in range(1, out.size() - 1):
		sm[i] = (out[i - 1] + out[i] * 2.0 + out[i + 1]) * 0.25
	return sm


## Desfaz laços: onde a linha cruza a si mesma, corta o trecho entre os dois cruzamentos e liga pelo ponto de
## encontro; depois tira bicos (pontos em que a linha quase volta para trás).
static func untangle(p: PackedVector2Array) -> PackedVector2Array:
	var pts := p.duplicate()
	var guard := 0
	var changed := true
	while changed and guard < 50:
		changed = false
		guard += 1
		for i in pts.size() - 1:
			for j in range(i + 2, pts.size() - 1):
				var x = Geometry2D.segment_intersects_segment(pts[i], pts[i + 1], pts[j], pts[j + 1])
				if x != null:
					var np := pts.slice(0, i + 1)
					np.append(x)
					np.append_array(pts.slice(j + 1))
					pts = np
					changed = true
					break
			if changed:
				break
	var out := PackedVector2Array()
	for i in pts.size():
		if i > 0 and i < pts.size() - 1 and out.size() > 0:
			var a := (pts[i] - out[-1]).normalized()
			var b := (pts[i + 1] - pts[i]).normalized()
			if a.dot(b) < -0.2:
				continue
		out.append(pts[i])
	return out


static func _dedupe(p: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in p:
		if out.is_empty() or out[-1].distance_to(q) > 0.01:
			out.append(q)
	return out


static func _resample_arr(p: Array, step: float) -> PackedVector2Array:
	return SimRoad._resample(PackedVector2Array(p), step)


## Direção "para a direita" (pista crescente) atravessando a estrada no nó n.
static func _right(road: SimRoad, T: Dictionary, n: int) -> Vector2:
	var ax := bridge_axis(road, n)
	var r := Vector2(-ax.y, ax.x)
	var L: Array = T["levels"][T["at"][n][0]]
	var d: Vector2 = road.nodes[L[-1]]["pos"] - road.nodes[L[0]]["pos"]
	return r if r.dot(d) >= 0.0 else -r


static func _field(road: SimRoad, RV: Dictionary) -> Dictionary:
	var cell := 24.0
	var grid := {}
	for g in road.legs:
		var lp: PackedVector2Array = g["pts"][0]
		for i in lp.size() - 1:
			var lo := lp[i].min(lp[i + 1]) - Vector2(cell, cell)
			var hi := lp[i].max(lp[i + 1]) + Vector2(cell, cell)
			for gx in range(int(floor(lo.x / cell)), int(floor(hi.x / cell)) + 1):
				for gy in range(int(floor(lo.y / cell)), int(floor(hi.y / cell)) + 1):
					var k := Vector2i(gx, gy)
					if not grid.has(k):
						grid[k] = []
					grid[k].append([lp[i], lp[i + 1]])
	return {"cell": cell, "grid": grid, "memo": {}, "need": float(RV["half_width"]) + float(RV["clearance"]) + 0.6, "step": 2.5}


## Distância até a estrada (até 24 m), guardada por célula da grade do A*.
static func _dist(F: Dictionary, c: Vector2i) -> float:
	var memo: Dictionary = F["memo"]
	if memo.has(c):
		return memo[c]
	var p := Vector2(c) * float(F["step"])
	var k := Vector2i(int(floor(p.x / F["cell"])), int(floor(p.y / F["cell"])))
	var best := float(F["cell"])
	for s in F["grid"].get(k, []):
		best = minf(best, Geometry2D.get_closest_point_to_segment(p, s[0], s[1]).distance_to(p))
	memo[c] = best
	return best


static func _astar(F: Dictionary, a: Vector2, b: Vector2) -> PackedVector2Array:
	var st: float = F["step"]
	var need: float = F["need"]
	var ca := Vector2i(roundi(a.x / st), roundi(a.y / st))
	var cb := Vector2i(roundi(b.x / st), roundi(b.y / st))
	var g := {ca: 0.0}
	var prev := {ca: ca}
	var heap: Array = [[0.0, ca]]
	var closed := {}
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var budget := 40000
	while not heap.is_empty() and budget > 0:
		budget -= 1
		var top: Array = _hpop(heap)
		var c: Vector2i = top[1]
		if closed.has(c):
			continue
		closed[c] = true
		if c == cb:
			break
		for d in dirs:
			var nc: Vector2i = c + d
			if closed.has(nc):
				continue
			var dd := _dist(F, nc)
			# Perto das pontas (as cabeceiras da ponte) o caminho pode encostar: o trecho reto da ponte cuida dali.
			var near_end := Vector2(nc - ca).length() * st < need + 1.0 or Vector2(nc - cb).length() * st < need + 1.0
			if dd < need and not near_end:
				continue
			var step_len := st * (1.4142 if d.x != 0 and d.y != 0 else 1.0)
			var ng: float = float(g[c]) + step_len * (1.0 + 10.0 / maxf(dd - need + 2.0, 1.0))
			if ng < float(g.get(nc, INF)):
				g[nc] = ng
				prev[nc] = c
				_hpush(heap, [ng + Vector2(cb - nc).length() * st, nc])
	if not prev.has(cb):
		return PackedVector2Array()
	var out := PackedVector2Array()
	var cur := cb
	while cur != ca:
		out.append(Vector2(cur) * st)
		cur = prev[cur]
	out.reverse()
	return out


static func _hpush(h: Array, x: Array) -> void:
	h.append(x)
	var i := h.size() - 1
	while i > 0:
		var p := (i - 1) >> 1
		if float(h[p][0]) <= float(h[i][0]):
			break
		var t = h[p]
		h[p] = h[i]
		h[i] = t
		i = p


static func _hpop(h: Array) -> Array:
	var top: Array = h[0]
	var last: Array = h.pop_back()
	if h.is_empty():
		return top
	h[0] = last
	var i := 0
	while true:
		var l := 2 * i + 1
		var r := l + 1
		var m := i
		if l < h.size() and float(h[l][0]) < float(h[m][0]):
			m = l
		if r < h.size() and float(h[r][0]) < float(h[m][0]):
			m = r
		if m == i:
			break
		var t = h[m]
		h[m] = h[i]
		h[i] = t
		i = m
	return top


## Ramer-Douglas-Peucker: tira a escada da grade antes de suavizar.
static func _simplify(p: PackedVector2Array, eps: float) -> Array:
	if p.size() < 3:
		return Array(p)
	var keep := {0: true, p.size() - 1: true}
	var stack: Array = [[0, p.size() - 1]]
	while not stack.is_empty():
		var r: Array = stack.pop_back()
		var dmax := 0.0
		var idx := -1
		for i in range(r[0] + 1, r[1]):
			var d := Geometry2D.get_closest_point_to_segment(p[i], p[r[0]], p[r[1]]).distance_to(p[i])
			if d > dmax:
				dmax = d
				idx = i
		if idx >= 0 and dmax > eps:
			keep[idx] = true
			stack.append([r[0], idx])
			stack.append([idx, r[1]])
	var out: Array = []
	for i in p.size():
		if keep.has(i):
			out.append(p[i])
	return out


## Quão longe do rascunho do rio ficam as ligações (fora dos trechos retos das pontes): maior é melhor.
static func _score(road: SimRoad, legs: Array, bridges: Array, draft: PackedVector2Array, RV: Dictionary) -> float:
	var st: float = float(RV["stub"]) + 0.05
	var best := INF
	for e in legs:
		var lp: PackedVector2Array = road.legs[e]["pts"][0]
		for p in lp:
			var skip := false
			for n in bridges:
				if p.distance_to(road.nodes[n]["pos"]) <= st:
					skip = true
					break
			if skip:
				continue
			for q in draft:
				best = minf(best, p.distance_squared_to(q))
	return sqrt(best)


static func _trans_of(T: Dictionary, e: int) -> int:
	for t in T["trans"].size():
		if T["trans"][t].has(e):
			return t
	return -1


## Comprimento mínimo da ligação e com os trechos retos nas pontas que são ponte.
static func _min_len(road: SimRoad, e: int, bridges: Array, RV: Dictionary) -> float:
	var g: Dictionary = road.legs[e]
	var a: Vector2 = road.nodes[g["a"]]["pos"]
	var b: Vector2 = road.nodes[g["b"]]["pos"]
	var st: float = RV["stub"]
	var used := 0.0
	if bridges.has(g["a"]):
		a += bridge_axis(road, g["a"]) * st
		used += st
	if bridges.has(g["b"]):
		b -= bridge_axis(road, g["b"]) * st
		used += st
	return used + a.distance_to(b)


## Refaz a ligação e com um trecho reto de `stub` m no eixo da ponte em cada ponta que é ponte; o meio
## volta a ser um desvio com o mesmo comprimento total (todas as rotas continuam do mesmo tamanho).
static func _straighten(road: SimRoad, e: int, bridges: Array, RV: Dictionary, rr: RandomNumberGenerator, target: float, force_sgn := 0.0) -> bool:
	var g: Dictionary = road.legs[e]
	var a: Vector2 = road.nodes[g["a"]]["pos"]
	var b: Vector2 = road.nodes[g["b"]]["pos"]
	var st: float = RV["stub"]
	var a2 := a
	var b2 := b
	var head := PackedVector2Array([a])
	var used := 0.0
	if bridges.has(g["a"]):
		a2 = a + bridge_axis(road, g["a"]) * st
		used += st
	if bridges.has(g["b"]):
		b2 = b - bridge_axis(road, g["b"]) * st
		used += st
	var mid_t := target - used
	if a2.distance_to(b2) > mid_t - 0.5:
		return false
	var lo := 0.0
	var hi := 80.0
	var h := 0.0
	var t1 := rr.randf_range(0.3, 0.4)
	var t2 := rr.randf_range(0.6, 0.7)
	# O novo desvio vai para o mesmo lado do antigo (_dogleg desvia para (b - a).normalized().orthogonal() * h).
	var side := (_straight_mid(road, g) - (a + b) * 0.5).dot((b2 - a2).normalized().orthogonal())
	var sgn := 1.0 if side >= 0.0 else -1.0
	if force_sgn != 0.0:
		# O lado é dado para a transição no sentido do eixo da estrada: vira o sinal para esta ligação.
		var fwd := (b2 - a2).normalized().orthogonal()
		var ref := Vector2(0, -1).orthogonal()
		sgn = force_sgn * (1.0 if fwd.dot(ref) >= 0.0 else -1.0)
	for it in 50:
		h = (lo + hi) * 0.5
		var l := SimRoad._length(SimRoad._resample(SimRoad._dogleg(a2, b2, h * sgn, t1, t2), 6.0))
		if absf(l - mid_t) < 0.01:
			break
		if l < mid_t:
			lo = h
		else:
			hi = h
	var poly := PackedVector2Array()
	if a2 != a:
		poly.append(a)
	poly.append_array(SimRoad._dogleg(a2, b2, h * sgn, t1, t2))
	if b2 != b:
		poly.append(b)
	var pts := SimRoad._resample(poly, 6.0)
	var l2 := SimRoad._length(pts)
	if absf(l2 - target) > 0.3:
		return false
	g["pts"][0] = pts
	g["len"][0] = l2
	return true


## Meio do desvio antigo da ligação (para o novo desvio ir para o mesmo lado e não cruzar as vizinhas).
static func _straight_mid(road: SimRoad, g: Dictionary) -> Vector2:
	var pts: PackedVector2Array = g["pts"][0]
	return SimRoad._point_on(pts, SimRoad._length(pts) * 0.5)


## As ligações refeitas não cruzam nenhuma outra (fora dos nós e do trecho reto comum das pontes).
static func _legs_cross(road: SimRoad, touched: Dictionary, bridges: Array, RV: Dictionary) -> int:
	var st: float = float(RV["stub"]) + 0.1
	var count := 0
	for e in touched:
		var A: PackedVector2Array = road.legs[e]["pts"][0]
		for f in road.legs.size():
			if f == e:
				continue
			var B: PackedVector2Array = road.legs[f]["pts"][0]
			for i in A.size() - 1:
				for j in B.size() - 1:
					var x = Geometry2D.segment_intersects_segment(A[i], A[i + 1], B[j], B[j + 1])
					if x == null:
						continue
					var skip := false
					for n in road.nodes:
						if (x as Vector2).distance_to(n["pos"]) < 0.6:
							skip = true
							break
					for n in bridges:
						if (x as Vector2).distance_to(road.nodes[n]["pos"]) <= st:
							skip = true
					if not skip:
						count += 1
	return count


## O rio fica longe da estrada (a não ser no trecho reto da ponte), dos outros locais, do início, do covil
## e dos outros rios; os rios anteriores também são conferidos de novo (as ligações refeitas podem chegar neles).
static func _clear(road: SimRoad, pts: PackedVector2Array, bridges: Array, RV: Dictionary, others: Array) -> bool:
	# O rio não encosta em si mesmo (uma curva fechada demais vira uma mancha de água).
	var self_d := 2.0 * float(RV["half_width"]) + 3.0
	var gap_i := int(ceil(self_d * 2.5 / 3.0))
	for i in pts.size():
		for j in range(i + gap_i, pts.size()):
			if pts[i].distance_squared_to(pts[j]) < self_d * self_d:
				_stat("self")
				return false
	if not _clear_legs(road, pts, bridges, RV):
		_stat("road")
		return false
	for o in others:
		if not _clear_legs(road, o["pts"], o["bridges"], RV):
			_stat("road_other")
			return false
	var nclear: float = RV["node_clear"]
	var eclear: float = RV["end_clear"]
	for ni in road.nodes.size():
		if bridges.has(ni):
			continue
		var np: Vector2 = road.nodes[ni]["pos"]
		var lim := eclear if road.nodes[ni]["in"].is_empty() or road.nodes[ni]["out"].is_empty() else nclear
		for p in pts:
			if p.distance_to(np) < lim:
				_stat("node")
				return false
	var rclear := 2.0 * float(RV["half_width"]) + 8.0
	for o in others:
		var op: PackedVector2Array = o["pts"]
		for p in pts:
			for q in op:
				if p.distance_squared_to(q) < rclear * rclear:
					_stat("river")
					return false
	return true


static func _clear_legs(road: SimRoad, pts: PackedVector2Array, bridges: Array, RV: Dictionary) -> bool:
	var need: float = float(RV["half_width"]) + float(RV["clearance"])
	var st: float = float(RV["stub"]) + 0.05
	var segs: Array = []
	for g in road.legs:
		var lp: PackedVector2Array = g["pts"][0]
		for i in lp.size() - 1:
			var near := false
			for n in bridges:
				var bp: Vector2 = road.nodes[n]["pos"]
				if lp[i].distance_to(bp) <= st and lp[i + 1].distance_to(bp) <= st:
					near = true
					break
			if not near:
				segs.append([lp[i], lp[i + 1]])
	# Grade simples para não comparar cada ponto com cada trecho.
	var cell := 24.0
	var grid := {}
	for s in segs:
		var lo := Vector2(minf(s[0].x, s[1].x), minf(s[0].y, s[1].y)) - Vector2(need, need)
		var hi := Vector2(maxf(s[0].x, s[1].x), maxf(s[0].y, s[1].y)) + Vector2(need, need)
		for gx in range(int(floor(lo.x / cell)), int(floor(hi.x / cell)) + 1):
			for gy in range(int(floor(lo.y / cell)), int(floor(hi.y / cell)) + 1):
				var k := Vector2i(gx, gy)
				if not grid.has(k):
					grid[k] = []
				grid[k].append(s)
	for p in pts:
		var k := Vector2i(int(floor(p.x / cell)), int(floor(p.y / cell)))
		for s in grid.get(k, []):
			if Geometry2D.get_closest_point_to_segment(p, s[0], s[1]).distance_to(p) < need:
				if not DEBUG:
					return false
				var dn := INF
				for n in bridges:
					dn = minf(dn, p.distance_to(road.nodes[n]["pos"]))
				var di := pts.find(p)
				_stat("road_b%d" % mini(int(dn / 5.0), 6))
				FAILS.append({"pts": pts, "p": p, "s": s})
				for e in road.legs.size():
					var lp2: PackedVector2Array = road.legs[e]["pts"][0]
					var k2 := lp2.find(s[0])
					if k2 >= 0 and k2 + 1 < lp2.size() and lp2[k2 + 1] == s[1]:
						var ga: int = road.legs[e]["a"]
						var gb: int = road.legs[e]["b"]
						var inc := "inc" if bridges.has(ga) or bridges.has(gb) else "other"
						_stat("road_%s_k%d_of%d" % [inc, k2, lp2.size() - 1])
						break
				_stat("road_i%s" % ("end" if di < 25 or di > pts.size() - 25 else "mid"))
				return false
	return true
