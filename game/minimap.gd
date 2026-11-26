class_name Minimap
extends Control
## Mapa da rota em tela cheia (M, Select, uma bifurcação sem escolha ou o Incêndio selecionado), em colcha de
## feltro (escolhida em 26/11/2026): a terra são retalhos sálvia e oliva costurados (o shader map_cloth.gdshader,
## como o chão do jogo), mar e rios de feltro azul, copas e montanhas em feltro chapado, locais em botões creme
## com o desenho a tinta, e as placas nos painéis de feltro do kit (UiParch).
## Um mapa longo e vertical para a run inteira: os atos empilhados de baixo para cima, rolável com a roda do mouse,
## arrastando, setas/PgUp/PgDn ou o direcional e o analógico esquerdo do controle. Abre com o herói em vista.
## O ato atual aparece inteiro; os atos futuros ainda não existem no Sim (cada ato gera a sua estrada ao começar),
## então são regiões cobertas de névoa com locais "?" de enfeite; os atos passados ficam guardados aqui
## (a estrada antiga é descartada pelo Sim) e aparecem com o caminho percorrido.
## O terreno (costa, rios, árvores, montanhas, aldeias...) é procedural, com semente da run e do ato, e é
## desenhado uma vez numa SubViewport (só volta a desenhar quando muda o ato ou o tamanho da tela); por quadro
## só entram as trilhas, os locais, o herói e a moldura.
## Clicar num local à frente planeja o caminho do herói (`node_clicked`); com o Incêndio selecionado, o clique
## num local vira o alvo da carta (`world_clicked`). O jogo fica parado enquanto o mapa está aberto (main.gd).

signal world_clicked(pos: Vector2)
signal cancel_requested
signal node_clicked(node: int)
signal close_requested

const HERO_COL := Color(0.62, 0.1, 0.08)       # o herói em tinta vermelha (a faixa de rota usa a mesma cor)
# Paleta do estilo A (mapa.html): papel, papel escuro, mar, tinta, vermelho e os preenchimentos dos ícones.
const BG := Color("9db07f")       # terra (o shader troca essa cor pelos retalhos costurados)
const BG2 := Color("c9a46a")      # faixa ocre dos cartuchos
const SEA := Color("6d8db0")      # mar, rios e lagos
const INK := Color("2f3a2a")      # linha escura dos contornos e textos
const ACC := Color("b5473a")      # linha vermelha da rota
const F1 := Color("efe4cf")
const F2 := Color("c9a46a")
const F3 := Color("d8c39a")
const PAPER := Color("efe4cf")    # botões dos locais, placas dos atos e a linha das costuras
const LEAF := Color("5d7b4a")     # copas
const PINE := Color("3f5f45")     # pinheiros e abetos
const MTN := Color("b3a68c")      # montanhas
const HILL := Color("8ba06c")     # colinas
const FOG := Color("d3d8cc")      # névoa dos atos que ainda não chegaram (fora da cor da terra: não vira retalho)
# Geometria em "unidades de desenho" de uma tela 1920x1080; a escala k leva para pixels.
const W := 1920.0
const ROW_GAP := 180.0             # distância entre fileiras de locais
const X0 := 400.0                  # faixa das pistas: de X0 a X0 + XW
const XW := 1120.0
const CART_GAP := 330.0            # do portão de um ato ao início do seguinte (o cartucho fica no meio)
const TOP_PAD := 230.0
const BOTTOM_PAD := 310.0          # abaixo do início do primeiro ato (o cartucho do Ato I)
const CELL := 30.0                 # grade de ocupação do terreno
const ACT_NAMES := 3               # nomes inventados por ato (UI_MAP_ACTNAME_<ato>_<k>)

var sim: Sim
var hover := -1: set = _set_hover
var t := 0.0
var tip_n := -1                    # nó sob o mouse e há quanto tempo (abre a caixa do local)
var tip_t := 0.0
var close_rect := Rect2()
var rail_rect := Rect2()
var scroll := 0.0                  # topo da tela, em pixels do conteúdo
var scroll_goal := 0.0
var pin_y := -1.0                  # altura pedida por scroll_to_design (as capturas): vale também depois de um novo layout
var k := 1.0                       # escala: pixels por unidade de desenho
var ox := 0.0                      # margem à esquerda quando a tela é mais larga que 16:9
var H := 2000.0                    # altura total do mapa, em unidades
var lay: Array = []                # por ato: {"start", "end", "cart", "rows", "top", "bottom"}
var past: Dictionary = {}          # ato -> SimRoad já percorrida (guardada ao trocar de ato)
var fake: Dictionary = {}          # ato futuro -> desenho de enfeite {"rows": [[Vector2]], "links": [[Vector2, Vector2]]}
var seen_road: SimRoad
var seen_act := -1
var lay_key := ""
var bake_key := ""
var vp: SubViewport                # o terreno pintado uma vez
var canvas: Node2D
var post: ColorRect
var kt := 1.0                      # escala da textura do terreno
var drag := false
var drag_from := Vector2.ZERO
var drag_scroll := 0.0
var last_mouse := Vector2(-9999, -9999)
var _mouse_hover := false          # hover vindo do mouse (o controle também troca o hover, e aí o mapa rola até ele)
var fell: Font
var fell_it: Font

## Rios, montanhas, colinas e árvores do mapa em gravura (hachura densa, escolhida em 15/11/2026).
const WASH_W := Color(0.43, 0.57, 0.6, 0.6)     # água
const WASH_G := Color(0.47, 0.53, 0.27)          # folhagem
const WASH_M := Color(0.55, 0.38, 0.2, 0.42)     # sombra das montanhas
static var _grain: ImageTexture
static var _puff: GradientTexture2D


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _ready() -> void:
	vp = SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.size = Vector2i(8, 8)
	canvas = Node2D.new()
	canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	canvas.draw.connect(func(): _paint_terrain(canvas))
	vp.add_child(canvas)
	post = ColorRect.new()
	var sm := ShaderMaterial.new()
	sm.shader = load("res://game/art/map_cloth.gdshader")
	sm.set_shader_parameter("land", BG)
	sm.set_shader_parameter("thread", PAPER)
	post.material = sm
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.add_child(post)
	add_child(vp)


func setup(s: Sim) -> void:
	if s != sim:
		past.clear()
		seen_road = null
		seen_act = -1
	sim = s
	if fell == null:
		fell = UiDiario.font("fell")
		fell_it = UiDiario.font("fell_it")
	_archive()
	_relayout()
	center_on_hero()
	queue_redraw()


## Abre com o herói em vista, um pouco abaixo do meio (a estrada à frente fica para cima).
func center_on_hero() -> void:
	if sim == null:
		return
	scroll_goal = _clamp_scroll(_design_of_hero().y * k - size.y * 0.62)
	scroll = scroll_goal


## Rola até a altura y (em unidades de desenho) no topo da tela; usado nas capturas (--mapscroll).
func scroll_to_design(y: float) -> void:
	pin_y = y
	scroll_goal = _clamp_scroll(y * k)
	scroll = scroll_goal


func _set_hover(v: int) -> void:
	var changed := v != hover
	hover = v
	# O controle (L1/R1 na bifurcação) troca o local destacado: o mapa rola até ele.
	if changed and v >= 0 and not _mouse_hover and sim:
		var p := node_point(v)
		if p.y < size.y * 0.2 or p.y > size.y * 0.8:
			scroll_goal = _clamp_scroll(scroll + p.y - size.y * 0.5)


func _clamp_scroll(v: float) -> float:
	return clampf(v, 0.0, maxf(H * k - size.y, 0.0))


# ---------------------------------------------------------------- estado e disposição

## O Sim troca a estrada a cada ato e descarta a antiga: guardamos a que acabou para desenhar o caminho feito.
func _archive() -> void:
	if sim == null:
		return
	if seen_road != null and seen_road != sim.road and sim.act > seen_act and seen_act >= 0:
		past[seen_act] = seen_road
	seen_road = sim.road
	seen_act = sim.act


func _acts() -> int:
	return maxi(1, sim.acts())


func _lanes() -> int:
	return maxi(1, int(sim.R["road"]["lanes"]))


func _seed(a: int) -> int:
	return int(sim.run_seed) * 31 + a * 7919 + 17


## Fileiras do ato a: as da estrada real (atual ou guardada) ou uma estimativa pela configuração do ato.
func _act_rows(a: int) -> int:
	if a == sim.act:
		return sim.road.rows
	if past.has(a):
		return (past[a] as SimRoad).rows
	var R: Dictionary = sim.R["road"].duplicate()
	R.merge(sim._act_cfg(a), true)
	var rl: Array = R["route_locations"]
	return int(ceil((float(rl[0]) + float(rl[1])) * 0.5))


func _road_of(a: int) -> SimRoad:
	if a == sim.act:
		return sim.road
	return past.get(a, null)


func _relayout() -> void:
	var vs := size if size.x > 0.0 else Vector2(1920, 1080)
	k = minf(vs.x / W, vs.y / 1080.0)
	ox = (vs.x - W * k) * 0.5
	var n := _acts()
	var rows: Array = []
	for a in n:
		rows.append(_act_rows(a))
	# De baixo para cima: cartucho do Ato I, início, fileiras, portão; folga; o ato seguinte...
	var total := BOTTOM_PAD + TOP_PAD
	for a in n:
		total += (int(rows[a]) + 1) * ROW_GAP + (CART_GAP if a > 0 else 0.0)
	H = total
	lay.clear()
	var y := H - BOTTOM_PAD
	for a in n:
		if a > 0:
			y -= CART_GAP
		var st := y
		var en: float = st - (int(rows[a]) + 1) * ROW_GAP
		var cart := st + 200.0 if a == 0 else st + CART_GAP * 0.5
		lay.append({"start": st, "end": en, "cart": cart, "rows": rows[a]})
		y = en
	for a in n:
		lay[a]["bottom"] = H - 40.0 if a == 0 else float(lay[a - 1]["end"])
		lay[a]["top"] = 120.0 if a == n - 1 else float(lay[a]["end"])
	fake.clear()
	lay_key = _key()


func _key() -> String:
	return "%d|%d|%d|%d|%d|%.4f|%d|%dx%d" % [sim.get_instance_id(), sim.act, sim.road.rows, past.size(), sim.run_seed, k, 1, int(size.x), int(size.y)]


## Ponto do nó n da estrada do ato a, em unidades de desenho. Um desvio fixo por nó tira a cara de grade.
func _dpos(a: int, road: SimRoad, n: int) -> Vector2:
	var nd: Dictionary = road.nodes[n]
	var row: int = nd["row"]
	var y: float = float(lay[a]["start"]) - (row + 1) * ROW_GAP
	var x := W * 0.5
	if row >= 0 and row < road.rows:
		x = X0 + (float(nd["lane"]) + 0.5) / float(_lanes()) * XW + sin(n * 12.9898 + a * 3.1) * 22.0
		y += sin(n * 78.233 + a * 1.7) * 15.0
	return Vector2(x, y)


## Curva da ligação e: bézier entre os nós com puxadores desviados por semente (trilha traçada à mão).
func _curve(a: int, road: SimRoad, e: int) -> PackedVector2Array:
	var g: Dictionary = road.legs[e]
	var pa := _dpos(a, road, g["a"])
	var pb := _dpos(a, road, g["b"])
	var dy := pb.y - pa.y
	var h1 := fposmod(sin(e * 91.7 + a * 5.3) * 43758.5, 1.0)
	var h2 := fposmod(sin(e * 47.1 + a * 2.9) * 24634.6, 1.0)
	var o1 := (h1 - 0.5) * 150.0
	var o2 := (h2 - 0.5) * 150.0
	return _cubic(pa, pa + Vector2(o1, dy * (0.3 + h2 * 0.3)), pb + Vector2(o2, -dy * (0.3 + h1 * 0.3)), pb, 22)


func _to_screen(d: Vector2) -> Vector2:
	return Vector2(ox + d.x * k, d.y * k - scroll)


## Ponto do nó n (do ato atual) na tela, em coordenadas locais do mapa (o mesmo ponto vale para desenho e clique).
func node_point(n: int) -> Vector2:
	if lay.is_empty() or lay_key != _key():
		_archive()
		_relayout()
	return _to_screen(_dpos(sim.act, sim.road, n))


func _design_of_hero() -> Vector2:
	var road := sim.road
	var acc := 0.0
	for i in road.path.size() - 1:
		var l := road._edge_len(road.path[i], road.path[i + 1])
		if sim.hero.s <= acc + l:
			for e in road.nodes[road.path[i]]["out"]:
				if road.legs[e]["b"] == road.path[i + 1]:
					return _along(_curve(sim.act, road, e), clampf((sim.hero.s - acc) / maxf(l, 1.0), 0.0, 1.0))
		acc += l
	return _dpos(sim.act, road, road.path[-1])


## Nó com local que pode ser escolhido como destino (à frente e alcançável), sob o ponto m do mapa (ou -1).
func node_at(m: Vector2) -> int:
	var best := -1
	var bd := maxf(26.0, 40.0 * k)
	for n in sim.road.reach:
		if sim.road.nodes[n]["loc"] < 0:
			continue
		# O nó para onde o herói já vai não é destino de rota, mas é alvo do Incêndio (10/11/2026).
		if n == sim.road.head and not sim._burn_targets().has(int(sim.road.nodes[n]["loc"])):
			continue
		var d := m.distance_to(node_point(n))
		if d < bd:
			bd = d
			best = n
	return best


# ---------------------------------------------------------------- entrada

func _process(delta: float) -> void:
	t += delta
	if sim == null:
		return
	if sim.road != seen_road:
		_archive()
	if not is_visible_in_tree():
		drag = false
		return
	if lay_key != _key():
		_relayout()
		center_on_hero()
		if pin_y >= 0.0:
			scroll_goal = _clamp_scroll(pin_y * k)
			scroll = scroll_goal
	if bake_key != _bake_id() and vp != null:
		_bake()
	# Controle: direcional para cima/baixo ou analógico esquerdo rolam o mapa.
	var pad := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(pad) < 0.25:
		pad = 0.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		pad = -1.0
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		pad = 1.0
	if pad != 0.0:
		scroll_goal = _clamp_scroll(scroll_goal + pad * 1500.0 * k * delta)
	scroll_goal = _clamp_scroll(scroll_goal)
	scroll = _clamp_scroll(lerpf(scroll, scroll_goal, clampf(delta * 14.0, 0.0, 1.0)))
	var m := get_local_mouse_position()
	if m.distance_to(last_mouse) > 0.5 or drag:
		last_mouse = m
		_mouse_hover = true
		hover = node_at(m) if Rect2(Vector2.ZERO, size).has_point(m) and not drag else -1
		_mouse_hover = false
	queue_redraw()
	# Parado sobre um local: a caixa explica a disputa e a recompensa (como na faixa de rota).
	tip_t = tip_t + delta if hover >= 0 and hover == tip_n else 0.0
	tip_n = hover
	if hover >= 0 and tip_t >= HandFan.TIP_HOLD:
		var li: int = sim.road.nodes[hover]["loc"]
		if li >= 0:
			var ty := str(sim.road.locations[li]["type"])
			var gp := global_position + node_point(hover)
			Tips.hold("map:%d" % hover, Rect2(gp - Vector2(16, 16), Vector2(32, 32)), func(): return [Tips.kw_entry(ty)])


func _gui_input(e: InputEvent) -> void:
	if sim == null:
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		# Botão direito solta a carta escolhida, como no resto da tela (10/11/2026).
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			cancel_requested.emit()
		elif mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var dir := -1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			scroll_goal = _clamp_scroll(scroll_goal + dir * 150.0 * k * maxf(mb.factor, 1.0))
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if close_rect.has_point(mb.position) and not sim.route_wait:
				close_requested.emit()
			elif rail_rect.has_point(mb.position):
				var f := (mb.position.y - rail_rect.position.y) / maxf(rail_rect.size.y, 1.0)
				scroll_goal = _clamp_scroll(f * H * k - size.y * 0.5)
			else:
				var n := node_at(mb.position)
				if n >= 0:
					node_clicked.emit(n)
					world_clicked.emit(sim.road.nodes[n]["pos"])
				else:
					# Fora de um local: arrastar rola o mapa.
					drag = true
					drag_from = mb.position
					drag_scroll = scroll
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_MIDDLE:
			drag = true
			drag_from = mb.position
			drag_scroll = scroll
		elif not mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_MIDDLE):
			drag = false
		accept_event()
	elif e is InputEventMouseMotion and drag:
		scroll = _clamp_scroll(drag_scroll - (e.position.y - drag_from.y))
		scroll_goal = scroll
		accept_event()
	elif e is InputEventPanGesture:
		scroll_goal = _clamp_scroll(scroll_goal + e.delta.y * 40.0 * k)
		accept_event()


