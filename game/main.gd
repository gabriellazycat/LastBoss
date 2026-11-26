extends Node3D
## Cena principal: menu → run → resultado. Roda o Sim num acumulador de passo fixo e traduz entrada em comandos.

var data: GameData
var meta: MetaSave
var sim: Sim
var world: WorldView
var hud: Hud
var tutorial: Tutorial
var cam: Camera3D
var acc := 0.0
var speed := 1.0
var paused := false
var running := false
var cursor := Vector2.ZERO        # cursor virtual do controle (tela)
var pad_active := false
var arena_built := false
var map_auto := false             # o mapa grande abriu sozinho numa bifurcação (fecha quando o herói volta a andar)
var map_after := false            # um local acabou: o mapa abre depois da cena e das recompensas (15/11/2026)
var map_after_t := 0.0
var map_after_open := false       # o mapa aberto agora é o do fim do local (replanejar a rota fecha ele)
var route_sel := 0                 # ramo destacado pelo controle na bifurcação
var status_ov: StatusOverlay
var act_end_seen := false
var target_mark: MeshInstance3D   # anel dourado no herói que a carta em mira vai atingir
var was_blocking := false           # oferta/bifurcação/mapa abertos no quadro anterior (solta a carta selecionada)
var auto_bot: PlayerBot
var auto_args := {}
var shots: Array = []
var life := 0.0


var overtime_said := false   # aviso da prorrogação da arena já mostrado
var overtime_party_t := -1.0  # Horda sem fim: chegada da party da vez na arena (re-arma o aviso da prorrogação)
var seen_party := -1         # party da fila já marcada como vista no meta (mapa da campanha, 16/11/2026)


var bg_mode := false   # teste/captura em segundo plano: janela fora da tela, sem foco, sem mover o mouse


func _ready() -> void:
	Settings.load_all()
	Settings.apply(get_tree())
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			auto_args[kv[0]] = kv[1]
	# --liberar: jogo de teste com todas as fases e vilões liberados, em saves próprios (user://liberar_*.save);
	# o seu save e o seu meta ficam intactos. Não é modo de teste: rota e coleção funcionam como no jogo normal
	# (10/11/2026).
	var liberar := OS.get_cmdline_user_args().has("--liberar") or auto_args.has("liberar")
	auto_args.erase("liberar")
	# Testes e capturas salvam num arquivo próprio: nunca tocam na run salva do jogador.
	if not auto_args.is_empty():
		SaveGame.current = "user://test_run.save"
	for t in str(auto_args.get("shots", "")).split(",", false):
		shots.append(float(t))
	# Auditoria de folga sem janela: o modo headless nasce 1024x1024 (o layout "expand" do projeto vira 1600x1600);
	# --spacewin=LxA põe a janela virtual no tamanho da captura (padrão 1920x1080 = o mesmo layout lógico de 1280x720).
	if auto_args.has("spacetest") and DisplayServer.get_name() == "headless":
		var wsz := str(auto_args.get("spacewin", "1920x1080")).split("x")
		get_window().size = Vector2i(int(wsz[0]), int(wsz[1]))
	# --set=ui_scale:1.15,language:en muda configurações só nesta execução (não salva).
	for kv in str(auto_args.get("set", "")).split(",", false):
		var p := kv.split(":")
		if p.size() == 2 and Settings.v.has(p[0]):
			if not Settings.session.has(p[0]):
				Settings.session[p[0]] = Settings.v[p[0]]
			Settings.v[p[0]] = float(p[1]) if typeof(Settings.v[p[0]]) == TYPE_FLOAT else (p[1] if typeof(Settings.v[p[0]]) == TYPE_STRING else str_to_var(p[1]))
	# Execução de teste/captura (qualquer argumento --x=y) roda em segundo plano (20/11/2026, pedido do usuário): janela
	# 1920x1080 fora da tela, sem foco e sem tela cheia, e nunca move o cursor de verdade. --fg=1 volta ao modo antigo.
	bg_mode = not auto_args.is_empty() and not auto_args.has("fg") and DisplayServer.get_name() != "headless"
	if bg_mode:
		if not Settings.session.has("fullscreen"):
			Settings.session["fullscreen"] = Settings.v["fullscreen"]
		Settings.v["fullscreen"] = false
	Settings.apply(get_tree())
	if bg_mode:
		var w := get_window()
		w.set_flag(Window.FLAG_NO_FOCUS, true)
		w.mode = Window.MODE_WINDOWED
		w.size = Vector2i(1920, 1080)
		w.position = Vector2i(-6000, 0)
	# Pele Covil: todo botão que nascer leva o material da moldura (o tema só leva a StyleBox).
	UiSkins.apply()
	if not get_tree().node_added.is_connected(UiDiario.on_node_added):
		get_tree().node_added.connect(UiDiario.on_node_added)
	if DisplayServer.get_name() != "headless":
		UiKit.sync(get_viewport())
	data = GameData.load_dir()
	meta = MetaSave.load_or_new(data)
	if not auto_args.is_empty():
		meta.file = "user://test_meta.save"
	if liberar:
		SaveGame.current = "user://liberar_run.save"
		meta = MetaSave.load_or_new(data, "user://liberar_meta.save")
		for vid in data.villain_ids:
			meta.unlock_villain(vid)
		meta.save()
	Tips.data = data
	add_child(Tips.new())
	audio = GameAudio.new()
	add_child(audio)
	_env()
	world = WorldView.new()
	# Bots e lotes rodam sem a cena da queda (ela segura a recompensa por ~3 s).
	world.cine_enabled = not auto_args.has("autoplay") and DisplayServer.get_name() != "headless"
	add_child(world)
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 0
	add_child(fx_layer)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vs := Shader.new()
	vs.code = Diorama.vignette_code()
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
	# Status à vista e prévia do feitiço: por baixo do HUD, por cima do mundo.
	status_ov = StatusOverlay.new()
	layer.add_child(status_ov)
	hud = Hud.new()
	layer.add_child(hud)
	tutorial = Tutorial.new()
	tutorial.visible = false
	layer.add_child(tutorial)
	hud.card_pressed.connect(_select)
	hud.offer_chosen.connect(func(k): if sim: sim.choose(k))
	hud.resume.connect(_toggle_pause)
	hud.to_menu.connect(_to_menu)
	hud.quit_game.connect(_quit)
	hud.speed_pressed.connect(_cycle_speed)
	hud.map_pressed.connect(func(): if sim: _toggle_map())
	hud.sfx = func(id: String, pitch: float):
		if audio:
			audio.play(id, 0.02, pitch)
	# Letreiro grande bate na tela: tranco de câmera e som (rodada 09/11/2026, impacto).
	hud.banner.on_slam = func(p: float):
		if world:
			world.add_trauma(0.45 * p)
		if audio:
			audio.play("part_destroyed", 0.02)
	hud.settings_changed.connect(_on_settings)
	menu = MainMenu.new()
	menu.theme = UiKit.make_theme()
	menu.setup(data, meta)
	layer.add_child(menu)
	menu.deck_chosen.connect(_start)
	menu.tutorial_chosen.connect(_start_tutorial)
	menu.continue_run.connect(_continue)
	_build_pause_extras()
	run_end = RunEnd.new()
	run_end.visible = false
	run_end.to_menu.connect(func(): _to_menu(false))
	end_layer = CanvasLayer.new()
	end_layer.layer = 3
	end_layer.add_child(run_end)
	add_child(end_layer)
	menu.settings_changed.connect(_on_settings)
	hud.minimap_clicked.connect(_minimap_click)
	hud.route_clicked.connect(_route_click)
	hud.minimap.cancel_requested.connect(func():
		if sim == null:
			return
		var had := hud.selected >= 0
		hud.selected = -1
		# Fecha o mapa que a carta abriu (fora da bifurcação, onde o mapa é a escolha do caminho).
		if had and hud.minimap.visible and not sim.route_wait:
			_toggle_map())
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
	audio.music_menu()
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
	if auto_args.has("reader"):
		# --menu=collection --reader=<índice>: abre o leitor de cartas (capturas e auditoria de folga).
		_open_reader_shot(int(auto_args["reader"]))
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
	if auto_args.has("villaintest"):
		_villain_layout_test()
	if auto_args.has("gshots"):
		_g_shots()
	if auto_args.has("mapicons"):
		_map_icons()
	if auto_args.has("tiptest"):
		_start("horde")
		_tip_test()
	if auto_args.has("humantest"):
		# Teste humano com o mouse (10/11/2026): o bot humano joga pela entrada real; game/human_playtest.gd.
		_start(str(auto_args.get("deck", "horde")))
		speed = float(auto_args.get("speed", "3"))
		hud.speed = speed
		var hp_ := HumanPlaytest.new()
		add_child(hp_)
		hp_.run(self, str(auto_args["humantest"]))
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
		# --skip=<tipo de local> (ex.: bridge) pula até a disputa desse local começar.
		var sk := str(auto_args.get("skip", "0"))
		var to_arena: bool = sk == "arena"
		var to_loc := sk if sk in SimRoad.LOC_TYPES else ""
		# --skip=act / --skip=act1: pula até a oferta de fim do ato 0 / do ato 1 (capturas da troca de ato).
		var to_act := sk.begins_with("act")
		var act_idx := int(sk.substr(3)) if to_act else -1
		var skip := 1e9 if to_arena or to_loc != "" or to_act else float(sk)
		sim.record_events = false
		while sim.t < skip and sim.phase != K.Phase.OVER and not (to_arena and sim.phase == K.Phase.ARENA) 				and not (to_loc != "" and str(sim.contest.get("type", "")) == to_loc) 				and not (to_act and sim.act_pending and sim.act == act_idx):
			auto_bot.think(sim)
			sim.step()
		sim.record_events = true
		if sim.phase == K.Phase.ROAD and sim.act != built_act:
			_apply_act_look(sim)
			world.build(sim, cam)


func _open_reader_shot(i: int) -> void:
	await get_tree().create_timer(1.5).timeout
	menu.collection._open_reader(i)


## Auditoria de folga (SpacingAudit): varre a tela atual e escreve uma linha por problema em <out>/space_<nome>.txt.
func _space_scan(tag: String) -> void:
	var view := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var found := SpacingAudit.scan(get_tree().root, tag, view)
	var lines: PackedStringArray = []
	for f in found:
		lines.append("%s\t%s\t%s\t%s\tfolga=%s\tminimo=%s\t%s" % [f["screen"], f["kind"], f["path"], str(f["text"]).replace("\n", " "), f["gap"], f["need"], f["side"]])
	var fa := FileAccess.open(str(auto_args.get("out", "user://")) + "space_%s.txt" % tag, FileAccess.WRITE)
	if fa:
		fa.store_string("\n".join(lines) + ("\n" if lines.size() > 0 else ""))
	print("space: ", tag, " problemas=", found.size(), " tela=", view.size)


func _env() -> void:
	cam = Camera3D.new()
	Diorama.setup_camera(cam)
	add_child(cam)
	cam.position = Vector3(0, 20, 14)
	PaintLook.apply()
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
	rim_light = rim
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
	LuzLook.apply(env, moon, rim)
	Settings.apply_quality(env, moon, get_viewport())
	Diorama.apply_env(env, moon, rim, 0)


