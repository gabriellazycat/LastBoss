class_name UiDiario
extends RefCounted
## Pele "Diário" da interface, a padrão desde 09/11/2026 (Settings "look_hud" 6; estudo em docs/variacoes/cartas/).
## Papel sujo com borda rasgada, fita crepe, nanquim e letra datilografada. As peças saem do shader
## game/ui/paper.gdshader (mesma textura-marcador do UiCovil). Cartas: faixa de fita no topo na cor do tipo,
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
static var _hatch := {}


# ---------------------------------------------------------------- fontes

## "type" Special Elite (datilografada), "hand" Patrick Hand, "marker" Permanent Marker, "fell" IM Fell SC,
## "fell_it" IM Fell itálico. As que não têm → e ★ caem na Alegreya Sans.
static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var file: String = {"type": "SpecialElite-Regular.ttf", "hand": "PatrickHand-Regular.ttf", "marker": "PermanentMarker-Regular.ttf",
		"fell": "IMFellEnglishSC-Regular.ttf", "fell_it": "IMFellEnglish-Italic.ttf"}.get(kind, "PatrickHand-Regular.ttf")
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
	sb.texture = UiCovil.marker(state)
	sb.set_expand_margin_all(shadow)
	sb.set_content_margin_all(margin)
	return sb


static func dress(c: Control, kind: String, margin := 12.0, opts := {}, unique := false) -> void:
	c.add_theme_stylebox_override("panel", box(margin, float(opts.get("shadow", 7.0))))
	c.material = material(kind, opts, unique)
	c.set_meta("paper", true)


static func seed_of(s: String) -> float:
	return float(absi(hash(s)) % 97) / 97.0


static func panel(bg: Color, _border: Color, margin: int, kind := "paper") -> PanelContainer:
	var p := PanelContainer.new()
	dress(p, kind, margin + 8, {"grime": 0.3 if bg.a < 0.9 else 0.4, "seed": randf()})
	return p


## Botões: fita crepe. O material entra quando o botão nasce (main conecta node_added). Cada botão sorteia
## uma de seis sementes (pontas rasgadas diferentes).
static func button_material(i := 0, tint := MASK) -> ShaderMaterial:
	return material("tape", {"button": true, "seed": float(i % 6) * 0.17, "tint": tint, "shadow": 4.0})


static func on_node_added(n: Node) -> void:
	if n is Button and n.material == null and not n.has_meta("no_frame"):
		(n as Button).material = button_material(n.get_instance_id())
	if n is Label or n is RichTextLabel:
		_inkify.call_deferred(n)


## Texto em cima de papel: cor clara vira tinta (mantém o matiz), sem contorno. Texto solto sobre o mundo fica.
static func _inkify(n: Control) -> void:
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
	var states := {"normal": 9, "hover": 10, "pressed": 11, "disabled": 12, "focus": 13}
	for st in states:
		var sb := box(10.0, 4.0, states[st])
		sb.content_margin_left = 22
		sb.content_margin_right = 22
		sb.content_margin_top = 8
		sb.content_margin_bottom = 7
		t.set_stylebox(st, "Button", sb)
		var ob := box(8.0, 4.0, states[st])
		ob.content_margin_left = 16
		t.set_stylebox(st, "OptionButton", ob)
	t.set_font("font", "Button", font("type"))
	t.set_font("font", "OptionButton", font("type"))
	t.set_font_size("font_size", "Button", 20)
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(k, "Button", INK)
		t.set_color(k, "OptionButton", INK)
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
	var pap := Color(0.9, 0.86, 0.76)
	t.set_stylebox("panel", "PopupMenu", flat.call(pap, INK, 2, 6))
	t.set_stylebox("hover", "PopupMenu", flat.call(Color(0.89, 0.8, 0.55), INK, 0, 4))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", BLOOD)
	t.set_font("font", "PopupMenu", font("type"))
	t.set_stylebox("panel", "TooltipPanel", flat.call(pap, INK, 1, 8))
	t.set_color("font_color", "TooltipLabel", INK)
	var track: StyleBoxFlat = flat.call(INK, INK, 0, 0)
	track.content_margin_top = 1
	track.content_margin_bottom = 1
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", track)
	t.set_stylebox("grabber_area_highlight", "HSlider", track)
	t.set_icon("grabber", "HSlider", _blot_icon(22, BLOOD))
	t.set_icon("grabber_highlight", "HSlider", _blot_icon(24, BLOOD.lightened(0.15)))
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


