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
	t_hand_cap()
	t_determinism()
	t_save()
	t_hero_ai()
	t_party()
	t_card_levels()
	t_location_rewards()
	t_route()
	t_shop()
	t_fountain_and_fire()
	t_contests()
	t_fork_after_location()
	t_offer_single_type()
	t_relics()
	t_events()
	t_ability_tell()
	t_arena_hunt()
	t_acts()
	t_meta()
	t_full_runs()
	t_combos()
	t_classes()
	t_group()
	t_translations()
	t_keywords()
	print("falhas: ", fails)
	get_tree().quit(fails)


func t_data() -> void:
	check(data.pool.size() == 48, "48 cartas na pool (%d)" % data.pool.size())
	check(data.upgrades.size() == 15, "15 upgrades")
	check(data.contracts.size() == 8, "8 contratos")
	var m := MetaSave.new()
	m.data = data
	m.unlocked = data.meta["start_collection"].duplicate()
	check(m.deck_errors(data.deck("horde")["cards"]).is_empty(), "Horda é válida com a coleção inicial %s" % str(m.deck_errors(data.deck("horde")["cards"])))
	for d in data.boss["decks"]:
		m.unlock_pact(d["id"])
		check(m.deck_errors(d["cards"]).is_empty(), "deck pronto %s é válido depois de liberar o pacto %s" % [d["id"], str(m.deck_errors(d["cards"]))])
		var fams := {}
		for id in d["cards"]:
			fams[_family(id)] = true
		check(fams.size() <= 2, "deck %s tem no máximo 2 famílias (%s)" % [d["id"], str(fams.keys())])


func _sim(seed_ := 1, deck := "horde") -> Sim:
	var s := Sim.new()
	s.setup(data, seed_, deck)
	s.auto_route = true
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
	check(s.valid_target(rats, h.x + 40.0, h.y), "monstro a 40 m é aceito (sem alcance máximo)")
	check(s.valid_target(web, h.x + 1.0, h.y), "feitiço ignora a distância mínima")
	check(s.hand.size() == 6, "Horda tem mão de 6")


func t_costs() -> void:
	var s := _sim(1, "ruin")
	var g := Sim.CardInst.new()
	g.def = data.card("goblin_dynamiter")
	check(s.card_cost(g) == 3, "Ruína: Goblin custa 3 (sem a taxa de monstro desde 09/11)")
	var tw := Sim.CardInst.new()
	tw.def = data.card("gargoyle_tower")
	check(s.card_cost(tw) == 4, "Ruína: Torre (estrutura) continua 4")
	var t := _sim(1, "treasure")
	check(int(t.elixir) == 7, "Tesouro começa com 7 de elixir")


func t_sacrifice_and_cycle() -> void:
	var s := _sim()
	s.elixir = 3.0
	var first: Sim.CardInst = s.hand[0]
	check(s.sacrifice(0), "sacrifício aceito")
	check(absf(s.elixir - 4.0) < 0.001, "sacrifício dá +1 de elixir")
	check(s.queue.has(first) or s.hand.has(first), "carta sacrificada volta ao deck")
	check(s.cards.size() == 10, "sacrifício não remove a carta")
	# Rodada 09/11/2026: girar de graça uma carta jogável deixava cavar o deck sem parar (o bot sacrificava
	# ~1400 vezes por run na Ruína atrás do Raio Sombrio). Na recarga, só carta morta gira.
	var live := Sim.CardInst.new()
	live.def = data.card("rat_horde")
	s.hand[0] = live
	check(not s.sacrifice(0) and s.hand[0] == live, "na recarga, carta jogável não gira")
	s.elixir = 0.0
	check(not s.sacrifice(0), "na recarga, carta só sem elixir também não gira")
	var dead := Sim.CardInst.new()
	dead.def = data.card("cosmic_ray")
	s.hand[0] = dead
	check(s.can_play(0) == K.Block.WRONG_PHASE and s.sacrifice(0) and s.elixir < 0.001, "na recarga, finalização na estrada gira (sem elixir)")
	for i in int(round(float(data.rules["sacrifice_cooldown"]) / s.dt)) + 1:
		s.step()
	s.hand[0] = live
	check(s.sacrifice(0), "depois da recarga, qualquer carta volta a sacrificar")


## Rodada 09/11/2026: compras extras não têm teto e a mão passava de 9 (só há teclas de 1 a 9).
func t_hand_cap() -> void:
	var s := _sim()
	var lib := Sim.CardInst.new()
	lib.def = data.card("forbidden_library")
	for k in 6:
		s.lair.erase("forbidden_library")
		s._apply(lib, s.hero.x, s.hero.y)
	check(s.hand.size() <= 9 and s.hand_size <= 9, "Biblioteca repetida não passa do teto da mão (%d, tamanho %d)" % [s.hand.size(), s.hand_size])


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


## Segundos até todas as unidades criadas morrerem (-1 se não morrerem em max_s).
func _kill_time(ids: Array, s: Sim, max_s := 60.0) -> float:
	for t in int(max_s / s.dt):
		if s.offers.size() > 0:
			s.choose(0)
		s.step()
		var alive := 0
		for i in ids:
			alive += s.units.alive[i]
		if alive == 0:
			return t * s.dt
	return -1.0


func _spawn_near(s: Sim, id: String, n: int) -> Array:
	var h := s.hero
	var ids := []
	for k in n:
		ids.append(s.units.spawn(data.card(id), h.x + 4.0 + k, h.y - 3.0 - k * 0.7, 0.0, 0.0, 0, 999))
	return ids


func t_party() -> void:
	# Grupo de 5 heróis em fila, sem XP: cada queda traz o próximo (nível +1, uma habilidade, vida cheia).
	var s := _sim(3)
	var bot := PlayerBot.load_bot("greedy", 3)
	for i in 200:
		bot.think(s)
		s.step()
	check(s.party_idx == 0 and s.hero.level == 1, "começa no herói 1, nível 1")
	s.hero.hp = 0.0
	s._check_end()
	check(s.party_idx == 1, "queda do herói 1 chama o herói 2 (party_idx %d)" % s.party_idx)
	check(s.hero.level == 2, "herói 2 é nível 2 (%d)" % s.hero.level)
	check(s.hero.upgrade_order.size() == 1, "herói 2 chega com 1 habilidade (%d)" % s.hero.upgrade_order.size())
	check(is_equal_approx(s.hero.hp, s.hero.max_hp()), "herói 2 chega com vida cheia")
	check(s.phase != K.Phase.OVER, "a run continua depois da primeira queda")
	check(s.offers.size() > 0, "a queda abre uma oferta")
	# Mais quedas até o último herói: a quinta é vitória.
	var size := int(data.rules["party"]["size"])
	for k in range(2, size):
		s.offers.clear()
		s.hero.hp = 0.0
		s._check_end()
		check(s.party_idx == k and s.phase != K.Phase.OVER, "herói %d entrou (party_idx %d)" % [k + 1, s.party_idx])
	s.offers.clear()
	s.hero.hp = 0.0
	s._check_end()
	check(s.phase == K.Phase.OVER and (s.stats["result"] == "win" or s.stats["result"] == "win_early"),
		"a quinta queda é vitória (%s)" % str(s.stats["result"]))
	check(int(s.stats["heroes_fallen"]) == size, "heroes_fallen = %d (%s)" % [size, str(s.stats["heroes_fallen"])])


