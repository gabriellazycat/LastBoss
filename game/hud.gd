class_name Hud
extends Control
## Interface da run. Lê o Sim; ações do jogador viram comandos via sinais.
## Hierarquia: o herói (a ameaça) no centro do topo → faixa de rota logo abaixo → objetivo à esquerda → corpo do chefe
## (na arena) à direita → esteira do ciclo, mão em leque e elixir embaixo.

signal card_pressed(i: int)
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
var hero_name_row: Control          # linha do título do herói (escondida com party)
var party_box: BoxContainer          # uma linha por herói de pé da party (nome e vida de cada um)
var party_rows: Array = []           # [{h: SimHero, bar: ProgressBar, lab: Label}]
var upg_row: HBoxContainer         # ícones das habilidades do herói (mouse em cima explica)
var upg_none: Label
var upg_shown := 0
var learn_panel: PanelContainer    # aviso "o herói aprendeu" (some sozinho, não pausa)
var learn_t := 0.0
var upg_icons: Dictionary = {}       # habilidade -> ícone na HUD (recarga desenhada por cima)
var contest_panel: PanelContainer     # disputa do local em andamento (rodada 09/11/2026)
var contest_label: RichTextLabel
var contest_text := ""
var contest_stages: Control           # marcadores e barra das etapas da disputa
var hold_offers := false             # cena da morte do herói: a recompensa e as cartas esperam
var banner: BigBanner                  # letreiro grande: objetivo do local, resultado, ato (rodada 09/11/2026)
var seals: LocSeals                    # selos dos marcos na cena do fim da disputa (15/11/2026)
var relic_row: Container           # relíquias do covil ganhas na run (Diário: coluna de etiquetas à direita)
var curse_label: Label
var hero_title: Label                # nome da classe do líder, ou "A PARTY" com mais de um herói de pé
# Esquerda: run.
var run_panel: PanelContainer
var time_label: Label
var road_label: Label
var road_bar: ProgressBar
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
var elixir_tray: BoxContainer
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
# Poderes de party (plano 21/11/2026, frente H): fileira de ícones com recarga sobre a party e painel de revelação.
var power_row: Control
var power_badges: Array = []           # PowerBadge, na ordem de Sim.party_powers()
var power_sig := ""
var power_flash: Dictionary = {}       # índice -> "trigger" | "ready" | "gained" (aplicado no próximo refresh)
var power_layer: Control               # painel de revelação (acima da offer_layer; pausa pelo Sim.step)
var power_box: PanelContainer
var power_panel_sig := ""
var power_continue: Button
var offer_title: Label
var offer_box: VBoxContainer   # linhas (HBox) de cartas, dentro de offer_scroll
var offer_scroll: ScrollContainer
var offer_sub: Label
var offer_skip: Button
var offer_gold: Label
var offer_keys: Label
var gold_label: Label
var offer_sig := ""
var offer_slots: Array = []
var offer_rays: Juice.Rays             # raios de luz atrás da oferta (impacto, rodada 09/11/2026)
var offer_obj = null                   # oferta já animada (a mesma oferta reconstruída não anima de novo)
var ledger: ShopLedger                 # a loja é o livro-caixa do mercador (game/shop_ledger.gd, decisão 11/11/2026)
var sfx: Callable                      # som da interface: sfx.call(id, tom)
var unlock_near: Label
var unlock_result: Dictionary = {}   # cartas liberadas e progresso dos desafios (MetaSave.apply_unlocks)
var pause_layer: Control
var pause_menu: VBoxContainer
var pause_deck: GridContainer
var pause_deck_scroll: ScrollContainer
var pause_build: GridContainer
var pause_time: Label
var settings: SettingsPanel
var result_layer: Control
var result_title: Label
var result_icon: TextureRect   # pele "Mapa aberto": o covil desenhado no alto do resultado
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
	_build_power_row()
	_build_offer()
	_build_power_panel()
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
	hn.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hn.text = tr("UI_HERO")
	hero_title = hn
	UiParch.style_label(hn, "title", 21, UiParch.BLOOD)
	hname.add_child(hn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hname.add_child(sp)
	curse_label = UiKit.label(14, Color(0.75, 1.0, 0.55), 3)
	Tips.attach(curse_label, func(): return [Tips.kw_entry("curse")])
	hname.add_child(curse_label)
	hv.add_child(hname)
	hero_name_row = hname
	hero_hp = UiKit.bar(UiKit.HERO_HP, 340, 22)
	hero_hp_label = UiKit.label(15, Color.WHITE, 3)
	# Número claro sobre a barra escura (a tinta automática do papel o deixava ilegível).
	UiParch.style_label(hero_hp_label, "bold", 16, UiParch.CREAM)
	hero_hp_label.add_theme_constant_override("outline_size", 4)
	hero_hp_label.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.02, 0.9))
	hero_hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_hp.add_child(hero_hp_label)
	hv.add_child(hero_hp)
	hero_of_label = UiKit.label(13, UiKit.MUTED, 3)
	hv.add_child(hero_of_label)
	party_box = HBoxContainer.new()
	party_box.add_theme_constant_override("separation", 14)
	party_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	party_box.visible = false
	hv.add_child(party_box)
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
	# Variações de 17/11/2026: a barra grande só para um herói sozinho (com party, as linhas de cada um bastam);
	# sem a linha "Sem habilidades ainda"; o painel encolhe para o que tem.
	hero_hp.custom_minimum_size = Vector2(360, 20)
	upg_row.custom_minimum_size = Vector2(0, 30)
	hv.add_theme_constant_override("separation", 2)


func _build_left() -> void:
	run_panel = UiKit.panel(UiKit.BG_SOFT, UiKit.EDGE.darkened(0.2), 10)
	run_panel.custom_minimum_size = Vector2(150, 0)
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
		if spec[0] in ["II", "M"]:
			UiDiario.icon_button(b, "pause" if spec[0] == "II" else "map")
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
	fan.card_dropped.connect(func(i, p): card_dropped.emit(i, p))
	bottom_box.add_child(fan)
	# Elixir em coluna na borda direita (17/11/2026).
	var eb: BoxContainer = VBoxContainer.new()
	eb.alignment = BoxContainer.ALIGNMENT_CENTER
	eb.set_meta("paper", true)
	eb.draw.connect(func(): UiDiario.draw_plate(eb, "paper", Vector2(18, 10)))
	eb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	eb.add_theme_constant_override("separation", 12)
	# A bandeja do elixir é sólida: o clique nela não pode cair no mundo atrás (rodada 09/11/2026).
	eb.mouse_filter = Control.MOUSE_FILTER_STOP
	elixir_tray = eb
	elixir_bar = ElixirBar.new()
	# Sem o botão de sacrifício (11/11/2026), a barra ocupa a bandeja toda: mais gomos cabem quando o máximo passa de 20.
	elixir_bar.custom_minimum_size = Vector2(740, 22)
	elixir_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	elixir_bar.vertical = true
	elixir_bar.custom_minimum_size = Vector2(46, 470)
	elixir_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# A gota grande embaixo já diz quanto há; os gomos dizem o máximo. Sem o "7 / 10" repetido no alto.
	elixir_bar.show_label = false
	elixir_bar.custom_minimum_size = Vector2(46, 300)
	elixir_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A moldura dupla do papel ocupa ~14 px no alto: sem este respiro a primeira fileira de gotas cruzava a linha.
	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 16)
	top_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eb.add_child(top_pad)
	eb.add_child(elixir_bar)
	elixir_badge = UiKit.badge(UiKit.ELIXIR, 30, 62)
	eb.add_child(elixir_badge)
	# Ouro da run (lojas), ao lado do elixir.
	gold_label = UiKit.label(20, UiKit.GOLD, 4)
	gold_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gold_label.custom_minimum_size = Vector2(0, 0)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	gold_label.custom_minimum_size = Vector2(70, 0)
	gold_label.add_theme_font_size_override("font_size", 16)
	gold_label.mouse_filter = Control.MOUSE_FILTER_STOP
	Tips.attach(gold_label, func(): return [Tips.kw_entry("gold")])
	# Ouro é moeda de loja, não de carta: vai para o canto de cima à direita, com os botões e as relíquias.
	gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	gold_label.custom_minimum_size = Vector2(0, 0)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.add_theme_font_size_override("font_size", 18)
	# Etiqueta de papel igual às das relíquias logo abaixo (solto sobre o mundo, o número se perdia no chão).
	var gb := UiParch.box("ink", 0.0)
	gb.content_margin_left = 16
	gb.content_margin_right = 16
	gb.content_margin_top = 7
	gb.content_margin_bottom = 8
	UiKit.fit_margins(gb, true)
	gold_label.add_theme_stylebox_override("normal", gb)
	gold_label.add_theme_color_override("font_color", UiParch.INK)
	gold_label.add_theme_constant_override("outline_size", 0)
	gold_label.set_meta("paper", true)
	add_child(gold_label)
	# A bandeja sai de baixo da mão: a mão desce e o elixir vai para um canto (posição em _layout_variant).
	eb.size_flags_horizontal = Control.SIZE_FILL
	add_child(eb)


