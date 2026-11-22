class_name MetaTreeView
extends Control
## Árvore radial do Covil (plano de metaprogressão, 21/11/2026). Lê data/meta_tree.json (GameData.meta_tree/meta_nodes) e
## o MetaSave v5 (node_level, can_buy, buy, refund). Cada setor é uma fatia da roda (a partir do topo, sentido horário);
## a profundidade (cadeia de pais) é o raio; sub-ramos (`branch`) viram faixas lado a lado dentro da fatia.
## Arrastar com o botão esquerdo ou do meio, roda do mouse para o zoom (nunca mexe no ponteiro).
## Sinais: node_hovered(id) ("" ao sair), node_clicked(id) ("" = clique no vazio), changed (compra/reembolso).
## O layout é estático (compute_layout) e não depende do tamanho da tela: o teste usa direto.

signal node_hovered(id: String)
signal node_clicked(id: String)
signal changed

const NODE_R := 30.0        # raio do nó (unidades do mundo)
const SPACING := 82.0       # distância mínima entre centros de nós vizinhos no mesmo raio
const R0 := 185.0           # raio do primeiro nível
const STEP := 128.0         # distância entre níveis
const HEART_R := 64.0
const GAP := 0.07           # folga entre setores (rad)
const ZMIN := 0.28
const ZMAX := 2.6
const ICONS := "res://assets/ui/meta/"
const SEC_COLORS := {
	"atributos": Color("7a4fd0"), "locais": Color("2f6b2a"), "arena": Color("a8323a"),
	"reliquias": Color("c08a2e"), "troca_ato": Color("2f5f8f"), "geral": Color("7a5a3a"),
}

var data: GameData
var meta: MetaSave
var act2_reached := false
var positions: Dictionary = {}     # id -> Vector2 (mundo, centro da roda em 0,0)
var wedges: Array = []             # [{id, a0, a1}]
var max_r := 400.0
var depths: Dictionary = {}
var rings: Array = []
var pan := Vector2.ZERO
var zoom := 0.6
var hovered := ""
var selected := ""
var _drag := false
var _moved := false
var _btn := 0
var _press := Vector2.ZERO
var _fit_pending := true
var _icon_cache: Dictionary = {}


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var lay := compute_layout(data.meta_tree)
	positions = lay["pos"]
	wedges = lay["wedges"]
	max_r = lay["max_r"]
	depths = lay["depth"]
	rings = lay["rings"]
	_fit_pending = true
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _fit_pending and size.x > 8:
		fit()
	elif what == NOTIFICATION_MOUSE_EXIT and hovered != "" and not _drag:
		hovered = ""
		node_hovered.emit("")
		queue_redraw()


# ---------------------------------------------------------------- layout (estático)

static func _depth(id: String, by_id: Dictionary, guard := 0) -> int:
	var p := str(by_id[id].get("parent", ""))
	if p == "" or not by_id.has(p) or guard > 24:
		return 1
	return 1 + _depth(p, by_id, guard + 1)


