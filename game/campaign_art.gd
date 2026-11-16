class_name CampaignArt
extends RefCounted
## Fundo do mapa da campanha (16/11/2026): o reino desenhado a tinta sépia no papel, no mesmo traço do mapa da run
## (Minimap em gravura, FS=1) e da UI. Árvores, montes, rio, lagos e brejos são os desenhos do mapa da run; as
## construções (casas, igrejas, castelos, torres e o covil) são desenhadas aqui, à mão: linha trêmula, perfis
## curvos, nada de caixa geométrica, e a sombra em hachura recortada na forma (_shade).
## STYLES guarda 10 jeitos de desenhar as construções (propostas para ele escolher); VARIANT é o usado no jogo.
## As regiões ficam onde data/campaign.json diz; o terreno é fixo e nunca cai em água, estrada ou região (_free).
## Desenhado uma vez numa SubViewport (bake) no dobro do tamanho do papel.

const INK := Minimap.INK
const BG := Minimap.BG
const SEA := Minimap.SEA
## Estilo das construções usado no jogo (--mapvar=N troca só naquela execução).
static var VARIANT := 3   # Nórdico, escolhido em 16/11/2026

## Cada estilo: nome, tremor da linha (wob), espessura (line), inclinação das casas (lean), inclinação do telhado
## (pitch), perfil do telhado (straight, concave, convex, long, leaf, slate), corpo (plain, timber, jetty, stone,
## planks), janela (round, arch, pointed, square, dot, none), sombra (hatch, cross, stipple, vert, solid), topo
## das torres (cone, witch, round, crenel, spire, leaf, stacked, hoarding), corpo das torres (taper, slender,
## squat, battered, planks), alto das muralhas (crenel, palisade), castelo (keep, cluster, motte, hall) e covil
## (maw, tower, skull).
const STYLES := [
	{"name": "Conto de fadas", "wob": 1.0, "line": 1.8, "lean": 0.07, "pitch": 0.95, "roof": "concave", "body": "plain",
		"win": "round", "shade": "hatch", "top": "witch", "tbody": "taper", "wall": "crenel", "castle": "cluster",
		"lair": "maw", "chimney": 0.8, "dormer": 0.35, "church": "witch"},
	{"name": "Gravura medieval", "wob": 0.7, "line": 1.8, "lean": 0.02, "pitch": 0.8, "roof": "straight", "body": "timber",
		"win": "square", "shade": "cross", "top": "cone", "tbody": "plain", "wall": "crenel", "castle": "keep",
		"lair": "maw", "chimney": 0.6, "dormer": 0.2, "church": "spire"},
	{"name": "Chalé de palha", "wob": 1.1, "line": 1.9, "lean": 0.03, "pitch": 0.62, "roof": "convex", "body": "plain",
		"win": "square", "shade": "stipple", "top": "round", "tbody": "squat", "wall": "crenel", "castle": "motte",
		"lair": "skull", "chimney": 0.5, "dormer": 0.0, "hut": 0.45, "church": "round"},
	{"name": "Nórdico", "wob": 0.9, "line": 1.9, "lean": 0.0, "pitch": 1.25, "roof": "long", "body": "planks",
		"win": "none", "shade": "vert", "top": "stacked", "tbody": "planks", "wall": "palisade", "castle": "hall",
		"lair": "maw", "chimney": 0.0, "dormer": 0.0, "church": "stacked"},
	{"name": "Gótico", "wob": 0.6, "line": 1.6, "lean": 0.0, "pitch": 1.45, "roof": "straight", "body": "stone",
		"win": "pointed", "shade": "hatch", "top": "spire", "tbody": "slender", "wall": "crenel", "castle": "cluster",
		"lair": "tower", "chimney": 0.4, "dormer": 0.4, "church": "spire", "dense": 1.5},
	{"name": "Mapa de viajante", "wob": 1.5, "line": 2.0, "lean": 0.08, "pitch": 0.85, "roof": "straight", "body": "plain",
		"win": "dot", "shade": "hatch", "top": "cone", "tbody": "taper", "wall": "crenel", "castle": "cluster",
		"lair": "maw", "chimney": 0.5, "dormer": 0.0, "church": "spire", "minimal": true},
	{"name": "Enxaimel torto", "wob": 1.0, "line": 1.8, "lean": 0.13, "pitch": 1.0, "roof": "straight", "body": "jetty",
		"win": "square", "shade": "hatch", "top": "hoarding", "tbody": "plain", "wall": "crenel", "castle": "keep",
		"lair": "skull", "chimney": 0.8, "dormer": 0.6, "church": "spire"},
	{"name": "Xilogravura", "wob": 0.9, "line": 2.6, "lean": 0.04, "pitch": 0.9, "roof": "straight", "body": "plain",
		"win": "arch", "shade": "solid", "top": "cone", "tbody": "taper", "wall": "crenel", "castle": "cluster",
		"lair": "maw", "chimney": 0.6, "dormer": 0.2, "church": "spire"},
	{"name": "Pedra rústica", "wob": 0.9, "line": 1.9, "lean": 0.02, "pitch": 0.75, "roof": "slate", "body": "stone",
		"win": "arch", "shade": "hatch", "top": "crenel", "tbody": "battered", "wall": "crenel", "castle": "keep",
		"lair": "skull", "chimney": 0.7, "dormer": 0.25, "church": "cone"},
	{"name": "Élfico", "wob": 0.8, "line": 1.7, "lean": 0.0, "pitch": 1.2, "roof": "leaf", "body": "plain",
		"win": "round", "shade": "hatch", "top": "leaf", "tbody": "slender", "wall": "crenel", "castle": "cluster",
		"lair": "tower", "chimney": 0.0, "dormer": 0.3, "church": "leaf"},
]

var ci: CanvasItem
var pen: Minimap            # só empresta os desenhos do mapa da run; nunca entra na árvore
var k := 2.0                # escala do papel na textura
var data: GameData
var v: Dictionary           # terreno
var st: Dictionary          # estilo das construções
var r := RandomNumberGenerator.new()
var items: Array = []       # [y, Callable]: desenhados de trás para a frente
var rivers: Array = []
var waters: Array = []
var island: PackedVector2Array = PackedVector2Array()
var roads: Array = []
var occ: Array = []


static func count() -> int:
	return STYLES.size()


static func style_name(n: int) -> String:
	return str(STYLES[clampi(n, 0, STYLES.size() - 1)]["name"])


static func paper_color(_n: int) -> Color:
	return BG


## Desenha o reino com o estilo n numa SubViewport filha de `parent` e devolve a textura (no dobro do papel).
static func bake(parent: Node, d: GameData, n: int) -> Texture2D:
	var p: Array = d.campaign_map.get("paper", [1640, 960])
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.size = Vector2i(int(float(p[0]) * 2.0), int(float(p[1]) * 2.0))
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var canvas := Node2D.new()
	canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	canvas.draw.connect(func(): CampaignArt.new().paint(canvas, d, 2.0, n))
	vp.add_child(canvas)
	parent.add_child(vp)
	return vp.get_texture()


func paint(canvas: CanvasItem, d: GameData, scale: float, n: int) -> void:
	ci = canvas
	data = d
	k = scale
	v = terrain()
	st = STYLES[clampi(n, 0, STYLES.size() - 1)]
	pen = Minimap.new()
	pen.fell = UiDiario.font("fell")
	pen.fell_it = UiDiario.font("fell_it")
	r.seed = 1601
	var paper := _paper()
	_tf(Vector2.ZERO, 1.0)
	# Papel: a cor, manchas e o grão, como no mapa da run.
	ci.draw_rect(Rect2(Vector2.ZERO, paper), BG)
	var stain := Minimap._puff_tex()
	for i in 9:
		var c := Vector2(r.randf() * paper.x, r.randf() * paper.y)
		var rad := r.randf_range(80.0, 260.0)
		ci.draw_texture_rect(stain, Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0), false, Color(0.54, 0.42, 0.19, 0.16))
	ci.draw_texture_rect(Minimap._grain_tex(), Rect2(Vector2.ZERO, paper), true, Color(1, 1, 1, 0.22))
	for ph in data.phases:
		var pts: Array = []
		for p in ph.get("map", {}).get("road", []):
			pts.append(Vector2(float(p[0]), float(p[1])))
		if pts.size() >= 2:
			roads.append(Minimap._smooth(pts, false, 6))
	for rv in v.get("rivers", []):
		rivers.append(Minimap._smooth(rv, false, 4))
		pen._river(ci, rv, r)
	for lk in v.get("lakes", []):
		var poly := _blob_poly(lk[0], lk[1], lk[2], 0.18)
		waters.append(poly)
		_lake(poly, lk[0], false)
	for road in roads:
		ci.draw_polyline(road, Color(INK, 0.55), 6.0, true)
		ci.draw_polyline(road, BG, 2.0, true)
	for road in roads:
		for rl in rivers:
			var hit := _cross(road, rl)
			if not hit.is_empty():
				pen._bridge(ci, hit[0], hit[1])
	if v.has("compass"):
		occ.append([v["compass"][0], 96.0 * float(v["compass"][1])])
	for w in waters:
		_waves(w)
	for rg in v.get("ranges", []):
		_range(rg[0], float(rg[1]), float(rg[2]))
	for hl in v.get("hills", []):
		_hills(hl[0], float(hl[1]), int(hl[2]))
	for mh in v.get("marsh", []):
		_marsh_area(mh[0], float(mh[1]))
	# As construções usam outra semente: trocar de estilo não mexe no terreno.
	var terrain_r := r.seed
	for ph in data.phases:
		r.seed = terrain_r + 7 * int(ph["id"]) + 1
		_region(ph)
	r.seed = terrain_r + 99
	_lair_land()
	r.seed = terrain_r + 555
	_scatter()
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		(it[1] as Callable).call()
		_tf(Vector2.ZERO, 1.0)
	if v.has("compass"):
		var cp: Array = v["compass"]
		_tf(cp[0], float(cp[1]))
		pen._compass(ci, Vector2.ZERO)
		_tf(Vector2.ZERO, 1.0)
	_border("double")
	pen.free()


## O terreno do reino (fixo): rio a leste, serras ao norte, lagos e brejo nos cantos.
static func terrain() -> Dictionary:
	var V2 := func(x: float, y: float) -> Vector2: return Vector2(x, y)
	return {"rivers": [[V2.call(1105, -20), V2.call(1128, 110), V2.call(1088, 250), V2.call(1112, 400), V2.call(1092, 540),
			V2.call(1146, 660), V2.call(1112, 820), V2.call(1150, 990)]],
		"lakes": [[V2.call(165, 810), 72.0, 34.0], [V2.call(1560, 512), 52.0, 26.0]],
		"ranges": [[[V2.call(40, 112), V2.call(225, 104)], 0.5, 1.0], [[V2.call(1175, 112), V2.call(1610, 118)], 0.5, 1.0]],
		"hills": [[V2.call(110, 690), 60.0, 3], [V2.call(1580, 930), 50.0, 2]],
		"marsh": [[V2.call(1590, 400), 30.0]],
		"compass": [V2.call(1562, 868), 0.55], "trees": ["d", "r", "p", "f"], "scatter": 190}


# ------------------------------------------------------------------ regiões

func _region(ph: Dictionary) -> void:
	var m: Dictionary = ph.get("map", {})
	if m.is_empty():
		return
	var c := Vector2(float(m["pos"][0]), float(m["pos"][1]))
	var rx := float(m["rx"])
	var ry := float(m["ry"])
	match str(ph.get("region", "")):
		"fazenda": _farm(c, rx, ry)
		"vila": _village(c, rx, ry)
		"floresta": _forest(c, rx, ry)
		"mosteiro": _monastery(c, rx, ry)
		"forte": _fort(c)
		"torre": _wizard_tower(c, rx, ry)
		"capital": _capital(c, rx, ry)


func _farm(c: Vector2, rx: float, ry: float) -> void:
	var ang := -0.12
	for i in 6:
		var p := c + Vector2((i % 3) * 74.0 - 140.0, (i / 3) * 48.0 - 8.0)
		var w := r.randf_range(60, 70)
		var h := r.randf_range(34, 42)
		_add(p.y - 30, func(): pen._field(ci, p.x, p.y, w, h, ang, r))
	_add(c.y + 6, func(): _house(c + Vector2(92, 6), 36, 20, 30, "thatch", false, 2))
	_add(c.y + 52, func(): _house(c + Vector2(66, 52), 22, 15, 16, "tile", true, 1))
	_add(c.y + 66, func(): _well(c + Vector2(118, 66)))
	for i in 3:
		var p := c + Vector2(150 + i * 18, 20 + (i % 2) * 14)
		_add(p.y, func(): _haystack(p, 9.0))
	_put(c + Vector2(-110, -58), 1.9, func(): pen._windmill(ci, 0, 0, r))
	_add(c.y + 92, func(): _fence(c + Vector2(-170, 92), c + Vector2(40, 98)))
	for i in 3:
		var p := c + Vector2(r.randf_range(-rx, rx) * 0.8, -ry * 0.75 + r.randf_range(-6, 6))
		_put(p, 1.25, func(): _tree_k("r"))


func _village(c: Vector2, rx: float, ry: float) -> void:
	var lane := Minimap._smooth([c + Vector2(-rx * 0.85, 30), c + Vector2(-40, 10), c + Vector2(40, 18), c + Vector2(rx * 0.75, 6)], false, 6)
	_add(c.y - 100, func():
		ci.draw_polyline(lane, Color(INK, 0.55), 5.0, true)
		ci.draw_polyline(lane, BG, 2.0, true))
	for i in 13:
		var u := float(i) / 12.0
		var base := Minimap._along(lane, clampf(u + r.randf_range(-0.03, 0.03), 0.0, 1.0))
		var side := -1.0 if i % 2 == 0 else 1.0
		var p := base + Vector2(r.randf_range(-6, 6), side * r.randf_range(24, 36) + (8 if side > 0 else -2))
		if p.distance_to(c + Vector2(0, -26)) < 36:
			continue
		var w := r.randf_range(15, 21)
		var roof := "thatch" if r.randf() < 0.4 else "tile"
		var hh := w * r.randf_range(0.55, 0.75)
		var dd := w * r.randf_range(0.6, 0.85)
		_add(p.y, func(): _house(p, w, hh, dd, roof, r.randf() < 0.6, 1))
	_add(c.y - 18, func(): _church(c + Vector2(-6, -18), 1.0))
	_add(c.y + 2, func(): _well(c + Vector2(30, 2)))
	_add(c.y + 74, func(): pen._field(ci, c.x - 70, c.y + 80, 44, 22, 0.05, r))
	_add(c.y + 75, func(): _fence(c + Vector2(-96, 94), c + Vector2(-44, 96)))
	for i in 6:
		var a := r.randf() * TAU
		_put(c + Vector2(cos(a) * rx * 0.9, sin(a) * ry * 0.8 + 10), 1.3, func(): _tree_k("r" if i % 2 == 0 else "d"))


