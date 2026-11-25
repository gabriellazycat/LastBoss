class_name UiParch
extends RefCounted
## Kit visual da interface (pele "Mapa aberto"): papel, moldura dupla de tinta, faixas e selos redesenhados como o
## pergaminho do mapa (assets/ui/kit_mapa, feito por tools/art/ui_kit/make_map_kit.py), com as cores e letras do
## mapa (minimap.gd). UiDiario chama estas peças; as funções dele mantêm os nomes antigos.

const PORTRAITS := "res://assets/ui/portraits/"

## Paleta: tinta e vermelho do mapa pergaminho, ouro das molduras, papel das cartas.
const INK := Color("3a2916")
const INK_SOFT := Color("5c4630")
const BLOOD := Color("8e2f27")
const GOLD := Color("c08a2e")
const GOLD_LIGHT := Color("f0cf7a")
const PARCH := Color("efe3c4")
const PARCH_DARK := Color("d9c393")
const CREAM := Color(1.0, 0.965, 0.89)
const NIGHT := Color(0.09, 0.065, 0.05, 0.86)
const ELIXIR := Color("7a4fd0")
const ELIXIR_DEEP := Color("3c1f78")
## Almas (a moeda da meta): azul-alma, para nao se confundir com o roxo do elixir.
const SOUL := Color("2b6a86")
const HP := Color("b3281c")
const HP_DEEP := Color("5a0f0a")
const GOOD := Color("2f6b2a")

static var _tex := {}
static var _fonts := {}


## Pasta do kit da pele atual: a "Mapa aberto" tem as mesmas peças redesenhadas como o pergaminho do mapa.
static func kit_dir() -> String:
	return "res://assets/ui/kit_mapa/"


static func tex(name: String) -> Texture2D:
	var key := kit_dir() + name
	if not _tex.has(key):
		var p := kit_dir() + name + ".png"
		if not ResourceLoader.exists(p):
			p = PORTRAITS + name + ".png"
		_tex[key] = load(p) if ResourceLoader.exists(p) else null
	return _tex[key]


## Retrato pintado (vilão ou herói, assets/ui/portraits/<id>.png); null se ainda não existe.
static func portrait(id: String) -> Texture2D:
	var p := PORTRAITS + id + ".png"
	if not _tex.has("P_" + id):
		_tex["P_" + id] = load(p) if ResourceLoader.exists(p) else null
	return _tex["P_" + id]


# ---------------------------------------------------------------- letras

## "title" IM Fell English SC (nomes das cartas, títulos); "body" Alegreya Sans Medium (texto corrido, legível em
## tamanho pequeno); "bold" Alegreya Sans Bold (números, rótulos); "serif" Alegreya (texto das cartas);
## "italic" IM Fell English itálico (linhas de tipo, legendas).
static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var file: String = {"title": "IMFellEnglishSC-UI.ttf", "body": "AlegreyaSans-Medium.ttf", "bold": "AlegreyaSans-Bold.ttf",
		"heavy": "AlegreyaSans-ExtraBold.ttf", "serif": "Alegreya-VF.ttf", "italic": "IMFellEnglish-Italic.ttf"}.get(kind, "AlegreyaSans-Medium.ttf")
	var fv := FontVariation.new()
	fv.base_font = load(UiDiario.F + file)
	# A Fell SC da interface não tem algarismos (o "1" dela lia "I"): os números caem na Alegreya serifada.
	fv.fallbacks = [load(UiDiario.F + ("Alegreya-VF.ttf" if kind == "title" else "AlegreyaSans-Bold.ttf")), load(UiDiario.F + "AlegreyaSans-Bold.ttf")]
	if kind == "title":
		fv.spacing_glyph = 1
	_fonts[kind] = fv
	return fv


# ---------------------------------------------------------------- caixas

