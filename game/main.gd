extends Node3D
## Cena principal: menu → run → resultado. Roda o Sim num acumulador de passo fixo e traduz entrada em comandos.

var data: GameData
var meta: MetaSave
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
var map_auto := false             # o mapa grande abriu sozinho numa bifurcação (fecha quando o herói volta a andar)
var route_sel := 0                 # ramo destacado pelo controle na bifurcação
var auto_bot: PlayerBot
var auto_args := {}
var shots: Array = []
var life := 0.0


func _ready() -> void:
	Settings.load_all()
	Settings.apply(get_tree())
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			auto_args[kv[0]] = kv[1]
	# Testes e capturas salvam num arquivo próprio: nunca tocam na run salva do jogador.
	if not auto_args.is_empty():
		SaveGame.current = "user://test_run.save"
	for t in str(auto_args.get("shots", "")).split(",", false):
		shots.append(float(t))
	# --set=ui_scale:1.15,language:en muda configurações só nesta execução (não salva).
	for kv in str(auto_args.get("set", "")).split(",", false):
		var p := kv.split(":")
		if p.size() == 2 and Settings.v.has(p[0]):
			if not Settings.session.has(p[0]):
				Settings.session[p[0]] = Settings.v[p[0]]
			Settings.v[p[0]] = float(p[1]) if typeof(Settings.v[p[0]]) == TYPE_FLOAT else (p[1] if typeof(Settings.v[p[0]]) == TYPE_STRING else str_to_var(p[1]))
	Settings.apply(get_tree())
	# Pele Covil: todo botão que nascer leva o material da moldura (o tema só leva a StyleBox).
	UiSkins.apply()
	if UiSkins.covil() and not get_tree().node_added.is_connected(UiCovil.on_node_added):
		get_tree().node_added.connect(UiCovil.on_node_added)
	elif not UiSkins.covil() and get_tree().node_added.is_connected(UiCovil.on_node_added):
		get_tree().node_added.disconnect(UiCovil.on_node_added)
	if DisplayServer.get_name() != "headless":
		UiCovil.sync(get_viewport())
	data = GameData.load_dir()
	meta = MetaSave.load_or_new(data)
	if not auto_args.is_empty():
		meta.file = "user://test_meta.save"
	Tips.data = data
	add_child(Tips.new())
	audio = GameAudio.new()
	add_child(audio)
	_env()
	world = WorldView.new()
	add_child(world)
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 0
	add_child(fx_layer)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vs := Shader.new()
	vs.code = "shader_type canvas_item;
void fragment(){ vec2 d = UV - vec2(0.5); float v = smoothstep(0.32, 0.85, length(d * vec2(1.0, 0.8))); COLOR = vec4(0.02, 0.0, 0.05, v * 0.82); }"
	var vm := ShaderMaterial.new()
	vm.shader = vs
	vignette.material = vm
	fx_layer.add_child(vignette)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	fx_layer.add_child(flash_rect)
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	hud.card_pressed.connect(_select)
	hud.card_sacrificed.connect(_sacrifice)
	hud.offer_chosen.connect(func(k): if sim: sim.choose(k))
	hud.resume.connect(_toggle_pause)
	hud.to_menu.connect(_to_menu)
	hud.quit_game.connect(_quit)
	hud.speed_pressed.connect(_cycle_speed)
	hud.map_pressed.connect(func(): if sim: _toggle_map())
	hud.settings_changed.connect(_on_settings)
	menu = MainMenu.new()
	menu.theme = UiKit.make_theme()
	menu.setup(data, meta)
	layer.add_child(menu)
	menu.deck_chosen.connect(_start)
	menu.continue_run.connect(_continue)
	menu.settings_changed.connect(_on_settings)
	hud.minimap_clicked.connect(_minimap_click)
	hud.route_clicked.connect(_route_click)
	hud.card_dropped.connect(func(i: int, sp: Vector2):
		if sim and hud.selected == i:
			var mm := hud.minimap
			var st := hud.strip
			if mm.visible and mm.get_global_rect().has_point(sp):
				var dn := mm.node_at(sp - mm.global_position)
				if dn >= 0:
					_play_at(sim.road.nodes[dn]["pos"])
			elif st.visible and st.get_global_rect().has_point(sp):
				var w = st.target_at(sp - st.global_position)
				if w != null:
					_play_at(w)
			elif hud.blocks_world(sp):
				# Soltar fora da janela ou em cima da HUD cancela o arrasto (antes jogava a carta num
				# ponto do chão escondido, rodada 09/11/2026).
				hud.selected = -1
			else:
				_click_world(sp))
	if DisplayServer.get_name() != "headless":
		var art := CardArt.new()
		add_child(art)
		await art.render_all(data)
	_build_menu_scene()
	_show_menu(str(auto_args.get("menu", "title")))
	audio.music("music_road")
	audio.set_intensity(0.0)
	_pad_actions()
	cursor = get_viewport().get_visible_rect().size * 0.5
	# Modo de teste: --autoplay=greedy --deck=horde --speed=4 --quit=60 --shots=10,30 --out=user://
	# Capturas da interface: --menu=settings --tab=controls, --start=horde (run sem bot), --offerat=3, --pauseat=4.
	if auto_args.has("tab"):
		menu.settings.tab = str(auto_args["tab"])
		menu.show_screen("settings")
	if auto_args.has("start"):
		_start(str(auto_args["start"]))
	if auto_args.has("hint"):
		hud.hints_seen.erase(str(auto_args["hint"]))
	if auto_args.has("uitest"):
		_start("horde")
		_ui_test()
	if auto_args.has("routetest"):
		_start("horde")
		_route_test()
	if auto_args.has("menutest"):
		_menu_test()
	if auto_args.has("tiptest"):
		_start("horde")
		_tip_test()
	if auto_args.has("chaostest"):
		_start("horde")
		var ct := ChaosTest.new()
		add_child(ct)
		ct.run(self)
	# Nas capturas, o cursor físico parado sobre a janela abria a prévia de uma carta em toda foto.
	if auto_args.has("shots"):
		hud.fan.mouse_override = Vector2(-10000, -10000)
	if auto_args.has("autoplay"):
		_start(str(auto_args.get("deck", "horde")))
		auto_bot = PlayerBot.load_bot(str(auto_args["autoplay"]), sim.run_seed)
		speed = float(auto_args.get("speed", "4"))
		# --skip=600 pula até o segundo 600; --skip=arena pula até a arena começar.
		var to_arena: bool = auto_args.get("skip", "") == "arena"
		var skip := 1e9 if to_arena else float(auto_args.get("skip", "0"))
		sim.record_events = false
		while sim.t < skip and sim.phase != K.Phase.OVER and not (to_arena and sim.phase == K.Phase.ARENA):
			auto_bot.think(sim)
			sim.step()
		sim.record_events = true