func _unhandled_input(e: InputEvent) -> void:
	if sim == null or not is_visible_in_tree():
		return
	if e is InputEventKey and e.pressed:
		var step := 0.0
		match e.keycode:
			KEY_UP:
				step = -160.0 * k
			KEY_DOWN:
				step = 160.0 * k
			KEY_PAGEUP:
				step = -size.y * 0.8
			KEY_PAGEDOWN:
				step = size.y * 0.8
			KEY_HOME:
				center_on_hero()
				get_viewport().set_input_as_handled()
				return
		if step != 0.0:
			scroll_goal = _clamp_scroll(scroll_goal + step)
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- desenho por quadro

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SEA.darkened(0.25))
	if sim == null or lay.is_empty():
		return
	var tex: Texture2D = vp.get_texture() if vp != null and bake_key.begins_with(lay_key) else null
	var dst := Rect2(Vector2(ox, 0.0), Vector2(W * k, size.y))
	if tex:
		draw_texture_rect_region(tex, dst, Rect2(0.0, scroll * kt / k, W * kt, size.y * kt / k))
	else:
		draw_rect(dst, BG)
	draw_set_transform(Vector2(ox, -scroll), 0.0, Vector2(k, k))
	tf_live = Transform2D(0.0, Vector2(k, k), 0.0, Vector2(ox, -scroll))
	var view := Rect2(0.0, scroll / k - 120.0, W, size.y / k + 240.0)
	_draw_current(view)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_overlay()


func _leg_state(e: int) -> String:
	var g: Dictionary = sim.road.legs[e]
	if g["chosen"] == 0:
		return "past"
	if g["closed"] == 0:
		return "shut"
	var a: int = g["a"]
	if sim.road.nodes[a]["out"].size() == 1 or sim.road.plan.get(a, -1) == e:
		if a == sim.road.head or _planned(a):
			return "plan"
	return "open"


## O nó n está no caminho planejado à frente (as bifurcações até ele já têm escolha).
func _planned(n: int) -> bool:
	return sim.road.s_of_node(n) >= 0.0 and not sim.road.path.has(n)


## Estilo do traço pela ponta: estrada (lojas, tavernas, portões), trilha ou pontilhado de ponte.
func _leg_kind(road: SimRoad, e: int) -> String:
	var ts: Array = []
	for end in ["a", "b"]:
		var li: int = road.nodes[road.legs[e][end]]["loc"]
		ts.append(str(road.locations[li]["type"]) if li >= 0 else "road")
	if ts.has("bridge"):
		return "dots"
	if ts.has("shop") or ts.has("tavern") or ts.has("road"):
		return "road"
	return "trail"


func _draw_current(view: Rect2) -> void:
	var road := sim.road
	var a := sim.act
	var march := fmod(t * 24.0, 24.0)
	# Trilhas: as fechadas por baixo; depois as abertas, a planejada e a já feita.
	for pass_ in 2:
		for e in road.legs.size():
			var st := _leg_state(e)
			if (st == "shut") != (pass_ == 0):
				continue
			var pts := _curve(a, road, e)
			if not view.intersects(_bounds(pts)):
				continue
			var kind := _leg_kind(road, e)
			match st:
				"shut":
					_dots(self, pts, Color(INK, 0.32), 2.6, 11.0)
					var mid := pts[pts.size() / 2]
					draw_line(mid + Vector2(-7, -7), mid + Vector2(7, 7), Color(ACC, 0.45), 2.5, true)
					draw_line(mid + Vector2(-7, 7), mid + Vector2(7, -7), Color(ACC, 0.45), 2.5, true)
				"past":
					_base_leg(self, pts, kind, 0.55)
					draw_polyline(pts, Color(ACC, 0.78), 7.0, true)
				"plan":
					_base_leg(self, pts, kind, 0.8)
					_dashed(self, pts, ACC, 5.0, 14.0, 10.0, march)
				_:
					_base_leg(self, pts, kind, 1.0)
	# Próxima escolha: os destinos possíveis pulsam (sempre que o herói espera, e de leve no resto do tempo).
	var fork := road.next_fork_node()
	var options: Array = []
	if fork >= 0:
		for e in road.nodes[fork]["out"]:
			options.append(road.legs[e]["b"])
	var burn: Array = sim._burn_targets() if _burn_selected() else []
	for li in road.locations.size():
		var loc: Dictionary = road.locations[li]
		var n: int = loc["node"]
		var p := _dpos(a, road, n)
		if not view.has_point(p):
			continue
		var gone: bool = loc["state"] != SimRoad.LocState.ACTIVE or not road.on_route_node(n)
		var visited: bool = road.path.has(n) and n != road.head
		if options.has(n) and not gone:
			var ph := fmod(t / 1.6, 1.0)
			var rk := 1.0 if sim.route_wait else 0.6
			draw_arc(p, 44.0 * lerpf(0.9, 1.35, ph), 0, TAU, 40, Color(ACC, (1.0 - ph) * rk), 4.0, true)
		if burn.has(li):
			var pb := 0.5 + 0.5 * sin(t * 6.0)
			draw_arc(p, 42.0 + 4.0 * pb, 0, TAU, 36, Color(0.9, 0.35, 0.05, 0.55 + 0.35 * pb), 4.0, true)
		var sc := 1.15 if n == hover else 1.0
		_badge(self, p, sc, 0.92 if not gone else 0.6)
		_icon(self, p, str(loc["type"]), sc, 1.0 if not gone else 0.42)
		if _planned(n) and loc["state"] == SimRoad.LocState.ACTIVE:
			draw_arc(p, 41.0 * sc, 0, TAU, 40, ACC, 3.0, true)
		if loc["state"] == SimRoad.LocState.DESTROYED:
			draw_line(p - Vector2(18, 18), p + Vector2(18, 18), ACC, 4.0, true)
			draw_line(p + Vector2(-18, 18), p + Vector2(18, -18), ACC, 4.0, true)
		if loc.get("burn", false) and loc["state"] == SimRoad.LocState.ACTIVE:
			draw_arc(p, 40.0, 0, TAU, 36, Color(0.9, 0.35, 0.05), 3.0, true)
		if visited:
			_tick(self, p + Vector2(26, -26))
		if loc.get("hard", false):
			# Disputa difícil (11/11/2026): caveira no canto; vencer as 3 etapas dá também uma relíquia.
			_skull_seal(self, p + Vector2(-31, -31), 1.0 if not gone else 0.45, t)
		if n == hover:
			draw_arc(p, 46.0, 0, TAU, 40, INK, 2.0, true)
		_label(self, p + Vector2(0, 62), tr("LOC_" + str(loc["type"])), 24, Color(INK, 0.95 if not gone else 0.5))
	# Começo e fim do ato: acampamento embaixo; portão do ato (ou o covil) em cima.
	var p0 := _dpos(a, road, 0)
	if view.has_point(p0):
		_badge(self, p0, 1.0, 0.92)
		_icon(self, p0, "start", 1.0, 1.0)
		if a == 0 and _exit_name() != "":
			_label(self, p0 + Vector2(0, 66), _exit_name(), 25, ACC)
	var pe := _dpos(a, road, road.nodes.size() - 1)
	if view.has_point(pe):
		var last := a + 1 >= _acts()
		_badge(self, pe, 1.1, 0.95)
		_icon(self, pe, "lair" if last else "gate", 1.1, 1.0)
		_label(self, pe + Vector2(0, 66), tr("UI_MAP_LAIR") if last else tr("UI_MAP_ACT_END").format({"n": a + 1}), 25, ACC)
	_draw_hero(_design_of_hero())


func _burn_selected() -> bool:
	var hud := get_parent()
	if hud == null or not ("selected" in hud):
		return false
	var i: int = hud.selected
	if i < 0:
		return false
	var ci := sim.hand_card(i)
	return ci != null and ci.def.id == "burn_village"


## O herói: uma bandeirola vermelha num mastro, balançando de leve, com a sombra no chão.
func _draw_hero(p: Vector2) -> void:
	var bob := sin(t * 5.2) * 3.0
	_ellipse(self, p + Vector2(0, 2), 24.0, 8.0, Color(0, 0, 0, 0.25))
	var q := p + Vector2(0, bob)
	draw_line(q, q + Vector2(0, -40), INK, 4.0, true)
	var flag := PackedVector2Array([q + Vector2(0, -76), q + Vector2(38, -76), q + Vector2(28, -62), q + Vector2(38, -48), q + Vector2(0, -48)])
	draw_colored_polygon(flag, HERO_COL)
	flag.append(flag[0])
	draw_polyline(flag, INK, 3.0, true)
	draw_line(q + Vector2(0, -48), q + Vector2(0, -80), INK, 3.0, true)
	draw_circle(q + Vector2(0, -80), 6.0, BG)
	draw_arc(q + Vector2(0, -80), 6.0, 0, TAU, 16, INK, 3.0, true)
	draw_polyline(PackedVector2Array([q + Vector2(13, -66), q + Vector2(19, -58), q + Vector2(27, -68)]), Color(1, 1, 1, 0.9), 3.0, true)


## Moldura, cabeçalho, ato em vista, legenda, trilho de rolagem e o botão de fechar (fixos na tela).
func _draw_overlay() -> void:
	var u := maxf(k, 0.62)
	# Bordas escurecidas (hora azul) e moldura costurada.
	var vw := 120.0 * k
	var dark := Color(0.05, 0.07, 0.14, 0.34)
	var clear := Color(0.05, 0.07, 0.14, 0.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(vw + ox, 0), Vector2(vw + ox, size.y), Vector2(0, size.y)]), PackedColorArray([dark, clear, clear, dark]))
	draw_polygon(PackedVector2Array([Vector2(size.x - vw - ox, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(size.x - vw - ox, size.y)]), PackedColorArray([clear, dark, dark, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, 70 * k), Vector2(0, 70 * k)]), PackedColorArray([dark, dark, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, size.y - 70 * k), Vector2(size.x, size.y - 70 * k), Vector2(size.x, size.y), Vector2(0, size.y)]), PackedColorArray([clear, clear, dark, dark]))
	var fr := Rect2(Vector2(20, 20) * k, size - Vector2(40, 40) * k)
	var fp := PackedVector2Array([fr.position, Vector2(fr.end.x, fr.position.y), fr.end, Vector2(fr.position.x, fr.end.y), fr.position])
	_dashed(self, _offs(Vector2(0, 1.5), Array(fp)), Color(0, 0, 0, 0.3), 3.0 * maxf(k, 0.7), 14.0 * k, 9.0 * k, 0.0)
	_dashed(self, fp, PAPER, 3.0 * maxf(k, 0.7), 14.0 * k, 9.0 * k, 0.0)
	# Ato em vista (o do meio da tela), num cartucho no canto de cima.
	var cy := (scroll + size.y * 0.5) / k
	var av := 0
	for a in lay.size():
		if cy <= float(lay[a]["bottom"]) and cy >= float(lay[a]["top"]) - 200.0:
			av = a
	var nm := _act_name(av) if av <= sim.act else tr("UI_MAP_UNKNOWN")
	var nw := fell.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, int(30 * u)).x
	_plate(Rect2(Vector2(40, 40) * u, Vector2(maxf(360 * u, nw + 52 * u), 96 * u)))
	draw_string(fell_it, Vector2(64, 74) * u, tr("UI_ACT").format({"n": av + 1}), HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * u), Color(INK, 0.85))
	draw_string(fell, Vector2(64, 116) * u, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, int(30 * u), INK)
	# Título e instrução no alto, ao centro.
	var title := tr("UI_ROUTE_CHOOSE") if sim.route_wait else tr("UI_MAP_TITLE")
	var sub := (tr("UI_ROUTE_KEYS") if sim.route_wait else tr("UI_MAP_PICK")) + "  ·  " + tr("UI_MAP_SCROLL")
	var tw := maxf(fell.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(36 * u)).x, fell_it.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * u)).x) + 60 * u
	var tr_ := Rect2(Vector2((size.x - tw) * 0.5, 30 * u), Vector2(tw, 84 * u))
	_plate(tr_)
	draw_string(fell, Vector2(tr_.position.x, tr_.position.y + 44 * u), title, HORIZONTAL_ALIGNMENT_CENTER, tw, int(36 * u), INK)
	draw_string(fell_it, Vector2(tr_.position.x, tr_.position.y + 72 * u), sub, HORIZONTAL_ALIGNMENT_CENTER, tw, int(18 * u), Color(INK, 0.8))
	# Fechar (fora de uma bifurcação, onde a escolha é obrigatória).
	close_rect = Rect2()
	if not sim.route_wait:
		var label := tr("UI_MAP_CLOSE")
		var lw := fell.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * u)).x + 36 * u
		close_rect = Rect2(Vector2(size.x - 80 * u - lw, 40 * u), Vector2(lw, 48 * u))
		var over := close_rect.has_point(get_local_mouse_position())
		_plate(close_rect, over)
		draw_string(fell, close_rect.position + Vector2(0, 32 * u), label, HORIZONTAL_ALIGNMENT_CENTER, lw, int(22 * u), INK)
	# Legenda dos traços, no canto de baixo.
	var items := [["past", tr("UI_MAP_LEG_DONE")], ["plan", tr("UI_MAP_LEG_PLAN")], ["open", tr("UI_MAP_LEG_OPEN")], ["shut", tr("UI_MAP_LEG_SHUT")]]
	var lw2 := 0.0
	for it in items:
		lw2 = maxf(lw2, fell_it.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * u)).x)
	var lr := Rect2(Vector2(size.x - 100 * u - lw2 - 90 * u, size.y - 60 * u - items.size() * 26 * u), Vector2(lw2 + 110 * u, items.size() * 26 * u + 22 * u))
	_plate(lr)
	for i in items.size():
		var y := lr.position.y + 22 * u + i * 26 * u
		var a0 := Vector2(lr.position.x + 16 * u, y)
		var line := PackedVector2Array([a0, a0 + Vector2(64 * u, 0)])
		match items[i][0]:
			"past":
				draw_polyline(line, Color(ACC, 0.78), 6.0 * u, true)
			"plan":
				_dashed(self, line, ACC, 4.5 * u, 12.0 * u, 8.0 * u, fmod(t * 20.0 * u, 20.0 * u))
			"open":
				_dashed(self, line, INK, 3.5 * u, 10.0 * u, 7.0 * u, 0.0)
			"shut":
				_dots(self, line, Color(INK, 0.4), 2.4 * u, 9.0 * u)
		draw_string(fell_it, Vector2(a0.x + 78 * u, y + 6 * u), items[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * u), INK)
	# Trilho de rolagem: os atos, a janela da tela e o herói.
	rail_rect = Rect2(Vector2(size.x - 46 * u, 150 * u), Vector2(18 * u, size.y - 150 * u - lr.size.y - 90 * u))
	if rail_rect.size.y > 60.0:
		draw_rect(rail_rect, PAPER)
		for a in range(1, lay.size()):
			var yy := rail_rect.position.y + float(lay[a - 1]["end"]) / H * rail_rect.size.y
			_dashed(self, PackedVector2Array([Vector2(rail_rect.position.x, yy), Vector2(rail_rect.end.x, yy)]), Color(INK, 0.6), 2.0, 4.0, 3.0, 0.0)
		for a in range(sim.act + 1, lay.size()):
			var top := rail_rect.position.y + float(lay[a]["top"]) / H * rail_rect.size.y
			var bot := rail_rect.position.y + float(lay[a]["bottom"]) / H * rail_rect.size.y
			draw_rect(Rect2(Vector2(rail_rect.position.x, top), Vector2(rail_rect.size.x, bot - top)), Color(INK, 0.12))
		draw_rect(rail_rect, INK, false, 2.0)
		var vy := rail_rect.position.y + scroll / (H * k) * rail_rect.size.y
		var vh := size.y / (H * k) * rail_rect.size.y
		draw_rect(Rect2(Vector2(rail_rect.position.x - 5, vy), Vector2(rail_rect.size.x + 10, vh)), Color(1, 1, 1, 0.18))
		draw_rect(Rect2(Vector2(rail_rect.position.x - 5, vy), Vector2(rail_rect.size.x + 10, vh)), ACC, false, 3.0)
		var hy := rail_rect.position.y + _design_of_hero().y / H * rail_rect.size.y
		draw_circle(Vector2(rail_rect.get_center().x, hy), 6.0 * u, ACC)
		draw_arc(Vector2(rail_rect.get_center().x, hy), 6.0 * u, 0, TAU, 16, INK, 2.0, true)


## Placa da tela (ato, título, fechar, legenda): painel de feltro do kit, com sombra macia.
func _plate(r: Rect2, hot := false) -> void:

	draw_style_box(UiParch.box("gold" if hot else "ink", 10.0), r)


## De onde a party saiu (mapa da campanha, 16/11/2026): "Saída: Floresta de Ramagris" no começo do Ato I.
func _exit_name() -> String:
	if sim == null or sim.data == null:
		return ""
	var region := str(sim.data.phase(sim.campaign_phase).get("region", ""))
	return tr("UI_CAMPAIGN_EXIT").format({"r": tr("REGION_" + region)}) if region != "" else ""


func _act_name(a: int) -> String:
	var i := posmod(int(sim.run_seed) + a * 7, ACT_NAMES)
	return tr("UI_MAP_ACTNAME_%d_%d" % [a % 3, i])


# ---------------------------------------------------------------- terreno (pintado uma vez)

## A textura do terreno acompanha os pixels reais da janela (a tela usa o esticamento canvas_items).
func _screen_scale() -> float:
	return get_viewport().get_final_transform().get_scale().x if get_viewport() else 1.0


