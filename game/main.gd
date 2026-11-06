extends Node3D
## Cena principal: menu → run → resultado. Roda o Sim num acumulador de passo fixo e traduz entrada em comandos.

var data: GameData
var sim: Sim
var world: WorldView
var hud: Hud
var cam: Camera3D
var acc := 0.0
var speed := 1.0
var paused := false
var running := false
var sac_mode := false
var cursor := Vector2.ZERO        # cursor virtual do controle (tela)
var pad_active := false
var arena_built := false
var b_hold := 0.0
var auto_bot: PlayerBot
var auto_args := {}
var shots: Array = []
var life := 0.0


func _ready() -> void:
	TranslationServer.set_locale("pt")
	data = GameData.load_dir()
	_env()
	world = WorldView.new()
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	hud.deck_chosen.connect(_start)
	hud.card_pressed.connect(_select)
	hud.card_sacrificed.connect(_sacrifice)
	hud.offer_chosen.connect(func(k): if sim: sim.choose(k))
	hud.restart.connect(func():
		running = false
		hud.result_panel.visible = false
		hud.show_menu(true))
	hud.minimap_clicked.connect(_minimap_click)
	hud.show_menu(true)
	_pad_actions()
	cursor = get_viewport().get_visible_rect().size * 0.5
	# Modo de teste: --autoplay=greedy --deck=horde --speed=4 --quit=60 --shots=10,30 --out=user://
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			auto_args[kv[0]] = kv[1]
	if auto_args.has("autoplay"):
		_start(str(auto_args.get("deck", "horde")))
		auto_bot = PlayerBot.load_bot(str(auto_args["autoplay"]), sim.run_seed)
		speed = float(auto_args.get("speed", "4"))
		var skip := float(auto_args.get("skip", "0"))
		sim.record_events = false
		while sim.t < skip and sim.phase != K.Phase.OVER:
			auto_bot.think(sim)
			sim.step()
		sim.record_events = true
		for t in str(auto_args.get("shots", "")).split(",", false):
			shots.append(float(t))


func _env() -> void:
	cam = Camera3D.new()
	cam.fov = 42
	cam.far = 600
	add_child(cam)
	cam.position = Vector3(0, 20, 14)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, 35, 0)
	light.light_energy = 1.1
	light.light_color = Color(0.85, 0.8, 1.0)
	light.shadow_enabled = true
	add_child(light)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.04, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.32, 0.5)
	env.ambient_light_energy = 0.8
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.1, 0.2)
	env.fog_density = 0.006
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)


func _pad_actions() -> void:
	var defs := {"pad_prev": JOY_BUTTON_LEFT_SHOULDER, "pad_next": JOY_BUTTON_RIGHT_SHOULDER, "pad_confirm": JOY_BUTTON_A,
		"pad_back": JOY_BUTTON_B, "pad_map": JOY_BUTTON_BACK, "pad_altar_prev": JOY_BUTTON_DPAD_LEFT,
		"pad_altar_next": JOY_BUTTON_DPAD_RIGHT, "pad_pause": JOY_BUTTON_START}
	for a in defs:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
			var e := InputEventJoypadButton.new()
			e.button_index = defs[a]
			InputMap.action_add_event(a, e)


func _start(deck: String) -> void:
	sim = Sim.new()
	sim.setup(data, int(Time.get_unix_time_from_system()) % 1000000, deck)
	sim.record_events = true
	world.build(sim, cam)
	arena_built = false
	hud.bind(sim)
	hud.show_menu(false)
	running = true
	paused = false
	acc = 0.0


# ---------------------------------------------------------------- laço