## Posições polares da árvore. Devolve {pos: {id: Vector2}, wedges: [{id, a0, a1}], max_r, depth: {id: int}}.
static func compute_layout(tree: Dictionary) -> Dictionary:
	var sectors: Array = tree.get("sectors", [])
	var by_id := {}
	for n in tree.get("nodes", []):
		by_id[str(n["id"])] = n
	var depth := {}
	var lanes := {}      # setor -> [chaves de faixa na ordem de aparição]
	var groups := {}     # "setor|faixa|prof" -> [ids]
	for id in by_id:
		depth[id] = _depth(id, by_id)
	for n in tree.get("nodes", []):
		var id := str(n["id"])
		var sec := str(n.get("sector", ""))
		var lane := str(n.get("branch", ""))
		if not lanes.has(sec):
			lanes[sec] = []
		if not lanes[sec].has(lane):
			lanes[sec].append(lane)
		var key := "%s|%s|%d" % [sec, lane, depth[id]]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(id)
	# Escala do primeiro raio: cresce até a roda inteira caber em 360 graus.
	var s := 1.0
	var widths := {}
	var total := 0.0
	while true:
		widths = _lane_widths(sectors, lanes, groups, s)
		total = 0.0
		for sec in sectors:
			total += widths[str(sec["id"])]["total"] + GAP
		if total <= TAU or s > 8.0:
			break
		s += 0.04
	var slack := maxf(0.0, TAU - total) / maxf(1.0, float(sectors.size()))
	var pos := {}
	var wedge_list: Array = []
	var a := -PI * 0.5
	var maxr := R0 * s
	for sec in sectors:
		var sid := str(sec["id"])
		var w: Dictionary = widths[sid]
		var span: float = float(w["total"]) + slack
		var a0 := a + GAP * 0.5
		var cursor: float = a0 + (span - float(w["total"])) * 0.5
		for lane in lanes.get(sid, []):
			var lw: float = w["lanes"][lane]
			var ac: float = cursor + lw * 0.5
			for d in range(1, 12):
				var key := "%s|%s|%d" % [sid, lane, d]
				if not groups.has(key):
					continue
				var g: Array = groups[key]
				var r := R0 * s + (d - 1) * STEP
				maxr = maxf(maxr, r)
				for i in g.size():
					var ang: float = ac + (float(i) - (g.size() - 1) * 0.5) * SPACING / r
					pos[g[i]] = Vector2(cos(ang), sin(ang)) * r
			cursor += lw
		wedge_list.append({"id": sid, "a0": a0, "a1": a0 + span})
		a += span + GAP
	var rings: Array = []
	for id in pos:
		var rr := snappedf((pos[id] as Vector2).length(), 0.5)
		if not rings.has(rr):
			rings.append(rr)
	return {"pos": pos, "wedges": wedge_list, "max_r": maxr + 96.0, "depth": depth, "rings": rings}


static func _lane_widths(sectors: Array, lanes: Dictionary, groups: Dictionary, s: float) -> Dictionary:
	var out := {}
	for sec in sectors:
		var sid := str(sec["id"])
		var lw := {}
		var tot := 0.0
		for lane in lanes.get(sid, []):
			var w := SPACING / (R0 * s)
			for d in range(1, 12):
				var key := "%s|%s|%d" % [sid, lane, d]
				if groups.has(key):
					w = maxf(w, groups[key].size() * SPACING / (R0 * s + (d - 1) * STEP))
			lw[lane] = w
			tot += w
		tot = maxf(tot, 0.5)
		out[sid] = {"lanes": lw, "total": tot}
	return out


# ---------------------------------------------------------------- estado dos nós

func sector_locked(sid: String) -> bool:
	for s in data.meta_tree.get("sectors", []):
		if str(s["id"]) == sid:
			return str(s.get("locked_until", "")) == "act2_reached" and not act2_reached
	return false


func node_sector(id: String) -> String:
	return str(data.meta_nodes[id].get("sector", ""))


## "sealed" (setor trancado), "max", "bought" (nível 1+, ainda há nível), "available", "locked" (falta o pai).
func state_of(id: String) -> String:
	var n: Dictionary = data.meta_nodes[id]
	if sector_locked(str(n.get("sector", ""))):
		return "sealed"
	var lv := meta.node_level(id)
	if lv >= (n["costs"] as Array).size():
		return "max"
	if lv >= 1:
		return "bought"
	var p := str(n.get("parent", ""))
	if p == "" or meta.node_level(p) >= 1:
		return "available"
	return "locked"


func can_buy(id: String) -> bool:
	return data.meta_nodes.has(id) and not sector_locked(node_sector(id)) and meta.can_buy(id)


func can_refund(id: String) -> bool:
	var lv := meta.node_level(id)
	if lv <= 0 or sector_locked(node_sector(id)):
		return false
	if lv == 1:
		for k in meta.upgrades:
			if str(data.meta_nodes.get(k, {}).get("parent", "")) == id and int(meta.upgrades[k]) > 0:
				return false
	return true


func buy_node(id: String) -> bool:
	if not can_buy(id):
		return false
	meta.buy(id)
	changed.emit()
	queue_redraw()
	return true


func refund_node(id: String) -> int:
	if not can_refund(id):
		return 0
	var back := meta.refund(id)
	changed.emit()
	queue_redraw()
	return back


func refresh() -> void:
	queue_redraw()


# ---------------------------------------------------------------- textos

func node_name(id: String) -> String:
	var n: Dictionary = data.meta_nodes.get(id, {})
	if n.has("name"):
		return str(n["name"])
	var key := str(n.get("name_key", "META_" + id))
	var t := tr(key)
	return t if t != key else id.replace("_", " ")