func _env() -> void:
	cam = Camera3D.new()
	cam.fov = 40
	cam.far = 500
	add_child(cam)
	cam.position = Vector3(0, 20, 14)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-52, 30, 0)
	moon.light_energy = 1.1
	moon.light_color = Color(0.7, 0.75, 1.0)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 70.0
	add_child(moon)
	# Contraluz por trás da cena, sem sombra: contorna personagens e cenário. O chão fica na camada 2,
	# fora do alcance dela, para continuar escuro e calmo.
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-28, 165, 0)
	rim.light_energy = 0.7
	rim.light_color = Color(0.55, 0.65, 1.0)
	rim.light_cull_mask = 1
	rim.light_specular = 0.0
	add_child(rim)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.06, 0.04, 0.12)
	sm.sky_horizon_color = Color(0.22, 0.14, 0.3)
	sm.ground_bottom_color = Color(0.03, 0.03, 0.05)
	sm.ground_horizon_color = Color(0.22, 0.14, 0.3)
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.33, 0.55)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.08
	# Acima de 1: só o que é emissivo brilha; unidades claras sob luz forte não estouram em branco.
	env.glow_hdr_threshold = 1.15
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.16, 0.11, 0.26)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.4
	env.fog_height = 1.5
	env.fog_height_density = 0.05
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.0035
	env.volumetric_fog_albedo = Color(0.55, 0.5, 0.75)
	env.volumetric_fog_emission = Color(0.03, 0.02, 0.06)
	env.volumetric_fog_length = 80.0
	env.volumetric_fog_ambient_inject = 0.15
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.05
	we.environment = env
	add_child(we)
	sun = moon
	world_env = env
	GroundLooks.apply_env(env, moon, rim)
	Settings.apply_quality(env, moon, get_viewport())


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


var audio: GameAudio
var flash_rect: ColorRect
var result_played := false
var menu_root: Node3D
var menu_t := 0.0
var menu: MainMenu
var sun: DirectionalLight3D
var world_env: Environment


func _show_menu(screen: String) -> void:
	Tips.close_all()
	hud.show_run(false)
	menu.visible = true
	menu.show_screen(screen)


## Sai da run para o menu. A run em andamento fica salva (o menu oferece Continuar).
func _to_menu(decks: bool) -> void:
	if running and sim and sim.phase != K.Phase.OVER and not auto_args.has("autoplay"):
		SaveGame.save(sim)
	running = false
	paused = false
	sim = null
	world.build_empty()
	_build_menu_scene()
	audio.music("music_road")
	audio.set_intensity(0.0)
	_show_menu("decks" if decks else "title")


func _quit() -> void:
	if running and sim and sim.phase != K.Phase.OVER and not auto_args.has("autoplay"):
		SaveGame.save(sim)
	get_tree().quit()


func _cycle_speed() -> void:
	speed = 1.0 if speed >= 8.0 else speed * 2.0
	hud.speed = speed
	hud.say(tr("UI_SPEED").format({"n": int(speed)}))


func _on_settings(key: String) -> void:
	if key in ["quality", "all"]:
		Settings.apply_quality(world_env, sun, get_viewport())
	# Variação de arte: o tema, o chão e as malhas são montados na criação, então recarrega a cena.
	if key.begins_with("look_"):
		get_tree().reload_current_scene.call_deferred()


