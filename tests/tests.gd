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
	t_deck_cycle()
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
	t_offer_single_rarity()
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
	t_group_spells()
	t_stall_and_overtime()
	t_human_bot()
	t_translations()
	t_keywords()
	t_card_fx()
	t_rarity_pool()
	t_dragon_c6()
	t_cards_lich_common()
	t_plague_cards()
	t_unique_art()
	print("falhas: ", fails)
	get_tree().quit(fails)


func t_data() -> void:
	check(data.pool.size() == 84, "84 cartas na pool (%d)" % data.pool.size())
	check(data.upgrades.size() == 15, "15 upgrades")
	check(data.contracts.size() == 8, "8 contratos")
	# Vilões (C3): dono válido em tudo; baralho inicial só com cartas do vilão ou comuns, liberadas com ele.
	var owners := ["common"] + data.villain_ids
	var bad: Array = []
	for c in data.pool:
		if not owners.has(c.owner):
			bad.append(c.id)
	for x in data.relics.values() + data.contracts + data.events_def.values():
		if not owners.has(str(x.get("owner", ""))):
			bad.append(str(x["id"]))
	check(bad.is_empty() and data.villain_ids == ["plague", "dragon", "lich"], "3 vilões; owner válido em cartas, relíquias, contratos e eventos %s" % str(bad))
	for vid in data.villain_ids:
		var have: Array = data.villain_cards(vid) + data.common_cards()
		var miss: Array = []
		for id in data.deck(vid)["cards"]:
			if not data.in_pool(data.card(id), vid) or not have.has(id):
				miss.append(id)
		check(miss.is_empty(), "baralho inicial de %s é do vilão/comum e vem liberado %s" % [vid, str(miss)])
	check(data.villain_id("horde") == "plague" and data.villain_id("treasure") == "dragon" and data.villain_id("cult") == "lich", "ids antigos de Pacto viram vilões")


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
	check(s.hand.size() == 5, "Praga tem mão de 5 como todo vilão")


func t_costs() -> void:
	var s := _sim(1, "dragon")
	var g := Sim.CardInst.new()
	g.def = data.card("goblin_dynamiter")
	check(s.card_cost(g) == 3, "Dragão: Goblin custa 3")
	var tw := Sim.CardInst.new()
	tw.def = data.card("gargoyle_tower")
	check(s.card_cost(tw) == 4, "Dragão: Torre (estrutura) continua 4")
	check(is_equal_approx(s.gold, 30.0), "Dragão começa com 30 de ouro")
	# Passivas dos vilões.
	s.gold = 120.0
	check(is_equal_approx(s.hoard_fire(), 0.10), "Tesouro do Dragão: 120 de ouro = +10%% de fogo (%.2f)" % s.hoard_fire())
	s.gold = 1000.0
	check(is_equal_approx(s.hoard_fire(), 0.30), "Tesouro do Dragão: teto de +30%")
	var l := _sim(1, "lich")
	var bolt := _inst("shadow_bolt")
	for k in 8:
		var j := l.units.spawn(data.card("bone_legion"), l.hero.x + 6.0, l.hero.y, 0.0, 0.0, 0, 999)
		l.kill_unit(j, K.Death.HERO)
	check(l.harvest_free and l.card_cost(bolt) == 0, "Colheita do Lich: 8 mortes suas = próximo feitiço custa 0")
	var p := _sim(1, "plague")
	var before := p.units.count
	for k in 200:
		var j := p.units.spawn(data.card("rat_horde"), p.hero.x + 30.0, p.hero.y, 0.0, 0.0, 0, 999)
		p.kill_unit(j, K.Death.EXPIRE if k < 0 else K.Death.HERO)
	var born := p.units.count - before
	check(born >= 15 and born <= 65, "Infestação da Praga: ~20%% das mortes de Bando deixam um rato (%d de 200)" % born)
	var ofs := true
	for k in 20:
		for o in s._card_options(3, func(cd: CardDef): return true):
			ofs = ofs and data.in_pool(data.card(o["id"]), "dragon")
	check(ofs, "ofertas do Dragão só têm cartas dele e comuns")


func t_sacrifice_and_cycle() -> void:
	var s := _sim()
	s.elixir = 3.0
	var first: Sim.CardInst = s.hand[0]
	check(s.sacrifice(0), "sacrifício aceito")
	check(absf(s.elixir - 4.0) < 0.001, "sacrifício dá +1 de elixir")
	check(s.discard.has(first) or s.queue.has(first) or s.hand.has(first), "carta sacrificada volta ao deck")
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
	dead.def = data.card("shadow_echo")
	s.last_spell_id = ""
	s.hand[0] = dead
	check(s.can_play(0) == K.Block.CONDITION and s.sacrifice(0) and s.elixir < 0.001, "na recarga, carta sem condição (Eco sem feitiço) gira (sem elixir)")
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
		s._apply(lib, s.hero.x, s.hero.y)
	check(s.hand.size() <= Sim.HAND_MAX and Sim.HAND_MAX == 7, "Biblioteca repetida não passa do teto da mão de 7 (%d, tamanho %d)" % [s.hand.size(), s.hand_size])
	var full := s.hand.size()
	for k in int(45.0 / s.dt):
		s.step()
	check(s.hand_size == 5 and s.hand.size() <= full, "Biblioteca acaba: a mão volta a 5 sem expulsar carta (%d, tamanho %d)" % [s.hand.size(), s.hand_size])
	# Escada de elixir por ato, teto 20 e custo liberado por ato (C4).
	var e := _sim(2, "dragon")
	check(is_equal_approx(e.elixir_max, 10.0) and e.max_offer_cost() == 7, "ato 1: elixir máximo 10, ofertas até custo 7")
	e.act = 1
	e.act_elixir_base = e._act_elixir("max", 0.0)
	e.recalc_elixir_max()
	check(is_equal_approx(e.elixir_max, 13.0) and e.max_offer_cost() == 9, "ato 2: elixir máximo 13, ofertas até custo 9")
	e.act = 2
	e.act_elixir_base = e._act_elixir("max", 0.0)
	e.recalc_elixir_max()
	check(is_equal_approx(e.elixir_max, 16.0) and e.max_offer_cost() == 12, "ato 3: elixir máximo 16, ofertas até custo 12")
	e.add_temp("elixir_max", 4.0, 40.0, "t")
	e.add_temp("elixir_max", 4.0, 40.0, "t")
	check(is_equal_approx(e.elixir_max, 20.0), "elixir máximo nunca passa de 20 (%.0f)" % e.elixir_max)
	e.elixir = 20.0
	e.temps.clear()
	e.recalc_elixir_max()
	check(is_equal_approx(e.elixir, 16.0), "elixir acima do máximo que encolheu é cortado")
	var cheap := _sim(3, "plague")
	var okc := true
	for k in 30:
		for o in cheap._card_options(3, func(cd: CardDef): return true):
			okc = okc and data.card(o["id"]).cost <= 7
	check(okc, "ato 1 nunca oferece carta de custo acima de 7")
	var sc := _sim(4, "plague")
	sc.elixir = 0.0
	sc.sacrifice(0)
	check(is_equal_approx(sc.elixir, 1.0), "sacrifício rende 10%% do elixir máximo (%.2f)" % sc.elixir)
	var col := _sim(5, "plague")
	col._apply(_inst("soul_collector"), col.hero.x, col.hero.y)
	col._apply(_inst("soul_collector"), col.hero.x, col.hero.y)
	check(is_equal_approx(col.temp_sum("elixir_regen"), 0.8), "Coletor de Almas é Temporário e cópias somam")


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
	u.setup(data, 2, "plague", [], ["rat_horde", "web", "ogre"])
	var ok := true
	for k in 20:
		for o in u._card_options(3, func(cd: CardDef): return true):
			ok = ok and o["id"] in ["rat_horde", "web", "ogre"]
	check(ok, "ofertas só sorteiam cartas desbloqueadas")


