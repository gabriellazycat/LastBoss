class_name MainMenu
extends Control
## Menu principal sobre o covil 3D: título, escolha de Pacto, coleção e configurações. Mouse, teclado e controle.

signal deck_chosen(id: String)
signal continue_run
signal settings_changed(key: String)

const DECKS := ["horde", "ruin", "treasure"]
const VERSION := "v0.1 · MVP"
const PACT_ART := {"horde": "rat_horde", "ruin": "shadow_bolt", "treasure": "mimic"}

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
var my_deck_row: HBoxContainer
var my_deck_err: Label
var collection: CollectionScreen
var settings: SettingsPanel
var footer: Label
var fade := 0.0


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
	_build_title()
	_build_decks()
	collection = CollectionScreen.new()
	collection.setup(data, meta)
	collection.visible = false
	collection.closed.connect(func(): show_screen("decks"))
	add_child(collection)
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
	add_child(title_box)
	var over := UiKit.label(18, UiKit.MUTED, 3)
	over.text = "UI_TITLE_OVER"
	title_box.add_child(over)
	var t := UiKit.title(124 if UiSkins.covil() else 104)
	t.text = "LAST BOSS"
	title_box.add_child(t)
	if UiSkins.covil():
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
	title_box.add_child(main_buttons)
	continue_btn = _menu_btn("UI_CONTINUE", func(): continue_run.emit())
	_menu_btn("UI_NEW_RUN", func(): show_screen("decks"))
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
	if UiSkins.covil():
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
	deck_screen.add_child(h)
	var hs := UiKit.label(18, UiKit.MUTED)
	hs.text = "UI_CHOOSE_DECK_SUB"
	deck_screen.add_child(hs)
	deck_row = HBoxContainer.new()
	deck_row.add_theme_constant_override("separation", 18)
	deck_row.alignment = BoxContainer.ALIGNMENT_CENTER
	deck_screen.add_child(deck_row)
	# O deck montado na coleção vai com qualquer Pacto.
	var mine := UiKit.panel(UiKit.BG, UiKit.EDGE, 12)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 8)
	mine.add_child(mv)
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 20)
	var ml := UiKit.title(26, UiKit.TEXT)
	ml.text = "UI_MY_DECK"
	ml.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mh.add_child(ml)
	my_deck_err = UiKit.label(16, UiKit.BAD)
	my_deck_err.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	my_deck_err.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mh.add_child(my_deck_err)
	var build := Button.new()
	build.text = "UI_BUILD_DECK"
	build.custom_minimum_size = Vector2(240, 46)
	build.pressed.connect(func(): show_screen("collection"))
	mh.add_child(build)
	mv.add_child(mh)
	my_deck_row = HBoxContainer.new()
	my_deck_row.add_theme_constant_override("separation", 6)
	mv.add_child(my_deck_row)
	deck_screen.add_child(mine)
	var back := Button.new()
	back.text = "UI_BACK"
	back.custom_minimum_size = Vector2(200, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func(): show_screen("title"))
	deck_screen.add_child(back)


func _fill_decks() -> void:
	UiKit.clear(deck_row)
	var errs := meta.deck_errors(meta.deck)
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
		b.text = "UI_PLAY_DECK"
		b.custom_minimum_size = Vector2(0, 54)
		b.add_theme_font_size_override("font_size", 22)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.disabled = errs.size() > 0
		b.pressed.connect(func():
			meta.pact = id
			meta.save()
			deck_chosen.emit(id))
		# Material próprio: acender este Pacto não pode acender os painéis que dividem o mesmo material.
		if p.material:
			p.material = p.material.duplicate()
		var lit := func(on: bool): UiKit.set_hot(p, on)
		b.focus_entered.connect(lit.bind(true))
		b.focus_exited.connect(lit.bind(false))
		b.mouse_entered.connect(func(): b.grab_focus())
		p.mouse_entered.connect(func(): b.grab_focus())
		v.add_child(b)
		deck_row.add_child(p)
	UiKit.clear(my_deck_row)
	var order := meta.deck.duplicate()
	order.sort_custom(func(a, c): return data.card(a).cost < data.card(c).cost or (data.card(a).cost == data.card(c).cost and a < c))
	for cid in order:
		var d: CardDef = data.card(cid)
		var cell := CollectionScreen.cell(d, 108.0)
		Tips.attach(cell, func(): return Tips.card_entries(d, [], true))
		my_deck_row.add_child(cell)
	my_deck_err.text = tr(errs[0]).format({"n": int(data.rules["deck"]["size"])}) if errs.size() > 0 else tr("UI_SOULS").format({"n": meta.souls})
	my_deck_err.add_theme_color_override("font_color", UiKit.BAD if errs.size() > 0 else UiKit.GOLD)


func show_screen(s: String) -> void:
	screen = s
	fade = 0.0
	title_box.visible = s == "title"
	deck_screen.visible = s == "decks"
	collection.visible = s == "collection"
	settings.visible = false
	if s == "title":
		continue_btn.visible = SaveGame.exists()
		(continue_btn if continue_btn.visible else main_buttons.get_child(1)).grab_focus.call_deferred()
	elif s == "decks":
		_fill_decks()
		_focus_first_deck.call_deferred()
	elif s == "collection":
		collection.open()
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
		elif screen == "collection":
			collection.refresh.call_deferred()


func _unhandled_input(e: InputEvent) -> void:
	if visible and screen == "decks" and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		show_screen("title")


func _process(delta: float) -> void:
	if not visible:
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
	collection.position = Vector2((vs.x - collection.size.x) * 0.5, (vs.y - collection.size.y) * 0.5 + (1.0 - fade) * 24.0)
	collection.modulate.a = fade
	settings.position = (vs - settings.size) * 0.5
	footer.text = VERSION + "   ·   " + tr("UI_MENU_KEYS")
	footer.position = Vector2(m, vs.y - 34)