func _forest(c: Vector2, rx: float, ry: float) -> void:
	for i in 80:
		var a := r.randf() * TAU
		var t := sqrt(r.randf())
		var p := c + Vector2(cos(a) * rx * 0.95 * t, sin(a) * ry * 0.85 * t + 14)
		if p.distance_to(c + Vector2(30, 34)) < 22:
			continue
		var kind: String = ["d", "r", "p", "f", "d", "p"][r.randi() % 6]
		_put(p, r.randf_range(1.35, 1.8), func(): _tree_k(kind))
	_add(c.y + 40.5, func(): _house(c + Vector2(30, 40), 17, 11, 13, "thatch", true, 1))


func _monastery(c: Vector2, rx: float, ry: float) -> void:
	_add(c.y - 200, func(): pen._hill_v(ci, c.x - 6, c.y + 46, 165, r))
	_add(c.y - 199, func(): pen._hill_v(ci, c.x + 120, c.y + 52, 72, r))
	_add(c.y - 150, func():
		var path := Minimap._smooth([c + Vector2(-20, 80), c + Vector2(30, 66), c + Vector2(-26, 54), c + Vector2(18, 40)], false, 6)
		ci.draw_polyline(path, Color(INK, 0.6), 4.0, true)
		ci.draw_polyline(path, BG, 1.6, true))
	# claustro: muro baixo em volta do pátio, a abadia, as celas
	var yard := [c + Vector2(-96, 40), c + Vector2(-84, -6), c + Vector2(70, -8), c + Vector2(88, 38)]
	_add(c.y - 8, func():
		_cwall(yard[1], yard[2], 7.0, "plain")
		_cwall(yard[0], yard[1], 7.0, "plain")
		_cwall(yard[2], yard[3], 7.0, "plain"))
	_add(c.y + 8, func(): _house(c + Vector2(-58, 14), 19, 11, 14, "tile", true, 1))
	_add(c.y + 10, func(): _abbey(c + Vector2(4, 18)))
	_add(c.y + 12, func(): _house(c + Vector2(62, 22), 16, 10, 12, "tile", false, 1))
	_add(c.y + 40, func(): _cwall(yard[0], yard[3], 7.0, "plain"))
	for i in 6:
		var p := c + Vector2(-128 + (i % 3) * 13, 52 + (i / 3) * 10)
		_add(p.y, func(): _cross_grave(p))
	for i in 5:
		var p := c + Vector2(r.randf_range(-150, 150), r.randf_range(58, 84))
		if absf(p.x - c.x) < 50:
			continue
		_put(p, 1.3, func(): _tree_k("p"))


## Forte da fronteira: muralha que segue o terreno em volta do pátio, torres de tamanhos diferentes nas quinas,
## a torre de menagem (ou o salão), e o portão na frente.
func _fort(c: Vector2) -> void:
	var ring := [c + Vector2(-122, 34), c + Vector2(-100, -28), c + Vector2(-22, -50), c + Vector2(70, -44),
		c + Vector2(124, -6), c + Vector2(110, 44), c + Vector2(0, 56)]
	var n := ring.size()
	var wh := 26.0
	var top := "palisade" if str(st["wall"]) == "palisade" else "crenel"
	for i in n:
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % n]
		var y := maxf(a.y, b.y)
		var back := y < c.y + 10
		var h := wh * (0.8 if back else 1.0)
		if (i + 1) % n == n - 1 or i == n - 1:
			# trechos da frente: abrem para o portão
			var g: Vector2 = ring[n - 1]
			if i == n - 2:
				_add(y + 0.5, func(): _cwall(a, g + Vector2(26, 0), h, top))
			else:
				_add(y + 0.5, func(): _cwall(g + Vector2(-26, 0), b, h, top))
			continue
		var sh := (a.x + b.x) * 0.5 > c.x + 20.0 and absf(b.y - a.y) > absf(b.x - a.x) * 0.6
		_add(y - (40.0 if back else 0.0), func(): _cwall(a, b, h, top, sh))
	for i in n - 1:
		var p: Vector2 = ring[i]
		var back := p.y < c.y
		var w := r.randf_range(20, 28) * (0.85 if back else 1.0)
		var h := r.randf_range(42, 60) * (0.85 if back else 1.0)
		_add(p.y + (0.2 if back else 1.0) - (39.0 if back else 0.0), func(): _tower(p + Vector2(0, 2), w, h, "", true))
	var g0: Vector2 = ring[n - 1]
	_add(g0.y + 2, func(): _gatehouse(g0, 56, wh + 16))
	# dentro
	_add(c.y - 8, func(): _keep_for(c + Vector2(-26, 4)))
	_add(c.y + 18, func(): _house(c + Vector2(50, 20), 30, 14, 18, "tile", true, 2))
	_add(c.y + 22, func(): _house(c + Vector2(-82, 24), 22, 12, 14, "tile", false, 1))


## A torre de menagem conforme o castelo do estilo.
func _keep_for(o: Vector2) -> void:
	match str(st["castle"]):
		"cluster":
			_tower(o + Vector2(-20, -6), 22, 66, "", true)
			_tower(o + Vector2(20, -2), 18, 50, "", false)
			_tower(o + Vector2(0, 6), 30, 84, "", true)
		"motte":
			pen._hill_v(ci, o.x, o.y + 10, 58, r)
			_tower(o + Vector2(0, -8), 32, 52, "", true)
		"hall":
			_house(o + Vector2(0, 8), 30, 16, 58, "tile", false, 0)
			_tower(o + Vector2(-34, 12), 16, 46, "", true)
		_:
			_square_keep(o, 46, 66, 24)
			_tower(o + Vector2(-26, 10), 18, 50, "", true)


func _wizard_tower(c: Vector2, rx: float, ry: float) -> void:
	_add(c.y - 200, func(): _crag(c + Vector2(0, 52), 112, 48))
	_add(c.y + 52, func(): _tower(c + Vector2(0, 46), 28, 132, "", true, true))
	_add(c.y + 70, func(): _house(c + Vector2(-64, 70), 18, 11, 14, "thatch", true, 1))
	_put(c + Vector2(82, 76), 1.4, func(): pen._stones(ci, Vector2.ZERO, r))
	for i in 8:
		var p := c + Vector2(r.randf_range(-rx, rx) * 0.9, r.randf_range(50, ry * 0.95))
		if absf(p.x - c.x) < 72:
			continue
		_put(p, 1.35, func(): _tree_k("f" if i % 2 == 0 else "p"))


## A capital: muralha oval com torres, o portão, as casas apertadas, a catedral e o castelo do rei ao fundo.
func _capital(c: Vector2, rx: float, ry: float) -> void:
	var wc := c + Vector2(0, 16)
	var wrx := rx * 0.94
	var wry := ry * 0.76
	var top := "palisade" if str(st["wall"]) == "palisade" else "crenel"
	var at := func(a: float) -> Vector2: return wc + Vector2(cos(a) * wrx, sin(a) * wry)
	var segs := 14
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var p0: Vector2 = at.call(a0)
		var p1: Vector2 = at.call(a1)
		var back := sin((a0 + a1) * 0.5) < 0.0
		if not back and absf(cos((a0 + a1) * 0.5)) < 0.2:
			continue   # o portão
		var sh := (p0.x + p1.x) * 0.5 > wc.x + wrx * 0.55
		_add((wc.y - wry - 4.0) if back else (wc.y + wry + 30.0), func(): _cwall(p0, p1, 9.0 if back else 15.0, top, sh))
	for i in segs:
		var a := TAU * i / segs
		var p: Vector2 = at.call(a)
		var back := sin(a) < -0.05
		var w := r.randf_range(14, 18) * (0.85 if back else 1.15)
		var h := r.randf_range(28, 36) * (0.85 if back else 1.2)
		_add((p.y + 0.1) if back else (wc.y + wry + 31.0 + p.x * 0.001), func(): _tower(p + Vector2(0, 2), w, h, "", false))
	var gp: Vector2 = at.call(PI * 0.5)
	_add(wc.y + wry + 32, func(): _gatehouse(gp + Vector2(0, 2), 50, 32))
	_add(c.y - 30, func(): _royal_castle(c + Vector2(-4, -6)))
	_add(c.y - 4, func(): _cathedral(c + Vector2(110, 6)))
	for i in 46:
		var a := r.randf() * TAU
		var t := sqrt(r.randf()) * 0.84
		var p := wc + Vector2(cos(a) * wrx * t, sin(a) * wry * t + 6)
		if absf(p.x - c.x + 4) < 76 and p.y < c.y + 24:
			continue
		if absf(p.x - c.x - 110) < 44 and p.y < c.y + 16:
			continue
		var w := r.randf_range(12, 17)
		var roof := "tile" if r.randf() < 0.75 else "thatch"
		var hh := w * r.randf_range(0.55, 0.72)
		var dd := w * r.randf_range(0.55, 0.8)
		_add(p.y, func(): _house(p, w, hh, dd, roof, r.randf() < 0.5, 1))


func _royal_castle(o: Vector2) -> void:
	_cwall(o + Vector2(-78, 22), o + Vector2(-30, 26), 16, "crenel")
	_cwall(o + Vector2(26, 26), o + Vector2(74, 22), 16, "crenel")
	_tower(o + Vector2(-50, -6), 20, 62, "", true)
	_tower(o + Vector2(46, -4), 20, 58, "", true)
	match str(st["castle"]):
		"hall":
			_house(o + Vector2(0, 14), 40, 22, 60, "tile", false, 0)
		"keep", "motte":
			_square_keep(o + Vector2(-4, 8), 50, 70, 22)
		_:
			_tower(o + Vector2(-16, 4), 26, 82, "", true)
			_tower(o + Vector2(14, 10), 32, 96, "", true)
	_tower(o + Vector2(-80, 26), 18, 36, "", false)
	_tower(o + Vector2(76, 26), 18, 36, "", false)


## O covil conforme o estilo, com árvores mortas, ossos e morcegos em volta.
func _lair_land() -> void:
	var l := _lair()
	match str(st["lair"]):
		"tower": _add(l.y - 60, func(): _lair_tower(l))
		"skull": _add(l.y - 60, func(): _lair_skull(l))
		_: _add(l.y - 60, func(): _lair_maw(l))
	for i in 10:
		var a := -PI * 0.15 + float(i) / 10.0 * TAU + r.randf_range(-0.2, 0.2)
		var p := l + Vector2(cos(a) * r.randf_range(165, 190), sin(a) * r.randf_range(95, 115) + 26)
		if _near_road(p, 22.0) or p.y < l.y - 40:
			continue
		_put(p, 1.45, func(): pen._tree(ci, "x", Vector2.ZERO, 1.0, r))
	_add(l.y + 34, func(): _bones(l + Vector2(-56, 32)))
	_add(l.y + 36, func(): _bones(l + Vector2(62, 34)))


# ------------------------------------------------------------------ traço à mão

func _lw() -> float:
	return float(st.get("line", 1.8))


## Linha trêmula por uma polilinha: cada trecho ganha uma barriga leve e um tremor (st.wob).
func _wp(pts: PackedVector2Array, w := -1.0, closed := false, col := INK) -> void:
	if pts.size() < 2:
		return
	if w < 0.0:
		w = _lw()
	var wob := float(st.get("wob", 1.0))
	var src := pts.duplicate()
	if closed:
		src.append(pts[0])
	var out := PackedVector2Array()
	for i in src.size() - 1:
		var a := src[i]
		var b := src[i + 1]
		var ln := a.distance_to(b)
		var n := maxi(1, int(ln / 5.0))
		var nrm := (b - a).orthogonal().normalized()
		var bow := r.randf_range(-0.5, 0.5) * wob * minf(1.6, ln / 22.0)
		for j in n:
			var t := float(j) / n
			out.append(a.lerp(b, t) + nrm * (sin(t * PI) * bow + r.randf_range(-0.22, 0.22) * wob))
	out.append(src[src.size() - 1])
	ci.draw_polyline(out, col, w * r.randf_range(0.92, 1.08), true)


func _wl(a: Vector2, b: Vector2, w := -1.0, col := INK) -> void:
	_wp(PackedVector2Array([a, b]), w, false, col)


## Forma preenchida de papel com o contorno trêmulo.
func _ws(pts: PackedVector2Array, fill := BG, w := -1.0) -> void:
	Minimap._fill(ci, pts, fill)
	_wp(pts, w, true)


func _q(a: Vector2, c: Vector2, b: Vector2, n := 7) -> PackedVector2Array:
	return Minimap._quad(a, c, b, n)


