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
var tab_row: Container

# Pele "Mapa aberto" (UiSkins.mapa()): a coleção é um mapa (estilo "A · o mapa", docs/ui_propostas/fotos/d6_colA.jpg).
const MAP_BG := "res://assets/ui/map/bg_colA.png"
const MAP_SIZE := Vector2(1688, 1008)   # o PNG: papel de 1640x960 com 24 px de margem
const PAPER := Vector2(24, 24)
## Centro do círculo de cada lugar, em coordenadas do papel (as estradas do fundo ligam estes pontos).
const PLACES := {"plague": Vector2(300, 225), "dragon": Vector2(300, 605), "lich": Vector2(640, 215), "common": Vector2(640, 615)}
const THUMB := Vector2(124, 116)
const MAP_COLS := 5
var map_mode := false
var head_l: Label
var count_l: Label
var info_l: Label
var grid_scroll: ScrollContainer
var shown: Array = []          # cartas da aba, na ordem da grade (o leitor percorre esta lista)
var reader: CardReader
static var _cap_done := false


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m


func _ready() -> void:
	if UiSkins.mapa():
		_build_map()
		return
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
	_close_reader()
	refresh()
	(tab_row.get_child(TABS.find(tab)) as Control).grab_focus.call_deferred()
	if map_mode and not _cap_done:
		_cap_done = true
		_capture_args.call_deferred()


func _close() -> void:
	_close_reader()
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
	if map_mode:
		_refresh_map()
		return
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
	else:
		# Carta bloqueada: mostra o desafio que a libera e o melhor progresso até agora.
		foot.text = UiKit.unlock_text(meta, d)
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
	if visible and e.is_action_pressed("ui_cancel") and not is_instance_valid(reader):
		get_viewport().set_input_as_handled()
		_close()


# ---------------------------------------------------------------- pele "Mapa aberto"

## A coleção como mapa: à esquerda os pactos são lugares ligados por estradas (o fundo já traz as estradas, os
## bosques, a rosa dos ventos e a faixa do título); à direita a grade de cartas do lugar escolhido. Clicar numa
## carta abre o leitor (CardReader).
func _build_map() -> void:
	map_mode = true
	add_theme_constant_override("separation", 0)
	var root := Control.new()
	root.custom_minimum_size = MAP_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var bg := TextureRect.new()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture = load(MAP_BG)
	bg.size = MAP_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	# Título na faixa do fundo (a faixa ocupa x 168..606, y 44..142 do papel).
	var t := UiParch.label("UI_COLLECTION", "title", 54, UiParch.INK)
	t.position = PAPER + Vector2(168, 38)
	t.size = Vector2(438, 60)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(t)
	var st := UiParch.label("UI_COL_SUBTITLE", "italic", 20, UiParch.INK_SOFT)
	st.position = PAPER + Vector2(168, 109)
	st.size = Vector2(438, 26)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(st)
	# Os lugares (um botão por pacto: o texto é a chave da aba, transparente, para os testes acharem o botão).
	tab_row = Container.new()
	tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tab_row)
	for id in TABS:
		tab_row.add_child(_place(id))
	souls_l = UiParch.label("", "italic", 22, UiParch.INK_SOFT)
	souls_l.position = PAPER + Vector2(60, 890)
	root.add_child(souls_l)
	# A metade direita: nome do lugar, contagem, grade e a linha de informação da carta em foco.
	head_l = UiParch.label("", "title", 42, UiParch.INK)
	head_l.position = PAPER + Vector2(880, 40)
	root.add_child(head_l)
	count_l = UiParch.label("", "italic", 22, UiParch.INK_SOFT)
	count_l.position = PAPER + Vector2(882, 96)
	root.add_child(count_l)
	grid_scroll = ScrollContainer.new()
	grid_scroll.position = PAPER + Vector2(862, 138)
	grid_scroll.size = Vector2(736, 712)
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid_scroll.follow_focus = true
	root.add_child(grid_scroll)
	var pad := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 10)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_scroll.add_child(pad)
	grid = GridContainer.new()
	grid.columns = MAP_COLS
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 14)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(grid)
	info_l = UiParch.label("", "italic", 21, UiParch.INK_SOFT)
	info_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_l.max_lines_visible = 2
	info_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_l.position = PAPER + Vector2(880, 858)
	info_l.size = Vector2(500, 64)
	info_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(info_l)
	var back := Button.new()
	back.text = "UI_BACK"
	UiParch.paper_button(back, 26)
	back.custom_minimum_size = Vector2(180, 56)
	back.size = back.custom_minimum_size
	back.position = PAPER + Vector2(1640 - 236, 960 - 98)
	back.pressed.connect(_close)
	root.add_child(back)