## Mancha de tinta (pegador de slider).
static func _blot_icon(n: int, col: Color) -> ImageTexture:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in n:
		for x in n:
			var a := atan2(y - c, x - c)
			var r := c * (0.8 + 0.12 * sin(a * 3.0 + 1.0) + 0.06 * sin(a * 7.0))
			var d := Vector2(x - c, y - c).length()
			if d <= r:
				img.set_pixel(x, y, Color(col.r, col.g, col.b, clampf(r - d, 0.0, 1.0)))
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
	l.add_theme_font_size_override("font_size", roundi(size * 1.18))
	l.add_theme_constant_override("outline_size", 0)


static func title(l: Label, size: int, col: Color) -> void:
	l.add_theme_font_override("font", font("marker") if size >= 30 else font("type"))
	l.add_theme_font_size_override("font_size", size if size >= 30 else roundi(size * 1.05))
	l.add_theme_color_override("font_color", ink_of(col) if col.get_luminance() > 0.42 else col)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))


## Título solto sobre o mundo (sem papel embaixo): fita vermelha atrás do texto.
static func tape_title(l: Label, tint := TYPES["monster"][0]) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(0.0, 4.0))
	(p.get_theme_stylebox("panel") as StyleBoxTexture).content_margin_left = 26
	(p.get_theme_stylebox("panel") as StyleBoxTexture).content_margin_right = 26
	(p.get_theme_stylebox("panel") as StyleBoxTexture).content_margin_top = 4
	(p.get_theme_stylebox("panel") as StyleBoxTexture).content_margin_bottom = 2
	p.material = material("tape", {"tint": Color(tint.r, tint.g, tint.b, 0.95), "shadow": 4.0, "seed": 0.3})
	p.set_meta("tape", true)
	l.set_meta("no_ink", true)
	l.add_theme_color_override("font_color", Color(1.0, 0.96, 0.9))
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.rotation_degrees = -1.2
	return p


## Rótulo numa tira de fita crepe (texto a tinta): legendas sobre o mundo, cabeçalhos das ofertas.
static func tape_wrap(c: Control, tint := MASK, rot := -1.5) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(0.0, 3.0)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 3
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.material = material("tape", {"tint": tint, "shadow": 3.0, "seed": randf()})
	p.set_meta("paper", true)
	p.add_child(c)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.rotation_degrees = rot
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Bilhete: etiqueta de papel claro em volta de um texto (efeito de melhoria, preço).
static func note_wrap(c: Control) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(6.0, 4.0)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	p.add_theme_stylebox_override("panel", sb)
	p.material = material("patch", {"grime": 0.2, "shadow": 4.0, "seed": randf(), "rough": 1.4})
	p.set_meta("paper", true)
	p.add_child(c)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.rotation_degrees = randf_range(-1.5, 1.5)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


# ---------------------------------------------------------------- barras e selos

## Barra a lápis: contorno tremido e enchimento hachurado na cor.
static func bar(col: Color, w: float, h: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.material = material("slot", {"shadow": 0.0, "rough": 0.8})
	b.add_theme_stylebox_override("background", box(0.0, 0.0))
	var fs := StyleBoxTexture.new()
	fs.texture = _hatch_tex(col)
	fs.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	fs.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	fs.set_expand_margin_all(-2.5 if h >= 10 else -1.5)
	fs.set_content_margin_all(0)
	b.add_theme_stylebox_override("fill", fs)
	return b


## Hachura de lápis: traços inclinados na cor sobre um fundo da mesma cor mais claro (32 px: o shader ignora).
static func _hatch_tex(col: Color) -> ImageTexture:
	var key := col.to_html()
	if not _hatch.has(key):
		var n := 32
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d := fmod(float(x + y * 0.55), 6.0)
				var stroke := clampf(1.6 - absf(d - 1.6), 0.0, 1.0)
				var base := Color(col.r, col.g, col.b, 0.38)
				img.set_pixel(x, y, base.lerp(Color(col.r * 0.8, col.g * 0.8, col.b * 0.8, 0.95), stroke))
		_hatch[key] = ImageTexture.create_from_image(img)
	return _hatch[key]


## Selo com número: "crystal" = mancha de sangue (custo, elixir), "crest" = escudo a nanquim, "sigil" = estrela.
static func badge(col: Color, size: int, w: float, shape: String) -> PanelContainer:
	var g := PanelContainer.new()
	g.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	g.custom_minimum_size = Vector2(w, w)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sd := randf() * 10.0
	g.draw.connect(func(): draw_badge(g, Rect2(Vector2.ZERO, g.size), col, shape, sd))
	var l := Label.new()
	l.name = "N"
	l.set_meta("no_ink", true)
	l.add_theme_font_override("font", font("type"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88) if shape != "crest" else INK)
	l.add_theme_constant_override("outline_size", 0)
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
			ci.draw_colored_polygon(pts, Color(0.88, 0.83, 0.72))
			var loop := pts.duplicate()
			loop.append(pts[0])
			ci.draw_polyline(loop, INK, maxf(1.5, s * 0.1), true)
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
	var c := r.get_center() + Vector2(0, r.size.y * 0.08)
	var s := minf(r.size.x * 0.5, r.size.y * 0.5) * 0.92
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var rr := s * (1.0 if sin(a) > -0.2 else 1.0 - (-sin(a) - 0.2) * 0.0)
		var p := c + Vector2(cos(a), sin(a)) * rr
		if sin(a) < -0.3:
			p.x = lerpf(p.x, c.x, (-sin(a) - 0.3) / 0.7 * 0.75)
			p.y = c.y - s - (-sin(a) - 0.3) / 0.7 * s * 0.55
		pts.append(p)
	if f > 0.0:
		var ink := col if f >= 1.0 else col.lerp(Color(0.85, 0.8, 0.7), 0.45)
		var top := c.y + s - (s * 2.5) * clampf(f, 0.0, 1.0)
		var fill := PackedVector2Array()
		for p in pts:
			fill.append(Vector2(p.x, maxf(p.y, top)))
		ci.draw_colored_polygon(fill, ink)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, Color(col.r * 0.55, col.g * 0.55, col.b * 0.55), 1.6, true)


