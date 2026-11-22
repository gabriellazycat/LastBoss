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
const DARK_PAPER := ["veteran", "cursed", "shadowy", "leech"]
const INK_LIGHT := Color(0.227, 0.165, 0.118)
const INK_DARK := Color(0.945, 0.91, 0.84)
const SH_CRACKS := preload("res://game/ui/card_cracks.gdshader")
const SH_BLOTS := preload("res://game/ui/card_blots.gdshader")
const SH_BLOOD := preload("res://game/ui/card_blood.gdshader")
const SH_SWEEP := preload("res://game/ui/card_sweep.gdshader")
const SH_RAYS := preload("res://game/ui/card_rays.gdshader")
const SH_FADE := preload("res://game/ui/card_art_fade.gdshader")
const SH_FLAMES := preload("res://game/ui/card_fuse_flames.gdshader")

static var _tex := {}
static var _fuse_cache := {}
static var _fx_tex := {}
static var _add_mat: CanvasItemMaterial = null
static var _serif: Font = null
static var _serif_bold: Font = null


static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var path := DIR + name + ".png"
		_tex[name] = load(path) if ResourceLoader.exists(path) else null
	return _tex[name]


static func _motion() -> float:
	return clampf(float(Settings.v.get("shake", 1.0)), 0.0, 1.0)


## Níveis IV a VI (metaprogressão): a moldura de ouro (lv3) tingida + brilho/raios próprios.
const LV_ROMAN := ["I", "I", "II", "III", "IV", "V", "VI"]
const LV_TINT := {4: Color(0.78, 0.62, 1.0), 5: Color(1.0, 0.5, 0.45), 6: Color(1.0, 0.97, 0.82)}
const LV_GLOW := {4: Color(0.62, 0.4, 1.0, 0.95), 5: Color(1.0, 0.3, 0.25, 0.95), 6: Color(1.0, 0.95, 0.7, 1.0)}


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
		"leech": return Color(0.3, 0.05, 0.08)
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
			sb.shadow_color = LV_GLOW.get(level, Color(1.0, 0.78, 0.27, 0.92))
			sb.shadow_size = int((24.0 + 4.0 * maxi(level - 3, 0)) * sx)
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
		rm.set_shader_parameter("col", LV_GLOW.get(level, Color(1.0, 0.84, 0.43) if level >= 3 else Color(0.6, 0.8, 1.0)))
		rm.set_shader_parameter("count", 14.0 + 2.0 * maxi(level - 3, 0) if level >= 3 else 18.0)
		rm.set_shader_parameter("speed", 0.12 + 0.03 * maxi(level - 3, 0) if level >= 3 else 0.05)
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
		elif mid == "leech":
			fx_sh = SH_BLOOD
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
		var lvl_frame := _layer("lv%d_%s" % [mini(level, 3), sz], full)
		if LV_TINT.has(level):
			lvl_frame.modulate = LV_TINT[level]
		body.add_child(lvl_frame)
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
		var plaque := _layer("plaque%d" % mini(level, 3), full)
		if LV_TINT.has(level):
			plaque.modulate = LV_TINT[level]
		body.add_child(plaque)
		var num: String = LV_ROMAN[clampi(level, 1, 6)]
		body.add_child(_label(num, UiDiario.font("fell"), 16, Color(0.11, 0.15, 0.2) if level == 2 else Color(0.29, 0.16, 0.02), Rect2(110, DH - 31, 80, 28)))

	# --- nome na fita
	var nm := UiKit.card_name(d, level)
	var fell := UiDiario.font("fell")
	# Na mão (compacta) a carta da frente cobre ~24 unidades da esquerda da seguinte: o nome começa depois dessa faixa
	# (a fonte encolhe para caber), senão a primeira letra some por baixo da vizinha.
	var name_x := 50.0 if compact else 32.0
	var name_w := 212.0 if compact else 236.0
	var fsz := UiCovil.fit_size(fell, nm, 31 if compact else 23, name_w, 12)
	body.add_child(_label(nm, fell, fsz, spec[2], Rect2(name_x, rib_y - 1.0, name_w, rib_h), 0))

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
		_explosive_fx(top, compact, DH, level, mo)
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



