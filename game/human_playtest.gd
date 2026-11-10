class_name HumanPlaytest
extends Node
## Teste humano com o mouse (10/11/2026): o bot humano (bots/human_bot.gd) decide como uma pessoa, e cada
## decisão vira entrada real injetada no motor: o mouse passa sobre a carta, clica ou arrasta até o ponto do
## mundo, clica na carta da oferta, aperta o número do ramo, clica no altar. Nada chama o Sim por fora:
## se a interface não deixa fazer, a jogada não acontece e vira um achado.
##
## Como uma pessoa testando, de tempos em tempos ele também passa o mouse para ler uma carta, abre e fecha o
## mapa e pausa. A cada quadro confere invariantes (elixir, mão, seleção, oferta na tela). Grava capturas e um
## relatório (humantest.md e .json) em --out. Cada achado leva ao lado a causa interna (só para a triagem; o
## bot nunca usa isso para decidir).
##
##   godot --path . -- --humantest=human --deck=horde --phase=1 --seed=7 --speed=4 --out=C:/pasta/ [--minutes=15]
##
## Sai com 0 se não houve achado de interface, 1 se houve. Não toca no save do jogador (main.gd pula o
## autosave e as Almas neste modo).

var m: Node                 # game/main.gd
var bot: HumanBot
var rng := RandomNumberGenerator.new()
var queue: Array = []       # jogadas pedidas pelo bot, na ordem
var job := false            # uma jogada em execução (gesto de mouse em andamento)
var findings: Array = []    # {t, kind, msg, cause}
var tally := {}             # tipo de jogada -> [pedidas, feitas pela interface]
var out := ""
var shot_every := 45.0
var next_shot := 5.0
var next_extra := 20.0
var t_real := 0.0
var max_real := 900.0
var offer_seen_t := -1.0
var last_offer_key := ""
var shots := 0
var done := false


func run(main: Node, bot_id: String) -> void:
	m = main
	rng.seed = int(m.sim.run_seed) * 31 + 7
	out = str(m.auto_args.get("out", ""))
	if out != "" and not out.ends_with("/"):
		out += "/"
	if out != "":
		DirAccess.make_dir_recursive_absolute(out)
	max_real = float(m.auto_args.get("minutes", "15")) * 60.0
	bot = PlayerBot.load_bot(bot_id, m.sim.run_seed) as HumanBot
	if bot == null:
		push_error("humantest: o bot precisa ser do tipo human")
		m.get_tree().quit(2)
		return
	# --skip=<s>: o bot joga direto no Sim (sem mouse) até o instante s, para chegar rápido num trecho.
	if m.auto_args.has("skip"):
		var sk := float(m.auto_args["skip"])
		var s0: Sim = m.sim
		bot.hands = s0
		s0.record_events = false
		while s0.t < sk and s0.phase != K.Phase.OVER:
			bot.think(s0)
			s0.step()
		s0.record_events = true
	bot.hands = self
	# O cursor físico parado sobre a janela abre a prévia de uma carta: o teste pina o mouse do leque.
	m.hud.fan.mouse_override = Vector2(-10000, -10000)
	print("humantest: bot=%s deck=%s fase=%d semente=%d" % [bot_id, m.sim.deck_id, m.sim.campaign_phase, m.sim.run_seed])


# ---------------------------------------------------------------- executor (mesma interface do Sim)

func busy() -> bool:
	return job or queue.size() > 0


func play(i: int, x: float, y: float) -> int:
	queue.append({"k": "play", "i": i, "x": x, "y": y})
	return K.Block.OK


func sacrifice(i: int) -> bool:
	queue.append({"k": "sac", "i": i})
	return true


func choose(k: int) -> bool:
	queue.append({"k": "choose", "o": k})
	return true


func choose_route(n: int) -> bool:
	queue.append({"k": "route", "n": n})
	return true


func teleport(k: int) -> bool:
	queue.append({"k": "tp", "a": k})
	return true


# ---------------------------------------------------------------- laço