func t_meta() -> void:
	var path := "user://test_meta.save"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var m := MetaSave.load_or_new(data, path)
	check(m.villains == ["plague"] and m.villain == "plague" and not m.phase_open(2), "começa só com a Praga e a fase 2 fechada")
	check(m.is_unlocked("rat_horde") and m.is_unlocked("rat_king") and m.is_unlocked("ogre") and not m.is_unlocked("torch"), "coleção inicial: Praga (comuns, incomuns, raras iniciais) e comuns")
	check(m.win_phase(1) == "dragon" and m.villains.has("dragon") and m.is_unlocked("torch") and m.phase_open(2), "vencer a fase 1 libera o Dragão e as cartas dele")
	check(not m.can_buy("torch") and m.can_buy("slime") == false, "Almas não compram comuns nem incomuns")
	m.win_phase(2)
	var rare := ""
	for c in data.pool:
		if c.rarity == 2 and not m.is_unlocked(c.id) and m.can_buy(c.id):
			rare = c.id
			break
	check(rare != "" and m.unlock_cost(rare) == 100, "rara bloqueada de vilão liberado custa 100 Almas (%s)" % rare)
	m.souls = 130
	check(m.unlock(rare) and m.souls == 30 and m.is_unlocked(rare), "desbloquear gasta as Almas")
	var s0 := m.souls
	m.win_phase(3)
	check(m.souls == s0 + 60 and m.rare_choices == 1, "fase 3 paga 60 Almas e uma rara à escolha")
	var ch := m.rare_choice_options(3, 5)
	check(ch.size() > 0 and m.choose_rare(ch[0]) and m.is_unlocked(ch[0]) and m.rare_choices == 0, "escolher a rara libera a carta")
	# Save antigo de Pactos: migra.
	var old := "user://test_meta_old.save"
	var f := FileAccess.open(old, FileAccess.WRITE)
	f.store_var({"souls": 77, "pacts": ["horde", "treasure"], "pact": "treasure", "unlocked": ["cosmic_ray", "ogre"], "phases_won": [1]})
	f.close()
	var mo := MetaSave.load_or_new(data, old)
	check(mo.souls == 77 and mo.villains == ["plague", "dragon"] and mo.villain == "dragon" and not mo.is_unlocked("cosmic_ray"), "save antigo: Pactos viram vilões, Almas ficam, carta removida some")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(old))
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
	# Disputa em 3 etapas (C5): cada etapa tem meta e janela; recompensa por degraus.
	var L: Dictionary = data.rules["locations"]
	# Ritual: mortes de monstros seus dentro do círculo (6, 10, 14).
	var s := _at_location("ritual")
	var p: Vector2 = s.road.locations[int(s.contest["li"])]["pos"]
	check(s.contest["type"] == "ritual" and s.hero.hold and int(s.contest["stages"]) == 3 and int(s.contest["stage"]) == 0, "Ritual: o herói para no local e a etapa 1 começa")
	for k in 6:
		var j := s.units.spawn(data.card("ogre"), p.x + 1.0, p.y, 0.0, 0.0, 0, 999)
		s.kill_unit(j, K.Death.HERO)
	s.step()
	check(int(s.contest["stage"]) == 1 and int(s.contest["won"]) == 1 and is_equal_approx(float(s.contest["goal"]), 10.0), "Ritual: 6 mortes vencem a etapa 1; a etapa 2 pede 10")
	_win_stage(s)
	_win_stage(s)
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "upgrade", "Ritual: as 3 etapas dão a recompensa cheia (nível de 1 entre 3)")
	s = _at_location("ritual")
	_steps(s, 3.0 * float(L["ritual"]["stages"][0]["window"]) + 0.5)
	check(s.contest.is_empty() and s.offers.is_empty() and not s.hero.hold, "Ritual: 3 janelas sem mortes → nada, e o herói segue")
	# Degraus: 1 etapa vencida = 15 de ouro, sem oferta.
	s = _at_location("ritual")
	var g0 := s.gold
	_win_stage(s)
	_steps(s, 2.0 * float(L["ritual"]["stages"][0]["window"]) + 0.5)
	check(s.contest.is_empty() and s.offers.is_empty() and is_equal_approx(s.gold - g0, 15.0), "1 etapa vencida: 15 de ouro, sem a recompensa do local (%.0f)" % (s.gold - g0))
	# Ritual, ato 2, 3ª etapa: só mortes de custo 3 ou mais.
	s = _at_location("ritual")
	s.act = 1
	_win_stage(s)
	_win_stage(s)
	check(str(s.contest["variant"]) == "cost3", "Ritual ato 2: a 3ª etapa pede monstros de custo 3+")
	for k in 3:
		var j := s.units.spawn(data.card("rat_horde"), p.x + 1.0, p.y, 0.0, 0.0, 0, 999)
		s.kill_unit(j, K.Death.HERO)
	check(is_equal_approx(float(s.contest["progress"]), 0.0), "Ritual ato 2: morte de rato (custo 2) não conta")
	# Santuário: monstro que luta no círculo; torre não conta.
	s = _at_location("shrine")
	p = s.road.locations[int(s.contest["li"])]["pos"]
	s.hero.petrify_t = 100.0
	s.units.spawn(data.card("gargoyle_tower"), p.x + 2.0, p.y, 0.0, 0.0, 0, 999)
	_steps(s, 7.0)
	check(int(s.contest["won"]) == 0, "Santuário: só uma torre no círculo não conta")
	s.units.spawn(data.card("slime"), p.x - 2.0, p.y, 0.0, 0.0, 0, 999)
	_steps(s, 8.6)
	check(int(s.contest["won"]) >= 1, "Santuário: 6 s com monstro no círculo vencem a etapa")
	s = _at_location("shrine")
	s.act = 2
	_win_stage(s)
	_win_stage(s)
	check(s.contest.has("p2"), "Santuário ato 3: a 3ª etapa tem dois círculos")
	_win_stage(s)
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "card", "Santuário: as 3 etapas dão a carta rara")
	# Taverna: casas no chão, meta cumulativa 1, 2, 3.
	s = _at_location("tavern")
	var loc: Dictionary = s.road.locations[int(s.contest["li"])]
	check(loc["houses"].size() == int(L["tavern"]["houses"]), "Taverna: as casas aparecem")
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
	for k in 3:
		s.step()
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "mod", "Taverna: todas as casas no chão vencem as 3 etapas (modificador)")
	# Ponte: dano na janela (150, 250, 400).
	s = _at_location("bridge")
	check(s.hero.tavern_t > 0.0, "Ponte: o herói fica lento")
	s.damage_hero(200.0, s.hero.x + 1.0, s.hero.y, 0, SimHero.DMG_PIERCE, "test")
	s.step()
	check(int(s.contest["won"]) == 1 and is_equal_approx(float(s.contest["goal"]), 250.0), "Ponte: 150 de dano vencem a etapa 1")
	_win_stage(s)
	_win_stage(s)
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "pick", "Ponte: as 3 etapas dão a escolha do tipo")
	# Fonte: interromper 3 goles; gole completo não ajuda o jogador.
	s = _at_location("fountain")
	check(s.hero.drink_t > 0.0, "Fonte: o herói começa a beber")
	var x0 := s.hero.x
	_steps(s, 1.0)
	check(is_equal_approx(s.hero.x, x0), "Fonte: bebendo, ele não anda")
	s.hero_fear(s.hero.x + 1.0, s.hero.y)
	s.step()
	check(int(s.contest["won"]) == 1 and s.hero.drink_t > 0.0, "Fonte: medo interrompe o gole 1 e começa o gole 2")
	_win_stage(s)
	_win_stage(s)
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "remove", "Fonte: 3 goles interrompidos = remover uma carta")
	s = _at_location("fountain")
	s.hero.base_hp = 1000.0
	s.hero.hp = 500.0
	_steps(s, 3.0 * float(L["fountain"]["stages"][0]["window"]) + 0.5)
	check(s.offers.is_empty() and s.hero.hp > 500.0, "Fonte: 3 goles completos curam o herói e não dão nada (%.0f)" % s.hero.hp)
	# Loja e "?": sem disputa.
	s = _at_location("shop")
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["source"] == "shop", "Loja abre na chegada, sem disputa")
	s = _at_location("event")
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["source"] == "event", "Local ? abre um evento de texto")