func _cat(parts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for part in parts:
		for p in part:
			if out.is_empty() or out[out.size() - 1].distance_to(p) > 0.05:
				out.append(p)
	return out


## Sombra dentro de uma forma, no jeito do estilo: hachura, cruzada, pontilhado, vertical ou chapada.
func _shade(poly: PackedVector2Array, kind := "", dens := 1.0) -> void:
	if poly.size() < 3:
		return
	if kind == "":
		kind = str(st.get("shade", "hatch"))
	dens *= float(st.get("dense", 1.0))
	match kind:
		"stipple":
			var b := Minimap._bounds(poly)
			var n := int(b.size.x * b.size.y / 7.0 * dens)
			for i in n:
				var p := Vector2(r.randf_range(b.position.x, b.end.x), r.randf_range(b.position.y, b.end.y))
				if Geometry2D.is_point_in_polygon(p, poly):
					ci.draw_circle(p, 0.7, INK)
		"solid":
			Minimap._fill(ci, poly, Color(INK, 0.9))
			_lines_in(poly, -0.6, 5.0, BG, 0.8)
		"cross":
			_lines_in(poly, -0.95, 2.8 / dens, INK, 0.8)
			_lines_in(poly, 0.6, 3.4 / dens, INK, 0.7)
		"vert":
			_lines_in(poly, PI * 0.5, 2.6 / dens, INK, 0.8)
		_:
			_lines_in(poly, -0.95, 2.4 / dens, INK, 0.8)


func _lines_in(poly: PackedVector2Array, ang: float, gap: float, col: Color, w: float) -> void:
	var b := Minimap._bounds(poly)
	var c := b.get_center()
	var R := b.size.length() * 0.5 + 2.0
	var dir := Vector2(cos(ang), sin(ang))
	var nrm := dir.orthogonal()
	var t := -R + r.randf() * gap
	while t <= R:
		var line := PackedVector2Array([c + nrm * t - dir * R, c + nrm * t + dir * R])
		for seg in Geometry2D.intersect_polyline_with_polygon(line, poly):
			if seg.size() >= 2:
				var a: Vector2 = seg[0]
				var e: Vector2 = seg[seg.size() - 1]
				ci.draw_line(a + Vector2(r.randf_range(-0.3, 0.3), 0), e, col, w, true)
		t += gap


func _dot_window(p: Vector2, s: float) -> void:
	match str(st.get("win", "square")):
		"round":
			ci.draw_circle(p, s * 0.5, INK)
		"arch":
			Minimap._fill(ci, _arch(p + Vector2(0, s * 0.6), s * 0.75, s * 1.3), INK)
		"pointed":
			Minimap._fill(ci, _cat([[p + Vector2(-s * 0.32, s * 0.7)], _q(p + Vector2(-s * 0.32, -s * 0.1), p + Vector2(-s * 0.3, -s * 0.7), p + Vector2(0, -s * 0.9)),
				_q(p + Vector2(0, -s * 0.9), p + Vector2(s * 0.3, -s * 0.7), p + Vector2(s * 0.32, -s * 0.1)), [p + Vector2(s * 0.32, s * 0.7)]]), INK)
		"square":
			var q := PackedVector2Array([p + Vector2(-s * 0.45, -s * 0.5), p + Vector2(s * 0.45, -s * 0.5), p + Vector2(s * 0.45, s * 0.5), p + Vector2(-s * 0.45, s * 0.5)])
			Minimap._fill(ci, q, INK)
			ci.draw_line(p + Vector2(0, -s * 0.5), p + Vector2(0, s * 0.5), BG, 0.8, true)
			ci.draw_line(p + Vector2(-s * 0.45, 0), p + Vector2(s * 0.45, 0), BG, 0.8, true)
		"dot":
			ci.draw_circle(p, s * 0.32, INK)
		_:
			pass


func _arch(o: Vector2, w: float, h: float) -> PackedVector2Array:
	return _cat([[o + Vector2(-w * 0.5, 0), o + Vector2(-w * 0.5, -h + w * 0.5)],
		_q(o + Vector2(-w * 0.5, -h + w * 0.5), o + Vector2(0, -h - w * 0.15), o + Vector2(w * 0.5, -h + w * 0.5)), [o + Vector2(w * 0.5, 0)]])


# ------------------------------------------------------------------ casas

## Perfil de uma água do telhado, do beiral (a) ao cume (b), conforme o estilo.
func _roof_edge(a: Vector2, b: Vector2, kind: String, left: bool) -> PackedVector2Array:
	var mid := a.lerp(b, 0.5)
	var out := Vector2(-1.0 if left else 1.0, 0.0)
	match kind:
		"concave":
			return _q(a, mid + Vector2(0, (a.y - b.y) * 0.18) - out * 2.0, b)
		"convex":
			return _q(a, mid + out * (a.distance_to(b) * 0.16) + Vector2(0, -(a.y - b.y) * 0.12), b)
		"leaf":
			var c1 := a + out * 2.0 + Vector2(0, -(a.y - b.y) * 0.45)
			var c2 := b - out * (absf(a.x - b.x) * 0.55) + Vector2(0, (a.y - b.y) * 0.25)
			return Minimap._cubic(a, c1, c2, b, 10)
		"long":
			return _q(a, mid + Vector2(0, (a.y - b.y) * 0.1), b)
		_:
			return _q(a, mid + Vector2(0, (a.y - b.y) * 0.04), b, 4)


## Casa à mão: frente com empena de perfil curvo, lado em fuga com sombra, telhado com textura, porta, janelas,
## chaminé torta com fumaça, água-furtada; a casa pode tombar um pouco (lean) e ter o andar de cima saliente (jetty).
func _house(o: Vector2, w: float, h: float, d: float, roof: String, chimney: bool, windows: int) -> void:
	if st.get("minimal", false):
		_house_min(o, w, h, d)
		return
	var kind := str(st.get("roof", "straight"))
	if roof == "thatch" and kind in ["straight", "concave", "slate"]:
		kind = "convex"
	if float(st.get("hut", 0.0)) > 0.0 and w < 22.0 and r.randf() < float(st["hut"]):
		_hut(o, w, h)
		return
	var body := str(st.get("body", "plain"))
	var hw := w * 0.5
	var hh := h
	var dd := d
	var pitch := w * float(st.get("pitch", 0.8)) * r.randf_range(0.9, 1.15)
	if kind == "long":
		hh = h * 0.55
		dd = d * 1.35
	var lean := r.randf_range(-1.0, 1.0) * float(st.get("lean", 0.03)) * hh
	var off := Vector2(dd, -dd * 0.42)
	var jet := (1.5 + w * 0.07) if body == "jetty" else 0.0
	var bl := o + Vector2(-hw, 0)
	var br := o + Vector2(hw, 0)
	var ml := o + Vector2(-hw + lean * 0.5, -hh * 0.5)
	var mr := o + Vector2(hw + lean * 0.5, -hh * 0.5)
	var tl := o + Vector2(-hw - jet + lean, -hh)
	var tr := o + Vector2(hw + jet + lean, -hh)
	var apex := (tl + tr) * 0.5 + Vector2(r.randf_range(-1, 1), -pitch)
	var ov := 2.0 + w * 0.09
	var el := tl + Vector2(-ov, ov * 0.55)
	var er := tr + Vector2(ov, ov * 0.55)
	# sombra no chão, do lado de trás
	_shade(PackedVector2Array([br + Vector2(1, 0), br + off + Vector2(1, 0), br + off + Vector2(dd * 0.55, 1.5), br + Vector2(dd * 0.55 + 3, 2.5)]), "hatch", 0.55)
	# lado em fuga
	var side := PackedVector2Array([br, br + off, tr + off, tr])
	if jet > 0.0:
		side = PackedVector2Array([br, br + off, mr + off, mr + off + Vector2(jet, 0), tr + off, tr, mr + Vector2(jet, 0), mr])
	_ws(side)
	_shade(side)
	for i in windows:
		var wp := br.lerp(br + off, (i + 1.0) / (windows + 1.0)) + Vector2(0, -hh * 0.6)
		_dot_window(wp, 3.2)
	# a água do telhado de lado
	var redge := _roof_edge(er, apex, kind, false)
	redge.reverse()
	var sag := Vector2(0, 1.5 + dd * 0.05)
	if kind == "long":
		sag = Vector2(0, 3.0 + dd * 0.06)
	var ridge := _q(apex, (apex + apex + off) * 0.5 + sag, apex + off, 6)
	var back := PackedVector2Array()
	for p in redge:
		back.append(p + off)
	var eave := _q(er + off, (er + er + off) * 0.5 + Vector2(0, 1.5), er, 6)
	var e_up := redge.duplicate()
	e_up.reverse()
	var slab_poly := _cat([ridge, back, eave, e_up])
	_ws(slab_poly)
	_roof_tex(redge, off, kind)
	if kind == "convex":
		_wp(_q(er + Vector2(0, 1.8), (er + er + off) * 0.5 + Vector2(0, 3.5), er + off + Vector2(0, 1.8)), _lw() * 0.8)
	# chaminé e água-furtada
	if chimney and r.randf() < float(st.get("chimney", 0.6)) + 0.2:
		var cb: Vector2 = redge[int(redge.size() * 0.45)].lerp(redge[int(redge.size() * 0.45)] + off, r.randf_range(0.45, 0.75))
		_chimney(cb)
	if dd > 14.0 and r.randf() < float(st.get("dormer", 0.0)):
		var dp: Vector2 = redge[int(redge.size() * 0.55)].lerp(redge[int(redge.size() * 0.55)] + off, 0.35)
		_dormer(dp, w * 0.24)
	# frente
	var front := PackedVector2Array([bl, br, mr, tr, tl, ml]) if jet > 0.0 else PackedVector2Array([bl, br, tr, tl])
	if jet > 0.0:
		front = PackedVector2Array([bl, br, mr, mr + Vector2(jet, 0), tr, tl, ml + Vector2(-jet, 0), ml])
	_ws(front)
	_body_tex(bl, br, tl, tr, ml, mr, jet, body)
	var ledge := _roof_edge(el, apex, kind, true)
	var gr := _roof_edge(er, apex, kind, false)
	gr.reverse()
	var gable := _cat([ledge, gr])
	_ws(gable)
	if kind == "long":
		# vigas cruzadas no alto da empena
		_wl(apex + Vector2(-2, 3), apex + Vector2(5, -7), _lw() * 0.9)
		_wl(apex + Vector2(2, 3), apex + Vector2(-5, -7), _lw() * 0.9)
		ci.draw_arc(apex + Vector2(6.5, -8), 1.6, PI, TAU * 0.9, 6, INK, 1.0, true)
		ci.draw_arc(apex + Vector2(-6.5, -8), 1.6, PI * 1.1, TAU, 6, INK, 1.0, true)
		for i in range(1, 4):
			_wl(el.lerp(apex, i * 0.22) + Vector2(1, 0), er.lerp(apex, i * 0.22) - Vector2(1, 0), 0.7)
	elif body == "timber" or body == "jetty":
		_wl(apex + Vector2(0, 3), (tl + tr) * 0.5 + Vector2(0, -0.5), 0.9)
		_wl((tl + tr) * 0.5 + (apex - (tl + tr) * 0.5) * 0.45 + Vector2(-pitch * 0.25, 0), (tl + tr) * 0.5 + (apex - (tl + tr) * 0.5) * 0.45 + Vector2(pitch * 0.25, 0), 0.8)
	elif pitch > 9.0:
		_dot_window(apex + Vector2(0, pitch * 0.55), 2.6)
	# porta
	var dx := r.randf_range(-0.22, 0.05) * w
	if body == "planks" or kind == "long":
		var dr := _arch(o + Vector2(dx, 0), w * 0.24, hh * 0.62)
		_ws(dr, BG, 1.2)
		for i in 2:
			_wl(o + Vector2(dx - w * 0.04 + i * w * 0.08, -1), o + Vector2(dx - w * 0.04 + i * w * 0.08, -hh * 0.5), 0.7)
	else:
		Minimap._fill(ci, _arch(o + Vector2(dx, 0), w * 0.22, minf(hh * 0.52, 9.0)), INK)
	if w > 15.0 and str(st.get("win", "")) != "none":
		_dot_window(o + Vector2(dx + w * 0.3, -hh * 0.62), 3.0)


func _roof_tex(edge: PackedVector2Array, off: Vector2, kind: String) -> void:
	var n := edge.size()
	match kind:
		"convex":
			# palha: traços curtos na direção da descida
			for i in int(off.length() * 0.9):
				var u := r.randf()
				var t := r.randf_range(0.1, 0.85)
				var a: Vector2 = Minimap._along(edge, t) + off * u
				var b: Vector2 = Minimap._along(edge, minf(1.0, t + 0.12)) + off * u
				ci.draw_line(a, a.lerp(b, 0.7), Color(INK, 0.8), 0.8, true)
		"slate":
			for j in range(1, 5):
				var t := j / 5.0
				var a: Vector2 = Minimap._along(edge, t)
				var m := int(off.length() / 4.0)
				for i in m:
					var p := a + off * (i + 0.5) / m
					ci.draw_arc(p + Vector2(0, -1.2), 2.0, 0.2, PI - 0.2, 5, INK, 0.8, true)
		"long", "leaf":
			for j in range(1, 6):
				var t := j / 6.0
				var a: Vector2 = Minimap._along(edge, t)
				_wl(a, a + off, 0.7)
		_:
			# telhas: fiadas paralelas ao beiral e juntas desencontradas
			var rows := maxi(3, int(edge[0].distance_to(edge[n - 1]) / 3.6))
			for j in range(1, rows):
				var t := float(j) / rows
				var a: Vector2 = Minimap._along(edge, t)
				ci.draw_line(a, a + off, Color(INK, 0.85), 0.75, true)
				var m := int(off.length() / 4.5)
				for i in m:
					var p := a + off * ((i + (0.5 if j % 2 == 0 else 0.0)) / m)
					var q: Vector2 = Minimap._along(edge, maxf(0.0, t - 1.0 / rows)) + off * ((i + (0.5 if j % 2 == 0 else 0.0)) / m)
					ci.draw_line(p, p.lerp(q, 0.8), Color(INK, 0.7), 0.6, true)


func _body_tex(bl: Vector2, br: Vector2, tl: Vector2, tr: Vector2, ml: Vector2, mr: Vector2, jet: float, body: String) -> void:
	match body:
		"timber", "jetty":
			_wl(ml + Vector2(-jet, 0), mr + Vector2(jet, 0), 1.0)
			_wl(bl + Vector2(1.5, 0), tl + Vector2(1.5 + jet, 0), 1.0)
			_wl(br + Vector2(-1.5, 0), tr + Vector2(-1.5 - jet, 0), 1.0)
			var mid_b := bl.lerp(br, 0.5)
			var mid_m := ml.lerp(mr, 0.5)
			var mid_t := tl.lerp(tr, 0.5)
			_wl(ml.lerp(mid_m, 0.15), tl.lerp(mid_t, 0.85), 0.8)
			_wl(mid_m.lerp(mr, 0.85), mid_t.lerp(tr, 0.15), 0.8)
			if body == "jetty":
				_wl(tl.lerp(tr, 0.33), ml.lerp(mr, 0.33), 0.8)
				_wl(tl.lerp(tr, 0.66), ml.lerp(mr, 0.66), 0.8)
				_wl(ml + Vector2(-jet, 1.0), mr + Vector2(jet, 1.0), 0.8)
		"stone":
			var wv := br.x - bl.x
			var hv := bl.y - tl.y
			for j in int(hv / 4.0):
				var y := bl.y - 2.0 - j * 4.0
				var x := bl.x + (2.0 if j % 2 == 0 else 4.0)
				while x < bl.x + wv - 3.0:
					if r.randf() < 0.55:
						ci.draw_arc(Vector2(x + 1.5, y), 1.7, PI * 1.05, TAU * 0.98, 5, Color(INK, 0.75), 0.7, true)
					x += 4.5
		"planks":
			var x0 := bl.x + 2.5
			while x0 < br.x - 1.5:
				_wl(Vector2(x0, bl.y - 0.5), Vector2(x0 + (tl.x - bl.x) * 0.0, tl.y + 1.0), 0.6)
				x0 += 3.0
		_:
			# reboco: duas manchas de reparo
			for i in 2:
				var p := bl.lerp(tr, r.randf_range(0.25, 0.75)) + Vector2(r.randf_range(-3, 3), 0)
				ci.draw_line(p, p + Vector2(2.5, 0.6), Color(INK, 0.6), 0.7, true)


func _chimney(b: Vector2) -> void:
	var lean := r.randf_range(-1.2, 1.2)
	var poly := PackedVector2Array([b + Vector2(-2.2, 2), b + Vector2(-2.0 + lean, -7.5), b + Vector2(2.6 + lean, -7.5), b + Vector2(2.6, 2)])
	_ws(poly, BG, _lw() * 0.75)
	_wl(b + Vector2(-2.8 + lean, -7.5), b + Vector2(3.2 + lean, -7.5), _lw() * 0.8)
	var s := b + Vector2(lean, -10)
	var pts: Array = [s]
	for i in 5:
		pts.append(s + Vector2(sin(i * 1.7) * (2.0 + i * 0.6) + i * 1.2, -i * 3.6))
	ci.draw_polyline(Minimap._smooth(pts, false, 4), Color(INK, 0.65), 0.9, true)


func _dormer(p: Vector2, w: float) -> void:
	var hw := w * 0.5
	var body := PackedVector2Array([p + Vector2(-hw, 1), p + Vector2(hw, 1), p + Vector2(hw, -w * 0.5), p + Vector2(-hw, -w * 0.5)])
	_ws(body, BG, _lw() * 0.75)
	var tri := _cat([_roof_edge(p + Vector2(-hw - 1.5, -w * 0.45), p + Vector2(0, -w * 1.1), str(st.get("roof", "straight")), true),
		[p + Vector2(hw + 1.5, -w * 0.45)]])
	_ws(tri, BG, _lw() * 0.75)
	_dot_window(p + Vector2(0, -w * 0.18), w * 0.38)


## Cabana redonda de palha (estilo de palha).
func _hut(o: Vector2, w: float, h: float) -> void:
	var hw := w * 0.55
	var hb := h * 0.6
	_shade(PackedVector2Array([o + Vector2(hw * 0.4, 1), o + Vector2(hw + 10, 1), o + Vector2(hw + 6, 3), o + Vector2(hw * 0.4, 3)]), "hatch", 0.5)
	var body := _cat([[o + Vector2(-hw, -hb)], _q(o + Vector2(-hw, 0), o + Vector2(0, 3), o + Vector2(hw, 0)), [o + Vector2(hw, -hb)]])
	body = _cat([[o + Vector2(-hw, -hb), o + Vector2(-hw, 0)], _q(o + Vector2(-hw, 0), o + Vector2(0, 3), o + Vector2(hw, 0)), [o + Vector2(hw, -hb)]])
	_ws(body)
	_shade(_cat([[o + Vector2(hw * 0.35, -hb), o + Vector2(hw * 0.35, 1.6)], _q(o + Vector2(hw * 0.35, 1.6), o + Vector2(hw * 0.75, 1.0), o + Vector2(hw, 0)), [o + Vector2(hw, -hb)]]))
	var apex := o + Vector2(r.randf_range(-1, 1), -hb - w * 0.95)
	var rl := o + Vector2(-hw - 3, -hb + 2)
	var rr := o + Vector2(hw + 3, -hb + 2)
	var roof := _cat([_q(rl, rl.lerp(apex, 0.5) + Vector2(-w * 0.18, -2), apex), _q(apex, rr.lerp(apex, 0.5) + Vector2(w * 0.18, -2), rr), _q(rr, o + Vector2(0, -hb + 6), rl)])
	_ws(roof)
	for i in 9:
		var t := (i + 0.5) / 9.0
		var p: Vector2 = Minimap._along(_q(rr, o + Vector2(0, -hb + 6), rl), t)
		ci.draw_line(p, p.lerp(apex, 0.3), Color(INK, 0.7), 0.7, true)
	_shade(_cat([[apex], _q(apex, rr.lerp(apex, 0.5) + Vector2(w * 0.18, -2), rr), [rr.lerp(rl, 0.35)]]), "stipple")
	Minimap._fill(ci, _arch(o + Vector2(-w * 0.12, 1), w * 0.26, hb * 0.8), INK)
	var s := apex + Vector2(0, -2)
	ci.draw_polyline(Minimap._smooth([s, s + Vector2(2, -4), s + Vector2(-1, -8), s + Vector2(3, -12)], false, 4), Color(INK, 0.6), 0.9, true)


## Casa de mapa de viajante: só a silhueta do telhado e da frente, uma linha de profundidade e a porta em ponto.
func _house_min(o: Vector2, w: float, h: float, d: float) -> void:
	var hw := w * 0.5
	var lean := r.randf_range(-1.0, 1.0) * float(st.get("lean", 0.05)) * h
	var apex := o + Vector2(lean, -h - w * float(st.get("pitch", 0.8)) * r.randf_range(0.85, 1.2))
	var front := _cat([[o + Vector2(-hw, 0), o + Vector2(-hw + lean * 0.7, -h)], _q(o + Vector2(-hw - 2 + lean, -h + 1), o + Vector2(-hw * 0.5 + lean, -h - 2), apex),
		_q(apex, o + Vector2(hw * 0.5 + lean, -h - 2), o + Vector2(hw + 2 + lean, -h + 1)), [o + Vector2(hw + lean * 0.7, -h), o + Vector2(hw, 0)]])
	var depth := d * 0.55
	_wp(PackedVector2Array([apex, apex + Vector2(depth, -depth * 0.3), o + Vector2(hw + 2 + lean + depth, -h + 1 - depth * 0.3), o + Vector2(hw + 2 + lean, -h + 1)]))
	_shade(PackedVector2Array([o + Vector2(hw, 0), o + Vector2(hw + depth, -depth * 0.3), o + Vector2(hw + depth, -h - depth * 0.3), o + Vector2(hw, -h)]))
	_wl(o + Vector2(hw + depth, -depth * 0.3), o + Vector2(hw + depth, -h - depth * 0.3 + 1))
	_wl(o + Vector2(hw, 0), o + Vector2(hw + depth, -depth * 0.3))
	_ws(front)
	ci.draw_circle(o + Vector2(-w * 0.1, -h * 0.25), 1.3, INK)


# ------------------------------------------------------------------ torres, muralhas e castelos

## Torre redonda à mão: corpo que afina (ou incha, ou abre na base), sombra do lado direito, janelas do estilo,
## a porta e o topo do estilo. `tall` deixa a torre mais esguia e com sacadas (a Torre dos Arcanos).
func _tower(o: Vector2, w: float, h: float, top := "", flag := true, tall := false) -> void:
	if top == "":
		top = str(st.get("top", "cone"))
	var tb := str(st.get("tbody", "plain"))
	var hw := w * 0.5
	var tw: float = hw * float({"taper": 0.82, "slender": 0.76, "squat": 0.95, "battered": 0.8, "planks": 0.9}.get(tb, 0.88))
	if tb == "squat":
		h *= 0.82
	var lean := r.randf_range(-1.0, 1.0) * float(st.get("lean", 0.02)) * h * 0.35
	var bulge := 1.5 if tb in ["taper", "squat"] else 0.4
	var left := Minimap._cubic(o + Vector2(-hw, 0), o + Vector2(-hw - bulge, -h * 0.35), o + Vector2(-tw - bulge * 0.5 + lean, -h * 0.75), o + Vector2(-tw + lean, -h), 8)
	var right := Minimap._cubic(o + Vector2(tw + lean, -h), o + Vector2(tw + bulge * 0.5 + lean, -h * 0.75), o + Vector2(hw + bulge, -h * 0.35), o + Vector2(hw, 0), 8)
	var base := _q(o + Vector2(hw, 0), o + Vector2(0, 3.5), o + Vector2(-hw, 0), 6)
	if tb == "battered":
		left = _cat([[o + Vector2(-hw - 4, 0)], _q(o + Vector2(-hw - 4, 0), o + Vector2(-hw, -h * 0.12), o + Vector2(-hw * 0.95, -h * 0.25)), [o + Vector2(-tw + lean, -h)]])
		right = _cat([[o + Vector2(tw + lean, -h), o + Vector2(hw * 0.95, -h * 0.25)], _q(o + Vector2(hw * 0.95, -h * 0.25), o + Vector2(hw, -h * 0.12), o + Vector2(hw + 4, 0))])
		base = _q(o + Vector2(hw + 4, 0), o + Vector2(0, 4), o + Vector2(-hw - 4, 0), 6)
	var body := _cat([left, right, base])
	_ws(body)
	# sombra: a terça parte da direita
	var sh := PackedVector2Array()
	for p in right:
		sh.append(p)
	for i in range(right.size() - 1, -1, -1):
		sh.append(Vector2(lerpf(right[i].x, o.x + lean * (1.0 - float(i) / right.size()), 0.42), right[i].y + (2.5 if i == right.size() - 1 else 0.0)))
	_shade(sh)
	match tb:
		"planks":
			for i in range(1, 5):
				var x := o.x - hw + i * w / 5.0
				_wl(Vector2(x, o.y + 1), Vector2(lerpf(x, o.x + lean, 0.1), o.y - h + 2), 0.6)
		"battered", "squat":
			for j in range(1, int(h / 7.0)):
				var y := o.y - j * 7.0
				var x := o.x - hw * 0.8 + (j % 2) * 3.0
				ci.draw_arc(Vector2(x + 3, y), 2.2, PI * 1.05, TAU * 0.97, 5, Color(INK, 0.7), 0.7, true)
				ci.draw_arc(Vector2(x + 9, y), 2.2, PI * 1.05, TAU * 0.97, 5, Color(INK, 0.7), 0.7, true)
		_:
			ci.draw_polyline(_q(o + Vector2(-hw * 0.95 + lean * 0.4, -h * 0.42), o + Vector2(lean * 0.4, -h * 0.42 + 2.5), o + Vector2(hw * 0.95 + lean * 0.4, -h * 0.42)), Color(INK, 0.7), 0.8, true)
	# janelas e porta
	var nwin := 3 if tall else (2 if h > 40.0 else 1)
	for i in nwin:
		var y := -h * (0.62 + 0.24 * i / maxf(1.0, nwin)) if not tall else -h * (0.25 + 0.25 * i)
		_dot_window(o + Vector2(-w * 0.12 + lean * (-y / h), y), maxf(2.6, w * 0.13))
	if h > 30.0:
		if tb == "planks":
			_ws(_arch(o + Vector2(-w * 0.06, 1.5), w * 0.3, minf(h * 0.22, 11.0)), BG, 1.1)
		else:
			Minimap._fill(ci, _arch(o + Vector2(-w * 0.06, 1.5), w * 0.28, minf(h * 0.2, 11.0)), INK)
	if tall:
		for t in [0.36, 0.68]:
			var y: float = -h * t
			var ww := lerpf(hw, tw, t) + 6.0
			var c := o + Vector2(lean * t, y)
			_ws(_cat([[c + Vector2(-ww, 0)], _q(c + Vector2(-ww, 0), c + Vector2(0, 5), c + Vector2(ww, 0)), [c + Vector2(ww - 2, -4), c + Vector2(-ww + 2, -4)]]))
			for i in 7:
				var x := c.x - ww + 2 + i * (ww * 2 - 4) / 6.0
				_wl(Vector2(x, c.y - 4), Vector2(x, c.y - 9), 0.9)
			_wl(c + Vector2(-ww + 1, -9), c + Vector2(ww - 1, -9), 1.0)
	var tip := _tower_top(o + Vector2(lean, -h), tw, top, tall)
	if flag:
		_flag(tip)


## O topo da torre; devolve a ponta (para a bandeira).
func _tower_top(t: Vector2, tw: float, top: String, tall: bool) -> Vector2:
	var w := tw * 2.0
	var rl := t + Vector2(-tw - 3.5, 1.5)
	var rr := t + Vector2(tw + 3.5, 1.5)
	var rim := _q(rr, t + Vector2(0, 6), rl, 8)
	match top:
		"crenel", "hoarding":
			if top == "hoarding":
				# galeria de madeira saliente e um telhado baixo
				var gl := t + Vector2(-tw - 5, 4)
				var gr := t + Vector2(tw + 5, 4)
				var gal := PackedVector2Array([gl, gr, gr + Vector2(0, -10), gl + Vector2(0, -10)])
				_ws(gal)
				for i in range(1, 6):
					_wl(gl.lerp(gr, i / 6.0), gl.lerp(gr, i / 6.0) + Vector2(0, -10), 0.6)
				for i in 4:
					var x := gl.x + 2 + i * (w + 6) / 3.5
					ci.draw_line(Vector2(x, gl.y), Vector2(x + 2, gl.y + 4), INK, 0.9, true)
				return _cone(t + Vector2(0, -10), tw + 6.0, w * 1.0, "straight")
			var pl := t + Vector2(-tw - 3, 2)
			var pr := t + Vector2(tw + 3, 2)
			_ws(PackedVector2Array([pl, pr, pr + Vector2(0, -6), pl + Vector2(0, -6)]))
			for i in 4:
				var x := pl.x + 1.5 + i * (pr.x - pl.x - 3) / 3.5
				ci.draw_arc(Vector2(x + 1.5, pl.y + 1.5), 1.5, 0.0, PI, 5, INK, 0.9, true)
			var n := maxi(3, int((pr.x - pl.x) / 5.5))
			for i in n:
				if i % 2 == 0:
					var x := pl.x + i * (pr.x - pl.x) / (n - 1.0) - 1.6
					var hm := r.randf_range(4.0, 5.5)
					_ws(PackedVector2Array([Vector2(x, pl.y - 6), Vector2(x + 0.3, pl.y - 6 - hm), Vector2(x + 3.4, pl.y - 6 - hm), Vector2(x + 3.6, pl.y - 6)]), BG, _lw() * 0.7)
			return t + Vector2(0, -10)
		"witch":
			var lean := r.randf_range(0.18, 0.32) * (1.0 if r.randf() < 0.5 else -1.0)
			var hgt := w * (1.8 if not tall else 2.4)
			var apex := t + Vector2(hgt * lean, -hgt)
			var tipx := apex + Vector2(hgt * lean * 0.6, hgt * 0.06)
			var lside := _q(rl, t + Vector2(-tw * 0.35, -hgt * 0.42), apex)
			var rside := _q(apex, t + Vector2(tw * 0.35, -hgt * 0.42), rr)
			var cone := _cat([lside, rside, rim])
			_ws(cone)
			_shade(_cat([[apex], _q(apex, t + Vector2(tw * 0.35, -hgt * 0.42), rr), [t + Vector2(tw * 0.25, 5)]]))
			_wp(_q(apex, apex + Vector2(hgt * lean * 0.2, -1.5), tipx), _lw() * 0.9)
			ci.draw_polyline(_q(rl + Vector2(2, -hgt * 0.2), t + Vector2(0, -hgt * 0.2 + 3), rr + Vector2(-2, -hgt * 0.2)), Color(INK, 0.7), 0.8, true)
			return tipx
		"round":
			var hgt := w * 1.1
			var apex := t + Vector2(0, -hgt)
			var cone := _cat([_q(rl + Vector2(-2, 0), t + Vector2(-tw * 1.05, -hgt * 0.75), apex), _q(apex, t + Vector2(tw * 1.05, -hgt * 0.75), rr + Vector2(2, 0)), _q(rr + Vector2(2, 0), t + Vector2(0, 7), rl + Vector2(-2, 0))])
			_ws(cone)
			for i in 8:
				var p: Vector2 = Minimap._along(_q(rr + Vector2(2, 0), t + Vector2(0, 7), rl + Vector2(-2, 0)), (i + 0.5) / 8.0)
				ci.draw_line(p, p.lerp(apex, 0.3), Color(INK, 0.7), 0.7, true)
			_shade(_cat([[apex], _q(apex, t + Vector2(tw * 1.05, -hgt * 0.75), rr + Vector2(2, 0)), [t + Vector2(tw * 0.3, 6)]]))
			return apex
		"spire":
			return _cone(t, tw + 2.5, w * (3.0 if not tall else 3.4), "concave", true)
		"leaf":
			var hgt := w * (2.2 if not tall else 2.6)
			var apex := t + Vector2(0, -hgt)
			var l := Minimap._cubic(rl, t + Vector2(-tw * 1.9, -hgt * 0.35), t + Vector2(-tw * 0.1, -hgt * 0.55), apex, 12)
			var rgt := Minimap._cubic(apex, t + Vector2(tw * 0.1, -hgt * 0.55), t + Vector2(tw * 1.9, -hgt * 0.35), rr, 12)
			_ws(_cat([l, rgt, rim]))
			_shade(_cat([[apex], rgt, [t + Vector2(tw * 0.2, 5)]]))
			ci.draw_polyline(_q(t + Vector2(0, -hgt * 0.05), t + Vector2(-2, -hgt * 0.5), apex), Color(INK, 0.7), 0.8, true)
			var tend := apex + Vector2(0, -6)
			_wl(apex, tend, 1.1)
			ci.draw_arc(tend + Vector2(2, 0), 2.0, PI, TAU * 1.1, 7, INK, 1.0, true)
			return tend
		"stacked":
			var c := t
			var ww := tw + 5.0
			for i in 3:
				var hh := 9.0 - i * 1.5
				var a := c + Vector2(-ww, 2)
				var b := c + Vector2(ww, 2)
				var top_c := c + Vector2(0, -hh)
				_ws(_cat([_q(a, a.lerp(top_c, 0.5) + Vector2(1.5, 1.5), top_c + Vector2(-ww * 0.45, 0)), [top_c + Vector2(ww * 0.45, 0)], _q(top_c + Vector2(ww * 0.45, 0), b.lerp(top_c, 0.5) + Vector2(-1.5, 1.5), b)]))
				_shade(PackedVector2Array([top_c + Vector2(ww * 0.1, 0), top_c + Vector2(ww * 0.45, 0), b, c + Vector2(ww * 0.2, 2)]), "vert")
				if i < 2:
					_ws(PackedVector2Array([top_c + Vector2(-ww * 0.4, 0), top_c + Vector2(ww * 0.4, 0), top_c + Vector2(ww * 0.4, -4), top_c + Vector2(-ww * 0.4, -4)]))
				c = top_c + Vector2(0, -4)
				ww *= 0.62
			var apex := c + Vector2(0, -6)
			_wl(c + Vector2(0, 4), apex, 1.2)
			_wl(apex + Vector2(-3, 0), apex + Vector2(2, -5), 1.0)
			return apex
		_:
			return _cone(t, tw + 3.5, w * (1.45 if not tall else 2.0), "straight")


## Telhado cônico de torre; devolve a ponta.
func _cone(t: Vector2, half: float, hgt: float, prof: String, lucarne := false) -> Vector2:
	var rl := t + Vector2(-half, 1.5)
	var rr := t + Vector2(half, 1.5)
	var apex := t + Vector2(r.randf_range(-1.0, 1.0), -hgt)
	var bow := (half * 0.18) if prof != "concave" else (-half * 0.3)
	var lside := _q(rl, rl.lerp(apex, 0.5) + Vector2(-bow, 0), apex)
	var rside := _q(apex, rr.lerp(apex, 0.5) + Vector2(bow, 0), rr)
	var rim := _q(rr, t + Vector2(0, 5.5), rl, 8)
	_ws(_cat([lside, rside, rim]))
	_shade(_cat([[apex], rside, [t + Vector2(half * 0.2, 5)]]))
	for f in [0.35, 0.65]:
		var a := rl.lerp(apex, f)
		var b := rr.lerp(apex, f)
		ci.draw_polyline(_q(a, (a + b) * 0.5 + Vector2(0, 3.0 * (1.0 - f)), b), Color(INK, 0.7), 0.8, true)
	if lucarne:
		var p := t.lerp(apex, 0.35) + Vector2(-half * 0.15, 0)
		_ws(_cat([[p + Vector2(-2.5, 3), p + Vector2(-2.5, -2)], _q(p + Vector2(-3.5, -1.5), p + Vector2(0, -6), p + Vector2(3.5, -1.5)), [p + Vector2(2.5, -2), p + Vector2(2.5, 3)]]), BG, 1.0)
		ci.draw_circle(p + Vector2(0, 0.5), 0.9, INK)
	var fin := apex + Vector2(0, -5)
	_wl(apex, fin, 1.2)
	ci.draw_circle(fin, 1.3, INK)
	return fin


func _flag(tip: Vector2) -> void:
	_wl(tip, tip + Vector2(0, -12), 1.2)
	var f := tip + Vector2(0, -12)
	var cloth := _cat([_q(f, f + Vector2(7, -3.5), f + Vector2(15, 0.5)), [f + Vector2(10, 3)], _q(f + Vector2(14, 6.5), f + Vector2(7, 3), f + Vector2(0, 6))])
	_ws(cloth, BG, 1.1)
	ci.draw_line(f + Vector2(3, 1.5), f + Vector2(9, 2.5), INK, 0.7, true)


## Trecho de muralha de a até b (a base segue o terreno), com pedras, ameias irregulares ou paliçada de toras.
func _cwall(a: Vector2, b: Vector2, h: float, top := "crenel", shade := false) -> void:
	var ln := a.distance_to(b)
	var sag := Vector2(0, r.randf_range(0.5, 2.5))
	var base := _q(a, a.lerp(b, 0.5) + sag, b, maxi(4, int(ln / 8.0)))
	var topl := PackedVector2Array()
	for p in base:
		topl.append(p + Vector2(0, -h + r.randf_range(-0.4, 0.4)))
	var poly := PackedVector2Array(base)
	for i in range(topl.size() - 1, -1, -1):
		poly.append(topl[i])
	if top == "palisade":
		# toras de ponta
		var n := maxi(3, int(ln / 5.5))
		var logs := PackedVector2Array()
		for i in n + 1:
			var p: Vector2 = Minimap._along(base, float(i) / n)
			var hh := h + r.randf_range(-1.5, 1.5)
			logs.append_array([p + Vector2(-2.6, 0), p + Vector2(-2.6, -hh), p + Vector2(0, -hh - 4), p + Vector2(2.6, -hh)])
		Minimap._fill(ci, poly, BG)
		for i in n + 1:
			var p: Vector2 = Minimap._along(base, float(i) / n)
			var hh := h + r.randf_range(-1.5, 1.5)
			var lg := PackedVector2Array([p + Vector2(-2.6, 0), p + Vector2(-2.6, -hh), p + Vector2(0, -hh - 4.5), p + Vector2(2.6, -hh), p + Vector2(2.6, 0)])
			_ws(lg, BG, _lw() * 0.7)
			if b.y < a.y - 4.0 or i % 3 == 0:
				ci.draw_line(p + Vector2(1.2, -1), p + Vector2(1.2, -hh + 1), INK, 0.8, true)
		_wl(base[0] + Vector2(0, -h * 0.35), base[base.size() - 1] + Vector2(0, -h * 0.35), 1.0)
		return
	if top == "plain":
		_ws(poly)
		for i in int(ln / 7.0):
			var p: Vector2 = Minimap._along(topl, (i + 0.5) / maxf(1.0, int(ln / 7.0)))
			ci.draw_line(p + Vector2(0, h * 0.4), p + Vector2(2.5, h * 0.4), Color(INK, 0.6), 0.7, true)
		return
	_ws(poly)
	if shade:
		_shade(poly, "", 0.7)
	else:
		# pedras: fiadas desencontradas de traços curtos
		var rows := int(h / 5.0)
		for j in range(1, rows):
			var off := Vector2(0, -h * j / rows)
			var m := int(ln / 9.0)
			for i in m:
				if r.randf() < 0.7:
					var u := (i + (0.5 if j % 2 == 0 else 0.0) + r.randf_range(-0.1, 0.1)) / maxf(1.0, m)
					var p: Vector2 = Minimap._along(base, clampf(u, 0.0, 1.0)) + off
					ci.draw_line(p, p + (b - a).normalized() * r.randf_range(3.0, 5.5), Color(INK, 0.7), 0.7, true)
	# adarve e ameias de alturas diferentes
	ci.draw_polyline(_offset_down(topl, 3.0), Color(INK, 0.8), 0.9, true)
	var nm := maxi(2, int(ln / 8.0))
	for i in nm:
		var u := (i + 0.25) / nm
		var p: Vector2 = Minimap._along(topl, u)
		var q: Vector2 = Minimap._along(topl, minf(1.0, u + 0.45 / nm))
		var hm := r.randf_range(3.8, 5.5)
		_ws(PackedVector2Array([p, p + Vector2(0.3, -hm), q + Vector2(-0.3, -hm), q]), BG, _lw() * 0.7)


func _offset_down(pts: PackedVector2Array, dy: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + Vector2(0, dy))
	return out


## Casa da guarda: duas torrinhas, o arco e a grade levadiça.
func _gatehouse(o: Vector2, w: float, h: float) -> void:
	var hw := w * 0.5
	var body := _cat([[o + Vector2(-hw, 0), o + Vector2(-hw + 1, -h)], _q(o + Vector2(-hw + 1, -h), o + Vector2(0, -h - 2), o + Vector2(hw - 1, -h)), [o + Vector2(hw, 0)]])
	_ws(body)
	_tower(o + Vector2(-hw + 6, 2), 15, h + 14, "", false)
	_tower(o + Vector2(hw - 6, 2), 15, h + 14, "", false)
	var gw := w * 0.44
	var gate := _arch(o, gw, h * 0.72)
	Minimap._fill(ci, gate, INK)
	for i in range(1, 5):
		var x := o.x - gw * 0.5 + gw * i / 5.0
		ci.draw_line(Vector2(x, o.y - 1), Vector2(x, o.y - h * 0.62), BG, 1.0, true)
	for j in range(1, 4):
		var y := o.y - h * 0.62 * j / 4.0
		ci.draw_line(Vector2(o.x - gw * 0.42, y), Vector2(o.x + gw * 0.42, y), BG, 1.0, true)
	_wp(gate, _lw() * 1.1)


## Torre de menagem quadrada em volume, com parapeito de ameias.
func _square_keep(o: Vector2, w: float, h: float, d: float) -> void:
	var hw := w * 0.5
	var off := Vector2(d, -d * 0.42)
	var lean := r.randf_range(-1.0, 1.0) * 1.2
	var side := PackedVector2Array([o + Vector2(hw, 0), o + Vector2(hw, 0) + off, o + Vector2(hw + lean, -h) + off, o + Vector2(hw + lean, -h)])
	_ws(side)
	_shade(side)
	var topf := PackedVector2Array([o + Vector2(-hw + lean, -h), o + Vector2(hw + lean, -h), o + Vector2(hw + lean, -h) + off, o + Vector2(-hw + lean, -h) + off])
	_ws(topf)
	var front := PackedVector2Array([o + Vector2(-hw, 0), o + Vector2(hw, 0), o + Vector2(hw + lean, -h), o + Vector2(-hw + lean, -h)])
	_ws(front)
	_body_tex(o + Vector2(-hw, 0), o + Vector2(hw, 0), o + Vector2(-hw + lean, -h), o + Vector2(hw + lean, -h), o + Vector2(-hw, -h * 0.5), o + Vector2(hw, -h * 0.5), 0.0, "stone" if str(st.get("body", "")) == "stone" else "plain")
	_cwall(o + Vector2(-hw + lean - 2, -h + 1), o + Vector2(hw + lean + 2, -h + 1), 0.1, "crenel")
	for i in 2:
		_dot_window(o + Vector2(-hw * 0.45 + i * hw * 0.9 + lean * 0.5, -h * 0.6), 4.0)
	_dot_window(o + Vector2(lean * 0.3, -h * 0.82), 3.5)
	Minimap._fill(ci, _arch(o, w * 0.24, h * 0.24), INK)
	_flag(o + Vector2(lean, -h - 6) + off * 0.5)


## Igreja da vila: nave e torre com o topo do estilo.
func _church(o: Vector2, s: float) -> void:
	_house(o + Vector2(9, 0), 18 * s, 13 * s, 30 * s, "tile", false, 2)
	_tower(o + Vector2(-9, 3), 13 * s, 32 * s, str(st.get("church", "spire")), false)


func _abbey(o: Vector2) -> void:
	_house(o + Vector2(12, 0), 26, 18, 44, "tile", false, 3)
	_tower(o + Vector2(-15, 4), 17, 44, str(st.get("church", "spire")), false)


func _cathedral(o: Vector2) -> void:
	_house(o + Vector2(14, 0), 30, 22, 46, "tile", false, 3)
	_tower(o + Vector2(-18, 4), 19, 52, str(st.get("church", "spire")), false)


# ------------------------------------------------------------------ o covil

## Montanha de chifres com a bocarra de presas e a caveira entalhada.
func _lair_maw(l: Vector2) -> void:
	var b := l.y + 24
	var o := Vector2(l.x, b)
	var horns := [[-150, 0.55, 60], [-100, 0.8, 92], [-58, 1.0, 128], [0, 1.15, 150], [52, 1.0, 132], [100, 0.8, 98], [146, 0.6, 52]]
	var outline := PackedVector2Array([o + Vector2(-196, 2)])
	var peaks: Array = []
	for i in horns.size():
		var hx := float(horns[i][0])
		var hh := float(horns[i][2])
		var lean := r.randf_range(-6, 10)
		var p := o + Vector2(hx + lean, -hh)
		peaks.append(p)
		var prev: Vector2 = outline[outline.size() - 1]
		outline.append_array(_q(prev, (prev + p) * 0.5 + Vector2(-6, 10), p, 6).slice(1))
		var valley := o + Vector2(hx + 24, -hh * 0.55 + r.randf_range(-6, 6)) if i < horns.size() - 1 else o + Vector2(196, 2)
		outline.append_array(_q(p, (p + valley) * 0.5 + Vector2(6, -4), valley, 6).slice(1))
	_ws(outline, BG, 2.6)
	for i in peaks.size():
		var p: Vector2 = peaks[i]
		var foot := Vector2(p.x + 22 + r.randf_range(-6, 6), b)
		var nxt := Vector2(p.x + 46, b - 10)
		var face := _cat([[p], _q(p, (p + nxt) * 0.5 + Vector2(4, 0), nxt), [foot]])
		_shade(face)
		_wp(_q(p, (p + foot) * 0.5 + Vector2(-3, 0), foot), 1.3)
	for i in 8:
		var p := o + Vector2(-160 + i * 24 + r.randf_range(-4, 4), -18 - (i % 3) * 16)
		_wl(p, p + Vector2(6, 7), 0.9)
	_maw(Vector2(l.x, b + 2), 46.0, 66.0)
	_skull(Vector2(l.x, b - 90), 1.0)
	_bats(o)


func _maw(m: Vector2, hw: float, h: float) -> void:
	var mouth := _cat([[m + Vector2(-hw, 0)], _q(m + Vector2(-hw, 0), m + Vector2(-hw - 3, -h * 0.95), m + Vector2(0, -h)), _q(m + Vector2(0, -h), m + Vector2(hw + 3, -h * 0.95), m + Vector2(hw, 0))])
	Minimap._fill(ci, mouth, INK)
	for i in 6:
		var x := m.x - hw * 0.72 + i * hw * 0.29
		var y := m.y - h * 0.94 + absf(i - 2.5) * 4.5
		var ln := 15.0 - absf(i - 2.5) * 1.6
		_ws(_cat([[Vector2(x - 5, y)], _q(Vector2(x - 5, y), Vector2(x - 1, y + ln * 0.6), Vector2(x + 0.5, y + ln)), _q(Vector2(x + 0.5, y + ln), Vector2(x + 2, y + ln * 0.5), Vector2(x + 5, y))]), BG, 1.0)
	for i in 5:
		var x := m.x - hw * 0.56 + i * hw * 0.28
		_ws(_cat([[Vector2(x - 4, m.y)], _q(Vector2(x - 4, m.y), Vector2(x - 0.5, m.y - 6), Vector2(x, m.y - 11)), _q(Vector2(x, m.y - 11), Vector2(x + 1.5, m.y - 5), Vector2(x + 4, m.y))]), BG, 1.0)
	_wp(mouth, 2.8)


func _skull(sk: Vector2, s: float) -> void:
	var head := Minimap._smooth([sk + Vector2(-13, 4) * s, sk + Vector2(-14, -8) * s, sk + Vector2(0, -17) * s, sk + Vector2(14, -8) * s, sk + Vector2(13, 4) * s, sk + Vector2(7, 11) * s, sk + Vector2(-7, 11) * s], true, 4)
	_ws(head, BG, 1.8)
	Minimap._fill(ci, Minimap._smooth(Minimap._ell(sk + Vector2(-5.5, -3) * s, 3.8 * s, 3.4 * s, 6, r, 0.2), true, 3), INK)
	Minimap._fill(ci, Minimap._smooth(Minimap._ell(sk + Vector2(5.5, -3) * s, 3.8 * s, 3.4 * s, 6, r, 0.2), true, 3), INK)
	Minimap._fill(ci, PackedVector2Array([sk + Vector2(0, 1.5) * s, sk + Vector2(-2, 6) * s, sk + Vector2(2, 6) * s]), INK)
	for i in 4:
		_wl(sk + Vector2(-5 + i * 3.3, 7.5) * s, sk + Vector2(-5 + i * 3.3, 11) * s, 1.0)


func _bats(o: Vector2) -> void:
	for p in [Vector2(-40, -186), Vector2(-14, -200), Vector2(28, -180), Vector2(70, -196), Vector2(4, -222)]:
		_bat(o + p)


## Torre negra arruinada sobre o penhasco, com a caverna de presas embaixo.
func _lair_tower(l: Vector2) -> void:
	var b := l.y + 24
	var o := Vector2(l.x, b)
	_crag(o + Vector2(0, 0), 190, 70)
	var t := o + Vector2(14, -58)
	var hw := 26.0
	var h := 140.0
	var left := _q(t + Vector2(-hw, 0), t + Vector2(-hw - 3, -h * 0.5), t + Vector2(-hw * 0.7, -h))
	var broken := PackedVector2Array([t + Vector2(-hw * 0.7, -h), t + Vector2(-hw * 0.3, -h - 14), t + Vector2(-hw * 0.05, -h + 2), t + Vector2(hw * 0.25, -h - 22), t + Vector2(hw * 0.5, -h - 6), t + Vector2(hw * 0.7, -h + 8)])
	var right := _q(t + Vector2(hw * 0.7, -h + 8), t + Vector2(hw + 3, -h * 0.5), t + Vector2(hw, 0))
	var body := _cat([left, broken, right, _q(t + Vector2(hw, 0), t + Vector2(0, 5), t + Vector2(-hw, 0))])
	_ws(body, BG, 2.4)
	_shade(_cat([[t + Vector2(hw * 0.1, -h + 2)], broken.slice(3), right, [t + Vector2(hw * 0.1, 3)]]), "solid")
	for i in 4:
		Minimap._fill(ci, _arch(t + Vector2(-hw * 0.35, -h * (0.25 + i * 0.2)), 6, 12), INK)
	for i in 6:
		var p := t + Vector2(r.randf_range(-hw * 0.8, 0), -r.randf_range(10, h - 10))
		ci.draw_arc(p, 2.4, PI * 1.05, TAU * 0.97, 5, INK, 0.8, true)
	_maw(Vector2(l.x - 60, b + 2), 34.0, 50.0)
	_skull(t + Vector2(-hw * 0.3, -h * 0.9), 0.8)
	_bats(o)


## Penhasco em forma de caveira: as órbitas são cavernas e a boca é a entrada, com presas.
func _lair_skull(l: Vector2) -> void:
	var b := l.y + 24
	var o := Vector2(l.x, b)
	var dome := _cat([[o + Vector2(-190, 2)], _q(o + Vector2(-190, 2), o + Vector2(-170, -60), o + Vector2(-120, -78)),
		Minimap._cubic(o + Vector2(-120, -78), o + Vector2(-100, -168), o + Vector2(100, -168), o + Vector2(120, -78), 16),
		_q(o + Vector2(120, -78), o + Vector2(170, -60), o + Vector2(190, 2))])
	_ws(dome, BG, 2.6)
	_shade(_cat([[o + Vector2(30, -150)], Minimap._cubic(o + Vector2(30, -150), o + Vector2(90, -150), o + Vector2(118, -110), o + Vector2(120, -78), 8),
		_q(o + Vector2(120, -78), o + Vector2(170, -60), o + Vector2(190, 2)), [o + Vector2(70, 2)], _q(o + Vector2(70, 2), o + Vector2(80, -80), o + Vector2(30, -150))]))
	for i in 10:
		var p := o + Vector2(r.randf_range(-150, -20), r.randf_range(-130, -20))
		_wl(p, p + Vector2(r.randf_range(4, 9), r.randf_range(3, 7)), 0.9)
	# órbitas
	for sx in [-1.0, 1.0]:
		var c := o + Vector2(sx * 52, -98)
		var eye := Minimap._smooth(Minimap._ell(c, 30, 24, 8, r, 0.15), true, 4)
		Minimap._fill(ci, eye, INK)
		_wp(eye, 2.4)
	# nariz
	Minimap._fill(ci, _cat([[o + Vector2(0, -70)], _q(o + Vector2(0, -70), o + Vector2(-12, -54), o + Vector2(-10, -46)), [o + Vector2(10, -46)], _q(o + Vector2(10, -46), o + Vector2(12, -54), o + Vector2(0, -70))]), INK)
	_maw(Vector2(l.x, b + 2), 58.0, 40.0)
	for x in [-70.0, 70.0]:
		_wl(o + Vector2(x, -30), o + Vector2(x * 1.3, 0), 1.2)
	_bats(o)


## Penhasco de pedra (base de torre ou do covil).
func _crag(c: Vector2, w: float, h: float) -> void:
	var pts := _cat([[c + Vector2(-w, 8)], _q(c + Vector2(-w, 8), c + Vector2(-w * 0.85, -h * 0.3), c + Vector2(-w * 0.55, -h * 0.5)),
		_q(c + Vector2(-w * 0.55, -h * 0.5), c + Vector2(-w * 0.35, -h * 1.05), c + Vector2(-w * 0.05, -h)),
		_q(c + Vector2(-w * 0.05, -h), c + Vector2(w * 0.3, -h * 1.05), c + Vector2(w * 0.5, -h * 0.55)),
		_q(c + Vector2(w * 0.5, -h * 0.55), c + Vector2(w * 0.85, -h * 0.4), c + Vector2(w, 8))])
	_ws(pts, BG, 2.3)
	_shade(_cat([[c + Vector2(w * 0.12, -h * 0.98)], _q(c + Vector2(w * 0.12, -h * 0.98), c + Vector2(w * 0.35, -h * 0.9), c + Vector2(w * 0.5, -h * 0.55)),
		_q(c + Vector2(w * 0.5, -h * 0.55), c + Vector2(w * 0.85, -h * 0.4), c + Vector2(w, 8)), [c + Vector2(w * 0.25, 8)]]))
	_wl(c + Vector2(-w * 0.05, -h), c + Vector2(-w * 0.02, 4), 1.1)
	_wl(c + Vector2(-w * 0.55, -h * 0.5), c + Vector2(-w * 0.6, 4), 1.0)


func _bat(p: Vector2) -> void:
	var wing := _cat([_q(p + Vector2(-9, -2), p + Vector2(-5, -5), p + Vector2(-2, -1)), [p + Vector2(0, -3)],
		_q(p + Vector2(2, -1), p + Vector2(5, -5), p + Vector2(9, -2)), [p + Vector2(4, 0), p + Vector2(0, 2), p + Vector2(-4, 0)]])
	Minimap._fill(ci, wing, INK)


func _bones(p: Vector2) -> void:
	for i in 3:
		var a := r.randf() * PI
		var d := Vector2(cos(a), sin(a) * 0.4) * 6.0
		var q := p + Vector2(i * 9 - 9, r.randf_range(-2, 2))
		_wl(q - d, q + d, 1.4)
		ci.draw_circle(q - d, 1.6, INK)
		ci.draw_circle(q + d, 1.6, INK)


func _well(p: Vector2) -> void:
	_ws(_cat([[p + Vector2(-6, -5), p + Vector2(-6, 0)], _q(p + Vector2(-6, 0), p + Vector2(0, 2), p + Vector2(6, 0)), [p + Vector2(6, -5)]]), BG, 1.4)
	_wl(p + Vector2(-5, -5), p + Vector2(-5, -14), 1.2)
	_wl(p + Vector2(5, -5), p + Vector2(5, -14), 1.2)
	_ws(_cat([[p + Vector2(-8.5, -12.5)], _q(p + Vector2(-8.5, -12.5), p + Vector2(-3, -16), p + Vector2(0, -19.5)), _q(p + Vector2(0, -19.5), p + Vector2(3, -16), p + Vector2(8.5, -12.5))]), BG, 1.3)


func _haystack(p: Vector2, s: float) -> void:
	var dome := _cat([[p + Vector2(-s, 0)], _q(p + Vector2(-s, 0), p + Vector2(-s * 0.7, -s * 2.0), p + Vector2(0, -s * 2.0)), _q(p + Vector2(0, -s * 2.0), p + Vector2(s * 0.7, -s * 2.0), p + Vector2(s, 0))])
	_ws(dome, BG, 1.4)
	for i in 4:
		var x := p.x + s * (0.2 + i * 0.2)
		_wl(Vector2(x, p.y - s * 1.5 + i * 2), Vector2(x - 1, p.y - 1), 0.8)


func _fence(a: Vector2, b: Vector2) -> void:
	_wl(a + Vector2(0, -4), b + Vector2(0, -4), 1.0)
	_wl(a + Vector2(0, -8), b + Vector2(0, -8), 1.0)
	var n := int(a.distance_to(b) / 9.0)
	for i in n + 1:
		var p := a.lerp(b, float(i) / maxf(n, 1))
		_wl(p, p + Vector2(r.randf_range(-0.6, 0.6), -10), 1.2)


func _cross_grave(p: Vector2) -> void:
	_wl(p, p + Vector2(0, -9), 1.4)
	_wl(p + Vector2(-3, -6), p + Vector2(3, -6), 1.4)
	_wl(p + Vector2(-3, 1), p + Vector2(3, 1), 0.8)


# ------------------------------------------------------------------ terreno

func _tree_k(kind: String) -> void:
	pen._tree(ci, kind, Vector2.ZERO, 1.0, r)


func _scatter() -> void:
	var paper := _paper()
	var tries := 0
	var placed := 0
	var want := int(v.get("scatter", 180))
	var kinds: Array = v.get("trees", ["d", "r", "p", "f"])
	while placed < want and tries < 3000:
		tries += 1
		var p := Vector2(r.randf_range(50, paper.x - 50), r.randf_range(150, paper.y - 40))
		if not _free(p, 10.0):
			continue
		placed += 1
		occ.append([p, 8.0])
		var roll := r.randf()
		if roll < 0.08:
			var w := r.randf_range(34, 50)
			if _free(p + Vector2(0, -w * 0.3), w * 0.6):
				_add(p.y, func(): pen._hill_v(ci, p.x, p.y, w, r))
		elif roll < 0.12:
			_put(p, 1.2, func(): pen._tree(ci, "x", Vector2.ZERO, 1.0, r))
		else:
			var kind: String = kinds[r.randi() % kinds.size()]
			for j in r.randi_range(1, 3):
				var q := p + Vector2(r.randf_range(-22, 22), r.randf_range(-8, 8))
				if _free(q, 8.0, false):
					_put(q, r.randf_range(1.05, 1.3), func(): _tree_k(kind))


func _blob_poly(c: Vector2, rx: float, ry: float, amp: float) -> PackedVector2Array:
	return Minimap._smooth(Minimap._ell(c, rx, ry, 12, r, amp), true, 4)


func _scaled(poly: PackedVector2Array, c: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(c + (p - c) * s)
	return out


func _lake(poly: PackedVector2Array, c: Vector2, frozen: bool) -> void:
	ci.draw_colored_polygon(poly, SEA)
	for i in 3:
		var sh := _scaled(poly, c, 1.0 + 0.045 * (i + 1) * (1.0 if not frozen else 0.6))
		sh.append(sh[0])
		ci.draw_polyline(sh, Color(INK, 0.45 - i * 0.12), 1.0, true)
	var closed := PackedVector2Array(poly)
	closed.append(poly[0])
	ci.draw_polyline(closed, INK, 2.6, true)
	var b := Minimap._bounds(poly)
	if frozen:
		# gelo: rachaduras em zigue-zague e um pouco de neve na margem
		for i in 5:
			var p := c + Vector2(r.randf_range(-b.size.x, b.size.x) * 0.3, r.randf_range(-b.size.y, b.size.y) * 0.25)
			var line := PackedVector2Array([p])
			for j in 4:
				p += Vector2(r.randf_range(-14, 14), r.randf_range(-6, 6))
				if Geometry2D.is_point_in_polygon(p, poly):
					line.append(p)
			if line.size() > 1:
				ci.draw_polyline(line, INK, 1.0, true)
	else:
		for i in 3:
			var yy := c.y - b.size.y * 0.18 + i * b.size.y * 0.16
			var ww := b.size.x * (0.22 - i * 0.04)
			var x0 := c.x - ww + r.randf_range(-8, 8)
			ci.draw_polyline(Minimap._quad(Vector2(x0, yy), Vector2(x0 + ww * 0.5, yy - 3), Vector2(x0 + ww, yy)), Color(INK, 0.7), 1.1, true)
			ci.draw_polyline(Minimap._quad(Vector2(x0 + ww, yy), Vector2(x0 + ww * 1.5, yy + 3), Vector2(x0 + ww * 2, yy)), Color(INK, 0.7), 1.1, true)


## Marcas de onda espalhadas na água (fora da ilha), mais numerosas quanto maior a água.
func _waves(w: PackedVector2Array) -> void:
	var b := Minimap._bounds(w)
	var paper := _paper()
	b = b.intersection(Rect2(Vector2(30, 40), paper - Vector2(60, 70)))
	var n := int(b.size.x * b.size.y / 5200.0)
	var placed: Array = []
	for i in n * 3:
		if placed.size() >= n:
			break
		var p := Vector2(r.randf_range(b.position.x, b.end.x), r.randf_range(b.position.y, b.end.y))
		if not Geometry2D.is_point_in_polygon(p, w) or not Geometry2D.is_point_in_polygon(p + Vector2(22, 0), w):
			continue
		if island.size() > 2 and (Geometry2D.is_point_in_polygon(p, island) or Geometry2D.is_point_in_polygon(p + Vector2(22, 0), island)):
			continue
		var edge := false
		for j in w.size() - 1:
			if Geometry2D.get_closest_point_to_segment(p + Vector2(11, 0), w[j], w[j + 1]).distance_to(p + Vector2(11, 0)) < 16.0:
				edge = true
				break
		if edge or _near_road(p + Vector2(11, 0), 16.0):
			continue
		var close := false
		for q in placed:
			if q.distance_to(p) < 40.0:
				close = true
				break
		if close:
			continue
		placed.append(p)
		ci.draw_polyline(Minimap._quad(p, p + Vector2(5.5, -4), p + Vector2(11, 0)), Color(INK, 0.75), 1.2, true)
		ci.draw_polyline(Minimap._quad(p + Vector2(11, 0), p + Vector2(16.5, -4), p + Vector2(22, 0)), Color(INK, 0.75), 1.2, true)


## Serra ao longo de uma espinha: duas fileiras de picos (a de trás menor), sem cair em água, estrada ou região.
func _range(spine: Array, snowy: float, size: float) -> void:
	var line := Minimap._smooth(spine, false, 6)
	var ln := 0.0
	for i in line.size() - 1:
		ln += line[i].distance_to(line[i + 1])
	var step := 44.0 * size
	var d := 0.0
	while d <= ln:
		var p := Minimap._along(line, d / maxf(ln, 1.0))
		for row in 2:
			var sc := 0.72 if row == 0 else 1.0
			var w := r.randf_range(34, 56) * size * sc
			var h := r.randf_range(50, 88) * size * sc
			var q := p + Vector2(r.randf_range(-10, 10), (-22.0 if row == 0 else 0.0) + r.randf_range(-8, 8))
			var foot := q + Vector2(0, -h * 0.25)
			if not _free(foot, w * 0.85, false):
				continue
			occ.append([foot, w * 0.85])
			var sn := r.randf() < snowy
			_add(q.y, func(): pen._mtn(ci, q.x, q.y, w, h, sn, r))
		d += step * r.randf_range(0.8, 1.15)


func _hills(c: Vector2, spread: float, n: int) -> void:
	for i in n * 3:
		if n <= 0:
			break
		var p := c + Vector2(r.randf_range(-spread, spread), r.randf_range(-spread, spread) * 0.5)
		var w := r.randf_range(30, 52)
		if not _free(p + Vector2(0, -w * 0.3), w * 0.7):
			continue
		occ.append([p + Vector2(0, -w * 0.3), w * 0.7])
		n -= 1
		_add(p.y, func(): pen._hill_v(ci, p.x, p.y, w, r))


func _marsh_area(c: Vector2, rad: float) -> void:
	var n := int(rad / 22.0) + 2
	for i in n * 3:
		if n <= 0:
			break
		var p := c + Vector2(r.randf_range(-rad, rad), r.randf_range(-rad, rad) * 0.45)
		if not _free(p, 22.0):
			continue
		occ.append([p, 26.0])
		n -= 1
		var pick := r.randf()
		if pick < 0.55:
			_add(p.y, func(): pen._marsh(ci, p, r))
		elif pick < 0.8:
			_add(p.y, func(): _pond(p, r.randf_range(14, 24)))
		else:
			_put(p, 1.2, func(): pen._tree(ci, "x", Vector2.ZERO, 1.0, r))


func _pond(c: Vector2, s: float) -> void:
	var poly := _blob_poly(c, s, s * 0.45, 0.25)
	Minimap._shape(ci, poly, SEA, 1.8)
	ci.draw_polyline(Minimap._quad(c + Vector2(-s * 0.4, 0), c + Vector2(0, -2), c + Vector2(s * 0.4, 0)), Color(INK, 0.7), 1.0, true)
	for i in 3:
		var p := c + Vector2(s * (0.6 + i * 0.25), -2.0 - i)
		_wl(p, p + Vector2(0, -7 - i * 2), 1.1)


## Lugar livre para um enfeite de raio `rad`: fora das regiões (com margem), do covil, das estradas, dos rios,
## da água e do relevo já posto (use_occ).
func _free(p: Vector2, rad := 10.0, use_occ := true, use_roads := true) -> bool:
	var paper := _paper()
	if p.x < 40 or p.x > paper.x - 40 or p.y < 60 or p.y > paper.y - 30:
		return false
	for ph in data.phases:
		var m: Dictionary = ph.get("map", {})
		if m.is_empty():
			continue
		var d := (p - Vector2(float(m["pos"][0]), float(m["pos"][1]))) / Vector2(float(m["rx"]) + 30.0 + rad * 0.6, float(m["ry"]) + 40.0 + rad * 0.6)
		if d.length() < 1.0:
			return false
	var l := (p - _lair()) / Vector2(215.0 + rad * 0.6, 165.0 + rad * 0.6)
	if l.length() < 1.0:
		return false
	if use_roads and _near_road(p, 22.0 + rad * 0.6):
		return false
	for rl in rivers:
		for i in rl.size() - 1:
			if Geometry2D.get_closest_point_to_segment(p, rl[i], rl[i + 1]).distance_to(p) < 22.0 + rad * 0.8:
				return false
	for w in waters:
		if Geometry2D.is_point_in_polygon(p, w):
			return false
		for i in w.size() - 1:
			if Geometry2D.get_closest_point_to_segment(p, w[i], w[i + 1]).distance_to(p) < 8.0 + rad * 0.7:
				return false
	if use_occ:
		for o in occ:
			if p.distance_to(o[0]) < (float(o[1]) + rad) * 0.75:
				return false
	return true


func _near_road(p: Vector2, dist: float) -> bool:
	for road in roads:
		for i in road.size() - 1:
			if Geometry2D.get_closest_point_to_segment(p, road[i], road[i + 1]).distance_to(p) < dist:
				return true
	return false


## Onde a estrada cruza o rio: [ponto, ângulo da ponte] ou vazio.
func _cross(road: PackedVector2Array, line: PackedVector2Array) -> Array:
	for i in road.size() - 1:
		for j in line.size() - 1:
			var hit = Geometry2D.segment_intersects_segment(road[i], road[i + 1], line[j], line[j + 1])
			if hit != null:
				return [hit, (road[i + 1] - road[i]).angle()]
	return []


func _border(kind: String) -> void:
	var paper := _paper()
	ci.draw_rect(Rect2(Vector2(14, 14), paper - Vector2(28, 28)), INK, false, 3.0)
	ci.draw_rect(Rect2(Vector2(22, 22), paper - Vector2(44, 44)), Color(INK, 0.6), false, 1.2)
	if kind != "ticks":
		return
	# régua de mapa antigo: faixas alternadas entre as duas linhas
	var seg := 40.0
	var x := 22.0
	var i := 0
	while x < paper.x - 22.0:
		if i % 2 == 0:
			ci.draw_rect(Rect2(Vector2(x, 15.5), Vector2(minf(seg, paper.x - 22.0 - x), 5.0)), INK)
			ci.draw_rect(Rect2(Vector2(x, paper.y - 20.5), Vector2(minf(seg, paper.x - 22.0 - x), 5.0)), INK)
		x += seg
		i += 1
	var y := 22.0
	i = 0
	while y < paper.y - 22.0:
		if i % 2 == 0:
			ci.draw_rect(Rect2(Vector2(15.5, y), Vector2(5.0, minf(seg, paper.y - 22.0 - y))), INK)
			ci.draw_rect(Rect2(Vector2(paper.x - 20.5, y), Vector2(5.0, minf(seg, paper.y - 22.0 - y))), INK)
		y += seg
		i += 1


func _add(y: float, fn: Callable) -> void:
	items.append([y, fn])


## Um desenho do mapa da run em p, na escala s (o desenho é feito em volta da origem).
func _put(p: Vector2, s: float, fn: Callable) -> void:
	items.append([p.y, func():
		_tf(p, s)
		fn.call()])


func _tf(p: Vector2, s: float) -> void:
	ci.draw_set_transform(p * k, 0.0, Vector2(k * s, k * s))


func _paper() -> Vector2:
	var p: Array = data.campaign_map.get("paper", [1640, 960])
	return Vector2(float(p[0]), float(p[1]))


func _lair() -> Vector2:
	var l: Array = data.campaign_map.get("lair", [820, 500])
	return Vector2(float(l[0]), float(l[1]))




# ------------------------------------------------------------------ desenhista avulso e ícones dos lugares

## Desenhista avulso no estilo escolhido (VARIANT), sem o mapa inteiro: o mapa da run desenha casas, torres e os
## ícones dos locais com ele, e --mapicons gera os ícones do menu e da loja com ele.
static func drawer(canvas: CanvasItem) -> CampaignArt:
	var a := CampaignArt.new()
	a.ci = canvas
	a.st = STYLES[clampi(VARIANT, 0, STYLES.size() - 1)]
	return a


## Textura de um desenho do mapa (assets/ui/map): a versão PNG no estilo escolhido (gerada por --mapicons), ou o
## SVG antigo quando não há PNG (rato, bosque, monte e serviços continuam em SVG).
static func map_tex(path: String) -> Texture2D:
	var png := path.get_basename() + ".png"
	if ResourceLoader.exists(png):
		return load(png)
	return load(path) if ResourceLoader.exists(path) else null


## Ícone de lugar centrado em c, numa caixa de cerca de ±30 vezes s, sobre a transformação `base` do desenho.
## kind: house, tavern, hall, shrine, gate, lair, shop, tent, tower, mill, boat.
func icon(kind: String, base: Transform2D, c: Vector2, s: float, seed_: int) -> void:
	r.seed = seed_
	ci.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(s, s), 0.0, c))
	match kind:
		"house":
			_house(Vector2(-16, 20), 22, 14, 14, "tile", true, 1)
		"tavern":
			_house(Vector2(-22, 20), 28, 15, 18, "tile", false, 1)
			_wl(Vector2(29, 22), Vector2(29, -6), 1.8)
			_wl(Vector2(29, -6), Vector2(17, -6), 1.6)
			_wl(Vector2(19, -6), Vector2(19, -2), 1.0)
			_wl(Vector2(27, -6), Vector2(27, -2), 1.0)
			_ws(PackedVector2Array([Vector2(16, -2), Vector2(30, -2), Vector2(30, 9), Vector2(16, 9)]), BG, 1.4)
			_ws(_cat([[Vector2(19.5, 0.5)], _q(Vector2(19.5, 7.5), Vector2(23, 8.5), Vector2(26, 7.5)), [Vector2(26, 0.5)]]), BG, 1.0)
			ci.draw_arc(Vector2(26.5, 4), 2.0, -PI * 0.5, PI * 0.5, 6, INK, 1.0, true)
		"hall":
			_house(Vector2(-26, 22), 32, 17, 24, "tile", false, 2)
			_rune_stone(Vector2(30, 24), 7.0)
		"shrine":
			_rune_stone(Vector2(-25, 24), 6.0)
			_rune_stone(Vector2(25, 24), 6.0)
			_tower(Vector2(0, 24), 24, 22, "stacked", false)
		"gate":
			_cwall(Vector2(-36, 22), Vector2(-15, 22), 15.0, "palisade")
			_cwall(Vector2(15, 22), Vector2(36, 22), 15.0, "palisade")
			_gatehouse(Vector2(0, 22), 30, 16)
		"lair":
			_ic_lair()
		"shop":
			_ic_stall()
		"tent", "start":
			_ic_tent()
		"tower":
			_tower(Vector2(0, 30), 26, 30, "stacked", false)
		"mill":
			_ic_mill()
		"boat":
			_ic_boat()
	ci.draw_set_transform_matrix(base)


