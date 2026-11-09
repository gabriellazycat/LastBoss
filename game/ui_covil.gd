class_name UiCovil
extends RefCounted
## Pele "Covil" da interface, o padrão desde 08/11/2026 (Settings "look_hud" 0; guia em docs/REVISAO_VISUAL.md).
## Ferro escuro com aro de bronze, gemas facetadas, Cinzel nos títulos e Alegreya Sans no texto.
## As molduras saem do shader game/ui/frame.gdshader: a StyleBoxTexture leva uma textura-marcador (9x9..13x13 px)
## e o Control leva o material. Nos botões o tamanho do marcador diz o estado (o shader lê TEXTURE_PIXEL_SIZE).

const F := "res://assets/fonts/"
const FRAME := preload("res://game/ui/frame.gdshader")
const TITLE := preload("res://game/ui/title.gdshader")

const IRON_TOP := Color(0.125, 0.105, 0.13)
const IRON_BOT := Color(0.052, 0.042, 0.058)
const BRONZE := Color(0.8, 0.62, 0.38)
const PAL := {
	"BG": Color(0.075, 0.06, 0.08, 0.95), "BG_SOFT": Color(0.06, 0.05, 0.065, 0.84), "EDGE": Color(0.6, 0.47, 0.32),
	"GOLD": Color(1.0, 0.82, 0.5), "TEXT": Color(0.96, 0.93, 0.87), "MUTED": Color(0.72, 0.67, 0.62),
	"HERO_HP": Color(0.86, 0.19, 0.16), "HERO_XP": Color(1.0, 0.72, 0.3), "POWER": Color(0.72, 0.46, 1.0),
	"ELIXIR": Color(0.78, 0.42, 1.0), "GOOD": Color(0.52, 0.93, 0.58), "BAD": Color(1.0, 0.42, 0.36),
}
## Comum (ferro), incomum (verdete), rara (aço azul), épica (ametista).
const RARITY := [Color(0.7, 0.7, 0.74), Color(0.46, 0.84, 0.54), Color(0.44, 0.68, 1.0), Color(0.82, 0.52, 1.0)]

## Parâmetros do shader por tipo de peça (larguras em unidades de interface, multiplicadas pela escala da peça).
const KINDS := {
	"plate": {"trim_w": 3.0, "cut": 10.0, "shadow": 10.0, "studs": 1.0, "noise_amt": 0.05, "glow_w": 18.0},
	"soft": {"trim_w": 2.0, "cut": 7.0, "shadow": 7.0, "studs": 0.0, "noise_amt": 0.04, "glow_w": 14.0},
	"card": {"trim_w": 3.5, "cut": 9.0, "shadow": 9.0, "studs": 1.0, "noise_amt": 0.06, "glow_w": 20.0},
	"inset": {"trim_w": 1.5, "cut": 5.0, "shadow": 0.0, "studs": 0.0, "noise_amt": 0.0, "inset": 1.0},
	"plaque": {"trim_w": 2.0, "cut": 6.0, "shadow": 4.0, "studs": 0.0, "noise_amt": 0.05, "glow_w": 10.0},
	"button": {"trim_w": 2.0, "cut": 8.0, "shadow": 6.0, "studs": 0.0, "noise_amt": 0.05, "glow_w": 16.0, "state_mode": 1.0},
	"slot": {"trim_w": 1.5, "cut": 3.0, "shadow": 0.0, "studs": 0.0, "noise_amt": 0.0},
}
const SCALED := ["trim_w", "cut", "shadow", "glow_w"]

static var _fonts := {}
static var _markers := {}
static var _mats := {}
static var _title_mats := {}
static var _fills := {}
static var _pip_sb: StyleBoxFlat


# ---------------------------------------------------------------- fontes

## "title" Cinzel 700, "title_black" Cinzel 900, "body" Alegreya Sans Medium, "bold" Bold, "heavy" ExtraBold.
static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var f: Font
	match kind:
		"title", "title_black", "title_wide":
			var fv := FontVariation.new()
			fv.base_font = load(F + "Cinzel-VF.ttf")
			var ts := TextServerManager.get_primary_interface()
			fv.variation_opentype = {ts.name_to_tag("wght"): 900 if kind == "title_black" else 700}
			fv.spacing_glyph = 4 if kind == "title_wide" else 1
			f = fv
		"body", "bold", "heavy", "caps":
			# A Alegreya Sans usa algarismos antigos (de altura irregular): números de vida e custo "pulavam".
			var fa := FontVariation.new()
			fa.base_font = load(F + {"body": "AlegreyaSans-Medium.ttf", "bold": "AlegreyaSans-Bold.ttf", "heavy": "AlegreyaSans-ExtraBold.ttf", "caps": "AlegreyaSans-Bold.ttf"}[kind])
			var tsv := TextServerManager.get_primary_interface()
			fa.opentype_features = {tsv.name_to_tag("lnum"): 1}
			if kind == "caps":
				fa.spacing_glyph = 2
			f = fa
	_fonts[kind] = f
	return f


# ---------------------------------------------------------------- molduras

static func marker(n: int) -> ImageTexture:
	if not _markers.has(n):
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_markers[n] = ImageTexture.create_from_image(img)
	return _markers[n]


