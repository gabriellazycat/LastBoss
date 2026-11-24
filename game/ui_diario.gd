class_name UiDiario
extends RefCounted
## Peças da interface em papel (base da pele "Mapa aberto", a única desde 24/11/2026; UiParch traz o kit do mapa):
## papel com borda rasgada, fita crepe, nanquim e letra datilografada. As peças saem do shader
## game/ui/paper.gdshader (textura-marcador de UiKit.marker). Cartas: faixa de fita no topo na cor do tipo,
## desenho a nanquim (assets/cards/<id>.png, feitos por tools/art/render_sketches.py), custo numa mancha de sangue
## e o texto numa etiqueta clara. Texto em cima de papel vira tinta escura sozinho (on_node_added).

const F := "res://assets/fonts/"
const PAPER := preload("res://game/ui/paper.gdshader")
const CARDS := "res://assets/cards/"

const INK := Color(0.12, 0.095, 0.075)
const BLOOD := Color(0.42, 0.06, 0.035)
const MASK := Color(0.89, 0.83, 0.63, 0.94)
const PAL := {
	"BG": Color(0.86, 0.81, 0.7, 0.97), "BG_SOFT": Color(0.86, 0.81, 0.7, 0.9), "EDGE": Color(0.3, 0.22, 0.15),
	"GOLD": Color(0.5, 0.09, 0.05), "TEXT": Color(0.12, 0.095, 0.075), "MUTED": Color(0.34, 0.29, 0.24),
	"HERO_HP": Color(0.62, 0.1, 0.07), "HERO_XP": Color(0.62, 0.42, 0.08), "POWER": Color(0.36, 0.21, 0.62),
	"ELIXIR": Color(0.4, 0.23, 0.74), "GOOD": Color(0.14, 0.42, 0.18), "BAD": Color(0.6, 0.09, 0.05),
}
const RARITY := [Color(0.34, 0.32, 0.29), Color(0.18, 0.42, 0.2), Color(0.15, 0.3, 0.58), Color(0.48, 0.2, 0.58)]
## Fita (faixa da carta), tinta do desenho e cor do nome sobre a fita, por tipo.
const TYPES := {
	"monster": [Color(0.66, 0.15, 0.1), Color(0.29, 0.07, 0.04), Color(1.0, 0.96, 0.9)],
	"swarm": [Color(0.8, 0.42, 0.13), Color(0.42, 0.2, 0.03), Color(1.0, 0.97, 0.9)],
	"spell": [Color(0.46, 0.31, 0.78), Color(0.23, 0.15, 0.5), Color(1.0, 0.97, 0.94)],
	"structure": [Color(0.87, 0.7, 0.25), Color(0.23, 0.23, 0.22), Color(0.12, 0.1, 0.07)],
	"route": [Color(0.21, 0.4, 0.67), Color(0.11, 0.23, 0.42), Color(0.98, 0.97, 0.93)],
	"lair": [Color(0.32, 0.44, 0.22), Color(0.17, 0.27, 0.13), Color(0.98, 0.97, 0.9)],
	"finisher": [Color(0.12, 0.105, 0.095), Color(0.1, 0.08, 0.06), Color(0.9, 0.74, 0.36)],
}

static var _fonts := {}
static var _mats := {}
static var _tex := {}
static var _painted := {}
static var _hatch := {}


# ---------------------------------------------------------------- fontes

## "type" Special Elite (datilografada), "hand" Patrick Hand, "marker" Permanent Marker, "fell" IM Fell SC,
## "fell_it" IM Fell itálico. As que não têm → e ★ caem na Alegreya Sans.
static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	# Rodada de UI 13/11/2026: as letras das cartas e do mapa no lugar da datilografada e da caneta (legibilidade).
	# "type" e "hand" viraram Alegreya Sans (negrito / médio); "marker" virou a IM Fell SC dos nomes das cartas.
	if kind == "marker":
		_fonts[kind] = UiParch.font("title")
		return _fonts[kind]
	var file: String = {"type": "AlegreyaSans-Bold.ttf", "hand": "AlegreyaSans-Medium.ttf",
		"fell": "IMFellEnglishSC-Regular.ttf", "fell_it": "IMFellEnglish-Italic.ttf"}.get(kind, "AlegreyaSans-Medium.ttf")
	var fv := FontVariation.new()
	fv.base_font = load(F + file)
	fv.fallbacks = [load(F + "AlegreyaSans-Bold.ttf")]
	if kind == "type":
		fv.spacing_glyph = 0
	_fonts[kind] = fv
	return fv


