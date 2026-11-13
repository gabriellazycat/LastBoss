class_name CardMold
extends RefCounted
## Molde único das cartas (moldura A da cartas_v4, decidida em 12/11/2026): cada carta é o molde + a arte + o texto.
## Arte cheia (decidida em 12/11/2026). Camadas PNG geradas por tools/art/card_mold/render_layers.py (assets/cards/mold/): papel,
## painel de texto, moldura por raridade, fita dobrada do nome por tipo, gema de custo, nível (aço/ouro + placa II/III) e um overlay
## por modificador (a Explosiva ainda tem máscara de silhueta queimada). As partes
## animadas são shaders (rachaduras do Amaldiçoado, manchas do Sombrio, reflexo e raios do nível).
## Desenho em 300x420 (grande) ou 300x380 (mão: só fita e arte); o resultado é escalado para (w, h).
## Ordem das camadas (de baixo para cima): raios, papel, arte, shaders de efeito, moldura, nível, modificadores, placa,
## gema, texto. O modificador manda no visual; o nível só dá brilho, moldura e placa.

const DIR := "res://assets/cards/mold/"
const RAR_NAMES := ["common", "uncommon", "rare", "legendary"]
const DARK_PAPER := ["veteran", "cursed", "shadowy"]
const INK_LIGHT := Color(0.227, 0.165, 0.118)
const INK_DARK := Color(0.945, 0.91, 0.84)
const SH_CRACKS := preload("res://game/ui/card_cracks.gdshader")
const SH_BLOTS := preload("res://game/ui/card_blots.gdshader")
const SH_SWEEP := preload("res://game/ui/card_sweep.gdshader")
const SH_RAYS := preload("res://game/ui/card_rays.gdshader")
const SH_FADE := preload("res://game/ui/card_art_fade.gdshader")

static var _tex := {}
static var _serif: Font = null
static var _serif_bold: Font = null


static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var path := DIR + name + ".png"
		_tex[name] = load(path) if ResourceLoader.exists(path) else null
	return _tex[name]


static func _motion() -> float:
	return clampf(float(Settings.v.get("shake", 1.0)), 0.0, 1.0)