## Capturas: põe o herói no primeiro local da rota, trocado para o tipo pedido, e começa a disputa.
func _debug_contest(ty: String) -> void:
	var road := sim.road
	if road.next_edge() < 0:
		road.plan_to(road.legs[road.nodes[road.head]["out"][0]]["b"])
	if road.nodes[road.head]["loc"] < 0:
		road.advance(road.next_edge())
	var li: int = road.nodes[road.head]["loc"]
	var loc: Dictionary = road.locations[li]
	loc["type"] = ty
	loc["r"] = float(sim.R["locations"][ty]["radius"])
	var p: Vector2 = loc["pos"]
	sim.hero.x = p.x
	sim.hero.y = p.y
	sim.hero.s = road.length()
	sim.hero.s_max = sim.hero.s
	sim.hero.seg = road.seg_at(sim.hero.s)
	sim._arrive(li)
	world.build(sim, cam)


## Chão, luz e névoa do ato atual (provisórios: os looks 2, 3 e 4 até a direção de arte nova).
## Fator sobre a energia do sol no primeiro ato (21/11/2026: estava forte demais).
const ACT_SUN_K := {0: 0.4, 1: 0.5, 2: 1.3}     # 21/11/2026: energia do sol por ato (ato 3 estava escuro: sobe)
const ACT_SHADOW_OP := {0: 0.4, 1: 0.6, 2: 1.0}  # opacidade da sombra por ato (ato 1 mais transparente; ato 3 padrão)

func _apply_act_look(s: Sim, blend := false) -> void:
	built_act = s.act
	var A: Array = data.rules.get("acts", [])
	GroundLooks.act_look = int(A[s.act].get("ground_look", -1)) if s.act < A.size() else -1
	if world_env and sun:
		var old := _env_snapshot() if blend else {}
		GroundLooks.apply_env(world_env, sun, rim_light)
		LuzLook.apply(world_env, sun, rim_light)
		if ACT_SUN_K.has(s.act):
			sun.light_energy *= ACT_SUN_K[s.act]
			sun.shadow_opacity = ACT_SHADOW_OP[s.act]
		else:
			sun.shadow_opacity = 1.0
		Diorama.apply_env(world_env, sun, rim_light, s.act)
		if blend and not old.is_empty():
			var nw := _env_snapshot()
			_env_apply(old, nw, 0.0)
			var tw := create_tween()
			tw.tween_method(func(v: float): _env_apply(old, nw, v), 0.0, 1.0, 3.0)
			tw.finished.connect(func(): _env_apply(old, nw, 1.0))


## Luz, céu e névoa como números, para a troca de ato misturar de um ato para o outro (C17, 19/11/2026).
func _env_snapshot() -> Dictionary:
	var d := {"sun_c": sun.light_color, "sun_e": sun.light_energy, "sun_r": sun.rotation_degrees,
		"amb_c": world_env.ambient_light_color, "amb_e": world_env.ambient_light_energy, "fog_c": world_env.fog_light_color,
		"fog_d": world_env.fog_density, "expo": world_env.tonemap_exposure, "sat": world_env.adjustment_saturation,
		"con": world_env.adjustment_contrast}
	d["vfog"] = world_env.volumetric_fog_density
	d["fsky"] = world_env.fog_sky_affect
	if rim_light:
		d["rim_c"] = rim_light.light_color
		d["rim_e"] = rim_light.light_energy
	var sm := world_env.sky.sky_material if world_env.sky else null
	if sm is ProceduralSkyMaterial:
		d["sky_t"] = sm.sky_top_color
		d["sky_h"] = sm.sky_horizon_color
		d["sky_g"] = sm.ground_bottom_color
	return d


func _env_apply(a: Dictionary, b: Dictionary, v: float) -> void:
	if not is_instance_valid(sun) or world_env == null:
		return
	sun.light_color = a["sun_c"].lerp(b["sun_c"], v)
	sun.light_energy = lerpf(a["sun_e"], b["sun_e"], v)
	sun.rotation_degrees = a["sun_r"].lerp(b["sun_r"], v)
	world_env.ambient_light_color = a["amb_c"].lerp(b["amb_c"], v)
	world_env.ambient_light_energy = lerpf(a["amb_e"], b["amb_e"], v)
	world_env.fog_light_color = a["fog_c"].lerp(b["fog_c"], v)
	world_env.fog_density = lerpf(a["fog_d"], b["fog_d"], v)
	world_env.tonemap_exposure = lerpf(a["expo"], b["expo"], v)
	world_env.adjustment_saturation = lerpf(a["sat"], b["sat"], v)
	world_env.adjustment_contrast = lerpf(a["con"], b["con"], v)
	if a.has("vfog") and b.has("vfog"):
		world_env.volumetric_fog_density = lerpf(a["vfog"], b["vfog"], v)
		world_env.fog_sky_affect = lerpf(a["fsky"], b["fsky"], v)
	if rim_light and a.has("rim_c") and b.has("rim_c"):
		rim_light.light_color = a["rim_c"].lerp(b["rim_c"], v)
		rim_light.light_energy = lerpf(a["rim_e"], b["rim_e"], v)
	var sm := world_env.sky.sky_material if world_env.sky else null
	if sm is ProceduralSkyMaterial and a.has("sky_t") and b.has("sky_t"):
		sm.sky_top_color = a["sky_t"].lerp(b["sky_t"], v)
		sm.sky_horizon_color = a["sky_h"].lerp(b["sky_h"], v)
		sm.ground_horizon_color = sm.sky_horizon_color
		sm.ground_bottom_color = a["sky_g"].lerp(b["sky_g"], v)


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
var run_end: RunEnd                 # tela de fim da run (Almas, recorde, desafios; frente G, 21/11/2026)
var end_layer: CanvasLayer
var end_info: Dictionary = {}       # o que MetaSave.apply_run devolveu para a run que acabou
var pause_powers_box: VBoxContainer # "Poderes da party" na pausa
var give_up_row: HBoxContainer      # confirmação de "Desistir"
var sun: DirectionalLight3D
var rim_light: DirectionalLight3D
var built_act := -1                 # ato cujo mundo está montado (cada ato tem o seu chão, rodada 09/11/2026)
var world_env: Environment


func _show_menu(screen: String) -> void:
	Tips.close_all()
	hud.show_run(false)
	menu.visible = true
	menu.show_screen(screen)


## Sai da run para o menu. A run em andamento fica salva (o menu oferece Continuar). `target` abre outra tela
## (o fim da run leva ao "covil"); `decks` abre a escolha de vilão.
func _to_menu(decks: bool, target := "") -> void:
	if running and sim and sim.phase != K.Phase.OVER and not auto_args.has("autoplay"):
		SaveGame.save(sim)
	running = false
	run_end.visible = false
	end_info = {}
	tutorial.visible = false
	tutorial.sim = null
	Engine.time_scale = 1.0
	world.cine_t = -1.0
	paused = false
	sim = null
	world.build_empty()
	_build_menu_scene()
	audio.music_menu()
	audio.set_intensity(0.0)
	_show_menu(target if target != "" else ("decks" if decks else "title"))


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


## Mesa do Lorde em 3D atrás do menu (DeskScene), com os papéis das telas.
func _build_menu_scene() -> void:
	if menu_root:
		menu_root.queue_free()
	var dk := DeskScene.new()
	dk.setup(cam, world_env, [sun, rim_light], menu, data)
	menu_root = dk
	add_child(dk)
	menu.desk = dk
	dk.paper_clicked.connect(func(id: String):
		if id == "continue":
			_continue()
		else:
			menu.show_screen(id))


var save_t := 0.0
var menu_shift := 3.4


func _continue() -> void:
	var s := SaveGame.load_run(data, "", MetaApply.run_mods(meta))   # o save guarda os mods da run; a meta atual só cobre save sem eles
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


## Tutorial (fase 0, config própria em data/campaign.json): sem mods da meta, deck pronto da Praga.
func _start_tutorial() -> void:
	_start("plague", 0)


## Começa a run do vilão: o deck montado (19 cartas) e os mods da meta (Covil, níveis, relíquias). Os modos de teste
## e de captura (qualquer --x=y) jogam o deck pronto do vilão sem mods (reproduzível); o tutorial (fase 0) também.
func _start(deck: String, phase := -1) -> void:
	var s := Sim.new()
	var seed_ := int(auto_args.get("seed", int(Time.get_unix_time_from_system()) % 1000000))
	var ph := phase if phase >= 0 else int(auto_args.get("phase", 1))
	if data.phase(ph).has("deck"):
		deck = str(data.phase(ph)["deck"])
	# --firstparty=guardiao.cleriga.mago.assassino: a primeira party da fase, só nesta execução (capturas da HUD com 4 heróis).
	if auto_args.has("firstparty"):
		var ps: Array = data.phase(ph).get("parties", []).duplicate(true)
		var first := Array(str(auto_args["firstparty"]).split(".", false))
		if ps.is_empty():
			ps.append(first)
		else:
			ps[0] = first
		data.phase(ph)["parties"] = ps
	# --herohp=50: multiplica a vida dos heróis só nesta execução (capturas que precisam chegar ao ato 3).
	if auto_args.has("herohp"):
		data.phase(ph)["hp_mult"] = float(auto_args["herohp"])
	# --menutest e --gshots usam o fluxo real do menu (deck e mods da meta de teste); os outros modos, não.
	var meta_run := auto_args.is_empty() or auto_args.has("menutest") or auto_args.has("gshots")
	if meta_run and ph > 0:
		meta.villain = data.villain_id(deck)
		s.setup(data, seed_, deck, meta.deck_for(deck), meta.unlocked, ph, MetaApply.run_mods(meta))
	elif meta_run:
		s.setup(data, seed_, deck, [], meta.unlocked, ph)
	else:
		s.setup(data, seed_, deck, [], [], ph)
	# Capturas e testes de janela sem bot seguem o primeiro ramo (com --routewait, esperam a escolha como no jogo).
	s.notify_gives = not auto_args.has("autoplay")
	s.auto_route = not auto_args.is_empty() and not auto_args.has("autoplay") and not auto_args.has("routewait") and not auto_args.has("routetest")
	_begin(s)


## A party que está em campo passa a ser "vista": o mapa da campanha revela essas classes (16/11/2026). Grava na
## hora, para sair no meio da run não perder. Os modos de teste gravam no meta de teste.
func _mark_heroes_seen() -> void:
	if sim == null or meta == null:
		return
	var p := sim.party_number(sim.party_idx)
	if p == seen_party:
		return
	seen_party = p
	var fresh := false
	for i in sim.party_members(p) if sim.party_of.size() > 0 else [sim.party_idx]:
		fresh = meta.see_hero(sim.party_class(int(i))) or fresh
	if fresh:
		meta.save()


