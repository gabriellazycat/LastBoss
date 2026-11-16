class_name UiKit
extends RefCounted
## Peças de interface compartilhadas (menu, HUD, pausa): paleta, tema, painéis, barras e o desenho das cartas.

# Paleta: estática (e não const) porque a pele da HUD (Settings "look_hud") troca as cores. Ver UiSkins.
static var BG := Color(0.055, 0.04, 0.085, 0.92)
static var BG_SOFT := Color(0.05, 0.035, 0.08, 0.72)
static var EDGE := Color(0.42, 0.3, 0.6)
static var GOLD := Color(1.0, 0.76, 0.36)
static var TEXT := Color(0.95, 0.92, 1.0)
static var MUTED := Color(0.72, 0.68, 0.82)
static var HERO_HP := Color(0.9, 0.24, 0.22)
static var HERO_XP := Color(1.0, 0.7, 0.3)
static var POWER := Color(0.72, 0.42, 1.0)
static var ELIXIR := Color(0.86, 0.32, 0.96)
static var GOOD := Color(0.45, 1.0, 0.6)
static var BAD := Color(1.0, 0.45, 0.4)
static var RARITY_COLORS := [Color(0.62, 0.62, 0.62), Color(0.35, 0.8, 0.35), Color(0.3, 0.55, 1.0), Color(0.7, 0.35, 1.0)]

static var _title_font: Font


## Fonte dos títulos: Cinzel na pele Covil; nas outras, a da pele ou uma serifada do sistema.
static func title_font() -> Font:
	if UiSkins.diario():
		return UiDiario.font("type")
	if _title_font == null and UiSkins.covil():
		_title_font = UiCovil.font("title")
	if _title_font == null:
		_title_font = UiSkins.title_font()
	if _title_font == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Cinzel", "Trajan Pro", "Georgia", "Palatino Linotype", "Times New Roman", "serif"])
		sf.font_weight = 700
		var fv := FontVariation.new()
		fv.base_font = sf
		fv.spacing_glyph = 3
		_title_font = fv
	return _title_font


## Caixa chanfrada: cantos cortados em diagonal (corner_detail 1) em vez de arredondados.
## A pele pode arredondar os cantos (UiSkins.corner()).
static func box(bg: Color, border: Color, bw := 1, cut := 8, margin := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(cut)
	sb.corner_detail = 1
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	UiSkins.style_box(sb, cut)
	return sb


static func make_theme() -> Theme:
	UiSkins.apply()
	_title_font = null
	var t := Theme.new()
	if UiSkins.diario():
		UiDiario.fill_theme(t)
		return t
	if UiSkins.covil():
		UiCovil.fill_theme(t)
		return t
	t.default_font_size = 18
	if UiSkins.body_font():
		t.default_font = UiSkins.body_font()
	var states := {
		"normal": [Color(0.09, 0.06, 0.14, 0.94), EDGE, 0],
		"hover": [Color(0.17, 0.1, 0.24, 0.98), GOLD, 5],
		"pressed": [Color(0.26, 0.13, 0.32), GOLD.lightened(0.2), 5],
		"focus": [Color(0.17, 0.1, 0.24, 0.98), GOLD, 5],
		"disabled": [Color(0.06, 0.05, 0.08, 0.8), Color(0.25, 0.23, 0.3), 0]}
	if UiSkins.on():
		states = UiSkins.button_states()
	for st in states:
		var sb: StyleBox = UiSkins.button_box(st, states[st][0], states[st][1]) if UiSkins.on() else null
		if sb == null:
			var fb := box(states[st][0], states[st][1], 1, 8, 12)
			fb.border_width_left = 1 + states[st][2]
			fb.content_margin_left = 16
			fb.shadow_color = Color(0, 0, 0, 0.4)
			fb.shadow_size = 4
			sb = fb
		t.set_stylebox(st, "Button", sb)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", UiSkins.hover_text())
	t.set_color("font_focus_color", "Button", UiSkins.hover_text())
	t.set_color("font_pressed_color", "Button", Color(1.0, 0.95, 0.8))
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.42, 0.5))
	t.set_color("font_outline_color", "Button", Color.BLACK)
	t.set_constant("outline_size", "Button", 3)
	t.set_color("font_outline_color", "Label", Color.BLACK)
	t.set_constant("outline_size", "Label", 4)
	t.set_color("font_color", "Label", TEXT)
	# Sliders e caixas de seleção das configurações.
	var track := box(Color(0, 0, 0, 0.55), EDGE.darkened(0.3), 1, 3, 0)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	var fill := box(POWER.darkened(0.15), POWER, 0, 3, 0)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _diamond(GOLD.darkened(0.1)))
	t.set_icon("grabber_highlight", "HSlider", _diamond(GOLD.lightened(0.3)))
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := box(Color(0.09, 0.06, 0.14, 0.94), GOLD if st in ["hover", "focus"] else EDGE, 1, 6, 8)
		t.set_stylebox(st, "OptionButton", sb)
	t.set_color("font_color", "OptionButton", TEXT)
	t.set_stylebox("panel", "PopupMenu", box(BG, EDGE, 1, 6, 6))
	t.set_stylebox("hover", "PopupMenu", box(Color(0.2, 0.12, 0.3), GOLD, 0, 4, 4))
	t.set_stylebox("panel", "TooltipPanel", box(BG, GOLD.darkened(0.3), 1, 4, 8))
	return t