func _bake_id() -> String:
	return lay_key + "|%.3f" % _screen_scale()


func _bake() -> void:
	kt = minf(k * _screen_scale(), 2.0)
	var px := Vector2i(int(ceil(W * kt)), int(ceil(H * kt)))
	if px.y > 16000:
		kt *= 16000.0 / float(px.y)
		px = Vector2i(int(ceil(W * kt)), int(ceil(H * kt)))
	vp.size = px
	post.size = Vector2(px)
	bake_key = _bake_id()
	canvas.queue_redraw()
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE


var BL: Dictionary = {}           # ocupação larga (trilhas e locais: nada grande perto)
var BL2: Dictionary = {}          # ocupação estreita (árvores podem chegar mais perto)
var OC: Dictionary = {}           # o que o próprio terreno já ocupou


func _mark(grid: Dictionary, p: Vector2, rad: float) -> void:
	var cx := int(floor(p.x / CELL))
	var cy := int(floor(p.y / CELL))
	var n := int(ceil(rad / CELL))
	for i in range(-n, n + 1):
		for j in range(-n, n + 1):
			if i * i + j * j <= n * n:
				grid[Vector2i(cx + i, cy + j)] = true


func _block_rect(r: Rect2) -> void:
	var x := r.position.x
	while x < r.end.x:
		var y := r.position.y
		while y < r.end.y:
			var c := Vector2i(int(floor(x / CELL)), int(floor(y / CELL)))
			BL[c] = true
			BL2[c] = true
			y += CELL
		x += CELL


func _free(grid: Dictionary, p: Vector2) -> bool:
	return not grid.has(Vector2i(int(floor(p.x / CELL)), int(floor(p.y / CELL))))


static func coast_l(y: float) -> float:
	return 230.0 + 34.0 * sin(y / 230.0) + 22.0 * sin(y / 97.0 + 1.0)


static func coast_r(y: float) -> float:
	return 1690.0 - 34.0 * sin(y / 210.0 + 2.0) - 22.0 * sin(y / 89.0)


## Desenho de enfeite de um ato futuro (o Sim ainda não gerou a estrada): fileiras de 2 ou 3 "?" ligadas.
func _fake_layout(a: int) -> Dictionary:
	if fake.has(a):
		return fake[a]
	var r := RandomNumberGenerator.new()
	r.seed = _seed(a) + 5
	var L: Dictionary = lay[a]
	var lanes := _lanes()
	var rows: Array = [[Vector2(W * 0.5, L["start"])]]
	for row in int(L["rows"]):
		var pick: Array = range(lanes)
		var count := mini(r.randi_range(2, 3), lanes)
		while pick.size() > count:
			pick.remove_at(r.randi_range(0, pick.size() - 1))
		var rr: Array = []
		for ln in pick:
			rr.append(Vector2(X0 + (ln + 0.5) / float(lanes) * XW + r.randf_range(-22, 22), float(L["start"]) - (row + 1) * ROW_GAP + r.randf_range(-15, 15)))
		rows.append(rr)
	rows.append([Vector2(W * 0.5, L["end"])])
	var links: Array = []
	for i in rows.size() - 1:
		var A: Array = rows[i]
		var B: Array = rows[i + 1]
		var hit := {}
		for p in A:
			var best: Vector2 = B[0]
			for q in B:
				if absf(q.x - p.x) < absf(best.x - p.x):
					best = q
			links.append([p, best])
			hit[best] = true
		for q in B:
			if not hit.has(q):
				var best: Vector2 = A[0]
				for p in A:
					if absf(q.x - p.x) < absf(best.x - p.x):
						best = p
				links.append([best, q])
	fake[a] = {"rows": rows, "links": links}
	return fake[a]


func _fake_curve(a: int, i: int, p: Vector2, q: Vector2) -> PackedVector2Array:
	var dy := q.y - p.y
	var h1 := fposmod(sin(i * 91.7 + a * 5.3) * 43758.5, 1.0)
	var h2 := fposmod(sin(i * 47.1 + a * 2.9) * 24634.6, 1.0)
	return _cubic(p, p + Vector2((h1 - 0.5) * 150.0, dy * 0.4), q + Vector2((h2 - 0.5) * 150.0, -dy * 0.4), q, 18)


## Pontos e curvas de cada ato, para o terreno desviar (reais no atual e nos guardados; de enfeite nos futuros).
func _act_paths(a: int) -> Dictionary:
	var road := _road_of(a)
	var pts: Array = []
	var curves: Array = []
	if road != null:
		for n in road.nodes.size():
			pts.append(_dpos(a, road, n))
		for e in road.legs.size():
			curves.append(_curve(a, road, e))
	elif a > sim.act:
		var f := _fake_layout(a)
		for row in f["rows"]:
			pts.append_array(row)
		for i in f["links"].size():
			curves.append(_fake_curve(a, i, f["links"][i][0], f["links"][i][1]))
	else:
		# Ato passado sem a estrada guardada (run retomada): só a linha do meio, percorrida.
		curves.append(PackedVector2Array([Vector2(W * 0.5, lay[a]["start"]), Vector2(W * 0.5, lay[a]["end"])]))
	return {"pts": pts, "curves": curves}


func _paint_terrain(ci: CanvasItem) -> void:
	if sim == null or lay.is_empty():
		return
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(kt, kt))
	tf_bake = Transform2D(0.0, Vector2(kt, kt), 0.0, Vector2.ZERO)
	var r := RandomNumberGenerator.new()
	r.seed = _seed(0) + 101
	# Papel: cor de fundo, manchas e a textura do grão.
	ci.draw_rect(Rect2(0, 0, W, H), BG)
	# Sem manchas nem grão: a textura de feltro vem do shader map_cloth por cima do terreno.
	# Ocupação: locais, trilhas, nomes e cartuchos.
	BL.clear()
	BL2.clear()
	OC.clear()
	var paths: Array = []
	for a in lay.size():
		var ap := _act_paths(a)
		paths.append(ap)
		for p in ap["pts"]:
			_mark(BL, p, 95.0)
			_mark(BL2, p, 60.0)
			_block_rect(Rect2(p + Vector2(-120, 30), Vector2(240, 44)))
		for cv in ap["curves"]:
			var c: PackedVector2Array = cv
			for i in range(0, c.size(), 2):
				_mark(BL, c[i], 62.0)
				_mark(BL2, c[i], 38.0)
		_block_rect(Rect2(Vector2(W * 0.5 - 340, float(lay[a]["cart"]) - 100), Vector2(680, 200)))
	# Rios de verdade e as suas fozes antes do mar: a praia é desenhada já aberta na boca de cada rio.
	_build_river_geo()
	# Mar e costa, de cima a baixo.
	_paint_sea(ci, r)
	# Terreno de cada ato (rios primeiro; as feições por altura, de trás para a frente).
	for a in lay.size():
		_paint_act(ci, a, paths[a])
	# Atos já feitos: o caminho percorrido em tinta vermelha.
	for a in lay.size():
		if a < sim.act:
			_paint_past(ci, a, paths[a])
	# Ligação entre os atos: do portão de um ao início do outro, por baixo do cartucho.
	for a in range(1, lay.size()):
		var line := PackedVector2Array([Vector2(W * 0.5, lay[a - 1]["end"]), Vector2(W * 0.5, lay[a]["start"])])
		if a <= sim.act:
			_base_leg(ci, line, "road", 0.6)
			ci.draw_polyline(line, Color(ACC, 0.6), 7.0, true)
		else:
			_dashed(ci, line, Color(INK, 0.45), 4.0, 11.0, 8.0, 0.0)
	# Névoa sobre os atos que ainda não chegaram, com os "?" por cima.
	for a in range(sim.act + 1, lay.size()):
		_paint_fog(ci, a)
	# Cartuchos, rosas dos ventos, navios e serpentes.
	for a in lay.size():
		_cartouche(ci, Vector2(W * 0.5, lay[a]["cart"]), a, a > sim.act)
		var rs := RandomNumberGenerator.new()
		rs.seed = _seed(a) + 77
		var left := a % 2 == 1
		var mid := (float(lay[a]["top"]) + float(lay[a]["bottom"])) * 0.5
		_compass(ci, Vector2(130.0 if left else 1790.0, mid + rs.randf_range(-300, 300)))
		var sy := float(lay[a]["top"]) + rs.randf_range(200, 600)
		_ship(ci, Vector2(1800.0 if left else 115.0, sy), rs.randf_range(0.75, 0.95), rs)
		_serpent(ci, Vector2(115.0 if left else 1805.0, float(lay[a]["bottom"]) - rs.randf_range(250, 500)), rs.randf_range(0.5, 0.7), not left)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_sea(ci: CanvasItem, r: RandomNumberGenerator) -> void:
	var cl: Array = []
	var cr: Array = []
	var y := -40.0
	while y <= H + 40.0:
		cl.append(Vector2(coast_l(y), y))
		cr.append(Vector2(coast_r(y), y))
		y += 40.0
	var sea_l := PackedVector2Array([Vector2(0, -40)])
	sea_l.append_array(PackedVector2Array(cl))
	sea_l.append(Vector2(0, H + 40))
	var sea_r := PackedVector2Array([Vector2(W, -40)])
	sea_r.append_array(PackedVector2Array(cr))
	sea_r.append(Vector2(W, H + 40))
	ci.draw_colored_polygon(sea_l, SEA)
	ci.draw_colored_polygon(sea_r, SEA)
	for i in range(1, 5):
		var ll: Array = []
		var rl: Array = []
		for p in cl:
			ll.append(Vector2(p.x - i * 14 + sin(p.y / 60.0 + i) * 3.0, p.y))
		for p in cr:
			rl.append(Vector2(p.x + i * 14 + sin(p.y / 60.0 + i) * 3.0, p.y))
		var col := Color(INK, 0.7 - i * 0.13)
		for piece in _split_at_mouths(ll, -1, 40.0 + i * 16.0):
			if piece.size() >= 4:
				ci.draw_polyline(_smooth(piece, false, 3), col, 2.0 - i * 0.3, true)
		for piece in _split_at_mouths(rl, 1, 40.0 + i * 16.0):
			if piece.size() >= 4:
				ci.draw_polyline(_smooth(piece, false, 3), col, 2.0 - i * 0.3, true)
	_coast_line(ci, cl, r, -1)
	_coast_line(ci, cr, r, 1)
	# Ilhotas e rochedos.
	for i in int(H / 400.0):
		var yy := r.randf_range(200, H - 200)
		var left := r.randf() < 0.5
		var x := coast_l(yy) - r.randf_range(60, 150) if left else coast_r(yy) + r.randf_range(60, 150)
		if x < 60 or x > W - 60:
			continue
		var rw := r.randf_range(10, 30)
		_shape(ci, _smooth(_ell(Vector2(x, yy), rw, rw * 0.6, 7, r, 0.45), true), BG, 2.2)
		if rw > 18:
			ci.draw_polyline(_quad(Vector2(x - rw * 0.5, yy + 2), Vector2(x, yy - 6), Vector2(x + rw * 0.5, yy + 2)), INK, 1.2, true)


## Feições do terreno: cada uma guarda a semente e é desenhada por `_feat`, em ordem de altura.
var feats: Array = []


func _put(y: float, kind: String, args: Array, sd: int) -> void:
	feats.append([y, kind, args, sd])


func _ok(p: Vector2, rad: float, grid: Dictionary) -> bool:
	if not _free(grid, p) or not _free(OC, p):
		return false
	var q := rad * 0.6
	for i in 6:
		var a := i * 1.05
		var o := p + Vector2(cos(a) * q, sin(a) * q * 0.7)
		if not _free(grid, o) or not _free(OC, o):
			return false
	return true


func _spot(r: RandomNumberGenerator, y0: float, y1: float, rad: float, grid: Dictionary) -> Vector2:
	for i in 120:
		var y := r.randf_range(y0, y1)
		var lo := coast_l(y) + 50.0 + rad
		var hi := coast_r(y) - 50.0 - rad
		if hi <= lo:
			continue
		var p := Vector2(r.randf_range(lo, hi), y)
		if _ok(p, rad, grid):
			return p
	return Vector2.INF


