class_name UiKit
extends RefCounted
## Peças de interface compartilhadas (menu, HUD, pausa): paleta, tema, painéis, barras e o desenho das cartas.

# Paleta: estática (e não const) porque UiSkins.apply() põe as cores da pele no começo. Ver UiSkins.
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


# ---------------------------------------------------------------- escala de espaçamento (rodada de UI de 20/11/2026)
## Uma escala só para toda margem e folga da interface, em pixels lógicos. Margem escrita à mão nova usa estes degraus.
const SP_XS := 4
const SP_S := 8
const SP_M := 12
const SP_L := 16
const SP_XL := 24
const SP_XXL := 32

## Quanto do papel a moldura desenhada ocupa a partir da borda do PNG (px 1:1, medido nos PNGs de assets/ui/kit*/:
## do contorno externo até a última linha de tinta/ouro). O 9-slice não escala, então vale em qualquer tamanho de caixa.
## O texto precisa começar DEPOIS disso mais a folga abaixo; a margem de conteúdo conta a moldura, não só a caixa.
const DEPTH_MAPA := {"gold": 22, "dark": 22, "night": 22, "ink": 10, "button_ink": 7, "button_gold": 11, "ribbon": 8}
const DEPTH_KIT := {"gold": 10, "dark": 10, "night": 10, "ink": 8, "button_ink": 4, "button_gold": 4, "ribbon": 8}
const GAP_PANEL := SP_S      # texto ↔ última linha da moldura de um painel (os dois eixos)
const GAP_BUTTON_X := SP_S   # idem num botão, na horizontal
const GAP_BUTTON_Y := SP_XS  # idem na vertical (a caixa de linha da fonte já traz folga acima e abaixo do desenho)


## Profundidade da moldura de um tipo de peça do kit ("gold", "ink", "button_ink"...) na pele atual.
static func paper_depth(kind: String) -> float:
	var t: Dictionary = DEPTH_MAPA
	return float(t.get(kind, t["ink"]))


## Margem de conteúdo mínima (px) de um painel de papel do `kind` (conta a moldura + GAP_PANEL).
static func paper_clean(kind: String) -> float:
	return paper_depth(kind) + GAP_PANEL


## Profundidade desenhada de uma StyleBox (contorno de uma StyleBoxFlat; moldura do kit numa StyleBoxTexture).
static func border_depth(sb: StyleBox) -> float:
	if sb is StyleBoxTexture:
		var tex: Texture2D = (sb as StyleBoxTexture).texture
		var path: String = tex.resource_path if tex else ""
		var table: Dictionary = DEPTH_MAPA if path.contains("/kit_mapa/") else DEPTH_KIT
		var file := path.get_file().get_basename()
		if file.begins_with("ribbon"):
			return float(table["ribbon"])
		if file.begins_with("panel_") or file.begins_with("button_"):
			return float(table.get(file.trim_prefix("panel_") if file.begins_with("panel_") else file, table["ink"]))
		return 0.0
	if sb is StyleBoxFlat:
		var f := sb as StyleBoxFlat
		return float(maxi(maxi(f.border_width_left, f.border_width_right), maxi(f.border_width_top, f.border_width_bottom)))
	return 0.0


## Sobe as margens de conteúdo de `sb` até o mínimo da moldura (para caixas com margens escritas à mão).
## Devolve a mesma caixa, para encadear. Margens já maiores ficam como estão.
static func fit_margins(sb: StyleBox, is_button := false) -> StyleBox:
	var need := clean_need(sb, is_button)
	sb.content_margin_left = maxf(sb.content_margin_left, need.x)
	sb.content_margin_right = maxf(sb.content_margin_right, need.x)
	sb.content_margin_top = maxf(sb.content_margin_top, need.y)
	sb.content_margin_bottom = maxf(sb.content_margin_bottom, need.y)
	return sb


## Folga mínima entre o texto e a borda da caixa (x = esquerda/direita, y = topo/base). `is_button`: o próprio botão.
static func clean_need(sb: StyleBox, is_button := false) -> Vector2:
	var d := border_depth(sb)
	var ribbon := sb is StyleBoxTexture and (sb as StyleBoxTexture).texture != null \
			and (sb as StyleBoxTexture).texture.resource_path.get_file().begins_with("ribbon")
	if is_button or ribbon:   # a fita é uma faixa fina de texto: mesma folga de botão
		return Vector2(d + GAP_BUTTON_X, d + GAP_BUTTON_Y)
	return Vector2(d + GAP_PANEL, d + GAP_PANEL)


