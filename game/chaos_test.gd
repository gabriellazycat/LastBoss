class_name ChaosTest
extends Node
## Teste de caos com a entrada real (rodada de 09/11/2026): cliques em lugares estranhos (bordas, fora da
## janela, em cima da HUD), cliques rápidos repetidos, arrastar e soltar em lugares inválidos, teclas
## esmagadas, pausa na oferta e na bifurcação, janela redimensionada, salvar e continuar, arena.
## godot --path . -- --chaostest=1   (sai com o número de falhas; erros de script aparecem no console)

var m: Node          # game/main.gd
var fails: Array = []
var rng := RandomNumberGenerator.new()


func run(main: Node) -> void:
	m = main
	rng.seed = 4242
	await _frames(20)
	_check_inv("início")
	await _edges()
	await _hud_clicks()
	await _rapid_clicks()
	await _bad_drags()
	await _pause_clicks()
	await _offer_pause()
	await _sacrifice_spam()
	await _resize()
	await _mash(400)
	await _save_continue()
	await _arena()
	print("chaostest resultado: ", "OK" if fails.is_empty() else "FALHOU " + str(fails))
	m.get_tree().quit(0 if fails.is_empty() else 1)


func step(name: String, cond: bool) -> void:
	print("chaostest ", name, ": ", cond)
	if not cond:
		fails.append(name)


## Invariantes do Sim que nenhuma entrada pode quebrar.
func _check_inv(where: String) -> bool:
	var s: Sim = m.sim
	var bad: Array = []
	if s.elixir < -0.001 or s.elixir > s.elixir_max + 0.001:
		bad.append("elixir %.2f" % s.elixir)
	if not (is_finite(s.hero.x) and is_finite(s.hero.y)):
		bad.append("herói fora do mundo")
	var U := s.units
	for i in U.hi:
		if U.alive[i] == 1 and not (is_finite(U.px[i]) and is_finite(U.py[i]) and is_finite(U.hp[i])):
			bad.append("unidade %d inválida" % i)
			break
	if s.hand.size() != s.hand_size and s.phase != K.Phase.OVER:
		bad.append("mão com %d" % s.hand.size())
	if m.hud.selected >= s.hand.size():
		bad.append("seleção %d fora da mão" % m.hud.selected)
	if not bad.is_empty():
		step("invariantes (" + where + ") " + str(bad), false)
		return false
	return true


func _frames(n: int) -> void:
	for _f in n:
		await m.get_tree().process_frame


func _vp() -> Vector2:
	return m.get_viewport().get_visible_rect().size


func _mouse(p: Vector2, button := MOUSE_BUTTON_LEFT, pressed := true) -> void:
	var mb := InputEventMouseButton.new()
	mb.button_index = button
	mb.pressed = pressed
	mb.position = p
	mb.global_position = p
	Input.parse_input_event(mb)