## Material do shader de moldura. `unique` para peças que mudam de estado sozinhas (cartas da mão).
static func material(kind: String, trim: Color, top := IRON_TOP, bot := IRON_BOT, glow := Color(0, 0, 0, 0), k := 1.0, unique := false) -> ShaderMaterial:
	var key := "%s/%s/%s/%s/%s/%.2f" % [kind, trim.to_html(), top.to_html(), bot.to_html(), glow.to_html(), k]
	if not unique and _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = FRAME
	var spec: Dictionary = KINDS[kind]
	for p in spec:
		m.set_shader_parameter(p, float(spec[p]) * (k if p in SCALED else 1.0))
	m.set_shader_parameter("trim", trim)
	m.set_shader_parameter("bg_top", top)
	m.set_shader_parameter("bg_bot", bot)
	m.set_shader_parameter("glow", glow)
	if not unique:
		_mats[key] = m
	return m


## StyleBox da moldura: textura-marcador, margem de expansão = sombra, margem de conteúdo dada.
static func box(kind: String, margin: float, k := 1.0, state := 9) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = marker(state)
	sb.set_expand_margin_all(float(KINDS[kind].get("shadow", 0.0)) * k)
	sb.set_content_margin_all(margin)
	return sb


## Veste um Control (PanelContainer, Panel) com a moldura.
static func dress(c: Control, kind: String, trim: Color, top := IRON_TOP, bot := IRON_BOT, glow := Color(0, 0, 0, 0), margin := 10.0, k := 1.0, unique := false) -> void:
	c.add_theme_stylebox_override("panel", box(kind, margin, k))
	c.material = material(kind, trim, top, bot, glow, k, unique)


## Fundo de uma cor qualquer puxado para o ferro da pele (os chamadores antigos passam roxos e marrons).
static func iron(bg: Color) -> Array:
	var b := Color(bg.r, bg.g, bg.b).lerp(Color(IRON_TOP.r, IRON_TOP.g, IRON_TOP.b), 0.6)
	var a := clampf(bg.a + 0.06, 0.78, 0.97)
	return [Color(b.r * 1.15, b.g * 1.15, b.b * 1.15, a), Color(b.r * 0.42, b.g * 0.42, b.b * 0.45, a)]


## Cor do aro: bronze tingido pela cor de significado do chamador (vermelho no herói, roxo no poder...).
static func trim_for(border: Color) -> Color:
	return BRONZE.lerp(Color(border.r, border.g, border.b).lightened(0.15), 0.42)


static func panel(bg: Color, border: Color, margin: int, kind := "plate") -> PanelContainer:
	var p := PanelContainer.new()
	var c := iron(bg)
	dress(p, kind, trim_for(border), c[0], c[1], Color(0, 0, 0, 0), margin + 4)
	return p


## Botões: a pele vale para todos pelo tema; o material entra quando o botão nasce (main conecta node_added).
static func button_material() -> ShaderMaterial:
	return material("button", BRONZE, Color(0.15, 0.12, 0.14, 0.97), Color(0.07, 0.055, 0.07, 0.97))


static func on_node_added(n: Node) -> void:
	if n is Button and n.material == null and not n.has_meta("no_frame"):
		(n as Button).material = button_material()


## Pixels de tela por unidade de interface (o shader converte as larguras). Chamado a cada quadro pelo main.
static func sync(vp: Viewport) -> void:
	var vs := vp.get_visible_rect().size
	if vs.x <= 0.0:
		return
	var px := float(DisplayServer.window_get_size().x) / vs.x if DisplayServer.get_name() != "headless" else 1.0
	RenderingServer.global_shader_parameter_set("ui_px", px)


# ---------------------------------------------------------------- tema