## Vence a etapa atual da disputa (meta cheia) e dá um passo.
func _win_stage(s: Sim) -> void:
	if s.contest.is_empty():
		return
	s.contest["progress"] = float(s.contest["goal"])
	if s.contest["type"] == "tavern":
		var loc: Dictionary = s.road.locations[int(s.contest["li"])]
		var need := int(s.contest["goal"])
		for k in loc["houses"].size():
			if s._houses_down(loc) < need:
				s.damage_house(k, 1.0e6)
	s.step()


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
	check(s.hand_size == 6 and s.elixir_max == 9.0, "Grimório Pesado: mão +1, elixir máximo −1 (%d, %.0f)" % [s.hand_size, s.elixir_max])
	s.gain_relic("shortcut_stone")
	var cost0 := s.card_cost(s.hand[0])
	s.contest = {"probe": true}
	check(s.card_cost(s.hand[0]) == maxi(0, cost0 - 2), "Pedra do Atalho: a primeira carta da disputa custa 2 a menos")
	s.contest["first"] = true
	check(s.card_cost(s.hand[0]) == cost0, "Pedra do Atalho: só a primeira carta")
	s.contest = {}
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
	check(c.relics == s.relics and c.rv("contest_first_discount") == 2.0 and c.hand_size == 6, "relíquias vão no salvamento")
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


## Raridade única (10/11/2026): recompensas e escolhas trazem uma raridade só; a loja fica de fora.
func t_offer_single_rarity() -> void:
	var mixed := 0
	var seen := 0
	for seed_ in range(1, 40):
		var s := _sim(seed_)
		for which in 5:
			s.offers.clear()
			match which:
				0: s._offer_level()
				1: s.offers.append({"options": s._card_options(3, func(_cd: CardDef): return true)})
				2: s.offers.append({"options": s._card_options(3, func(cd: CardDef): return cd.rarity >= 2)})
				3: s._offer_contract({"kind": "card", "min_rarity": "uncommon"})
				4: s._offer_relics()
			for o in s.offers:
				var rs := {}
				for op in o["options"]:
					if op["kind"] == "card":
						rs[data.card(op["id"]).rarity] = true
					elif op["kind"] == "relic":
						rs[str(data.relics[op["id"]].get("rarity", "common"))] = true
				if rs.size() > 0:
					seen += 1
				if rs.size() > 1:
					mixed += 1
	check(seen > 100 and mixed == 0, "ofertas com raridade trazem uma só (%d ofertas, %d misturadas)" % [seen, mixed])


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


## Passo C0: dono de toda carta, vocabulário de "ai" e primitivas de CardFxLib (docs/CARD_FX.md).
func t_card_fx() -> void:
	var owners := ["plague", "dragon", "lich", "common"]
	var bad: Array = []
	for c in data.pool:
		if not owners.has(c.owner):
			bad.append(c.id)
	check(bad.is_empty(), "toda carta tem owner válido %s" % [bad])
	var aims := ["hero", "cluster", "line", "soaked", "own_unit", "ahead", "unit_key", "location"]
	var conds := ["hero_hindered", "hero_soaked", "hero_shielded", "elixir_spare", "elixir_below", "hand_has", "pack_below",
		"own_near_hero", "own_units_below", "last_spell_has", "unit_alive", "wounded_near_hero",
		"recent_deaths", "gold_above", "contest_active", "pack_min"]
	var ai_bad: Array = []
	for c in data.pool:
		if not aims.has(PlayerBot.aim_of(c)):
			ai_bad.append(c.id + ":aim")
		var cs: Array = []
		for r in c.ai.get("value", []):
			cs.append(r.get("if", {}))
		cs.append(c.ai.get("needs", {}))
		cs.append(c.ai.get("wait_for", {}).get("if", {}))
		for cd in cs:
			for key in cd:
				if not conds.has(key):
					ai_bad.append(c.id + ":" + key)
	check(ai_bad.is_empty(), "ai das cartas só usa o vocabulário conhecido %s" % [ai_bad])
	# Carta montada só com ops: dano, estado, zona, invocação, elixir e ouro.
	var s := _sim(5)
	_tough(s)
	var fake := CardDef.from_dict({"id": "fx_test", "type": "spell", "cost": 1, "owner": "common",
		"fx": {"damage": 100, "radius": 3.0, "soak": 4.0},
		"ops": [{"op": "damage", "damage": "damage", "radius": "radius"},
			{"op": "status", "status": "soaked", "duration": "soak", "target": "area", "radius": 3.0},
			{"op": "zone", "kind": "fire", "radius": 2.0, "duration": 3.0, "dps": 10},
			{"op": "summon", "unit": "skeleton", "n": 2},
			{"op": "elixir", "amount": 2}, {"op": "gold", "amount": 10}]}, 999)
	var ci := Sim.CardInst.new()
	ci.def = fake
	s.elixir = 0.0
	var h0 := s.hero.hp
	var u0 := s.units.count
	var z0 := s.zones.size()
	var g0 := s.gold
	s._apply(ci, s.hero.x, s.hero.y)
	check(h0 - s.hero.hp > 50.0, "op damage machuca o herói (%.0f)" % (h0 - s.hero.hp))
	check(s.hero.soaked_t > 3.0, "op status encharca")
	check(s.zones.size() == z0 + 1 and s.zones[-1]["kind"] == "fire", "op zone cria a zona de fogo")
	var alive := 0
	for j in s.units.hi:
		alive += s.units.alive[j]
	check(alive >= 2, "op summon invoca 2 esqueletos (%d unidades, antes %d)" % [alive, u0])
	check(is_equal_approx(s.elixir, 2.0) and s.gold > g0, "ops elixir e gold")
	# Gatilho ao morrer (no Ogro, só durante o teste).
	var s2 := _sim(5)
	var dd := data.card("ogre")
	dd.on_death = [{"op": "elixir", "amount": 3}]
	s2._apply(_inst("ogre"), s2.hero.x + 5.0, s2.hero.y)
	var jj := -1
	for j in s2.units.hi:
		if s2.units.alive[j] == 1 and s2.units.def[j] == dd.idx:
			jj = j
	s2.elixir = 0.0
	if jj >= 0:
		s2.kill_unit(jj, K.Death.HERO)
	dd.on_death = []
	check(jj >= 0 and is_equal_approx(s2.elixir, 3.0), "on_death roda as ops quando a unidade morre")


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


## Fase de grupo com dois heróis colados: o da vez e um seguidor a 1 m.
func _two_heroes() -> Sim:
	var s := _phase_sim(4)
	s.offers.clear()
	s.hero.hp = 0.0
	s._check_end()
	s.offers.clear()
	var f: SimHero = s.followers[0]
	f.x = s.hero.x + 1.0
	f.y = s.hero.y
	f.hp = f.max_hp()
	s.hero.hp = s.hero.max_hp()
	return s


func _cast(s: Sim, id: String, x: float, y: float) -> void:
	var ci := Sim.CardInst.new()
	ci.def = data.card(id)
	ci.uid = 999
	s._apply(ci, x, y)