# ---------------------------------------------------------------------------------------------------------------------
# Explosiva (13/11/2026): pavio aceso em volta da carta. A borda (cordinha trançada + fio de brasa) é o PNG
# mod_explosive_edge_*; aqui fica o que anda. Por nível da carta:
#   1 = faísca correndo o pavio (loop) com rastro curto de brasa e faisquinhas soltando dela;
#   2 = faísca maior + estouros pequenos (clarão, anel de fumaça e lascas) de tempos em tempos em pontos da borda;
#   3 = tudo isso + chamas lambendo o pé da carta (shader) e um estouro grande periódico com brasas voando.
# Os estouros só caem em pontos da borda longe do custo, da fita do nome e do texto. Com o tremor em zero, só a borda.
# Custo: por carta 1 Line2D de ~20 pontos, 1-3 sprites, 1-3 CPUParticles2D pequenos e 1-3 tweens.

## Pontos do contorno irregular: o mesmo jag(H,3,13,3,9) de tools/art/card_mold/overlays.js (rng xorshift32 da cartas_v4).
static func _fuse_path(dh: float) -> Dictionary:
	if _fuse_cache.has(dh):
		return _fuse_cache[dh]
	var st := [(3 * 2654435761) & 0xFFFFFFFF]
	if st[0] == 0:
		st[0] = 1
	var amp := 13.0
	var b := 3.0
	var hh := int(dh)
	var pts := PackedVector2Array()
	for t in range(0, 301, 9):
		pts.append(Vector2(t, snappedf(b + _rnd(st) * amp, 0.1)))
	for t in range(0, hh + 1, 9):
		pts.append(Vector2(snappedf(300.0 - (b + _rnd(st) * amp), 0.1), t))
	for t in range(300, -1, -9):
		pts.append(Vector2(t, snappedf(dh - (b + _rnd(st) * amp), 0.1)))
	for t in range(hh, -1, -9):
		pts.append(Vector2(snappedf(b + _rnd(st) * amp, 0.1), t))
	pts.append(pts[0])
	var cum := PackedFloat32Array([0.0])
	for i in range(1, pts.size()):
		cum.append(cum[i - 1] + pts[i].distance_to(pts[i - 1]))
	var r := {"pts": pts, "cum": cum, "len": cum[cum.size() - 1]}
	_fuse_cache[dh] = r
	return r


static func _rnd(st: Array) -> float:
	var s: int = st[0]
	s = (s ^ (s << 13)) & 0xFFFFFFFF
	s = s ^ (s >> 17)
	s = (s ^ (s << 5)) & 0xFFFFFFFF
	st[0] = s
	return float(s) / 4294967296.0


## Ponto a uma distância `d` ao longo do pavio (dá a volta).
static func _fuse_at(fp: Dictionary, d: float) -> Vector2:
	var cum: PackedFloat32Array = fp["cum"]
	var pts: PackedVector2Array = fp["pts"]
	d = fposmod(d, fp["len"])
	var i := clampi(cum.bsearch(d), 1, cum.size() - 1)
	var seg := cum[i] - cum[i - 1]
	return pts[i - 1].lerp(pts[i], 0.0 if seg <= 0.0 else (d - cum[i - 1]) / seg)


