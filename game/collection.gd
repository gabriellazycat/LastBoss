class_name CollectionScreen
extends VBoxContainer
## Biblioteca (plano de metaprogressão, 21/11/2026; refeita no estilo Hearthstone em 25/11/2026), em duas telas:
##  1. "pick": retratos grandes dos vilões (trancados aparecem trancados) com a contagem do deck (19/19) e das cartas
##     liberadas; clicar num vilão liberado entra na tela 2.
##  2. "deck": a coleção do vilão. Grade de 5 colunas com rolagem contínua (roda do mouse e arrasto, sem páginas),
##     filtros de custo e de tipo (monstro/estrutura/feitiço/temporário/comuns) no topo; à direita o deck em barrinhas
##     (custo + nome + quantidade; clicar na barrinha tira a carta) e a curva de elixir; clicar na carta da grade
##     põe no deck; botão direito, Y do controle ou a tecla I abrem o zoom (atual × próximo nível, "Subir · preço").
## Cartas bloqueadas continuam na grade (tracejadas, com o desafio). Deck incompleto não grava.
## O contrato com o menu continua o da antiga Coleção: setup(d, m), open(), refresh(), closed, grid, tab, shown,
## set_tab(id) (agora entra direto na tela 2 do vilão), _open_reader(i) e a estática cell().
## As compras e o deck passam por `api` (o MetaSave): buy_card_level(id) -> bool, set_deck(vid, ids) -> bool,
## deck_ok(vid, ids) -> bool. Enquanto a frente D não os tem, library_demo.gd põe um objeto com esses nomes em `api`.

signal closed

var _direct := false   # aberta direto no deck de um vilão (open_deck): o Esc fecha em vez de voltar à tela 1

const BOARD := Vector2(1688, 1008)        # espaço de desenho: papel de 1640x960 com 24 px de margem (como a Coleção do Mapa aberto)
const PAPER := Vector2(24, 24)
const PAPER_SIZE := Vector2(1640, 960)
const CELL := Vector2(200, 253)           # a carta do álbum (compacta: arte cheia e fita do nome)
const FOOT := 44.0
const CELL_W := 132.0                    # largura padrão da cell() estática (menu e tela de Pacto)
const COLS := 5
const VISIBLE_ROWS := 2                   # fileiras visíveis por vez na rolagem (10 cartas)
const PER_PAGE := 200                     # sem páginas: teto de cartas na grade (a constante fica por compatibilidade com os testes)
const MAX_COPIES := 3
const DECK_SIZE := 19
const MAX_LEVEL := 6
const ROMAN := ["", "I", "II", "III", "IV", "V", "VI"]
const GRID_MARGIN := 6.0
const WHEEL_STEP := 150.0
## Faixas de custo do filtro e da curva de elixir (custo no nível atual da carta).
const BUCKETS := [[0, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 9], [10, 99]]
const BUCKET_NAMES := ["0-1", "2", "3", "4", "5", "6", "7-9", "10+"]
## Filtro de tipo: "all" = do vilão + comuns; "common" = só as comuns; os outros agrupam por CardDef.type.
const TYPE_FILTERS := ["all", "monster", "structure", "spell", "lair", "common"]
const TYPE_KEYS := ["UI_LIB_ALL", "TYPE_monster", "TYPE_structure", "TYPE_spell", "TYPE_lair", "UI_TAB_V_common"]
const TYPE_W := [100, 140, 160, 140, 170, 140]
const PICK_W := 440.0
const PICK_H := 690.0

