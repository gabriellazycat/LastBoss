class_name Tips
extends CanvasLayer
## Caixas de explicação, como no Hearthstone: passar o mouse num objeto (carta, ícone de habilidade) abre caixas ao
## lado; passar o mouse numa palavra-chave colorida abre a caixa dela. Caixas aninham: uma palavra dentro de uma
## caixa abre outra, até MAX_DEPTH níveis. Cada nível espera GRACE s antes de fechar e fica aberto enquanto o mouse
## está na sua âncora, numa das suas caixas ou num nível mais fundo.
##
## Marcação no texto (strings.csv): [[id]] mostra o nome da palavra-chave (KW_id); [[id|texto]] mostra "texto".
## A explicação vem de KWD_id, com os números lidos dos dados (_kw_params).

static var KW_COLOR := Color(1.0, 0.84, 0.42)
const GRACE := 0.4
const MAX_DEPTH := 3
const BOX_W := 300.0
const KEYWORDS := [
	"pack", "undead", "fire", "shadow", "construct",
	"slow", "fear", "curse", "soaked", "petrify", "root",
	"shield", "pierce", "elixir", "sacrifice", "teleport", "altar",
	"swarm", "monster", "spell", "structure", "route", "lair", "finisher",
	"veteran", "cheap", "explosive", "cursed", "shadowy",
	"shop", "tavern", "fountain", "ritual", "shrine", "bridge", "gold", "event",
]

static var inst: Tips
static var data: GameData
static var _static_re: RegEx
static var mouse_override = null   # posição global fixa do mouse (só no teste da entrada real)

var root: Control
## Um dicionário por nível: owner, col, boxes, word (âncora palavra: o rótulo), seen (quadro do último hold), t.
var levels: Array = []
var _attached: Control = null


func _ready() -> void:
	layer = 50
	inst = self
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.make_theme()
	add_child(root)


## Há caixa aberta: o jogador está lendo (o jogo não pausa por isso).
static func reading() -> bool:
	return inst != null and inst.levels.size() > 0


## O nível 0 pertence a `owner` e ainda está aberto (o leque segura a carta ampliada enquanto o mouse lê as caixas).
static func is_open(owner: String) -> bool:
	return inst != null and inst.levels.size() > 0 and inst.levels[0]["owner"] == owner


static func close_all() -> void:
	if inst:
		inst._close_from(0)


# ---------------------------------------------------------------- texto

## Converte a marcação em BBCode. `link` = as palavras abrem caixa; `exclude` = id que não vira link (a própria caixa).
static func rich(text: String, link := true, exclude := "") -> String:
	var out := ""
	var at := 0
	for m in inst_re().search_all(text):
		out += text.substr(at, m.get_start() - at)
		var id := m.get_string(1)
		var shown := m.get_string(2) if m.get_string(2) != "" else kw_name(id)
		var col := "[color=#%s]%s[/color]" % [KW_COLOR.to_html(false), shown]
		out += ("[url=%s]%s[/url]" % [id, col]) if link and id != exclude else col
		at = m.get_end()
	return out + text.substr(at)


## Texto sem marcação (para onde não há RichTextLabel).
static func plain(text: String) -> String:
	var out := ""
	var at := 0
	for m in inst_re().search_all(text):
		out += text.substr(at, m.get_start() - at)
		out += m.get_string(2) if m.get_string(2) != "" else kw_name(m.get_string(1))
		at = m.get_end()
	return out + text.substr(at)


## Ids das palavras-chave do texto, na ordem, sem repetir.
static func keywords(text: String) -> Array:
	var ids: Array = []
	for m in inst_re().search_all(text):
		var id := m.get_string(1)
		if not ids.has(id):
			ids.append(id)
	return ids


static func inst_re() -> RegEx:
	if _static_re == null:
		_static_re = RegEx.create_from_string("\\[\\[([a-z_]+)(?:\\|([^\\]]+))?\\]\\]")
	return _static_re


static func kw_name(id: String) -> String:
	return TranslationServer.translate("KW_" + id)


