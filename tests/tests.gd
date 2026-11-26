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
	# `-- --only=t_x,t_y` roda so essas funcoes (frentes de trabalho: teste rapido, sem a suite inteira).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for fn in a.substr(7).split(","):
				call(fn)
			print("falhas: ", fails)
			get_tree().quit(fails)
			return
	t_data()
	t_elixir_and_ring()
	t_costs()
	t_no_hand_sacrifice()
	t_deck_cycle()
	t_hand_cap()
	t_determinism()
	t_save()
	t_hero_ai()
	t_party()
	t_card_levels()
	t_levels6()
	t_location_rewards()
	t_route()
	t_rivers()
	t_water()
	t_shop()
	t_fountain_and_fire()
	t_contests()
	t_fork_after_location()
	t_offer_single_type()
	t_offer_single_rarity()
	t_offer_upgrades()
	t_shrine_blessed()
	t_hero_knockback_mult()
	t_explosive_hp_frac()
	t_mod_effects()
	t_roads_curved()
	t_give_notice()
	t_relics()
	t_relics_1111()
	t_events()
	t_ability_tell()
	t_soul_absorb_cooldown()
	t_arena_hunt()
	t_acts()
	t_act_continuous()
	t_world_append()
	t_meta()
	t_unlock_challenges()
	t_full_runs()
	t_combos()
	t_classes()
	t_group()
	t_parties()
	t_run15()
	t_group_spells()
	t_stall_and_overtime()
	t_human_bot()
	t_translations()
	t_keywords()
	t_shadowy_leech()
	t_card_fx()
	t_rarity_pool()
	t_dragon_c6()
	t_cards_lich_common()
	t_plague_cards()
	t_unique_art()
	t_helper()
	t_round_2026_11_13()
	t_ui_spacing()
	t_contracts()
	t_meta5()

	t_powers()
	t_power_hud()
	t_library_ui()
	t_covil_ui()
	t_bots15()
	t_menus()
	t_frente_i()
	print("falhas: ", fails)
	get_tree().quit(fails)


func t_data() -> void:
	check(data.pool.size() == 118, "118 cartas na pool (%d)" % data.pool.size())
	check(data.upgrades.size() == 15, "15 upgrades")
	# Vilões (C3): dono válido em tudo; baralho inicial só com cartas do vilão ou comuns, liberadas com ele.
	var owners := ["common"] + data.villain_ids
	var bad: Array = []
	for c in data.pool:
		if not owners.has(c.owner):
			bad.append(c.id)
	for x in data.relics.values() + data.events_def.values():
		if not owners.has(str(x.get("owner", ""))):
			bad.append(str(x["id"]))
	check(bad.is_empty() and data.villain_ids == ["plague", "dragon", "lich"], "3 vilões; owner válido em cartas, relíquias e eventos %s" % str(bad))
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
	# Um círculo por herói; nos heróis à distância o raio é o alcance de ataque (15/11/2026).
	if data.phase(94).is_empty():
		data.phases.append({"id": 94, "key": "TEST_94", "parties": [["arqueira", "escudeiro"]], "hp_mult": 1.0})
	var rs := Sim.new()
	rs.setup(data, 5, "horde", [], [], 94)
	var rrats: Sim.CardInst = rs.hand[0]
	for ci in rs.hand:
		if ci != null and ci.def.category == "field" and not ci.def.is_spell:
			rrats = ci
			break
	var lead := rs.hero
	var fol: SimHero = rs.followers[0]
	fol.x = lead.x + 40.0
	fol.y = lead.y
	check(is_equal_approx(rs.ring_of(lead), float(lead.H["attack_range"])) and rs.ring_of(lead) > 6.0, "Arqueira: o círculo é o alcance de ataque (%.1f m)" % rs.ring_of(lead))
	check(is_equal_approx(rs.ring_of(fol), 3.0), "Escudeiro: o círculo é de 3 m")
	check(not rs.valid_target(rrats, lead.x + 5.0, lead.y), "monstro a 5 m do Arqueira é recusado")
	check(rs.valid_target(rrats, lead.x + 8.0, lead.y), "monstro a 8 m do Arqueira é aceito")
	check(not rs.valid_target(rrats, fol.x + 1.5, fol.y), "o outro membro da party também tem círculo")
	check(rs.valid_target(rrats, fol.x + 4.0, fol.y), "fora do círculo do outro membro vale")
	var pushed := rs.clear_of_rings(Vector2(lead.x + 1.0, lead.y))
	check(rs.valid_target(rrats, pushed.x, pushed.y), "a mira dos bots sai dos círculos")
	check(s.hand.size() == 5, "Praga tem mão de 5 como todo vilão")


func t_costs() -> void:
	var s := _sim(1, "dragon")
	var g := Sim.CardInst.new()
	g.def = data.card("goblin_dynamiter")
	check(s.card_cost(g) == 3, "Dragão: Goblin custa 3")
	var tw := Sim.CardInst.new()
	tw.def = data.card("gargoyle_tower")
	check(s.card_cost(tw) == 4, "Dragão: Torre (estrutura) continua 4")
	check(is_equal_approx(s.gold, 45.0), "Dragão começa com 45 de ouro (calibragem de 13/11/2026)")
	# Passivas dos vilões.
	s.gold = 1000.0
	check(is_equal_approx(s.hoard_fire(), 0.0), "Dragão: sem bônus de fogo por ouro (passiva trocada em 15/11/2026)")
	var g0 := s.gold
	s._dragon_shop()
	check(is_equal_approx(s.gold, g0 + 200.0), "Dragão: loja dá 200 de ouro")
	check(s.offers.size() > 0 and s.offers[0]["source"] == "location", "Dragão: loja abre escolha de carta")
	var all_hi := s.offers.size() > 0
	for op in s.offers[0]["options"]:
		all_hi = all_hi and s.data.card(str(op["id"])).rarity >= 2
	check(all_hi, "Dragão: as cartas da loja são rara ou lendária")
	var l := _sim(1, "lich")
	var bolt := _inst("shadow_bolt")
	# Ciclo de feitiço (15/11/2026): morte barateia o próximo feitiço; feitiço barateia a próxima criatura.
	var servant := _inst("raised_servant")
	var bc := data.card("shadow_bolt").cost
	var sc := data.card("raised_servant").cost
	check(not l.cycle_applies(bolt) and not l.cycle_applies(servant), "Ciclo: nada armado no começo")
	var j := l.units.spawn(data.card("bone_legion"), l.hero.x + 6.0, l.hero.y, 0.0, 0.0, 0, 999)
	l.kill_unit(j, K.Death.HERO)
	check(l.cycle_applies(bolt) and not l.cycle_applies(servant) and l.card_cost(bolt) == maxi(0, bc - 1), "Ciclo: criatura morta = próximo feitiço custa 1 a menos")
	l.cycle_spell = false
	l.cycle_mon = true
	check(l.cycle_applies(servant) and not l.cycle_applies(bolt) and l.card_cost(servant) == maxi(0, sc - 1), "Ciclo: feitiço lançado = próxima criatura custa 1 a menos")
	var p := _sim(1, "plague")
	var before := p.units.count
	for k in 200:
		var jr := p.units.spawn(data.card("rat_horde"), p.hero.x + 30.0, p.hero.y, 0.0, 0.0, 0, 999)
		p.kill_unit(jr, K.Death.EXPIRE if k < 0 else K.Death.HERO)
	var born := p.units.count - before
	# Cartas em vigor (16/11/2026): efeito temporário segura a carta fora do descarte até acabar.
	var hs := _sim(1, "dragon")
	hs.elixir = 10.0
	hs.hand[0] = _inst("dark_forge")
	var forge: Sim.CardInst = hs.hand[0]
	hs.cards.append(forge)   # no jogo a carta da mão sempre está no baralho (`cards`)
	var nd := hs.discard.size()
	hs.play(0, hs.hero.x, hs.hero.y)
	check(hs.held.size() == 1 and hs.discard.size() == nd and not hs.discard.has(forge), "Em vigor: Forja fica retida, fora do descarte")
	hs.t += 31.0
	hs._release_held()
	check(hs.held.is_empty() and hs.discard.has(forge), "Em vigor: acabou o efeito, a carta vai ao descarte")
	check(born >= 15 and born <= 65, "Infestação da Praga: ~20%% das mortes de Bando deixam um rato (%d de 200)" % born)
	var ofs := true
	for k in 20:
		for o in s._card_options(3, func(cd: CardDef): return true):
			ofs = ofs and data.in_pool(data.card(o["id"]), "dragon")
	check(ofs, "ofertas do Dragão só têm cartas dele e comuns")


## Rodada 11/11/2026: o sacrifício da carta da mão saiu (botão, X+número, clique direito, regras e relíquia).
func t_no_hand_sacrifice() -> void:
	var s := _sim()
	check(not s.has_method("sacrifice") and not s.has_method("sacrifice_ready"), "Sim não tem mais sacrifício da mão")
	check(not data.rules.has("sacrifice_cooldown") and not data.rules.has("sacrifice_elixir_frac"), "regras do sacrifício saíram de rules.json")
	check(not data.relics.has("portable_altar"), "Altar Portátil (recarga do sacrifício) saiu")
	check(not s.stats.has("sacrifices"), "stats sem contagem de sacrifícios")
	# O sacrifício de unidades em campo continua (Devorar, Sacrifício Sombrio, Ritual Profano).
	check(K.Death.SACRIFICE == 2 and data.card("dark_sacrifice") != null, "sacrifício de monstro em campo continua")


## Rodada 09/11/2026: compras extras não têm teto e a mão passava de 9 (só há teclas de 1 a 9).
func t_hand_cap() -> void:
	var s := _sim()
	var lib := Sim.CardInst.new()
	lib.def = data.card("forbidden_library")
	for k in 6:
		s._apply(lib, s.hero.x, s.hero.y)
	check(s.hand.size() <= Sim.HAND_MAX and Sim.HAND_MAX == 7, "Biblioteca repetida não passa do teto da mão de 7 (%d, tamanho %d)" % [s.hand.size(), s.hand_size])
	var full := s.hand.size()
	_steps_free(s, 45.0)
	check(s.hand_size == 5 and s.hand.size() <= full, "Biblioteca acaba: a mão volta a 5 sem expulsar carta (%d, tamanho %d)" % [s.hand.size(), s.hand_size])
	# Piso de elixir por ato (13/11/2026): máximo 10/12/14 e regen x1/x1,25/x1,5 (rules.acts[].elixir), as relíquias
	# somam por cima sem teto; o custo máximo das ofertas (7/9/16) nunca passa do elixir máximo permanente.
	var e := _sim(2, "dragon")
	var spp := float(data.rules["elixir"]["seconds_per_point"])
	check(is_equal_approx(e.elixir_max, 10.0) and e.max_offer_cost() == 7 and is_equal_approx(e.seconds_per_elixir(), spp), "ato 1: elixir máximo 10, 2,8 s por ponto, ofertas até custo 7")
	var floors: Array = []
	for a in data.rules["acts"]:
		floors.append([float(a["elixir"].get("max", 0.0)), float(a["elixir"].get("regen_mult", 0.0))])
	check(floors.size() == 3 and floors[0][0] <= floors[1][0] and floors[1][0] <= floors[2][0] and floors[0][1] < floors[1][1] and floors[1][1] < floors[2][1], "acts[].elixir: o piso de máximo e de regen não cai e a regen sobe a cada ato %s" % [floors])
	e._next_act()
	check(e.act == 1 and is_equal_approx(e.elixir_max, floors[1][0]) and is_equal_approx(e.seconds_per_elixir(), spp / floors[1][1]), "trocar de ato sobe o piso de elixir e de regen (%.1f, %.2f s)" % [e.elixir_max, e.seconds_per_elixir()])
	e.act = 2
	e.recalc_elixir_max()
	check(is_equal_approx(e.elixir_max, floors[2][0]) and e.max_offer_cost() == mini(16, int(floors[2][0])), "ato 3 sem relíquias: máximo do piso (%.0f) e ofertas até custo %d" % [e.elixir_max, e.max_offer_cost()])
	var e2 := _sim(2, "dragon")
	e2.act = 2
	for k in 4:
		e2.gain_relic("heart_of_well")
	check(e2.elixir_max > 20.0 and e2.max_offer_cost() == 16, "relíquias de elixir empilham sem teto (%.0f) e liberam o custo 16 do ato 3" % e2.elixir_max)
	var mxe := e2.elixir_max
	e2.add_temp("elixir_max", 4.0, 40.0, "t")
	e2.elixir = mxe + 4.0
	e2.temps.clear()
	e2.recalc_elixir_max()
	check(is_equal_approx(e2.elixir, mxe), "elixir acima do máximo que encolheu é cortado")
	var cheap := _sim(3, "plague")
	var okc := true
	for k in 30:
		for o in cheap._card_options(3, func(cd: CardDef): return true):
			okc = okc and data.card(o["id"]).cost <= 7
	check(okc, "ato 1 nunca oferece carta de custo acima de 7")
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
	var s := _legacy_sim(3, 95)
	var bot := PlayerBot.load_bot("greedy", 3)
	for i in 200:
		bot.think(s)
		s.step()
	check(s.party_idx == 0 and s.hero.level == 1, "começa no herói 1, nível 1")
	s.hero.hp = 0.0
	s._check_end()
	check(s.party_idx == 1, "queda do herói 1 chama o herói 2 (party_idx %d)" % s.party_idx)
	check(s.hero.level == 2, "herói 2 é nível 2 (%d)" % s.hero.level)
	check(s.powers.size() == 1, "a party 2 chega com 1 poder novo (%d)" % s.powers.size())
	check(is_equal_approx(s.hero.hp, s.hero.max_hp()), "herói 2 chega com vida cheia")
	check(s.phase != K.Phase.OVER, "a run continua depois da primeira queda")
	check(s.offers.size() > 0, "a queda abre uma oferta")
	# Mais quedas até o último herói: a quinta é vitória.
	var size := s.party_size()
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
	check(is_equal_approx(data.card("shadow_bolt").fxv("damage", 2), 156.25), "Raio Sombrio N2: 156 de dano (125 base, calibragem de 13/11/2026)")
	check(data.card("burn_village").cost_at(1) == 4 and data.card("burn_village").cost_at(3) == 3 and data.card("burn_village").cost_at(5) == 2, "Incêndio: -1 no III e -1 no V")
	check(data.card("soul_feast").fxv("bonus_per_card", 5) == 1.0 and data.card("soul_feast").fxv("bonus_per_card", 6) == 2.0,
		"especial n3 só vale no nível VI")
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
	check(c.card_cost(_inst("burn_village", 2)) == 4 and c.card_cost(_inst("burn_village", 3)) == 3, "Incêndio N2 custa 4 e N3 custa 3")


## Níveis I a VI (frente C, 21/11/2026): só fumaça, sem varredura de balanço.
func t_levels6() -> void:
	var d := data.card("soul_feast")
	for lv in range(1, 7):
		check(is_equal_approx(d.mult(lv), 1.0 + 0.25 * (lv - 1)), "mult(%d) = %.2f" % [lv, 1.0 + 0.25 * (lv - 1)])
	check(is_equal_approx(d.mult(6), 2.25), "VI = 2,25x")
	check(int(data.rules["card_levels"]["max"]) == 6, "teto de nível é VI")
	var bv := data.card("burn_village")   # custo 4 e escala o custo
	var want := [4, 4, 3, 3, 2, 2]
	for lv in range(1, 7):
		check(bv.cost_at(lv) == want[lv - 1], "Incêndio custo no nível %d = %d (%d)" % [lv, want[lv - 1], bv.cost_at(lv)])
	for lv in range(1, 7):
		check(d.has_n3(lv, "bonus_per_card") == (lv == 6), "n3 do Banquete só no VI (nível %d)" % lv)
	var top := 0
	var bad_roll := 0
	var seen := {}
	for seed_ in range(1, 120):
		var s := _sim(seed_)
		for p in [0.5, 1.0]:
			for ea in [false, true]:
				var lv := s.roll_offer_level(ea, p)
				top = maxi(top, lv)
				seen[lv] = true
				if lv < 1 or lv > 6:
					bad_roll += 1
	check(bad_roll == 0, "roll_offer_level nunca fora de 1..6")
	check(top >= 4, "níveis altos aparecem (máx %d)" % top)
	# Loja: nível e preço respeitam o teto e a escala; a meta nunca é rebaixada.
	var s2 := Sim.new()
	s2.setup(data, 5, "horde", [], [], 1, {"card_levels": {"rat_horde": 4}})
	s2.auto_route = true
	s2.act = s2.acts() - 1
	s2.act_pending = true
	for k in 6:
		s2.offers.clear()
		s2._open_shop()
		for it in s2.offers[0]["options"]:
			if it["item"]["kind"] == "card":
				var cd: CardDef = data.card(it["item"]["id"])
				var lv := int(it["item"]["level"])
				var base := int(data.rules["shop"]["prices"][K.RARITIES[cd.rarity]]) + int(data.rules["shop"]["card_upgrade"]) * (lv - 1)
				check(lv >= 1 and lv <= 6 and int(it["price"]) == base, "loja: nível %d e preço coerentes" % lv)
	var co: Array = s2._card_options(3, func(cd: CardDef): return cd.id == "rat_horde")
	for o in co:
		check(int(o["level"]) >= 4, "oferta de carta da meta (IV) nunca abaixo de IV (%d)" % int(o["level"]))
	# Martelo da Forja e upgrade da run ignoram cartas no VI; todas no VI vira ouro.
	var s3 := _sim(7)
	for ci in s3.cards:
		ci.level = 6
	check(s3._level_up_options(-1).is_empty(), "upgrade da run ignora cartas no VI")
	var g0 := s3.gold
	s3.gain_relic("forge_hammer")
	for ci in s3.cards:
		check(ci.level == 6, "Martelo da Forja não passa do VI")
	check(s3.gold > g0, "upgrade sem carta elegível vira ouro")
	s3.cards[0].level = 5
	check(s3._level_up_options(-1).size() == 1, "só a carta abaixo do VI entra no upgrade")


func t_location_rewards() -> void:
	# Recompensas por marco (12/11/2026): a barra de cada local tem 3 marcos; cada um vale uma recompensa.
	var s := _sim()
	s.offers.clear()
	var n10 := s.cards.size()
	s._offer_marks("ritual", 1)
	check(s.offers.size() == 1 and s.offers[0]["options"].size() == maxi(1, roundi(n10 * 0.25)) and s.offers[0]["options"][0]["kind"] == "upgrade",
		"ritual, marco 1: nível de 1 carta entre 25%% do deck (%d opções)" % s.offers[0]["options"].size())
	s.offers.clear()
	s._offer_marks("ritual", 2)
	check(s.offers.size() == 1 and s.offers[0]["options"].size() == maxi(1, roundi(n10 * 0.5)), "ritual, marco 2: 1 carta entre 50%% do deck")
	s.offers.clear()
	s._offer_marks("ritual", 3)
	check(s.offers.size() == 1 and s.offers[0]["options"].size() > roundi(n10 * 0.5), "ritual, marco 3: qualquer carta do deck")
	var uid: int = s.offers[0]["options"][0]["uid"]
	s.choose(0)
	var lv := 0
	for ci in s.cards:
		if ci.uid == uid:
			lv = ci.level
	check(lv == 2, "escolher a melhoria sobe a carta para o N2")
	s._offer_marks("ritual", 3)
	check(s.choose(Sim.SKIP) and s.offers.is_empty(), "toda recompensa pode ser recusada")
	s._offer_marks("fountain", 3)
	var distinct := {}
	for ci in s.cards:
		distinct["%s/%d/%d" % [ci.def.id, ci.level, ci.mods]] = true
	check(s.offers[0]["options"].size() == distinct.size(), "fonte, marco 3: escolhe qualquer carta do deck (cópias iguais uma vez)")
	var n_before := s.cards.size()
	s.choose(0)
	check(s.cards.size() == n_before - 1, "remover tira a carta do deck")
	s.offers.clear()
	s._offer_marks("fountain", 1)
	check(s.offers.size() == 1 and s.offers[0]["options"].size() == maxi(1, roundi(s.cards.size() * 0.25)), "fonte, marco 1: 1 carta entre 25%% do deck")
	s.offers.clear()
	s._offer_marks("bridge", 3)
	var rar_ok := s.offers.size() == 3
	for k in s.offers.size():
		rar_ok = rar_ok and s.offers[k]["options"][0]["kind"] == "card" and data.card(s.offers[k]["options"][0]["id"]).rarity == k
	check(rar_ok, "ponte, 3 marcos: 3 escolhas de carta (comum, incomum, rara)")
	s.offers.clear()
	s._offer_marks("bridge", 1)
	check(s.offers.size() == 1 and data.card(s.offers[0]["options"][0]["id"]).rarity == 0, "ponte, marco 1: 1 carta comum")
	s.offers.clear()
	while s.cards.size() > int(data.rules["deck"]["min_in_run"]):
		s._remove_uid(s.cards[0].uid)
	s._offer_marks("fountain", 3)
	check(s.offers.is_empty(), "nunca remove abaixo do deck mínimo")
	# Ofertas só com cartas desbloqueadas.
	var u := Sim.new()
	u.setup(data, 2, "plague", [], ["rat_horde", "web", "ogre"])
	var ok := true
	for k in 20:
		for o in u._card_options(3, func(cd: CardDef): return true):
			ok = ok and o["id"] in ["rat_horde", "web", "ogre"]
	check(ok, "ofertas só sorteiam cartas desbloqueadas")