var data: GameData
var meta: MetaSave
var api: Object                   # quem compra nível e grava deck (padrão: o próprio meta)
var tabs: Array = []              # vilões (data.villain_ids) e "common" (mantido por compatibilidade)
var tab := "plague"               # vilão da tela 2
var deck_vid := "plague"          # o deck em edição (igual a `tab`)
var work: Array = []              # deck em edição (ids); só vai para o save quando está válido
var stage := "pick"               # "pick" (escolher o vilão) ou "deck" (a coleção)
var type_filter := "all"          # um de TYPE_FILTERS
var cost_filter := -1             # índice em BUCKETS; -1 = todos
var shown: Array = []             # cartas da grade depois dos filtros, na ordem da grade
var zoom_id := ""
var grid: GridContainer
var grid_sc: ScrollContainer
var board: Control
var almas_l: Label
var head_l: Label
var sub_l: Label
var count_l: Label
var empty_l: Label
var back_b: Button
var vil_b: Button
var pick_layer: Control
var pick_row: Control
var deck_layer: Control
var type_row: Container
var filter_row: Container
var deck_box: Control
var deck_head: Label
var deck_count_l: Label
var deck_warn: Label
var deck_list: VBoxContainer
var curve: Control
var zoom_layer: Control
var _cnt_labels := {}             # id -> Label "n/3" da célula
var _cell_cards := {}             # id -> carta da célula (escurece com 3 cópias)
var _grid_top := true             # a próxima reconstrução da grade volta ao topo
var _scroll_target := 0.0
var _last_set := 0
var _drag_pending := false
var _drag_active := false
var _drag_from := Vector2.ZERO
static var _gray: Shader


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m
	api = m
	tabs = d.villain_ids.duplicate()
	tabs.append("common")
	tab = str(d.villain_ids[0])
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
	almas_l = UiParch.label("", "bold", 30, UiParch.SOUL)
	almas_l.position = PAPER + Vector2(900, 34)
	almas_l.size = Vector2(694, 40)
	almas_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	board.add_child(almas_l)
	_build_pick_layer()
	_build_deck_layer()
	back_b = Button.new()
	back_b.text = "UI_BACK"
	UiParch.paper_button(back_b, 26)
	back_b.custom_minimum_size = Vector2(200, 56)
	back_b.size = back_b.custom_minimum_size
	back_b.position = PAPER + Vector2(46, 880)
	back_b.pressed.connect(_close)
	board.add_child(back_b)
	zoom_layer = Control.new()
	zoom_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(zoom_layer)
	if data != null:
		refresh()


func open() -> void:
	_close_zoom()
	_direct = false
	stage = "pick"
	type_filter = "all"
	cost_filter = -1
	_grid_top = true
	work = _saved_deck(deck_vid)
	refresh()
	_focus_first()


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
	_refresh_light()


func buy_level(id: String) -> bool:
	var ok: bool = api.buy_card_level(id)
	refresh()
	return ok


func set_cost_filter(k: int) -> void:
	cost_filter = k if k != cost_filter else -1
	_grid_top = true
	refresh()


func set_type_filter(t: String) -> void:
	type_filter = t if t != type_filter else "all"
	_grid_top = true
	refresh()


## Entra na coleção do vilão (tela 2). "common" não troca de vilão: só liga o filtro de comuns.
func set_tab(id: String) -> void:
	if id == "common":
		type_filter = "common"
	else:
		type_filter = "all"
		cost_filter = -1
		tab = id
		if id != deck_vid:
			deck_vid = id
			work = _saved_deck(id)
	stage = "deck"
	_grid_top = true
	refresh()
	_focus_first()


## Abre direto na coleção do vilão vindo de fora (botão "Editar deck" da escolha de vilão): o Esc fecha a
## Biblioteca e volta para quem abriu, em vez de cair na escolha de vilão da própria Biblioteca.
func open_deck(id: String) -> void:
	set_tab(id)
	_direct = true


## Volta à escolha do vilão (tela 1).
func to_pick() -> void:
	_close_zoom()
	_direct = false
	stage = "pick"
	refresh()
	_focus_first()


static func type_group(d: CardDef) -> String:
	match d.type:
		"spell", "structure", "lair":
			return d.type
		"monster", "swarm":
			return "monster"
	return d.type


func _filtered() -> Array:
	var out: Array = []
	for d in data.pool:
		if type_filter == "common":
			if d.owner != "common":
				continue
		else:
			if not data.in_pool(d, tab):
				continue
			if type_filter != "all" and type_group(d) != type_filter:
				continue
		if cost_filter >= 0 and bucket_of(_cost(d)) != cost_filter:
			continue
		out.append(d)
	# Como na coleção do Hearthstone: por custo; no mesmo custo as do vilão antes das comuns.
	out.sort_custom(func(a: CardDef, b: CardDef):
		var ca := _cost(a)
		var cb := _cost(b)
		if ca != cb:
			return ca < cb
		var oa := 1 if a.owner == "common" else 0
		var ob := 1 if b.owner == "common" else 0
		if oa != ob:
			return oa < ob
		return a.idx < b.idx)
	return out


