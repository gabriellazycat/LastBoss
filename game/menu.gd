class_name MainMenu
extends Control
## Menu principal sobre o covil 3D: título, escolha de Pacto, coleção e configurações. Mouse, teclado e controle.

signal deck_chosen(id: String)
signal continue_run
signal settings_changed(key: String)

const VERSION := "v0.1 · MVP"
## Retrato do vilão enquanto assets/cards/villain_<id>.png não chega: a arte antiga mais próxima.
const VILLAIN_ART_FALLBACK := {"plague": "pact_horde", "dragon": "pact_treasure", "lich": "dark_pact"}

var data: GameData
var meta: MetaSave
var screen := "title"
var shade: TextureRect
var veil: ColorRect
var title_box: VBoxContainer
var main_buttons: VBoxContainer
var continue_btn: Button
var new_run_btn: Button
var title_art: Control
var deck_screen: Control
var deck_row: HBoxContainer
var preview_head: Label
var preview_row: HBoxContainer
var pending_villain := ""
var pending_phase := -1     # fase da campanha escolhida (-1 = a próxima a vencer)
var campaign: CampaignMap    # mapa da campanha (16/11/2026): Nova run abre aqui, antes do vilão
var rare_screen: Control
var rare_row: HBoxContainer
var rare_sub: Label
var rare_skipped := false   # "Voltar": a escolha de rara não reabre até o jogo fechar
var collection: CollectionScreen
var compendium: CompendiumScreen
var settings: SettingsPanel
var footer: Label
var fade := 0.0
const CAMPAIGN_MAX_SCALE := 1.6
## Pele Diário: a mesa 3D atrás (main liga) e a folha do título; a tela anterior volta para a mesa.
var desk: DeskScene
var title_root: Control
var prev_screen := ""
var prev_fade := 1.0


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Sombra à esquerda para o texto ler bem sobre a cena.
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.01, 0.04, 0.88))
	g.set_color(1, Color(0.02, 0.01, 0.04, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(1, 0)
	shade = TextureRect.new()
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	veil = ColorRect.new()
	veil.color = Color(0.02, 0.012, 0.03, 0.62)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.visible = false
	add_child(veil)
	if UiSkins.diario():
		shade.visible = false
	_build_title()
	_build_decks()
	_build_campaign()
	_build_rare()
	collection = CollectionScreen.new()
	collection.setup(data, meta)
	collection.visible = false
	collection.closed.connect(func(): show_screen("title"))
	add_child(collection)
	compendium = CompendiumScreen.new()
	compendium.setup(data, meta)
	compendium.visible = false
	compendium.closed.connect(func(): show_screen("title"))
	add_child(compendium)
	settings = SettingsPanel.new()
	settings.visible = false
	settings.closed.connect(func(): show_screen("title"))
	settings.changed.connect(func(k): settings_changed.emit(k))
	add_child(settings)
	footer = UiKit.label(14, UiKit.MUTED, 3)
	add_child(footer)
	show_screen("title")


func _build_title() -> void:
	if UiSkins.mapa():
		_build_title_map()
		return
	title_box = VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 6)
	if UiSkins.diario():
		# Folha presa com duas fitas; o título a pincel e as opções em fita crepe.
		var sheet := PanelContainer.new()
		UiDiario.dress(sheet, "paper", 46.0, {"grime": 0.5, "seed": 0.21, "shadow": 12.0, "rough": 3.0})
		sheet.rotation_degrees = 0.0   # 13/11/2026: folha com moldura dourada, reta e sem fita crepe
		sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sheet)
		sheet.add_child(title_box)
		title_root = sheet
	else:
		add_child(title_box)
		title_root = title_box
	var over := UiKit.label(18, UiKit.MUTED, 3)
	over.text = "UI_TITLE_OVER"
	title_box.add_child(over)
	var t := UiKit.title(124 if UiSkins.covil() else (100 if UiSkins.diario() else 104))
	t.text = "LAST BOSS"
	title_box.add_child(t)
	if UiSkins.diario():
		over.add_theme_font_override("font", UiDiario.font("type"))
		over.add_theme_color_override("font_color", UiDiario.INK.lightened(0.25))
		t.rotation_degrees = -2.0
		title_box.add_child(UiDiario.ornament(470))
	elif UiSkins.covil():
		over.add_theme_font_override("font", UiCovil.font("caps"))
		over.add_theme_color_override("font_color", UiKit.GOLD.darkened(0.15))
		title_box.add_child(UiCovil.ornament(520))
	else:
		var rule := ColorRect.new()
		rule.color = UiKit.GOLD.darkened(0.2)
		rule.custom_minimum_size = Vector2(420, 2)
		rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		title_box.add_child(rule)
	var sub := UiKit.label(20, Color(0.88, 0.84, 0.96))
	sub.text = "UI_SUBTITLE"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	sub.custom_minimum_size = Vector2(460, 0)
	title_box.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 34)
	title_box.add_child(gap)
	main_buttons = VBoxContainer.new()
	main_buttons.add_theme_constant_override("separation", 10)
	if UiSkins.diario():
		# Embaixo das fitas, a caveira coroada do Lorde a nanquim (a folha não fica com um vazio do lado).
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		title_box.add_child(row)
		row.add_child(main_buttons)
		var doodle := VBoxContainer.new()
		doodle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		doodle.alignment = BoxContainer.ALIGNMENT_END
		# Retrato pintado do vilão da última run (o "eu" da folha); sem ele, a caveira a nanquim.
		var pt := UiParch.portrait("villain_" + meta.villain) if meta else null
		if pt != null:
			title_art = UiParch.framed_art(pt, Vector2(210, 200), "frame_legend")
			title_art.size_flags_horizontal = Control.SIZE_SHRINK_END
			doodle.add_child(title_art)
		else:
			var sk := TextureRect.new()
			sk.texture = UiDiario.card_tex("lord_skull")
			sk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sk.custom_minimum_size = Vector2(170, 170)
			doodle.add_child(sk)
		var me := Label.new()
		me.text = "UI_TITLE_ME"
		me.add_theme_font_override("font", UiDiario.font("hand"))
		me.add_theme_font_size_override("font_size", 24)
		me.add_theme_color_override("font_color", UiDiario.BLOOD)
		me.set_meta("no_ink", true)
		me.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		me.rotation_degrees = -5.0
		doodle.add_child(me)
		row.add_child(doodle)
	else:
		title_box.add_child(main_buttons)
	continue_btn = _menu_btn("UI_CONTINUE", func(): continue_run.emit())
	new_run_btn = _menu_btn("UI_NEW_RUN", func(): show_screen("campaign"))
	_menu_btn("UI_COLLECTION", func(): show_screen("collection"))
	_menu_btn("UI_COMPENDIUM", func(): show_screen("compendium"))
	_menu_btn("UI_SETTINGS", func(): show_screen("settings"))
	if OS.get_name() != "Web":
		_menu_btn("UI_QUIT", func(): get_tree().quit())


