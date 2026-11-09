extends Node
## Fuzz da simulação (rodada de 09/11/2026): decks esquisitos (qualquer carta, cópias demais, várias
## finalizações, níveis e modificadores sorteados) e comandos sem sentido (índices inválidos, alvos em
## qualquer lugar, rota para nós que não existem). Confere invariantes a cada passo e que a run termina.
## godot --headless --path . res://headless/fuzz.tscn -- --seeds=1-40

const MAX_T := 3600.0


func _ready() -> void:
	var args := {"seeds": "1-20"}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var data := GameData.load_dir()
	var ab := str(args["seeds"]).split("-")
	var fails := 0
	var results := {}
	for s in range(int(ab[0]), int(ab[1]) + 1):
		var r := run_one(data, s)
		results[r["result"]] = int(results.get(r["result"], 0)) + 1
		if r["bad"] != "":
			fails += 1
			printerr("FUZZ FALHOU seed %d: %s (deck %s)" % [s, r["bad"], r["deck"]])
	print("fuzz: resultados ", results, " falhas ", fails)
	get_tree().quit(fails)


func run_one(data: GameData, s: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = s * 31 + 7
	var pacts := ["horde", "ruin", "treasure"]
	var pact: String = pacts[rng.randi_range(0, 2)]
	var list: Array = []
	for k in rng.randi_range(6, 16):
		list.append(data.pool[rng.randi_range(0, data.pool.size() - 1)].id)
	var sim := Sim.new()
	sim.setup(data, s, pact, list)
	for c in sim.cards:
		c.level = rng.randi_range(1, 3)
		c.mods = rng.randi_range(0, 31)
	var still_t := 0.0
	var last_s := -1.0
	var bad := ""
	while sim.phase != K.Phase.OVER and sim.t < MAX_T:
		_chaos(sim, rng)
		sim.step()
		bad = _inv(sim)
		if bad != "":
			break
		# Herói parado na estrada por muito tempo sem motivo (sem bifurcação nem oferta) = travado.
		if sim.phase == K.Phase.ROAD and not sim.route_wait and sim.offers.is_empty():
			if absf(sim.hero.s - last_s) < 0.01:
				still_t += sim.dt
			else:
				still_t = 0.0
			last_s = sim.hero.s
			if still_t > 240.0:
				bad = "herói parado %.0f s na estrada (s=%.1f, t=%.0f)" % [still_t, sim.hero.s, sim.t]
				break
	if bad == "" and sim.phase != K.Phase.OVER:
		bad = "run não terminou em %.0f s (fase %d)" % [MAX_T, sim.phase]
	return {"result": sim.stats["result"], "bad": bad, "deck": pact + " " + str(list)}


func _chaos(sim: Sim, rng: RandomNumberGenerator) -> void:
	if sim.offers.size() > 0:
		var k := rng.randi_range(-3, 6)
		if not sim.choose(k):
			sim.choose(Sim.SKIP if rng.randf() < 0.7 else rng.randi_range(0, 2))
		if sim.offers.size() > 0 and rng.randf() < 0.3:
			sim.choose(Sim.SKIP)
		return
	if sim.route_wait or rng.randf() < 0.01:
		var n := rng.randi_range(-3, sim.road.nodes.size() + 3)
		sim.choose_route(n)
		if sim.route_wait and rng.randf() < 0.5:
			var outs: Array = sim.road.nodes[sim.road.head]["out"]
			if outs.size() > 0:
				sim.choose_route(sim.road.legs[outs[rng.randi_range(0, outs.size() - 1)]]["b"])
	if rng.randf() > 0.15:
		return
	var i := rng.randi_range(-1, sim.hand.size())
	match rng.randi_range(0, 9):
		0:
			sim.sacrifice(i)
		1:
			sim.teleport(rng.randi_range(-2, 7))
		_:
			var a := rng.randf() * TAU
			var d := rng.randf_range(0.0, 1.0) ** 2 * 80.0
			sim.play(i, sim.hero.x + cos(a) * d, sim.hero.y + sin(a) * d)


func _inv(sim: Sim) -> String:
	if not (sim.elixir >= -0.001 and sim.elixir <= sim.elixir_max + 0.001):
		return "elixir %.3f" % sim.elixir
	var h := sim.hero
	if not (is_finite(h.x) and is_finite(h.y) and is_finite(h.hp)):
		return "herói com número inválido"
	if h.hp > h.max_hp() * 1.0001 + 0.01:
		return "herói com vida acima do máximo (%.0f/%.0f)" % [h.hp, h.max_hp()]
	var U := sim.units
	for i in U.hi:
		if U.alive[i] == 1:
			if not (is_finite(U.px[i]) and is_finite(U.py[i]) and is_finite(U.hp[i])):
				return "unidade %d com número inválido" % i
			if U.hp[i] > U.max_hp[i] * 1.0001 + 0.01:
				return "unidade %d com vida acima do máximo" % i
	# A mão pode passar do tamanho (Pacto Sombrio compra a mais), mas nunca do teto das teclas.
	if sim.hand.size() > Sim.HAND_MAX or (sim.hand.size() < sim.hand_size and sim.hand.size() < sim.cards.size()):
		return "mão com %d (tamanho %d, teto %d)" % [sim.hand.size(), sim.hand_size, Sim.HAND_MAX]
	return ""