static func fill_theme(t: Theme) -> void:
	t.default_font = font("body")
	t.default_font_size = 20
	var states := {"normal": 9, "hover": 10, "pressed": 11, "disabled": 12, "focus": 13}
	for st in states:
		var sb := box("button", 10.0, 1.0, states[st])
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		t.set_stylebox(st, "Button", sb)
		var ob := box("button", 8.0, 1.0, states[st])
		ob.content_margin_left = 14
		t.set_stylebox(st, "OptionButton", ob)
	t.set_font("font", "Button", font("bold"))
	t.set_font("font", "OptionButton", font("bold"))
	var txt: Color = PAL["TEXT"]
	t.set_color("font_color", "Button", Color(0.9, 0.86, 0.8))
	t.set_color("font_hover_color", "Button", Color(1.0, 0.92, 0.72))
	t.set_color("font_focus_color", "Button", Color(1.0, 0.92, 0.72))
	t.set_color("font_pressed_color", "Button", Color(1.0, 0.95, 0.8))
	t.set_color("font_hover_pressed_color", "Button", Color(1.0, 0.95, 0.8))
	t.set_color("font_disabled_color", "Button", Color(0.62, 0.56, 0.5))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.85))
	t.set_constant("outline_size", "Button", 2)
	t.set_color("font_color", "OptionButton", txt)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.9))
	t.set_constant("outline_size", "Label", 2)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 2)
	t.set_constant("shadow_outline_size", "Label", 3)
	t.set_color("font_color", "Label", txt)
	t.set_color("default_color", "RichTextLabel", txt)
	t.set_color("font_outline_color", "RichTextLabel", Color(0, 0, 0, 0.85))
	t.set_constant("outline_size", "RichTextLabel", 2)
	t.set_font("normal_font", "RichTextLabel", font("body"))
	t.set_font("bold_font", "RichTextLabel", font("bold"))
	# Peças desenhadas pela Godot fora do nosso material (janelas, trilhas): caixas simples na paleta.
	var flat := func(bg: Color, border: Color, bw: int, r: int, m: int) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.set_border_width_all(bw)
		s.set_corner_radius_all(r)
		s.corner_detail = 3
		s.set_content_margin_all(m)
		s.anti_aliasing = true
		return s
	t.set_stylebox("panel", "PopupMenu", flat.call(Color(0.08, 0.065, 0.085, 0.98), BRONZE.darkened(0.25), 2, 4, 6))
	t.set_stylebox("hover", "PopupMenu", flat.call(Color(0.3, 0.22, 0.12, 0.9), BRONZE, 0, 3, 4))
	t.set_color("font_color", "PopupMenu", txt)
	t.set_color("font_hover_color", "PopupMenu", Color(1.0, 0.92, 0.72))
	t.set_font("font", "PopupMenu", font("body"))
	t.set_stylebox("panel", "TooltipPanel", flat.call(Color(0.08, 0.065, 0.085, 0.97), BRONZE.darkened(0.2), 1, 3, 8))
	var track: StyleBoxFlat = flat.call(Color(0.02, 0.015, 0.025, 0.85), BRONZE.darkened(0.45), 1, 3, 0)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	var fl: StyleBoxFlat = flat.call(PAL["POWER"].darkened(0.2), PAL["POWER"].lightened(0.2), 0, 3, 0)
	fl.content_margin_top = 4
	fl.content_margin_bottom = 4
	t.set_stylebox("grabber_area", "HSlider", fl)
	t.set_stylebox("grabber_area_highlight", "HSlider", fl)
	t.set_icon("arrow", "OptionButton", _chevron())
	t.set_icon("grabber", "HSlider", _grabber(false))
	t.set_icon("grabber_highlight", "HSlider", _grabber(true))
	t.set_stylebox("scroll", "VScrollBar", flat.call(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, 3, 3))
	t.set_stylebox("grabber", "VScrollBar", flat.call(BRONZE.darkened(0.35), Color(0, 0, 0, 0), 0, 3, 3))
	t.set_stylebox("grabber_highlight", "VScrollBar", flat.call(BRONZE.darkened(0.1), Color(0, 0, 0, 0), 0, 3, 3))
	t.set_stylebox("grabber_pressed", "VScrollBar", flat.call(BRONZE, Color(0, 0, 0, 0), 0, 3, 3))
	t.set_stylebox("separator", "HSeparator", flat.call(BRONZE.darkened(0.5), Color(0, 0, 0, 0), 0, 0, 0))