func _rune_stone(p: Vector2, s: float) -> void:
	var sh := _cat([[p + Vector2(-s * 0.6, 0)], _q(p + Vector2(-s * 0.7, -s * 1.3), p + Vector2(-s * 0.2, -s * 2.3), p + Vector2(s * 0.3, -s * 2.0)), _q(p + Vector2(s * 0.3, -s * 2.0), p + Vector2(s * 0.75, -s * 1.2), p + Vector2(s * 0.6, 0))])
	_ws(sh, BG, 1.4)
	_wl(p + Vector2(-s * 0.15, -s * 1.6), p + Vector2(-s * 0.15, -s * 0.4), 0.9)
	_wl(p + Vector2(-s * 0.15, -s * 1.2), p + Vector2(s * 0.25, -s * 1.5), 0.9)
	_wl(p + Vector2(-s * 0.15, -s * 0.8), p + Vector2(s * 0.25, -s * 0.5), 0.9)


func _ic_lair() -> void:
	var b := 24.0
	var peaks := [Vector2(-26, -2), Vector2(-12, -22), Vector2(2, -34), Vector2(16, -20), Vector2(28, -4)]
	var outline := PackedVector2Array([Vector2(-36, b)])
	for i in peaks.size():
		var p: Vector2 = peaks[i]
		var prev: Vector2 = outline[outline.size() - 1]
		outline.append_array(_q(prev, (prev + p) * 0.5 + Vector2(-2, 4), p, 5).slice(1))
		var valley: Vector2 = Vector2(36, b)
		if i < peaks.size() - 1:
			valley = (p + peaks[i + 1]) * 0.5 + Vector2(0, 10)
		outline.append_array(_q(p, (p + valley) * 0.5 + Vector2(2, -2), valley, 5).slice(1))
	_ws(outline, BG, 2.0)
	for p in peaks:
		var foot := Vector2(p.x + 8, b)
		_shade(_cat([[p], _q(p, p + Vector2(10, 8), p + Vector2(14, 16)), [foot]]))
		_wl(p, foot, 1.1)
	var m := Vector2(0, b + 1)
	var mouth := _cat([[m + Vector2(-13, 0)], _q(m + Vector2(-13, 0), m + Vector2(-14, -21), m + Vector2(0, -22)), _q(m + Vector2(0, -22), m + Vector2(14, -21), m + Vector2(13, 0))])
	Minimap._fill(ci, mouth, INK)
	for i in 4:
		var x := -8.0 + i * 5.3
		var y0 := m.y - 20.0 + absf(i - 1.5) * 1.5
		Minimap._fill(ci, PackedVector2Array([Vector2(x - 2, y0), Vector2(x + 2, y0), Vector2(x, m.y - 14)]), BG)
	for i in 3:
		var x := -5.0 + i * 5.0
		Minimap._fill(ci, PackedVector2Array([Vector2(x - 1.8, m.y - 0.5), Vector2(x + 1.8, m.y - 0.5), Vector2(x, m.y - 5)]), BG)
	_wp(mouth, 2.0)