func _on_map_choice(id: String) -> void:
	if id == "continue":
		continue_run.emit()
	elif id == "new_run":
		show_screen("campaign")
	elif id == "quit":
		get_tree().quit()
	else:
		show_screen(id)


## Pele "Mapa aberto": o título é um mapa aberto sobre a mesa (MapMenu, maquete "Menu A").
func _build_title_map() -> void:
	var mm := MapMenu.new()
	var pt := UiParch.portrait("villain_" + meta.villain) if meta else null
	if pt == null and ResourceLoader.exists("res://assets/cards/rat_king.png"):
		pt = load("res://assets/cards/rat_king.png")
	mm.build(pt)
	add_child(mm)
	title_root = mm
	title_box = VBoxContainer.new()   # o resto do menu ainda pergunta pelo title_box; no mapa ele fica vazio
	main_buttons = VBoxContainer.new()
	main_buttons.visible = false
	mm.add_child(main_buttons)
	continue_btn = mm.continue_btn
	new_run_btn = mm.buttons["new_run"]
	mm.chosen.connect(_on_map_choice)
	if OS.get_name() == "Web":
		mm.buttons["quit"].visible = false


func _menu_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(380, 56)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", 24)
	if UiSkins.diario():
		b.custom_minimum_size = Vector2(320, 52)
		UiDiario.menu_button(b, 24, txt == "UI_CONTINUE")
	elif UiSkins.covil():
		UiCovil.menu_button(b, 26)
	b.pressed.connect(cb)
	b.mouse_entered.connect(func(): b.grab_focus())
	main_buttons.add_child(b)
	return b


func _build_decks() -> void:
	if UiSkins.diario():
		_build_villains_parch()
		return
	deck_screen = VBoxContainer.new()
	deck_screen.add_theme_constant_override("separation", 18)
	add_child(deck_screen)
	var h := UiKit.title(44)
	h.text = "UI_CHOOSE_VILLAIN"
	deck_screen.add_child(UiDiario.tape_title(h) if UiSkins.diario() else h)
	var hs := UiKit.label(18, UiKit.MUTED)
	hs.text = "UI_CHOOSE_VILLAIN_SUB"
	deck_screen.add_child(hs)
	deck_row = HBoxContainer.new()
	deck_row.add_theme_constant_override("separation", 18)
	deck_row.alignment = BoxContainer.ALIGNMENT_CENTER
	deck_screen.add_child(deck_row)
	# Prévia: o baralho inicial do vilão em foco, todas as cartas à vista de uma vez.
	var prev := UiKit.panel(UiKit.BG, UiKit.EDGE, 12)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	prev.add_child(pv)
	preview_head = UiKit.title(26, UiKit.TEXT)
	pv.add_child(preview_head)
	preview_row = HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 6)
	pv.add_child(preview_row)
	deck_screen.add_child(prev)
	var back := Button.new()
	back.text = "UI_BACK"
	back.custom_minimum_size = Vector2(200, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func(): show_screen("campaign"))
	deck_screen.add_child(back)


## Vilão que já vem em foco: o último escolhido, se estiver liberado.
func _default_villain() -> String:
	return meta.villain if meta.villains.has(meta.villain) else data.villain_ids[0]


## Retrato do vilão (assets/cards/<portrait>.png); sem ele, a arte antiga mais próxima.
static func villain_tex(d: GameData, id: String) -> Texture2D:
	var t := UiDiario.card_tex(str(d.villain(id).get("portrait", "villain_" + id)))
	if t == null:
		t = UiDiario.card_tex(VILLAIN_ART_FALLBACK.get(d.villain_id(id), "lord_skull"))
	return t


