class_name MainMenu
extends Control
## Menu principal sobre o covil 3D: título, escolha de Pacto, coleção e configurações. Mouse, teclado e controle.

signal deck_chosen(id: String)
signal continue_run
signal settings_changed(key: String)

const DECKS := ["horde", "ruin", "treasure", "crypt", "cult"]
const VERSION := "v0.1 · MVP"
const PACT_ART := {"horde": "rat_horde", "ruin": "goblin_dynamiter", "treasure": "mimic", "crypt": "ghoul", "cult": "acolyte"}

var data: GameData
var meta: MetaSave
var screen := "title"
var shade: TextureRect
var veil: ColorRect
var title_box: VBoxContainer
var main_buttons: VBoxContainer
var continue_btn: Button
var deck_screen: Control
var deck_row: HBoxContainer
var preview_head: Label
var preview_row: HBoxContainer
var group_screen: Control
var group_row: HBoxContainer
var group_deck: Label
var pending_pact := ""
var pending_phase := -1     # fase da campanha escolhida (-1 = a próxima a vencer)
var phase_row: HBoxContainer
var phase_info: Label
var collection: CollectionScreen
var compendium: CompendiumScreen
var settings: SettingsPanel
var footer: Label
var fade := 0.0
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
	_build_group()
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
	title_box = VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 6)
	if UiSkins.diario():
		# Folha presa com duas fitas; o título a pincel e as opções em fita crepe.
		var sheet := PanelContainer.new()
		UiDiario.dress(sheet, "paper", 46.0, {"grime": 0.5, "seed": 0.21, "shadow": 12.0, "rough": 3.0})
		sheet.rotation_degrees = -1.2
		sheet.draw.connect(_tapes.bind(sheet))
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
	_menu_btn("UI_NEW_RUN", func(): show_screen("decks"))
	_menu_btn("UI_COLLECTION", func(): show_screen("collection"))
	_menu_btn("UI_COMPENDIUM", func(): show_screen("compendium"))
	_menu_btn("UI_SETTINGS", func(): show_screen("settings"))
	if OS.get_name() != "Web":
		_menu_btn("UI_QUIT", func(): get_tree().quit())


func _menu_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(380, 56)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", 24)
	if UiSkins.diario():
		b.custom_minimum_size = Vector2(0, 50)
		UiDiario.menu_button(b, 23, txt == "UI_CONTINUE")
	elif UiSkins.covil():
		UiCovil.menu_button(b, 26)
	b.pressed.connect(cb)
	b.mouse_entered.connect(func(): b.grab_focus())
	main_buttons.add_child(b)
	return b


func _build_decks() -> void:
	deck_screen = VBoxContainer.new()
	deck_screen.add_theme_constant_override("separation", 18)
	add_child(deck_screen)
	var h := UiKit.title(44)
	h.text = "UI_CHOOSE_DECK"
	deck_screen.add_child(UiDiario.tape_title(h) if UiSkins.diario() else h)
	var hs := UiKit.label(18, UiKit.MUTED)
	hs.text = "UI_CHOOSE_DECK_SUB"
	deck_screen.add_child(hs)
	deck_row = HBoxContainer.new()
	deck_row.add_theme_constant_override("separation", 18)
	deck_row.alignment = BoxContainer.ALIGNMENT_CENTER
	deck_screen.add_child(deck_row)
	# Prévia: as cartas do deck do Pacto em foco, todas à vista de uma vez.
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
	back.pressed.connect(func(): show_screen("title"))
	deck_screen.add_child(back)


func _fill_decks() -> void:
	UiKit.clear(deck_row)
	if UiSkins.diario():
		_fill_contracts()
		_fill_preview(meta.pact if DECKS.has(meta.pact) else DECKS[0])
		return
	for id in DECKS:
		var deck: Dictionary = data.deck(id)
		var p := UiKit.panel(UiKit.BG, UiKit.EDGE, 16)
		p.custom_minimum_size = Vector2(380, 300)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		p.add_child(v)
		# Brasão do Pacto: o retrato de uma carta que é a cara dele.
		var emblem := Control.new()
		emblem.custom_minimum_size = Vector2(346, 150)
		emblem.clip_contents = true
		var ea := TextureRect.new()
		ea.texture = CardArt.textures.get(PACT_ART[id])
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
		v.add_child(Tips.label(tr("DECKSTYLE_" + id), 18, Color(0.9, 0.86, 1.0), 346.0))
		var rules := Tips.label(UiKit.deck_rules_text(deck["rules"]), 16, Color(0.9, 0.86, 1.0), 346.0)
		rules.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(rules)
		var b := Button.new()
		b.text = "UI_PICK_DECK"
		if not meta.pacts.has(id):
			b.text = tr("UI_PACT_LOCKED").format({"n": _phase_unlocking(id)})
			b.disabled = true
		b.custom_minimum_size = Vector2(0, 54)
		b.add_theme_font_size_override("font_size", 22)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.pressed.connect(func():
			pending_pact = id
			show_screen("group"))
		# Material próprio: acender este Pacto não pode acender os painéis que dividem o mesmo material.
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
	_fill_preview(meta.pact if DECKS.has(meta.pact) else DECKS[0])


