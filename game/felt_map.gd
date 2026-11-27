class_name FeltMap
extends RefCounted
## Fundos de mapa em feltro (26/11/2026): o menu principal (MapMenu) e a feira do mascate (ShopLedger) desenham o
## fundo uma vez numa SubViewport, com os traços do mapa da rota (Minimap: árvores, montanhas, rio, rosa dos
## ventos) e o shader dos retalhos costurados (map_cloth.gdshader) por cima, recortado com cantos redondos.

const RADIUS := 26.0

## Cria a SubViewport como filha de `host` e devolve a textura. `painter(ci, mm)` desenha o mapa; o retalho
## grande fica em `paper` (coordenadas da textura de tamanho `size`). O Minimap auxiliar fica fora da árvore e
## é liberado quando o host sai da árvore.
static func make(host: Node, size: Vector2, paper: Rect2, painter: Callable) -> Texture2D:
	var mm := Minimap.new()
	mm.fell = UiDiario.font("fell")
	mm.fell_it = UiDiario.font("fell_it")
	host.tree_exiting.connect(func(): if is_instance_valid(mm): mm.free())
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(size)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var cv := Node2D.new()
	cv.draw.connect(func(): painter.call(cv, mm))
	vp.add_child(cv)
	var post := ColorRect.new()
	var sm := ShaderMaterial.new()
	sm.shader = load("res://game/art/map_cloth.gdshader")
	sm.set_shader_parameter("land", Minimap.BG)
	sm.set_shader_parameter("thread", Minimap.PAPER)
	sm.set_shader_parameter("cell", 230.0)
	sm.set_shader_parameter("rect_size", paper.size)
	sm.set_shader_parameter("radius", RADIUS)
	post.material = sm
	post.position = paper.position
	post.size = paper.size
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.add_child(post)
	host.add_child(vp)
	return vp.get_texture()


## Sombra na mesa e o retalho grande de feltro, de cantos redondos.
static func base(ci: CanvasItem, paper: Rect2) -> void:
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0.02, 0.03, 0.08, 0.45)
	sh.set_corner_radius_all(int(RADIUS) + 4)
	sh.shadow_color = Color(0.02, 0.03, 0.08, 0.35)
	sh.shadow_size = 14
	ci.draw_style_box(sh, Rect2(paper.position + Vector2(4, 8), paper.size))
	var bs := StyleBoxFlat.new()
	bs.bg_color = Minimap.BG
	bs.set_corner_radius_all(int(RADIUS))
	ci.draw_style_box(bs, paper)


## Costura creme em volta do retalho grande (por último, por cima de tudo).
static func rim(ci: CanvasItem, mm: Minimap, paper: Rect2) -> void:
	var e := paper.grow(-14.0)
	var pts := PackedVector2Array([e.position, Vector2(e.end.x, e.position.y), e.end, Vector2(e.position.x, e.end.y), e.position])
	mm._dashed(ci, Minimap._offs(Vector2(0, 1.5), Array(pts)), Color(0, 0, 0, 0.3), 3.0, 14.0, 9.0, 0.0)
	mm._dashed(ci, pts, Minimap.PAPER, 3.0, 14.0, 9.0, 0.0)


## Trilha de areia com pesponto pelos pontos `pts` (linha `thread`: creme, ou vermelha para a rota).
static func trail(ci: CanvasItem, mm: Minimap, pts: PackedVector2Array, thread := Minimap.PAPER, w := 16.0) -> void:
	ci.draw_polyline(pts, Color("c9a46a"), w, true)
	ci.draw_polyline(pts, Color("b08a55"), 2.0, true)
	mm._dashed(ci, pts, thread, 2.4 if thread == Minimap.PAPER else 4.0, 10.0 if thread == Minimap.PAPER else 12.0, 8.0, 0.0)


## Faixa de título: pontas ocre e placa creme costurada, centrada em c, com a placa de `w` x `h`.
static func banner(ci: CanvasItem, mm: Minimap, c: Vector2, w: float, h: float) -> void:
	var hw := w * 0.5 + 30.0
	var bh := h * 0.32
	var band := PackedVector2Array([c + Vector2(-hw, -bh), c + Vector2(hw, -bh), c + Vector2(hw, -bh + 10), c + Vector2(hw + 42, -bh + 10),
		c + Vector2(hw + 22, bh * 0.2 + 14), c + Vector2(hw + 42, bh + 38), c + Vector2(hw, bh + 38), c + Vector2(hw, bh + 48),
		c + Vector2(-hw, bh + 48), c + Vector2(-hw, bh + 38), c + Vector2(-hw - 42, bh + 38), c + Vector2(-hw - 22, bh * 0.2 + 14),
		c + Vector2(-hw - 42, -bh + 10), c + Vector2(-hw, -bh + 10)])
	ci.draw_colored_polygon(band, Color("c9a46a"))
	var plate := StyleBoxFlat.new()
	plate.bg_color = Minimap.PAPER
	plate.set_corner_radius_all(14)
	plate.shadow_color = Color(0.05, 0.07, 0.12, 0.25)
	plate.shadow_size = 6
	plate.shadow_offset = Vector2(0, 3)
	var pr := Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h))
	ci.draw_style_box(plate, pr)
	var q := pr.grow(-9.0)
	mm._dashed(ci, PackedVector2Array([q.position, Vector2(q.end.x, q.position.y), q.end, Vector2(q.position.x, q.end.y), q.position]), Color("8a6a50"), 2.2, 9.0, 7.0, 0.0)


## Bosque de n árvores em volta de c.
static func grove(ci: CanvasItem, mm: Minimap, r: RandomNumberGenerator, c: Vector2, n: int, spread := Vector2(70, 40)) -> void:
	for i in n:
		var p := c + Vector2(r.randf_range(-spread.x, spread.x), r.randf_range(-spread.y, spread.y))
		mm._tree(ci, ["d", "r", "p", "f"][r.randi() % 4], p, r.randf_range(1.6, 2.1), r)
