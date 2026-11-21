class_name CardReader
extends Control
## Leitor de carta da coleção (pele "Mapa aberto"): um papel grande sobre um véu escuro com a carta em tamanho
## grande (o molde real, o mesmo do jogo) e, ao lado, o texto explicado em letra de leitura: o que a carta faz, os
## números, cada palavra-chave explicada, como evolui por nível e, se bloqueada, como liberar.
## ←/→ passam para a carta anterior/próxima da lista; Esc, "Fechar" ou um clique fora fecham.
## Coordenadas no espaço de desenho da coleção (1688x1008, o PNG do fundo); quem chama posiciona e escala.

signal closed(index: int)

const SHEET := Vector2(1400, 904)
const CARD_W := 420.0
const TEXT_W := 700.0
const BODY := 27          # texto corrido (Alegreya Sans): ~18 px de verdade em 1280x720
const SMALL := 24
const NOTE := Color("f3e8c9")

var cards: Array = []     # CardDef da lista que as setas percorrem
var index := 0
var meta: MetaSave
var place := ""           # nome do pacto, no rodapé ("Rainha da Praga · carta 3 de 32")
var area := Vector2(1688, 1008)

var sheet: Panel
var card_box: Control
var scroll: ScrollContainer
var body: VBoxContainer
var pos_l: Label
var close_b: Button


func setup(list: Array, i: int, m: MetaSave, place_name: String, area_size: Vector2) -> void:
	cards = list
	index = i
	meta = m
	place = place_name
	area = area_size


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = area
	# Véu: cobre a tela toda (passa bem da borda da coleção, que o menu escala para caber); clique nele fecha.
	var veil := Control.new()
	veil.position = Vector2(-3000, -3000)
	veil.size = area + Vector2(6000, 6000)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.draw.connect(func(): veil.draw_rect(Rect2(Vector2.ZERO, veil.size), Color(0.06, 0.04, 0.025, 0.76)))
	veil.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			close())
	add_child(veil)
	sheet = Panel.new()
	sheet.add_theme_stylebox_override("panel", UiParch.box("gold", 0))
	sheet.size = SHEET
	sheet.position = ((area - SHEET) * 0.5).round()
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(sheet)
	# A carta: o molde de verdade, grande.
	card_box = Control.new()
	card_box.position = Vector2(70, 64)
	card_box.size = Vector2(CARD_W, CARD_W * 1.4)
	card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(card_box)
	pos_l = UiParch.label("", "italic", 23, UiParch.INK_SOFT)
	pos_l.position = Vector2(50, 676)
	pos_l.size = Vector2(CARD_W + 40, 30)
	pos_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(pos_l)
	var nav := UiParch.label(tr("UI_COL_NAV"), "italic", 23, UiParch.INK_SOFT)
	nav.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nav.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.position = Vector2(70, 708)
	nav.size = Vector2(CARD_W, 64)
	sheet.add_child(nav)
	# O texto: folha mais clara, coluna estreita (linhas curtas), rolagem quando a carta tem muito o que dizer.
	var note := Panel.new()
	var ns := StyleBoxFlat.new()
	ns.bg_color = NOTE
	ns.border_color = Color(UiParch.INK, 0.75)
	ns.set_border_width_all(2)
	ns.shadow_color = Color(0, 0, 0, 0.18)
	ns.shadow_size = 6
	ns.shadow_offset = Vector2(0, 3)
	note.add_theme_stylebox_override("panel", ns)
	note.position = Vector2(548, 44)
	note.size = Vector2(TEXT_W + 100, 740)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(note)
	scroll = ScrollContainer.new()
	scroll.position = note.position + Vector2(40, 26)
	scroll.size = Vector2(TEXT_W + 30, 740 - 52)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sheet.add_child(scroll)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.custom_minimum_size = Vector2(TEXT_W, 0)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(body)
	# Botões para quem usa o mouse (o teclado e o controle usam as setas).
	var prev := _button(tr("UI_COL_PREV"), func(): step(-1))
	prev.position = Vector2(548, 808)
	var nx := _button(tr("UI_COL_NEXT"), func(): step(1))
	nx.position = Vector2(548 + TEXT_W + 100 - 190, 808)
	close_b = _button(tr("UI_COL_CLOSE"), close)
	close_b.position = Vector2(548 + (TEXT_W + 100 - 190) * 0.5, 808)
	for b in [prev, nx, close_b]:
		b.focus_neighbor_left = b.get_path()
		b.focus_neighbor_right = b.get_path()
		b.focus_neighbor_top = b.get_path()
		b.focus_neighbor_bottom = b.get_path()
	show_card()
	close_b.grab_focus.call_deferred()


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	UiParch.paper_button(b, 25)
	b.custom_minimum_size = Vector2(190, 54)
	b.size = b.custom_minimum_size
	b.pressed.connect(cb)
	sheet.add_child(b)
	return b