## Por que a carta não entra no deck agora ("" = entra).
func _why_not(d: CardDef) -> String:
	if not _can_edit():
		return tr("UI_LIB_VILLAIN_LOCKED")
	if not _eligible(d):
		return tr("UI_LIB_OTHER_VILLAIN")
	if deck_count(d.id) >= MAX_COPIES:
		return tr("UI_LIB_MAX_COPIES").format({"m": MAX_COPIES})
	if work.size() >= DECK_SIZE:
		return tr("UI_LIB_DECK_FULL")
	return ""


# ---------------------------------------------------------------- peças

func _villain_tex(vid: String) -> Texture2D:
	var t := UiParch.portrait("villain_" + vid)
	if t == null:
		t = MainMenu.villain_tex(data, vid)
	return t


func _card_box(hot: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.35, 0.22, 0.1, 0.16 if hot else 0.07)
	s.border_color = UiParch.BLOOD if hot else Color(UiParch.INK, 0.55)
	s.set_border_width_all(4 if hot else 2)
	s.set_corner_radius_all(8)
	return s


func _build_pick_layer() -> void:
	pick_layer = Control.new()
	pick_layer.size = BOARD
	pick_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(pick_layer)
	var t := UiParch.label("UI_LIB_TITLE", "title", 54, UiParch.INK)
	t.position = PAPER + Vector2(48, 26)
	t.size = Vector2(620, 64)
	pick_layer.add_child(t)
	var st := UiParch.label("UI_LIB_PICK_SUB", "italic", 24, UiParch.INK_SOFT)
	st.position = PAPER + Vector2(50, 90)
	st.size = Vector2(900, 32)
	pick_layer.add_child(st)
	pick_row = Control.new()
	pick_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pick_layer.add_child(pick_row)


func _build_deck_layer() -> void:
	deck_layer = Control.new()
	deck_layer.size = BOARD
	deck_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(deck_layer)
	vil_b = Button.new()
	vil_b.text = "UI_LIB_VILLAINS"
	UiParch.paper_button(vil_b, 24)
	vil_b.position = PAPER + Vector2(46, 26)
	vil_b.size = Vector2(190, 56)
	vil_b.pressed.connect(to_pick)
	deck_layer.add_child(vil_b)
	head_l = UiParch.label("", "title", 50, UiParch.INK)
	head_l.position = PAPER + Vector2(262, 14)
	head_l.size = Vector2(640, 60)
	deck_layer.add_child(head_l)
	sub_l = UiParch.label("", "italic", 22, UiParch.INK_SOFT)
	sub_l.position = PAPER + Vector2(264, 70)
	sub_l.size = Vector2(640, 28)
	deck_layer.add_child(sub_l)
	# Filtro de tipo e de custo.
	var tl := UiParch.label("UI_LIB_TYPE", "italic", 22, UiParch.INK_SOFT)
	tl.position = PAPER + Vector2(48, 112)
	tl.size = Vector2(100, 34)
	deck_layer.add_child(tl)
	type_row = HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 8)
	type_row.position = PAPER + Vector2(150, 108)
	deck_layer.add_child(type_row)
	for k in TYPE_FILTERS.size():
		type_row.add_child(_type_button(k))
	var fl := UiParch.label("UI_LIB_COST", "italic", 22, UiParch.INK_SOFT)
	fl.position = PAPER + Vector2(48, 164)
	fl.size = Vector2(100, 34)
	deck_layer.add_child(fl)
	filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 6)
	filter_row.position = PAPER + Vector2(150, 160)
	deck_layer.add_child(filter_row)
	for k in BUCKETS.size() + 1:
		filter_row.add_child(_filter_button(k - 1))
	count_l = UiParch.label("", "italic", 22, UiParch.INK_SOFT)
	count_l.position = PAPER + Vector2(800, 166)
	count_l.size = Vector2(330, 30)
	count_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	deck_layer.add_child(count_l)
	# A grade: rolagem contínua (roda e arrasto), duas fileiras à vista.
	grid_sc = ScrollContainer.new()
	grid_sc.position = PAPER + Vector2(40, 214)
	grid_sc.size = Vector2(1110, GRID_MARGIN * 2 + VISIBLE_ROWS * (CELL.y + FOOT) + (VISIBLE_ROWS - 1) * 14)
	grid_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid_sc.follow_focus = true
	deck_layer.add_child(grid_sc)
	var mg := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		mg.add_theme_constant_override("margin_" + side, int(GRID_MARGIN))
	grid_sc.add_child(mg)
	grid = GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	mg.add_child(grid)
	empty_l = UiParch.label("UI_LIB_EMPTY", "italic", 28, UiParch.INK_SOFT)
	empty_l.position = PAPER + Vector2(40, 400)
	empty_l.size = Vector2(1110, 40)
	empty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_l.visible = false
	deck_layer.add_child(empty_l)
	var hint := UiParch.label("UI_LIB_HINT", "italic", 21, UiParch.INK_SOFT)
	hint.position = PAPER + Vector2(270, 896)
	hint.size = Vector2(860, 30)
	deck_layer.add_child(hint)
	_build_deck_panel()


