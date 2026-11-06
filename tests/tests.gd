extends Node
## Testes: roda tudo no _ready e sai com o número de falhas.
## godot --headless --path . res://tests/tests.tscn

var fails := 0
var data: GameData


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		fails += 1
		printerr("  FALHOU  ", msg)


func _ready() -> void:
	data = GameData.load_dir()
	t_data()
	t_elixir_and_ring()
	t_costs()
	t_sacrifice_and_cycle()
	t_determinism()
	t_save()
	t_full_runs()
	t_translations()
	print("falhas: ", fails)
	get_tree().quit(fails)


func t_data() -> void:
	check(data.pool.size() == 32, "32 cartas na pool")
	check(data.upgrades.size() == 15, "15 upgrades")
	check(data.contracts.size() == 8, "8 contratos")
	for d in data.boss["decks"]:
		check(d["cards"].size() == 6, "deck %s tem 6 cartas" % d["id"])


func _sim(seed_ := 1, deck := "horde") -> Sim:
	var s := Sim.new()
	s.setup(data, seed_, deck)
	return s


func t_elixir_and_ring() -> void:
	var s := _sim()
	var e0 := s.elixir
	for i in int(round(2.8 / s.dt)):
		s.step()
	check(absf(s.elixir - e0 - 1.0) < 0.05, "1 de elixir a cada 2,8 s (%.2f)" % (s.elixir - e0))
	var rats := Sim.CardInst.new()
	rats.def = data.card("rat_horde")
	var web := Sim.CardInst.new()
	web.def = data.card("web")
	var h := Vector2(s.hero.x, s.hero.y)
	check(not s.valid_target(rats, h.x + 1.0, h.y), "monstro a 1 m do herói é recusado")
	check(s.valid_target(rats, h.x + 6.0, h.y), "monstro a 6 m é aceito")
	check(not s.valid_target(rats, h.x + 13.0, h.y), "monstro a 13 m é recusado")
	check(s.valid_target(web, h.x + 1.0, h.y), "feitiço ignora a distância mínima")
	check(s.hand.size() == 6, "Horda tem mão de 6")


func t_costs() -> void:
	var s := _sim(1, "ruin")
	var g := Sim.CardInst.new()
	g.def = data.card("goblin_dynamiter")
	check(s.card_cost(g) == 4, "Ruína: Goblin custa 4")
	var tw := Sim.CardInst.new()
	tw.def = data.card("gargoyle_tower")
	check(s.card_cost(tw) == 4, "Ruína: Torre (estrutura) continua 4")
	var t := _sim(1, "treasure")
	check(int(t.elixir) == 8, "Tesouro começa com 8 de elixir")


func t_sacrifice_and_cycle() -> void:
	var s := _sim()
	s.elixir = 3.0
	var first: Sim.CardInst = s.hand[0]
	check(s.sacrifice(0), "sacrifício aceito")
	check(absf(s.elixir - 4.0) < 0.001, "sacrifício dá +1 de elixir")
	check(s.queue.has(first) or s.hand.has(first), "carta sacrificada volta ao deck")
	check(s.cards.size() == 6, "sacrifício não remove a carta")


func _run(seed_: int, deck: String, bot: String, max_ticks := 100000) -> Sim:
	var s := _sim(seed_, deck)
	var b := PlayerBot.load_bot(bot, seed_)
	var n := 0
	while s.phase != K.Phase.OVER and n < max_ticks:
		b.think(s)
		s.step()
		n += 1
	return s


func t_determinism() -> void:
	var a := _run(7, "horde", "greedy", 3000)
	var b := _run(7, "horde", "greedy", 3000)
	check(a.state_hash() == b.state_hash(), "mesma semente → mesmo estado")
	var c := _run(8, "horde", "greedy", 3000)
	check(a.state_hash() != c.state_hash(), "semente diferente → estado diferente")


func t_save() -> void:
	# Salva no meio da run (estrada e arena) e confere que a retomada é idêntica.
	for skip in [1500, 13000]:
		var a := _sim(11, "ruin")
		var b := PlayerBot.load_bot("greedy", 11)
		for i in skip:
			b.think(a)
			a.step()
		check(SaveGame.save(a, "user://test.save"), "salvou (tick %d, fase %d)" % [skip, a.phase])
		var c := SaveGame.load_run(data, "user://test.save")
		check(c != null and c.state_hash() == a.state_hash(), "carregou com o mesmo estado (tick %d)" % skip)
		var b2 := PlayerBot.load_bot("greedy", 11)
		b2.rng.state = b.rng.state
		b2.next_t = b.next_t
		for i in 2000:
			b.think(a)
			a.step()
			b2.think(c)
			c.step()
		check(a.state_hash() == c.state_hash() and a.result == c.result, "retomada idêntica 2000 ticks depois (tick %d)" % skip)
	SaveGame.erase("user://test.save")


func t_full_runs() -> void:
	for deck in ["horde", "ruin", "treasure"]:
		var t0 := Time.get_ticks_msec()
		var s := _run(3, deck, "greedy")
		var ms := Time.get_ticks_msec() - t0
		check(s.phase == K.Phase.OVER, "run %s termina (%s em %.0f s de jogo, %d ms, arena %.0f s, herói nv %d, jogador nv %d)" % [
			deck, s.stats["result"], s.t, ms, s.stats["arena_t"], s.hero.level, s.player_level])
	var r := _run(4, "horde", "random")
	check(r.phase == K.Phase.OVER, "run do bot aleatório termina (%s)" % r.stats["result"])


func t_translations() -> void:
	TranslationServer.set_locale("en")
	check(tr("CARD_rat_horde") != "CARD_rat_horde", "tradução en carregada")
	TranslationServer.set_locale("pt")
	check(tr("CARD_rat_horde") == "Horda de Ratos", "tradução pt carregada")