## Painel de papel com moldura: "gold" (arabescos dourados, painéis principais), "ink" (traço fino, rótulos e
## botões), "night" (papel azul-noite do Veterano). Margens do 9-slice medidas no PNG (cantos com arabesco).
static func box(kind := "gold", margin := 18.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex("panel_" + kind)
	var m := 34.0 if kind != "ink" else 14.0
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	# margin <= 0: caixa "crua" (o chamador põe as margens e usa UiKit.fit_margins); senão a margem conta a moldura desenhada.
	sb.set_content_margin_all(margin if margin <= 0.0 else maxf(margin, UiKit.paper_clean(kind)))
	return sb


## Botão de papel com traço fino; acende em dourado no foco/mouse, afunda ao apertar.
## pad.y/pad.w: SP_M, o mínimo que mantém o texto fora do traço (UiKit.clean_need).
static func button_box(state: String, pad := Vector4(20, 11, 20, 12)) -> StyleBox:
	if state == "focus":
		var f := StyleBoxFlat.new()
		f.bg_color = Color(0, 0, 0, 0)
		f.draw_center = false
		f.border_color = GOLD_LIGHT
		f.set_border_width_all(2)
		f.set_corner_radius_all(6)
		f.set_expand_margin_all(3)
		f.anti_aliasing = true
		return f
	var sb := StyleBoxTexture.new()
	sb.texture = tex("button_gold" if state in ["hover", "pressed"] else "button_ink")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sb.set_texture_margin(side, 17.0 if state in ["hover", "pressed"] else 9.0)
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	match state:
		"pressed":
			sb.modulate_color = Color(0.86, 0.8, 0.7)
			sb.content_margin_top = pad.y + 2
			sb.content_margin_bottom = pad.w - 2
		"disabled":
			sb.modulate_color = Color(0.72, 0.69, 0.64, 0.9)
	return sb


## Fita dobrada (a do nome da carta) como fundo de botão ou título: `kind` = tipo da fita (monster = vermelha).
static func ribbon_box(kind := "monster", dim := false, pad := Vector4(46, 12, 46, 12)) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex("ribbon_%s%s" % [kind, "_dim" if dim else ""])
	sb.texture_margin_left = 34
	sb.texture_margin_right = 34
	sb.texture_margin_top = 14
	sb.texture_margin_bottom = 18
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	return sb


static var _ring_mat: ShaderMaterial


## Pinta só a silhueta (alfa) da textura em amarelo: o contorno do foco das faixas.
static func _ring_material() -> ShaderMaterial:
	if _ring_mat == null:
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;
uniform vec4 col : source_color = vec4(0.94, 0.81, 0.48, 1.0);
void fragment() { COLOR = vec4(col.rgb, texture(TEXTURE, UV).a); }
"
		_ring_mat = ShaderMaterial.new()
		_ring_mat.shader = sh
		_ring_mat.set_shader_parameter("col", GOLD_LIGHT)
	return _ring_mat


## Aplica a fita como botão: normal, mouse (mais claro), apertado/desligado (fita escura). Texto creme em Fell SC.
static func ribbon_button(b: Button, kind := "monster", size := 24) -> void:
	b.set_meta("no_frame", true)
	b.material = null
	var hover := ribbon_box(kind)
	hover.modulate_color = Color(1.12, 1.08, 1.04)
	b.add_theme_stylebox_override("normal", ribbon_box(kind))
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", ribbon_box(kind, true))
	b.add_theme_stylebox_override("hover_pressed", ribbon_box(kind, true))
	b.add_theme_stylebox_override("disabled", ribbon_box(kind, true))
	# Foco: contorno amarelo com a forma da faixa (a silhueta da fita, um pouco maior, atrás do botão).
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ring := NinePatchRect.new()
	ring.name = "FocusRing"
	ring.texture = tex("ribbon_%s" % kind)
	ring.patch_margin_left = 34
	ring.patch_margin_right = 34
	ring.patch_margin_top = 14
	ring.patch_margin_bottom = 18
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.offset_left = -5
	ring.offset_right = 5
	ring.offset_top = -5
	ring.offset_bottom = 5
	ring.show_behind_parent = true
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.material = _ring_material()
	ring.visible = b.has_focus()
	b.add_child(ring)
	b.focus_entered.connect(func(): ring.visible = true)
	b.focus_exited.connect(func(): ring.visible = false)
	b.add_theme_font_override("font", font("title"))
	b.add_theme_font_size_override("font_size", size)
	var txt := Color("1c140c") if kind == "structure" else CREAM
	for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, txt)
	b.add_theme_color_override("font_disabled_color", Color(txt, 0.55))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	b.add_theme_constant_override("outline_size", 0 if kind == "structure" else 3)


## Botão de papel (o padrão do tema): Fell SC a tinta, vermelho no mouse.
static func paper_button(b: Button, size := 22) -> void:
	b.set_meta("no_frame", true)
	b.material = null
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, button_box(st))
	b.add_theme_stylebox_override("hover_pressed", button_box("pressed"))
	b.add_theme_font_override("font", font("title"))
	b.add_theme_font_size_override("font_size", size)
	for k in ["font_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(k, INK)
	b.add_theme_color_override("font_hover_color", BLOOD)
	b.add_theme_color_override("font_hover_pressed_color", BLOOD)
	b.add_theme_color_override("font_disabled_color", Color(INK, 0.5))
	b.add_theme_constant_override("outline_size", 0)


## Título numa fita (sobre o mundo ou no topo de uma tela).
static func ribbon_title(text: String, size := 34, kind := "monster") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", ribbon_box(kind, false, Vector4(56, 12, 56, 12)))
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_meta("tape", true)
	var l := Label.new()
	l.text = text
	style_label(l, "title", size, CREAM)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


static func style_label(l: Control, kind: String, size: int, col: Color) -> void:
	l.set_meta("no_ink", true)
	if l is RichTextLabel:
		l.add_theme_font_override("normal_font", font(kind))
		l.add_theme_font_size_override("normal_font_size", size)
		l.add_theme_color_override("default_color", col)
		l.add_theme_constant_override("outline_size", 0)
		return
	l.add_theme_font_override("font", font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))