## Sim para os testes de perseguição: o herói não morre (o teste mede alcance, não o balanceamento).
func _sim_tough(seed_: int) -> Sim:
	var s := _sim(seed_)
	s.hero.base_hp = 1.0e6
	s.hero.hp = 1.0e6
	return s


func t_hero_ai() -> void:
	# Quem foge do herói (suporte, atiradores) tem que ser alcançável.
	var s := _sim_tough(5)
	var king := _spawn_near(s, "rat_king", 1)
	var tk := _kill_time(king, s)
	check(tk > 0.0 and tk < 20.0, "herói alcança e mata o Rei dos Ratos sozinho (%.1f s)" % tk)
	s = _sim_tough(5)
	var pack := _spawn_near(s, "rat_horde", 6) + _spawn_near(s, "rat_king", 1)
	var tp := _kill_time(pack, s)
	check(tp > 0.0 and tp < 45.0, "herói mata o Rei dos Ratos com o bando (%.1f s)" % tp)
	s = _sim_tough(5)
	var archers := _spawn_near(s, "skeleton_archers", 5)
	var ta := _kill_time(archers, s)
	check(ta > 0.0 and ta < 30.0, "herói mata 5 arqueiros que recuam (%.1f s)" % ta)
	# Inimigos dentro da curva de uma ligação ondulada: o progresso na estrada não pode recuar muito.
	var back: float = data.rules["road"]["max_backtrack"]
	var worst := 0.0
	for seed_ in [1, 4, 5, 8]:
		s = _sim(seed_)
		# A ligação mais ondulada da primeira fileira à segunda; o plano manda o herói por ela.
		var leg: Dictionary = {}
		var dev := -1.0
		for g in s.road.legs:
			if s.road.nodes[g["a"]]["row"] != 0:
				continue
			var gp: PackedVector2Array = g["pts"][0]
			var q := gp[gp.size() / 4]
			var dd := q.distance_to(gp[0].lerp(gp[gp.size() - 1], 0.25))
			if dd > dev:
				dev = dd
				leg = g
		for e0 in s.road.nodes[0]["out"]:
			if s.road.legs[e0]["b"] == leg["a"]:
				s.road.plan[0] = e0
		s.road.plan[leg["a"]] = s.road.legs.find(leg)
		var pts: PackedVector2Array = leg["pts"][0]
		var mid := pts[pts.size() / 4]
		var inner := mid.lerp(pts[0].lerp(pts[pts.size() - 1], 0.25), 0.35)
		var spawned := false
		var smax := 0.0
		for t in 12000:
			s.step()
			if s.offers.size() > 0:
				s.choose(0)
			if not spawned and leg["chosen"] == 0 and Vector2(s.hero.x, s.hero.y).distance_to(mid) < 6.0:
				spawned = true
				for k in 4:
					s.units.spawn(data.card("skeleton_archers"), inner.x + k, inner.y, 0.0, 0.0, 0, 999)
				s.units.spawn(data.card("rat_king"), inner.x, inner.y + 2.0, 0.0, 0.0, 0, 999)
			smax = maxf(smax, s.hero.s)
			worst = maxf(worst, smax - s.hero.s)
			if s.phase != K.Phase.ROAD:
				break
	check(worst <= back + 0.01, "herói não volta pela estrada mais de %.0f m (pior: %.1f m)" % [back, worst])


func t_full_runs() -> void:
	for deck in ["horde", "ruin", "treasure"]:
		var t0 := Time.get_ticks_msec()
		var s := _run(3, deck, "greedy")
		var ms := Time.get_ticks_msec() - t0
		check(s.phase == K.Phase.OVER, "run %s termina (%s em %.0f s de jogo, %d ms, arena %.0f s, herói nv %d, heróis caídos %s)" % [
			deck, s.stats["result"], s.t, ms, s.stats["arena_t"], s.hero.level, str(s.stats.get("heroes_fallen", 0))])
	var r := _run(4, "horde", "random")
	check(r.phase == K.Phase.OVER, "run do bot aleatório termina (%s)" % r.stats["result"])


func t_translations() -> void:
	TranslationServer.set_locale("en")
	check(tr("CARD_rat_horde") != "CARD_rat_horde", "tradução en carregada")
	TranslationServer.set_locale("pt")
	check(tr("CARD_rat_horde") == "Horda de Ratos", "tradução pt carregada")


## Palavras-chave e habilidades do herói: todo texto existe nas duas línguas, sem número faltando, e toda
## marcação [[id]] aponta para uma palavra-chave que tem caixa.
func t_keywords() -> void:
	Tips.data = data
	for loc in ["pt", "en"]:
		TranslationServer.set_locale(loc)
		var bad: Array = []
		var texts: Array = []
		for id in Tips.KEYWORDS:
			if tr("KW_" + id) == "KW_" + id or tr("KWD_" + id) == "KWD_" + id:
				bad.append("sem texto: " + id)
			texts.append(Tips.kw_desc(id))
		for id in data.upgrades:
			if tr("UPG_" + id) == "UPG_" + id or tr("UPGD_" + id) == "UPGD_" + id:
				bad.append("sem texto: " + id)
			texts.append(UpgradeIcon.desc(data, id))
		for d in data.pool:
			texts.append(UiKit.card_desc(d))
		for t in texts:
			if Tips.plain(t).contains("{") or Tips.plain(t).contains("[["):
				bad.append("sobrou marcação: " + t)
			for id in Tips.keywords(t):
				if not Tips.KEYWORDS.has(id):
					bad.append("palavra-chave desconhecida: " + id)
		check(bad.is_empty(), "palavras-chave e habilidades completas (%s) %s" % [loc, str(bad)])
	TranslationServer.set_locale("pt")
	check(Tips.plain("leva [[fire|Fogo]] e [[slow]]") == "leva Fogo e Lentidão", "marcação vira texto simples")
	check(Tips.rich("[[fear]]", true).contains("[url=fear]"), "palavra-chave vira link")
	check(not Tips.rich("[[fear]]", true, "fear").contains("[url"), "caixa não linka a própria palavra")


func _inst(id: String, level := 1) -> Sim.CardInst:
	var ci := Sim.CardInst.new()
	ci.def = data.card(id)
	ci.level = level
	return ci