func _build_messages() -> void:
	info_label = UiKit.label(13, UiKit.MUTED, 3)
	add_child(info_label)
	help_label = UiKit.label(13, Color(0.78, 0.76, 0.86), 3)
	# Peles de papel (16/11/2026): a ajuda do rodapé numa etiqueta de papel, em tinta (antes, cinza sobre o mundo).
	var hb := UiParch.box("ink", 0.0)
	hb.content_margin_left = 12
	hb.content_margin_right = 12
	hb.content_margin_top = 3
	hb.content_margin_bottom = 4
	help_label.add_theme_stylebox_override("normal", hb)
	help_label.add_theme_color_override("font_color", UiParch.INK)
	help_label.set_meta("paper", true)
	# A moldura dupla do papel cortava as letras com 3–4 px de margem.
	hb.content_margin_left = 18
	hb.content_margin_right = 18
	hb.content_margin_top = 8
	hb.content_margin_bottom = 9
	UiKit.fit_margins(hb, true)
	add_child(help_label)
	toast = UiKit.title(30, Color(1, 0.62, 0.45))
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
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cv.add_child(contest_label)
	# Disputa em 3 etapas: marcadores (vencida / atual / por vir), barra da etapa atual e o tempo.
	contest_stages = Control.new()
	contest_stages.custom_minimum_size = Vector2(560, 30)
	contest_stages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contest_stages.draw.connect(_draw_contest_stages)
	contest_stages.visible = false
	cv.add_child(contest_stages)
	contest_panel.add_child(cv)
	contest_panel.visible = false
	# Selo compacto: texto e barra mais estreitos (antes 560 px de largura em duas linhas grossas).
	contest_label.custom_minimum_size = Vector2(430, 0)
	contest_label.add_theme_font_size_override("normal_font_size", 16)
	contest_stages.custom_minimum_size = Vector2(430, 24)
	cv.add_theme_constant_override("separation", 2)
	# No canto, a leitura começa na borda esquerda (texto alinhado à esquerda, mais estreito).
	contest_label.set_meta("center", false)
	contest_label.custom_minimum_size = Vector2(380, 0)
	# Respiro dentro do papel: sem ele o texto encostava na moldura da esquerda.
	var cm := StyleBoxEmpty.new()
	cm.content_margin_left = UiKit.SP_L
	cm.content_margin_right = UiKit.SP_S + 2
	cm.content_margin_top = UiKit.SP_XS
	contest_label.add_theme_stylebox_override("normal", cm)
	contest_stages.custom_minimum_size = Vector2(380, 24)
	add_child(contest_panel)
	banner = BigBanner.new()
	add_child(banner)
	seals = LocSeals.new()
	add_child(seals)
	# Relíquias do covil ganhas na run, em fila no canto de baixo à direita.
	relic_row = VBoxContainer.new()
	# Relíquias são passivas (o fim da hierarquia): só o ícone, em grade de até 290 px; o nome fica na caixa de dica.
	var fl := HFlowContainer.new()
	fl.alignment = FlowContainer.ALIGNMENT_END
	fl.custom_minimum_size = Vector2(290, 0)
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 6)
	relic_row = fl
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
	# Ouro à vista nas ofertas de evento (a pilha da direita some com a oferta; as opções pedem ouro).
	offer_gold = UiKit.label(22, UiKit.GOLD, 4)
	offer_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_gold.visible = false
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
	offer_title.add_theme_font_size_override("font_size", 46)
	v.add_child(UiDiario.tape_title(offer_title))
	v.add_child(UiDiario.tape_wrap(offer_sub, UiDiario.MASK, 1.0))
	var keys_tag := UiDiario.tape_wrap(sub, UiDiario.MASK, -0.8)
	# Folga para o texto não encostar na borda da etiqueta (16/11/2026).
	var ksb := (keys_tag.get_theme_stylebox("panel") as StyleBox).duplicate() as StyleBox
	ksb.content_margin_top = 7
	ksb.content_margin_bottom = 8
	ksb.content_margin_left = 22
	ksb.content_margin_right = 22
	UiKit.fit_margins(ksb, true)
	keys_tag.add_theme_stylebox_override("panel", ksb)
	v.add_child(keys_tag)
	v.add_child(offer_gold)
	v.add_child(offer_scroll)
	v.add_child(offer_skip)
	offer_layer.add_child(v)
	ledger = ShopLedger.new()
	ledger.hud = self
	ledger.chosen.connect(choose_offer)
	offer_layer.add_child(ledger)
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
	var sheet := PanelContainer.new()
	UiDiario.dress(sheet, "paper", 34.0, {"grime": 0.45, "seed": 0.52, "shadow": 10.0, "rough": 2.6})
	sheet.rotation_degrees = -1.0
	sheet.add_child(pause_menu)
	row.add_child(sheet)
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
	# Baralho grande rola dentro de uma caixa de altura limitada (como _fit_offer), em vez de empurrar o painel.
	pause_deck_scroll = ScrollContainer.new()
	pause_deck_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pause_deck_scroll.add_child(pause_deck)
	iv.add_child(pause_deck_scroll)
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
	# Mapa aberto: o covil no alto (anel vermelho na vitória), morros e bosque apoiados na moldura de baixo.
	result_icon = TextureRect.new()
	result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_icon.custom_minimum_size = Vector2(0, 112)
	result_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(result_icon)
	_map_doodle(p, "m-mount", Vector2(150, 62), Vector2(26, 14), false, true)
	_map_doodle(p, "m-bosque", Vector2(130, 56), Vector2(26, 12))
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
	# Segurar 1 s (HoldButton): clicar sem querer na tela de resultado não recomeça nem sai da run.
	var rb := HoldButton.new()
	result_btn = rb
	result_btn.text = "UI_RESTART"
	result_btn.custom_minimum_size = Vector2(280, 56)
	result_btn.add_theme_font_size_override("font_size", 22)
	rb.held.connect(func(): to_menu.emit(true))
	var mb := HoldButton.new()
	mb.text = "UI_MAIN_MENU"
	mb.custom_minimum_size = Vector2(280, 56)
	mb.add_theme_font_size_override("font_size", 22)
	mb.held.connect(func(): to_menu.emit(false))
	br.add_child(result_btn)
	br.add_child(mb)
	v.add_child(br)
	var hold_hint := UiKit.label(16, UiKit.MUTED, 3)
	hold_hint.text = "UI_HOLD_HINT"
	hold_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hold_hint)
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
	help_label.position = Vector2(m, vs.y - 30)
	info_label.position = Vector2(m, vs.y - 56)
	# Faixa de rota em pé na borda esquerda, do painel da run até acima das legendas de rodapé.
	strip.position = Vector2(m, run_panel.position.y + run_panel.size.y + 12)
	strip.size = Vector2(strip.custom_minimum_size.x, maxf(info_label.position.y - 16.0 - strip.position.y, 120.0))
	var below := top + 10   # (a linha foi apagada junto com o painel de contrato e o aviso ainda a usa)
	# O mapa grande cobre a tela inteira (como o mapa do Slay the Spire); a run fica parada por trás.
	if minimap.size != vs:
		minimap.size = vs
	minimap.position = Vector2.ZERO
	parts_panel.position = Vector2(vs.x - parts_panel.size.x - m, tool_row.position.y + tool_row.size.y + 8)
	toast.position = Vector2((vs.x - toast.size.x) * 0.5, vs.y * 0.28)
	contest_panel.size = contest_panel.get_combined_minimum_size()
	contest_panel.position = Vector2((vs.x - contest_panel.size.x) * 0.5, duel.position.y + duel.size.y + 8)
	learn_panel.position = Vector2((vs.x - learn_panel.size.x) * 0.5, duel.position.y + duel.size.y + (contest_panel.size.y + 16.0 if contest_panel.visible else 26))
	relic_row.size = relic_row.get_combined_minimum_size()
	var rel_y := tool_row.position.y + tool_row.size.y + 8
	if parts_panel.visible:
		rel_y = parts_panel.position.y + parts_panel.size.y + 8
	relic_row.position = Vector2(vs.x - relic_row.size.x - m, rel_y)
	hint_panel.position = Vector2((vs.x - hint_panel.size.x) * 0.5, below + 6)
	for layer in [offer_layer, power_layer, pause_layer, result_layer]:
		# O escurecimento cobre a tela inteira (pela âncora ele ficava com tamanho zero e não aparecia).
		layer.position = Vector2.ZERO
		layer.size = vs
		var b: Control = layer.get_node("Box")
		b.position = (vs - b.size) * 0.5
	settings.position = (vs - settings.size) * 0.5
	_layout_variant(vs, m)
	_layout_powers(vs, m)


## Área real da mão: do monte de compra ao de descarte (o retângulo do leque é mais largo que as cartas).
func hand_rect() -> Rect2:
	var fr := fan.get_global_rect()
	var l := fan.deck_pile.get_global_rect().position.x
	var r := fan.disc_pile.get_global_rect().end.x
	return Rect2(l, fr.position.y, r - l, fr.size.y)


## Pares de elementos da HUD visíveis que se sobrepõem (capturas das variações, 17/11/2026). Vazio = nada encavalado.
func overlap_report() -> Array:
	var named := {"grupo": duel, "poderes": power_row, "missao": contest_panel, "relogio": run_panel, "botoes": tool_row, "reliquias": relic_row,
		"elixir": elixir_tray, "mao": fan, "ajuda": help_label, "fps": info_label, "aprendeu": learn_panel, "dica": hint_panel,
		"faixa": strip, "corpo": parts_panel, "ouro": gold_label, "aviso": toast}
	var out: Array = []
	var keys := named.keys()
	for i in keys.size():
		var a: Control = named[keys[i]]
		if a == null or not a.is_visible_in_tree():
			continue
		var ra := hand_rect() if a == fan else a.get_global_rect()
		if not get_viewport_rect().encloses(ra):
			out.append("%s sai da tela %s" % [keys[i], ra])
		for j in range(i + 1, keys.size()):
			var b: Control = named[keys[j]]
			if b == null or not b.is_visible_in_tree():
				continue
			var inter := ra.intersection(hand_rect() if b == fan else b.get_global_rect())
			if inter.size.x > 2.0 and inter.size.y > 2.0:
				out.append("%s x %s (%dx%d)" % [keys[i], keys[j], int(inter.size.x), int(inter.size.y)])
	return out