func _paint_act(ci: CanvasItem, a: int, ap: Dictionary) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = _seed(a) + 303
	feats.clear()
	var y0: float = float(lay[a]["top"]) + 40.0
	var y1: float = float(lay[a]["bottom"]) - 20.0
	var biome := a % 3
	# Rios: atravessam as pontes do ato (ou passam em lugares de enfeite nos atos sem estrada).
	var cross: Array = []
	var road := _road_of(a)
	var real: Array = river_geo.get(a, [])
	if real.size() > 0:
		# Rios de verdade (15/11/2026): o mesmo traçado do mundo, pelos mesmos pontos de controle.
		for g in real:
			for p in g["land"]:
				_mark(BL2, p, 30.0)
				_mark(OC, p, 34.0)
				_mark(BL, p, 24.0)
			_river_to_sea(ci, g, r)
	if road != null and real.is_empty():
		var nb := 0
		for loc in road.locations:
			if loc["type"] == "bridge":
				if nb % 2 == 0:
					cross.append(_dpos(a, road, loc["node"]))
				nb += 1
	if cross.is_empty() and real.is_empty():
		cross.append(Vector2(r.randf_range(700, 1220), r.randf_range(y0 + 400, y1 - 400)))
	var rivers: Array = []
	for i in mini(cross.size(), 2):
		var b: Vector2 = cross[i]
		var dir := 1.0 if (i + a) % 2 == 0 else -1.0
		var key := [b + Vector2(dir * 300, -300), b + Vector2(dir * 90, -100), b, b + Vector2(-dir * 70, 90), b + Vector2(-dir * 320, 300)]
		var m: Array = []
		for s in key.size() - 1:
			for q in 5:
				var tq := q / 5.0
				var off := sin((s * 5 + q) * 1.25) * (30.0 if q % 2 == 1 else -26.0) * (0.35 if s == 1 or s == 2 else 1.0)
				m.append(Vector2(lerpf(key[s].x, key[s + 1].x, tq) + off, lerpf(key[s].y, key[s + 1].y, tq)))
		m.append(key[-1])
		var w := _wob(m, r, 18.0)
		rivers.append(w)
		for p in w:
			_mark(BL2, p, 30.0)
		_river(ci, w, r)
		# Cachoeira perto da nascente.
		var pa: Vector2 = w[2]
		var pb: Vector2 = w[3]
		var ang := (pb - pa).angle()
		var mm := (pa + pb) * 0.5
		var nrm := Vector2(-sin(ang), cos(ang))
		ci.draw_line(mm - nrm * 18, mm + nrm * 24, INK, 2.6, true)
		for kk in range(-2, 4):
			var s0 := mm + nrm * kk * 5.0 + Vector2(0, 2)
			ci.draw_polyline(_quad(s0, s0 + Vector2(r.randf_range(-1.5, 1.5), 6), s0 + Vector2(0, 10 + r.randf() * 4)), INK, 1.1, true)
		ci.draw_line(mm - nrm * 20, mm - nrm * 20 + Vector2(-6, -6), INK, 1.6, true)
		ci.draw_line(mm + nrm * 26, mm + nrm * 26 + Vector2(6, -6), INK, 1.6, true)
		_mark(OC, mm, 40.0)
	# Pontes onde um rio cruza uma trilha (longe dos locais) e marcos de légua ao lado das estradas.
	var bridges: Array = []
	for cv in ap["curves"]:
		var c: PackedVector2Array = cv
		for rv in rivers:
			for i in c.size() - 1:
				for j in rv.size() - 1:
					var x = Geometry2D.segment_intersects_segment(c[i], c[i + 1], rv[j], rv[j + 1])
					if x == null:
						continue
					var near := false
					for p in ap["pts"]:
						if (p as Vector2).distance_to(x) < 70.0:
							near = true
					for q in bridges:
						if (q as Vector2).distance_to(x) < 40.0:
							near = true
					if near:
						continue
					bridges.append(x)
					_bridge(ci, x, (c[i + 1] - c[i]).angle())
	if road != null:
		for e in road.legs.size():
			if _leg_kind(road, e) != "road" or r.randf() < 0.35:
				continue
			var c: PackedVector2Array = ap["curves"][e]
			var i := int(c.size() * r.randf_range(0.35, 0.65))
			var d := (c[mini(i + 1, c.size() - 1)] - c[i]).normalized()
			var side := 1.0 if r.randf() < 0.5 else -1.0
			var p := c[i] + Vector2(-d.y, d.x) * 16.0 * side
			var near := false
			for q in ap["pts"]:
				if (q as Vector2).distance_to(p) < 60.0:
					near = true
			if not near:
				_put(p.y, "milestone", [p], 0)
	# Feições por bioma: 0 bosque, campo e aldeia; 1 colina, brejo, mesa e ruína; 2 serra, vulcão e pinheiro.
	match biome:
		2:
			if a == lay.size() - 1:
				# A grande serra no alto do último ato.
				var cx0 := coast_l(300) + 80.0
				var span := coast_r(300) - coast_l(300) - 160.0
				for i in 16:
					var x := cx0 + i * span / 15.0 + r.randf_range(-15, 15)
					var y := 210.0 + r.randf() * 120.0
					if absf(x - W * 0.5) < 150.0 and y > 220.0:
						continue
					_put(y, "snow" if r.randf() < 0.55 else "peak", [x, y, r.randf_range(40, 60), r.randf_range(90, 130)], r.randi())
			_many(r, 2, y0 + 250, y1 - 200, 70, BL, func(p): _put(p.y, "volc", [p.x, p.y, r.randf_range(40, 52), r.randf_range(56, 70)], r.randi()))
			_many(r, 10, y0, y1, 80, BL, func(p): _range(r, p, 3 + r.randi() % 3, r.randf_range(20, 28), r.randf_range(42, 62), r.randf() < 0.7))
			_many(r, 22, y0, y1, 40, BL, func(p): _put(p.y, "snow" if r.randf() < 0.5 else "peak", [p.x, p.y, r.randf_range(20, 34), r.randf_range(40, 70)], r.randi()))
			_many(r, 4, y0, y1, 50, BL, func(p): _put(p.y, "cliff", [p.x, p.y, r.randf_range(34, 50)], r.randi()))
			_many(r, 3, y0, y1, 34, BL, func(p): _put(p.y, "cave", [p.x, p.y], r.randi()))
			_many(r, 3, y0, y1, 30, BL, func(p): _put(p.y, "tower", [p.x, p.y], r.randi()))
			_many(r, 2, y0, y1, 30, BL, func(p): _put(p.y, "ruin", [p.x, p.y], r.randi()))
			_many(r, 2, y0 + 200, y1, 60, BL, func(p): _put(p.y - 20, "lake", [p.x, p.y, r.randf_range(34, 50), r.randf_range(16, 24)], r.randi()))
			_many(r, 30, y0, y1, 30, BL2, func(p): _grove(r, p, ["f", "p"] if r.randf() < 0.75 else ["f", "x"], 4 + r.randi() % 6, 30.0, r.randf_range(1.0, 1.35)))
			_many(r, 80, y0, y1, 15, BL2, func(p): _put(p.y, ["f", "f", "p", "x"][r.randi() % 4], [p.x, p.y, r.randf_range(1.0, 1.5)], r.randi()))
		1:
			_many(r, 16, y0, y1, 60, BL, func(p): _hills(r, p, 2 + r.randi() % 3))
			_many(r, 4, y0, y1, 56, BL, func(p): _put(p.y, "mesa", [p.x, p.y, r.randf_range(34, 46), r.randf_range(24, 34)], r.randi()))
			_many(r, 8, y0, y1, 50, BL, func(p): _range(r, p, 2 + r.randi() % 2, r.randf_range(16, 22), r.randf_range(28, 44), false))
			_many(r, 3, y0, y1, 50, BL, func(p): _put(p.y, "cliff", [p.x, p.y, r.randf_range(30, 46)], r.randi()))
			_many(r, 3, y0, y1, 70, BL, func(p): _put(p.y - 20, "lake", [p.x, p.y, r.randf_range(40, 62), r.randf_range(18, 28)], r.randi()))
			_many(r, 6, y0, y1, 50, BL, func(p): _put(p.y, "marsh", [p.x, p.y], r.randi()))
			_many(r, 3, y0, y1, 34, BL, func(p): _put(p.y, "ruin", [p.x, p.y], r.randi()))
			_many(r, 2, y0, y1, 32, BL, func(p): _put(p.y, "stones", [p.x, p.y], r.randi()))
			_many(r, 1, y0, y1, 30, BL, func(p): _put(p.y, "tower", [p.x, p.y], r.randi()))
			_many(r, 2, y0, y1, 50, BL, func(p): _village(r, p, 2 + r.randi() % 2))
			_many(r, 2, y0, y1, 34, BL, func(p): _put(p.y, "cave", [p.x, p.y], r.randi()))
			_many(r, 32, y0, y1, 28, BL2, func(p): _grove(r, p, [["d", "r"], ["d", "b"], ["x", "b"], ["r", "p"]][r.randi() % 4], 4 + r.randi() % 5, 28.0, r.randf_range(0.95, 1.25)))
			_many(r, 100, y0, y1, 15, BL2, func(p): _put(p.y, ["d", "r", "b", "x", "p"][r.randi() % 5], [p.x, p.y, r.randf_range(0.9, 1.35)], r.randi()))
		_:
			_many(r, 4, y0, y1, 66, BL, func(p): _farm(r, p))
			_many(r, 4, y0, y1, 56, BL, func(p): _village(r, p, 3 + r.randi() % 3))
			_many(r, 3, y0, y1, 66, BL, func(p): _put(p.y - 20, "lake", [p.x, p.y, r.randf_range(40, 64), r.randf_range(18, 30)], r.randi()))
			_many(r, 2, y0, y1, 48, BL, func(p): _put(p.y, "marsh", [p.x, p.y], r.randi()))
			_many(r, 2, y0, y1, 32, BL, func(p): _put(p.y, "stones", [p.x, p.y], r.randi()))
			_many(r, 2, y0, y1, 32, BL, func(p): _put(p.y, "ruin", [p.x, p.y], r.randi()))
			_many(r, 1, y0, y1, 30, BL, func(p): _put(p.y, "tower", [p.x, p.y], r.randi()))
			_many(r, 4, y0, y1, 56, BL, func(p): _hills(r, p, 2 + r.randi() % 2))
			_many(r, 3, y0, y1, 50, BL, func(p): _range(r, p, 2, r.randf_range(16, 22), r.randf_range(26, 38), false))
			_many(r, 44, y0, y1, 34, BL2, func(p): _grove(r, p, [["d", "d", "r"], ["r", "b"], ["d", "p"], ["p", "p", "f"], ["d", "r", "b"]][r.randi() % 5], 6 + r.randi() % 7, 36.0, r.randf_range(1.05, 1.4)))
			_many(r, 110, y0, y1, 15, BL2, func(p): _put(p.y, ["d", "r", "b", "p", "d"][r.randi() % 5], [p.x, p.y, r.randf_range(0.95, 1.45)], r.randi()))
	feats.sort_custom(func(fa, fb): return fa[0] < fb[0])
	for f in feats:
		_feat(ci, f)
	feats.clear()


func _many(r: RandomNumberGenerator, n: int, y0: float, y1: float, rad: float, grid: Dictionary, fn: Callable) -> void:
	for i in n:
		var p := _spot(r, y0, y1, rad, grid)
		if p != Vector2.INF:
			fn.call(p)
			_mark(OC, p, rad)


func _grove(r: RandomNumberGenerator, c: Vector2, kinds: Array, n: int, spread: float, s0: float) -> void:
	var pts: Array = []
	for i in n * 3:
		if pts.size() >= n:
			break
		var a := r.randf() * TAU
		var d := sqrt(r.randf()) * spread
		var p := c + Vector2(cos(a) * d * 1.3, sin(a) * d * 0.8)
		if not _free(BL2, p):
			continue
		var crowd := false
		for q in pts:
			if absf(q.x - p.x) < 13.0 * s0 and absf(q.y - p.y) < 9.0 * s0:
				crowd = true
		if crowd:
			continue
		pts.append(p)
	for p in pts:
		_put(p.y, kinds[r.randi() % kinds.size()], [p.x, p.y, s0 * r.randf_range(0.8, 1.2)], r.randi())
	_mark(OC, c, spread * 0.9)


func _range(r: RandomNumberGenerator, c: Vector2, n: int, w0: float, h0: float, snowy: bool) -> void:
	for i in n:
		var off := i - (n - 1) * 0.5
		var cc := absf(off) / (n * 0.5)
		var y := c.y - 6.0 + cc * 10.0 + r.randf() * 6.0
		var hh := h0 * (1.15 - cc * 0.45) * r.randf_range(0.85, 1.1)
		_put(y, "snow" if snowy and hh > h0 * 0.95 else "peak", [c.x + off * w0 * 1.15 + r.randf_range(-5, 5), y, w0 * r.randf_range(0.85, 1.15), hh], r.randi())


func _hills(r: RandomNumberGenerator, c: Vector2, n: int) -> void:
	for i in n:
		var y := c.y + (i % 2) * 8.0
		_put(y, "hill", [c.x + (i - (n - 1) * 0.5) * r.randf_range(28, 38), y, r.randf_range(18, 28)], 0)


func _village(r: RandomNumberGenerator, c: Vector2, n: int) -> void:
	var church := r.randi() % n
	for i in n:
		var p := Vector2(c.x + (i - (n - 1) * 0.5) * 20.0 + r.randf_range(-5, 5), c.y + r.randf_range(-12, 12))
		_put(p.y, "house", [p.x, p.y, r.randf_range(11, 15), r.randf_range(8, 11), i == church and n >= 3], r.randi())
	_put(c.y + 18, "lane", [c.x - n * 12.0, c.y + 16, n * 24.0], 0)
	_mark(OC, c, n * 14.0 + 20.0)


func _farm(r: RandomNumberGenerator, c: Vector2) -> void:
	var n := 2 + r.randi() % 3
	var ang := r.randf_range(-0.25, 0.25)
	for i in n:
		var dx := (i % 2) * 46.0 - 23.0
		var dy := (i / 2) * 30.0 - 15.0
		_put(c.y + dy - 20, "field", [c.x + dx + r.randf_range(-3, 3), c.y + dy, r.randf_range(38, 48), r.randf_range(22, 30), ang], r.randi())
	if r.randf() < 0.55:
		var p := Vector2(c.x + r.randf_range(-40, 40), c.y + 34)
		_put(p.y, "windmill", [p.x, p.y], r.randi())
	_mark(OC, c, 62.0)


func _feat(ci: CanvasItem, f: Array) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = f[3]
	var g: Array = f[2]
	match f[1]:
		"d", "r", "p", "f", "x", "b":
			_tree(ci, f[1], Vector2(g[0], g[1]), g[2], r)
		"peak":
			_peak(ci, g[0], g[1], g[2], g[3], r)
		"snow":
			_snow(ci, g[0], g[1], g[2], g[3], r)
		"volc":
			_volcano(ci, g[0], g[1], g[2], g[3], r)
		"mesa":
			_mesa(ci, g[0], g[1], g[2], g[3], r)
		"cliff":
			_cliff(ci, g[0], g[1], g[2], r)
		"hill":
			var x: float = g[0]
			var y: float = g[1]
			var w: float = g[2]
			_hill_v(ci, x, y, w, r)
			return
		"lake":
			_lake(ci, Vector2(g[0], g[1]), g[2], g[3], r)
		"marsh":
			_marsh(ci, Vector2(g[0], g[1]), r)
		"house":
			_house(ci, g[0], g[1], g[2], g[3], g[4], r)
		"lane":
			_dashed(ci, _quad(Vector2(g[0], g[1]), Vector2(g[0] + g[2] * 0.5, g[1] + 8), Vector2(g[0] + g[2], g[1] - 2)), INK, 1.3, 4.0, 5.0, 0.0)
		"windmill":
			_windmill(ci, g[0], g[1], r)
		"field":
			_field(ci, g[0], g[1], g[2], g[3], g[4], r)
		"ruin":
			_ruin(ci, g[0], g[1])
		"tower":
			_tower(ci, g[0], g[1])
		"stones":
			_stones(ci, Vector2(g[0], g[1]), r)
		"cave":
			_cave(ci, g[0], g[1])
		"milestone":
			var p: Vector2 = g[0]
			_shape(ci, _poly([p + Vector2(-3, 0), p + Vector2(-3, -6)], _quad(p + Vector2(-3, -6), p + Vector2(0, -11), p + Vector2(3, -6)), [p + Vector2(3, 0)]), BG, 1.4)
			ci.draw_line(p + Vector2(-5, 0), p + Vector2(5, 0), INK, 1.0, true)


# ---------------------------------------------------------------- feições (porte do mapa.html, estilo A)

func _tree0(ci: CanvasItem, kind: String, p: Vector2, s: float, r: RandomNumberGenerator, leaf: Color, det: Color) -> void:
	var x := p.x
	var y := p.y
	match kind:
		"d":   # copa em nuvem
			ci.draw_line(p, p + Vector2(0, -7 * s), INK, 2.0, true)
			_shape(ci, _smooth(_ell(Vector2(x, y - 15 * s), 11 * s, 9 * s, 8, r, 0.4), true), leaf, 2.0)
			ci.draw_line(Vector2(x + 4 * s, y - 11 * s), Vector2(x + 8 * s, y - 14 * s), det, 1.2, true)
			ci.draw_line(Vector2(x + 2 * s, y - 8 * s), Vector2(x + 7 * s, y - 11 * s), det, 1.2, true)
		"r":   # copa redonda
			ci.draw_line(p, p + Vector2(0, -8 * s), INK, 2.0, true)
			ci.draw_line(p + Vector2(0, -6 * s), p + Vector2(-3 * s, -9 * s), INK, 2.0, true)
			ci.draw_circle(Vector2(x, y - 15 * s), 9 * s, leaf)
			ci.draw_arc(Vector2(x, y - 15 * s), 9 * s, 0, TAU, 20, INK, 2.0, true)
			ci.draw_arc(Vector2(x, y - 15 * s), 6 * s, -0.9, 0.9, 8, det, 1.3, true)
		"p":   # pinheiro em três andares
			ci.draw_line(p, p + Vector2(0, -5 * s), INK, 2.0, true)
			var w := 8.0 * s
			var h := 9.0 * s
			for i in 3:
				var yy := y - 5 * s - i * h * 0.75
				var ww := w * (1.0 - i * 0.25)
				_shape(ci, PackedVector2Array([Vector2(x - ww, yy), Vector2(x, yy - h * 1.25), Vector2(x + ww, yy)]), leaf, 1.8)
				ci.draw_line(Vector2(x + ww * 0.2, yy - h * 0.25), Vector2(x + ww * 0.7, yy - h * 0.05), det, 1.1, true)
		"f":   # abeto alto
			var h := 36.0 * s
			var w := 6.0 * s
			var b := y - 4 * s
			ci.draw_line(p, Vector2(x, b), INK, 2.0, true)
			var pts := PackedVector2Array([Vector2(x, b - h)])
			for i in range(1, 6):
				var tt := i / 5.0
				pts.append(Vector2(x + w * tt + (2 * s if i % 2 == 1 else 0.0), b - h + h * tt))
			pts.append(Vector2(x - w, b))
			for i in range(4, 0, -1):
				var tt := i / 5.0
				pts.append(Vector2(x - w * tt - (2 * s if i % 2 == 1 else 0.0), b - h + h * tt))
			_shape(ci, pts, leaf, 1.8)
			ci.draw_line(Vector2(x + 1, b - h * 0.6), Vector2(x + w * 0.6, b - 2 * s), det, 1.1, true)
		"x":   # árvore morta
			var h := 22.0 * s
			ci.draw_polyline(_quad(p, Vector2(x - 2 * s, y - h * 0.5), Vector2(x + s, y - h)), INK, 1.9, true)
			ci.draw_polyline(_quad(Vector2(x, y - h * 0.45), Vector2(x - 6 * s, y - h * 0.45 - 3 * s), Vector2(x - 9 * s, y - h * 0.45 - 10 * s)), INK, 1.9, true)
			ci.draw_line(Vector2(x - 5 * s, y - h * 0.62), Vector2(x - 10 * s, y - h * 0.62 - 2 * s), INK, 1.9, true)
			ci.draw_polyline(_quad(Vector2(x + 0.5 * s, y - h * 0.6), Vector2(x + 5.5 * s, y - h * 0.6 - 2 * s), Vector2(x + 8.5 * s, y - h * 0.6 - 9 * s)), INK, 1.9, true)
			ci.draw_line(Vector2(x + 5 * s, y - h * 0.78), Vector2(x + 10 * s, y - h * 0.78 - s), INK, 1.9, true)
			ci.draw_line(Vector2(x + s, y - h), Vector2(x - 2 * s, y - h - 4 * s), INK, 1.9, true)
			ci.draw_line(Vector2(x + s, y - h), Vector2(x + 4 * s, y - h - 3 * s), INK, 1.9, true)
			ci.draw_line(Vector2(x - 5 * s, y), Vector2(x + 5 * s, y), INK, 1.3, true)
		_:     # arbusto
			var pts := _poly([Vector2(x - 9 * s, y)], _quad(Vector2(x - 9 * s, y), Vector2(x - 11 * s, y - 8 * s), Vector2(x - 4 * s, y - 9 * s)),
				_quad(Vector2(x - 4 * s, y - 9 * s), Vector2(x, y - 14 * s), Vector2(x + 5 * s, y - 9 * s)),
				_quad(Vector2(x + 5 * s, y - 9 * s), Vector2(x + 12 * s, y - 9 * s), Vector2(x + 9 * s, y)))
			_shape(ci, pts, leaf, 1.8)


func _peak(ci: CanvasItem, x: float, y: float, w: float, h: float, r: RandomNumberGenerator) -> void:
	_mtn(ci, x, y, w, h, false, r)
	return


func _snow(ci: CanvasItem, x: float, y: float, w: float, h: float, r: RandomNumberGenerator) -> void:
	_mtn(ci, x, y, w, h, true, r)
	return