## Um lugar do mapa: círculo com a arte de uma carta do pacto, anel duplo de tinta (vermelho no escolhido),
## nome em Fell SC e "N / M cartas".
func _place(id: String) -> Button:
	var b := Button.new()
	b.text = "UI_TAB_V_" + id
	b.toggle_mode = true
	b.flat = true
	b.set_meta("no_frame", true)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(k, Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0)
	b.size = Vector2(300, 250)
	b.position = PAPER + PLACES[id] - Vector2(150, 90)
	var art := _place_art(id)
	var ring := Control.new()
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.draw.connect(func(): _draw_place(ring, b, art, id == tab))
	b.add_child(ring)
	var nm := UiParch.label(tr("UI_TAB_V_common") if id == "common" else tr("DECK_" + id), "title", 32, UiParch.INK)
	nm.name = "Name"
	nm.position = Vector2(0, 168)
	nm.size = Vector2(300, 40)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(nm)
	var cl := UiParch.label("", "italic", 21, UiParch.INK_SOFT)
	cl.name = "Count"
	cl.position = Vector2(0, 210)
	cl.size = Vector2(300, 28)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(cl)
	var hot := func(): _place_style(b, id)
	for sig in [b.focus_entered, b.focus_exited, b.mouse_entered, b.mouse_exited]:
		sig.connect(hot)
	b.pressed.connect(func():
		tab = id
		refresh())
	return b


func _place_style(b: Button, id: String) -> void:
	var on := id == tab
	var lit := b.has_focus() or b.is_hovered()
	var nm := b.get_node("Name") as Label
	nm.add_theme_color_override("font_color", UiParch.BLOOD if on or lit else UiParch.INK)
	nm.add_theme_font_size_override("font_size", 36 if on else 32)
	(b.get_child(0) as Control).queue_redraw()


## Arte do lugar: a primeira carta pintada do pacto (as já liberadas antes).
func _place_art(id: String) -> Texture2D:
	var first: Texture2D = null
	for d in data.pool:
		if d.owner != id or not UiDiario.painted(d.id):
			continue
		var t := UiDiario.hand_art(d.id)
		if t == null:
			continue
		if meta.is_unlocked(d.id):
			return t
		if first == null:
			first = t
	return first


func _draw_place(c: Control, b: Button, art: Texture2D, on: bool) -> void:
	var r := 72.0 if on else 60.0
	var ctr := Vector2(150, 90)
	var lit := b.has_focus() or b.is_hovered()
	if on:
		for k in 4:
			c.draw_circle(ctr, r + 14.0 + k * 4.0, Color(0.66, 0.2, 0.23, 0.07))
	c.draw_circle(ctr + Vector2(0, 3), r + 11.0, Color(0, 0, 0, 0.12))
	c.draw_circle(ctr, r + 9.0, Color("e8d6a8"))
	if art != null:
		var ts := art.get_size()
		var s := minf(ts.x, ts.y)
		var o := Vector2((ts.x - s) * 0.5, (ts.y - s) * 0.42)
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i in 64:
			var a := TAU * i / 64.0
			var dir := Vector2(cos(a), sin(a))
			pts.append(ctr + dir * r)
			uvs.append((o + (dir * 0.5 + Vector2(0.5, 0.5)) * s) / ts)
		c.draw_colored_polygon(pts, Color.WHITE, uvs, art)
	c.draw_arc(ctr, r + 2.0, 0, TAU, 72, UiParch.INK, 4.0, true)
	if on:
		c.draw_arc(ctr, r + 11.0, 0, TAU, 72, Color("a8323a"), 4.5, true)
	else:
		c.draw_arc(ctr, r + 10.0, 0, TAU, 72, UiParch.BLOOD if lit else UiParch.INK, 3.0 if lit else 2.5, true)


func _refresh_map() -> void:
	souls_l.text = tr("UI_SOULS").format({"n": meta.souls})
	souls_l.visible = meta.souls > 0
	for k in tab_row.get_child_count():
		var b := tab_row.get_child(k) as Button
		var id: String = TABS[k]
		b.button_pressed = id == tab
		var n := 0
		var m := 0
		for d in data.pool:
			if d.owner == id:
				m += 1
				if meta.is_unlocked(d.id):
					n += 1
		(b.get_node("Count") as Label).text = tr("UI_COL_COUNT").format({"a": n, "b": m})
		_place_style(b, id)
	var had_focus := -1
	for k in grid.get_child_count():
		if grid.get_child(k).has_focus():
			had_focus = k
	UiKit.clear(grid)
	shown.clear()
	var got := 0
	for d in data.pool:
		if d.owner == tab:
			shown.append(d)
			if meta.is_unlocked(d.id):
				got += 1
	for i in shown.size():
		grid.add_child(_map_cell(shown[i], i))
	head_l.text = tr("UI_TAB_V_common") if tab == "common" else tr("DECK_" + tab)
	count_l.text = tr("UI_COL_HEAD").format({"a": got, "b": shown.size()})
	info_l.text = tr("UI_COL_HINT")
	info_l.add_theme_color_override("font_color", UiParch.INK_SOFT)
	if had_focus >= 0 and had_focus < grid.get_child_count():
		(grid.get_child(had_focus) as Control).grab_focus.call_deferred()
	if is_instance_valid(reader):
		reader.cards = shown
		reader.index = clampi(reader.index, 0, maxi(0, shown.size() - 1))
		reader.show_card()


