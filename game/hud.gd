class_name Hud
extends Control
## Interface da run. Lê o Sim; ações do jogador viram comandos via sinais.

signal card_pressed(i: int)
signal card_sacrificed(i: int)
signal offer_chosen(k: int)
signal deck_chosen(id: String)
signal restart
signal continue_run
signal minimap_clicked(pos: Vector2)
signal card_dropped(i: int, screen_pos: Vector2)

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
var hint_panel: PanelContainer
var hint_label: Label
var hint_t := 0.0
var hints_seen: Dictionary = {}
var pause_panel: PanelContainer
var pause_label: Label
var sac_zone: Button
var top_box: HBoxContainer
var bottom_box: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _make_theme()
	_build()


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	var states := {"normal": [Color(0.12, 0.08, 0.18, 0.95), Color(0.55, 0.4, 0.75)], "hover": [Color(0.2, 0.12, 0.3, 0.98), Color(1.0, 0.8, 0.4)],
		"pressed": [Color(0.3, 0.15, 0.4), Color(1.0, 0.85, 0.5)], "focus": [Color(0.2, 0.12, 0.3, 0.98), Color(1.0, 0.8, 0.4)],
		"disabled": [Color(0.08, 0.06, 0.1, 0.8), Color(0.3, 0.3, 0.3)]}
	for st in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[st][0]
		sb.border_color = states[st][1]
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(12)
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 5
		t.set_stylebox(st, "Button", sb)
	t.set_color("font_color", "Button", Color(0.95, 0.9, 1.0))
	t.set_color("font_hover_color", "Button", Color(1.0, 0.92, 0.6))
	t.set_color("font_outline_color", "Button", Color.BLACK)
	t.set_constant("outline_size", "Button", 4)
	t.set_color("font_outline_color", "Label", Color.BLACK)
	t.set_constant("outline_size", "Label", 4)
	return t


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
	build_label = _label(12, Color(0.88, 0.88, 1.0))
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
	sac_zone = Button.new()
	sac_zone.text = "UI_SACRIFICE"
	sac_zone.focus_mode = Control.FOCUS_NONE
	sac_zone.add_theme_font_size_override("font_size", 14)
	sac_zone.pressed.connect(func():
		if selected >= 0:
			card_sacrificed.emit(selected))
	eb.add_child(sac_zone)
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
	hint_panel = _panel(Color(0.08, 0.05, 0.14, 0.92), Color(1.0, 0.8, 0.4))
	hint_panel.custom_minimum_size = Vector2(620, 0)
	hint_label = _label(17, Color(1, 0.95, 0.85))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint_label.custom_minimum_size = Vector2(600, 0)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_panel.add_child(hint_label)
	hint_panel.visible = false
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_panel)
	var cf := ConfigFile.new()
	if cf.load("user://hints.cfg") == OK:
		for k in cf.get_section_keys("seen") if cf.has_section("seen") else []:
			hints_seen[k] = true
	pause_panel = _panel(Color(0.04, 0.03, 0.07, 0.95), Color(0.6, 0.45, 0.9))
	pause_panel.custom_minimum_size = Vector2(720, 0)
	pause_label = _label(17)
	pause_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	pause_label.custom_minimum_size = Vector2(700, 0)
	pause_panel.add_child(pause_label)
	pause_panel.visible = false
	add_child(pause_panel)


