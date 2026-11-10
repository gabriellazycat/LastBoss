class_name Minimap
extends Control
## Mapa da rota em tela cheia (M, Select, uma bifurcação sem escolha ou o Incêndio selecionado), desenhado como um
## mapa antigo: pergaminho, trilhas a tinta (feitas em traço cheio, planejadas e possíveis tracejadas), locais com o
## nome embaixo, bússola e rabiscos de montanha e floresta nas margens. A rede de caminhos aparece inteira em
## esquema (fileiras de baixo para cima, pistas lado a lado). Clicar num local à frente planeja o caminho do herói
## (`node_clicked`); com o Incêndio selecionado, o clique num local vira o alvo da carta (`world_clicked`).
## O jogo fica parado enquanto o mapa está aberto (quem cuida é o main.gd).

signal world_clicked(pos: Vector2)
signal cancel_requested
signal node_clicked(node: int)
signal close_requested

const HERO_COL := Color(0.62, 0.1, 0.08)       # o herói em tinta vermelha
const INK := Color(0.2, 0.12, 0.07)
const INK_SOFT := Color(0.34, 0.22, 0.12)
const PAPER_LIGHT := Color(0.9, 0.8, 0.58)
const PAST := Color(0.3, 0.2, 0.12, 0.55)
const ROAD := Color(0.3, 0.19, 0.1)
const PLAN := Color(0.66, 0.1, 0.07)
const SHUT := Color(0.3, 0.2, 0.12, 0.35)
const MAX_W := 1240.0

var sim: Sim
var hover := -1
var t := 0.0
var tip_n := -1                    # nó sob o mouse e há quanto tempo (abre a caixa do local, rodada 09/11/2026)
var tip_t := 0.0
var paper: NoiseTexture2D
var vignette: GradientTexture2D
var decor: Array = []              # rabiscos da margem: [tipo, posição, escala]
var decor_size := Vector2.ZERO
var close_rect := Rect2()


func setup(s: Sim) -> void:
	sim = s
	if paper == null:
		_make_paper()
	decor_size = Vector2.ZERO
	queue_redraw()


func _make_paper() -> void:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.006
	n.fractal_octaves = 4
	n.seed = 7
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(0.66, 0.5, 0.3), Color(0.82, 0.7, 0.47), Color(0.9, 0.8, 0.58)])
	paper = NoiseTexture2D.new()
	paper.noise = n
	paper.color_ramp = g
	paper.width = 1024
	paper.height = 640
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	vg.colors = PackedColorArray([Color(0.2, 0.1, 0.03, 0.0), Color(0.2, 0.1, 0.03, 0.06), Color(0.16, 0.08, 0.02, 0.6)])
	vignette = GradientTexture2D.new()
	vignette.gradient = vg
	vignette.fill = GradientTexture2D.FILL_RADIAL
	vignette.fill_from = Vector2(0.5, 0.5)
	vignette.fill_to = Vector2(1.0, 0.5)
	vignette.width = 256
	vignette.height = 256


func _process(delta: float) -> void:
	t += delta
	if sim and is_visible_in_tree():
		var m := get_local_mouse_position()
		hover = node_at(m) if Rect2(Vector2.ZERO, size).has_point(m) else -1
		queue_redraw()
		# Parado sobre um local: a caixa explica a disputa e a recompensa (como na faixa de rota).
		tip_t = tip_t + delta if hover >= 0 and hover == tip_n else 0.0
		tip_n = hover
		if hover >= 0 and tip_t >= HandFan.TIP_HOLD:
			var li: int = sim.road.nodes[hover]["loc"]
			if li >= 0:
				var ty := str(sim.road.locations[li]["type"])
				var gp := global_position + node_point(hover)
				Tips.hold("map:%d" % hover, Rect2(gp - Vector2(12, 12), Vector2(24, 24)), func(): return [Tips.kw_entry(ty)])


## Área do desenho da rota: entre o título e a legenda, até MAX_W de largura, centrada.
func _area() -> Rect2:
	var w := minf(size.x - 200.0, MAX_W)
	return Rect2(Vector2((size.x - w) * 0.5, 120.0), Vector2(w, maxf(size.y - 120.0 - 100.0, 200.0)))