## Fonte dos títulos: Cinzel na pele Covil; nas outras, a da pele ou uma serifada do sistema.
static func title_font() -> Font:
	return UiDiario.font("type")


## Caixa chanfrada: cantos cortados em diagonal (corner_detail 1) em vez de arredondados.
static func box(bg: Color, border: Color, bw := 1, cut := 8, margin := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(cut)
	sb.corner_detail = 1
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	return sb


static func make_theme() -> Theme:
	UiSkins.apply()
	_title_font = null
	var t := Theme.new()
	UiDiario.fill_theme(t)
	return t


static func panel(bg := BG, border := EDGE, margin := 10) -> PanelContainer:
	return UiDiario.panel(bg, border, margin)


static func label(size := 18, col := TEXT, outline := 4) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", outline)
	UiDiario.label(l, size, outline)
	return l


static func title(size: int, col := GOLD) -> Label:
	var l := label(size, col, maxi(4, size / 9))
	UiDiario.title(l, size, col)
	return l


static func bar(col: Color, w: float, h: float) -> ProgressBar:
	return UiDiario.bar(col, w, h)


## Losango com um número (nível, custo). A pele troca a forma (medalha, hexágono, orbe, losango). Na Covil,
## `shape` escolhe a gema: "crystal" (custo, elixir; o padrão), "crest" (herói) ou "sigil" (poder).
static func badge(col: Color, size := 22, w := 40.0, shape := "crystal") -> PanelContainer:
	return UiDiario.badge(col, size, w, shape)


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
	UiDiario.dress(c, "paper", margin + 8, {"grime": 0.35, "seed": 0.6})
	return


## Cor de um título depois de criado (na Covil o degradê de metal segue a cor).
static func title_color(l: Label, col: Color) -> void:
	l.add_theme_color_override("font_color", UiDiario.ink_of(col))
	return


## Estado de uma carta da mão: selecionada (borda dourada) e jogável (brilho verde).
static func card_state(p: Control, selected: bool, playable: bool) -> void:
	UiDiario.card_state(p, selected, playable)
	return


## Painel aceso (Pacto em foco no menu).
static func set_hot(c: Control, on: bool) -> void:
	UiDiario.set_hot(c, on)
	return


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
			var grew: bool = (k == "count" and d.scales("count")) or (d.scales(k) and d.fx.has(k)) or (level >= CardDef.N3_LEVEL and d.n3.has(k))
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
	if level >= CardDef.N3_LEVEL and d.n3.size() > 0:
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
	return UiDiario.mini_card(d, cost, mods, key, w, h, named, level)


## Carta desenhada: arte, custo, atalho, nome, tipo, modificadores e texto. `w` define a escala.
static func card(d: CardDef, cost: int, mods: Array, key := "", w := 168.0, level := 1) -> PanelContainer:
	var dc := UiDiario.card(d, cost, mods, key, w, level)
	dc.set_meta("ui_card", true)   # --bare (capturas para maquete) mantém as cartas e esconde o resto
	return dc


# ---------------------------------------------------------------- utilidades (vieram da pele Covil, 24/11/2026)

static var _markers := {}


## Textura-marcador branca n×n: o shader do papel lê o tamanho dela (TEXTURE_PIXEL_SIZE) para saber o estado.
static func marker(n: int) -> ImageTexture:
	if not _markers.has(n):
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_markers[n] = ImageTexture.create_from_image(img)
	return _markers[n]


## Pixels de tela por unidade de interface (o shader do papel converte as larguras). Chamado a cada quadro pelo main.
static func sync(vp: Viewport) -> void:
	var vs := vp.get_visible_rect().size
	if vs.x <= 0.0:
		return
	var px := float(DisplayServer.window_get_size().x) / vs.x if DisplayServer.get_name() != "headless" else 1.0
	RenderingServer.global_shader_parameter_set("ui_px", px)


## Tamanho de fonte que faz `text` caber em `w` (começa em `size`, não passa de `lo`).
static func fit_size(f: Font, text: String, size: int, w: float, lo: int) -> int:
	var s := size
	while s > lo and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > w:
		s -= 1
	return s
