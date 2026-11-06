class_name Hud
extends Control
## Interface da run. Lê o Sim; ações do jogador viram comandos via sinais.

signal card_pressed(i: int)
signal card_sacrificed(i: int)
signal offer_chosen(k: int)
signal deck_chosen(id: String)
signal restart
signal minimap_clicked(pos: Vector2)

const RARITY_COLORS := [Color(0.62, 0.62, 0.62), Color(0.35, 0.8, 0.35), Color(0.3, 0.55, 1.0), Color(0.7, 0.35, 1.0)]

var sim: Sim
var selected := -1
var hand_box: HBoxContainer
var card_panels: Array = []
var elixir_bar: ProgressBar
var elixir_label: Label
var hero_bar: ProgressBar
var hero_label: Label
var player_bar: ProgressBar
var player_label: Label
var hero_hp: ProgressBar
var build_label: Label
var minimap: Minimap
var parts_box: VBoxContainer
var part_bars: Array = []
var contract_panel: PanelContainer
var contract_label: Label
var offer_panel: PanelContainer
var offer_title: Label
var offer_box: HBoxContainer
var offer_sig := ""
var result_panel: PanelContainer
var result_label: Label
var menu_panel: PanelContainer
var toast: Label
var toast_t := 0.0
var info_label: Label
var help_label: Label
var tele_label: Label
var hand_sig := ""
var lang_btn: Button
var top_box: HBoxContainer
var bottom_box: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _panel(col := Color(0.06, 0.05, 0.1, 0.85), border := Color(0.45, 0.35, 0.65)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _label(size := 18, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _bar(col: Color, w: float, h: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.show_percentage = false
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(4)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(4)
	b.add_theme_stylebox_override("fill", fg)
	b.add_theme_stylebox_override("background", bg)
	return b


func _build() -> void:
	# Topo: corrida de níveis.
	var top := HBoxContainer.new()
	top_box = top
	top.position = Vector2(-420, 12)
	top.add_theme_constant_override("separation", 24)
	add_child(top)
	var hv := VBoxContainer.new()
	hero_label = _label(20, Color(1, 0.8, 0.5))
	hero_bar = _bar(Color(1, 0.7, 0.3), 380, 14)
	hero_hp = _bar(Color(0.85, 0.2, 0.2), 380, 10)
	build_label = _label(14, Color(0.9, 0.9, 1.0))
	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	build_label.custom_minimum_size = Vector2(380, 0)
	build_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for n in [hero_label, hero_bar, hero_hp, build_label]:
		hv.add_child(n)
	top.add_child(hv)
	var pv := VBoxContainer.new()
	player_label = _label(20, Color(0.85, 0.6, 1.0))
	player_bar = _bar(Color(0.65, 0.35, 1.0), 380, 14)
	pv.add_child(player_label)
	pv.add_child(player_bar)
	top.add_child(pv)
	# Minimapa / partes do chefe.
	minimap = Minimap.new()
	minimap.position = Vector2(-272, 12)
	minimap.size = Vector2(260, 260)
	minimap.world_clicked.connect(func(p): minimap_clicked.emit(p))
	add_child(minimap)
	parts_box = VBoxContainer.new()
	parts_box.position = Vector2(-292, 16)
	parts_box.visible = false
	add_child(parts_box)
	tele_label = _label(16, Color(0.8, 0.7, 1.0))
	# Contrato.
	contract_panel = _panel(Color(0.1, 0.06, 0.04, 0.85), Color(0.85, 0.6, 0.3))
	contract_panel.position = Vector2(12, 120)
	contract_panel.custom_minimum_size = Vector2(320, 0)
	contract_label = _label(16, Color(1, 0.9, 0.7))
	contract_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	contract_panel.add_child(contract_label)
	add_child(contract_panel)
	info_label = _label(14, Color(0.8, 0.8, 0.8))
	info_label.position = Vector2(12, 4)
	add_child(info_label)
	lang_btn = Button.new()
	lang_btn.position = Vector2(12, 70)
	lang_btn.focus_mode = Control.FOCUS_NONE
	lang_btn.pressed.connect(func():
		TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("pt") else "pt")
		hand_sig = ""
		offer_sig = "")
	add_child(lang_btn)
	# Base: mão e elixir.
	var bottom := VBoxContainer.new()
	bottom_box = bottom
	bottom.position = Vector2(-560, -270)
	bottom.custom_minimum_size = Vector2(1120, 0)
	add_child(bottom)
	hand_box = HBoxContainer.new()
	hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_box.add_theme_constant_override("separation", 10)
	bottom.add_child(hand_box)
	var eb := HBoxContainer.new()
	eb.alignment = BoxContainer.ALIGNMENT_CENTER
	elixir_bar = _bar(Color(0.85, 0.3, 0.95), 760, 26)
	elixir_label = _label(22, Color(1, 0.8, 1))
	eb.add_child(elixir_bar)
	eb.add_child(elixir_label)
	bottom.add_child(eb)
	help_label = _label(13, Color(0.75, 0.75, 0.8))
	help_label.position = Vector2(12, -26)
	add_child(help_label)
	toast = _label(26, Color(1, 0.5, 0.4))
	toast.position = Vector2(-300, 120)
	toast.custom_minimum_size = Vector2(600, 0)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(toast)
	# Oferta.
	offer_panel = _panel(Color(0.05, 0.03, 0.1, 0.94), Color(0.8, 0.6, 1.0))
	offer_panel.position = Vector2(-430, -200)
	offer_panel.custom_minimum_size = Vector2(860, 0)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 14)
	offer_title = _label(28, Color(1, 0.9, 0.5))
	offer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_box = HBoxContainer.new()
	offer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	offer_box.add_theme_constant_override("separation", 16)
	ov.add_child(offer_title)
	ov.add_child(offer_box)
	offer_panel.add_child(ov)
	offer_panel.visible = false
	add_child(offer_panel)
	# Resultado.
	result_panel = _panel()
	result_panel.position = Vector2(-330, -140)
	result_panel.custom_minimum_size = Vector2(660, 0)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 16)
	result_label = _label(26)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	var rb := Button.new()
	rb.text = "UI_RESTART"
	rb.custom_minimum_size = Vector2(0, 54)
	rb.pressed.connect(func(): restart.emit())
	rv.add_child(result_label)
	rv.add_child(rb)
	result_panel.add_child(rv)
	result_panel.visible = false
	add_child(result_panel)
	_build_menu()