## Seta das listas suspensas: divisa de bronze.
static func _chevron() -> ImageTexture:
	var w := 16
	var img := Image.create(w, w, false, Image.FORMAT_RGBA8)
	for y in w:
		for x in w:
			var d := absf((y - 5.0) - (7.5 - absf(x - 7.5)) * 0.8)
			if y >= 3 and y <= 12 and absf(x - 7.5) <= 6.5 and d < 1.6:
				img.set_pixel(x, y, Color(BRONZE.r * 1.15, BRONZE.g * 1.15, BRONZE.b * 1.1, clampf(1.6 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## Pegador do slider: losango de bronze com brilho.
static func _grabber(hot: bool) -> ImageTexture:
	var n := 22
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	var base := BRONZE.lightened(0.25 if hot else 0.0)
	for y in n:
		for x in n:
			var d := absf(x - c) + absf(y - c)
			if d <= c:
				var lit := 1.0 + ((c - x) + (c - y)) / (2.0 * c) * 0.35
				img.set_pixel(x, y, Color(0.03, 0.02, 0.02) if d > c - 1.6 else Color(base.r * lit, base.g * lit, base.b * lit))
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- texto

static func title(l: Label, size: int, col: Color) -> void:
	l.add_theme_font_override("font", font("title_black" if size >= 40 else "title"))
	l.add_theme_constant_override("outline_size", maxi(2, size / 18))
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.01, 0.9))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	l.add_theme_constant_override("shadow_offset_y", maxi(2, size / 16))
	l.add_theme_constant_override("shadow_outline_size", maxi(3, size / 10))
	if size >= 26:
		l.add_theme_color_override("font_color", Color.WHITE)
		l.material = title_material(size, col)


static func title_material(size: int, col: Color) -> ShaderMaterial:
	var key := "%d/%s" % [size, col.to_html()]
	if not _title_mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = TITLE
		m.set_shader_parameter("top_col", col.lerp(Color(1.0, 0.96, 0.84), 0.4 if col.s < 0.6 else 0.12))
		m.set_shader_parameter("bot_col", col.darkened(0.32))
		# Cinzel: maiúsculas de ~0,3 a ~1,05 do tamanho da fonte a partir do topo do Label.
		m.set_shader_parameter("y0", size * 0.32)
		m.set_shader_parameter("y1", size * 1.08)
		_title_mats[key] = m
	return _title_mats[key]


## A Alegreya Sans tem olho pequeno: o mesmo tamanho nominal lê menor que a fonte antiga.
const TEXT_SCALE := 1.15


static func label(l: Label, size: int, outline: int) -> void:
	l.add_theme_font_size_override("font_size", roundi(size * TEXT_SCALE))
	l.add_theme_constant_override("outline_size", mini(outline, 3))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	if size >= 22:
		l.add_theme_font_override("font", font("bold"))


## Tamanho de fonte que faz `text` caber em `w` (começa em `size`, não passa de `lo`).
static func fit_size(f: Font, text: String, size: int, w: float, lo: int) -> int:
	var s := size
	while s > lo and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > w:
		s -= 1
	return s


# ---------------------------------------------------------------- barras

static func bar(col: Color, w: float, h: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.material = material("slot", BRONZE.darkened(0.3 if h >= 10 else 0.5), Color(0.02, 0.015, 0.025, 0.9), Color(0.035, 0.025, 0.035, 0.9))
	b.add_theme_stylebox_override("background", box("slot", 0))
	var inset := 2.5 if h >= 10 else 1.5
	var fs := StyleBoxTexture.new()
	fs.texture = _fill_tex(col)
	fs.set_expand_margin_all(-inset)
	fs.set_content_margin_all(0)
	b.add_theme_stylebox_override("fill", fs)
	return b


## Líquido da barra: brilho no alto, cor cheia no meio, fundo escuro; 32 px de largura para o shader ignorar.
static func _fill_tex(col: Color) -> ImageTexture:
	var key := col.to_html()
	if not _fills.has(key):
		var h := 32
		var img := Image.create(32, h, false, Image.FORMAT_RGBA8)
		for y in h:
			var t := float(y) / (h - 1)
			var c := col.lightened(0.4).lerp(col, smoothstep(0.0, 0.42, t)).lerp(col.darkened(0.42), smoothstep(0.55, 1.0, t))
			if y >= 2 and y <= 4:
				c = c.lightened(0.28)
			for x in 32:
				img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
		_fills[key] = ImageTexture.create_from_image(img)
	return _fills[key]


# ---------------------------------------------------------------- gemas, selos, gomos

## Selo com número: "crystal" (custo, elixir), "crest" (escudo do herói), "sigil" (poder do Lorde).
static func badge(col: Color, size: int, w: float, shape: String) -> PanelContainer:
	var g := PanelContainer.new()
	g.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	g.custom_minimum_size = Vector2(w, w)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.draw.connect(func(): draw_badge(g, Rect2(Vector2.ZERO, g.size), col, shape))
	var l := Label.new()
	l.name = "N"
	l.add_theme_font_override("font", font("title_black"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.06))
	l.add_theme_constant_override("outline_size", maxi(3, size / 5))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.add_child(l)
	return g


static func draw_badge(ci: CanvasItem, r: Rect2, col: Color, shape: String) -> void:
	var c := r.get_center()
	var s := minf(r.size.x, r.size.y) * 0.5
	var pts := PackedVector2Array()
	match shape:
		"crest":
			c.y -= s * 0.04
			pts = PackedVector2Array([c + Vector2(-s * 0.88, -s * 0.86), c + Vector2(0, -s * 0.98), c + Vector2(s * 0.88, -s * 0.86),
				c + Vector2(s * 0.84, s * 0.12), c + Vector2(0, s * 1.0), c + Vector2(-s * 0.84, s * 0.12)])
		"sigil":
			# Selo redondo de bronze com uma estrela violeta: o poder não pode parecer o cristal do custo.
			ci.draw_circle(c, s * 1.02, Color(0.03, 0.02, 0.03, 0.95))
			ci.draw_circle(c, s * 0.95, BRONZE.darkened(0.2))
			ci.draw_circle(c, s * 0.8, col.darkened(0.6))
			var star := PackedVector2Array()
			for i in 10:
				var a := TAU * i / 10.0 - PI * 0.5
				star.append(c + Vector2(cos(a), sin(a)) * s * (0.78 if i % 2 == 0 else 0.42))
			facet(ci, star, c, col)
			ci.draw_arc(c, s * 0.95, 0, TAU, 32, BRONZE.lightened(0.25), 1.2, true)
			return
		_:
			for i in 6:
				var a := TAU * i / 6.0 - PI * 0.5
				pts.append(c + Vector2(cos(a), sin(a)) * s * 0.98)
	facet(ci, pts, c, col)


## Polígono facetado: contorno escuro, aro de bronze, facetas iluminadas do alto à esquerda, mesa clara e brilho.
static func facet(ci: CanvasItem, pts: PackedVector2Array, c: Vector2, col: Color) -> void:
	ci.draw_colored_polygon(_scaled(pts, c, 1.12), Color(0.03, 0.02, 0.03, 0.95))
	ci.draw_colored_polygon(_scaled(pts, c, 1.05), BRONZE.darkened(0.15))
	var L := Vector2(-0.5, -0.866)
	var n := pts.size()
	var core := c + Vector2(-1.0, -1.5)
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var mid := ((a + b) * 0.5 - c).normalized()
		var lit := mid.dot(L) * 0.5 + 0.5
		var fc := col.darkened(0.55).lerp(col.lightened(0.3), lit)
		ci.draw_colored_polygon(PackedVector2Array([core, a, b]), fc)
	var table := _scaled(pts, core, 0.5)
	ci.draw_colored_polygon(table, col.lerp(Color.WHITE, 0.12))
	var top := pts[0]
	ci.draw_colored_polygon(PackedVector2Array([top.lerp(c, 0.18), pts[n - 1].lerp(c, 0.22), c.lerp(pts[n - 1], 0.25)]), Color(1, 1, 1, 0.35))
	var loop := _scaled(pts, c, 1.05)
	loop.append(loop[0])
	ci.draw_polyline(loop, BRONZE.lightened(0.25), 1.2, true)


static func _scaled(pts: PackedVector2Array, c: Vector2, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + (p - c) * k)
	return out


## Gomo de elixir: frasco de vidro escuro com o líquido; cheio, ele brilha.
static func draw_pip(ci: CanvasItem, r: Rect2, f: float, col: Color, t: float) -> void:
	if _pip_sb == null:
		_pip_sb = StyleBoxFlat.new()
		_pip_sb.anti_aliasing = true
		_pip_sb.corner_detail = 6
	var sb := _pip_sb
	var rad := int(minf(r.size.y * 0.5, 9.0))
	sb.set_corner_radius_all(rad + 1)
	sb.shadow_size = 0
	sb.set_border_width_all(1)
	sb.border_color = Color(0, 0, 0, 0.9)
	sb.bg_color = Color(0.05, 0.035, 0.06, 0.92)
	ci.draw_style_box(sb, r.grow(1.0))
	sb.set_border_width_all(0)
	if f > 0.0:
		var fr := Rect2(r.position + Vector2(2, 2), Vector2(maxf((r.size.x - 4.0) * f, 4.0), r.size.y - 4.0))
		sb.set_corner_radius_all(rad - 1)
		sb.bg_color = col if f >= 1.0 else col.darkened(0.45)
		if f >= 1.0:
			sb.shadow_color = Color(col.r, col.g, col.b, 0.45 + 0.1 * sin(t * 3.0))
			sb.shadow_size = 5
		ci.draw_style_box(sb, fr)
		sb.shadow_size = 0
		sb.bg_color = Color(1, 1, 1, 0.32 if f >= 1.0 else 0.12)
		sb.set_corner_radius_all(int(fr.size.y * 0.2))
		ci.draw_style_box(sb, Rect2(fr.position + Vector2(3, 1.5), Vector2(maxf(fr.size.x - 6.0, 1.0), fr.size.y * 0.28)))
		sb.bg_color = col.darkened(0.6)
		ci.draw_style_box(sb, Rect2(fr.position + Vector2(0, fr.size.y * 0.78), Vector2(fr.size.x, fr.size.y * 0.22)))
	sb.set_border_width_all(1)
	sb.border_color = BRONZE.darkened(0.35) if f < 1.0 else BRONZE.lightened(0.1)
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_corner_radius_all(rad)
	ci.draw_style_box(sb, r)


## Losango de raridade (pé das cartas).
static func draw_rarity(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.8, 0), c + Vector2(0, s), c + Vector2(-s * 0.8, 0)])
	facet(ci, pts, c, col)