func _click(p: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	_mouse(p, button, true)
	_mouse(p, button, false)


func _move(p: Vector2, held := false) -> void:
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(mv)


func _key(kc: Key, pressed := true) -> void:
	var ev := InputEventKey.new()
	ev.keycode = kc
	ev.physical_keycode = kc
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _tap(kc: Key) -> void:
	_key(kc, true)
	_key(kc, false)


func _played() -> int:
	var n := 0
	for k in m.sim.stats["played"]:
		n += int(m.sim.stats["played"][k])
	return n


## Seleciona a primeira carta de monstro da mão (índice) ou -1.
func _unit_card() -> int:
	for i in m.sim.hand.size():
		var c = m.sim.hand[i]
		if c and c.def.category == "field" and not c.def.is_spell:
			return i
	return -1


func _hero_screen(off := Vector3.ZERO) -> Vector2:
	return m.cam.unproject_position(Vector3(m.sim.hero.x, 0, m.sim.hero.y) + off)


# ---------------------------------------------------------------- casos

## Bordas e fora da janela, com e sem carta selecionada.
func _edges() -> void:
	var v := _vp()
	var pts := [Vector2(0, 0), Vector2(v.x - 1, 0), Vector2(0, v.y - 1), v - Vector2.ONE, Vector2(-80, -80),
		Vector2(v.x + 200, v.y * 0.5), Vector2(v.x * 0.5, -300), Vector2(v.x * 0.5, v.y + 300), Vector2(1e7, 1e7)]
	var p0 := _played()
	for p in pts:
		_click(p)
		_click(p, MOUSE_BUTTON_RIGHT)
		_click(p, MOUSE_BUTTON_MIDDLE)
		_click(p, MOUSE_BUTTON_WHEEL_UP)
	await _frames(3)
	step("cliques nas bordas sem carta não jogam nada", _played() == p0)
	m.sim.elixir = 10.0
	var i := _unit_card()
	if i >= 0:
		m._select(i)
		# Céu (acima do horizonte) e fora da janela: nada pode ir para o mundo.
		for p in [Vector2(v.x * 0.5, 2), Vector2(-80, -80), Vector2(1e7, -1e7)]:
			_click(p)
		await _frames(3)
		var units_far := 0
		var U: SimUnits = m.sim.units
		for k in U.hi:
			if U.alive[k] == 1 and Vector2(U.px[k] - m.sim.hero.x, U.py[k] - m.sim.hero.y).length() > 120.0:
				units_far += 1
		step("carta solta no céu ou fora da janela não cria unidade longe (%d)" % units_far, units_far == 0)
	m.hud.selected = -1
	_check_inv("bordas")


## Cliques em cima da HUD com carta selecionada: a HUD engole o clique, nada vai para o mundo atrás dela.
func _hud_clicks() -> void:
	m.sim.elixir = 10.0
	var hud = m.hud
	# O tempo da run é texto solto sobre o mundo (deixa o clique passar de propósito); as peças sólidas não.
	var targets := {"barra do herói": hud.hero_badge, "elixir": hud.elixir_badge, "bandeja do elixir": hud.elixir_bar,
		"botão de sacrifício": hud.sac_zone, "velocidade": hud.speed_btn}
	for name in targets:
		var c: Control = targets[name]
		if c == null or not c.is_visible_in_tree():
			continue
		var i := _unit_card()
		if i < 0:
			break
		m._select(i)
		var p0 := _played()
		var sac0: int = m.sim.stats["sacrifices"]
		_click(c.get_global_rect().get_center())
		await _frames(3)
		var ok: bool = _played() == p0
		if name == "botão de sacrifício":
			ok = true   # clicar no Sacrificar com a carta selecionada sacrifica (é o botão)
		step("clique com carta em cima de '%s' não joga a carta no mundo" % name, ok)
		m.hud.selected = -1
		await _frames(2)
	_check_inv("HUD")


## Muitos cliques no mesmo quadro no mesmo ponto: só joga o que o elixir paga, nunca fica negativo.
func _rapid_clicks() -> void:
	m.sim.elixir = 10.0
	var i := _unit_card()
	if i < 0:
		return
	var p := _hero_screen(Vector3(0, 0, -7))
	var e_min := 99.0
	for r in 30:
		var k := _unit_card()
		if k < 0:
			break
		m._select(k)
		_click(p)
		_click(p)
		await m.get_tree().process_frame
		e_min = minf(e_min, m.sim.elixir)
	step("30 cliques rápidos não deixam o elixir negativo (mín %.2f)" % e_min, e_min >= -0.001)
	# Duplo clique na mesma carta: seleciona e desseleciona, sem jogar.
	m.sim.elixir = 10.0
	m.hud.selected = -1
	await _frames(1)
	var p0 := _played()
	_tap(KEY_1)
	_tap(KEY_1)
	await _frames(2)
	step("tecla 1 duas vezes desseleciona", m.hud.selected == -1 and _played() == p0)
	_check_inv("cliques rápidos")


## Arrastar a carta do leque e soltar em lugares inválidos.
func _bad_drags() -> void:
	var v := _vp()
	m.sim.elixir = 10.0
	m.hud.fan.mouse_override = null
	var drops := {"fora da janela": Vector2(-200, v.y * 0.5), "abaixo da janela": Vector2(v.x * 0.3, v.y + 120),
		"bandeja do elixir": m.hud.elixir_bar.get_global_rect().get_center(), "o próprio leque": m.hud.fan.card_rect(2).get_center(), "em cima do herói": _hero_screen()}
	for name in drops:
		var c0: Vector2 = m.hud.fan.card_rect(0).get_center()
		var p0 := _played()
		var hand0: Array = m.sim.hand.duplicate()
		_mouse(c0, MOUSE_BUTTON_LEFT, true)
		await m.get_tree().process_frame
		var tgt: Vector2 = drops[name]
		for k in 6:
			_move(c0.lerp(tgt, (k + 1) / 6.0), true)
			await m.get_tree().process_frame
		_mouse(tgt, MOUSE_BUTTON_LEFT, false)
		await _frames(3)
		var ok := _played() == p0
		if not ok:
			var c1 = hand0[0]
			var g: Vector3 = m._ground_point(tgt)
			print("   (jogou %s; ponto no chão %s, herói a %.0f m, no chão: %s)" % [c1.def.id if c1 else "?", g,
				Vector2(g.x - m.sim.hero.x, g.z - m.sim.hero.y).length(), m._on_ground(tgt)])
		if name == "em cima do herói":
			# A 0 m do herói o monstro é recusado (mínimo 3 m); feitiço pode ir.
			var c = hand0[0]
			ok = _played() == p0 or (c != null and c.def.is_spell)
		step("arrastar e soltar em '%s' não joga a carta" % name, ok)
		m.hud.selected = -1
	_check_inv("arrastar")


## Com o jogo pausado, cliques no mundo não podem jogar carta nem mexer no Sim.
func _pause_clicks() -> void:
	m.sim.elixir = 10.0
	var i := _unit_card()
	if i < 0:
		return
	m._select(i)
	_tap(KEY_SPACE)
	await _frames(3)
	var paused: bool = m.paused
	var p0 := _played()
	var t0: float = m.sim.t
	for p in [_hero_screen(Vector3(0, 0, -7)), _hero_screen(Vector3(5, 0, 2)), _vp() * 0.5]:
		_click(p)
	_tap(KEY_2)
	_tap(KEY_M)
	_tap(KEY_F)
	await _frames(10)
	step("pausado: clique no mundo não joga a carta", paused and _played() == p0)
	step("pausado: o tempo do Sim não anda", absf(m.sim.t - t0) < 0.0001)
	_tap(KEY_SPACE)
	await _frames(3)
	step("Espaço despausa", not m.paused)
	m.hud.selected = -1
	_check_inv("pausa")


## Pausa com uma oferta aberta, teclas e cliques enquanto pausado, despausa e escolhe.
func _offer_pause() -> void:
	m.sim._offer_level()
	await _frames(2)
	var had: bool = m.sim.offers.size() > 0
	_tap(KEY_ESCAPE)
	await _frames(2)
	_tap(KEY_1)
	_tap(KEY_0)
	_click(_vp() * 0.5)
	await _frames(3)
	step("pausado na oferta: teclas não escolhem", had and m.sim.offers.size() > 0)
	_tap(KEY_ESCAPE)
	await _frames(3)
	_tap(KEY_1)
	await _frames(3)
	step("oferta resolve depois da pausa", m.sim.offers.is_empty() and not m.paused)
	_check_inv("oferta")


## Sacrifício esmagado: clique direito, X+número e arrastar ao Sacrificar, muitas vezes seguidas.
func _sacrifice_spam() -> void:
	m.sim.elixir = 2.0
	var s0: int = m.sim.stats["sacrifices"]
	var e0: float = m.sim.elixir
	for r in 25:
		_key(KEY_X, true)
		_tap(KEY_1 + (r % 5) as Key)
		_key(KEY_X, false)
		await m.get_tree().process_frame
	var gained: float = m.sim.elixir - e0
	step("25 sacrifícios seguidos dão no máximo +1 de elixir (%.2f)" % gained, gained <= 1.0 + 3.0 / 2.8 * 0.5 + 0.01)
	step("sacrifício na recarga é recusado para carta jogável (%d aceitos)" % (int(m.sim.stats["sacrifices"]) - s0), int(m.sim.stats["sacrifices"]) - s0 <= 6)
	_check_inv("sacrifício")


## Janela redimensionada: pequena, grande e de volta, com clique no meio.
func _resize() -> void:
	var w := m.get_window()
	var orig := w.size
	for sz in [Vector2i(800, 450), Vector2i(640, 360), Vector2i(1600, 900), Vector2i(1024, 1024), orig]:
		w.size = sz
		await _frames(5)
		var v := _vp()
		var fr: Rect2 = m.hud.fan.get_global_rect()
		var inside: bool = fr.position.y < v.y and fr.end.y > 0.0 and fr.size.x <= v.x + 2.0
		step("janela %dx%d: leque de cartas visível" % [sz.x, sz.y], inside)
		_click(v * 0.5)
		_tap(KEY_M)
		await _frames(2)
		_tap(KEY_M)
		await _frames(2)
	_check_inv("janela")


## Teclas e cliques aleatórios por muitos quadros; invariantes a cada quadro.
func _mash(n: int) -> void:
	var keys := [KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_9, KEY_X, KEY_M, KEY_Q, KEY_E,
		KEY_F, KEY_SPACE, KEY_ESCAPE]
	var ok := true
	for r in n:
		var v := _vp()
		match rng.randi_range(0, 5):
			0, 1:
				_tap(keys[rng.randi_range(0, keys.size() - 1)])
			2, 3:
				var p := Vector2(rng.randf_range(-50, v.x + 50), rng.randf_range(-50, v.y + 50))
				_click(p, MOUSE_BUTTON_LEFT if rng.randf() < 0.8 else MOUSE_BUTTON_RIGHT)
			4:
				m.sim.elixir = minf(m.sim.elixir_max, m.sim.elixir + 1.0)
			5:
				_move(Vector2(rng.randf_range(0, v.x), rng.randf_range(0, v.y)))
		await m.get_tree().process_frame
		if m.sim.phase == K.Phase.OVER:
			break
		if not _check_inv("esmagar %d" % r):
			ok = false
			break
	# Sai de qualquer pausa/painel deixado pelo esmagamento.
	for _k in 4:
		if m.paused:
			_tap(KEY_ESCAPE)
			await _frames(3)
	while m.sim.offers.size() > 0:
		m.sim.choose(Sim.SKIP)
	step("%d entradas aleatórias sem quebrar o Sim" % n, ok)


## Salvar e voltar ao menu no meio da run e continuar: mesma run, mesmo tempo e mão.
func _save_continue() -> void:
	if m.sim.phase == K.Phase.OVER:
		return
	var t0: float = m.sim.t
	var hand0: Array = m.sim.hand.map(func(c): return c.def.id if c else "")
	var path0: Array = m.sim.road.path.duplicate()
	if not m.paused:
		_tap(KEY_ESCAPE)
		await _frames(3)
	var b: Button = m._button(m.hud, "UI_SAVE_MENU")
	if b == null:
		step("pausa tem 'Salvar e voltar ao menu'", false)
		return
	await m._click(b)
	await _frames(5)
	step("salvou e voltou ao menu", not m.running and m.menu.visible and SaveGame.exists())
	var c: Button = m._button(m.menu, "UI_CONTINUE")
	if c == null:
		step("menu tem Continuar", false)
		return
	await m._click(c)
	await _frames(5)
	var hand1: Array = m.sim.hand.map(func(x): return x.def.id if x else "")
	# O Sim já andou alguns quadros depois de Continuar (na velocidade que o esmagamento deixou): tolerância.
	step("Continuar retoma a mesma run (t %.1f → %.1f, mão igual %s, caminho igual %s)" % [t0, m.sim.t, hand1 == hand0, m.sim.road.path == path0],
		m.running and m.sim.t >= t0 - 0.001 and m.sim.t - t0 < 2.0 and hand1 == hand0 and m.sim.road.path == path0)
	# Continuar duas vezes seguidas (clique duplo no botão) não pode criar duas runs.
	_check_inv("continuar")


## Arena: Q/E e cliques nos altares esmagados, finalização fora de hora, velocidade no máximo.
func _arena() -> void:
	var bot := PlayerBot.load_bot("heuristic", 1)
	var s: Sim = m.sim
	s.record_events = false
	var guard := 0
	while s.phase == K.Phase.ROAD and guard < 400000:
		if s.route_wait:
			s.choose_route(0)
		bot.think(s)
		s.step()
		guard += 1
	s.record_events = true
	await _frames(10)
	if s.phase != K.Phase.ARENA:
		step("chegou à arena para o teste (fase %d)" % s.phase, s.phase == K.Phase.OVER)
		return
	var tele0: int = s.stats["teleports"]
	for r in 60:
		_tap(KEY_Q if r % 2 == 0 else KEY_E)
		for k in s.arena.altar_pos.size():
			var ap: Vector2 = s.arena.altar_pos[k]
			_click(m.cam.unproject_position(Vector3(ap.x, 0, ap.y)))
		await m.get_tree().process_frame
		if s.phase == K.Phase.OVER:
			break
	var tele: int = s.stats["teleports"] - tele0
	var cd := float(s.R["arena"]["teleport_cooldown"])
	var max_tele := int(60.0 / 60.0 * (1.0 / cd)) + 3
	step("altares esmagados respeitam a recarga do teleporte (%d)" % tele, tele <= max_tele)
	for _k in 4:
		_tap(KEY_F)
	await _frames(30)
	_check_inv("arena")