func t_unlock_challenges() -> void:
	var s := _sim(3, "plague")
	var T: UnlockTrack = s.track
	var stats := {"heroes_fallen": 5, "gold_end": 0.0, "gold_earned": 0.0, "gold_spent": 0, "spent_act": [10.0, 5.0]}
	stats["parties_beaten"] = 11
	var ctx := {"won": false, "villain": "plague", "phase": 1, "best_party": 0, "best_by_villain": {"plague": 0}, "heroes_total": 26}
	var ids := ["ruin_titan", "sewer_flood", "alpha_beast", "fallen_healer"]
	var r: Dictionary = T.check(stats, ctx, ids)
	var done: Array = r["done"].map(func(p): return p["id"])
	check(done.has("sewer_flood") and done.has("ruin_titan") and not done.has("alpha_beast"), "desafios: derrubar a party 11 com o vilão cumpre (40 ratos não) (%s)" % str(done))
	T.t["peak"]["rat"] = 40
	T.t["min_loss"] = 3
	ctx["runs_done"] = {"alpha_beast": 1, "fallen_healer": 2}
	r = T.check(stats, ctx, ids)
	ctx.erase("runs_done")
	done = r["done"].map(func(p): return p["id"])
	check(done.has("alpha_beast") and done.has("fallen_healer"), "desafios em N runs: 40 ratos de uma vez (2ª run) e perdendo até 3 monstros (3ª run) (%s)" % str(done))
	# A maior parte dos desafios é entre runs ("no total", "em N runs"); o gerador (cross_run) conta assim. Plano 21/11: ~70%+.
	var cross := 0
	for k in data.unlock_challenges:
		var ch: Dictionary = data.unlock_challenges[k]
		if ch.get("total", false) or ch.has("runs"):
			cross += 1
	var frac := float(cross) / float(data.unlock_challenges.size())
	check(frac >= 0.75 and frac <= 0.95, "desafios: ~85%% entre runs (%d de %d)" % [cross, data.unlock_challenges.size()])
	# Relíquias por desafio (ids "r:<id>"): o rastreador conhece todas e a de party cumpre como a das cartas.
	var rch := 0
	for rid in data.relics:
		if T.challenge("r:" + str(rid)).size() > 0:
			rch += 1
	stats["parties_beaten"] = 8
	var rr: Dictionary = T.check(stats, ctx, ["r:cracked_hourglass", "r:shortcut_stone"])
	check(rch >= 30 and rr["done"].size() == 1 and rr["done"][0]["id"] == "r:cracked_hourglass", "desafios de relíquia: %d com desafio; party 8 cumpre, party 11 não" % rch)
	stats["parties_beaten"] = 8
	# "no total": carta comum soma o acumulado de todos os vilões (Ogro: 600 monstros)
	T.t["plays"]["monster"] = 40
	ctx["totals_all"] = {"plays|monster": 550.0}
	r = T.check(stats, ctx, ["ogre"])
	check(r["done"].is_empty() and absf(float(r["near"][0]["v"]) - 590.0) < 0.01 and r["near"][0].get("acc", false), "no total: 550 de antes + 40 desta fase = 590/600")
	T.t["plays"]["monster"] = 60
	r = T.check(stats, ctx, ["ogre"])
	check(r["done"].size() == 1, "no total: 550 + 60 libera o Ogro")
	# carta de vilão soma só as runs com ele (Dragão de Ossos: 35 heróis)
	ctx["totals_all"] = {"heroes|": 100.0}
	ctx["totals_villain"] = {"heroes|": 10.0}
	r = T.check(stats, ctx, ["bone_dragon"])
	check(r["done"].is_empty() and absf(float(r["near"][0]["v"]) - 15.0) < 0.01, "no total: carta de vilão usa só o acumulado dele (10 + 5 = 15/35)")
	# "em N fases diferentes": Ninho de Morcegos = 3 estruturas de uma vez em 3 fases
	T.t["peak"]["structure"] = 5
	ctx["runs_done"] = {"bat_nest": 1}
	r = T.check(stats, ctx, ["bat_nest"])
	check(r["done"].is_empty() and r["near"][0].get("hit", false) and int(r["near"][0]["v"]) == 2, "em N fases: cumpriu nesta fase, 2/4")
	ctx["runs_done"] = {"bat_nest": 3}
	r = T.check(stats, ctx, ["bat_nest"])
	check(r["done"].size() == 1, "em N fases: a 4ª fase libera")
	# desafio de party vale também perdendo (conta as parties derrubadas), mas só com a party certa
	ctx["won"] = false
	stats["parties_beaten"] = 7
	r = T.check(stats, ctx, ["sewer_flood"])
	check(r["done"].is_empty() and int(r["near"][0]["v"]) == 7, "desafios: party 7 de 8 ainda não cumpre (7/8)")
	# janela deslizante: 5 cartas em 5 s
	var s2 := _sim(4, "plague")
	var c := Sim.CardInst.new()
	c.def = data.card("web")
	for i in 7:
		s2.t = 10.0 + i * 0.8
		s2.track.on_play(s2, c)
	check(int(s2.track.t["win_peak"].get("any|6.0", 0)) == 7, "desafios: 7 cartas em 6 segundos (janela deslizante)")
	# a run de verdade rastreia: joga uma carta e anda um pouco
	var s3 := _sim(6, "plague")
	s3.elixir = 10.0
	for i in 40:
		s3.step()
	check(int(s3.track.t["peak"].get("monster", 0)) == 0, "desafios: rastreador roda no passo do Sim sem erro")
	# fim de fase: acumula entre fases (perdendo também), separa por vilão e salva
	var path := "user://test_meta_unlock.save"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var m := MetaSave.load_or_new(data, path)
	s3.track.t["plays"]["monster"] = 400
	s3.track.t["peak"]["rat"] = 40
	s3.track.t["peak"]["structure"] = 5
	m.apply_unlocks(s3, false, path)
	check(not m.is_unlocked("ogre") and float(m.progress["ogre"]["v"]) == 400.0 and float(m.totals["plague"]["plays|monster"]) == 400.0, "apply_unlocks: run perdida soma no total (Ogro 400/600)")
	check(int(m.runs_done.get("bat_nest", 0)) == 1 and float(m.progress["bat_nest"]["v"]) == 1.0, "apply_unlocks: conta a fase do feito (Ninho 1/4)")
	check(int(m.runs_done.get("alpha_beast", 0)) == 1, "apply_unlocks: conta a run do feito de pico (40 ratos, 1/2)")
	var s4 := _sim(7, "dragon")
	s4.track.t["plays"]["monster"] = 250
	var res := m.apply_unlocks(s4, false, path)
	check(m.is_unlocked("ogre") and res["done"].any(func(p): return p["id"] == "ogre"), "apply_unlocks: carta comum soma as fases de outro vilão (400 + 250 libera o Ogro)")
	check(not m.totals.get("dragon", {}).is_empty() and float(m.totals["plague"]["plays|monster"]) == 400.0, "apply_unlocks: acumulado separado por vilão")
	var m2 := MetaSave.load_or_new(data, path)
	check(m2.is_unlocked("ogre") and int(m2.runs_done.get("alpha_beast", 0)) == 1 and int(m2.runs_done.get("bat_nest", 0)) == 1 and float(m2.totals_all().get("plays|monster", 0.0)) == 650.0, "desbloqueio, acumulados e fases contadas sobrevivem ao salvar")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func t_meta() -> void:
	var path := "user://test_meta.save"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var m := MetaSave.load_or_new(data, path)
	check(m.villains == ["plague"] and m.villain == "plague", "começa só com a Praga")
	check(m.is_unlocked("rat_horde") and m.is_unlocked("rat_king") and m.is_unlocked("web") and not m.is_unlocked("ogre") and not m.is_unlocked("gold_dart"), "coleção inicial: baralho base e cartas liberadas; o resto bloqueado por desafio")
	# Save antigo (sem "ver" ou de versão menor que a 5): zera por decisão do plano de 21/11/2026, nada é lido.
	var old := "user://test_meta_old.save"
	var f := FileAccess.open(old, FileAccess.WRITE)
	f.store_var({"souls": 77, "pacts": ["horde", "treasure"], "pact": "treasure", "unlocked": ["cosmic_ray", "ogre"], "phases_won": [1]})
	f.close()
	var mo := MetaSave.load_or_new(data, old)
	check(not "souls" in mo and mo.villains == ["plague"] and mo.villain == "plague" and mo.almas == 0 and not mo.is_unlocked("cosmic_ray") and not mo.is_unlocked("ogre"), "save antigo (v4): zera tudo (só a Praga, 0 Almas, cartas antigas somem)")
	check(mo.heroes_seen.is_empty() and mo.best_party == 0 and mo.upgrades.is_empty(), "save antigo (v4): nada é migrado (heróis vistos, recorde, melhorias)")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(old))
	check(m.see_hero("besteiro") and not m.see_hero("besteiro"), "herói visto só conta na primeira vez")
	m.add_run(path)
	var m2 := MetaSave.load_or_new(data, path)
	check(m2.is_unlocked("rat_king") and m2.runs == 1, "meta salva e carrega")
	var fm := FileAccess.open(path, FileAccess.READ)
	var raw = fm.get_var()
	fm.close()
	check(typeof(raw) == TYPE_DICTIONARY and not raw.has("souls"), "o meta salvo não tem mais Almas")
	check(m2.heroes_seen.has("besteiro"), "heróis vistos salvam e carregam")
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
				# Exceção: um rio que corta uma fileira inteira faz todos os locais dela Ponte (15/11/2026).
				if by_row.has(key) and road.locations[n["loc"]]["type"] != "bridge":
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


## Rios (15/11/2026): sementes × atos, com as regras conferidas por fora do gerador.
func t_rivers() -> void:
	var RV: Dictionary = data.rules["road"]["river"]
	var need: float = float(RV["half_width"]) + float(RV["clearance"]) - 0.05
	var maps := 0
	var no_river := 0
	var two := 0
	var kinds := {"cross": 0, "u": 0}
	var nb_hist := {}
	var bad_cap := 0
	var bad_type := 0
	var bad_route := 0
	var bad_clear := 0
	var bad_len := 0
	var bad_shop := 0
	var t0 := Time.get_ticks_msec()
	for seed_ in range(1, 121):
		for act in 3:
			var road := SimRoad.new()
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_ * 7919 + act * 104729
			var cfg: Dictionary = data.rules["acts"][mini(act, data.rules["acts"].size() - 1)].get("road", {})
			road.generate(rng, data.rules, cfg)
			maps += 1
			if road.rivers.is_empty():
				no_river += 1
			if road.rivers.size() == 2:
				two += 1
			var total := 0
			var is_b := {}
			for rv in road.rivers:
				kinds[rv["kind"]] += 1
				if rv["kind"] == "cross":
					kinds["diagonal" if int(rv.get("slope", 0)) != 0 else "reto"] = int(kinds.get("diagonal" if int(rv.get("slope", 0)) != 0 else "reto", 0)) + 1
				total += rv["bridges"].size()
				for n in rv["bridges"]:
					is_b[n] = true
					if int(road.nodes[n]["row"]) == road.shop_row:
						bad_shop += 1
			nb_hist[total] = int(nb_hist.get(total, 0)) + 1
			if total > int(RV["max_bridges"]):
				bad_cap += 1
			for li in road.locations.size():
				var loc: Dictionary = road.locations[li]
				if (loc["type"] == "bridge") != is_b.has(int(loc["node"])):
					bad_type += 1
			var paths := _all_paths(road)
			var l0 := _path_len(road, paths[0])
			for p in paths:
				if absf(_path_len(road, p) - l0) > 1.0:
					bad_len += 1
				for rv in road.rivers:
					var c := 0
					for n in p:
						if rv["bridges"].has(n):
							c += 1
					if (rv["kind"] == "cross" and c != 1) or (rv["kind"] == "u" and c != 0 and c != 2):
						bad_route += 1
			# Distância do rio à estrada, na força bruta (fora do trecho reto de cada ponte).
			for rv in road.rivers:
				var pts: PackedVector2Array = rv["pts"]
				for g in road.legs:
					var lp: PackedVector2Array = g["pts"][0]
					for i in lp.size() - 1:
						var skip := false
						for n in rv["bridges"]:
							var bp: Vector2 = road.nodes[n]["pos"]
							if lp[i].distance_to(bp) <= float(RV["stub"]) + 0.05 and lp[i + 1].distance_to(bp) <= float(RV["stub"]) + 0.05:
								skip = true
						if skip:
							continue
						for q in pts:
							if Geometry2D.get_closest_point_to_segment(q, lp[i], lp[i + 1]).distance_to(q) < need:
								bad_clear += 1
								break
	print("  rios: %d mapas, %d sem rio, %d com 2 rios, formatos %s, pontes por ato %s, %d ms" % [maps, no_river, two, str(kinds), str(nb_hist), Time.get_ticks_msec() - t0])
	check(no_river * 10 <= maps, "quase todo ato tem rio (%d de %d sem)" % [no_river, maps])
	check(bad_cap == 0, "no máximo %d pontes por ato (%d acima)" % [int(RV["max_bridges"]), bad_cap])
	check(bad_type == 0, "toda Ponte está num rio e todo nó-ponte é Ponte (%d erros)" % bad_type)
	check(bad_shop == 0, "a fileira da Loja nunca vira ponte (%d)" % bad_shop)
	check(bad_route == 0, "rota passa por 1 ponte do rio que atravessa e 0 ou 2 do vai e volta (%d erros)" % bad_route)
	check(bad_clear == 0, "o rio só toca a estrada nas pontes (%d trechos perto demais)" % bad_clear)
	check(bad_len == 0, "com as pontes, todas as rotas seguem do mesmo comprimento (%d fora)" % bad_len)


## Água dos rios na simulação (16/11/2026): carta, unidade, ponte, alvo e save.
func t_water() -> void:
	var s := _sim(12)
	var T := s.terra()
	check(T.ok and T.bridges.size() > 0, "terreno do rio montado (%d pontes)" % T.bridges.size())
	if not T.ok or T.bridges.is_empty():
		return
	# Um ponto no meio da água, longe das pontes.
	var wet := Vector2.INF
	for rv in s.road.rivers:
		for p in rv["pts"]:
			var near_bridge := false
			for b in T.bridges:
				if p.distance_to(b["c"]) < 15.0:
					near_bridge = true
			if not near_bridge and T.is_water(p.x, p.y) and T.region_at(p.x, p.y) == SimTerrain.UNKNOWN:
				wet = p
				break
		if wet != Vector2.INF:
			break
	check(wet != Vector2.INF, "achou um ponto na água")
	var ground: CardDef = null
	var flyer: CardDef = null
	var spell: CardDef = null
	for c in data.cards:
		if c.category != "field":
			continue
		if c.is_spell and spell == null:
			spell = c
		elif not c.is_spell and c.fly and flyer == null:
			flyer = c
		elif not c.is_spell and not c.fly and c.arch == K.Arch.CHASER and ground == null and c.id != "ghost":   # o Fantasma morre no 1º passo e o teste de travessia "falhava"
			ground = c
	var gi := s._new_inst(ground)
	check(not s.valid_target(gi, wet.x, wet.y), "monstro de chão não pode ser solto na água (%s)" % ground.id)
	if flyer:
		check(s.valid_target(s._new_inst(flyer), wet.x, wet.y) or s.in_any_ring(wet.x, wet.y), "voador pode ser solto na água (%s)" % flyer.id)
	if spell:
		check(s.valid_target(s._new_inst(spell), wet.x, wet.y), "feitiço pode ser solto na água (%s)" % spell.id)
	# Unidade que nasce (ou é empurrada) para a água volta para a margem no passo seguinte.
	var j := s.units.spawn(ground, wet.x, wet.y, 0.0, 0.0, K.F_NO_XP, 0)
	s.step()
	check(s.units.alive[j] == 0 or not T.is_water(s.units.px[j], s.units.py[j]), "unidade na água volta para a margem")
	# Travessia: herói parado numa cabeceira, monstro na outra margem; ele vai pela ponte e nunca entra na água.
	var b: Dictionary = T.bridges[0]
	var c: Vector2 = b["c"]
	var ea: Vector2 = b["a"]
	var eb: Vector2 = b["b"]
	var s2 := _sim(12)
	var T2 := s2.terra()
	s2.offers.clear()
	s2.hero.base_hp = 1.0e6
	s2.hero.hp = 1.0e6
	var hp_ := ea + (ea - c).normalized() * 3.0
	s2.hero.x = hp_.x
	s2.hero.y = hp_.y
	s2.hero.hold = true
	s2.hero.leash_mult = 1000.0   # a ponte pode ficar longe do herói na estrada (19/11/2026: estradas em curva); sem coleira
	s2.hero.hold_x = hp_.x
	s2.hero.hold_y = hp_.y
	var up := eb + (eb - c).normalized() * 3.0 + (eb - c).normalized().orthogonal() * 6.0
	if T2.is_water(up.x, up.y):
		up = T2.nearest_dry(up.x, up.y)
	var k := s2.units.spawn(ground, up.x, up.y, 0.0, 0.0, K.F_NO_XP, 0)
	var wet_steps := 0
	var crossed := false
	for st in int(25.0 / s2.dt):
		s2.hero.x = hp_.x
		s2.hero.y = hp_.y
		if s2.offers.size() > 0:
			s2.choose(Sim.SKIP)
		s2.step()
		if s2.units.alive[k] == 0:
			break
		if T2.is_water(s2.units.px[k], s2.units.py[k]):
			wet_steps += 1
		if T2.same_side(s2.units.px[k], s2.units.py[k], hp_.x, hp_.y) and T2.region_at(s2.units.px[k], s2.units.py[k]) != SimTerrain.ON_DECK:
			crossed = true
			break
	check(wet_steps == 0, "o monstro nunca termina um passo na água (%d)" % wet_steps)
	check(crossed, "o monstro do outro lado chega ao herói pela ponte")
	# Herói: monstro do outro lado da água não vira alvo, mesmo perto.
	var s3 := _sim(12)
	var T3 := s3.terra()
	s3.offers.clear()
	s3.hero.x = hp_.x
	s3.hero.y = hp_.y
	var other := eb + (eb - c).normalized() * 3.0
	var m := s3.units.spawn(ground, other.x, other.y, 0.0, 0.0, K.F_NO_XP, 0)
	check(not T3.same_side(hp_.x, hp_.y, other.x, other.y) or T3.region_at(other.x, other.y) == SimTerrain.ON_DECK, "os dois pontos estão em margens diferentes")
	s3.hero.AI = s3.hero.AI.duplicate()
	s3.hero.AI["engage_radius"] = 60.0
	s3.hero._choose_target()
	check(not (s3.hero.target_kind == SimHero.TGT_UNIT and s3.hero.target == m), "herói ignora monstro do outro lado do rio")
	# Save e load: os rios voltam iguais e a água funciona.
	check(SaveGame.save(s, "user://test_rio.save"), "salvou com rio")
	var r := SaveGame.load_run(data, "user://test_rio.save")
	check(r != null and r.road.rivers.size() == s.road.rivers.size() and r.terra().ok and r.terra().is_water(wet.x, wet.y),
		"carregou com os mesmos rios e a água no lugar")
	check(r != null and r.state_hash() == s.state_hash(), "save com rio: mesmo estado")

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
	g._offer_marks("tavern", 3)
	check(is_equal_approx(g.gold - gb, float(data.rules["gold"]["per_contest"])), "disputa com os 3 marcos rende ouro")
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
func _at_location(ty: String, seed_ := 3, act_ := 0) -> Sim:
	var s := _sim(seed_)
	s.hero.base_hp = 1.0e6
	s.hero.hp = 1.0e6
	# Estrada decidida até o primeiro nó; herói em cima dele (com o progresso na estrada certo, senão a coleira o puxa).
	s.road.advance(s.road.nodes[0]["out"][0])
	var li: int = s.road.nodes[s.road.head]["loc"]
	var loc: Dictionary = s.road.locations[li]
	loc["type"] = ty
	loc["hard"] = false   # o mapa da semente pode sortear o local como difícil (metas ×); o teste quer a meta base
	loc["r"] = float(data.rules["locations"][ty]["radius"])
	var p: Vector2 = loc["pos"]
	s.hero.x = p.x
	s.hero.y = p.y
	s.hero.s = s.road.length()
	s.hero.s_max = s.hero.s
	s.hero.seg = s.road.seg_at(s.hero.s)
	s.offers.clear()
	s.act = act_
	s._arrive(li)
	return s


func _steps(s: Sim, sec: float) -> void:
	for i in int(sec / s.dt):
		s.step()


## Como _steps, mas pula as ofertas que aparecem (a sim para esperando a escolha; o mapa de cada semente decide quando a 1ª sai).
func _steps_free(s: Sim, sec: float) -> void:
	for i in int(sec / s.dt):
		if s.offers.size() > 0:
			s.choose(Sim.SKIP)
		s.step()