static func _diamond(col: Color) -> ImageTexture:
	var n := 20
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in n:
		for x in n:
			var d := absf(x - c) + absf(y - c)
			if d <= c:
				img.set_pixel(x, y, col if d < c - 2.0 else Color(0.1, 0.05, 0.0))
	return ImageTexture.create_from_image(img)


static func panel(bg := BG, border := EDGE, margin := 10) -> PanelContainer:
	if UiSkins.diario():
		return UiDiario.panel(bg, border, margin)
	if UiSkins.covil():
		return UiCovil.panel(bg, border, margin, "soft" if bg.a < 0.9 else "plate")
	var p := PanelContainer.new()
	var sb: StyleBox = UiSkins.panel_box(bg, border, margin) if UiSkins.on() else null
	p.add_theme_stylebox_override("panel", sb if sb else box(bg, border, 1, 8, margin))
	return p


static func label(size := 18, col := TEXT, outline := 4) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", outline)
	if UiSkins.diario():
		UiDiario.label(l, size, outline)
	elif UiSkins.covil():
		UiCovil.label(l, size, outline)
	return l


static func title(size: int, col := GOLD) -> Label:
	var l := label(size, col, maxi(4, size / 9))
	if UiSkins.diario():
		UiDiario.title(l, size, col)
		return l
	if UiSkins.covil():
		UiCovil.title(l, size, col)
		return l
	l.add_theme_font_override("font", title_font())
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", maxi(2, size / 20))
	return l


