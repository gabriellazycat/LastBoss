class_name Hud
extends Control
## Interface da run. Lê o Sim; ações do jogador viram comandos via sinais.
## Hierarquia: o herói (a ameaça) no centro do topo → faixa de rota logo abaixo → objetivo à esquerda → corpo do chefe
## (na arena) à direita → esteira do ciclo, mão em leque e elixir embaixo.

signal card_pressed(i: int)
signal card_sacrificed(i: int)
signal offer_chosen(k: int)
signal minimap_clicked(pos: Vector2)
signal route_clicked(node: int)
signal card_dropped(i: int, screen_pos: Vector2)
signal resume
signal to_menu(decks: bool)
signal quit_game
signal speed_pressed
signal map_pressed
signal settings_changed(key: String)

var sim: Sim
var selected := -1
var speed := 1.0
# Topo: herói × você.
var duel: HBoxContainer
var hero_badge: PanelContainer
var hero_hp: ProgressBar
var hero_hp_label: Label
var hero_of_label: Label
var upg_row: HBoxContainer         # ícones das habilidades do herói (mouse em cima explica)
var upg_none: Label
var upg_shown := 0
var learn_panel: PanelContainer    # aviso "o herói aprendeu" (some sozinho, não pausa)
var learn_t := 0.0
var upg_icons: Dictionary = {}       # habilidade -> ícone na HUD (recarga desenhada por cima)
var contest_panel: PanelContainer     # disputa do local em andamento (rodada 09/11/2026)
var contest_label: RichTextLabel
var contest_text := ""
var hold_offers := false             # cena da morte do herói: a recompensa e as cartas esperam
var banner: BigBanner                  # letreiro grande: objetivo do local, resultado, ato (rodada 09/11/2026)
var relic_row: HBoxContainer          # relíquias do covil ganhas na run
var curse_label: Label
# Esquerda: run e contrato.
var run_panel: PanelContainer
var time_label: Label
var road_label: Label
var road_bar: ProgressBar
var contract_panel: PanelContainer
var contract_name: Label
var contract_goal: RichTextLabel
var contract_text := ""
var contract_bar: ProgressBar
var contract_time: Label
# Faixa de rota (estrada) e mapa grande (M ou carta de rota).
var strip: RouteStrip
var minimap: Minimap
var parts_panel: PanelContainer
var parts_box: VBoxContainer
var part_rows: Array = []
var tele_label: Label
var tele_bar: ProgressBar
var tool_row: HBoxContainer
var speed_btn: Button
# Base: mão e elixir.
var bottom_box: VBoxContainer
var fan: HandFan
var pad := false
var elixir_bar: ElixirBar
var elixir_badge: PanelContainer
var elixir_tray: HBoxContainer
var sac_zone: Button
# Mensagens.
var info_label: Label
var help_label: Label
var toast: Label
var toast_t := 0.0
var hint_panel: PanelContainer
var hint_label: RichTextLabel
var hint_t := 0.0
var hints_seen: Dictionary = {}
# Sobreposições.
var offer_layer: Control
var offer_title: Label
var offer_box: VBoxContainer   # linhas (HBox) de cartas, dentro de offer_scroll
var offer_scroll: ScrollContainer
var offer_sub: Label
var offer_skip: Button
var offer_keys: Label
var gold_label: Label
var offer_sig := ""
var offer_slots: Array = []
var offer_rays: Juice.Rays             # raios de luz atrás da oferta (impacto, rodada 09/11/2026)
var offer_obj = null                   # oferta já animada (a mesma oferta reconstruída não anima de novo)
var sfx: Callable                      # som da interface: sfx.call(id, tom)
var souls_gained := 0
var pause_layer: Control
var pause_menu: VBoxContainer
var pause_deck: GridContainer
var pause_build: GridContainer
var pause_time: Label
var settings: SettingsPanel
var result_layer: Control
var result_title: Label
var result_sub: Label
var result_grid: GridContainer
var result_btn: Button
var result_shown := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.make_theme()
	_build_top()
	_build_left()
	_build_right()
	_build_bottom()
	_build_messages()
	_build_offer()
	_build_pause()
	_build_result()
	var cf := ConfigFile.new()
	if cf.load("user://hints.cfg") == OK:
		for k in cf.get_section_keys("seen") if cf.has_section("seen") else []:
			hints_seen[k] = true
	visible = false


func _build_top() -> void:
	duel = HBoxContainer.new()
	duel.add_theme_constant_override("separation", 14)
	duel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(duel)
	# Herói: a ameaça. Vida grande, XP fina (cada XP que ele ganha é culpa sua).
	var hp := UiKit.panel(UiKit.BG_SOFT, UiKit.HERO_HP.darkened(0.4), 8)
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 10)
	hp.add_child(hh)
	hero_badge = UiKit.badge(UiKit.HERO_XP, 22, 48, "crest")
	hero_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hh.add_child(hero_badge)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 3)
	hh.add_child(hv)
	var hname := HBoxContainer.new()
	var hn := UiKit.label(15, UiKit.HERO_XP.lightened(0.3), 3)
	hn.text = "UI_HERO"
	if UiSkins.covil():
		hn.add_theme_font_override("font", UiCovil.font("title"))
		hn.add_theme_font_size_override("font_size", 16)
	hname.add_child(hn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hname.add_child(sp)
	curse_label = UiKit.label(14, Color(0.75, 1.0, 0.55), 3)
	Tips.attach(curse_label, func(): return [Tips.kw_entry("curse")])
	hname.add_child(curse_label)
	hv.add_child(hname)
	hero_hp = UiKit.bar(UiKit.HERO_HP, 340, 22)
	hero_hp_label = UiKit.label(15, Color.WHITE, 3)
	hero_hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_hp.add_child(hero_hp_label)
	hv.add_child(hero_hp)
	hero_of_label = UiKit.label(13, UiKit.MUTED, 3)
	hv.add_child(hero_of_label)
	upg_row = HBoxContainer.new()
	upg_row.add_theme_constant_override("separation", 3)
	upg_row.custom_minimum_size = Vector2(340, 30)
	upg_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upg_none = UiKit.label(13, UiKit.MUTED, 3)
	upg_none.text = "UI_NO_BUILD"
	upg_none.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	upg_row.add_child(upg_none)
	hv.add_child(upg_row)
	duel.add_child(hp)


func _build_left() -> void:
	run_panel = UiKit.panel(UiKit.BG_SOFT, UiKit.EDGE.darkened(0.2), 10)
	if UiSkins.covil():
		# O tempo é texto solto sobre o mundo (sombra forte), não mais uma caixa entre tantas.
		run_panel.material = null
		var rs := StyleBoxEmpty.new()
		rs.set_content_margin_all(6)
		run_panel.add_theme_stylebox_override("panel", rs)
	run_panel.custom_minimum_size = Vector2(190 if UiSkins.covil() else (150 if UiSkins.diario() else 300), 0)
	run_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	run_panel.add_child(v)
	time_label = UiKit.title(28, UiKit.TEXT)
	v.add_child(time_label)
	road_label = UiKit.label(14, UiKit.MUTED, 3)
	v.add_child(road_label)
	road_bar = UiKit.bar(Color(0.8, 0.25, 0.9), 276, 8)
	v.add_child(road_bar)
	add_child(run_panel)
	contract_panel = UiKit.panel(Color(0.1, 0.06, 0.04, 0.85), UiKit.GOLD.darkened(0.25), 10)
	contract_panel.custom_minimum_size = Vector2(300, 0)
	contract_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 4)
	contract_panel.add_child(cv)
	var ch := HBoxContainer.new()
	contract_name = UiKit.label(17, UiKit.GOLD)
	contract_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contract_time = UiKit.label(17, UiKit.TEXT)
	ch.add_child(contract_name)
	ch.add_child(contract_time)
	cv.add_child(ch)
	contract_goal = Tips.label("", 15, Color(1, 0.92, 0.8), 276.0)
	cv.add_child(contract_goal)
	contract_bar = UiKit.bar(UiKit.GOLD, 276, 10)
	cv.add_child(contract_bar)
	add_child(contract_panel)