# ---------------------------------------------------------------- cartas

static func card_tex(id: String) -> Texture2D:
	if not _tex.has(id):
		var path := CARDS + id + ".png"
		if not ResourceLoader.exists(path):
			path = CARDS + CardModel.art_of(id) + ".png"
		_tex[id] = load(path) if ResourceLoader.exists(path) else null
	return _tex[id]


static func type_spec(d: CardDef) -> Array:
	return TYPES.get(d.type, TYPES["monster"])


## Mancha de custo com o número (nomes "Gem" e "Cost": a mão troca o número quando o custo muda).
static func _cost_blot(cost: int, s: float, cheaper := false) -> PanelContainer:
	# Custo abaixo do original (Barato, nível que barateia): a gema fica azul-água.
	# Dois dígitos (10 a 12) encolhem a fonte para caber no selo.
	var gem := badge(Color(0.08, 0.55, 0.6) if cheaper else BLOOD, int(s * (0.52 if cost < 10 else 0.4)), s, "crystal")
	gem.name = "Gem"
	(gem.get_node("N") as Label).name = "Cost"
	(gem.get_node("Cost") as Label).text = str(cost)
	return gem


static func _name_label(nm: String, size: float, col: Color, room: float, lines := 2) -> Label:
	var l := Label.new()
	l.text = nm
	l.set_meta("no_ink", true)
	var f := font("type")
	var fsz := UiCovil.fit_size(f, nm, int(size), room, int(size * 0.72))
	var two := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x > room and lines > 1
	if two:
		var longest := ""
		for word in nm.split(" "):
			if word.length() > longest.length():
				longest = word
		fsz = UiCovil.fit_size(f, longest, int(size * 0.9), room, int(size * 0.62))
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", fsz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("line_spacing", int(-fsz * 0.22))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD if two else TextServer.AUTOWRAP_OFF
	l.max_lines_visible = lines
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Carta grande: faixa de fita com nome e custo, desenho, tipo entre traços e o texto numa etiqueta clara.
static func card(d: CardDef, cost: int, mods: Array, key: String, w: float, level: int) -> PanelContainer:
	var k := w / 168.0
	var spec := type_spec(d)
	var p := PanelContainer.new()
	var band := roundf(31.0 * k)
	var opts := {"grime": 0.9, "seed": seed_of(d.id), "band": band, "tint": Color(spec[0].r, spec[0].g, spec[0].b, 0.94), "shadow": roundf(6.0 * k), "rough": 1.6 * k}
	p.add_theme_stylebox_override("panel", box(0.0, opts["shadow"]))
	p.material = material("card", opts, true)
	p.set_meta("paper", true)
	p.custom_minimum_size = Vector2(w, roundf(240.0 * k))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := HBoxContainer.new()
	head.custom_minimum_size = Vector2(w, band)
	head.add_theme_constant_override("separation", int(4 * k))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(9.0 * k, 0)
	head.add_child(pad)
	var nm := ("★ " if mods.size() > 0 else "") + UiKit.card_name(d, level)
	var nl := _name_label(nm, 15.5 * k, spec[2], w - 52.0 * k)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.custom_minimum_size = Vector2(0, band)
	head.add_child(nl)
	var gem := _cost_blot(cost, 27.0 * k, cost < d.cost)
	gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(gem)
	var pad2 := Control.new()
	pad2.custom_minimum_size = Vector2(5.0 * k, 0)
	head.add_child(pad2)
	v.add_child(head)
	var art := TextureRect.new()
	art.texture = card_tex(d.id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.custom_minimum_size = Vector2(w, roundf(w * 0.62))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(art)
	var tl := Label.new()
	tl.text = UiKit.type_line(d).to_upper()
	tl.set_meta("no_ink", true)
	tl.add_theme_font_override("font", font("type"))
	tl.add_theme_font_size_override("font_size", int(9.5 * k))
	tl.add_theme_color_override("font_color", Color(spec[1].r, spec[1].g, spec[1].b, 0.85))
	tl.add_theme_constant_override("outline_size", 0)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tl.custom_minimum_size = Vector2(w - 20.0 * k, 0)
	var mids := UiKit.mod_ids_of(mods)
	var dark := CardFx.is_dark(mids, level)
	if dark:
		tl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8, 0.9))
	var tcol: Color = spec[1] if not dark else Color(0.92, 0.88, 0.8)
	tl.draw.connect(func():
		var tw := tl.get_theme_font("font").get_string_size(tl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tl.get_theme_font_size("font_size")).x
		var y := tl.size.y * 0.55
		var x0 := (tl.size.x - tw) * 0.5 - 6.0 * k
		var x1 := (tl.size.x + tw) * 0.5 + 6.0 * k
		var lc := Color(tcol.r, tcol.g, tcol.b, 0.4)
		tl.draw_line(Vector2(8.0 * k, y), Vector2(x0, y), lc, 1.0, true)
		tl.draw_line(Vector2(x1, y), Vector2(tl.size.x - 8.0 * k, y), lc, 1.0, true))
	v.add_child(tl)
	if mods.size() > 0:
		var ml := Label.new()
		var stars: Array = []
		for mo in mods:
			stars.append("★ " + mo)
		ml.text = "  ".join(stars)
		ml.set_meta("no_ink", true)
		ml.add_theme_font_override("font", font("hand"))
		ml.add_theme_font_size_override("font_size", int(15.0 * k))
		ml.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55) if dark else BLOOD)
		ml.add_theme_constant_override("outline_size", 0)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD
		ml.custom_minimum_size = Vector2(w - 20.0 * k, 0)
		v.add_child(ml)
	var patch := PanelContainer.new()
	patch.add_theme_stylebox_override("panel", box(roundf(4.0 * k), 0.0))
	(patch.get_theme_stylebox("panel") as StyleBoxTexture).content_margin_left = roundf(6.0 * k)
	(patch.get_theme_stylebox("panel") as StyleBoxTexture).content_margin_right = roundf(6.0 * k)
	patch.material = material("patch", {"grime": 0.0, "shadow": 0.0, "rough": 1.1 * k, "seed": seed_of(d.id + "p")})
	patch.set_meta("paper", true)
	patch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mg := MarginContainer.new()
	for side in ["left", "right"]:
		mg.add_theme_constant_override("margin_" + side, int(8.0 * k))
	mg.add_theme_constant_override("margin_top", int(3.0 * k))
	mg.add_theme_constant_override("margin_bottom", int(7.0 * k))
	mg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var desc := UiKit.card_rich(d, int(15.0 * k), INK, w - 34.0 * k, true, level, mids)
	desc.set_meta("no_ink", true)
	desc.add_theme_font_override("normal_font", font("hand"))
	desc.add_theme_font_override("bold_font", font("type"))
	desc.add_theme_constant_override("outline_size", 0)
	desc.add_theme_constant_override("line_separation", int(-2.0 * k))
	desc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(desc)
	patch.add_child(cc)
	mg.add_child(patch)
	v.add_child(mg)
	if key != "":
		# O atalho fica no pé da carta, embaixo da etiqueta (posição fixa caía em cima do desenho).
		var kc := CenterContainer.new()
		kc.custom_minimum_size = Vector2(w, roundf(19.0 * k))
		kc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var kt := _key_tag(key, k)
		kt.custom_minimum_size = kt.size
		kc.add_child(kt)
		v.add_child(kc)
	p.add_child(v)
	UiKit.ignore_mouse(p)
	CardFx.attach(p, level, mids, w / 116.0, true)
	return p