func t_contests() -> void:
	# Barra única (12/11/2026): uma janela e 3 marcos; cada marco alcançado dá uma recompensa.
	var L: Dictionary = data.rules["locations"]
	# Ritual: mortes de monstros seus dentro do círculo.
	var s := _at_location("ritual")
	var p: Vector2 = s.road.locations[int(s.contest["li"])]["pos"]
	var rm: Array = L["ritual"]["marks"]
	check(s.contest["type"] == "ritual" and s.hero.hold and s.contest["marks"].size() == 3 and is_equal_approx(float(s.contest["goal"]), float(rm[2])), "Ritual: o herói para no local e a barra de 3 marcos começa")
	check(is_equal_approx(float(s.contest["window"]), float(L["ritual"]["window"])), "Ritual: uma janela só para a barra")
	_kills(s, p, int(rm[0]))
	s.step()
	check(int(s.contest["won"]) == 1 and not s.contest.is_empty(), "Ritual: as mortes do 1º marco o alcançam e a disputa segue")
	_kills(s, p, int(rm[1]) - int(rm[0]))
	s.step()
	check(int(s.contest["won"]) == 2, "Ritual: 2º marco")
	_kills(s, p, int(rm[2]) - int(rm[1]))
	s.step()
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "upgrade" and s.offers[0]["options"].size() > roundi(s.cards.size() * 0.5),
		"Ritual: os 3 marcos dão o nível de qualquer carta")
	s = _at_location("ritual")
	_steps(s, float(L["ritual"]["window"]) + 0.5)
	check(s.contest.is_empty() and s.offers.is_empty() and not s.hero.hold, "Ritual: janela sem mortes → nada, e o herói segue")
	# Parcial: só o 1º marco = recompensa do marco 1 (25% do deck), sem ouro de consolo.
	s = _at_location("ritual")
	p = s.road.locations[int(s.contest["li"])]["pos"]
	var g0 := s.gold
	_kills(s, p, int(rm[0]))
	# O que nasce das mortes (um passivo sorteado, como "+1 rato ao morrer") bateria no herói e daria ouro de dano:
	# este teste é só da recompensa do local, então tira as sobras (o resultado não depende mais do sorteio).
	for i in s.units.hi:
		if s.units.alive[i] == 1:
			s.units.release(i)
	_steps(s, float(L["ritual"]["window"]) + 0.5)
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"].size() == maxi(1, roundi(s.cards.size() * 0.25)) and is_equal_approx(s.gold - g0, 0.0),
		"Ritual: só o marco 1 → 1 carta entre 25%% do deck, sem ouro (%.0f)" % (s.gold - g0))
	# Ritual, ato 2: metas ×1,5 e só mortes de custo 3 ou mais.
	s = _at_location("ritual", 3, 1)
	p = s.road.locations[int(s.contest["li"])]["pos"]
	check(str(s.contest["variant"]) == "cost3" and is_equal_approx(float(s.contest["marks"][0]), roundf(float(rm[0]) * 1.5)), "Ritual ato 2: variante de custo 3+ e metas ×1,5")
	for k in 3:
		var j := s.units.spawn(data.card("kobold_scavengers"), p.x + 1.0, p.y, 0.0, 0.0, 0, 999)
		s.kill_unit(j, K.Death.HERO)
	check(is_equal_approx(float(s.contest["progress"]), 0.0), "Ritual ato 2: morte de monstro de custo 2 não conta")
	# Santuário: monstro que luta no círculo; torre não conta.
	s = _at_location("shrine")
	p = s.road.locations[int(s.contest["li"])]["pos"]
	s.hero.petrify_t = 100.0
	s.units.spawn(data.card("gargoyle_tower"), p.x + 2.0, p.y, 0.0, 0.0, 0, 999)
	_steps(s, 7.0)
	check(int(s.contest["won"]) == 0, "Santuário: só uma torre no círculo não conta")
	s.units.spawn(data.card("slime"), p.x - 2.0, p.y, 0.0, 0.0, 0, 999)
	_steps(s, float(L["shrine"]["marks"][0]) + 2.6)
	check(int(s.contest["won"]) >= 1, "Santuário: os segundos do 1º marco com monstro no círculo o alcançam")
	s = _at_location("shrine", 3, 2)
	check(s.contest.has("p2"), "Santuário ato 3: a barra tem dois círculos")
	_fill(s, 3)
	check(s.contest.is_empty() and s.offers.size() == 3 and s.offers[0]["options"][0]["kind"] == "card", "Santuário: os 3 marcos dão 3 escolhas de carta rara")
	s = _at_location("shrine")
	_fill(s, 1)
	_steps(s, float(L["shrine"]["window"]) + 0.5)
	check(s.contest.is_empty() and s.offers.size() == 1, "Santuário: só 1 marco = 1 carta rara")
	# Taverna: casas no chão, meta cumulativa 1, 2, 3; 1 escolha de modificador por casa.
	s = _at_location("tavern", 4)
	var loc: Dictionary = s.road.locations[int(s.contest["li"])]
	check(loc["houses"].size() == int(L["tavern"]["houses"]) and is_equal_approx(float(loc["houses"][0]["max_hp"]), float(L["tavern"]["house_hp_act"][0])), "Taverna: as casas aparecem com a vida do ato")
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
	check(s.contest.is_empty() and s.offers.size() == 3 and s.offers[0]["options"][0]["kind"] == "mod", "Taverna: 3 casas no chão = 3 escolhas de modificador")
	s = _at_location("tavern")
	s.hero.petrify_t = 100.0
	s.damage_house(0, 1.0e6)
	_steps(s, float(L["tavern"]["window"]) + 0.5)
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "mod", "Taverna: 1 casa destruída = 1 escolha de modificador")
	# Ponte: dano na janela, 3 marcos, escolhas de carta comum, incomum e rara.
	s = _at_location("bridge")
	check(s.hero.tavern_t > 0.0, "Ponte: o herói fica lento")
	var bm: Array = L["bridge"]["marks"]
	s.damage_hero(float(bm[0]) * 1.1, s.hero.x + 1.0, s.hero.y, 0, SimHero.DMG_PIERCE, "test")
	s.step()
	check(int(s.contest["won"]) == 1 and is_equal_approx(float(s.contest["goal"]), float(bm[2])), "Ponte: o dano do 1º marco o alcança")
	_fill(s, 3)
	check(s.contest.is_empty() and s.offers.size() == 3 and s.offers[0]["options"][0]["kind"] == "card", "Ponte: 3 marcos = 3 escolhas de carta")
	s = _at_location("bridge", 3, 2)
	check(is_equal_approx(float(s.contest["marks"][0]), roundf(float(bm[0]) * 2.2)), "Ponte ato 3: metas ×2,2")
	# Fonte: interromper o gole enche a barra; gole completo não ajuda o jogador.
	s = _at_location("fountain")
	check(s.hero.drink_t > 0.0, "Fonte: o herói começa a beber")
	check(s.helper != null and s.helper.hp > 0.0 and s.helper.cls() != s.hero.cls(), "Fonte: um guarda de outra classe defende o local")
	var gh := s.helper
	var x0 := s.hero.x
	_steps(s, 1.0)
	check(is_equal_approx(s.hero.x, x0), "Fonte: bebendo, ele não anda")
	s.hero_fear(s.hero.x + 1.0, s.hero.y)
	s.step()
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"][0]["kind"] == "remove" and s.offers[0]["options"].size() > roundi(s.cards.size() * 0.5),
		"Fonte: medo enche a barra = remover qualquer carta")
	check(s.helper == null and gh != null, "Fonte: o guarda some com a disputa")
	s = _at_location("fountain")
	s.contest["progress"] = float(L["fountain"]["marks"][0]) + 5.0
	s.step()
	check(int(s.contest["won"]) == 1, "Fonte: o dano do 1º marco o alcança")
	_steps(s, float(L["fountain"]["window"]) + 0.5)
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["options"].size() == maxi(1, roundi(s.cards.size() * 0.25)),
		"Fonte: só o marco 1 = remover 1 carta entre 25%% do deck")
	s = _at_location("fountain", 3, 2)
	check(is_equal_approx(float(s.contest["marks"][0]), roundf(float(L["fountain"]["marks"][0]) * 2.2)), "Fonte ato 3: metas ×2,2")
	s = _at_location("fountain")
	s.hero.base_hp = 1000.0
	s.hero.hp = 500.0
	_steps(s, float(L["fountain"]["window"]) + 0.5)
	check(s.offers.is_empty() and s.hero.hp > 500.0, "Fonte: gole completo cura o herói e não dá nada (%.0f)" % s.hero.hp)
	# Loja e "?": sem disputa.
	s = _at_location("shop")
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["source"] == "shop", "Loja abre na chegada, sem disputa")
	s = _at_location("event")
	check(s.contest.is_empty() and s.offers.size() == 1 and s.offers[0]["source"] == "event", "Local ? abre um evento de texto")


## Mortes de ogros nossos dentro do círculo (conta para o Ritual).
func _kills(s: Sim, p: Vector2, n: int) -> void:
	for k in n:
		var j := s.units.spawn(data.card("ogre"), p.x + 1.0, p.y, 0.0, 0.0, 0, 999)
		s.kill_unit(j, K.Death.HERO)


## Leva a barra até o marco `n` (1 a 3) e dá um passo.
func _fill(s: Sim, n: int) -> void:
	if s.contest.is_empty():
		return
	s.contest["progress"] = float(s.contest["marks"][n - 1])
	if s.contest["type"] == "tavern":
		var loc: Dictionary = s.road.locations[int(s.contest["li"])]
		for k in loc["houses"].size():
			if s._houses_down(loc) < n:
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
	# Pelo menos a do fim de cada ato (11/11/2026: o Herói Ajudante e outras fontes dão mais).
	check(s.stats["relics"].size() >= at.size(), "ao menos uma relíquia por ato terminado (%d relíquias, %d atos)" % [s.stats["relics"].size(), at.size()])
	check(int(s.stats["locs_visited"]) >= at.size() * 5, "cada ato passa por vários locais (%d)" % s.stats["locs_visited"])
	# Começo do ato seguinte: estrada nova, herói no começo dela, vida mantida.
	var a := _sim(5)
	a.hero.hp = a.hero.max_hp() * 0.5
	var hp := a.hero.hp
	a._end_act()
	check(a.act_pending and a.offers.size() == 2 and a.offers[0]["source"] == "act_card" and a.offers[1]["source"] == "relic", "fim do ato oferece a carta e, depois dela, a relíquia")
	var old_road := a.road
	a.choose(Sim.SKIP)
	check(a.offers.size() == 1 and a.offers[0]["source"] == "relic", "recusar a carta do fim de ato passa para a relíquia")
	a.choose(Sim.SKIP)   # a relíquia sorteada pode mexer na vida (não é mais sempre de elixir)
	a.step()
	check(a.act == 1 and a.road != old_road and a.hero.s == 0.0 and is_equal_approx(a.hero.hp, hp), "ato 2: estrada nova, herói no começo e com a mesma vida")


## C17 (19/11/2026): troca de ato contínua. O ato novo nasce no covil do anterior, sem teleporte e sem matar unidades.
func t_act_continuous() -> void:
	var a := _sim(5)
	var lair: Vector2 = a.road.lair
	a.hero.x = lair.x
	a.hero.y = lair.y
	for k in 4:
		a.units.spawn(data.card("rat_horde"), lair.x + 3.0 + k, lair.y + 2.0, 0.0, 0.0, 0, 999)
	var alive := 0
	for i in a.units.hi:
		alive += int(a.units.alive[i])
	a._end_act()
	var old_road := a.road
	if SaveGame.save(a, "user://test_act.save"):   # save no meio da troca (oferta pendente)
		var c := SaveGame.load_run(data, "user://test_act.save")
		check(c != null and c.state_hash() == a.state_hash() and c.act_pending, "save no meio da troca de ato recarrega igual")
		SaveGame.erase("user://test_act.save")
	a.choose(Sim.SKIP)
	a.choose(Sim.SKIP)
	a.step()
	var alive2 := 0
	for i in a.units.hi:
		alive2 += int(a.units.alive[i])
	check(a.act == 1 and a.road != old_road, "ato novo gerado")
	check(a.road.route[0].distance_to(lair) < 0.01, "o ato novo nasce no covil do anterior")
	check(Vector2(a.hero.x, a.hero.y).distance_to(lair) < 2.0, "o herói não é teleportado na troca (%.2f m)" % Vector2(a.hero.x, a.hero.y).distance_to(lair))
	check(alive2 >= alive, "a troca de ato não mata unidades (%d -> %d)" % [alive, alive2])
	var dir_dot := old_road.lair_dir.dot((a.road.nodes[1]["pos"] - a.road.nodes[0]["pos"]).normalized())
	check(dir_dot > 0.3, "o ato novo segue no sentido do anterior (%.2f)" % dir_dot)
	check(SaveGame.save(a, "user://test_act.save"), "salvou depois da troca")
	var c2 := SaveGame.load_run(data, "user://test_act.save")
	check(c2 != null and c2.state_hash() == a.state_hash() and c2.past_lines.size() == a.past_lines.size() and a.past_lines.size() > 0, "save depois da troca guarda as estradas anteriores")
	if c2 != null:
		for i in 600:
			a.step()
			c2.step()
		check(a.state_hash() == c2.state_hash(), "retomada idêntica depois da troca de ato")
	SaveGame.erase("user://test_act.save")


## Atos encadeados (C17): o ato novo não cruza nem encosta na estrada do anterior, longe do covil de partida.
func t_acts_chain() -> void:
	var near := 0
	var n := 0
	var worst := 0
	var river_min := 1e9
	for sd in range(1, 121):
		var s := _sim(sd)
		for k in range(1, int(data.rules["run"]["acts"])):
			s.past_lines.append_array(s.road.all_lines())
			var nr := s.gen_act_road(k, s.road.lair, s.road.lair_dir, s.past_lines)
			var grid := SimRoad.point_grid(s.past_lines, 12.0)
			var c := nr.clash(grid, 12.0, s.road.lair, Sim.ACT_SKIP_R, 6.0)
			near += c
			worst = maxi(worst, c)
			for rv in nr.rivers:
				for rp in rv["pts"]:
					river_min = minf(river_min, rp.distance_to(s.road.lair))
			n += 1
			s.road = nr
	print("  atos encadeados: %d trocas, pontos a menos de 6 m %d (pior troca %d)" % [n, near, worst])
	check(worst == 0, "atos encadeados: nenhuma troca caiu na tentativa de reserva")
	print("  atos encadeados: rio mais perto do covil de partida %.1f m" % river_min)
	check(river_min > 12.0, "atos encadeados: o rio do ato novo nunca fica em cima do covil de partida (%.1f m)" % river_min)
	check(near == 0, "atos encadeados: estrada nova nunca encosta na anterior (%d pontos)" % near)


func t_world_append() -> void:
	var a := _sim(5)
	var w := WorldView.new()
	add_child(w)
	var cam := Camera3D.new()
	add_child(cam)
	w.build(a, cam)
	w.cam_pos = Vector3(123, 0, -45)
	var n0 := w.static_nodes.size()
	a._end_act()
	a.choose(Sim.SKIP)
	a.choose(Sim.SKIP)
	a.step()
	w.build(a, cam, true)
	check(n0 > 0 and w.static_nodes.size() > 0, "WorldView guarda o cenário do ato (%d nós)" % n0)
	check(w.old_acts.size() == 1 and (w.old_acts[0] as Node).get_child_count() > 0, "o cenário do ato antigo fica num nó à parte e continua no mapa (%d)" % ((w.old_acts[0] as Node).get_child_count() if w.old_acts.size() > 0 else -1))
	check(w.cam_pos.is_equal_approx(Vector3(123, 0, -45)), "anexar o ato não teleporta a câmera")
	w.build(a, cam, true)
	w.build(a, cam)   # reconstrução limpa
	w.queue_free()
	cam.queue_free()


func t_relics() -> void:
	var s := _sim(2)
	s.gain_relic("heavy_grimoire")
	check(s.hand_size == 7 and s.elixir_max == 8.0, "Grimório Pesado: mão +2, elixir máximo −2 (%d, %.0f)" % [s.hand_size, s.elixir_max])
	s.gain_relic("shortcut_stone")
	var cost0 := s.card_cost(s.hand[0])
	s.contest = {"probe": true}
	check(s.card_cost(s.hand[0]) == 0, "Pedra do Atalho: a primeira carta da disputa custa 0")
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
	check(c.relics == s.relics and c.rv("contest_first_discount") == 99.0 and c.hand_size == 7, "relíquias vão no salvamento")
	SaveGame.erase("user://test.save")


## Relíquias da rodada 11/11/2026: cada efeito novo, empilhamento, fontes (disputa difícil, loja) e salvamento.
func _contest_li(s: Sim) -> int:
	for k in s.road.locations.size():
		if s.road.locations[k]["type"] in ["tavern", "fountain", "ritual", "bridge", "shrine"]:
			return k
	return -1


func _mods_total(s: Sim) -> int:
	var n := 0
	for ci in s.cards:
		for b in [1, 2, 4, 8, 16]:
			if ci.mods & b:
				n += 1
	return n


func t_relics_1111() -> void:
	# Empilhamento: a mesma relíquia vem de novo e soma; "unique" não repete.
	var s := _sim(7, "plague")
	s.gain_relic("elixir_flask")
	s.gain_relic("elixir_flask")
	var fl := float(data.relics["elixir_flask"]["fx"]["elixir_max"])
	check(is_equal_approx(s.elixir_max, 10.0 + 2.0 * fl) and s.relics.count("elixir_flask") == 2, "Frasco de Elixir empilha (%.0f)" % s.elixir_max)
	s.gain_relic("bone_crown")
	s.gain_relic("bone_crown")
	check(s.relics.count("bone_crown") <= 1, "relíquia única não repete")
	check(s._relic_pool().has("elixir_flask"), "relíquia que empilha continua no sorteio depois de pega")
	s.gain_relic("quick_spring")
	var rg := float(data.relics["quick_spring"]["fx"]["elixir_regen"]) + 2.0 * float(data.relics["elixir_flask"]["fx"].get("elixir_regen", 0.0))
	check(rg > 0.0 and is_equal_approx(s.seconds_per_elixir(), 2.8 / (1.0 + rg)), "Nascente Veloz: regen mais rápida (%.2f s)" % s.seconds_per_elixir())
	s.gain_relic("hand_pocket")
	check(s.hand_size == 6, "Bolso Extra: mão +1")
	# Tambor de Guerra e Marca da Vitória: chegar à disputa dá elixir; vencer as 3 etapas sobe o máximo (até o teto).
	var v := _sim(8, "plague")
	v.gain_relic("war_drum")
	v.gain_relic("victory_mark")
	var li := _contest_li(v)
	v.elixir = 0.0
	v._arrive(li)
	check(is_equal_approx(v.elixir, float(data.relics["war_drum"]["fx"]["contest_enter_elixir"])), "Tambor de Guerra: +elixir ao entrar numa disputa (%.1f)" % v.elixir)
	var m0 := v.elixir_max
	v._resolve_contest(3)
	check(is_equal_approx(v.elixir_max, m0 + 1.0), "Marca da Vitória: vencer a disputa dá +1 de máximo")
	for k in 6:
		v.offers.clear()
		v._arrive(li)
		v._resolve_contest(3)
	v.offers.clear()
	var cap := float(data.relics["victory_mark"]["fx"]["contest_max_cap"])
	check(is_equal_approx(v.elixir_max, m0 + cap), "Marca da Vitória para no teto (+%.0f)" % cap)
	# Disputa difícil: vencer as 3 etapas dá também a oferta de relíquia.
	var h := _sim(9, "plague")
	var hl := _contest_li(h)
	h.road.locations[hl]["hard"] = true
	h._arrive(hl)
	h._resolve_contest(3)
	check(h.offers.size() >= 2 and h.offers[h.offers.size() - 1]["source"] == "relic" and h.offers[h.offers.size() - 1]["relic_src"] == "hard", "disputa difícil vencida: recompensa normal e depois 1 de 3 relíquias")
	var h2 := _sim(9, "plague")
	h2.road.locations[hl]["hard"] = true
	h2._arrive(hl)
	h2._resolve_contest(2)
	check(not h2.offers.any(func(o): return o["source"] == "relic"), "disputa difícil sem as 3 etapas não dá relíquia")
	var hard_n := 0
	for loc in _sim(19, "plague").road.locations:
		if loc.get("hard", false):
			hard_n += 1
	check(hard_n == int(data.rules["road"]["hard_contests"]), "o mapa marca %d disputas difíceis por ato (%d)" % [int(data.rules["road"]["hard_contests"]), hard_n])
	# Selo da Ganância: 4 opções.
	var g := _sim(10, "plague")
	g.gain_relic("greedy_seal")
	g.offers.clear()
	g.offer_relic_choice("test")
	check(g.offers[0]["options"].size() == 4, "Selo da Ganância: oferta de relíquia com 4 opções")
	# Abertura: a 1ª carta contra o herói da vez sai de graça.
	var o := _sim(11, "plague")
	o.gain_relic("opening_gambit")
	o.elixir = 0.0
	check(o.card_cost(o.hand[0]) == 0 and o.play(0, o.hero.x + 6.0, o.hero.y) == K.Block.OK, "Abertura: a 1ª carta custa 0")
	check(not o.gambit_ready(), "Abertura: só a primeira")
	o.hero.pidx += 1
	check(o.gambit_ready(), "Abertura: vale de novo no herói seguinte")
	# Moeda da Sorte (chance forçada em 100%).
	var lc := _sim(12, "plague")
	lc.gain_relic("lucky_coin")
	lc.rfx["free_play_chance"] = 1.0
	lc.elixir = 9.0
	lc.play(0, lc.hero.x + 6.0, lc.hero.y)
	check(lc.elixir >= 9.0 - 0.001, "Moeda da Sorte: a carta sai sem gastar elixir")
	# Ninhada Dobrada: bando invoca +1.
	var tw := _sim(13, "plague")
	var n0 := tw.units.count
	tw._apply(_inst("rat_horde"), tw.hero.x + 6.0, tw.hero.y)
	var base_n := tw.units.count - n0
	tw.gain_relic("twin_litter")
	n0 = tw.units.count
	tw._apply(_inst("rat_horde"), tw.hero.x + 6.0, tw.hero.y)
	check(tw.units.count - n0 == base_n + 1, "Ninhada Dobrada: carta de bando invoca +1 (%d → %d)" % [base_n, tw.units.count - n0])
	# Chamado da Cova (chance forçada): morre e volta Esqueleto; o Esqueleto não volta de novo.
	var gc := _sim(14, "plague")
	gc.gain_relic("grave_call")
	gc.rfx["skeleton_return"] = 1.0
	var j := gc.units.spawn(data.card("rat_horde"), gc.hero.x + 5.0, gc.hero.y, 0.0, 0.0, 0, 999)
	gc.kill_unit(j, K.Death.HERO)
	var sk := -1
	for q in gc.units.hi:
		if gc.units.alive[q] == 1 and data.cards[gc.units.def[q]].id == "skeleton":
			sk = q
	check(sk >= 0, "Chamado da Cova: monstro morto volta como Esqueleto")
	if sk >= 0:
		gc.kill_unit(sk, K.Death.HERO)
	var sk2 := 0
	for q in gc.units.hi:
		if gc.units.alive[q] == 1 and data.cards[gc.units.def[q]].id == "skeleton":
			sk2 += 1
	check(sk2 == 0, "Esqueleto da relíquia não volta de novo")
	# Filactério (Lich): o 1º monstro morto pelo herói da vez volta com a vida cheia, uma vez por herói.
	var ph := _sim(15, "lich")
	ph.gain_relic("phylactery")
	var c0 := ph.units.count
	var u := ph.units.spawn(data.card("rat_horde"), ph.hero.x + 5.0, ph.hero.y, 0.0, 0.0, 0, 999)
	ph.kill_unit(u, K.Death.HERO)
	check(ph.units.count == c0 + 1, "Filactério: o primeiro monstro volta")
	var u2 := ph.units.spawn(data.card("rat_horde"), ph.hero.x + 5.0, ph.hero.y, 0.0, 0.0, 0, 999)
	ph.kill_unit(u2, K.Death.HERO)
	check(ph.units.count == c0 + 1, "Filactério: só uma vez por herói")
	# Ao pegar: Martelo da Forja, Lima do Funileiro, Tinta de Carimbo, Dízimo de Sangue, Piche.
	var pk := _sim(16, "plague")
	var lv0 := 0
	for c in pk.cards:
		lv0 += c.level
	pk.gain_relic("forge_hammer")
	var lv1 := 0
	for c in pk.cards:
		lv1 += c.level
	check(lv1 == lv0 + int(data.relics["forge_hammer"]["fx"]["pickup_upgrade"]), "Martelo da Forja: +1 nível em 3 cartas (%d → %d)" % [lv0, lv1])
	var cs0 := 0
	for c in pk.cards:
		cs0 += pk.card_cost(c)
	pk.gain_relic("tinker_file")
	var cs1 := 0
	var neg := false
	for c in pk.cards:
		cs1 += pk.card_cost(c)
		neg = neg or c.def.cost_at(c.level) - c.discount < 0
	check(cs1 == cs0 - 2 and not neg, "Lima do Funileiro: 2 cartas custam 1 a menos (%d → %d)" % [cs0, cs1])
	var md0 := _mods_total(pk)
	pk.gain_relic("stamp_ink")
	check(_mods_total(pk) == md0 + 2, "Tinta de Carimbo: 2 modificadores em cartas do baralho")
	var hp0 := pk.hero.hp
	pk.gain_relic("blood_tithe")
	check(is_equal_approx(pk.hero.hp, hp0 - pk.hero.max_hp() * 0.05), "Dízimo de Sangue: o herói perde 5% da vida máxima")
	pk.gain_relic("tar_pit")
	check(is_equal_approx(pk.hero_speed_mult(pk.hero), 0.75), "Piche: herói da vez 25% mais lento")
	SaveGame.save(pk, "user://test.save")
	var c2 := SaveGame.load_run(data, "user://test.save")
	var disc0 := 0
	var disc1 := 0
	for c in pk.cards:
		disc0 += c.discount
	for c in c2.cards:
		disc1 += c.discount
	check(c2.relics == pk.relics and disc0 == disc1 and c2.slow_hero == pk.slow_hero, "relíquias novas vão no salvamento")
	pk._hero_fell()
	check(is_equal_approx(pk.hero_speed_mult(pk.hero), 1.0), "Piche: o herói seguinte vem normal")
	# Cofre Vivo e Tesouro de Ato (Dragão).
	var dg := _sim(17, "dragon")
	dg.gain_relic("living_vault")
	dg.gold = 1000.0
	var dm := dg.elixir_max
	dg._pay(250)
	check(is_equal_approx(dg.elixir_max, dm + 2.0), "Cofre Vivo: cada 100 de ouro gasto dá +1 de máximo")
	dg.gain_relic("act_hoard")
	var gd0 := dg.gold
	dg._next_act()
	check(dg.gold >= gd0 + 80.0 - 0.01, "Tesouro de Ato: +80 de ouro no começo do ato")
	# Loja vende 1 relíquia, com o preço da raridade.
	var sh := _sim(18, "plague")
	sh.gold = 2000.0
	sh._open_shop()
	var rk := -1
	var opts: Array = sh.offers[0]["options"]
	for k in opts.size():
		if opts[k]["item"]["kind"] == "relic":
			rk = k
	check(rk >= 0, "loja tem 1 relíquia à venda")
	if rk >= 0:
		var rid: String = opts[rk]["item"]["id"]
		var want := int(data.rules["shop"]["relic_prices"][str(data.relics[rid]["rarity"])])
		check(int(opts[rk]["price"]) == want and sh.choose(rk) and sh.relics.has(rid), "relíquia da loja: preço da raridade (%d) e compra" % want)
	SaveGame.save(v, "user://test.save")
	var c3 := SaveGame.load_run(data, "user://test.save")
	check(is_equal_approx(c3.elixir_max, v.elixir_max), "ganho de máximo da Marca da Vitória vai no salvamento")
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
				3: s._offer_level()
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