# ---------------------------------------------------------------- papel

## Material do papel. `kind`: "paper", "tape", "lined", "slot", "card", "patch", "contract".
static func material(kind: String, opts := {}, unique := false) -> ShaderMaterial:
	var key := kind + str(opts)
	if not unique and _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = PAPER
	m.set_shader_parameter("kind", ["paper", "tape", "lined", "slot", "card", "patch", "contract"].find(kind))
	m.set_shader_parameter("grime", float(opts.get("grime", 0.45)))
	m.set_shader_parameter("seed", float(opts.get("seed", 0.0)))
	m.set_shader_parameter("shadow", float(opts.get("shadow", 7.0)))
	m.set_shader_parameter("rough", float(opts.get("rough", 2.0)))
	m.set_shader_parameter("band", float(opts.get("band", 0.0)))
	m.set_shader_parameter("tint", opts.get("tint", MASK))
	m.set_shader_parameter("state_mode", 1.0 if opts.get("button", false) else 0.0)
	if opts.has("paper_a"):
		m.set_shader_parameter("paper_a", opts["paper_a"])
		m.set_shader_parameter("paper_b", opts["paper_b"])
	if not unique:
		_mats[key] = m
	return m


static func box(margin: float, shadow := 7.0, state := 9) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = UiKit.marker(state)
	sb.set_expand_margin_all(shadow)
	sb.set_content_margin_all(margin)
	return sb


## Papel com moldura do kit das cartas (UiParch). `kind`/`opts`/`unique` ficam pela compatibilidade: o papel sujo do
## shader saiu na rodada de UI de 13/11/2026. "contract" e painéis grandes levam a moldura dourada; o resto, o traço fino.
static func dress(c: Control, kind: String, margin := 12.0, opts := {}, unique := false) -> void:
	var gold := kind in ["contract", "paper", "lined"] and margin >= 18.0
	c.add_theme_stylebox_override("panel", UiParch.box("gold" if gold else "ink", margin))
	c.material = null
	c.set_meta("paper", true)


static func seed_of(s: String) -> float:
	return float(absi(hash(s)) % 97) / 97.0


static func panel(bg: Color, _border: Color, margin: int, kind := "paper") -> PanelContainer:
	var p := PanelContainer.new()
	dress(p, kind, margin + 8, {"grime": 0.3 if bg.a < 0.9 else 0.4, "seed": randf()})
	return p


static func on_node_added(n: Node) -> void:
	if n is Label or n is RichTextLabel:
		_inkify.call_deferred(n)


## Texto em cima de papel: cor clara vira tinta (mantém o matiz), sem contorno. Texto solto sobre o mundo fica.
static func _inkify(n) -> void:   # sem tipo: um nó já liberado (telas que se refazem) dava erro ao converter o argumento
	if not is_instance_valid(n) or n.has_meta("no_ink") or not on_paper(n):
		return
	var key := "font_color" if n is Label else "default_color"
	var col: Color = n.get_theme_color(key)
	n.add_theme_color_override(key, ink_of(col))
	n.add_theme_constant_override("outline_size", 0)
	n.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))


static func on_paper(n: Node) -> bool:
	var p := n
	while p != null and p is CanvasItem:
		if p.has_meta("paper") or p.has_meta("tape"):
			return true
		p = p.get_parent()
	return false


## Cor legível sobre papel: claras escurecem mantendo o matiz; neutras viram tinta.
static func ink_of(c: Color) -> Color:
	if c.get_luminance() < 0.42:
		return c
	if c.s < 0.25:
		return INK
	return Color.from_hsv(c.h, minf(c.s * 1.1 + 0.15, 1.0), 0.38, 1.0)


# ---------------------------------------------------------------- tema