func step(dir: int) -> void:
	if cards.is_empty():
		return
	index = posmod(index + dir, cards.size())
	show_card()


func close() -> void:
	closed.emit(index)
	queue_free()


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e.is_action_pressed("ui_cancel"):
		close()
	elif e.is_action_pressed("ui_left"):
		step(-1)
	elif e.is_action_pressed("ui_right"):
		step(1)
	elif e.is_action_pressed("ui_up", true):
		scroll.scroll_vertical -= 90
	elif e.is_action_pressed("ui_down", true):
		scroll.scroll_vertical += 90
	elif e.is_action_pressed("ui_focus_next") or e.is_action_pressed("ui_focus_prev"):
		pass
	else:
		return
	get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- conteúdo

func show_card() -> void:
	var d: CardDef = cards[index]
	var open := meta == null or meta.is_unlocked(d.id)
	UiKit.clear(card_box)
	var c := UiKit.card(d, d.cost, [], "", CARD_W, 1)
	UiKit.ignore_mouse(c)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_box.add_child(c)
	if not open:
		c.modulate = Color(0.8, 0.77, 0.74)
		card_box.add_child(_stamp())
	pos_l.text = tr("UI_COL_POS").format({"p": place, "a": index + 1, "b": cards.size()})
	UiKit.clear(body)
	body.add_child(UiParch.label(UiKit.card_name(d), "title", 46, UiParch.BLOOD))
	var rar: String = tr("RARITY_" + ["common", "uncommon", "rare", "legendary"][clampi(d.rarity, 0, 3)])
	var tl := UiParch.label(UiKit.type_line(d) + " · " + rar, "italic", 25, UiParch.INK_SOFT)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(TEXT_W, 0)
	body.add_child(tl)
	if not open:
		body.add_child(_unlock_box(d))
	body.add_child(_numbers(d))
	body.add_child(_head("UI_COL_WHAT"))
	body.add_child(_rich(Tips.rich(UiKit.card_desc(d, 1, false, [], false), false), BODY))
	var words := _keywords(d)
	if words.size() > 0:
		body.add_child(_head("UI_COL_WORDS"))
		for id in words:
			body.add_child(_rich("[b]%s[/b] — %s" % [Tips.kw_name(id), Tips.rich(Tips.kw_desc(id), false)], SMALL))
	var lv := _levels(d)
	if lv != "":
		body.add_child(_head("UI_COL_LEVELS"))
		body.add_child(_rich(lv, SMALL))
	scroll.scroll_vertical = 0


## Carimbo "Bloqueada" torto sobre a carta.
func _stamp() -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(NOTE, 0.92)
	sb.border_color = UiParch.BLOOD
	sb.set_border_width_all(4)
	sb.set_content_margin_all(UiKit.SP_M)
	sb.content_margin_left = UiKit.SP_XL + UiKit.SP_XS
	sb.content_margin_right = UiKit.SP_XL + UiKit.SP_XS
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(UiParch.label(tr("UI_COL_LOCKED"), "title", 44, UiParch.BLOOD))
	p.position = Vector2(70, 250)
	p.rotation = deg_to_rad(-9)
	return p


func _unlock_box(d: CardDef) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UiParch.BLOOD, 0.1)
	sb.border_color = UiParch.BLOOD
	sb.set_border_width_all(3)
	sb.set_content_margin_all(UiKit.SP_L)
	UiKit.fit_margins(sb)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UiParch.label(tr("UI_COL_HOW_UNLOCK"), "title", 30, UiParch.BLOOD))
	var t := UiParch.label(UiKit.unlock_text(meta, d), "bold", BODY, UiParch.INK)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(TEXT_W - 40, 0)
	v.add_child(t)
	p.add_child(v)
	return p