## As 3 ideias de combo do vilão, uma linha curta cada.
func _combo_lines(id: String, size: int, col: Color, w: float, font: Font = null) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	for i in 3:
		var l := Tips.label("%d · %s" % [i + 1, tr("VCOMBO_%s_%d" % [id, i + 1])], size, col, w)
		if font:
			l.add_theme_font_override("normal_font", font)
			l.add_theme_font_size_override("normal_font_size", size)
		v.add_child(l)
	return v


func _fill_decks() -> void:
	if UiSkins.diario():
		_fill_villains_parch()
		return
	UiKit.clear(deck_row)
	for id in data.villain_ids:
		var p := UiKit.panel(UiKit.BG, UiKit.EDGE, 16)
		p.custom_minimum_size = Vector2(380, 300)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		p.add_child(v)
		# Retrato do vilão.
		var emblem := Control.new()
		emblem.custom_minimum_size = Vector2(346, 130)
		emblem.clip_contents = true
		var ea := TextureRect.new()
		ea.texture = villain_tex(data, id)
		ea.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ea.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		ea.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		ea.set_anchors_preset(Control.PRESET_FULL_RECT)
		emblem.add_child(ea)
		if UiSkins.covil():
			var ef := Panel.new()
			ef.set_anchors_preset(Control.PRESET_FULL_RECT)
			UiCovil.dress(ef, "inset", UiCovil.BRONZE, UiCovil.IRON_TOP, UiCovil.IRON_BOT, Color(0, 0, 0, 0), 0.0)
			emblem.add_child(ef)
		v.add_child(emblem)
		var name_ := UiKit.title(34)
		name_.text = tr("DECK_" + id).to_upper()
		v.add_child(name_)
		v.add_child(Tips.label(UiKit.deck_rules_text(data, id), 16, Color(0.9, 0.86, 1.0), 346.0))
		# Sem dicas de combo (17/11/2026): o jogador descobre sozinho.
		var b := Button.new()
		b.text = "UI_PICK_VILLAIN"
		if not meta.villains.has(id):
			b.text = tr("UI_VILLAIN_LOCKED").format({"n": _phase_unlocking(id)})
			b.disabled = true
		b.custom_minimum_size = Vector2(0, 54)
		b.add_theme_font_size_override("font_size", 22)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.pressed.connect(func():
			pending_villain = id
			_start_villain())
		# Material próprio: acender este vilão não pode acender os painéis que dividem o mesmo material.
		if p.material:
			p.material = p.material.duplicate()
		var lit := func(on: bool): UiKit.set_hot(p, on)
		b.focus_entered.connect(_fill_preview.bind(id))
		b.focus_entered.connect(lit.bind(true))
		b.focus_exited.connect(lit.bind(false))
		b.mouse_entered.connect(func(): b.grab_focus())
		p.mouse_entered.connect(func(): b.grab_focus())
		v.add_child(b)
		deck_row.add_child(p)
	_fill_preview(_default_villain())


## Cartas do baralho inicial do vilão, da mais barata à mais cara.
func _fill_preview(id: String) -> void:
	preview_head.text = tr("UI_VILLAIN_DECK").format({"name": tr("DECK_" + id), "n": data.deck(id)["cards"].size()})
	UiKit.clear(preview_row)
	var order: Array = data.deck(id)["cards"].duplicate()
	order.sort_custom(func(a, c): return data.card(a).cost < data.card(c).cost or (data.card(a).cost == data.card(c).cost and a < c))
	for cid in order:
		var d: CardDef = data.card(cid)
		var cell := CollectionScreen.cell(d, 92.0 if UiSkins.diario() else 112.0)
		Tips.attach(cell, func(): return Tips.card_entries(d, [], true))
		preview_row.add_child(cell)


func _build_rare() -> void:
	rare_screen = VBoxContainer.new()
	rare_screen.add_theme_constant_override("separation", 16)
	add_child(rare_screen)
	if UiSkins.diario():
		rare_screen.draw.connect(func(): UiDiario.draw_plate(rare_screen, "paper", Vector2(34, 28)))
	var h := UiKit.title(44)
	h.text = "UI_RARE_CHOICE"
	rare_screen.add_child(h)
	rare_sub = UiKit.label(18, UiKit.MUTED)
	rare_screen.add_child(rare_sub)
	rare_row = HBoxContainer.new()
	rare_row.add_theme_constant_override("separation", 22)
	rare_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rare_screen.add_child(rare_row)
	var back := Button.new()
	back.text = "UI_BACK"
	back.custom_minimum_size = Vector2(200, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_skip_rare)
	rare_screen.add_child(back)


func _skip_rare() -> void:
	rare_skipped = true
	show_screen("title")


## Há uma rara à escolha esperando (fases 3 e 4) e ainda há cartas para oferecer.
func _rare_pending() -> bool:
	return meta.rare_choices > 0 and not rare_skipped and not meta.rare_choice_options(3).is_empty()