func _build_right() -> void:
	strip = RouteStrip.new()
	strip.world_clicked.connect(func(p): minimap_clicked.emit(p))
	strip.node_clicked.connect(func(n): route_clicked.emit(n))
	add_child(strip)
	minimap = Minimap.new()
	minimap.size = Vector2(620, 620)
	minimap.visible = false
	minimap.world_clicked.connect(func(p): minimap_clicked.emit(p))
	minimap.node_clicked.connect(func(n): route_clicked.emit(n))
	minimap.close_requested.connect(func(): map_pressed.emit())
	add_child(minimap)
	parts_panel = UiKit.panel(UiKit.BG_SOFT, UiKit.POWER.darkened(0.3), 12)
	parts_panel.custom_minimum_size = Vector2(290, 0)
	parts_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parts_box = VBoxContainer.new()
	parts_box.add_theme_constant_override("separation", 4)
	parts_panel.add_child(parts_box)
	parts_panel.visible = false
	add_child(parts_panel)
	tool_row = HBoxContainer.new()
	tool_row.add_theme_constant_override("separation", 6)
	add_child(tool_row)
	for spec in [["II", "UI_TIP_PAUSE", func(): resume.emit()], ["1x", "UI_TIP_SPEED", func(): speed_pressed.emit()], ["M", "UI_TIP_MAP", func(): map_pressed.emit()]]:
		var b := Button.new()
		b.text = spec[0]
		b.tooltip_text = spec[1]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(52, 44)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(spec[2])
		if UiSkins.diario() and spec[0] in ["II", "M"]:
			UiDiario.icon_button(b, "pause" if spec[0] == "II" else "map")
		elif UiSkins.covil() and spec[0] in ["II", "M"]:
			UiCovil.icon_button(b, "pause" if spec[0] == "II" else "map")
		tool_row.add_child(b)
		if spec[0] == "1x":
			speed_btn = b


func _build_bottom() -> void:
	bottom_box = VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 10)
	bottom_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_box)
	fan = HandFan.new()
	fan.card_pressed.connect(func(i): card_pressed.emit(i))
	fan.card_sacrificed.connect(func(i): card_sacrificed.emit(i))
	fan.card_dropped.connect(func(i, p): card_dropped.emit(i, p))
	bottom_box.add_child(fan)
	var eb := HBoxContainer.new()
	eb.alignment = BoxContainer.ALIGNMENT_CENTER
	if UiSkins.diario():
		eb.set_meta("paper", true)
		eb.draw.connect(func(): UiCovil.draw_plate(eb, "paper", Vector2(18, 10)))
		eb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	elif UiSkins.covil():
		# Bandeja de ferro atrás do sacrifício e do elixir: os frascos ficavam soltos sobre o mundo.
		eb.draw.connect(func(): UiCovil.draw_plate(eb, "soft", Vector2(14, 8)))
		eb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	eb.add_theme_constant_override("separation", 12)
	# A bandeja do elixir é sólida: o clique nela não pode cair no mundo atrás (rodada 09/11/2026).
	eb.mouse_filter = Control.MOUSE_FILTER_STOP
	elixir_tray = eb
	sac_zone = Button.new()
	sac_zone.text = "UI_SACRIFICE"
	sac_zone.tooltip_text = "UI_TIP_SACRIFICE"
	sac_zone.focus_mode = Control.FOCUS_NONE
	sac_zone.custom_minimum_size = Vector2(170, 44)
	sac_zone.add_theme_font_size_override("font_size", 15)
	sac_zone.add_theme_color_override("font_color", UiKit.BAD.lightened(0.3))
	if UiSkins.diario():
		sac_zone.set_meta("no_frame", true)
		sac_zone.material = UiDiario.material("tape", {"button": true, "tint": Color(0.66, 0.15, 0.1, 0.95), "shadow": 4.0, "seed": 0.4})
		for ck in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			sac_zone.add_theme_color_override(ck, Color(1.0, 0.95, 0.88))
	elif UiSkins.covil():
		# Botão de sacrifício: aro de bronze puxado para o vermelho (é o altar).
		sac_zone.material = UiCovil.material("button", UiCovil.BRONZE.lerp(UiKit.BAD, 0.5), Color(0.17, 0.1, 0.1, 0.97), Color(0.08, 0.04, 0.045, 0.97))
	sac_zone.pressed.connect(func():
		if selected >= 0:
			card_sacrificed.emit(selected))
	eb.add_child(sac_zone)
	elixir_bar = ElixirBar.new()
	elixir_bar.custom_minimum_size = Vector2(560, 22)
	elixir_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	elixir_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eb.add_child(elixir_bar)
	elixir_badge = UiKit.badge(UiKit.ELIXIR, 26, 52)
	eb.add_child(elixir_badge)
	# Ouro da run (lojas), ao lado do elixir.
	gold_label = UiKit.label(20, UiKit.GOLD, 4)
	gold_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gold_label.custom_minimum_size = Vector2(110, 0)
	gold_label.mouse_filter = Control.MOUSE_FILTER_STOP
	Tips.attach(gold_label, func(): return [Tips.kw_entry("gold")])
	eb.add_child(gold_label)
	bottom_box.add_child(eb)


func _build_messages() -> void:
	info_label = UiKit.label(13, UiKit.MUTED, 3)
	add_child(info_label)
	help_label = UiKit.label(13, Color(0.78, 0.76, 0.86), 3)
	if UiSkins.covil():
		var hs := StyleBoxFlat.new()
		hs.bg_color = Color(0.03, 0.02, 0.04, 0.72)
		hs.set_corner_radius_all(4)
		hs.content_margin_left = 10
		hs.content_margin_right = 10
		hs.content_margin_top = 2
		hs.content_margin_bottom = 3
		help_label.add_theme_stylebox_override("normal", hs)
		help_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.78))
	add_child(help_label)
	toast = UiKit.title(30, Color(1, 0.62, 0.45))
	if UiSkins.diario():
		toast.set_meta("no_ink", true)
		toast.add_theme_color_override("font_color", Color(1.0, 0.93, 0.84))
		toast.add_theme_constant_override("outline_size", 10)
		toast.add_theme_color_override("font_outline_color", Color(0.25, 0.04, 0.02))
	toast.custom_minimum_size = Vector2(900, 0)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.modulate.a = 0.0
	add_child(toast)
	hint_panel = UiKit.panel(Color(0.08, 0.05, 0.14, 0.94), UiKit.GOLD, 14)
	hint_panel.custom_minimum_size = Vector2(620, 0)
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label = Tips.label("", 17, Color(1, 0.95, 0.85), 590.0, true)
	hint_panel.add_child(hint_label)
	hint_panel.visible = false
	add_child(hint_panel)
	# Aviso de habilidade nova do herói: ícone, nome e o que faz. Não pausa; some em alguns segundos.
	learn_panel = UiKit.panel(Color(0.06, 0.04, 0.1, 0.95), UiKit.HERO_XP, 12)
	learn_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	learn_panel.visible = false
	add_child(learn_panel)
	# Disputa do local em andamento (rodada 09/11/2026): o que falta e quanto tempo resta.
	contest_panel = UiKit.panel(Color(0.08, 0.04, 0.06, 0.92), UiKit.GOLD, 10)
	contest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contest_label = Tips.label("", 17, Color(1, 0.93, 0.8), 560.0, true)
	contest_panel.add_child(contest_label)
	contest_panel.visible = false
	add_child(contest_panel)
	banner = BigBanner.new()
	add_child(banner)
	# Relíquias do covil ganhas na run, em fila no canto de baixo à direita.
	relic_row = HBoxContainer.new()
	relic_row.add_theme_constant_override("separation", 6)
	relic_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(relic_row)


func _dim() -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(0.02, 0.01, 0.04, 0.7)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	return d