## Carta compacta (mão em leque, esteira): faixa com nome e custo e o desenho embaixo.
static func mini_card(d: CardDef, cost: int, mods: Array, key: String, w: float, h: float, named: bool, level: int) -> PanelContainer:
	var k := w / 116.0
	var spec := type_spec(d)
	var p := PanelContainer.new()
	var band := roundf((34.0 if named else 0.0) * k)
	var opts := {"grime": 0.85, "seed": seed_of(d.id), "band": band if named else 8.0 * k, "tint": Color(spec[0].r, spec[0].g, spec[0].b, 0.94), "shadow": maxf(roundf(5.0 * k), 2.0), "rough": 1.3 * k}
	p.add_theme_stylebox_override("panel", box(0.0, opts["shadow"]))
	p.material = material("card", opts, true)
	p.set_meta("paper", true)
	p.custom_minimum_size = Vector2(w, h)
	p.size = p.custom_minimum_size
	var body := Control.new()
	body.custom_minimum_size = Vector2(w, h)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.texture = card_tex(d.id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.position = Vector2(3.0 * k, band + 2.0 * k)
	art.size = Vector2(w - 6.0 * k, h - band - (14.0 if key != "" else 5.0) * k)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(art)
	var gs := clampf(27.0 * k, 16.0, 30.0) if named else clampf(22.0 * k, 12.0, 18.0)
	if named:
		var nm := ("★ " if mods.size() > 0 else "") + UiKit.card_name(d, level)
		var nl := _name_label(nm, 14.0 * k, spec[2], w - gs - 14.0 * k)
		nl.position = Vector2(7.0 * k, 0)
		nl.size = Vector2(w - gs - 12.0 * k, band)
		body.add_child(nl)
	var gem := _cost_blot(cost, gs, cost < d.cost)
	gem.position = Vector2(w - gs - 3.0 * k, (band - gs) * 0.5 if named else 2.0)
	gem.size = Vector2(gs, gs)
	body.add_child(gem)
	if key != "":
		var kt := _key_tag(key, k)
		kt.position = Vector2(w * 0.5 - 8.5 * k, h - 13.0 * k)
		body.add_child(kt)
	p.add_child(body)
	UiKit.ignore_mouse(p)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	CardFx.attach(p, level, UiKit.mod_ids_of(mods), w / 116.0)
	return p


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
	var m := p.material as ShaderMaterial
	if m == null:
		return
	var s := 2 if selected else (1 if playable else 0)
	if p.get_meta("st", -1) == s:
		return
	p.set_meta("st", s)
	m.set_shader_parameter("hot", 1.0 if selected else 0.0)


static func set_hot(c: Control, on: bool) -> void:
	var m := c.material as ShaderMaterial
	if m:
		m.set_shader_parameter("hot", 1.0 if on else 0.0)


# ---------------------------------------------------------------- menu e ícones

## Botão de menu: fita crepe datilografada; a primeira opção pode ser vermelha.
static func menu_button(b: Button, size: int, red := false) -> void:
	b.set_meta("no_frame", true)
	b.material = material("tape", {"button": true, "seed": randf(), "tint": Color(0.66, 0.15, 0.1, 0.95) if red else MASK, "shadow": 4.0})
	b.add_theme_font_override("font", font("type"))
	b.add_theme_font_size_override("font_size", size)
	var c := Color(1.0, 0.96, 0.9) if red else INK
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, c)
	b.rotation_degrees = randf_range(-1.6, 1.6)


## Traço de pincel sob um título.
static func ornament(w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 16)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var pts := PackedVector2Array()
		var pts2 := PackedVector2Array()
		for i in 25:
			var t := float(i) / 24.0
			pts.append(Vector2(t * c.size.x, 9.0 - sin(t * 3.0) * 3.0 + sin(t * 17.0) * 0.8))
			pts2.append(Vector2(8.0 + t * (c.size.x - 30.0), 13.0 - sin(t * 2.5 + 1.0) * 2.0))
		c.draw_polyline(pts, BLOOD, 3.2, true)
		c.draw_polyline(pts2, Color(BLOOD.r, BLOOD.g, BLOOD.b, 0.7), 1.8, true))
	return c


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
	if c.material == null:
		c.material = material("paper", {"grime": 0.25, "seed": 0.4, "shadow": 6.0})
		c.set_meta("paper", true)
	c.draw_style_box(box(0.0, 6.0), Rect2(-grow, c.size + grow * 2.0))