## Três raras ainda bloqueadas dos vilões liberados; escolher uma entra na coleção.
func _fill_rare() -> void:
	rare_sub.text = tr("UI_RARE_CHOICE_SUB").format({"n": meta.rare_choices})
	UiKit.clear(rare_row)
	for cid in meta.rare_choice_options(3):
		var d: CardDef = data.card(cid)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		var cell := CollectionScreen.cell(d, 220.0)
		Tips.attach(cell, func(): return Tips.card_entries(d, [], true))
		col.add_child(cell)
		var own := UiKit.label(16, UiKit.MUTED)
		own.text = tr("DECK_" + d.owner) if d.owner != "common" else tr("UI_TAB_V_common")
		own.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(own)
		var b := Button.new()
		b.text = "UI_RARE_PICK"
		b.custom_minimum_size = Vector2(0, 52)
		b.add_theme_font_size_override("font_size", 21)
		b.pressed.connect(func():
			if meta.choose_rare(d.id):
				meta.save()
			show_screen("title"))
		b.mouse_entered.connect(func(): b.grab_focus())
		col.add_child(b)
		rare_row.add_child(col)


## Mapa da campanha: escolher a fase (região) leva à escolha do vilão; o tutorial tem vilão fixo e começa direto.
func _build_campaign() -> void:
	campaign = CampaignMap.new()
	campaign.setup(data, meta)
	campaign.visible = false
	campaign.chosen.connect(func(k: int):
		pending_phase = k
		var ph: Dictionary = data.phase(k)
		if ph.has("deck"):
			pending_villain = data.villain_id(str(ph["deck"]))
			deck_chosen.emit(pending_villain)
		else:
			show_screen("decks"))
	campaign.back.connect(func(): show_screen("title"))
	add_child(campaign)


## Vilão escolhido: a run começa na fase escolhida no mapa.
func _start_villain() -> void:
	if pending_villain == "" or not meta.villains.has(pending_villain):
		return
	meta.villain = pending_villain
	meta.save()
	deck_chosen.emit(pending_villain)


## Fase que libera o vilão (para o aviso do vilão bloqueado).
func _phase_unlocking(pid: String) -> int:
	for ph in data.phases:
		if data.villain_id(str(ph.get("unlock_villain", "-"))) == data.villain_id(pid):
			return int(ph["id"])
	return 0


## A primeira fase ainda não vencida (o tutorial, num jogo novo).
func _next_phase() -> int:
	for ph in data.phases:
		if not meta.phases_won.has(int(ph["id"])):
			return int(ph["id"])
	return 1


func show_screen(s: String) -> void:
	if s == "title" and _rare_pending():
		s = "rare"
	if UiSkins.diario() and s != screen and is_node_ready():
		prev_screen = screen
		prev_fade = 0.0
	var came_from := screen
	screen = s
	fade = 0.0
	if is_instance_valid(desk):
		desk.set_current(_desk_id(s))
		desk.set_continue(SaveGame.exists())
	title_root.visible = s == "title" or (prev_screen == "title" and prev_fade < 1.0)
	deck_screen.visible = s == "decks"
	campaign.visible = s == "campaign"
	rare_screen.visible = s == "rare"
	collection.visible = s == "collection"
	compendium.visible = s == "compendium"
	settings.visible = false
	if s == "title":
		continue_btn.visible = SaveGame.exists()
		if UiSkins.mapa():
			(continue_btn if continue_btn.visible else new_run_btn).grab_focus.call_deferred()
		else:
			if UiSkins.diario():
				# A opção principal é a fita vermelha: Continuar quando há run salva; senão, Nova run.
				UiDiario.menu_button(new_run_btn, 24, not continue_btn.visible)
			(continue_btn if continue_btn.visible else main_buttons.get_child(1)).grab_focus.call_deferred()
	elif s == "decks":
		_fill_decks()
		_focus_first_deck.call_deferred()
	elif s == "campaign":
		# Vindo do título, o mapa abre na próxima fase a vencer; voltando do vilão, na que estava escolhida.
		if came_from != "decks" or pending_phase < 0 or not meta.phase_open(pending_phase):
			pending_phase = _next_phase()
		campaign.open(pending_phase)
	elif s == "rare":
		_fill_rare()
		for b in rare_screen.find_children("*", "Button", true, false):
			b.grab_focus.call_deferred()
			break
	elif s == "collection":
		collection.open()
	elif s == "compendium":
		compendium.open()
	elif s == "settings":
		settings.open()


func _focus_first_deck() -> void:
	for b in deck_screen.find_children("*", "Button", true, false):
		if not b.disabled:
			b.grab_focus()
			return


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		if screen == "decks":
			_fill_decks.call_deferred()
		elif screen == "campaign":
			campaign.refresh.call_deferred()
		elif screen == "rare":
			_fill_rare.call_deferred()
		elif screen == "collection":
			collection.refresh.call_deferred()
		elif screen == "compendium":
			compendium.show_tab.call_deferred(compendium.tab)


func _unhandled_input(e: InputEvent) -> void:
	if visible and screen == "compendium" and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		show_screen("title")
		return
	if visible and screen == "rare" and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_skip_rare()
		return
	if visible and screen == "decks" and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		show_screen("campaign")
		return
	if visible and screen == "campaign" and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		show_screen("title")