# ---------------------------------------------------------------- cartas

## Carta grande (ampliada, ofertas): arte em cima com janela de bronze, placa do nome, tipo, texto, custo e raridade.
static func card(d: CardDef, cost: int, mods: Array, key: String, w: float, level: int) -> PanelContainer:
	var k := w / 168.0
	var rc: Color = UiKit.RARITY_COLORS[d.rarity]
	var p := PanelContainer.new()
	var m := roundf(8.0 * k)
	var glow := Color(rc.r, rc.g, rc.b, 0.16 if d.rarity >= 2 else 0.0)
	dress(p, "card", _rarity_trim(d.rarity), Color(0.13, 0.11, 0.135, 0.98), Color(0.05, 0.04, 0.055, 0.98), glow, m, k, true)
	p.custom_minimum_size = Vector2(w, roundf(228.0 * k))
	var bw := w - 2.0 * m
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var top := Control.new()
	var art_h := roundf(bw * 0.86)
	top.custom_minimum_size = Vector2(bw, art_h)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var clip := Control.new()
	clip.clip_contents = true
	clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.add_child(clip)
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = CardArt.textures.get(d.id)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip.add_child(art)
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	dress(frame, "inset", BRONZE.darkened(0.1), IRON_TOP, IRON_BOT, Color(0, 0, 0, 0), 0.0, k)
	clip.add_child(frame)
	# Placa do nome na borda de baixo da arte.
	var ph := roundf(27.0 * k)
	var plaque := PanelContainer.new()
	dress(plaque, "plaque", _rarity_trim(d.rarity).lerp(BRONZE, 0.35), Color(0.16, 0.13, 0.15, 0.98), Color(0.07, 0.055, 0.07, 0.98), Color(0, 0, 0, 0), 0.0, k)
	plaque.position = Vector2(roundf(bw * 0.03), art_h - roundf(ph * 0.62))
	plaque.size = Vector2(roundf(bw * 0.94), ph)
	var nl := Label.new()
	var nm := UiKit.card_name(d, level)
	var nf := font("title")
	nl.text = nm
	nl.add_theme_font_override("font", nf)
	nl.add_theme_font_size_override("font_size", fit_size(nf, nm, int(15.0 * k), bw * 0.94 - 12.0 * k, int(10.0 * k)))
	nl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.86) if mods.is_empty() else PAL["GOLD"])
	nl.add_theme_constant_override("outline_size", 2)
	nl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nl.clip_text = true
	plaque.add_child(nl)
	top.add_child(plaque)
	var gs := roundf(40.0 * k)
	var gem := UiKit.badge(UiKit.ELIXIR, int(22.0 * k), gs)
	gem.name = "Gem"
	(gem.get_node("N") as Label).name = "Cost"
	(gem.get_node("Cost") as Label).text = str(cost)
	gem.position = Vector2(-m - 7.0 * k, -m - 7.0 * k)
	top.add_child(gem)
	if key != "":
		top.add_child(_key_tag(key, k, Vector2(bw - 19.0 * k, 3.0 * k)))
	v.add_child(top)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, roundf(ph * 0.42 + 3.0 * k))
	v.add_child(gap)
	var tl := Label.new()
	tl.text = UiKit.type_line(d).to_upper()
	tl.add_theme_font_override("font", font("caps"))
	tl.add_theme_font_size_override("font_size", int(10.5 * k))
	tl.add_theme_color_override("font_color", rc.lerp(PAL["MUTED"], 0.45))
	tl.add_theme_constant_override("outline_size", 0)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tl.custom_minimum_size = Vector2(bw, 0)
	v.add_child(tl)
	if mods.size() > 0:
		var ml := Label.new()
		var stars: Array = []
		for mo in mods:
			stars.append("★ " + mo)
		ml.text = "  ".join(stars)
		ml.add_theme_font_override("font", font("bold"))
		ml.add_theme_font_size_override("font_size", int(12.5 * k))
		ml.add_theme_color_override("font_color", PAL["GOLD"])
		ml.add_theme_constant_override("outline_size", 2)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD
		ml.custom_minimum_size = Vector2(bw, 0)
		v.add_child(ml)
	var rule := Control.new()
	rule.custom_minimum_size = Vector2(bw, roundf(9.0 * k))
	rule.draw.connect(func():
		var y := rule.size.y * 0.5
		var cx := rule.size.x * 0.5
		var half := rule.size.x * 0.3
		rule.draw_line(Vector2(cx - half, y), Vector2(cx + half, y), Color(BRONZE.r, BRONZE.g, BRONZE.b, 0.35), 1.0, true)
		rule.draw_colored_polygon(PackedVector2Array([Vector2(cx, y - 2.5 * k), Vector2(cx + 2.5 * k, y), Vector2(cx, y + 2.5 * k), Vector2(cx - 2.5 * k, y)]), Color(BRONZE.r, BRONZE.g, BRONZE.b, 0.6)))
	v.add_child(rule)
	var desc := UiKit.card_rich(d, int(14.5 * k), Color(0.93, 0.9, 0.84), bw - 6.0 * k, true, level)
	desc.add_theme_font_override("normal_font", font("body"))
	desc.add_theme_font_override("bold_font", font("bold"))
	desc.add_theme_constant_override("line_separation", int(-1.0 * k))
	v.add_child(desc)
	p.add_child(v)
	var rr := d.rarity
	p.draw.connect(func(): draw_rarity(p, Vector2(p.size.x * 0.5, p.size.y - 1.5 * k), 6.5 * k, UiKit.RARITY_COLORS[rr]))
	return p