func _volcano(ci: CanvasItem, x: float, y: float, w: float, h: float, r: RandomNumberGenerator) -> void:
	var cw := w * 0.22
	var pts := _cubic(Vector2(x - w, y), Vector2(x - w * 0.55, y - h * 0.25), Vector2(x - cw * 1.3, y - h * 0.8), Vector2(x - cw, y - h), 10)
	pts.append_array(_cubic(Vector2(x + cw, y - h), Vector2(x + cw * 1.3, y - h * 0.8), Vector2(x + w * 0.55, y - h * 0.25), Vector2(x + w, y), 10))
	_fill(ci, pts, BG)
	ci.draw_polyline(pts, INK, 2.4, true)
	_ellipse(ci, Vector2(x, y - h), cw, cw * 0.32, Color(INK, 0.8))
	for i in range(1, 8):
		var tt := i / 8.0
		var s := Vector2(x + cw + (w - cw) * tt * 0.95, y - h + h * tt)
		ci.draw_line(s, s + Vector2(-w * 0.22, h * 0.12), INK, 1.3, true)
	ci.draw_polyline(_quad(Vector2(x - cw * 0.3, y - h), Vector2(x - cw * 0.3 - 4, y - h + h * 0.3), Vector2(x - cw * 0.3 + 3, y - h + h * 0.55)), INK, 1.3, true)
	ci.draw_polyline(_quad(Vector2(x + cw * 0.4, y - h), Vector2(x + cw * 0.4 + 5, y - h + h * 0.25), Vector2(x + cw * 0.4 - 1, y - h + h * 0.42)), INK, 1.3, true)
	# Fumaça em caracóis.
	var s := Vector2(x, y - h - 6)
	for i in 4:
		var rad := 5.0 + i * 3.0
		ci.draw_arc(s + Vector2(rad * 0.6, 0), rad * 0.75, PI, PI * 2.6, 12, INK, 1.6, true)
		s += Vector2(rad * 1.2 + 2, -(rad * 0.9 + 6))


func _mesa(ci: CanvasItem, x: float, y: float, w: float, h: float, r: RandomNumberGenerator) -> void:
	var tl := x - w * r.randf_range(0.55, 0.7)
	var trr := x + w * r.randf_range(0.45, 0.6)
	var pts := PackedVector2Array([Vector2(x - w, y), Vector2(tl, y - h * 0.7), Vector2(tl + 4, y - h)])
	for i in range(1, 4):
		pts.append(Vector2(tl + (trr - tl) * i / 4.0, y - h + (r.randf() - 0.5) * 4.0))
	pts.append_array([Vector2(trr, y - h), Vector2(trr + 3, y - h * 0.6), Vector2(x + w, y)])
	_fill(ci, pts, BG)
	ci.draw_polyline(pts, INK, 2.4, true)
	var xx := x - w * 0.15
	while xx < x + w - 6:
		var tt := y - h + 4 if xx < trr else y - h + (xx - trr) / (x + w - trr) * h + 4
		var ln := (y - tt) * r.randf_range(0.35, 0.8)
		if ln > 4:
			ci.draw_line(Vector2(xx, tt), Vector2(xx + (r.randf() - 0.5) * 1.5, tt + ln), INK, 1.1, true)
		xx += 4.5
	ci.draw_line(Vector2(tl + 3, y - h * 0.55), Vector2(tl, y - h * 0.25), INK, 1.1, true)
	ci.draw_line(Vector2(x - w - 6, y + 1), Vector2(x + w + 6, y + 1), Color(INK, 0.6), 1.2, true)


func _cliff(ci: CanvasItem, x: float, y: float, w: float, r: RandomNumberGenerator) -> void:
	var pts: Array = []
	var n := 7
	for i in n + 1:
		pts.append(Vector2(x - w + 2.0 * w * i / n, y + (r.randf() - 0.5) * 10.0))
	ci.draw_polyline(_smooth(pts, false, 4), INK, 2.6, true)
	for i in n * 2:
		var tt := (i + 0.5) / (n * 2)
		var j := int(tt * n)
		var u := tt * n - j
		var p: Vector2 = (pts[j] as Vector2).lerp(pts[j + 1], u)
		var ln := r.randf_range(4, 7) if i % 2 == 1 else r.randf_range(9, 15)
		var tri := PackedVector2Array([p + Vector2(-1.6, 2), p + Vector2((r.randf() - 0.5) * 2.0, 2 + ln), p + Vector2(1.6, 2)])
		ci.draw_colored_polygon(tri, INK)


func _lake(ci: CanvasItem, c: Vector2, rw: float, rh: float, r: RandomNumberGenerator) -> void:
	_shape(ci, _smooth(_ell(c, rw, rh, 10, r, 0.35), true), SEA, 2.6)
	var outer := _smooth(_ell(c, rw + 9, rh + 7, 10, r, 0.25), true)
	outer.append(outer[0])
	ci.draw_polyline(outer, Color(INK, 0.45), 1.0, true)
	for i in 3:
		var yy := c.y - rh * 0.4 + i * rh * 0.4
		var ww := rw * (0.5 - i * 0.1)
		var x0 := c.x - ww + (r.randf() - 0.5) * 10.0
		ci.draw_polyline(_quad(Vector2(x0, yy), Vector2(x0 + ww * 0.5, yy - 3), Vector2(x0 + ww, yy)), Color(INK, 0.7), 1.1, true)
		ci.draw_polyline(_quad(Vector2(x0 + ww, yy), Vector2(x0 + ww * 1.5, yy + 3), Vector2(x0 + ww * 2, yy)), Color(INK, 0.7), 1.1, true)
	for i in 4:
		var a := r.randf() * TAU
		var p := c + Vector2(cos(a) * (rw + 4), sin(a) * (rh + 3))
		ci.draw_line(p + Vector2(-3, 0), p + Vector2(-2, -6), INK, 1.2, true)
		ci.draw_line(p, p + Vector2(0, -8), INK, 1.2, true)
		ci.draw_line(p + Vector2(3, 0), p + Vector2(2, -6), INK, 1.2, true)


func _marsh(ci: CanvasItem, c: Vector2, r: RandomNumberGenerator) -> void:
	for i in 7:
		var p := c + Vector2(r.randf_range(-40, 40), r.randf_range(-18, 18))
		var hh := r.randf_range(6, 11)
		ci.draw_line(p + Vector2(-4, 0), p + Vector2(-2, -hh * 0.7), INK, 1.3, true)
		ci.draw_line(p, p + Vector2(0, -hh), INK, 1.3, true)
		ci.draw_line(p + Vector2(4, 0), p + Vector2(2, -hh * 0.7), INK, 1.3, true)
		ci.draw_line(p + Vector2(-7, 3), p + Vector2(7, 3), INK, 1.3, true)
	for i in 5:
		var p := c + Vector2(r.randf_range(-45, 45), r.randf_range(-14, 22))
		ci.draw_line(p, p + Vector2(r.randf_range(6, 14), 0), INK, 1.3, true)


## Casas, torres e ícones de construções no traço escolhido para o reino (CampaignArt, estilo Nórdico desde
## 16/11/2026): o mapa da run, o mapa da campanha e o menu usam o mesmo desenho. 
const ART_ICONS := {"tavern": "tavern", "shrine": "shrine", "gate": "gate", "lair": "lair", "shop": "shop", "start": "tent"}
var tf_live := Transform2D.IDENTITY
var tf_bake := Transform2D.IDENTITY
var art_of := {}


func _art(ci: CanvasItem) -> CampaignArt:
	var id := ci.get_instance_id()
	if not art_of.has(id):
		art_of[id] = CampaignArt.drawer(ci)
	return art_of[id]


func _house(ci: CanvasItem, x: float, y: float, w: float, h: float, steeple: bool, r: RandomNumberGenerator) -> void:
	var a := _art(ci)
	a.r.seed = r.randi()
	if steeple:
		a._church(Vector2(x, y), 0.72)
	else:
		a._house(Vector2(x, y), w * 1.15, h, w * 0.85, "tile", a.r.randf() < 0.5, 1)
	return


func _windmill(ci: CanvasItem, x: float, y: float, r: RandomNumberGenerator) -> void:
	_shape(ci, PackedVector2Array([Vector2(x - 7, y), Vector2(x - 4, y - 22), Vector2(x + 4, y - 22), Vector2(x + 7, y)]), BG, 1.8)
	_shape(ci, _quad(Vector2(x - 5, y - 25), Vector2(x, y - 31), Vector2(x + 5, y - 25)), BG2, 1.6)
	var c := Vector2(x, y - 24)
	var a0 := r.randf() * 1.5
	for i in 4:
		var a := a0 + i * PI * 0.5
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x) * 4.0
		ci.draw_line(c, c + d * 17.0, INK, 1.4, true)
		ci.draw_polyline(PackedVector2Array([c + d * 6.0, c + d * 6.0 + n, c + d * 17.0 + n, c + d * 17.0]), INK, 1.4, true)
	ci.draw_circle(c, 2.0, INK)


func _field(ci: CanvasItem, x: float, y: float, w: float, h: float, ang: float, r: RandomNumberGenerator) -> void:
	var c := cos(ang)
	var sn := sin(ang)
	var q := func(u: float, v: float) -> Vector2:
		return Vector2(x + u * w * c - v * h * sn + v * w * 0.12, y + u * w * sn * 0.5 + v * h * c)
	var p: Array = []
	for uv in [[-0.5, -0.5], [0.5, -0.5], [0.5, 0.5], [-0.5, 0.5]]:
		p.append(q.call(uv[0], uv[1]) + Vector2((r.randf() - 0.5) * 5.0, (r.randf() - 0.5) * 4.0))
	var outline := PackedVector2Array(p)
	outline.append(p[0])
	ci.draw_polyline(outline, INK, 1.6, true)
	var n := int(round(h / 7.0))
	var vert := r.randf() < 0.5
	for i in range(1, n):
		var tt := float(i) / n
		var a: Vector2 = (p[0] as Vector2).lerp(p[1], tt) if vert else (p[0] as Vector2).lerp(p[3], tt)
		var b: Vector2 = (p[3] as Vector2).lerp(p[2], tt) if vert else (p[1] as Vector2).lerp(p[2], tt)
		ci.draw_line(a, b, Color(INK, 0.75), 0.9, true)


func _ruin(ci: CanvasItem, x: float, y: float) -> void:
	var o := Vector2(x, y)
	_shape(ci, _offs(o, [Vector2(-14, 0), Vector2(-14, -20), Vector2(-11, -24), Vector2(-9, -21), Vector2(-7, -27), Vector2(-5, -25), Vector2(-5, 0)]), BG, 1.8)
	_shape(ci, _poly(_offs(o, [Vector2(-5, 0), Vector2(-5, -14)]), _quad(o + Vector2(-5, -14), o + Vector2(2, -23), o + Vector2(9, -14)), _offs(o, [Vector2(9, 0)])), BG, 1.8)
	_shape(ci, _offs(o, [Vector2(9, 0), Vector2(9, -10), Vector2(12, -8), Vector2(14, -13), Vector2(17, -10), Vector2(17, 0)]), BG, 1.8)
	ci.draw_polyline(_quad(o + Vector2(-6, -1), o + Vector2(0, -12), o + Vector2(6, -1)), INK, 1.2, true)
	_shape(ci, _offs(o, [Vector2(20, 1), Vector2(26, 1), Vector2(26, -3), Vector2(20, -3)]), BG, 1.3)
	_shape(ci, _offs(o, [Vector2(-24, 2), Vector2(-19, 2), Vector2(-19, -1), Vector2(-24, -1)]), BG, 1.3)


func _tower(ci: CanvasItem, x: float, y: float) -> void:
	var a := _art(ci)
	a.r.seed = hash(Vector2i(int(x), int(y)))
	a._tower(Vector2(x, y), 13, 30, "", true)
	return


func _stones(ci: CanvasItem, c: Vector2, r: RandomNumberGenerator) -> void:
	var n := 5 + r.randi() % 3
	var lst: Array = []
	for i in n:
		var a := float(i) / n * TAU + r.randf() * 0.3
		lst.append(c + Vector2(cos(a) * 18.0, sin(a) * 7.0))
	lst.sort_custom(func(p, q): return p.y < q.y)
	for p in lst:
		var hh := r.randf_range(8, 13)
		_shape(ci, _poly([p + Vector2(-3, 0), p + Vector2(-3, -hh + 2)], _quad(p + Vector2(-3, -hh + 2), p + Vector2(0, -hh - 2), p + Vector2(3, -hh + 2)), [p + Vector2(3, 0)]), BG, 1.6)
	if r.randf() < 0.5:
		ci.draw_line(c + Vector2(-7, -12), c + Vector2(7, -12), INK, 2.2, true)


func _cave(ci: CanvasItem, x: float, y: float) -> void:
	var o := Vector2(x, y)
	var hump := _poly(_quad(o + Vector2(-26, 0), o + Vector2(-22, -16), o + Vector2(-12, -22)), _quad(o + Vector2(-12, -22), o + Vector2(-4, -30), o + Vector2(4, -25)),
		_quad(o + Vector2(4, -25), o + Vector2(14, -23), o + Vector2(17, -13)), _quad(o + Vector2(17, -13), o + Vector2(21, -6), o + Vector2(26, 0)))
	_fill(ci, hump, BG)
	ci.draw_polyline(hump, INK, 2.2, true)
	var mouth := _poly([o + Vector2(-8, 0)], _quad(o + Vector2(-8, 0), o + Vector2(-8, -13), o + Vector2(1, -13)), _quad(o + Vector2(1, -13), o + Vector2(10, -13), o + Vector2(10, 0)))
	_fill(ci, mouth, INK)
	ci.draw_line(o + Vector2(12, -14), o + Vector2(18, -10), INK, 1.2, true)
	ci.draw_line(o + Vector2(16, -8), o + Vector2(22, -5), INK, 1.2, true)
	ci.draw_line(o + Vector2(-18, -6), o + Vector2(-13, -8), INK, 1.2, true)


func _bridge(ci: CanvasItem, p: Vector2, ang: float) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	var hl := 13.0
	var hw := 6.0
	ci.draw_colored_polygon(PackedVector2Array([p - d * hl - n * hw, p + d * hl - n * hw, p + d * hl + n * hw, p - d * hl + n * hw]), BG)
	for sd in [-1.0, 1.0]:
		var o: Vector2 = n * hw * sd
		ci.draw_line(p - d * hl + o, p + d * hl + o, INK, 1.8, true)
		ci.draw_line(p - d * hl + o, p - d * (hl + 4) + o * 1.4, INK, 1.8, true)
		ci.draw_line(p + d * hl + o, p + d * (hl + 4) + o * 1.4, INK, 1.8, true)


## Ato percorrido: o caminho feito em tinta vermelha, os outros ramos apagados, os locais pequenos e desbotados.
func _paint_past(ci: CanvasItem, a: int, ap: Dictionary) -> void:
	var road := _road_of(a)
	if road == null:
		var c: PackedVector2Array = ap["curves"][0]
		_base_leg(ci, c, "road", 0.5)
		ci.draw_polyline(c, Color(ACC, 0.55), 6.0, true)
		return
	for e in road.legs.size():
		var c: PackedVector2Array = ap["curves"][e]
		if road.legs[e]["chosen"] == 0:
			_base_leg(ci, c, _leg_kind(road, e), 0.5)
			ci.draw_polyline(c, Color(ACC, 0.7), 7.0, true)
		else:
			_dots(ci, c, Color(INK, 0.3), 2.6, 11.0)
	for loc in road.locations:
		var n: int = loc["node"]
		var p := _dpos(a, road, n)
		var on := road.path.has(n)
		_badge(ci, p, 0.9, 0.85)
		_icon(ci, p, str(loc["type"]), 0.9, 0.85 if on else 0.4)
		if on:
			_tick(ci, p + Vector2(24, -24))
		_label(ci, p + Vector2(0, 58), tr("LOC_" + str(loc["type"])), 22, Color(INK, 0.8 if on else 0.45))
	_badge(ci, _dpos(a, road, 0), 0.9, 0.85)
	_icon(ci, _dpos(a, road, 0), "start", 0.9, 0.8)
	if a == 0 and _exit_name() != "":
		_label(ci, _dpos(a, road, 0) + Vector2(0, 60), _exit_name(), 22, Color(INK, 0.8))
	var pe := _dpos(a, road, road.nodes.size() - 1)
	_badge(ci, pe, 1.0, 0.9)
	_icon(ci, pe, "gate", 1.0, 0.9)
	_tick(ci, pe + Vector2(26, -26))