func t_group_spells() -> void:
	# Zonas, Raio Sombrio, Óleo e Prisão pegam o grupo (10/11/2026); antes só o herói da vez.
	var s := _two_heroes()
	var f: SimHero = s.followers[0]
	_cast(s, "web", s.hero.x + 0.5, s.hero.y)
	s._zones()
	check(s.hero.slow_t > 0.0 and f.slow_t > 0.0, "teia prende o herói e o seguidor")
	s = _two_heroes()
	f = s.followers[0]
	var b0 := f.hp
	_cast(s, "boiling_oil", s.hero.x + 0.5, s.hero.y)
	for _k in 20:
		s._zones()
	check(f.hp < b0 and f.soaked_t > 0.0, "óleo fervente queima e encharca o seguidor (%.0f -> %.0f)" % [b0, f.hp])
	s = _two_heroes()
	f = s.followers[0]
	_cast(s, "oil_splash", s.hero.x + 0.9, s.hero.y)
	check(f.soaked_t > 0.0 and s.hero.soaked_t <= 0.0, "Balde de Óleo em grupo encharca só o herói mais perto do ponto")
	s.hero.soaked_t = 1.0
	_cast(s, "torch", s.hero.x + 0.5, s.hero.y)
	check(f.burn_t > 0.0, "Tocha incendeia o seguidor encharcado")
	var dry := _two_heroes()
	var df: SimHero = dry.followers[0]
	var d0 := df.hp
	_cast(dry, "torch", dry.hero.x, dry.hero.y)
	check(is_equal_approx(df.hp, d0), "Tocha não respinga no seguidor seco")
	var fb := f.hp
	for _k in 10:
		s._burn()
	check(f.hp < fb, "seguidor em chamas perde vida")
	s = _two_heroes()
	f = s.followers[0]
	s.hero.shield_hp = 0.0
	var h0 := s.hero.hp
	b0 = f.hp
	# Raio de trás do herói passando pelos dois (linha no eixo x).
	_cast(s, "shadow_bolt", s.hero.x - 3.0, s.hero.y)
	check(s.hero.hp < h0 and f.hp < b0, "Raio Sombrio atravessa a linha e pega os dois")
	check(h0 - s.hero.hp > (b0 - f.hp) * 1.5, "o primeiro da linha leva o golpe cheio, o segundo metade")
	s = _two_heroes()
	f = s.followers[0]
	for hh in s.all_heroes():
		hh.root_t = 2.0
	var fx0 := f.x
	f.x += 10.0
	var fx1 := f.x
	for _k in 10:
		s._follow(f)
	check(is_equal_approx(f.x, fx1) and fx1 != fx0, "seguidor preso não anda atrás do grupo")
	# Sozinho, nada muda: o Balde encharca o herói mesmo longe do ponto.
	var solo := _sim(5)
	_cast(solo, "oil_splash", solo.hero.x + 30.0, solo.hero.y)
	check(solo.hero.soaked_t > 0.0, "fora da fase de grupo o Balde de Óleo encharca o herói em qualquer ponto")


func t_stall_and_overtime() -> void:
	# Isca fora do alcance não segura o herói para sempre (a run do Tesouro travava até o tempo acabar).
	var s := _sim(15, "treasure")
	s.auto_route = true
	s.hero.prog_mark = s.hero.s
	for _k in int(25.0 / s.dt):
		s.hero.hold = false
		s.hero.x = s.hero.ox
		s.hero.y = s.hero.oy
		s.hero.update(s.dt)
		s.tick += 1
		s.t += s.dt
	check(s.hero.push_t > 0.0, "herói parado 20 s fica impaciente (push %.1f s)" % s.hero.push_t)
	s.zones.append({"kind": "bait", "x": s.hero.x + 6.0, "y": s.hero.y, "r": 1.0, "t": 40.0, "xp": 0.0})
	s.hero._choose_target()
	check(not s.hero.lure_on, "impaciente, ele ignora a Isca de Ouro")
	# Prorrogação da arena: depois de overtime_s, sem cura e golpe maior.
	var a := _sim(3)
	a.enter_arena()
	var d0 := a.hero.damage()
	check(a.overtime() == 0.0, "arena começa sem prorrogação")
	a.t += float(data.rules["arena"]["overtime_s"]) + 120.0
	check(absf(a.overtime() - 2.0) < 0.01 and a.hero.damage() > d0 * 1.2, "2 min de prorrogação: golpe do herói %.0f -> %.0f" % [d0, a.hero.damage()])


func t_human_bot() -> void:
	# O bot humano termina runs nas fases 1 e 4 sem travar e sem jogada recusada em excesso.
	for ph in [1, 4]:
		var s := Sim.new()
		s.setup(data, 21, "ruin", [], [], ph)
		s.auto_route = false
		var b := PlayerBot.load_bot("human", 21)
		var k := 0
		while s.phase != K.Phase.OVER and k < 70000:
			b.think(s)
			s.step()
			k += 1
		var st: Dictionary = (b as HumanBot).stats
		check(s.phase == K.Phase.OVER and s.stats["result"] != "timeout", "bot humano termina a fase %d (%s em %.0f s, %d jogadas)" % [ph, s.stats["result"], s.t, st["plays"]])
		check(st["refused"] <= st["plays"] * 0.05 + 2, "bot humano quase nunca tem jogada recusada (%d de %d)" % [st["refused"], st["plays"]])


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
	var base2: float = float(data.hero_of(s3.party_class(1), s3.phase_hp_mult)["hp"]) * pow(float(data.rules["party"]["step"]), 1) * float(s3.deck_rules.get("hero_hp_mult", 1.0))
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
	var path := "user://test_group.save"
	check(SaveGame.save(s, path), "salva a run da fase de grupo")
	var ld := SaveGame.load_run(data, path)
	check(ld != null and ld.campaign_phase == 4 and ld.followers.size() == s.followers.size() and ld.hero.cls() == s.hero.cls(),
		"continuar a fase de grupo mantém a fase, a classe e os seguidores (%d)" % (ld.followers.size() if ld else -1))
	if ld and ld.followers.size() > 0:
		check(ld.followers[0].cls() == s.followers[0].cls() and absf(ld.followers[0].hp - s.followers[0].hp) < 0.01, "seguidor volta com a classe e a vida")
	SaveGame.erase(path)
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


## Baralho com descarte (C2): nenhuma carta some nem duplica; o descarte vira compra; "Retorna" volta uma vez por
## embaralhada; cartas de Rota saem do baralho na arena.
func _deck_total(s: Sim) -> int:
	var n := s.queue.size() + s.discard.size() + s.benched.size()
	for c in s.hand:
		if c:
			n += 1
	return n


func t_deck_cycle() -> void:
	var s := _sim(3, "treasure")
	var ok := true
	var reshuffled := false
	for k in 60:
		s.elixir = 20.0
		s.sac_elixir_t = -100.0
		s.sacrifice(k % s.hand.size())
		ok = ok and _deck_total(s) == s.cards.size() and s.hand.size() == mini(s.hand_size, s.cards.size())
		reshuffled = reshuffled or int(s.stats.get("shuffles", 0)) > 0
	check(ok, "ciclo compra/mão/descarte conserva as cartas (%d)" % s.cards.size())
	check(reshuffled, "descarte é embaralhado quando a compra acaba")
	# Retorna: uma vez por embaralhada.
	var r := _sim(4)
	var c: Sim.CardInst = r.hand[0]
	c.def = CardDef.from_dict({"id": "t_returns", "category": "field", "type": "spell", "cost": 0, "rarity": "rare", "owner": "common", "fx": {"returns": true}}, 0)
	r._to_discard(c)
	check(r.queue.has(c) and not r.discard.has(c), "Retorna: volta para a compra")
	r.queue.erase(c)
	r._to_discard(c)
	check(r.discard.has(c), "Retorna: na segunda vez na mesma embaralhada, vai ao descarte")
	r.queue.clear()
	r.draw_card()
	r.discard.erase(c)
	r._to_discard(c)
	check(r.queue.has(c), "Retorna: depois de embaralhar, pode voltar de novo")
	# Rota fora na arena.
	var a := _sim(5, "treasure")
	var routes := 0
	for ci in a.cards:
		if ci.def.category == "route":
			routes += 1
	a.enter_arena()
	var left := 0
	for arr in [a.queue, a.discard, a.hand]:
		for ci in arr:
			if ci and ci.def.category == "route":
				left += 1
	check(routes > 0 and left == 0 and a.benched.size() == routes and _deck_total(a) == a.cards.size(), "cartas de Rota ficam fora do baralho na arena (%d)" % routes)