func _build_offer() -> void:
	offer_layer = _dim()
	offer_rays = Juice.Rays.new()
	offer_rays.set_anchors_preset(Control.PRESET_FULL_RECT)
	offer_layer.add_child(offer_rays)
	offer_layer.color.a = 0.55
	var v := VBoxContainer.new()
	v.name = "Box"
	v.add_theme_constant_override("separation", 18)
	offer_title = UiKit.title(40)
	offer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_sub = UiKit.label(19, UiKit.TEXT, 3)
	offer_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := UiKit.label(16, UiKit.MUTED, 3)
	sub.text = "UI_OFFER_KEYS"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_keys = sub
	offer_box = VBoxContainer.new()
	offer_box.add_theme_constant_override("separation", 14)
	# Rolagem para listas longas (deck inteiro) e para qualquer oferta que não caiba na tela; a folga em volta
	# deixa a carta subir (hover) e a entrada com sobra sem ser cortada. Altura e largura: _fit_offer.
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 20)
	pad.add_theme_constant_override("margin_bottom", 6)
	pad.add_child(offer_box)
	offer_scroll = ScrollContainer.new()
	offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	offer_scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	offer_scroll.add_child(pad)
	# Toda recompensa pode ser recusada (deck enxuto também é estratégia).
	offer_skip = Button.new()
	offer_skip.text = "UI_OFFER_SKIP"
	offer_skip.custom_minimum_size = Vector2(240, 46)
	offer_skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	offer_skip.pressed.connect(func(): offer_chosen.emit(Sim.SKIP))
	if UiSkins.diario():
		offer_title.add_theme_font_size_override("font_size", 46)
		v.add_child(UiDiario.tape_title(offer_title))
		v.add_child(UiDiario.tape_wrap(offer_sub, UiDiario.MASK, 1.0))
		v.add_child(UiDiario.tape_wrap(sub, UiDiario.MASK, -0.8))
	else:
		v.add_child(offer_title)
		v.add_child(offer_sub)
		v.add_child(sub)
	v.add_child(offer_scroll)
	v.add_child(offer_skip)
	offer_layer.add_child(v)
	offer_layer.visible = false
	add_child(offer_layer)
	# O mapa em tela cheia cobre a mão e os painéis, mas fica sob ofertas e pausa.
	move_child(minimap, offer_layer.get_index())


func _build_pause() -> void:
	pause_layer = _dim()
	var row := HBoxContainer.new()
	row.name = "Box"
	row.add_theme_constant_override("separation", 28)
	pause_layer.add_child(row)
	pause_menu = VBoxContainer.new()
	pause_menu.add_theme_constant_override("separation", 10)
	var t := UiKit.title(56)
	t.text = "UI_PAUSED"
	pause_menu.add_child(t)
	pause_time = UiKit.label(17, UiKit.MUTED, 3)
	pause_menu.add_child(pause_time)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	pause_menu.add_child(gap)
	for spec in [["UI_RESUME", func(): resume.emit()], ["UI_SETTINGS", func(): _open_settings()],
			["UI_SAVE_MENU", func(): to_menu.emit(false)], ["UI_SAVE_QUIT", func(): quit_game.emit()]]:
		var b := Button.new()
		b.text = spec[0]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(320, 54)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(spec[1])
		b.mouse_entered.connect(func(): b.grab_focus())
		pause_menu.add_child(b)
	if UiSkins.diario():
		var sheet := PanelContainer.new()
		UiDiario.dress(sheet, "paper", 34.0, {"grime": 0.45, "seed": 0.52, "shadow": 10.0, "rough": 2.6})
		sheet.rotation_degrees = -1.0
		sheet.add_child(pause_menu)
		row.add_child(sheet)
	else:
		row.add_child(pause_menu)
	var info := UiKit.panel(UiKit.BG, UiKit.EDGE, 16)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 10)
	info.add_child(iv)
	var dh := UiKit.title(26)
	dh.name = "DeckHead"
	iv.add_child(dh)
	pause_deck = GridContainer.new()
	pause_deck.columns = 5
	pause_deck.add_theme_constant_override("h_separation", 8)
	pause_deck.add_theme_constant_override("v_separation", 8)
	iv.add_child(pause_deck)
	var bh := UiKit.title(26)
	bh.text = "UI_HERO_BUILD"
	iv.add_child(bh)
	# Habilidades do herói: ícone e nome; o mouse em cima explica.
	pause_build = GridContainer.new()
	pause_build.columns = 3
	pause_build.add_theme_constant_override("h_separation", 10)
	pause_build.add_theme_constant_override("v_separation", 6)
	iv.add_child(pause_build)
	row.add_child(info)
	settings = SettingsPanel.new()
	settings.visible = false
	settings.closed.connect(func():
		settings.visible = false
		pause_layer.get_node("Box").visible = true
		pause_menu.get_child(3).grab_focus())
	settings.changed.connect(func(k: String):
		if k == "hints_reset":
			hints_seen.clear()
		settings_changed.emit(k))
	pause_layer.add_child(settings)
	pause_layer.visible = false
	add_child(pause_layer)


func _open_settings() -> void:
	pause_layer.get_node("Box").visible = false
	settings.open()