## Névoa de um ato futuro: papel desbotado por cima do terreno, nuvens macias e os locais "?" de enfeite.
func _paint_fog(ci: CanvasItem, a: int) -> void:
	var f := _fake_layout(a)
	for i in f["links"].size():
		_dots(ci, _fake_curve(a, i, f["links"][i][0], f["links"][i][1]), Color(INK, 0.5), 3.0, 12.0)
	var top := 0.0 if a == lay.size() - 1 else float(lay[a]["end"]) - 60.0
	var bot := float(lay[a - 1]["end"]) - 70.0
	var fogc := Color(FOG, 0.86)
	var edge := Color(FOG, 0.0)
	if a - 1 > sim.act:
		# O ato de baixo também está na névoa: as duas emendam sem borda (a borda macia só no limite com o ato atual).
		ci.draw_rect(Rect2(0, top, W, float(lay[a - 1]["end"]) - 60.0 - top), fogc)
	else:
		ci.draw_rect(Rect2(0, top, W, bot - top - 90.0), fogc)
		ci.draw_polygon(PackedVector2Array([Vector2(0, bot - 90.0), Vector2(W, bot - 90.0), Vector2(W, bot), Vector2(0, bot)]), PackedColorArray([fogc, fogc, edge, edge]))
	var r := RandomNumberGenerator.new()
	r.seed = _seed(a) + 909
	var puff := _puff_tex()
	for i in int((bot - top) / 40.0):
		var c := Vector2(r.randf() * W, r.randf_range(top, bot))
		var rad := r.randf_range(110, 290)
		ci.draw_texture_rect(puff, Rect2(c - Vector2(rad * 1.5, rad), Vector2(rad * 3.0, rad * 2.0)), false, Color(FOG.lightened(0.15), 0.55))
	for i in 14:
		var c := Vector2(r.randf() * W, bot - 30.0)
		ci.draw_texture_rect(puff, Rect2(c - Vector2(260, 120), Vector2(520, 240)), false, Color(FOG.lightened(0.1), 0.7))
	for row in f["rows"]:
		for p in row:
			ci.draw_circle(p, 30.0, Color(FOG, 0.9))
			_dashed_arc(ci, p, 30.0, Color(INK, 0.6), 2.5)
			ci.draw_string(fell, p + Vector2(-60, 13), "?", HORIZONTAL_ALIGNMENT_CENTER, 120, 38, Color(INK, 0.6))


# ---------------------------------------------------------------- locais, cartucho e enfeites

## Selo do local: halo de papel, anel a tinta e um anel tracejado por dentro.
func _badge(ci: CanvasItem, p: Vector2, s: float, alpha: float) -> void:
	ci.draw_circle(p, 38.0 * s, Color(PAPER, 0.96))
	ci.draw_arc(p, 36.0 * s, 0, TAU, 44, Color(INK, alpha), 2.5, true)
	_dashed_arc(ci, p, 32.0 * s, Color(INK, alpha * 0.9), 1.0)


## Selo de cera vermelho-escuro com uma caveira em tinta clara: marca as disputas difíceis (pulsa de leve).
func _skull_seal(ci: CanvasItem, c: Vector2, alpha: float, time: float) -> void:
	var pulse := 0.5 + 0.5 * sin(time * 3.2)
	var wax := Color(0.5, 0.09, 0.07)
	var bone := Color(0.98, 0.93, 0.8)
	var ink := Color(INK, alpha)
	if alpha > 0.9:
		ci.draw_arc(c, 24.0 + 3.0 * pulse, 0, TAU, 32, Color(ACC, 0.55 - 0.3 * pulse), 3.0, true)
	ci.draw_circle(c + Vector2(1.5, 2.5), 21.0, Color(0, 0, 0, 0.28 * alpha))
	# Selo de cera com borda irregular
	var pts := PackedVector2Array()
	for i in 20:
		var a := i * TAU / 20.0
		pts.append(c + Vector2(cos(a), sin(a)) * (21.0 + (1.6 if i % 2 == 0 else -0.6)))
	ci.draw_colored_polygon(pts, Color(wax, alpha))
	pts.append(pts[0])
	ci.draw_polyline(pts, ink, 2.5, true)
	ci.draw_arc(c, 16.5, 0, TAU, 28, Color(bone, 0.35 * alpha), 1.2, true)
	# Caveira: crânio, mandíbula, órbitas, nariz e dentes
	var b := Color(bone, alpha)
	ci.draw_circle(c + Vector2(0, -3), 11.0, b)
	ci.draw_rect(Rect2(c + Vector2(-6.5, 3.0), Vector2(13.0, 8.5)), b)
	ci.draw_arc(c + Vector2(0, -3), 11.0, 0, TAU, 24, ink, 1.6, true)
	ci.draw_circle(c + Vector2(-4.5, -3.0), 3.3, ink)
	ci.draw_circle(c + Vector2(4.5, -3.0), 3.3, ink)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, 1.0), c + Vector2(-2, 4.5), c + Vector2(2, 4.5)]), ink)
	for k in [-3.0, 0.0, 3.0]:
		ci.draw_line(c + Vector2(k, 7.0), c + Vector2(k, 11.0), ink, 1.3, true)
	ci.draw_line(c + Vector2(-6.5, 11.5), c + Vector2(6.5, 11.5), ink, 1.6, true)


func _tick(ci: CanvasItem, p: Vector2) -> void:
	ci.draw_circle(p, 11.0, ACC)
	ci.draw_arc(p, 11.0, 0, TAU, 20, INK, 2.0, true)
	ci.draw_polyline(PackedVector2Array([p + Vector2(-5, 0), p + Vector2(-1, 5), p + Vector2(6, -4)]), Color(1, 1, 1), 3.0, true)