func t_offer_upgrades() -> void:
	# Oferta de carta já melhorada (11/11/2026): p = 0 → sempre nível 1; p = 1 → sempre 2+; um nível só por oferta.
	var lo := {}
	var hi := {}
	var l3 := 0
	var mixed := 0
	for seed_ in range(1, 60):
		var s := _sim(seed_)
		lo[s.roll_offer_level(false, 0.0)] = true
		var lv := s.roll_offer_level(false, 1.0)
		hi[lv] = true
		if lv == 3:
			l3 += 1
		# Oferta de verdade: no começo do ato 1 tudo nível 1; no fim do ato 3, tudo 2+; todas as cartas no mesmo nível.
		s.act = 0
		s.hero.s = 0.0
		check(is_equal_approx(s.run_progress(), 0.0), "progresso da run é 0 no começo do ato 1")
		var o0: Array = s._card_options(3, func(_cd: CardDef): return true)
		s.act = s.acts() - 1
		s.act_pending = true
		check(is_equal_approx(s.run_progress(), 1.0), "progresso da run é 1 no fim do ato 3")
		var o1: Array = s._card_options(3, func(_cd: CardDef): return true)
		for o in o0:
			if int(o["level"]) != 1:
				mixed += 1
		var lv1 := int(o1[0]["level"]) if o1.size() > 0 else 2
		for o in o1:
			if int(o["level"]) < 2 or int(o["level"]) != lv1:
				mixed += 1
	check(lo.size() == 1 and lo.has(1), "oferta com p = 0: sempre nível 1")
	check(not hi.has(1) and l3 > 5 and l3 < 55, "oferta com p = 1: sempre nível 2+, e nível 3 em parte (%d de 59)" % l3)
	check(mixed == 0, "todas as cartas de uma oferta têm o mesmo nível (e o nível esperado no começo e no fim da run)")
	# O nível da opção vira o nível da carta no deck; loja cobra o upgrade por nível extra.
	var s2 := _sim(3)
	var c: CardDef = s2._pick_card(func(_cd: CardDef): return true, [])
	var n0 := s2.cards.size()
	s2._apply_option({"kind": "card", "id": c.id, "level": 3})
	check(s2.cards.size() == n0 + 1 and s2.cards[s2.cards.size() - 1].level == 3, "carta oferecida no nível 3 entra no deck no nível 3")
	s2.act = s2.acts() - 1
	s2.act_pending = true
	s2.offers.clear()
	s2._open_shop()
	var ok_price := true
	for it in s2.offers[0]["options"]:
		if it["item"]["kind"] == "card":
			var cd: CardDef = data.card(it["item"]["id"])
			var want := int(data.rules["shop"]["prices"][K.RARITIES[cd.rarity]]) + int(data.rules["shop"]["card_upgrade"]) * (int(it["item"]["level"]) - 1)
			if int(it["price"]) != want:
				ok_price = false
	check(ok_price, "loja: carta melhorada custa a raridade + o preço do upgrade por nível extra")
	# Fim de ato: a oferta de carta vem antes das relíquias, com 3 opções do mesmo nível 2+ (fim do ato 3).
	var e := _sim(9)
	e.act = e.acts() - 1
	e._end_act()
	var oc: Dictionary = e.offers[0]
	check(e.offers.size() == 2 and oc["source"] == "act_card" and e.offers[1]["source"] == "relic", "fim de ato: carta primeiro, relíquias depois")
	check(oc["options"].size() >= 1 and int(oc["options"][0]["level"]) >= 2, "fim de ato: as cartas já vêm melhoradas no fim da run")
	var hp0 := e.cards.size()
	check(e.choose(0) and e.cards.size() == hp0 + 1 and e.offers[0]["source"] == "relic", "fim de ato: escolher a carta a põe no deck e libera a relíquia")


func t_shrine_blessed() -> void:
	# Santuário: cada herói do círculo ganha uma barreira (10% da vida máxima); o dano continua valendo;
	# ao fim do desafio só o valor concedido sai.
	var s := _at_location("shrine")
	var frac := float(data.rules["locations"]["shrine"]["ward_frac"])
	var want: float = s.hero.max_hp() * frac
	check(absf(s.hero.ward - want) < 0.01 and want > 0.0, "Santuário: barreira de %.0f%% da vida máxima (%.1f)" % [frac * 100.0, s.hero.ward])
	s.hero.ward += 7.0   # barreira de outra fonte: tem de sobrar
	var hp0 := s.hero.hp
	s.hero.ward = 0.0 + 7.0 + want
	s.damage_hero(want + 20.0, 0.0, 0.0, 0, SimHero.DMG_AREA, "ogre")
	check(s.hero.hp < hp0 + 0.001 and s.hero.hp >= 0.0, "Santuário: o dano não é mais zerado")
	s.hero.ward = want + 7.0
	s._resolve_contest(0)
	check(absf(s.hero.ward - 7.0) < 0.01 and not s.contest.has("ward_given"), "Santuário: ao fim só a barreira concedida sai (%.2f)" % s.hero.ward)
	var hp1 := s.hero.hp
	s.damage_hero(10.0, 0.0, 0.0, 0, SimHero.DMG_AREA, "ogre")
	check(s.hero.hp <= hp1, "fora da disputa o herói leva dano normal")


func t_hero_knockback_mult() -> void:
	var s := _sim_tough(1)
	var h: SimHero = s.hero
	h.knockback(h.x - 1.0, h.y, 4.0)
	var mult := float(data.rules["hero"]["knockback_mult"])
	var spd := Vector2(h.kb_x, h.kb_y).length() * h.kb_t
	check(absf(spd - 4.0 * mult) < 0.05 and mult < 1.0, "Empurrão do herói: distância x%.2f (%.2f)" % [mult, spd])


func t_explosive_hp_frac() -> void:
	var f := float(data.modifiers["explosive"]["p"]["hp_frac"])
	check(is_equal_approx(f, 0.15) and not data.modifiers["explosive"]["p"].has("damage"), "Explosivo: dano ao herói é fração da vida do monstro")


func t_mod_effects() -> void:
	# Modificador sem efeito nunca é sorteado: Amaldiçoado só em feitiço que maldiz, Barato só com custo > 0.
	var s := _sim(5)
	var bad := 0
	var seen := 0
	for n in 400:
		var o: Dictionary = s._mod_option([])
		if o.is_empty():
			continue
		seen += 1
		var d: CardDef = data.card(str(o["card"]))
		if not s.mod_has_effect(d, str(o["mod"])):
			bad += 1
		if str(o["mod"]) == "cursed" and d.is_spell and not CardDef.CURSE_SPELLS.has(d.id):
			bad += 1
		if str(o["mod"]) == "cheap" and d.cost <= 0:
			bad += 1
	check(seen > 50 and bad == 0, "Modificador sem efeito nunca sorteado (%d ofertas, %d inválidas)" % [seen, bad])
	check(not s.mod_has_effect(data.card("soul_feast"), "cursed"), "Maldição não é oferecida a feitiço que não maldiz")


func t_roads_curved() -> void:
	# Estradas em curva (19/11/2026): 200 sementes x atos, nenhuma ligação cruza outra (teste geométrico),
	# as rotas têm o mesmo comprimento, os rios têm ponte em locais Ponte, e os pontos seguem o contrato (passo curto).
	var cross := 0
	var bad_len := 0
	var bad_bridge := 0
	var long_step := 0
	var maps := 0
	for seed_ in range(1, 201):
		var act_ := seed_ % 3
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_ * 7919
		var road := SimRoad.new()
		road.generate(rng, data.rules, data.rules["acts"][act_].get("road", {}))
		maps += 1
		var bridges: Array = []
		for rv in road.rivers:
			bridges.append_array(rv["bridges"])
		for i in road.legs.size():
			var A: PackedVector2Array = road.legs[i]["pts"][0]
			for k in A.size() - 1:
				if A[k].distance_to(A[k + 1]) > 12.0:
					long_step += 1
			for j in range(i + 1, road.legs.size()):
				if road.polylines_cross(A, road.legs[j]["pts"][0], 0.6, bridges, 12.1):
					cross += 1
		var paths := _all_paths(road)
		var l0 := _path_len(road, paths[0])
		for p in paths:
			if absf(_path_len(road, p) - l0) > 1.0:
				bad_len += 1
		for rv in road.rivers:
			for n in rv["bridges"]:
				if road.nodes[n]["loc"] >= 0 and str(road.locations[road.nodes[n]["loc"]]["type"]) != "bridge":
					bad_bridge += 1
	# Sem violações novas (obs. de 17/11: a estrada antiga, em trechos retos, já cruzava): a linha de base medida nos mesmos
	# 200 mapas era 132 cruzamentos em 70 mapas; a curva com desvio para fora mede 97.
	check(cross <= 132, "estradas em curva: sem cruzamentos novos em %d mapas (%d, base antiga 132)" % [maps, cross])
	check(bad_len == 0, "estradas em curva: rotas de igual comprimento (%d fora)" % bad_len)
	check(bad_bridge == 0, "estradas em curva: rios com ponte nos locais Ponte (%d erros)" % bad_bridge)
	check(long_step == 0, "estradas em curva: pontos reamostrados em passo curto (%d trechos longos)" % long_step)


func t_give_notice() -> void:
	# Efeitos "give" de evento (Encruzilhada, Fonte): emitem GIVE e, com a HUD, abrem o aviso com as cartas reais.
	var s := _sim(4)
	s.notify_gives = true
	s.record_events = true
	var n0 := s.cards.size()
	Effects.run(s, [{"kind": "upgrade", "give": true, "n": 1}, {"kind": "remove", "give": true}, {"kind": "card", "give": true, "n": 1}])
	var evs := 0
	for e in s.events:
		if int(e[0]) == K.Ev.GIVE:
			evs += 1
	check(evs == 3, "efeito give emite o evento GIVE (%d)" % evs)
	check(s.offers.size() == 1 and s.offers[0]["source"] == "give" and s.offers[0]["options"].size() == 3, "o aviso junta as 3 mudanças numa oferta")
	check(s.cards.size() == n0, "o aviso não muda o baralho de novo (%d → %d)" % [n0, s.cards.size()])
	check(s.choose(Sim.SKIP) and s.offers.is_empty(), "Continuar fecha o aviso")
	var q := _sim(4)
	Effects.run(q, [{"kind": "upgrade", "give": true, "n": 1}])
	check(q.offers.is_empty(), "sem HUD (bots) nenhum aviso é aberto")


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


func t_soul_absorb_cooldown() -> void:
	# "Absorver Almas" cura uma vez por recarga, não a cada morte (o enxame não pode deixar o herói imortal).
	var s := _sim_tough(7)
	s.hero.apply_upgrade("soul_absorb")
	var cd := float(data.upgrades["soul_absorb"]["p"]["cooldown"])
	s.hero.hp = s.hero.max_hp() * 0.5
	var hp0 := s.hero.hp
	var ids := _spawn_near(s, "rat", 3)
	for i in ids:
		s.kill_unit(i, K.Death.HERO)
	var once := s.hero.max_hp() * float(data.upgrades["soul_absorb"]["p"]["heal"])
	check(absf(s.hero.hp - hp0 - once) < 0.01, "Absorver Almas: 3 mortes juntas curam uma vez só (+%.1f, esperado %.1f)" % [s.hero.hp - hp0, once])
	var st := s.hero.ability_state("soul_absorb")
	check(st.y == cd and st.x > 0.0, "HUD mostra a recarga do Absorver Almas (%.1f de %.1f)" % [st.x, st.y])
	s.hero.absorb_t = 0.0
	var hp1 := s.hero.hp
	s.kill_unit(_spawn_near(s, "rat", 1)[0], K.Death.HERO)
	check(s.hero.hp > hp1, "Absorver Almas volta a curar depois da recarga")


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


## Fase de teste de fila antiga (cada herói é uma party sozinha), para os testes que olham a queda herói a herói.
## 95: 5 Escudeiros; 96: Clériga e Escudeiros; 97: Escudeiro e Arqueira alternados (como eram as fases 2 e 3 de antes).
func _legacy_sim(seed_: int, id: int, deck := "horde") -> Sim:
	if data.phase(id).is_empty():
		var lists := {
			95: ["escudeiro", "escudeiro", "escudeiro", "escudeiro", "escudeiro"],
			96: ["cleriga", "escudeiro", "cleriga", "arqueira", "escudeiro", "cleriga", "escudeiro"],
			97: ["escudeiro", "arqueira", "escudeiro", "arqueira", "escudeiro", "arqueira", "escudeiro"],
			98: ["escudeiro", "arqueira", "cleriga", "mago", "escudeiro", "arqueira"],
		}
		var ph := {"id": id, "key": "TEST_%d" % id, "party": lists[id], "hp_mult": 1.5 if id == 98 else 2.6}
		if id == 98:
			ph["group"] = true
			ph["revive_hp"] = 0.5
		data.phases.append(ph)
	var s := Sim.new()
	s.setup(data, seed_, deck, [], [], id)
	s.auto_route = true
	return s


## Fase de teste com a fila da antiga Fase 4 (a Companhia, 15/11/2026): a campanha de 16/11/2026 mudou a fase 4,
## e os testes de parties precisam desta fila fixa.
func _companhia() -> int:
	if data.phase(93).is_empty():
		data.phases.append({"id": 93, "key": "TEST_93", "parties": [["escudeiro"], ["guardiao", "cleriga", "mago", "assassino"], ["arqueira"]], "hp_mult": 1.5})
	return 93


func _phase_sim(n: int, seed_ := 7) -> Sim:
	var s := Sim.new()
	s.setup(data, seed_, "horde", [], [], n)
	s.auto_route = true
	return s


## Fase de grupo com dois heróis colados: o da vez e um seguidor a 1 m.
func _two_heroes() -> Sim:
	var s := _legacy_sim(7, 98)
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
	# O bot humano termina o tutorial (0) e a fase única de 15 parties (1) sem travar e sem jogada recusada em excesso.
	for ph in [0, 1]:
		var s := Sim.new()
		s.setup(data, 21, "ruin", [], [], ph)
		s.auto_route = false
		var b := PlayerBot.load_bot("human", 21)
		var k := 0
		while s.phase != K.Phase.OVER and k < 80000:
			b.think(s)
			s.step()
			k += 1
		var st: Dictionary = (b as HumanBot).stats
		# Na fase única o bot sem meta pode chegar ao teto de tempo da run (rules.sim.max_run_seconds, 3000 s): isso é um fim limpo.
		check(s.phase == K.Phase.OVER and (ph == 1 or s.stats["result"] != "timeout"), "bot humano termina a fase %d (%s em %.0f s, %d jogadas, %d parties)" % [ph, s.stats["result"], s.t, st["plays"], s.parties_beaten()])
		check(st["refused"] <= st["plays"] * 0.05 + 2, "bot humano quase nunca tem jogada recusada (%d de %d)" % [st["refused"], st["plays"]])


func t_classes() -> void:
	var s := _legacy_sim(7, 97)
	check(s.party_size() == 7 and s.party_class(1) == "arqueira", "fila alterna Escudeiro e Arqueira")
	s.offers.clear()
	s.hero.hp = 0.0
	s._check_end()
	check(s.hero.cls() == "arqueira" and float(s.hero.H["attack_range"]) >= 6.0 and s.hero.shield_max <= 0.0, "Arqueira ataca de longe e não tem escudo")
	check(float(s.hero.H.get("cleave_arc", 0.0)) <= 0.0 and str(s.hero.H.get("projectile", "")) == "arrow",
		"Arqueira não herda o golpe em arco do Escudeiro e atira flecha")
	check(float(data.hero_of("mago")["cleave_arc"]) <= 0.0 and float(data.hero_of("escudeiro")["cleave_arc"]) > 0.0,
		"Só o Escudeiro varre em arco")
	s.offers.clear()
	s.record_events = true
	_spawn_near(s, "rat_horde", 1)
	s.events.clear()
	var hshots := 0
	for i in 300:
		s.step()
		for e in s.events:
			if int(e[0]) == K.Ev.HERO_SHOT:
				hshots += 1
		s.events.clear()
	check(hshots > 0, "Herói à distância emite o projétil (HERO_SHOT) ao atacar (%d)" % hshots)
	var sh := _legacy_sim(7, 97)
	sh.hero.apply_upgrade("tower_shield")
	var sh_max: float = sh.hero.shield_max
	check(sh_max > float(sh.hero.H["shield"]["hp"]), "Escudo de Torre aumenta o escudo")
	sh.hero.next_hero(2)
	check(is_equal_approx(sh.hero.shield_max, sh_max), "Escudo de Torre (habilidade do grupo) vale também para o herói seguinte com escudo")
	var s3 := _legacy_sim(7, 96)
	check(s3.hero.cls() == "cleriga", "fila começa com a Clériga")
	s3.hero.hp = s3.hero.max_hp() * 0.5
	var hp_before: float = s3.hero.hp
	for i in 40:
		s3.hero.update(s3.dt)
	check(is_equal_approx(s3.hero.hp, hp_before), "Clériga não se cura mais com o tempo")
	var wc: Dictionary = s3.hero.H["ward_cast"]
	check(is_equal_approx(s3.hero.ward, hp_before * float(wc["pct"])), "Clériga conjura escudo de %.1f%% da vida atual em si (%.2f)" % [float(wc["pct"]) * 100.0, s3.hero.ward])
	var w1: float = s3.hero.ward
	for i in int(2.0 / s3.dt):
		s3.hero.update(s3.dt)
	check(is_equal_approx(s3.hero.ward, w1), "Clériga: escudo só de novo depois da recarga (5 s)")
	for i in int(4.0 / s3.dt):
		s3.hero.update(s3.dt)
	check(s3.hero.ward > w1 * 1.5, "Clériga: conjura outro escudo passada a recarga (%.2f)" % s3.hero.ward)
	s3.offers.clear()
	var base2: float = float(data.hero_of(s3.party_class(1), s3.phase_hp_mult)["hp"]) * pow(float(data.rules["party"]["step"]), 1) * float(data.rules.get("hero_hp_mult", 1.0))
	s3.hero.hp = 0.0
	s3._check_end()
	check(s3.hero.max_hp() > base2 * 1.15, "a bênção da Clériga dá vida ao próximo (%.0f > %.0f)" % [s3.hero.max_hp(), base2])
	var s4 := _phase_sim(_companhia())
	check(s4.party_class(3) == "mago", "o 4º herói da Fase 4 é o Mago")
	check(s4.party_mode() and s4.party_count() == 3 and s4.party_size() == 6, "a Fase 4 é uma fila de 3 parties (6 heróis)")
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
	check(s0.party_size() == 3 and s0.party_count() == 2 and s0.acts() == 1 and s0.hero.max_hp() < float(data.hero["hp"]) * 0.6, "tutorial: 3 Escudeiros fracos e 1 ato")
	# Plano 21/11/2026: só o tutorial (fase 0) e a fase única de 15 parties.
	var ids: Array = []
	var maps_ok := true
	for ph in data.phases:
		if int(ph["id"]) >= 90:
			continue
		ids.append(int(ph["id"]))
		maps_ok = maps_ok and str(ph.get("region", "")) != ""
	check(ids == [0, 1], "a campanha é o tutorial (0) e a fase única (1) (%s)" % str(ids))
	check(maps_ok, "tutorial e fase única têm região")
	var p15: Array = data.phase(1)["parties"]
	check(p15.size() == 15 and p15[14].size() >= p15[0].size() and data.phase(1).has("unlock_villain_at"), "a fase única tem a fila fixa de 15 parties e libera vilões por party")