func _process(delta: float) -> void:
	if not visible:
		return
	if UiSkins.diario():
		_process_desk(delta)
		return
	fade = minf(fade + delta * 4.0, 1.0)
	var vs := get_viewport_rect().size
	shade.position = Vector2.ZERO
	shade.size = Vector2(vs.x * (0.62 if screen == "title" else 1.0), vs.y)
	shade.modulate.a = 1.0 if screen == "title" else 0.75
	veil.visible = UiSkins.covil() and screen != "title"
	veil.size = vs
	var m := clampf(vs.x * 0.07, 32.0, 140.0)
	title_box.position = Vector2(m - (1.0 - fade) * 30.0, (vs.y - title_box.size.y) * 0.5)
	title_box.modulate.a = fade
	deck_screen.position = Vector2((vs.x - deck_screen.size.x) * 0.5, (vs.y - deck_screen.size.y) * 0.5 + (1.0 - fade) * 24.0)
	deck_screen.modulate.a = fade
	var cfit := minf(CAMPAIGN_MAX_SCALE, minf(vs.y * 0.96 / maxf(campaign.size.y, 1.0), vs.x * 0.98 / maxf(campaign.size.x, 1.0)))
	campaign.scale = Vector2.ONE * cfit
	campaign.position = (vs - campaign.size * cfit) * 0.5 + Vector2(0, (1.0 - fade) * 24.0)
	campaign.modulate.a = fade
	rare_screen.position = Vector2((vs.x - rare_screen.size.x) * 0.5, (vs.y - rare_screen.size.y) * 0.5 + (1.0 - fade) * 24.0)
	rare_screen.modulate.a = fade
	collection.position = Vector2((vs.x - collection.size.x) * 0.5, (vs.y - collection.size.y) * 0.5 + (1.0 - fade) * 24.0)
	collection.modulate.a = fade
	compendium.position = Vector2((vs.x - compendium.size.x) * 0.5, (vs.y - compendium.size.y) * 0.5 + (1.0 - fade) * 24.0)
	compendium.modulate.a = fade
	settings.position = (vs - settings.size) * 0.5
	footer.text = VERSION + "   ·   " + tr("UI_MENU_KEYS")
	footer.position = Vector2(m, vs.y - 34)
	footer.visible = screen != "campaign"   # o mapa da campanha ocupa a tela até embaixo


# ---------------------------------------------------------------- pele Diário

## Papel da mesa que cada tela usa (o grupo sai do mesmo maço do vilão; a rara é coisa da coleção).
func _desk_id(s: String) -> String:
	return {"campaign": "decks", "rare": "collection"}.get(s, s)


func _screen_node(s: String) -> Control:
	match s:
		"title":
			return title_root
		"decks":
			return deck_screen
		"campaign":
			return campaign
		"rare":
			return rare_screen
		"collection":
			return collection
		"compendium":
			return compendium
		"settings":
			return settings
	return null


func _final_pos(s: String, c: Control, vs: Vector2) -> Vector2:
	if s == "title" and UiSkins.mapa():
		return (vs - c.size) * 0.5
	if s == "title":
		var m := clampf(vs.x * 0.06, 28.0, 120.0)
		return Vector2(m, (vs.y - c.size.y) * 0.5)
	return (vs - c.size) * 0.5


## A tela aberta sobe do papel dela na mesa (escala, giro e posição); a anterior desce de volta.
func _process_desk(delta: float) -> void:
	fade = minf(fade + delta * 2.6, 1.0)
	prev_fade = minf(prev_fade + delta * 3.2, 1.0)
	var vs := get_viewport_rect().size
	for s in ["title", "decks", "campaign", "rare", "collection", "compendium"]:
		var c := _screen_node(s)
		if c == null:
			continue
		var cur: bool = s == screen
		var leaving: bool = s == prev_screen and prev_fade < 1.0
		c.visible = cur or leaving
		# A tela que está saindo (descendo de volta para a mesa) não pega o mouse: ela cobria os papéis e um
		# clique logo depois do Esc caía nela (achado do --menutest, 10/11/2026).
		c.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED if cur else Control.MOUSE_BEHAVIOR_DISABLED
		if not c.visible:
			continue
		var e := ease(fade, -2.2) if cur else 1.0 - ease(prev_fade, 2.0)
		var from := desk.screen_point(_desk_id(s)) if is_instance_valid(desk) else Vector2(vs.x * 0.5, vs.y * 0.85)
		var fin := _final_pos(s, c, vs)
		c.pivot_offset = c.size * 0.5
		# O mapa da campanha pode crescer além de 1 para encher a tela (19/11/2026); as outras folhas, não.
		var fit := minf(CAMPAIGN_MAX_SCALE if s == "campaign" else 1.0, minf(vs.y * 0.94 / maxf(c.size.y, 1.0), vs.x * 0.96 / maxf(c.size.x, 1.0)))
		c.scale = Vector2.ONE * lerpf(0.16, fit, e)
		c.position = (from - c.size * 0.5).lerp(fin, e)
		c.rotation = lerpf(deg_to_rad(9.0 if s.length() % 2 == 0 else -9.0), deg_to_rad((-0.35 if UiSkins.mapa() else -1.2) if s == "title" else 0.0), e)
		c.modulate.a = clampf(e * 3.0, 0.0, 1.0)
	settings.position = (vs - settings.size) * 0.5
	footer.text = VERSION + "   ·   " + tr("UI_MENU_KEYS")
	footer.position = Vector2(clampf(vs.x * 0.06, 28.0, 120.0), vs.y - 34)
	footer.add_theme_color_override("font_color", Color(0.85, 0.78, 0.66))
	# As folhas grandes (vilão, grupo, coleção) cobrem o rodapé em 1280x720: ele só aparece no título.
	footer.visible = screen == "title"


