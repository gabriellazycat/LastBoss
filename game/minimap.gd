class_name Minimap
extends Control
## Mapa grande da rota (M, Select, numa bifurcação sem escolha ou com o Incêndio selecionado): a rede de
## caminhos inteira em esquema (fileiras de baixo para cima, pistas lado a lado), os locais de cada nó,
## o caminho já feito, o planejado e os ramos bloqueados. A estrada real é longa e estreita; no esquema
## as escolhas ficam legíveis. Clicar num local à frente planeja o caminho do herói (`node_clicked`); com o
## Incêndio selecionado, o clique num local vira o alvo da carta (`world_clicked` com a posição do local).

signal world_clicked(pos: Vector2)
signal node_clicked(node: int)

const HERO_COL := Color(1.0, 0.97, 0.9)   # o herói em branco-pergaminho (o azul era o da Fonte Sagrada)
const ROAD := Color(0.75, 0.65, 0.5)
const PAST := Color(0.42, 0.36, 0.3)
const PLAN := Color(1.0, 0.86, 0.45)
const SHUT := Color(0.18, 0.16, 0.16, 0.7)

var sim: Sim
var hover := -1
var t := 0.0


func setup(s: Sim) -> void:
	sim = s
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	if sim and is_visible_in_tree():
		var m := get_local_mouse_position()
		hover = node_at(m) if Rect2(Vector2.ZERO, size).has_point(m) else -1
		queue_redraw()


## Área do desenho da rota: abaixo do título e acima da legenda (que não cobrem mais a estrada).
func _area() -> Rect2:
	return Rect2(Vector2(14, 64), size - Vector2(28, 64 + 70))


## Ponto do nó n no esquema: a fileira dá a altura (o início embaixo), a pista dá o lado.
func node_point(n: int) -> Vector2:
	var a := _area().grow(-18.0)
	var nd: Dictionary = sim.road.nodes[n]
	var f := (float(nd["row"]) + 1.0) / float(sim.road.rows + 1)
	var lanes := int(sim.R["road"]["lanes"])
	var x := 0.5
	if nd["row"] >= 0 and nd["row"] < sim.road.rows:
		x = (float(nd["lane"]) + 0.5) / float(lanes)
	return Vector2(a.position.x + a.size.x * x, a.end.y - a.size.y * f)


## Onde o herói está no esquema: entre os dois nós da ligação que ele percorre agora.
func hero_point() -> Vector2:
	var road := sim.road
	var acc := 0.0
	for k in road.path.size() - 1:
		var l := road._edge_len(road.path[k], road.path[k + 1])
		if sim.hero.s <= acc + l:
			return node_point(road.path[k]).lerp(node_point(road.path[k + 1]), clampf((sim.hero.s - acc) / maxf(l, 1.0), 0.0, 1.0))
		acc += l
	return node_point(road.path[-1])


## Nó com local que pode ser escolhido como destino (à frente e alcançável), sob o ponto m do mapa (ou -1).
func node_at(m: Vector2) -> int:
	var best := -1
	var bd := 22.0
	for n in sim.road.reach:
		if n == sim.road.head or sim.road.nodes[n]["loc"] < 0:
			continue
		var d := m.distance_to(node_point(n))
		if d < bd:
			bd = d
			best = n
	return best


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and sim:
		var n := node_at(e.position)
		node_clicked.emit(n)
		if n >= 0:
			world_clicked.emit(sim.road.nodes[n]["pos"])
		accept_event()


## O nó n está no caminho planejado à frente (as bifurcações até ele já têm escolha).
func _planned(n: int) -> bool:
	return sim.road.s_of_node(n) >= 0.0 and not sim.road.path.has(n)


func _edge_col(e: int) -> Color:
	var g: Dictionary = sim.road.legs[e]
	if g["chosen"] == 0:
		return PAST
	if g["closed"] == 0:
		return SHUT
	var a: int = g["a"]
	if sim.road.nodes[a]["out"].size() == 1 or sim.road.plan.get(a, -1) == e:
		if a == sim.road.head or _planned(a):
			return PLAN
	return ROAD