static func kw_desc(id: String) -> String:
	return TranslationServer.translate("KWD_" + id).format(_kw_params())


static func _num(x) -> Variant:
	if typeof(x) == TYPE_FLOAT and is_equal_approx(x, round(x)):
		return int(x)
	return x


static func _pct(x) -> int:
	return int(round(absf(float(x)) * 100.0))


## Números das explicações, sempre lidos dos dados (o ajustador muda os números, o texto acompanha).
static func _kw_params() -> Dictionary:
	if data == null:
		return {}
	var R: Dictionary = data.rules
	var S: Dictionary = R["status"]
	var L: Dictionary = R["locations"]
	var A: Dictionary = R["arena"]
	var Hs: Dictionary = data.hero["shield"]
	var p := {
		"slow": _pct(S["slow"]), "fear": _num(S["fear"]), "soaked_mult": _num(R["fire_vs_soaked"]),
		"curse_hp": _pct(R["curse"]["hp_per_stack"]), "curse_max": _num(R["curse"]["max_stacks"]),
		"shield_hp": _num(Hs["hp"]), "shield_cone": _num(Hs["cone"]), "shield_regen": _num(Hs["regen_seconds"]),
		"hp_growth": _pct(data.hero["hp_growth"]), "dmg_growth": _pct(data.hero["damage_growth"]),
		"upg_every": _num(R["hero_xp"].get("upgrade_every", 1)), "upg_max": _num(R["hero_xp"].get("upgrade_max", 15)),
		"gold_dmg": _num(R["gold"]["damage_per_gold"]), "gold_win": _num(R["gold"]["per_contest"]),
		"tavern_houses": _num(L["tavern"]["houses"]), "tavern_house_hp": _num(L["tavern"]["house_hp"]),
		"tavern_aggro": _num(L["tavern"]["aggro_r"]), "tavern_s": _num(L["tavern"]["window"]),
		"fountain_s": _num(L["fountain"]["drink_s"]), "fountain_dmg": _num(L["fountain"]["interrupt_damage"]),
		"fountain_heal": _pct(L["fountain"]["heal"]),
		"ritual_mult": _num(L["ritual"]["elixir_mult"]), "ritual_kills": _num(L["ritual"]["kills"]), "ritual_s": _num(L["ritual"]["window"]),
		"shrine_s": _num(L["shrine"]["hold_s"]), "shrine_window": _num(L["shrine"]["window"]),
		"bridge_atk": _pct(L["bridge"]["attack_speed"]), "bridge_s": _num(L["bridge"]["duration"]), "bridge_win": _num(L["bridge"]["win_damage"]),
		"tp_cd": _num(A["teleport_cooldown"]), "tp_cost": _num(A["teleport_cost"]), "altar_hp": _num(A["altar_hp"]),
		"sac_cd": _num(R["sacrifice_cooldown"]),
	}
	for mid in data.modifiers:
		var mp: Dictionary = data.modifiers[mid].get("p", {})
		for k in mp:
			p["%s_%s" % [mid, k]] = _num(mp[k])
	return p


# ---------------------------------------------------------------- rótulos

