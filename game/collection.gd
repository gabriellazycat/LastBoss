class_name CollectionScreen
extends VBoxContainer
## Biblioteca (plano de metaprogressão, 21/11/2026): o álbum de cartas por vilão. Abas por vilão + Comuns, cartas grandes
## em páginas com nível (I a VI) e "N/3 no deck"; bloqueadas tracejadas com o desafio e o progresso; filtro por custo
## de elixir; à direita a lista fina do deck (19/19) com a curva de elixir; clicar numa carta abre o zoom (atual ×
## próximo nível com os números recalculados, "Subir · preço" e "+ no deck").
## O nome da classe e o contrato com o menu continuam os da antiga Coleção: setup(d, m), open(), refresh(), closed,
## grid, tab, shown, _open_reader(i) e a estática cell().
## As compras e o deck passam por `api` (o MetaSave): buy_card_level(id) -> bool, set_deck(vid, ids) -> bool,
## deck_ok(vid, ids) -> bool. Enquanto a frente D não os tem, library_demo.gd põe um objeto com esses nomes em `api`.

signal closed

const BOARD := Vector2(1688, 1008)        # espaço de desenho: papel de 1640x960 com 24 px de margem (como a Coleção do Mapa aberto)
const PAPER := Vector2(24, 24)
const PAPER_SIZE := Vector2(1640, 960)
const CELL := Vector2(200, 253)           # a carta do álbum (compacta: arte cheia e fita do nome)
const FOOT := 44.0
const CELL_W := 132.0                    # largura padrão da cell() estática (menu e tela de Pacto)
const COLS := 5
const PER_PAGE := 10
const MAX_COPIES := 3
const DECK_SIZE := 19
const MAX_LEVEL := 6
const ROMAN := ["", "I", "II", "III", "IV", "V", "VI"]
## Faixas de custo do filtro e da curva de elixir (custo no nível atual da carta).
const BUCKETS := [[0, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 9], [10, 99]]
const BUCKET_NAMES := ["0-1", "2", "3", "4", "5", "6", "7-9", "10+"]

var data: GameData
var meta: MetaSave
var api: Object                   # quem compra nível e grava deck (padrão: o próprio meta)
var tabs: Array = []              # vilões (data.villain_ids) e "common"
var tab := "plague"
var deck_vid := "plague"          # o deck em edição: o do último vilão aberto (a aba Comuns edita o mesmo)
var work: Array = []              # deck em edição (ids); só vai para o save quando está válido
var page := 0
var cost_filter := -1             # índice em BUCKETS; -1 = todos
var shown: Array = []             # cartas da aba depois do filtro, na ordem do álbum (todas as páginas)
var zoom_id := ""
var grid: GridContainer
var tab_row: Container
var board: Control
var almas_l: Label
var head_l: Label
var count_l: Label
var page_l: Label
var prev_b: Button
var next_b: Button
var filter_row: Container
var deck_box: Control
var deck_head: Label
var deck_count_l: Label
var deck_warn: Label
var deck_list: VBoxContainer
var curve: Control
var zoom_layer: Control
var note_l: Label
static var _gray: Shader


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m
	api = m
	tabs = d.villain_ids.duplicate()
	tabs.append("common")
	tab = str(tabs[0])
	deck_vid = tab
	work = _saved_deck(deck_vid)


func _ready() -> void:
	add_theme_constant_override("separation", 0)
	board = Control.new()
	board.custom_minimum_size = BOARD
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)
	var sheet := Panel.new()
	sheet.add_theme_stylebox_override("panel", UiParch.box("gold", 0))
	sheet.position = PAPER
	sheet.size = PAPER_SIZE
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(sheet)
	var t := UiParch.label("UI_LIB_TITLE", "title", 54, UiParch.INK)
	t.position = PAPER + Vector2(48, 26)
	t.size = Vector2(420, 64)
	board.add_child(t)
	var st := UiParch.label("UI_LIB_SUB", "italic", 21, UiParch.INK_SOFT)
	st.position = PAPER + Vector2(50, 88)
	st.size = Vector2(520, 28)
	board.add_child(st)
	almas_l = UiParch.label("", "bold", 30, UiParch.ELIXIR_DEEP)
	almas_l.position = PAPER + Vector2(560, 40)
	almas_l.size = Vector2(540, 40)
	almas_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	board.add_child(almas_l)
	# Abas: um botão por vilão e a aba Comuns (o texto é a chave da aba; a contagem vai num rótulo por cima).
	tab_row = Container.new()
	tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(tab_row)
	for k in tabs.size():
		tab_row.add_child(_tab_button(str(tabs[k]), k))
	# Filtro por custo.
	var fl := UiParch.label("UI_LIB_COST", "italic", 22, UiParch.INK_SOFT)
	fl.position = PAPER + Vector2(50, 196)
	fl.size = Vector2(120, 34)
	board.add_child(fl)
	filter_row = Container.new()
	filter_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(filter_row)
	for k in BUCKETS.size() + 1:
		filter_row.add_child(_filter_button(k - 1))
	head_l = UiParch.label("", "title", 34, UiParch.INK)
	head_l.position = PAPER + Vector2(780, 192)
	head_l.size = Vector2(340, 44)
	head_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	board.add_child(head_l)
	count_l = UiParch.label("", "italic", 20, UiParch.INK_SOFT)
	count_l.position = PAPER + Vector2(780, 232)
	count_l.size = Vector2(340, 26)
	count_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	board.add_child(count_l)
	# O álbum: 5 colunas x 2 linhas por página.
	grid = GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 14)
	grid.position = PAPER + Vector2(46, 262)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(grid)
	prev_b = Button.new()
	prev_b.text = "UI_LIB_PREV"
	UiParch.paper_button(prev_b, 22)
	prev_b.position = PAPER + Vector2(46, 880)
	prev_b.size = Vector2(150, 48)
	prev_b.pressed.connect(func(): _go_page(page - 1))
	board.add_child(prev_b)
	next_b = Button.new()
	next_b.text = "UI_LIB_NEXT"
	UiParch.paper_button(next_b, 22)
	next_b.position = PAPER + Vector2(46 + 1088 - 150, 880)
	next_b.size = Vector2(150, 48)
	next_b.pressed.connect(func(): _go_page(page + 1))
	board.add_child(next_b)
	page_l = UiParch.label("", "italic", 24, UiParch.INK_SOFT)
	page_l.position = PAPER + Vector2(46 + 150, 886)
	page_l.size = Vector2(1088 - 300, 36)
	page_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board.add_child(page_l)
	_build_deck_panel()
	var back := Button.new()
	back.text = "UI_BACK"
	UiParch.paper_button(back, 26)
	back.custom_minimum_size = Vector2(180, 56)
	back.size = back.custom_minimum_size
	back.position = PAPER + Vector2(1640 - 236, 960 - 94)
	back.pressed.connect(_close)
	board.add_child(back)
	note_l = UiParch.label("", "italic", 20, UiParch.BLOOD)
	note_l.position = PAPER + Vector2(1150, 872)
	note_l.size = Vector2(230, 56)
	note_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	board.add_child(note_l)
	zoom_layer = Control.new()
	zoom_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(zoom_layer)
	if data != null:
		refresh()