func _build_result() -> void:
	result_layer = _dim()
	var p := UiKit.panel(UiKit.BG, UiKit.GOLD.darkened(0.3), 28)
	p.name = "Box"
	p.custom_minimum_size = Vector2(820, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	result_title = UiKit.title(80)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(result_title)
	result_sub = UiKit.label(20, Color(0.9, 0.86, 1.0))
	result_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(result_sub)
	result_grid = GridContainer.new()
	result_grid.columns = 3
	result_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result_grid.add_theme_constant_override("h_separation", 10)
	result_grid.add_theme_constant_override("v_separation", 10)
	v.add_child(result_grid)
	var br := HBoxContainer.new()
	br.alignment = BoxContainer.ALIGNMENT_CENTER
	br.add_theme_constant_override("separation", 14)
	result_btn = Button.new()
	result_btn.text = "UI_RESTART"
	result_btn.custom_minimum_size = Vector2(280, 56)
	result_btn.add_theme_font_size_override("font_size", 22)
	result_btn.pressed.connect(func(): to_menu.emit(true))
	var mb := Button.new()
	mb.text = "UI_MAIN_MENU"
	mb.custom_minimum_size = Vector2(280, 56)
	mb.add_theme_font_size_override("font_size", 22)
	mb.pressed.connect(func(): to_menu.emit(false))
	br.add_child(result_btn)
	br.add_child(mb)
	v.add_child(br)
	result_layer.add_child(p)
	result_layer.visible = false
	add_child(result_layer)


# ---------------------------------------------------------------- layout

func _process(_d: float) -> void:
	if visible:
		_layout()


func _layout() -> void:
	var vs := get_viewport_rect().size
	var m := 14.0
	run_panel.position = Vector2(m, m)
	run_panel.size = run_panel.get_combined_minimum_size()
	tool_row.position = Vector2(vs.x - tool_row.size.x - m, m)
	# Centralizado, mas nunca por cima do painel da run nem dos botões (interface ampliada ou janela estreita).
	duel.position = Vector2(clampf((vs.x - duel.size.x) * 0.5, m + run_panel.size.x + 12.0, maxf(tool_row.position.x - duel.size.x - 12.0, m + run_panel.size.x + 12.0)), 10)
	bottom_box.position = Vector2((vs.x - bottom_box.size.x) * 0.5, vs.y - bottom_box.size.y - 30)
	var top := maxf(run_panel.position.y + run_panel.size.y, duel.position.y + duel.size.y)
	help_label.position = Vector2(m, vs.y - 24)
	info_label.position = Vector2(m, vs.y - 44)
	# Faixa de rota em pé na borda esquerda, do painel da run até acima das legendas de rodapé.
	strip.position = Vector2(m, run_panel.position.y + run_panel.size.y + 12)
	strip.size = Vector2(strip.custom_minimum_size.x, maxf(info_label.position.y - 16.0 - strip.position.y, 120.0))
	var below := top + 10
	var left := strip.position.x + strip.size.x + 12 if strip.visible else m
	contract_panel.position = Vector2(left, below)
	# O mapa grande cobre a tela inteira (como o mapa do Slay the Spire); a run fica parada por trás.
	if minimap.size != vs:
		minimap.size = vs
	minimap.position = Vector2.ZERO
	parts_panel.position = Vector2(vs.x - parts_panel.size.x - m, tool_row.position.y + tool_row.size.y + 8)
	toast.position = Vector2((vs.x - toast.size.x) * 0.5, vs.y * 0.28)
	contest_panel.size = contest_panel.get_combined_minimum_size()
	contest_panel.position = Vector2((vs.x - contest_panel.size.x) * 0.5, duel.position.y + duel.size.y + 8)
	learn_panel.position = Vector2((vs.x - learn_panel.size.x) * 0.5, duel.position.y + duel.size.y + (70 if contest_panel.visible else 26))
	relic_row.position = Vector2(vs.x - relic_row.size.x - m, tool_row.position.y + tool_row.size.y + 8)
	hint_panel.position = Vector2((vs.x - hint_panel.size.x) * 0.5, below + 6)
	for layer in [offer_layer, pause_layer, result_layer]:
		# O escurecimento cobre a tela inteira (pela âncora ele ficava com tamanho zero e não aparecia).
		layer.position = Vector2.ZERO
		layer.size = vs
		var b: Control = layer.get_node("Box")
		b.position = (vs - b.size) * 0.5
	settings.position = (vs - settings.size) * 0.5


# ---------------------------------------------------------------- estado

func show_run(on: bool) -> void:
	visible = on
	if not on:
		sim = null
		offer_layer.visible = false
		pause_layer.visible = false
		result_layer.visible = false


func bind(s: Sim) -> void:
	sim = s
	selected = -1
	offer_sig = ""
	result_shown = false
	show_run(true)
	for n in [duel, run_panel, strip, bottom_box, tool_row]:
		n.visible = true
	minimap.visible = false
	parts_panel.visible = false
	UiKit.clear(parts_box)
	part_rows.clear()
	result_layer.visible = false
	pause_layer.visible = false
	minimap.setup(s)
	strip.setup(s)
	fan.bind(s)
	contract_text = ""
	_sync_upgrades()
	Tips.close_all()


func show_pause(on: bool) -> void:
	pause_layer.visible = on and sim != null
	if not pause_layer.visible:
		settings.visible = false
		return
	pause_layer.get_node("Box").visible = true
	settings.visible = false
	pause_time.text = tr("UI_PAUSE_TIME").format({"t": _clock(sim.t), "deck": tr("DECK_" + sim.deck_id)})
	(pause_layer.find_child("DeckHead", true, false) as Label).text = tr("UI_RUN_DECK").format({"n": sim.cards.size()})
	UiKit.clear(pause_deck)
	for ci in sim.cards:
		if UiSkins.diario():
			var mc := UiKit.mini_card(ci.def, sim.card_cost(ci), UiKit.mod_names(ci), "", 92.0, 120.0, true, ci.level)
			mc.mouse_filter = Control.MOUSE_FILTER_STOP
			var mcd: CardDef = ci.def
			var mmids := UiKit.mod_ids(ci)
			Tips.attach(mc, func(): return Tips.card_entries(mcd, mmids, true))
			pause_deck.add_child(mc)
			continue
		var cell := UiKit.panel(Color(0.04, 0.03, 0.06), UiKit.RARITY_COLORS[ci.def.rarity], 3)
		var cd: CardDef = ci.def
		var mids := UiKit.mod_ids(ci)
		Tips.attach(cell, func(): return Tips.card_entries(cd, mids, true))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 0)
		var art := TextureRect.new()
		art.texture = CardArt.textures.get(ci.def.id)
		art.custom_minimum_size = Vector2(112, 50)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		cv.add_child(art)
		var nl := UiKit.label(12, Color(0.92, 0.9, 0.98), 3)
		nl.text = tr("CARD_" + ci.def.id)
		nl.custom_minimum_size = Vector2(112, 0)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cv.add_child(nl)
		var mods := _mod_names(ci)
		if mods.size() > 0:
			var ml := UiKit.label(11, UiKit.GOLD, 3)
			ml.text = "★ " + ", ".join(mods)
			ml.custom_minimum_size = Vector2(112, 0)
			ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ml.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			cv.add_child(ml)
		cell.add_child(cv)
		UiKit.ignore_mouse(cell)
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		pause_deck.add_child(cell)
	UiKit.clear(pause_build)
	for u in sim.hero.upgrade_order:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.custom_minimum_size = Vector2(200, 0)
		row.add_child(UpgradeIcon.make(u, 34))
		var nl := UiKit.label(15, Color(0.9, 0.88, 1.0), 3)
		nl.text = tr("UPG_" + u)
		nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(nl)
		UiKit.ignore_mouse(row)
		_attach_upgrade(row, u)
		pause_build.add_child(row)
	if sim.hero.upgrade_order.is_empty():
		var nl := UiKit.label(15, UiKit.MUTED, 3)
		nl.text = tr("UI_NO_BUILD")
		pause_build.add_child(nl)
	pause_menu.get_child(3).grab_focus.call_deferred()


## Caixas de uma habilidade do herói: nome com o ícone e o que faz, mais as palavras-chave do texto.
func upgrade_entries(id: String) -> Array:
	return Tips.text_entries(tr("UPG_" + id), UpgradeIcon.desc(sim.data, id), UpgradeIcon.make(id, 30))


func _attach_upgrade(c: Control, id: String) -> void:
	Tips.attach(c, func(): return upgrade_entries(id) if sim else [])


## Esc/B dentro da pausa: fecha as configurações primeiro. Devolve true se tratou.
func back() -> bool:
	if pause_layer.visible and settings.visible:
		settings.closed.emit()
		return true
	return false


## Dica contextual: aparece só na primeira vez (fica salva em user://hints.cfg).
func hint(key: String) -> void:
	if hints_seen.has(key) or not Settings.v["hints"]:
		return
	hints_seen[key] = true
	Tips.set_text(hint_label, tr("HINT_" + key))
	hint_panel.visible = true
	hint_t = 8.0
	var cf := ConfigFile.new()
	for k in hints_seen:
		cf.set_value("seen", k, true)
	cf.save("user://hints.cfg")


func _hints() -> void:
	if sim.t > 0.5:
		hint("start")
	if sim.route_wait:
		hint("fork")
	if sim.offers.size() > 0:
		hint("offer")
	if sim.contract.size() > 0:
		hint("contract")
	if sim.phase == K.Phase.ARENA:
		hint("arena")
	var h := Vector2(sim.hero.x, sim.hero.y)
	for loc in sim.road.locations:
		if loc["type"] == "shrine" and loc["state"] == SimRoad.LocState.ACTIVE and h.distance_to(loc["pos"]) < 45.0:
			hint("shrine")
	for ci in sim.hand:
		if ci and ci.def.category == "route":
			hint("route")


## Ponto da tela onde soltar uma carta não vale: fora da janela ou em cima de uma peça sólida da HUD.
func blocks_world(p: Vector2) -> bool:
	if not get_viewport().get_visible_rect().has_point(p):
		return true
	for c in [hero_badge, elixir_tray, tool_row, gold_label]:
		if c and c.is_visible_in_tree() and c.get_global_rect().has_point(p):
			return true
	return false


func say(txt: String) -> void:
	toast.text = txt
	toast_t = 1.8


static func _clock(t: float) -> String:
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]


func _mod_names(ci: Sim.CardInst) -> Array:
	return UiKit.mod_names(ci)


# ---------------------------------------------------------------- atualização

