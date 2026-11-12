class_name CollectionScreen
extends VBoxContainer
## Coleção do menu: ver as cartas por dono (Praga, Dragão, Lich, Comuns) e comprar raras e lendárias com Almas.
## Não há deck montado: a run usa o baralho inicial do vilão e as ofertas saem da coleção dele.

signal closed

const COLS := 6
const CELL_W := 132.0
const TABS := ["plague", "dragon", "lich", "common"]

var data: GameData
var meta: MetaSave
var souls_l: Label
var grid: GridContainer
var tab := "plague"
var tab_row: HBoxContainer


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	if UiSkins.diario():
		draw.connect(func(): UiDiario.draw_plate(self, "paper", Vector2(34, 28)))
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
	sub.text = "UI_COLLECTION_SUB_V"
	add_child(sub)
	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	add_child(tab_row)
	for id in TABS:
		var tb := Button.new()
		tb.text = "UI_TAB_V_" + id
		tb.toggle_mode = true
		tb.custom_minimum_size = Vector2(150, 44)
		var tid: String = id
		tb.pressed.connect(func():
			tab = tid
			refresh())
		tab_row.add_child(tb)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 24)
	add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(COLS * (CELL_W + 8), 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid = GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	body.add_child(scroll)
	var back := Button.new()
	back.text = "UI_BACK"
	back.custom_minimum_size = Vector2(200, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_close)
	add_child(back)


func open() -> void:
	refresh()
	(tab_row.get_child(TABS.find(tab)) as Control).grab_focus.call_deferred()


func _close() -> void:
	meta.save()
	closed.emit()


## Célula de carta com arte e nome (também usada na tela de Pacto).
static func cell(d: CardDef, w := CELL_W) -> PanelContainer:
	if UiSkins.diario():
		var mc := UiKit.mini_card(d, d.cost, [], "", w, roundf(w * 1.32), true)
		mc.mouse_filter = Control.MOUSE_FILTER_PASS
		return mc
	var p := UiKit.panel(Color(0.04, 0.03, 0.06), UiKit.RARITY_COLORS[d.rarity], 2)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.texture = UiDiario.hand_art(d.id)
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
	for k in tab_row.get_child_count():
		(tab_row.get_child(k) as Button).button_pressed = TABS[k] == tab
	var had_focus := -1
	for k in grid.get_child_count():
		if grid.get_child(k).has_focus():
			had_focus = k
	UiKit.clear(grid)
	for d in data.pool:
		if d.owner == tab:
			grid.add_child(_grid_button(d))
	if had_focus >= 0 and had_focus < grid.get_child_count():
		(grid.get_child(had_focus) as Control).grab_focus.call_deferred()


func _grid_button(d: CardDef) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(CELL_W, (CELL_W * 1.32 + 30) if UiSkins.diario() else (CELL_W * 0.52 + 52))
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
		foot.text = tr("UI_UNLOCKED")
		foot.add_theme_color_override("font_color", UiKit.MUTED)
	elif meta.can_buy(d.id):
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
	else:
		# Sem preço em Almas: a carta vem com o vilão (ou com a rara à escolha).
		foot.text = tr("UI_UNLOCK_WITH").format({"v": tr("DECK_" + d.owner)})
		foot.add_theme_color_override("font_color", UiKit.MUTED)
		foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		foot.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		c.modulate = Color(0.62, 0.58, 0.64)
		c.add_child(_lock())
	v.add_child(foot)
	b.add_child(v)
	Tips.attach(b, func(): return Tips.card_entries(d, [], true))
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


func _unhandled_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
