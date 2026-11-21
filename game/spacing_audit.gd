class_name SpacingAudit
extends RefCounted
## Teste de folga da interface (rodada de UI de 20/11/2026): para cada Label, RichTextLabel e Button visível, mede a
## distância entre o retângulo do TEXTO (tamanho real pela fonte, não o do controle) e a borda da caixa que o contém
## (Panel/PanelContainer com fundo, ou o próprio botão), e lista tudo abaixo do mínimo da moldura (UiKit.clean_need).
## Também acusa texto cortado: mais alto/largo que o controle, ou saindo de um ancestral que recorta ou da tela.
## Uso pelo jogo: --spacetest=1 (main.gd, _space_test). Todas as medidas em pixels lógicos da tela.

const CLIP_TOL := 0.5      # texto pode passar disto da borda de um recorte antes de contar como cortado


## Varre `root` e devolve uma lista de problemas: {screen, kind, path, text, gap, need, side}.
## kind: "folga" (perto da borda da caixa), "corte" (texto cortado), "tela" (fora da tela).
static func scan(root: Node, screen: String, view: Rect2) -> Array:
	var out: Array = []
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if not (c is Label or c is RichTextLabel or c is Button):
			continue
		if not c.is_visible_in_tree() or c.size.x < 1.0 or c.size.y < 1.0:
			continue
		if c.has_meta("no_audit") or _faded(c) or _in_subviewport(c):
			continue
		var txt := _text_of(c)
		if txt.strip_edges() == "":
			continue
		var tr_ := text_rect(c)          # no espaço local do controle
		if tr_.size.x <= 0.0:
			continue
		_check_cut(c, tr_, txt, screen, out)
		_check_clips(c, tr_, txt, screen, view, out)
		if _scrolled_partly(c, tr_):
			continue   # item na borda de uma rolagem: o resto dele está rolado para fora, a folga não vale
		_check_box(c, tr_, txt, screen, out)
	return out


## Exceção: papéis da mesa 3D (desk_scene.gd) são texturas coladas em objetos 3D (SubViewport), não tela de interface.
static func _in_subviewport(c: Node) -> bool:
	var p := c.get_parent()
	while p != null:
		if p is SubViewport:
			return true
		p = p.get_parent()
	return false


static func _scrolled_partly(c: Control, r: Rect2) -> bool:
	var cx := c.get_global_transform()
	var p := c.get_parent()
	while p != null and p is Control:
		if p is ScrollContainer:
			var pc := p as Control
			var tb := _bbox(pc.get_global_transform().affine_inverse() * cx, r)
			if not Rect2(Vector2.ZERO, pc.size).encloses(tb):
				return true
		p = p.get_parent()
	return false


static func _faded(c: CanvasItem) -> bool:
	# Texto do leitor sob transição ou de tela que ainda sobe da mesa (transparente) não conta.
	var p: Node = c
	var a := 1.0
	while p != null and p is CanvasItem:
		a *= (p as CanvasItem).modulate.a * (p as CanvasItem).self_modulate.a
		p = p.get_parent()
	return a < 0.3


static func _text_of(c: Control) -> String:
	if c is RichTextLabel:
		return (c as RichTextLabel).get_parsed_text()
	var raw: String = (c as Label).text if c is Label else (c as Button).text
	if c.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED:
		return raw
	return TranslationServer.translate(raw)


static func _path(c: Node) -> String:
	var parts: Array = []
	var p := c
	while p != null and parts.size() < 4 and p.get_parent() != null:
		parts.append(str(p.name))
		p = p.get_parent()
	parts.reverse()
	return "/".join(parts)