func refresh(delta: float, fps: float) -> void:
	if sim == null:
		return
	var over := sim.phase == K.Phase.OVER
	fan.selected = selected
	fan.pad = pad
	fan.sac_rect = sac_zone.get_global_rect()
	fan.mouse_filter = Control.MOUSE_FILTER_IGNORE if hold_offers else Control.MOUSE_FILTER_STOP
	fan.modulate.a = lerpf(fan.modulate.a, 0.35 if hold_offers else 1.0, clampf(delta * 8.0, 0.0, 1.0))
	fan.refresh(delta)
	var sel := sim.hand_card(selected) if selected >= 0 else null
	# Alvos que a faixa destaca para a carta de rota selecionada.
	strip.target = "location" if sel and sel.def.id == "burn_village" else ""
	gold_label.text = tr("UI_GOLD").format({"g": int(sim.gold)})
	gold_label.visible = sim.phase == K.Phase.ROAD
	elixir_bar.max_value = sim.elixir_max
	elixir_bar.value = sim.elixir
	elixir_bar.cost = sim.card_cost(sel) if sel and sim.offers.is_empty() else 0
	(elixir_badge.get_node("N") as Label).text = str(int(sim.elixir))
	sac_zone.disabled = selected < 0 or sim.offers.size() > 0
	sac_zone.text = tr("UI_SACRIFICE" if sim.sacrifice_ready() else "UI_SACRIFICE_CD")
	_refresh_top()
	_refresh_left()
	info_label.visible = Settings.v["show_fps"]
	info_label.text = tr("UI_FPS").format({"fps": int(fps), "u": sim.units.count})
	# A linha de atalhos só no começo da run: depois as dicas ficam na pausa e nas caixas das cartas.
	help_label.visible = Settings.v["show_help"] and not over and sim.t < 45.0
	help_label.text = tr("UI_HELP_ARENA") if sim.phase == K.Phase.ARENA else tr("UI_HELP")
	speed_btn.text = "%dx" % int(speed)
	_hints()
	if hint_t > 0.0:
		# Lendo a dica (mouse em cima ou numa caixa aberta por ela): não some.
		var reading_hint := hint_panel.get_global_rect().has_point(get_global_mouse_position()) or Tips.reading()
		hint_t = maxf(hint_t, 1.0) if reading_hint else hint_t - delta
		hint_panel.modulate.a = clampf(hint_t, 0.0, 1.0)
		hint_panel.visible = hint_t > 0.0
	_refresh_offer()
	_refresh_contest()
	_refresh_relics()
	_refresh_arena()
	if sim.phase == K.Phase.ROAD and minimap.visible:
		minimap.queue_redraw()
	toast_t = maxf(toast_t - delta, 0.0)
	toast.modulate.a = clampf(toast_t * 2.0, 0.0, 1.0)
	toast.scale = Vector2.ONE * (1.0 + maxf(toast_t - 1.6, 0.0) * 0.6)
	toast.pivot_offset = toast.size * 0.5
	bottom_box.visible = not over and sim.offers.is_empty() and not pause_layer.visible
	tool_row.visible = not over and not pause_layer.visible
	if over and not result_shown:
		_show_result()


func _refresh_top() -> void:
	var h := sim.hero
	(hero_badge.get_node("N") as Label).text = str(h.level)
	hero_hp.max_value = h.max_hp()
	hero_hp.value = h.hp
	hero_hp_label.text = "%d / %d" % [int(h.hp), int(h.max_hp())]
	hero_of_label.text = tr("UI_HERO_OF").format({"k": sim.party_idx + 1, "n": sim.party_size()}) + " · " + tr("HERO_" + sim.hero.cls())
	if sim.group_mode():
		hero_of_label.text += " · " + tr("UI_HEROES_STANDING").format({"n": 1 + sim.followers.size()})
		var fl: Array = []
		for f in sim.followers:
			fl.append("%s %d%%" % [tr("HERO_" + f.cls()), int(round(100.0 * f.hp / maxf(f.max_hp(), 1.0)))])
		if fl.size() > 0:
			hero_of_label.text += " (" + ", ".join(fl) + ")"
	_refresh_upgrades()
	curse_label.text = tr("UI_CURSES").format({"n": h.curses}) if h.curses > 0 else ""


## Fileira de ícones das habilidades. Habilidade nova: ícone pulsa e o aviso aparece (sem pausar).
func _refresh_upgrades() -> void:
	var order: Array = sim.hero.upgrade_order
	while upg_shown < order.size():
		var ic := _add_upgrade_icon(order[upg_shown])
		ic.pulse = 4.0
		_announce(order[upg_shown])
		upg_shown += 1
	upg_none.visible = order.is_empty()
	# Recarga de cada habilidade: a janela para jogar a carta certa (rodada 09/11/2026).
	for id in upg_icons:
		var ic: UpgradeIcon = upg_icons[id]
		var st := sim.hero.ability_state(id)
		var f := clampf(st.x / st.y, 0.0, 1.0) if st.y > 0.0 else 0.0
		var tl := st.z >= 0.0
		if not is_equal_approx(f, ic.cd_frac) or tl != ic.telling:
			ic.cd_frac = f
			ic.telling = tl
			ic.queue_redraw()
		elif tl:
			ic.queue_redraw()
	if learn_t > 0.0:
		learn_t -= get_process_delta_time()
		learn_panel.modulate.a = clampf(learn_t * 2.0, 0.0, 1.0)
		# Com caixas abertas o aviso sai do caminho (o ícone na fileira explica a mesma coisa).
		learn_panel.visible = learn_t > 0.0 and not Tips.reading() and not pause_layer.visible


func _add_upgrade_icon(id: String) -> UpgradeIcon:
	var ic := UpgradeIcon.make(id, 30)
	_attach_upgrade(ic, id)
	upg_row.add_child(ic)
	upg_icons[id] = ic
	return ic


## Run nova ou carregada: refaz a fileira com o que o herói já tem, sem anunciar.
func _sync_upgrades() -> void:
	upg_icons.clear()
	for c in upg_row.get_children():
		if c != upg_none:
			upg_row.remove_child(c)
			c.queue_free()
	for id in sim.hero.upgrade_order:
		_add_upgrade_icon(id)
	upg_shown = sim.hero.upgrade_order.size()
	learn_t = 0.0
	learn_panel.visible = false