## Fila de parties (15/11/2026): grupos de 1 a 4 heróis; cada queda dá recompensa; a party seguinte chega junta.
func t_parties() -> void:
	var s := _phase_sim(_companhia())   # [escudeiro] [guardiao, cleriga, mago, assassino] [arqueira]
	check(s.party_mode() and s.party_count() == 3 and s.party_size() == 6, "Fase 4: 3 parties, 6 heróis")
	check(s.followers.size() == 0 and s.hero.cls() == "escudeiro", "a party 1 é só o Escudeiro")
	check(s.party_n_of(1) == 4 and s.party_n_of(0) == 1 and s.party_n_of(5) == 1, "tamanho de cada party")
	var solo_hp: float = s.hero.max_hp()
	s.offers.clear()
	s.hero.hp = 0.0
	s._check_end()
	check(s.cur_party == 1 and s.followers.size() == 3, "a party 2 chega inteira: 1 líder e 3 membros (%d)" % s.followers.size())
	check(s.hero.cls() == "guardiao" and s.followers[0].cls() == "cleriga" and s.followers[1].cls() == "mago" and s.followers[2].cls() == "assassino",
		"a party 2 vem na ordem escrita")
	check(s.powers.size() == 1 and s.party_powers().size() == 1, "o poder novo é da party toda (lista única de poderes)")
	var step := float(data.rules["party"]["step"])
	var want: float = float(data.hero_of("assassino", s.phase_hp_mult)["hp"]) * step * float(data.rules.get("hero_hp_mult", 1.0)) / 4.0
	check(absf(s.followers[2].max_hp() - want) < 1.0, "a força da party é dividida entre os 4 membros (%.0f = %.0f)" % [s.followers[2].max_hp(), want])
	check(s.hero.level == 2 and int(s.stats["heroes_fallen"]) == 1, "party 2 = nível 2; 1 queda contada")
	check(s.offers.size() > 0, "a queda do último da party 1 abre recompensa")
	# Um membro cai com gente ainda de pé: recompensa, habilidade e ninguém novo chega.
	s.offers.clear()
	var n0 := s.powers.size()
	s.followers[1].hp = 0.0   # o Mago
	s._check_end()
	check(s.followers.size() == 2 and s.cur_party == 1, "o Mago caiu e a party 2 segue com 3 de pé")
	check(s.offers.is_empty() and s.powers.size() == n0,
		"membro que cai não dá recompensa nem poder (só a party inteira; oferta por herói é melhoria do Covil)")
	check(int(s.stats["heroes_fallen"]) == 2, "queda do membro conta (%d)" % int(s.stats["heroes_fallen"]))
	# O líder cai: o seguinte assume o lugar dele.
	s.offers.clear()
	var next_cls: String = s.followers[0].cls()
	var next_hp: float = s.followers[0].hp
	s.hero.hp = 0.0
	s._check_end()
	check(s.hero.cls() == next_cls and absf(s.hero.hp - next_hp) < 1.0 and s.followers.size() == 1 and s.cur_party == 1,
		"o líder caiu: o Clériga assume (%s, %d seguidores)" % [s.hero.cls(), s.followers.size()])
	# Só sobra o Assassino e ele cai também: chega a party 3 (Arqueira), sem seguidores.
	s.offers.clear()
	s.hero.hp = 0.0
	s._check_end()
	check(s.hero.cls() == "assassino" and s.followers.size() == 0, "sobrou o Assassino")
	s.offers.clear()
	s.hero.hp = 0.0
	s._check_end()
	check(s.cur_party == 2 and s.hero.cls() == "arqueira" and s.followers.size() == 0, "a party 3 chega sozinha")
	check(s.hero.max_hp() > solo_hp * 1.15, "a party 3 é mais forte que a 1 (%.0f > %.0f)" % [s.hero.max_hp(), solo_hp])
	check(s.phase != K.Phase.OVER, "a run continua")
	s.offers.clear()
	s.hero.hp = 0.0
	s._check_end()
	check(s.phase == K.Phase.OVER and str(s.stats["result"]) in ["win", "win_early"] and int(s.stats["heroes_fallen"]) == 6,
		"a última party cai: vitória com 6 quedas (%s, %d)" % [str(s.stats["result"]), int(s.stats["heroes_fallen"])])
	# Salvar e continuar no meio de uma party de 4.
	var m := _phase_sim(_companhia())
	m.offers.clear()
	m.hero.hp = 0.0
	m._check_end()
	var path := "user://test_party.save"
	check(SaveGame.save(m, path), "salva a run no meio da party 2")
	var ld := SaveGame.load_run(data, path)
	check(ld != null and ld.followers.size() == 3 and ld.cur_party == 1 and ld.party_n_of(1) == 4 and ld.hero.cls() == "guardiao",
		"continuar mantém a party (%d seguidores)" % (ld.followers.size() if ld else -1))
	SaveGame.erase(path)
	# Run completa de ponta a ponta com o bot, em todas as fases.
	for ph in [1, 2, 3, 4]:
		var r := Sim.new()
		r.setup(data, 31 + ph, "horde", [], [], ph)
		r.auto_route = true
		var bot := PlayerBot.load_bot("heuristic", 31 + ph)
		var k := 0
		while r.phase != K.Phase.OVER and k < 70000:
			bot.think(r)
			r.step()
			k += 1
		check(r.phase == K.Phase.OVER, "Fase %d com parties termina com o bot (%s, %d quedas de %d)" % [ph, str(r.stats["result"]), int(r.stats["heroes_fallen"]), r.party_size()])


