class_name ElixirBar
extends Control
## Elixir em gomos: um por ponto, o gomo que está enchendo aparece parcial; os gomos que a carta selecionada custa piscam.

var value := 0.0
var max_value := 10.0
var cost := 0          # custo da carta selecionada (0 = nenhuma)
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var n := maxi(int(max_value), 1)
	var gap := 4.0
	var w := (size.x - gap * (n - 1)) / n
	var h := size.y
	for i in n:
		var r := Rect2(i * (w + gap), 0, w, h)
		var f := clampf(value - i, 0.0, 1.0)
		if UiSkins.diario():
			UiDiario.draw_pip(self, r, f, UiKit.ELIXIR, t)
			if cost > 0 and i >= int(value) - cost and i < int(value):
				draw_arc(r.get_center() + Vector2(0, r.size.y * 0.08), r.size.y * 0.62, 0, TAU, 20, Color(0.6, 0.08, 0.05, 0.45 + 0.35 * sin(t * 6.0)), 2.0, true)
			elif cost > 0 and int(value) < cost and i >= int(value) and i < cost:
				draw_line(r.position + Vector2(2, 2), r.end - Vector2(2, 2), Color(0.6, 0.08, 0.05, 0.85), 2.0, true)
			continue
		if UiSkins.covil():
			UiCovil.draw_pip(self, r, f, UiKit.ELIXIR, t + i * 0.4)
			if cost > 0 and i >= int(value) - cost and i < int(value):
				draw_rect(r.grow(-1), Color(1, 0.88, 0.6, 0.18 + 0.16 * sin(t * 6.0)))
			elif cost > 0 and int(value) < cost and i >= int(value) and i < cost:
				draw_rect(r.grow(1), Color(1, 0.35, 0.3, 0.75), false, 2.0)
			continue
		if UiSkins.on():
			UiSkins.draw_gem(self, r, f, UiKit.ELIXIR)
			if cost > 0 and i >= int(value) - cost and i < int(value):
				draw_rect(r.grow(-2), Color(1, 0.9, 0.6, 0.2 + 0.2 * sin(t * 8.0)))
			elif cost > 0 and int(value) < cost and i >= int(value) and i < cost:
				draw_rect(r, Color(1, 0.3, 0.3, 0.6), false, 2.0)
			continue
		draw_rect(r, Color(0, 0, 0, 0.62))
		if f > 0.0:
			var col := UiKit.ELIXIR if f >= 1.0 else UiKit.ELIXIR.darkened(0.35)
			draw_rect(Rect2(r.position, Vector2(w * f, h)), col)
			if f >= 1.0:
				draw_rect(Rect2(r.position, Vector2(w, h * 0.35)), Color(1, 1, 1, 0.18))
		# Gomos que a carta selecionada vai gastar.
		if cost > 0 and i >= int(value) - cost and i < int(value):
			draw_rect(r, Color(1, 0.9, 0.6, 0.25 + 0.2 * sin(t * 8.0)))
		elif cost > 0 and int(value) < cost and i >= int(value) and i < cost:
			draw_rect(r, Color(1, 0.3, 0.3, 0.6), false, 2.0)
		draw_rect(r, Color(0.9, 0.6, 1.0, 0.35), false, 1.0)