## Carta compacta (mão em leque, esteira): arte inteira, nome embaixo sobre um degradê, custo e atalho.
static func mini_card(d: CardDef, cost: int, mods: Array, key: String, w: float, h: float, named: bool, level: int) -> PanelContainer:
	var k := w / 116.0
	var p := PanelContainer.new()
	var m := maxf(roundf(5.0 * k), 3.0)
	dress(p, "card", _rarity_trim(d.rarity), Color(0.12, 0.1, 0.12, 0.98), Color(0.05, 0.04, 0.055, 0.98), Color(0, 0, 0, 0), m, maxf(k * 0.85, 0.45), true)
	p.custom_minimum_size = Vector2(w, h)
	p.size = p.custom_minimum_size
	var body := Control.new()
	body.custom_minimum_size = Vector2(w - 2.0 * m, h - 2.0 * m)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var clip := Control.new()
	clip.clip_contents = true
	clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(clip)
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture = CardArt.textures.get(d.id)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	if named:
		art.anchor_bottom = 0.86
	clip.add_child(art)
	if named:
		var grad := Gradient.new()
		grad.set_color(0, Color(0.03, 0.02, 0.035, 0.0))
		grad.set_color(1, Color(0.03, 0.02, 0.035, 0.96))
		grad.add_point(0.45, Color(0.03, 0.02, 0.035, 0.75))
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill_from = Vector2(0, 0.0)
		gt.fill_to = Vector2(0, 1.0)
		var fade := TextureRect.new()
		fade.texture = gt
		fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade.anchor_top = 0.5
		clip.add_child(fade)
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	dress(frame, "inset", BRONZE.darkened(0.15), IRON_TOP, IRON_BOT, Color(0, 0, 0, 0), 0.0, maxf(k * 0.8, 0.4))
	clip.add_child(frame)
	if named:
		# Mesma linguagem da carta grande: nome em Cinzel numa plaqueta. Uma linha quando cabe na parte que a
		# carta vizinha do leque não cobre; senão, duas.
		var nm := ("★ " if mods.size() > 0 else "") + UiKit.card_name(d, level)
		var nf := font("title")
		var room := w - 2.0 * m - 16.0 * k
		var fsz := fit_size(nf, nm, int(15.0 * k), room, int(12.0 * k))
		var two := nf.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x > room
		if two:
			var longest := ""
			for word in nm.split(" "):
				if word.length() > longest.length():
					longest = word
			fsz = fit_size(nf, longest, int(14.0 * k), room, int(10.0 * k))
		var ph := roundf((42.0 if two else 26.0) * k)
		var plaque := PanelContainer.new()
		dress(plaque, "plaque", _rarity_trim(d.rarity).lerp(BRONZE, 0.35), Color(0.16, 0.13, 0.15, 0.97), Color(0.07, 0.055, 0.07, 0.97), Color(0, 0, 0, 0), 0.0, k * 0.8)
		plaque.position = Vector2(0, h - 2.0 * m - ph - 7.0 * k)
		plaque.size = Vector2(w - 2.0 * m, ph)
		plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nl := Label.new()
		nl.text = nm
		nl.add_theme_font_override("font", nf)
		nl.add_theme_font_size_override("font_size", fsz)
		nl.add_theme_color_override("font_color", PAL["GOLD"] if mods.size() > 0 else Color(1.0, 0.95, 0.86))
		nl.add_theme_constant_override("outline_size", 2)
		nl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		nl.add_theme_constant_override("line_spacing", int(-4.0 * k))
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD if two else TextServer.AUTOWRAP_OFF
		nl.max_lines_visible = 2
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plaque.add_child(nl)
		body.add_child(plaque)
	# Nas miniaturas da esteira (sem nome) a gema é menor e fica dentro da carta: as cartas são vizinhas coladas.
	var gs := clampf(32.0 * k, 18.0, 34.0) if named else clampf(26.0 * k, 13.0, 20.0)
	var gem := UiKit.badge(UiKit.ELIXIR, int(gs * 0.56), gs)
	gem.name = "Gem"
	(gem.get_node("N") as Label).name = "Cost"
	(gem.get_node("Cost") as Label).text = str(cost)
	gem.position = Vector2(-m - gs * 0.16, -m - gs * 0.16) if named else Vector2(-m * 0.5, -m * 0.5)
	body.add_child(gem)
	# O atalho fica no pé da carta, sobre o aro: em cima ele batia no custo da carta vizinha do leque.
	if key != "":
		body.add_child(_key_tag(key, k, Vector2((w - 2.0 * m) * 0.5 - 8.5 * k, h - 2.0 * m - 4.0 * k)))
	p.add_child(body)
	UiKit.ignore_mouse(p)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Atalho do teclado num disco escuro com aro.