func _build_menu() -> void:
	menu_panel = _panel(Color(0.04, 0.03, 0.07, 0.96), Color(0.6, 0.4, 0.9))
	menu_panel.position = Vector2(-520, -230)
	menu_panel.custom_minimum_size = Vector2(1040, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	var t := _label(56, Color(0.85, 0.6, 1.0))
	t.text = "UI_TITLE"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var st := _label(22)
	st.text = "UI_CHOOSE_DECK"
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(st)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	for id in ["horde", "ruin", "treasure"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(320, 200)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.text = tr("DECK_" + id) + "\n\n" + tr("DECKDESC_" + id)
		b.set_meta("deck", id)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(func(): deck_chosen.emit(id))
		row.add_child(b)
	v.add_child(row)
	menu_panel.add_child(v)
	add_child(menu_panel)


func _process(_d: float) -> void:
	_layout()


func _layout() -> void:
	var vs := get_viewport_rect().size
	top_box.position = Vector2(vs.x * 0.5 - 392.0, 10)
	minimap.position = Vector2(vs.x - minimap.size.x - 12, 12)
	parts_box.position = Vector2(vs.x - 292, 16)
	bottom_box.position = Vector2((vs.x - bottom_box.size.x) * 0.5, vs.y - bottom_box.size.y - 34)
	help_label.position = Vector2(12, vs.y - 26)
	toast.position = Vector2((vs.x - toast.size.x) * 0.5, vs.y * 0.3)
	for p in [offer_panel, result_panel, menu_panel]:
		p.position = (vs - p.size) * 0.5
	contract_panel.position = Vector2(12, 110)


func show_menu(on: bool) -> void:
	menu_panel.visible = on
	for b in menu_panel.find_children("*", "Button", true, false):
		var id: String = b.get_meta("deck")
		b.text = tr("DECK_" + id) + "\n\n" + tr("DECKDESC_" + id)


func bind(s: Sim) -> void:
	sim = s
	selected = -1
	hand_sig = ""
	offer_sig = ""
	minimap.visible = true
	parts_box.visible = false
	result_panel.visible = false
	minimap.setup(s)


func say(txt: String) -> void:
	toast.text = txt
	toast_t = 1.6


# ---------------------------------------------------------------- cartas

static func card_params(d: CardDef) -> Dictionary:
	var p := {"count": d.count}
	for k in d.fx:
		var v = d.fx[k]
		if typeof(v) == TYPE_FLOAT and is_equal_approx(v, round(v)):
			v = int(v)
		p[k] = v
	return p


static func card_desc(d: CardDef) -> String:
	return TranslationServer.translate("DESC_" + d.id).format(card_params(d))


func _card_panel(i: int, ci: Sim.CardInst) -> PanelContainer:
	var d := ci.def
	var p := _panel(Color(0.1, 0.08, 0.14, 0.95), RARITY_COLORS[d.rarity])
	p.custom_minimum_size = Vector2(170, 210)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	var cost := _label(30, Color(1, 0.6, 1))
	cost.name = "Cost"
	var key := _label(16, Color(0.7, 0.7, 0.7))
	key.text = str(i + 1)
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(cost)
	top.add_child(key)
	var name_ := _label(17, RARITY_COLORS[d.rarity].lightened(0.35))
	name_.text = tr("CARD_" + d.id)
	name_.autowrap_mode = TextServer.AUTOWRAP_WORD
	var mods := ""
	for mid in K.MOD_IDS:
		if ci.has_mod(K.MOD_BY_ID[mid]):
			mods += "★ " + tr("MOD_" + mid) + "\n"
	var ml := _label(13, Color(1, 0.85, 0.4))
	ml.text = mods.strip_edges()
	var desc := _label(13, Color(0.85, 0.85, 0.9))
	desc.text = card_desc(d)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(150, 0)
	for n in [top, name_, ml, desc]:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(n)
	p.add_child(v)
	p.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			if e.button_index == MOUSE_BUTTON_LEFT:
				card_pressed.emit(i)
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				card_sacrificed.emit(i))
	return p


func _rebuild_hand() -> void:
	for c in hand_box.get_children():
		c.queue_free()
	card_panels.clear()
	for i in sim.hand.size():
		var ci: Sim.CardInst = sim.hand[i]
		if ci == null:
			continue
		var p := _card_panel(i, ci)
		hand_box.add_child(p)
		card_panels.append(p)


func _hand_signature() -> String:
	var s := TranslationServer.get_locale()
	for ci in sim.hand:
		s += ":%d/%d" % [ci.uid if ci else 0, ci.mods if ci else 0]
	return s


# ---------------------------------------------------------------- atualização

func refresh(delta: float, fps: float) -> void:
	if sim == null:
		return
	var sig := _hand_signature()
	if sig != hand_sig:
		hand_sig = sig
		_rebuild_hand()
	for k in card_panels.size():
		var p: PanelContainer = card_panels[k]
		var ci: Sim.CardInst = sim.hand[k] if k < sim.hand.size() else null
		if ci == null:
			continue
		var b := sim.can_play(k)
		var cost: Label = p.find_child("Cost", true, false)
		cost.text = str(sim.card_cost(ci))
		p.modulate = Color(1, 1, 1) if b == K.Block.OK else Color(0.55, 0.55, 0.6)
		p.position.y = -18.0 if k == selected else 0.0
		var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
		sb.set_border_width_all(5 if k == selected else 2)
	var h := sim.hero
	elixir_bar.max_value = sim.elixir_max
	elixir_bar.value = sim.elixir
	elixir_label.text = tr("UI_ELIXIR").format({"n": int(sim.elixir), "max": int(sim.elixir_max)})
	hero_label.text = tr("UI_HERO_LEVEL").format({"n": h.level}) + "   " + str(int(h.hp)) + " / " + str(int(h.max_hp()))
	hero_bar.max_value = h.xp_needed()
	hero_bar.value = h.xp
	hero_hp.max_value = h.max_hp()
	hero_hp.value = h.hp
	var names: Array = []
	for u in h.upgrade_order:
		names.append(tr("UPG_" + u))
	var bl := tr("UI_BUILD").format({"list": ", ".join(names)}) if names.size() > 0 else ""
	if h.curses > 0:
		bl += "\n" + tr("UI_CURSES").format({"n": h.curses})
	build_label.text = bl
	player_label.text = tr("UI_PLAYER_LEVEL").format({"n": sim.player_level})
	player_bar.max_value = sim._player_next()
	player_bar.value = sim.player_xp
	info_label.text = tr("UI_FPS").format({"fps": int(fps), "u": sim.units.count})
	lang_btn.text = tr("UI_LANG")
	help_label.text = tr("UI_HELP")
	_refresh_contract()
	_refresh_offer()
	_refresh_arena()
	if sim.phase == K.Phase.ROAD:
		minimap.queue_redraw()
	if toast_t > 0.0:
		toast_t -= delta
		toast.modulate.a = clampf(toast_t, 0.0, 1.0)
	if sim.phase == K.Phase.OVER and not result_panel.visible:
		result_panel.visible = true
		var st := sim.stats
		result_label.text = tr("UI_RESULT_" + str(st["result"])) + "\n\n" + tr("UI_RESULT_STATS").format({
			"t": "%d:%02d" % [int(sim.t) / 60, int(sim.t) % 60], "h": h.level, "p": sim.player_level})


func _refresh_contract() -> void:
	var c := sim.contract
	contract_panel.visible = c.size() > 0
	if c.is_empty():
		return
	var g: Dictionary = c["goal"]
	var gp := {}
	for k in g:
		gp[k] = g[k]
	if g.has("tag"):
		gp["tag"] = tr("TAG_" + str(g["tag"]))
	if typeof(gp.get("amount")) == TYPE_FLOAT:
		gp["amount"] = int(gp["amount"])
	contract_label.text = tr("UI_CONTRACT").format({"name": tr("CON_" + str(c["id"])), "goal": tr("CONG_" + str(g["kind"])).format(gp)}) \
		+ "\n" + tr("UI_CONTRACT_PROGRESS").format({"p": int(c["progress"]), "a": int(g["amount"]), "t": int(c["t"])})


func _refresh_offer() -> void:
	var on := sim.offers.size() > 0
	offer_panel.visible = on
	if not on:
		offer_sig = ""
		return
	var o: Dictionary = sim.offers[0]
	var sig := TranslationServer.get_locale() + str(o)
	if sig == offer_sig:
		return
	offer_sig = sig
	offer_title.text = tr({"level": "UI_OFFER_LEVEL", "shrine": "UI_OFFER_SHRINE", "contract": "UI_OFFER_CONTRACT"}[o["source"]])
	for c in offer_box.get_children():
		c.queue_free()
	var opts: Array = o["options"]
	for k in opts.size():
		var op: Dictionary = opts[k]
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 220)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.add_theme_font_size_override("font_size", 17)
		var txt := ""
		match str(op["kind"]):
			"card":
				var d: CardDef = sim.data.card(op["id"])
				txt = "[%d]  %s\n%s · %d\n\n%s" % [k + 1, tr("CARD_" + d.id), tr("RARITY_" + K.RARITIES[d.rarity]), d.cost, card_desc(d)]
				var sb := StyleBoxFlat.new()
				sb.bg_color = Color(0.12, 0.1, 0.16)
				sb.border_color = RARITY_COLORS[d.rarity]
				sb.set_border_width_all(3)
				sb.set_corner_radius_all(8)
				b.add_theme_stylebox_override("normal", sb)
			"mod":
				txt = "[%d]  %s\n\n%s" % [k + 1, tr("UI_OPT_MOD").format({"mod": tr("MOD_" + str(op["mod"])), "card": tr("CARD_" + str(op["card"]))}), tr("MODDESC_" + str(op["mod"]))]
			"remove":
				txt = "[%d]  %s" % [k + 1, tr("UI_OPT_REMOVE").format({"card": tr("CARD_" + str(op["card"]))})]
		b.text = txt
		b.pressed.connect(func(): offer_chosen.emit(k))
		offer_box.add_child(b)