## C6, Dragão Avarento: as 12 cartas novas (uma verificação por mecânica).
func t_dragon_c6() -> void:
	# Cofre do Dragão: ouro em dobro por 30 s.
	var s := _sim(5, "dragon")
	s.elixir = 20.0
	s.hand[0] = _inst("dragon_vault")
	var g0 := s.gold
	s._earn_gold(10.0)
	var plain := s.gold - g0
	check(s.play(0, s.hero.x, s.hero.y) == K.Block.OK, "Cofre do Dragão joga")
	g0 = s.gold
	s._earn_gold(10.0)
	check(is_equal_approx(s.gold - g0, plain * 2.0), "Cofre do Dragão dobra o ouro (%.1f → %.1f)" % [plain, s.gold - g0])
	_steps(s, 31.0)
	g0 = s.gold
	s._earn_gold(10.0)
	check(is_equal_approx(s.gold - g0, plain), "Cofre do Dragão acaba em 30 s")
	# Imposto de Sangue: paga 20, a próxima carta custa 3 a menos (uma só) e a carta Retorna.
	s = _sim(5, "dragon")
	s.elixir = 20.0
	s.gold = 100.0
	var bt := _inst("blood_tax")
	var bo := _inst("boiling_oil")
	s.hand[0] = bt
	s.hand[1] = bo
	check(s.card_cost(bo) == 3, "Óleo Fervente custa 3 sem o Imposto")
	s.play(0, s.hero.x, s.hero.y)
	check(is_equal_approx(s.gold, 80.0), "Imposto de Sangue paga 20 de ouro (%.0f)" % s.gold)
	check(s.card_cost(bo) == 0, "depois do Imposto a próxima carta custa 3 a menos (%d)" % s.card_cost(bo))
	check(s.queue.has(bt) and s.returned.has(bt.uid), "Imposto de Sangue Retorna ao baralho")
	s.play(s.hand.find(bo), s.hero.x, s.hero.y)
	check(s.card_cost(_inst("boiling_oil")) == 3, "o desconto vale para uma carta só")
	s.gold = 5.0
	s.hand[0] = _inst("blood_tax")
	check(s.can_play(0) == K.Block.CONDITION, "Imposto de Sangue sem 20 de ouro não joga")
	# Avalanche de Ouro: 3× o ouro (teto 900), sem gastar; prende o herói.
	s = _sim(5, "dragon")
	_tough(s)
	s.elixir = 20.0
	s.hand[0] = _inst("gold_avalanche")
	s.gold = 20.0
	check(s.can_play(0) == K.Block.CONDITION, "Avalanche sem 30 de ouro não joga")
	s.gold = 100.0
	var h0 := s.hero.hp
	s.play(0, s.hero.x, s.hero.y)
	check(absf((h0 - s.hero.hp) - 300.0) < 1.0 and s.gold >= 100.0, "Avalanche: 3× o ouro e não gasta (%.0f, ouro %.0f)" % [h0 - s.hero.hp, s.gold])
	check(s.hero.root_t > 1.5, "Avalanche prende o herói")
	s.hand[0] = _inst("gold_avalanche")
	s.gold = 1000.0
	h0 = s.hero.hp
	s.play(0, s.hero.x, s.hero.y)
	check(absf((h0 - s.hero.hp) - 900.0) < 1.0, "Avalanche tem teto de 900 (%.0f)" % (h0 - s.hero.hp))
	# Ouro Derretido: gasta até 30, 6 de fogo por ouro, lentidão.
	s = _sim(5, "dragon")
	_tough(s)
	s.elixir = 20.0
	s.gold = 20.0
	s.hand[0] = _inst("molten_gold")
	check(s.can_play(0) == K.Block.OK, "Ouro Derretido joga com 20 de ouro")
	h0 = s.hero.hp
	s.play(0, s.hero.x, s.hero.y)
	check(s.gold < 10.0 and h0 - s.hero.hp >= 120.0 and s.hero.slow_t > 2.0, "Ouro Derretido: 20 de ouro viram 120+ de fogo e lentidão (%.0f)" % (h0 - s.hero.hp))
	s.gold = 80.0
	s.hand[0] = _inst("molten_gold")
	s.play(0, s.hero.x, s.hero.y)
	check(s.gold >= 50.0 and s.gold < 70.0, "Ouro Derretido gasta no máximo 30 (%.0f)" % s.gold)
	# Faísca: só incendeia o encharcado.
	s = _sim(5, "dragon")
	_tough(s)
	s._apply(_inst("spark"), s.hero.x, s.hero.y)
	check(s.burn_t <= 0.0, "Faísca em herói seco não incendeia")
	s.hero.soaked_t = 5.0
	s._apply(_inst("spark"), s.hero.x, s.hero.y)
	check(s.burn_t > 0.0 and s.burn_src == "spark", "Faísca em herói encharcado incendeia")
	# Kobolds: cada golpe rende ouro.
	s = _sim(5, "dragon")
	var kb := _spawn(s, "kobold_scavengers", 2.0)
	check(kb.size() == 4, "Kobolds Catadores: 4 kobolds (%d)" % kb.size())
	g0 = s.gold
	_hit(s, kb[0])
	_hit(s, kb[1])
	check(is_equal_approx(s.gold - g0, 2.0 + (s.gold - g0 - 2.0)) and s.gold > g0 + 1.9, "cada golpe dos Kobolds rende ouro (%.1f)" % (s.gold - g0))
	# Baú Armadilha: ao ser destruído pelo herói explode e rende ouro; sozinho (expirar) não.
	s = _sim(5, "dragon")
	_tough(s)
	var tc := _spawn(s, "trap_chest", 0.5)
	g0 = s.gold
	h0 = s.hero.hp
	s.kill_unit(tc[0], K.Death.HERO)
	check(h0 - s.hero.hp >= 150.0 and s.gold - g0 >= 15.0, "Baú Armadilha explode e rende ouro (%.0f, +%.0f)" % [h0 - s.hero.hp, s.gold - g0])
	# Guarda do Tesouro: +5 de vida por ouro.
	s = _sim(5, "dragon")
	s.elixir = 20.0
	s.hand[0] = _inst("treasure_guard")
	s.gold = 0.0
	s.play(0, s.hero.x + 8.0, s.hero.y)
	var tg0 := 0.0
	for j in s.units.hi:
		if s.units.alive[j] == 1 and s.units.def[j] == data.card("treasure_guard").idx:
			tg0 = s.units.max_hp[j]
	s.hand[0] = _inst("treasure_guard")
	s.gold = 100.0
	s.play(0, s.hero.x + 8.0, s.hero.y)
	var tg1 := 0.0
	for j in s.units.hi:
		if s.units.alive[j] == 1 and s.units.def[j] == data.card("treasure_guard").idx:
			tg1 = maxf(tg1, s.units.max_hp[j])
	check(absf(tg0 - 900.0) < 1.0 and absf(tg1 - 1400.0) < 1.0, "Guarda do Tesouro: 900 de vida, +500 com 100 de ouro (%.0f → %.0f)" % [tg0, tg1])
	# Fornalha: o herói não seca, o fogo causa +30%, e ela some em 15 s.
	s = _sim(5, "dragon")
	var fu := _spawn(s, "furnace", 1.0)
	s.hero.soaked_t = 10.0
	_steps(s, 5.0)
	check(s.hero.soaked_t > 9.5, "Fornalha: o herói não seca perto dela (%.1f)" % s.hero.soaked_t)
	check(absf(CardsDragon.hero_damage_bonus(s, s.hero, K.TAG_FIRE, 0) - 0.3) < 0.001 and CardsDragon.hero_damage_bonus(s, s.hero, 0, 0) == 0.0, "Fornalha: +30% só no fogo")
	_steps(s, 11.0)
	check(s.units.alive[fu[0]] == 0, "Fornalha expira em 15 s")
	check(CardsDragon.hero_damage_bonus(s, s.hero, K.TAG_FIRE, 0) == 0.0, "sem Fornalha, sem bônus")
	# Chuva de Brasas: zona de fogo e o óleo no chão pega fogo.
	s = _sim(5, "dragon")
	_tough(s)
	s.zones.append({"kind": "oil", "x": s.hero.x + 1.0, "y": s.hero.y, "r": 2.0, "t": 20.0, "dps": 0.0, "soaked": 5.0})
	var z0 := s.zones.size()
	s._apply(_inst("ember_rain"), s.hero.x, s.hero.y)
	var fires := 0
	for z in s.zones:
		if z["kind"] == "fire":
			fires += 1
	check(s.zones.size() == z0 + 2 and fires == 2, "Chuva de Brasas: zona de fogo e o óleo pega fogo (%d zonas de fogo)" % fires)
	# Erupção: encharcado explode; seco não sofre; o óleo vira fogo.
	s = _sim(5, "dragon")
	_tough(s)
	h0 = s.hero.hp
	s._apply(_inst("eruption"), s.hero.x, s.hero.y)
	check(is_equal_approx(h0, s.hero.hp), "Erupção não machuca herói seco")
	s.hero.soaked_t = 5.0
	s._apply(_inst("eruption"), s.hero.x, s.hero.y)
	check(h0 - s.hero.hp >= 400.0 and s.hero.soaked_t <= 0.0, "Erupção: encharcado leva 400+ de fogo (%.0f)" % (h0 - s.hero.hp))
	var burning := false
	for z in s.zones:
		burning = burning or (z["kind"] == "fire" and float(z["t"]) > 9.0)
	check(burning, "Erupção deixa o chão queimando por 10 s")
	# Dragão Ancião: voa, 3000 de vida e solta a Chuva de Brasas ao entrar.
	s = _sim(5, "dragon")
	s.elixir = 20.0
	s.hand[0] = _inst("elder_dragon")
	var zz := s.zones.size()
	s.play(0, s.hero.x + 8.0, s.hero.y)
	var ed := -1
	for j in s.units.hi:
		if s.units.alive[j] == 1 and s.units.def[j] == data.card("elder_dragon").idx:
			ed = j
	check(ed >= 0 and absf(s.units.max_hp[ed]) >= 3000.0 and (s.units.flags[ed] & K.F_FLY) != 0, "Dragão Ancião: voador de 3000 de vida")
	check(s.zones.size() == zz + 1 and s.zones[-1]["kind"] == "fire", "Dragão Ancião solta a Chuva de Brasas ao entrar")