## Duas tiras de fita crepe nos cantos de cima da folha.
func _tapes(sheet: Control) -> void:
	var w := sheet.size.x
	for spec in [[Vector2(-10, 4), -38.0], [Vector2(w - 70, -4), 34.0]]:
		var o: Vector2 = spec[0]
		var a := deg_to_rad(spec[1])
		var pts := PackedVector2Array()
		for q in [Vector2(0, 0), Vector2(86, 0), Vector2(86, 26), Vector2(0, 26)]:
			pts.append(o + Vector2(36, 0) + (q - Vector2(43, 13)).rotated(a))
		sheet.draw_colored_polygon(pts, Color(0.9, 0.84, 0.64, 0.88))


## Contratos dos vilões: nome, retrato a nanquim, passiva e combos como cláusulas, assinatura em sangue e lacre.
func _fill_contracts() -> void:
	for id in data.villain_ids:
		var p := PanelContainer.new()
		UiDiario.dress(p, "contract", 34.0, {"grime": 0.7, "seed": UiDiario.seed_of(id), "shadow": 10.0, "rough": 2.6}, true)
		p.custom_minimum_size = Vector2(380, 0)
		if not meta.villains.has(id):
			p.modulate = Color(0.75, 0.72, 0.7)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		p.add_child(v)
		var k := Label.new()
		k.text = tr("UI_VILLAIN_TAG")
		k.add_theme_font_override("font", UiDiario.font("type"))
		k.add_theme_font_size_override("font_size", 15)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(k)
		var nm := Label.new()
		nm.text = tr("DECK_" + id)
		nm.add_theme_font_override("font", UiDiario.font("fell"))
		nm.add_theme_font_size_override("font_size", 46)
		nm.add_theme_color_override("font_color", UiDiario.BLOOD)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		var art := TextureRect.new()
		art.texture = villain_tex(data, id)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(0, 100)
		v.add_child(art)
		var lines: PackedStringArray = UiKit.deck_rules_text(data, id).split("\n", false)
		for i in lines.size():
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var sec := Label.new()
			sec.text = "§%d" % (i + 1)
			sec.add_theme_font_override("font", UiDiario.font("fell"))
			sec.add_theme_font_size_override("font_size", 19)
			sec.add_theme_color_override("font_color", UiDiario.BLOOD)
			row.add_child(sec)
			var rl := Tips.label(lines[i].trim_prefix("• "), 15, UiDiario.INK, 340.0)
			rl.add_theme_font_override("normal_font", UiDiario.font("type"))
			rl.add_theme_font_size_override("normal_font_size", 15)
			row.add_child(rl)
			v.add_child(row)
		# Sem dicas de combo (17/11/2026): o jogador descobre sozinho.
		var gap := Control.new()
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		gap.custom_minimum_size = Vector2(0, 6)
		v.add_child(gap)
		var sign := HBoxContainer.new()
		sign.add_theme_constant_override("separation", 10)
		var line := Control.new()
		line.custom_minimum_size = Vector2(0, 52)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sd := float(data.villain_ids.find(id)) * 1.7
		line.draw.connect(func():
			var y := line.size.y - 14.0
			line.draw_line(Vector2(0, y), Vector2(line.size.x, y), UiDiario.INK, 1.5, true)
			var pts := PackedVector2Array()
			for j in 40:
				var x := 6.0 + j * (line.size.x * 0.7) / 40.0
				pts.append(Vector2(x, y - 14.0 + sin(j * 0.9 + sd) * 9.0 * (1.0 - j / 46.0) + sin(j * 2.3) * 3.0))
			line.draw_polyline(pts, UiDiario.BLOOD, 2.4, true)
			var f := UiDiario.font("type")
			line.draw_string(f, Vector2(0, line.size.y - 0.0), tr("UI_PACT_LORD"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(UiDiario.INK, 0.7)))
		sign.add_child(line)
		var seal := UiDiario.badge(UiDiario.BLOOD, 24, 58.0, "crystal")
		(seal.get_node("N") as Label).text = tr("DECK_" + id).left(1).to_upper()
		(seal.get_node("N") as Label).add_theme_font_override("font", UiDiario.font("fell"))
		sign.add_child(seal)
		v.add_child(sign)
		var b := Button.new()
		b.text = "UI_PICK_VILLAIN"
		if not meta.villains.has(id):
			b.text = tr("UI_VILLAIN_LOCKED").format({"n": _phase_unlocking(id)})
			b.disabled = true
		b.custom_minimum_size = Vector2(0, 50)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 21)
		b.pressed.connect(func():
			pending_villain = id
			_start_villain())
		var lit := func(on: bool): UiKit.set_hot(p, on)
		b.focus_entered.connect(_fill_preview.bind(id))
		b.focus_entered.connect(lit.bind(true))
		b.focus_exited.connect(lit.bind(false))
		b.mouse_entered.connect(func(): b.grab_focus())
		p.mouse_entered.connect(func(): b.grab_focus())
		v.add_child(b)
		p.rotation_degrees = [-1.2, 0.6, 1.4][data.villain_ids.find(id) % 3]
		deck_row.add_child(p)