## Barraca: telhado de tábuas em duas águas curvas, postes, balcão de tábuas, um saco e um barril.
func _ic_stall() -> void:
	_wl(Vector2(-24, 22), Vector2(-24, -8), 1.8)
	_wl(Vector2(24, 22), Vector2(24, -8), 1.8)
	_ws(PackedVector2Array([Vector2(-26, 22), Vector2(26, 22), Vector2(26, 8), Vector2(-26, 8)]))
	for i in range(1, 8):
		_wl(Vector2(-26 + i * 6.5, 21.5), Vector2(-26 + i * 6.5, 8.5), 0.7)
	_ws(_cat([[Vector2(-30, -6)], _q(Vector2(-30, -6), Vector2(-14, -22), Vector2(0, -30)), _q(Vector2(0, -30), Vector2(14, -22), Vector2(30, -6)), _q(Vector2(30, -6), Vector2(0, -12), Vector2(-30, -6))]), BG, 2.0)
	for i in range(1, 6):
		var t := i / 6.0
		_wl(Vector2(lerpf(-28, 28, t), -7.5 - 4.0 * sin(t * PI)), Vector2(0, -29), 0.7)
	_shade(_cat([[Vector2(0, -30)], _q(Vector2(0, -30), Vector2(14, -22), Vector2(30, -6)), [Vector2(14, -9)]]))
	_wl(Vector2(-4, -36), Vector2(4, -24), 1.4)
	_wl(Vector2(4, -36), Vector2(-4, -24), 1.4)
	_ws(_cat([[Vector2(-20, 8)], _q(Vector2(-21, 0), Vector2(-15, -6), Vector2(-9, 0)), [Vector2(-10, 8)]]), BG, 1.3)
	_wl(Vector2(-17, -2), Vector2(-13, -2), 0.8)
	_ws(PackedVector2Array([Vector2(4, 8), Vector2(4, -3), Vector2(14, -3), Vector2(14, 8)]), BG, 1.3)
	_wl(Vector2(4, 2.5), Vector2(14, 2.5), 0.8)
	_shade(PackedVector2Array([Vector2(10, 7.5), Vector2(10, -2.5), Vector2(13.5, -2.5), Vector2(13.5, 7.5)]))