## Cartas novas do Lich e comuns (C6): uma verificação por mecânica.
func t_cards_lich_common() -> void:
	# Servo Reanimado: a morte conta como 2 (log de mortes, Colheita, contagem por carta).
	var s := _sim(5, "lich")
	_tough(s)
	var sv := _spawn(s, "raised_servant")
	var skl := _spawn(s, "skeleton_archers")
	var di: int = data.card("raised_servant").idx
	s.kill_unit(sv[0], K.Death.HERO)
	check(CardsLich.recent_deaths(s, 10.0) == 2 and s.dead_by_def[di] == 2, "Servo Reanimado: a morte conta como 2 (%d)" % CardsLich.recent_deaths(s, 10.0))
	s.kill_unit(skl[0], K.Death.HERO)
	check(CardsLich.recent_deaths(s, 10.0) == 3, "monstro comum conta 1 morte")
	# Túmulo Aberto: sem mortes recentes nada acontece; com 2, levanta esqueletos; Retorna.
	var s2 := _sim(6, "lich")
	_tough(s2)
	var n0 := s2.units.count
	s2._apply(_inst("open_grave"), s2.hero.x + 4.0, s2.hero.y)
	check(s2.units.count == n0, "Túmulo Aberto sem mortes recentes não levanta ninguém")
	var two := _spawn(s2, "bone_legion")
	s2.kill_unit(two[0], K.Death.HERO)
	s2.kill_unit(two[1], K.Death.HERO)
	var alive_before := 0
	for j in s2.units.hi:
		alive_before += s2.units.alive[j]
	s2._apply(_inst("open_grave"), s2.hero.x + 4.0, s2.hero.y)
	var alive_after := 0
	for j in s2.units.hi:
		alive_after += s2.units.alive[j]
	check(alive_after == alive_before + 2, "Túmulo Aberto com 2 mortes levanta 2 esqueletos (%d → %d)" % [alive_before, alive_after])
	var og := _inst("open_grave")
	s2._to_discard(og)
	check(s2.queue.has(og), "Túmulo Aberto Retorna ao baralho")
	# Apocalipse Arcano: repete os feitiços recentes sem laço (não se registra nem repete o Eco).
	var s3 := _sim(7, "lich")
	_tough(s3)
	s3.t = 100.0
	for id in ["shadow_bolt", "arcane_spark", "life_drain"]:
		CardsLich.on_card_played(s3, _inst(id), s3.hero.x, s3.hero.y)
	var log_n: int = s3.cstate["lich"]["sp"].size()
	var hp0 := s3.hero.hp
	s3._apply(_inst("arcane_apocalypse"), s3.hero.x, s3.hero.y)
	var loss := hp0 - s3.hero.hp
	check(log_n == 3 and loss > 200.0, "Apocalipse Arcano repete 3 feitiços (%.0f de dano)" % loss)
	CardsLich.on_card_played(s3, _inst("arcane_apocalypse"), s3.hero.x, s3.hero.y)
	CardsLich.on_card_played(s3, _inst("shadow_echo"), s3.hero.x, s3.hero.y)
	check(s3.cstate["lich"]["sp"].size() == log_n, "Apocalipse e Eco não entram no registro (sem laço)")
	s3.t += 16.0
	hp0 = s3.hero.hp
	s3._apply(_inst("arcane_apocalypse"), s3.hero.x, s3.hero.y)
	check(is_equal_approx(hp0, s3.hero.hp), "Apocalipse ignora feitiços de mais de 15 s")
	# Maldição da Fraqueza: o golpe do herói nas unidades cai 30% e volta ao normal.
	var s4 := _sim(8)
	_tough(s4)
	var og4 := _spawn(s4, "ogre")
	var h0: float = s4.units.hp[og4[0]]
	s4.hero_hits_unit(og4[0], 100.0)
	var normal := h0 - s4.units.hp[og4[0]]
	s4._apply(_inst("weakness_curse"), s4.hero.x, s4.hero.y)
	h0 = s4.units.hp[og4[0]]
	s4.hero_hits_unit(og4[0], 100.0)
	var weak := h0 - s4.units.hp[og4[0]]
	check(absf(weak - normal * 0.7) < 0.5, "Maldição da Fraqueza: golpe do herói %.0f → %.0f" % [normal, weak])
	s4.t += 7.0
	h0 = s4.units.hp[og4[0]]
	s4.hero_hits_unit(og4[0], 100.0)
	check(absf((h0 - s4.units.hp[og4[0]]) - normal) < 0.5, "Maldição da Fraqueza acaba em 6 s")
	# Cálice Profundo: +4 de elixir máximo e 2 de elixir na hora; expira em 40 s.
	var s5 := _sim(9)
	var m0 := s5.elixir_max
	s5.elixir = 3.0
	s5._apply(_inst("deep_chalice"), s5.hero.x, s5.hero.y)
	check(is_equal_approx(s5.elixir_max, m0 + 4.0) and is_equal_approx(s5.elixir, 5.0), "Cálice Profundo: máximo %.0f → %.0f, elixir %.1f" % [m0, s5.elixir_max, s5.elixir])
	s5.t += 41.0
	s5._temps()
	check(is_equal_approx(s5.elixir_max, m0), "Cálice Profundo expira (máximo %.0f)" % s5.elixir_max)
	# Ritual Profano: sacrifica 1 monstro; os próximos feitiços custam 1 a menos e depois voltam ao normal.
	var s6 := _sim(10, "lich")
	_tough(s6)
	var rv_ := _spawn(s6, "ghoul")
	var bolt := _inst("shadow_bolt")
	var c0 := s6.card_cost(bolt)
	s6._apply(_inst("profane_ritual"), s6.hero.x + 0.5, s6.hero.y)
	check(s6.units.alive[rv_[0]] == 0 and s6.card_cost(bolt) == c0 - 1, "Ritual Profano sacrifica e baixa o custo (%d → %d)" % [c0, s6.card_cost(bolt)])
	for i in 3:
		CardsLich.on_card_played(s6, bolt, s6.hero.x, s6.hero.y)
	check(s6.card_cost(bolt) == c0, "Ritual Profano acaba depois de 3 feitiços")
	# Estandarte de Guerra e Troll: a vida do aliado perto do estandarte sobe; o Troll regenera.
	var s7 := _sim(11)
	_tough(s7)
	var gl := _spawn(s7, "ghoul")
	var hp_g: float = s7.units.max_hp[gl[0]]
	_spawn(s7, "war_banner", 1.0)
	s7.step()
	check(s7.units.max_hp[gl[0]] > hp_g * 1.2, "Estandarte de Guerra: +vida (%.0f → %.0f)" % [hp_g, s7.units.max_hp[gl[0]]])
	var tr := _spawn(s7, "cave_troll", 8.0)
	s7.units.hp[tr[0]] = s7.units.max_hp[tr[0]] * 0.5
	var th0: float = s7.units.hp[tr[0]]
	for i in 20:
		s7.step()
	check(s7.units.alive[tr[0]] == 0 or s7.units.hp[tr[0]] > th0, "Troll das Cavernas regenera")
