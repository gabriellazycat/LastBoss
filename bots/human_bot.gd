class_name HumanBot
extends PlayerBot
## Bot "humano" (10/11/2026): joga como uma pessoa que já entendeu o jogo, com os limites de uma pessoa.
##
## Limites humanos:
##  - tempo de reação: pensa a cada `think_min`..`think_max` s de jogo, e faz no máximo uma jogada por vez
##    (duas quando há uma janela clara, como o escudo quebrado);
##  - mira imprecisa: o ponto de soltar a carta tem um erro de `aim_error` m;
##  - erros: com `mistake` de chance joga uma carta qualquer, e com `lapse` de chance se distrai e não joga;
##  - só usa o que está na tela: posição, vida, escudo, para onde o herói olha, ícones de estado (encharcado,
##    preso, lento), monstros, locais e o mapa. Nada do mapa de perigo nem da escolha interna do herói.
##
## Jogo (o que um humano bom faz):
##  - junta elixir e solta uma onda de monstros de uma vez (`wave`), em vez de pingar um por um;
##  - aproveita janelas: escudo quebrado, herói preso, encharcado ou com pouca vida -> gasta tudo na hora;
##  - põe corpo a corpo pelos lados e por trás do escudo, atiradores longe e atrás, tanques na frente;
##  - feitiço onde pega mais heróis (fase de grupo) e adiantado ao passo do herói;
##  - fase de grupo: concentra os monstros no herói mais fraco;
##  - disputas, combos, ofertas, rota e arena como o bot heurístico (o que ele faz bem fica).
##
## Robustez: toda jogada passa por `hands` (o Sim direto, ou a entrada real da janela no --humantest);
## jogada recusada tenta outro ponto uma vez; carta presa na mão vira sacrifício; oferta que não aceita a
## escolha é pulada; bifurcação sem resposta segue o primeiro ramo. Os tropeços contam em `stats`.

## Executor das jogadas. Sem janela é o próprio Sim; no --humantest, o nó que move o mouse.
var hands: Object = null
var stats := {"plays": 0, "retries": 0, "refused": 0, "sacrifices": 0, "mistakes": 0, "lapses": 0, "waves": 0,
	"stuck_dumps": 0, "offer_skips": 0, "route_fallbacks": 0}
var _stuck_since := -1.0
var _avoid := {}   # carta -> até quando não tentar de novo (a jogada falhou na interface; a pessoa desiste um pouco)


## A jogada desta carta não saiu (teste com mouse): não tenta de novo por avoid_s s.
func avoid_card(id: String, t: float) -> void:
	_avoid[id] = t + float(P.get("avoid_s", 15.0))


func think(sim: Sim) -> void:
	if hands == null:
		hands = sim
	if hands != sim and hands.has_method("busy") and hands.busy():
		return
	if sim.phase == K.Phase.OVER:
		return
	if sim.offers.size() > 0:
		_human_offer(sim)
		return
	if sim.route_wait:
		var n := _pick_route(sim)
		if n < 0 or not hands.choose_route(n):
			stats["route_fallbacks"] += 1
			var outs: Array = sim.road.nodes[sim.road.head]["out"]
			if outs.size() > 0:
				hands.choose_route(sim.road.legs[outs[0]]["b"])
		return
	if sim.t < next_t:
		return
	next_t = sim.t + rng.randf_range(float(P.get("think_min", 0.35)), float(P.get("think_max", 0.8)))
	if rng.randf() < float(P.get("lapse", 0.03)):
		stats["lapses"] += 1
		return
	if sim.phase == K.Phase.ARENA:
		_smart_arena_h(sim)
	# Duas jogadas seguidas só sem janela de teste: com o mouse, a segunda sairia sem o elixir que a primeira gastou.
	var acts := 2 if _window(sim) and hands == sim else 1
	for _k in acts:
		if not _act(sim):
			break


## Oferta: a escolha do heurístico; se o Sim recusar, pula; se nem pular dá, a primeira opção que entrar.
func _human_offer(sim: Sim) -> void:
	var k := _pick_offer(sim)
	if hands.choose(k):
		return
	stats["offer_skips"] += 1
	if hands.choose(Sim.SKIP):
		return
	for j in sim.offers[0]["options"].size():
		if hands.choose(j):
			return


