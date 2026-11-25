class_name CovilScreen
extends Control
## Tela do Covil (plano de metaprogressão, 21/11/2026): lateral com Almas e botões + árvore radial (MetaTreeView) +
## janela de detalhe do nó. Pele "Mapa aberto" (papel, moldura dourada, fitas). A integração no menu é da frente G:
## esta tela só emite sinais (open_library, start_run, back) e grava o MetaSave (meta.save()) a cada compra/reembolso.
## Passar o mouse sobre um nó mostra a janela (só leitura); clicar fixa a janela e libera Comprar/Reembolsar.

signal open_library
signal start_run
signal back

const SIDE_W := 340.0
const DETAIL_W := 400.0

var data: GameData
var meta: MetaSave
var view: MetaTreeView
var almas_l: Label
var detail: PanelContainer
var confirm_row: HBoxContainer
var refund_all_b: Button
var _d_icon: TextureRect
var _d_name: Label
var _d_sector: Label
var _d_desc: Label
var _d_level: Label
var _d_fx: Label
var _d_next: Label
var _d_note: Label
var _d_buy: Button
var _d_refund: Button
var _d_btns: HBoxContainer
var _d_close: Button
var _d_pips: HBoxContainer
var _shown := ""
var act2_override := -1   # -1 = ler do MetaSave ("act2_reached", frente D); 0/1 = forcar (demo e testes)


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.065, 0.05)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 26
	row.offset_top = 22
	row.offset_right = -26
	row.offset_bottom = -22
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	row.add_child(_build_side())
	var stage := Control.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(stage)
	var paper := PanelContainer.new()
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.add_theme_stylebox_override("panel", UiParch.box("gold", 22))
	stage.add_child(paper)
	view = MetaTreeView.new()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper.add_child(view)
	view.setup(data, meta)
	view.node_hovered.connect(func(_id): _update_detail())
	view.node_clicked.connect(func(_id): _update_detail())
	view.changed.connect(_on_changed)
	_build_detail(stage)
	refresh()


# ---------------------------------------------------------------- lateral