static func label(text: String, kind: String, size: int, col := INK) -> Label:
	var l := Label.new()
	l.text = text
	style_label(l, kind, size, col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Filete dourado com losango no meio (separador de seções, como o da carta lendária).
static func divider(w: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 14)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var y := c.size.y * 0.5
		var mid := c.size.x * 0.5
		c.draw_line(Vector2(0, y), Vector2(mid - 12, y), Color(GOLD, 0.85), 1.5, true)
		c.draw_line(Vector2(mid + 12, y), Vector2(c.size.x, y), Color(GOLD, 0.85), 1.5, true)
		c.draw_colored_polygon(PackedVector2Array([Vector2(mid, y - 6), Vector2(mid + 7, y), Vector2(mid, y + 6), Vector2(mid - 7, y)]), GOLD)
		c.draw_colored_polygon(PackedVector2Array([Vector2(mid, y - 3), Vector2(mid + 3.5, y), Vector2(mid, y + 3), Vector2(mid - 3.5, y)]), GOLD_LIGHT))
	return c


## Retrato com moldura dourada por cima (vilão, herói). `tex` ausente → o desenho antigo, sem moldura.
static func framed_art(t: Texture2D, size: Vector2, frame := "frame_gold") -> Control:
	var c := Control.new()
	c.custom_minimum_size = size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var clip := Panel.new()
	var cb := StyleBoxFlat.new()
	cb.bg_color = Color.WHITE
	cb.set_corner_radius_all(8)
	clip.add_theme_stylebox_override("panel", cb)
	clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(clip)
	var a := TextureRect.new()
	a.texture = t
	a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	a.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	a.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(a)
	var f := Panel.new()
	var fs := StyleBoxTexture.new()
	fs.texture = tex(frame)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		fs.set_texture_margin(side, 34.0)
	fs.draw_center = false
	f.add_theme_stylebox_override("panel", fs)
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(f)
	return c


## Barra de vida/progresso: trilho escuro com aro dourado, enchimento com brilho em cima (combina com as gemas).
static func bar(col: Color, w: float, h: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.13, 0.085, 0.06, 0.92)
	bg.border_color = GOLD if h >= 10 else Color(GOLD, 0.8)
	# Mapa aberto: trilho de papel mais escuro com contorno de tinta (sem aro dourado).
	bg.bg_color = Color("c9b07c")
	bg.border_color = INK
	bg.set_border_width_all(2 if h >= 12 else 1)
	bg.set_corner_radius_all(int(minf(h * 0.5, 7)))
	bg.anti_aliasing = true
	bg.shadow_color = Color(0, 0, 0, 0.25)
	bg.shadow_size = 2
	bg.shadow_offset = Vector2(0, 1)
	b.add_theme_stylebox_override("background", bg)
	var fs := StyleBoxFlat.new()
	fs.bg_color = col
	fs.border_color = col.lightened(0.35)
	fs.border_width_top = int(maxf(1.0, h * 0.18)) if h >= 8 else 0
	fs.set_corner_radius_all(int(minf(h * 0.5, 7)))
	fs.set_expand_margin_all(-2.0 if h >= 12 else -1.0)
	fs.anti_aliasing = true
	b.add_theme_stylebox_override("fill", fs)
	return b


## Gota de elixir no desenho da gema de custo das cartas: roxa com aro dourado e brilho; vazia = só o contorno
## sobre um fundo de tinta clara. `f` 0..1 enche de baixo para cima.
static func draw_drop(ci: CanvasItem, r: Rect2, f: float, col := ELIXIR) -> void:
	var c := r.get_center() + Vector2(0, r.size.y * 0.12)
	var s := minf(r.size.x * 0.5, r.size.y * 0.4) * 0.95
	var pts := _drop(c, s)
	if f >= 1.0:
		ci.draw_colored_polygon(pts, col.darkened(0.28))
		ci.draw_colored_polygon(_drop(c + Vector2(-s * 0.08, -s * 0.1), s * 0.8), col.lightened(0.06))
		ci.draw_circle(c + Vector2(-s * 0.3, -s * 0.12), s * 0.17, Color(1, 1, 1, 0.55))
	else:
		ci.draw_colored_polygon(pts, Color(0.23, 0.17, 0.12, 0.2))
		if f > 0.0:
			var top := c.y + s - (s * 2.85) * clampf(f, 0.0, 1.0)
			var fill := PackedVector2Array()
			for p in pts:
				fill.append(Vector2(p.x, maxf(p.y, top)))
			ci.draw_colored_polygon(fill, col.lerp(Color(0.6, 0.55, 0.66), 0.4))
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, GOLD if f >= 1.0 else Color(GOLD, 0.55), maxf(1.4, s * 0.15) if f >= 1.0 else 1.3, true)


static func _drop(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var p := c + Vector2(cos(a), sin(a)) * s
		if sin(a) < -0.25:
			var k := (-sin(a) - 0.25) / 0.75
			p.x = lerpf(p.x, c.x, k * 0.82)
			p.y = c.y - s - k * s * 0.85
		pts.append(p)
	return pts