## Posição do grupo, do objetivo e dos avisos (disposição de 17/11/2026, em _layout_7).
func _layout_variant(vs: Vector2, m: float) -> void:
	strip.visible = false
	# Sem o relógio (pedido de 17/11/2026): o tempo da run fica só na pausa.
	run_panel.visible = false
	duel.size = duel.get_combined_minimum_size()
	contest_panel.size = contest_panel.get_combined_minimum_size()
	_layout_7(vs, m)
	var top_end := duel.position.y + duel.size.y   # onde acaba o que está no alto, no meio da tela (para os avisos)
	learn_panel.position = Vector2((vs.x - learn_panel.size.x) * 0.5, top_end + 10.0)
	hint_panel.position = Vector2((vs.x - hint_panel.size.x) * 0.5, top_end + (learn_panel.size.y + 20.0 if learn_panel.visible else 10.0))


## Disposição da HUD (17/11/2026):
## alto à esquerda = missão (só quando há); alto ao centro = vida do grupo, centrada no meio da tela sempre (não pula
## quando a missão aparece); alto à direita = botões, ouro, corpo do chefe e relíquias, empilhados; borda direita
## embaixo = coluna do elixir, que cresce só até onde a pilha da direita deixa; embaixo no centro = a mão.
func _layout_7(vs: Vector2, m: float) -> void:
	contest_panel.position = Vector2(m, m)
	var lo := contest_panel.position.x + contest_panel.size.x + 12.0 if contest_panel.visible else m
	var right_edge := tool_row.position.x - 12.0
	duel.position = Vector2(clampf((vs.x - duel.size.x) * 0.5, lo, maxf(right_edge - duel.size.x, lo)), 10.0)
	help_label.position = Vector2(m, (contest_panel.position.y + contest_panel.size.y if contest_panel.visible else m) + 8.0)
	# Pilha da direita: botões > ouro > corpo do chefe > relíquias.
	gold_label.size = gold_label.get_combined_minimum_size()
	var y := tool_row.position.y + tool_row.size.y + 6.0
	gold_label.position = Vector2(vs.x - gold_label.size.x - m - 4.0, y)
	gold_label.visible = bottom_box.visible
	if gold_label.visible:
		y = gold_label.position.y + gold_label.size.y + 6.0
	if parts_panel.visible:
		parts_panel.position = Vector2(vs.x - parts_panel.size.x - m, y)
		y = parts_panel.position.y + parts_panel.size.y + 8.0
	relic_row.position = Vector2(vs.x - relic_row.size.x - m, y)
	if relic_row.get_child_count() > 0:
		y = relic_row.position.y + relic_row.size.y + 8.0
	# Coluna do elixir: presa embaixo; os gomos encolhem para caber sob a pilha (de 150 a 330 px).
	var floor_y := vs.y - 24.0
	var extra := elixir_tray.get_combined_minimum_size().y - elixir_bar.custom_minimum_size.y
	var bar_h := clampf(floor_y - (y + 14.0) - extra, 200.0, 330.0)
	if absf(elixir_bar.custom_minimum_size.y - bar_h) > 1.0:
		elixir_bar.custom_minimum_size.y = bar_h
	elixir_tray.size = elixir_tray.get_combined_minimum_size()
	elixir_tray.position = Vector2(vs.x - elixir_tray.size.x - m - 6.0, floor_y - elixir_tray.size.y)
	elixir_tray.visible = bottom_box.visible
	bottom_box.position.y = vs.y - bottom_box.size.y - 14.0


# ---------------------------------------------------------------- estado

func show_run(on: bool) -> void:
	visible = on
	if not on:
		sim = null
		offer_layer.visible = false
		power_layer.visible = false
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
	# Variações de 17/11/2026: sem a faixa de rota; a rota fica só no mapa (M).
	strip.visible = false
	minimap.visible = false
	parts_panel.visible = false
	UiKit.clear(parts_box)
	part_rows.clear()
	result_layer.visible = false
	pause_layer.visible = false
	minimap.setup(s)
	strip.setup(s)
	fan.bind(s)
	_sync_upgrades()
	Tips.close_all()


## O baralho da pausa nunca passa de ~45% da altura da tela: depois de um quadro (a grade já mediu), a rolagem
## recebe a altura do conteúdo limitada a isso e a largura da grade (+ barra); o resto rola.
func _fit_pause_deck() -> void:
	pause_deck_scroll.custom_minimum_size = Vector2.ZERO
	await get_tree().process_frame
	if not is_instance_valid(pause_deck_scroll):
		return
	var vs := get_viewport_rect().size
	var content := pause_deck.get_combined_minimum_size()
	var max_h := maxf(vs.y * 0.45, 160.0)
	var scrolls := content.y > max_h
	pause_deck_scroll.custom_minimum_size = Vector2(content.x + (14.0 if scrolls else 0.0), minf(content.y, max_h))


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
		art.texture = UiDiario.hand_art(ci.def.id)
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
	_fit_pause_deck()
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
	if sim.phase == K.Phase.ARENA:
		hint("arena")
	var h := Vector2(sim.hero.x, sim.hero.y)
	for loc in sim.road.locations:
		if loc["type"] == "shrine" and loc["state"] == SimRoad.LocState.ACTIVE and h.distance_to(loc["pos"]) < 45.0:
			hint("shrine")
		if loc["type"] == "helper" and loc["state"] == SimRoad.LocState.ACTIVE and h.distance_to(loc["pos"]) < 45.0 and sim.road.is_on_route(loc):
			hint("helper")
	for ci in sim.hand:
		if ci and ci.def.category == "route":
			hint("route")


## Ponto da tela onde soltar uma carta não vale: fora da janela ou em cima de uma peça sólida da HUD.
func blocks_world(p: Vector2) -> bool:
	if not get_viewport().get_visible_rect().has_point(p):
		return true
	# Painéis da HUD 7 (17/11/2026): soltar a carta em cima do grupo, da missão ou das relíquias cancela, como nos botões.
	for c in [hero_badge, elixir_tray, tool_row, gold_label, duel, contest_panel, relic_row, power_row]:
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
	_refresh_powers()
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


## Cartas liberadas nesta fase: revelação por cima do resultado; sem nenhuma, uma linha "Quase lá" no resultado.
func _show_unlocks() -> void:
	if is_instance_valid(unlock_near):
		unlock_near.queue_free()
	if unlock_result.is_empty():
		return
	var rv := UnlockReveal.build(sim.data, unlock_result)
	if rv != null:
		add_child(rv)
		rv.finished.connect(func(): result_btn.grab_focus.call_deferred())
		return
	var txt := UnlockReveal.near_text(unlock_result)
	if txt != "":
		unlock_near = UiKit.label(15, UiKit.MUTED, 3)
		unlock_near.text = txt
		unlock_near.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_grid.get_parent().add_child(unlock_near)
		result_grid.get_parent().move_child(unlock_near, result_grid.get_index() + 1)


func _refresh_top() -> void:
	var h := sim.hero
	(hero_badge.get_node("N") as Label).text = str(h.level)
	_curse_hatch(hero_hp, h)
	hero_hp.value = h.hp
	hero_hp_label.text = "%d / %d" % [int(h.hp), int(h.max_hp())]
	hero_of_label.text = tr("UI_HERO_OF").format({"k": sim.party_idx + 1, "n": sim.party_size()}) + " · " + tr("HERO_" + sim.hero.cls())
	if sim.party_mode():
		hero_of_label.text = tr("UI_PARTY_OF").format({"k": sim.cur_party + 1, "n": sim.party_count()}) + " · " + tr("UI_FALLEN_OF").format({"k": sim.group_falls, "n": sim.party_size()})
	_refresh_party()
	hero_hp.visible = not party_box.visible
	var standing := 1 + sim.followers.size()
	hero_title.text = tr("UI_HERO_PARTY") if standing > 1 else tr("HERO_" + sim.hero.cls()).to_upper()
	# Barra de chefe (17/11/2026): com party, o título "A PARTY" e a lista "(Clériga 80%...)" repetiam as barras.
	hero_title.visible = not party_box.visible
	hero_name_row.visible = hero_title.visible or h.curses > 0
	if sim.group_mode() and not party_box.visible:
		hero_of_label.text += " · " + tr("UI_HEROES_STANDING").format({"n": 1 + sim.followers.size()})
		var fl: Array = []
		for f in sim.followers:
			fl.append("%s %d%%" % [tr("HERO_" + f.cls()), int(round(100.0 * f.hp / maxf(f.max_hp(), 1.0)))])
		if fl.size() > 0:
			hero_of_label.text += " (" + ", ".join(fl) + ")"
	_refresh_upgrades()
	curse_label.text = tr("UI_CURSES").format({"n": h.curses}) if h.curses > 0 else ""