func t_card_levels() -> void:
	var rats := data.card("rat_horde")
	check(rats.count_at(1) == 8 and rats.count_at(2) == 10 and rats.count_at(3) == 12, "Horda: 8, 10 e 12 ratos por nível")
	check(is_equal_approx(data.card("shadow_bolt").fxv("damage", 2), 175.0), "Raio Sombrio N2: 175 de dano")
	check(data.card("burn_village").cost_at(1) == 4 and data.card("burn_village").cost_at(3) == 2, "Incêndio fica 1 mais barato por nível")
	check(data.card("soul_feast").fxv("bonus_per_card", 2) == 1.0 and data.card("soul_feast").fxv("bonus_per_card", 3) == 2.0,
		"especial do N3 só vale no nível 3")
	var s := _sim()
	var n0 := s.units.count
	s._apply(_inst("rat_horde", 3), s.hero.x + 6.0, s.hero.y, )
	check(s.units.count - n0 == 12, "Horda N3 solta 12 ratos (%d)" % (s.units.count - n0))
	var i := s.units.hi - 1
	check(s.units.lvl[i] == 3, "unidade guarda o nível da carta")
	var g := _sim()
	var g1 := _sim()
	g._apply(_inst("ogre", 1), g.hero.x + 6.0, g.hero.y)
	g1._apply(_inst("ogre", 3), g1.hero.x + 6.0, g1.hero.y)
	check(is_equal_approx(g1.units.hp[0] / g.units.hp[0], 1.5), "Ogro N3 tem +50% de vida")
	var c := _sim()
	c.elixir = 10.0
	check(c.card_cost(_inst("burn_village", 2)) == 3, "Incêndio N2 custa 3")


func t_location_rewards() -> void:
	var s := _sim()
	s.offers.clear()
	s._offer_location("ritual", true)
	check(s.offers.size() == 1 and s.offers[0]["options"].size() == 3 and s.offers[0]["options"][0]["kind"] == "upgrade",
		"ritual vencido: 3 cartas para subir")
	var uid: int = s.offers[0]["options"][0]["uid"]
	s.choose(0)
	var lv := 0
	for ci in s.cards:
		if ci.uid == uid:
			lv = ci.level
	check(lv == 2, "escolher a melhoria sobe a carta para o N2")
	s._offer_location("ritual", false)
	check(s.offers.is_empty(), "disputa perdida não dá nada (rodada 09/11/2026)")
	s._offer_location("ritual", true)
	check(s.choose(Sim.SKIP) and s.offers.is_empty(), "toda recompensa pode ser recusada")
	s._offer_location("fountain", true)
	var distinct := {}
	for ci in s.cards:
		distinct["%s/%d/%d" % [ci.def.id, ci.level, ci.mods]] = true
	check(s.offers[0]["options"].size() == distinct.size(), "fonte vencida: escolhe qualquer carta do deck (cópias iguais uma vez)")
	s.choose(0)
	check(s.cards.size() == 9, "remover tira a carta do deck")
	s._offer_location("bridge", true)
	check(s.offers[0]["options"][1]["kind"] == "pick", "ponte vencida: escolhe o tipo")
	s.choose(1)
	check(s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "upgrade", "depois do tipo vem a recompensa")
	s.offers.clear()
	while s.cards.size() > int(data.rules["deck"]["min_in_run"]):
		s._remove_uid(s.cards[0].uid)
	s._offer_location("fountain", true)
	check(s.offers.is_empty(), "nunca remove abaixo do deck mínimo")
	# Ofertas só com cartas desbloqueadas.
	var u := Sim.new()
	u.setup(data, 2, "horde", [], ["rat_horde", "web", "ogre"])
	var ok := true
	for k in 20:
		for o in u._card_options(3, func(cd: CardDef): return true):
			ok = ok and o["id"] in ["rat_horde", "web", "ogre"]
	check(ok, "ofertas só sorteiam cartas desbloqueadas")
	# Pacto Sombrio: tira vida de uma parte em vez de destruí-la.
	var a := _sim()
	a.phase = K.Phase.ARENA
	a.arena.setup(a, Vector2(a.hero.x, a.hero.y + 20.0), Vector2(0, -1))
	var before := a.arena.destroyed
	a._apply(_inst("dark_pact", 1), 0.0, 0.0)
	check(a.arena.destroyed == before and is_equal_approx(a.elixir, a.elixir_max), "Pacto Sombrio não destrói a parte cheia e enche o elixir")


func t_meta() -> void:
	var path := "user://test_meta.save"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var m := MetaSave.load_or_new(data, path)
	check(m.unlocked.size() == data.meta["start_collection"].size() and m.deck_errors(m.deck).is_empty(), "coleção inicial e deck pronto válido")
	check(m.pacts == ["horde"] and not m.phase_open(2), "começa só com a Horda e a fase 2 fechada")
	check(m.win_phase(1) == "ruin" and m.pacts.has("ruin") and m.is_unlocked("torch") and m.phase_open(2), "vencer a fase 1 libera a Ruína e as cartas dela")
	check(not m.can_add("ogre") and m.unlock_cost("ogre") == 70, "Ogro começa bloqueado e custa 70 Almas")
	m.souls = 75
	check(m.unlock("ogre") and m.souls == 5 and m.is_unlocked("ogre"), "desbloquear gasta as Almas")
	check(m.deck_errors(m.deck + ["web"]).has("DECKERR_size"), "deck de 11 é recusado")
	var three: Array = m.deck.duplicate()
	three[0] = "web"
	three[1] = "web"
	three[2] = "web"
	check(m.deck_errors(three).has("DECKERR_copies"), "3 cópias é recusado")
	var st := {"dmg_by_card": {"a": 4000.0}, "locs_visited": 9, "result": "win"}
	var per_loc := int(data.meta["souls"]["per_location"])
	check(MetaSave.souls_for(data, st) == 10 + 9 * per_loc + 40, "Almas: dano, locais e vitória (%d)" % MetaSave.souls_for(data, st))
	m.add_run(st, path)
	var m2 := MetaSave.load_or_new(data, path)
	check(m2.souls == m.souls and m2.is_unlocked("ogre") and m2.runs == 1, "meta salva e carrega")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Nível da carta sobrevive ao salvamento da run.
	var s := _sim(5)
	s.cards[0].level = 3
	SaveGame.save(s, "user://test.save")
	var c := SaveGame.load_run(data, "user://test.save")
	check(c.cards[0].level == 3, "nível da carta vai no salvamento")
	SaveGame.erase("user://test.save")


## Todas as rotas de um mapa: lista de listas de nós, do início ao covil.
func _all_paths(road: SimRoad) -> Array:
	var out: Array = []
	var stack: Array = [[0]]
	while stack.size() > 0:
		var p: Array = stack.pop_back()
		var n: int = p[-1]
		if road.nodes[n]["out"].is_empty():
			out.append(p)
			continue
		for e in road.nodes[n]["out"]:
			stack.append(p + [road.legs[e]["b"]])
	return out


func _path_len(road: SimRoad, p: Array) -> float:
	var s := 0.0
	for k in p.size() - 1:
		s += road._edge_len(p[k], p[k + 1])
	return s