func _process(delta: float) -> void:
	if m == null or m.sim == null or done:
		return
	t_real += delta
	var s: Sim = m.sim
	_invariants()
	if out != "" and t_real >= next_shot:
		next_shot += shot_every
		_shot("t%04d" % int(s.t))
	if s.phase == K.Phase.OVER or t_real > max_real:
		done = true
		_finish()
		return
	if job:
		return
	if queue.is_empty():
		if t_real >= next_extra and s.offers.is_empty() and not s.route_wait and not m.paused and m.hud.selected < 0 and not m.hud.minimap.visible:
			next_extra = t_real + rng.randf_range(20.0, 45.0)
			_extra()
			return
		bot.think(s)
	if queue.size() > 0:
		_exec(queue.pop_front())


func _exec(j: Dictionary) -> void:
	job = true
	# Cena da queda do herói: o jogo segura cartas e cliques de propósito; a pessoa espera a cena acabar.
	var w := 0.0
	while (m.world.cine_active() or m.hud.hold_offers) and w < 8.0:
		await m.get_tree().process_frame
		w += get_process_delta_time()
	match str(j["k"]):
		"play":
			await _do_play(j)
		"sac":
			await _do_sac(j)
		"choose":
			await _do_choose(j)
		"route":
			await _do_route(j)
		"tp":
			await _do_tp(j)
	job = false


func _count(kind: String, ok: bool) -> void:
	var r: Array = tally.get(kind, [0, 0])
	r[0] += 1
	if ok:
		r[1] += 1
	tally[kind] = r


func _find(kind: String, msg: String, cause := "") -> void:
	var t: float = m.sim.t if m.sim else 0.0
	findings.append({"t": snappedf(t, 0.1), "kind": kind, "msg": msg, "cause": cause})
	print("humantest ACHADO [%s] t=%.0f %s %s" % [kind, t, msg, ("(" + cause + ")") if cause != "" else ""])
	if out != "" and findings.filter(func(f): return f["kind"] == kind).size() <= 2:
		_shot("achado_%s_%d" % [kind, findings.size()])


# ---------------------------------------------------------------- gestos

## Ponto do canvas -> pixel da janela (escala do conteúdo).
func _win(p: Vector2) -> Vector2:
	return m.get_viewport().get_final_transform() * p


func _mouse(p: Vector2, button := MOUSE_BUTTON_LEFT, pressed := true) -> void:
	var mb := InputEventMouseButton.new()
	mb.button_index = button
	mb.pressed = pressed
	mb.position = p
	mb.global_position = p
	Input.parse_input_event(mb)


func _move(p: Vector2, held := false) -> void:
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(mv)