## Ícone a tinta de cada tipo de local (o mesmo desenho do mapa.html, estilo A).
func _icon(ci: CanvasItem, c: Vector2, ty: String, s: float, alpha: float) -> void:
	if ART_ICONS.has(ty):
		_art(ci).icon(ART_ICONS[ty], tf_live if ci == self else tf_bake, c, s * 0.85, hash(ty) ^ hash(Vector2i(c)))
		if alpha < 0.99:
			ci.draw_circle(c, 34.0 * s, Color(PAPER, (1.0 - alpha) * 0.85))
		return
	var ink := Color(INK, alpha)
	var f1 := Color(F1, alpha)
	var f2 := Color(F2, alpha)
	var f3 := Color(F3, alpha)
	var f4 := Color(ACC, alpha)
	var w := 2.5
	var P := func(pts: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for q in pts:
			out.append(c + (q as Vector2) * s)
		return out
	var L := func(a: Vector2, b: Vector2) -> void:
		ci.draw_line(c + a * s, c + b * s, ink, w, true)
	match ty:
		"shop":
			_shape(ci, P.call([Vector2(-22, -2), Vector2(-22, 20), Vector2(22, 20), Vector2(22, -2)]), f3, w, ink)
			_shape(ci, P.call([Vector2(-26, -2), Vector2(-20, -18), Vector2(20, -18), Vector2(26, -2)]), f2, w, ink)
			L.call(Vector2(-13, -18), Vector2(-17, -2))
			L.call(Vector2(0, -18), Vector2(0, -2))
			L.call(Vector2(13, -18), Vector2(17, -2))
			_disc(ci, c + Vector2(-9, 10) * s, 5 * s, f1, ink, w)
			_disc(ci, c + Vector2(8, 12) * s, 4 * s, f4, ink, w)
		"tavern":
			_shape(ci, P.call([Vector2(-22, 20), Vector2(-22, -4), Vector2(0, -22), Vector2(22, -4), Vector2(22, 20)]), f3, w, ink)
			_shape(ci, P.call([Vector2(-6, 20), Vector2(-6, 6), Vector2(6, 6), Vector2(6, 20)]), ink, w, ink)
			_shape(ci, P.call([Vector2(-17, 0), Vector2(-8, 0), Vector2(-8, 8), Vector2(-17, 8)]), f1, w, ink)
			ci.draw_polyline(P.call([Vector2(12, -8), Vector2(12, -20), Vector2(18, -20), Vector2(18, -3)]), ink, w, true)
			ci.draw_arc(c + Vector2(17, -28) * s, 4 * s, PI * 0.5, PI * 1.5, 8, ink, w, true)
		"fountain":
			_shape(ci, P.call([Vector2(-24, 12), Vector2(24, 12), Vector2(18, 22), Vector2(-18, 22)]), f2, w, ink)
			L.call(Vector2(0, 12), Vector2(0, -12))
			var bowl := _quad(c + Vector2(-16, -12) * s, c + Vector2(0, 2) * s, c + Vector2(16, -12) * s)
			_shape(ci, bowl, f4, w, ink)
			ci.draw_polyline(_quad(c + Vector2(-9, -18) * s, c + Vector2(-13, -10) * s, c + Vector2(-9, -8) * s), ink, w, true)
			ci.draw_polyline(_quad(c + Vector2(9, -18) * s, c + Vector2(13, -10) * s, c + Vector2(9, -8) * s), ink, w, true)
			L.call(Vector2(0, -24), Vector2(0, -18))
			_disc(ci, c + Vector2(0, -26) * s, 2 * s, f4, ink, 1.5)
		"ritual":
			_disc(ci, c, 24 * s, f1, ink, w)
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI * 0.5 + i * PI / 5.0
				star.append(c + Vector2(cos(a), sin(a)) * (15.0 if i % 2 == 0 else 6.0) * s)
			_shape(ci, star, f4, 1.8, ink)
			ci.draw_arc(c, 8 * s, 0, TAU, 16, ink, 1.5, true)
			for q in [Vector2(-3, -30), Vector2(-3, 22)]:
				_shape(ci, P.call([q, q + Vector2(6, 0), q + Vector2(6, 8), q + Vector2(0, 8)]), f2, 1.8, ink)
			for q in [Vector2(-30, -3), Vector2(22, -3)]:
				_shape(ci, P.call([q, q + Vector2(8, 0), q + Vector2(8, 6), q + Vector2(0, 6)]), f2, 1.8, ink)
		"shrine":
			_shape(ci, P.call([Vector2(-24, -6), Vector2(0, -24), Vector2(24, -6)]), f4, w, ink)
			_shape(ci, P.call([Vector2(-18, -6), Vector2(18, -6), Vector2(18, -1), Vector2(-18, -1)]), f1, w, ink)
			for x in [-13.0, 0.0, 13.0]:
				L.call(Vector2(x, -1), Vector2(x, 18))
			_shape(ci, P.call([Vector2(-22, 18), Vector2(22, 18), Vector2(22, 23), Vector2(-22, 23)]), f2, w, ink)
			_disc(ci, c + Vector2(0, -12) * s, 3 * s, f3, ink, 1.5)
		"bridge":
			var arch := _quad(c + Vector2(-24, 4) * s, c + Vector2(0, -30) * s, c + Vector2(24, 4) * s)
			_shape(ci, arch, f2, w, ink)
			L.call(Vector2(-30, 4), Vector2(30, 4))
			for q in [[Vector2(-30, 4), Vector2(-30, -4)], [Vector2(30, 4), Vector2(30, -4)], [Vector2(-20, -2), Vector2(-20, 4)], [Vector2(0, -8), Vector2(0, 4)], [Vector2(20, -2), Vector2(20, 4)]]:
				L.call(q[0], q[1])
			var wave := PackedVector2Array()
			for i in 25:
				var x := -26.0 + i * 2.0
				wave.append(c + Vector2(x, 16.0 - sin(i * PI / 3.0) * 2.5) * s)
			ci.draw_polyline(wave, ink, w, true)
		"event":
			ci.draw_polyline(P.call([Vector2(-22, 22), Vector2(0, 2), Vector2(22, 22)]), ink, w, true)
			L.call(Vector2(0, 22), Vector2(0, 2))
			ci.draw_line(c + Vector2(-26, 22) * s, c + Vector2(26, 22) * s, f2, w, true)
			ci.draw_arc(c + Vector2(0, -16) * s, 9 * s, PI * 0.95, PI * 2.35, 14, ink, w + 1.4, true)
			ci.draw_polyline(_quad(c + Vector2(6.5, -9.5) * s, c + Vector2(0, -6) * s, c + Vector2(0, -2) * s), ink, w + 1.4, true)
			_disc(ci, c + Vector2(0, 8) * s, 2.6 * s, f4, ink, 1.2)
		"gate":
			_shape(ci, P.call([Vector2(-14, -14), Vector2(14, -14), Vector2(14, 22), Vector2(-14, 22)]), f2, w, ink)
			for sx in [-1.0, 1.0]:
				_shape(ci, P.call([Vector2(14 * sx, 22), Vector2(14 * sx, -18), Vector2(18 * sx, -18), Vector2(18 * sx, -22), Vector2(22 * sx, -22), Vector2(22 * sx, -18), Vector2(26 * sx, -18), Vector2(26 * sx, 22)]), f2, w, ink)
			var arch := _poly([c + Vector2(-9, 22) * s, c + Vector2(-9, 4) * s], _quad(c + Vector2(-9, 4) * s, c + Vector2(0, -10) * s, c + Vector2(9, 4) * s), [c + Vector2(9, 22) * s])
			_shape(ci, arch, ink, w, ink)
			L.call(Vector2(-28, 22), Vector2(28, 22))
			L.call(Vector2(0, -14), Vector2(0, -30))
			_shape(ci, P.call([Vector2(0, -30), Vector2(11, -26), Vector2(0, -21)]), f4, 1.8, ink)
		"lair":
			_shape(ci, P.call([Vector2(-24, 22), Vector2(-24, -4), Vector2(-18, -10), Vector2(-18, -22), Vector2(-9, -15), Vector2(0, -30), Vector2(9, -15), Vector2(18, -22), Vector2(18, -10), Vector2(24, -4), Vector2(24, 22)]), f2, w, ink)
			var door := _poly([c + Vector2(-8, 22) * s, c + Vector2(-8, 6) * s], _quad(c + Vector2(-8, 6) * s, c + Vector2(0, -2) * s, c + Vector2(8, 6) * s), [c + Vector2(8, 22) * s])
			_shape(ci, door, ink, w, ink)
			_disc(ci, c + Vector2(-7, -4) * s, 3 * s, f3, ink, 1.5)
			_disc(ci, c + Vector2(7, -4) * s, 3 * s, f3, ink, 1.5)
			ci.draw_polyline(_quad(c + Vector2(-24, -4) * s, c + Vector2(-32, -12) * s, c + Vector2(-28, -18) * s), ink, w, true)
			ci.draw_polyline(_quad(c + Vector2(24, -4) * s, c + Vector2(32, -12) * s, c + Vector2(28, -18) * s), ink, w, true)
		"helper":   # herói ajudante: figura com escudo e lança
			_shape(ci, _poly([c + Vector2(-12, 22) * s, c + Vector2(-10, -4) * s], _quad(c + Vector2(-10, -4) * s, c + Vector2(0, -10) * s, c + Vector2(10, -4) * s), [c + Vector2(12, 22) * s]), f4, w, ink)
			_disc(ci, c + Vector2(0, -16) * s, 8 * s, f1, ink, w)
			_shape(ci, _quad(c + Vector2(-14, -26) * s, c + Vector2(0, -36) * s, c + Vector2(14, -26) * s), f2, w, ink)
			L.call(Vector2(16, -12), Vector2(24, 18))
			L.call(Vector2(13, -4), Vector2(23, -4))
			_shape(ci, _poly(_quad(c + Vector2(-12, -4) * s, c + Vector2(-26, -2) * s, c + Vector2(-20, 14) * s), _quad(c + Vector2(-20, 14) * s, c + Vector2(-12, 12) * s, c + Vector2(-12, 4) * s)), f3, w, ink)
		_:   # início do ato: tenda com bandeirola
			_shape(ci, P.call([Vector2(-22, 20), Vector2(0, -16), Vector2(22, 20)]), f2, w, ink)
			_shape(ci, P.call([Vector2(-7, 20), Vector2(0, 4), Vector2(7, 20)]), ink, w, ink)
			L.call(Vector2(0, -16), Vector2(0, -30))
			_shape(ci, P.call([Vector2(0, -30), Vector2(12, -26), Vector2(0, -21)]), f4, 1.8, ink)


func _label(ci: CanvasItem, at: Vector2, s: String, fs: int, col: Color) -> void:
	var w := 420.0
	ci.draw_string_outline(fell, at - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_CENTER, w, fs, 8, Color(BG, 0.95))
	ci.draw_string(fell, at - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_CENTER, w, fs, col)


## Cartucho do ato: faixa com pontas recortadas, placa dupla, "Ato N" em itálico e o nome inventado.
func _cartouche(ci: CanvasItem, c: Vector2, a: int, fogged: bool) -> void:
	var al := 0.5 if fogged else 1.0
	var ink := Color(INK, al)
	var band := PackedVector2Array([c + Vector2(-320, -40), c + Vector2(320, -40), c + Vector2(320, -30), c + Vector2(354, -30), c + Vector2(338, 0), c + Vector2(354, 30),
		c + Vector2(320, 30), c + Vector2(320, 40), c + Vector2(-320, 40), c + Vector2(-320, 30), c + Vector2(-354, 30), c + Vector2(-338, 0), c + Vector2(-354, -30), c + Vector2(-320, -30)])
	_shape(ci, band, Color(BG2, al), 3.0, ink)
	var plate := Rect2(c + Vector2(-300, -48), Vector2(600, 96))
	ci.draw_rect(plate, Color(PAPER, al))
	ci.draw_rect(plate, ink, false, 3.0)
	ci.draw_rect(plate.grow(-8.0), ink, false, 1.6)
	ci.draw_string(fell_it, c + Vector2(-300, -10), tr("UI_ACT").format({"n": a + 1}), HORIZONTAL_ALIGNMENT_CENTER, 600, 28, Color(INK, 0.85 * al))
	var nm := _act_name(a) if not fogged else tr("UI_MAP_UNKNOWN")
	ci.draw_string(fell, c + Vector2(-300, 32), nm, HORIZONTAL_ALIGNMENT_CENTER, 600, 40, ink)


func _compass(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_circle(c, 92.0, Color(BG, 0.6))
	ci.draw_arc(c, 92.0, 0, TAU, 64, INK, 2.4, true)
	ci.draw_arc(c, 84.0, 0, TAU, 64, INK, 1.4, true)
	_star(ci, c, 4, 88.0, 22.0, -PI * 0.5, BG)
	_star(ci, c, 4, 60.0, 16.0, -PI * 0.25, Color(INK, 0.85))
	var s8 := PackedVector2Array()
	for i in 17:
		var a := i * PI / 8.0
		s8.append(c + Vector2(cos(a), sin(a)) * (44.0 if i % 2 == 0 else 12.0))
	ci.draw_polyline(s8, INK, 2.0, true)
	ci.draw_string(fell, c + Vector2(-40, -98), "N", HORIZONTAL_ALIGNMENT_CENTER, 80, 34, INK)
	ci.draw_string(fell, c + Vector2(-40, 122), "S", HORIZONTAL_ALIGNMENT_CENTER, 80, 24, INK)
	ci.draw_string(fell, c + Vector2(-148, 9), tr("UI_MAP_WEST"), HORIZONTAL_ALIGNMENT_CENTER, 80, 24, INK)
	ci.draw_string(fell, c + Vector2(68, 9), tr("UI_MAP_EAST"), HORIZONTAL_ALIGNMENT_CENTER, 80, 24, INK)


func _star(ci: CanvasItem, c: Vector2, n: int, R: float, ri: float, rot: float, fill: Color) -> void:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := rot + i * PI / n
		pts.append(c + Vector2(cos(a), sin(a)) * (ri if i % 2 == 1 else R))
	_shape(ci, pts, fill, 2.0)


func _ship(ci: CanvasItem, c: Vector2, s: float, r: RandomNumberGenerator) -> void:
	var P := func(pts: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for q in pts:
			out.append(c + (q as Vector2) * s)
		return out
	var hull := _poly(_quad(c + Vector2(-30, 0) * s, c + Vector2(0, 22) * s, c + Vector2(30, 0) * s), [c + Vector2(24, -8) * s, c + Vector2(-24, -8) * s])
	_shape(ci, hull, PAPER, 2.4)
	ci.draw_line(c + Vector2(0, -8) * s, c + Vector2(0, -52) * s, INK, 2.4, true)
	_shape(ci, _poly(_quad(c + Vector2(0, -50) * s, c + Vector2(22, -40) * s, c + Vector2(20, -20) * s), [c + Vector2(0, -20) * s]), PAPER, 2.4)
	_shape(ci, _poly(_quad(c + Vector2(0, -44) * s, c + Vector2(-18, -36) * s, c + Vector2(-16, -20) * s), [c + Vector2(0, -20) * s]), PAPER, 2.4)
	for i in 3:
		var x := -38.0 + i * 20.0
		ci.draw_polyline(_quad(c + Vector2(x, 12) * s, c + Vector2(x + 10, 18) * s, c + Vector2(x + 20, 12) * s), INK, 1.8, true)


func _serpent(ci: CanvasItem, c: Vector2, s: float, flip: bool) -> void:
	var fx := -1.0 if flip else 1.0
	var T := func(v: Vector2) -> Vector2:
		return c + Vector2(v.x * fx, v.y) * s
	for hump in [[-60.0, 34.0], [-8.0, 30.0], [44.0, 26.0]]:
		var x0: float = hump[0]
		var hh: float = hump[1]
		var w := 40.0 if x0 < 0 else 32.0
		if x0 > -10 and x0 < 0:
			w = 36.0
		var pts := _cubic(T.call(Vector2(x0, 10)), T.call(Vector2(x0, 10 - hh)), T.call(Vector2(x0 + w, 10 - hh)), T.call(Vector2(x0 + w, 10)), 12)
		_shape(ci, pts, PAPER, 2.4)
	var head := _poly(_quad(T.call(Vector2(-90, 8)), T.call(Vector2(-96, -22)), T.call(Vector2(-116, -26))), _quad(T.call(Vector2(-116, -26)), T.call(Vector2(-142, -22)), T.call(Vector2(-136, -10))),
		_quad(T.call(Vector2(-136, -10)), T.call(Vector2(-120, -14)), T.call(Vector2(-114, -4))), _quad(T.call(Vector2(-114, -4)), T.call(Vector2(-100, 4)), T.call(Vector2(-92, 18))))
	_shape(ci, head, PAPER, 2.4)
	ci.draw_circle(T.call(Vector2(-124, -16)), 2.0 * s, INK)
	for i in 5:
		var x := -110.0 + i * 40.0
		ci.draw_polyline(_quad(T.call(Vector2(x, 24)), T.call(Vector2(x + 20, 30)), T.call(Vector2(x + 40, 24))), INK, 1.8, true)


# ---------------------------------------------------------------- traços

## Traço de base de uma trilha: estrada dupla, trilha tracejada ou pontilhado de ponte.
func _base_leg(ci: CanvasItem, pts: PackedVector2Array, kind: String, alpha: float) -> void:
	match kind:
		"road":
			ci.draw_polyline(pts, Color(INK, alpha), 6.0, true)
			ci.draw_polyline(pts, BG, 2.0, true)
		"dots":
			_dots(ci, pts, Color(INK, alpha), 5.0, 10.0)
		_:
			_dashed(ci, pts, Color(INK, alpha), 4.5, 11.0, 8.0, 0.0)


## Linha tracejada ao longo de uma polilinha (traço, vão), com deslocamento para a marcha das formigas.
func _dashed(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, dash: float, gap: float, offset: float) -> void:
	var period := dash + gap
	var pos := -fposmod(offset, period)
	var on := true
	var left := dash
	# Avança a fase até o começo da linha.
	while pos < 0.0:
		var take := minf(left, -pos)
		pos += take
		left -= take
		if left <= 0.001:
			on = not on
			left = dash if on else gap
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		if seg <= 0.0001:
			continue
		var p := 0.0
		while p < seg:
			var take := minf(left, seg - p)
			if on:
				ci.draw_line(a.lerp(b, p / seg), a.lerp(b, (p + take) / seg), col, w, true)
			p += take
			left -= take
			if left <= 0.001:
				on = not on
				left = dash if on else gap


func _dots(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, step: float) -> void:
	var acc := step * 0.5
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		while acc <= seg:
			ci.draw_circle(a.lerp(b, acc / maxf(seg, 0.0001)), w * 0.5, col)
			acc += step
		acc -= seg


func _dashed_arc(ci: CanvasItem, c: Vector2, rad: float, col: Color, w: float) -> void:
	var n := int(rad * TAU / 7.0)
	for i in n:
		var a0 := i * TAU / n
		ci.draw_arc(c, rad, a0, a0 + TAU / n * 0.45, 3, col, w, true)


# ---------------------------------------------------------------- geometria e utilidades

static func _cubic(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, n := 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / n
		var v := 1.0 - u
		out.append(p0 * v * v * v + p1 * 3.0 * v * v * u + p2 * 3.0 * v * u * u + p3 * u * u * u)
	return out


static func _quad(a: Vector2, c: Vector2, b: Vector2, n := 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / n
		out.append(a.lerp(c, u).lerp(c.lerp(b, u), u))
	return out


## Junta pedaços (Arrays ou PackedVector2Array) numa polilinha só, sem repetir pontos colados.
static func _poly(a, b = [], c = [], d = []) -> PackedVector2Array:
	var out := PackedVector2Array()
	for part in [a, b, c, d]:
		for p in part:
			if out.is_empty() or out[out.size() - 1].distance_to(p) > 0.01:
				out.append(p)
	return out


static func _offs(o: Vector2, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(o + p)
	return out


## Curva suave (Catmull-Rom) pelos pontos.
static func _smooth(pts: Array, closed: bool, sub := 5) -> PackedVector2Array:
	var n := pts.size()
	var out := PackedVector2Array()
	if n < 2:
		return PackedVector2Array(pts)
	var segs := n if closed else n - 1
	for i in segs:
		var p0: Vector2 = pts[(i - 1 + n) % n] if closed else pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n] if closed else pts[mini(i + 2, n - 1)]
		var c1 := p1 + (p2 - p0) / 6.0
		var c2 := p2 - (p3 - p1) / 6.0
		var part := _cubic(p1, c1, c2, p2, sub)
		for j in part.size() - 1:
			out.append(part[j])
	if not closed:
		out.append(pts[n - 1])
	return out


static func _wob(pts: Array, r: RandomNumberGenerator, amp: float) -> Array:
	var out: Array = []
	for p in pts:
		out.append(p + Vector2((r.randf() - 0.5) * amp, (r.randf() - 0.5) * amp))
	return out


static func _ell(c: Vector2, rx: float, ry: float, n: int, r: RandomNumberGenerator, amp: float) -> Array:
	var out: Array = []
	for i in n:
		var a := float(i) / n * TAU
		out.append(c + Vector2(cos(a) * rx * (1.0 + (r.randf() - 0.5) * amp), sin(a) * ry * (1.0 + (r.randf() - 0.5) * amp)))
	return out


static func _along(pts: PackedVector2Array, u: float) -> Vector2:
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var goal := total * u
	for i in pts.size() - 1:
		var l := pts[i].distance_to(pts[i + 1])
		if goal <= l:
			return pts[i].lerp(pts[i + 1], goal / maxf(l, 0.0001))
		goal -= l
	return pts[pts.size() - 1]


static func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r.grow(10.0)


## Preenche o polígono se ele for desenhável (os contornos à mão às vezes se cruzam; aí só fica o traço).
static func _fill(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if col.a > 0.0 and pts.size() >= 3 and Geometry2D.triangulate_polygon(pts).size() > 0:
		ci.draw_colored_polygon(pts, col)


static func _shape(ci: CanvasItem, pts: PackedVector2Array, fill: Color, w := 2.0, col := INK) -> void:
	_fill(ci, pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, col, w, true)


static func _disc(ci: CanvasItem, c: Vector2, rad: float, fill: Color, col: Color, w: float) -> void:
	ci.draw_circle(c, rad, fill)
	ci.draw_arc(c, rad, 0, TAU, maxi(12, int(rad * 1.5)), col, w, true)


static func _ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := i * TAU / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)


## Grão do papel: ruído em tons de sépia com transparência, gerado uma vez (síncrono) e repetido.
static func _grain_tex() -> ImageTexture:
	if _grain:
		return _grain
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.03
	n.fractal_octaves = 4
	n.seed = 7
	var src := n.get_seamless_image(160, 160)
	var img := Image.create(160, 160, false, Image.FORMAT_RGBA8)
	for y in 160:
		for x in 160:
			var v := src.get_pixel(x, y).r
			img.set_pixel(x, y, Color(0.35, 0.22, 0.08, clampf((v - 0.35) * 0.55, 0.0, 0.3)))
	_grain = ImageTexture.create_from_image(img)
	return _grain


## Mancha macia (centro opaco, borda transparente): manchas do papel e nuvens da névoa.
static func _puff_tex() -> GradientTexture2D:
	if _puff:
		return _puff
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	_puff = GradientTexture2D.new()
	_puff.gradient = g
	_puff.fill = GradientTexture2D.FILL_RADIAL
	_puff.fill_from = Vector2(0.5, 0.5)
	_puff.fill_to = Vector2(1.0, 0.5)
	_puff.width = 128
	_puff.height = 128
	return _puff


# ---------------------------------------------------------------- variações dos elementos internos (15/11/2026)

func _tree(ci: CanvasItem, kind: String, p: Vector2, s: float, r: RandomNumberGenerator) -> void:
	_tree0(ci, kind, p, s, r, PINE if kind in ["p", "f"] else LEAF, (PINE if kind in ["p", "f"] else LEAF).darkened(0.3))


## Montanha nas variações 1 a 4 (pico com ombros, ou nevada em triângulo).
func _mtn(ci: CanvasItem, x: float, y: float, w: float, h: float, snowy: bool, r: RandomNumberGenerator) -> void:
	var top := Vector2(x + (r.randf() - 0.5) * w * 0.25, y - h)
	var base := Vector2(x + w * 0.15, y)
	var right_edge := Vector2(x + w, y)
	var pts: PackedVector2Array
	var shade: PackedVector2Array
	if snowy:
		pts = PackedVector2Array([Vector2(x - w, y), top, right_edge])
		shade = PackedVector2Array([top, right_edge, base])
	else:
		var sh := Vector2(x + w * 0.35, y - h * 0.45)
		pts = PackedVector2Array([Vector2(x - w, y), Vector2(x - w * 0.4, y - h * 0.55), top, sh, right_edge])
		shade = PackedVector2Array([top, sh, right_edge, base])
	var cap_l := top.lerp(Vector2(x - w, y), 0.34)
	var cap_r := top.lerp(right_edge, 0.34)
	var cap := PackedVector2Array([top, cap_r])
	for i in range(1, 4):
		var tt := 1.0 - i / 4.0
		cap.append(cap_l.lerp(cap_r, tt) + Vector2(0, 5.0 if i % 2 == 1 else -1.0))
	cap.append(cap_l)
	# feltro chapado, com o lado da sombra mais escuro
	_fill(ci, pts, MTN)
	_fill(ci, shade, MTN.darkened(0.18))
	if snowy:
		_fill(ci, PackedVector2Array(Array(cap)), PAPER)
	if snowy:
		ci.draw_polyline(cap.slice(1), INK, 1.4, true)
	ci.draw_line(top, base, INK, 1.4, true)
	ci.draw_polyline(pts, INK, 2.6, true)


func _hill_v(ci: CanvasItem, x: float, y: float, w: float, r: RandomNumberGenerator) -> void:
	var arc := _quad(Vector2(x - w, y), Vector2(x, y - w * 0.9), Vector2(x + w, y))
	var sh := PackedVector2Array([_along(arc, 0.5)])
	for i in range(5, 11):
		sh.append(_along(arc, i / 10.0))
	sh.append(Vector2(x + w * 0.08, y))
	_fill(ci, arc, HILL)
	_fill(ci, sh, HILL.darkened(0.12))
	ci.draw_polyline(arc, INK, 2.2, true)


static func _offset_var(pts: PackedVector2Array, d0: float, d1: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var a := pts[maxi(i - 1, 0)]
		var b := pts[mini(i + 1, n - 1)]
		var tg := (b - a).normalized()
		out.append(pts[i] + Vector2(-tg.y, tg.x) * lerpf(d0, d1, float(i) / maxf(n - 1, 1)))
	return out


## Rios do ato a (SimRoad.rivers) em unidades de desenho: os pontos de controle passam pelos nós (_dpos) e pelo
## meio das trilhas desenhadas (_curve); as pontas saem pelas bordas do papel.
func _real_rivers(a: int, road: SimRoad) -> Array:
	var out: Array = []
	var npos := func(n): return _dpos(a, road, n)
	var lmid := func(e):
		var c := _curve(a, road, e)
		return c[c.size() / 2]
	# Trilhas desenhadas (para o meandro não encostar nelas).
	var trail := PackedVector2Array()
	for e in road.legs.size():
		trail.append_array(_curve(a, road, e))
	for n in road.nodes.size():
		if road.nodes[n]["loc"] < 0 or road.locations[road.nodes[n]["loc"]]["type"] != "bridge":
			trail.append(_dpos(a, road, n))
	for k in road.rivers.size():
		var rv: Dictionary = road.rivers[k]
		var line := SimRivers.untangle(SimRivers.polyline(rv["ctrl"], npos, lmid, 520.0, 34.0, 22.0))
		var anchors: Array = rv["bridges"].map(func(n): return _dpos(a, road, n))
		# Rio natural (16/11/2026): curvas alternadas, calmas nas pontes, sem chegar a 22 unidades de uma trilha.
		var room := func(p: Vector2) -> float:
			var dmin := INF
			for q in trail:
				dmin = minf(dmin, p.distance_squared_to(q))
			return sqrt(dmin) - 30.0
		var m := SimRivers.meander(line, anchors, 62.0, 470.0, _seed(a) * 13 + k, 46.0, 8.0, room)
		out.append(Array(SimRivers.untangle(m)))
	return out


## Altura (unidades de desenho) do meio do rio k do ato atual; 0 se não houver.
func river_y(k := 0) -> float:
	if sim == null or lay.is_empty() or k >= sim.road.rivers.size():
		return 0.0
	var ys := 0.0
	var bs: Array = sim.road.rivers[k]["bridges"]
	for n in bs:
		ys += _dpos(sim.act, sim.road, n).y
	return ys / bs.size()


## Parte do rio em terra: corta a linha onde ela passa da costa (coast_l / coast_r) e termina no ponto da costa.
func _river_land(w: Array) -> Array:
	var inside := func(p: Vector2) -> bool: return p.x > coast_l(p.y) and p.x < coast_r(p.y)
	var i0 := 0
	while i0 < w.size() and not inside.call(w[i0]):
		i0 += 1
	var i1 := w.size() - 1
	while i1 > i0 and not inside.call(w[i1]):
		i1 -= 1
	if i0 >= i1:
		return w
	var out: Array = w.slice(i0, i1 + 1)
	if i0 > 0:
		out.push_front(_on_coast(w[i0 - 1], w[i0]))
	if i1 < w.size() - 1:
		out.append(_on_coast(w[i1 + 1], w[i1]))
	return out


## Ponto da costa entre `outp` (no mar) e `inp` (em terra), por bissecção.
func _on_coast(outp: Vector2, inp: Vector2) -> Vector2:
	var a := outp
	var b := inp
	for k in 20:
		var m := (a + b) * 0.5
		if m.x > coast_l(m.y) and m.x < coast_r(m.y):
			b = m
		else:
			a = m
	return (a + b) * 0.5


## Rios de verdade de cada ato com estrada (atual ou já feito): parte em terra e fozes. Calculado uma vez por
## desenho do terreno, antes do mar (a praia precisa saber onde abrir).
var river_geo: Dictionary = {}   # ato -> [{"land": [Vector2], "mouths": [{"side", "lft", "rgt", "a", "b"}]}]
const FLARE_LEN := 120.0


func _build_river_geo() -> void:
	river_geo.clear()
	for a in lay.size():
		var road := _road_of(a)
		if road == null or road.rivers.is_empty():
			continue
		var list: Array = []
		for w in _real_rivers(a, road):
			var land := _river_land(w)
			var mouths: Array = []
			if land.size() >= 6 and (land[0] as Vector2).distance_to(w[0]) > 1.0:
				mouths.append(_mouth(land, 0))
			if land.size() >= 6 and (land[-1] as Vector2).distance_to(w[-1]) > 1.0:
				mouths.append(_mouth(land, land.size() - 1))
			list.append({"land": land, "mouths": mouths.filter(func(m): return not m.is_empty())})
		river_geo[a] = list


func _coast_x(side: int, y: float) -> float:
	return coast_l(y) if side < 0 else coast_r(y)


## Foz na ponta `mi` da parte em terra: as margens se abrem num estuário e terminam em cima da costa
## (`a` e `b`, as pontas da praia).
func _mouth(land: Array, mi: int) -> Dictionary:
	var dir := -1 if mi == 0 else 1
	var seg: Array = []
	var acc := 0.0
	var i: int = mi
	while i >= 0 and i < land.size() and acc <= FLARE_LEN:
		seg.append([land[i], acc])
		var j := i - dir
		if j >= 0 and j < land.size():
			acc += (land[i] as Vector2).distance_to(land[j])
		i = j
	if seg.size() < 4:
		return {}
	var m: Vector2 = seg[0][0]
	var side := -1 if m.x < W * 0.5 else 1
	var lft: Array = []
	var rgt: Array = []
	for k in range(seg.size() - 1, -1, -1):   # de dentro para a costa
		var p: Vector2 = seg[k][0]
		var q: Vector2 = seg[mini(k + 1, seg.size() - 1)][0]
		var o: Vector2 = seg[maxi(k - 1, 0)][0]
		var tg := (o - q).normalized()   # aponta para o mar
		var nrm := Vector2(-tg.y, tg.x)
		var t := 1.0 - float(seg[k][1]) / FLARE_LEN
		var hw := 8.0 + 50.0 * t * t * t
		lft.append(p + nrm * hw)
		rgt.append(p - nrm * hw)
	# Margens sem dobra: onde o rio curva perto do mar, a margem de dentro da curva se dobraria (quina).
	lft = _smooth_bank(lft)
	rgt = _smooth_bank(rgt)
	# Cada margem termina exatamente onde cruza a costa (a mesma conta que a praia usa).
	lft = _to_coast(lft, side)
	rgt = _to_coast(rgt, side)
	# Canto arredondado: a margem vira e segue a costa por um trecho, para longe da boca (a ponta de cima vai
	# para cima, a de baixo para baixo); a praia começa onde o arco termina.
	var up_is_l: bool = (lft[-1] as Vector2).y < (rgt[-1] as Vector2).y
	lft = _fillet(lft, side, -1.0 if up_is_l else 1.0)
	rgt = _fillet(rgt, side, 1.0 if up_is_l else -1.0)
	var a: Vector2 = lft[-1]
	var b: Vector2 = rgt[-1]
	if a.y > b.y:
		var tmp := a
		a = b
		b = tmp
	return {"side": side, "lft": lft, "rgt": rgt, "a": a, "b": b}


## Arredonda o fim da margem `arr` (que termina em cima da costa): troca os últimos FILLET de linha por uma
## curva que sai da margem e encosta na costa a FILLET dali, no sentido `dir` (−1 para cima, +1 para baixo).
const FILLET := 30.0


func _fillet(arr: Array, side: int, dir: float) -> Array:
	var c: Vector2 = arr[-1]
	var k := arr.size() - 1
	var acc := 0.0
	while k > 0 and acc < FILLET:
		acc += (arr[k] as Vector2).distance_to(arr[k - 1])
		k -= 1
	var p: Vector2 = arr[k]
	var ey := c.y + dir * FILLET
	var e := Vector2(_coast_x(side, ey), ey)
	# Curva que sai de p na direção da margem e chega em e na direção da praia: sem quina nas duas pontas.
	var tb: Vector2 = (p - (arr[maxi(k - 1, 0)] as Vector2)).normalized() if k > 0 else (c - p).normalized()
	var ec := Vector2(_coast_x(side, ey - dir * 2.0), ey - dir * 2.0)
	var tc: Vector2 = (ec - e).normalized()   # da praia de volta para a boca
	var l := p.distance_to(e) * 0.45
	var p1 := p + tb * l
	var p2 := e + tc * l
	var out: Array = arr.slice(0, k + 1)
	for i in range(1, 17):
		var t := i / 16.0
		var u := 1.0 - t
		out.append(p * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + e * t * t * t)
	return out


## Desfaz laços e alisa a margem (o primeiro ponto, que encosta no rio, fica onde está).
func _smooth_bank(arr: Array) -> Array:
	var p := Array(SimRivers.untangle(PackedVector2Array(arr)))
	if p.size() < 4:
		return p
	p = Array(SimRoad._resample(PackedVector2Array(p), 4.0))
	for it in 12:
		var q := p.duplicate()
		for i in range(1, p.size() - 1):
			q[i] = (p[i - 1] + p[i] * 2.0 + p[i + 1]) * 0.25
		p = q
	return p


## Corta a margem no primeiro ponto em que ela passa para o mar; se não chega lá, segue reto até a costa.
func _to_coast(arr: Array, side: int) -> Array:
	var inside := func(p: Vector2) -> bool: return p.x > coast_l(p.y) and p.x < coast_r(p.y)
	for k in range(1, arr.size()):
		if not inside.call(arr[k]):
			var out: Array = arr.slice(0, k)
			out.append(_on_coast(arr[k], arr[k - 1]))
			return out
	# Não chegou: segue na própria direção até tocar a costa (nunca um traço reto de lado).
	var out2: Array = arr.duplicate()
	var e: Vector2 = arr[-1]
	var d: Vector2 = (e - (arr[-2] as Vector2)).normalized() if arr.size() > 1 else Vector2(side, 0)
	var q := e
	for k in 120:
		var nq := q + d * 3.0
		if not inside.call(nq):
			out2.append(_on_coast(nq, q))
			return out2
		out2.append(nq)
		q = nq
		d = (d + Vector2(side * 0.06, 0)).normalized()   # vira aos poucos para o mar (no máximo ~3° por passo)
	out2.append(Vector2(_coast_x(side, q.y), q.y))
	return out2


func _mouths_on(side: int) -> Array:
	var out: Array = []
	for a in river_geo:
		for g in river_geo[a]:
			for m in g["mouths"]:
				if int(m["side"]) == side:
					out.append(m)
	return out


## Corta uma linha paralela à costa (pontos de cima para baixo) nas bocas dos rios; `pad` alarga o corte.
func _split_at_mouths(pts: Array, side: int, pad: float) -> Array:
	var ms := _mouths_on(side)
	if ms.is_empty():
		return [pts]
	var pieces: Array = []
	var cur: Array = []
	for p in pts:
		var gap := false
		for m in ms:
			if p.y > float(m["a"].y) - pad and p.y < float(m["b"].y) + pad:
				gap = true
		if gap:
			if cur.size() >= 2:
				pieces.append(cur)
			cur = []
		else:
			cur.append(p)
	if cur.size() >= 2:
		pieces.append(cur)
	return pieces


## A linha da praia, tremida como antes, mas aberta em cada foz: o trecho para exatamente na ponta da margem
## do rio (sem tremido perto dela), para as duas linhas se emendarem.
func _coast_line(ci: CanvasItem, cl: Array, r: RandomNumberGenerator, side: int) -> void:
	var wob := _wob(cl, r, 10.0)   # o mesmo número de sorteios de antes
	var ms := _mouths_on(side)
	ms.sort_custom(func(x, y): return x["a"].y < y["a"].y)
	var pieces: Array = []
	var cur: Array = []
	var mi := 0
	for k in cl.size():
		var p: Vector2 = cl[k]
		while mi < ms.size() and p.y > float(ms[mi]["b"].y):
			mi += 1
		if mi < ms.size() and p.y >= float(ms[mi]["a"].y):
			# Dentro da boca: fecha o trecho na ponta de cima; o próximo começa na de baixo.
			var m: Dictionary = ms[mi]
			if cur.is_empty() or cur[-1] != m["b"]:
				if cur.size() > 0:
					# Até a ponta, a costa exata a cada 8 unidades (sem trecho reto até a boca).
					var y0: float = (cur[-1] as Vector2).y + 8.0
					while y0 < float(m["a"].y) - 4.0:
						cur.append(Vector2(_coast_x(side, y0), y0))
						y0 += 8.0
					cur.append(m["a"])
					pieces.append(cur)
				cur = [m["b"]]
				var y1: float = float(m["b"].y) + 8.0
				while y1 < p.y + 40.0 - 4.0:
					if mi + 1 < ms.size() and y1 >= float(ms[mi + 1]["a"].y):
						break
					cur.append(Vector2(_coast_x(side, y1), y1))
					y1 += 8.0
			continue
		# Longe das bocas, o tremido normal; perto, ele some aos poucos.
		var near := INF
		for m in ms:
			near = minf(near, minf(absf(p.y - float(m["a"].y)), absf(p.y - float(m["b"].y))))
		var f := clampf((near - 30.0) / 70.0, 0.0, 1.0)
		cur.append(p.lerp(wob[k], f))
	if cur.size() >= 2:
		pieces.append(cur)
	for piece in pieces:
		if piece.size() >= 2:
			ci.draw_polyline(_smooth(_dense_near(piece, ms, side), false, 3), INK, 3.4, true)


## Perto das bocas, preenche os vãos da praia com a costa exata a cada 8 unidades (sem trecho reto).
func _dense_near(piece: Array, ms: Array, side: int) -> Array:
	if ms.is_empty():
		return piece
	var out: Array = [piece[0]]
	for i in range(1, piece.size()):
		var p: Vector2 = piece[i - 1]
		var q: Vector2 = piece[i]
		var near := false
		for m in ms:
			for e in [m["a"], m["b"]]:
				if absf(float(e.y) - p.y) < 120.0 or absf(float(e.y) - q.y) < 120.0:
					near = true
		if near and q.y - p.y > 12.0:
			var y := p.y + 8.0
			while y < q.y - 4.0:
				out.append(Vector2(_coast_x(side, y), y))
				y += 8.0
		out.append(q)
	return out


## Água da foz, pintada em faixas (um polígono só falha calado quando a forma se cruza): quadriláteros entre as
## duas margens, mais a boca entre as pontas, que segue a curva da costa e avança um pouco no mar.
func _fill_mouth(ci: CanvasItem, m: Dictionary) -> void:
	var n := 40
	var L := _resample_n(m["lft"], n)
	var R := _resample_n(m["rgt"], n)
	for i in n - 1:
		_tri(ci, L[i], L[i + 1], R[i + 1])
		_tri(ci, L[i], R[i + 1], R[i])
	# Boca: das pontas da praia até o mar, em fatias (cada uma um quadrilátero simples, sem chance de falhar).
	var side: int = m["side"]
	var a: Vector2 = m["a"]
	var b: Vector2 = m["b"]
	var c: Vector2 = (L[n - 1] + R[n - 1]) * 0.5
	var ys: Array = []
	var y := a.y
	while y < b.y:
		ys.append(y)
		y += 5.0
	ys.append(b.y)
	for i in ys.size() - 1:
		var y0: float = ys[i]
		var y1: float = ys[i + 1]
		if y1 - y0 < 0.05:
			continue
		var in0 := Vector2(_coast_x(side, y0) - side * 3.0, y0)
		var in1 := Vector2(_coast_x(side, y1) - side * 3.0, y1)
		var out0 := Vector2(_coast_x(side, y0) + side * 40.0, y0)
		var out1 := Vector2(_coast_x(side, y1) + side * 40.0, y1)
		ci.draw_colored_polygon(PackedVector2Array([in0, out0, out1, in1]), SEA)
		# Do meio da boca até a costa (triângulo).
		_tri(ci, c, in0 + Vector2(side * 4.0, 0), in1 + Vector2(side * 4.0, 0))
	# Das pontas das margens até o meio (fecha os cantos do leque).
	_tri(ci, c, L[n - 1], a)
	_tri(ci, c, R[n - 1], b)


## Um triângulo de água (os degenerados ficam de fora: o Godot recusa e não desenha).
func _tri(ci: CanvasItem, p: Vector2, q: Vector2, r: Vector2) -> void:
	if absf((q - p).cross(r - p)) > 2.0:
		ci.draw_colored_polygon(PackedVector2Array([p, q, r]), SEA)


## A mesma linha com n pontos igualmente espaçados.
func _resample_n(pts: Array, n: int) -> Array:
	var cum: Array = [0.0]
	for i in range(1, pts.size()):
		cum.append(float(cum[-1]) + (pts[i] as Vector2).distance_to(pts[i - 1]))
	var total: float = cum[-1]
	var out: Array = []
	var j := 0
	for k in n:
		var d := total * k / float(n - 1)
		while j < pts.size() - 2 and float(cum[j + 1]) < d:
			j += 1
		var seg: float = maxf(float(cum[j + 1]) - float(cum[j]), 0.0001) if pts.size() > 1 else 1.0
		out.append((pts[j] as Vector2).lerp(pts[mini(j + 1, pts.size() - 1)], clampf((d - float(cum[j])) / seg, 0.0, 1.0)))
	return out


## Rio de verdade com foz (16/11/2026): o rio só existe em terra; onde chega ao mar, as margens se abrem num
## estuário que termina nas pontas da praia, e a água se junta ao mar.
func _river_to_sea(ci: CanvasItem, g: Dictionary, r: RandomNumberGenerator) -> void:
	var land: Array = g["land"]
	var mouths: Array = g["mouths"]
	for m in mouths:
		_fill_mouth(ci, m)
	# O rio de linha dupla vai até onde a boca começa a abrir.
	var cut0 := 0
	var cut1 := land.size() - 1
	for m in mouths:
		var inner: Vector2 = m["lft"][0]
		var at_end: bool = inner.distance_to(land[-1]) < inner.distance_to(land[0])
		var acc := 0.0
		if at_end:
			while cut1 > cut0 + 1 and acc < FLARE_LEN - 10.0:
				acc += (land[cut1] as Vector2).distance_to(land[cut1 - 1])
				cut1 -= 1
		else:
			while cut0 < land.size() - 2 and acc < FLARE_LEN - 10.0:
				acc += (land[cut0] as Vector2).distance_to(land[cut0 + 1])
				cut0 += 1
	_river(ci, PackedVector2Array(land.slice(cut0, cut1 + 1)), r)
	for m in mouths:
		for side_pts in [m["lft"], m["rgt"]]:
			ci.draw_polyline(_smooth(side_pts, false, 3), INK, 2.2, true)
			# Engrossa perto da praia para casar com a linha da costa.
			var tail: Array = (side_pts as Array).slice(int(side_pts.size() * 0.55))
			ci.draw_polyline(_smooth(tail, false, 3), INK, 3.2, true)


## Rio: a linha do meio é `w` (pontos de controle), da nascente à foz.
func _river(ci: CanvasItem, w: Array, _r: RandomNumberGenerator) -> void:
	var line := _smooth(w, false, 4)
	# gravura: duas margens e riscos da corrente
	ci.draw_polyline(line, SEA, 16.0, true)
	ci.draw_polyline(_offset_var(line, -8, -8), INK, 2.2, true)
	ci.draw_polyline(_offset_var(line, 8, 8), INK, 2.2, true)
	for i in range(2, line.size() - 2, 3):
		var tg := (line[i + 1] - line[i - 1]).normalized()
		var o := Vector2(-tg.y, tg.x) * (3.0 if i % 2 == 0 else -3.0)
		ci.draw_line(line[i] + o - tg * 4, line[i] + o + tg * 4, INK, 1.0, true)