func _begin(s: Sim) -> void:
	if menu_root:
		menu_root.queue_free()
		menu_root = null
	sim = s
	sim.record_events = true
	seen_party = -1
	result_played = false
	map_after = false   # o mapa pós-local pendente da run anterior não abre na nova
	map_after_t = 0.0
	map_after_open = false
	audio.music_for_run(sim)
	audio.set_intensity(0.0)
	_apply_act_look(sim)
	world.build(sim, cam)
	arena_built = false
	save_t = sim.t
	menu.visible = false
	hud.bind(sim)
	hud.speed = speed
	if sim.phase_cfg.get("tutorial", false):
		tutorial.bind(sim)
	else:
		tutorial.visible = false
	running = true
	paused = false
	acc = 0.0


# ---------------------------------------------------------------- laço

func _process(delta: float) -> void:
	life += delta
	if auto_args.has("bare"):
		_bare_ui()
	if DisplayServer.get_name() != "headless":
		UiKit.sync(get_viewport())
	if menu_root and not running and not (menu_root is DeskScene):
		menu_t += delta * 0.15
		var a := sin(menu_t * 2.0) * 0.55
		cam.position = Vector3(sin(a) * 12.0, 2.6, -cos(a) * 12.0 - 1.0)
		cam.look_at(Vector3(0, 1.2, -1.0), Vector3.UP)
		# Na tela de título o chefe fica à direita, livre do texto; nas outras, ao fundo e no centro.
		var shift := 3.4 if menu.screen == "title" else 0.0
		menu_shift = lerpf(menu_shift, shift, clampf(delta * 3.0, 0.0, 1.0))
		cam.look_at(Vector3(0, 1.2, -1.0) - cam.global_transform.basis.x * menu_shift, Vector3.UP)
	# --spacetest=<nome da tela>: no instante --spaceat (padrão 4 s) roda a auditoria de folga da interface (tools/space_audit.sh).
	if auto_args.has("spacetest") and not auto_args.has("_spacedone") and life >= float(auto_args.get("spaceat", "4")):
		auto_args["_spacedone"] = true
		_space_scan(str(auto_args["spacetest"]))
	if auto_args.has("quit") and life >= float(auto_args["quit"]):
		if sim:
			print("autoplay fim: t=%.0f fase=%d resultado=%s unidades=%d fps=%d menu=%s run=%s" % [sim.t, sim.phase, sim.stats["result"], sim.units.count, Engine.get_frames_per_second(), menu.visible, running])
		get_tree().quit(0)
		return
	if shots.size() > 0 and life >= float(shots[0]):
		shots.pop_front()
		var img := get_viewport().get_texture().get_image()
		var path := str(auto_args.get("out", "user://")) + "shot_%03d.png" % int(life)
		img.save_png(path)
		print("captura: ", path)
		if auto_args.has("hudlayout") and hud.visible:
			print("hud sobreposicoes: ", hud.overlap_report())
	if not running or sim == null:
		return
	# Capturas da mão (rodada C-UI): --elixirmax=20 (barra), --cost=12 (custo da mão), --discardfill=6, --pile=draw|discard,
	# --stages=1 (disputa com a barra no 1º marco, no painel).
	if life >= 2.0 and not auto_args.has("_capdone") and (auto_args.has("elixirmax") or auto_args.has("cost") or auto_args.has("discardfill") or auto_args.has("pile") or auto_args.has("stages")):
		auto_args["_capdone"] = true
		if auto_args.has("elixirmax"):
			sim.elixir_max = float(auto_args["elixirmax"])
			sim.elixir = sim.elixir_max * 0.65
		if auto_args.has("cost"):
			for ci in sim.hand:
				if ci != null:
					ci.def.cost = int(auto_args["cost"])
		for i in int(auto_args.get("discardfill", "0")):
			if sim.queue.size() > 0:
				sim.discard.append(sim.queue.pop_back())
		if auto_args.has("stages"):
			_debug_contest("tavern")
			sim.contest["progress"] = 1.5
			sim.contest["won"] = 1
	if auto_args.has("pile") and life >= 3.0:
		var pw := str(auto_args["pile"])
		auto_args.erase("pile")
		hud.fan._open_pile(pw)
	# --contestend=<s>:<n>: com uma disputa rodando (--offer=contest:<tipo>), termina ela nesse instante com n marcos
	# (0 = falha; no ajudante, n > 0 = vencido). Capturas da cena do local (15/11/2026).
	if auto_args.has("contestend") and sim.contest.size() > 0:
		var cw := str(auto_args["contestend"]).split(":")
		if life >= float(cw[0]):
			auto_args.erase("contestend")
			var cn := int(cw[1]) if cw.size() > 1 else 3
			var cty := str(sim.contest["type"])
			if cty == "helper":
				sim._resolve_helper(cn > 0)
			else:
				if cn >= 3 and cw.size() > 2 and cw[2] == "hard":
					sim.road.locations[int(sim.contest["li"])]["hard"] = true
				sim._resolve_contest(cn)
			world.handle_events(sim.events)
			hud.handle_events(sim.events)
			audio.handle_events(sim.events, sim)
			sim.events.clear()
			_scene_gates()
	# --skipkey=<s>: aperta espaço de verdade nesse instante (pulo da cena do local); --pick=<s>: a partir desse
	# instante escolhe a 1ª opção de cada oferta que aparecer na tela (o mapa do fim do local abre depois).
	if auto_args.has("select") and sim and sim.offers.is_empty() and sim.phase != K.Phase.OVER:
		hud.selected = int(auto_args["select"])   # captura: segura a carta N da mão (anel de alcance)
	if auto_args.has("skipkey") and life >= float(auto_args["skipkey"]):
		auto_args.erase("skipkey")
		var ke := InputEventKey.new()
		ke.keycode = KEY_SPACE
		ke.pressed = true
		Input.parse_input_event(ke)
		print("cena: espaço apertado; cena ativa=%s, t=%.2f" % [not world.scene.is_empty(), float(world.scene.get("t", -1.0))])
	if auto_args.has("pick") and life >= float(auto_args["pick"]) and sim.offers.size() > 0 and not hud.hold_offers:
		hud.choose_offer(0, true)
	# --shopbuy=<s>: com a loja aberta (--offer=shop), compra pela Hud a 1ª carta e o modificador nesse instante;
	# --shopgold=<n> deixa esse ouro depois (captura do livro-caixa com vendidos, registro e falta de ouro).
	if auto_args.has("shopbuy") and life >= float(auto_args["shopbuy"]) and sim.offers.size() > 0 and sim.offers[0]["source"] == "shop":
		auto_args.erase("shopbuy")
		hud.choose_offer(0)
		for bi in sim.offers[0]["options"].size() if sim.offers.size() > 0 else 0:
			if sim.offers[0]["options"][bi]["item"]["kind"] == "mod":
				hud.choose_offer(bi)
				break
		if auto_args.has("shopgold"):
			sim.gold = float(auto_args["shopgold"])
	if auto_args.has("pauseat") and life >= float(auto_args["pauseat"]):
		auto_args.erase("pauseat")
		_toggle_pause()
	if auto_args.has("offerat") and life >= float(auto_args["offerat"]):
		auto_args.erase("offerat")
		# --offer=ritual (ou fountain:0 etc.) abre a recompensa de um local; sem ela, um level-up.
		if auto_args.has("offer"):
			var ow := str(auto_args["offer"]).split(":")
			if ow[0] == "shop":
				# --offer=shop: loja com 200 de ouro. Extras (separados por :): purse = Bolsa do Mercador (carta a mais),
				# big = deck com 24 cartas a mais, upgrade/remove = já compra a escolha de carta do deck.
				sim.gold = 200.0
				if ow.has("purse"):
					sim.relics.append("merchant_purse")
					sim.rebuild_rfx()
				if ow.has("big"):
					for i in 24:
						sim._new_inst(sim.data.cards[i % sim.data.cards.size()])
				sim._open_shop()
				for pk in ["upgrade", "remove"]:
					if ow.has(pk):
						for bi in sim.offers[0]["options"].size():
							var bo: Dictionary = sim.offers[0]["options"][bi]
							if bo["item"]["kind"] == "pick" and bo["item"]["what"] == pk:
								sim._buy(bi)
								break
			elif ow[0] == "relic":
				# --offer=relic: escolha de relíquia do fim do ato.
				sim._offer_relics()
			elif ow[0] == "event":
				# --offer=event (ou event:<id>): evento de texto, com 100 de ouro.
				sim.gold = 100.0
				if ow.size() > 1:
					sim.events_seen = sim.data.event_ids.filter(func(e): return e != ow[1])
				sim._offer_event()
			elif ow[0] == "contest":
				# --offer=contest:<tipo>: o herói chega a um local desse tipo e a disputa começa.
				_debug_contest(ow[1] if ow.size() > 1 else "tavern")
			else:
				sim._offer_marks(ow[0], 3 if (ow.size() < 2 or ow[1] != "0") else 1)
		else:
			sim._offer_level()
			sim.damage_hero(1.0, sim.hero.x, sim.hero.y + 5.0, 0, SimHero.DMG_PIERCE, "test")
	# Uma oferta, a bifurcação ou o mapa grande abrindo soltam a carta da mão; antes ela ficava erguida por cima
	# das outras até o clique direito. Só na transição: com oferta aberta o controle usa hud.selected como cursor.
	var blocking := not sim.offers.is_empty() or sim.route_wait or hud.minimap.visible
	if blocking and not was_blocking and hud.selected >= 0:
		var sel_ci := sim.hand_card(hud.selected)
		if not (hud.minimap.visible and sim.offers.is_empty() and not sim.route_wait and sel_ci and sel_ci.def.id == "burn_village"):
			hud.selected = -1
	was_blocking = blocking
	if status_ov.sim != sim:
		status_ov.setup(sim, world, cam)
	status_ov.visible = not world.cine_active()
	# Cena da morte do herói e cena do local: a recompensa só abre quando a cena acaba; cartas travadas.
	_scene_gates()
	_map_after_location(delta)
	# --spawn=<id>,<id>: coloca essas criaturas em campo, em arco diante do herói, 2 s depois do início (fotos do mapa).
	if auto_args.has("spawn") and life >= 2.0:
		var sp_ids: PackedStringArray = str(auto_args["spawn"]).split(",", false)
		auto_args.erase("spawn")
		for si in sp_ids.size():
			var sa := -0.9 + 1.8 * float(si) / maxf(sp_ids.size() - 1.0, 1.0)
			var sc_: CardDef = data.card(sp_ids[si])
			sim.units.spawn(sc_, sim.hero.x + sin(sa) * 9.0, sim.hero.y - cos(sa) * 9.0 - 2.0, 0.0, 0.0, K.F_NO_XP, 0)
	# --fxdemo=<id>,<id>: joga esses feitiços um a cada 0,8 s diante do herói, com elixir cheio (captura dos efeitos,
	# rodada visual 20/11/2026). Só para capturas: não mexe em nada sem o argumento.
	# --camzoom=<n>: câmera mais perto (negativo) ou longe, só para capturas de detalhe.
	if auto_args.has("camzoom"):
		world.zoom = float(auto_args["camzoom"])
	# --camlair=1: a câmera mira o covil do último ato (capturas dos modelos, 20/11/2026).
	if auto_args.has("camlair"):
		if world.lair_pos == Vector3.ZERO and sim.act + 1 >= sim.acts():
			world._build_lair()   # o --skip=arena pula a montagem da estrada do último ato
			# --camlair=2: gira o covil para a frente (a boca) ficar virada para a câmera.
			if str(auto_args["camlair"]) == "2" and world.lair_node:
				world.lair_node.rotation.y += PI
		world.cam_lair = true
	# Contado no tempo da run (sim.t), não do processo: a carga varia e a foto não pode pegar o menu.
	# --fxshot=<s>: depois do último feitiço, espera s segundos de run, salva <out>fx.png e fecha.
	if auto_args.has("fxdemo") and sim.t >= float(auto_args.get("fxat", "2")):
		var fx_t0 := float(auto_args.get("fxat", "2"))
		var fx_ids: PackedStringArray = str(auto_args["fxdemo"]).split(",", false)
		var fx_i := int(auto_args.get("_fxi", "0"))
		if fx_i >= fx_ids.size():
			if not auto_args.has("_fxlife"):
				auto_args["_fxlife"] = str(life)
			# --fxwait=<s>: espera também s segundos de relógio (a câmera assenta depois de um --skip longo).
			var waited := life - float(auto_args["_fxlife"]) >= float(auto_args.get("fxwait", "0"))
			if waited and auto_args.has("fxshot") and sim.t >= fx_t0 + (fx_ids.size() - 1) * float(auto_args.get("fxgap", "0.8")) + float(auto_args["fxshot"]):
				var vs := get_viewport().get_visible_rect().size
				var sp := cam.unproject_position(Vector3(sim.hero.x, 0.8, sim.hero.y))
				print("fxdemo_screen %.4f %.4f" % [sp.x / vs.x, sp.y / vs.y])
				if auto_args.has("out"):
					get_viewport().get_texture().get_image().save_png(str(auto_args["out"]) + "fx.png")
				auto_args.erase("fxdemo")
				get_tree().quit()
		elif sim.t >= fx_t0 + fx_i * float(auto_args.get("fxgap", "0.8")):
			auto_args["_fxi"] = str(fx_i + 1)
			var fd := float(auto_args.get("fxdist", "0"))
			var fa := -0.8 + 1.6 * float(fx_i) / maxf(fx_ids.size() - 1.0, 1.0)
			sim.hand[0] = sim._new_inst(data.card(fx_ids[fx_i]))
			sim.elixir = maxf(sim.elixir, 20.0)
			sim.play(0, sim.hero.x + sin(fa) * fd, sim.hero.y - cos(fa) * fd)
			var fd_vs := get_viewport().get_visible_rect().size
			var fd_sp := cam.unproject_position(Vector3(sim.hero.x + sin(fa) * fd, 0.8, sim.hero.y - cos(fa) * fd))
			print("fxclip %d %.4f %.4f %s" % [Engine.get_frames_drawn(), fd_sp.x / fd_vs.x, fd_sp.y / fd_vs.y, fx_ids[fx_i]])
	# Capturas de efeito: o mouse fica no centro da janela, senão a câmera acompanha o cursor de verdade e o
	# enquadramento muda de uma gravação para outra.
	if (auto_args.has("fxend") or auto_args.has("fxshot")) and not bg_mode:
		get_viewport().warp_mouse(get_viewport().get_visible_rect().size * 0.5)
	# --herostop=<s>: a partir desse tempo da run o herói fica parado onde está (os efeitos não ficam para trás).
	if auto_args.has("herostop") and sim.t >= float(auto_args["herostop"]):
		if not auto_args.has("_hs"):
			auto_args["_hs"] = "%f,%f" % [sim.hero.x, sim.hero.y]
		var hs: PackedStringArray = str(auto_args["_hs"]).split(",")
		sim.hero.x = float(hs[0])
		sim.hero.y = float(hs[1])
	# --fxemit=<tipo>[:escala],<tipo>...: dispara efeitos prontos (hit, death, heal, shield, level, magic, collapse...)
	# diante do herói, um a cada --fxegap s (4), a partir de --fxeat (tempo da run). Imprime "fxclip <quadro do filme>
	# <x> <y> <rótulo>" (posição do herói na tela, 0..1) para recortar o clipe e achar o pico. --fxgap=<s> espaça o --fxdemo.
	# --fxend=<s>: fecha nesse tempo da run (clipes com --write-movie). Só capturas.
	if auto_args.has("fxemit") and sim.t >= float(auto_args.get("fxeat", "2")):
		var fe_list: PackedStringArray = str(auto_args["fxemit"]).split(",", false)
		var fe_n := int(auto_args.get("_fxen", "0"))
		if fe_n < fe_list.size() and sim.t >= float(auto_args.get("fxeat", "2")) + float(auto_args.get("fxegap", "4")) * fe_n:
			auto_args["_fxen"] = str(fe_n + 1)
			var fe_parts: PackedStringArray = fe_list[fe_n].split(":")
			var fe_s := float(fe_parts[1]) if fe_parts.size() > 1 else 1.0
			var fe_pos := Vector3(sim.hero.x, 1.0, sim.hero.y - float(auto_args.get("fxdist", "3")))
			world.emit_fx(fe_parts[0], fe_pos, fe_s, Color.WHITE)
			var fe_vs := get_viewport().get_visible_rect().size
			var fe_sp := cam.unproject_position(fe_pos)
			print("fxclip %d %.4f %.4f %s" % [Engine.get_frames_drawn(), fe_sp.x / fe_vs.x, fe_sp.y / fe_vs.y, fe_parts[0]])
	if auto_args.has("fxend"):
		# --fxrel=1: --fxend conta a partir do primeiro quadro (depois de um --skip longo, o tempo da run já vai longe).
		if auto_args.has("fxrel") and not auto_args.has("_fxbase"):
			auto_args["_fxbase"] = str(sim.t)
			print("fxclip %d 0 0 base" % Engine.get_frames_drawn())
		if sim.t >= float(auto_args["fxend"]) + float(auto_args.get("_fxbase", "0")):
			get_tree().quit()
	# --statusdemo=1: herói com vários efeitos ao mesmo tempo (captura dos selos de status).
	if auto_args.has("statusdemo") and life >= 2.0:
		auto_args.erase("statusdemo")
		sim.hero.slow_t = 4.0
		sim.hero.soaked_t = 6.0
		sim.mark_until = sim.t + 5.0
		CardsCommon._st(sim)["weak_until"] = sim.t + 8.0
		CardsCommon._st(sim)["weak"] = 0.3
		sim.hero.curses = 2
	# --aim=<id da carta>: essa carta na vaga 1, selecionada, mirando no herói (captura da prévia do feitiço).
	if auto_args.has("aim") and life >= 2.5:
		sim.hand[0] = sim._new_inst(data.card(str(auto_args["aim"])))
		auto_args.erase("aim")
		hud.selected = 0
		pad_active = true
		var off_ := float(auto_args.get("aimoff", "0"))
		cursor = cam.unproject_position(Vector3(sim.hero.x + off_, 0.0, sim.hero.y))
	# --hand=<n>: mão com n cartas (captura da interface com mão cheia, até HAND_MAX).
	if auto_args.has("hand") and sim.hand_size != int(auto_args["hand"]):
		sim.hand_size = int(auto_args["hand"])
		sim._refill_hand()
	# --powers=id:nivel,id:nivel: dá esses poderes à party (recargas variadas) uma vez; --powerat=<s>:id:nivel:anterior abre
	# o painel de revelação desse poder (anterior 0 = novo). Capturas da HUD dos poderes (frente H, 22/11/2026).
	if auto_args.has("powers") and sim.phase != K.Phase.OVER:
		var pk := 0
		for pw in str(auto_args["powers"]).split(",", false):
			var pp := pw.split(":")
			var pd: Dictionary = sim.data.hero_powers.get(pp[0], {})
			if not pd.is_empty():
				var plv := int(pp[1]) if pp.size() > 1 else 1
				var pcd := float(pd["cooldown"][clampi(plv, 1, 3) - 1])
				sim.powers.append({"id": pp[0], "level": plv, "cd_left": 0.0 if pk % 3 == 2 else pcd * (0.25 + 0.2 * (pk % 4)), "gap_left": 0.0})
				pk += 1
		auto_args.erase("powers")
	if auto_args.has("powerat") and life >= float(str(auto_args["powerat"]).split(":")[0]):
		var pa := str(auto_args["powerat"]).split(":")
		auto_args.erase("powerat")
		var pcd2 := float(sim.data.hero_powers[pa[1]]["cooldown"][clampi(int(pa[2]), 1, 3) - 1])
		sim.offers.append({"source": "power", "options": [{"kind": "power", "id": pa[1], "level": int(pa[2]), "prev_level": int(pa[3]),
			"new": int(pa[3]) == 0, "cooldown": pcd2}], "powers": sim.party_powers()})
	# --killat=<s>: derruba o herói nesse instante (captura da cena da queda).
	# --killat=5 derruba o herói da vez aos 5 s; --killat=5,7 derruba um aos 5 s e o próximo líder aos 7 s (party de 4
	# nas capturas, 16/11/2026).
	if auto_args.has("killat") and life >= float(str(auto_args["killat"]).split(",")[0]):
		var rest: Array = Array(str(auto_args["killat"]).split(",")).slice(1)
		if rest.is_empty():
			auto_args.erase("killat")
		else:
			auto_args["killat"] = ",".join(rest)
		sim.damage_hero(sim.hero.hp + 99999.0, sim.hero.x, sim.hero.y + 1.0, 0, SimHero.DMG_PIERCE, "test")
	if auto_bot:
		auto_bot.think(sim)
	# --mapshot=<s>: abre o mapa grande nesse instante (capturas do mapa); --mapscroll=<y> rola até essa altura
	# do mapa (em unidades de desenho de uma tela 1920x1080; 0 = topo, onde fica o último ato).
	if auto_args.has("mapshot") and life >= float(auto_args["mapshot"]) and sim.phase == K.Phase.ROAD:
		auto_args.erase("mapshot")
		if not hud.minimap.visible:
			_toggle_map()
		if auto_args.has("mapscroll"):
			# --mapscroll=river[N]: centra no N-ésimo rio do ato (capturas dos rios, 16/11/2026).
			var ms := str(auto_args["mapscroll"])
			if ms.begins_with("river"):
				hud.minimap.scroll_to_design(hud.minimap.river_y(int(ms.trim_prefix("river"))) - 540.0)
			else:
				hud.minimap.scroll_to_design(float(ms))
	# Bifurcação sem escolha: o jogo espera e o mapa grande abre sozinho (nunca por cima da cena do local).
	if sim.route_wait and not hud.minimap.visible and sim.offers.is_empty() and not world.cine_active():
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
	# Com o mapa em tela cheia aberto, a run fica parada (nas bifurcações o herói já espera).
	# A caixa do tutorial fica acima da pausa: com o jogo pausado ela some e não pega o mouse, senão cobria as
	# configurações e segurava os cliques (achado do --menutest, 10/11/2026).
	tutorial.modulate.a = 0.0 if paused else 1.0
	tutorial.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED if paused else Control.MOUSE_BEHAVIOR_INHERITED
	tutorial.tick()
	if not paused and not stopped and not hud.minimap.visible and not tutorial.holding:
		acc = minf(acc + delta * speed, sim.dt * 12.0)
		while acc >= sim.dt:
			sim.step()
			acc -= sim.dt
			world.handle_events(sim.events)
			hud.handle_events(sim.events)
			audio.handle_events(sim.events, sim)
			sim.events.clear()
			# A cena do local começou neste passo: segura a oferta já, sem ela piscar por um quadro.
			_scene_gates()
			if sim.offers.size() > 0 and world.scene.is_empty():
				acc = 0.0
				break
	_mark_heroes_seen()
	# Fim de ato: a velocidade volta a 1 (nos testes automáticos ela é a do argumento).
	if sim.act_pending and not act_end_seen and auto_args.is_empty():
		speed = 1.0
		hud.speed = speed
	act_end_seen = sim.act_pending
	# Chegar ao ato 2 pela primeira vez abre o setor "Troca de ato" do Covil.
	if sim.act >= 1 and not sim.phase_cfg.get("tutorial", false) and meta.see_act2():
		meta.save()
	# Ato novo: estrada nova, chão e luz do ato.
	if sim.phase == K.Phase.ROAD and sim.act != built_act:
		var first := built_act < 0 or world.sim != sim
		var pre: bool = not first and world.pre_ready()
		var t_sw := Time.get_ticks_usec()
		_apply_act_look(sim, not first)
		if pre:
			world.commit_next()   # o ato novo já foi montado antes, aos poucos: só adota
		else:
			world.build(sim, cam, not first)
		if world.pre_log:
			print("troca de ato (%s): %.1f ms" % ["pré-montado" if pre else "montagem inteira", (Time.get_ticks_usec() - t_sw) / 1000.0])
	if sim.phase == K.Phase.ARENA and not arena_built:
		arena_built = true
		world.build_arena()
		hud.say(tr("UI_ARENA"))
		overtime_said = false
	if sim.phase == K.Phase.ARENA and not overtime_said and sim.overtime() > 0.0:
		overtime_said = true
		hud.say(tr("UI_OVERTIME"))
	if sim.phase == K.Phase.ROAD:
		audio.set_intensity(sim.hero.s / maxf(sim.road.length(), 1.0) * (0.6 if not sim.road.complete else 1.0))
	if sim.phase != K.Phase.OVER and sim.t - save_t > 10.0 and not auto_args.has("autoplay") and not auto_args.has("humantest"):
		save_t = sim.t
		SaveGame.save(sim)
	if sim.phase == K.Phase.OVER and not result_played:
		result_played = true
		SaveGame.erase()
		# Fim da run (vitória ou derrota): Almas (dano + heróis, mantidas ao perder), recorde, desafios e vilões
		# liberados. apply_run grava no arquivo da meta (nos modos de teste, o de teste) e devolve o resumo.
		end_info = meta.apply_run(sim)
		run_end.show_result(data, meta, sim, end_info)
		audio.result_music(sim.result in [K.Result.WIN, K.Result.WIN_EARLY])
	var alpha := 1.0 if sim.waiting_choice() else clampf(acc / sim.dt, 0.0, 1.0)
	world.look_freeze = hud.fan != null and (hud.fan.hover >= 0 or hud.fan.press_i >= 0)
	world.draw(alpha, delta * (0.15 if stopped else 1.0))
	flash_rect.color = world.screen_flash if Settings.v["flash"] else Color(0, 0, 0, 0)
	_update_placement()
	hud.pad = pad_active
	hud.refresh(delta, Engine.get_frames_per_second())
	if sim.phase == K.Phase.OVER and run_end.visible and hud.result_layer.visible:
		# A tela de fim da run (game/run_end.gd) toma o lugar do painel antigo do HUD.
		hud.result_layer.visible = false
		run_end.focus_first.call_deferred()


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
	# Sem sacrifício da mão (11/11/2026): clique direito numa carta não tira a carta da mão nem mexe no elixir.
	var h0: Array = sim.hand.duplicate()
	var e0 := sim.elixir
	var rc := InputEventMouseButton.new()
	rc.button_index = MOUSE_BUTTON_RIGHT
	rc.pressed = true
	rc.position = hud.fan.get_global_rect().get_center()
	Input.parse_input_event(rc)
	var rcu := rc.duplicate()
	rcu.pressed = false
	Input.parse_input_event(rcu)
	await get_tree().process_frame
	await get_tree().process_frame
	var rc_ok := sim.hand == h0 and sim.elixir >= e0 - 0.001
	print("uitest clique direito na carta não faz nada: ", rc_ok)
	ok = ok and rc_ok
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
	# Eventos entram em pixels da janela: passam pela escala do conteúdo (10/11/2026: sem isso, o aperto
	# caía fora da carta quando a janela não tinha o tamanho base, e o arrasto nunca começava).
	var win := get_viewport().get_final_transform()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = win * c0
	down.global_position = win * c0
	Input.parse_input_event(down)
	await get_tree().process_frame
	var tgt := cam.unproject_position(Vector3(sim.hero.x, 0, sim.hero.y) + Vector3(5, 0, -3))
	# O arrasto passa por pontos no caminho, como a mão de uma pessoa (um salto só, direto do leque ao
	# mundo, não chegava a soltar a carta; o --humantest arrasta assim desde 10/11/2026).
	for k in 5:
		var mv := InputEventMouseMotion.new()
		mv.position = win * c0.lerp(tgt, (k + 1) / 5.0)
		mv.global_position = mv.position
		mv.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(mv)
		await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = win * tgt
	up.global_position = win * tgt
	Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame
	var after := 0
	for k2 in sim.stats["played"]:
		after += int(sim.stats["played"][k2])
	print("uitest arrastar e soltar jogou a carta: ", after == before + 1)
	ok = ok and after == before + 1
	# Loja (livro-caixa): sem ouro o Enter não compra e avisa; com ouro, Enter compra o item em foco; um clique
	# na linha de Subir nível abre o passo do baralho, Enter confirma e volta à loja; 0 sai.
	ok = ok and await _shop_ui_test()
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
	mb.position = get_viewport().get_final_transform() * (mm.global_position + mm.node_point(far))
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
	if alt >= 0 and not hud.strip.visible:
		print("routetest clique na faixa: pulado (sem a faixa na HUD 7)")
	elif alt >= 0:
		var st := hud.strip
		var mb2 := InputEventMouseButton.new()
		mb2.button_index = MOUSE_BUTTON_LEFT
		mb2.pressed = true
		mb2.position = get_viewport().get_final_transform() * (st.global_position + st._node_point(alt))
		Input.parse_input_event(mb2)
		await get_tree().process_frame
		await get_tree().process_frame
		var replanned: bool = sim.road.s_of_node(alt) >= 0.0 and sim.road.s_of_node(far) < 0.0
		print("routetest clique na faixa troca o plano: ", replanned)
		ok = ok and replanned
	print("routetest resultado: ", "OK" if ok else "FALHOU")
	get_tree().quit(0 if ok else 1)