func _process(delta: float) -> void:
	life += delta
	if auto_args.has("quit") and life >= float(auto_args["quit"]):
		print("autoplay fim: t=%.0f fase=%d resultado=%s unidades=%d fps=%d" % [sim.t, sim.phase, sim.stats["result"], sim.units.count, Engine.get_frames_per_second()])
		get_tree().quit(0)
		return
	if shots.size() > 0 and life >= float(shots[0]):
		shots.pop_front()
		var img := get_viewport().get_texture().get_image()
		var path := str(auto_args.get("out", "user://")) + "shot_%03d.png" % int(life)
		img.save_png(path)
		print("captura: ", path)
	if not running or sim == null:
		return
	if auto_bot:
		auto_bot.think(sim)
	if auto_args.has("stress"):
		_stress(int(auto_args["stress"]))
	_pad_cursor(delta)
	if not paused:
		acc = minf(acc + delta * speed, sim.dt * 12.0)
		while acc >= sim.dt:
			sim.step()
			acc -= sim.dt
			world.handle_events(sim.events)
			sim.events.clear()
			if sim.offers.size() > 0:
				acc = 0.0
				break
	if sim.phase == K.Phase.ARENA and not arena_built:
		arena_built = true
		world.build_arena()
		hud.say(tr("UI_ARENA"))
	var alpha := clampf(acc / sim.dt, 0.0, 1.0)
	world.draw(alpha, delta)
	_update_placement()
	hud.refresh(delta, Engine.get_frames_per_second())


## Teste de estresse: mantém N unidades vivas e o herói imortal; mede o FPS.
var fps_samples: Array = []


func _stress(n: int) -> void:
	sim.hero.hp = sim.hero.max_hp()
	var kinds := ["rat", "bat", "skeleton", "rat_horde", "slime", "ogre"]
	var k := 0
	while sim.units.count < n and k < 60:
		var c: CardDef = data.card(kinds[(sim.units.count + k) % kinds.size()])
		var a := randf() * TAU
		var r := randf_range(3.0, 14.0)
		sim.units.spawn(c, sim.hero.x + cos(a) * r, sim.hero.y + sin(a) * r, 0.0, 0.0, K.F_NO_XP, 0)
		k += 1
	if life > 5.0:
		fps_samples.append(Engine.get_frames_per_second())
	if fps_samples.size() > 0 and fps_samples.size() % 120 == 0:
		var lo: float = fps_samples.min()
		var avg := 0.0
		for f in fps_samples:
			avg += f
		print("stress: unidades=%d fps_med=%.0f fps_min=%.0f" % [sim.units.count, avg / fps_samples.size(), lo])


func _ground_point(screen: Vector2) -> Vector3:
	var o := cam.project_ray_origin(screen)
	var n := cam.project_ray_normal(screen)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(o, n)
	return hit if hit != null else Vector3.ZERO


func _pointer() -> Vector2:
	return cursor if pad_active else get_viewport().get_mouse_position()


func _update_placement() -> void:
	var ci := sim.hand_card(hud.selected)
	if ci == null or sim.phase == K.Phase.OVER:
		world.show_placement(false, Vector3.ZERO, true, 1.0)
		return
	var p := _ground_point(_pointer())
	var d := ci.def
	var r: float = d.fx.get("radius", 1.0)
	world.show_placement(d.category == "field" or d.id == "gold_bait", p, sim.valid_target(ci, p.x, p.z), r)


# ---------------------------------------------------------------- comandos

func _select(i: int) -> void:
	if sim == null or sim.phase == K.Phase.OVER:
		return
	if sac_mode:
		sac_mode = false
		_sacrifice(i)
		return
	var ci := sim.hand_card(i)
	if ci == null:
		return
	hud.selected = -1 if hud.selected == i else i
	# Cartas sem alvo (covil, finalização) saem na hora.
	if hud.selected >= 0 and (ci.def.category == "lair" or ci.def.category == "finisher"):
		_play_at(Vector2(sim.hero.x, sim.hero.y))


func _sacrifice(i: int) -> void:
	if sim and sim.sacrifice(i):
		hud.selected = -1


func _play_at(p: Vector2) -> void:
	var i := hud.selected
	if i < 0:
		return
	var b := sim.play(i, p.x, p.y)
	if b == K.Block.OK:
		hud.selected = -1
	else:
		hud.say(tr("UI_BLOCK_%d" % mini(b, 5)))
		if b != K.Block.NO_ELIXIR and b != K.Block.BAD_TARGET:
			hud.selected = -1


func _minimap_click(p: Vector2) -> void:
	if sim and hud.selected >= 0:
		_play_at(p)


