class_name RouteStrip
extends Control
## Faixa de rota: a rede de caminhos inteira numa coluna, do início (embaixo) ao covil (em cima), na borda esquerda.
## Cada fileira de locais é uma linha da faixa; as pistas (esquerda, meio, direita) viram colunas estreitas.
## O já percorrido fica apagado e os ramos bloqueados somem. Clicar num local à frente planeja o caminho;
## com o Incêndio selecionado, os alvos pulsam e o clique vira o alvo da carta.

signal world_clicked(pos: Vector2)
signal node_clicked(node: int)

const PAD_START := 18.0            # folga embaixo (início da estrada)
const PAD_END := 34.0              # folga em cima (covil)
const LANE := 19.0                 # distância entre pistas
const ROAD := Color(0.78, 0.68, 0.52)
const PAST := Color(0.3, 0.27, 0.25)
const PLAN := Color(1.0, 0.86, 0.45)
const LABEL_GAP := 8.0             # textos ficam à direita da faixa

var sim: Sim
var target := ""                   # "location" (Incêndio) ou ""
var t := 0.0
var hover_loc := -1
var hover_lair := false
var tip_loc := -1
var tip_t := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(66, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(s: Sim) -> void:
	sim = s
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	if sim and is_visible_in_tree():
		_update_hover()
		queue_redraw()
		# Local sob o mouse por um instante: abre a caixa explicando o local (passar rápido não abre nem pausa).
		tip_t = tip_t + delta if hover_loc >= 0 and hover_loc == tip_loc else 0.0
		tip_loc = hover_loc
		if hover_loc >= 0 and tip_t >= HandFan.TIP_HOLD:
			var ty := str(sim.road.locations[hover_loc]["type"])
			var p := global_position + _loc_point(sim.road.locations[hover_loc])
			Tips.hold("loc:%d" % hover_loc, Rect2(p - Vector2(10, 10), Vector2(20, 20)), func(): return [Tips.kw_entry(ty)])


# ---------------------------------------------------------------- geometria

func _cx() -> float:
	return size.x * 0.5


## Ponto do nó n na faixa: a fileira dá a altura (o início embaixo), a pista dá o lado.
func _node_point(n: int) -> Vector2:
	var road := sim.road
	var nd: Dictionary = road.nodes[n]
	var f := (float(nd["row"]) + 1.0) / float(road.rows + 1)
	var y := size.y - PAD_START - f * (size.y - PAD_START - PAD_END)
	var lanes := int(sim.R["road"]["lanes"])
	var x := _cx() + (float(nd["lane"]) - (lanes - 1) * 0.5) * LANE
	if nd["row"] < 0 or nd["row"] >= road.rows:
		x = _cx()
	return Vector2(x, y)


func _loc_point(loc: Dictionary) -> Vector2:
	return _node_point(int(loc["node"]))


func _lair_point() -> Vector2:
	return _node_point(sim.road.nodes.size() - 1)


## Onde o herói está na faixa: entre os dois nós da ligação que ele percorre agora.
func _hero_point() -> Vector2:
	var road := sim.road
	var s := sim.hero.s
	var acc := 0.0
	for k in road.path.size() - 1:
		var a: int = road.path[k]
		var b: int = road.path[k + 1]
		var l := road._edge_len(a, b)
		if s <= acc + l:
			return _node_point(a).lerp(_node_point(b), clampf((s - acc) / maxf(l, 1.0), 0.0, 1.0))
		acc += l
	return _node_point(road.path[-1])


## O local ficou para trás: no caminho já feito, antes do herói.
func _behind(loc: Dictionary) -> bool:
	var s := sim.road.s_of_node(int(loc["node"]))
	return sim.road.path.has(int(loc["node"])) and s >= 0.0 and s < sim.hero.s


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if not UiCovil.draw_plate(self):
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.035, 0.08, 0.72))
		draw_rect(Rect2(Vector2.ZERO, size), UiKit.EDGE.darkened(0.2), false, 1.0)
	if sim == null or sim.road.legs.is_empty():
		return
	var road := sim.road
	var pulse := 0.5 + 0.5 * sin(t * 6.0)
	var hp := _hero_point()
	for e in road.legs.size():
		var g: Dictionary = road.legs[e]
		if g["closed"] == 0:
			continue
		var a: int = g["a"]
		var pa := _node_point(a)
		var pb := _node_point(g["b"])
		var col := ROAD
		if g["chosen"] == 0:
			col = PAST if pb.y >= hp.y else ROAD
		elif road.plan.get(a, -1) == e and road.on_route_node(a):
			col = PLAN
		elif road.nodes[a]["out"].size() > 1 and road.plan.has(a):
			col = Color(0.4, 0.36, 0.32)
		# Contorno escuro: a estrada desenhada lê como um mapa, não como uma linha solta.
		draw_line(pa, pb, Color(0.04, 0.02, 0.06, 0.85), 7.0)
		draw_line(pa, pb, col, 4.0)
		if g["chosen"] == 0 and pa.y >= hp.y and pb.y < hp.y:
			draw_line(pa, hp, PAST, 4.0)
	# Próxima bifurcação sem escolha: distância até ela; com o herói esperando, as opções pulsam.
	var fork := road.next_fork_node()
	if fork >= 0:
		var fp := _node_point(fork)
		var d := maxf(road.s_of_node(fork) - sim.hero.s, 0.0) if road.s_of_node(fork) >= 0.0 else 0.0
		_text(fp.y, tr("UI_ROUTE_CHOOSE") if sim.route_wait else tr("UI_STRIP_FORK").format({"m": int(d)}), Color(0.6, 0.92, 1.0), 13)
		for e in road.nodes[fork]["out"]:
			var op := _node_point(road.legs[e]["b"])
			var k := 1.0 if sim.route_wait else 0.5
			draw_circle(op, 11.0 + 2.0 * pulse, Color(1.0, 0.85, 0.4, (0.25 + 0.35 * pulse) * k))
	for i in road.locations.size():
		var loc: Dictionary = road.locations[i]
		var n: int = loc["node"]
		if not road.on_route_node(n) and not road.path.has(n):
			continue
		var p := _loc_point(loc)
		var c: Color = WorldView.LOC_COLORS[loc["type"]]
		var active: bool = loc["state"] == SimRoad.LocState.ACTIVE
		var rr := 6.5 if active else 4.5
		if not active or _behind(loc):
			c = c.darkened(0.6)
		if target == "location" and sim._burn_targets().has(i):
			draw_circle(p, 11.0 + 2.0 * pulse, Color(1.0, 0.55, 0.2, 0.3 + 0.3 * pulse))
		draw_circle(p, rr + 1.5, Color(0, 0, 0, 0.8))
		draw_circle(p, rr, c)
		if loc.get("burn", false) and active:
			draw_arc(p, rr + 2.5, 0, TAU, 18, Color(1.0, 0.45, 0.1), 1.5)
		if loc["state"] == SimRoad.LocState.DESTROYED:
			draw_line(p - Vector2(4, 4), p + Vector2(4, 4), Color(1, 0.4, 0.3), 2.0)
			draw_line(p + Vector2(-4, 4), p + Vector2(4, -4), Color(1, 0.4, 0.3), 2.0)
		if i == hover_loc:
			draw_arc(p, rr + 3.0, 0, TAU, 20, Color.WHITE, 1.5)
	# Covil e progresso.
	var lp := _lair_point()
	var is_lair: bool = sim.act + 1 >= sim.acts()
	draw_circle(lp, 12.5, Color(0, 0, 0, 0.8))
	if not is_lair:
		# Portão de passagem: dois pilares e uma verga, em vez do círculo do covil.
		var gc := UiKit.GOLD if UiSkins.covil() else Color(0.95, 0.8, 0.5)
		draw_rect(Rect2(lp + Vector2(-9, -8), Vector2(4, 16)), gc)
		draw_rect(Rect2(lp + Vector2(5, -8), Vector2(4, 16)), gc)
		draw_rect(Rect2(lp + Vector2(-10, -10), Vector2(20, 4)), gc)
	elif UiSkins.covil():
		UiCovil.draw_rarity(self, lp, 12.0, UiKit.GOLD)
	else:
		draw_circle(lp, 11.0, Color(0.8, 0.2, 0.9))
		draw_arc(lp, 12.0, 0, TAU, 24, Color(0.95, 0.75, 1.0), 1.5)
	_text(lp.y, "%d%%" % int(_progress() * 100.0), Color(0.95, 0.75, 1.0), 13)
	# Herói.
	draw_circle(hp, 8.0, Color(0, 0, 0, 0.8))
	draw_circle(hp, 6.5, Minimap.HERO_COL if UiSkins.covil() else Color(0.45, 0.72, 1.0))
	draw_arc(hp, 9.5, 0, TAU, 24, Color(1, 1, 1, 0.85), 2.0)
	# Nome do local sob o mouse.
	if hover_loc >= 0:
		var loc: Dictionary = road.locations[hover_loc]
		var txt := tr("LOC_" + str(loc["type"]))
		var s := road.s_of_node(int(loc["node"]))
		if loc["state"] == SimRoad.LocState.ACTIVE and s >= 0.0 and s > sim.hero.s:
			txt = tr("UI_STRIP_DIST").format({"name": txt, "m": int(s - sim.hero.s)})
		_text(_loc_point(loc).y, txt, UiKit.TEXT, 14)
	elif hover_lair:
		_text(lp.y + 18.0, tr("UI_STRIP_LAIR" if is_lair else "UI_STRIP_ACT_END").format({"n": sim.act + 1, "m": int(maxf(road.total_length() - sim.hero.s, 0.0))}), UiKit.TEXT, 14)