## Rótulo com palavras-chave que abrem caixa (texto solto: contrato, dica, regras do deck...).
static func label(text: String, size := 15, col := UiKit.TEXT, w := 0.0, center := false) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.meta_underlined = false
	l.add_theme_font_size_override("normal_font_size", roundi(size * UiCovil.TEXT_SCALE) if UiSkins.covil() else size)
	l.add_theme_color_override("default_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 2 if UiSkins.covil() else 3)
	if w > 0.0:
		l.custom_minimum_size = Vector2(w, 0)
	l.set_meta("center", center)
	set_text(l, text)
	_wire(l, 0)
	return l


static func set_text(l: RichTextLabel, text: String, link := true, exclude := "") -> void:
	var t := rich(text, link, exclude)
	l.text = "[center]%s[/center]" % t if l.get_meta("center", false) else t


static func _wire(l: RichTextLabel, level: int) -> void:
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.meta_hover_started.connect(func(m): if inst: inst._word_enter(str(m), level, l))
	l.meta_hover_ended.connect(func(_m): if inst: inst._word_exit(level, l))


# ---------------------------------------------------------------- objetos

## Liga caixas a um controle: com o mouse em cima, abre as entradas de `builder` (chamado só ao abrir).
static func attach(c: Control, builder: Callable) -> void:
	c.set_meta("tip_builder", builder)
	if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.mouse_entered.connect(func(): if inst: inst._attached = c)
	c.mouse_exited.connect(func(): if inst and inst._attached == c: inst._attached = null)


## Chamado a cada quadro enquanto um objeto está sob o mouse: abre (se preciso) e segura o nível 0.
static func hold(owner: String, anchor: Rect2, builder: Callable) -> void:
	if inst == null:
		return
	if inst.levels.size() > 0 and inst.levels[0]["owner"] == owner:
		inst.levels[0]["seen"] = Engine.get_process_frames()
		return
	var entries: Array = builder.call()
	if entries.is_empty():
		return
	inst._open(0, owner, anchor, entries, null)


## Entrada de caixa: título, corpo (com marcação), ícone opcional, id da palavra-chave (não vira link de si mesma).
static func entry(title: String, body: String, icon: Control = null, kw := "") -> Dictionary:
	return {"title": title, "body": body, "icon": icon, "kw": kw}


static func kw_entry(id: String) -> Dictionary:
	return entry(kw_name(id), kw_desc(id), null, id)


## Caixas de uma carta: (opcional) o texto dela e depois cada palavra-chave do tipo, das tags, dos modificadores e do texto.
static func card_entries(d: CardDef, mod_ids: Array, with_card: bool, level := 1) -> Array:
	var out: Array = []
	var desc := UiKit.card_desc(d, level)
	if with_card:
		var body := "%s\n%s" % [UiKit.type_line(d), desc]
		for mid in mod_ids:
			body += "\n★ [[%s]]: %s" % [mid, TranslationServer.translate("MODDESC_" + mid)]
		# Na coleção e nas ofertas: o que o nível 3 acrescenta.
		if level < 3 and d.n3.size() > 0:
			var n3 := TranslationServer.translate("N3_" + d.id).format(UiKit.card_params(d, 3))
			body += "\n" + TranslationServer.translate("UI_N3_PREVIEW").format({"t": n3})
		out.append(entry(UiKit.card_name(d, level), body))
	var ids: Array = [d.type]
	ids.append_array(d.tag_names)
	ids.append_array(mod_ids)
	for id in keywords(desc):
		if not ids.has(id):
			ids.append(id)
	for id in ids:
		if KEYWORDS.has(id):
			out.append(kw_entry(id))
	return out


## Caixas de um texto qualquer: o próprio texto e as palavras-chave dele.
static func text_entries(title: String, body: String, icon: Control = null) -> Array:
	var out: Array = [entry(title, body, icon)]
	for id in keywords(body):
		out.append(kw_entry(id))
	return out


# ---------------------------------------------------------------- níveis

func _word_enter(id: String, level: int, l: RichTextLabel) -> void:
	if level >= MAX_DEPTH or not KEYWORDS.has(id):
		return
	if levels.size() > level and levels[level]["owner"] == "kw:" + id:
		levels[level]["word"] = l
		return
	# A palavra já tem caixa aberta num nível de cima (ex.: ao lado da carta): não repete.
	for i in mini(level, levels.size()):
		if levels[i]["kws"].has(id):
			return
	var m := _mouse()
	var anchor := Rect2(m + Vector2(0, -11), Vector2(4, 22))
	if level > 0:
		# Palavra dentro de uma caixa: a nova coluna vai ao lado da coluna de cima, na altura da palavra.
		var up: Rect2 = (levels[level - 1]["col"] as Control).get_global_rect()
		anchor = Rect2(Vector2(up.position.x, m.y - 11.0), Vector2(up.size.x, 22))
	_open(level, "kw:" + id, anchor, [kw_entry(id)], l)


func _word_exit(level: int, l: RichTextLabel) -> void:
	if levels.size() > level and levels[level]["word"] == l:
		levels[level]["word"] = null


func _open(level: int, owner: String, anchor: Rect2, entries: Array, word: RichTextLabel) -> void:
	_close_from(level)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var boxes: Array = []
	var kws: Array = []
	for e in entries:
		var b := _make_box(e, level)
		col.add_child(b)
		boxes.append(b)
		if e["kw"] != "":
			kws.append(e["kw"])
	root.add_child(col)
	col.reset_size()
	var vs := root.get_viewport_rect().size
	var cs := col.get_combined_minimum_size()
	var x := anchor.end.x + 8.0
	var y := anchor.position.y
	if word and level == 0:
		# Palavra solta: logo abaixo dela (ou acima, se não couber), sem cobrir a linha.
		x = anchor.position.x - 24.0
		y = anchor.end.y + 4.0
		if y + cs.y > vs.y - 8.0:
			y = anchor.position.y - cs.y - 4.0
	elif x + cs.x > vs.x - 8.0:
		x = anchor.position.x - cs.x - 8.0
	y = clampf(y, 8.0, maxf(vs.y - cs.y - 8.0, 8.0))
	col.position = Vector2(clampf(x, 8.0, maxf(vs.x - cs.x - 8.0, 8.0)), y)
	levels.append({"owner": owner, "col": col, "boxes": boxes, "kws": kws, "word": word, "seen": Engine.get_process_frames(), "t": 0.0})


func _make_box(e: Dictionary, level: int) -> PanelContainer:
	var p := UiKit.panel(Color(0.06, 0.04, 0.1, 0.97), UiKit.GOLD.darkened(0.15), 10)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if e["icon"]:
		head.add_child(e["icon"])
	var t := UiKit.label(17, KW_COLOR if e["kw"] != "" else UiKit.GOLD, 3)
	t.text = e["title"]
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(t)
	v.add_child(head)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.meta_underlined = false
	body.custom_minimum_size = Vector2(BOX_W, 0)
	body.add_theme_font_size_override("normal_font_size", 15)
	body.add_theme_color_override("default_color", Color(0.92, 0.9, 0.98))
	body.text = rich(e["body"], level + 1 < MAX_DEPTH, e["kw"])
	_wire(body, level + 1)
	v.add_child(body)
	return p


func _mouse() -> Vector2:
	return root.get_global_mouse_position() if mouse_override == null else mouse_override


func _close_from(level: int) -> void:
	while levels.size() > level:
		var lv: Dictionary = levels.pop_back()
		lv["col"].queue_free()


func _mouse_in(lv: Dictionary, m: Vector2) -> bool:
	for b in lv["boxes"]:
		if (b as Control).get_global_rect().grow(4.0).has_point(m):
			return true
	return false


func _process(delta: float) -> void:
	if _attached and (not is_instance_valid(_attached) or not _attached.is_visible_in_tree()):
		_attached = null
	if _attached:
		var c := _attached
		hold("obj:%d" % c.get_instance_id(), c.get_global_rect(), c.get_meta("tip_builder"))
	if levels.is_empty():
		return
	var m := _mouse()
	var frame := Engine.get_process_frames()
	var deeper := false
	for i in range(levels.size() - 1, -1, -1):
		var lv: Dictionary = levels[i]
		var w = lv["word"]
		if w != null and (not is_instance_valid(w) or not w.is_visible_in_tree() or not w.get_global_rect().has_point(m)):
			lv["word"] = null
			w = null
		var alive: bool = deeper or w != null or frame - int(lv["seen"]) <= 1 or _mouse_in(lv, m)
		if alive:
			lv["t"] = 0.0
		else:
			lv["t"] += delta
			if lv["t"] >= GRACE:
				_close_from(i)
				deeper = false
				continue
		deeper = deeper or alive