## Passo C6 (Praga): as 16 cartas novas, o estado Peste e os ganchos da Praga.
func _pl(s: Sim, id: String, dx := 0.5) -> Array:
	var out := _spawn(s, id, dx)
	CardsPlague.on_card_played(s, _inst(id), s.hero.x, s.hero.y)
	return out


func _pl_still(s: Sim) -> void:
	_tough(s)
	s.hero.petrify_t = 1.0e6   # herói parado: não anda nem ataca


func _count_def(s: Sim, id: String) -> int:
	var n := 0
	var di := data.card(id).idx
	for j in s.units.hi:
		if s.units.alive[j] == 1 and s.units.def[j] == di:
			n += 1
	return n


func t_plague_cards() -> void:
	var ids := ["rat_brute", "infected_bite", "bat_cloud", "rat_trap", "wolf_pack", "brood_mother", "corrupt_piper", "sewer_flood",
		"war_boar", "hunt_instinct", "devour", "bubonic_plague", "rat_tide", "mother_nest", "alpha_beast", "endless_swarm"]
	var missing: Array = []
	for id in ids:
		var c := data.card(id)
		if c == null or c.owner != "plague":
			missing.append(id)
	check(missing.is_empty(), "as 16 cartas novas da Praga existem com owner plague %s" % [missing])
	# Peste: acumula por mordida, dá dano a mais, tem teto e expira.
	var s := _sim(5, "plague")
	_pl_still(s)
	var br := _pl(s, "rat_brute")
	var d0 := _hit(s, br[0])
	check(CardsPlague.peste_of(s, s.hero) == 1, "Ratazana: 1 mordida = 1 acúmulo de Peste")
	for k in 4:
		_hit(s, br[0])
	var d5 := _hit(s, br[0])
	check(CardsPlague.peste_of(s, s.hero) == 6 and d5 > d0 * 1.15, "Peste: cada acúmulo aumenta o dano recebido (%.1f → %.1f)" % [d0, d5])
	CardsPlague.add_peste(s, s.hero, 40)
	check(CardsPlague.peste_of(s, s.hero) == 15, "Peste: teto de 15 acúmulos")
	s.kill_unit(br[0], K.Death.EXPIRE)
	for i in int(round(7.0 / s.dt)):
		s.step()
	check(CardsPlague.peste_of(s, s.hero) == 15, "Peste: ainda vale antes de 8 s sem mordida")
	for i in int(round(2.0 / s.dt)):
		s.step()
	check(CardsPlague.peste_of(s, s.hero) == 0, "Peste: some 8 s depois da última mordida")
	# Matilha de Lobos: +10% de dano por acúmulo de Peste.
	s = _sim(5, "plague")
	_pl_still(s)
	var wo := _pl(s, "wolf_pack")
	var w0 := _hit(s, wo[0])
	CardsPlague.add_peste(s, s.hero, 10)
	var w10 := _hit(s, wo[0])
	check(wo.size() == 3 and w10 > w0 * 2.0, "Matilha: dano sobe com a Peste no herói (%.1f → %.1f)" % [w0, w10])
	# Mordida Infectada: a mordida do Bando perto do ponto aplica Peste a mais; longe, não.
	s = _sim(5, "plague")
	_pl_still(s)
	var rr := _pl(s, "rat_horde")
	_hit(s, rr[0])
	check(CardsPlague.peste_of(s, s.hero) == 0, "rato comum não aplica Peste sozinho")
	s._apply(_inst("infected_bite"), s.hero.x, s.hero.y)
	_hit(s, rr[0])
	check(CardsPlague.peste_of(s, s.hero) == 1, "Mordida Infectada: mordida de Bando aplica +1 Peste")
	# Praga Bubônica: toda mordida aplica Peste; no fim, dano por acúmulo.
	s = _sim(5, "plague")
	_pl_still(s)
	rr = _pl(s, "rat_horde")
	s._apply(_inst("bubonic_plague"), s.hero.x, s.hero.y)
	_hit(s, rr[0])
	_hit(s, rr[0])
	check(CardsPlague.peste_of(s, s.hero) == 2, "Praga Bubônica: toda mordida aplica Peste")
	s.cstate["plague"]["bubo_t"] = s.t - 0.1
	var hb := s.hero.hp
	s.step()
	check(hb - s.hero.hp >= 2.0 * float(data.card("bubonic_plague").fx["per_stack"]), "Praga Bubônica: no fim, 15 de dano por acúmulo (%.0f)" % (hb - s.hero.hp))
	# Devorar: Retorna; sacrifica 3 ratos e fortalece a fera mais perto.
	check(data.card("devour").fx.get("returns", false) == true and data.card("devour").cost == 0, "Devorar: custo 0 e Retorna")
	s = _sim(5, "plague")
	_pl_still(s)
	var wb := _pl(s, "war_boar", 5.0)
	var rats5 := _pl(s, "rat_horde", 4.0)
	s.units.hp[wb[0]] = 100.0
	var dm0: float = s.units.dmg[wb[0]]
	var n0 := _count_def(s, "rat_horde")
	s._apply(_inst("devour"), s.hero.x, s.hero.y)
	check(n0 - _count_def(s, "rat_horde") == 3 and s.units.hp[wb[0]] >= 299.0 and s.units.dmg[wb[0]] > dm0 * 1.2,
		"Devorar: sacrifica 3 ratos, cura a fera e ela bate mais (%d ratos, vida %.0f)" % [_count_def(s, "rat_horde"), s.units.hp[wb[0]]])
	check(rats5.size() == 8, "Horda tem 8 ratos")
	# Javali: empurra e atordoa uma vez por recarga.
	s = _sim(5, "plague")
	_tough(s)
	wb = _pl(s, "war_boar")
	s.units.timer2[wb[0]] = 0.0
	s.hero.petrify_t = 0.0
	s.unit_hits_hero(wb[0])
	check(s.hero.petrify_t > 0.5 and s.hero.kb_t > 0.0, "Javali de Guerra: empurra e atordoa o herói")
	s.hero.petrify_t = 0.0
	s.unit_hits_hero(wb[0])
	check(s.hero.petrify_t <= 0.0, "Javali de Guerra: segunda investida só depois da recarga")
	# Instinto de Caça: Feras correm mais e roubam vida.
	s = _sim(5, "plague")
	_pl_still(s)
	var wf := _pl(s, "wolf_pack", 6.0)
	var sp0: float = s.units.spd[wf[0]]
	s._apply(_inst("hunt_instinct"), s.hero.x, s.hero.y)
	s.step()
	s.step()
	check(s.units.spd[wf[0]] > sp0 * 1.5, "Instinto de Caça: Feras +60%% de velocidade (%.1f → %.1f)" % [sp0, s.units.spd[wf[0]]])
	s.units.hp[wf[0]] = 10.0
	_hit(s, wf[0])
	check(s.units.hp[wf[0]] > 10.0, "Instinto de Caça: roubo de vida")
	# Esgoto Transbordante: 1 rato por segundo; Ninho-Mãe dobra.
	s = _sim(5, "plague")
	_pl_still(s)
	_pl(s, "sewer_flood", 8.0)
	for i in int(round(6.0 / s.dt)):
		s.step()
	var base_rats := _count_def(s, "rat")
	check(base_rats >= 5, "Esgoto Transbordante: ~1 rato por segundo (%d em 6 s)" % base_rats)
	var s2 := _sim(5, "plague")
	_pl_still(s2)
	_pl(s2, "sewer_flood", 8.0)
	s2._apply(_inst("mother_nest"), s2.hero.x, s2.hero.y)
	for i in int(round(6.0 / s2.dt)):
		s2.step()
	var dbl := _count_def(s2, "rat")
	check(dbl >= base_rats * 1.7, "Ninho-Mãe: o ninho produz em dobro (%d contra %d)" % [dbl, base_rats])
	# Mãe da Ninhada pare ratos; Ratoeira prende e solta ratos.
	s = _sim(5, "plague")
	_pl_still(s)
	_pl(s, "brood_mother", 8.0)
	for i in int(round(9.0 / s.dt)):
		s.step()
	check(_count_def(s, "rat") >= 4, "Mãe da Ninhada: pare 2 ratos a cada 4 s (%d)" % _count_def(s, "rat"))
	s = _sim(5, "plague")
	_tough(s)
	var tr := _pl(s, "rat_trap", 0.3)
	s.step()
	s.step()
	check(s.hero.root_t > 0.5 and _count_def(s, "rat") == 4 and s.units.alive[tr[0]] == 0, "Ratoeira Viva: prende o herói, solta 4 ratos e some")
	# Flautista: o Bando perto bate mais rápido.
	var gain := 0.0
	var dmg_a := 0.0
	var dmg_b := 0.0
	for pass_ in 2:
		s = _sim(5, "plague")
		_pl_still(s)
		var fxp: Dictionary = data.card("corrupt_piper").fx
		var keep: float = fxp["atk_speed"]
		fxp["atk_speed"] = keep if pass_ == 0 else 0.0
		_pl(s, "rat_horde", 1.0)
		_pl(s, "corrupt_piper", 2.0)
		var h0 := s.hero.hp
		for i in int(round(8.0 / s.dt)):
			s.step()
		fxp["atk_speed"] = keep
		if pass_ == 0:
			dmg_a = h0 - s.hero.hp
		else:
			dmg_b = h0 - s.hero.hp
	gain = dmg_a / maxf(dmg_b, 0.001)
	check(gain > 1.15, "Flautista Corrompido: Bando por perto causa mais dano (%.0f contra %.0f)" % [dmg_a, dmg_b])
	# Enxame Sem Fim: 12 ratos e o Bando que morre renasce uma vez.
	s = _sim(5, "plague")
	_pl_still(s)
	var r0 := _count_def(s, "rat")
	s._apply(_inst("endless_swarm"), s.hero.x, s.hero.y)
	check(_count_def(s, "rat") - r0 == 12, "Enxame Sem Fim: invoca 12 ratos")
	var one := -1
	for j in s.units.hi:
		if s.units.alive[j] == 1 and s.units.def[j] == data.card("rat").idx:
			one = j
			break
	var before := _count_def(s, "rat")
	s.kill_unit(one, K.Death.HERO)
	check(_count_def(s, "rat") == before, "Enxame Sem Fim: o rato que morre renasce")
	var again := -1
	for j in s.units.hi:
		if s.units.alive[j] == 1 and s.units.def[j] == data.card("rat").idx and (s.units.flags[j] & K.F_REVIVED):
			again = j
			break
	s.kill_unit(again, K.Death.HERO)
	check(_count_def(s, "rat") == before - 1, "Enxame Sem Fim: só renasce uma vez")
	# Besta Alfa solta um Chamado do Bando ao entrar; Maré de Ratos são 30 ratos.
	s = _sim(5, "plague")
	_tough(s)
	_pl(s, "alpha_beast", 6.0)
	check(s.rally_until > s.t, "Besta Alfa: solta um Chamado do Bando ao entrar")
	s = _sim(5, "plague")
	_tough(s)
	check(_spawn(s, "rat_tide", 5.0).size() == 30, "Maré de Ratos: 30 ratos")
	# Nuvem de Morcegos voa; Sewer/ninho e as 16 têm texto nos dois idiomas.
	s = _sim(5, "plague")
	var bc := _spawn(s, "bat_cloud", 5.0)
	check(bc.size() == 5 and (s.units.flags[bc[0]] & K.F_FLY) != 0, "Nuvem de Morcegos: 5 morcegos voadores")
	var no_text: Array = []
	for id in ids:
		for pre in ["CARD_", "DESC_"]:
			if TranslationServer.translate(pre + id) == pre + id:
				no_text.append(pre + id)
	check(no_text.is_empty(), "as 16 cartas têm nome e descrição %s" % [no_text])