func node_desc(id: String) -> String:
	var n: Dictionary = data.meta_nodes.get(id, {})
	if n.has("desc"):
		return str(n["desc"])
	var key := str(n.get("desc_key", "META_%s_d" % id))
	var t := tr(key)
	return t if t != key else ""


func sector_name(sid: String) -> String:
	for s in data.meta_tree.get("sectors", []):
		if str(s["id"]) == sid:
			var key := str(s.get("name_key", "META_SEC_" + sid))
			var t := tr(key)
			return t if t != key else sid.capitalize()
	return sid


## Valor do efeito `path` do nó no nível `lv` ("" se lv = 0).
static func _fx_val(arr: Array, lv: int) -> String:
	if lv <= 0 or arr.is_empty():
		return "-"
	var v: float = float(arr[mini(lv, arr.size()) - 1])
	return ("%+d" % int(v)) if is_equal_approx(v, round(v)) else ("%+.2f" % v)


## Linhas "caminho: agora → próximo" do nó (o texto técnico serve quando falta a descrição traduzida).
func fx_lines(id: String) -> Array:
	var n: Dictionary = data.meta_nodes.get(id, {})
	var lv := meta.node_level(id)
	var mx: int = (n.get("costs", []) as Array).size()
	var out: Array = []
	for path in n.get("fx", {}):
		var arr: Array = n["fx"][path]
		var line := "%s  %s" % [path, _fx_val(arr, lv)]
		if lv < mx:
			line += "  →  " + _fx_val(arr, lv + 1)
		out.append(line)
	return out


# ---------------------------------------------------------------- câmera

func _w2s(p: Vector2) -> Vector2:
	return size * 0.5 + pan + p * zoom


func fit() -> void:
	_fit_pending = false
	zoom = clampf(minf(size.x, size.y) / (2.0 * max_r) * 1.02, ZMIN, ZMAX)
	pan = Vector2.ZERO
	queue_redraw()


func center_on(world: Vector2, z: float) -> void:
	zoom = clampf(z, ZMIN, ZMAX)
	pan = -world * zoom
	_clamp_pan()
	queue_redraw()


func focus_sector(sid: String, z := 1.0) -> void:
	for w in wedges:
		if str(w["id"]) == sid:
			var am := (float(w["a0"]) + float(w["a1"])) * 0.5
			var rs: Array = []
			for id in positions:
				if node_sector(id) == sid:
					rs.append((positions[id] as Vector2).length())
			var r := 0.0
			for x in rs:
				r += x
			r = r / maxf(1.0, float(rs.size()))
			center_on(Vector2(cos(am), sin(am)) * r, z)
			return


func _clamp_pan() -> void:
	var lim := max_r * zoom
	pan = Vector2(clampf(pan.x, -lim, lim), clampf(pan.y, -lim, lim))


func _zoom_at(p: Vector2, f: float) -> void:
	var nz := clampf(zoom * f, ZMIN, ZMAX)
	if is_equal_approx(nz, zoom):
		return
	var w := (p - size * 0.5 - pan) / zoom
	zoom = nz
	pan = p - size * 0.5 - w * zoom
	_clamp_pan()
	queue_redraw()


func node_at(p: Vector2) -> String:
	var best := ""
	var bd := 1e9
	for id in positions:
		var d := (_w2s(positions[id]) - p).length()
		if d <= NODE_R * zoom + 4.0 and d < bd:
			bd = d
			best = id
	return best


## Seleciona um nó por código (capturas e testes): abre a janela de detalhe como o clique.
func select(id: String) -> void:
	selected = id
	node_clicked.emit(id)
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_at(mb.position, 1.14)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_at(mb.position, 1.0 / 1.14)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_drag = true
				_moved = false
				_btn = mb.button_index
				_press = mb.position
			elif _drag:
				_drag = false
				if not _moved and _btn == MOUSE_BUTTON_LEFT:
					selected = node_at(mb.position)
					node_clicked.emit(selected)
					queue_redraw()
			accept_event()
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if _drag:
			if not _moved and (mm.position - _press).length() > 6.0:
				_moved = true
			if _moved:
				pan += mm.relative
				_clamp_pan()
				queue_redraw()
		else:
			var h := node_at(mm.position)
			if h != hovered:
				hovered = h
				node_hovered.emit(h)
				queue_redraw()


# ---------------------------------------------------------------- desenho

func _icon(name: String) -> Texture2D:
	if not _icon_cache.has(name):
		var p := ICONS + name + ".svg"
		_icon_cache[name] = load(p) if name != "" and ResourceLoader.exists(p) else null
	return _icon_cache[name]