## Ponto do nó n no esquema: a fileira dá a altura (o início embaixo), a pista dá o lado. Um desvio fixo por nó
## tira a cara de grade (o mesmo ponto vale para o desenho e para o clique).
func node_point(n: int) -> Vector2:
	var a := _area().grow(-24.0)
	var nd: Dictionary = sim.road.nodes[n]
	var f := (float(nd["row"]) + 1.0) / float(sim.road.rows + 1)
	var lanes := int(sim.R["road"]["lanes"])
	var x := 0.5
	var p := Vector2.ZERO
	if nd["row"] >= 0 and nd["row"] < sim.road.rows:
		x = (float(nd["lane"]) + 0.5) / float(lanes)
		p = Vector2(sin(n * 12.9898) * 14.0, sin(n * 78.233 + 1.0) * 6.0)
	return Vector2(a.position.x + a.size.x * x, a.end.y - a.size.y * f) + p


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
	var bd := 26.0
	for n in sim.road.reach:
		if sim.road.nodes[n]["loc"] < 0:
			continue
		# O nó para onde o herói já vai não é destino de rota, mas é alvo do Incêndio (10/11/2026: o local
		# seguinte, o alvo mais natural, não aceitava o clique no mapa grande; na faixa já aceitava).
		if n == sim.road.head and not sim._burn_targets().has(int(sim.road.nodes[n]["loc"])):
			continue
		var d := m.distance_to(node_point(n))
		if d < bd:
			bd = d
			best = n
	return best


func _gui_input(e: InputEvent) -> void:
	# Botão direito no mapa solta a carta escolhida, como no resto da tela (10/11/2026: com o Incêndio na mão,
	# o mapa abria e o botão direito não fazia nada; só o Esc saía, e o jogo ficava parado).
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT and sim:
		cancel_requested.emit()
		accept_event()
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and sim:
		if close_rect.has_point(e.position) and not sim.route_wait:
			close_requested.emit()
			accept_event()
			return
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


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	_draw_paper(rect)
	if sim == null:
		return
	if decor_size != size:
		_make_decor()
	_draw_decor()
	var road := sim.road
	var pulse := 0.5 + 0.5 * sin(t * 6.0)
	# Trilhas: as fechadas por baixo; as feitas em traço cheio; as possíveis e a planejada tracejadas.
	for pass_ in 2:
		for e in road.legs.size():
			var col := _edge_col(e)
			if (col == SHUT) != (pass_ == 0):
				continue
			var pts := _trail(e)
			if col == PAST:
				draw_polyline(pts, col, 3.0, true)
			elif col == SHUT:
				_dashed(pts, col, 2.0, 2.0, 9.0)
				var mid := pts[pts.size() / 2]
				draw_line(mid + Vector2(-6, -6), mid + Vector2(6, 6), Color(PLAN, 0.55), 2.5, true)
				draw_line(mid + Vector2(-6, 6), mid + Vector2(6, -6), Color(PLAN, 0.55), 2.5, true)
			elif col == PLAN:
				_dashed(pts, col, 4.5, 14.0, 7.0)
			else:
				_dashed(pts, col, 3.0, 10.0, 8.0)
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
		var fill := PAPER_LIGHT.lerp(c, 0.55).darkened(0.12)
		if gone:
			fill = PAPER_LIGHT.darkened(0.25)
		if options.has(n):
			var k := 1.0 if sim.route_wait else 0.5
			draw_circle(p, 24.0 + 5.0 * pulse, Color(0.95, 0.75, 0.25, (0.25 + 0.3 * pulse) * k))
		_ink_circle(p, 14.0, fill, n)
		_icon(p, str(loc["type"]), Color(INK, 0.85 if not gone else 0.4))
		if _planned(n) and loc["state"] == SimRoad.LocState.ACTIVE:
			draw_arc(p, 19.5, 0, TAU, 28, PLAN, 2.5, true)
		if loc["state"] == SimRoad.LocState.DESTROYED:
			draw_line(p - Vector2(10, 10), p + Vector2(10, 10), PLAN, 3.0, true)
			draw_line(p + Vector2(-10, 10), p + Vector2(10, -10), PLAN, 3.0, true)
		if loc.get("burn", false) and loc["state"] == SimRoad.LocState.ACTIVE:
			draw_arc(p, 22.0, 0, TAU, 24, Color(0.9, 0.35, 0.05), 3.0, true)
		if n == hover:
			draw_arc(p, 22.0, 0, TAU, 28, INK, 2.0, true)
		# O nome embaixo do local (só dos que ainda importam).
		if not gone or n == hover:
			_name(p + Vector2(0, 32), tr("LOC_" + str(loc["type"])), Color(INK, 0.9 if not gone else 0.5))
	_draw_lair(node_point(road.nodes.size() - 1))
	_draw_hero(hero_point())
	_draw_frame()
	_draw_compass(Vector2(size.x - 118.0, size.y - 128.0), 56.0)
	_draw_header()
	_legend()