## Cartas do deck pronto do Pacto, da mais barata à mais cara.
func _fill_preview(id: String) -> void:
	preview_head.text = tr("UI_DECK_CONTENTS").format({"name": tr("DECK_" + id), "n": data.deck(id)["cards"].size()})
	UiKit.clear(preview_row)
	var order: Array = data.deck(id)["cards"].duplicate()
	order.sort_custom(func(a, c): return data.card(a).cost < data.card(c).cost or (data.card(a).cost == data.card(c).cost and a < c))
	for cid in order:
		var d: CardDef = data.card(cid)
		var cell := CollectionScreen.cell(d, 92.0 if UiSkins.diario() else 112.0)
		Tips.attach(cell, func(): return Tips.card_entries(d, [], true))
		preview_row.add_child(cell)


func _build_group() -> void:
	group_screen = VBoxContainer.new()
	group_screen.add_theme_constant_override("separation", 18)
	add_child(group_screen)
	var h := UiKit.title(44)
	h.text = "UI_CHOOSE_GROUP"
	group_screen.add_child(UiDiario.tape_title(h) if UiSkins.diario() else h)
	var hs := UiKit.label(18, UiKit.MUTED)
	hs.text = "UI_CHOOSE_GROUP_SUB"
	group_screen.add_child(hs)
	group_deck = UiKit.label(22, UiKit.GOLD)
	group_screen.add_child(group_deck)
	phase_row = HBoxContainer.new()
	phase_row.add_theme_constant_override("separation", 10)
	group_screen.add_child(phase_row)
	phase_info = UiKit.label(18, UiKit.TEXT)
	phase_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phase_info.custom_minimum_size = Vector2(900, 0)
	group_screen.add_child(phase_info)
	group_row = HBoxContainer.new()
	group_row.add_theme_constant_override("separation", 8)
	group_screen.add_child(group_row)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 14)
	var back := Button.new()
	back.text = "UI_BACK"
	back.custom_minimum_size = Vector2(200, 56)
	back.pressed.connect(func(): show_screen("decks"))
	btns.add_child(back)
	var go := Button.new()
	go.name = "Go"
	go.text = "UI_START_RUN"
	go.custom_minimum_size = Vector2(320, 56)
	go.add_theme_font_size_override("font_size", 24)
	go.pressed.connect(func():
		meta.pact = pending_pact
		meta.save()
		deck_chosen.emit(pending_pact))
	btns.add_child(go)
	group_screen.add_child(btns)