func t_route() -> void:
	var R: Dictionary = data.rules["road"].duplicate()
	R.merge(data.rules["acts"][0]["road"], true)
	var bad_len := 0
	var bad_rows := 0
	var bad_shrines := 0
	var bad_shops := 0
	var bad_cross := 0
	var forks := 0
	var npaths := 0
	var nmaps := 30
	for seed_ in range(1, nmaps + 1):
		var s := _sim(seed_)
		var road := s.road
		var paths := _all_paths(road)
		npaths += paths.size()
		var l0 := _path_len(road, paths[0])
		var shops_total := 0
		for loc in road.locations:
			if loc["type"] == "shop":
				shops_total += 1
		if shops_total != 1:
			bad_shops += 1
		for p in paths:
			if absf(_path_len(road, p) - l0) > 1.0:
				bad_len += 1
			var nsh := 0
			var nsp := 0
			for n in p:
				var li: int = road.nodes[n]["loc"]
				if li >= 0:
					nsh += 1 if road.locations[li]["type"] == "shrine" else 0
					nsp += 1 if road.locations[li]["type"] == "shop" else 0
			if nsh < int(R["shrines"][0]) or nsh > int(R["shrines"][1]):
				bad_shrines += 1
			if nsp != 1:
				bad_shops += 1
			if p.size() - 2 < int(R["route_locations"][0]) or p.size() - 2 > int(R["route_locations"][1]):
				bad_rows += 1
		# Tipos diferentes na mesma fileira; ligações que não se cruzam.
		var by_row := {}
		for n in road.nodes:
			if n["loc"] >= 0:
				var key := str(n["row"]) + str(road.locations[n["loc"]]["type"])
				if by_row.has(key):
					bad_rows += 1
				by_row[key] = true
		for e1 in road.legs:
			for e2 in road.legs:
				if road.nodes[e1["a"]]["row"] == road.nodes[e2["a"]]["row"]:
					var d1: int = road.nodes[e1["a"]]["lane"] - road.nodes[e2["a"]]["lane"]
					var d2: int = road.nodes[e1["b"]]["lane"] - road.nodes[e2["b"]]["lane"]
					if d1 * d2 < 0:
						bad_cross += 1
		for n in road.nodes:
			if n["out"].size() > 1:
				forks += 1
	check(bad_len == 0, "todas as rotas têm o mesmo comprimento (%d fora)" % bad_len)
	check(bad_rows == 0, "%s locais por rota e tipos diferentes por fileira (%d erros)" % [str(R["route_locations"]), bad_rows])
	check(bad_cross == 0, "ligações nunca se cruzam (%d)" % bad_cross)
	check(bad_shrines * 10 <= npaths, "Santuários por rota quase sempre entre %s (%d de %d rotas fora)" % [str(R["shrines"]), bad_shrines, npaths])
	check(bad_shops == 0, "toda rota passa por exatamente uma Loja (%d erros)" % bad_shops)
	check(forks >= nmaps * 3, "o mapa tem bifurcações (%d em %d mapas)" % [forks, nmaps])
	# Sem plano, o jogo espera a escolha do jogador; a escolha resolve e fecha os outros ramos.
	var w := Sim.new()
	w.setup(data, 3, "horde")
	for i in 20:
		w.step()
	check(w.route_wait and w.t < 0.06, "sem escolha, o herói espera na primeira bifurcação")
	var outs: Array = w.road.nodes[0]["out"]
	var pick: int = w.road.legs[outs[outs.size() - 1]]["b"]
	check(not w.choose_route(w.road.nodes.size() + 5), "nó inexistente é recusado")
	check(w.choose_route(pick) and not w.route_wait, "escolher o ramo solta o herói")
	w.step()
	check(w.road.head == pick and w.road.path == [0, pick], "o herói vai pelo nó escolhido")
	var closed := 0
	for e in outs:
		if e != outs[outs.size() - 1] and w.road.legs[e]["closed"] == 0:
			closed += 1
	check(closed == outs.size() - 1, "os ramos não escolhidos ficam fechados")
	check(outs.size() == 1 or not w.choose_route(w.road.legs[outs[0]]["b"]), "nó que ficou para trás não pode ser escolhido")
	# Escolher um nó distante planeja todas as bifurcações até ele.
	var far := -1
	for n in w.road.reach:
		if w.road.nodes[n]["loc"] >= 0 and (far < 0 or w.road.nodes[n]["row"] > w.road.nodes[far]["row"]):
			far = n
	check(w.choose_route(far), "escolher um nó distante")
	var guard := 0
	while not w.road.path.has(far) and guard < 40000:
		if w.offers.size() > 0:
			w.choose(Sim.SKIP)
		w.step()
		guard += 1
		if w.route_wait:
			break
	check(w.road.path.has(far), "o herói chega ao nó distante sem nova pergunta no caminho")
	# Bots escolhem a rota sozinhos e terminam a run.
	var r := Sim.new()
	r.setup(data, 6, "ruin")
	var rb := PlayerBot.load_bot("heuristic", 6)
	var n_ := 0
	while r.phase != K.Phase.OVER and n_ < 100000:
		rb.think(r)
		r.step()
		n_ += 1
	check(r.phase == K.Phase.OVER and int(r.stats["locs_visited"]) >= 6,
		"Heurístico escolhe a rota e termina (%s, %d locais, %s)" % [r.stats["result"], r.stats["locs_visited"], str(r.stats["route"])])


func t_shop() -> void:
	var s := _sim(4)
	s.offers.clear()
	s.gold = 0.0
	s._open_shop()
	var o: Dictionary = s.offers[0]
	check(o["source"] == "shop" and o["options"].size() >= 5, "loja abre com cartas, nível, modificador e remoção (%d)" % o["options"].size())
	check(not s.choose(0) and s.offers.size() == 1, "sem ouro não compra")
	s.gold = 1000.0
	var n0 := s.cards.size()
	var price: int = o["options"][0]["price"]
	check(s.choose(0) and s.cards.size() == n0 + 1 and is_equal_approx(s.gold, 1000.0 - price), "comprar carta gasta o ouro e põe a carta no deck")
	var up := -1
	for k in o["options"].size():
		if o["options"][k]["item"]["kind"] == "pick" and o["options"][k]["item"]["what"] == "upgrade":
			up = k
	var g0 := s.gold
	check(s.choose(up) and s.offers[0]["source"] == "shop_pick", "nível abre a escolha da carta")
	check(s.choose(Sim.SKIP) and s.offers[0]["source"] == "shop" and is_equal_approx(s.gold, g0), "voltar da escolha não cobra")
	s.choose(up)
	var uid: int = s.offers[0]["options"][0]["uid"]
	s.choose(0)
	var lv := 0
	for ci in s.cards:
		if ci.uid == uid:
			lv = ci.level
	check(lv == 2 and s.gold < g0 and s.offers[0]["source"] == "shop", "nível escolhido: paga, sobe a carta e volta à loja")
	check(s.choose(Sim.SKIP) and s.offers.is_empty(), "recusar sai da loja")
	s._open_shop()
	var base := int(data.rules["shop"]["prices"]["common"])
	var full := true
	for op in s.offers[0]["options"]:
		if op["item"]["kind"] == "card" and data.card(op["item"]["id"]).rarity == 0:
			full = full and op["price"] == base
	check(full, "loja sem desconto (rodada 09/11/2026)")
	s.offers.clear()
	# Ouro: dano no herói e disputa vencida.
	var g := _sim(4)
	g.gold = 0.0
	g.damage_hero(400.0, g.hero.x + 1.0, g.hero.y, 0, 0, "rat_horde")
	var per := float(data.rules["gold"]["damage_per_gold"])
	check(g.gold > 0.0 and g.gold <= 400.0 / per + 0.01, "dano no herói rende ouro (%.1f)" % g.gold)
	var gb := g.gold
	g._offer_location("tavern", true)
	check(is_equal_approx(g.gold - gb, float(data.rules["gold"]["per_contest"])), "disputa vencida rende ouro")
	# Bot compra na loja e sai (não trava a run).
	var b := PlayerBot.load_bot("heuristic", 1)
	var t := _sim(5)
	t.offers.clear()
	t.gold = 300.0
	t._open_shop()
	for i in 30:
		b.think(t)
	check(t.offers.is_empty() and t.stats["shop_buys"] >= 1, "Heurístico compra e sai da loja (%d compras)" % t.stats["shop_buys"])