func _build_side() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(SIDE_W, 0)
	panel.add_theme_stylebox_override("panel", UiParch.box("gold", 26))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UiParch.ribbon_title(tr("UI_COVIL_TITLE"), 34))
	v.add_child(UiParch.divider(SIDE_W - 60))
	var cap := UiParch.label(tr("UI_COVIL_ALMAS"), "title", 22, UiParch.INK_SOFT)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	almas_l = UiParch.label("0", "heavy", 64, UiParch.SOUL)
	almas_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(almas_l)
	v.add_child(UiParch.divider(SIDE_W - 60))
	var hint := UiParch.label(tr("UI_COVIL_HINT"), "italic", 18, UiParch.INK_SOFT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	var fit_b := _button(tr("UI_COVIL_FIT"), 20)
	fit_b.pressed.connect(func(): view.fit())
	v.add_child(fit_b)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var lib := _button(tr("UI_COVIL_LIBRARY"), 24)
	lib.pressed.connect(func(): open_library.emit())
	v.add_child(lib)
	refund_all_b = _button(tr("UI_COVIL_REFUND_ALL"), 22)
	refund_all_b.pressed.connect(func(): request_refund_all())
	v.add_child(refund_all_b)
	confirm_row = HBoxContainer.new()
	confirm_row.visible = false
	confirm_row.add_theme_constant_override("separation", 8)
	var ask := UiParch.label(tr("UI_COVIL_REFUND_ASK"), "body", 17, UiParch.BLOOD)
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ask.custom_minimum_size = Vector2(SIDE_W - 190, 0)
	confirm_row.add_child(ask)
	var yes := _button(tr("UI_COVIL_YES"), 18)
	yes.pressed.connect(func(): confirm_refund_all())
	var no := _button(tr("UI_COVIL_NO"), 18)
	no.pressed.connect(func(): confirm_row.visible = false)
	confirm_row.add_child(yes)
	confirm_row.add_child(no)
	v.add_child(confirm_row)
	var go := Button.new()
	go.text = tr("UI_COVIL_START")
	UiParch.ribbon_button(go, "monster", 30)
	go.pressed.connect(func(): start_run.emit())
	v.add_child(go)
	var bk := _button(tr("UI_COVIL_BACK"), 22)
	bk.pressed.connect(func(): back.emit())
	v.add_child(bk)
	return panel


func _button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	UiParch.paper_button(b, size)
	b.focus_mode = Control.FOCUS_NONE
	return b


func request_refund_all() -> void:
	confirm_row.visible = true


func confirm_refund_all() -> void:
	meta.refund_all()
	confirm_row.visible = false
	_on_changed()


# ---------------------------------------------------------------- janela de detalhe

func _build_detail(stage: Control) -> void:
	detail = PanelContainer.new()
	detail.visible = false
	detail.anchor_left = 1.0
	detail.anchor_right = 1.0
	detail.offset_left = -DETAIL_W - 36
	detail.offset_right = -36
	detail.offset_top = 36
	detail.offset_bottom = 40
	detail.add_theme_stylebox_override("panel", UiParch.box("gold", 24))
	stage.add_child(detail)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	detail.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	_d_icon = UiKit.relic_icon("", 64)
	head.add_child(_d_icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	head.add_child(names)
	_d_name = UiParch.label("", "title", 28, UiParch.INK)
	_d_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_name.custom_minimum_size = Vector2(190, 0)
	names.add_child(_d_name)
	_d_sector = UiParch.label("", "italic", 18, UiParch.INK_SOFT)
	names.add_child(_d_sector)
	_d_close = Button.new()
	_d_close.text = "x"
	UiParch.paper_button(_d_close, 20)
	_d_close.focus_mode = Control.FOCUS_NONE
	_d_close.tooltip_text = tr("UI_COVIL_CLOSE")
	_d_close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_d_close.pressed.connect(func():
		view.selected = ""
		view.queue_redraw()
		_update_detail())
	head.add_child(_d_close)
	v.add_child(UiParch.divider(DETAIL_W - 50))
	_d_desc = UiParch.label("", "serif", 21, UiParch.INK)
	_d_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_desc.custom_minimum_size = Vector2(DETAIL_W - 50, 0)
	v.add_child(_d_desc)
	_d_fx = UiParch.label("", "bold", 17, UiParch.SOUL)
	_d_fx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_fx.custom_minimum_size = Vector2(DETAIL_W - 50, 0)
	v.add_child(_d_fx)
	var lv_row := HBoxContainer.new()
	lv_row.add_theme_constant_override("separation", 10)
	v.add_child(lv_row)
	_d_level = UiParch.label("", "bold", 22, UiParch.INK)
	lv_row.add_child(_d_level)
	_d_pips = HBoxContainer.new()
	_d_pips.add_theme_constant_override("separation", 5)
	_d_pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lv_row.add_child(_d_pips)
	_d_next = UiParch.label("", "bold", 20, UiParch.INK_SOFT)
	v.add_child(_d_next)
	_d_note = UiParch.label("", "italic", 18, UiParch.BLOOD)
	_d_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_note.custom_minimum_size = Vector2(DETAIL_W - 50, 0)
	v.add_child(_d_note)
	_d_btns = HBoxContainer.new()
	_d_btns.add_theme_constant_override("separation", 10)
	v.add_child(_d_btns)
	_d_buy = Button.new()
	UiParch.ribbon_button(_d_buy, "monster", 24)
	_d_buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_d_buy.pressed.connect(func():
		if _shown != "":
			view.buy_node(_shown))
	_d_btns.add_child(_d_buy)
	_d_refund = _button(tr("UI_COVIL_REFUND"), 20)
	_d_refund.pressed.connect(func():
		if _shown != "":
			view.refund_node(_shown))
	_d_btns.add_child(_d_refund)


## Mostra o nó fixado (clique) ou o sob o mouse (só leitura); sem nenhum, esconde a janela.
func _update_detail() -> void:
	var id := view.selected if view.selected != "" else view.hovered
	_shown = id
	if id == "" or not data.meta_nodes.has(id):
		_shown = ""
		detail.visible = false
		return
	var pinned := id == view.selected
	var n: Dictionary = data.meta_nodes[id]
	var lv := meta.node_level(id)
	var mx: int = (n["costs"] as Array).size()
	var itex := MetaTreeView.icon_tex(str(n.get("icon", "")))
	_d_icon.texture = itex if itex != null else MetaTreeView.icon_tex("dim")
	_d_name.text = view.node_name(id)
	_d_sector.text = view.sector_name(view.node_sector(id))
	var desc := view.node_desc(id)
	_d_desc.text = desc
	_d_desc.visible = desc != ""
	_d_fx.text = "\n".join(view.fx_lines(id))
	_d_fx.visible = _d_fx.text != ""
	_d_level.text = tr("UI_COVIL_LEVEL").format({"n": lv, "m": mx})
	UiKit.clear(_d_pips)
	for k in mx:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(16, 16)
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiParch.GOLD_LIGHT if k < lv else UiParch.PARCH_DARK
		sb.border_color = UiParch.INK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		pip.add_theme_stylebox_override("panel", sb)
		_d_pips.add_child(pip)
	var cost := meta.node_cost(id)
	_d_next.text = tr("UI_COVIL_NEXT").format({"c": cost}) if cost >= 0 else tr("UI_COVIL_MAXED")
	# Aviso de por que não dá para comprar.
	var note := ""
	if view.sector_locked(view.node_sector(id)):
		note = tr("UI_COVIL_SEALED")
	elif cost >= 0 and not _parent_ok(n):
		note = tr("UI_COVIL_NEED_PARENT").format({"p": view.node_name(str(n["parent"]))})
	elif cost >= 0 and meta.almas < cost:
		note = tr("UI_COVIL_NEED_ALMAS").format({"n": cost - meta.almas})
	elif lv > 0 and not view.can_refund(id) and cost < 0:
		note = tr("UI_COVIL_REFUND_BLOCKED")
	if not pinned:
		note = tr("UI_COVIL_PIN")
	_d_note.text = note
	_d_note.visible = note != ""
	_d_btns.visible = pinned
	_d_close.visible = pinned
	_d_buy.visible = cost >= 0
	_d_buy.text = tr("UI_COVIL_BUY").format({"c": cost})
	_d_buy.disabled = not view.can_buy(id)
	_d_refund.visible = lv > 0
	_d_refund.disabled = not view.can_refund(id)
	detail.reset_size()
	detail.visible = true


func _parent_ok(n: Dictionary) -> bool:
	var p := str(n.get("parent", ""))
	return p == "" or meta.node_level(p) >= 1


# ---------------------------------------------------------------- estado

func _on_changed() -> void:
	meta.save()
	refresh()


func act2_reached() -> bool:
	if act2_override >= 0:
		return act2_override == 1
	var v = meta.get("act2_reached")
	return v != null and bool(v)


func refresh() -> void:
	if view:
		view.act2_reached = act2_reached()
	if almas_l:
		almas_l.text = str(meta.almas)
	if view:
		view.refresh()
	if detail and detail.is_inside_tree():
		_update_detail()