## O grupo que o Pacto vai enfrentar: a fila de heróis, com nível, habilidades e força de cada um.
func _fill_group() -> void:
	if pending_pact == "":
		pending_pact = meta.pact if DECKS.has(meta.pact) else DECKS[0]
	group_deck.text = tr("UI_GROUP_DECK").format({"name": tr("DECK_" + pending_pact)})
	if pending_phase < 0 or not meta.phase_open(pending_phase):
		pending_phase = _next_phase()
	_fill_phases()
	UiKit.clear(group_row)
	var P: Dictionary = data.rules["party"]
	var ph: Dictionary = data.phase(pending_phase)
	var party: Array = ph.get("party", [])
	var n := party.size()
	var mult := float(data.deck(pending_pact)["rules"].get("hero_hp_mult", 1.0)) * float(ph.get("hp_mult", 1.0))
	for i in n:
		if UiSkins.diario():
			group_row.add_child(_wanted_poster(i, n, P, mult, str(party[i])))
			continue
		var pnl := UiKit.panel(UiKit.BG, UiKit.EDGE, 12)
		pnl.custom_minimum_size = Vector2(150, 210)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		pnl.add_child(v)
		var num := UiKit.title(20)
		num.text = tr("UI_HERO_OF").format({"k": i + 1, "n": n}) + " · " + tr("HERO_" + str(party[i]))
		v.add_child(num)
		var lv := UiKit.label(18, UiKit.TEXT)
		lv.text = tr("UI_HERO_LEVEL").format({"n": i + 1})
		v.add_child(lv)
		var sk := UiKit.label(16, UiKit.MUTED)
		sk.text = tr("UI_GROUP_SKILLS").format({"n": i})
		v.add_child(sk)
		var hp := UiKit.label(16, UiKit.GOOD)
		hp.text = tr("UI_GROUP_HP").format({"n": int(round(float(data.hero["hp"]) * pow(float(P["step"]), i) * mult))})
		v.add_child(hp)
		var dm := UiKit.label(16, UiKit.BAD)
		dm.text = tr("UI_GROUP_DMG").format({"n": int(round(float(data.hero["damage"]) * pow(float(P["step"]), i)))})
		v.add_child(dm)
		group_row.add_child(pnl)


## Fase que libera o pacto (para o aviso do contrato bloqueado).
func _phase_unlocking(pid: String) -> int:
	for ph in data.phases:
		if str(ph.get("unlock_pact", "")) == pid:
			return int(ph["id"])
	return 0


## A primeira fase ainda não vencida (o tutorial, num jogo novo).
func _next_phase() -> int:
	for ph in data.phases:
		if not meta.phases_won.has(int(ph["id"])):
			return int(ph["id"])
	return 1


## Botões das fases da campanha: as fechadas ficam desligadas; a escolhida mostra o grupo.
func _fill_phases() -> void:
	UiKit.clear(phase_row)
	for ph in data.phases:
		var k := int(ph["id"])
		var b := Button.new()
		b.text = "%s · %s%s" % [tr("UI_PHASE").format({"n": k}), tr(str(ph["key"])), "  ✓" if meta.phases_won.has(k) else ""]
		b.custom_minimum_size = Vector2(0, 44)
		b.toggle_mode = true
		b.button_pressed = k == pending_phase
		b.disabled = not meta.phase_open(k)
		if b.disabled:
			b.tooltip_text = tr("UI_PHASE_LOCKED")
		b.pressed.connect(func():
			pending_phase = k
			_fill_group())
		phase_row.add_child(b)
	var ph: Dictionary = data.phase(pending_phase)
	var txt := tr("PHASED_%d" % pending_phase)
	if str(ph.get("unlock_pact", "")) != "":
		txt += "  " + tr("UI_PHASE_UNLOCKS").format({"p": tr("DECK_" + str(ph["unlock_pact"]))})
	phase_info.text = txt


func show_screen(s: String) -> void:
	if UiSkins.diario() and s != screen and is_node_ready():
		prev_screen = screen
		prev_fade = 0.0
	screen = s
	fade = 0.0
	if is_instance_valid(desk):
		desk.set_current(_desk_id(s))
		desk.set_continue(SaveGame.exists())
	title_root.visible = s == "title" or (prev_screen == "title" and prev_fade < 1.0)
	deck_screen.visible = s == "decks"
	group_screen.visible = s == "group"
	collection.visible = s == "collection"
	compendium.visible = s == "compendium"
	settings.visible = false
	if s == "title":
		continue_btn.visible = SaveGame.exists()
		(continue_btn if continue_btn.visible else main_buttons.get_child(1)).grab_focus.call_deferred()
	elif s == "decks":
		_fill_decks()
		_focus_first_deck.call_deferred()
	elif s == "group":
		_fill_group()
		(group_screen.find_child("Go", true, false) as Button).grab_focus.call_deferred()
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
		elif screen == "group":
			_fill_group.call_deferred()
		elif screen == "collection":
			collection.refresh.call_deferred()
		elif screen == "compendium":
			compendium.show_tab.call_deferred(compendium.tab)