# ---------------------------------------------------------------- telas em pergaminho (rodada de UI 13/11/2026)
# Escolha do vilão e do grupo de heróis refeitas no kit das cartas (UiParch): uma folha com moldura dourada,
# lista à esquerda e o detalhe do item em foco à direita; texto corrido em Alegreya Sans de 17-19 (o antigo, em
# datilografada de 14-15, não se lia em 1280x720). Os botões mantêm os textos-chave (UI_PICK_VILLAIN,
# UI_START_RUN) que o --menutest procura.

var v_tabs := {}             # id do vilão → botão da lista
var v_focus := ""            # vilão em foco no detalhe
var v_art: Control
var v_name: Label
var v_status: Label
var v_rules: VBoxContainer
var v_combos: VBoxContainer
var v_pick: Button

const P_TEXT_W := 560.0
const LOCK := ""


## Texto com palavras-chave (as mesmas dicas das cartas), em Alegreya Sans a tinta.
func _rich(text: String, size: int, col := UiParch.INK, w := 0.0, center := false) -> RichTextLabel:
	var l := Tips.label(text, size, col, w, center)
	UiParch.style_label(l, "body", size, col)
	l.add_theme_font_override("bold_font", UiParch.font("bold"))
	l.add_theme_font_size_override("bold_font_size", size)
	return l


## Folha de pergaminho com moldura dourada, que sobe da mesa como as outras telas.
func _sheet(margin := 30.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiParch.box("gold", margin))
	p.set_meta("paper", true)
	return p


## Retrato pintado (assets/ui/portraits/); sem ele, o desenho antigo.
func _art_for(id: String, kind: String) -> Texture2D:
	var t := UiParch.portrait(kind + "_" + id)
	if t != null:
		return t
	return villain_tex(data, id) if kind == "villain" else UiDiario.card_tex("hero_" + id)


func _paper_btn(key: String, w: float, h: float, size := 22) -> Button:
	var b := Button.new()
	b.text = key
	b.custom_minimum_size = Vector2(w, h)
	UiParch.paper_button(b, size)
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


func _build_villains_parch() -> void:
	deck_screen = _sheet(30.0)
	add_child(deck_screen)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	deck_screen.add_child(root)
	root.add_child(UiParch.ribbon_title(tr("UI_CHOOSE_VILLAIN"), 34))
	var sub := _rich(tr("UI_CHOOSE_VILLAIN_SUB"), 18, UiParch.INK_SOFT, 1060.0, true)
	sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(sub)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 26)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL   # prende a linha do Voltar no fundo da folha
	root.add_child(body)
	# Lista dos vilões: retrato, nome e situação (liberado, bloqueado, último escolhido).
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	list.custom_minimum_size = Vector2(350, 0)
	body.add_child(list)
	deck_row = HBoxContainer.new()   # compat: o caminho das outras peles limpa esta linha
	for id in data.villain_ids:
		var b := Button.new()
		b.custom_minimum_size = Vector2(350, 118)
		UiParch.paper_button(b, 20)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_top = 9
		row.offset_right = -10
		row.offset_bottom = -9
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(row)
		var art := UiParch.framed_art(_art_for(id, "villain"), Vector2(104, 100))
		art.name = "Art"
		row.add_child(art)
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)
		var nm := UiParch.label(tr("DECK_" + id), "title", 23, UiParch.BLOOD)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(nm)
		var st := UiParch.label("", "body", 16, UiParch.INK_SOFT)
		st.name = "Status"
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(st)
		b.focus_entered.connect(_focus_villain.bind(id))
		b.mouse_entered.connect(func(): b.grab_focus())
		b.pressed.connect(func():
			if meta.villains.has(id):
				pending_villain = id
				_start_villain())
		list.add_child(b)
		v_tabs[id] = b
	# Detalhe do vilão em foco.
	var det := VBoxContainer.new()
	det.add_theme_constant_override("separation", 10)
	det.custom_minimum_size = Vector2(880, 0)
	body.add_child(det)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 24)
	det.add_child(top)
	v_art = Control.new()
	v_art.custom_minimum_size = Vector2(300, 288)
	top.add_child(v_art)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	info.add_child(UiParch.label(tr("UI_VILLAIN_TAG"), "italic", 18, UiParch.INK_SOFT))
	v_name = UiParch.label("", "title", 44, UiParch.BLOOD)
	info.add_child(v_name)
	v_status = UiParch.label("", "bold", 17, UiParch.INK_SOFT)
	info.add_child(v_status)
	info.add_child(UiParch.divider(P_TEXT_W))
	v_rules = VBoxContainer.new()
	v_rules.add_theme_constant_override("separation", 8)
	info.add_child(v_rules)
	v_combos = VBoxContainer.new()
	v_combos.visible = false   # sem dicas de combo (17/11/2026)
	v_combos.add_theme_constant_override("separation", 4)
	det.add_child(v_combos)
	det.add_child(UiParch.divider(880))
	preview_head = UiParch.label("", "title", 21, UiParch.INK)
	det.add_child(preview_head)
	preview_row = HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 6)
	det.add_child(preview_row)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 16)
	root.add_child(btns)
	var back := _paper_btn("UI_BACK", 180, 52)
	back.pressed.connect(func(): show_screen("campaign"))
	btns.add_child(back)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(gap)
	v_pick = Button.new()
	v_pick.text = "UI_PICK_VILLAIN"
	v_pick.custom_minimum_size = Vector2(400, 60)
	UiParch.ribbon_button(v_pick, "monster", 26)
	v_pick.mouse_entered.connect(func(): v_pick.grab_focus())
	v_pick.pressed.connect(func():
		pending_villain = v_focus
		_start_villain())
	btns.add_child(v_pick)