## Janela de ataque visível: escudo quebrado, herói preso/petrificado/encharcado, ou com pouca vida.
func _window(sim: Sim) -> bool:
	var h := sim.hero
	return h.shield_max > 0.0 and h.shield_hp <= 0.0 or h.root_t > 0.0 or h.petrify_t > 0.0 \
		or h.soaked_t > 1.0 or h.hp_frac() < 0.3


## Uma jogada (ou nada). Devolve true se jogou.
func _act(sim: Sim) -> bool:
	if sim.hand.is_empty():
		return false
	# Carta morta (fora de fase, condição, limite): sacrifica na hora, como uma pessoa limpando a mão.
	for i in sim.hand.size():
		if sim.hand[i] == null:
			continue
		var b := sim.can_play(i)
		if b == K.Block.WRONG_PHASE or b == K.Block.STACK_LIMIT:
			if hands.sacrifice(i):
				stats["sacrifices"] += 1
				return true
	var h := sim.hero
	# Disputa à frente (Ponte, Fonte): guarda elixir até ela abrir.
	var contest := _contest_ahead(sim)
	var ctype := str(contest.get("type", ""))
	var guard := {}
	if ctype in ["bridge", "fountain"] and not contest["entered"] and sim.elixir < float(P.get("contest_reserve", 6)):
		return false
	if ctype in ["ritual", "tavern"]:
		if Vector2(h.x, h.y).distance_to(contest["pos"]) <= 18.0 or contest["entered"]:
			guard = contest
	var shrine := _shrine_ahead(sim)
	if shrine.size() > 0 and not shrine["entered"] and sim.elixir < float(P.get("shrine_reserve", 0)):
		return false
	var spot: Dictionary = shrine if shrine.size() > 0 and shrine["entered"] else guard
	# Onda: espera juntar elixir, a menos que haja janela, disputa em andamento ou elixir quase cheio.
	var urgent := _window(sim) or spot.size() > 0 or not sim.contest.is_empty() or sim.phase == K.Phase.ARENA
	var full := sim.elixir >= sim.elixir_max - float(P.get("full_margin", 1.0))
	if not urgent and not full and sim.elixir < float(P.get("wave", 6.0)) and _engaged(sim) == 0:
		return false
	var mistake := rng.randf() < float(P.get("mistake", 0.02))
	var best := -1
	var best_v := 0.0
	for i in sim.hand.size():
		if sim.hand[i] == null or sim.can_play(i) != K.Block.OK:
			continue
		if float(_avoid.get(sim.hand[i].def.id, -1.0)) > sim.t:
			continue
		var v := _human_value(sim, sim.hand[i]) if not mistake else rng.randf() * 5.0 + 0.1
		if v > best_v:
			best_v = v
			best = i
	if best < 0:
		return _maybe_dump(sim, full)
	_stuck_since = -1.0
	var c: Sim.CardInst = sim.hand[best]
	if sim.phase == K.Phase.ARENA and sim.elixir - sim.card_cost(c) < float(P.get("teleport_reserve", 2.0)) and sim.arena.tp_cd <= 0.0:
		return false
	if mistake:
		stats["mistakes"] += 1
	var pos := _human_target(sim, c, spot)
	if not mistake:
		pos += Vector2(rng.randfn(0.0, 1.0), rng.randfn(0.0, 1.0)) * float(P.get("aim_error", 0.5))
	var r: int = hands.play(best, pos.x, pos.y)
	if r == K.Block.BAD_TARGET:
		# Soltou perto demais do herói (ou fora do mapa): tenta de novo um pouco mais longe.
		stats["retries"] += 1
		var hp := Vector2(h.x, h.y)
		var dir := (pos - hp)
		dir = dir.normalized() if dir.length() > 0.1 else -Vector2(h.face_x, h.face_y)
		pos = hp + dir * (float(sim.R["ring"]["min"]) + 1.0)
		r = hands.play(best, pos.x, pos.y)
	if r != K.Block.OK:
		stats["refused"] += 1
		return false
	stats["plays"] += 1
	if sim.elixir < 1.0:
		stats["waves"] += 1
	return true