func t_fountain_and_fire() -> void:
	# Incêndio: marca um local à frente; o fogo pega quando o herói chega.
	var f := _sim(2)
	var tg: Array = f._burn_targets()
	check(tg.size() > 0, "Incêndio tem alvos à frente")
	var li: int = tg[0]
	var lp: Vector2 = f.road.locations[li]["pos"]
	f._apply(_inst("burn_village", 1), lp.x, lp.y)
	check(f.road.locations[li].get("burn", false), "Incêndio marca o local")
	f.road.plan_to(f.road.locations[li]["node"])
	var fire := false
	for i in 30000:
		if f.offers.size() > 0:
			f.choose(Sim.SKIP)
		f.step()
		for z in f.zones:
			if z["kind"] == "fire" and z["src"] == "burn_village":
				fire = true
		if fire:
			break
	check(fire, "o local marcado pega fogo quando o herói chega")


# ================================================================ rodada 09/11/2026: atos, disputas, relíquias, eventos

## Sim parada num local do tipo `ty` (troca o tipo do primeiro local da rota): herói em cima dele, disputa começada.
func _at_location(ty: String, seed_ := 3) -> Sim:
	var s := _sim(seed_)
	s.hero.base_hp = 1.0e6
	s.hero.hp = 1.0e6
	# Estrada decidida até o primeiro nó; herói em cima dele (com o progresso na estrada certo, senão a coleira o puxa).
	s.road.advance(s.road.nodes[0]["out"][0])
	var li: int = s.road.nodes[s.road.head]["loc"]
	var loc: Dictionary = s.road.locations[li]
	loc["type"] = ty
	loc["r"] = float(data.rules["locations"][ty]["radius"])
	var p: Vector2 = loc["pos"]
	s.hero.x = p.x
	s.hero.y = p.y
	s.hero.s = s.road.length()
	s.hero.s_max = s.hero.s
	s.hero.seg = s.road.seg_at(s.hero.s)
	s.offers.clear()
	s._arrive(li)
	return s


func _steps(s: Sim, sec: float) -> void:
	for i in int(sec / s.dt):
		s.step()


func t_contests() -> void:
	# Ritual: 10 mortes de monstros seus dentro do círculo.
	var s := _at_location("ritual")
	var p: Vector2 = s.road.locations[int(s.contest["li"])]["pos"]
	check(s.contest["type"] == "ritual" and s.hero.hold, "Ritual: o herói para no local e a disputa começa")
	for k in 10:
		var j := s.units.spawn(data.card("ogre"), p.x + 1.0, p.y, 0.0, 0.0, 0, 999)
		s.kill_unit(j, K.Death.HERO)
	s.step()
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "upgrade", "Ritual: 10 mortes no círculo vencem (nível de 1 entre 3)")
	s = _at_location("ritual")
	_steps(s, float(data.rules["locations"]["ritual"]["window"]) + 0.2)
	check(s.contest.is_empty() and s.offers.is_empty() and not s.hero.hold, "Ritual: janela acaba sem mortes → nada, e o herói segue")
	# Santuário: monstro que luta no círculo por 6 s; torre não conta.
	s = _at_location("shrine")
	p = s.road.locations[int(s.contest["li"])]["pos"]
	s.hero.petrify_t = 100.0
	s.units.spawn(data.card("gargoyle_tower"), p.x + 2.0, p.y, 0.0, 0.0, 0, 999)
	_steps(s, 7.0)
	check(s.contest.size() > 0, "Santuário: só uma torre no círculo não conta")
	s.units.spawn(data.card("slime"), p.x - 2.0, p.y, 0.0, 0.0, 0, 999)
	_steps(s, 6.5)
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "card", "Santuário: 6 s com monstro no círculo vencem")
	# Taverna: destruir as casas; os monstros vão nelas.
	s = _at_location("tavern")
	var loc: Dictionary = s.road.locations[int(s.contest["li"])]
	check(loc["houses"].size() == int(data.rules["locations"]["tavern"]["houses"]), "Taverna: as casas aparecem")
	s.hero.petrify_t = 100.0
	var hp0 := 0.0
	for h in loc["houses"]:
		hp0 += float(h["hp"])
	var hpos: Vector2 = Vector2(loc["houses"][0]["x"], loc["houses"][0]["y"])
	for k in 3:
		s.units.spawn(data.card("ogre"), hpos.x + 3.0, hpos.y + k, 0.0, 0.0, 0, 999)
	_steps(s, 4.0)
	var hp1 := 0.0
	for h in loc["houses"]:
		hp1 += float(h["hp"])
	check(hp1 < hp0, "Taverna: monstros perto atacam as casas (%.0f → %.0f)" % [hp0, hp1])
	for k in loc["houses"].size():
		s.damage_house(k, 1.0e6)
	s.step()
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "mod", "Taverna: todas as casas no chão vencem (modificador)")
	# Ponte: dano na janela.
	s = _at_location("bridge")
	check(s.hero.tavern_t > 0.0, "Ponte: o herói fica lento")
	s.damage_hero(200.0, s.hero.x + 1.0, s.hero.y, 0, SimHero.DMG_PIERCE, "test")
	s.step()
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "pick", "Ponte: 150 de dano vencem (escolhe o tipo)")
	# Fonte: interromper o gole; se ele termina, cura 15% e você não ganha nada.
	s = _at_location("fountain")
	check(s.hero.drink_t > 0.0, "Fonte: o herói começa a beber")
	var x0 := s.hero.x
	_steps(s, 1.0)
	check(is_equal_approx(s.hero.x, x0), "Fonte: bebendo, ele não anda")
	s.hero_fear(s.hero.x + 1.0, s.hero.y)
	s.step()
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "remove", "Fonte: medo interrompe e você remove uma carta")
	s = _at_location("fountain")
	s.hero.base_hp = 1000.0
	s.hero.hp = 500.0
	_steps(s, float(data.rules["locations"]["fountain"]["drink_s"]) + 0.2)
	check(s.offers.is_empty() and s.hero.hp > 500.0, "Fonte: gole completo cura o herói e não dá nada (%.0f)" % s.hero.hp)
	# Loja e "?": sem disputa.
	s = _at_location("shop")
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["source"] == "shop", "Loja abre na chegada, sem disputa")
	s = _at_location("event")
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["source"] == "event", "Local ? abre um evento de texto")