## Captura do teste da entrada (só com --out=<pasta>).
func _shop_ui_test() -> bool:
	var ok := true
	sim.gold = 0.0
	sim._open_shop()
	for _f in 3:
		await get_tree().process_frame
	var n0: int = sim.offers[0]["options"].size()
	var shown := hud.ledger.is_visible_in_tree() and hud.selected == 0
	await _key(KEY_ENTER)
	var refused: bool = sim.offers[0]["options"].size() == n0 and hud.ledger.toast_bad
	print("uitest loja abre no livro-caixa com foco: ", shown, " · sem ouro não compra e avisa: ", refused)
	ok = ok and shown and refused
	_ui_shot("shop")
	sim.gold = 999.0
	var cards0 := sim.cards.size()
	await _key(KEY_ENTER)
	var bought: bool = sim.cards.size() == cards0 + 1 and sim.offers[0]["options"].size() == n0 - 1 and hud.ledger.rows[0]["sold"]
	print("uitest Enter compra o item em foco (vendido no livro): ", bought)
	ok = ok and bought
	var up_k := -1
	for i in sim.offers[0]["options"].size():
		var it: Dictionary = sim.offers[0]["options"][i]["item"]
		if it["kind"] == "pick" and it["what"] == "upgrade":
			up_k = i
	var picked := false
	if up_k >= 0:
		# O clique entra em pixels da janela (passa pela escala do conteúdo).
		var wp: Vector2 = get_viewport().get_final_transform() * (hud.offer_click_points(up_k)[0] as Vector2)
		for down in [true, false]:
			var mb := InputEventMouseButton.new()
			mb.button_index = MOUSE_BUTTON_LEFT
			mb.pressed = down
			mb.position = wp
			mb.global_position = wp
			Input.parse_input_event(mb)
		for _f in 3:
			await get_tree().process_frame
		var in_pick: bool = sim.offers[0]["source"] == "shop_pick"
		_ui_shot("shop_pick")
		var g := sim.gold
		await _key(KEY_DOWN)
		await _key(KEY_ENTER)
		picked = in_pick and sim.offers.size() > 0 and sim.offers[0]["source"] == "shop" and sim.gold < g
	print("uitest clique em Subir nível abre o baralho e Enter confirma: ", picked)
	ok = ok and picked
	await get_tree().process_frame
	_ui_shot("shop_after")
	await _key(KEY_0)
	print("uitest 0 sai da loja: ", sim.offers.is_empty())
	ok = ok and sim.offers.is_empty()
	return ok