static func _key_tag(key: String, k: float, at: Vector2) -> Control:
	var s := roundf(17.0 * k)
	var c := Control.new()
	c.position = at
	c.size = Vector2(s, s)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var o := c.size * 0.5
		c.draw_circle(o, s * 0.5 + 1.0, Color(0, 0, 0, 0.8))
		c.draw_circle(o, s * 0.5, Color(0.1, 0.08, 0.1, 0.95))
		c.draw_arc(o, s * 0.5 - 0.5, 0, TAU, 20, BRONZE.darkened(0.1), 1.2, true))
	var l := Label.new()
	l.text = key
	l.add_theme_font_override("font", font("heavy"))
	l.add_theme_font_size_override("font_size", int(12.0 * k))
	l.add_theme_color_override("font_color", Color(1.0, 0.93, 0.8))
	l.add_theme_constant_override("outline_size", 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.offset_top = -1.0
	c.add_child(l)
	return c


## Aro da carta por raridade: ferro, verdete, aço azul, ametista (puxados para o bronze da pele).
static func _rarity_trim(r: int) -> Color:
	var rc: Color = UiKit.RARITY_COLORS[r]
	return BRONZE.lerp(rc, [0.55, 0.62, 0.66, 0.7][clampi(r, 0, 3)])


## Estado da carta da mão: selecionada (aro aceso, brilho dourado) ou jogável (brilho verde fraco).
static func card_state(p: Control, selected: bool, playable: bool) -> void:
	var m := p.material as ShaderMaterial
	if m == null:
		return
	var s := 2 if selected else (1 if playable else 0)
	if p.get_meta("st", -1) == s:
		return
	p.set_meta("st", s)
	m.set_shader_parameter("hot", 1.0 if selected else 0.0)
	m.set_shader_parameter("glow", Color(0.55, 1.0, 0.62, 0.2) if s == 1 else Color(0, 0, 0, 0))


## Liga/desliga o aro aceso de um painel (Pacto em foco no menu).
static func set_hot(c: Control, on: bool) -> void:
	var m := c.material as ShaderMaterial
	if m:
		m.set_shader_parameter("hot", 1.0 if on else 0.0)


# ---------------------------------------------------------------- menu e ícones

## Botão de menu "fantasma": só o texto em Cinzel; em foco ganha uma faixa dourada que some para a direita e
## um losango à esquerda (o menu passa o foco para o botão sob o mouse).
static func menu_button(b: Button, size: int) -> void:
	b.set_meta("no_frame", true)
	b.add_theme_font_override("font", font("title_wide"))
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", _menu_box(0.0))
	b.add_theme_stylebox_override("hover", _menu_box(0.0))
	b.add_theme_stylebox_override("disabled", _menu_box(0.0))
	b.add_theme_stylebox_override("focus", _menu_box(0.0))
	b.add_theme_stylebox_override("pressed", _menu_box(0.0))
	b.add_theme_color_override("font_color", Color(0.86, 0.81, 0.74))
	b.add_theme_color_override("font_hover_color", PAL["GOLD"])
	b.add_theme_color_override("font_focus_color", PAL["GOLD"])
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.8))
	b.add_theme_constant_override("outline_size", 3)
	b.draw.connect(func():
		if not (b.has_focus() or b.is_hovered()):
			return
		var c := Vector2(14.0, b.size.y * 0.5)
		var s := 6.5
		facet(b, PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), c, PAL["GOLD"])
		var tw := b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
		var y := b.size.y - 7.0
		var n := 20
		for i in n:
			var x0 := 34.0 + (tw + 40.0) * i / n
			var x1 := 34.0 + (tw + 40.0) * (i + 1) / n
			b.draw_line(Vector2(x0, y), Vector2(x1, y), Color(PAL["GOLD"].r, PAL["GOLD"].g, PAL["GOLD"].b, 0.85 * (1.0 - float(i) / n)), 2.0))
	b.focus_entered.connect(b.queue_redraw)
	b.focus_exited.connect(b.queue_redraw)


