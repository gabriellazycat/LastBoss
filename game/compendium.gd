class_name CompendiumScreen
extends VBoxContainer
## Compêndio do menu (rodada 09/11/2026): tudo o que existe no jogo e o que faz.
## Abas: Cartas (bloqueadas também, níveis, especial do N3), Relíquias, Modificadores, Locais e Poderes (de party).

signal closed

const TABS := ["cards", "relics", "mods", "locs", "hero"]
const TAB_KEYS := {"cards": "UI_COMP_CARDS", "relics": "UI_COMP_RELICS", "mods": "UI_COMP_MODS", "locs": "UI_COMP_LOCS", "hero": "UI_MENU_COMP_POWERS"}
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
			body = _list(data.relic_ids.map(func(r): return [tr("REL_" + r), tr("RELD_" + r), _rarity_col(str(data.relics[r].get("rarity", "common"))), r]))
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
	var all := VBoxContainer.new()
	all.add_theme_constant_override("separation", 14)
	# Agrupadas por dono: um cabeçalho e uma grade para cada vilão e para as comuns.
	for owner in data.villain_ids + ["common"]:
		var head := UiKit.title(30, UiKit.GOLD)
		head.text = tr("DECK_" + owner) if owner != "common" else tr("UI_COMP_OWNER_common")
		all.add_child(head)
		var g := GridContainer.new()
		g.columns = 6
		g.add_theme_constant_override("h_separation", 14)
		g.add_theme_constant_override("v_separation", 18)
		all.add_child(g)
		_cards_of(g, owner)
	return all


func _cards_of(g: GridContainer, owner: String) -> void:
	for d in data.pool:
		if d.owner != owner:
			continue
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
			lines.append("[color=#e0b070]" + UiKit.unlock_text(meta, d) + "[/color]")
		v.add_child(Tips.label("\n".join(lines), 13, UiKit.TEXT, CARD_W))
		g.add_child(v)


## Lista de [nome, texto, cor]: nome em destaque e o texto ao lado.
func _list(rows: Array) -> Container:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	for r in rows:
		var p := UiKit.panel(UiKit.BG_SOFT, (r[2] as Color).darkened(0.3), 10)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 18)
		if r.size() > 3:
			h.add_child(UiKit.relic_icon(str(r[3]), 48.0))   # aba Relíquias: ícone (15/11/2026)
		var n := UiKit.title(22, (r[2] as Color).lightened(0.3))
		n.text = r[0]
		n.custom_minimum_size = Vector2(260, 0)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD
		h.add_child(n)
		h.add_child(Tips.label(str(r[1]), 16, UiKit.TEXT, 860.0))
		p.add_child(h)
		v.add_child(p)
	return v


## Aba Poderes (21/11/2026, no lugar das 15 habilidades do herói): os poderes de party de data/hero_powers.json, com o
## gatilho, a recarga e o efeito de cada nível (1 a 3).
func _hero() -> Container:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	var intro := Tips.label(tr("UI_MENU_COMP_POWERS_SUB"), 17, UiKit.MUTED, 1080.0)
	v.add_child(intro)
	for id in data.power_ids:
		var d: Dictionary = data.hero_powers[id]
		var p := UiKit.panel(UiKit.BG_SOFT, UiKit.HERO_XP.darkened(0.3), 10)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		var icon_path := "res://assets/ui/powers/%s.svg" % id
		if ResourceLoader.exists(icon_path):
			var ic := TextureRect.new()
			ic.texture = load(icon_path)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.custom_minimum_size = Vector2(52, 52)
			h.add_child(ic)
		var col := VBoxContainer.new()
		var n := UiKit.title(22, UiKit.HERO_XP.lightened(0.3))
		n.text = tr("POWER_" + id)
		col.add_child(n)
		col.add_child(Tips.label(tr("UI_MENU_TRIG_" + str(d.get("trigger", ""))) + " · " + tr("UI_MENU_COMP_COOLDOWN").format({"cd": int(HeroPowers.params(d, 1)["cd"])}), 15, UiKit.GOOD, 1000.0))
		for lv in range(1, int(d.get("lv", []).size()) + 1):
			var desc := tr("POWER_" + id + "_d").format(HeroPowers.params(d, lv))
			col.add_child(Tips.label(tr("UI_MENU_COMP_LEVEL").format({"n": lv, "d": desc}), 16, UiKit.TEXT, 1000.0))
		h.add_child(col)
		p.add_child(h)
		v.add_child(p)
	return v