func _ui_shot(tag: String) -> void:
	if auto_args.has("spacetest"):
		_space_scan("hand_" + tag)
	if auto_args.has("out") and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(str(auto_args["out"]) + "uitest_%s.png" % tag)


func _click(c: Control) -> void:
	# Pele Diário: a tela do menu sobe da mesa animada; o clique espera ela parar (até 1,5 s).
	var wait := 0.0
	while menu.visible and (menu.fade < 1.0 or menu.prev_fade < 1.0) and wait < 1.5:
		await get_tree().process_frame
		wait += get_process_delta_time()
	if c == null:
		return
	# O clique entra em pixels da janela: passa pela escala do conteúdo (como no --routetest) e pela escala e
	# giro do próprio Control (as telas do Diário encolhem para caber e ficam levemente tortas).
	var p := get_viewport().get_final_transform() * (c.get_global_transform() * (c.size * 0.5))
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


## Escolha de vilão sem cliques: trocar o vilão em foco não pode mexer em Voltar, cartas nem na folha.
func _villain_layout_test() -> void:
	await get_tree().create_timer(0.5).timeout
	for vid in data.villain_ids:
		meta.unlock_villain(vid)
	menu.show_screen("decks")
	await get_tree().create_timer(2.5).timeout
	var back_b: Button = _button(menu.deck_screen, "UI_BACK")
	var first := []
	var ok := true
	for vid in data.villain_ids:
		menu._focus_villain(vid)
		await get_tree().create_timer(0.4).timeout
		var m := [back_b.global_position, back_b.size, menu.preview_row.global_position, menu.preview_row.size, menu.deck_screen.global_position, menu.deck_screen.size]
		print("villaintest ", vid, ": ", m)
		if first.is_empty():
			first = m
		elif m != first:
			ok = false
	_ui_shot("villains_last")
	print("villaintest resultado: ", "OK" if ok else "FALHOU")
	get_tree().quit()