## Retângulo do texto no espaço local do controle.
static func text_rect(c: Control) -> Rect2:
	if c is Label:
		var l := c as Label
		var font := l.get_theme_font("font")
		var fs := l.get_theme_font_size("font_size")
		var sbn := l.get_theme_stylebox("normal")
		var ml := sbn.get_margin(SIDE_LEFT) if sbn else 0.0
		var mt := sbn.get_margin(SIDE_TOP) if sbn else 0.0
		var mr := sbn.get_margin(SIDE_RIGHT) if sbn else 0.0
		var mb := sbn.get_margin(SIDE_BOTTOM) if sbn else 0.0
		var avail := Vector2(l.size.x - ml - mr, l.size.y - mt - mb)
		var wrap := l.autowrap_mode != TextServer.AUTOWRAP_OFF
		var flags := TextServer.BREAK_MANDATORY
		if wrap:
			flags |= TextServer.BREAK_WORD_BOUND
			if l.autowrap_mode == TextServer.AUTOWRAP_ARBITRARY:
				flags |= TextServer.BREAK_GRAPHEME_BOUND
		var txt := _text_of(l)
		if l.uppercase:
			txt = txt.to_upper()
		var sz := font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, avail.x if wrap else -1.0, fs, -1, flags)
		var line_h := font.get_height(fs) + float(l.get_theme_constant("line_spacing"))
		if l.max_lines_visible > 0:
			sz.y = minf(sz.y, line_h * l.max_lines_visible)
		var x := 0.0
		match l.horizontal_alignment:
			HORIZONTAL_ALIGNMENT_CENTER:
				x = (avail.x - sz.x) * 0.5
			HORIZONTAL_ALIGNMENT_RIGHT:
				x = avail.x - sz.x
		var y := 0.0
		match l.vertical_alignment:
			VERTICAL_ALIGNMENT_CENTER:
				y = (avail.y - sz.y) * 0.5
			VERTICAL_ALIGNMENT_BOTTOM:
				y = avail.y - sz.y
		var r := Rect2(ml + x, mt + y, sz.x, sz.y)
		return r   # o contorno do texto é suave e vaza para fora sem cortar: _check_clips o soma
	if c is RichTextLabel:
		var t := c as RichTextLabel
		var w := float(t.get_content_width())
		var h := float(t.get_content_height())
		var raw := t.text
		var full := raw.contains("[center]") or raw.contains("[right]") or raw.contains("[fill]")
		if full or w <= 0.0:
			w = t.size.x
		return Rect2(0, 0, minf(w, t.size.x) if not full else t.size.x, h)
	var b := c as Button
	var font2 := b.get_theme_font("font")
	var fs2 := b.get_theme_font_size("font_size")
	var sb := b.get_theme_stylebox("normal")
	var ml2 := sb.get_margin(SIDE_LEFT) if sb else 0.0
	var mr2 := sb.get_margin(SIDE_RIGHT) if sb else 0.0
	var mt2 := sb.get_margin(SIDE_TOP) if sb else 0.0
	var mb2 := sb.get_margin(SIDE_BOTTOM) if sb else 0.0
	var txt2 := _text_of(b)
	var wrap2 := b.autowrap_mode != TextServer.AUTOWRAP_OFF
	var avail_w := b.size.x - ml2 - mr2
	var sz2 := font2.get_multiline_string_size(txt2, HORIZONTAL_ALIGNMENT_LEFT, avail_w if wrap2 else -1.0, fs2, -1,
			TextServer.BREAK_MANDATORY | (TextServer.BREAK_WORD_BOUND if wrap2 else 0))
	var icon_w := 0.0
	if b.icon != null and not b.expand_icon:
		icon_w = b.icon.get_width() + float(b.get_theme_constant("h_separation"))
	var total_w := sz2.x + icon_w
	var x2 := ml2
	match b.alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			x2 = ml2 + (avail_w - total_w) * 0.5
		HORIZONTAL_ALIGNMENT_RIGHT:
			x2 = b.size.x - mr2 - total_w
	var y2 := mt2 + (b.size.y - mt2 - mb2 - sz2.y) * 0.5
	return Rect2(x2 + icon_w, y2, sz2.x, sz2.y)


## Texto mais largo ou mais alto que o próprio controle.
static func _check_cut(c: Control, r: Rect2, txt: String, screen: String, out: Array) -> void:
	var over_x := r.size.x - c.size.x
	var over_y := r.size.y - c.size.y
	if c is Label:
		var l := c as Label
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF or l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			if l.get_line_count() > l.get_visible_line_count():
				out.append({"screen": screen, "kind": "corte", "path": _path(c), "text": txt.left(40), "gap": -over_y, "need": 0.0, "side": "linhas"})
				return
		if l.autowrap_mode == TextServer.AUTOWRAP_OFF and over_x > 1.5:
			out.append({"screen": screen, "kind": "corte", "path": _path(c), "text": txt.left(40), "gap": -over_x, "need": 0.0, "side": "largura"})
	elif c is Button:
		if over_x > 1.5 and (c as Button).clip_text:
			out.append({"screen": screen, "kind": "corte", "path": _path(c), "text": txt.left(40), "gap": -over_x, "need": 0.0, "side": "largura"})