## Barreira (ward) como camada azul na barra de vida: começa onde a vida termina e, se passa da ponta, encosta na direita.
func _ward_layer(bar: ProgressBar, h: SimHero) -> void:
	var o := bar.get_node_or_null("WardLayer") as Control
	if o == null:
		o = Control.new()
		o.name = "WardLayer"
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		o.set_anchors_preset(Control.PRESET_FULL_RECT)
		o.draw.connect(func() -> void:
			var w: float = float(o.get_meta("ward", 0.0))
			if w <= 0.0:
				return
			var sz := o.size
			var base: float = maxf(float(o.get_meta("base", 1.0)), 1.0)
			var x0: float = clampf(float(o.get_meta("hp", 0.0)) / base, 0.0, 1.0) * sz.x
			var x1: float = minf(x0 + w / base * sz.x, sz.x)
			x0 = maxf(minf(x0, x1 - minf(w / base * sz.x, sz.x)), 0.0)
			var r := Rect2(x0, 1.0, maxf(x1 - x0, 2.0), sz.y - 2.0)
			# Corpo em degradê vertical (gelo): escuro embaixo, claro em cima.
			var bands := 6
			for i in bands:
				var t := float(i) / float(bands - 1)
				var c := Color(0.62, 0.88, 1.0, 0.92).lerp(Color(0.22, 0.45, 0.85, 0.92), t)
				var bh := r.size.y / float(bands)
				o.draw_rect(Rect2(r.position.x, r.position.y + bh * i, r.size.x, bh + 0.5), c)
			# Listras diagonais de brilho, recortadas na faixa.
			var step := 7.0
			var sx := r.position.x - r.size.y
			while sx < r.end.x:
				var a := Vector2(sx, r.end.y)
				var b := Vector2(sx + r.size.y, r.position.y)
				var ca := clampf(a.x, r.position.x, r.end.x)
				var cb := clampf(b.x, r.position.x, r.end.x)
				if cb > ca:
					var ya := r.end.y - (ca - a.x)
					var yb := r.end.y - (cb - a.x)
					o.draw_line(Vector2(ca, ya), Vector2(cb, yb), Color(1, 1, 1, 0.22), 2.0)
				sx += step
			# Faixa de luz no topo e linha escura na base.
			o.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, maxf(r.size.y * 0.22, 1.0)), Color(1, 1, 1, 0.45))
			o.draw_rect(Rect2(r.position.x, r.end.y - 1.0, r.size.x, 1.0), Color(0.05, 0.15, 0.4, 0.6))
			o.draw_rect(r, Color(0.92, 0.98, 1.0, 0.95), false, 1.5)
			# Brasão de escudo na ponta direita da faixa.
			var hh := sz.y - 2.0
			if hh >= 8.0 and r.size.x >= hh * 0.9:
				var cx := r.end.x - hh * 0.5
				var cy := sz.y * 0.5
				var s := hh * 0.5
				var pts := PackedVector2Array([
					Vector2(cx - s * 0.8, cy - s * 0.85), Vector2(cx + s * 0.8, cy - s * 0.85),
					Vector2(cx + s * 0.8, cy + s * 0.1), Vector2(cx, cy + s * 1.0),
					Vector2(cx - s * 0.8, cy + s * 0.1)])
				var inner := PackedVector2Array()
				for p in pts:
					inner.append(Vector2(cx, cy) + (p - Vector2(cx, cy)) * 0.62)
				o.draw_colored_polygon(pts, Color(0.06, 0.16, 0.42, 0.95))
				o.draw_colored_polygon(inner, Color(0.8, 0.95, 1.0, 0.98))
				var closed := pts.duplicate()
				closed.append(pts[0])
				o.draw_polyline(closed, Color(1, 1, 1, 0.95), 1.2))
		bar.add_child(o)
	if absf(float(o.get_meta("ward", -1.0)) - h.ward) > 0.01 or absf(float(o.get_meta("hp", -1.0)) - h.hp) > 0.01:
		o.set_meta("ward", h.ward)
		o.set_meta("hp", h.hp)
		o.set_meta("base", h.base_hp)
		o.queue_redraw()


## Vida tirada pelas Maldições: a barra mede a vida sem maldição e a ponta direita fica riscada (verde-veneno),
## mostrando o quanto elas já tiraram. Sem maldição, a faixa some.
func _curse_hatch(bar: ProgressBar, h: SimHero) -> void:
	_ward_layer(bar, h)
	bar.max_value = h.base_hp
	var cut := clampf(1.0 - h.max_hp() / maxf(h.base_hp, 1.0), 0.0, 1.0)
	var o := bar.get_node_or_null("CurseHatch") as Control
	if o == null:
		o = Control.new()
		o.name = "CurseHatch"
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		o.clip_contents = true
		o.anchor_top = 0.0
		o.anchor_bottom = 1.0
		o.anchor_right = 1.0
		o.offset_left = 0.0
		o.offset_right = 0.0
		o.offset_top = 0.0
		o.offset_bottom = 0.0
		o.draw.connect(func() -> void:
			var sz := o.size
			var line := Color(0.75, 1.0, 0.55, 0.85)
			o.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.05, 0.02, 0.07, 0.8))
			var x := -sz.y
			while x < sz.x:
				o.draw_line(Vector2(x, sz.y), Vector2(x + sz.y, 0.0), line, 1.5)
				x += 6.0
			o.draw_line(Vector2.ZERO, Vector2(0.0, sz.y), line, 2.0))
		bar.add_child(o)
		bar.move_child(o, 0)   # atrás do número da vida
	o.visible = cut > 0.0
	o.anchor_left = 1.0 - cut
	o.queue_redraw()


## Vida de cada herói da party em campo: uma linha por herói de pé, o líder primeiro. Só aparece com mais de um.
func _refresh_party() -> void:
	var members: Array = [sim.hero] + sim.followers
	party_box.visible = members.size() > 1
	var same := party_rows.size() == members.size()
	if same:
		for i in members.size():
			if party_rows[i]["h"] != members[i]:
				same = false
				break
	if not same:
		UiKit.clear(party_box)
		party_rows.clear()
		if members.size() > 1:
			for i in members.size():
				var row: BoxContainer = VBoxContainer.new()
				row.add_theme_constant_override("separation", 1)
				row.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var lead := i == 0
				var nm := UiKit.label(13, UiKit.TEXT if i == 0 else UiKit.MUTED, 3)
				nm.custom_minimum_size = Vector2(0, 0)
				nm.text = ("▶ " if i == 0 else "") + tr("HERO_" + (members[i] as SimHero).cls())
				row.add_child(nm)
				var bw := 140.0 if lead else 112.0
				var bar := UiKit.bar(UiKit.HERO_HP, bw, 16)
				var lab := UiKit.label(13 if lead else 12, Color.WHITE, 3)
				# Mesma letra e mesma altura de barra para todos (o líder se distingue pela barra mais larga e pelo ▸):
				# nomes e barras alinham numa linha só. Número claro com contorno, como a barra do herói sozinho.
				UiParch.style_label(nm, "bold" if i == 0 else "body", 14, UiParch.INK if i == 0 else UiParch.INK.lightened(0.25))
				UiParch.style_label(lab, "bold", 13, UiParch.CREAM)
				lab.add_theme_constant_override("outline_size", 4)
				lab.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.02, 0.9))
				lab.set_anchors_preset(Control.PRESET_FULL_RECT)
				lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				bar.add_child(lab)
				row.add_child(bar)
				party_box.add_child(row)
				party_rows.append({"h": members[i], "bar": bar, "lab": lab})
	for r in party_rows:
		var h: SimHero = r["h"]
		_curse_hatch(r["bar"] as ProgressBar, h)
		(r["bar"] as ProgressBar).value = h.hp
		(r["lab"] as Label).text = "%d" % int(h.hp)


## Fileira de ícones das habilidades. Habilidade nova: ícone pulsa e o aviso aparece (sem pausar).
func _refresh_upgrades() -> void:
	var order: Array = sim.hero.upgrade_order
	while upg_shown < order.size():
		var ic := _add_upgrade_icon(order[upg_shown])
		ic.pulse = 4.0
		_announce(order[upg_shown])
		upg_shown += 1
	upg_none.visible = false
	upg_row.visible = not order.is_empty()
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
	head.text = tr("UI_HERO_LEARNED")
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
	# Disputa difícil (11/11/2026): alcançar os 3 marcos também dá uma relíquia.
	var hard: bool = c.has("li") and sim.road.locations[int(c["li"])].get("hard", false)
	txt = _mission_text(txt, int(ceil(float(c["window"]) - float(c["t"]))), hard)
	contest_stages.visible = true
	contest_stages.queue_redraw()
	if txt != contest_text:
		contest_text = txt
		Tips.set_text(contest_label, txt)