## Nada para jogar há um tempo com o elixir cheio: troca a carta que menos vale por elixir.
func _maybe_dump(sim: Sim, full: bool) -> bool:
	if not full:
		_stuck_since = -1.0
		return false
	if _stuck_since < 0.0:
		_stuck_since = sim.t
		return false
	if sim.t - _stuck_since < float(P.get("dump_after", 3.0)) or not sim.sacrifice_ready():
		return false
	var worst := -1
	var wv := INF
	for i in sim.hand.size():
		if sim.hand[i] == null:
			continue
		var v := _human_value(sim, sim.hand[i])
		if v < wv:
			wv = v
			worst = i
	if worst >= 0 and hands.sacrifice(worst):
		stats["stuck_dumps"] += 1
		_stuck_since = -1.0
		return true
	return false


## Monstros seus brigando perto do herói da vez (até 4 m).
func _engaged(sim: Sim) -> int:
	var U := sim.units
	var n := 0
	for i in U.hi:
		if U.alive[i] == 1 and U.arch[i] != K.Arch.STRUCTURE:
			if Vector2(U.px[i] - sim.hero.x, U.py[i] - sim.hero.y).length_squared() < 16.0:
				n += 1
	return n


## Valor da carta agora: o do heurístico (custo, raridade, combos, famílias) mais o que se vê na tela.
func _human_value(sim: Sim, c: Sim.CardInst) -> float:
	var v := _smart_value(sim, c)
	if v < 0.0:
		return v
	var d := c.def
	var h := sim.hero
	if d.is_spell and d.category == "field":
		var n := _spell_hits(sim, c)
		if n == 0 and needs_hit(d):
			return -1.0
		v += float(P.get("group_spell", 1.5)) * maxf(0.0, n - 1.0)
		if d.ai.get("lingers", false) and (h.root_t > 0.0 or h.petrify_t > 0.0):
			v += 1.0   # alvo parado: a zona pega com certeza
	elif d.is_unit:
		if h.shield_max > 0.0 and h.shield_hp <= 0.0:
			v += float(P.get("shield_window", 1.5))
		if h.hp_frac() < 0.3:
			v += 1.0
	return v


## Quantos heróis o feitiço pega se cair no melhor ponto.
func _spell_hits(sim: Sim, c: Sim.CardInst) -> int:
	var d := c.def
	var r := float(d.fx.get("radius", 2.5))
	match aim_of(d):
		"line":
			return _bolt_line(sim, d.fx)[1]
		"soaked":
			var n := 0
			for hh in sim.all_heroes():
				if hh.soaked_t > 0.3:
					n += 1
			return n
		"own_unit":
			return 1 if _own_near_hero(sim, 4.0) >= 0 else 0
	return _cluster(sim, r)[1]


## Ponto que pega mais heróis num raio r (centro de cada herói e pontos médios dos pares). [ponto, quantos]
func _cluster(sim: Sim, r: float) -> Array:
	var hs: Array = sim.all_heroes()
	var cands: Array = []
	for a in hs:
		cands.append(_lead(sim, a))
	for i in hs.size():
		for j in range(i + 1, hs.size()):
			cands.append((_lead(sim, hs[i]) + _lead(sim, hs[j])) * 0.5)
	var best: Vector2 = cands[0]
	var bn := 0
	for p in cands:
		var n := 0
		for hh in hs:
			if Vector2(hh.x, hh.y).distance_to(p) <= r + hh.radius - 0.3:
				n += 1
		if n > bn:
			bn = n
			best = p
	return [best, bn]


## Onde o herói vai estar daqui a pouco (a pessoa adianta a mira pelo passo dele).
func _lead(_sim: Sim, hh: SimHero) -> Vector2:
	var v := Vector2(hh.x - hh.ox, hh.y - hh.oy) / maxf(_sim.dt, 0.001)
	return Vector2(hh.x, hh.y) + v.limit_length(6.0) * float(P.get("lead_s", 0.4))