## Covil do chefe em 3D atrás do menu.
func _build_menu_scene() -> void:
	if menu_root:
		menu_root.queue_free()
	menu_root = Node3D.new()
	add_child(menu_root)
	var k := Models.Kit.new()
	k.add(Models.cyl(14.0, 14.5, 0.4, 32), Vector3(0, -0.2, 0), Color(0.1, 0.085, 0.12))
	for i in 3:
		var tm := TorusMesh.new()
		tm.inner_radius = 3.0 + i * 3.5
		tm.outer_radius = 3.2 + i * 3.5
		tm.rings = 48
		tm.ring_segments = 3
		k.add(tm, Vector3(0, 0.02, 0), Color(0.35, 0.2, 0.45), Vector3.ZERO, Vector3(1, 0.1, 1))
	var floor_ := MeshInstance3D.new()
	floor_.mesh = k.done()
	# Piso fosco: com o shader de toon o piso perto da câmera acendia num domo azul-claro na base do menu.
	var fm := StandardMaterial3D.new()
	fm.vertex_color_use_as_albedo = true
	fm.roughness = 0.95
	fm.metallic_specular = 0.1
	fm.albedo_color = Color(0.32, 0.3, 0.36)
	floor_.material_override = fm
	floor_.layers = 2
	menu_root.add_child(floor_)
	var throne := MeshInstance3D.new()
	throne.mesh = Models.prop("throne")
	throne.material_override = Models.glow_material(0.1)
	throne.position = Vector3(0, 0, -1.5)
	menu_root.add_child(throne)
	var boss := Models.boss_full()
	boss.position = Vector3(0, 1.0, -1.0)
	boss.scale = Vector3.ONE * 0.8
	menu_root.add_child(boss)
	for i in 6:
		var a := TAU * i / 6.0 + 0.5
		var pp := Vector3(cos(a), 0, sin(a)) * 9.0
		var mi := MeshInstance3D.new()
		mi.mesh = Models.prop("brazier" if i % 2 == 0 else "pillar")
		mi.material_override = Models.glow_material(0.6 if i % 2 == 0 else 0.0)
		mi.position = pp
		menu_root.add_child(mi)
		if i % 2 == 0:
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.55, 0.2)
			l.light_energy = 3.0
			l.omni_range = 12.0
			# Sem névoa: a esfera de alcance da luz do braseiro atrás da câmera aparecia como um disco claro.
			l.light_volumetric_fog_energy = 0.0
			l.position = pp + Vector3(0, 2.5, 0)
			menu_root.add_child(l)
	var core_l := OmniLight3D.new()
	core_l.light_color = Color(0.8, 0.3, 1.0)
	core_l.light_energy = 4.0
	core_l.omni_range = 10.0
	core_l.light_volumetric_fog_energy = 0.0
	core_l.position = Vector3(0, 3, 1)
	menu_root.add_child(core_l)
	_menu_atmosphere()


## Covil do menu: paredes escuras em volta (o céu do bosque não aparece atrás do chefe), contraluz fria que
## recorta o chefe, um facho de luz de cima na névoa e brasas subindo dos braseiros.
func _menu_atmosphere() -> void:
	var wall := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 24.0
	cyl.bottom_radius = 24.0
	cyl.height = 30.0
	cyl.radial_segments = 48
	cyl.cap_top = false
	# Fundo fechado: pela fresta entre o piso e a parede aparecia o disco do "sol" do céu (a contraluz).
	cyl.cap_bottom = true
	wall.mesh = cyl
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.05, 0.04, 0.07)
	wm.roughness = 1.0
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	wall.material_override = wm
	wall.position = Vector3(0, 8, -1)
	menu_root.add_child(wall)
	var rim_l := OmniLight3D.new()
	rim_l.light_color = Color(0.45, 0.6, 1.0)
	rim_l.light_energy = 5.0
	rim_l.omni_range = 9.0
	rim_l.light_volumetric_fog_energy = 0.0
	rim_l.position = Vector3(0, 4.5, -5.0)
	menu_root.add_child(rim_l)
	var shaft := SpotLight3D.new()
	shaft.light_color = Color(0.75, 0.62, 1.0)
	shaft.light_energy = 7.0
	shaft.light_volumetric_fog_energy = 3.0
	shaft.spot_range = 22.0
	shaft.spot_angle = 18.0
	shaft.position = Vector3(1.5, 16, 1.0)
	menu_root.add_child(shaft)
	shaft.look_at(Vector3(0, 1.5, -1.0), Vector3.FORWARD)
	var embers := GPUParticles3D.new()
	embers.amount = 90
	embers.lifetime = 5.0
	embers.preprocess = 5.0
	embers.visibility_aabb = AABB(Vector3(-14, -2, -14), Vector3(28, 16, 28))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(9, 0.5, 7)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0.15, 0.25, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.6, 0.25, 0.0))
	fade.add_point(0.2, Color(1.0, 0.6, 0.25, 1.0))
	fade.set_color(1, Color(1.0, 0.35, 0.15, 0.0))
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	embers.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var dot := GradientTexture2D.new()
	var dg := Gradient.new()
	dg.set_color(0, Color(1, 1, 1, 1))
	dg.set_color(1, Color(1, 1, 1, 0))
	dot.gradient = dg
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(0.5, 0.0)
	dot.width = 32
	dot.height = 32
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.albedo_texture = dot
	em.vertex_color_use_as_albedo = true
	em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	em.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	em.albedo_color = Color(2.5, 1.6, 0.8)
	q.material = em
	embers.draw_pass_1 = q
	embers.position = Vector3(0, 0.3, -1)
	menu_root.add_child(embers)


var save_t := 0.0
var menu_shift := 3.4


func _continue() -> void:
	var s := SaveGame.load_run(data)
	if s == null:
		SaveGame.erase()
		_show_menu("title")
		return
	_begin(s)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and running and sim and sim.phase != K.Phase.OVER and not auto_args.has("autoplay"):
		SaveGame.save(sim)
	# Perder o foco da janela pausa a run.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and running and not paused and auto_args.is_empty():
		_toggle_pause()