static func fill_theme(t: Theme) -> void:
	t.default_font = font("hand")
	t.default_font_size = 22
	# Botões (13/11/2026): papel com traço fino; dourado no mouse; afunda ao apertar (UiParch.button_box).
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(st, "Button", UiParch.button_box(st))
		t.set_stylebox(st, "OptionButton", UiParch.button_box(st, Vector4(16, 11, 16, 12)))
	t.set_stylebox("hover_pressed", "Button", UiParch.button_box("pressed"))
	t.set_font("font", "Button", UiParch.font("title"))
	t.set_font("font", "OptionButton", font("hand"))
	t.set_font_size("font_size", "Button", 21)
	for k in ["font_color", "font_focus_color", "font_pressed_color"]:
		t.set_color(k, "Button", INK)
		t.set_color(k, "OptionButton", INK)
	for k in ["font_hover_color", "font_hover_pressed_color"]:
		t.set_color(k, "Button", UiParch.BLOOD)
		t.set_color(k, "OptionButton", UiParch.BLOOD)
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.37, 0.33))
	t.set_constant("outline_size", "Button", 0)
	t.set_color("font_color", "Label", INK)
	t.set_constant("outline_size", "Label", 0)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_constant("outline_size", "RichTextLabel", 0)
	t.set_font("normal_font", "RichTextLabel", font("hand"))
	t.set_font("bold_font", "RichTextLabel", font("type"))
	var flat := func(bg: Color, border: Color, bw: int, m: int) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.set_border_width_all(bw)
		s.set_corner_radius_all(2)
		s.set_content_margin_all(m)
		s.anti_aliasing = true
		return s
	t.set_stylebox("panel", "PopupMenu", UiParch.box("ink", 8.0))
	t.set_stylebox("hover", "PopupMenu", flat.call(Color(0.89, 0.8, 0.55), INK, 0, 4))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", BLOOD)
	t.set_font("font", "PopupMenu", font("type"))
	var tip := UiParch.box("ink", 10.0)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_font("font", "TooltipLabel", font("hand"))
	t.set_color("font_color", "TooltipLabel", INK)
	var track: StyleBoxFlat = flat.call(INK, INK, 0, 0)
	track.content_margin_top = 1
	track.content_margin_bottom = 1
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", track)
	t.set_stylebox("grabber_area_highlight", "HSlider", track)
	t.set_icon("grabber", "HSlider", _gem_icon(22, UiParch.BLOOD))
	t.set_icon("grabber_highlight", "HSlider", _gem_icon(24, UiParch.BLOOD.lightened(0.15)))
	t.set_icon("checked", "CheckBox", _check_icon(true))
	t.set_icon("unchecked", "CheckBox", _check_icon(false))
	t.set_icon("checked", "CheckButton", _check_icon(true))
	t.set_icon("unchecked", "CheckButton", _check_icon(false))
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_color", "CheckButton", INK)
	t.set_stylebox("scroll", "VScrollBar", flat.call(Color(0, 0, 0, 0.08), Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("grabber", "VScrollBar", flat.call(Color(0.25, 0.2, 0.15, 0.6), Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("grabber_highlight", "VScrollBar", flat.call(Color(0.25, 0.2, 0.15, 0.8), Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("grabber_pressed", "VScrollBar", flat.call(BLOOD, Color(0, 0, 0, 0), 0, 3))
	t.set_stylebox("separator", "HSeparator", flat.call(Color(0.12, 0.1, 0.08, 0.5), Color(0, 0, 0, 0), 0, 0))


## Pegador de slider: losango vermelho com aro dourado (o losango do filete das cartas).
static func _gem_icon(n: int, col: Color) -> ImageTexture:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in n:
		for x in n:
			var d := absf(x - c) + absf(y - c)
			if d <= c:
				var rim := clampf((d - (c - 3.0)) / 1.5, 0.0, 1.0)
				var a := clampf(c - d + 0.5, 0.0, 1.0)
				var body := col.lightened(0.25 * (1.0 - (x + y) / (2.0 * n)))
				var px := body.lerp(UiParch.GOLD, rim)
				img.set_pixel(x, y, Color(px.r, px.g, px.b, a))
	return ImageTexture.create_from_image(img)


## Caixinha desenhada a lápis, com um X de caneta quando marcada.
static func _check_icon(on: bool) -> ImageTexture:
	var n := 24
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var edge := mini(mini(x - 2, y - 2), mini(n - 3 - x, n - 3 - y))
			if edge >= 0 and edge < 2:
				img.set_pixel(x, y, INK)
			if on:
				var dx := absi((x - 4) - (y - 4))
				var dy := absi((x - 4) - (n - 5 - y))
				if x >= 4 and x <= n - 5 and y >= 4 and y <= n - 5 and (dx <= 1 or dy <= 1):
					img.set_pixel(x, y, Color(BLOOD.r * 1.3, BLOOD.g, BLOOD.b))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- texto

static func label(l: Label, size: int, _outline: int) -> void:
	l.add_theme_font_override("font", font("hand"))
	l.add_theme_font_size_override("font_size", roundi(size * 1.06))
	l.add_theme_constant_override("outline_size", 0)


static func title(l: Label, size: int, col: Color) -> void:
	l.add_theme_font_override("font", UiParch.font("title") if size >= 24 else font("type"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", ink_of(col) if col.get_luminance() > 0.42 else col)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))


## Título solto sobre o mundo (sem papel embaixo): fita vermelha atrás do texto.
static func tape_title(l: Label, tint := TYPES["monster"][0]) -> PanelContainer:
	# Desde 13/11/2026: a fita dobrada vermelha do nome das cartas, com o título em Fell SC creme.
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiParch.ribbon_box("monster", false, Vector4(56, 12, 56, 12)))
	p.set_meta("tape", true)
	l.set_meta("no_ink", true)
	l.add_theme_font_override("font", UiParch.font("title"))
	l.add_theme_color_override("font_color", UiParch.CREAM)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Rótulo numa tira de fita crepe (texto a tinta): legendas sobre o mundo, cabeçalhos das ofertas.
static func tape_wrap(c: Control, tint := MASK, rot := -1.5) -> PanelContainer:
	# Desde 13/11/2026: etiqueta de papel com traço fino (sem fita crepe torta).
	var p := PanelContainer.new()
	var sb := UiParch.box("ink", 0.0)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 4
	sb.content_margin_bottom = 5
	UiKit.fit_margins(sb, true)
	p.set_meta("tag", true)   # etiqueta de uma linha: folga de botão (UiKit.clean_need), não de painel
	p.add_theme_stylebox_override("panel", sb)
	p.set_meta("paper", true)
	p.add_child(c)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Bilhete: etiqueta de papel claro em volta de um texto (efeito de melhoria, preço).
static func note_wrap(c: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UiParch.box("ink", 0.0)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	UiKit.fit_margins(sb, true)
	p.set_meta("tag", true)
	p.add_theme_stylebox_override("panel", sb)
	p.set_meta("paper", true)
	p.add_child(c)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


# ---------------------------------------------------------------- barras e selos

## Barra a lápis: contorno tremido e enchimento hachurado na cor.
static func bar(col: Color, w: float, h: float) -> ProgressBar:
	# Desde 13/11/2026: trilho escuro com aro dourado (UiParch.bar), no lugar do lápis hachurado.
	return UiParch.bar(col, w, h)


## Selo com número: "crystal" = mancha de sangue (custo, elixir), "crest" = escudo a nanquim, "sigil" = estrela.
static func badge(col: Color, size: int, w: float, shape: String) -> PanelContainer:
	var g := PanelContainer.new()
	g.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	g.custom_minimum_size = Vector2(w, w)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sd := randf() * 10.0
	# Elixir (13/11/2026): a mesma gema roxa do custo das cartas, com o número em Fell creme e contorno roxo.
	var gem := shape == "crystal" and col.b > col.r
	if gem:
		# Desenhada pelo próprio painel (o número continua filho "N" direto, como os outros chamam).
		var gtex := UiParch.tex("gem_common_purple")
		var gsb := StyleBoxEmpty.new()
		gsb.content_margin_top = roundf(w * 0.3)
		g.add_theme_stylebox_override("panel", gsb)
		g.custom_minimum_size = Vector2(w * 0.92, w * 1.05)
		g.draw.connect(func(): g.draw_texture_rect(gtex, Rect2(Vector2.ZERO, g.size), false))
	else:
		g.draw.connect(func(): draw_badge(g, Rect2(Vector2.ZERO, g.size), col, shape, sd))
	var l := Label.new()
	l.name = "N"
	l.set_meta("no_ink", true)
	l.add_theme_font_override("font", font("fell") if gem else font("type"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88) if shape != "crest" else INK)
	l.add_theme_constant_override("outline_size", 5 if gem else 0)
	l.add_theme_color_override("font_outline_color", Color(0.14, 0.03, 0.24))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(l)
	return g


static func blob(c: Vector2, r: float, sd: float, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var k := 1.0 + 0.09 * sin(a * 3.0 + sd) + 0.05 * sin(a * 7.0 + sd * 2.3) + 0.03 * sin(a * 11.0 + sd * 0.7)
		pts.append(c + Vector2(cos(a), sin(a)) * r * k)
	return pts


static func draw_badge(ci: CanvasItem, r: Rect2, col: Color, shape: String, sd := 0.0) -> void:
	var c := r.get_center()
	var s := minf(r.size.x, r.size.y) * 0.5
	match shape:
		"crest":
			var pts := PackedVector2Array([c + Vector2(-s * 0.82, -s * 0.84), c + Vector2(s * 0.82, -s * 0.84), c + Vector2(s * 0.8, s * 0.1),
				c + Vector2(0, s * 0.96), c + Vector2(-s * 0.8, s * 0.1)])
			ci.draw_colored_polygon(pts, UiParch.PARCH)
			var loop := pts.duplicate()
			loop.append(pts[0])
			ci.draw_polyline(loop, UiParch.GOLD, maxf(2.5, s * 0.16), true)
			ci.draw_polyline(loop, INK, maxf(1.0, s * 0.05), true)
			ci.draw_line(c + Vector2(-s * 0.5, -s * 0.5), c + Vector2(s * 0.5, -s * 0.5), Color(INK.r, INK.g, INK.b, 0.4), 1.0, true)
		"sigil":
			ci.draw_colored_polygon(blob(c, s * 0.95, sd), Color(0.1, 0.08, 0.06))
			var star := PackedVector2Array()
			for i in 10:
				var a := TAU * i / 10.0 - PI * 0.5
				star.append(c + Vector2(cos(a), sin(a)) * s * (0.7 if i % 2 == 0 else 0.32))
			ci.draw_colored_polygon(star, col.lightened(0.25))
		_:
			ci.draw_colored_polygon(blob(c, s * 1.04, sd), Color(1.0, 0.95, 0.85, 0.7))
			ci.draw_colored_polygon(blob(c, s * 0.92, sd + 1.0), Color(0.36, 0.05, 0.03) if col.r >= col.b * 0.5 else col.darkened(0.45))
			ci.draw_circle(c + Vector2(-s * 0.3, -s * 0.32), s * 0.14, Color(1, 1, 1, 0.16))


## Gota de tinta do Elixir: contorno, enchida de baixo para cima conforme `f`.
static func draw_pip(ci: CanvasItem, r: Rect2, f: float, col: Color, _t: float) -> void:
	# Desde 13/11/2026: a gota da gema de custo das cartas (roxa com aro dourado).
	UiParch.draw_drop(ci, r, f, col)


# ---------------------------------------------------------------- cartas

static func card_tex(id: String) -> Texture2D:
	if not _tex.has(id):
		var path := CARDS + id + ".png"
		if not ResourceLoader.exists(path):
			path = CARDS + CardModel.art_of(id) + ".png"
		_tex[id] = load(path) if ResourceLoader.exists(path) else null
	return _tex[id]


## Cartas com a arte pintada nova (aquarela + nanquim): a lista fica em data/card_art.json,
## atualizada a cada vilão concluído. Essas usam assets/cards/<id>.png também na mão das outras peles, no lugar
## do retrato 3D (decisão do designer, 11/11/2026).
static func painted(id: String) -> bool:
	if _painted.is_empty():
		_painted["_"] = true
		var path := "res://data/card_art.json"
		if FileAccess.file_exists(path):
			var j = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(j) == TYPE_DICTIONARY:
				for cid in j.get("painted", []):
					_painted[str(cid)] = true
	return _painted.has(id) and id != "_"


## Arte da carta para a mão, o HUD e a coleção: a pintada, quando existe; senão, o retrato 3D.
static func hand_art(id: String) -> Texture2D:
	if painted(id):
		var t := card_tex(id)
		if t != null:
			return t
	return CardArt.textures.get(id)


static func type_spec(d: CardDef) -> Array:
	return TYPES.get(d.type, TYPES["monster"])


## Carta grande no molde único (game/card_mold.gd): moldura A com a fita dobrada do nome, arte, tipo e texto.
static func card(d: CardDef, cost: int, mods: Array, key: String, w: float, level: int) -> PanelContainer:
	return CardMold.build(d, cost, UiKit.mod_ids_of(mods), key, w, roundf(w * 1.4), false, level)


## Carta compacta (mão em leque, esteira) no molde único: fita com o nome, custo e a arte.
static func mini_card(d: CardDef, cost: int, mods: Array, key: String, w: float, h: float, _named: bool, level: int) -> PanelContainer:
	return CardMold.build(d, cost, UiKit.mod_ids_of(mods), key, w, h, true, level)


## Atalho do teclado: número datilografado num círculo a nanquim.
static func _key_tag(key: String, k: float) -> Control:
	var s := roundf(17.0 * k)
	var c := Control.new()
	c.size = Vector2(s, s)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var o := c.size * 0.5
		c.draw_circle(o, s * 0.5, Color(0.92, 0.88, 0.78))
		c.draw_arc(o, s * 0.5 - 0.6, 0, TAU, 20, INK, 1.2, true))
	var l := Label.new()
	l.text = key
	l.set_meta("no_ink", true)
	l.add_theme_font_override("font", font("type"))
	l.add_theme_font_size_override("font_size", int(12.0 * k))
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(l)
	return c


## Estado da carta da mão: selecionada acende a borda.
static func card_state(p: Control, selected: bool, playable: bool) -> void:
	if p.has_meta("mold"):
		CardMold.set_hot(p, selected)
		return
	var m := p.material as ShaderMaterial
	if m == null:
		return
	var s := 2 if selected else (1 if playable else 0)
	if p.get_meta("st", -1) == s:
		return
	p.set_meta("st", s)
	m.set_shader_parameter("hot", 1.0 if selected else 0.0)


static func set_hot(c: Control, on: bool) -> void:
	# Painel em foco (contrato do vilão, cartaz do herói): sobe um pouco e clareia.
	c.self_modulate = Color(1.06, 1.03, 0.96) if on else Color.WHITE
	var m := c.material as ShaderMaterial
	if m:
		m.set_shader_parameter("hot", 1.0 if on else 0.0)


# ---------------------------------------------------------------- menu e ícones

static func icon_button(b: Button, kind: String) -> void:
	b.text = ""
	b.draw.connect(_draw_icon.bind(b, kind))


static func _draw_icon(b: Button, kind: String) -> void:
	var c := b.size * 0.5
	var col := BLOOD if (b.is_hovered() or b.has_focus()) else INK
	if kind == "pause":
		for dx in [-5.0, 5.0]:
			b.draw_rect(Rect2(c + Vector2(dx - 2.5, -9.0), Vector2(5, 18)), col)
		return
	var pts := PackedVector2Array([c + Vector2(-12, -8), c + Vector2(-4, -11), c + Vector2(4, -8), c + Vector2(12, -11),
		c + Vector2(12, 8), c + Vector2(4, 11), c + Vector2(-4, 8), c + Vector2(-12, 11), c + Vector2(-12, -8)])
	b.draw_polyline(pts, col, 2.0, true)
	b.draw_line(c + Vector2(-4, -11), c + Vector2(-4, 8), col, 1.5, true)
	b.draw_line(c + Vector2(4, -8), c + Vector2(4, 11), col, 1.5, true)


## Fundo de um Control que se desenha sozinho (faixa de rota, mapa grande): papel.
static func draw_plate(c: Control, kind := "paper", grow := Vector2.ZERO) -> void:
	c.set_meta("paper", true)
	c.draw_style_box(UiParch.box("gold", 0.0), Rect2(-grow, c.size + grow * 2.0))