func _progress() -> float:
	return clampf(sim.hero.s / maxf(sim.road.total_length(), 1.0), 0.0, 1.0)


## Texto à direita da faixa, centrado verticalmente em y.
func _text(y: float, s: String, col: Color, fs: int) -> void:
	var font := get_theme_default_font()
	if UiSkins.covil():
		font = UiCovil.font("bold")
		fs = roundi(fs * UiCovil.TEXT_SCALE)
	var at := Vector2(size.x + LABEL_GAP, clampf(y, fs * 0.5, size.y - fs * 0.5) + fs * 0.35)
	if UiSkins.covil():
		var tw := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pill := StyleBoxFlat.new()
		pill.bg_color = Color(0.05, 0.04, 0.05, 0.78)
		pill.border_color = Color(UiCovil.BRONZE.r, UiCovil.BRONZE.g, UiCovil.BRONZE.b, 0.45)
		pill.set_border_width_all(1)
		pill.set_corner_radius_all(int(fs * 0.7))
		pill.anti_aliasing = true
		draw_style_box(pill, Rect2(at + Vector2(-8, -fs * 0.98), Vector2(tw + 16, fs * 1.42)))
	draw_string_outline(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.BLACK)
	draw_string(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


# ---------------------------------------------------------------- mouse

func _update_hover() -> void:
	var m := get_local_mouse_position()
	hover_loc = -1
	hover_lair = false
	if not Rect2(Vector2.ZERO, size).has_point(m):
		return
	hover_loc = _loc_at(m)
	hover_lair = hover_loc < 0 and m.distance_to(_lair_point()) < 16.0


## Local visível na faixa sob o ponto m (ou -1).
func _loc_at(m: Vector2) -> int:
	var best := 10.0
	var pick := -1
	for i in sim.road.locations.size():
		var loc: Dictionary = sim.road.locations[i]
		if not sim.road.on_route_node(int(loc["node"])) and not sim.road.path.has(int(loc["node"])):
			continue
		var d := m.distance_to(_loc_point(loc))
		if d < best:
			best = d
			pick = i
	return pick


func _gui_input(e: InputEvent) -> void:
	if sim == null or not (e is InputEventMouseButton) or not e.pressed or e.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	var w = target_at(e.position)
	if w != null:
		world_clicked.emit(w)
		return
	var li := _loc_at(e.position)
	if target == "" and li >= 0:
		node_clicked.emit(int(sim.road.locations[li]["node"]))


## Ponto do mundo que a carta de rota selecionada afeta em m (local), ou null. Também usado ao soltar uma carta arrastada.
func target_at(m: Vector2):
	if target == "location":
		var best := 14.0
		var pick := -1
		for i in sim._burn_targets():
			var d := m.distance_to(_loc_point(sim.road.locations[i]))
			if d < best:
				best = d
				pick = i
		if pick >= 0:
			return sim.road.locations[pick]["pos"]
	return null