func _ic_tent() -> void:
	var apex := Vector2(0, -22)
	_ws(_cat([_q(Vector2(-28, 22), Vector2(-14, 2), apex), _q(apex, Vector2(14, 2), Vector2(28, 22))]))
	_shade(_cat([[apex], _q(apex, Vector2(14, 2), Vector2(28, 22)), [Vector2(10, 22)], _q(Vector2(10, 22), Vector2(8, 4), apex)]))
	Minimap._fill(ci, _cat([[Vector2(0, -4)], _q(Vector2(0, -4), Vector2(-3, 10), Vector2(-9, 22)), [Vector2(6, 22)], _q(Vector2(6, 22), Vector2(3, 10), Vector2(0, -4))]), INK)
	_ws(_cat([[Vector2(0, -4)], _q(Vector2(0, -4), Vector2(-6, 10), Vector2(-15, 22)), [Vector2(-9, 22)], _q(Vector2(-9, 22), Vector2(-3, 10), Vector2(0, -4))]), BG, 1.2)
	_wl(apex, apex + Vector2(-7, -10), 1.6)
	_wl(apex, apex + Vector2(7, -10), 1.6)
	_wl(Vector2(-30, 23), Vector2(30, 23), 1.0)
	for x in [-34.0, 34.0]:
		_wl(Vector2(x * 0.82, 22), Vector2(x, 26), 1.0)