func open() -> void:
	_close_zoom()
	page = 0
	cost_filter = -1
	work = _saved_deck(deck_vid)
	refresh()


func _close() -> void:
	_close_zoom()
	meta.save()
	closed.emit()


# ---------------------------------------------------------------- dados do álbum e do deck

func _lv(id: String) -> int:
	return clampi(int(meta.card_levels.get(id, 1)), 1, MAX_LEVEL)


func _cost(d: CardDef) -> int:
	return d.cost_at(_lv(d.id))


static func bucket_of(cost: int) -> int:
	for k in BUCKETS.size():
		if cost >= int(BUCKETS[k][0]) and cost <= int(BUCKETS[k][1]):
			return k
	return BUCKETS.size() - 1


func _tab_name(id: String) -> String:
	return tr("UI_TAB_V_common") if id == "common" else tr("DECK_" + id)


## Deck gravado do vilão (ou o baralho inicial dele enquanto o save não tem um).
func _saved_deck(vid: String) -> Array:
	var d: Array = meta.decks.get(vid, [])
	if d.is_empty():
		d = data.deck(vid)["cards"]
	return d.duplicate()


func deck_count(id: String) -> int:
	var n := 0
	for x in work:
		if x == id:
			n += 1
	return n


func deck_valid() -> bool:
	return work.size() == DECK_SIZE and api.deck_ok(deck_vid, work)


func _can_edit() -> bool:
	return meta.villains.has(deck_vid)


## Cartas que cabem no deck do vilão em edição: dele ou comuns, e já liberadas.
func _eligible(d: CardDef) -> bool:
	return data.in_pool(d, deck_vid) and meta.is_unlocked(d.id)


func can_add(id: String) -> bool:
	var d := data.card(id)
	return d != null and _can_edit() and _eligible(d) and work.size() < DECK_SIZE and deck_count(id) < MAX_COPIES


func deck_add(id: String) -> bool:
	if not can_add(id):
		return false
	work.append(id)
	_deck_changed()
	return true


func deck_remove(id: String) -> bool:
	if not _can_edit() or not work.has(id):
		return false
	work.remove_at(work.find(id))
	_deck_changed()
	return true


## O deck só vai para o save quando está completo e válido; incompleto fica só na tela (aviso vermelho) e,
## se a tela fechar assim, volta ao último deck gravado.
func _deck_changed() -> void:
	if work.size() == DECK_SIZE and api.deck_ok(deck_vid, work):
		api.set_deck(deck_vid, work.duplicate())
	refresh()


func buy_level(id: String) -> bool:
	var ok: bool = api.buy_card_level(id)
	refresh()
	return ok


func set_cost_filter(k: int) -> void:
	cost_filter = k if k != cost_filter else -1
	page = 0
	refresh()


func set_tab(id: String) -> void:
	tab = id
	page = 0
	if id != "common":
		if id != deck_vid:
			deck_vid = id
			work = _saved_deck(id)
	refresh()


func _go_page(p: int) -> void:
	page = clampi(p, 0, maxi(0, _pages() - 1))
	refresh()


func _pages() -> int:
	return maxi(1, ceili(float(shown.size()) / PER_PAGE))


func _filtered() -> Array:
	var out: Array = []
	for d in data.pool:
		if d.owner != tab:
			continue
		if cost_filter >= 0 and bucket_of(_cost(d)) != cost_filter:
			continue
		out.append(d)
	return out


# ---------------------------------------------------------------- peças