func _unhandled_input(e: InputEvent) -> void:
	if visible and screen == "compendium" and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		show_screen("title")
		return
	if visible and screen == "group" and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		show_screen("decks")
		return
	if visible and screen == "decks" and e.is_action_pressed("ui_cancel"):
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
	group_screen.position = Vector2((vs.x - group_screen.size.x) * 0.5, (vs.y - group_screen.size.y) * 0.5 + (1.0 - fade) * 24.0)
	group_screen.modulate.a = fade
	collection.position = Vector2((vs.x - collection.size.x) * 0.5, (vs.y - collection.size.y) * 0.5 + (1.0 - fade) * 24.0)
	collection.modulate.a = fade
	compendium.position = Vector2((vs.x - compendium.size.x) * 0.5, (vs.y - compendium.size.y) * 0.5 + (1.0 - fade) * 24.0)
	compendium.modulate.a = fade
	settings.position = (vs - settings.size) * 0.5
	footer.text = VERSION + "   ·   " + tr("UI_MENU_KEYS")
	footer.position = Vector2(m, vs.y - 34)


# ---------------------------------------------------------------- pele Diário

## Papel da mesa que cada tela usa (o grupo sai do mesmo maço do Pacto).
func _desk_id(s: String) -> String:
	return {"group": "decks"}.get(s, s)


func _screen_node(s: String) -> Control:
	match s:
		"title":
			return title_root
		"decks":
			return deck_screen
		"group":
			return group_screen
		"collection":
			return collection
		"compendium":
			return compendium
		"settings":
			return settings
	return null


func _final_pos(s: String, c: Control, vs: Vector2) -> Vector2:
	if s == "title":
		var m := clampf(vs.x * 0.06, 28.0, 120.0)
		return Vector2(m, (vs.y - c.size.y) * 0.5)
	return (vs - c.size) * 0.5


## A tela aberta sobe do papel dela na mesa (escala, giro e posição); a anterior desce de volta.
func _process_desk(delta: float) -> void:
	fade = minf(fade + delta * 2.6, 1.0)
	prev_fade = minf(prev_fade + delta * 3.2, 1.0)
	var vs := get_viewport_rect().size
	for s in ["title", "decks", "group", "collection", "compendium"]:
		var c := _screen_node(s)
		if c == null:
			continue
		var cur: bool = s == screen
		var leaving: bool = s == prev_screen and prev_fade < 1.0
		c.visible = cur or leaving
		if not c.visible:
			continue
		var e := ease(fade, -2.2) if cur else 1.0 - ease(prev_fade, 2.0)
		var from := desk.screen_point(_desk_id(s)) if is_instance_valid(desk) else Vector2(vs.x * 0.5, vs.y * 0.85)
		var fin := _final_pos(s, c, vs)
		c.pivot_offset = c.size * 0.5
		var fit := minf(1.0, minf(vs.y * 0.94 / maxf(c.size.y, 1.0), vs.x * 0.96 / maxf(c.size.x, 1.0)))
		c.scale = Vector2.ONE * lerpf(0.16, fit, e)
		c.position = (from - c.size * 0.5).lerp(fin, e)
		c.rotation = lerpf(deg_to_rad(9.0 if s.length() % 2 == 0 else -9.0), deg_to_rad(-1.2 if s == "title" else 0.0), e)
		c.modulate.a = clampf(e * 3.0, 0.0, 1.0)
	settings.position = (vs - settings.size) * 0.5
	footer.text = VERSION + "   ·   " + tr("UI_MENU_KEYS")
	footer.position = Vector2(clampf(vs.x * 0.06, 28.0, 120.0), vs.y - 34)
	footer.add_theme_color_override("font_color", Color(0.85, 0.78, 0.66))


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