func _announce(id: String) -> void:
	UiKit.clear(learn_panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.add_child(UpgradeIcon.make(id, 52))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var head := UiKit.label(14, UiKit.HERO_XP.lightened(0.3), 3)
	head.text = tr("UI_HERO_LEARNED").format({"n": sim.hero.level})
	var nl := UiKit.title(24)
	nl.text = tr("UPG_" + id)
	var dl := RichTextLabel.new()
	dl.bbcode_enabled = true
	dl.fit_content = true
	dl.scroll_active = false
	dl.custom_minimum_size = Vector2(380, 0)
	dl.add_theme_font_size_override("normal_font_size", 15)
	dl.text = Tips.rich(UpgradeIcon.desc(sim.data, id), false)
	for n in [head, nl, dl]:
		v.add_child(n)
	h.add_child(v)
	learn_panel.add_child(h)
	UiKit.ignore_mouse(learn_panel)
	learn_panel.reset_size()
	learn_panel.visible = true
	learn_t = 4.0


func _refresh_left() -> void:
	time_label.text = _clock(sim.t)
	# Na estrada o progresso fica na faixa de rota.
	road_bar.visible = false
	road_label.visible = sim.phase != K.Phase.ROAD
	road_label.text = tr("UI_IN_ARENA")
	var c := sim.contract
	contract_panel.visible = c.size() > 0 and sim.phase != K.Phase.OVER
	if c.is_empty():
		return
	var g: Dictionary = c["goal"]
	var gp := {}
	for k2 in g:
		gp[k2] = g[k2]
	if g.has("tag"):
		gp["tag"] = "[[%s]]" % str(g["tag"])
	if typeof(gp.get("amount")) == TYPE_FLOAT:
		gp["amount"] = int(gp["amount"])
	contract_name.text = tr("CON_" + str(c["id"]))
	var goal := tr("CONG_" + str(g["kind"])).format(gp)
	if goal != contract_text:
		contract_text = goal
		Tips.set_text(contract_goal, goal)
	contract_bar.max_value = maxf(float(g["amount"]), 1.0)
	contract_bar.value = float(c["progress"])
	var tl := int(c["t"])
	contract_time.text = "%d s" % tl
	contract_time.add_theme_color_override("font_color", UiKit.BAD if tl <= 10 else UiKit.TEXT)


func _refresh_contest() -> void:
	var c := sim.contest
	contest_panel.visible = c.size() > 0 and sim.phase == K.Phase.ROAD and not pause_layer.visible
	if not contest_panel.visible:
		return
	var p := float(c["progress"])
	var g := float(c["goal"])
	var txt := tr("UI_CONTEST_" + str(c["type"])).format({
		"p": int(p) if c["type"] != "bridge" and c["type"] != "fountain" else int(p),
		"g": int(g), "s": int(ceil(float(c["window"]) - float(c["t"])))})
	if txt != contest_text:
		contest_text = txt
		Tips.set_text(contest_label, txt)


func _refresh_relics() -> void:
	if relic_row.get_child_count() == sim.relics.size():
		return
	UiKit.clear(relic_row)
	for id in sim.relics:
		var b := UiKit.label(14, UiKit.GOLD, 3)
		b.text = "◆ " + tr("REL_" + str(id))
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		var rid: String = id
		Tips.attach(b, func(): return [Tips.entry(tr("REL_" + rid), tr("RELD_" + rid))])
		relic_row.add_child(b)


## Eventos da simulação que viram aviso na tela (disputa, ato).
func handle_events(evs: Array) -> void:
	for e in evs:
		match int(e[0]):
			K.Ev.CONTEST:
				if int(e[4]) == 0 and sim.contest.size() > 0:
					# Chegou no local: o objetivo bate grande no meio e voa para o painel da disputa no topo.
					var c := sim.contest
					var f := {"g": int(c["goal"]), "s": int(ceil(float(c["window"])))}
					var dock := Vector2(get_viewport_rect().size.x * 0.5, duel.position.y + duel.size.y + 26.0)
					banner.show_banner(tr("UI_GOAL_" + str(c["type"])).format(f), tr("UI_GOALSUB_" + str(c["type"])).format(f), UiKit.GOLD, dock)
				elif int(e[4]) > 0:
					banner.show_banner(tr("UI_BANNER_WON"), tr("UI_CONTEST_WON"), Color(0.55, 1.0, 0.55), Vector2(-1, -1), 0.8)
				elif int(e[4]) < 0:
					banner.show_banner(tr("UI_BANNER_LOST"), tr("UI_CONTEST_LOST"), Color(1.0, 0.45, 0.4), Vector2(-1, -1), 0.6)
			K.Ev.ACT_START:
				banner.show_banner(tr("UI_ACT_OF").format({"n": int(e[3]) + 1, "m": sim.acts()}), "", UiKit.GOLD, Vector2(-1, -1), 1.0)


func _refresh_offer() -> void:
	var on := sim.offers.size() > 0 and not hold_offers
	offer_layer.visible = on
	if not on:
		offer_sig = ""
		return
	var o: Dictionary = sim.offers[0]
	var sig := TranslationServer.get_locale() + str(o)
	if sig != offer_sig:
		offer_sig = sig
		_build_offer_options(o)
		if not is_same(o, offer_obj):
			offer_obj = o
			_offer_entrance()
	for k in offer_slots.size():
		var slot: Control = offer_slots[k]
		var hot: bool = k == selected or slot.get_meta("hover", false)
		# A grade guarda a altura de cada linha em base_y; a carta só sobe a partir dela.
		var base: float = slot.get_meta("base_y", slot.position.y)
		slot.position.y = lerpf(slot.position.y, base - (14.0 if hot else 0.0), 0.25)


## Carta só de texto (relíquia, opção de evento): título e descrição numa moldura.
func _text_card(title: String, body: String, w: float, edge: Color) -> PanelContainer:
	var cp := UiKit.panel(UiKit.BG, edge, 14)
	cp.custom_minimum_size = Vector2(w, 246.0 * w / 168.0)
	var pv := VBoxContainer.new()
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.add_theme_constant_override("separation", 12)
	var pt := UiKit.title(24, edge.lightened(0.3))
	pt.text = title
	pt.autowrap_mode = TextServer.AUTOWRAP_WORD
	pt.custom_minimum_size = Vector2(w - 30.0, 0)
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pt)
	pv.add_child(Tips.label(body, 16, UiKit.TEXT, w - 30.0, true))
	UiKit.ignore_mouse(pv)
	cp.add_child(pv)
	return cp


func _offer_heading(o: Dictionary) -> String:
	if o["source"] == "location":
		return tr("UI_OFFER_LOC_" + str(o["loc"]))
	if o["source"] == "shop":
		return tr("UI_OFFER_SHOP").format({"g": int(sim.gold)})
	if o["source"] == "shop_pick":
		return tr("UI_OFFER_SHOP_PICK_" + str(o["what"]))
	if o["source"] == "relic":
		return tr("UI_OFFER_RELIC").format({"a": int(o.get("act", 0)) + 1})
	if o["source"] == "event":
		return tr("EVT_" + str(o["event"])) if o.has("event") else tr("UI_OFFER_EVENT_STEP")
	return tr({"level": "UI_OFFER_LEVEL", "shrine": "UI_OFFER_SHRINE", "contract": "UI_OFFER_CONTRACT"}[o["source"]])


func _inst_level(uid: int) -> int:
	for ci in sim.cards:
		if ci.uid == uid:
			return ci.level
	return 1