func _fill_villains_parch() -> void:
	for id in v_tabs:
		var b: Button = v_tabs[id]
		var open: bool = meta.villains.has(id)
		var st := b.find_child("Status", true, false) as Label
		if not open:
			st.text = LOCK + tr("UI_VILLAIN_LOCKED").format({"n": _phase_unlocking(id)})
		elif id == meta.villain:
			st.text = tr("UI_VILLAIN_LAST")
		else:
			st.text = tr("UI_VILLAIN_READY")
		st.add_theme_color_override("font_color", UiParch.INK_SOFT if open else UiParch.BLOOD)
		(b.find_child("Art", true, false) as Control).modulate = Color.WHITE if open else Color(0.55, 0.52, 0.5)
	_focus_villain(_default_villain())
	if not v_measured:
		_measure_villain_sheet()


var v_measured := false


## A folha cresce ou encolhe conforme o texto do vilão em foco, e a tela é recentrada a cada frame:
## passa por todos uma vez, guarda o maior tamanho e o trava como mínimo, para o tamanho nunca mudar.
func _measure_villain_sheet() -> void:
	v_measured = true
	var keep := _default_villain()
	var best := Vector2.ZERO
	var rules_h := 0.0
	var combos_h := 0.0
	for id in data.villain_ids:
		_focus_villain(id)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		rules_h = maxf(rules_h, v_rules.get_combined_minimum_size().y)
		combos_h = maxf(combos_h, v_combos.get_combined_minimum_size().y)
		best = best.max(deck_screen.get_combined_minimum_size())
	# Cada bloco variável ganha a altura do maior: nada abaixo dele (cartas, Voltar) se mexe ao trocar de vilão.
	v_rules.custom_minimum_size.y = rules_h
	v_combos.custom_minimum_size.y = combos_h
	await get_tree().process_frame
	best = deck_screen.get_combined_minimum_size()
	deck_screen.custom_minimum_size = best
	deck_screen.reset_size()
	_focus_villain(keep)


## Detalhe do vilão: retrato grande, passiva e vida dos heróis, combos, baralho inicial e o botão de escolher.
func _focus_villain(id: String) -> void:
	if v_focus == id and v_art.get_child_count() > 0:
		return
	v_focus = id
	for k in v_tabs:
		var on: bool = k == id
		(v_tabs[k] as Button).add_theme_stylebox_override("normal", UiParch.button_box("hover" if on else "normal"))
	var open: bool = meta.villains.has(id)
	for c in v_art.get_children():
		c.queue_free()
	var art := UiParch.framed_art(_art_for(id, "villain"), v_art.custom_minimum_size, "frame_legend")
	art.modulate = Color.WHITE if open else Color(0.6, 0.57, 0.55)
	v_art.add_child(art)
	v_name.text = tr("DECK_" + id)
	v_status.text = tr("UI_VILLAIN_READY") if open else LOCK + tr("UI_VILLAIN_LOCKED").format({"n": _phase_unlocking(id)})
	v_status.add_theme_color_override("font_color", UiParch.GOOD if open else UiParch.BLOOD)
	UiKit.clear(v_rules)
	var lines: PackedStringArray = UiKit.deck_rules_text(data, id).split("\n", false)
	for i in lines.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var mark := UiParch.label("◆", "bold", 15, UiParch.GOLD)
		mark.custom_minimum_size = Vector2(16, 0)
		mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		mark.offset_top = 0
		row.add_child(mark)
		row.add_child(_rich(lines[i].trim_prefix("• "), 19, UiParch.INK, P_TEXT_W - 30.0))
		v_rules.add_child(row)
	UiKit.clear(v_combos)
	for i in 0:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var n := UiParch.label(str(i + 1), "heavy", 18, UiParch.BLOOD)
		n.custom_minimum_size = Vector2(18, 0)
		row.add_child(n)
		row.add_child(_rich(tr("VCOMBO_%s_%d" % [id, i + 1]), 17, UiParch.INK, 840.0))
		v_combos.add_child(row)
	_fill_preview(id)
	v_pick.disabled = not open
	v_pick.text = "UI_PICK_VILLAIN" if open else LOCK + tr("UI_VILLAIN_LOCKED").format({"n": _phase_unlocking(id)})