## Esc e espera a tela anterior sair: durante a descida (0,3 s) ela ainda existe e pega o Esc seguinte.
func _esc() -> void:
	await _key(KEY_ESCAPE)
	await get_tree().create_timer(0.5).timeout


## Teste do menu com entrada real (frente G, 21/11/2026): Menu → Covil ⇄ Biblioteca → Escolher vilão (deck 19/19, vilão
## trancado, Editar deck) → run com mods e deck → pausa (poderes, Desistir) → salvar e continuar → fim da run → Covil.
func _menu_test() -> void:
	var fails: Array = []   # lambdas capturam por valor: um bool não voltaria daqui
	SaveGame.erase()   # o arquivo de teste; a run salva do jogador fica em outro
	var had_save := SaveGame.exists()
	await get_tree().create_timer(0.5).timeout
	var step := func(name: String, cond: bool):
		print("menutest ", name, ": ", cond)
		if not cond:
			fails.append(name)
	var mm := menu.title_root as MapMenu
	if mm == null:
		get_tree().quit(1)
		return
	# Menu → Covil.
	await _click(mm.buttons["covil"])
	step.call("o lugar Covil abre a roda", menu.screen == "covil")
	await get_tree().create_timer(0.6).timeout
	_ui_shot("menu_covil")
	# Covil → Biblioteca (Esc volta ao Covil).
	await _click(_button(menu.covil, tr("UI_COVIL_LIBRARY")))
	step.call("Biblioteca abre a partir do Covil", menu.screen == "collection" and menu.lib_return == "covil")
	await get_tree().create_timer(0.4).timeout
	await _esc()
	step.call("Esc da Biblioteca volta ao Covil", menu.screen == "covil")
	# Comprar e reembolsar na árvore gravam em disco (e a meta aplicada à run vem de MetaApply.run_mods).
	var almas_keep := meta.almas
	var upg_keep: Dictionary = meta.upgrades.duplicate()
	meta.upgrades = {}
	meta.almas = 100000
	var buy_id := ""
	for nid in data.meta_nodes:
		if str(data.meta_nodes[nid].get("parent", "")) == "" and menu.covil.view.can_buy(nid):
			buy_id = nid
			break
	step.call("há um nó raiz comprável na árvore", buy_id != "" and meta.buyable_count() > 0)
	if buy_id != "":
		menu.covil.view.buy_node(buy_id)
		step.call("comprar grava o nível no save", MetaSave.load_or_new(data, meta.file).node_level(buy_id) == 1)
		menu.covil.view.refund_node(buy_id)
		step.call("reembolsar grava o nível no save", MetaSave.load_or_new(data, meta.file).node_level(buy_id) == 0 and meta.almas == 100000)
	meta.upgrades = upg_keep
	meta.almas = almas_keep
	meta.save()
	# Covil → Começar run → Escolher vilão: deck 19/19, vilão trancado "derrote a party N".
	await _click(_button(menu.covil, tr("UI_COVIL_START")))
	step.call("Começar run abre a escolha de vilão", menu.screen == "decks")
	await get_tree().create_timer(1.2).timeout
	_ui_shot("menu_decks")
	step.call("o deck da escolha tem 19 cartas", menu.preview_row.get_child_count() == 19)
	menu._focus_villain("dragon")
	step.call("vilão trancado: Começar desligado e texto da party", menu.v_pick.disabled and menu.v_pick.text == tr("UI_MENU_LOCKED").format({"n": 3}))
	menu._focus_villain("plague")
	step.call("vilão liberado: Começar ligado", not menu.v_pick.disabled)
	# Clicar no vilão só seleciona; a run começa no botão Começar.
	await _click(menu.v_tabs["plague"])
	step.call("clicar no vilão só seleciona (a run não começa)", menu.screen == "decks" and not running and menu.pending_villain == "plague" and menu.v_focus == "plague")
	# Editar deck abre a Biblioteca naquele vilão; Esc volta à escolha.
	await _click(_button(menu, "UI_MENU_EDIT_DECK"))
	step.call("Editar deck abre a Biblioteca no vilão", menu.screen == "collection" and menu.collection.tab == "plague" and menu.collection.deck_vid == "plague")
	await get_tree().create_timer(0.4).timeout
	await _esc()
	step.call("Esc da Biblioteca volta à escolha de vilão", menu.screen == "decks")
	await _esc()
	step.call("Esc da escolha volta ao Covil", menu.screen == "covil")
	await _esc()
	step.call("Esc do Covil volta ao título", menu.screen == "title")
	# Lugares do mapa: Biblioteca e Compêndio.
	await _click(mm.buttons["collection"])
	step.call("Biblioteca abre pelo menu", menu.screen == "collection" and menu.lib_return == "title")
	await _esc()
	step.call("Esc da Biblioteca volta ao título", menu.screen == "title")
	await _click(mm.buttons["compendium"])
	for _f in 4:
		await get_tree().process_frame
	step.call("Compêndio abre", menu.screen == "compendium")
	await _click(_button(menu.compendium, "UI_MENU_COMP_POWERS"))
	step.call("aba Poderes do Compêndio lista os poderes", menu.compendium.tab == "hero" and menu.compendium.body.get_child_count() >= data.power_ids.size())
	await _esc()
	step.call("Esc do Compêndio volta ao título", menu.screen == "title")
	# Começar a run: deck montado e mods da meta no Sim.
	meta.card_levels["rat_horde"] = 3
	meta.upgrades = {}
	await _click(mm.buttons["covil"])
	await _click(_button(menu.covil, tr("UI_COVIL_START")))
	await get_tree().create_timer(0.8).timeout
	await _click(menu.v_pick)
	step.call("Começar a run do vilão", running and sim != null and sim.deck_id == "plague" and sim.campaign_phase == 1 and not menu.visible)
	step.call("a run leva o deck de 19 e os mods da meta", sim.cards.size() == 19 and sim.mods["deck"].size() == 19 and int(sim.mods["card_levels"].get("rat_horde", 1)) == 3)
	await get_tree().create_timer(0.3).timeout
	await _esc()
	step.call("Esc pausa", paused and hud.pause_layer.visible)
	step.call("a pausa tem Poderes da party e Desistir", pause_powers_box != null and _button(hud, "UI_MENU_GIVE_UP") != null)
	sim.powers.append({"id": "fire_burst", "level": 1, "cd_left": 0.0, "gap_left": 0.0})
	_fill_pause_extras()
	step.call("a pausa lista o poder da party", pause_powers_box.get_child_count() == 2)
	_ui_shot("menu_pause")
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
	await _esc()
	step.call("Esc fecha as configurações e mantém a pausa", not hud.settings.visible and paused and hud.pause_layer.visible)
	# Salvar e voltar → Continuar retoma a run com os mesmos mods.
	if not had_save:
		await _click(_button(hud, "UI_SAVE_MENU"))
		step.call("Salvar e voltar ao menu", not running and menu.visible and SaveGame.exists())
		await _click(_button(menu, "UI_CONTINUE"))
		step.call("Continuar retoma a run", running and sim != null and sim.deck_id == "plague")
		step.call("a run retomada guarda os mods", sim != null and int(sim.mods["card_levels"].get("rat_horde", 1)) == 3 and sim.mods["deck"].size() == 19)
		SaveGame.erase()
	# Desistir: a run acaba como derrota, as Almas entram e a tela de fim aparece.
	var runs0 := meta.runs
	await get_tree().create_timer(0.3).timeout
	await _esc()
	await _click(_button(hud, "UI_MENU_GIVE_UP"))
	await _click(_button(hud, "UI_MENU_GIVE_UP_YES"))
	for _f in 6:
		await get_tree().process_frame
	step.call("Desistir termina a run como derrota", sim.phase == K.Phase.OVER and sim.result == K.Result.LOSS)
	step.call("a tela de fim da run aparece e o painel antigo some", run_end.visible and not hud.result_layer.visible and meta.runs == runs0 + 1)
	_ui_shot("menu_end")
	await get_tree().create_timer(1.0).timeout
	await _click(_button(run_end, "UI_END_MENU"))
	step.call("o fim da run volta ao menu principal, não ao Covil", not running and menu.visible and menu.screen in ["title", "covil"] and not run_end.visible)
	# Com Almas para gastar, a contagem termina abrindo a árvore do Covil: espera e volta ao mapa.
	await get_tree().create_timer(4.0).timeout
	if menu.screen == "covil":
		await _esc()
	# Tutorial pelo menu.
	await _click(mm.buttons["tutorial"])
	step.call("Tutorial começa a fase 0", running and sim != null and sim.campaign_phase == 0 and not menu.visible)
	SaveGame.erase()
	print("menutest resultado: ", "OK" if fails.is_empty() else "FALHOU " + str(fails))
	get_tree().quit(0 if fails.is_empty() else 1)


## --gshots=1 --out=pasta/: capturas da frente G com uma meta de teste: menu, covil, escolher vilão, pausa
## com poderes e fim da run. Só usa o meta de teste (user://test_meta.save); nada do jogador é tocado.
func _g_shots() -> void:
	meta.almas = 138
	meta.almas_earned = 138
	meta.best_party = 5
	meta.best_by_villain = {"plague": 5}
	meta.act2_reached = true
	meta.card_levels = {"rat_horde": 3, "rat_king": 2}
	await get_tree().create_timer(1.0).timeout
	menu.show_screen("title")
	await get_tree().create_timer(1.5).timeout
	_ui_shot("g_menu")
	menu.show_screen("covil")
	await get_tree().create_timer(1.2).timeout
	_ui_shot("g_covil")
	menu.decks_back = "covil"
	menu.show_screen("decks")
	await get_tree().create_timer(2.2).timeout
	_ui_shot("g_villain")
	menu._focus_villain("dragon")
	await get_tree().create_timer(0.8).timeout
	_ui_shot("g_villain_locked")
	_start("plague")
	await get_tree().create_timer(1.0).timeout
	for pw in [["fire_burst", 2], ["spell_ward", 1], ["slay_next", 1], ["ally_rat", 3]]:
		sim.powers.append({"id": pw[0], "level": pw[1], "cd_left": 0.0, "gap_left": 0.0})
	_toggle_pause()
	await get_tree().create_timer(0.8).timeout
	_ui_shot("g_pause")
	_toggle_pause()
	sim.cur_party = 6
	sim.stats["almas_dmg"] = 5400.0
	sim.stats["heroes_fallen"] = 9
	_give_up()
	await get_tree().create_timer(1.6).timeout
	_ui_shot("g_end_reveal")
	if is_instance_valid(run_end.reveal):
		var rv: UnlockReveal = run_end.reveal
		rv.finished.emit()
		rv.queue_free()
	await get_tree().create_timer(1.0).timeout
	_ui_shot("g_end")
	print("gshots ok")
	get_tree().quit(0)