## Missão no canto (17/11/2026): o nome do local em destaque e, embaixo, o que fazer. O tempo fica só na barra
## de marcos (antes aparecia no texto e na barra); a regra da disputa difícil vira uma linha menor por último.
func _mission_text(txt: String, secs: int, hard: bool) -> String:
	txt = txt.trim_suffix(" · %d s" % secs)
	var k := txt.find(": ")
	var head := txt.substr(0, k) if k > 0 else ""
	var body := txt.substr(k + 2) if k > 0 else txt
	if hard:
		head = "☠ " + (head if head != "" else tr("UI_CONTEST_HARD").get_slice(":", 0).trim_prefix("☠ "))
	var out := ("[b][color=#%s]%s[/color][/b]
" % [UiKit.GOLD.to_html(false), head] if head != "" else "") + body
	if hard:
		out += "
[font_size=13]%s[/font_size]" % tr("UI_CONTEST_HARD").trim_prefix("☠ ")
	return out


## Barra única da disputa (12/11/2026): enche até o 3º marco; cada marco é um círculo na barra (cheio e verde = alcançado,
## anel dourado = o próximo). À direita, o tempo que resta.
func _draw_contest_stages() -> void:
	var c := sim.contest
	if not c.has("marks"):
		return
	var marks: Array = c["marks"]
	var goal := maxf(float(c.get("goal", 1.0)), 0.001)
	var reached := int(c.get("won", 0))
	var font := ThemeDB.fallback_font
	var ci := contest_stages
	var h := ci.size.y
	var r := h * 0.46
	var left := maxf(float(c.get("window", 0.0)) - float(c.get("t", 0.0)), 0.0)
	var ttxt := "%d s" % int(ceil(left))
	var tw := font.get_string_size(ttxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var bx := r + 2.0
	var bw := maxf(ci.size.x - bx - tw - 14.0 - r, 40.0)
	var br := Rect2(bx, h * 0.5 - 7.0, bw, 14.0)
	var f := clampf(float(c.get("progress", 0.0)) / goal, 0.0, 1.0)
	ci.draw_rect(br, Color(0, 0, 0, 0.6))
	ci.draw_rect(Rect2(br.position, Vector2(br.size.x * f, br.size.y)), UiKit.GOLD)
	ci.draw_rect(br, Color(1, 0.9, 0.6, 0.5), false, 1.0)
	if marks.size() > 1:
		for i in marks.size():
			var ctr := Vector2(bx + bw * clampf(float(marks[i]) / goal, 0.0, 1.0), h * 0.5)
			if i < reached:
				ci.draw_circle(ctr, r, UiKit.GOOD)
				ci.draw_string(font, ctr + Vector2(-5, 6), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.05, 0.1, 0.05))
			elif i == reached:
				ci.draw_circle(ctr, r, Color(0.2, 0.15, 0.05))
				ci.draw_arc(ctr, r, 0, TAU, 28, UiKit.GOLD, 3.0, true)
				ci.draw_string(font, ctr + Vector2(-4, 6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.GOLD)
			else:
				ci.draw_circle(ctr, r, Color(0.1, 0.08, 0.08, 0.85))
				ci.draw_arc(ctr, r, 0, TAU, 28, Color(0.6, 0.55, 0.5, 0.7), 2.0, true)
				ci.draw_string(font, ctr + Vector2(-4, 6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.55, 0.5, 0.8))
	ci.draw_string(font, Vector2(br.end.x + r + 8.0, h * 0.5 + 6.0), ttxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UiKit.BAD if left <= 5.0 else UiKit.TEXT)


func _refresh_relics() -> void:
	if relic_row.get_child_count() == sim.relics.size():
		return
	UiKit.clear(relic_row)
	for id in sim.relics:
		var rid: String = id
		# Etiqueta de papel com o losango dourado (antes: texto vermelho solto que passava por cima do herói).
		var tag := PanelContainer.new()
		var sb := UiParch.box("ink", 0.0)
		sb.content_margin_left = 10
		sb.content_margin_right = 12
		sb.content_margin_top = 3
		sb.content_margin_bottom = 4
		UiKit.fit_margins(sb, true)
		tag.set_meta("tag", true)
		tag.add_theme_stylebox_override("panel", sb)
		tag.set_meta("paper", true)
		tag.size_flags_horizontal = Control.SIZE_SHRINK_END
		tag.mouse_filter = Control.MOUSE_FILTER_STOP
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(UiKit.relic_icon(rid, 28.0))
		sb.content_margin_left = UiKit.SP_S
		sb.content_margin_right = UiKit.SP_S
		UiKit.fit_margins(sb, true)
		tag.add_child(row)
		Tips.attach(tag, func(): return [Tips.entry(tr("REL_" + rid), tr("RELD_" + rid))])
		relic_row.add_child(tag)
		continue
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 4)
		hb.mouse_filter = Control.MOUSE_FILTER_STOP
		hb.add_child(UiKit.relic_icon(rid, 24.0))
		var b := UiKit.label(14, UiKit.GOLD, 3)
		b.text = tr("REL_" + str(id))
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(b)
		Tips.attach(hb, func(): return [Tips.entry(tr("REL_" + rid), tr("RELD_" + rid))])
		relic_row.add_child(hb)


## Eventos da simulação que viram aviso na tela (disputa, ato).
func handle_events(evs: Array) -> void:
	for e in evs:
		match int(e[0]):
			K.Ev.POWER_TRIGGER:
				power_flash[int(e[3])] = "trigger"
			K.Ev.POWER_READY:
				if not power_flash.has(int(e[3])):
					power_flash[int(e[3])] = "ready"
			K.Ev.POWER_GAINED:
				power_flash[int(e[3])] = "gained"
			K.Ev.CONTEST:
				var code := int(e[4])
				if code == 0 and sim.contest.size() > 0:
					# Chegou no local: o objetivo bate grande no meio e voa para o painel da disputa no topo.
					var c := sim.contest
					var f := {"g": int(c["goal"]), "s": int(ceil(float(c["window"])))}
					var dock := Vector2(get_viewport_rect().size.x * 0.5, duel.position.y + duel.size.y + 26.0)
					banner.show_banner(tr("UI_GOAL_" + str(c["type"])).format(f), tr("UI_GOALSUB_" + str(c["type"])).format(f), UiKit.GOLD, dock)
				elif code >= 3 and code <= 5:
					banner.show_banner(tr("UI_BANNER_MARK").format({"n": code - 2}), "", Color(0.55, 1.0, 0.55), Vector2(-1, -1), 0.5)
				elif code == 1:
					banner.show_banner(tr("UI_BANNER_WON"), tr("UI_CONTEST_WON"), Color(0.55, 1.0, 0.55), Vector2(-1, -1), 0.8)
				elif code >= 11:
					banner.show_banner(tr("UI_BANNER_PARTIAL").format({"n": code - 10}), "", UiKit.GOLD, Vector2(-1, -1), 0.7)
				elif code < 0:
					var lost_sub := tr("UI_CONTEST_LOST")
					var lloc: Dictionary = sim.road.locations[int(e[3])] if int(e[3]) < sim.road.locations.size() else {}
					if lloc.get("type", "") == "helper":
						lost_sub = tr("UI_HELPER_LOST")
					banner.show_banner(tr("UI_BANNER_LOST"), lost_sub, Color(1.0, 0.45, 0.4), Vector2(-1, -1), 0.6)
			K.Ev.LOCATION:
				# Chegada na loja e na encruzilhada: o nome do local bate no meio durante a cena de chegada.
				var ali := int(e[3])
				if ali >= 0 and ali < sim.road.locations.size():
					var aty := str(sim.road.locations[ali]["type"])
					if aty == "shop" or aty == "event":
						banner.show_banner(tr("LOC_" + aty).replace("?", "").strip_edges(), "", UiKit.GOLD, Vector2(-1, -1), 0.6)
			K.Ev.ACT_START:
				banner.show_banner(tr("UI_ACT_OF").format({"n": int(e[3]) + 1, "m": sim.acts()}), "", UiKit.GOLD, Vector2(-1, -1), 1.0)


func _refresh_offer() -> void:
	var on := sim.offers.size() > 0 and not hold_offers
	var is_power: bool = on and str(sim.offers[0]["source"]) == "power"
	offer_layer.visible = on and not is_power
	power_layer.visible = is_power
	var shop_ui: bool = on and (sim.offers[0]["source"] == "shop" or sim.offers[0]["source"] == "shop_pick")
	# Saiu da loja: o cursor do livro não pode virar a carta selecionada da mão.
	if ledger.visible and not shop_ui:
		selected = -1
	ledger.visible = shop_ui
	if not on:
		offer_sig = ""
		power_panel_sig = ""
		return
	if is_power:
		offer_sig = ""
		_refresh_power_panel(sim.offers[0])
		return
	var o: Dictionary = sim.offers[0]
	# Loja e escolha da carta do serviço: o livro-caixa desenha tudo (sem a caixa de ofertas comum).
	(offer_layer.get_node("Box") as Control).visible = not shop_ui
	offer_rays.visible = not shop_ui
	if shop_ui:
		offer_sig = ""
		offer_obj = null
		ledger.sync(sim, o)
		return
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


## Escolha de oferta pelo teclado, controle ou livro-caixa. Na loja, o livro confere antes: sem ouro ele avisa
## (linha treme, ouro pisca) e nada vai ao Sim. `reset` solta o cursor depois (controle, fora da loja).
func choose_offer(k: int, reset := false) -> void:
	if sim == null or sim.offers.is_empty():
		return
	var shop_ui: bool = sim.offers[0]["source"] == "shop" or sim.offers[0]["source"] == "shop_pick"
	if shop_ui and not ledger.before_choose(k):
		return
	offer_chosen.emit(k)
	if reset and not shop_ui:
		selected = -1


## Pontos da tela para o teste com o mouse escolher a opção k (SKIP: sair/voltar). Vazio: a opção não está à vista.
func offer_click_points(k: int) -> Array:
	if power_layer.is_visible_in_tree():
		return [power_continue.get_global_transform() * (power_continue.size * 0.5)]
	if ledger.is_visible_in_tree():
		return ledger.click_points(k)
	if k == Sim.SKIP:
		return [offer_skip.get_global_transform() * (offer_skip.size * 0.5)]
	if k < offer_slots.size():
		var c: Control = offer_slots[k].get_meta("card", null)
		if c:
			return [c.get_global_transform() * (c.size * 0.5)]
	return []


func offer_ready() -> bool:
	if power_layer.is_visible_in_tree():
		return power_continue.is_visible_in_tree()
	return ledger.is_visible_in_tree() or (offer_slots.size() > 0 and offer_skip.is_visible_in_tree())


## Carta só de texto (relíquia, opção de evento): título e descrição numa moldura.
func _text_card(title: String, body: String, w: float, edge: Color, relic_id := "") -> PanelContainer:
	var cp := UiKit.panel(UiKit.BG, edge, 14)
	cp.custom_minimum_size = Vector2(w, 246.0 * w / 168.0)
	var pv := VBoxContainer.new()
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.add_theme_constant_override("separation", 12)
	if relic_id != "":
		pv.add_child(UiKit.relic_icon(relic_id, w * 0.42))   # ícone da relíquia em cima do nome (15/11/2026)
	var pt := UiKit.title(24, edge.lightened(0.3))
	pt.text = title
	pt.autowrap_mode = TextServer.AUTOWRAP_WORD
	pt.custom_minimum_size = Vector2(w - 30.0, 0)
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pt)
	var bl := Tips.label(body, 16, UiKit.TEXT, w - 30.0, true)
	# 13/11/2026: título em Fell SC na cor da raridade, filete dourado e texto maior (lia pequeno no centro da carta).
	UiParch.style_label(pt, "title", 27, edge.darkened(0.25) if edge.get_luminance() > 0.35 else edge)
	UiParch.style_label(bl, "body", 19, UiParch.INK)
	var dv := UiParch.divider(w * 0.55)
	dv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pv.add_child(dv)
	pv.add_child(bl)
	UiKit.ignore_mouse(pv)
	cp.add_child(pv)
	return cp