static func bar(col: Color, w: float, h: float) -> ProgressBar:
	if UiSkins.diario():
		return UiDiario.bar(col, w, h)
	if UiSkins.covil():
		return UiCovil.bar(col, w, h)
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.show_percentage = false
	if UiSkins.on():
		b.add_theme_stylebox_override("fill", UiSkins.bar_fill(col, h))
		b.add_theme_stylebox_override("background", UiSkins.bar_back(h))
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return b
	var fg := box(col, col.lightened(0.35), 0, 2, 0)
	fg.border_width_top = 1 if h >= 8 else 0
	var bg := box(Color(0, 0, 0, 0.62), Color(0, 0, 0, 0.9), 1, 2, 0)
	b.add_theme_stylebox_override("fill", fg)
	b.add_theme_stylebox_override("background", bg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## Losango com um número (nível, custo). A pele troca a forma (medalha, hexágono, orbe, losango). Na Covil,
## `shape` escolhe a gema: "crystal" (custo, elixir; o padrão), "crest" (herói) ou "sigil" (poder).
static func badge(col: Color, size := 22, w := 40.0, shape := "crystal") -> PanelContainer:
	if UiSkins.diario():
		return UiDiario.badge(col, size, w, shape)
	if UiSkins.covil():
		return UiCovil.badge(col, size, w, shape)
	var g := PanelContainer.new()
	var sb: StyleBox = UiSkins.badge_box(col, w) if UiSkins.on() else box(col.darkened(0.45), col.lightened(0.3), 2, int(w * 0.32), 0)
	g.add_theme_stylebox_override("panel", sb)
	g.custom_minimum_size = Vector2(w, w)
	var l := label(size, Color.WHITE)
	l.name = "N"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	g.add_child(l)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


## Ícone da relíquia (15/11/2026): assets/ui/relics/<id>.svg (gerado por tools/art/relic_icons.py).
## Sem arquivo, devolve um quadrado vazio do mesmo tamanho (o layout não pula).
static func relic_icon(id: String, px: float) -> TextureRect:
	var tr_ := TextureRect.new()
	var path := "res://assets/ui/relics/%s.svg" % id
	if ResourceLoader.exists(path):
		tr_.texture = load(path)
	tr_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr_.custom_minimum_size = Vector2(px, px)
	tr_.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tr_.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr_


## Esvazia um contêiner na hora. Só queue_free deixa os filhos velhos contando no tamanho até o fim do quadro,
## e um contêiner que cresceu por causa deles não encolhe sozinho.
static func clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


## Fundo de um painel que não é PanelContainer criado aqui (configurações): moldura da pele ou caixa simples.
static func panel_style(c: Control, bg: Color, border: Color, margin: int) -> void:
	if UiSkins.diario():
		UiDiario.dress(c, "paper", margin + 8, {"grime": 0.35, "seed": 0.6})
		return
	if UiSkins.covil():
		var ic := UiCovil.iron(bg)
		UiCovil.dress(c, "plate", UiCovil.trim_for(border), ic[0], ic[1], Color(0, 0, 0, 0), margin)
		return
	c.add_theme_stylebox_override("panel", box(bg, border, 1, 12, margin))


## Cor de um título depois de criado (na Covil o degradê de metal segue a cor).
static func title_color(l: Label, col: Color) -> void:
	if UiSkins.diario():
		l.add_theme_color_override("font_color", UiDiario.ink_of(col))
		return
	if UiSkins.covil() and l.material is ShaderMaterial:
		l.material = UiCovil.title_material(l.get_theme_font_size("font_size"), col)
		return
	l.add_theme_color_override("font_color", col)


## Estado de uma carta da mão: selecionada (borda dourada) e jogável (brilho verde).
static func card_state(p: Control, selected: bool, playable: bool) -> void:
	if UiSkins.diario():
		UiDiario.card_state(p, selected, playable)
		return
	if UiSkins.covil():
		UiCovil.card_state(p, selected, playable)
		return
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
	sb.set_border_width_all(4 if selected else 2)
	sb.border_color = GOLD if selected else p.get_meta("rarity_color", EDGE)
	sb.shadow_color = Color(1.0, 0.7, 0.3, 0.55) if selected else (Color(0.5, 1.0, 0.6, 0.25) if playable else Color(0, 0, 0, 0.5))


## Painel aceso (Pacto em foco no menu).
static func set_hot(c: Control, on: bool) -> void:
	if UiSkins.diario():
		UiDiario.set_hot(c, on)
		return
	if UiSkins.covil():
		UiCovil.set_hot(c, on)
		return
	var sb: StyleBox = c.get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		(sb as StyleBoxFlat).border_color = GOLD if on else EDGE
	elif sb is StyleBoxTexture:
		(sb as StyleBoxTexture).modulate_color = Color(1.3, 1.22, 1.1) if on else Color.WHITE


static func ignore_mouse(n: Node) -> void:
	for c in n.find_children("*", "Control", true, false):
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ---------------------------------------------------------------- cartas

## Números do texto da carta no nível dado; frações viram também `<chave>_pct` (0,125 → 13).
const UP_COLOR := "#2f7d3a"         # número que o upgrade melhorou (verde), no texto da carta
const COST_COLOR := "#13808c"       # custo que baixou (azul-água)
const N3_COLOR := "#8a5a08"         # efeito especial do nível 3 (ouro escuro)


static func card_params(d: CardDef, level := 1, mark := false, mids: Array = []) -> Dictionary:
	var p := {"count": d.count_at(level)}
	var keys: Array = d.fx.keys()
	for k in d.n3:
		if not keys.has(k):
			keys.append(k)
	for k in keys:
		var x = d.fx.get(k, d.n3.get(k))
		if typeof(x) == TYPE_FLOAT or typeof(x) == TYPE_INT:
			x = d.fxv(k, level) if d.fx.has(k) else float(d.n3[k])
			p[k + "_pct"] = int(round(x * 100.0))
			x = int(round(x)) if is_equal_approx(x, round(x)) or absf(x) >= 20.0 else snappedf(x, 0.1)
		p[k] = x
	# Veterano: +1 unidade (só monstro e enxame).
	var vet_keys: Array = []
	if mids.has("veteran") and d.is_unit:
		p["count"] = int(p["count"]) + 1
		vet_keys.append("count")
	if mark:
		for k in vet_keys:
			p[k] = "[color=%s]%s▲[/color]" % [UP_COLOR, str(p[k])]
	# Carta upada: os números que cresceram saem em verde com ▲ (o texto já mostra o valor novo).
	if mark and level > 1:
		for k in p.keys():
			var grew: bool = (k == "count" and d.scales("count")) or (d.scales(k) and d.fx.has(k)) or (level >= 3 and d.n3.has(k))
			if grew and not str(k).ends_with("_pct") and not vet_keys.has(k):
				p[k] = "[color=%s]%s▲[/color]" % [UP_COLOR, str(p[k])]
				if p.has(k + "_pct"):
					p[k + "_pct"] = "[color=%s]%s[/color]" % [UP_COLOR, str(p[k + "_pct"])]
	return p


## O que muda de um nível para o outro ("Vida 75 → 94 · DPS 8 → 10").
static func level_changes(d: CardDef, from: int, to: int) -> String:
	var parts: Array = []
	for k in d.lvl:
		var a: float
		var b: float
		match str(k):
			"count":
				a = d.count_at(from); b = d.count_at(to)
			"hp":
				a = d.hp_at(from) if d.is_unit else d.fxv("hp", from)
				b = d.hp_at(to) if d.is_unit else d.fxv("hp", to)
			"dps":
				a = d.dps_at(from) if d.is_unit else d.fxv("dps", from)
				b = d.dps_at(to) if d.is_unit else d.fxv("dps", to)
			"cost":
				a = d.cost_at(from); b = d.cost_at(to)
			_:
				a = d.fxv(k, from); b = d.fxv(k, to)
		var fa := "%d%%" % int(round(a * 100.0)) if a < 1.0 and b < 1.0 else (str(int(round(a))) if absf(a) >= 20.0 or is_equal_approx(a, round(a)) else str(snappedf(a, 0.1)))
		var fb := "%d%%" % int(round(b * 100.0)) if a < 1.0 and b < 1.0 else (str(int(round(b))) if absf(b) >= 20.0 or is_equal_approx(b, round(b)) else str(snappedf(b, 0.1)))
		parts.append("%s %s → %s" % [TranslationServer.translate("LVLK_" + k), fa, fb])
	return " · ".join(parts)


## Nome da carta: cada nível acima do 1 ganha um "+" (Horda de Ratos+).
static func card_name(d: CardDef, level := 1) -> String:
	return TranslationServer.translate("CARD_" + d.id) + "+".repeat(maxi(0, level - 1))


## Texto da carta com a marcação de palavras-chave ([[id]]); Tips.rich/plain convertem. No N3, o especial vem junto.
static func card_desc(d: CardDef, level := 1, mark := false, mids: Array = [], stats := true) -> String:
	var p := card_params(d, level, mark, mids)
	var t := TranslationServer.translate("DESC_" + d.id).format(p)
	if level >= 3 and d.n3.size() > 0:
		var n3 := TranslationServer.translate("N3_" + d.id).format(p)
		t += (" [color=%s]★ %s[/color]" % [N3_COLOR, n3]) if mark else " " + n3
	if stats and d.is_unit:
		t += "\n" + unit_stats(d, level, mark, mids)
	if mark and level > 1:
		# Números que o texto não cita (custo; vida e dano das unidades quando a linha de status está fora): o antigo riscado, o novo colorido.
		var parts: Array = []
		for k in d.lvl:
			var a: float
			var b: float
			var col := UP_COLOR
			var arrow := "▲"
			match str(k):
				"hp":
					if not d.is_unit or stats:
						continue
					a = d.hp; b = d.hp_at(level)
				"dps":
					if not d.is_unit or stats:
						continue
					a = d.dps; b = d.dps_at(level)
				"cost":
					a = d.cost; b = d.cost_at(level); col = COST_COLOR; arrow = "▼"
				_:
					continue
			parts.append("%s [s]%d[/s] [color=%s]%d%s[/color]" % [TranslationServer.translate("LVLK_" + k), int(round(a)), col, int(round(b)), arrow])
		if parts.size() > 0:
			t += "\n" + " · ".join(parts)
	return t


## Linha de status da unidade: "Vida 75 · DPS 8" (por unidade); bando ganha "×N" ao lado do DPS.
## Carta upada (mark): o número que cresceu sai em verde com ▲.
static func unit_stats(d: CardDef, level := 1, mark := false, mids: Array = []) -> String:
	var hp := str(int(round(d.hp_at(level))))
	var dv := d.dps_at(level)
	var dps := str(int(round(dv))) if absf(dv) >= 20.0 or is_equal_approx(dv, round(dv)) else str(snappedf(dv, 0.1))
	var n := d.count_at(level) + (1 if mids.has("veteran") else 0)
	if mark and level > 1:
		if d.scales("hp"):
			hp = "[color=%s]%s▲[/color]" % [UP_COLOR, hp]
		if d.scales("dps"):
			dps = "[color=%s]%s▲[/color]" % [UP_COLOR, dps]
	var parts: Array = ["%s %s" % [TranslationServer.translate("LVLK_hp"), hp]]
	if dv > 0.0:
		parts.append("%s %s" % [TranslationServer.translate("LVLK_dps"), dps])
	var s := " · ".join(parts)
	if n > 1:
		s += " ×%d" % n
	return s


## Texto da carta como BBCode, com as palavras-chave coloridas (sem link: a carta abre as caixas ao lado).
static func card_rich(d: CardDef, size: int, col: Color, w: float, center := true, level := 1, mids: Array = []) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(w, 0)
	l.add_theme_font_size_override("normal_font_size", size)
	l.add_theme_color_override("default_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	var t := Tips.rich(card_desc(d, level, true, mids), false)
	l.text = "[center]%s[/center]" % t if center else t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Linha de uma carta bloqueada: "Desafio: ... (11/15)" (o texto vem de UNLOCK_<id>; o progresso, do MetaSave).
static func unlock_text(meta: MetaSave, d: CardDef) -> String:
	if not meta.data.unlock_challenges.has(d.id):
		return TranslationServer.translate("UI_UNLOCK_WITH").format({"v": TranslationServer.translate("DECK_" + d.owner)})
	var t := TranslationServer.translate("UNLOCK_" + d.id)
	var p: Dictionary = meta.progress.get(d.id, {})
	var extra := ""
	if not p.is_empty() and float(p.get("g", 1.0)) > 1.0:
		extra = " (%d/%d)" % [int(floor(float(p["v"]))), int(round(float(p["g"])))]
	return TranslationServer.translate("UI_CHALLENGE").format({"t": t}) + extra


static func type_line(d: CardDef) -> String:
	var parts: Array = [TranslationServer.translate("TYPE_" + d.type)]
	for t in d.tag_names:
		parts.append(TranslationServer.translate("TAG_" + t))
	# Fera é característica (fx.beast), não tag de dados: aparece na linha de tipos como Bando, Fogo etc.
	if d.beast and not d.tag_names.has("beast"):
		parts.append(TranslationServer.translate("TAG_beast"))
	return " · ".join(parts)


## Regras do vilão: a passiva dele (a vida dos heróis é igual para todos: rules.hero_hp_mult).
static func deck_rules_text(data: GameData, vid: String) -> String:
	var id := data.villain_id(vid)
	var lines: Array = ["• " + TranslationServer.translate("VILLAIN_%s_PASSIVE" % id)]
	return "
".join(lines)


## Modificadores da carta; o primeiro ganho vem na frente (é o dono do papel da carta).
static func mod_ids(ci: Sim.CardInst) -> Array:
	var ids: Array = []
	for mid in K.MOD_IDS:
		if ci.has_mod(K.MOD_BY_ID[mid]):
			if int(K.MOD_BY_ID[mid]) == ci.first_mod:
				ids.push_front(mid)
			else:
				ids.append(mid)
	return ids


static func mod_names(ci: Sim.CardInst) -> Array:
	return mod_ids(ci).map(func(mid): return TranslationServer.translate("MOD_" + mid))


## Ids dos modificadores a partir dos nomes traduzidos (as cartas desenhadas recebem os nomes, na ordem).
static func mod_ids_of(names: Array) -> Array:
	var ids: Array = []
	for nm in names:
		for mid in K.MOD_IDS:
			if TranslationServer.translate("MOD_" + mid) == nm:
				ids.append(mid)
	return ids


## Carta compacta (mão em leque e esteira): arte, custo, atalho e, se `named`, o nome (★ = tem modificador).
static func mini_card(d: CardDef, cost: int, mods: Array, key := "", w := 116.0, h := 146.0, named := true, level := 1) -> PanelContainer:
	if UiSkins.diario():
		return UiDiario.mini_card(d, cost, mods, key, w, h, named, level)
	if UiSkins.covil():
		return UiCovil.mini_card(d, cost, mods, key, w, h, named, level)
	var k := w / 116.0
	var rc: Color = RARITY_COLORS[d.rarity]
	var p := PanelContainer.new()
	var sb := box(UiSkins.card_bg(), rc, 2, int(7 * k), int(4 * k))
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 5
	p.add_theme_stylebox_override("panel", sb)
	p.set_meta("rarity_color", rc)
	p.custom_minimum_size = Vector2(w, h)
	p.size = p.custom_minimum_size
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	var over := Control.new()
	over.custom_minimum_size = Vector2(w - 8 * k, (h - 8 * k) * (0.62 if named else 1.0))
	over.clip_contents = true
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = UiDiario.hand_art(d.id)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	over.add_child(art)
	var gs := clampf(30.0 * k, 18.0, 30.0)
	var gem := badge(ELIXIR, int(gs * 0.62), gs)
	gem.name = "Gem"
	(gem.get_node("N") as Label).name = "Cost"
	(gem.get_node("Cost") as Label).text = str(cost)
	gem.position = Vector2(1, 1)
	over.add_child(gem)
	if key != "":
		var kl := label(int(14 * k), Color(0.92, 0.9, 0.98))
		kl.text = key
		kl.position = Vector2(w - 8 * k - 16 * k, 1)
		over.add_child(kl)
	v.add_child(over)
	if named:
		var nl := label(int(13 * k), rc.lightened(0.5), 3)
		nl.text = ("★ " if mods.size() > 0 else "") + card_name(d, level)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD
		nl.max_lines_visible = 2
		nl.custom_minimum_size = Vector2(w - 8 * k, 0)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if mods.size() > 0:
			nl.add_theme_color_override("font_color", GOLD)
		v.add_child(nl)
	p.add_child(v)
	ignore_mouse(p)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Carta desenhada: arte, custo, atalho, nome, tipo, modificadores e texto. `w` define a escala.
static func card(d: CardDef, cost: int, mods: Array, key := "", w := 168.0, level := 1) -> PanelContainer:
	if UiSkins.diario():
		var dc := UiDiario.card(d, cost, mods, key, w, level)
		dc.set_meta("ui_card", true)   # --bare (capturas para maquete) mantém as cartas e esconde o resto
		return dc
	if UiSkins.covil():
		return UiCovil.card(d, cost, mods, key, w, level)
	var k := w / 168.0
	var rc: Color = RARITY_COLORS[d.rarity]
	var p := PanelContainer.new()
	var sb := box(UiSkins.card_bg(), rc, 2, 8, 6)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(w, 246.0 * k)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var over := Control.new()
	over.custom_minimum_size = Vector2(w - 12, 96.0 * k)
	over.clip_contents = true
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = UiDiario.hand_art(d.id)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	over.add_child(art)
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0.04, 0.03, 0.07, 0.85))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0.55)
	gt.fill_to = Vector2(0, 1)
	var fade := TextureRect.new()
	fade.texture = gt
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	over.add_child(fade)
	var gem := badge(ELIXIR, int(22 * k), 34.0 * k)
	gem.name = "Gem"
	(gem.get_node("N") as Label).name = "Cost"
	(gem.get_node("Cost") as Label).text = str(cost)
	gem.position = Vector2(2, 2)
	over.add_child(gem)
	if key != "":
		var kl := label(int(14 * k), Color(0.92, 0.9, 0.98))
		kl.text = key
		kl.position = Vector2(w - 12 - 18 * k - 4, 2)
		over.add_child(kl)
	var name_ := label(int(16 * k), rc.lightened(0.5))
	name_.text = card_name(d, level)
	name_.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tl := label(int(11 * k), MUTED, 3)
	tl.text = type_line(d)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tl.custom_minimum_size = Vector2(w - 12, 0)
	var ml := label(int(12 * k), GOLD)
	var stars: Array = []
	for m in mods:
		stars.append("★ " + m)
	ml.text = "  ".join(stars)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD
	ml.visible = mods.size() > 0
	var desc := card_rich(d, int(13 * k), Color(0.9, 0.9, 0.96), w - 12, true, level)
	for n in [over, name_, tl, ml, desc]:
		v.add_child(n)
	p.add_child(v)
	ignore_mouse(p)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p