func _tab_button(id: String, k: int) -> Button:
	var b := Button.new()
	b.text = "UI_TAB_V_" + id
	b.toggle_mode = true
	UiParch.paper_button(b, 26)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, UiParch.button_box(st, Vector4(20, 8, 20, 30)))
	b.add_theme_stylebox_override("hover_pressed", UiParch.button_box("pressed", Vector4(20, 8, 20, 30)))
	b.size = Vector2(212, 72)
	b.position = PAPER + Vector2(46 + k * 222, 118)
	b.set_meta("tab_id", id)
	b.pressed.connect(func(): set_tab(id))
	var cl := UiParch.label("", "italic", 17, UiParch.INK_SOFT)
	cl.name = "Count"
	cl.position = Vector2(0, 44)
	cl.size = Vector2(212, 20)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(cl)
	return b


func _filter_button(k: int) -> Button:
	var b := Button.new()
	b.text = "UI_LIB_ALL" if k < 0 else BUCKET_NAMES[k]
	b.toggle_mode = true
	UiParch.paper_button(b, 20)
	b.size = Vector2(86 if k < 0 else 62, 38)
	b.position = PAPER + Vector2(172 + (0 if k < 0 else 96 + k * 68), 194)
	b.set_meta("bucket", k)
	b.pressed.connect(func():
		if k < 0:
			cost_filter = -1
			page = 0
			refresh()
		else:
			set_cost_filter(k))
	return b


## Numeral romano do nível (widget próprio: o molde só traz as placas I a III).
static func roman_badge(level: int, px: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, px)
	c.size = Vector2(px, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var ctr := Vector2(px, px) * 0.5
		var gold := Color("f0cf7a") if level >= 4 else (Color("c08a2e") if level >= 2 else Color("b8a47a"))
		c.draw_circle(ctr + Vector2(0, 1.5), px * 0.5, Color(0, 0, 0, 0.35))
		c.draw_circle(ctr, px * 0.5, Color("2b1d10"))
		c.draw_arc(ctr, px * 0.5 - 1.5, 0, TAU, 40, gold, 2.0, true)
		var f := UiParch.font("title")
		var fs := int(px * (0.44 if level < 4 else 0.38))
		c.draw_string(f, Vector2(0, ctr.y + fs * 0.34), ROMAN[clampi(level, 1, MAX_LEVEL)], HORIZONTAL_ALIGNMENT_CENTER, px, fs, gold.lightened(0.25)))
	return c


## O molde (frente C) já tem placa para este nível? Então o widget romano não repete.
static func mold_has_plaque(level: int) -> bool:
	return level >= 2 and CardMold.tex("plaque%d" % level) != null


func _dashed(c: Control, col: Color, w := 3.0) -> void:
	var r := Rect2(Vector2(2, 2), c.size - Vector2(4, 4))
	var a := r.position
	var b := r.position + Vector2(r.size.x, 0)
	var d := r.end
	var e := r.position + Vector2(0, r.size.y)
	for seg in [[a, b], [b, d], [d, e], [e, a]]:
		c.draw_dashed_line(seg[0], seg[1], col, w, 10.0, true, true)


## Célula de carta com arte e nome (também usada na tela de Pacto).
static func cell(d: CardDef, w := CELL_W) -> PanelContainer:
	var mc := UiKit.mini_card(d, d.cost, [], "", w, roundf(w * 1.32), true)
	mc.mouse_filter = Control.MOUSE_FILTER_PASS
	return mc


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



# ---------------------------------------------------------------- atualização

func refresh() -> void:
	if data == null or grid == null:
		return
	almas_l.text = tr("UI_LIB_ALMAS").format({"n": meta.almas})
	for b in tab_row.get_children():
		var id: String = b.get_meta("tab_id")
		(b as Button).button_pressed = id == tab
		var n := 0
		var m := 0
		for d in data.pool:
			if d.owner == id:
				m += 1
				if meta.is_unlocked(d.id):
					n += 1
		((b as Button).get_node("Count") as Label).text = tr("UI_LIB_COUNT").format({"a": n, "b": m})
	for b in filter_row.get_children():
		(b as Button).button_pressed = int(b.get_meta("bucket")) == cost_filter
	shown = _filtered()
	page = clampi(page, 0, _pages() - 1)
	head_l.text = _tab_name(tab)
	count_l.text = tr("UI_LIB_SHOWN").format({"n": shown.size()})
	page_l.text = tr("UI_LIB_PAGE").format({"p": page + 1, "t": _pages()})
	prev_b.disabled = page <= 0
	next_b.disabled = page >= _pages() - 1
	var had_focus := -1
	for k in grid.get_child_count():
		if grid.get_child(k).has_focus():
			had_focus = k
	UiKit.clear(grid)
	for i in range(page * PER_PAGE, mini(shown.size(), (page + 1) * PER_PAGE)):
		grid.add_child(_album_cell(shown[i], i))
	if had_focus >= 0 and had_focus < grid.get_child_count() and zoom_id == "":
		var gb := grid.get_child(had_focus) as Control
		(func():
			if is_instance_valid(gb) and gb.is_inside_tree():
				gb.grab_focus()).call_deferred()
	_refresh_deck()
	if zoom_id != "":
		_build_zoom()