## A bifurcação é escolhida depois do local do nó, não antes.
func t_fork_after_location() -> void:
	var bad := 0
	var waits := 0
	for seed_ in range(1, 9):
		var s := Sim.new()
		s.setup(data, seed_, "horde")
		s.hero.base_hp = 1.0e6
		s.hero.hp = 1.0e6
		for i in 30000:
			if s.offers.size() > 0:
				s.choose(Sim.SKIP)
			if s.route_wait:
				var li: int = s.road.nodes[s.road.head]["loc"]
				if li >= 0:
					waits += 1
					if s.road.locations[li]["state"] == SimRoad.LocState.ACTIVE:
						bad += 1
				var outs: Array = s.road.nodes[s.road.head]["out"]
				s.choose_route(s.road.legs[outs[0]]["b"])
			s.step()
			if s.act > 0 or s.phase != K.Phase.ROAD:
				break
	check(waits > 0 and bad == 0, "a escolha da bifurcação vem depois do evento do nó (%d escolhas, %d antes do evento)" % [waits, bad])


func t_acts() -> void:
	var s := _run(3, "horde", "heuristic")
	var acts := int(data.rules["run"]["acts"])
	var at: Array = s.stats["act_t"]
	check(s.phase == K.Phase.OVER, "run em atos termina (%s em %.0f s)" % [s.stats["result"], s.t])
	if s.stats["arena_t"] >= 0.0:
		check(at.size() == acts, "a arena só vem depois dos %d atos (%d)" % [acts, at.size()])
	check(s.stats["relics"].size() == at.size(), "uma relíquia por ato terminado (%d relíquias, %d atos)" % [s.stats["relics"].size(), at.size()])
	check(int(s.stats["locs_visited"]) >= at.size() * 5, "cada ato passa por vários locais (%d)" % s.stats["locs_visited"])
	# Começo do ato seguinte: estrada nova, herói no começo dela, vida mantida.
	var a := _sim(5)
	a.hero.hp = a.hero.max_hp() * 0.5
	var hp := a.hero.hp
	a._end_act()
	check(a.act_pending and a.offers.size() == 1 and a.offers[0]["source"] == "relic", "fim do ato oferece relíquia")
	var old_road := a.road
	a.choose(0)
	a.step()
	check(a.act == 1 and a.road != old_road and a.hero.s == 0.0 and is_equal_approx(a.hero.hp, hp), "ato 2: estrada nova, herói no começo e com a mesma vida")


func t_relics() -> void:
	var s := _sim(2)
	s.gain_relic("heavy_grimoire")
	check(s.hand_size == 7 and s.elixir_max == 9.0, "Grimório Pesado: mão +1, elixir máximo −1 (%d, %.0f)" % [s.hand_size, s.elixir_max])
	s.gain_relic("passage_stone")
	check(s.teleport_cost() == 0.0, "Pedra de Passagem: teleporte de graça")
	s.gain_relic("bone_crown")
	s.elixir = 0.0
	for k in 10:
		var j := s.units.spawn(data.card("rat_horde"), s.hero.x + 5.0, s.hero.y, 0.0, 0.0, 0, 999)
		s.kill_unit(j, K.Death.HERO)
	check(is_equal_approx(s.elixir, 1.0), "Coroa de Ossos: 10 mortes dão +1 de elixir")
	s.gain_relic("watchful_eye")
	s.ability_fired("war_cry")
	check(s.card_cost(s.hand[0]) == 0, "Olho Vigilante: carta grátis logo depois de uma habilidade")
	SaveGame.save(s, "user://test.save")
	var c := SaveGame.load_run(data, "user://test.save")
	check(c.relics == s.relics and c.teleport_cost() == 0.0 and c.hand_size == 7, "relíquias vão no salvamento")
	SaveGame.erase("user://test.save")


func t_events() -> void:
	var ok := true
	for id in data.event_ids:
		for k in data.events_def[id]["options"].size():
			var s := _sim(4)
			s.offers.clear()
			s.gold = 500.0
			s._push_offer("event", [{"kind": "event_opt", "event": id, "opt": k}], {"event": id})
			ok = ok and s.choose(0)
			for g in 5:
				if s.offers.size() > 0:
					s.choose(0)
	check(ok, "todas as opções de todos os eventos rodam")
	var p := _sim(4)
	p.offers.clear()
	p.gold = 0.0
	p._push_offer("event", [{"kind": "event_opt", "event": "hooded_merchant", "opt": 0}], {"event": "hooded_merchant"})
	check(not p.choose(0), "opção que pede ouro é recusada sem ouro")
	var a := _sim(9)
	var b := _sim(9)
	for x in [a, b]:
		x.offers.clear()
		x._push_offer("event", [{"kind": "event_opt", "event": "forgotten_tomb", "opt": 0}], {"event": "forgotten_tomb"})
		x.choose(0)
	check(a.relics == b.relics and a.next_extra_ability == b.next_extra_ability, "chance do evento é determinística pela semente")


func t_offer_single_type() -> void:
	var mixed := 0
	for seed_ in range(1, 40):
		var s := _sim(seed_)
		s.offers.clear()
		s._offer_level()
		for o in s.offers:
			var kinds := {}
			for op in o["options"]:
				kinds[op["kind"]] = true
			if kinds.size() > 1:
				mixed += 1
	check(mixed == 0, "oferta de queda nunca mistura tipos (%d misturadas)" % mixed)


func t_ability_tell() -> void:
	var s := _sim_tough(6)
	s.hero.apply_upgrade("sword_spin")
	s.record_events = true
	_spawn_near(s, "ogre", 1)
	var tell_t := -1.0
	var spin_t := -1.0
	for i in 400:
		s.step()
		for e in s.events:
			if e[0] == K.Ev.ABILITY_TELL and tell_t < 0.0:
				tell_t = s.t
			if e[0] == K.Ev.SPIN and spin_t < 0.0:
				spin_t = s.t
		s.events.clear()
		if spin_t > 0.0:
			break
	check(tell_t > 0.0 and spin_t - tell_t >= 0.95, "aviso da habilidade 1 s antes de ela disparar (aviso %.2f, giro %.2f)" % [tell_t, spin_t])
	var st := s.hero.ability_state("sword_spin")
	check(st.y == float(data.upgrades["sword_spin"]["p"]["interval"]) and st.x > 0.0, "HUD lê a recarga da habilidade (%.1f de %.1f)" % [st.x, st.y])