## Trecho do pavio entre d0 e d1 (d1 > d0), com os vértices do meio: o rastro da faísca.
static func _fuse_span(fp: Dictionary, d0: float, d1: float) -> PackedVector2Array:
	var cum: PackedFloat32Array = fp["cum"]
	var pts: PackedVector2Array = fp["pts"]
	var L: float = fp["len"]
	var out := PackedVector2Array([_fuse_at(fp, d0)])
	var a := fposmod(d0, L)
	var left := d1 - d0
	var i := cum.bsearch(a, false)
	while left > 0.0:
		if i >= cum.size():
			i = 1
			a -= L
		var step := cum[i] - a
		if step >= left:
			break
		left -= step
		a = cum[i]
		out.append(pts[i])
		i += 1
	out.append(_fuse_at(fp, d1))
	return out


## Pontos da borda onde um estouro não cobre custo, nome nem texto (os estouros grandes ficam ainda mais longe).
static func _safe_spots(fp: Dictionary, compact: bool, big: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	var y_max := (220.0 if compact else 150.0) if big else (280.0 if compact else 205.0)
	var pts: PackedVector2Array = fp["pts"]
	for i in range(0, pts.size() - 1, 2):
		var p := pts[i]
		if p.y > y_max or (p.x < 96.0 and p.y < 100.0):   # gema do custo no canto de cima à esquerda
			continue
		if compact and p.x > 220.0 and p.y < 56.0:          # atalho do teclado (mão)
			continue
		out.append(p.lerp(Vector2(150.0, p.y), 0.04))        # um nadinha para dentro
	return out


static func _fx_texture(kind: String) -> Texture2D:
	if _fx_tex.has(kind):
		return _fx_tex[kind]
	var g := Gradient.new()
	match kind:
		"glow":   # clarão da faísca: miolo branco-amarelo, halo laranja
			g.offsets = PackedFloat32Array([0.0, 0.12, 0.35, 1.0])
			g.colors = PackedColorArray([Color(1, 1, 0.92, 1), Color(1, 0.86, 0.45, 0.95), Color(1, 0.45, 0.08, 0.35), Color(1, 0.3, 0.0, 0.0)])
		"dot":    # faisquinha
			g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
			g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
		"ring":   # anel de fumaça (miolo vazio)
			g.offsets = PackedFloat32Array([0.0, 0.36, 0.62, 0.8, 1.0])
			g.colors = PackedColorArray([Color(0.22, 0.18, 0.15, 0), Color(0.22, 0.18, 0.15, 0.1), Color(0.16, 0.12, 0.1, 0.9), Color(0.3, 0.26, 0.23, 0.5), Color(0.4, 0.38, 0.36, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64 if kind != "dot" else 16
	t.height = t.width
	_fx_tex[kind] = t
	return t


static func _additive() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat


static func _sprite(kind: String, add: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _fx_texture(kind)
	if add:
		s.material = _additive()
	return s


## Faíscas/brasas soltas no mundo (local_coords desligado: ficam para trás quando a faísca anda).
static func _embers(amount: int, life: float, v0: float, v1: float, grav: float, s0: float, s1: float, burst: bool) -> CPUParticles2D:
	var pt := CPUParticles2D.new()
	pt.texture = _fx_texture("dot")
	pt.material = _additive()
	pt.amount = amount
	pt.lifetime = life
	pt.local_coords = false
	pt.one_shot = burst
	pt.explosiveness = 1.0 if burst else 0.0
	pt.emitting = not burst
	pt.direction = Vector2(0, -1)
	pt.spread = 180.0
	pt.gravity = Vector2(0, grav)
	pt.initial_velocity_min = v0
	pt.initial_velocity_max = v1
	pt.damping_min = v0 * 0.6
	pt.damping_max = v0 * 1.2
	pt.scale_amount_min = s0
	pt.scale_amount_max = s1
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(1, 0.97, 0.8, 1), Color(1, 0.62, 0.15, 0.95), Color(0.85, 0.2, 0.02, 0)])
	pt.color_ramp = g
	return pt


static func _explosive_fx(top: Control, compact: bool, dh: float, level: int, mo: float) -> void:
	var lv := clampi(level, 1, 3)
	var full := Vector2(300.0, dh)
	# chamas lambendo o pé da carta (nível 3): por baixo da cordinha, quase todas fora da carta
	if lv >= 3:
		var fl := ColorRect.new()
		var fh := 32.0 if compact else 54.0
		fl.position = Vector2(-8.0, dh - (20.0 if compact else 36.0))   # pontas até ~384 (grande) / ~360 (mão): abaixo do texto; na mão só roçam a fita
		fl.size = Vector2(316.0, fh)
		fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var fm := ShaderMaterial.new()
		fm.shader = SH_FLAMES
		fm.set_shader_parameter("motion", mo)
		fm.set_shader_parameter("hole", 0.0 if compact else 0.6)   # vão baixo no meio: a placa "III" fica à mostra
		fm.set_shader_parameter("seed", randf() * 50.0)
		fl.material = fm
		top.add_child(fl)
	var edge := _layer("mod_explosive_edge_" + ("cmp" if compact else "full"), full)
	top.add_child(edge)
	if mo <= 0.0:
		return
	var fp := _fuse_path(dh)
	var L: float = fp["len"]
	var k := 1.35 if compact else 1.0   # na mão a carta é pequena: tudo um pouco maior para ler
	var fx := Node2D.new()
	fx.name = "Fuse"
	top.add_child(fx)

	# --- a faísca: pavio queimado atrás dela (fuligem), rastro de brasa (Line2D afinando), clarão piscando e faisquinhas
	var soot := Line2D.new()
	soot.width = 4.2 * k
	var sg := Gradient.new()
	sg.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	sg.colors = PackedColorArray([Color(0.1, 0.05, 0.02, 0), Color(0.1, 0.05, 0.02, 0.55), Color(0.1, 0.05, 0.02, 0.8)])
	soot.gradient = sg
	soot.joint_mode = Line2D.LINE_JOINT_ROUND
	fx.add_child(soot)
	var trail := Line2D.new()
	trail.width = (4.4 if lv == 1 else 5.8) * k
	var wc := Curve.new()
	wc.add_point(Vector2(0, 0.15))
	wc.add_point(Vector2(1, 1))
	trail.width_curve = wc
	var tg := Gradient.new()
	tg.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	tg.colors = PackedColorArray([Color(1, 0.3, 0.02, 0), Color(1, 0.62, 0.15, 0.85), Color(1, 0.95, 0.7, 1)])
	trail.gradient = tg
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.material = _additive()
	fx.add_child(trail)
	var spark := Node2D.new()
	fx.add_child(spark)
	var glow := _sprite("glow", true)
	var gsc := (0.66 if lv == 1 else 0.95) * k
	glow.scale = Vector2.ONE * gsc
	spark.add_child(glow)
	var core := _sprite("dot", true)
	core.scale = Vector2.ONE * (0.75 if lv == 1 else 1.0) * k
	spark.add_child(core)
	var sp := _embers(12 if lv == 1 else 20, 0.6, 35.0, 85.0 if lv == 1 else 110.0, 80.0, 0.16 * k, (0.3 if lv == 1 else 0.4) * k, false)
	spark.add_child(sp)

	var period := (5.0 if lv == 1 else 4.4) * (L / 1600.0)   # ~7 s por volta no nível 1
	var tail := (60.0 if lv == 1 else 85.0) * k
	var off := randf() * L
	var run := func(d: float) -> void:
		spark.position = _fuse_at(fp, d)
		trail.points = _fuse_span(fp, d - tail, d)
		soot.points = _fuse_span(fp, d - tail * 2.2, d - tail * 0.5)
		var fl := 0.85 + 0.15 * sin(d * 0.9) + 0.1 * sin(d * 2.3)   # tremulada do clarão
		if compact and spark.position.y > dh - 70.0:
			fl *= 0.6   # na mão, a faísca passa rente à fita do nome: clarão menor ali
		glow.scale = Vector2.ONE * gsc * fl
	var tw := fx.create_tween().set_loops()
	tw.tween_method(run, off, off + L, period)
	run.call(off)

	# --- estouros nos pontos seguros da borda (nível 2 e 3)
	if lv >= 2:
		var spots := _safe_spots(fp, compact, false)
		var pop := _pop_node(k, false)
		fx.add_child(pop)
		var tp := pop.create_tween().set_loops()
		tp.tween_interval(0.6 + randf() * 1.6)
		tp.tween_callback(func() -> void: _pop_fire(pop, spots[randi() % spots.size()], false))
		tp.tween_interval(1.5 if lv == 2 else 1.2)
	if lv >= 3:
		var spots_big := _safe_spots(fp, compact, true)
		var boom := _pop_node(k, true)
		fx.add_child(boom)
		var tb := boom.create_tween().set_loops()
		tb.tween_interval(2.4 + randf() * 2.0)
		tb.tween_callback(func() -> void:
			_pop_fire(boom, spots_big[randi() % spots_big.size()], true)
			var te := edge.create_tween()   # a borda inteira acende com o estouro
			te.tween_property(edge, "modulate", Color(1.9, 1.45, 1.05), 0.08)
			te.tween_property(edge, "modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
		tb.tween_interval(2.6)


## Nó de um estouro: clarão (soma), anel de fumaça e lascas de brasa disparadas de uma vez.
static func _pop_node(k: float, big: bool) -> Node2D:
	var n := Node2D.new()
	var ring := _sprite("ring", false)
	ring.name = "Ring"
	ring.modulate.a = 0.0
	n.add_child(ring)
	var flash := _sprite("glow", true)
	flash.name = "Flash"
	flash.modulate.a = 0.0
	n.add_child(flash)
	if big:   # onda de calor larga e laranja por baixo do clarão
		var wave := _sprite("glow", true)
		wave.name = "Wave"
		wave.modulate = Color(1.0, 0.55, 0.2, 0.0)
		n.add_child(wave)
	var e := _embers(32 if big else 14, 1.2 if big else 0.7, 80.0 if big else 55.0, 200.0 if big else 120.0, 110.0 if big else 50.0,
			0.22 * k, (0.55 if big else 0.36) * k, true)
	e.name = "Bits"
	n.add_child(e)
	n.set_meta("k", k)
	return n


static func _pop_fire(n: Node2D, at: Vector2, big: bool) -> void:
	if not is_instance_valid(n):
		return
	var k: float = n.get_meta("k", 1.0)
	n.position = at
	var flash := n.get_node("Flash") as Sprite2D
	var ring := n.get_node("Ring") as Sprite2D
	var bits := n.get_node("Bits") as CPUParticles2D
	# as lascas saem para fora da carta (longe do texto)
	bits.direction = (at - Vector2(150.0, 200.0)).normalized()
	bits.spread = 80.0 if big else 60.0
	bits.restart()
	var s := (2.6 if big else 1.5) * k
	var t := n.create_tween().set_parallel()
	var wave := n.get_node_or_null("Wave") as Sprite2D
	if wave != null:
		wave.scale = Vector2.ONE * s * 0.6
		wave.modulate.a = 0.9
		t.tween_property(wave, "scale", Vector2.ONE * s * 2.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(wave, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flash.scale = Vector2.ONE * s * 0.3
	flash.modulate.a = 1.0
	t.tween_property(flash, "scale", Vector2.ONE * s, 0.12).set_ease(Tween.EASE_OUT)
	t.tween_property(flash, "modulate:a", 0.0, 0.42 if big else 0.32).set_delay(0.1)
	ring.scale = Vector2.ONE * s * 0.35
	ring.modulate.a = 1.0
	t.tween_property(ring, "scale", Vector2.ONE * s * (1.5 if big else 1.15), 1.1 if big else 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(ring, "modulate:a", 0.0, 1.0 if big else 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
