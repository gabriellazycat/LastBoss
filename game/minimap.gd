class_name Minimap
extends Control
## Minimapa: rota inteira, ramos, locais e progresso do herói. Clicável para cartas de rota.

signal world_clicked(pos: Vector2)

var sim: Sim
var bounds := Rect2()


func setup(s: Sim) -> void:
	sim = s
	var r := Rect2(Vector2.ZERO, Vector2.ZERO)
	var first := true
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for p in pts:
				if first:
					r = Rect2(p, Vector2.ZERO)
					first = false
				else:
					r = r.expand(p)
	bounds = r.grow(25.0)
	queue_redraw()


func to_map(p: Vector2) -> Vector2:
	var sc := minf(size.x / bounds.size.x, size.y / bounds.size.y)
	var off := (size - bounds.size * sc) * 0.5
	return off + (p - bounds.position) * sc


func to_world(m: Vector2) -> Vector2:
	var sc := minf(size.x / bounds.size.x, size.y / bounds.size.y)
	var off := (size - bounds.size * sc) * 0.5
	return (m - off) / sc + bounds.position


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and sim:
		world_clicked.emit(to_world(e.position))
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.08, 0.82))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.4, 0.7, 0.8), false, 2.0)
	if sim == null:
		return
	for li in sim.road.legs.size():
		var leg: Dictionary = sim.road.legs[li]
		for b in leg["pts"].size():
			var col := Color(0.75, 0.65, 0.5)
			if leg["kind"] == "fork":
				if leg["closed"] == b:
					col = Color(0.8, 0.2, 0.2)
				elif leg["chosen"] >= 0 and leg["chosen"] != b:
					col = Color(0.3, 0.28, 0.25)
				elif leg["forced"] == b:
					col = Color(0.4, 0.9, 1.0)
			var pts: PackedVector2Array = leg["pts"][b]
			var mp := PackedVector2Array()
			for p in pts:
				mp.append(to_map(p))
			draw_polyline(mp, col, 2.5, true)
	for loc in sim.road.locations:
		var c: Color = WorldView.LOC_COLORS[loc["type"]]
		if loc["state"] != SimRoad.LocState.ACTIVE:
			c = c.darkened(0.6)
		draw_circle(to_map(loc["pos"]), 4.5, c)
	draw_circle(to_map(sim.road.lair), 6.0, Color(0.8, 0.2, 0.9))
	draw_circle(to_map(Vector2(sim.hero.x, sim.hero.y)), 5.0, Color(0.4, 0.7, 1.0))
	draw_arc(to_map(Vector2(sim.hero.x, sim.hero.y)), 8.0, 0, TAU, 24, Color(1, 1, 1, 0.7), 1.5)