## Feitiço em linha (Raio Sombrio): de que ponto atirar para a linha passar por mais heróis. [origem, quantos]
func _bolt_line(sim: Sim, fx: Dictionary) -> Array:
	var hs: Array = sim.all_heroes()
	var L := float(fx.get("length", 10.0))
	var W := float(fx.get("width", 1.5))
	var best := [Vector2(sim.hero.x, sim.hero.y) - Vector2(sim.hero.face_x, sim.hero.face_y) * 3.0, 1]
	for a in hs:
		for b in hs:
			var pa := Vector2(a.x, a.y)
			var pb := Vector2(b.x, b.y)
			var dir := (pb - pa).normalized() if a != b else -Vector2(a.face_x, a.face_y)
			var o := pa - dir * 2.0
			var n := 0
			for hh in hs:
				var rel := Vector2(hh.x, hh.y) - o
				var along := rel.dot(dir)
				var side := absf(rel.dot(Vector2(-dir.y, dir.x)))
				if along >= -0.5 and along <= L and side <= W * 0.5 + hh.radius - 0.2:
					n += 1
			if n > int(best[1]):
				best = [o, n]
	return best


## Herói que os monstros devem caçar: na fase de grupo, o de pé com menos vida (até 12 m do da vez).
func _focus(sim: Sim) -> SimHero:
	var t: SimHero = sim.hero
	for f in sim.followers:
		if Vector2(f.x - sim.hero.x, f.y - sim.hero.y).length() < 12.0 and f.hp < t.hp:
			t = f
	return t


func _human_target(sim: Sim, c: Sim.CardInst, spot: Dictionary) -> Vector2:
	var d := c.def
	if d.category != "field":
		return _target(sim, c, false)
	if d.is_spell:
		match aim_of(d):
			"line":
				return _bolt_line(sim, d.fx)[0]
			"soaked":
				for hh in sim.all_heroes():
					if hh.soaked_t > 0.3:
						return _lead(sim, hh)
			"own_unit", "ahead":
				return _target(sim, c, false)
			"cluster":
				return _cluster(sim, float(d.fx.get("radius", 3.0)))[0]
		return _lead(sim, sim.hero)
	if sim.phase == K.Phase.ARENA:
		return _smart_target(sim, c, {})
	if spot.size() > 0:
		return _smart_target(sim, c, spot)
	var tgt := _focus(sim)
	var hp := _lead(sim, tgt)
	var face := Vector2(tgt.face_x, tgt.face_y)
	var ring := float(sim.R["ring"]["min"])
	match d.arch:
		K.Arch.TANK:
			# Tanque na frente: segura o golpe e o escudo.
			return hp + _forward(sim) * (ring + 2.0)
		K.Arch.STRUCTURE:
			return hp + _forward(sim).rotated(rng.randf_range(-0.5, 0.5)) * 9.0
		K.Arch.SHOOTER:
			return hp + (-face).rotated(rng.randf_range(-0.8, 0.8)) * 7.0
	# Corpo a corpo e enxame: pelo lado de trás do escudo (o lado sai do sorteio, como uma pessoa variando).
	var ang := float(P.get("flank", 2.2)) * (1.0 if rng.randf() < 0.5 else -1.0)
	var dist := ring + float(P.get("melee_gap", 0.8))
	if tgt.shield_max <= 0.0 or tgt.shield_hp <= 0.0:
		dist = ring + 0.3
	return hp + face.rotated(ang) * dist


## Arena: teleporta para longe quando o herói chega perto do chefe (igual ao heurístico).
func _smart_arena_h(sim: Sim) -> void:
	var A := sim.arena
	var h := Vector2(sim.hero.x, sim.hero.y)
	if h.distance_to(Vector2(A.bx, A.by)) < float(P.get("teleport_distance", 3.5)):
		var far := -1
		var fd := 0.0
		for k in A.altar_pos.size():
			if A.can_teleport(k):
				var dd := h.distance_to(A.altar_pos[k])
				if dd > fd:
					fd = dd
					far = k
		if far >= 0:
			hands.teleport(far)