static func _menu_box(a: float) -> StyleBox:
	var sb := StyleBoxTexture.new()
	if a > 0.0:
		var g := Gradient.new()
		g.set_color(0, Color(PAL["GOLD"].r, PAL["GOLD"].g * 0.8, PAL["GOLD"].b * 0.5, a))
		g.set_color(1, Color(PAL["GOLD"].r, PAL["GOLD"].g * 0.8, PAL["GOLD"].b * 0.5, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.width = 128
		gt.height = 4
		sb.texture = gt
	else:
		sb.draw_center = false
		sb.texture = marker(9)
	sb.content_margin_left = 34
	sb.content_margin_right = 18
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


## Régua de ornamento: losango e uma linha de bronze que some para a direita.
static func ornament(w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 14)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var y := c.size.y * 0.5
		var n := 24
		for i in n:
			var x0 := 14.0 + (c.size.x - 14.0) * i / n
			var x1 := 14.0 + (c.size.x - 14.0) * (i + 1) / n
			c.draw_line(Vector2(x0, y), Vector2(x1, y), Color(BRONZE.r, BRONZE.g, BRONZE.b, 0.9 * (1.0 - float(i) / n)), 2.0)
		var p := Vector2(6.0, y)
		facet(c, PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 0), p + Vector2(0, 6), p + Vector2(-5, 0)]), p, PAL["GOLD"]))
	return c


## Ícone desenhado num botão da HUD: "pause" (duas barras) ou "map" (mapa dobrado).
static func icon_button(b: Button, kind: String) -> void:
	b.text = ""
	b.draw.connect(_draw_icon.bind(b, kind))


static func _draw_icon(b: Button, kind: String) -> void:
	var c := b.size * 0.5
	var col: Color = PAL["GOLD"] if (b.is_hovered() or b.has_focus()) else Color(0.92, 0.85, 0.72)
	var sh := Color(0, 0, 0, 0.7)
	if kind == "pause":
		for dx in [-5.0, 5.0]:
			b.draw_rect(Rect2(c + Vector2(dx - 2.5, -7.5), Vector2(5, 18)), sh)
			b.draw_rect(Rect2(c + Vector2(dx - 2.5, -9.0), Vector2(5, 18)), col)
		return
	var pts := PackedVector2Array([c + Vector2(-12, -8), c + Vector2(-4, -11), c + Vector2(4, -8), c + Vector2(12, -11),
		c + Vector2(12, 8), c + Vector2(4, 11), c + Vector2(-4, 8), c + Vector2(-12, 11), c + Vector2(-12, -8)])
	var off := PackedVector2Array()
	for p in pts:
		off.append(p + Vector2(0, 1.5))
	b.draw_polyline(off, sh, 3.0, true)
	b.draw_polyline(pts, col, 2.0, true)
	b.draw_line(c + Vector2(-4, -11), c + Vector2(-4, 8), col, 1.5, true)
	b.draw_line(c + Vector2(4, -8), c + Vector2(4, 11), col, 1.5, true)


## Fundo de um Control que se desenha sozinho (faixa de rota, mapa grande): põe o material e desenha a placa.
## Chamar no começo do _draw; devolve false nas outras peles (o chamador desenha o fundo antigo).
static func draw_plate(c: Control, kind := "soft", grow := Vector2.ZERO) -> bool:
	if not UiSkins.covil():
		return false
	if c.material == null:
		c.material = material(kind, BRONZE.darkened(0.1), Color(0.07, 0.06, 0.075, 0.82), Color(0.035, 0.03, 0.04, 0.82))
	c.draw_style_box(box(kind, 0.0), Rect2(-grow, c.size + grow * 2.0))
	return true