func _type_button(k: int) -> Button:
	var b := Button.new()
	b.text = TYPE_KEYS[k]
	b.toggle_mode = true
	UiParch.paper_button(b, 20)
	b.custom_minimum_size = Vector2(TYPE_W[k], 40)
	b.set_meta("type", TYPE_FILTERS[k])
	b.pressed.connect(func():
		if k == 0:
			type_filter = "all"
			_grid_top = true
			refresh()
		else:
			set_type_filter(TYPE_FILTERS[k]))
	return b


func _filter_button(k: int) -> Button:
	var b := Button.new()
	b.text = "UI_LIB_ALL" if k < 0 else BUCKET_NAMES[k]
	b.toggle_mode = true
	UiParch.paper_button(b, 20)
	b.custom_minimum_size = Vector2(86 if k < 0 else 62, 38)
	b.set_meta("bucket", k)
	b.pressed.connect(func():
		if k < 0:
			cost_filter = -1
			_grid_top = true
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
	shown = _filtered()
	var in_deck := stage == "deck"
	pick_layer.visible = not in_deck
	deck_layer.visible = in_deck
	back_b.text = "UI_COL_CLOSE" if in_deck else "UI_BACK"
	if in_deck or grid.get_child_count() == 0:
		_rebuild_grid()
	if in_deck:
		for b in type_row.get_children():
			(b as Button).button_pressed = str(b.get_meta("type")) == type_filter
		for b in filter_row.get_children():
			(b as Button).button_pressed = int(b.get_meta("bucket")) == cost_filter
		_refresh_head()
		_refresh_deck()
	else:
		_build_pick()
	if zoom_id != "":
		_build_zoom()


func _refresh_head() -> void:
	head_l.text = _tab_name(tab)
	var n := 0
	var m := 0
	for d in data.pool:
		if d.owner == tab:
			m += 1
			if meta.is_unlocked(d.id):
				n += 1
	sub_l.text = tr("UI_LIB_UNLOCKED").format({"a": n, "b": m})
	count_l.text = tr("UI_LIB_SHOWN2").format({"n": shown.size()})


## Só o que muda ao pôr/tirar carta do deck: contagens das células, o painel do deck e a curva (a grade não é refeita,
## o foco e a rolagem ficam onde estão).
func _refresh_light() -> void:
	if grid == null:
		return
	for id in _cnt_labels:
		_paint_count(str(id))
	_refresh_deck()
	if zoom_id != "":
		_build_zoom()


func _paint_count(id: String) -> void:
	var n := deck_count(id)
	var l := _cnt_labels.get(id) as Label
	if l != null and is_instance_valid(l):
		l.text = "%d/%d" % [n, MAX_COPIES]
		l.add_theme_color_override("font_color", UiParch.ELIXIR_DEEP if n > 0 else UiParch.INK_SOFT)
	var c := _cell_cards.get(id) as Control
	if c != null and is_instance_valid(c):
		c.modulate = Color(1, 1, 1, 0.5) if n >= MAX_COPIES else Color.WHITE


func _rebuild_grid() -> void:
	var keep := 0 if _grid_top else grid_sc.scroll_vertical
	var had_focus := -1
	if not _grid_top:
		for k in grid.get_child_count():
			if grid.get_child(k).has_focus():
				had_focus = k
	_grid_top = false
	UiKit.clear(grid)
	_cnt_labels.clear()
	_cell_cards.clear()
	for i in shown.size():
		grid.add_child(_album_cell(shown[i], i))
	if empty_l:
		empty_l.visible = shown.is_empty()
	if had_focus >= 0 and had_focus < grid.get_child_count() and zoom_id == "":
		var gb := grid.get_child(had_focus) as Control
		(func():
			if is_instance_valid(gb) and gb.is_inside_tree():
				gb.grab_focus()).call_deferred()
	_restore_scroll(keep)


func _restore_scroll(v: int) -> void:
	_scroll_target = float(v)
	if v == 0:
		grid_sc.scroll_vertical = 0
		_last_set = 0
		return
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_instance_valid(grid_sc):
		grid_sc.scroll_vertical = v
		_scroll_target = float(grid_sc.scroll_vertical)
		_last_set = grid_sc.scroll_vertical


## Primeiro foco ao entrar numa tela: a primeira carta da grade ou o vilão em foco.
func _focus_first() -> void:
	(func():
		if not is_inside_tree() or not is_visible_in_tree():
			return
		if stage == "deck":
			if grid.get_child_count() > 0:
				(grid.get_child(0) as Control).grab_focus()
			return
		var first: Control = null
		for b in pick_row.get_children():
			if b is Button and not (b as Button).disabled and first == null:
				first = b
			if b is Button and str(b.get_meta("villain_id")) == tab and not (b as Button).disabled:
				first = b
		if first != null:
			first.grab_focus()).call_deferred()


# ---------------------------------------------------------------- tela 1: escolher o vilão

func _build_pick() -> void:
	var had := -1
	for k in pick_row.get_child_count():
		if pick_row.get_child(k).has_focus():
			had = k
	UiKit.clear(pick_row)
	var n := data.villain_ids.size()
	var total := n * PICK_W + (n - 1) * 50.0
	var x0 := PAPER.x + (PAPER_SIZE.x - total) * 0.5
	for k in n:
		pick_row.add_child(_pick_card(str(data.villain_ids[k]), Vector2(x0 + k * (PICK_W + 50.0), PAPER.y + 150.0)))
	if had >= 0 and had < pick_row.get_child_count() and stage == "pick":
		var fb := pick_row.get_child(had) as Control
		(func():
			if is_instance_valid(fb) and fb.is_inside_tree():
				fb.grab_focus()).call_deferred()


func _pick_card(vid: String, at: Vector2) -> Button:
	var open := meta.villains.has(vid)
	var b := Button.new()
	b.flat = true
	b.set_meta("no_frame", true)
	b.set_meta("villain_id", vid)
	b.position = at
	b.custom_minimum_size = Vector2(PICK_W, PICK_H)
	b.size = b.custom_minimum_size
	for st in ["normal", "disabled"]:
		b.add_theme_stylebox_override(st, _card_box(false))
	for st in ["hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(st, _card_box(open))
	var art := UiParch.framed_art(_villain_tex(vid), Vector2(PICK_W - 40, 440), "frame_gold")
	art.position = Vector2(20, 20)
	art.size = Vector2(PICK_W - 40, 440)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not open:
		art.modulate = Color(0.42, 0.4, 0.42)
	b.add_child(art)
	if not open:
		var k := CollectionScreen._lock()
		k.set_anchors_preset(Control.PRESET_TOP_LEFT)
		k.size = Vector2((PICK_W - 40) / 2.6, 440 / 2.6)
		k.scale = Vector2.ONE * 2.6
		k.position = Vector2(20, 20)
		b.add_child(k)
	var nm := UiParch.label(_tab_name(vid), "title", 44, UiParch.INK)
	nm.position = Vector2(0, 474)
	nm.size = Vector2(PICK_W, 56)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(nm)
	var got := 0
	var all := 0
	for d in data.pool:
		if d.owner == vid:
			all += 1
			if meta.is_unlocked(d.id):
				got += 1
	if open:
		var dn: int = work.size() if vid == deck_vid else _saved_deck(vid).size()
		var l1 := UiParch.label(tr("UI_LIB_DECK_N").format({"a": dn, "b": DECK_SIZE}), "bold", 34, UiParch.GOOD if dn == DECK_SIZE else UiParch.BLOOD)
		l1.position = Vector2(0, 540)
		l1.size = Vector2(PICK_W, 44)
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(l1)
		var l2 := UiParch.label(tr("UI_LIB_UNLOCKED").format({"a": got, "b": all}), "italic", 26, UiParch.INK_SOFT)
		l2.position = Vector2(0, 590)
		l2.size = Vector2(PICK_W, 34)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(l2)
		var l3 := UiParch.label("UI_LIB_ENTER", "italic", 22, UiParch.BLOOD)
		l3.position = Vector2(0, 638)
		l3.size = Vector2(PICK_W, 30)
		l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(l3)
		b.pressed.connect(func(): set_tab(vid))
	else:
		var party := int(meta.villain_unlock_at().get(data.villain_id(vid), 0))
		var l1 := UiParch.label(tr("UI_MENU_LOCKED").format({"n": party}), "bold", 28, UiParch.INK_SOFT)
		l1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l1.position = Vector2(30, 540)
		l1.size = Vector2(PICK_W - 60, 80)
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(l1)
		var l2 := UiParch.label(tr("UI_LIB_UNLOCKED").format({"a": got, "b": all}), "italic", 26, UiParch.INK_SOFT)
		l2.position = Vector2(0, 630)
		l2.size = Vector2(PICK_W, 34)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(l2)
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


# ---------------------------------------------------------------- tela 2: a grade

## Carta do álbum: compacta (arte grande + fita do nome) com a placa romana do nível por cima, e embaixo a lupa, os
## pontinhos de nível e "n/3" (cópias no deck). Clicar põe no deck. Bloqueada: moldura tracejada, arte apagada, o
## desafio e o progresso (clicar abre o zoom).
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
		_cell_cards[d.id] = c
		var rb := roman_badge(lv, 34.0)   # a carta compacta não leva placa do molde
		rb.position = Vector2(CELL.x - 42, 8)
		b.add_child(rb)
		var foot := Control.new()
		foot.position = Vector2(0, CELL.y + 6)
		foot.size = Vector2(CELL.x, FOOT - 8)
		foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		foot.draw.connect(func():
			for p in range(1, MAX_LEVEL + 1):
				var ctr := Vector2(46.0 + (p - 1) * 14.0, foot.size.y * 0.5)
				var col := Color("c08a2e") if p <= lv else Color(UiParch.INK, 0.25)
				foot.draw_colored_polygon(PackedVector2Array([ctr + Vector2(0, -5.5), ctr + Vector2(5.5, 0), ctr + Vector2(0, 5.5), ctr + Vector2(-5.5, 0)]), col))
		var nl := UiParch.label("", "bold", 22, UiParch.INK_SOFT)
		nl.position = Vector2(136, 1)
		nl.size = Vector2(CELL.x - 138, 28)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		foot.add_child(nl)
		b.add_child(foot)
		_cnt_labels[d.id] = nl
		_paint_count(d.id)
		var zb := Button.new()
		zb.flat = true
		zb.set_meta("no_frame", true)
		zb.focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			zb.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		zb.position = Vector2(0, CELL.y + 4)
		zb.size = Vector2(36, 32)
		zb.tooltip_text = ""
		zb.draw.connect(func():
			var hot := zb.is_hovered()
			var col := UiParch.BLOOD if hot else UiParch.INK_SOFT
			zb.draw_arc(Vector2(15, 14), 8.0, 0, TAU, 20, col, 2.5, true)
			zb.draw_line(Vector2(21, 20), Vector2(28, 27), col, 3.0, true))
		zb.mouse_entered.connect(func(): zb.queue_redraw())
		zb.mouse_exited.connect(func(): zb.queue_redraw())
		zb.pressed.connect(func(): _open_zoom(d.id))
		b.add_child(zb)
		b.pressed.connect(func(): _cell_add(d))
	else:
		b.add_child(_locked_cell(d))
		b.pressed.connect(func(): _open_zoom(d.id))
	b.gui_input.connect(func(e: InputEvent):
		if _is_info_event(e):
			b.accept_event()
			_open_zoom(d.id))
	b.mouse_entered.connect(func():
		if _cell_in_view(b):
			b.grab_focus())
	return b


func _cell_add(d: CardDef) -> void:
	if deck_add(d.id):
		return
	var why := _why_not(d)
	deck_warn.text = why
	deck_warn.add_theme_color_override("font_color", UiParch.BLOOD)


## Botão direito, Y do controle ou a tecla I: detalhes da carta (zoom com os níveis).
static func _is_info_event(e: InputEvent) -> bool:
	if e is InputEventMouseButton:
		return e.pressed and e.button_index == MOUSE_BUTTON_RIGHT
	if e is InputEventKey:
		return e.pressed and not e.echo and e.keycode == KEY_I
	if e is InputEventJoypadButton:
		return e.pressed and e.button_index == JOY_BUTTON_Y
	return false


## A célula está inteira dentro da janela de rolagem? (só então o mouse passando por cima lhe dá o foco, para o
## follow_focus não brigar com a rolagem suave).
func _cell_in_view(b: Control) -> bool:
	var top := b.position.y + GRID_MARGIN
	var sv := float(grid_sc.scroll_vertical)
	return top >= sv - 2.0 and top + b.size.y <= sv + grid_sc.size.y + 2.0


# ---------------------------------------------------------------- rolagem suave (roda e arrasto)

func _scroll_max() -> float:
	var sb := grid_sc.get_v_scroll_bar()
	return maxf(0.0, sb.max_value - sb.page)


func _over_grid(pos: Vector2) -> bool:
	var inv := grid_sc.get_global_transform_with_canvas().affine_inverse()
	return Rect2(Vector2.ZERO, grid_sc.size).has_point(inv * pos)


func _input(e: InputEvent) -> void:
	if stage != "deck" or zoom_id != "" or grid_sc == null or not is_visible_in_tree():
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _over_grid(mb.position):
				var dir := -1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
				_scroll_target = clampf(_scroll_target + dir * WHEEL_STEP * maxf(mb.factor, 1.0), 0.0, _scroll_max())
				get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_pending = _over_grid(mb.position)
				_drag_active = false
				_drag_from = mb.position
			else:
				if _drag_active:
					get_viewport().set_input_as_handled()   # o soltar do arrasto não conta como clique na carta
				_drag_pending = false
				_drag_active = false
	elif e is InputEventMouseMotion and _drag_pending:
		var mm := e as InputEventMouseMotion
		if not _drag_active and (mm.position - _drag_from).length() > 10.0:
			_drag_active = true
		if _drag_active:
			var sc := grid_sc.get_global_transform_with_canvas().get_scale().y
			_scroll_target = clampf(_scroll_target - mm.relative.y / maxf(sc, 0.01), 0.0, _scroll_max())
			grid_sc.scroll_vertical = int(_scroll_target)
			_last_set = grid_sc.scroll_vertical
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if stage != "deck" or grid_sc == null or not is_visible_in_tree():
		return
	var cur := grid_sc.scroll_vertical
	if cur != _last_set:
		_scroll_target = float(cur)   # mudou por fora (foco do teclado/controle): acompanha
	var diff := _scroll_target - float(cur)
	if absf(diff) >= 1.0:
		var step := diff * (1.0 - exp(-delta * 16.0))
		if absf(step) < 1.0:
			step = signf(diff)
		grid_sc.scroll_vertical = cur + int(step)
	_last_set = grid_sc.scroll_vertical


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
	var div := Control.new()
	div.position = PAPER + Vector2(1160, 30)
	div.size = Vector2(4, 880)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	div.draw.connect(func(): div.draw_dashed_line(Vector2(2, 0), Vector2(2, div.size.y), Color(UiParch.INK, 0.45), 2.0, 8.0))
	deck_layer.add_child(div)
	deck_box = Control.new()
	deck_box.position = PAPER + Vector2(1180, 84)
	deck_box.size = Vector2(440, 800)
	deck_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_layer.add_child(deck_box)
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
	deck_warn.position = Vector2(0, 44)
	deck_warn.size = Vector2(440, 26)
	deck_warn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	deck_box.add_child(deck_warn)
	var sc := ScrollContainer.new()
	sc.position = Vector2(0, 76)
	sc.size = Vector2(440, 566)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	deck_box.add_child(sc)
	deck_list = VBoxContainer.new()
	deck_list.add_theme_constant_override("separation", 1)
	deck_list.custom_minimum_size = Vector2(426, 0)
	sc.add_child(deck_list)
	var ct := UiParch.label("UI_LIB_CURVE", "italic", 22, UiParch.INK_SOFT)
	ct.position = Vector2(0, 650)
	ct.size = Vector2(440, 28)
	deck_box.add_child(ct)
	curve = Control.new()
	curve.position = Vector2(0, 680)
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
	deck_head.text = _tab_name(deck_vid)
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
	var had_focus := -1
	for k in deck_list.get_child_count():
		if deck_list.get_child(k).has_focus():
			had_focus = k
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
	if had_focus >= 0 and deck_list.get_child_count() > 0:
		var fb := deck_list.get_child(mini(had_focus, deck_list.get_child_count() - 1)) as Control
		(func():
			if is_instance_valid(fb) and fb.is_inside_tree() and fb.focus_mode != Control.FOCUS_NONE:
				fb.grab_focus()).call_deferred()
	curve.queue_redraw()


func _row_box(bg: Color, border := Color(0, 0, 0, 0), bw := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(4)
	if bw > 0 and bg.a == 0.0:
		s.draw_center = false
	return s


## Barrinha do deck: gota de custo + nome + ×n + nível. Clicar (ou Enter/A) tira uma cópia; botão direito, Y ou I abrem o zoom.
func _deck_row(d: CardDef, n: int) -> Button:
	var row := Button.new()
	row.flat = true
	row.set_meta("no_frame", true)
	row.set_meta("card_id", d.id)
	row.custom_minimum_size = Vector2(426, 28)
	row.disabled = not _can_edit()
	row.add_theme_stylebox_override("normal", _row_box(Color(0.35, 0.22, 0.1, 0.10)))
	row.add_theme_stylebox_override("disabled", _row_box(Color(0.35, 0.22, 0.1, 0.10)))
	for st in ["hover", "pressed", "hover_pressed"]:
		row.add_theme_stylebox_override(st, _row_box(Color(UiParch.BLOOD, 0.20)))
	row.add_theme_stylebox_override("focus", _row_box(Color(0, 0, 0, 0), UiParch.BLOOD, 3))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 2
	hb.offset_right = -8
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(hb)
	var gem := Control.new()
	gem.custom_minimum_size = Vector2(28, 28)
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cost := _cost(d)
	gem.draw.connect(func():
		UiParch.draw_drop(gem, Rect2(Vector2(2, 1), Vector2(24, 24)), 1.0)
		gem.draw_string(UiParch.font("bold"), Vector2(0, 19), str(cost), HORIZONTAL_ALIGNMENT_CENTER, 28, 16 if cost < 10 else 13, Color.WHITE))
	hb.add_child(gem)
	var nl := UiParch.label(UiKit.card_name(d), "body", 21, UiParch.INK)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nl.clip_text = true
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hb.add_child(nl)
	var xl := UiParch.label("×%d" % n if n > 1 else "", "bold", 20, UiParch.ELIXIR_DEEP)
	xl.custom_minimum_size = Vector2(30, 0)
	xl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(xl)
	var rb := roman_badge(_lv(d.id), 22.0)
	rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(rb)
	row.pressed.connect(func(): deck_remove(d.id))
	row.gui_input.connect(func(e: InputEvent):
		if _is_info_event(e):
			row.accept_event()
			_open_zoom(d.id))
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
		elif stage == "deck" and not _direct:
			to_pick()
		else:
			_close()