func _start(deck: String) -> void:
	var s := Sim.new()
	var seed_ := int(auto_args.get("seed", int(Time.get_unix_time_from_system()) % 1000000))
	# Os modos de teste e de captura jogam o deck pronto do Pacto com a coleção inteira (reproduzível).
	if auto_args.is_empty():
		s.setup(data, seed_, deck, meta.deck, meta.unlocked)
	else:
		s.setup(data, seed_, deck)
	# Capturas e testes de janela sem bot seguem o primeiro ramo (com --routewait, esperam a escolha como no jogo).
	s.auto_route = not auto_args.is_empty() and not auto_args.has("autoplay") and not auto_args.has("routewait") and not auto_args.has("routetest")
	_begin(s)


func _begin(s: Sim) -> void:
	if menu_root:
		menu_root.queue_free()
		menu_root = null
	sim = s
	sim.record_events = true
	result_played = false
	audio.music("music_road")
	audio.set_intensity(0.0)
	world.build(sim, cam)
	arena_built = false
	save_t = sim.t
	menu.visible = false
	hud.bind(sim)
	hud.speed = speed
	running = true
	paused = false
	acc = 0.0


# ---------------------------------------------------------------- laço

func _process(delta: float) -> void:
	life += delta
	if DisplayServer.get_name() != "headless":
		UiCovil.sync(get_viewport())
	if menu_root and not running:
		menu_t += delta * 0.15
		var a := sin(menu_t * 2.0) * 0.55
		cam.position = Vector3(sin(a) * 12.0, 2.6, -cos(a) * 12.0 - 1.0)
		cam.look_at(Vector3(0, 1.2, -1.0), Vector3.UP)
		# Na tela de título o chefe fica à direita, livre do texto; nas outras, ao fundo e no centro.
		var shift := 3.4 if menu.screen == "title" else 0.0
		menu_shift = lerpf(menu_shift, shift, clampf(delta * 3.0, 0.0, 1.0))
		cam.look_at(Vector3(0, 1.2, -1.0) - cam.global_transform.basis.x * menu_shift, Vector3.UP)
	if auto_args.has("quit") and life >= float(auto_args["quit"]):
		if sim:
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
	if auto_args.has("pauseat") and life >= float(auto_args["pauseat"]):
		auto_args.erase("pauseat")
		_toggle_pause()
	if auto_args.has("offerat") and life >= float(auto_args["offerat"]):
		auto_args.erase("offerat")
		# --offer=ritual (ou fountain:0 etc.) abre a recompensa de um local; sem ela, um level-up.
		if auto_args.has("offer"):
			var ow := str(auto_args["offer"]).split(":")
			if ow[0] == "shop":
				# --offer=shop (ou shop:0): loja com 200 de ouro.
				sim.gold = 200.0
				sim._open_shop(ow.size() < 2 or ow[1] != "0")
			else:
				sim._offer_location(ow[0], ow.size() < 2 or ow[1] != "0")
		else:
			sim._offer_level()
			sim.damage_hero(1.0, sim.hero.x, sim.hero.y + 5.0, 0, SimHero.DMG_PIERCE, "test")
	if auto_bot:
		auto_bot.think(sim)
	# Bifurcação sem escolha: o jogo espera e o mapa grande abre sozinho.
	if sim.route_wait and not hud.minimap.visible and sim.offers.is_empty():
		map_auto = true
		_toggle_map()
	_close_auto_map()
	if auto_args.has("stress"):
		_stress(int(auto_args["stress"]))
	_pad_cursor(delta)
	# Hit-stop: congela a simulação por alguns milissegundos em impactos grandes.
	var stopped := false
	if world.hitstop > 0.0:
		world.hitstop -= delta
		stopped = true
	if not paused and not stopped:
		acc = minf(acc + delta * speed, sim.dt * 12.0)
		while acc >= sim.dt:
			sim.step()
			acc -= sim.dt
			world.handle_events(sim.events)
			audio.handle_events(sim.events, sim)
			sim.events.clear()
			if sim.offers.size() > 0:
				acc = 0.0
				break
	if sim.phase == K.Phase.ARENA and not arena_built:
		arena_built = true
		world.build_arena()
		hud.say(tr("UI_ARENA"))
	if sim.phase == K.Phase.ROAD:
		audio.set_intensity(sim.hero.s / maxf(sim.road.length(), 1.0) * (0.6 if not sim.road.complete else 1.0))
	if sim.phase != K.Phase.OVER and sim.t - save_t > 10.0 and not auto_args.has("autoplay"):
		save_t = sim.t
		SaveGame.save(sim)
	if sim.phase == K.Phase.OVER and not result_played:
		result_played = true
		SaveGame.erase()
		hud.souls_gained = meta.add_run(sim.stats) if auto_args.is_empty() else MetaSave.souls_for(data, sim.stats)
		audio.music("")
		audio.play("victory" if sim.result in [K.Result.WIN, K.Result.WIN_EARLY] else "defeat", 0.0)
	var alpha := clampf(acc / sim.dt, 0.0, 1.0)
	world.draw(alpha, delta * (0.15 if stopped else 1.0))
	flash_rect.color = world.screen_flash if Settings.v["flash"] else Color(0, 0, 0, 0)
	_update_placement()
	hud.pad = pad_active
	hud.refresh(delta, Engine.get_frames_per_second())