func _build_offer_options(o: Dictionary) -> void:
	offer_title.text = _offer_heading(o)
	var shop: bool = o["source"] == "shop"
	# A loja não tem subtítulo: ela não depende mais da disputa (sem desconto por vitória).
	offer_sub.visible = o["source"] == "location" or o.has("event")
	if UiSkins.diario():
		offer_sub.get_parent().visible = offer_sub.visible
	if o.has("event"):
		offer_sub.text = tr("EVT_%s_BODY" % str(o["event"]))
		offer_sub.add_theme_color_override("font_color", UiKit.TEXT)
	elif offer_sub.visible:
		var won: bool = o["won"]
		offer_sub.text = tr("UI_OFFER_WON" if won else "UI_OFFER_LOST")
		offer_sub.add_theme_color_override("font_color", UiKit.GOOD if won else UiKit.BAD)
	offer_skip.text = tr("UI_SHOP_LEAVE") if shop else tr("UI_OFFER_SKIP")
	offer_keys.text = tr("UI_SHOP_KEYS") if shop else tr("UI_OFFER_KEYS")
	UiKit.clear(offer_box)
	offer_slots.clear()
	var opts: Array = o["options"]
	# Remover "qualquer carta" mostra o deck inteiro: cartas menores, em linhas. A loja fica numa linha só.
	var w := (240.0 if UiSkins.covil() else 220.0) if opts.size() <= 4 else 150.0
	var cols := mini(opts.size(), 4 if w > 200.0 else 7)
	var vs := get_viewport_rect().size
	if shop:
		# Duas linhas: cartas em cima, serviços (subir nível, modificador, remover) embaixo. A largura da carta
		# sai da altura e da largura úteis da tela; o que sobrar de altura vira rolagem (_fit_offer).
		var n_cards := 0
		for it in opts:
			if str(it["item"]["kind"]) == "card":
				n_cards += 1
		var n_serv := opts.size() - n_cards
		cols = maxi(maxi(n_cards, n_serv), 1)
		var per_row := (vs.y - 280.0) / (2.0 if n_cards > 0 and n_serv > 0 else 1.0)
		w = minf(clampf((per_row - 120.0) * 168.0 / 246.0, 96.0, 180.0), (vs.x - 120.0 - 22.0 * (cols - 1)) / cols)
	var shop_scale := minf(1.0, w / 180.0) if shop else 1.0
	var rows: Array = []
	for k in opts.size():
		var op: Dictionary = opts[k]
		# Item da loja: desenha o que ele dá, com o preço em cima.
		var price := -1
		if op["kind"] == "buy":
			price = int(op["price"])
			op = op["item"]
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override("separation", 6)
		var head := UiKit.label(18 if w > 200.0 else 14, UiKit.GOLD)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.custom_minimum_size = Vector2(w, 0)
		head.autowrap_mode = TextServer.AUTOWRAP_WORD
		var foot := Tips.label("", 14, Color(0.92, 0.88, 1.0), w, true)
		var key := str(k + 1) if k < 9 else ""
		var cp: PanelContainer
		var cd: CardDef
		var lv := 1
		var mids: Array = []
		match str(op["kind"]):
			"card":
				cd = sim.data.card(op["id"])
				head.text = tr("UI_OPT_NEW").format({"r": tr("RARITY_" + K.RARITIES[cd.rarity])})
				head.add_theme_color_override("font_color", UiKit.RARITY_COLORS[cd.rarity].lightened(0.4))
				cp = UiKit.card(cd, cd.cost, [], key, w)
			"mod":
				cd = sim.data.card(str(op["card"]))
				lv = _inst_level(int(op["uid"]))
				mids = [str(op["mod"])]
				head.text = tr("UI_OPT_MOD_HEAD").format({"mod": tr("MOD_" + str(op["mod"]))})
				# Barato já mostra o custo novo na carta (gema azul-água).
				var mc := cd.cost_at(lv) - (1 if str(op["mod"]) == "cheap" else 0)
				cp = UiKit.card(cd, maxi(mc, 1), [tr("MOD_" + str(op["mod"]))], key, w, lv)
				Tips.set_text(foot, "[[%s]]: %s" % [op["mod"], tr("MODDESC_" + str(op["mod"]))])
			"upgrade":
				cd = sim.data.card(str(op["card"]))
				lv = int(op["level"]) + 1
				head.text = tr("UI_OPT_UP_HEAD").format({"a": lv - 1, "b": lv})
				head.add_theme_color_override("font_color", UiKit.GOOD)
				cp = UiKit.card(cd, cd.cost_at(lv), [], key, w, lv)
				var ch := UiKit.level_changes(cd, lv - 1, lv)
				if lv >= 3 and cd.n3.size() > 0:
					ch += ("
" if ch != "" else "") + tr("UI_OPT_UP_N3")
				Tips.set_text(foot, ch)
			"remove":
				cd = sim.data.card(str(op["card"]))
				lv = int(op.get("level", 1))
				head.text = tr("UI_OPT_REMOVE_HEAD")
				head.add_theme_color_override("font_color", UiKit.BAD)
				cp = UiKit.card(cd, cd.cost_at(lv), [], key, w, lv)
				cp.modulate = Color(1.0, 0.6, 0.6)
				if w > 200.0:
					Tips.set_text(foot, tr("UI_OPT_REMOVE").format({"card": UiKit.card_name(cd, lv)}))
			"pick":
				head.text = tr("UI_OPT_BUY_" + str(op["what"]).to_upper()) if price >= 0 else tr("UI_OPT_PICK_HEAD")
				cp = UiKit.panel(UiKit.BG, UiKit.GOLD, 14)
				cp.custom_minimum_size = Vector2(w, 246.0 * w / 168.0)
				var pv := VBoxContainer.new()
				pv.alignment = BoxContainer.ALIGNMENT_CENTER
				pv.add_theme_constant_override("separation", 12)
				var pt := UiKit.title(maxi(roundi(30.0 * shop_scale), 16), UiKit.GOLD)
				pt.text = tr("UI_PICK_" + str(op["what"]))
				pt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				pt.custom_minimum_size = Vector2(w - 20.0, 0)
				pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				pv.add_child(pt)
				pv.add_child(Tips.label(tr("UI_OPT_BUY_" + str(op["what"]).to_upper() + "_D") if price >= 0 else tr("UI_PICKD_" + str(op["what"])), maxi(roundi(16.0 * shop_scale), 11), UiKit.TEXT, w - 30.0, true))
				UiKit.ignore_mouse(pv)
				cp.add_child(pv)
			"relic":
				var rel: Dictionary = sim.data.relics.get(str(op["id"]), {})
				var ri := K.RARITIES.find(str(rel.get("rarity", "common")))
				head.text = tr("RARITY_" + K.RARITIES[maxi(ri, 0)])
				head.add_theme_color_override("font_color", UiKit.RARITY_COLORS[maxi(ri, 0)].lightened(0.4))
				cp = _text_card(tr("REL_" + str(op["id"])), tr("RELD_" + str(op["id"])), w, UiKit.RARITY_COLORS[maxi(ri, 0)])
			"event_opt":
				var ek := "EVT_%s_%s" % [op["event"], sim.data.events_def[op["event"]]["options"][int(op["opt"])]["id"]]
				head.text = key
				cp = _text_card(tr(ek), tr(ek + "_D"), w, UiKit.GOLD)
				if not sim.event_option_ok(op):
					var need: float = sim.data.events_def[op["event"]]["options"][int(op["opt"])].get("requires", {}).get("gold", 0)
					cp.modulate = Color(0.55, 0.55, 0.55)
					Tips.set_text(foot, tr("UI_EVENT_NEEDS").format({"g": int(need)}))
			"transform", "copy":
				cd = sim.data.card(str(op["card"]))
				lv = int(op.get("level", 1))
				head.text = tr("UI_OPT_" + str(op["kind"]).to_upper() + "_HEAD")
				cp = UiKit.card(cd, cd.cost_at(lv), [], key, w, lv)
		if price >= 0:
			var ok := sim.can_afford(opts[k])
			# Preço numa linha, descrição noutra (com quebra): o rótulo não alarga a coluna.
			# Carta, escolha de carta e modificador já se descrevem sozinhos (ou têm nota embaixo): só o preço no rótulo.
			var desc := "" if str(op["kind"]) in ["card", "pick", "mod"] else "
" + head.text
			head.text = tr("UI_SHOP_PRICE").format({"p": price}) + desc
			head.add_theme_color_override("font_color", UiKit.GOLD if ok else UiKit.BAD)
			if not ok:
				cp.modulate = cp.modulate * Color(0.55, 0.55, 0.55)
				Tips.set_text(foot, tr("UI_SHOP_POOR"))
		if cd:
			var tl := lv
			var tm := mids
			var td := cd
			Tips.attach(cp, func(): return Tips.card_entries(td, tm, false, tl))
		cp.mouse_filter = Control.MOUSE_FILTER_STOP
		cp.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				offer_chosen.emit(k))
		cp.mouse_entered.connect(func(): slot.set_meta("hover", true))
		cp.mouse_exited.connect(func(): slot.set_meta("hover", false))
		if UiSkins.diario():
			head.custom_minimum_size = Vector2(0, 0)
			head.autowrap_mode = TextServer.AUTOWRAP_OFF
			if shop:
				head.add_theme_font_size_override("font_size", 14 if w >= 130.0 else 12)
				head.custom_minimum_size = Vector2(maxf(w - 12.0, 40.0), 0)
				head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			head.add_theme_font_override("font", UiDiario.font("type"))
			slot.add_child(UiDiario.tape_wrap(head, UiDiario.MASK, -2.0 + k * 1.3))
			slot.add_child(cp)
			var note := UiDiario.note_wrap(foot)
			note.custom_minimum_size = Vector2(w * 0.9, 0)
			note.visible = foot.get_parsed_text().strip_edges() != ""
			slot.add_child(note)
		else:
			slot.add_child(head)
			slot.add_child(cp)
			slot.add_child(foot)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.set_meta("card", cp)
		slot.set_meta("special", lv > 1 or mids.size() > 0 or str(op["kind"]) in ["upgrade", "mod"])
		slot.set_meta("fx_col", Color(0.55, 1.0, 0.55) if str(op["kind"]) == "upgrade" else (CardFx.MOD_COLOR.get(mids[0], UiKit.GOLD).lightened(0.3) if mids.size() > 0 else UiKit.GOLD))
		var row_i := (0 if str(op["kind"]) == "card" else 1) if shop else k / cols
		while rows.size() <= row_i:
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 22)
			# Cada linha guarda a altura de seus itens em base_y; a carta só sobe a partir dela.
			row.sort_children.connect(func():
				for c in row.get_children():
					c.set_meta("base_y", c.position.y))
			rows.append(row)
			offer_box.add_child(row)
		(rows[row_i] as Control).add_child(slot)
		offer_slots.append(slot)
	offer_scroll.custom_minimum_size = Vector2.ZERO
	_fit_offer()