## Moinho de poste: casinha de tábuas sobre o cavalete e quatro velas de treliça.
func _ic_mill() -> void:
	_wl(Vector2(0, 8), Vector2(-14, 26), 1.6)
	_wl(Vector2(0, 8), Vector2(14, 26), 1.6)
	_wl(Vector2(0, 8), Vector2(0, 26), 1.6)
	_wl(Vector2(-10, 20), Vector2(10, 20), 1.0)
	_ws(PackedVector2Array([Vector2(-11, 10), Vector2(11, 10), Vector2(10, -14), Vector2(-10, -14)]))
	for i in range(1, 6):
		_wl(Vector2(-11 + i * 3.7, 9.5), Vector2(-10 + i * 3.4, -13.5), 0.6)
	_shade(PackedVector2Array([Vector2(4, 9.5), Vector2(10.5, 9.5), Vector2(9.5, -13.5), Vector2(4, -13.5)]))
	_ws(_cat([[Vector2(-13, -13)], _q(Vector2(-13, -13), Vector2(-6, -22), Vector2(0, -25)), _q(Vector2(0, -25), Vector2(6, -22), Vector2(13, -13))]), BG, 1.8)
	var hub := Vector2(-1, -12)
	for i in 4:
		var a := 0.6 + i * PI * 0.5
		var d := Vector2(cos(a), sin(a))
		var n := d.orthogonal() * 4.5
		_wl(hub, hub + d * 30.0, 1.4)
		_wp(PackedVector2Array([hub + d * 9.0, hub + d * 9.0 + n, hub + d * 30.0 + n, hub + d * 30.0]), 1.0, true)
		for j in range(1, 5):
			var p := hub + d * (9.0 + j * 4.2)
			_wl(p, p + n, 0.6)
	ci.draw_circle(hub, 2.2, INK)