func _offer_heading(o: Dictionary) -> String:
	if o["source"] == "location":
		return tr("UI_OFFER_LOC_" + str(o["loc"]))
	if o["source"] == "relic" and o.get("from", "") == "helper":
		return tr("UI_OFFER_RELIC_HELPER")
	if o["source"] == "relic":
		return tr("UI_OFFER_RELIC").format({"a": int(o.get("act", 0)) + 1})
	if o["source"] == "act_card":
		return tr("UI_OFFER_ACT_CARD").format({"a": int(o.get("act", 0)) + 1})
	if o["source"] == "event":
		return tr("EVT_" + str(o["event"])) if o.has("event") else tr("UI_OFFER_EVENT_STEP")
	if o["source"] == "give":
		return tr("UI_OFFER_GIVE")
	# "level" é a recompensa de queda: vem a cada herói que cai (o id interno ficou do tempo do XP).
	return tr({"level": "UI_OFFER_FALL", "shrine": "UI_OFFER_SHRINE"}[o["source"]])


func _inst(uid: int) -> Sim.CardInst:
	for ci in sim.cards:
		if ci.uid == uid:
			return ci
	return null


func _inst_level(uid: int) -> int:
	for ci in sim.cards:
		if ci.uid == uid:
			return ci.level
	return 1