static func _layer(name: String, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.size = size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func _label(text: String, font: Font, size: int, col: Color, rect: Rect2, outline := 0, outline_col := Color.BLACK) -> Label:
	var l := Label.new()
	l.text = text
	l.set_meta("no_ink", true)
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", outline_col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = rect.position
	l.size = rect.size
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _fonts() -> void:
	if _serif != null:
		return
	var base: Font = load(UiDiario.F + "Alegreya-VF.ttf")
	var fv := FontVariation.new()
	fv.base_font = base
	_serif = fv
	var fb := FontVariation.new()
	fb.base_font = base
	fb.variation_embolden = 0.7
	_serif_bold = fb


## Cor do papel (para o fundo atrás das camadas e a sombra): a do primeiro modificador, senão o creme.
static func paper_color(mids: Array) -> Color:
	match mids[0] if mids.size() > 0 else "":
		"cheap": return Color(0.65, 0.86, 0.8)
		"veteran": return Color(0.18, 0.25, 0.46)
		"explosive": return Color(0.78, 0.5, 0.27)
		"cursed": return Color(0.25, 0.1, 0.35)
		"shadowy": return Color(0.1, 0.1, 0.13)
	return Color(0.93, 0.87, 0.72)


static func is_dark(mids: Array) -> bool:
	return mids.size() > 0 and DARK_PAPER.has(mids[0])


## Monta a carta. `compact` = a da mão (arte cheia e fita, sem texto). `mods` são os ids dos modificadores, na ordem em que foram ganhos.
static func build(d: CardDef, cost: int, mods: Array, key: String, w: float, h: float, compact: bool, level: int) -> PanelContainer:
	_fonts()
	var DH := 380.0 if compact else 420.0
	var sz := "cmp" if compact else "full"
	var sx := w / 300.0
	var sy := h / DH
	var mo := _motion()
	var dark := is_dark(mods)
	var burnt := mods.has("explosive") and tex("mod_explosive_mask_" + sz) != null
	var rib_y := 318.0 if compact else 250.0                     # fita do nome (medida nos PNGs)
	var rib_h := 50.0 if compact else 38.0
	var art_h := 380.0 if compact else 310.0                     # arte cheia: carta toda na mão, até o painel na grande
	var type_id: String = d.type if tex("ribbon_%s_%s" % [d.type, sz]) != null else "monster"
	var rar: String = RAR_NAMES[clampi(d.rarity, 0, 3)]
	var spec := UiDiario.type_spec(d)
	var paper: String = mods[0] if mods.size() > 0 else "none"

	# --- painel raiz: sombra e brilho do nível (a carta queimada tem silhueta irregular, então fica sem sombra retangular)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0) if burnt else paper_color(mods)
	sb.set_corner_radius_all(int(10.0 * sx))
	if not burnt:
		sb.shadow_color = Color(0, 0, 0, 0.55)
		sb.shadow_size = maxi(int(8.0 * sx), 3)
		sb.shadow_offset = Vector2(0, 3.0 * sx)
		if level == 2:
			sb.shadow_color = Color(0.55, 0.78, 1.0, 0.8)
			sb.shadow_size = int(20.0 * sx)
			sb.shadow_offset = Vector2.ZERO
		elif level >= 3:
			sb.shadow_color = Color(1.0, 0.78, 0.27, 0.92)
			sb.shadow_size = int(24.0 * sx)
			sb.shadow_offset = Vector2.ZERO
	# O fundo colorido (cor do papel do modificador) e a sombra/brilho do nível ficam num Panel do tamanho exato da carta.
	# Antes eram o estilo do próprio PanelContainer: quando um contêiner esticava a carta (oferta com o rótulo de cima
	# mais largo que ela, loja), o fundo esticava junto e aparecia ao lado da carta como "outra carta de outra cor por
	# trás" (bug relatado em 12/11/2026, rodada de UI 13/11/2026). A raiz agora não desenha nada e não estica.
	p.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	p.custom_minimum_size = Vector2(w, h)
	p.size = p.custom_minimum_size
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.set_meta("mold", true)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(w, h)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(holder)
	var base := Panel.new()
	base.name = "Base"
	base.add_theme_stylebox_override("panel", sb)
	base.position = Vector2.ZERO
	base.size = Vector2(w, h)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(base)
	var full := Vector2(300.0, DH)

	# --- atrás da carta: raios girando (só carta grande, nível 2 e 3)
	var back := _scaled(Vector2(sx, sy), full)
	holder.add_child(back)
	if not compact and level >= 2 and not burnt:
		var rays := ColorRect.new()
		rays.position = Vector2(-110, -50)
		rays.size = Vector2(520, 520)
		rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rm := ShaderMaterial.new()
		rm.shader = SH_RAYS
		rm.set_shader_parameter("col", Color(1.0, 0.84, 0.43) if level >= 3 else Color(0.6, 0.8, 1.0))
		rm.set_shader_parameter("count", 14.0 if level >= 3 else 18.0)
		rm.set_shader_parameter("speed", 0.12 if level >= 3 else 0.05)
		rm.set_shader_parameter("motion", mo)
		rays.material = rm
		back.add_child(rays)

	# --- recorte da carta: cantos redondos ou, na Explosiva, a silhueta queimada irregular
	var clipper: Control
	if burnt:
		var tr := TextureRect.new()
		tr.texture = tex("mod_explosive_mask_" + sz)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		clipper = tr
	else:
		var pn := Panel.new()
		var cb := StyleBoxFlat.new()
		cb.bg_color = Color.WHITE
		cb.set_corner_radius_all(int(10.0 * sx))
		pn.add_theme_stylebox_override("panel", cb)
		clipper = pn
	clipper.size = Vector2(w, h)
	clipper.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	clipper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(clipper)
	var body := _scaled(Vector2(sx, sy), full)
	clipper.add_child(body)

	# --- papel (tingido pelo primeiro modificador) e a arte cheia
	body.add_child(_layer("paper_%s_%s" % [paper, sz], full))
	var art := TextureRect.new()
	art.texture = UiDiario.card_tex(d.id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.size = Vector2(300.0, art_h)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var am := ShaderMaterial.new()
	am.shader = SH_FADE
	am.set_shader_parameter("fade_from", 2.0 if compact else 0.82)
	am.set_shader_parameter("rect_h", art_h)
	art.material = am
	body.add_child(art)

	# --- efeitos animados dos modificadores (sobre a arte, sempre abaixo do painel, da moldura e da fita)
	for mid in mods:
		var fx_sh: Shader = null
		if mid == "cursed":
			fx_sh = SH_CRACKS
		elif mid == "shadowy":
			fx_sh = SH_BLOTS
		if fx_sh == null:
			continue
		var fx := ColorRect.new()
		fx.position = Vector2(6, 6)
		fx.size = Vector2(288, (310.0 if compact else 256.0))
		fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = fx_sh
		m.set_shader_parameter("motion", mo)
		m.set_shader_parameter("scale", Vector2(4.0, 4.0 * fx.size.y / fx.size.x))
		fx.material = m
		body.add_child(fx)

	# --- painel de texto (só na grande), moldura, fita do nome na cor do tipo
	if not compact:
		body.add_child(_layer("panel_%s_full" % paper, full))
	body.add_child(_layer("frame_%s_%s" % [rar, sz], full))
	body.add_child(_layer("ribbon_%s_%s" % [type_id, sz], full))
	# --- nível: moldura de aço (2) ou ouro (3); depois os modificadores por cima (o queimado, por exemplo, se sobressai)
	if level >= 2:
		body.add_child(_layer("lv%d_%s" % [mini(level, 3), sz], full))
	for mid in mods:
		var ov := _layer("mod_%s_%s" % [mid, sz], full)
		if ov.texture != null:
			body.add_child(ov)
	if level >= 3:
		var sw := ColorRect.new()
		sw.size = full
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var swm := ShaderMaterial.new()
		swm.shader = SH_SWEEP
		swm.set_shader_parameter("motion", mo)
		sw.material = swm
		body.add_child(sw)
	if level >= 2 and not compact:   # na mão a placa taparia o nome; o nível já aparece na moldura e no "+"
		body.add_child(_layer("plaque%d" % mini(level, 3), full))
		var num := "II" if level == 2 else "III"
		body.add_child(_label(num, UiDiario.font("fell"), 16, Color(0.11, 0.15, 0.2) if level == 2 else Color(0.29, 0.16, 0.02), Rect2(110, DH - 31, 80, 28)))

	# --- nome na fita
	var nm := UiKit.card_name(d, level)
	var fell := UiDiario.font("fell")
	var fsz := UiCovil.fit_size(fell, nm, 31 if compact else 23, 236.0, 14)
	body.add_child(_label(nm, fell, fsz, spec[2], Rect2(32, rib_y - 1.0, 236, rib_h), 0))

	# --- tipo e raridade, e o texto (só carta grande)
	if not compact:
		var tl := _label("%s · %s" % [UiKit.type_line(d), TranslationServer.translate("RARITY_" + rar)], UiDiario.font("fell_it"), 15,
				Color(0.78, 0.8, 0.88) if dark else Color(0.43, 0.31, 0.22), Rect2(20, 292, 260, 22))
		body.add_child(tl)
		body.add_child(_rules(d, level, mods, dark, Rect2(24, 316, 252, 80)))

	# --- atalho do teclado
	if key != "":
		var kt := UiDiario._key_tag(key, 1.0 if not compact else 2.2)
		# Na mão o atalho ia em cima da fita e cobria a 1ª letra do nome ("◆Rei dos Ratos"): agora no canto de cima à direita.
		kt.position = Vector2(36, DH - 24.0) if not compact else Vector2(300.0 - 50.0, 12.0)
		body.add_child(kt)

	# --- por cima do recorte: borda de brasa da Explosiva, gema de custo e brilho do nível
	var top := _scaled(Vector2(sx, sy), full)
	holder.add_child(top)
	if burnt:
		top.add_child(_layer("mod_explosive_edge_" + sz, full))
	var gs := Vector2(84, 96) if compact else Vector2(68, 78)
	var cheaper := cost < d.cost
	var gem := Control.new()
	gem.name = "Gem"
	gem.position = Vector2(-16, -16) if compact else Vector2(-14, -14)
	gem.size = gs
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gem.add_child(_layer("gem_%s_%s" % [rar, "teal" if cheaper else "purple"], gs))
	var gk := gs.x / 68.0
	var cl := _label(str(cost), UiDiario.font("fell"), int((34.0 if cost < 10 else 26.0) * gk), Color(1.0, 0.965, 0.89),
			Rect2(gs.x * 0.1, gs.y * 0.34, gs.x * 0.8, gs.y * 0.5), int(4.0 * gk), Color(0.14, 0.03, 0.24))
	cl.name = "Cost"
	gem.add_child(cl)
	top.add_child(gem)
	if cheaper:
		var old := RichTextLabel.new()
		old.bbcode_enabled = true
		old.fit_content = true
		old.scroll_active = false
		old.autowrap_mode = TextServer.AUTOWRAP_OFF
		old.set_meta("no_ink", true)
		old.text = "[s]%d[/s]" % d.cost
		old.add_theme_font_override("normal_font", UiDiario.font("fell"))
		old.add_theme_font_size_override("normal_font_size", int(20.0 * gk))
		old.add_theme_color_override("default_color", Color(1, 1, 1, 0.92))
		old.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		old.add_theme_constant_override("outline_size", 4)
		old.position = gem.position + Vector2(gs.x - 6.0, 4.0)
		old.size = Vector2(36, 24)
		old.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(old)
	if not compact and level >= 2 and mo > 0.0:
		top.add_child(_dust(level >= 3, DH))

	# --- seleção (a mão liga e desliga)
	var hot := Panel.new()
	hot.name = "Hot"
	var hb := StyleBoxFlat.new()
	hb.bg_color = Color(0, 0, 0, 0)
	hb.set_border_width_all(maxi(int(3.0 * sx), 2))
	hb.border_color = Color(1.0, 0.86, 0.45)
	hb.set_corner_radius_all(int(10.0 * sx))
	# Sem sombra: num StyleBoxFlat de fundo transparente ela pinta o interior da carta de amarelo.
	hot.add_theme_stylebox_override("panel", hb)
	hot.clip_contents = true
	var shine := Polygon2D.new()
	shine.name = "Shine"
	shine.color = Color(1, 1, 1, 0.38)
	shine.visible = false
	hot.add_child(shine)
	hot.position = Vector2.ZERO
	hot.size = Vector2(w, h)
	hot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hot.visible = false
	holder.add_child(hot)
	UiKit.ignore_mouse(p)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Contêiner de camadas desenhado em 300xH e escalado para o tamanho da carta (não é um Container: o tamanho fica livre).
static func _scaled(sc: Vector2, design: Vector2) -> Control:
	var c := Control.new()
	c.size = design
	c.scale = sc
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Texto da carta no papel: o maior tamanho (18 a 12) em que cabe no retângulo.
static func _rules(d: CardDef, level: int, mods: Array, dark: bool, rect: Rect2) -> Control:
	var col := INK_DARK if dark else INK_LIGHT
	var plain := Tips.plain(UiKit.card_desc(d, level, true, mods))
	var size := 12
	for s in [18, 17, 16, 15, 14, 13]:
		var ext := _serif.get_multiline_string_size(plain, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, s)
		if ext.y * 1.0 <= rect.size.y:
			size = s
			break
	var desc := UiKit.card_rich(d, size, col, rect.size.x, true, level, mods)
	desc.set_meta("no_ink", true)
	if dark:
		desc.text = _lift_colors(desc.text)
	desc.add_theme_font_override("normal_font", _serif)
	desc.add_theme_font_override("bold_font", _serif_bold)
	desc.add_theme_constant_override("outline_size", 0)
	desc.add_theme_constant_override("line_separation", -1)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cc := CenterContainer.new()
	cc.position = rect.position
	cc.size = rect.size
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(desc)
	return cc


## Em papel escuro, as cores escuras das palavras-chave (vermelho, azul) viram claras para dar leitura.
static func _lift_colors(t: String) -> String:
	var re := RegEx.new()
	re.compile("\\[color=(#?[0-9a-fA-F]{6})\\]")
	var ms := re.search_all(t)
	ms.reverse()
	for m in ms:
		var c := Color.html(m.get_string(1))
		if c.get_luminance() < 0.5:
			c = c.lightened(0.6)
			t = t.substr(0, m.get_start()) + "[color=#%s]" % c.to_html(false) + t.substr(m.get_end())
	return t


static func _dust(gold: bool, dh: float) -> CPUParticles2D:
	var pt := CPUParticles2D.new()
	pt.position = Vector2(150, dh * 0.62)
	pt.amount = 16
	pt.lifetime = 3.2
	pt.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pt.emission_rect_extents = Vector2(140, 150)
	pt.direction = Vector2(0, -1)
	pt.spread = 12.0
	pt.gravity = Vector2.ZERO
	pt.initial_velocity_min = 14.0
	pt.initial_velocity_max = 26.0
	pt.scale_amount_min = 1.8
	pt.scale_amount_max = 3.4
	var g := Gradient.new()
	var c := Color(1.0, 0.86, 0.45) if gold else Color(0.78, 0.9, 1.0)
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.add_point(0.25, Color(c.r, c.g, c.b, 1.0))
	g.set_color(g.get_point_count() - 1, Color(c.r, c.g, c.b, 0.0))
	pt.color_ramp = g
	pt.emitting = true
	return pt


## Liga/desliga o brilho de seleção da carta montada no molde.
static func set_hot(p: Control, on: bool) -> void:
	var h := p.find_child("Hot", true, false)
	if h == null or h.visible == on:
		return  # a mão chama isto todo quadro: só reage à mudança
	h.visible = on
	var s := h.get_node_or_null("Shine") as Polygon2D
	if s == null:
		return
	if s.has_meta("tw"):
		var old: Tween = s.get_meta("tw")
		if old and old.is_valid():
			old.kill()
		s.remove_meta("tw")
	s.visible = on
	if not on:
		return
	# Reflexo: faixa inclinada que atravessa a carta e repete (parado quando o tremor está em zero).
	var sz: Vector2 = (h as Control).size
	var bw := sz.x * 0.22
	var sk := sz.y * 0.3
	s.polygon = PackedVector2Array([Vector2(sk, 0), Vector2(sk + bw, 0), Vector2(bw, sz.y), Vector2(0, sz.y)])
	s.position = Vector2(-bw - sk, 0)
	var tw := s.create_tween().set_loops()
	tw.tween_property(s, "position:x", sz.x + 4.0, 0.9).from(-bw - sk).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.7)
	s.set_meta("tw", tw)