func _arc_pts(c: Vector2, r: float, a0: float, a1: float) -> PackedVector2Array:
	var n := maxi(6, int(absf(a1 - a0) * 18.0))
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := a0 + (a1 - a0) * float(i) / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _dashed_ring(c: Vector2, r: float, col: Color, w: float) -> void:
	var n := 16
	for i in n:
		var a := TAU * i / n
		draw_arc(c, r, a, a + TAU / n * 0.55, 6, col, w, true)


func _draw() -> void:
	if data == null or meta == null:
		return
	var c := size * 0.5 + pan
	var z := zoom
	var fb := UiParch.font("bold")
	var ft := UiParch.font("title")
	# Fatias.
	for i in wedges.size():
		var w: Dictionary = wedges[i]
		var sid := str(w["id"])
		var col: Color = SEC_COLORS.get(sid, UiParch.INK_SOFT)
		var pts := PackedVector2Array([c])
		pts.append_array(_arc_pts(c, max_r * z, w["a0"], w["a1"]))
		draw_colored_polygon(pts, Color(col, 0.13 if sector_locked(sid) else 0.07))
		draw_polyline(_arc_pts(c, max_r * z, w["a0"], w["a1"]), Color(col, 0.55), 2.0, true)
		for a in [w["a0"], w["a1"]]:
			draw_line(c, c + Vector2(cos(a), sin(a)) * max_r * z, Color(col, 0.25), 1.2, true)
	# Anéis de profundidade.
	for rr in rings:
		draw_arc(c, float(rr) * z, 0, TAU, 96, Color(UiParch.INK, 0.12), 1.0, true)
	# Arestas.
	for id in positions:
		var n: Dictionary = data.meta_nodes[id]
		var p := str(n.get("parent", ""))
		var a := _w2s(positions[p]) if (p != "" and positions.has(p)) else c
		var b := _w2s(positions[id])
		var st := state_of(id)
		var lv := meta.node_level(id)
		if lv >= 1:
			draw_line(a, b, UiParch.INK, maxf(2.5, 4.0 * z), true)
		elif st == "available":
			draw_line(a, b, Color(UiParch.BLOOD, 0.85), maxf(1.8, 3.0 * z), true)
		else:
			draw_dashed_line(a, b, Color(UiParch.INK_SOFT, 0.5), maxf(1.4, 2.0 * z), 9.0 * z + 3.0, true)
	# Coração do covil.
	var hr := HEART_R * z
	draw_circle(c, hr + 5.0 * z, Color(UiParch.INK, 0.9))
	draw_circle(c, hr, UiParch.PARCH_DARK)
	var ht := _icon("heart")
	if ht:
		draw_texture_rect(ht, Rect2(c - Vector2(hr, hr) * 0.78, Vector2(hr, hr) * 1.56), false)
	draw_arc(c, hr, 0, TAU, 64, UiParch.GOLD, maxf(2.0, 3.5 * z), true)
	if z >= 0.45:
		_label(fb, c + Vector2(0, hr + 22.0 * z), tr("UI_COVIL_CENTER"), int(clampf(18.0 * z, 11, 26)), UiParch.BLOOD, 260.0)
	# Rótulos dos setores.
	for w in wedges:
		var sid := str(w["id"])
		var am := (float(w["a0"]) + float(w["a1"])) * 0.5
		var rr := (max_r - 40.0) * z
		var lp := c + Vector2(cos(am), sin(am)) * rr
		var col: Color = SEC_COLORS.get(sid, UiParch.INK).darkened(0.25)
		var fs := int(clampf(24.0 * z, 13, 34))
		_label(ft, lp, sector_name(sid), fs, col, 300.0)
		if sector_locked(sid):
			var lt := _icon("lock")
			if lt:
				draw_texture_rect(lt, Rect2(lp + Vector2(-16, 8), Vector2(32, 32)) if z > 0.4 else Rect2(lp, Vector2.ZERO), false)
			_label(fb, lp + Vector2(0, 54), tr("UI_COVIL_SEALED"), int(clampf(17.0 * z, 11, 24)), UiParch.BLOOD, 300.0)
	# Nós (o destacado por cima).
	for id in positions:
		if id != selected and id != hovered:
			_draw_node(id, fb)
	for id in [selected, hovered]:
		if id != "" and positions.has(id):
			_draw_node(id, fb)