func _head(key: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	v.add_child(gap)
	v.add_child(UiParch.label(tr(key), "title", 30, UiParch.BLOOD))
	var line := Control.new()
	line.custom_minimum_size = Vector2(TEXT_W, 6)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.draw.connect(func(): line.draw_line(Vector2(0, 2), Vector2(line.size.x, 2), Color(UiParch.INK, 0.45), 1.5, true))
	v.add_child(line)
	return v


func _rich(text: String, fs: int) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(TEXT_W, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiParch.style_label(l, "body", fs, UiParch.INK)
	l.add_theme_font_override("bold_font", UiParch.font("bold"))
	l.add_theme_font_size_override("bold_font_size", fs)
	l.add_theme_constant_override("line_separation", 3)
	l.text = text
	return l


## Ficha dos números: rótulo à esquerda, valor à direita (custo sempre; vida, dano, ritmo e movimento das unidades).
func _numbers(d: CardDef) -> Control:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 22)
	g.add_theme_constant_override("v_separation", 2)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows: Array = [["UI_COL_K_cost", tr("UI_COL_V_cost").format({"n": d.cost})]]
	var unit := d.is_unit or d.is_structure
	if unit and d.hp > 0.0:
		rows.append(["UI_COL_K_hp", _n(d.hp_at(1))])
	if unit and d.dps > 0.0:
		var hit := d.attack_interval >= 0.9
		rows.append(["UI_COL_K_dps", tr("UI_COL_V_dps_hit" if hit else "UI_COL_V_dps").format({"n": _n(d.dps_at(1)), "s": _n(d.attack_interval)})])
		rows.append(["UI_COL_K_attack", tr("UI_COL_V_ranged").format({"n": _n(d.range)}) if d.projectile or d.range > 2.0 else tr("UI_COL_V_melee")])
	if d.is_unit:
		if d.speed <= 0.0:
			rows.append(["UI_COL_K_speed", tr("UI_COL_V_still")])
		else:
			var k := "UI_COL_V_speed_slow" if d.speed < 3.0 else ("UI_COL_V_speed_mid" if d.speed < 4.5 else "UI_COL_V_speed_fast")
			rows.append(["UI_COL_K_speed", tr(k).format({"n": _n(d.speed)})])
		if d.count_at(1) > 1:
			rows.append(["UI_COL_K_units", tr("UI_COL_V_units").format({"n": d.count_at(1)})])
		if d.fly:
			rows.append(["UI_COL_K_fly", tr("UI_COL_V_fly")])
	for r in rows:
		g.add_child(UiParch.label(tr(r[0]), "bold", SMALL, UiParch.INK_SOFT))
		var v := UiParch.label(str(r[1]), "body", SMALL + 1, UiParch.INK)
		v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.custom_minimum_size = Vector2(TEXT_W - 200, 0)
		g.add_child(v)
	return g


static func _n(x: float) -> String:
	if is_equal_approx(x, roundf(x)) or absf(x) >= 20.0:
		return str(int(roundf(x)))
	var s := str(snappedf(x, 0.1))
	return s.replace(".", ",") if TranslationServer.get_locale().begins_with("pt") else s


## Palavras-chave da carta, sem repetir: tipo, tags, Fera e as que o texto cita.
func _keywords(d: CardDef) -> Array:
	var ids: Array = [d.type]
	ids.append_array(d.tag_names)
	if d.beast and not ids.has("beast"):
		ids.append("beast")
	for id in Tips.keywords(UiKit.card_desc(d, 1)):
		if not ids.has(id):
			ids.append(id)
	return ids.filter(func(id): return Tips.KEYWORDS.has(id))


## "Nível 1 → 2: Vida 75 → 94 · …", "Nível 2 → 3: …" e o especial do nível 3.
func _levels(d: CardDef) -> String:
	var lines: Array = []
	for a in [1, 2]:
		var t := UiKit.level_changes(d, a, a + 1)
		if t != "":
			lines.append("[b]%s[/b]  %s" % [tr("UI_COL_LV").format({"a": a, "b": a + 1}), t])
	if d.n3.size() > 0:
		var n3 := tr("N3_" + d.id).format(UiKit.card_params(d, 3))
		lines.append("[b]★[/b] " + Tips.rich(tr("UI_N3_PREVIEW").format({"t": n3}), false))
	if lines.is_empty() and (d.lvl.size() > 0 or d.n3.size() > 0):
		lines.append(tr("UI_COL_LV_SAME"))
	return "\n".join(lines)