func t_arena_hunt() -> void:
	var a := _sim(3)
	a.hero.base_hp = 1.0e6
	a.hero.hp = 1.0e6
	a.enter_arena()
	var h := Vector2(a.hero.x, a.hero.y)
	var j := a.units.spawn(data.card("skeleton_archers"), h.x + 8.0, h.y, 0.0, 0.0, 0, 999)
	a.hero._choose_target()
	check(a.hero.target_kind == SimHero.TGT_UNIT and a.hero.target == j, "na arena o herói caça o atirador a 8 m")
	a.units.release(j)
	var tw := a.units.spawn(data.card("gargoyle_tower"), h.x + 6.0, h.y, 0.0, 0.0, 0, 999)
	a.hero._choose_target()
	check(a.hero.target == tw, "na arena a Torre de Gárgula não é mais ignorada")
	# Pedra por 3 s, depois 5 s vulnerável.
	a.units.px[tw] = h.x + 2.0
	var stone_seen := false
	var free_after := false
	a.hero.petrify_t = 100.0
	for i in int(4.0 / a.dt):
		a.units.update(a.dt)
		if a.units.flags[tw] & K.F_STONE:
			stone_seen = true
	free_after = not (a.units.flags[tw] & K.F_STONE)
	check(stone_seen and free_after, "a Torre vira pedra e depois fica vulnerável mesmo com o herói perto")
	a.elixir = 1.0
	check(not a.arena.can_teleport((a.arena.altar + 1) % a.arena.altar_pos.size()), "teleporte custa 2 de elixir")
	a.elixir = 10.0
	var k := (a.arena.altar + 1) % a.arena.altar_pos.size()
	check(a.teleport(k), "teleporta com elixir")
	check(is_equal_approx(a.arena.tp_cd, 12.0), "recarga do teleporte de 12 s (%.1f)" % a.arena.tp_cd)


var _fam_cache: Dictionary = {}


func _family(id: String) -> String:
	if _fam_cache.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
		for c in j["cards"]:
			_fam_cache[c["id"]] = str(c.get("family", "?"))
	return str(_fam_cache.get(id, "?"))


## Unidades novas de uma carta, a dx do herói (o teste chama _apply direto, sem o anel mínimo).
func _spawn(s: Sim, id: String, dx := 0.5) -> Array:
	var before := []
	for j in s.units.hi:
		if s.units.alive[j] == 1:
			before.append(j)
	s._apply(_inst(id), s.hero.x + dx, s.hero.y)
	var out := []
	for j in s.units.hi:
		if s.units.alive[j] == 1 and not before.has(j):
			out.append(j)
	return out


func _tough(s: Sim) -> void:
	s.hero.base_hp = 1.0e7
	s.hero.hp = 1.0e7
	s.hero.shield_hp = 0.0
	s.hero.shield_max = 0.0


func _hit(s: Sim, j: int) -> float:
	_tough(s)
	var h0 := s.hero.hp
	s.unit_hits_hero(j)
	return h0 - s.hero.hp


## Famílias de cartas (rodada autônoma de 09/11/2026): cada combo funciona e rende mais que a carta sozinha.
func t_combos() -> void:
	# Bando: Ratos Raivosos batem mais com mais bicho de bando; Chamado do Bando aumenta.
	var s := _sim(5)
	var rr := _spawn(s, "rabid_rats")
	s.units.n_pack = 1
	var a := _hit(s, rr[0])
	s.units.n_pack = 20
	var b := _hit(s, rr[0])
	check(b > a * 1.5, "Ratos Raivosos: bando grande bate mais (%.1f → %.1f)" % [a, b])
	s._apply(_inst("pack_call"), s.hero.x, s.hero.y)
	var c := _hit(s, rr[0])
	check(c > b * 1.3, "Chamado do Bando aumenta o dano do bando (%.1f → %.1f)" % [b, c])
	# Fogo: Balde de Óleo encharca; Tocha em herói encharcado incendeia.
	s = _sim(5)
	_tough(s)
	s._apply(_inst("torch"), s.hero.x, s.hero.y)
	check(s.burn_t <= 0.0, "Tocha sem óleo não incendeia")
	s._apply(_inst("oil_splash"), s.hero.x, s.hero.y)
	check(s.hero.soaked_t > 0.0, "Balde de Óleo encharca o herói")
	var h0 := s.hero.hp
	s._apply(_inst("torch"), s.hero.x, s.hero.y)
	check(s.burn_t > 0.0 and s.burn_src == "torch", "Tocha em herói encharcado incendeia")
	check(h0 - s.hero.hp > float(data.card("torch").fx["damage"]) * 1.2, "fogo em herói encharcado dói mais (%.0f)" % (h0 - s.hero.hp))
	s = _sim(5)
	s._apply(_inst("tar_net"), s.hero.x, s.hero.y)
	s.step()
	check(s.hero.root_t > 0.0 and s.hero.soaked_t > 0.0, "Rede de Piche enraíza e encharca")
	# Cobiça: Mercenário cresce com o ouro; Pedágio troca ouro por elixir; Mímico morde em dobro perto da isca.
	s = _sim(5)
	var m0 := _spawn(s, "gold_merc", 4.0)
	s.gold = 200.0
	var m1 := _spawn(s, "gold_merc", 4.0)
	check(s.units.max_hp[m1[0]] > s.units.max_hp[m0[0]] * 1.5, "Mercenário com ouro tem mais vida (%.0f → %.0f)" % [s.units.max_hp[m0[0]], s.units.max_hp[m1[0]]])
	s.hand[0] = _inst("toll")
	s.gold = 10.0
	check(s.can_play(0) == K.Block.CONDITION, "Pedágio sem ouro não joga")
	s.gold = 100.0
	s.elixir = 1.0
	check(s.play(0, s.hero.x, s.hero.y) == K.Block.OK and s.elixir >= 3.9 and s.gold < 100.0, "Pedágio troca ouro por elixir (%.1f)" % s.elixir)
	s = _sim(5)
	_tough(s)
	var mi := _spawn(s, "mimic", 1.0)
	s.mimic_bite(mi[0])
	var solo := float(s.stats["dmg_by_card"].get("mimic", 0.0))
	s.zones.append({"kind": "bait", "x": s.units.px[mi[0]], "y": s.units.py[mi[0]], "r": 1.0, "t": 40.0, "xp": 0.0})
	s.units.gen[mi[0]] = 0
	s.mimic_bite(mi[0])
	var both := float(s.stats["dmg_by_card"].get("mimic", 0.0)) - solo
	check(both > solo * 1.5, "Mímico morde mais forte perto da Isca (%.0f → %.0f)" % [solo, both])
	var hp0 := s.hero.hp
	# Morte: Carniçal cresce com mortes perto; Colheita devolve elixir; Explosão de Cadáver.
	s = _sim(5)
	var gh := _spawn(s, "ghoul", 3.0)
	var g0 := _hit(s, gh[0])
	var fod := _spawn(s, "bone_legion", 3.5)
	s.elixir = 0.0
	s._apply(_inst("soul_harvest"), s.hero.x, s.hero.y)
	for j in fod:
		s.kill_unit(j, K.Death.HERO)
	check(_hit(s, gh[0]) > g0 * 1.4, "Carniçal fica mais forte com mortes perto")
	check(s.elixir >= 1.0, "Colheita de Almas devolve elixir por morte (%.2f)" % s.elixir)
	var big := _spawn(s, "ghoul", 1.5)
	_tough(s)
	hp0 = s.hero.hp
	s._apply(_inst("corpse_blast"), s.units.px[big[0]], s.units.py[big[0]])
	check(s.units.alive[big[0]] == 0 and hp0 - s.hero.hp >= 80.0, "Explosão de Cadáver consome o monstro e fere o herói (%.0f)" % (hp0 - s.hero.hp))
	# Sequência: Faísca cresce com feitiços recentes; Eco repete; Acólitos atiram junto; Marca aumenta.
	s = _sim(5)
	_tough(s)
	hp0 = s.hero.hp
	s._apply(_inst("arcane_spark"), s.hero.x, s.hero.y)
	var sp1 := hp0 - s.hero.hp
	s.spell_times = [s.t, s.t, s.t]
	hp0 = s.hero.hp
	s._apply(_inst("arcane_spark"), s.hero.x, s.hero.y)
	check(hp0 - s.hero.hp > sp1 * 2.5, "Faísca Arcana cresce com feitiços recentes (%.0f → %.0f)" % [sp1, hp0 - s.hero.hp])
	s.hand[0] = _inst("shadow_echo")
	s.last_spell_id = ""
	check(s.can_play(0) == K.Block.CONDITION, "Eco Sombrio sem feitiço anterior não joga")
	var echo: Sim.CardInst = s.hand[0]
	s.hand[1] = _inst("oil_splash")
	s.elixir = 10.0
	s.hero.soaked_t = 0.0
	s.play(1, s.hero.x, s.hero.y)
	s.hero.soaked_t = 0.0
	var ei := s.hand.find(echo)
	check(ei >= 0 and s.play(ei, s.hero.x, s.hero.y) == K.Block.OK and s.hero.soaked_t > 0.0, "Eco Sombrio repete o último feitiço")
	_spawn(s, "acolyte", 3.0)
	_tough(s)
	hp0 = s.hero.hp
	s._after_spell(_inst("web"))
	check(hp0 - s.hero.hp > 0.0, "Acólito atira quando você joga um feitiço")
	s.spell_times.clear()
	hp0 = s.hero.hp
	s._apply(_inst("arcane_spark"), s.hero.x, s.hero.y)
	var nomark := hp0 - s.hero.hp
	s._apply(_inst("shadow_mark"), s.hero.x, s.hero.y)
	hp0 = s.hero.hp
	s._apply(_inst("arcane_spark"), s.hero.x, s.hero.y)
	check(hp0 - s.hero.hp > nomark * 1.3, "Marca Sombria aumenta o dano de feitiço (%.0f → %.0f)" % [nomark, hp0 - s.hero.hp])