func _label(f: Font, p: Vector2, t: String, fs: int, col: Color, w: float) -> void:
	var pos := Vector2(p.x - w * 0.5, p.y)
	draw_string_outline(f, pos, t, HORIZONTAL_ALIGNMENT_CENTER, w, fs, 6, Color(UiParch.PARCH, 0.9))
	draw_string(f, pos, t, HORIZONTAL_ALIGNMENT_CENTER, w, fs, col)


func _draw_node(id: String, fb: Font) -> void:
	var n: Dictionary = data.meta_nodes[id]
	var st := state_of(id)
	var c := _w2s(positions[id])
	var hot := id == hovered or id == selected
	var r := NODE_R * zoom * (1.12 if hot else 1.0)
	if c.x < -80 or c.y < -80 or c.x > size.x + 80 or c.y > size.y + 80:
		return
	var fill := UiParch.PARCH
	var ring := UiParch.BLOOD
	var rw := maxf(2.0, 3.2 * zoom)
	var mod := Color.WHITE
	match st:
		"bought", "max":
			fill = Color("d9a640") if st == "max" else Color("e9c46a")
			ring = UiParch.INK
			rw = maxf(2.5, 4.0 * zoom)
		"available":
			fill = UiParch.CREAM
		"locked", "sealed":
			fill = Color(UiParch.PARCH_DARK, 0.75)
			ring = UiParch.INK_SOFT
			mod = Color(1, 1, 1, 0.45)
	draw_circle(c + Vector2(0, 3.0 * zoom), r, Color(0, 0, 0, 0.18))
	draw_circle(c, r, fill)
	if st == "available" and meta.almas >= meta.node_cost(id) and not sector_locked(node_sector(id)):
		draw_arc(c, r + 5.0 * zoom, 0, TAU, 48, Color(UiParch.GOLD_LIGHT, 0.95), maxf(2.5, 4.0 * zoom), true)
	if st == "locked" or st == "sealed":
		_dashed_ring(c, r, ring, rw)
	else:
		draw_arc(c, r, 0, TAU, 48, ring, rw, true)
	if st == "max":
		draw_arc(c, r - 4.0 * zoom, 0, TAU, 48, Color(UiParch.INK, 0.5), 1.4, true)
	if hot:
		draw_arc(c, r + 3.0 * zoom, 0, TAU, 48, Color(UiParch.BLOOD, 0.9), maxf(2.0, 3.0 * zoom), true)
	var ir := r * 0.64
	var tex := _icon(str(n.get("icon", "")))
	if tex == null:
		tex = _icon("dim")
	if tex:
		draw_texture_rect(tex, Rect2(c - Vector2(ir, ir), Vector2(ir, ir) * 2.0), false, mod)
	else:
		var d := PackedVector2Array([c + Vector2(0, -ir), c + Vector2(ir, 0), c + Vector2(0, ir), c + Vector2(-ir, 0)])
		draw_colored_polygon(d, Color(UiParch.INK_SOFT, 0.6))
	# Pontos de nível na borda de baixo.
	var mx: int = (n["costs"] as Array).size()
	var lv := meta.node_level(id)
	if mx > 1 and zoom >= 0.4:
		var pr := maxf(2.2, 4.0 * zoom)
		for k in mx:
			var pp := c + Vector2((float(k) - (mx - 1) * 0.5) * pr * 2.9, r + pr * 0.4)
			draw_circle(pp, pr + 1.2, UiParch.INK)
			draw_circle(pp, pr, UiParch.GOLD_LIGHT if k < lv else UiParch.PARCH_DARK)
	if zoom >= 0.62 or hot:
		var fs := int(clampf(15.0 * zoom, 11, 22))
		var ty := c.y + r + _pr_off(mx) + float(fs) + 4.0
		_label(fb, Vector2(c.x, ty), node_name(id), fs, UiParch.INK if st != "locked" and st != "sealed" else UiParch.INK_SOFT, 170.0 * maxf(zoom, 0.8))
		if st == "available" or st == "bought":
			var cost := meta.node_cost(id)
			if cost >= 0:
				var afford := meta.almas >= cost
				_label(fb, Vector2(c.x, ty + float(fs) + 1.0), str(cost), fs, UiParch.GOOD if afford else UiParch.BLOOD, 100.0)


func _pr_off(mx: int) -> float:
	return maxf(2.2, 4.0 * zoom) * 1.4 if mx > 1 else 0.0