## Carta do álbum: compacta (arte grande + fita do nome) com a placa romana do nível por cima, e embaixo os
## pontinhos de nível e "N/3 no deck". Bloqueada: moldura tracejada, arte apagada, o desafio e o progresso.
func _album_cell(d: CardDef, i: int) -> Button:
	var open := meta.is_unlocked(d.id)
	var lv := _lv(d.id)
	var b := Button.new()
	b.flat = true
	b.set_meta("no_frame", true)
	b.set_meta("card_id", d.id)
	b.custom_minimum_size = CELL + Vector2(0, FOOT)
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var fs := StyleBoxFlat.new()
	fs.draw_center = false
	fs.border_color = UiParch.BLOOD
	fs.set_border_width_all(3)
	fs.set_corner_radius_all(6)
	fs.set_expand_margin_all(4)
	b.add_theme_stylebox_override("focus", fs)
	if open:
		var c := UiKit.mini_card(d, d.cost_at(lv), [], "", CELL.x, CELL.y, true, mini(lv, 3))   # o molde só sabe até III (o nome ganha um + por nível)
		UiKit.ignore_mouse(c)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.position = Vector2.ZERO
		b.add_child(c)
		var rb := roman_badge(lv, 34.0)   # a carta compacta não leva placa do molde
		rb.position = Vector2(CELL.x - 42, 8)
		b.add_child(rb)
		var foot := Control.new()
		foot.position = Vector2(0, CELL.y + 6)
		foot.size = Vector2(CELL.x, FOOT - 8)
		foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		foot.draw.connect(func():
			for p in range(1, MAX_LEVEL + 1):
				var ctr := Vector2(10.0 + (p - 1) * 17.0, foot.size.y * 0.5)
				var col := Color("c08a2e") if p <= lv else Color(UiParch.INK, 0.25)
				foot.draw_colored_polygon(PackedVector2Array([ctr + Vector2(0, -6), ctr + Vector2(6, 0), ctr + Vector2(0, 6), ctr + Vector2(-6, 0)]), col))
		var n := deck_count(d.id)
		var nl := UiParch.label(tr("UI_LIB_IN_DECK").format({"n": n, "m": MAX_COPIES}), "bold", 19, UiParch.ELIXIR_DEEP if n > 0 else UiParch.INK_SOFT)
		nl.position = Vector2(112, 2)
		nl.size = Vector2(CELL.x - 112, 26)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		foot.add_child(nl)
		b.add_child(foot)
	else:
		b.add_child(_locked_cell(d))
	b.pressed.connect(func(): _open_reader(shown.find(d)))
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