func _draw_paper(r: Rect2) -> void:
	draw_rect(r, Color(0.8, 0.68, 0.46))
	if paper:
		draw_texture_rect(paper, r, false)
	# Manchas de café e dobras: poucas, fixas.
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 9:
		var c := Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		var rad := rng.randf_range(40.0, 130.0)
		draw_circle(c, rad, Color(0.45, 0.28, 0.1, 0.05))
		draw_arc(c, rad, 0, TAU, 40, Color(0.4, 0.24, 0.08, 0.07), 3.0, true)
	draw_line(Vector2(r.size.x * 0.5, 0), Vector2(r.size.x * 0.5, r.size.y), Color(0.3, 0.18, 0.06, 0.08), 3.0)
	draw_line(Vector2(0, r.size.y * 0.5), Vector2(r.size.x, r.size.y * 0.5), Color(0.3, 0.18, 0.06, 0.06), 3.0)
	if vignette:
		draw_texture_rect(vignette, r, false)


## Moldura dupla a tinta, com um canto marcado.
func _draw_frame() -> void:
	var r := Rect2(Vector2(22, 22), size - Vector2(44, 44))
	draw_rect(r, Color(INK, 0.85), false, 3.0)
	draw_rect(r.grow(-9.0), Color(INK, 0.6), false, 1.5)
	for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		draw_circle(corner, 6.0, Color(INK, 0.85))
		draw_circle(corner, 3.0, PAPER_LIGHT)


func _draw_header() -> void:
	var font := UiKit.title_font()
	var title := tr("UI_ROUTE_CHOOSE") if sim.route_wait else tr("UI_MAP_TITLE")
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	var cx := size.x * 0.5
	draw_string(font, Vector2(cx - tw * 0.5 + 2, 74), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.95, 0.88, 0.7, 0.6))
	draw_string(font, Vector2(cx - tw * 0.5, 72), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, INK)
	# Filete com losango no meio.
	var ly := 84.0
	draw_line(Vector2(cx - 240.0, ly), Vector2(cx - 14.0, ly), Color(INK, 0.8), 2.0, true)
	draw_line(Vector2(cx + 14.0, ly), Vector2(cx + 240.0, ly), Color(INK, 0.8), 2.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(cx, ly - 7), Vector2(cx + 8, ly), Vector2(cx, ly + 7), Vector2(cx - 8, ly)]), INK)
	var sub := tr("UI_ROUTE_KEYS") if sim.route_wait else tr("UI_MAP_PICK")
	var font2 := UiCovil.font("body") if UiSkins.covil() else get_theme_default_font()
	var sw := font2.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(font2, Vector2(cx - sw * 0.5, 108), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK_SOFT)
	# Fechar (fora de uma bifurcação, onde a escolha é obrigatória).
	close_rect = Rect2()
	if not sim.route_wait:
		var label := tr("UI_MAP_CLOSE")
		var lw := font2.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		close_rect = Rect2(Vector2(size.x - 60.0 - lw - 28.0, 40.0), Vector2(lw + 28.0, 36.0))
		var over := close_rect.has_point(get_local_mouse_position())
		draw_rect(close_rect, Color(INK, 0.25 if over else 0.08))
		draw_rect(close_rect, Color(INK, 0.85), false, 2.0)
		draw_string(font2, close_rect.position + Vector2(14, 25), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)


## Rosa dos ventos: o norte aponta para a frente da estrada.
func _draw_compass(c: Vector2, r: float) -> void:
	draw_arc(c, r, 0, TAU, 48, Color(INK, 0.8), 2.0, true)
	draw_arc(c, r * 0.72, 0, TAU, 48, Color(INK, 0.45), 1.2, true)
	for k in 4:
		var a := -PI * 0.5 + k * PI * 0.5
		var d := Vector2(cos(a), sin(a))
		var q := Vector2(-d.y, d.x)
		var tip := c + d * (r * 1.28 if k == 0 else r * 1.05)
		draw_colored_polygon(PackedVector2Array([tip, c + q * r * 0.16, c - q * r * 0.16]), INK if k == 0 else Color(INK, 0.7))
	for k in 4:
		var a := -PI * 0.25 + k * PI * 0.5
		var d := Vector2(cos(a), sin(a))
		draw_line(c, c + d * r * 0.62, Color(INK, 0.5), 1.5, true)
	var f := UiKit.title_font()
	draw_string(f, c + Vector2(-8, -r * 1.28 - 8), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)