func _altar_step(dir: int) -> void:
	if sim == null or sim.phase != K.Phase.ARENA:
		return
	var A := sim.arena
	var n := A.altar_pos.size()
	var k := A.altar
	for _t in n:
		k = (k + dir + n) % n
		if A.can_teleport(k):
			sim.teleport(k)
			return


func _click_world(screen: Vector2) -> void:
	var g := _ground_point(screen)
	var p := Vector2(g.x, g.z)
	if hud.selected >= 0:
		_play_at(p)
		return
	if sim.phase == K.Phase.ARENA:
		for k in sim.arena.altar_pos.size():
			if p.distance_to(sim.arena.altar_pos[k]) < 2.0:
				sim.teleport(k)
				return


func _unhandled_input(e: InputEvent) -> void:
	if not running or sim == null:
		return
	if e is InputEventMouseMotion:
		pad_active = false
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if sim.offers.is_empty():
				_click_world(e.position)
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			hud.selected = -1
	if e is InputEventKey and e.pressed and not e.echo:
		var kc: int = e.keycode
		if kc >= KEY_1 and kc <= KEY_9:
			var n := kc - KEY_1
			if sim.offers.size() > 0:
				sim.choose(n)
			else:
				_select(n)
		match kc:
			KEY_X:
				sac_mode = true
			KEY_ESCAPE:
				hud.selected = -1
				sac_mode = false
			KEY_SPACE:
				paused = not paused
				hud.say(tr("UI_PAUSED") if paused else "")
			KEY_F:
				speed = 1.0 if speed >= 8.0 else speed * 2.0
				hud.say(tr("UI_SPEED").format({"n": int(speed)}))
			KEY_M:
				_toggle_map()
			KEY_Q:
				_altar_step(-1)
			KEY_E:
				_altar_step(1)
	if e is InputEventKey and not e.pressed and e.keycode == KEY_X:
		sac_mode = false
	_pad_input(e)


func _toggle_map() -> void:
	var mm := hud.minimap
	var big := mm.size.x < 400
	mm.size = Vector2(620, 620) if big else Vector2(260, 260)
	mm.setup(sim)


# ---------------------------------------------------------------- controle

func _pad_input(e: InputEvent) -> void:
	if not (e is InputEventJoypadButton or e is InputEventJoypadMotion):
		return
	pad_active = true
	if e.is_action_pressed("pad_pause"):
		paused = not paused
	if sim.offers.size() > 0:
		if e.is_action_pressed("pad_prev") or e.is_action_pressed("pad_next"):
			var d := -1 if e.is_action_pressed("pad_prev") else 1
			hud.selected = wrapi(hud.selected + d, 0, sim.offers[0]["options"].size())
		if e.is_action_pressed("pad_confirm"):
			sim.choose(maxi(hud.selected, 0))
			hud.selected = -1
		return
	if e.is_action_pressed("pad_prev") or e.is_action_pressed("pad_next"):
		var d := -1 if e.is_action_pressed("pad_prev") else 1
		hud.selected = wrapi(hud.selected + d, 0, sim.hand.size())
	if e.is_action_pressed("pad_confirm"):
		if hud.selected >= 0:
			var ci := sim.hand_card(hud.selected)
			if ci and (ci.def.category == "lair" or ci.def.category == "finisher"):
				_play_at(Vector2(sim.hero.x, sim.hero.y))
			else:
				_click_world(cursor)
	if e.is_action_pressed("pad_back"):
		b_hold = 0.0
	if e.is_action_pressed("pad_map"):
		_toggle_map()
	if e.is_action_pressed("pad_altar_prev"):
		_altar_step(-1)
	if e.is_action_pressed("pad_altar_next"):
		_altar_step(1)


func _pad_cursor(delta: float) -> void:
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if v.length() > 0.2:
		pad_active = true
		cursor += v * 900.0 * delta
		cursor = cursor.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size)
	# Segurar B sacrifica a carta selecionada.
	if Input.is_action_pressed("pad_back") and hud.selected >= 0:
		b_hold += delta
		if b_hold > 0.5:
			b_hold = 0.0
			_sacrifice(hud.selected)