static var _gray: Shader

## Carta da grade: miniatura da arte numa moldura de papel leve, nome embaixo; bloqueada = apagada e "???".
func _map_cell(d: CardDef, i: int) -> Button:
	var open := meta.is_unlocked(d.id)
	var b := Button.new()
	b.flat = true
	b.set_meta("no_frame", true)
	b.custom_minimum_size = Vector2(THUMB.x, THUMB.y + 52)
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var fs := StyleBoxFlat.new()
	fs.draw_center = false
	fs.border_color = UiParch.BLOOD
	fs.set_border_width_all(3)
	fs.set_corner_radius_all(4)
	fs.set_expand_margin_all(5)
	b.add_theme_stylebox_override("focus", fs)
	var th := Control.new()
	th.size = THUMB
	th.pivot_offset = THUMB * 0.5
	th.rotation = deg_to_rad(((i * 37) % 7 - 3) * 0.4)
	th.mouse_filter = Control.MOUSE_FILTER_IGNORE
	th.draw.connect(func():
		th.draw_rect(Rect2(Vector2(1, 3), THUMB), Color(0, 0, 0, 0.18))
		th.draw_rect(Rect2(Vector2.ZERO, THUMB), Color("f1e3bd"))
		th.draw_rect(Rect2(Vector2.ONE, THUMB - Vector2(2, 2)), UiParch.INK, false, 2.0))
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # antes do tamanho: senão o tamanho fica o da textura
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = UiDiario.hand_art(d.id)
	art.position = Vector2(6, 6)
	art.size = THUMB - Vector2(12, 12)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not open:
		if _gray == null:
			_gray = Shader.new()
			_gray.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat g = dot(c.rgb, vec3(0.3, 0.59, 0.11));\n\tCOLOR = vec4(mix(vec3(g), vec3(0.95, 0.89, 0.74), 0.55), c.a);\n}\n"
		var mat := ShaderMaterial.new()
		mat.shader = _gray
		art.material = mat
	th.add_child(art)
	b.add_child(th)
	var nm := UiParch.label(UiKit.card_name(d) if open else "???", "body", 20, UiParch.INK if open else UiParch.INK_SOFT)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # antes do tamanho: sem quebra, o rótulo cresce até o texto caber
	nm.max_lines_visible = 2
	nm.add_theme_constant_override("line_spacing", -1)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(-4, THUMB.y + 5)
	nm.size = Vector2(THUMB.x + 8, 48)
	b.add_child(nm)
	b.pressed.connect(func(): _open_reader(shown.find(d)))
	b.mouse_entered.connect(func(): b.grab_focus())
	b.focus_entered.connect(func():
		if open:
			info_l.text = UiKit.card_name(d) + " · " + UiKit.type_line(d) + "  —  " + tr("UI_COL_HINT")
			info_l.add_theme_color_override("font_color", UiParch.INK_SOFT)
		else:
			info_l.text = tr("UI_COL_LOCKED") + " · " + UiKit.unlock_text(meta, d)
			info_l.add_theme_color_override("font_color", UiParch.BLOOD))
	return b


func _open_reader(i: int) -> void:
	if i < 0 or i >= shown.size():
		return
	_close_reader()
	Tips.close_all()
	reader = CardReader.new()
	reader.setup(shown, i, meta, head_l.text, MAP_SIZE)
	reader.closed.connect(func(at: int):
		reader = null
		if at >= 0 and at < grid.get_child_count():
			(grid.get_child(at) as Control).grab_focus.call_deferred())
	(get_child(0) as Control).add_child(reader)


func _close_reader() -> void:
	if is_instance_valid(reader):
		reader.queue_free()
	reader = null


## Capturas: --coltab=<aba> abre a coleção nessa aba; --colread=<id da carta> abre o leitor nessa carta.
func _capture_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--coltab="):
			tab = a.trim_prefix("--coltab=")
			refresh()
		elif a.begins_with("--colread="):
			var id := a.trim_prefix("--colread=")
			for d in data.pool:
				if d.id == id:
					tab = d.owner
					refresh()
					_open_reader(shown.find(d))
					break