## Pontos da trilha da ligação e: curva suave entre os nós com um tremor leve, como traçada à mão.
func _trail(e: int) -> PackedVector2Array:
	var pa := node_point(sim.road.legs[e]["a"])
	var pb := node_point(sim.road.legs[e]["b"])
	var mp := PackedVector2Array()
	for i in 17:
		var u := float(i) / 16.0
		var w := u * u * (3.0 - 2.0 * u)
		var wob := sin(u * 9.0 + e * 1.7) * 2.4 * sin(u * PI)
		mp.append(Vector2(lerpf(pa.x, pb.x, w) + wob, lerpf(pa.y, pb.y, u)))
	return mp


## Linha tracejada ao longo de uma polilinha (traço, vão), com pontas redondas.
func _dashed(pts: PackedVector2Array, col: Color, w: float, dash: float, gap: float) -> void:
	var on := true
	var left := dash
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		var pos := 0.0
		while pos < seg:
			var take := minf(left, seg - pos)
			if on:
				draw_line(a.lerp(b, pos / seg), a.lerp(b, (pos + take) / seg), col, w, true)
			pos += take
			left -= take
			if left <= 0.001:
				on = not on
				left = dash if on else gap


## Círculo a tinta: contorno duplo, o segundo deslocado como um traço refeito.
func _ink_circle(p: Vector2, r: float, fill: Color, seed_: int) -> void:
	draw_circle(p, r, fill)
	var o := Vector2(sin(seed_ * 3.7), cos(seed_ * 2.3)) * 1.2
	draw_arc(p, r, 0, TAU, 32, Color(INK, 0.95), 2.5, true)
	draw_arc(p + o, r + 1.5, 0.3, TAU - 0.4, 28, Color(INK, 0.5), 1.4, true)


func _name(at: Vector2, s: String, col: Color) -> void:
	var f := UiKit.title_font()
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	# Halo de pergaminho: as trilhas não riscam as letras.
	var halo := Color(0.9, 0.8, 0.58, 0.9)
	for o in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2), Vector2(-1.5, -1.5), Vector2(1.5, 1.5)]:
		draw_string(f, at + Vector2(-w * 0.5, 0) + o, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, halo)
	draw_string(f, at + Vector2(-w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)


## O covil do Lorde: uma torre com ameias, em tinta vermelha, no fim da estrada.
func _draw_lair(p: Vector2) -> void:
	var base := Rect2(p + Vector2(-17, -12), Vector2(34, 30))
	draw_rect(base, PAPER_LIGHT)
	draw_rect(base, PLAN, false, 3.0)
	for k in 3:
		var bx := base.position.x + k * 12.0
		draw_rect(Rect2(Vector2(bx, base.position.y - 9.0), Vector2(8, 9)), PAPER_LIGHT)
		draw_rect(Rect2(Vector2(bx, base.position.y - 9.0), Vector2(8, 9)), PLAN, false, 2.5)
	draw_rect(Rect2(p + Vector2(-5, 2), Vector2(10, 16)), PLAN)
	_name(p + Vector2(0, 44), tr("UI_MAP_LAIR"), PLAN)


## O herói: um peão a tinta vermelha, com um anel que pulsa.
func _draw_hero(p: Vector2) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	draw_arc(p, 16.0 + 3.0 * pulse, 0, TAU, 28, Color(HERO_COL, 0.55), 2.0, true)
	draw_circle(p + Vector2(0, -9), 5.5, HERO_COL)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(8, 8), p + Vector2(-8, 8)]), HERO_COL)
	draw_line(p + Vector2(-9, 8), p + Vector2(9, 8), INK, 2.5, true)
	draw_arc(p + Vector2(0, -9), 5.5, 0, TAU, 14, INK, 1.5, true)
	_name(p + Vector2(0, -24), tr("UI_MAP_HERO"), HERO_COL)


