class_name CompendiumScreen
extends VBoxContainer
## Compêndio do menu (rodada 09/11/2026): tudo o que existe no jogo e o que faz.
## Abas: Cartas (bloqueadas também, níveis 1 a 3, especial do N3, preço), Relíquias, Modificadores, Locais e Herói.

signal closed

const TABS := ["cards", "relics", "mods", "locs", "hero"]
const TAB_KEYS := {"cards": "UI_COMP_CARDS", "relics": "UI_COMP_RELICS", "mods": "UI_COMP_MODS", "locs": "UI_COMP_LOCS", "hero": "UI_COMP_HERO"}
const CARD_W := 176.0

var data: GameData
var meta: MetaSave
var tab := "cards"
var tab_row: HBoxContainer
var scroll: ScrollContainer
var body: Container


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	if UiSkins.diario():
		draw.connect(func(): UiDiario.draw_plate(self, "paper", Vector2(34, 28)))
	var t := UiKit.title(44)
	t.text = "UI_COMPENDIUM"
	add_child(t)
	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	add_child(tab_row)
	for id in TABS:
		var b := Button.new()
		b.text = TAB_KEYS[id]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(160, 44)
		var tid: String = id
		b.pressed.connect(func(): show_tab(tid))
		tab_row.add_child(b)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1180, 640)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var back := Button.new()
	back.text = "UI_BACK"
	back.custom_minimum_size = Vector2(200, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func(): closed.emit())
	add_child(back)


func open() -> void:
	show_tab(tab)
	(tab_row.get_child(TABS.find(tab)) as Control).grab_focus.call_deferred()


func show_tab(id: String) -> void:
	tab = id
	for k in tab_row.get_child_count():
		(tab_row.get_child(k) as Button).button_pressed = TABS[k] == id
	if body:
		scroll.remove_child(body)
		body.queue_free()
	match id:
		"cards":
			body = _cards()
		"relics":
			body = _list(data.relic_ids.map(func(r): return [tr("REL_" + r), tr("RELD_" + r), _rarity_col(str(data.relics[r].get("rarity", "common")))]))
		"mods":
			body = _list(K.MOD_IDS.map(func(m): return [tr("MOD_" + m), Tips.rich(tr("MODDESC_" + m), false), UiKit.GOLD]))
		"locs":
			var rows: Array = []
			for ty in SimRoad.LOC_TYPES:
				rows.append([tr("LOC_" + ty), Tips.rich(Tips.kw_desc(ty), false), WorldView.LOC_COLORS.get(ty, UiKit.GOLD)])
			body = _list(rows)
		"hero":
			body = _hero()
	scroll.add_child(body)
	scroll.scroll_vertical = 0


func _rarity_col(r: String) -> Color:
	return UiKit.RARITY_COLORS[maxi(0, K.RARITIES.find(r))]


func _cards() -> Container:
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 18)
	for d in data.pool:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		var c := UiKit.card(d, d.cost, [], "", CARD_W, 1)
		UiKit.ignore_mouse(c)
		var dd: CardDef = d
		Tips.attach(c, func(): return Tips.card_entries(dd, [], false, 1))
		v.add_child(c)
		var lines: Array = []
		var l2 := UiKit.level_changes(d, 1, 2)
		var l3 := UiKit.level_changes(d, 2, 3)
		if l2 != "":
			lines.append("N2: " + l2)
		if l3 != "":
			lines.append("N3: " + l3)
		if d.n3.size() > 0:
			lines.append(tr("UI_OPT_UP_N3"))
		if meta and not meta.is_unlocked(d.id):
			lines.append("[color=#e0b070]" + tr("UI_COMP_LOCKED").format({"c": meta.unlock_cost(d.id)}) + "[/color]")
		v.add_child(Tips.label("\n".join(lines), 13, UiKit.TEXT, CARD_W))
		g.add_child(v)
	return g


## Lista de [nome, texto, cor]: nome em destaque e o texto ao lado.
func _list(rows: Array) -> Container:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	for r in rows:
		var p := UiKit.panel(UiKit.BG_SOFT, (r[2] as Color).darkened(0.3), 10)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 18)
		var n := UiKit.title(22, (r[2] as Color).lightened(0.3))
		n.text = r[0]
		n.custom_minimum_size = Vector2(260, 0)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD
		h.add_child(n)
		h.add_child(Tips.label(str(r[1]), 16, UiKit.TEXT, 860.0))
		p.add_child(h)
		v.add_child(p)
	return v


func _hero() -> Container:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	for u in data.hero["upgrades"]:
		var id: String = u["id"]
		var p := UiKit.panel(UiKit.BG_SOFT, UiKit.HERO_XP.darkened(0.3), 10)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		h.add_child(UpgradeIcon.make(id, 52))
		var col := VBoxContainer.new()
		var n := UiKit.title(22, UiKit.HERO_XP.lightened(0.3))
		n.text = tr("UPG_" + id)
		col.add_child(n)
		col.add_child(Tips.label(Tips.rich(UpgradeIcon.desc(data, id), false), 16, UiKit.TEXT, 1000.0))
		col.add_child(Tips.label(tr("UI_COMP_COUNTER").format({"t": tr("HCTR_" + id)}), 15, UiKit.GOOD, 1000.0))
		h.add_child(col)
		p.add_child(h)
		v.add_child(p)
	return v
