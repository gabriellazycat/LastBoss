class_name CollectionScreen
extends VBoxContainer
## Coleção do menu: desbloquear cartas com Almas e montar o deck base (10 cartas) que vai para a run.

signal closed

const COLS := 6
const CELL_W := 132.0

var data: GameData
var meta: MetaSave
var souls_l: Label
var grid: GridContainer
var deck_box: VBoxContainer
var deck_head: Label
var err_l: Label
var presets: HBoxContainer


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 30)
	var t := UiKit.title(44)
	t.text = "UI_COLLECTION"
	head.add_child(t)
	souls_l = UiKit.title(30, UiKit.GOLD)
	souls_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(souls_l)
	add_child(head)
	var sub := UiKit.label(17, UiKit.MUTED)
	sub.text = "UI_COLLECTION_SUB"
	add_child(sub)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 24)
	add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(COLS * (CELL_W + 8), 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid = GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	body.add_child(scroll)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	deck_head = UiKit.title(26, UiKit.TEXT)
	right.add_child(deck_head)
	deck_box = VBoxContainer.new()
	deck_box.add_theme_constant_override("separation", 3)
	right.add_child(deck_box)
	err_l = UiKit.label(15, UiKit.BAD)
	err_l.autowrap_mode = TextServer.AUTOWRAP_WORD
	err_l.custom_minimum_size = Vector2(370, 0)
	right.add_child(err_l)
	var pl := UiKit.label(15, UiKit.MUTED)
	pl.text = "UI_PRESETS"
	right.add_child(pl)
	presets = HBoxContainer.new()
	presets.add_theme_constant_override("separation", 6)
	right.add_child(presets)
	var back := Button.new()
	back.text = "UI_BACK"
	back.custom_minimum_size = Vector2(200, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_close)
	right.add_child(back)


func open() -> void:
	refresh()
	(grid.get_child(0) as Control).grab_focus.call_deferred()


func _close() -> void:
	meta.save()
	closed.emit()


## Célula de carta com arte e nome (também usada na tela de Pacto).
static func cell(d: CardDef, w := CELL_W) -> PanelContainer:
	var p := UiKit.panel(Color(0.04, 0.03, 0.06), UiKit.RARITY_COLORS[d.rarity], 2)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.texture = CardArt.textures.get(d.id)
	art.custom_minimum_size = Vector2(w - 4, (w - 4) * 0.52)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gem := UiKit.badge(UiKit.ELIXIR, 14, 22.0)
	(gem.get_node("N") as Label).text = str(d.cost)
	gem.position = Vector2(1, 1)
	art.add_child(gem)
	var cl := UiKit.label(12, Color(0.92, 0.9, 0.98), 3)
	cl.text = TranslationServer.translate("CARD_" + d.id)
	if UiSkins.covil():
		cl.add_theme_font_size_override("font_size", UiCovil.fit_size(UiCovil.font("body"), cl.text, roundi(12 * UiCovil.TEXT_SCALE), w - 8.0, 10))
	cl.custom_minimum_size = Vector2(w - 4, 0)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(art)
	v.add_child(cl)
	p.add_child(v)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p


## Cadeado sobre a arte de uma carta bloqueada.
static func _lock() -> Control:
	var k := Control.new()
	k.set_anchors_preset(Control.PRESET_FULL_RECT)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k.draw.connect(func():
		var c := Vector2(k.size.x * 0.5, k.size.y * 0.36)
		var gold := Color(1.0, 0.85, 0.55)
		k.draw_arc(c + Vector2(0, -4), 8.0, PI, TAU, 16, Color(0, 0, 0, 0.8), 5.0, true)
		k.draw_arc(c + Vector2(0, -4), 8.0, PI, TAU, 16, gold, 3.0, true)
		k.draw_rect(Rect2(c + Vector2(-12, -4), Vector2(24, 18)).grow(1.5), Color(0, 0, 0, 0.85))
		k.draw_rect(Rect2(c + Vector2(-12, -4), Vector2(24, 18)), gold)
		k.draw_circle(c + Vector2(0, 4), 3.0, Color(0.2, 0.12, 0.05)))
	return k


func refresh() -> void:
	souls_l.text = tr("UI_SOULS").format({"n": meta.souls})
	var had_focus := -1
	for k in grid.get_child_count():
		if grid.get_child(k).has_focus():
			had_focus = k
	UiKit.clear(grid)
	for d in data.pool:
		grid.add_child(_grid_button(d))
	if had_focus >= 0 and had_focus < grid.get_child_count():
		(grid.get_child(had_focus) as Control).grab_focus.call_deferred()
	_fill_deck()


func _grid_button(d: CardDef) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(CELL_W, CELL_W * 0.52 + 52)
	b.flat = true
	# A célula já tem moldura; o botão só marca o foco (teclado e controle) com um contorno dourado.
	b.set_meta("no_frame", true)
	if UiSkins.covil():
		var fs := StyleBoxFlat.new()
		fs.draw_center = false
		fs.border_color = UiKit.GOLD
		fs.set_border_width_all(2)
		fs.set_corner_radius_all(3)
		fs.set_expand_margin_all(4)
		# A sombra da célula (10 px) cobria o contorno: ele fica por fora dela, e a célula não desenha sombra.
		fs.set_border_width_all(3)
		b.add_theme_stylebox_override("focus", fs)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var c := cell(d)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.ignore_mouse(c)   # a célula inteira é o botão (antes só a parte de baixo respondia)
	if UiSkins.covil() and c.material:
		c.material = c.material.duplicate()
		(c.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
		c.get_theme_stylebox("panel").set_expand_margin_all(0)
	v.add_child(c)
	var foot := UiKit.label(13, UiKit.TEXT, 3)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.custom_minimum_size = Vector2(CELL_W, 0)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if meta.is_unlocked(d.id):
		var n := meta.deck.count(d.id)
		foot.text = tr("UI_IN_DECK").format({"n": n}) if n > 0 else tr("UI_ADD")
		foot.add_theme_color_override("font_color", UiKit.GOLD if n > 0 else UiKit.MUTED)
		b.pressed.connect(func():
			if meta.can_add(d.id):
				meta.deck.append(d.id)
				refresh())
	else:
		var cost := meta.unlock_cost(d.id)
		foot.text = tr("UI_UNLOCK").format({"n": cost})
		# Preço que ainda não dá para pagar: cobre (o vermelho parecia erro).
		foot.add_theme_color_override("font_color", UiKit.GOLD if meta.souls >= cost else Color(0.88, 0.6, 0.45))
		c.modulate = Color(0.62, 0.58, 0.64)
		c.add_child(_lock())
		b.pressed.connect(func():
			if meta.unlock(d.id):
				meta.save()
				refresh())
	v.add_child(foot)
	b.add_child(v)
	Tips.attach(b, func(): return Tips.card_entries(d, [], true))
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


func _fill_deck() -> void:
	var D: Dictionary = data.rules["deck"]
	deck_head.text = tr("UI_YOUR_DECK").format({"n": meta.deck.size(), "max": int(D["size"])})
	UiKit.clear(deck_box)
	var order := meta.deck.duplicate()
	order.sort_custom(func(a, b): return data.card(a).cost < data.card(b).cost or (data.card(a).cost == data.card(b).cost and a < b))
	for k in order.size():
		var id: String = order[k]
		var d := data.card(id)
		var row := Button.new()
		row.text = "%d   %s" % [d.cost, tr("CARD_" + id)]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.custom_minimum_size = Vector2(370, 34)
		row.add_theme_font_size_override("font_size", 16)
		row.add_theme_color_override("font_color", UiKit.RARITY_COLORS[d.rarity].lightened(0.45))
		if UiSkins.covil():
			row.icon = CardArt.textures.get(id)
			row.expand_icon = true
			row.add_theme_constant_override("icon_max_width", 40)
		row.tooltip_text = ""
		row.pressed.connect(func():
			meta.deck.erase(id)
			refresh())
		Tips.attach(row, func(): return Tips.card_entries(d, [], true))
		deck_box.add_child(row)
	var errs := meta.deck_errors(meta.deck)
	err_l.text = "\n".join(errs.map(func(e): return tr(e).format({"n": int(D["size"])}))) if errs.size() > 0 else tr("UI_DECK_OK")
	err_l.add_theme_color_override("font_color", UiKit.BAD if errs.size() > 0 else UiKit.GOOD)
	UiKit.clear(presets)
	for pid in MainMenu.DECKS:
		var pb := Button.new()
		pb.text = tr("DECK_" + pid)
		pb.custom_minimum_size = Vector2(118, 40)
		var list: Array = data.deck(pid)["cards"]
		pb.disabled = not list.all(func(id): return meta.is_unlocked(id))
		pb.pressed.connect(func():
			meta.deck = list.duplicate()
			refresh())
		presets.add_child(pb)


func _unhandled_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