func _build_menu() -> void:
	menu_panel = _panel(Color(0.04, 0.03, 0.07, 0.55), Color(0.6, 0.4, 0.9))
	menu_panel.position = Vector2(-520, -230)
	menu_panel.custom_minimum_size = Vector2(1040, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var t := _label(64, Color(1.0, 0.75, 0.35))
	t.add_theme_constant_override("outline_size", 10)
	t.text = "UI_TITLE"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var st := _label(22)
	st.text = "UI_CHOOSE_DECK"
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := _label(18, Color(0.85, 0.8, 0.95))
	sub.text = "UI_SUBTITLE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(sub)
	v.add_child(st)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	for id in ["horde", "ruin", "treasure"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(330, 230)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.text = tr("DECK_" + id) + "\n\n" + tr("DECKDESC_" + id)
		b.set_meta("deck", id)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(func(): deck_chosen.emit(id))
		row.add_child(b)
	v.add_child(row)
	var cont := Button.new()
	cont.name = "Continue"
	cont.text = "UI_CONTINUE"
	cont.custom_minimum_size = Vector2(0, 46)
	cont.pressed.connect(func(): continue_run.emit())
	v.add_child(cont)
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
	for p in [offer_panel, result_panel, pause_panel]:
		p.position = (vs - p.size) * 0.5
	menu_panel.position = Vector2((vs.x - menu_panel.size.x) * 0.5, vs.y - menu_panel.size.y - 30)
	contract_panel.position = Vector2(12, 110)
	hint_panel.position = Vector2((vs.x - hint_panel.size.x) * 0.5, 190)


func show_menu(on: bool) -> void:
	menu_panel.visible = on
	for n in [top_box, minimap, contract_panel, bottom_box, help_label, info_label, parts_box]:
		n.visible = not on
	if on:
		sim = null
	var data := GameData.load_dir()
	var cont: Button = menu_panel.find_child("Continue", true, false)
	cont.visible = SaveGame.exists()
	for b in menu_panel.find_children("*", "Button", true, false):
		if not b.has_meta("deck"):
			continue
		var id: String = b.get_meta("deck")
		var names: Array = []
		for cid in data.deck(id)["cards"]:
			names.append(tr("CARD_" + cid))
		b.text = "%s

%s
%s

%s" % [tr("DECK_" + id).to_upper(), tr("DECKSTYLE_" + id), deck_rules_text(data.deck(id)["rules"]), tr("UI_DECK_CARDS").format({"list": ", ".join(names)})]


## Regras próprias do deck, montadas dos dados (o ajustador muda os números).
static func deck_rules_text(rules: Dictionary) -> String:
	var lines: Array = []
	for k in rules:
		var v = rules[k]
		if typeof(v) == TYPE_FLOAT and (k.ends_with("_mult")):
			if is_equal_approx(v, 1.0):
				continue
			lines.append("• " + TranslationServer.translate("RULE_" + k).format({"p": int(round(v * 100.0))}))
		else:
			lines.append("• " + TranslationServer.translate("RULE_" + k).format({"n": int(v)}))
	return "
".join(lines)


func bind(s: Sim) -> void:
	sim = s
	selected = -1
	hand_sig = ""
	offer_sig = ""
	for n in [top_box, minimap, bottom_box, help_label, info_label]:
		n.visible = true
	parts_box.visible = false
	result_panel.visible = false
	minimap.setup(s)


func show_pause(on: bool) -> void:
	pause_panel.visible = on and sim != null
	if not pause_panel.visible:
		return
	var deck: Array = []
	for ci in sim.cards:
		var mods: Array = []
		for mid in K.MOD_IDS:
			if ci.has_mod(K.MOD_BY_ID[mid]):
				mods.append(tr("MOD_" + mid))
		var line := tr("CARD_" + ci.def.id)
		if mods.size() > 0:
			line = tr("UI_CARD_MODS").format({"card": line, "mods": ", ".join(mods)})
		deck.append("• " + line)
	var ups: Array = []
	for u in sim.hero.upgrade_order:
		ups.append(tr("UPG_" + u))
	pause_label.text = tr("UI_PAUSE_TEXT").format({"deck": "
".join(deck), "build": ", ".join(ups) if ups.size() > 0 else "—", "n": sim.cards.size()})


## Dica contextual: aparece só na primeira vez (fica salva em user://hints.cfg).
func hint(key: String) -> void:
	if hints_seen.has(key):
		return
	hints_seen[key] = true
	hint_label.text = tr("HINT_" + key)
	hint_panel.visible = true
	hint_t = 7.0
	var cf := ConfigFile.new()
	for k in hints_seen:
		cf.set_value("seen", k, true)
	cf.save("user://hints.cfg")


func _hints() -> void:
	if sim.t > 0.5:
		hint("start")
	if sim.offers.size() > 0 and sim.offers[0]["source"] == "level":
		hint("offer")
	if sim.contract.size() > 0:
		hint("contract")
	if sim.phase == K.Phase.ARENA:
		hint("arena")
	var h := Vector2(sim.hero.x, sim.hero.y)
	for loc in sim.road.locations:
		if loc["type"] == "shrine" and loc["state"] == SimRoad.LocState.ACTIVE and h.distance_to(loc["pos"]) < 45.0:
			hint("shrine")
	for ci in sim.hand:
		if ci and ci.def.category == "route":
			hint("route")
		elif ci and ci.def.category == "finisher" and sim.phase == K.Phase.ROAD:
			hint("finisher")


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


func _gem(cost: int) -> PanelContainer:
	var g := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.55, 0.15, 0.75)
	sb.border_color = Color(1, 0.75, 1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	g.add_theme_stylebox_override("panel", sb)
	var l := _label(24, Color.WHITE)
	l.name = "Cost"
	l.text = str(cost)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.add_child(l)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


func _type_line(d: CardDef) -> String:
	var parts: Array = [tr("TYPE_" + d.type)]
	for t in d.tag_names:
		parts.append(tr("TAG_" + t))
	return " · ".join(parts)


func _card_panel(i: int, ci: Sim.CardInst) -> PanelContainer:
	var d := ci.def
	var p := _panel(Color(0.08, 0.06, 0.12, 0.97), RARITY_COLORS[d.rarity])
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
	sb.set_content_margin_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	p.custom_minimum_size = Vector2(168, 246)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(156, 96)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = CardArt.textures.get(d.id)
	var over := Control.new()
	over.custom_minimum_size = Vector2(156, 96)
	over.add_child(art)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	var gem := _gem(ci.def.cost)
	gem.position = Vector2(2, 2)
	over.add_child(gem)
	var key := _label(15, Color(0.9, 0.9, 0.9))
	key.text = str(i + 1)
	key.position = Vector2(140, 2)
	over.add_child(key)
	var name_ := _label(16, RARITY_COLORS[d.rarity].lightened(0.45))
	name_.text = tr("CARD_" + d.id)
	name_.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tl := _label(11, Color(0.7, 0.65, 0.8))
	tl.text = _type_line(d)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var mods := []
	for mid in K.MOD_IDS:
		if ci.has_mod(K.MOD_BY_ID[mid]):
			mods.append("★ " + tr("MOD_" + mid))
	var ml := _label(12, Color(1, 0.85, 0.4))
	ml.text = "  ".join(mods)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ml.visible = mods.size() > 0
	var desc := _label(12, Color(0.86, 0.86, 0.92))
	desc.text = card_desc(d)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(156, 0)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for n in [over, name_, tl, ml, desc]:
		v.add_child(n)
	for n in v.find_children("*", "Control", true, false):
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	p.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton:
			if e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				card_pressed.emit(i)
			elif e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
				card_sacrificed.emit(i)
			elif not e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				# Arrastar e soltar: fora da mão = posicionar; sobre o ícone = sacrificar.
				var gp: Vector2 = p.get_global_transform() * e.position
				if sac_zone.get_global_rect().has_point(gp):
					card_sacrificed.emit(i)
				elif not hand_box.get_global_rect().grow(8).has_point(gp):
					card_dropped.emit(i, gp))
	p.mouse_entered.connect(func(): p.set_meta("hover", true))
	p.mouse_exited.connect(func(): p.set_meta("hover", false))
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
		p.modulate = Color(1, 1, 1) if b == K.Block.OK else Color(0.5, 0.5, 0.58)
		var lift := -26.0 if k == selected else (-10.0 if p.get_meta("hover", false) else 0.0)
		p.position.y = lerpf(p.position.y, lift, clampf(delta * 14.0, 0.0, 1.0))
		var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
		sb.set_border_width_all(5 if k == selected else 2)
		sb.shadow_color = Color(0.8, 0.5, 1.0, 0.55) if k == selected else (Color(0.5, 1.0, 0.6, 0.25) if b == K.Block.OK else Color(0, 0, 0, 0.5))
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
	_hints()
	if hint_t > 0.0:
		hint_t -= delta
		hint_panel.modulate.a = clampf(hint_t, 0.0, 1.0)
		hint_panel.visible = hint_t > 0.0
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
		var top := ""
		var best := 0
		for cid in st["played"]:
			if int(st["played"][cid]) > best:
				best = int(st["played"][cid])
				top = cid
		var lines: Array = [tr("UI_RESULT_" + str(st["result"])), "", tr("UI_RESULT_STATS").format({
			"t": "%d:%02d" % [int(sim.t) / 60, int(sim.t) % 60], "h": h.level, "p": sim.player_level}),
			tr("UI_RESULT_MORE").format({"k": st["kills"], "s": st["shrines_won"], "c": st["contracts_ok"], "p": st["parts_lost"]})]
		if top != "":
			lines.append(tr("UI_RESULT_TOP").format({"card": tr("CARD_" + top)}))
		result_label.text = "
".join(lines)


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