## Etapa D: arte única. Cada carta tem o próprio png; nenhum campo "art" aponta para a imagem de outra;
## os modelos próprios e as variantes não usam "model" emprestado.
func t_unique_art() -> void:
	var no_png: Array = []
	var borrowed: Array = []
	var seen := {}
	for c in data.cards:
		if c.category == "aux":
			continue  # unidades auxiliares (rato, morcego...) não são cartas
		var p := "res://assets/cards/%s.png" % c.id
		if not FileAccess.file_exists(p) and not ResourceLoader.exists(p):
			no_png.append(c.id)
		seen[CardModel.art_of(c.id)] = seen.get(CardModel.art_of(c.id), 0) + 1
		if CardModel.art_of(c.id) != c.id:
			borrowed.append(c.id)
	check(no_png.is_empty(), "toda carta tem o próprio png %s" % [no_png])
	check(borrowed.is_empty(), "nenhuma carta aponta para a imagem de outra %s" % [borrowed])
	var dup: Array = []
	for k in seen:
		if seen[k] > 1:
			dup.append(k)
	check(dup.is_empty(), "nenhuma imagem é compartilhada %s" % [dup])
	var own := ["wolf_pack", "war_boar", "alpha_beast", "treasure_guard", "elder_dragon", "cave_troll", "death_knight", "bone_colossus", "ruin_titan"]
	var miss: Array = []
	for id in own:
		if CardModel.of(id) != id or Looks.mesh(7, id) == null:
			miss.append(id)
	for id in Looks.VARIANTS:
		if CardModel.of(id) != id or Looks.mesh(7, Looks.VARIANTS[id]["base"]) == null:
			miss.append(id)
	check(miss.is_empty(), "9 modelos próprios e %d variantes registrados, sem model emprestado %s" % [Looks.VARIANTS.size(), miss])

## Etapa E: em cada vilão e ato, toda oferta de raridade única fecha com 3 opções de uma raridade só (ou cai inteira
## para a vizinha), e nunca traz carta acima do custo liberado no ato.
func t_rarity_pool() -> void:
	var ok := true
	var info := ""
	for vid in data.villain_ids:
		for a in 3:
			var s := _sim(9 + a, vid)
			s.act = a
			for k in 40:
				var opts := s._card_options(3, func(cd: CardDef): return true)
				var rs := {}
				for o in opts:
					var c: CardDef = data.card(o["id"])
					rs[c.rarity] = true
					if c.cost > s.max_offer_cost() or not data.in_pool(c, vid):
						ok = false
						info = "%s ato %d: %s" % [vid, a + 1, c.id]
				if opts.size() != 3 or rs.size() != 1:
					ok = false
					info = "%s ato %d: %d opções, %d raridades" % [vid, a + 1, opts.size(), rs.size()]
	check(ok, "ofertas de raridade única fecham com 3 opções em todo vilão e ato, dentro do custo liberado %s" % info)