func _click(p: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	_move(p)
	_mouse(p, button, true)
	_mouse(p, button, false)


func _tap(kc: Key) -> void:
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = kc
		ev.physical_keycode = kc
		ev.pressed = down
		Input.parse_input_event(ev)


func _frames(n: int) -> void:
	for _f in n:
		await m.get_tree().process_frame


func _played() -> int:
	var n := 0
	for k in m.sim.stats["played"]:
		n += int(m.sim.stats["played"][k])
	return n


## Ponto do mundo na tela (canvas). Fora da tela: o ponto visível mais perto, como a pessoa faria.
func _screen_of(x: float, y: float) -> Array:
	var w3 := Vector3(x, 0.0, y)
	var vis: Rect2 = m.get_viewport().get_visible_rect().grow(-40.0)
	if m.cam.is_position_behind(w3):
		return [vis.get_center(), false]
	var p: Vector2 = m.cam.unproject_position(w3)
	if vis.has_point(p):
		return [p, true]
	return [Vector2(clampf(p.x, vis.position.x, vis.end.x), clampf(p.y, vis.position.y, vis.end.y)), false]


## Carta k da mão: o centro dela na tela, pinando o mouse do leque nela enquanto o gesto dura.
func _card_point(k: int) -> Vector2:
	var c: Vector2 = m.hud.fan.card_rect(k).get_center()
	m.hud.fan.mouse_override = c - m.hud.fan.global_position
	return c


## O ponto da tela está coberto: painéis da HUD ou o leque de cartas (soltar ali não joga).
func _covered(p: Vector2) -> bool:
	if m.hud.blocks_world(p):
		return true
	var fan: Control = m.hud.fan
	var fr: Rect2 = fan.fan_rect().grow(12.0)
	return Rect2(fan.global_position + fr.position, fr.size).has_point(p)


func _unpin() -> void:
	m.hud.fan.mouse_override = Vector2(-10000, -10000)


# ---------------------------------------------------------------- jogadas

func _do_play(j: Dictionary) -> void:
	var s: Sim = m.sim
	var i := int(j["i"])
	if s.offers.size() > 0 or i >= s.hand.size() or s.hand[i] == null:
		return
	var cid: String = s.hand[i].def.id
	if cid == "burn_village":
		await _do_play_map(i, float(j["x"]), float(j["y"]))
		return
	# Carta ainda selecionada de antes: solta primeiro (clicar nela de novo a desselecionaria).
	if m.hud.selected >= 0:
		_click(_win(m.get_viewport().get_visible_rect().get_center()), MOUSE_BUTTON_RIGHT)
		await _frames(2)
	var p0 := _played()
	var sp: Array = _screen_of(float(j["x"]), float(j["y"]))
	var wp: Vector2 = sp[0]
	# Ponto embaixo da HUD (leque de cartas, painéis): a pessoa mira no chão livre mais perto, girando em
	# volta do herói. Conta quantas vezes o lugar pensado estava coberto (achado de UX, não de bug).
	if _covered(wp):
		_count("alvo coberto pela HUD (UX)", false)
		var h := Vector2(s.hero.x, s.hero.y)
		var v := Vector2(float(j["x"]), float(j["y"])) - h
		var found := false
		for a in [0.5, -0.5, 1.0, -1.0, 1.6, -1.6, 2.2, -2.2, 3.1]:
			for r in [1.0, 0.8, 1.3]:
				var q: Vector2 = h + v.rotated(a) * r
				var sq: Array = _screen_of(q.x, q.y)
				if sq[1] and not _covered(sq[0]) and s.valid_target(s.hand[i], q.x, q.y):
					wp = sq[0]
					j["x"] = q.x
					j["y"] = q.y
					found = true
					break
			if found:
				break
	var cp := _card_point(i)
	_move(_win(cp))
	await _frames(rng.randi_range(2, 6))   # olha a carta antes de jogar
	var drag := rng.randf() < 0.5
	if drag:
		_mouse(_win(cp), MOUSE_BUTTON_LEFT, true)
		await _frames(1)
		_unpin()
		for k in 5:
			_move(_win(cp.lerp(wp, (k + 1) / 5.0)), true)
			await _frames(1)
		_mouse(_win(wp), MOUSE_BUTTON_LEFT, false)
	else:
		_click(_win(cp))
		await _frames(2)
		_unpin()
		if m.hud.selected != i and s.hand_card(i) != null and s.hand_card(i).def.id == cid:
			var fan: Control = m.hud.fan
			var hv: Control = m.get_viewport().gui_get_hovered_control()
			_find("selecao", "clique na carta %d (%s) não a selecionou" % [i + 1, cid], "selecionada=%d, mão=%d, slot sob o clique=%d, leque pega mouse=%s, segura=%s, cena=%s, sob o mouse=%s" % [
				m.hud.selected, s.hand.size(), fan._slot_at(cp - fan.global_position), fan.mouse_filter != Control.MOUSE_FILTER_IGNORE,
				m.hud.hold_offers, m.world.cine_active(), str(hv.get_path()).get_slice("/", 4) + "/…/" + hv.name if hv else "nenhum"])
		# Incêndio abre o mapa grande: o clique vai no mapa (o mundo fica atrás).
		if m.hud.minimap.visible:
			_unpin()
		_move(_win(wp))
		await _frames(2)
		_click(_win(wp))
	await _frames(3)
	var ok := _played() > p0
	_count("jogar (" + ("arrastar" if drag else "clicar") + ")", ok)
	if not ok:
		bot.avoid_card(cid, s.t)
		var cause := _why_not(i, cid, float(j["x"]), float(j["y"]), wp, sp[1])
		var kind := "jogar_fora_da_tela" if not sp[1] else ("jogar" if cause.begins_with("interface") else "jogar_regra")
		if kind == "jogar":
			# Suspeita até repetir: o relatório separa o que se repete do que aconteceu uma vez.
			cause += "; cid=" + cid
		_find(kind, "%s não saiu pela interface (%s)" % [cid, "arrastar" if drag else "clicar"], cause)
		_click(_win(wp), MOUSE_BUTTON_RIGHT)   # solta a seleção, como a pessoa faria
		await _frames(1)


## Incêndio: a carta abre o mapa grande; a pessoa clica no local marcado no mapa.
func _do_play_map(i: int, x: float, y: float) -> void:
	var s: Sim = m.sim
	var p0 := _played()
	var cp := _card_point(i)
	_click(_win(cp))
	await _frames(4)
	_unpin()
	var mm: Control = m.hud.minimap
	var target := -1
	var bd := INF
	for n in s.road.nodes.size():
		var li: int = s.road.nodes[n]["loc"]
		if li >= 0 and s._burn_targets().has(li):
			var d: float = Vector2(x, y).distance_to(s.road.locations[li]["pos"])
			if d < bd:
				bd = d
				target = n
	var ok := false
	if not mm.visible:
		_find("mapa", "Incêndio selecionado e o mapa grande não abriu", "selecionada=%d" % m.hud.selected)
	elif target >= 0:
		await _frames(rng.randi_range(10, 25))   # procura o local no mapa
		_click(_win(mm.get_global_transform() * mm.node_point(target)))
		await _frames(4)
		ok = _played() > p0
	_count("jogar no mapa (Incêndio)", ok)
	if not ok:
		bot.avoid_card("burn_village", s.t)
		if target >= 0 and mm.visible:
			var cpnt: Vector2 = mm.get_global_transform() * mm.node_point(target)
			var local: Vector2 = mm.get_global_transform().affine_inverse() * cpnt
			_find("mapa", "clique no local do mapa não jogou o Incêndio", "nó %d, node_at no clique=%d, no alcance=%s, escala do mapa=%s, %d alvos, selecionada=%d" % [
				target, mm.node_at(local), s.road.reach.has(target), mm.get_global_transform().get_scale(), s._burn_targets().size(), m.hud.selected])
		# Desiste: botão direito solta a carta e fecha o mapa.
		_click(_win(m.get_viewport().get_visible_rect().get_center()), MOUSE_BUTTON_RIGHT)
		await _frames(3)
		if m.hud.selected >= 0 or (mm.visible and not s.route_wait):
			_find("cancelar", "botão direito com o mapa do Incêndio aberto não soltou a carta", "mapa=%s selecionada=%d" % [mm.visible, m.hud.selected])
			_tap(KEY_ESCAPE)
			await _frames(2)


## Por que a jogada não saiu: regra do jogo (elixir, alvo) ou interface (nada bloqueou no Sim).
func _why_not(i: int, cid: String, x: float, y: float, wp: Vector2, on_screen: bool) -> String:
	var s: Sim = m.sim
	if i >= s.hand.size() or s.hand[i] == null or s.hand[i].def.id != cid:
		return "a mão mudou durante o gesto"
	var b := s.can_play(i)
	if b != K.Block.OK:
		return "regra: bloqueio %d" % b
	if not s.valid_target(s.hand[i], x, y):
		return "regra: alvo inválido"
	if not on_screen:
		return "alvo fora da tela"
	var hov: Control = m.get_viewport().gui_get_hovered_control()
	var g: Vector3 = m._ground_point(wp)
	if not s.valid_target(s.hand[i], g.x, g.z):
		return "regra: o ponto do chão ficou inválido até soltar (o herói andou; %.1f m dele)" % Vector2(g.x - s.hero.x, g.z - s.hero.y).length()
	var gd := Vector2(g.x - s.hero.x, g.z - s.hero.y).length()
	return "interface: nada bloqueou no Sim; controle sob o ponto = %s, mapa=%s, pausa=%s, cena=%s, selecionada=%d, chão a %.1f m do herói (válido=%s)" % [
		hov.name if hov else "nenhum", m.hud.minimap.visible, m.paused, m.world.cine_active(), m.hud.selected, gd,
		s.valid_target(s.hand[i], g.x, g.z)]


func _do_sac(j: Dictionary) -> void:
	var s: Sim = m.sim
	var i := int(j["i"])
	if s.offers.size() > 0 or i >= s.hand.size() or s.hand[i] == null:
		return
	var n0: int = s.stats["sacrifices"]
	var cp := _card_point(i)
	_move(_win(cp))
	await _frames(2)
	_click(_win(cp), MOUSE_BUTTON_RIGHT)
	await _frames(3)
	_unpin()
	var ok: bool = s.stats["sacrifices"] > n0
	_count("sacrificar", ok)
	if not ok and s.sacrifice_ready() and not m.hud.hold_offers and not m.world.cine_active():
		_find("sacrificar", "botão direito na carta %d não sacrificou" % (i + 1), "sacrifício pronto; carta=%s, livre=%s" % [
			s.hand[i].def.id if i < s.hand.size() and s.hand[i] else "-", s.sacrifice_free(i)])


func _do_choose(j: Dictionary) -> void:
	var s: Sim = m.sim
	if s.offers.is_empty():
		return
	var k := int(j["o"])
	var key := str(s.offers[0])
	# Espera a oferta aparecer (a cena da queda do herói segura a oferta; as cartas chegam uma a uma).
	var wait := 0.0
	while wait < 6.0 and (m.hud.hold_offers or not _offer_ready()):
		await m.get_tree().process_frame
		wait += get_process_delta_time()
	if not _offer_ready():
		_find("oferta", "oferta aberta no Sim e invisível na tela por 6 s", "hold=%s" % m.hud.hold_offers)
	# Lê as opções: as cartas entram voando uma a uma (até ~1 s); a pessoa espera ver todas.
	var read_t := 0.0
	var want := rng.randf_range(1.0, 2.0)
	while read_t < want:
		await m.get_tree().process_frame
		read_t += get_process_delta_time()
	var target: Control = m.hud.offer_skip if k == Sim.SKIP else null
	if k != Sim.SKIP and k < m.hud.offer_slots.size():
		target = m.hud.offer_slots[k].get_meta("card", null)
	if target == null:
		_find("oferta", "opção %d da oferta sem controle na tela" % k, "%d opções no Sim" % s.offers[0]["options"].size())
	else:
		for attempt in 2:
			if not is_instance_valid(target):
				break
			var p: Vector2 = target.get_global_transform() * (target.size * 0.5)
			_click(_win(p))
			await _frames(4)
			if s.offers.is_empty() or str(s.offers[0]) != key or not is_instance_valid(target):
				break
			if attempt == 0:
				_count("oferta: primeiro clique ignorado (UX)", false)
				await _frames(20)
	var ok := s.offers.is_empty() or str(s.offers[0]) != key
	_count("oferta", ok)
	if not ok:
		var cause := "regra: o Sim recusa a opção" if not _sim_accepts(k) else "interface: clique não chegou"
		if cause.begins_with("interface"):
			_find("oferta", "clique na opção %d (%s) não escolheu" % [k, s.offers[0]["source"]], cause)
		# A pessoa tenta outra coisa: pular, ou a primeira opção que entrar.
		_click(_win(m.hud.offer_skip.get_global_transform() * (m.hud.offer_skip.size * 0.5)))
		await _frames(4)
		if s.offers.size() > 0 and str(s.offers[0]) == key:
			_tap(KEY_1)
			await _frames(3)


func _offer_ready() -> bool:
	return m.hud.offer_slots.size() > 0 and m.hud.offer_skip.is_visible_in_tree()


## Sem mexer no jogo: a opção seria aceita? (só preço e evento; o resto o Sim aceita).
func _sim_accepts(k: int) -> bool:
	var s: Sim = m.sim
	if k == Sim.SKIP:
		return true
	var op: Dictionary = s.offers[0]["options"][k]
	if str(s.offers[0]["source"]) == "shop":
		return s.can_afford(op)
	if str(op.get("kind", "")) == "event_opt":
		return s.event_option_ok(op)
	return true


func _do_route(j: Dictionary) -> void:
	var s: Sim = m.sim
	if not s.route_wait:
		return
	var outs: Array = s.road.nodes[s.road.head]["out"]
	var k := -1
	for e in outs.size():
		if int(s.road.legs[outs[e]]["b"]) == int(j["n"]):
			k = e
	if k < 0:
		k = 0
	await _frames(rng.randi_range(10, 30))   # olha o mapa
	_tap(KEY_1 + k)
	await _frames(3)
	var ok := not s.route_wait
	_count("rota (tecla)", ok)
	if not ok:
		_find("rota", "tecla %d na bifurcação não escolheu o ramo" % (k + 1), "%d ramos" % outs.size())


func _do_tp(j: Dictionary) -> void:
	var s: Sim = m.sim
	var a := int(j["a"])
	if s.phase != K.Phase.ARENA or not s.arena.can_teleport(a) or m.hud.selected >= 0:
		return
	var n0: int = s.stats["teleports"]
	var p: Vector2 = s.arena.altar_pos[a]
	var sp: Array = _screen_of(p.x, p.y)
	if not sp[1]:
		# Altar fora da tela: Q/E percorre os altares.
		_tap(KEY_E)
	else:
		_click(_win(sp[0]))
	await _frames(3)
	var ok: bool = s.stats["teleports"] > n0
	_count("teleporte (" + ("clique" if sp[1] else "tecla E") + ")", ok)
	if not ok and s.arena.can_teleport(a) and sp[1]:
		_find("teleporte", "clique no altar %d não teleportou" % a, "elixir %.1f" % s.elixir)


# ---------------------------------------------------------------- o que uma pessoa testando faz

func _extra() -> void:
	job = true
	match rng.randi_range(0, 3):
		0:
			# Passa o mouse numa carta para ler: a carta amplia.
			if m.sim.hand.size() > 0:
				var k := rng.randi_range(0, m.sim.hand.size() - 1)
				_move(_win(_card_point(k)))
				await _frames(8)
				var ok: bool = m.hud.fan.preview != null and m.hud.fan.hover == k
				_count("ler carta (passar o mouse)", ok)
				if not ok:
					_find("leitura", "mouse sobre a carta %d não ampliou" % (k + 1), "hover=%d" % m.hud.fan.hover)
				_unpin()
				await _frames(2)
		1:
			# Abre e fecha o mapa grande.
			_tap(KEY_M)
			await _frames(6)
			var opened: bool = m.hud.minimap.visible
			_tap(KEY_M)
			await _frames(4)
			var ok: bool = opened and not m.hud.minimap.visible
			_count("mapa (M)", ok)
			if not ok:
				_find("mapa", "M não abriu e fechou o mapa", "aberto=%s depois=%s" % [opened, m.hud.minimap.visible])
		2:
			# Pausa: o tempo do jogo para; Espaço volta.
			_tap(KEY_SPACE)
			await _frames(3)
			var t0: float = m.sim.t
			await _frames(10)
			var frozen: bool = m.paused and is_equal_approx(m.sim.t, t0)
			_tap(KEY_SPACE)
			await _frames(3)
			var ok: bool = frozen and not m.paused
			_count("pausar (Espaço)", ok)
			if not ok:
				_find("pausa", "Espaço não pausou ou não voltou", "pausado=%s tempo parado=%s" % [m.paused, frozen])
		3:
			# Seleciona uma carta e desiste (botão direito): nada é jogado.
			if m.sim.hand.size() > 0:
				var p0 := _played()
				var k := rng.randi_range(0, m.sim.hand.size() - 1)
				_click(_win(_card_point(k)))
				await _frames(2)
				_unpin()
				_click(_win(m.get_viewport().get_visible_rect().get_center()), MOUSE_BUTTON_RIGHT)
				await _frames(3)
				var ok: bool = m.hud.selected == -1 and _played() == p0
				_count("desistir da carta (botão direito)", ok)
				if not ok:
					_find("cancelar", "botão direito não soltou a carta", "selecionada=%d" % m.hud.selected)
	job = false


# ---------------------------------------------------------------- invariantes e relatório

func _invariants() -> void:
	var s: Sim = m.sim
	if s.elixir < -0.001 or s.elixir > s.elixir_max + 0.001:
		_find("invariante", "elixir fora da faixa: %.2f" % s.elixir)
	if s.phase != K.Phase.OVER and s.hand.size() != mini(s.hand_size, Sim.HAND_MAX) and s.queue.size() > 0:
		_find("invariante", "mão com %d cartas (tamanho %d) com baralho" % [s.hand.size(), s.hand_size])
	if m.hud.selected >= s.hand.size():
		_find("invariante", "seleção %d fora da mão" % m.hud.selected)
	# Oferta no Sim sem nada na tela (fora da cena da queda), ou o quadro preso sem oferta.
	if s.offers.size() > 0 and not m.hud.hold_offers:
		if offer_seen_t < 0.0:
			offer_seen_t = t_real
		elif t_real - offer_seen_t > 3.0 and not _offer_ready():
			_find("oferta", "oferta sem quadro na tela há 3 s", str(s.offers[0]["source"]))
			offer_seen_t = t_real + 1e6
	else:
		offer_seen_t = -1.0


func _shot(tag: String) -> void:
	if out == "" or DisplayServer.get_name() == "headless":
		return
	shots += 1
	m.get_viewport().get_texture().get_image().save_png(out + "humantest_%02d_%s.png" % [shots, tag])


func _finish() -> void:
	await _frames(20)
	_shot("fim")
	var s: Sim = m.sim
	var ui := findings.filter(func(f): return not str(f["kind"]) in ["jogar_regra", "jogar_fora_da_tela"])
	var rep := {"deck": s.deck_id, "phase": s.campaign_phase, "seed": s.run_seed, "result": s.stats["result"],
		"t_game": snappedf(s.t, 0.1), "t_real": snappedf(t_real, 0.1), "tally": tally, "bot": bot.stats,
		"findings": findings, "ui_findings": ui.size()}
	if out != "":
		var f := FileAccess.open(out + "humantest.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(rep, " "))
		f.close()
		f = FileAccess.open(out + "humantest.md", FileAccess.WRITE)
		f.store_string(_md(rep))
		f.close()
	print("humantest resultado: %s em %.0f s de jogo; achados de interface: %d; jogadas: %s" % [s.stats["result"], s.t, ui.size(), tally])
	m.get_tree().quit(0 if ui.is_empty() else 1)


func _md(r: Dictionary) -> String:
	var L := ["# Teste humano com o mouse", "",
		"Pacto **%s**, fase %d, semente %d. Resultado: **%s** em %.0f s de jogo (%.0f s reais)." % [r["deck"], r["phase"], r["seed"], r["result"], r["t_game"], r["t_real"]],
		"", "## Jogadas pela interface", "", "| jogada | pedidas | feitas |", "|---|---|---|"]
	for k in r["tally"]:
		L.append("| %s | %d | %d |" % [k, r["tally"][k][0], r["tally"][k][1]])
	L += ["", "## Achados (%d de interface)" % r["ui_findings"], ""]
	if r["findings"].is_empty():
		L.append("Nenhum.")
	for f in r["findings"]:
		L.append("- t=%s [%s] %s — %s" % [f["t"], f["kind"], f["msg"], f["cause"]])
	L += ["", "## Bot", "", str(r["bot"])]
	return "\n".join(L) + "\n"