## Texto saindo de um ancestral que recorta (leque, carta, painel) ou da tela. Medido no espaço local de cada recorte
## (cartas do leque estão giradas; o retângulo global de um nó girado não serve).
static func _check_clips(c: Control, r: Rect2, txt: String, screen: String, view: Rect2, out: Array) -> void:
	var o := 0.0
	if c is Label or c is Button:
		o = float(c.get_theme_constant("outline_size")) * 0.5   # o contorno do texto também é desenhado
	var rg := r.grow(o)
	var cx := c.get_global_transform()
	var p: Node = c.get_parent()
	while p != null and p is Control:
		var pc := p as Control
		if pc.clip_contents or pc.clip_children != CanvasItem.CLIP_CHILDREN_DISABLED or pc is ScrollContainer:
			var tb := _bbox(pc.get_global_transform().affine_inverse() * cx, rg)
			var pr := Rect2(Vector2.ZERO, pc.size)
			if pr.size.x > 2.0 and not pr.intersects(tb):
				return   # totalmente fora do recorte: não é desenhado (rolado para fora, carta escondida)
			var d := _outside(tb, pr)
			if d > CLIP_TOL and pr.size.x > 2.0 and not pc is ScrollContainer:
				out.append({"screen": screen, "kind": "corte", "path": _path(c), "text": txt.left(40), "gap": -d, "need": 0.0, "side": "recorte " + str(pc.name)})
				return
		p = p.get_parent()
	var dv := _outside(_bbox(cx, rg), view)
	if dv > CLIP_TOL:
		out.append({"screen": screen, "kind": "tela", "path": _path(c), "text": txt.left(40), "gap": -dv, "need": 0.0, "side": "tela"})


## Caixa que contém o retângulo `r` depois de transformado por `xf`.
static func _bbox(xf: Transform2D, r: Rect2) -> Rect2:
	var q := [xf * r.position, xf * Vector2(r.end.x, r.position.y), xf * r.end, xf * Vector2(r.position.x, r.end.y)]
	var bb := Rect2(q[0], Vector2.ZERO)
	for pt in q:
		bb = bb.expand(pt)
	return bb


## Quanto de `a` passa para fora de `b` (0 se está dentro).
static func _outside(a: Rect2, b: Rect2) -> float:
	return maxf(maxf(b.position.x - a.position.x, a.end.x - b.end.x), maxf(b.position.y - a.position.y, a.end.y - b.end.y))


## A caixa de papel/painel mais próxima acima do controle, e o próprio botão.
static func _check_box(c: Control, r: Rect2, txt: String, screen: String, out: Array) -> void:
	var boxes: Array = []
	if c is Label and not c.has_meta("no_frame_audit"):
		var sbl := c.get_theme_stylebox("normal")   # etiqueta de papel: o fundo é do próprio rótulo
		if _is_box(sbl):
			boxes.append([c, sbl, true])
	if c is Button:
		var sb := c.get_theme_stylebox("normal")
		if _is_box(sb) and not c.has_meta("no_frame_audit"):
			boxes.append([c, sb, true])
	var p: Node = c.get_parent()
	while p != null and p is Control:
		var pc := p as Control
		# Panel (sem "Container") é arte com filhos posicionados à mão (carta, gema): conta só o recorte, não a folga.
		if pc is PanelContainer:
			var sb2 := pc.get_theme_stylebox("panel")
			if _is_box(sb2) and pc.is_visible_in_tree():
				boxes.append([pc, sb2, pc.has_meta("tag")])
				break
		p = p.get_parent()
	for bx in boxes:
		var box: Control = bx[0]
		var sbx: StyleBox = bx[1]
		var need := UiKit.clean_need(sbx, bx[2])
		# Distâncias no espaço local da caixa (vale para telas giradas e encolhidas do Diário).
		var m := box.get_global_transform().affine_inverse() * c.get_global_transform()
		var q := [m * r.position, m * Vector2(r.end.x, r.position.y), m * r.end, m * Vector2(r.position.x, r.end.y)]
		var tb := Rect2(q[0], Vector2.ZERO)
		for pt in q:
			tb = tb.expand(pt)
		var gaps := {"esq": tb.position.x, "topo": tb.position.y, "dir": box.size.x - tb.end.x, "base": box.size.y - tb.end.y}
		for side in gaps:
			var need_s: float = need.x if side in ["esq", "dir"] else need.y
			if gaps[side] < need_s - 0.5:
				out.append({"screen": screen, "kind": "folga", "path": _path(c), "text": txt.left(40), "gap": snappedf(gaps[side], 0.1),
						"need": need_s, "side": side + (" (botão)" if bx[2] else " (" + str(box.name) + ")")})


static func _is_box(sb: StyleBox) -> bool:
	if sb == null or sb is StyleBoxEmpty:
		return false
	if sb is StyleBoxFlat:
		var f := sb as StyleBoxFlat
		return f.draw_center and f.bg_color.a > 0.15 or f.border_width_left + f.border_width_top > 0
	if sb is StyleBoxTexture:
		return (sb as StyleBoxTexture).texture != null
	return true