func _build_offer_options(o: Dictionary) -> void:
	offer_title.text = _offer_heading(o)
	offer_sub.visible = o["source"] == "location" or o.has("event")
	offer_sub.get_parent().visible = offer_sub.visible
	if o.has("event"):
		offer_sub.text = tr("EVT_%s_BODY" % str(o["event"]))
		offer_sub.add_theme_color_override("font_color", UiKit.TEXT)
	elif offer_sub.visible:
		var won: bool = o["won"]
		offer_sub.text = tr("UI_OFFER_MARK").format({"a": int(o.get("mark", 3))}) if o.has("mark") else tr("UI_OFFER_WON" if won else "UI_OFFER_LOST")
		offer_sub.add_theme_color_override("font_color", UiKit.GOOD if won else UiKit.GOLD)
	offer_skip.text = tr("UI_OFFER_CONTINUE" if o["source"] == "give" else "UI_OFFER_SKIP")
	offer_gold.visible = o["source"] == "event"
	offer_gold.text = tr("UI_GOLD").format({"g": int(sim.gold)})
	offer_keys.text = tr("UI_OFFER_KEYS")
	UiKit.clear(offer_box)
	offer_slots.clear()
	var opts: Array = o["options"]
	# Remover "qualquer carta" mostra o deck inteiro: cartas menores, em linhas. (A loja é o ShopLedger.)
	var w := 220.0 if opts.size() <= 4 else 150.0
	var cols := mini(opts.size(), 4 if w > 200.0 else 7)
	var vs := get_viewport_rect().size
	# Subir de nível mostra a carta antes e depois (duas cartas por opção): no máximo 3 por linha e cartas menores.
	var any_up := false
	for it in opts:
		var ik: Dictionary = it["item"] if it.has("item") else it
		if str(ik.get("kind", "")) == "upgrade":
			any_up = true
	if any_up:
		cols = mini(cols, 3)
		w = minf(maxf(w, 200.0), floorf(((vs.x - 140.0 - 22.0 * (cols - 1)) / cols - 14.0)))
	var rows: Array = []
	for k in opts.size():
		var op: Dictionary = opts[k]
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override("separation", 6)
		var head := UiKit.label(18 if w > 200.0 else 14, UiKit.GOLD)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.custom_minimum_size = Vector2(w, 0)
		head.autowrap_mode = TextServer.AUTOWRAP_WORD
		var foot := Tips.label("", 14, Color(0.92, 0.88, 1.0), w, true)
		var key := str(k + 1) if k < 9 else ""
		var cp: PanelContainer
		var pair_node: Control = null   # upgrade: antes -> depois no lugar da carta sozinha
		var cd: CardDef
		var lv := 1
		var mids: Array = []
		match str(op["kind"]):
			"card":
				cd = sim.data.card(op["id"])
				# Ofertas podem vir já melhoradas (rodada 11/11/2026): o nível vem na opção.
				lv = int(op.get("level", 1))
				head.text = tr("UI_OPT_NEW").format({"r": tr("RARITY_" + K.RARITIES[cd.rarity])})
				head.add_theme_color_override("font_color", UiKit.RARITY_COLORS[cd.rarity].lightened(0.4))
				cp = UiKit.card(cd, cd.cost_at(lv), [], key, w, lv)
			"mod":
				cd = sim.data.card(str(op["card"]))
				lv = _inst_level(int(op["uid"]))
				var mci := _inst(int(op["uid"]))
				mids = (UiKit.mod_ids(mci) if mci else []) + [str(op["mod"])]
				head.text = tr("UI_OPT_MOD_HEAD").format({"mod": tr("MOD_" + str(op["mod"]))})
				# Barato já mostra o custo novo na carta (gema azul-água); os modificadores já na carta continuam.
				var mc := (sim.card_cost(mci) if mci else cd.cost_at(lv)) - (1 if str(op["mod"]) == "cheap" else 0)
				var mnames: Array = (UiKit.mod_names(mci) if mci else []) + [tr("MOD_" + str(op["mod"]))]
				cp = UiKit.card(cd, maxi(mc, 0), mnames, key, w, lv)
				Tips.set_text(foot, "[[%s]]: %s" % [op["mod"], tr("MODDESC_" + str(op["mod"]))])
			"upgrade":
				cd = sim.data.card(str(op["card"]))
				lv = int(op["level"]) + 1
				head.text = tr("UI_OPT_UP_HEAD").format({"a": lv - 1, "b": lv})
				head.add_theme_color_override("font_color", UiKit.GOOD)
				var uci := _inst(int(op["uid"]))
				mids = UiKit.mod_ids(uci) if uci else []
				var ucost := cd.cost_at(lv)
				if uci:
					ucost = maxi(sim.card_cost(uci) + cd.cost_at(lv) - cd.cost_at(uci.level), 0)
				cp = UiKit.card(cd, ucost, UiKit.mod_names(uci) if uci else [], key, w, lv)
				# Só o "depois" em tamanho cheio; o que mudou vem em linhas embaixo (Opção A, 12/11/2026).
				var ch := UiKit.level_changes(cd, lv - 1, lv).replace(" · ", "\n")
				if lv >= CardDef.N3_LEVEL and cd.n3.size() > 0:
					ch += ("
" if ch != "" else "") + tr("UI_OPT_UP_N3")
				foot.add_theme_font_size_override("normal_font_size", 18)
				Tips.set_text(foot, ch)
			"remove":
				cd = sim.data.card(str(op["card"]))
				lv = int(op.get("level", 1))
				head.text = tr("UI_OPT_REMOVE_HEAD")
				head.add_theme_color_override("font_color", UiKit.BAD)
				var rci := _inst(int(op.get("uid", -1)))
				mids = UiKit.mod_ids(rci) if rci else []
				cp = UiKit.card(cd, sim.card_cost(rci) if rci else cd.cost_at(lv), UiKit.mod_names(rci) if rci else [], key, w, lv)
				cp.modulate = Color(1.0, 0.6, 0.6)
				# Sempre à vista (também nas cartas pequenas do deck inteiro), com o texto da carta.
				Tips.set_text(foot, tr("UI_OPT_REMOVE").format({"card": UiKit.card_name(cd, lv)}) + "
" + UiKit.card_desc(cd, lv))
			"pick":
				head.text = tr("UI_OPT_PICK_HEAD")
				cp = UiKit.panel(UiKit.BG, UiKit.GOLD, 14)
				cp.custom_minimum_size = Vector2(w, 246.0 * w / 168.0)
				var pv := VBoxContainer.new()
				pv.alignment = BoxContainer.ALIGNMENT_CENTER
				pv.add_theme_constant_override("separation", 12)
				var pt := UiKit.title(30, UiKit.GOLD)
				pt.text = tr("UI_PICK_" + str(op["what"]))
				pt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				pt.custom_minimum_size = Vector2(w - 20.0, 0)
				pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				pv.add_child(pt)
				pv.add_child(Tips.label(tr("UI_PICKD_" + str(op["what"])), 16, UiKit.TEXT, w - 30.0, true))
				UiKit.ignore_mouse(pv)
				cp.add_child(pv)
			"relic":
				var rel: Dictionary = sim.data.relics.get(str(op["id"]), {})
				var ri := K.RARITIES.find(str(rel.get("rarity", "common")))
				head.text = tr("RARITY_" + K.RARITIES[maxi(ri, 0)])
				head.add_theme_color_override("font_color", UiKit.RARITY_COLORS[maxi(ri, 0)].lightened(0.4))
				cp = _text_card(tr("REL_" + str(op["id"])), tr("RELD_" + str(op["id"])), w, UiKit.RARITY_COLORS[maxi(ri, 0)], str(op["id"]))
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
				var tci := _inst(int(op.get("uid", -1)))
				mids = UiKit.mod_ids(tci) if tci else []
				cp = UiKit.card(cd, sim.card_cost(tci) if tci else cd.cost_at(lv), UiKit.mod_names(tci) if tci else [], key, w, lv)
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
		head.custom_minimum_size = Vector2(0, 0)
		head.autowrap_mode = TextServer.AUTOWRAP_OFF
		head.add_theme_font_override("font", UiDiario.font("type"))
		slot.add_child(UiDiario.tape_wrap(head, UiDiario.MASK, -2.0 + k * 1.3))
		slot.add_child(pair_node if pair_node else cp)
		var note := UiDiario.note_wrap(foot)
		note.custom_minimum_size = Vector2(w * 0.9, 0)
		note.visible = foot.get_parsed_text().strip_edges() != ""
		slot.add_child(note)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.set_meta("card", pair_node if pair_node else cp)
		slot.set_meta("special", lv > 1 or mids.size() > 0 or str(op["kind"]) in ["upgrade", "mod"])
		slot.set_meta("fx_col", Color(0.55, 1.0, 0.55) if str(op["kind"]) == "upgrade" else (CardFx.MOD_COLOR.get(mids[0], UiKit.GOLD).lightened(0.3) if mids.size() > 0 else UiKit.GOLD))
		var row_i := k / cols
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
	if result_icon:
		result_icon.texture = CampaignArt.map_tex("res://assets/ui/map/node_m-lair%s.svg" % ("_hot" if won else ""))
		result_icon.modulate = Color.WHITE if won else Color(0.78, 0.7, 0.62)
		UiKit.title_color(result_title, UiParch.INK if won else UiParch.BLOOD)
	result_sub.text = tr("UI_RESULT_" + r)
	var top := ""
	var best := 0
	for cid in st["played"]:
		if int(st["played"][cid]) > best:
			best = int(st["played"][cid])
			top = cid
	UiKit.clear(result_grid)
	# Rodada 16/11/2026: sem Almas, nível do herói nem Santuários (sistemas que saíram). A arena só aparece se houve.
	var you := "%d / %d" % [int(st.get("heroes_fallen", 0)), sim.party_size()]
	var tiles := [["UI_ST_you", you], ["UI_ST_time", _clock(sim.t)],
		["UI_ST_contests", "%d / %d" % [int(st["locs_won"]), int(st["locs_visited"])]], ["UI_ST_gold", str(int(st["gold_earned"]))],
		["UI_ST_relics", str(st["relics"].size())], ["UI_ST_kills", str(st["kills"])],
		["UI_ST_top", tr("CARD_" + top) if top != "" else "—"]]
	if float(st.get("arena_t", -1.0)) >= 0.0:
		tiles.append(["UI_ST_parts", str(st["parts_lost"])])
	for tdef in tiles:
		var tp := UiKit.panel(Color(0.08, 0.06, 0.12, 0.95), UiKit.EDGE.darkened(0.2), 10)
		tp.custom_minimum_size = Vector2(180, 86)
		var tv := VBoxContainer.new()
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		# Heróis derrubados é o placar da run: dourado. Zeros ficam apagados.
		var main_: bool = tdef[0] == "UI_ST_you"
		var zero: bool = tdef[1] == "0"
		var val := UiKit.title(30 if tdef[1].length() < 8 else 17, UiKit.GOLD if main_ else (UiKit.MUTED if zero else UiKit.TEXT))
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
	_show_unlocks()


## Pele "Mapa aberto": um desenho do mapa apoiado na linha de baixo da moldura do painel, no canto direito (o
## bosquinho no painel do herói, o rato no do corpo do chefe), como nas maquetes da pele. Pintado
## pelo próprio painel, embaixo do texto.
func _map_doodle(panel: Control, icon: String, sz: Vector2, from_corner: Vector2, on_top := false, left := false) -> void:
	var tex: Texture2D = CampaignArt.map_tex("res://assets/ui/map/icon_%s.svg" % icon)
	if tex == null:
		return
	panel.draw.connect(func():
		var at := Vector2(panel.size.x - sz.x - from_corner.x, -sz.y * 0.55 + from_corner.y) if on_top else panel.size - sz - from_corner
		if left:
			at.x = from_corner.x
		panel.draw_texture_rect(tex, Rect2(at, sz), false))

# ---------------------------------------------------------------- poderes de party (frente H, 22/11/2026)

const ROMAN := ["", "I", "II", "III"]


## Ícone do poder: assets/ui/powers/<id>.svg (tools/art/power_icons.py). Sem arquivo, quadrado vazio do mesmo tamanho.
static func power_icon(id: String, px: float) -> TextureRect:
	var tr_ := TextureRect.new()
	var path := "res://assets/ui/powers/%s.svg" % id
	if ResourceLoader.exists(path):
		tr_.texture = load(path)
	tr_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr_.custom_minimum_size = Vector2(px, px)
	tr_.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tr_.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr_


func _build_power_row() -> void:
	power_row = Control.new()
	power_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	power_row.visible = false
	add_child(power_row)


func _power_status(it: Dictionary) -> String:
	if str(it.get("trigger", "")) == "interval":
		return tr("UI_POWER_EVERY").format({"s": int(ceil(float(it["cd_total"])))})
	if bool(it["ready"]):
		return tr("UI_POWER_READY")
	return tr("UI_POWER_CHARGING").format({"s": int(ceil(float(it["cd_left"])))})


func _power_entries(i: int) -> Array:
	if sim == null:
		return []
	var list := sim.party_powers()
	if i >= list.size():
		return []
	var it: Dictionary = list[i]
	var d := HeroPowers.describe(sim, str(it["id"]), int(it["level"]))
	if d.is_empty():
		return []
	var body := "%s\n\n%s: %d s\n%s" % [d["desc"], tr("UI_POWER_COOLDOWN"), int(d["cooldown"]), _power_status(it)]
	return [Tips.entry("%s %s" % [d["name"], ROMAN[clampi(int(it["level"]), 1, 3)]], body, power_icon(str(it["id"]), 30))]


## Fileira de ícones sobre a party: refaz quando muda a lista; todo quadro atualiza recarga, segundos e brilhos.
func _refresh_powers() -> void:
	var list := sim.party_powers()
	var sig := ""
	for it in list:
		sig += "%s%d," % [it["id"], int(it["level"])]
	sig += TranslationServer.get_locale()
	if sig != power_sig:
		power_sig = sig
		UiKit.clear(power_row)
		power_badges.clear()
		for i in list.size():
			var b := PowerBadge.new()
			b.setup(str(list[i]["id"]), int(list[i]["level"]))
			var idx := i
			Tips.attach(b, func(): return _power_entries(idx))
			power_row.add_child(b)
			power_badges.append(b)
	power_row.visible = not list.is_empty() and sim.phase != K.Phase.OVER and not pause_layer.visible
	for i in power_badges.size():
		var b: PowerBadge = power_badges[i]
		var it: Dictionary = list[i]
		var tot := maxf(float(it["cd_total"]), 0.01)
		b.interval = str(it.get("trigger", "")) == "interval"
		b.ok_ready = bool(it["ready"])
		b.frac = clampf(float(it["cd_left"]) / tot, 0.0, 1.0)
		b.secs = int(ceil(float(it["cd_left"]))) if not b.ok_ready else 0
		if power_flash.has(i):
			match str(power_flash[i]):
				"trigger":
					b.flash = 1.0
				"ready":
					b.pop = 1.0
				"gained":
					b.pop = 2.0
	power_flash.clear()


## Posição da fileira: logo abaixo do grupo, centrada nele; quebra em linhas e encolhe os ícones se forem muitos.
func _layout_powers(vs: Vector2, m: float) -> void:
	var n := power_badges.size()
	if n == 0 or not power_row.visible:
		return
	var px := 46.0 if n <= 10 else (36.0 if n <= 24 else 28.0)
	var gap := 4.0
	var wmax := clampf(maxf(duel.size.x, 320.0), 320.0, vs.x * 0.5)
	var per := maxi(1, int(floor((wmax + gap) / (px + gap))))
	var cols := mini(n, per)
	var rows := int(ceil(float(n) / float(per)))
	power_row.size = Vector2(cols * (px + gap) - gap, rows * (px + gap) - gap)
	for i in n:
		var b: PowerBadge = power_badges[i]
		b.size = Vector2(px, px)
		b.position = Vector2((i % per) * (px + gap), (i / per) * (px + gap))
	var y := duel.position.y + duel.size.y + 6.0
	var x := duel.position.x + (duel.size.x - power_row.size.x) * 0.5
	if contest_panel.visible and contest_panel.position.y + contest_panel.size.y > y:
		x = maxf(x, contest_panel.position.x + contest_panel.size.x + 12.0)
	x = clampf(x, m, maxf(vs.x - power_row.size.x - m, m))
	power_row.position = Vector2(x, y)
	var dy := power_row.size.y + 8.0
	learn_panel.position.y += dy
	hint_panel.position.y += dy


func _build_power_panel() -> void:
	power_layer = _dim()
	power_layer.color.a = 0.6
	power_box = UiKit.panel(UiKit.BG, UiKit.GOLD, 22)
	power_box.name = "Box"
	power_layer.add_child(power_box)
	power_layer.visible = false
	add_child(power_layer)


## Descrição da evolução: cada número que muda aparece como "antes → depois" (o que não muda fica como está).
func _power_evo_desc(id: String, prev: int, lv: int) -> String:
	var pd: Dictionary = sim.data.hero_powers.get(id, {})
	if pd.is_empty():
		return ""
	var a := HeroPowers.params(pd, prev)
	var b := HeroPowers.params(pd, lv)
	var m := {}
	for k in b:
		var nv = b[k]
		var ov = a.get(k, nv)
		if (nv is float or nv is int) and (ov is float or ov is int) and not is_equal_approx(float(nv), float(ov)):
			m[k] = "%s → %s" % [_num(ov), _num(nv)]
		elif typeof(nv) == typeof(ov) and nv != ov and not (nv is Array or nv is Dictionary):
			m[k] = "%s → %s" % [str(ov), str(nv)]
		else:
			m[k] = nv
	var s := tr("POWER_" + id + "_d").format(m)
	# A unidade vale para os dois lados: "12 → 18%" vira "12% → 18%".
	var re := RegEx.new()
	re.compile("(\\d+(?:\\.\\d+)?) → (\\d+(?:\\.\\d+)?)(%|x\\b| m\\b| s\\b)")
	return re.sub(s, "$1$3 → $2$3", true)


static func _num(v) -> String:
	var f := float(v)
	return str(int(round(f))) if is_equal_approx(f, round(f)) else str(snappedf(f, 0.01))


## Painel de revelação do poder (oferta-aviso "power"): novo ou evolução, efeito, recarga e os poderes que a party já tem.
func _refresh_power_panel(o: Dictionary) -> void:
	var sig := TranslationServer.get_locale() + str(o)
	if sig == power_panel_sig:
		return
	var first := power_panel_sig == ""
	power_panel_sig = sig
	UiKit.clear(power_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	var opts: Array = o["options"]
	var any_new := false
	for op in opts:
		if bool(op.get("new", false)):
			any_new = true
	var title := UiKit.title(38)
	title.text = tr("UI_POWER_NEW" if any_new else "UI_POWER_EVOLVED")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(UiDiario.tape_title(title))
	var changed: Array = []
	for op in opts:
		var id := str(op["id"])
		changed.append(id)
		var lv := int(op["level"])
		var d := HeroPowers.describe(sim, id, lv)
		if d.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var badge := PowerBadge.new()
		badge.setup(id, lv)
		badge.custom_minimum_size = Vector2(88, 88)
		badge.static_view = true
		badge.pop = 2.0
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(badge)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		col.custom_minimum_size = Vector2(470, 0)
		var nm := UiKit.title(30)
		nm.text = str(d["name"])
		col.add_child(nm)
		var prev := int(op.get("prev_level", 0))
		var lvl := UiKit.label(17, UiKit.GOLD, 3)
		lvl.text = tr("UI_POWER_LEVEL_UP").format({"a": ROMAN[clampi(prev, 0, 3)], "b": ROMAN[clampi(lv, 1, 3)]}) if prev > 0 and not bool(op.get("new", false)) else tr("UI_POWER_LEVEL").format({"n": ROMAN[clampi(lv, 1, 3)]})
		col.add_child(lvl)
		var evo := prev > 0 and not bool(op.get("new", false))
		col.add_child(Tips.label(_power_evo_desc(id, prev, lv) if evo else str(d["desc"]), 18, UiKit.TEXT, 470.0, false))
		var cd := UiKit.label(17, UiKit.MUTED, 3)
		var cd_now := int(op.get("cooldown", d["cooldown"]))
		var cd_old := int(HeroPowers.describe(sim, id, prev).get("cooldown", cd_now)) if evo else cd_now
		if str(d["trigger"]) == "interval":
			cd.text = tr("UI_POWER_EVERY").format({"s": cd_now if cd_old == cd_now else "%d → %d" % [cd_old, cd_now]})
		else:
			cd.text = "%s: %s s" % [tr("UI_POWER_COOLDOWN"), str(cd_now) if cd_old == cd_now else "%d s → %d" % [cd_old, cd_now]]
		# Evolução: só o que mudou aparece; recarga igual some.
		cd.visible = not evo or cd_old != cd_now
		col.add_child(cd)
		row.add_child(col)
		v.add_child(row)
	var have: Array = o.get("powers", [])
	if not have.is_empty():
		v.add_child(UiParch.divider(560.0))
		var hl := UiKit.label(17, UiKit.MUTED, 3)
		hl.text = tr("UI_POWER_HAVE").format({"n": have.size()})
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(hl)
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 6)
		fl.add_theme_constant_override("v_separation", 6)
		fl.alignment = FlowContainer.ALIGNMENT_CENTER
		fl.custom_minimum_size = Vector2(574, 0)
		for it in have:
			var mb := PowerBadge.new()
			mb.setup(str(it["id"]), int(it["level"]))
			mb.static_view = true
			mb.custom_minimum_size = Vector2(44, 44)
			mb.hilite = changed.has(str(it["id"]))
			mb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fl.add_child(mb)
		v.add_child(fl)
	power_continue = Button.new()
	power_continue.text = tr("UI_OFFER_CONTINUE")
	power_continue.custom_minimum_size = Vector2(240, 46)
	power_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	power_continue.pressed.connect(func(): offer_chosen.emit(0))
	v.add_child(power_continue)
	power_box.add_child(v)
	power_box.size = Vector2.ZERO
	if first:
		Juice.slam(title)
		if sfx.is_valid():
			sfx.call("reward", 0.9)


## Medalhão de um poder: ícone sobre papel, varredura radial da recarga que falta, segundos, brilho quando pronto,
## piscar ao disparar e selo do nível (I a III). `static_view`: sem recarga (painel de revelação).
class PowerBadge extends Control:
	var id := ""
	var level := 1
	var frac := 0.0
	var secs := 0
	var ok_ready := false
	var interval := false
	var flash := 0.0
	var pop := 0.0
	var static_view := false
	var hilite := false
	var _drawn_secs := 0
	var tex: Texture2D

	func setup(id_: String, level_: int) -> void:
		id = id_
		level = level_
		custom_minimum_size = Vector2(40, 40)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var path := "res://assets/ui/powers/%s.svg" % id
		if ResourceLoader.exists(path):
			tex = load(path)

	func _process(delta: float) -> void:
		if flash > 0.0:
			flash = maxf(flash - delta * 2.5, 0.0)
		if pop > 0.0:
			pop = maxf(pop - delta, 0.0)
		# Recarga em andamento: segundos e varredura mudam todo quadro, então redesenha (antes só brilho/pop redesenhavam).
		if flash > 0.0 or pop > 0.0 or (ok_ready and not interval and not static_view) or (not static_view and (frac > 0.0 or secs != _drawn_secs)):
			_drawn_secs = secs
			queue_redraw()

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var c := size * 0.5
		var r := s * 0.5
		var tt := Time.get_ticks_msec() * 0.001
		var glow := 0.5 + 0.5 * sin(tt * 4.0) if (ok_ready and not interval and not static_view) else 0.0
		if glow > 0.0:
			draw_circle(c, r, Color(1.0, 0.85, 0.35, 0.25 + 0.2 * glow))
		var popk := minf(pop, 1.0)
		draw_circle(c, r * 0.9, Color(0.07, 0.05, 0.1))
		draw_circle(c, r * 0.84, Color(0.89, 0.81, 0.62))
		if tex != null:
			var q := r * 1.34
			draw_texture_rect(tex, Rect2(c - Vector2(q, q) * 0.5, Vector2(q, q)), false)
		if not static_view and frac > 0.0:
			var pts := PackedVector2Array([c])
			var steps := maxi(6, int(32.0 * frac) + 2)
			for i in steps + 1:
				var a := -PI * 0.5 + TAU * frac * float(i) / float(steps)
				pts.append(c + Vector2(cos(a), sin(a)) * r * 0.84)
			draw_colored_polygon(pts, Color(0.05, 0.03, 0.08, 0.62))
		var ring := Color(0.24, 0.17, 0.11)
		if glow > 0.0:
			ring = Color(1.0, 0.82, 0.3).lerp(Color(1, 0.95, 0.7), glow)
		elif hilite or popk > 0.0:
			ring = Color(1.0, 0.82, 0.3)
		draw_arc(c, r * 0.9, 0.0, TAU, 40, ring, maxf(1.8, s * 0.07), true)
		if popk > 0.0:
			draw_arc(c, r * (1.0 + (1.0 - popk) * 0.35), 0.0, TAU, 40, Color(1.0, 0.9, 0.5, popk), 2.0, true)
		if flash > 0.0:
			draw_circle(c, r * 0.9, Color(1, 1, 1, 0.55 * flash))
			draw_arc(c, r * (1.0 + (1.0 - flash) * 0.6), 0.0, TAU, 40, Color(1, 0.95, 0.7, flash), 3.0, true)
		var font := get_theme_default_font()
		if font == null:
			font = ThemeDB.fallback_font
		if not static_view and secs > 0 and not ok_ready:
			var fs := int(maxf(12.0, s * 0.42))
			var t := str(secs)
			var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var tp := Vector2(c.x - tw.x * 0.5, c.y + fs * 0.34)
			draw_string_outline(font, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0.05, 0.03, 0.08, 0.95))
			draw_string(font, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.96, 0.85))
		# Selo do nível, no canto de baixo à direita.
		var sc := c + Vector2(r, r) * 0.66
		var sr := maxf(7.0, s * 0.2)
		draw_circle(sc, sr, Color(0.07, 0.05, 0.1))
		draw_circle(sc, sr * 0.82, Color(0.85, 0.65, 0.25))
		var lt: String = Hud.ROMAN[clampi(level, 1, 3)]
		var lfs := int(maxf(9.0, sr * 1.15))
		var lw := font.get_string_size(lt, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs)
		draw_string(font, Vector2(sc.x - lw.x * 0.5, sc.y + lfs * 0.34), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs, Color(0.12, 0.07, 0.03))