## --mapicons=1: desenha no traço Nórdico (CampaignArt) os ícones das construções do menu, da
## loja e do fim da run e salva em assets/ui/map/ como PNG (icon_<s>.png, node_<s>.png e node_<s>_hot.png, com o
## anel do lugar); o jogo prefere o PNG ao SVG antigo (CampaignArt.map_tex).
func _map_icons() -> void:
	await get_tree().create_timer(0.3).timeout
	var jobs := [["m-lair", "lair"], ["m-library", "hall"], ["m-tower", "tower"], ["m-mill", "mill"], ["m-boat", "boat"],
		["m-tent", "tent"], ["m-house", "house"]]
	for j in jobs:
		for mode in ["icon", "node", "node_hot"]:
			var vp := SubViewport.new()
			vp.disable_3d = true
			vp.transparent_bg = true
			vp.size = Vector2i(256, 256) if mode == "icon" else Vector2i(240, 240)
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			var cv := Node2D.new()
			var kind: String = j[1]
			var m: String = mode
			cv.draw.connect(func():
				var a := CampaignArt.drawer(cv)
				if m == "icon":
					a.icon(kind, Transform2D.IDENTITY, Vector2(128, 136), 2.85, 7)
					return
				var hot := m == "node_hot"
				cv.draw_circle(Vector2(120, 120), 112.0, Color("e8d6a8"))
				cv.draw_arc(Vector2(120, 120), 112.0, 0.0, TAU, 96, Color("a8323a") if hot else CampaignArt.INK, 10.0 if hot else 8.0, true)
				cv.draw_arc(Vector2(120, 120), 94.0, 0.0, TAU, 96, CampaignArt.INK, 4.0, true)
				a.icon(kind, Transform2D.IDENTITY, Vector2(120, 124), 2.05, 7))
			vp.add_child(cv)
			add_child(vp)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var name_ := ("icon_%s.png" if mode == "icon" else ("node_%s_hot.png" if mode == "node_hot" else "node_%s.png")) % j[0]
			vp.get_texture().get_image().save_png("res://assets/ui/map/" + name_)
			if auto_args.has("out"):
				vp.get_texture().get_image().save_png(str(auto_args["out"]) + name_)
			vp.queue_free()
	print("mapicons ok")
	get_tree().quit(0)


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
	if not bg_mode:
		get_viewport().warp_mouse(get_viewport().get_visible_rect().size * Vector2(0.5, 0.35))
	await get_tree().create_timer(0.6).timeout
	# Armadura Ignífuga: caixas "Armadura" e "Fogo"; o texto do Fogo cita Encharcado, que ainda não tem caixa.
	sim.hero.apply_upgrade("fireproof")
	await get_tree().create_timer(0.3).timeout
	var icons := hud.upg_row.find_children("*", "UpgradeIcon", false, false)
	step.call("Habilidade nova aparece na HUD com aviso", icons.size() == 1 and hud.learn_panel.visible)
	_ui_shot("tip_learn")
	if icons.is_empty():
		print("tiptest resultado: FALHOU ", fails, " (sem ícone de habilidade; passos seguintes pulados)")
		get_tree().quit(1)
		return
	# Mouse no ícone: abre a caixa e o jogo continua. Se o cursor físico segurar outro controle, tenta de novo.
	var t0 := sim.t
	for attempt in 3:
		await _hover((icons[0] as Control).get_global_rect().get_center())
		if bg_mode:
			# Janela fora da tela e sem foco: o Godot não entrega mouse_entered ao evento sintético; avisa o controle
			# na mão (o resto do teste, as caixas e as palavras, usa Tips.mouse_override e roda de verdade).
			(icons[0] as Control).mouse_entered.emit()
		await get_tree().create_timer(0.2).timeout
		t0 = sim.t
		await get_tree().create_timer(0.3).timeout
		if Tips.reading() and str(Tips.inst.levels[0]["owner"]).begins_with("obj:"):
			break
		await _hover(get_viewport().get_visible_rect().size * Vector2(0.5, 0.35), 2)
		await get_tree().create_timer(0.5).timeout
	var icon_open: bool = Tips.reading() and str(Tips.inst.levels[0]["owner"]).begins_with("obj:")
	step.call("Mouse no ícone abre a caixa", icon_open)
	if not icon_open:
		# Sem a caixa aberta não há o que varrer: os passos seguintes dependem dela e travavam com índice fora do array.
		print("tiptest resultado: FALHOU ", fails, " (caixa do ícone não abriu; passos seguintes pulados)")
		get_tree().quit(1)
		return
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
	# As caixas da carta são só de leitura: não pegam o mouse (o mundo e as outras cartas continuam clicáveis).
	var grabs := false
	if Tips.reading():
		for b in Tips.inst.levels[0]["boxes"]:
			grabs = grabs or (b as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE
	step.call("Caixas da carta não bloqueiam o mouse", Tips.reading() and not grabs)
	# Ir para a carta vizinha: as caixas da anterior somem junto com ela (sem a espera de 0,4 s).
	var uid0: String = Tips.inst.levels[0]["owner"] if Tips.reading() else ""
	var c1 := hud.fan.card_rect(1).get_center()
	hud.fan.mouse_override = c1 - hud.fan.global_position
	await _hover(c1, 3)
	step.call("Caixas somem junto com a carta", not Tips.is_open(uid0) and hud.fan.hover == 1)
	# Mapa grande aberto por cima da mão: o mouse sobre as cartas (atrás do mapa) não acende nenhuma.
	hud.fan.mouse_override = null
	Tips.close_all()
	_toggle_map()
	await get_tree().process_frame
	await _hover(c0, 4)
	await get_tree().create_timer(0.8).timeout
	step.call("Mapa aberto: cartas atrás dele não reagem ao mouse", hud.minimap.visible and hud.fan.hover < 0 and not Tips.reading())
	_toggle_map()
	await get_tree().process_frame
	# A Godot só recalcula o controle sob o mouse no próximo movimento: mexe e espera assentar.
	await _hover(c0 + Vector2(4, 0), 2)
	await _hover(c0, 4)
	await get_tree().create_timer(0.2).timeout
	step.call("Mapa fechado: a carta volta a reagir", hud.fan.hover == 0)
	hud.fan.mouse_override = null
	# Duas cartas lado a lado com attach: a caixa da esquerda não cobre nem segura a da direita.
	Tips.close_all()
	var pair: Array = []
	for k in 2:
		var pc := PanelContainer.new()
		pc.custom_minimum_size = Vector2(130, 180)
		pc.size = Vector2(130, 180)
		pc.position = Vector2(500 + k * 150, 520)
		pc.mouse_filter = Control.MOUSE_FILTER_STOP
		var tag := "Carta %d" % k
		Tips.attach(pc, func(): return Tips.text_entries(tag, "Texto com [[fire]] e [[slow]] para a caixa."))
		hud.add_child(pc)
		pair.append(pc)
	await _hover(Vector2(300, 100), 3)
	var pl := (pair[0] as Control).get_global_rect().get_center()
	var pr := (pair[1] as Control).get_global_rect().get_center()
	await _hover(pl, 3)
	await get_tree().create_timer(0.3).timeout
	var left_id := "obj:%d" % (pair[0] as Control).get_instance_id()
	step.call("Par de cartas: mouse na esquerda abre a caixa", Tips.reading() and Tips.inst.levels[0]["owner"] == left_id)
	var covers := false
	if Tips.reading():
		for b in Tips.inst.levels[0]["boxes"]:
			covers = covers or (b as Control).get_global_rect().intersects((pair[1] as Control).get_global_rect())
	step.call("Par de cartas: a caixa não cobre a carta vizinha", Tips.reading() and not covers)
	# Mouse vai para a direita passando por cima da caixa: a caixa passa a ser a da carta da direita em < 1 s.
	if Tips.reading():
		await _hover((Tips.inst.levels[0]["col"] as Control).get_global_rect().position + Vector2(12, 8), 2)
	await _hover(pr, 3)
	await get_tree().create_timer(0.15).timeout
	var right_id := "obj:%d" % (pair[1] as Control).get_instance_id()
	step.call("Par de cartas: passa a caixa da carta da direita", Tips.reading() and Tips.inst.levels[0]["owner"] == right_id)
	# Mouse fora das cartas e sobre a caixa (fora de palavra): fecha mesmo assim.
	await _hover(pl, 3)
	await get_tree().create_timer(0.2).timeout
	if Tips.reading():
		await _hover((Tips.inst.levels[0]["col"] as Control).get_global_rect().position + Vector2(12, 8), 2)
	await get_tree().create_timer(0.8).timeout
	step.call("Caixa fecha com o mouse sobre ela fora da âncora", not Tips.reading())
	for pc in pair:
		pc.queue_free()
	Tips.mouse_override = null
	print("tiptest resultado: ", "OK" if fails.is_empty() else "FALHOU " + str(fails))
	get_tree().quit(0 if fails.is_empty() else 1)


## Move o mouse (evento real) e fixa a posição que as caixas leem. O RichTextLabel acha a palavra sob o cursor
## pela posição real do mouse, não pela do evento: por isso também move o cursor de verdade.
func _hover(p: Vector2, frames := 3) -> void:
	Tips.mouse_override = p
	if not bg_mode:
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
	if ci == null or sim.phase == K.Phase.OVER or not sim.offers.is_empty():
		world.show_placement(false, Vector3.ZERO, true, 1.0)
		status_ov.set_preview(null, Vector3.ZERO)
		_mark_target(null, Vector3.ZERO)
		return
	var p := _ground_point(_pointer())
	status_ov.set_preview(ci if _on_ground(_pointer()) else null, p)
	var d := ci.def
	var r: float = d.fx.get("radius", 1.0)
	world.show_placement(d.category == "field" or d.category == "lair" or d.id == "gold_bait", p, _on_ground(_pointer()) and sim.valid_target(ci, p.x, p.z), r)
	_mark_target(ci if _on_ground(_pointer()) else null, p)


## Mira de alvo único (feitiço de status/maldição/dano em "hero"/"nearest") e de monstro: o herói que vai receber.
func _single_target(d: CardDef) -> bool:
	if d.category != "field":
		return false
	if not d.is_spell:
		return d.type == "monster" or d.type == "swarm"
	for o in d.ops:
		var t := str(o.get("target", "hero" if str(o.get("op", "")) in ["status", "curse"] else "area"))
		if t == "hero" or t == "nearest":
			return true
	return false


func _mark_target(ci: Sim.CardInst, p: Vector3) -> void:
	if ci == null or not _single_target(ci.def):
		if target_mark:
			target_mark.visible = false
		return
	var h: SimHero = sim.hero
	if sim.has_method("hero_nearest"):
		var hn = sim.hero_nearest(Vector2(p.x, p.z))
		if hn != null:
			h = hn
	if target_mark == null:
		target_mark = world._circle(1.3, Color(1.0, 0.85, 0.2, 1.0), 0.09, 1.4)
		world.add_child(target_mark)
	target_mark.visible = true
	target_mark.position = Vector3(h.x, 0.08 + world.surface_y(h.x, h.y), h.y)


# ---------------------------------------------------------------- comandos

func _select(i: int) -> void:
	if sim == null or sim.phase == K.Phase.OVER:
		return
	var ci := sim.hand_card(i)
	if ci == null:
		return
	hud.selected = -1 if hud.selected == i else i
	# O Incêndio mira um local da rota: o mapa grande abre junto (a Isca de Ouro vai no mundo, perto do herói).
	if (hud.selected >= 0 and ci.def.id == "burn_village") != hud.minimap.visible and not sim.route_wait:
		_toggle_map()
	# Finalização sai na hora; Temporário (covil) segue o fluxo dos feitiços: mira e solta em qualquer ponto do chão.
	if hud.selected >= 0 and ci.def.category == "finisher":
		_play_at(Vector2(sim.hero.x, sim.hero.y))


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
	# O nó para onde o herói já vai só é clicável no mapa para o Incêndio: sem carta, não mexe no plano.
	if sim == null or hud.selected >= 0 or n < 0 or sim.offers.size() > 0 or n == sim.road.head:
		return
	if sim.choose_route(n):
		audio.play("card_play", 0.0)
		_close_auto_map()
		if map_after_open and hud.minimap.visible:
			_toggle_map()   # mapa do fim do local: replanejou, segue


## Opção k da bifurcação em que o herói espera (da esquerda para a direita).
func _route_option(k: int) -> bool:
	if not sim.route_wait:
		return false
	var outs: Array = sim.road.nodes[sim.road.head]["out"]
	if k < 0 or k >= outs.size():
		return false
	_route_click(sim.road.legs[outs[k]]["b"])
	return true


## Cenas (queda do herói, local): a HUD segura a oferta e esmaece as cartas; os selos dos marcos leem a cena.
## Na cena do local o mundo segue em câmera lenta mesmo com a recompensa já pronta na simulação (sem isso ele
## congelaria assim que a oferta entra); sem cena, a oferta pausa a simulação como sempre.
func _scene_gates() -> void:
	hud.hold_offers = world.cine_active()
	sim.pause_on_offer = world.scene.is_empty() or sim.offers.is_empty()
	hud.seals.show_scene(world.scene)


## Depois de todo local (15/11/2026), o mapa grande abre quando a cena e as recompensas acabam e o jogo espera:
## numa bifurcação ele já abre sozinho (escolha obrigatória); com uma bifurcação ainda por decidir à frente, o
## jogador olha e fecha. Desde 17/11/2026 só a bifurcação onde o herói espera abre o mapa; sem escolha o jogo segue direto.
func _map_after_location(delta: float) -> void:
	if not world.scene.is_empty():
		map_after = true
		map_after_t = 0.0
		return
	if not map_after or world.cine_active() or not sim.offers.is_empty() or sim.act_pending:
		map_after_t = 0.0
		return
	if sim.phase != K.Phase.ROAD or hud.minimap.visible or sim.route_wait or sim.road.complete:
		map_after = false   # fora da estrada, mapa já aberto, ou a bifurcação abre o dela
		return
	# 17/11/2026 (2ª correção): head é o fim da rota já decidida, que pode ser a bifurcação logo DEPOIS do próximo
	# ponto; o jogador não tem o que escolher agora. Só a bifurcação onde o herói espera (route_wait) abre o mapa,
	# e isso é feito em _process. Depois do evento sem escolha o jogo segue direto.
	map_after = false


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
	if world and world.cine_active() and not (e is InputEventMouseMotion):
		# Cena do local: depois de 1 s, clique, espaço ou A do controle pulam para a recompensa (e o evento
		# morre aqui, sem escolher nada nem pausar).
		var skip_ev: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
			or (e is InputEventKey and e.pressed and not e.echo and (e.keycode == KEY_SPACE or e.keycode == KEY_ENTER)) \
			or e.is_action_pressed("pad_confirm")
		if skip_ev and world.scene_skippable():
			world.skip_scene()
			hud.banner.t = -1.0   # o letreiro do resultado não fica por trás da recompensa
			hud.banner.visible = false
			_scene_gates()
			get_viewport().set_input_as_handled()
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
			world.zoom = clampf(world.zoom - 2.0, world.ZOOM_START, 20.0)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			world.zoom = clampf(world.zoom + 2.0, world.ZOOM_START, 20.0)
	if e is InputEventKey and e.pressed and not e.echo:
		var kc: int = e.keycode
		if paused and kc != KEY_ESCAPE and kc != KEY_SPACE:
			return
		if kc >= KEY_1 and kc <= KEY_9:
			var n := kc - KEY_1
			if sim.offers.size() > 0:
				hud.choose_offer(n)
			elif not _route_option(n):
				_select(n)
		if kc == KEY_0 and sim.offers.size() > 0:
			hud.choose_offer(Sim.SKIP)
		match kc:
			KEY_ESCAPE:
				if paused and hud.back():
					pass
				elif not paused and hud.minimap.visible and not sim.route_wait:
					# Esc fecha o mapa (e solta a carta que o abriu, como o Incêndio).
					hud.selected = -1
					_toggle_map()
				elif not paused and hud.selected >= 0:
					hud.selected = -1
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
	_pad_input(e)


func _toggle_pause() -> void:
	if sim == null or sim.phase == K.Phase.OVER:
		return
	paused = not paused
	hud.show_pause(paused)
	if paused:
		_fill_pause_extras()


## Pausa (frente G, 21/11/2026): "Desistir" no fim do menu (mantém as Almas: a run acaba como derrota e passa por
## MetaSave.apply_run) e "Poderes da party" no painel da direita (Sim.party_powers com nome e efeito de HeroPowers).
func _build_pause_extras() -> void:
	var gu := Button.new()
	gu.text = "UI_MENU_GIVE_UP"
	gu.alignment = HORIZONTAL_ALIGNMENT_LEFT
	gu.custom_minimum_size = Vector2(320, 54)
	gu.add_theme_font_size_override("font_size", 22)
	gu.mouse_entered.connect(func(): gu.grab_focus())
	hud.pause_menu.add_child(gu)
	give_up_row = HBoxContainer.new()
	give_up_row.visible = false
	give_up_row.add_theme_constant_override("separation", 8)
	var ask := UiKit.label(16, UiKit.MUTED, 3)
	ask.text = "UI_MENU_GIVE_UP_ASK"
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.custom_minimum_size = Vector2(320, 0)
	ask.name = "Ask"
	var confirm := VBoxContainer.new()
	confirm.name = "GiveUpBox"
	confirm.visible = false
	confirm.add_theme_constant_override("separation", 6)
	confirm.add_child(ask)
	give_up_row.add_theme_constant_override("separation", 8)
	var yes := Button.new()
	yes.text = "UI_MENU_GIVE_UP_YES"
	yes.custom_minimum_size = Vector2(150, 46)
	yes.pressed.connect(_give_up)
	var no := Button.new()
	no.text = "UI_MENU_GIVE_UP_NO"
	no.custom_minimum_size = Vector2(160, 46)
	no.pressed.connect(func(): confirm.visible = false)
	give_up_row.visible = true
	give_up_row.add_child(yes)
	give_up_row.add_child(no)
	confirm.add_child(give_up_row)
	hud.pause_menu.add_child(confirm)
	gu.pressed.connect(func(): confirm.visible = not confirm.visible)
	# Poderes da party: dentro do painel de baralho e habilidades da pausa.
	var iv: Control = hud.pause_build.get_parent()
	# As habilidades do herói saíram do jogo (21/11/2026): o bloco antigo some, os poderes ocupam o lugar.
	hud.pause_build.visible = false
	for c in iv.get_children():
		if c is Label and (c as Label).text == "UI_HERO_BUILD":
			c.visible = false
	var head := UiKit.title(26)
	head.text = "UI_MENU_PAUSE_POWERS"
	iv.add_child(head)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 150)
	iv.add_child(sc)
	pause_powers_box = VBoxContainer.new()
	pause_powers_box.add_theme_constant_override("separation", 6)
	pause_powers_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(pause_powers_box)