func t_group() -> void:
	var s := _legacy_sim(7, 98)
	check(s.group_mode(), "fase de grupo antiga (modo de levantar o caído)")
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
	check(ld != null and ld.campaign_phase == 98 and ld.followers.size() == s.followers.size() and ld.hero.cls() == s.hero.cls(),
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
	r.setup(data, 11, "horde", [], [], 98)
	r.auto_route = true
	var bot := PlayerBot.load_bot("heuristic", 11)
	var k := 0
	while r.phase != K.Phase.OVER and k < 60000:
		bot.think(r)
		r.step()
		k += 1
	check(r.phase == K.Phase.OVER, "run completa da fase de grupo com o bot termina (%s em %.0f s, %d quedas)" % [str(r.stats["result"]), r.t, int(r.stats["heroes_fallen"])])


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
		s._cycle(k % s.hand.size())
		# Recarga da vaga (15/11/2026): a compra chega depois de DRAW_DELAY s.
		for _w in int(ceil(Sim.DRAW_DELAY / s.dt)) + 1:
			s._tick_draws()
		ok = ok and _deck_total(s) == s.cards.size() and s.hand.size() == mini(s.hand_size, s.cards.size())
		reshuffled = reshuffled or int(s.stats.get("shuffles", 0)) > 0
	check(ok, "ciclo compra/mão/descarte conserva as cartas (%d)" % s.cards.size())
	check(reshuffled, "descarte é embaralhado quando a compra acaba")
	# Recarga: a vaga jogada fica vazia por DRAW_DELAY s e só então recebe carta.
	var w := _sim(3, "treasure")
	w._cycle(0)
	var empty_now := w.hand[0] == null and w.hand.size() == mini(w.hand_size, w.cards.size())
	for _w in int(Sim.DRAW_DELAY / w.dt) - 2:
		w._tick_draws()
	var still_empty := w.hand[0] == null and w.wait_left(0) > 0.0
	for _w in 4:
		w._tick_draws()
	check(empty_now and still_empty and w.hand[0] != null, "carta jogada: a vaga espera %.1f s antes da compra" % Sim.DRAW_DELAY)
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
	a.queue.append(a._new_inst(data.card("gold_bait")))   # o baralho base do Dragão não traz mais carta de Rota
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
	_steps_free(s, 31.0)
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
	check(is_equal_approx(s.gold, 100.0 - float(data.card("blood_tax").fx["gold_cost"])), "Imposto de Sangue paga o gold_cost em ouro (%.0f)" % s.gold)
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
	for k in 4:   # golpes de 0,25 s rendem 1/4 do ouro: o ouro por segundo é o de antes
		_hit(s, kb[0])
		_hit(s, kb[1])
	check(s.gold > g0 + 1.9, "os golpes dos Kobolds rendem ouro (%.1f)" % (s.gold - g0))
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
	check(absf(tg0 - 1020.0) < 1.0 and absf(tg1 - 1520.0) < 1.0, "Guarda do Tesouro: 1020 de vida, +500 com 100 de ouro (%.0f → %.0f)" % [tg0, tg1])
	# Guarda do Tesouro: cada um vivo gasta 10 de ouro por segundo; o ouro para em 0.
	s.gold = 100.0
	var gg0 := s.gold
	s.dt = 0.5
	CardsDragon.on_tick(s)
	check(absf((gg0 - s.gold) - 10.0) < 0.01, "Guarda do Tesouro: 2 vivos gastam 10 de ouro em 0,5 s (%.1f)" % (gg0 - s.gold))
	s.gold = 3.0
	CardsDragon.on_tick(s)
	check(s.gold == 0.0, "Guarda do Tesouro: o ouro não fica negativo (%.1f)" % s.gold)
	# Custo em ouro: Moedas Amaldiçoadas (15) e Batedor Goblin (30) ficam bloqueados sem ouro e cobram ao jogar.
	for gc in [["cursed_coins", 15.0], ["goblin_scout", 30.0], ["coin_swarm", 15.0], ["gold_rain", 40.0], ["gilded_golem", 35.0], ["hoard_dragon", 120.0]]:
		var sg := _sim(5, "dragon")
		sg.elixir = 20.0
		sg.hand[0] = _inst(gc[0])
		sg.gold = gc[1] - 1.0
		var blocked: bool = sg.can_play(0) == K.Block.CONDITION
		sg.gold = gc[1] + 5.0
		var r := sg.play(0, sg.hero.x + 8.0, sg.hero.y)
		check(blocked and r == K.Block.OK and is_equal_approx(sg.gold, 5.0), "%s: custa %.0f de ouro (bloqueada sem: %s, sobrou %.1f)" % [gc[0], gc[1], blocked, sg.gold])
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
	# Cálice Profundo: +4 de elixir máximo e +20% de geração por 40 s (sem elixir na hora).
	var s5 := _sim(9)
	var m0 := s5.elixir_max
	s5.elixir = 3.0
	s5._apply(_inst("deep_chalice"), s5.hero.x, s5.hero.y)
	check(is_equal_approx(s5.elixir_max, m0 + 4.0) and is_equal_approx(s5.elixir, 3.0) and is_equal_approx(s5.temp_sum("elixir_regen"), 0.2),
		"Cálice Profundo: máximo %.0f → %.0f, elixir %.1f, geração +%.0f%%" % [m0, s5.elixir_max, s5.elixir, s5.temp_sum("elixir_regen") * 100.0])
	s5.t += 41.0
	s5._temps()
	check(is_equal_approx(s5.elixir_max, m0) and is_equal_approx(s5.temp_sum("elixir_regen"), 0.0), "Cálice Profundo expira (máximo %.0f)" % s5.elixir_max)
	# Ritual Profano: sacrifica 1 monstro; os próximos feitiços custam 1 a menos e depois voltam ao normal.
	var s6 := _sim(10, "lich")
	_tough(s6)
	var rv_ := _spawn(s6, "ghoul")
	var bolt := _inst("shadow_bolt")
	var c0 := s6.card_cost(bolt)
	s6._apply(_inst("profane_ritual"), s6.hero.x + 0.5, s6.hero.y)
	# O monstro sacrificado também arma o Ciclo de feitiço (passiva do Lich): os dois descontos somam no jogo.
	check(s6.cycle_spell and s6.card_cost(bolt) == c0 - 2, "Ritual Profano + Ciclo de feitiço somam (%d → %d)" % [c0, s6.card_cost(bolt)])
	s6.cycle_spell = false   # daqui em diante, só o Ritual
	check(s6.units.alive[rv_[0]] == 0 and s6.card_cost(bolt) == c0 - 1, "Ritual Profano sacrifica e baixa o custo (%d → %d)" % [c0, s6.card_cost(bolt)])
	for i in 3:
		CardsLich.on_card_played(s6, bolt, s6.hero.x, s6.hero.y)
	check(s6.card_cost(bolt) == c0, "Ritual Profano acaba depois de 3 feitiços")
	# Cultistas: enquanto há algum vivo, todo feitiço custa 1 a menos (fixo, não soma por cultista nem por feitiço).
	var sc := _sim(12)
	_tough(sc)
	var cb := _inst("shadow_bolt")
	var cc0 := sc.card_cost(cb)
	_spawn(sc, "cultists")
	sc.step()
	check(sc.card_cost(cb) == maxi(0, cc0 - 1), "Cultistas: feitiço custa 1 a menos (%d → %d)" % [cc0, sc.card_cost(cb)])
	_spawn(sc, "cultists")
	sc.step()
	for i in 4:
		CardsLich.on_card_played(sc, cb, sc.hero.x, sc.hero.y)
	check(sc.card_cost(cb) == maxi(0, cc0 - 1), "Cultistas: desconto não acumula (2 grupos, 4 feitiços)")
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
	# Golpes rápidos (0,25 s) rendem fração de acúmulo: 4 golpes = 1 acúmulo, o mesmo ritmo por segundo de antes.
	for k in 3:
		_hit(s, br[0])
	check(CardsPlague.peste_of(s, s.hero) == 1, "Ratazana: 4 golpes de 0,25 s = 1 acúmulo de Peste")
	for k in 19:
		_hit(s, br[0])
	var d5 := _hit(s, br[0])
	check(CardsPlague.peste_of(s, s.hero) == 6 and d5 > d0 * 1.15, "Peste: cada acúmulo aumenta o dano recebido (%.1f → %.1f)" % [d0, d5])
	CardsPlague.add_peste(s, s.hero, 40)
	check(CardsPlague.peste_of(s, s.hero) == 30, "Peste: teto de 30 acúmulos")
	s.kill_unit(br[0], K.Death.EXPIRE)
	for i in int(round(7.0 / s.dt)):
		s.step()
	check(CardsPlague.peste_of(s, s.hero) == 30, "Peste: ainda vale antes de 8 s sem mordida")
	for i in int(round(3.0 / s.dt)):
		s.step()
	var pd := CardsPlague.peste_of(s, s.hero)
	check(pd >= 27 and pd <= 29, "Peste: depois de 8 s cai 1 acúmulo por segundo (%d)" % pd)
	for i in int(round(32.0 / s.dt)):
		s.step()
	check(CardsPlague.peste_of(s, s.hero) == 0, "Peste: some aos poucos até zerar")
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
	for k in 4:
		_hit(s, rr[0])
	check(CardsPlague.peste_of(s, s.hero) == 1, "Mordida Infectada: mordida de Bando aplica +1 Peste (por segundo de golpes)")
	# Praga Bubônica: toda mordida aplica Peste; no fim, dano por acúmulo.
	s = _sim(5, "plague")
	_pl_still(s)
	rr = _pl(s, "rat_horde")
	s._apply(_inst("bubonic_plague"), s.hero.x, s.hero.y)
	for k in 8:
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
	s.deck_rules["infestation"] = 0.0   # a Infestação (rato extra ao acaso) mascarava a contagem
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


## Herói Ajudante (11/11/2026): 1 por ato num ramo de bifurcação, para o herói da vez, matar dá relíquia,
## falhar dá o bônus da classe, e a morte dele não é queda de herói do grupo.
func t_helper() -> void:
	var R: Dictionary = data.rules
	var hr: Array = R["road"]["helper_rows"]
	var ok := true
	var info := ""
	for sd in range(1, 41):
		for a in 3:
			var cfg: Dictionary = R["acts"][a].get("road", {}) if R.get("acts", []).size() > a else {}
			var rng := RandomNumberGenerator.new()
			rng.seed = sd * 7 + a
			var road := SimRoad.new()
			road.generate(rng, R, cfg)
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = sd * 7 + a
			var road2 := SimRoad.new()
			road2.generate(rng2, R, cfg)
			var n := 0
			var shops := 0
			for li in road.locations.size():
				var loc: Dictionary = road.locations[li]
				if loc["type"] != road2.locations[li]["type"]:
					ok = false
					info = "semente %d ato %d: mapa muda com a mesma semente" % [sd, a + 1]
				if loc["type"] == "shop":
					shops += 1
				if loc["type"] == "helper":
					n += 1
					var row: int = road.nodes[loc["node"]]["row"]
					var mates := 0
					for nd in road.nodes:
						if int(nd["row"]) == row:
							mates += 1
					if row < int(hr[0]) or row > int(hr[1]) or mates < 2:
						ok = false
						info = "semente %d ato %d: ajudante na fileira %d com %d nós" % [sd, a + 1, row, mates]
			if n != int(R["road"]["helpers"]) or shops != 1:
				ok = false
				info = "semente %d ato %d: %d ajudantes, %d lojas" % [sd, a + 1, n, shops]
	check(ok, "estrada: 1 Herói Ajudante por ato numa fileira com bifurcação (3 a 5), 1 Loja, mesma semente = mesmo mapa %s" % info)

	# Chegada: o ajudante aparece parado ao lado do local, de outra classe; o herói da vez para lá.
	var s := _at_location("helper")
	var li := int(s.contest.get("li", -1))
	var p: Vector2 = s.road.locations[li]["pos"]
	check(s.contest.get("type", "") == "helper" and s.helper != null and s.helper.is_helper and s.hero.hold,
		"Herói Ajudante: disputa começa, o ajudante está no local e o herói da vez para")
	check(s.helper != null and s.helper.cls() != s.hero.cls() and is_equal_approx(s.helper.hp, float(R["locations"]["helper"]["hp_act"][0])),
		"Herói Ajudante: classe diferente da do herói da vez e vida do ato 1 (%s, %.0f)" % [s.helper.cls() if s.helper else "-", s.helper.hp if s.helper else 0.0])
	check(s.all_heroes().has(s.helper) and s.heroes_near(s.helper.x, s.helper.y, 1.0).has(s.helper) and s.multi_heroes(),
		"Herói Ajudante: feitiços de área e de grupo o encontram (all_heroes, heroes_near)")
	var spot := Vector2(s.helper.x, s.helper.y)
	var s0 := s.hero.s_max
	var far := 0.0
	var moved := 0.0
	for i in int(10.0 / s.dt):
		s.step()
		far = maxf(far, Vector2(s.hero.x, s.hero.y).distance_to(p))
		if s.helper:
			moved = maxf(moved, Vector2(s.helper.x, s.helper.y).distance_to(spot))
	check(far <= float(R["locations"]["hold_radius"]) + 1.0 and s.hero.s_max <= s0 + 3.0 and s.contest.get("type", "") == "helper",
		"Herói Ajudante: o herói da vez fica parado no local durante a disputa (%.1f m do centro)" % far)
	var hd := Vector2(s.helper.x, s.helper.y).distance_to(Vector2(s.hero.x, s.hero.y)) if s.helper else INF
	check(s.helper != null and hd <= 4.5, "Herói Ajudante: fica junto do herói da vez (%.1f m dele; andou %.1f m)" % [hd, moved])
	# 15/11/2026: monstro a uns metros do ajudante (ao alcance do grupo): ele anda até lá e bate.
	var hp0: float = s.helper.hp
	var hpos := Vector2(s.helper.x, s.helper.y)
	var away := (hpos - Vector2(s.hero.x, s.hero.y)).normalized()
	if away.length() < 0.5:
		away = Vector2(1, 0)
	var op := hpos + away * 4.0
	# O rio pode passar ali: tenta outros ângulos, sempre do lado de fora do ajudante (mais perto dele que do herói da vez).
	for ang in [0.0, 0.5, -0.5, 1.0, -1.0, 0.25, -0.25]:
		op = hpos + away.rotated(ang) * 4.0
		if not s.terra().is_water(op.x, op.y) and not s.terra().is_water((op.x + hpos.x) * 0.5, (op.y + hpos.y) * 0.5) and op.distance_to(Vector2(s.hero.x, s.hero.y)) > hpos.distance_to(op) + 0.5:
			break
	var og := s.units.spawn(data.card("ogre"), op.x, op.y, 0.0, 0.0, 0, 999)
	s.units.hp[og] = 1.0e6
	s.units.max_hp[og] = 1.0e6
	var walked := 0.0
	for i in int(4.0 / s.dt):
		s.step()
		if s.helper:
			walked = maxf(walked, Vector2(s.helper.x, s.helper.y).distance_to(hpos))
	check(walked > 1.0 and s.units.alive[og] == 1 and s.units.hp[og] < 1.0e6,
		"Herói Ajudante: anda até o monstro e bate nele (andou %.1f m; ogro %.0f)" % [walked, s.units.hp[og]])
	check(s.helper != null and s.helper.hp < hp0, "Herói Ajudante: monstro perto dele o ataca (%.0f -> %.0f)" % [hp0, s.helper.hp if s.helper else 0.0])
	# Salva no meio da disputa: a retomada traz o ajudante de volta.
	check(SaveGame.save(s, "user://test_helper.save"), "Herói Ajudante: salva no meio da disputa")
	var c := SaveGame.load_run(data, "user://test_helper.save")
	check(c != null and c.helper != null and c.contest.get("type", "") == "helper" and is_equal_approx(c.helper.hp, s.helper.hp) and c.helper.cls() == s.helper.cls(),
		"Herói Ajudante: carregar no meio da disputa refaz o ajudante (mesma classe e vida)")
	if c:
		_steps(c, 1.0)
	SaveGame.erase("user://test_helper.save")
	# Matar: 1 de 3 relíquias; não conta como herói caído nem sobe nível.
	s.record_events = true
	s.events.clear()
	var fallen0 := int(s.stats["heroes_fallen"])
	var pidx0 := s.party_idx
	var lv0 := s.hero.level
	s.helper.hp = 5.0
	s.hit_hero = s.helper
	s.damage_hero(50.0, s.helper.x, s.helper.y, 0, SimHero.DMG_PIERCE, "test")
	s.hit_hero = null
	s.step()
	var falls := 0
	for ev in s.events:
		if int(ev[0]) == K.Ev.HERO_FALL or int(ev[0]) == K.Ev.HERO_LEVEL:
			falls += 1
	check(s.helper == null and s.contest.is_empty() and not s.hero.hold and s.road.locations[li]["state"] == SimRoad.LocState.WON,
		"Herói Ajudante: morto, a disputa acaba vencida e ele some")
	check(s.offers.size() > 0 and s.offers[-1]["source"] == "relic" and s.offers[-1].get("from", "") == "helper" and s.offers[-1]["options"].size() > 0,
		"Herói Ajudante: matar oferece relíquias")
	check(falls == 0 and int(s.stats["heroes_fallen"]) == fallen0 and s.party_idx == pidx0 and s.hero.level == lv0,
		"Herói Ajudante: a morte dele não é queda de herói do grupo (sem queda, nível nem fila)")
	# Falhar: o tempo acaba e ele vai embora sem dar nada (12/11/2026: sem bônus de classe).
	var t2 := _at_location("helper", 5)
	t2.contest["cls"] = "arqueira"
	t2.helper.base_hp = 1.0e7
	t2.helper.hp = 1.0e7
	_steps_free(t2, float(t2.contest["window"]) + 1.0)
	check(t2.helper == null and t2.contest.is_empty() and t2.offers.is_empty() and t2.hero.bonus_dmg == 0.0,
		"Herói Ajudante: tempo acabou, ele vai embora sem bônus nem recompensa")
	var t3 := _sim(6)
	t3.hero.bonus_dmg = 0.2
	t3.hero.ward = 10.0
	t3.hero.clear_act_bonus()
	check(t3.hero.ward == 0.0 and t3.hero.bonus_dmg == 0.0 and t3.hero.bonus_splash == 0.0, "Herói Ajudante: os bônus acabam no fim do ato")


## Rodada de 13/11/2026: Selvagens, fogo e ouro do Dragão, comuns novas, piso de elixir, pesos e vida única dos heróis.
func t_round_2026_11_13() -> void:
	# --- Vida única dos heróis: o vilão não muda a vida.
	var hp_ref := 0.0
	var same := true
	for vid in data.villain_ids:
		var sv := _sim(3, vid)
		if hp_ref == 0.0:
			hp_ref = sv.hero.base_hp
		same = same and is_equal_approx(sv.hero.base_hp, hp_ref)
		same = same and not data.villain(vid)["rules"].has("hero_hp_mult")
	check(same and hp_ref > 0.0, "heróis têm a mesma vida em todos os vilões (%.0f)" % hp_ref)
	# --- Ratos e morcegos são Bando, nunca Fera.
	var rats_ok := true
	for id in ["rat", "rat_horde", "rabid_rats", "rat_brute", "bat", "bat_cloud", "rat_tide", "rat_king"]:
		if data.card(id).beast:
			rats_ok = false
	check(rats_ok and data.card("lone_wolf").beast and data.card("wolf_pack").beast and not data.card("lone_wolf").tags & K.TAG_PACK, "ratos e morcegos não são Fera; os Selvagens são")
	# --- Alcateia: só Fera conta (Bando não).
	var s := _sim(5, "plague")
	_pl_still(s)
	var w1 := _pl(s, "lone_wolf")
	s.step()
	var d1 := _hit(s, w1[0])
	_pl(s, "rat_horde")
	s.step()
	var d_rats := _hit(s, w1[0])
	check(absf(d_rats - d1) < 0.01, "Alcateia: ratos em campo não contam (%.1f = %.1f)" % [d_rats, d1])
	_pl(s, "wolf_pack")
	s.step()
	var d3 := _hit(s, w1[0])
	check(d3 > d1 * 1.25, "Alcateia: Fera em campo aumenta o dano (%.1f > %.1f)" % [d3, d1])
	# --- Infestação (15/11/2026): qualquer monstro que morre pode deixar um rato; o rato deixado não gera outro.
	s.deck_rules["infestation"] = 1.0
	var n0 := s.units.count
	s.kill_unit(w1[0], K.Death.HERO)
	check(s.units.count == n0, "Infestação: o monstro morre e deixa 1 rato (%d -> %d)" % [n0, s.units.count])
	var rat_i := -1
	for ui in s.units.hi:
		if s.units.alive[ui] != 0 and (s.units.flags[ui] & K.F_INFESTED):
			rat_i = ui
	check(rat_i >= 0, "Infestação: o rato deixado nasce marcado")
	var n1 := s.units.count
	if rat_i >= 0:
		s.kill_unit(rat_i, K.Death.HERO)
	check(s.units.count == n1 - 1, "Infestação: rato deixado pela passiva não gera outro rato")
	s.deck_rules["infestation"] = 0.0
	# --- Caçada do Urso: cada golpe soma dano até o teto.
	s = _sim(5, "plague")
	_pl_still(s)
	var bear := _pl(s, "brown_bear")
	var b0 := _hit(s, bear[0])
	for k in 150:
		_hit(s, bear[0])
	var b1 := _hit(s, bear[0])
	check(b1 > b0 * 1.5 and b1 < b0 * 1.7, "Caçada: dano sobe até o teto de +60%% (%.1f -> %.1f)" % [b0, b1])
	# (Sangue das hienas dependia da Infestação de Fera, removida em 15/11/2026.)
	# --- Bicho Infectado: explode com Peste.
	s = _sim(5, "plague")
	_tough(s)
	var cr := _pl(s, "plague_carrion", 0.2)
	s.kamikaze(cr[0])
	check(CardsPlague.peste_of(s, s.hero) >= 3, "Bicho Infectado: explosão aplica 3 de Peste (%d)" % CardsPlague.peste_of(s, s.hero))
	# --- Pestilência Negra: Peste no máximo e dobra o dano da Peste.
	s = _sim(5, "plague")
	_tough(s)
	CardsPlague.on_card_played(s, _inst("rat_brute"), s.hero.x, s.hero.y)
	CardsPlague.add_peste(s, s.hero, 5.0)
	var pb0 := CardsPlague.hero_damage_bonus(s, s.hero, 0, 0)
	s._apply(_inst("black_pestilence"), s.hero.x, s.hero.y)
	check(CardsPlague.peste_of(s, s.hero) == 30 and CardsPlague.hero_damage_bonus(s, s.hero, 0, 0) > pb0 * 5.0, "Pestilência Negra: Peste no máximo e dói mais (%.2f)" % CardsPlague.hero_damage_bonus(s, s.hero, 0, 0))
	# --- Toca da Matilha e Besta Primordial.
	s = _sim(5, "plague")
	_pl_still(s)
	_pl(s, "pack_den")
	for k in int(5.0 / s.dt):
		s.step()
	check(_count_def(s, "wolf_pup") >= 1, "Toca da Matilha: solta filhotes (%d)" % _count_def(s, "wolf_pup"))
	var pr := _pl(s, "primal_beast")
	s.step()
	var p1 := _hit(s, pr[0])
	for k in 6:
		_pl(s, "rat_horde")
	s.step()
	check(_hit(s, pr[0]) > p1 * 1.3, "Besta Primordial: +dano por criatura em campo, Bando incluído")
	var pups0 := _count_def(s, "wolf_pup")
	s.kill_unit(pr[0], K.Death.HERO)
	check(_count_def(s, "wolf_pup") >= pups0 + 4, "Besta Primordial: solta 4 filhotes ao morrer")
	# --- Dragão: Cão do Inferno queima; Veio de Ouro e Câmbio rendem ouro; Fênix renasce; Golem deixa lava; meteoros.
	s = _sim(5, "dragon")
	_tough(s)
	var hh := _spawn(s, "hell_hound", 0.4)
	s.burn_t = 0.0
	s.unit_hits_hero(hh[0])
	check(s.burn_t > 0.0 and s.burn_dps >= 5.0, "Cão do Inferno: a mordida queima (%.1f por seg.)" % s.burn_dps)
	var g0 := s.gold
	s._apply(_inst("dragon_exchange"), s.hero.x, s.hero.y)
	check(is_equal_approx(s.gold - g0, 40.0), "Câmbio do Dragão: +40 de ouro")
	g0 = s.gold
	_spawn(s, "gold_mine", 5.0)
	for k in int(3.5 / s.dt):
		s.step()
	check(s.gold - g0 >= 3.0, "Veio de Ouro: rende ouro por segundo (+%.1f)" % (s.gold - g0))
	var ph := _spawn(s, "ash_phoenix", 6.0)
	s.kill_unit(ph[0], K.Death.HERO)
	check(_count_def(s, "ash_phoenix") == 1, "Fênix das Cinzas: renasce")
	var ph2: int = -1
	for j in s.units.hi:
		if s.units.alive[j] == 1 and s.units.def[j] == data.card("ash_phoenix").idx:
			ph2 = j
	check(ph2 >= 0 and s.units.hp[ph2] < s.units.max_hp[ph2] * 0.55 and s.units.hp[ph2] > s.units.max_hp[ph2] * 0.45, "Fênix: renasce com 50%% da vida")
	s.kill_unit(ph2, K.Death.HERO)
	check(_count_def(s, "ash_phoenix") == 0, "Fênix: só renasce uma vez")
	var gl := _spawn(s, "magma_golem", 7.0)
	var z0 := s.zones.size()
	s.kill_unit(gl[0], K.Death.HERO)
	check(s.zones.size() > z0, "Golem de Magma: deixa lava ao morrer")
	var sal := _spawn(s, "ash_salamander", 8.0)
	CardsDragon.on_card_played(s, _inst("ash_salamander"), s.hero.x, s.hero.y)   # como no jogo: jogar uma carta cria o estado
	z0 = s.zones.size()
	for k in int(1.2 / s.dt):
		s.step()
	check(s.zones.size() > z0, "Salamandra de Brasa: deixa chamas")
	var hp0 := s.hero.hp
	s._apply(_inst("meteor_storm"), s.hero.x, s.hero.y)
	for k in int(2.5 / s.dt):
		s.step()
	check(hp0 - s.hero.hp > 300.0, "Chuva de Meteoros: dano no herói (%.0f)" % (hp0 - s.hero.hp))
	# --- Lich: Exército Eterno levanta esqueletos; Dragão de Ossos cura com mortes.
	s = _sim(5, "lich")
	_pl_still(s)
	s._apply(_inst("eternal_army"), s.hero.x, s.hero.y)
	check(_count_def(s, "skeleton") == 12, "Exército Eterno: 12 esqueletos (%d)" % _count_def(s, "skeleton"))
	var sk := -1
	for j in s.units.hi:
		if s.units.alive[j] == 1 and s.units.def[j] == data.card("skeleton").idx:
			sk = j
			break
	s.kill_unit(sk, K.Death.HERO)
	check(_count_def(s, "skeleton") == 12, "Exército Eterno: a morte levanta outro esqueleto (%d)" % _count_def(s, "skeleton"))
	var bd := _spawn(s, "bone_dragon", 2.0)
	s.units.hp[bd[0]] = s.units.max_hp[bd[0]] * 0.5
	var bh0: float = s.units.hp[bd[0]]
	var sk2 := -1
	for j in s.units.hi:
		if s.units.alive[j] == 1 and s.units.def[j] == data.card("skeleton").idx:
			sk2 = j
			break
	s.kill_unit(sk2, K.Death.HERO)
	check(s.units.hp[bd[0]] > bh0, "Dragão de Ossos: morte por perto o cura")
	# --- Comuns: dardo, espinhos, curandeiro, mensageiro, grito, fosso, armadura.
	s = _sim(5, "plague")
	_tough(s)
	var dh := s.hero.hp
	s._apply(_inst("poison_dart"), s.hero.x, s.hero.y)
	check(dh - s.hero.hp >= 59.0 and s.burn_t > 0.0, "Flecha Envenenada: dano e veneno")
	s = _sim(5, "plague")
	_tough(s)
	var tr := _spawn(s, "spike_trap", 0.2)
	s.hero.root_t = 0.0
	dh = s.hero.hp
	s.step()
	check(s.hero.root_t > 0.5 and dh - s.hero.hp >= 79.0 and s.units.alive[tr[0]] == 0, "Armadilha de Espinhos: dano, prende e some")
	s = _sim(5, "plague")
	_pl_still(s)
	var hl := _spawn(s, "fallen_healer", 6.0)
	var tk := _spawn(s, "ogre", 6.5)
	s.units.hp[tk[0]] = s.units.max_hp[tk[0]] * 0.5
	var th0: float = s.units.hp[tk[0]]
	for k in int(3.0 / s.dt):
		s.step()
	check(s.units.hp[tk[0]] > th0 + 10.0 and s.units.alive[hl[0]] == 1, "Curandeiro Caído: cura aliado por perto (%.0f -> %.0f)" % [th0, s.units.hp[tk[0]]])
	s = _sim(5, "plague")
	_pl_still(s)
	var el0 := s.elixir
	var hand0 := s.hand.size()
	s._apply(_inst("dark_messenger"), s.hero.x, s.hero.y)
	check(s.elixir > el0 and s.hand.size() == hand0 + 1, "Mensageiro Sombrio: compra 1 carta e devolve elixir")
	var wcw := _spawn(s, "goblin_scout", 3.0)
	s.step()
	var wd0 := _hit(s, wcw[0])
	s._apply(_inst("war_cry"), s.hero.x, s.hero.y)
	check(_hit(s, wcw[0]) > wd0 * 1.2, "Grito de Guerra: todos os monstros causam mais (não só o Bando)")
	var m0 := s.hero_speed_mult(s.hero)
	s._apply(_inst("flooded_pit"), s.hero.x, s.hero.y)
	check(s.hero_speed_mult(s.hero) < m0 * 0.75, "Fosso Inundado: herói mais lento (%.2f -> %.2f)" % [m0, s.hero_speed_mult(s.hero)])
	var ha := _spawn(s, "hollow_armor", 2.0)
	dh = s.hero.hp
	s.hero_hits_unit(ha[0], 100.0)
	check(dh - s.hero.hp >= 9.0, "Armadura Vazia: devolve 10%% do golpe (%.1f)" % (dh - s.hero.hp))
	var bc0 := _count_def(s, "barricade")
	s.kill_unit(ha[0], K.Death.HERO)
	check(_count_def(s, "barricade") == bc0 + 1, "Armadura Vazia: deixa uma Barricada ao morrer")
	# --- Peso do sorteio: carta do vilão pesa 2, comum 1.
	s = _sim(7, "plague")
	var com := 0
	var tot := 400
	for k in tot:
		var cp := s._pick_card(func(_c: CardDef): return true, [])
		if cp != null and cp.owner == "common":
			com += 1
	var n_com := 0
	var n_all := 0
	for c in data.pool:
		if s._card_ok(c):
			n_all += 1
			if c.owner == "common":
				n_com += 1
	check(float(com) / tot < float(n_com) / n_all * 0.85, "sorteio: comum sai menos que no sorteio uniforme (%.0f%% contra %.0f%%)" % [100.0 * com / tot, 100.0 * n_com / n_all])
	# --- Relíquias: a oferta de ato não força mais uma de elixir (19/11/2026); Biblioteca Viva compra ao embaralhar.
	var any_offer := true
	for sd in 12:
		var so := _sim(sd + 1, "dragon")
		so.offers.clear()
		so._offer_relics("act")
		any_offer = any_offer and so.offers.size() == 1 and so.offers[0]["options"].size() > 0
	check(any_offer, "oferta de relíquia do ato vem com opções (sem relíquia de elixir obrigatória)")
	s = _sim(5, "plague")
	s.gain_relic("living_library")
	s.discard.append_array(s.queue)
	s.queue.clear()
	var hs0 := s.hand.size()
	s.hand.resize(maxi(0, s.hand.size() - 1))
	hs0 = s.hand.size()
	s.draw_card()
	check(s.hand.size() >= hs0 + 1 and int(s.stats.get("shuffles", 0)) >= 1, "Biblioteca Viva: embaralhar compra 1 carta a mais")


## Sombrio vira escudo de vida (50% da vida absorve o dano antes) e Rouba-vida cura a unidade (19/11/2026).
func t_shadowy_leech() -> void:
	var s := _sim(3)
	s.hero.base_hp = 1.0e6
	s.hero.hp = 1.0e6
	var d: CardDef = null
	for c in data.cards:
		if d == null and not c.is_spell and not c.fly and c.arch == K.Arch.CHASER:
			d = c
	check(data.modifiers.has("leech") and K.MOD_IDS.has("leech"), "Rouba-vida existe como modificador")
	var j := s.units.spawn(d, s.hero.x + 40.0, s.hero.y, 0.0, 0.0, K.F_SHADOWY, 0)
	var hp0 := s.units.hp[j]
	var sh0 := s.units.sh[j]
	check(is_equal_approx(sh0, hp0 * 0.5), "Sombrio: nasce com escudo de 50%% da vida (%.1f de %.1f)" % [sh0, hp0])
	s.hero_hits_unit(j, sh0 * 0.5)
	check(s.units.hp[j] == hp0 and is_equal_approx(s.units.sh[j], sh0 * 0.5), "Sombrio: o escudo absorve o golpe antes da vida")
	s.hero_hits_unit(j, s.units.sh[j] + 1.0)
	check(s.units.sh[j] <= 0.0 and is_equal_approx(s.units.hp[j], hp0 - 1.0), "Sombrio: o que passa do escudo tira vida")
	var plain := s.units.spawn(d, s.hero.x + 40.0, s.hero.y, 0.0, 0.0, 0, 0)
	check(s.units.sh[plain] == 0.0, "Unidade comum nasce sem escudo")
	var k := s.units.spawn(d, s.hero.x, s.hero.y, 0.0, 0.0, K.F_LEECH, 0)
	s.units.hp[k] = s.units.max_hp[k] * 0.1
	var h0 := s.units.hp[k]
	s.unit_hits_hero(k)
	check(s.units.hp[k] > h0 and s.units.hp[k] <= s.units.max_hp[k], "Rouba-vida: golpe no herói cura a unidade (sem passar da vida máxima)")
	var child := s.spawn_child(d, s.hero.x, s.hero.y, j)
	check(child < 0 or (s.units.flags[child] & K.F_SHADOWY) != 0, "Filhote herda o Sombrio")


## Horda sem fim (19/11/2026): fila infinita, determinística, sobrevive ao salvamento; só acaba com o covil.
func _endless_kill(s: Sim) -> void:
	for f in s.followers:
		f.hp = 0.0
	s.hero.hp = 0.0
	s._check_end()
	s.offers.clear()


## Frente A (21/11/2026): fase unica de 15 parties, oferta so por party, mods neutros, run curta com o bot.
func t_run15() -> void:
	var ph: Dictionary = data.phase(1)
	check(ph.get("parties", []).size() == 15, "fase 1: 15 parties")
	check(int(data.unlock_villain_at.get("dragon", 0)) == 3 and int(data.unlock_villain_at.get("lich", 0)) == 6, "unlock_villain_at: dragao 3, lich 6")
	var sizes_ok := true
	var classes: Array = data.hero_classes.keys()
	for g in ph["parties"]:
		sizes_ok = sizes_ok and g.size() >= 1 and g.size() <= 4
		for c in g:
			sizes_ok = sizes_ok and classes.has(str(c))
	check(sizes_ok, "parties de 1 a 4 heroes de classes validas")
	check(data.phase(0).get("tutorial", false), "tutorial segue na fase 0")
	var a := Sim.new()
	a.setup(data, 5, "horde", [], [], 1)
	var b := Sim.new()
	b.setup(data, 5, "horde", [], [], 1, MetaApply.defaults())
	check(a.party_count() == 15 and a.party_mode(), "Sim.setup fase 1: fila de 15 parties")
	check(a.elixir_max == b.elixir_max and is_equal_approx(a.draw_delay(), b.draw_delay()) and is_equal_approx(a.seconds_per_elixir(), b.seconds_per_elixir()), "mods neutros nao mudam os numeros")
	var m := MetaApply.defaults()
	m["recarga"]["carta"] = 0.5
	m["elixir"]["max"] = 2.0
	var c := Sim.new()
	c.setup(data, 5, "horde", [], [], 1, m)
	check(is_equal_approx(c.draw_delay(), a.draw_delay() * 0.5) and is_equal_approx(c.elixir_max, a.elixir_max + 2.0), "mods de recarga e elixir max aplicam")
	# Oferta so por party morta (ha 1 heroi por party na party 1 e 2: use a party 3, de 2 herois).
	var s := Sim.new()
	s.setup(data, 5, "horde", [], [], 1)
	s.auto_route = true
	while s.cur_party < 2:
		s.hero.hp = 0.0
		s._check_end()
		s.offers.clear()
	check(s.party_members(s.cur_party).size() == 2, "party 3 tem 2 herois")
	s.offers.clear()
	s.followers[0].hp = 0.0
	s._check_end()
	check(s.offers.is_empty(), "heroi morto sem a melhoria: sem oferta de carta")
	s.hero.hp = 0.0
	s._check_end()
	check(s.offers.size() > 0, "party inteira morta: oferta de carta")
	var m2 := MetaApply.defaults()
	m2["oferta_por_heroi"] = true
	var s2 := Sim.new()
	s2.setup(data, 5, "horde", [], [], 1, m2)
	s2.auto_route = true
	while s2.cur_party < 2:
		s2.hero.hp = 0.0
		s2._check_end()
		s2.offers.clear()
	s2.offers.clear()
	s2.followers[0].hp = 0.0
	s2._check_end()
	check(s2.offers.size() > 0, "oferta_por_heroi: heroi morto oferece carta")
	# Run curta com o bot (so fumaca).
	var r := _phase_sim(1, 9)
	var bot := PlayerBot.load_bot("greedy", 9)
	var n := 0
	while r.phase != K.Phase.OVER and n < 4000:
		bot.think(r)
		r.step()
		n += 1
	check(n > 0 and r.t > 0.0, "run curta com o bot sem erro (%.0f s simulados)" % r.t)

## Rodada de UI de 20/11/2026: escala de espaçamento e auditoria de folga (game/spacing_audit.gd). A auditoria das telas
## inteiras roda fora daqui: bash tools/space_audit.sh <pasta> (sem janela, ~3 min; código de saída = nº de problemas).
func t_ui_spacing() -> void:
	# A escala: degraus crescentes e a moldura desenhada dentro da margem de conteúdo dos painéis, botões e fitas do kit.
	check(UiKit.SP_XS < UiKit.SP_S and UiKit.SP_S < UiKit.SP_M and UiKit.SP_M < UiKit.SP_L and UiKit.SP_L < UiKit.SP_XL and UiKit.SP_XL < UiKit.SP_XXL, "escala de espaçamento crescente")
	for kind in ["gold", "ink", "dark", "night"]:
		var sb := UiParch.box(kind, 6.0) as StyleBoxTexture
		var need := UiKit.clean_need(sb)
		check(sb.content_margin_left >= need.x and sb.content_margin_top >= need.y, "painel %s: margem de conteúdo %.0f cobre a moldura (%.0f)" % [kind, sb.content_margin_top, need.y])
		check(UiParch.box(kind, 60.0).content_margin_left == 60.0, "painel %s: margem maior que o mínimo fica como está" % kind)
		check(UiParch.box(kind, 0.0).content_margin_left == 0.0, "painel %s cru (margem 0) continua cru" % kind)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var bb := UiParch.button_box(st) as StyleBoxTexture
		var need := UiKit.clean_need(bb, true)
		var top: float = bb.content_margin_top if st != "pressed" else bb.content_margin_top - 2.0
		check(bb.content_margin_left >= need.x and top >= need.y - (2.0 if st == "pressed" else 0.0) and bb.content_margin_bottom >= need.y - 2.0, "botão %s: folga cobre a moldura" % st)
	var rb := UiParch.ribbon_box("monster")
	check(rb.content_margin_top >= UiKit.clean_need(rb).y and rb.content_margin_bottom >= UiKit.clean_need(rb).y, "fita: folga cobre a moldura")
	var raw := UiParch.box("ink", 0.0)
	raw.content_margin_left = 2.0
	raw.content_margin_top = 2.0
	UiKit.fit_margins(raw, true)
	check(raw.content_margin_left >= UiKit.clean_need(raw, true).x and raw.content_margin_top >= UiKit.clean_need(raw, true).y, "fit_margins sobe margens escritas à mão")
	# A auditoria enxerga o problema: rótulo colado na borda do painel de papel acusa; com a margem do kit, não.
	var holder := Control.new()
	holder.size = Vector2(800, 600)
	add_child(holder)
	var bad := PanelContainer.new()
	var bsb := UiParch.box("ink", 0.0)
	bsb.set_content_margin_all(3.0)
	bad.add_theme_stylebox_override("panel", bsb)
	var bl := Label.new()
	bl.text = "Texto colado"
	bad.add_child(bl)
	holder.add_child(bad)
	var good := PanelContainer.new()
	good.add_theme_stylebox_override("panel", UiParch.box("ink", 4.0))
	good.position = Vector2(300, 0)
	var gl := Label.new()
	gl.text = "Texto com folga"
	good.add_child(gl)
	holder.add_child(good)
	var cut := Label.new()   # largura menor que o texto, com clip_text: deve acusar corte
	cut.text = "Um texto bem comprido que não cabe"
	cut.clip_text = true
	cut.size = Vector2(60, 24)
	cut.position = Vector2(0, 300)
	holder.add_child(cut)
	for pc in [bad, good]:   # sem esperar um quadro: dimensiona e distribui os filhos agora
		pc.size = pc.get_combined_minimum_size()
		pc.notification(Container.NOTIFICATION_SORT_CHILDREN)
	var found := SpacingAudit.scan(holder, "teste", Rect2(Vector2.ZERO, Vector2(800, 600)))
	var bad_hits := 0
	var good_hits := 0
	var cut_hits := 0
	for f in found:
		if str(f["text"]).begins_with("Texto colado"):
			bad_hits += 1
		elif str(f["text"]).begins_with("Texto com folga"):
			good_hits += 1
		elif f["kind"] == "corte":
			cut_hits += 1
	if bad_hits < 1:
		print("  [diag] auditoria: bad.size=%s lbl.size=%s lbl.vis=%s margem=%s achados=%s" % [bad.size, bl.size, bl.is_visible_in_tree(), bsb.content_margin_left, str(found)])
	check(bad_hits >= 1, "auditoria: texto colado na moldura é acusado (%d)" % bad_hits)
	check(good_hits == 0, "auditoria: painel com a margem do kit passa limpo (%d)" % good_hits)
	check(cut_hits >= 1, "auditoria: texto mais largo que o rótulo é acusado como corte (%d)" % cut_hits)
	holder.queue_free()


## Contratos da metaprogressao (onda 0, 21/11/2026): dados novos carregam, mods neutros, API do MetaSave v5.
func t_contracts() -> void:
	check(data.meta_nodes.size() > 0 and data.power_ids.size() > 0, "meta_tree e hero_powers carregam")
	var mods := MetaApply.merge({})
	check(float(mods["arena"]["boss_hp_mult"]) == 1.0 and mods["deck"].is_empty(), "mods neutros")
	var path := "user://test_contracts.save"
	var m := MetaSave.load_or_new(data, path)
	m.add_almas(300)
	check(not m.buy("atr_elixir_regen_1"), "filho nao compra antes do pai")
	check(m.buy("atr_elixir_max_1") and m.buy("atr_elixir_regen_1"), "compra pai e depois filho")
	var mm := MetaApply.run_mods(m)
	check(float(mm["elixir"]["max"]) == 1.0, "run_mods le o no comprado (%s)" % str(mm["elixir"]))
	m.save()
	var m2 := MetaSave.load_or_new(data, path)
	check(m2.almas == m.almas and m2.node_level("atr_elixir_max_1") == 1, "v5 ida e volta")
	m2.refund_all()
	check(m2.almas == m2.almas_earned and m2.upgrades.is_empty(), "reembolso total devolve tudo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var sim := Sim.new()
	sim.setup(data, 1, "plague", [], [], 1, {"mao": {"inicial": 1}})
	check(sim.party_powers().is_empty() and sim.hand_size >= 6, "setup com mods e party_powers vazio")


## Frente D (21/11/2026): MetaSave v5, Almas, reembolso, deck de 19, reliquias liberadas e fallback de raridade.
func t_meta5() -> void:
	var path := "user://test_meta5.save"
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(abs_path)
	# arvore: pais existem, fx dentro de DEFAULTS, custos crescentes
	var defs := MetaApply.defaults()
	var ok_tree := data.meta_nodes.size() >= 40
	for id in data.meta_nodes:
		var nd: Dictionary = data.meta_nodes[id]
		var par := str(nd["parent"])
		ok_tree = ok_tree and (par == "" or data.meta_nodes.has(par))
		for k in nd["fx"]:
			var parts := str(k).split(".")
			if parts[0] == "locais":
				continue   # locais.<local>.<chave>: deltas sobre a regra do local
			var d: Variant = defs
			for pk in parts:
				if d is Dictionary and (d as Dictionary).has(pk):
					d = d[pk]
				else:
					ok_tree = false
					printerr("fx fora de DEFAULTS: ", id, " ", k)
					break
	check(ok_tree, "meta_tree: pais existem e todo fx esta em MetaApply.DEFAULTS (%d nos)" % data.meta_nodes.size())
	# save v5 ida e volta; save antigo zera
	var m := MetaSave.load_or_new(data, path)
	check(m.relics_unlocked.size() == 12 and m.is_relic_unlocked("elixir_flask") and not m.is_relic_unlocked("heart_of_well"), "comeca so com as 12 reliquias livres")
	m.add_almas(5000)
	check(m.buy("atr_elixir_max_1") and m.buy("atr_elixir_max_1") and m.buy("atr_elixir_regen_1") and m.buy("ger_card_disc_1"), "compra nos")
	if not m.unlocked.has("ogre"):
		m.unlocked.append("ogre")
	check(m.buy_card_level("rat_brute") and m.buy_card_level("rat_brute") and m.card_level("rat_brute") == 3, "sobe a carta ate III")
	check(not m.buy_card_level("ogre") or m.unlocked.has("ogre"), "carta bloqueada nao sobe")
	var locked_card := ""
	for c in data.pool:
		if not m.unlocked.has(c.id):
			locked_card = c.id
			break
	check(locked_card != "" and not m.buy_card_level(locked_card), "carta nao liberada nao sobe")
	for k in 10:
		m.buy_card_level("rat_brute")
	check(m.card_level("rat_brute") == 6 and m.card_cost("rat_brute") == -1 and not m.buy_card_level("rat_brute"), "teto da carta e VI")
	check(m.buy_relic_level("elixir_flask") and m.buy_relic_level("elixir_flask") and not m.buy_relic_level("elixir_flask") and m.relic_level("elixir_flask") == 3, "reliquia sobe de 1 a 3")
	check(not m.buy_relic_level("heart_of_well"), "reliquia bloqueada nao sobe")
	m.relics_unlocked.append("heart_of_well")
	check(m.buy_relic_level("heart_of_well"), "reliquia liberada sobe")
	m.see_act2()
	m.reach_party(7)
	m.save()
	var m2 := MetaSave.load_or_new(data, path)
	check(m2.almas == m.almas and m2.almas_earned == 5000 and m2.node_level("atr_elixir_max_1") == 2 and m2.card_level("rat_brute") == 6 \
		and m2.relic_level("elixir_flask") == 3 and m2.best_party == 7 and m2.act2_reached and m2.is_relic_unlocked("heart_of_well"), "save v5 ida e volta")
	var ver4 := FileAccess.open(path, FileAccess.WRITE)
	ver4.store_var({"ver": 4, "almas": 999, "upgrades": {"atr_elixir_max_1": 3}, "phases_won": [1, 2]})
	ver4 = null
	check(MetaSave.load_or_new(data, path).almas == 0, "save de versao menor zera")
	# reembolso conserva
	var spent := m2.almas_earned - m2.almas
	var back := m2.refund_all()
	check(back == spent and spent > 0 and m2.almas == m2.almas_earned and m2.upgrades.is_empty() and m2.card_levels.is_empty() and m2.relic_levels.is_empty(), "refund_all conserva (%d de volta)" % back)
	check(not m2.buy("atr_elixir_regen_1") and m2.buy("atr_elixir_max_1"), "filho so compra depois do pai")
	check(m2.refund("atr_elixir_max_1") > 0 and m2.almas == m2.almas_earned, "refund de no devolve o preco")
	# Almas por dano: teto na vida maxima de cada heroi
	var s := _sim(3)
	var hp := s.hero.max_hp()
	for k in 4:
		s.hero.hp = s.hero.max_hp()
		s.damage_hero(hp * 0.5, s.hero.x + 1.0, s.hero.y, 0, SimHero.DMG_PIERCE, "test")
	var ad := float(s.stats.get("almas_dmg", 0.0))
	check(ad > 0.0 and ad <= hp + 0.01, "dano em Almas conta so ate a vida maxima do heroi (%.0f de %.0f)" % [ad, hp])
	var g := m2.almas_for(60000.0, 6)
	check(int(g["dmg"]) == 200 and int(g["heroes"]) == 48 and int(g["total"]) == 248, "almas_for: dano/300 + 8 por heroi (%s)" % str(g))
	# apply_run grava e mantem Almas ao perder
	s.stats["heroes_fallen"] = 2
	s.stats["parties_beaten"] = 3
	s.result = K.Result.LOSS
	var m3 := MetaSave.load_or_new(data, path)
	m3.file = path
	var before := m3.almas
	var res := m3.apply_run(s, path)
	check(m3.almas == before + int(res["almas"]["total"]) and int(res["almas"]["total"]) > 0 and m3.best_party == 3 and m3.runs == 1 and res["new_best"], "apply_run soma Almas ao perder, recorde e run")
	check(m3.villains.has("dragon") and res["villains"] == ["dragon"], "party 3 libera o Dragao")
	DirAccess.remove_absolute(abs_path)
	# deck de 19
	var dk: Array = data.deck("plague")["cards"]
	check(m3.deck_ok("plague", dk) and m3.set_deck("plague", dk) and m3.deck_for("plague").size() == 19, "deck inicial e valido (19)")
	var bad4: Array = dk.duplicate()
	for i in 4:
		bad4[i] = "rat_brute"
	check(not m3.deck_ok("plague", bad4), "mais de 3 copias nao vale")
	check(not m3.deck_ok("plague", dk.slice(0, 18)), "18 cartas nao vale")
	var other := ""
	for c in data.pool:
		if c.owner == "lich":
			other = c.id
			break
	var bad_owner: Array = dk.duplicate()
	bad_owner[0] = other
	check(not m3.deck_ok("plague", bad_owner), "carta de outro vilao nao vale")
	# reliquia bloqueada nao aparece; fallback de raridade
	var sm := Sim.new()
	sm.setup(data, 5, "plague", [], [], 1, {"reliquias": {"unlocked": ["elixir_flask", "quick_spring", "torn_banner", "heart_of_well"]}})
	var pool := sm._relic_pool()
	check(pool.size() == 4 and not pool.has("deep_cauldron") and not pool.has("bone_crown"), "pool so tem as reliquias liberadas (%s)" % str(pool))
	var seen_rare := false
	for sd in 12:
		sm.rng_offer.seed = sd + 1
		sm._offer_relics("act")
		var offer: Dictionary = sm.offers[sm.offers.size() - 1] if sm.offers is Array and sm.offers.size() > 0 else {}
		if offer.is_empty():
			continue
		var n := 0
		for o in offer.get("options", []):
			n += 1
			check(pool.has(str(o["id"])), "oferta so com liberadas")
		seen_rare = seen_rare or n >= 3
		sm.offers.clear()
	check(seen_rare, "fallback de raridade: a oferta fecha 3 opcoes mesmo com a raridade sorteada curta")

## Biblioteca (frente F, 21/11/2026): teste de fumaça da tela (instancia, filtro por custo, regras do deck, compra de nível).
func t_library_ui() -> void:
	var path := "user://test_library.save"
	UiSkins.apply()
	var m := LibraryDemo.seed_meta(data, path)
	var scr := CollectionScreen.new()
	scr.setup(data, m)
	scr.api = LibraryDemo.make_api(m)
	var holder := Control.new()
	holder.size = Vector2(1688, 1008)
	add_child(holder)
	holder.add_child(scr)
	scr.open()
	check(scr.tabs.size() == data.villain_ids.size() + 1 and scr.grid.get_child_count() > 0 and scr.grid.get_child_count() <= CollectionScreen.PER_PAGE, "biblioteca instancia com abas e a primeira pagina")
	scr.set_cost_filter(1)
	var all_two := scr.shown.size() > 0
	for d in scr.shown:
		if CollectionScreen.bucket_of(d.cost_at(int(m.card_levels.get(d.id, 1)))) != 1:
			all_two = false
	check(all_two, "filtro por custo mostra so a faixa escolhida (%d cartas)" % scr.shown.size())
	scr.set_cost_filter(1)
	check(scr.cost_filter == -1, "clicar de novo no filtro limpa")
	# Deck: 19 cartas e ate 3 copias.
	scr.set_tab("plague")
	check(scr.work.size() == CollectionScreen.DECK_SIZE and scr.deck_valid(), "deck inicial do vilao tem 19 e vale")
	var extra := ""
	for d in data.pool:
		if d.owner == "plague" and m.is_unlocked(d.id) and scr.deck_count(d.id) == 0:
			extra = d.id
			break
	check(extra != "" and not scr.deck_add(extra), "deck cheio nao aceita mais carta")
	var drop: Array = []
	for id in scr.work:
		if not drop.has(id) and drop.size() < 4:
			drop.append(id)
	for id in drop:
		check(scr.deck_remove(id), "tira uma copia de " + str(id))
	check(scr.work.size() == 15 and not scr.deck_valid(), "deck com 15 cartas nao vale")
	check(m.decks.get("plague", []).size() in [0, 19], "deck incompleto nao vai para o save")
	var ok3 := true
	for k in 3:
		ok3 = ok3 and scr.deck_add(extra)
	check(ok3 and scr.deck_count(extra) == 3, "ate 3 copias da mesma carta")
	check(not scr.deck_add(extra) and scr.deck_count(extra) == 3, "a 4a copia e recusada")
	var dragon_card := ""
	for d in data.pool:
		if d.owner == "dragon":
			dragon_card = d.id
			break
	check(not scr.can_add(dragon_card), "carta de outro vilao nao entra no deck")
	scr.deck_add(str(drop[0]))
	check(scr.work.size() == 19 and scr.deck_valid() and m.decks.get("plague", []).size() == 19, "deck completo volta a valer e e gravado")
	# Comprar nivel: saldo e nivel mudam; no VI ou sem Almas, nada.
	var buy := ""
	for d in data.pool:
		if d.owner == "plague" and m.is_unlocked(d.id) and int(m.card_levels.get(d.id, 1)) < 6:
			buy = d.id
			break
	var lv0 := int(m.card_levels.get(buy, 1))
	var bal0 := m.almas
	var price := MetaApply.card_upgrade_cost(data, buy, lv0 + 1)
	check(scr.buy_level(buy) and int(m.card_levels[buy]) == lv0 + 1 and m.almas == bal0 - price and price > 0, "comprar nivel desconta o preco e sobe a carta")
	m.almas = 0
	check(not scr.buy_level(buy) and int(m.card_levels[buy]) == lv0 + 1, "sem Almas nao compra")
	m.almas = 99999
	m.card_levels[buy] = 6
	check(not scr.buy_level(buy) and m.almas == 99999, "no nivel VI nao compra mais")
	scr._open_zoom(buy)
	check(scr.zoom_layer.get_child_count() > 0, "zoom abre")
	scr._close_zoom()
	holder.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	UiSkins.apply()

## Poderes de party (frente B, 21/11/2026): dados, sorteio na queda da party, recarga, gatilho com 1,5 s entre
## disparos, save v8 e runs curtas do bot. Fumaça: nada de balanço.
func t_powers() -> void:
	var ids: Array = data.power_ids
	var ok_data := ids.size() >= 20 and ids.size() <= 24
	for id in ids:
		var d: Dictionary = data.hero_powers[id]
		var keys0: Array = d["lv"][0].keys()
		ok_data = ok_data and d["lv"].size() == 3 and d["cooldown"].size() == 3 and d["lv"][2].keys() == keys0
		ok_data = ok_data and float(d["cooldown"][0]) >= float(d["cooldown"][2]) and float(d["cooldown"][2]) >= 4.0 and float(d["cooldown"][0]) <= 60.0
		ok_data = ok_data and TranslationServer.translate("POWER_" + str(id)) != "" and d.has("counters") and d.has("weight")
	check(ok_data, "poderes: %d com 3 niveis, recargas 4-60 s e mesmas chaves por nivel" % ids.size())
	# Sorteio: cada queda de party dá exatamente 1 poder novo ou 1 evolucao; a oferta-aviso vem depois da de carta.
	var s := _sim(7, "ruin")
	check(s.powers.is_empty(), "a run comeca sem poderes")
	var falls := 0
	var order_ok := true
	var evolved := false
	while falls < 8 and s.cur_party < s.party_count() - 1:
		s.offers.clear()
		var lv_before := 0
		for p in s.powers:
			lv_before += int(p["level"])
		s.hero.hp = 0.0
		for f in s.followers:
			f.hp = 0.0
		s._check_end()
		falls += 1
		var lv_after := 0
		for p in s.powers:
			lv_after += int(p["level"])
		order_ok = order_ok and lv_after == lv_before + 1 and str(s.offers.back()["source"]) == "power"
		var op: Dictionary = s.offers.back()["options"][0]
		order_ok = order_ok and op["kind"] == "power" and int(op["level"]) >= 1 and (s.offers.back()["powers"] as Array).size() == s.powers.size()
		if not bool(op["new"]):
			evolved = true
	check(falls >= 2 and order_ok, "cada queda de party da +1 (poder novo ou nivel) e a oferta-aviso vem por ultimo (%d quedas)" % falls)
	check(s.powers.size() >= 1 and s.party_powers().size() == s.powers.size(), "party_powers lista os poderes (%d)" % s.powers.size())
	var top := 0
	for p in s.powers:
		top = maxi(top, int(p["level"]))
	check(top <= 3, "nivel maximo 3")
	s.offers.clear()
	s.choose(0)   # aviso vazio: nao quebra
	# Probabilidade de evolucao ~1 em 3 e estilo do jogador (dano da party toda) pesa o sorteio.
	var r := _sim(3, "ruin")
	for id in ["fire_burst", "whirlwind", "slay_next", "ally_rat"]:
		r.powers.append({"id": id, "level": 1, "cd_left": 0.0, "gap_left": 0.0})
	var evo := 0
	for k in 600:
		if not bool(HeroPowers.roll(r)["new"]):
			evo += 1
	check(evo > 150 and evo < 270, "cerca de 1 em 3 sorteios e evolucao (%d de 600)" % evo)
	var q := _sim(3, "ruin")
	HeroPowers.note(q, "fire", 1000.0)
	var fw := 0
	for k in 600:
		if HeroPowers.roll(q)["id"] == "fire_ward":
			fw += 1
	check(fw > 60, "dano de fogo da party puxa o poder de fogo (%d de 600; base ~29)" % fw)
	var q2 := _sim(3, "ruin")
	q2.hero.note("burst", 500.0)
	q2.followers.clear()
	check(float(q2.power_state["taken"].get("burst", 0.0)) == 500.0, "Hero.note soma o dano da party no motor")
	# Recarga conta; gatilho respeita 1,5 s entre disparos e a recarga do poder.
	var c := _sim(5, "ruin")
	c.record_events = true
	c.hero.base_hp = 1.0e6
	c.hero.hp = 1.0e6
	c.powers.append({"id": "fire_burst", "level": 1, "cd_left": 5.0, "gap_left": 0.0})
	for k in 20:
		c.step()
	check(absf(float(c.powers[0]["cd_left"]) - 4.0) < 0.1, "recarga conta (%.2f)" % float(c.powers[0]["cd_left"]))
	var a := _sim(5, "ruin")
	a.record_events = true
	a.hero.base_hp = 1.0e6
	a.hero.hp = 1.0e6
	a.powers.append({"id": "fire_burst", "level": 1, "cd_left": 0.0, "gap_left": 0.0})
	a.powers.append({"id": "whirlwind", "level": 1, "cd_left": 0.0, "gap_left": 0.0})
	for k in 4:
		a.units.spawn(data.card("ogre"), a.hero.x + 1.2 + k * 0.3, a.hero.y + 0.2 * k, 0.0, 0.0, 0, 900 + k)
	var trig_t: Array = []
	var ready_seen := 0
	for k in 120:
		a.events.clear()
		a.step()
		for e in a.events:
			if e[0] == K.Ev.POWER_TRIGGER:
				trig_t.append(a.t)
	check(trig_t.size() == 2, "dois poderes prontos disparam um por vez (%d disparos em 6 s)" % trig_t.size())
	if trig_t.size() >= 2:
		check(float(trig_t[1]) - float(trig_t[0]) >= 1.45, "1,5 s entre gatilhos (%.2f s)" % (float(trig_t[1]) - float(trig_t[0])))
	check(float(a.powers[0]["cd_left"]) > 5.0 and float(a.powers[1]["cd_left"]) > 5.0, "depois de disparar a recarga longa comeca")
	check(float(a.hero.hp) <= 1.0e6, "gatilho nao quebra o heroi")
	# Todo poder dispara (nivel 1 e 3) quando a condicao dele acontece, sem erro de script.
	var fired_all := true
	var not_fired: Array = []
	for pid in ids:
		for lvl in [1, 3]:
			var f := _sim(5, "ruin")
			f.record_events = true
			f.hero.base_hp = 1.0e6
			f.hero.hp = 1.0e5
			f.hero.curses = 1
			f.powers.append({"id": pid, "level": lvl, "cd_left": 0.0, "gap_left": 0.0})
			for k in 3:
				f.units.spawn(data.card("ogre"), f.hero.x + 1.2 + k * 0.3, f.hero.y + 0.3 * k, 0.0, 0.0, 0, 800 + k)
			f.units.spawn(data.card("barricade"), f.hero.x - 1.2, f.hero.y, 0.0, 0.0, 0, 810)
			f.hero.slow_t = 1.0
			f.hero.note("fire", 300.0)
			f.hero.note("projectile", 300.0)
			f.hero.note("burst", 300.0)
			f.hero.take_damage(10.0, f.hero.x + 3.0, f.hero.y, 0, SimHero.DMG_SPELL)
			var got := false
			for e in f.events:
				if e[0] == K.Ev.POWER_TRIGGER:
					got = true   # spell_ward reage ja no golpe de feitiço
			for k in 100:
				if got:
					break
				f.events.clear()
				f.step()
				for e in f.events:
					if e[0] == K.Ev.POWER_TRIGGER:
						got = true
				if got:
					break
			if not got:
				fired_all = false
				not_fired.append("%s:%d" % [pid, lvl])
	check(fired_all, "todos os poderes disparam nos niveis 1 e 3 (sem disparo: %s)" % str(not_fired))
	# Rato aliado: nasce a cada 5 s, maximo 5.
	var rt := _sim(5, "ruin")
	rt.hero.base_hp = 1.0e6
	rt.hero.hp = 1.0e6
	rt.powers.append({"id": "ally_rat", "level": 1, "cd_left": 5.0, "gap_left": 0.0})
	for k in int(32.0 / rt.dt):
		rt.step()
	var rats: Array = rt.power_state["allies"]
	check(rats.size() == 5, "rato aliado: 1 a cada 5 s, maximo 5 (%d)" % rats.size())
	# Save v8: poderes, niveis e recargas ida e volta.
	var sv := _sim(11, "ruin")
	var b := PlayerBot.load_bot("greedy", 11)
	for k in 6:
		sv.offers.clear()
		sv.hero.hp = 0.0
		for f in sv.followers:
			f.hp = 0.0
		sv._check_end()
	sv.offers.clear()
	for i in 300:
		b.think(sv)
		sv.step()
	sv.powers[0]["cd_left"] = 7.25
	check(SaveGame.VERSION == 8 and SaveGame.save(sv, "user://test_powers.save"), "save v8 grava")
	var ld := SaveGame.load_run(data, "user://test_powers.save")
	var same := ld != null and ld.powers.size() == sv.powers.size()
	if same:
		for j in sv.powers.size():
			same = same and ld.powers[j]["id"] == sv.powers[j]["id"] and int(ld.powers[j]["level"]) == int(sv.powers[j]["level"]) 				and absf(float(ld.powers[j]["cd_left"]) - float(sv.powers[j]["cd_left"])) < 0.001
	check(same, "poderes, niveis e recargas voltam do save (%d)" % sv.powers.size())
	SaveGame.erase("user://test_powers.save")
	# 3 runs curtas do bot sem erro (limite de ticks; falha de script derruba o teste).
	for sd in [21, 22, 23]:
		var rs := _run(sd, "ruin", "greedy", 9000)
		check(rs.t > 100.0 and rs.powers.size() >= 0, "run curta com poderes sem erro (semente %d, %d poderes, party %d)" % [sd, rs.powers.size(), rs.cur_party])
## Covil radial (frente E, 22/11/2026): instancia com a arvore de mentira, posicoes sem sobreposicao, comprar/reembolsar.
func t_covil_ui() -> void:
	var path := "user://test_covil_ui.save"
	var d2 := GameData.load_dir()
	CovilDemo.use_fake_tree(d2)
	for pair in [[data, "arvore do arquivo"], [d2, "arvore de mentira"]]:
		var gd: GameData = pair[0]
		var lay := MetaTreeView.compute_layout(gd.meta_tree)
		var pos: Dictionary = lay["pos"]
		check(pos.size() == gd.meta_nodes.size(), "covil: todo no tem posicao (%s: %d)" % [pair[1], pos.size()])
		var ids: Array = pos.keys()
		var min_d := 1e9
		for i in ids.size():
			min_d = minf(min_d, (pos[ids[i]] as Vector2).length() - MetaTreeView.HEART_R)
			for j in range(i + 1, ids.size()):
				min_d = minf(min_d, (pos[ids[i]] as Vector2).distance_to(pos[ids[j]]))
		check(min_d >= MetaTreeView.NODE_R * 2.0 + 4.0, "covil: nos sem sobreposicao (%s, minimo %.1f)" % [pair[1], min_d])
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		var m := MetaSave.load_or_new(gd, path)
		m.add_almas(1000)
		var sc := CovilScreen.new()
		sc.act2_override = 0
		sc.setup(gd, m)
		add_child(sc)
		check(sc.view != null and sc.almas_l.text == "1000", "covil: instancia sem erro (%s)" % pair[1])
		# Compra e reembolso: filho so depois do pai, saldo e estado acompanham.
		var root := ""
		var child := ""
		for id in gd.meta_nodes:
			var nd: Dictionary = gd.meta_nodes[id]
			if str(nd["parent"]) == "" and str(nd["sector"]) != "troca_ato" and root == "":
				for k in gd.meta_nodes:
					if str(gd.meta_nodes[k]["parent"]) == id:
						root = id
						child = k
						break
		check(root != "", "covil: achou par pai/filho (%s)" % pair[1])
		var v: MetaTreeView = sc.view
		check(v.state_of(root) == "available" and v.state_of(child) == "locked", "covil: estados antes da compra")
		check(not v.buy_node(child), "covil: filho nao compra antes do pai")
		var cost: int = m.node_cost(root)
		check(v.buy_node(root) and m.almas == 1000 - cost and sc.almas_l.text == str(1000 - cost), "covil: comprar desconta e atualiza o saldo")
		check(v.state_of(child) == "available", "covil: filho abre depois do pai")
		check(v.buy_node(child), "covil: compra o filho")
		check(v.refund_node(root) == 0 and m.node_level(root) == 1, "covil: pai nao reembolsa com filho comprado")
		var back := v.refund_node(child)
		check(back > 0 and m.node_level(child) == 0, "covil: reembolsa o filho")
		check(v.refund_node(root) == cost and m.almas == 1000 and sc.almas_l.text == "1000", "covil: reembolsa o pai e o saldo volta")
		# Setor da troca de ato: trancado ate chegar ao ato 2.
		var ato := ""
		for id in gd.meta_nodes:
			if str(gd.meta_nodes[id]["sector"]) == "troca_ato" and str(gd.meta_nodes[id]["parent"]) == "":
				ato = id
		if ato != "":
			check(v.state_of(ato) == "sealed" and not v.buy_node(ato), "covil: troca de ato trancada antes do ato 2")
			sc.act2_override = 1
			sc.refresh()
			check(v.state_of(ato) == "available" and v.buy_node(ato), "covil: troca de ato abre depois do ato 2")
		sc.confirm_refund_all()
		check(m.almas == m.almas_earned and m.upgrades.is_empty(), "covil: reembolsar tudo devolve tudo")
		sc.queue_free()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Frente H (22/11/2026): HUD dos poderes. Ícones com recarga, painel de revelação (novo e evolução) e Continuar.
func t_power_hud() -> void:
	var s := _sim(7, "ruin")
	s.powers.append({"id": "fire_burst", "level": 2, "cd_left": 9.0, "gap_left": 0.0})
	s.powers.append({"id": "ally_rat", "level": 1, "cd_left": 0.0, "gap_left": 0.0})
	var h := Hud.new()
	add_child(h)
	h.offer_chosen.connect(func(k): s.choose(k))
	h.bind(s)
	h.refresh(0.016, 60.0)
	h._layout()
	check(h.power_badges.size() == 2 and h.power_row.visible, "hud: um icone por poder da party (%d)" % h.power_badges.size())
	var b0: Hud.PowerBadge = h.power_badges[0]
	var tot := float(s.party_powers()[0]["cd_total"])
	check(absf(b0.frac - 9.0 / tot) < 0.01 and b0.secs == 9 and not b0.ok_ready, "hud: recarga cheia de segundos (%.2f, %d s)" % [b0.frac, b0.secs])
	check(ResourceLoader.exists("res://assets/ui/powers/fire_burst.svg") and b0.tex != null, "hud: icone SVG do poder carregado")
	for k in 20:
		s.step()
	h.refresh(0.016, 60.0)
	check(b0.frac < 9.0 / tot and b0.secs <= 9, "hud: recarga atualiza com o tempo (%.3f)" % b0.frac)
	h.handle_events([[K.Ev.POWER_TRIGGER, 0.0, 0.0, 0, 0]])
	h.refresh(0.016, 60.0)
	check(b0.flash > 0.9, "hud: icone pisca quando o poder dispara")
	check(not Hud.power_icon("nao_existe", 20.0).texture and Hud.power_icon("war_hound", 20.0).texture != null, "hud: icone ausente nao quebra")
	# Muitos poderes: quebra em linhas dentro da largura, sem estourar.
	var many := _sim(7, "ruin")
	for i in 30:
		many.powers.append({"id": data.power_ids[i % data.power_ids.size()], "level": 1 + i % 3, "cd_left": float(i), "gap_left": 0.0})
	var h2 := Hud.new()
	add_child(h2)
	h2.bind(many)
	h2.refresh(0.016, 60.0)
	h2._layout()
	check(h2.power_badges.size() == 30 and h2.power_row.size.x <= get_viewport().get_visible_rect().size.x * 0.5 + 1.0 and h2.power_row.size.y > 28.0, "hud: 30 poderes quebram em linhas (%s)" % str(h2.power_row.size))
	h2.queue_free()
	# Painel de revelacao: depois da oferta de carta; novo e evolucao; Continuar fecha.
	var n := _sim(9, "ruin")
	var seen_new := false
	var seen_evo := false
	for k in 8:
		n.offers.clear()
		n.hero.hp = 0.0
		for f in n.followers:
			f.hp = 0.0
		n._check_end()
		if n.offers.is_empty() or str(n.offers.back()["source"]) != "power":
			break
		var op: Dictionary = n.offers.back()["options"][0]
		seen_new = seen_new or bool(op["new"])
		seen_evo = seen_evo or not bool(op["new"])
		var h3 := Hud.new()
		add_child(h3)
		h3.offer_chosen.connect(func(kk): n.choose(kk))
		h3.bind(n)
		var keep: Array = [n.offers.back()]
		n.offers = keep
		h3.refresh(0.016, 60.0)
		h3._layout()
		check(h3.power_layer.visible and not h3.offer_layer.visible and h3.offer_ready(), "hud: painel do poder aparece com a oferta power (%s)" % str(op["id"]))
		check(h3.power_box.size.x > 300.0 and h3.power_box.get_child_count() == 1, "hud: painel montado com o poder e a lista da party")
		h3.power_continue.pressed.emit()
		h3.refresh(0.016, 60.0)
		check(n.offers.is_empty() and not h3.power_layer.visible, "hud: Continuar fecha o painel (choose)")
		h3.queue_free()
		if seen_new and seen_evo:
			break
	check(seen_new, "hud: painel de poder novo exercitado")
	h.queue_free()
## Frente J (21/11/2026): bots na run de 15 parties. Fumaça: oferta de poder fecha, BotRun.run devolve o dicionário,
## mods de meta maxada aplicam. Nada de balanço.
func t_bots15() -> void:
	# Oferta "power": o bot fecha (os dois bots).
	for bid in ["heuristic", "human"]:
		var s := _phase_sim(1, 5)
		s.offers.append({"source": "power", "options": [{"kind": "power", "id": "x", "level": 1, "prev_level": 0, "new": true}]})
		var b := PlayerBot.load_bot(bid, 5)
		b.think(s)
		check(s.offers.is_empty(), "bot %s fecha a oferta de poder" % bid)
	# Run completa com limite de tempo simulado pequeno.
	var r := BotRun.run(data, 3, MetaApply.defaults(), [], {"max_t": 120.0})
	check(r.has("result") and r.has("parties_beaten") and r.has("t") and r.has("stats"), "BotRun.run devolve o dicionario")
	check(float(r["t"]) > 0.0 and float(r["t"]) < 200.0 and int(r["parties_beaten"]) >= 0, "BotRun.run respeita o limite de tempo (%.0f s)" % float(r["t"]))
	# Meta maxada.
	var mm := BotRun.maxed_mods(data)
	var nm := MetaApply.defaults()
	check(float(mm["elixir"]["max"]) > float(nm["elixir"]["max"]), "meta maxada: elixir maximo maior (+%.1f)" % float(mm["elixir"]["max"]))
	var lv_ok: bool = mm["card_levels"].size() > 0
	for id in mm["card_levels"]:
		lv_ok = lv_ok and int(mm["card_levels"][id]) == 6
	check(lv_ok and mm["deck"].size() == MetaSave.DECK_SIZE, "meta maxada: cartas no nivel VI e deck de 19")
	check(mm["reliquias"]["unlocked"].size() == data.relics.size(), "meta maxada: reliquias liberadas")
	var r2 := BotRun.run(data, 3, mm, [], {"max_t": 60.0})
	check(r2.has("result") and float(r2["t"]) > 0.0, "BotRun.run com meta maxada sem erro")
	# Opcional (--runs): runs completas de verificação de números absurdos (não faz parte da fumaça).
	if "--runs" in OS.get_cmdline_user_args():
		for sd in [1, 2, 3]:
			for tag in ["sem meta", "meta maxada"]:
				var t0 := Time.get_ticks_msec()
				var rr := BotRun.run(data, sd, MetaApply.defaults() if tag == "sem meta" else mm, [], {"max_t": 6000.0})
				print("RUN %s seed %d: %s, parties %d, t %.0f s, ticks %d, quedas %d, %d ms reais" % [tag, sd, rr["result"], rr["parties_beaten"], rr["t"], rr["ticks"], int(rr["stats"].get("heroes_fallen", 0)), Time.get_ticks_msec() - t0])
## Frente G (21/11/2026), fumaça: menu → Covil → escolher vilão monta o Sim com mods e deck; apply_run no fim de uma run
## curta do bot alimenta a tela de fim; o save da run retoma com os mesmos mods; a pausa lista os poderes.
func t_menus() -> void:
	var path := "user://test_menus.save"
	var rpath := "user://test_menus_run.save"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var m := MetaSave.load_or_new(data, path)
	m.add_almas(500)
	m.card_levels["rat_horde"] = 3
	var first_node := ""
	for id in data.meta_nodes:
		if str(data.meta_nodes[id].get("parent", "")) == "":
			first_node = str(id)
			break
	check(first_node != "" and m.buy(first_node), "menus: comprou um nó da raiz da árvore")
	# O menu: título com recorde e Almas, Covil, escolha de vilão (deck 19/19, trancado), Biblioteca de volta.
	var menu := MainMenu.new()
	menu.theme = UiKit.make_theme()
	menu.setup(data, m)
	add_child(menu)
	check(menu.screen == "title" and menu.status_text().contains(str(m.almas)), "menus: o título mostra as Almas (%s)" % menu.status_text())
	m.best_party = 4
	check(menu.status_text().contains("4"), "menus: o título mostra o recorde")
	menu.covil.start_run.emit()
	check(menu.screen == "decks" and menu.preview_row.get_child_count() == 19, "menus: Começar run do Covil abre a escolha com o deck de 19")
	menu._focus_villain("dragon")
	check(menu.v_pick.disabled and menu.unlock_party("dragon") == 3 and menu.unlock_party("lich") == 6 and menu.locked_text("dragon").contains("3"), "menus: vilão trancado pede a party 3")
	menu._focus_villain("plague")
	check(not menu.v_pick.disabled and menu.v_edit.disabled == false, "menus: vilão liberado pode começar e editar o deck")
	menu.v_edit.pressed.emit()
	check(menu.screen == "collection" and menu.collection.tab == "plague" and menu.lib_return == "decks", "menus: Editar deck abre a Biblioteca no vilão")
	menu.collection.closed.emit()
	check(menu.screen == "decks", "menus: a Biblioteca volta à escolha de vilão")
	var picked := []
	menu.deck_chosen.connect(func(id): picked.append(id))
	menu.v_pick.pressed.emit()
	check(picked == ["plague"] and m.villain == "plague", "menus: Começar escolhe o vilão")
	menu.show_screen("covil")
	check(menu.covil.visible and not menu.deck_screen.visible, "menus: o Covil abre")
	menu.queue_free()
	# O Sim que o main monta ao Começar: deck montado e mods da meta.
	var sim := Sim.new()
	sim.setup(data, 11, "plague", m.deck_for("plague"), m.unlocked, 1, MetaApply.run_mods(m))
	check(sim.cards.size() == 19 and sim.mods["deck"].size() == 19, "menus: o Sim começa com o deck de 19")
	check(int(sim.mods["card_levels"].get("rat_horde", 1)) == 3, "menus: o Sim leva os níveis de carta da meta")
	# A pausa lista os poderes da party.
	sim.powers.append({"id": "fire_burst", "level": 2, "cd_left": 0.0, "gap_left": 0.0})
	var pl: Array = sim.party_powers()
	var info: Dictionary = HeroPowers.describe(sim, "fire_burst", 2)
	check(pl.size() == 1 and info.has("name") and str(info["desc"]) != "" and not str(info["desc"]).contains("{"), "menus: poder da party com nome e efeito para a pausa")
	check(not Tips.power_entries(data, "fire_burst", 2).is_empty(), "menus: caixas de dica do poder")
	# Save da run retomado com os mesmos mods.
	for i in 300:
		sim.step()
	check(SaveGame.save(sim, rpath), "menus: salvou a run")
	var c := SaveGame.load_run(data, rpath)
	check(c != null and c.mods == sim.mods and c.cards.size() == 19 and int(c.mods["card_levels"].get("rat_horde", 1)) == 3, "menus: a run retomada guarda os mods")
	check(c != null and c.party_powers().size() == 1, "menus: a run retomada guarda os poderes")
	SaveGame.erase(rpath)
	# Fim de uma run curta do bot: apply_run alimenta a tela de fim.
	var r := Sim.new()
	r.setup(data, 9, "plague", m.deck_for("plague"), m.unlocked, 1, MetaApply.run_mods(m))
	r.auto_route = true
	var bot := PlayerBot.load_bot("greedy", 9)
	var n := 0
	while r.phase != K.Phase.OVER and n < 3000:
		bot.think(r)
		r.step()
		n += 1
	r.cur_party = 6
	r.stats["almas_dmg"] = 4000.0
	r.stats["heroes_fallen"] = 8
	r._finish(K.Result.LOSS)
	var a0 := m.almas
	var res := m.apply_run(r, path)
	check(int(res["party"]) == 6 and bool(res["new_best"]) and m.best_party == 6 and int(res["best"]) == 6, "menus: apply_run guarda o recorde (party 6)")
	check(int(res["almas"]["total"]) > 0 and m.almas == a0 + int(res["almas"]["total"]) and int(res["balance"]) == m.almas, "menus: apply_run soma as Almas ao saldo")
	var end := RunEnd.new()
	add_child(end)
	end.show_result(data, m, r, res)
	check(end.visible and end.menu_b != null, "menus: a tela de fim monta com os botões")
	check(end.find_child("NewBest", true, false) != null, "menus: novo recorde em destaque")
	var tot := end.find_child("AlmasTotal", true, false)
	check(tot != null and tot.find_children("*", "Label", true, false).any(func(l): return (l as Label).text == "+%d" % int(res["almas"]["total"])), "menus: a tela mostra o total de Almas")
	var got := []
	end.to_menu.connect(func(): got.append("menu"))
	end.menu_b.disabled = false
	end.menu_b.pressed.emit()
	check(got == ["menu"], "menus: o botão Menu emite o sinal")
	end.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Frente I (21/11/2026), fumaça: conservação do reembolso com Almas vindas de uma run (soma dos preços pagos = ganho - saldo,
## no save que volta do disco), e a aba Cartas do Compêndio mostra os níveis II a VI com o especial no VI.
func t_frente_i() -> void:
	var path := "user://test_frente_i.save"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var m := MetaSave.load_or_new(data, path)
	var s := _sim(9)
	s.stats["heroes_fallen"] = 4
	s.stats["parties_beaten"] = 2
	s.stats["almas_dmg"] = 6000.0
	s.result = K.Result.LOSS
	var res := m.apply_run(s, path)
	var gained := int(res["almas"]["total"])
	check(gained > 0 and m.almas == gained and m.almas_earned == gained, "reembolso: as Almas da run entram no saldo e no total ganho (%d)" % gained)
	m.add_almas(2000)
	var paid := 0
	for id in ["atr_elixir_max_1", "atr_elixir_max_1", "atr_elixir_regen_1"]:
		var c := m.node_cost(id)
		if c > 0 and m.buy(id):
			paid += c
	var cc := m.card_cost("rat_brute")
	if cc > 0 and m.buy_card_level("rat_brute"):
		paid += cc
	var rc := m.relic_cost("elixir_flask")
	if rc > 0 and m.buy_relic_level("elixir_flask"):
		paid += rc
	check(paid > 0 and m.almas_earned - m.almas == paid, "reembolso: soma dos preços pagos = ganho - saldo (%d)" % paid)
	m.save(path)
	var m2 := MetaSave.load_or_new(data, path)
	check(m2.almas_earned - m2.almas == paid, "reembolso: o save recarregado mantém a conta (%d)" % paid)
	check(m2.refund_all() == paid and m2.almas == m2.almas_earned and m2.upgrades.is_empty() and m2.card_levels.is_empty() and m2.relic_levels.is_empty(),
		"reembolso total devolve exatamente o gasto (almas == almas_earned)")
	check(m2.refund_all() == 0 and m2.almas == m2.almas_earned, "reembolsar de novo não devolve nada")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Compêndio: aba Cartas até o nível VI, com o especial no VI.
	var comp := CompendiumScreen.new()
	comp.setup(data, null)
	add_child(comp)
	comp.show_tab("cards")
	var texts: Array = []
	for l in comp.find_children("*", "RichTextLabel", true, false):
		texts.append((l as RichTextLabel).get_parsed_text())
	var all := "
".join(texts)
	check(all.contains("VI: ") and all.contains("II: ") and not all.contains("N2: ") and not all.contains("N3: "), "compêndio: aba Cartas mostra os níveis II a VI (sem N2/N3)")
	check(all.contains(TranslationServer.translate("UI_OPT_UP_N3")) and TranslationServer.translate("UI_OPT_UP_N3").contains("VI"), "compêndio: o especial aparece como o do nível VI")
	comp.queue_free()