func _draw() -> void:
	if not UiCovil.draw_plate(self):
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.08, 0.82))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.4, 0.7, 0.8), false, 2.0)
	if sim == null:
		return
	var road := sim.road
	var pulse := 0.5 + 0.5 * sin(t * 6.0)
	# Ligações: as fechadas por baixo, as abertas e planejadas por cima.
	for pass_ in 2:
		for e in road.legs.size():
			var col := _edge_col(e)
			if (col == SHUT) != (pass_ == 0):
				continue
			# Curva suave entre os dois nós (sai e chega na vertical, como uma estrada).
			var pa := node_point(road.legs[e]["a"])
			var pb := node_point(road.legs[e]["b"])
			var mp := PackedVector2Array()
			for i in 13:
				var u := float(i) / 12.0
				var w := u * u * (3.0 - 2.0 * u)
				mp.append(Vector2(lerpf(pa.x, pb.x, w), lerpf(pa.y, pb.y, u)))
			draw_polyline(mp, Color(0, 0, 0, 0.7 if col != SHUT else 0.35), 8.0 if col != SHUT else 5.0, true)
			draw_polyline(mp, col, 5.0 if col != SHUT else 2.5, true)
	# Próxima escolha: os destinos possíveis pulsam (sempre que o herói espera, e de leve no resto do tempo).
	var fork := road.next_fork_node()
	var options: Array = []
	if fork >= 0:
		for e in road.nodes[fork]["out"]:
			options.append(road.legs[e]["b"])
	for li in road.locations.size():
		var loc: Dictionary = road.locations[li]
		var n: int = loc["node"]
		var p := node_point(n)
		var c: Color = WorldView.LOC_COLORS[loc["type"]]
		var gone: bool = loc["state"] != SimRoad.LocState.ACTIVE or not road.on_route_node(n)
		if gone:
			c = c.darkened(0.65)
		if options.has(n):
			var k := 1.0 if sim.route_wait else 0.45
			draw_circle(p, 19.0 + 4.0 * pulse, Color(1.0, 0.85, 0.4, (0.25 + 0.35 * pulse) * k))
		draw_circle(p, 13.0, Color(0, 0, 0, 0.85))
		draw_circle(p, 10.5, c)
		_icon(p, str(loc["type"]), Color(0.05, 0.03, 0.06, 0.85 if not gone else 0.5))
		if _planned(n) and loc["state"] == SimRoad.LocState.ACTIVE:
			draw_arc(p, 15.0, 0, TAU, 28, PLAN, 2.5, true)
		if loc["state"] == SimRoad.LocState.DESTROYED:
			draw_line(p - Vector2(4, 4), p + Vector2(4, 4), Color(1, 0.4, 0.3), 2.0)
			draw_line(p + Vector2(-4, 4), p + Vector2(4, -4), Color(1, 0.4, 0.3), 2.0)
		if loc.get("burn", false) and loc["state"] == SimRoad.LocState.ACTIVE:
			draw_arc(p, 16.5, 0, TAU, 24, Color(1.0, 0.45, 0.1), 2.0, true)
		if n == hover:
			draw_arc(p, 17.0, 0, TAU, 28, Color.WHITE, 2.0, true)
	var lp := node_point(road.nodes.size() - 1)
	if UiSkins.covil():
		UiCovil.draw_rarity(self, lp, 10.0, UiKit.GOLD)
	else:
		draw_circle(lp, 6.0, Color(0.8, 0.2, 0.9))
	var hp := hero_point()
	draw_circle(hp, 8.0, Color(0, 0, 0, 0.8))
	draw_circle(hp, 6.0, HERO_COL if UiSkins.covil() else Color(0.4, 0.7, 1.0))
	draw_arc(hp, 10.0, 0, TAU, 24, Color(1, 1, 1, 0.85), 2.0, true)
	_legend()
	if hover >= 0:
		var loc: Dictionary = road.locations[road.nodes[hover]["loc"]]
		_label(node_point(hover) + Vector2(18, -12), tr("LOC_" + str(loc["type"])))


func _label(at: Vector2, s: String) -> void:
	var font := UiCovil.font("bold") if UiSkins.covil() else get_theme_default_font()
	draw_string_outline(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color.BLACK)
	draw_string(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.TEXT)


## Título e legenda: o mapa grande aparece pouco e não pode depender de passar o mouse nos pontos.
func _legend() -> void:
	var title_font := UiKit.title_font()
	var font := UiCovil.font("bold") if UiSkins.covil() else get_theme_default_font()
	var title := tr("UI_ROUTE_CHOOSE") if sim.route_wait else tr("UI_MAP_TITLE")
	draw_string_outline(title_font, Vector2(18, 34), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 4, Color.BLACK)
	draw_string(title_font, Vector2(18, 34), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UiKit.GOLD)
	var sub := tr("UI_ROUTE_KEYS") if sim.route_wait else tr("UI_MAP_PICK")
	draw_string_outline(font, Vector2(18, 56), sub, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 13, 3, Color.BLACK)
	draw_string(font, Vector2(18, 56), sub, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 13, UiKit.TEXT)
	var items: Array = []
	for k in SimRoad.LOC_TYPES:
		items.append([WorldView.LOC_COLORS[k], tr("LOC_" + k)])
	items.append([HERO_COL, tr("UI_MAP_HERO")])
	items.append([UiKit.GOLD, tr("UI_MAP_LAIR")])
	var x := 18.0
	var y := size.y - 30.0
	for it in items:
		var w := font.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		if x + 16.0 + w > size.x - 14.0:
			x = 18.0
			y -= 22.0
	x = 18.0
	var rows_y := y
	for it in items:
		var w := font.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		if x + 16.0 + w > size.x - 14.0:
			x = 18.0
			rows_y += 22.0
		draw_circle(Vector2(x + 5.0, rows_y - 5.0), 6.0, Color(0, 0, 0, 0.8))
		draw_circle(Vector2(x + 5.0, rows_y - 5.0), 4.5, it[0])
		draw_string_outline(font, Vector2(x + 14.0, rows_y), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, Color.BLACK)
		draw_string(font, Vector2(x + 14.0, rows_y), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.TEXT)
		x += 16.0 + w + 14.0
	draw_arc(hero_point(), 8.0, 0, TAU, 24, Color(1, 1, 1, 0.7), 1.5)


## Sinal simples dentro do círculo do local (o tipo se lê pela cor e pela forma).
func _icon(p: Vector2, ty: String, c: Color) -> void:
	match ty:
		"shop":
			draw_circle(p, 4.0, c)
			draw_arc(p, 4.0, 0, TAU, 12, Color(1, 1, 1, 0.5), 1.0)
		"shrine":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 0), p + Vector2(0, 6), p + Vector2(-5, 0)]), c)
		"ritual":
			for k in 5:
				var a := -PI * 0.5 + k * TAU / 5.0
				var b := -PI * 0.5 + (k + 2) * TAU / 5.0
				draw_line(p + Vector2(cos(a), sin(a)) * 6.0, p + Vector2(cos(b), sin(b)) * 6.0, c, 1.5)
		"fountain":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(4, 2), p + Vector2(0, 5), p + Vector2(-4, 2)]), c)
		"tavern":
			draw_rect(Rect2(p - Vector2(3.5, 4), Vector2(7, 8)), c)
		"bridge":
			draw_arc(p + Vector2(0, 4), 6.0, PI, TAU, 10, c, 2.0)