## Rabiscos das margens: montanhas, árvores e ondas, fixos por tamanho de tela e longe das trilhas.
func _make_decor() -> void:
	decor.clear()
	decor_size = size
	var keep: Array = []
	for n in sim.road.nodes.size():
		keep.append(node_point(n))
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var tries := 0
	while decor.size() < 46 and tries < 600:
		tries += 1
		var p := Vector2(rng.randf_range(60.0, size.x - 60.0), rng.randf_range(130.0, size.y - 90.0))
		var ok := true
		# Longe dos nós e da faixa onde passam as trilhas.
		var a := _area()
		if p.x > a.position.x - 10.0 and p.x < a.end.x + 10.0:
			ok = false
		if p.distance_to(Vector2(size.x - 118.0, size.y - 128.0)) < 110.0:
			ok = false
		for d in decor:
			if p.distance_to(d[1]) < 54.0:
				ok = false
		if ok:
			decor.append([rng.randi_range(0, 2), p, rng.randf_range(0.8, 1.4)])
	# Se a tela é estreita e não sobra margem, nada é desenhado (o mapa continua legível).


func _draw_decor() -> void:
	var col := Color(INK, 0.4)
	for d in decor:
		var p: Vector2 = d[1]
		var s: float = d[2]
		match d[0]:
			0:   # montanha
				draw_polyline(PackedVector2Array([p + Vector2(-18, 10) * s, p + Vector2(-4, -12) * s, p + Vector2(4, -2) * s, p + Vector2(10, -9) * s, p + Vector2(22, 10) * s]), col, 2.0, true)
				draw_line(p + Vector2(-4, -12) * s, p + Vector2(-1, 8) * s, Color(INK, 0.22), 1.5, true)
			1:   # árvore
				draw_arc(p + Vector2(0, -6) * s, 9.0 * s, PI * 0.9, TAU + PI * 0.1, 14, col, 2.0, true)
				draw_line(p + Vector2(0, 2) * s, p + Vector2(0, 12) * s, col, 2.0, true)
			_:   # ondas
				for k in 2:
					draw_arc(p + Vector2(-9 + k * 18, 0) * s, 9.0 * s, PI * 1.1, PI * 1.9, 10, col, 2.0, true)


## Legenda: os sinais dos locais, em tinta, no pé do mapa.
func _legend() -> void:
	var font := UiKit.title_font()
	var items: Array = []
	for k in SimRoad.LOC_TYPES:
		items.append([k, tr("LOC_" + k)])
	var total := 0.0
	for it in items:
		total += 34.0 + font.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var x := (size.x - total) * 0.5
	var y := size.y - 52.0
	var plate := Rect2(Vector2(x - 18.0, y - 26.0), Vector2(total + 28.0, 38.0))
	draw_rect(plate, Color(0.9, 0.8, 0.58, 0.92))
	draw_rect(plate, Color(INK, 0.7), false, 2.0)
	for it in items:
		var p := Vector2(x + 11.0, y - 5.0)
		var c: Color = WorldView.LOC_COLORS[it[0]]
		_ink_circle(p, 10.0, PAPER_LIGHT.lerp(c, 0.55).darkened(0.12), x)
		_icon(p, it[0], Color(INK, 0.85))
		var w := font.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(font, Vector2(x + 26.0, y), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
		x += 34.0 + w


## Sinal simples dentro do círculo do local (o tipo se lê pela cor e pela forma).
func _icon(p: Vector2, ty: String, c: Color) -> void:
	match ty:
		"shop":
			draw_circle(p, 4.5, c)
			draw_arc(p, 4.5, 0, TAU, 12, Color(1, 1, 1, 0.5), 1.0)
		"shrine":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -7), p + Vector2(6, 0), p + Vector2(0, 7), p + Vector2(-6, 0)]), c)
		"ritual":
			for k in 5:
				var a := -PI * 0.5 + k * TAU / 5.0
				var b := -PI * 0.5 + (k + 2) * TAU / 5.0
				draw_line(p + Vector2(cos(a), sin(a)) * 7.0, p + Vector2(cos(b), sin(b)) * 7.0, c, 1.8)
		"fountain":
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -7), p + Vector2(5, 2), p + Vector2(0, 6), p + Vector2(-5, 2)]), c)
		"tavern":
			draw_rect(Rect2(p - Vector2(4, 5), Vector2(8, 10)), c)
		"bridge":
			draw_arc(p + Vector2(0, 4), 7.0, PI, TAU, 10, c, 2.4)
		"event":
			var f := UiKit.title_font()
			draw_string(f, p + Vector2(-5, 7), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, c)