func _phase_sim(n: int, seed_ := 7) -> Sim:
	var s := Sim.new()
	s.setup(data, seed_, "horde", [], [], n)
	s.auto_route = true
	return s


func t_classes() -> void:
	var s := _phase_sim(2)
	check(s.party_size() == 7 and s.party_class(1) == "arqueira", "Fase 2 alterna Escudeiro e Arqueira")
	s.offers.clear()
	s.hero.hp = 0.0
	s._check_end()
	check(s.hero.cls() == "arqueira" and float(s.hero.H["attack_range"]) >= 6.0 and s.hero.shield_max <= 0.0, "Arqueira ataca de longe e não tem escudo")
	var s3 := _phase_sim(3)
	check(s3.hero.cls() == "cleriga", "Fase 3 começa com a Clériga")
	s3.hero.hp = s3.hero.max_hp() * 0.5
	for i in 40:
		s3.hero.update(s3.dt)
	check(s3.hero.hp > s3.hero.max_hp() * 0.5, "Clériga se cura com o tempo")
	s3.offers.clear()
	var base2: float = float(data.hero_of("escudeiro")["hp"]) * pow(float(data.rules["party"]["step"]), 1)
	s3.hero.hp = 0.0
	s3._check_end()
	check(s3.hero.max_hp() > base2 * 1.15, "a bênção da Clériga dá vida ao próximo (%.0f > %.0f)" % [s3.hero.max_hp(), base2])
	var s4 := _phase_sim(4)
	check(s4.party_class(3) == "mago", "o 4º herói da Fase 4 é o Mago")
	var sw := _phase_sim(1)
	var rats := _spawn(sw, "rat_horde", 2.0)
	sw.hero.H = data.hero_of("mago")
	sw.hero.target = rats[0]
	sw.hero.target_kind = SimHero.TGT_UNIT
	var alive0 := 0
	for j in rats:
		alive0 += sw.units.alive[j]
	sw.hero._splash(sw.units.px[rats[0]], sw.units.py[rats[0]], 500.0)
	var alive1 := 0
	for j in rats:
		alive1 += sw.units.alive[j]
	check(alive1 < alive0 - 2, "golpe do Mago atinge vários ratos em volta (%d → %d)" % [alive0, alive1])
	var s0 := _phase_sim(0)
	check(s0.party_size() == 3 and s0.acts() == 1 and s0.hero.max_hp() < float(data.hero["hp"]) * 0.6, "tutorial: 3 Escudeiros fracos e 1 ato")


func t_group() -> void:
	var s := _phase_sim(4)
	check(s.group_mode(), "Fase 4 é de grupo")
	s.offers.clear()
	s.hero.hp = 0.0
	s._check_end()
	check(s.followers.size() == 1 and s.party_idx == 1, "quem chega levanta o caído: 2 heróis de pé (%d seguidores)" % s.followers.size())
	if s.followers.size() > 0:
		check(absf(s.followers[0].hp / s.followers[0].max_hp() - 0.5) < 0.05, "o levantado volta com metade da vida")
		s.offers.clear()
		s.followers[0].hp = 0.0
		s._check_end()
		check(s.followers.size() == 1 and s.party_idx == 2, "o levantado cai de novo e fica no chão; chega o próximo (%d)" % s.followers.size())
		# Monstro vai no herói mais perto.
		var f: SimHero = s.followers[0]
		f.x = s.hero.x + 20.0
		f.y = s.hero.y
		f.hp = f.max_hp()
		var near := _spawn(s, "ghoul", 21.0)
		var before := f.hp
		for i in 40:
			s.units.update(s.dt)
		check(f.hp < before, "monstro perto do seguidor ataca o seguidor")
	var n := 0
	while s.phase != K.Phase.OVER and n < 40:
		s.offers.clear()
		s.hero.hp = 0.0
		for g in s.followers:
			g.hp = 0.0
		s._check_end()
		n += 1
	check(s.phase == K.Phase.OVER and str(s.stats["result"]) in ["win", "win_early"], "a fase de grupo termina em vitória quando ninguém fica de pé (%s, %d quedas)" % [str(s.stats["result"]), int(s.stats["heroes_fallen"])])
	var r := Sim.new()
	r.setup(data, 11, "horde", [], [], 4)
	r.auto_route = true
	var bot := PlayerBot.load_bot("heuristic", 11)
	var k := 0
	while r.phase != K.Phase.OVER and k < 60000:
		bot.think(r)
		r.step()
		k += 1
	check(r.phase == K.Phase.OVER, "run completa da Fase 4 com o bot termina (%s em %.0f s, %d quedas)" % [str(r.stats["result"]), r.t, int(r.stats["heroes_fallen"])])