## Teste da entrada real: injeta teclas e cliques e confere o efeito no Sim.
func _ui_test() -> void:
	var ok := true
	await get_tree().create_timer(0.5).timeout
	sim.elixir = 10.0
	var ev := InputEventKey.new()
	ev.keycode = KEY_1
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	ok = ok and hud.selected == 0
	print("uitest selecionar com tecla 1: ", hud.selected == 0)
	# Selecionada e com o mouse junto ao leque (fora das cartas): o balão com a descrição aparece.
	hud.fan.mouse_override = Vector2(hud.fan.fan_rect().position.x - 12.0, hud.fan.size.y * 0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	var ball := hud.fan.balloon != null and hud.fan.balloon.visible
	print("uitest carta selecionada mostra o balão: ", ball)
	ok = ok and ball
	_ui_shot("selected")
	hud.fan.mouse_override = null
	var f := Vector3(0, 0, -6)
	var target := Vector3(sim.hero.x, 0, sim.hero.y) + f
	var sp := cam.unproject_position(target)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = sp
	Input.parse_input_event(mb)
	await get_tree().process_frame
	await get_tree().process_frame
	var played := 0
	for k in sim.stats["played"]:
		played += int(sim.stats["played"][k])
	print("uitest clique no mundo jogou a carta: ", played == 1, " unidades=", sim.units.count)
	ok = ok and played == 1
	var e0 := sim.elixir
	var x := InputEventKey.new()
	x.keycode = KEY_X
	x.pressed = true
	Input.parse_input_event(x)
	var two := InputEventKey.new()
	two.keycode = KEY_2
	two.pressed = true
	Input.parse_input_event(two)
	await get_tree().process_frame
	await get_tree().process_frame
	print("uitest X+2 sacrificou: ", sim.stats["sacrifices"] == 1)
	ok = ok and sim.stats["sacrifices"] == 1
	sim._offer_level()
	sim.damage_hero(1.0, sim.hero.x, sim.hero.y + 5.0, 0, SimHero.DMG_PIERCE, "test")
	await get_tree().process_frame
	var had_offer := sim.offers.size() > 0
	var n0 := sim.cards.size()
	var one := InputEventKey.new()
	one.keycode = KEY_1
	one.pressed = true
	Input.parse_input_event(one)
	await get_tree().process_frame
	await get_tree().process_frame
	print("uitest oferta escolhida com tecla 1: ", had_offer and sim.offers.is_empty())
	ok = ok and had_offer and sim.offers.is_empty()
	# Arrastar a carta 1 até o mapa.
	sim.elixir = 10.0
	await get_tree().process_frame
	var before := 0
	for k2 in sim.stats["played"]:
		before += int(sim.stats["played"][k2])
	# Passar o mouse sobre a carta 1 mostra a carta ampliada.
	var c0 := hud.fan.card_rect(0).get_center()
	# Fixa o mouse do leque: com a janela sem foco, o cursor real passando por cima desfaria o hover.
	hud.fan.mouse_override = c0 - hud.fan.global_position
	for _f in 3:
		await get_tree().process_frame
	var zoomed := hud.fan.preview != null and hud.fan.hover == 0
	print("uitest mouse sobre a carta amplia: ", zoomed)
	ok = ok and zoomed
	_ui_shot("hover")
	hud.fan.mouse_override = null
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = c0
	down.global_position = c0
	Input.parse_input_event(down)
	await get_tree().process_frame
	var tgt := cam.unproject_position(Vector3(sim.hero.x, 0, sim.hero.y) + Vector3(5, 0, -3))
	var mv := InputEventMouseMotion.new()
	mv.position = tgt
	mv.global_position = tgt
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(mv)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = tgt
	up.global_position = tgt
	Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame
	var after := 0
	for k2 in sim.stats["played"]:
		after += int(sim.stats["played"][k2])
	print("uitest arrastar e soltar jogou a carta: ", after == before + 1)
	ok = ok and after == before + 1
	# M abre e fecha o mapa grande.
	var mk := InputEventKey.new()
	mk.keycode = KEY_M
	mk.pressed = true
	Input.parse_input_event(mk)
	await get_tree().process_frame
	await get_tree().process_frame
	var opened := hud.minimap.visible
	_ui_shot("map")
	Input.parse_input_event(mk)
	await get_tree().process_frame
	print("uitest M abre e fecha o mapa: ", opened and not hud.minimap.visible)
	ok = ok and opened and not hud.minimap.visible
	print("uitest resultado: ", "OK" if ok else "FALHOU")
	get_tree().quit(0 if ok else 1)


## Teste da escolha de rota com a entrada real: o mapa abre sozinho na bifurcação, a tecla 2 escolhe o
## segundo ramo, um clique no mapa planeja o caminho até um local distante e um clique na faixa também.
func _route_test() -> void:
	var ok := true
	await get_tree().create_timer(0.6).timeout
	var waiting: bool = sim.route_wait and hud.minimap.visible
	print("routetest bifurcação pausa e abre o mapa: ", waiting)
	ok = ok and waiting
	_ui_shot("route_wait")
	var outs: Array = sim.road.nodes[sim.road.head]["out"]
	var want: int = sim.road.legs[outs[mini(1, outs.size() - 1)]]["b"]
	var two := InputEventKey.new()
	two.keycode = KEY_2
	two.pressed = true
	Input.parse_input_event(two)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	var went: bool = not sim.route_wait and sim.road.path.size() >= 2 and sim.road.path[1] == want
	print("routetest tecla 2 escolhe o segundo ramo: ", went, " (caminho ", sim.road.path, ")")
	ok = ok and went
	print("routetest mapa fecha quando o herói volta a andar: ", not hud.minimap.visible)
	ok = ok and not hud.minimap.visible
	# Clique no mapa grande: um local alcançável três fileiras à frente.
	_toggle_map()
	await get_tree().process_frame
	var mm := hud.minimap
	var far := -1
	var row0: int = sim.road.nodes[sim.road.head]["row"]
	for n in sim.road.reach:
		if sim.road.nodes[n]["loc"] >= 0 and sim.road.nodes[n]["row"] == row0 + 3:
			far = n
			break
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = mm.global_position + mm.node_point(far)
	Input.parse_input_event(mb)
	await get_tree().process_frame
	await get_tree().process_frame
	var planned: bool = far >= 0 and sim.road.s_of_node(far) >= 0.0
	print("routetest clique no mapa planeja o caminho até o local: ", planned)
	ok = ok and planned
	_ui_shot("route_planned")
	if mm.visible:
		_toggle_map()
	# Clique na faixa: outro local da mesma fileira, se houver.
	var alt := -1
	for n in sim.road.reach:
		if n != far and sim.road.nodes[n]["loc"] >= 0 and sim.road.nodes[n]["row"] == row0 + 3:
			alt = n
	if alt >= 0:
		var st := hud.strip
		var mb2 := InputEventMouseButton.new()
		mb2.button_index = MOUSE_BUTTON_LEFT
		mb2.pressed = true
		mb2.position = st.global_position + st._node_point(alt)
		Input.parse_input_event(mb2)
		await get_tree().process_frame
		await get_tree().process_frame
		var replanned: bool = sim.road.s_of_node(alt) >= 0.0 and sim.road.s_of_node(far) < 0.0
		print("routetest clique na faixa troca o plano: ", replanned)
		ok = ok and replanned
	print("routetest resultado: ", "OK" if ok else "FALHOU")
	get_tree().quit(0 if ok else 1)


## Captura do teste da entrada (só com --out=<pasta>).
func _ui_shot(tag: String) -> void:
	if auto_args.has("out"):
		get_viewport().get_texture().get_image().save_png(str(auto_args["out"]) + "uitest_%s.png" % tag)


func _click(c: Control) -> void:
	var p := c.get_global_rect().get_center()
	for down in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = down
		mb.position = p
		mb.global_position = p
		Input.parse_input_event(mb)
	for _f in 3:
		await get_tree().process_frame


func _key(kc: Key) -> void:
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = kc
		ev.physical_keycode = kc
		ev.pressed = down
		Input.parse_input_event(ev)
	for _f in 3:
		await get_tree().process_frame


func _button(root: Node, key: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if b.text == key and b.is_visible_in_tree():
			return b
	return null


## Teste do menu com entrada real: Nova run → deck → pausa → configurações → salvar e voltar → Continuar.
func _menu_test() -> void:
	var fails: Array = []   # lambdas capturam por valor: um bool não voltaria daqui
	SaveGame.erase()   # o arquivo de teste; a run salva do jogador fica em outro
	var had_save := SaveGame.exists()
	await get_tree().create_timer(0.5).timeout
	var step := func(name: String, cond: bool):
		print("menutest ", name, ": ", cond)
		if not cond:
			fails.append(name)
	await _click(_button(menu, "UI_NEW_RUN"))
	step.call("Nova run abre os decks", menu.screen == "decks")
	await _key(KEY_ESCAPE)
	step.call("Esc volta ao título", menu.screen == "title")
	await _click(_button(menu, "UI_NEW_RUN"))
	await _click(_button(menu, "UI_PLAY_DECK"))
	step.call("Jogar com o deck começa a run", running and sim != null and sim.deck_id == "horde" and not menu.visible)
	await get_tree().create_timer(0.3).timeout
	await _key(KEY_ESCAPE)
	step.call("Esc pausa", paused and hud.pause_layer.visible)
	await _click(_button(hud, "UI_SETTINGS"))
	step.call("Configurações abre na pausa", hud.settings.visible)
	await _click(_button(hud.settings, "UI_TAB_game"))
	var fps_btn: Button = null
	for b in hud.settings.find_children("*", "Button", true, false):
		var first := b.get_parent().get_child(0)
		if b.toggle_mode and first is Label and first.text == "SET_show_fps":
			fps_btn = b
	var was: bool = Settings.v["show_fps"]
	await _click(fps_btn)
	step.call("Botão liga/desliga muda a configuração", Settings.v["show_fps"] != was)
	await _click(fps_btn)
	await _key(KEY_ESCAPE)
	step.call("Esc fecha as configurações e mantém a pausa", not hud.settings.visible and paused and hud.pause_layer.visible)
	await _key(KEY_ESCAPE)
	step.call("Esc despausa", not paused and not hud.pause_layer.visible)
	if not had_save:
		await _key(KEY_ESCAPE)
		await _click(_button(hud, "UI_SAVE_MENU"))
		step.call("Salvar e voltar ao menu", not running and menu.visible and SaveGame.exists())
		await _click(_button(menu, "UI_CONTINUE"))
		step.call("Continuar retoma a run", running and sim != null and sim.deck_id == "horde")
		SaveGame.erase()
	print("menutest resultado: ", "OK" if fails.is_empty() else "FALHOU " + str(fails))
	get_tree().quit(0 if fails.is_empty() else 1)


## Teste das caixas de explicação com entrada real: habilidade nova na HUD, caixa do ícone, caixa aninhada
## pela palavra, o jogo segue com a caixa aberta, carta da mão só depois de parar nela.
func _tip_test() -> void:
	var fails: Array = []
	var step := func(name: String, cond: bool):
		print("tiptest ", name, ": ", cond)
		if not cond:
			fails.append(name)
	Settings.v["hints"] = false
	# O cursor físico parado sobre o leque abria a prévia de uma carta (e as caixas dela escondem o aviso):
	# o teste começa com o mouse no meio do mundo, longe da interface.
	get_viewport().warp_mouse(get_viewport().get_visible_rect().size * Vector2(0.5, 0.35))
	await get_tree().create_timer(0.6).timeout
	# Armadura Ignífuga: caixas "Armadura" e "Fogo"; o texto do Fogo cita Encharcado, que ainda não tem caixa.
	sim.hero.apply_upgrade("fireproof")
	await get_tree().create_timer(0.3).timeout
	var icons := hud.upg_row.find_children("*", "UpgradeIcon", false, false)
	step.call("Habilidade nova aparece na HUD com aviso", icons.size() == 1 and hud.learn_panel.visible)
	_ui_shot("tip_learn")
	# Mouse no ícone: abre a caixa e o jogo continua.
	await _hover((icons[0] as Control).get_global_rect().get_center())
	await get_tree().create_timer(0.2).timeout
	var t0 := sim.t
	await get_tree().create_timer(0.3).timeout
	step.call("Mouse no ícone abre a caixa", Tips.reading() and Tips.inst.levels[0]["owner"].begins_with("obj:"))
	step.call("Caixa aberta não pausa o jogo", sim.t > t0)
	_ui_shot("tip_icon")
	# Entra na caixa do Fogo e varre o texto até achar uma palavra-chave: abre a caixa aninhada.
	var body: RichTextLabel = Tips.inst.levels[0]["boxes"][-1].find_children("*", "RichTextLabel", true, false)[0]
	var r := body.get_global_rect()
	var nested := false
	var y := r.position.y + 6.0
	while y < r.end.y and not nested:
		var x := r.position.x + 4.0
		while x < r.end.x and not nested:
			await _hover(Vector2(x, y), 1)
			nested = Tips.inst.levels.size() >= 2
			x += 10.0
		y += 9.0
	step.call("Palavra dentro da caixa abre outra caixa", nested)
	await get_tree().create_timer(0.1).timeout
	_ui_shot("tip_nested")
	# Mouse para dentro da caixa aninhada: as duas continuam abertas.
	if nested:
		await _hover((Tips.inst.levels[1]["boxes"][0] as Control).get_global_rect().get_center())
		await get_tree().create_timer(0.7).timeout
		step.call("Caixa aninhada fica aberta com o mouse nela", Tips.inst.levels.size() >= 2)
	# Mouse longe: tudo fecha depois do atraso e o jogo volta.
	await _hover(get_viewport().get_visible_rect().size * Vector2(0.5, 0.45))
	await get_tree().create_timer(0.7).timeout
	var t1 := sim.t
	await get_tree().create_timer(0.3).timeout
	step.call("Mouse longe fecha tudo", not Tips.reading() and sim.t > t1)
	# Carta da mão: passar rápido não abre; parar ~0,6 s abre as caixas ao lado.
	var c0 := hud.fan.card_rect(0).get_center()
	hud.fan.mouse_override = c0 - hud.fan.global_position
	await _hover(c0)
	await get_tree().create_timer(0.3).timeout
	step.call("Passar rápido na carta não abre caixa", not Tips.reading() and hud.fan.preview != null)
	await get_tree().create_timer(0.5).timeout
	step.call("Parar na carta abre as caixas ao lado", Tips.reading() and Tips.inst.levels[0]["owner"].begins_with("hand:"))
	_ui_shot("tip_card")
	hud.fan.mouse_override = null
	Tips.mouse_override = null
	print("tiptest resultado: ", "OK" if fails.is_empty() else "FALHOU " + str(fails))
	get_tree().quit(0 if fails.is_empty() else 1)


## Move o mouse (evento real) e fixa a posição que as caixas leem. O RichTextLabel acha a palavra sob o cursor
## pela posição real do mouse, não pela do evento: por isso também move o cursor de verdade.
func _hover(p: Vector2, frames := 3) -> void:
	Tips.mouse_override = p
	get_viewport().warp_mouse(p)
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	Input.parse_input_event(mm)
	for _f in frames:
		await get_tree().process_frame


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


## O ponteiro aponta para o chão (e não para o céu). Sem alcance máximo, é isso que limita a carta ao que se vê.
func _on_ground(screen: Vector2) -> bool:
	return Plane(Vector3.UP, 0.0).intersects_ray(cam.project_ray_origin(screen), cam.project_ray_normal(screen)) != null


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
	world.show_placement(d.category == "field" or d.id == "gold_bait", p, _on_ground(_pointer()) and sim.valid_target(ci, p.x, p.z), r)


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
	# O Incêndio mira um local da rota: o mapa grande abre junto (a Isca de Ouro vai no mundo, perto do herói).
	if (hud.selected >= 0 and ci.def.id == "burn_village") != hud.minimap.visible and not sim.route_wait:
		_toggle_map()
	# Cartas sem alvo (covil, finalização) saem na hora.
	if hud.selected >= 0 and (ci.def.category == "lair" or ci.def.category == "finisher"):
		_play_at(Vector2(sim.hero.x, sim.hero.y))


func _sacrifice(i: int) -> void:
	if sim and sim.sacrifice(i):
		hud.selected = -1
	elif sim and i >= 0 and i < sim.hand.size() and not sim.sacrifice_ready():
		hud.say(tr("UI_SACRIFICE_WAIT"))


func _play_at(p: Vector2) -> void:
	var i := hud.selected
	if i < 0:
		return
	var b := sim.play(i, p.x, p.y)
	if b == K.Block.OK:
		hud.selected = -1
		if hud.minimap.visible:
			_toggle_map()
	else:
		hud.say(tr("UI_BLOCK_%d" % mini(b, 5)))
		if b != K.Block.NO_ELIXIR and b != K.Block.BAD_TARGET:
			hud.selected = -1


func _minimap_click(p: Vector2) -> void:
	if sim and hud.selected >= 0:
		_play_at(p)


## Clique num local do mapa ou da faixa (sem carta selecionada): o herói vai passar por ele.
func _route_click(n: int) -> void:
	if sim == null or hud.selected >= 0 or n < 0 or sim.offers.size() > 0:
		return
	if sim.choose_route(n):
		audio.play("card_play", 0.0)
		_close_auto_map()


## Opção k da bifurcação em que o herói espera (da esquerda para a direita).
func _route_option(k: int) -> bool:
	if not sim.route_wait:
		return false
	var outs: Array = sim.road.nodes[sim.road.head]["out"]
	if k < 0 or k >= outs.size():
		return false
	_route_click(sim.road.legs[outs[k]]["b"])
	return true


## O mapa que abriu sozinho na bifurcação fecha quando o herói volta a andar.
func _close_auto_map() -> void:
	if map_auto and not sim.route_wait and hud.minimap.visible:
		map_auto = false
		_toggle_map()


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
	if not get_viewport().get_visible_rect().has_point(screen):
		return
	var g := _ground_point(screen)
	var p := Vector2(g.x, g.z)
	if hud.selected >= 0:
		if not _on_ground(screen):
			return
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
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			world.zoom = clampf(world.zoom - 2.0, -12.0, 20.0)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			world.zoom = clampf(world.zoom + 2.0, -12.0, 20.0)
	if e is InputEventKey and e.pressed and not e.echo:
		var kc: int = e.keycode
		if paused and kc != KEY_ESCAPE and kc != KEY_SPACE:
			return
		if kc >= KEY_1 and kc <= KEY_9:
			var n := kc - KEY_1
			if sim.offers.size() > 0:
				sim.choose(n)
			elif not _route_option(n):
				_select(n)
		if kc == KEY_0 and sim.offers.size() > 0:
			sim.choose(Sim.SKIP)
		match kc:
			KEY_X:
				sac_mode = true
			KEY_ESCAPE:
				if paused and hud.back():
					pass
				elif not paused and (hud.selected >= 0 or sac_mode):
					hud.selected = -1
					sac_mode = false
				else:
					_toggle_pause()
			KEY_SPACE:
				_toggle_pause()
			KEY_F:
				_cycle_speed()
			KEY_M:
				_toggle_map()
			KEY_Q:
				_altar_step(-1)
			KEY_E:
				_altar_step(1)
	if e is InputEventKey and not e.pressed and e.keycode == KEY_X:
		sac_mode = false
	_pad_input(e)


func _toggle_pause() -> void:
	if sim == null or sim.phase == K.Phase.OVER:
		return
	paused = not paused
	hud.show_pause(paused)


## Mapa grande da rota (M, Select ou ao escolher uma carta de rota). No dia a dia, a faixa de rota na borda esquerda.
func _toggle_map() -> void:
	var mm := hud.minimap
	if sim.phase != K.Phase.ROAD and not mm.visible:
		return
	mm.visible = not mm.visible
	if mm.visible:
		mm.setup(sim)


# ---------------------------------------------------------------- controle

func _pad_input(e: InputEvent) -> void:
	if not (e is InputEventJoypadButton or e is InputEventJoypadMotion):
		return
	pad_active = true
	if e.is_action_pressed("pad_pause"):
		_toggle_pause()
	if paused:
		# Na pausa o controle navega pelos botões (ui_*); B volta.
		if e.is_action_pressed("pad_back") and not hud.back():
			_toggle_pause()
		return
	if sim.route_wait and sim.offers.is_empty():
		# Bifurcação: L1/R1 trocam o ramo destacado, A escolhe.
		var outs: Array = sim.road.nodes[sim.road.head]["out"]
		if e.is_action_pressed("pad_prev") or e.is_action_pressed("pad_next"):
			route_sel = wrapi(route_sel + (-1 if e.is_action_pressed("pad_prev") else 1), 0, outs.size())
			hud.minimap.hover = sim.road.legs[outs[route_sel]]["b"]
		if e.is_action_pressed("pad_confirm"):
			_route_option(clampi(route_sel, 0, outs.size() - 1))
		return
	if sim.offers.size() > 0:
		if e.is_action_pressed("pad_prev") or e.is_action_pressed("pad_next"):
			var d := -1 if e.is_action_pressed("pad_prev") else 1
			hud.selected = wrapi(hud.selected + d, 0, sim.offers[0]["options"].size())
		if e.is_action_pressed("pad_confirm"):
			sim.choose(maxi(hud.selected, 0))
			hud.selected = -1
		elif e.is_action_pressed("pad_back"):
			sim.choose(Sim.SKIP)
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
		cursor += v * 900.0 * float(Settings.v["pad_speed"]) * delta
		cursor = cursor.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size)
	# Segurar B sacrifica a carta selecionada.
	if Input.is_action_pressed("pad_back") and hud.selected >= 0:
		b_hold += delta
		if b_hold > 0.5:
			b_hold = 0.0
			_sacrifice(hud.selected)