func _fill_pause_extras() -> void:
	var gub := hud.pause_menu.get_node_or_null("GiveUpBox")
	if gub:
		gub.visible = false
	UiKit.clear(pause_powers_box)
	var list: Array = sim.party_powers()
	if list.is_empty():
		var none := UiKit.label(15, UiKit.MUTED, 3)
		none.text = tr("UI_MENU_PAUSE_NO_POWERS")
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.custom_minimum_size = Vector2(380, 0)
		pause_powers_box.add_child(none)
		return
	for p in list:
		var info: Dictionary = HeroPowers.describe(sim, str(p["id"]), int(p["level"]))
		if info.is_empty():
			continue
		var name_l := UiKit.label(16, UiKit.GOLD, 3)
		name_l.text = tr("UI_MENU_POWER_LINE").format({"name": info["name"], "lv": info["level"], "cd": int(round(float(info["cooldown"])))})
		pause_powers_box.add_child(name_l)
		var d := UiKit.label(14, Color(0.9, 0.88, 1.0), 3)
		d.text = str(info["desc"])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(400, 0)
		pause_powers_box.add_child(d)


## "Desistir": a run acaba como derrota (o laço principal chama apply_run: as Almas ganhas ficam).
func _give_up() -> void:
	if sim == null or sim.phase == K.Phase.OVER:
		return
	paused = false
	hud.show_pause(false)
	sim._finish(K.Result.LOSS)


## Mapa grande da rota (M, Select ou ao escolher uma carta de rota). No dia a dia, a faixa de rota na borda esquerda.
func _toggle_map() -> void:
	var mm := hud.minimap
	if sim.phase != K.Phase.ROAD and not mm.visible:
		return
	mm.visible = not mm.visible
	if mm.visible:
		mm.setup(sim)
	else:
		map_after_open = false


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
		# Pela Hud: na loja o livro-caixa confere o ouro e mantém o cursor (hud.selected) na página.
		if e.is_action_pressed("pad_confirm"):
			hud.choose_offer(maxi(hud.selected, 0), true)
		elif e.is_action_pressed("pad_back"):
			hud.choose_offer(Sim.SKIP, true)
		return
	if e.is_action_pressed("pad_prev") or e.is_action_pressed("pad_next"):
		var d := -1 if e.is_action_pressed("pad_prev") else 1
		hud.selected = wrapi(hud.selected + d, 0, sim.hand.size())
	if e.is_action_pressed("pad_confirm"):
		if hud.selected >= 0:
			var ci := sim.hand_card(hud.selected)
			if ci and ci.def.category == "finisher":
				_play_at(Vector2(sim.hero.x, sim.hero.y))
			else:
				_click_world(cursor)
	if e.is_action_pressed("pad_back"):
		hud.selected = -1   # B solta a carta (segurar B sacrificava até 11/11/2026)
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

## --bare (só capturas para maquetes de UI): esconde a interface e deixa o mundo e as cartas
## (mão, ofertas, loja). Quem contém uma carta fica, mas sem desenhar o próprio fundo (self_modulate transparente).
func _bare_ui() -> void:
	var keep := {}
	for n in get_tree().root.find_children("*", "Control", true, false):
		if n.has_meta("ui_card") or n is HandFan:
			var p: Node = n
			while p:
				keep[p] = true
				p = p.get_parent()
	for n in get_tree().root.find_children("*", "Control", true, false):
		var c := n as Control
		if keep.has(c):
			if not (c.has_meta("ui_card") or c is HandFan):
				c.self_modulate.a = 0.0
			continue
		var inside := false
		var p2: Node = c.get_parent()
		while p2:
			if p2 is HandFan or p2.has_meta("ui_card"):
				inside = true
				break
			p2 = p2.get_parent()
		if not inside:
			c.visible = false