func _refresh_arena() -> void:
	if sim.phase != K.Phase.ARENA or not sim.arena.active:
		return
	var A := sim.arena
	if not parts_box.visible:
		minimap.visible = false
		parts_box.visible = true
		for c in parts_box.get_children():
			c.queue_free()
		part_bars.clear()
		for k in A.part_ids.size():
			var l := _label(16)
			l.set_meta("id", A.part_ids[k])
			var b := _bar(Color(0.75, 0.3, 0.9), 270, 14)
			parts_box.add_child(l)
			parts_box.add_child(b)
			part_bars.append([l, b])
		tele_label = _label(16, Color(0.8, 0.7, 1.0))
		parts_box.add_child(tele_label)
	for k in part_bars.size():
		var l: Label = part_bars[k][0]
		var b: ProgressBar = part_bars[k][1]
		l.text = tr("UI_PART_" + str(A.part_ids[k]))
		b.max_value = A.part_max[k]
		b.value = A.part_hp[k]
		l.modulate = Color(1, 1, 1) if A.part_hp[k] > 0 else Color(0.4, 0.4, 0.4)
	tele_label.text = tr("UI_TELEPORT_READY") if A.tp_cd <= 0.0 else tr("UI_TELEPORT_CD").format({"t": ceili(A.tp_cd)})