## Contratos dos Pactos: "Pacto da", nome antigo, desenho a nanquim, cláusulas, assinatura em sangue e lacre.
func _fill_contracts() -> void:
	for id in DECKS:
		var deck: Dictionary = data.deck(id)
		var p := PanelContainer.new()
		UiDiario.dress(p, "contract", 34.0, {"grime": 0.7, "seed": UiDiario.seed_of(id), "shadow": 10.0, "rough": 2.6}, true)
		p.custom_minimum_size = Vector2(300 if DECKS.size() > 3 else 360, 0)
		if not meta.pacts.has(id):
			p.modulate = Color(0.75, 0.72, 0.7)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		p.add_child(v)
		var k := Label.new()
		k.text = tr("UI_PACT_OF_" + id).to_upper()
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
		var ds := Tips.label(tr("DECKSTYLE_" + id), 19, UiDiario.INK, 300.0, true)
		ds.add_theme_font_override("normal_font", UiDiario.font("fell_it"))
		ds.add_theme_font_size_override("normal_font_size", 19)
		v.add_child(ds)
		var art := TextureRect.new()
		art.texture = UiDiario.card_tex("pact_" + id) if id in ["horde", "ruin", "treasure"] else CardArt.textures.get(PACT_ART[id])
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(0, 112)
		v.add_child(art)
		var lines: PackedStringArray = UiKit.deck_rules_text(deck["rules"]).split("\n", false)
		for i in lines.size():
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var sec := Label.new()
			sec.text = "§%d" % (i + 1)
			sec.add_theme_font_override("font", UiDiario.font("fell"))
			sec.add_theme_font_size_override("font_size", 19)
			sec.add_theme_color_override("font_color", UiDiario.BLOOD)
			row.add_child(sec)
			var rl := Tips.label(lines[i].trim_prefix("• "), 15, UiDiario.INK, 290.0)
			rl.add_theme_font_override("normal_font", UiDiario.font("type"))
			rl.add_theme_font_size_override("normal_font_size", 15)
			row.add_child(rl)
			v.add_child(row)
		var gap := Control.new()
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		gap.custom_minimum_size = Vector2(0, 6)
		v.add_child(gap)
		var sign := HBoxContainer.new()
		sign.add_theme_constant_override("separation", 10)
		var line := Control.new()
		line.custom_minimum_size = Vector2(0, 52)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sd := float(DECKS.find(id)) * 1.7
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
		b.text = "UI_PACT_SIGN"
		if not meta.pacts.has(id):
			b.text = tr("UI_PACT_LOCKED").format({"n": _phase_unlocking(id)})
			b.disabled = true
		b.custom_minimum_size = Vector2(0, 50)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 21)
		b.pressed.connect(func():
			pending_pact = id
			show_screen("group"))
		var lit := func(on: bool): UiKit.set_hot(p, on)
		b.focus_entered.connect(_fill_preview.bind(id))
		b.focus_entered.connect(lit.bind(true))
		b.focus_exited.connect(lit.bind(false))
		b.mouse_entered.connect(func(): b.grab_focus())
		p.mouse_entered.connect(func(): b.grab_focus())
		v.add_child(b)
		p.rotation_degrees = [-1.2, 0.6, 1.4, -0.7, 1.0][DECKS.find(id) % 5]
		deck_row.add_child(p)


## Herói do grupo como cartaz de "procura-se".
func _wanted_poster(i: int, n: int, P: Dictionary, mult: float, cls := "escudeiro") -> PanelContainer:
	var pnl := PanelContainer.new()
	UiDiario.dress(pnl, "paper", 20.0, {"grime": 0.75, "seed": 0.13 * (i + 1), "shadow": 8.0, "rough": 2.6})
	pnl.custom_minimum_size = Vector2(186, 0)
	pnl.rotation_degrees = [-2.0, 1.5, -0.8, 2.2, -1.6][i % 5]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pnl.add_child(v)
	var h := Label.new()
	h.text = "UI_WANTED"
	h.add_theme_font_override("font", UiDiario.font("fell"))
	h.add_theme_font_size_override("font_size", 26)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var art := TextureRect.new()
	var arte := UiDiario.card_tex("hero_" + cls)  # cls é a String com o id da classe
	if arte == null:
		arte = UiDiario.card_tex("hero_wanted")
	art.texture = arte
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(0, 104)
	v.add_child(art)
	var num := UiKit.title(20)
	num.text = tr("UI_HERO_OF").format({"k": i + 1, "n": n})
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(num)
	var H := data.hero_of(cls)
	var cl := UiKit.title(18)
	cl.text = tr("HERO_" + cls)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cl)
	Tips.attach(pnl, func(): return [Tips.entry(tr("HERO_" + cls), tr("HEROD_" + cls))])
	for spec in [[tr("UI_HERO_LEVEL").format({"n": i + 1}), UiDiario.INK], [tr("UI_GROUP_SKILLS").format({"n": i}), UiDiario.PAL["MUTED"]],
			[tr("UI_GROUP_HP").format({"n": int(round(float(H["hp"]) * pow(float(P["step"]), i) * mult))}), UiDiario.PAL["GOOD"]],
			[tr("UI_GROUP_DMG").format({"n": int(round(float(H["damage"]) * pow(float(P["step"]), i)))}), UiDiario.PAL["BAD"]]]:
		var l := UiKit.label(16, spec[1])
		l.text = spec[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	return pnl