## Drakkar: proa com cabeça de dragão, popa enrolada, escudos na borda e vela listrada.
func _ic_boat() -> void:
	var hull := _cat([[Vector2(-30, -2)], _q(Vector2(-30, -2), Vector2(-26, 14), Vector2(-8, 16)), [Vector2(8, 16)], _q(Vector2(8, 16), Vector2(26, 14), Vector2(30, -2)), _q(Vector2(30, -2), Vector2(0, 4), Vector2(-30, -2))])
	_wl(Vector2(0, 2), Vector2(0, -36), 1.8)
	var sail := _cat([[Vector2(-16, -33)], _q(Vector2(-16, -33), Vector2(0, -35), Vector2(16, -33)), _q(Vector2(16, -33), Vector2(19, -20), Vector2(16, -8)), _q(Vector2(16, -8), Vector2(0, -6), Vector2(-16, -8)), _q(Vector2(-16, -8), Vector2(-13, -20), Vector2(-16, -33))])
	_ws(sail)
	for i in [1, 3]:
		var x0: float = -16.0 + i * 6.4
		_shade(PackedVector2Array([Vector2(x0, -33.5), Vector2(x0 + 6.4, -33.8), Vector2(x0 + 6.4, -6.5), Vector2(x0, -6.8)]), "vert")
	_ws(hull, BG, 2.0)
	_wp(_q(Vector2(-27, 6), Vector2(0, 10), Vector2(27, 6)), 0.8)
	_shade(_cat([[Vector2(8, 16)], _q(Vector2(8, 16), Vector2(26, 14), Vector2(30, -2)), [Vector2(16, 6)]]))
	_wp(_q(Vector2(30, -2), Vector2(38, -10), Vector2(33, -22)), 2.0)
	_wp(_q(Vector2(33, -22), Vector2(39, -25), Vector2(41, -21)), 1.6)
	ci.draw_circle(Vector2(35, -21), 1.0, INK)
	_wp(_q(Vector2(-30, -2), Vector2(-39, -8), Vector2(-35, -18)), 2.0)
	ci.draw_arc(Vector2(-32.5, -18), 2.6, PI, TAU * 1.15, 8, INK, 1.6, true)
	for i in 5:
		var p := Vector2(-18 + i * 9, 1.5 + absf(i - 2) * 0.6)
		_ws(Minimap._smooth(Minimap._ell(p, 3.6, 3.6, 8, r, 0.05), true, 2), BG, 1.1)
		ci.draw_circle(p, 0.9, INK)
	for i in 2:
		var y := 21.0 + i * 5.0
		var x0 := -26.0 + i * 8.0
		_wp(_cat([_q(Vector2(x0, y), Vector2(x0 + 5, y - 3), Vector2(x0 + 10, y)), _q(Vector2(x0 + 10, y), Vector2(x0 + 15, y - 3), Vector2(x0 + 20, y))]), 1.0)
		_wp(_cat([_q(Vector2(x0 + 26, y), Vector2(x0 + 31, y - 3), Vector2(x0 + 36, y)), _q(Vector2(x0 + 36, y), Vector2(x0 + 41, y - 3), Vector2(x0 + 46, y))]), 1.0)