func _locked_cell(d: CardDef) -> Control:
	var c := Control.new()
	c.size = CELL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		c.draw_rect(Rect2(Vector2.ZERO, CELL), Color(0.82, 0.72, 0.5, 0.28))
		_dashed(c, Color(UiParch.INK, 0.7), 3.0))
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = UiDiario.hand_art(d.id)
	art.position = Vector2(10, 10)
	art.size = Vector2(CELL.x - 20, 108)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _gray == null:
		_gray = Shader.new()
		_gray.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat g = dot(c.rgb, vec3(0.3, 0.59, 0.11));\n\tCOLOR = vec4(mix(vec3(g), vec3(0.95, 0.89, 0.74), 0.55), c.a * 0.8);\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = _gray
	art.material = mat
	c.add_child(art)
	var k := CollectionScreen._lock()
	k.set_anchors_preset(Control.PRESET_TOP_LEFT)
	k.position = Vector2(0, -6)
	k.size = Vector2(CELL.x, 120)
	c.add_child(k)
	var nm := UiParch.label("???", "title", 24, UiParch.INK_SOFT)
	nm.position = Vector2(0, 122)
	nm.size = Vector2(CELL.x, 30)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(nm)
	var tx := UiParch.label(UiKit.unlock_text(meta, d), "body", 18, UiParch.INK)
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tx.max_lines_visible = 4
	tx.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tx.position = Vector2(12, 152)
	tx.size = Vector2(CELL.x - 24, 78)
	tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(tx)
	var p: Dictionary = meta.progress.get(d.id, {})
	if not p.is_empty() and float(p.get("g", 1.0)) > 1.0:
		var ratio := clampf(float(p["v"]) / float(p["g"]), 0.0, 1.0)
		var bar := Control.new()
		bar.position = Vector2(14, CELL.y - 16)
		bar.size = Vector2(CELL.x - 28, 8)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.draw.connect(func():
			bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(UiParch.INK, 0.2))
			bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * ratio, bar.size.y)), UiParch.ELIXIR)
			bar.draw_rect(Rect2(Vector2.ZERO, bar.size), UiParch.INK, false, 1.5))
		c.add_child(bar)
	var wrap := Control.new()
	wrap.custom_minimum_size = CELL + Vector2(0, FOOT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(c)
	var lb := UiParch.label("UI_LIB_LOCKED", "italic", 19, UiParch.INK_SOFT)
	lb.position = Vector2(0, CELL.y + 8)
	lb.size = Vector2(CELL.x, 26)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wrap.add_child(lb)
	return wrap


# ---------------------------------------------------------------- deck e curva de elixir

func _build_deck_panel() -> void:
	deck_box = Control.new()
	deck_box.position = PAPER + Vector2(1160, 36)
	deck_box.size = Vector2(440, 800)
	deck_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(deck_box)
	var div := Control.new()
	div.position = PAPER + Vector2(1140, 30)
	div.size = Vector2(4, 820)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	div.draw.connect(func(): div.draw_dashed_line(Vector2(2, 0), Vector2(2, div.size.y), Color(UiParch.INK, 0.45), 2.0, 8.0))
	board.add_child(div)
	deck_head = UiParch.label("", "title", 34, UiParch.INK)
	deck_head.position = Vector2(0, 0)
	deck_head.size = Vector2(330, 44)
	deck_head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	deck_box.add_child(deck_head)
	deck_count_l = UiParch.label("", "bold", 38, UiParch.INK)
	deck_count_l.position = Vector2(330, -2)
	deck_count_l.size = Vector2(110, 48)
	deck_count_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	deck_box.add_child(deck_count_l)
	deck_warn = UiParch.label("", "italic", 20, UiParch.INK_SOFT)
	deck_warn.position = Vector2(0, 46)
	deck_warn.size = Vector2(440, 28)
	deck_box.add_child(deck_warn)
	var sc := ScrollContainer.new()
	sc.position = Vector2(0, 80)
	sc.size = Vector2(440, 528)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	deck_box.add_child(sc)
	deck_list = VBoxContainer.new()
	deck_list.add_theme_constant_override("separation", 1)
	deck_list.custom_minimum_size = Vector2(430, 0)
	sc.add_child(deck_list)
	var ct := UiParch.label("UI_LIB_CURVE", "italic", 22, UiParch.INK_SOFT)
	ct.position = Vector2(0, 622)
	ct.size = Vector2(440, 28)
	deck_box.add_child(ct)
	curve = Control.new()
	curve.position = Vector2(0, 652)
	curve.size = Vector2(440, 150)
	curve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curve.draw.connect(_draw_curve)
	deck_box.add_child(curve)


func _curve_counts() -> Array:
	var out: Array = []
	out.resize(BUCKETS.size())
	out.fill(0)
	for id in work:
		var d := data.card(id)
		if d != null:
			out[bucket_of(_cost(d))] += 1
	return out


func _draw_curve() -> void:
	var counts := _curve_counts()
	var mx := 1
	for n in counts:
		mx = maxi(mx, int(n))
	var w := curve.size.x / counts.size()
	var base := curve.size.y - 26.0
	var top := 22.0
	curve.draw_line(Vector2(0, base), Vector2(curve.size.x, base), UiParch.INK, 2.0)
	var f := UiParch.font("bold")
	for k in counts.size():
		var n: int = counts[k]
		var h := (base - top) * float(n) / mx
		var r := Rect2(k * w + 8, base - h, w - 16, h)
		if n > 0:
			curve.draw_rect(r, UiParch.ELIXIR)
			curve.draw_rect(r, UiParch.ELIXIR_DEEP, false, 2.0)
			curve.draw_string(f, Vector2(k * w, base - h - 5), str(n), HORIZONTAL_ALIGNMENT_CENTER, w, 20, UiParch.INK)
		var hot := cost_filter == k
		curve.draw_string(UiParch.font("body"), Vector2(k * w, curve.size.y - 5), BUCKET_NAMES[k], HORIZONTAL_ALIGNMENT_CENTER, w, 19, UiParch.BLOOD if hot else UiParch.INK_SOFT)


func _refresh_deck() -> void:
	deck_head.text = _tab_name(deck_vid) if deck_vid != "common" else ""
	var n := work.size()
	deck_count_l.text = "%d/%d" % [n, DECK_SIZE]
	var ok := n == DECK_SIZE
	deck_count_l.add_theme_color_override("font_color", UiParch.GOOD if ok else UiParch.BLOOD)
	if not _can_edit():
		deck_warn.text = tr("UI_LIB_VILLAIN_LOCKED")
		deck_warn.add_theme_color_override("font_color", UiParch.INK_SOFT)
	elif not ok:
		deck_warn.text = tr("UI_LIB_DECK_INCOMPLETE").format({"n": DECK_SIZE - n})
		deck_warn.add_theme_color_override("font_color", UiParch.BLOOD)
	else:
		deck_warn.text = tr("UI_LIB_DECK_RULES").format({"m": MAX_COPIES})
		deck_warn.add_theme_color_override("font_color", UiParch.INK_SOFT)
	UiKit.clear(deck_list)
	var cnt := {}
	for id in work:
		cnt[id] = int(cnt.get(id, 0)) + 1
	var ids: Array = cnt.keys()
	ids.sort_custom(func(a, b):
		var ca := _cost(data.card(a))
		var cb := _cost(data.card(b))
		if ca != cb:
			return ca < cb
		return String(TranslationServer.translate("CARD_" + str(a))) < String(TranslationServer.translate("CARD_" + str(b))))
	for id in ids:
		deck_list.add_child(_deck_row(data.card(id), int(cnt[id])))
	curve.queue_redraw()


func _deck_row(d: CardDef, n: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.custom_minimum_size = Vector2(430, 28)
	var gem := Control.new()
	gem.custom_minimum_size = Vector2(28, 28)
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cost := _cost(d)
	gem.draw.connect(func():
		UiParch.draw_drop(gem, Rect2(Vector2(2, 1), Vector2(24, 24)), 1.0)
		gem.draw_string(UiParch.font("bold"), Vector2(0, 19), str(cost), HORIZONTAL_ALIGNMENT_CENTER, 28, 16 if cost < 10 else 13, Color.WHITE))
	row.add_child(gem)
	var nb := Button.new()
	nb.flat = true
	nb.set_meta("no_frame", true)
	nb.text = UiKit.card_name(d)
	nb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nb.clip_text = true
	nb.add_theme_font_override("font", UiParch.font("body"))
	nb.add_theme_font_size_override("font_size", 21)
	for k in ["font_color", "font_focus_color", "font_pressed_color"]:
		nb.add_theme_color_override(k, UiParch.INK)
	nb.add_theme_color_override("font_hover_color", UiParch.BLOOD)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		nb.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	nb.pressed.connect(func(): _open_zoom(d.id))
	row.add_child(nb)
	var xl := UiParch.label("×%d" % n if n > 1 else "", "bold", 20, UiParch.ELIXIR_DEEP)
	xl.custom_minimum_size = Vector2(34, 0)
	row.add_child(xl)
	var rb := roman_badge(_lv(d.id), 24.0)
	rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rb)
	var mb := Button.new()
	mb.text = "-"
	mb.flat = true
	mb.set_meta("no_frame", true)
	mb.disabled = not _can_edit()
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		mb.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	mb.add_theme_font_override("font", UiParch.font("bold"))
	mb.add_theme_font_size_override("font_size", 30)
	for k in ["font_color", "font_focus_color", "font_pressed_color"]:
		mb.add_theme_color_override(k, UiParch.INK_SOFT)
	mb.add_theme_color_override("font_hover_color", UiParch.BLOOD)
	mb.add_theme_color_override("font_disabled_color", Color(UiParch.INK, 0.25))
	mb.custom_minimum_size = Vector2(30, 26)
	mb.pressed.connect(func(): deck_remove(d.id))
	row.add_child(mb)
	return row


# ---------------------------------------------------------------- zoom: atual × próximo nível

func _open_reader(i: int) -> void:
	if i < 0 or i >= shown.size():
		return
	_open_zoom((shown[i] as CardDef).id)


func _open_zoom(id: String) -> void:
	zoom_id = id
	Tips.close_all()
	_build_zoom()


func _close_zoom() -> void:
	zoom_id = ""
	if zoom_layer:
		UiKit.clear(zoom_layer)
	# devolve o foco à carta do álbum
	if grid:
		for b in grid.get_children():
			if b.has_meta("card_id") and b.get_meta("card_id") == _last_zoom:
				var fb := b as Control
				(func():
					if is_instance_valid(fb) and fb.is_inside_tree():
						fb.grab_focus()).call_deferred()
				break


var _last_zoom := ""


## Linhas da comparação: [rótulo, valor atual, valor no outro nível, mudou?, sinal (+1 subiu, -1 desceu)].
func rows(d: CardDef, a: int, b: int) -> Array:
	var out: Array = []
	var ca := d.cost_at(a)
	var cb := d.cost_at(b)
	out.append([TranslationServer.translate("LVLK_cost"), str(ca), str(cb), ca != cb, -1 if cb < ca else (1 if cb > ca else 0)])
	var keys: Array = []
	if d.is_unit:
		if d.count > 1 or d.scales("count"):
			keys.append("count")
		keys.append("hp")
		if d.dps > 0.0:
			keys.append("dps")
	for k in d.lvl:
		if k != "cost" and not keys.has(k):
			keys.append(k)
	for k in keys:
		var x: float
		var y: float
		match str(k):
			"count":
				x = d.count_at(a); y = d.count_at(b)
			"hp":
				x = d.hp_at(a) if d.is_unit else d.fxv("hp", a)
				y = d.hp_at(b) if d.is_unit else d.fxv("hp", b)
			"dps":
				x = d.dps_at(a) if d.is_unit else d.fxv("dps", a)
				y = d.dps_at(b) if d.is_unit else d.fxv("dps", b)
			_:
				x = d.fxv(k, a); y = d.fxv(k, b)
		var pct: bool = x < 1.0 and y < 1.0 and x > 0.0 and str(k) not in ["count", "hp", "dps"]
		var sx := _num(x, pct)
		var sy := _num(y, pct)
		out.append([TranslationServer.translate("LVLK_" + str(k)), sx, sy, sx != sy, 1 if y > x else (-1 if y < x else 0)])
	return out


static func _num(v: float, pct: bool) -> String:
	if pct:
		return "%d%%" % int(round(v * 100.0))
	return str(int(round(v))) if absf(v) >= 20.0 or is_equal_approx(v, round(v)) else str(snappedf(v, 0.1))


## Especial do nível VI (n3 da carta), com os números do nível dado; "" se a carta não tem.
func special_text(d: CardDef, level: int) -> String:
	if d.n3.is_empty():
		return ""
	var t := String(TranslationServer.translate("N3_" + d.id)).format(UiKit.card_params(d, level))
	return t.trim_prefix("N3:").strip_edges()   # o texto antigo abria com "N3:"; o especial agora é do nível VI


func _build_zoom() -> void:
	UiKit.clear(zoom_layer)
	_last_zoom = zoom_id
	var d := data.card(zoom_id)
	var open := meta.is_unlocked(d.id)
	var lv := _lv(d.id)
	var nxt := lv + 1 if lv < MAX_LEVEL else 0
	var veil := Control.new()
	veil.position = Vector2(-3000, -3000)
	veil.size = BOARD + Vector2(6000, 6000)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.draw.connect(func(): veil.draw_rect(Rect2(Vector2.ZERO, veil.size), Color(0.06, 0.04, 0.025, 0.78)))
	veil.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			veil.accept_event()
			_close_zoom())
	zoom_layer.add_child(veil)
	var SH := Vector2(1560, 900)
	var sheet := Panel.new()
	sheet.add_theme_stylebox_override("panel", UiParch.box("gold", 0))
	sheet.size = SH
	sheet.position = ((BOARD - SH) * 0.5).round()
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	zoom_layer.add_child(sheet)
	var title := UiParch.label(UiKit.card_name(d), "title", 46, UiParch.BLOOD)
	title.position = Vector2(64, 36)
	title.size = Vector2(840, 56)
	sheet.add_child(title)
	var tl := UiParch.label(UiKit.type_line(d) + " · " + tr("RARITY_" + ["common", "uncommon", "rare", "legendary"][clampi(d.rarity, 0, 3)]), "italic", 24, UiParch.INK_SOFT)
	tl.position = Vector2(66, 92)
	tl.size = Vector2(840, 32)
	sheet.add_child(tl)
	# Cartas: atual (esquerda) e próximo nível (meio) ou, no VI, o especial.
	var CW := 290.0
	var cy := 150.0
	_zoom_card(sheet, d, lv, Vector2(64, cy), CW, tr("UI_LIB_NOW").format({"l": ROMAN[lv]}), not open)
	var arrow := UiParch.label("→", "title", 60, UiParch.GOLD)
	arrow.position = Vector2(64 + CW + 6, cy + 150)
	arrow.size = Vector2(70, 70)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(arrow)
	var nx := 64 + CW + 80
	if nxt > 0:
		_zoom_card(sheet, d, nxt, Vector2(nx, cy), CW, tr("UI_LIB_NEXT_LV").format({"l": ROMAN[nxt]}), false)
	else:
		var note := Panel.new()
		var ns := StyleBoxFlat.new()
		ns.bg_color = Color("f3e8c9")
		ns.border_color = Color(UiParch.INK, 0.75)
		ns.set_border_width_all(2)
		note.add_theme_stylebox_override("panel", ns)
		note.position = Vector2(nx, cy + 30)
		note.size = Vector2(CW, CW * 1.4 - 30)
		sheet.add_child(note)
		var mt := UiParch.label("UI_LIB_MAXED", "title", 32, UiParch.BLOOD)
		mt.position = Vector2(14, 14)
		mt.size = Vector2(CW - 28, 44)
		mt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.add_child(mt)
		var sp := special_text(d, lv)
		var spl := UiParch.label(("★ " + Tips.plain(sp)) if sp != "" else tr("UI_LIB_NO_SPECIAL"), "body", 24, UiParch.INK)
		spl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		spl.position = Vector2(18, 74)
		spl.size = Vector2(CW - 36, CW * 1.4 - 130)
		note.add_child(spl)
	# Números recalculados (diferenças em verde/água).
	var tx := 64.0
	var ty := cy + 34 + CW * 1.4 + 52
	var sub := UiParch.label("UI_LIB_NUMBERS", "italic", 22, UiParch.INK_SOFT)
	sub.position = Vector2(tx, ty - 34)
	sub.size = Vector2(500, 30)
	sheet.add_child(sub)
	var rs := rows(d, lv, nxt if nxt > 0 else lv)
	var ry := ty
	for r in rs:
		var ch: bool = r[3] and nxt > 0
		var good := (int(r[4]) > 0) != (str(r[0]) == tr("LVLK_cost"))
		var col := (UiParch.GOOD if good else Color("13808c")) if ch else UiParch.INK
		var l1 := UiParch.label(str(r[0]), "body", 22, UiParch.INK_SOFT)
		l1.position = Vector2(tx, ry)
		l1.size = Vector2(250, 28)
		l1.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sheet.add_child(l1)
		var l2 := UiParch.label(str(r[1]), "bold", 24, UiParch.INK)
		l2.position = Vector2(tx + 260, ry)
		l2.size = Vector2(110, 28)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sheet.add_child(l2)
		if nxt > 0:
			var l3 := UiParch.label(str(r[2]) + (("  ▲" if int(r[4]) > 0 else "  ▼") if ch else ""), "bold", 24, col)
			l3.position = Vector2(tx + 400, ry)
			l3.size = Vector2(150, 28)
			sheet.add_child(l3)
		ry += 30
	# Coluna da direita: especial, barra de nível, preço e deck.
	var rx := 1000.0
	if nxt == MAX_LEVEL and d.n3.size() > 0:
		var sp2 := special_text(d, MAX_LEVEL)
		var bx := Panel.new()
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color("f3e8c9")
		bs.border_color = Color(UiParch.GOLD, 0.9)
		bs.set_border_width_all(2)
		bx.add_theme_stylebox_override("panel", bs)
		bx.position = Vector2(rx, 150)
		bx.size = Vector2(480, 150)
		sheet.add_child(bx)
		var h := UiParch.label("UI_LIB_SPECIAL_VI", "title", 24, UiParch.BLOOD)
		h.position = Vector2(14, 8)
		h.size = Vector2(450, 30)
		bx.add_child(h)
		var sl := UiParch.label("★ " + Tips.plain(sp2), "body", 22, UiParch.INK)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.position = Vector2(14, 42)
		sl.size = Vector2(452, 100)
		bx.add_child(sl)
	var bar := Control.new()
	bar.position = Vector2(rx, 330)
	bar.size = Vector2(480, 70)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(bar)
	for p in range(1, MAX_LEVEL + 1):
		var rb := roman_badge(p, 52.0)
		rb.position = Vector2((p - 1) * 80, 8)
		if p > lv:
			rb.modulate = Color(1, 1, 1, 0.38 if p != nxt else 0.8)
		bar.add_child(rb)
	var bl := Control.new()
	bl.position = Vector2(0, 0)
	bl.size = bar.size
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bl.draw.connect(func():
		for p in range(1, MAX_LEVEL):
			var x0 := (p - 1) * 80 + 52.0
			bl.draw_line(Vector2(x0 + 2, 34), Vector2(p * 80 - 2, 34), Color("c08a2e") if p < lv else Color(UiParch.INK, 0.3), 3.0))
	bar.add_child(bl)
	# Subir.
	var cost := MetaApply.card_upgrade_cost(data, d.id, nxt) if nxt > 0 else 0
	var up := Button.new()
	up.name = "Up"
	UiParch.paper_button(up, 30)
	up.position = Vector2(rx, 430)
	up.size = Vector2(480, 70)
	if not open:
		up.text = tr("UI_LIB_LOCKED")
		up.disabled = true
	elif nxt == 0:
		up.text = tr("UI_LIB_MAXED")
		up.disabled = true
	else:
		up.text = tr("UI_LIB_UPGRADE").format({"p": cost})
		up.disabled = meta.almas < cost
	up.pressed.connect(func(): buy_level(d.id))
	sheet.add_child(up)
	var bal := UiParch.label(tr("UI_LIB_BALANCE").format({"n": meta.almas}) if not (nxt > 0 and meta.almas < cost and open) else tr("UI_LIB_NEED").format({"n": cost - meta.almas}), "italic", 22, UiParch.BLOOD if (nxt > 0 and meta.almas < cost and open) else UiParch.INK_SOFT)
	bal.position = Vector2(rx, 506)
	bal.size = Vector2(480, 30)
	bal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(bal)
	# Deck.
	var n := deck_count(d.id)
	var add := Button.new()
	add.name = "Add"
	UiParch.paper_button(add, 28)
	add.position = Vector2(rx, 570)
	add.size = Vector2(480, 64)
	add.text = tr("UI_LIB_ADD").format({"n": n, "m": MAX_COPIES})
	add.disabled = not can_add(d.id)
	add.pressed.connect(func(): deck_add(d.id))
	sheet.add_child(add)
	var rem := Button.new()
	rem.name = "Remove"
	UiParch.paper_button(rem, 24)
	rem.position = Vector2(rx, 642)
	rem.size = Vector2(480, 52)
	rem.text = tr("UI_LIB_REMOVE")
	rem.disabled = n <= 0 or not _can_edit()
	rem.pressed.connect(func(): deck_remove(d.id))
	sheet.add_child(rem)
	var why := ""
	if not open:
		why = UiKit.unlock_text(meta, d)
	elif not _can_edit():
		why = tr("UI_LIB_VILLAIN_LOCKED")
	elif not _eligible(d):
		why = tr("UI_LIB_OTHER_VILLAIN")
	elif n >= MAX_COPIES:
		why = tr("UI_LIB_MAX_COPIES").format({"m": MAX_COPIES})
	elif work.size() >= DECK_SIZE:
		why = tr("UI_LIB_DECK_FULL")
	var wl := UiParch.label(why, "italic", 21, UiParch.BLOOD)
	wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wl.position = Vector2(rx, 702)
	wl.size = Vector2(480, 56)
	wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(wl)
	var dc := UiParch.label(tr("UI_LIB_DECK_OF").format({"v": _tab_name(deck_vid), "a": work.size(), "b": DECK_SIZE}), "bold", 22, UiParch.INK_SOFT)
	dc.position = Vector2(rx, 764)
	dc.size = Vector2(480, 30)
	dc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.add_child(dc)
	var close := Button.new()
	close.name = "Close"
	close.text = "UI_COL_CLOSE"
	UiParch.paper_button(close, 26)
	close.position = Vector2(rx + 150, 810)
	close.size = Vector2(180, 52)
	close.pressed.connect(_close_zoom)
	sheet.add_child(close)
	(func():
		if is_instance_valid(close) and close.is_inside_tree():
			close.grab_focus()).call_deferred()


func _zoom_card(parent: Control, d: CardDef, level: int, at: Vector2, w: float, caption: String, dim: bool) -> void:
	var cap := UiParch.label(caption, "title", 26, UiParch.INK)
	cap.position = at + Vector2(0, -2)
	cap.size = Vector2(w, 32)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(cap)
	var box := Control.new()
	box.position = at + Vector2(0, 34)
	box.size = Vector2(w, w * 1.4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	var c := UiKit.card(d, d.cost_at(level), [], "", w, level)
	UiKit.ignore_mouse(c)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dim:
		c.modulate = Color(0.78, 0.74, 0.7)
	box.add_child(c)
	if not mold_has_plaque(level):
		var rb := roman_badge(level, 44.0)
		rb.position = Vector2(w - 56, 10)
		box.add_child(rb)


func _unhandled_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if zoom_id != "":
			_close_zoom()
		else:
			_close()