## A oferta nunca passa da tela: depois de dois quadros (os rótulos já quebraram linha), a rolagem recebe a largura
## e a altura do conteúdo, limitadas ao que sobra na tela; o resto rola.
func _fit_offer() -> void:
	var box := offer_layer.get_node("Box") as Control
	box.size = Vector2.ZERO
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(offer_scroll) or offer_slots.is_empty():
		return
	var vs := get_viewport_rect().size
	var content := (offer_box.get_parent() as Control).get_combined_minimum_size()
	# Altura de tudo que não é a rolagem (título, dicas, botão e espaços), com folga.
	var others := box.get_combined_minimum_size().y - offer_scroll.get_combined_minimum_size().y
	var max_h := maxf(vs.y - others - 36.0, 160.0)
	var scrolls := content.y > max_h
	offer_scroll.custom_minimum_size = Vector2(minf(content.x + (14.0 if scrolls else 0.0), vs.x - 24.0), minf(content.y, max_h))
	box.size = Vector2.ZERO


## Entrada da oferta: raios acendem, o título bate e as cartas chegam uma a uma, cada uma com faíscas e um
## som um tom acima da anterior; carta upada ganha clarão.
func _offer_entrance() -> void:
	offer_rays.kick()
	Juice.slam(offer_title)
	if sfx.is_valid():
		sfx.call("reward", 0.8)
	for k in offer_slots.size():
		var slot: Control = offer_slots[k]
		var cp: Control = slot.get_meta("card")
		if cp == null:
			continue
		var special: bool = slot.get_meta("special", false)
		var col: Color = slot.get_meta("fx_col", UiKit.GOLD)
		var pitch := 1.0 + 0.1 * k
		Juice.card_in(cp, 0.18 + 0.11 * k, special, func():
			if not is_instance_valid(cp):
				return
			Juice.burst(offer_layer, cp.get_global_rect().get_center() - offer_layer.get_global_rect().position, col, 26 if special else 16, 1.25 if special else 0.9)
			if sfx.is_valid():
				sfx.call("card_play" if not special else "level_player", pitch))


func _refresh_arena() -> void:
	if sim.phase != K.Phase.ARENA or not sim.arena.active:
		return
	var A := sim.arena
	if not parts_panel.visible:
		minimap.visible = false
		strip.visible = false
		parts_panel.visible = true
		var head := UiKit.title(22)
		head.text = "UI_YOUR_BODY"
		parts_box.add_child(head)
		for k in A.part_ids.size():
			var l := UiKit.label(15, UiKit.TEXT, 3)
			var b := UiKit.bar(UiKit.POWER, 266, 14)
			# Vida da parte em %, na linha do nome, à direita.
			var pl := UiKit.label(14, UiKit.GOLD, 3)
			pl.name = "P"
			pl.set_anchors_preset(Control.PRESET_FULL_RECT)
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.add_child(pl)
			parts_box.add_child(l)
			parts_box.add_child(b)
			part_rows.append([l, b])
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 6)
		parts_box.add_child(gap)
		tele_label = UiKit.label(15, Color(0.8, 0.85, 1.0), 3)
		Tips.attach(tele_label, func(): return [Tips.kw_entry("teleport"), Tips.kw_entry("altar")])
		tele_bar = UiKit.bar(Color(0.4, 0.75, 1.0), 266, 6)
		parts_box.add_child(tele_label)
		parts_box.add_child(tele_bar)
	for k in part_rows.size():
		var l: Label = part_rows[k][0]
		var b: ProgressBar = part_rows[k][1]
		var alive: bool = A.part_hp[k] > 0
		l.text = tr("UI_PART_" + str(A.part_ids[k])) + ("" if alive else "  ✖")
		b.max_value = A.part_max[k]
		b.value = A.part_hp[k]
		var frac: float = A.part_hp[k] / maxf(A.part_max[k], 1.0)
		(l.get_node("P") as Label).text = "%d%%" % ceili(frac * 100.0) if alive else ""
		var fs := b.get_theme_stylebox("fill")
		if fs is StyleBoxFlat:
			(fs as StyleBoxFlat).bg_color = UiKit.BAD if frac < 0.3 else UiKit.POWER
		else:
			b.self_modulate = Color(1.5, 0.55, 0.55) if frac < 0.3 else Color.WHITE
		l.modulate = Color(1, 1, 1) if alive else Color(0.45, 0.45, 0.45)
	var cd := float(A.A["teleport_cooldown"])
	tele_label.text = tr("UI_TELEPORT_READY") if A.tp_cd <= 0.0 else tr("UI_TELEPORT_CD").format({"t": ceili(A.tp_cd)})
	tele_bar.max_value = cd
	tele_bar.value = cd - A.tp_cd


func _show_result() -> void:
	result_shown = true
	result_layer.visible = true
	for n in [duel, run_panel, strip, minimap, parts_panel, hint_panel]:
		n.visible = false
	var st := sim.stats
	var r := str(st["result"])
	var won := r in ["win", "win_early"]
	result_title.text = tr("UI_RESULT_TITLE_" + r)
	UiKit.title_color(result_title, UiKit.GOLD if won else Color(0.9, 0.24, 0.18))
	result_sub.text = tr("UI_RESULT_" + r)
	var top := ""
	var best := 0
	for cid in st["played"]:
		if int(st["played"][cid]) > best:
			best = int(st["played"][cid])
			top = cid
	UiKit.clear(result_grid)
	var tiles := [["UI_ST_time", _clock(sim.t)], ["UI_ST_hero", str(sim.hero.level)], ["UI_ST_you", str(int(st.get("heroes_fallen", 0)))],
		["UI_ST_kills", str(st["kills"])], ["UI_ST_shrines", str(st["shrines_won"])], ["UI_ST_contracts", str(st["contracts_ok"])],
		["UI_ST_parts", str(st["parts_lost"])], ["UI_ST_top", tr("CARD_" + top) if top != "" else "—"],
		["UI_ST_souls", "+%d" % souls_gained]]
	for tdef in tiles:
		var tp := UiKit.panel(Color(0.08, 0.06, 0.12, 0.95), UiKit.EDGE.darkened(0.2), 10)
		tp.custom_minimum_size = Vector2(180, 86)
		var tv := VBoxContainer.new()
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		# Almas ganhas é a recompensa: dourada. Zeros ficam apagados.
		var souls: bool = tdef[0] == "UI_ST_souls"
		var zero: bool = tdef[1] == "0"
		if souls and UiSkins.covil():
			tp.material = UiCovil.material("plate", UiKit.GOLD, Color(0.2, 0.15, 0.08, 0.95), Color(0.08, 0.06, 0.04, 0.95), Color(1.0, 0.8, 0.4, 0.22))
		var val := UiKit.title(30 if tdef[1].length() < 8 else 17, UiKit.GOLD if souls else (UiKit.MUTED if zero else UiKit.TEXT))
		if UiSkins.covil() and tdef[1].length() >= 8:
			# Nome (carta mais jogada): texto comum, não título; em versalete grande ele quebrava a grade.
			val = UiKit.label(20, UiKit.TEXT, 3)
			val.add_theme_font_override("font", UiCovil.font("bold"))
		val.text = tdef[1]
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val.autowrap_mode = TextServer.AUTOWRAP_WORD
		val.custom_minimum_size = Vector2(160, 0)
		var lab := UiKit.label(13, UiKit.MUTED, 3)
		lab.text = tdef[0]
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tv.add_child(val)
		tv.add_child(lab)
		tp.add_child(tv)
		result_grid.add_child(tp)
	result_btn.grab_focus.call_deferred()
