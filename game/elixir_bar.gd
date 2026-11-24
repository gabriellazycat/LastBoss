class_name ElixirBar
extends Control
## Elixir em gomos: um por ponto, o gomo que está enchendo aparece parcial; os gomos que a carta selecionada custa piscam.

var value := 0.0
var max_value := 10.0
var cost := 0          # custo da carta selecionada (0 = nenhuma)
var t := 0.0
var vertical := false  # gomos de baixo para cima, número no alto (variações da HUD de 17/11/2026)
var show_label := true # false: sem o "atual / máximo" (a gota ao lado já mostra o número)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var n := maxi(int(round(max_value)), 1)
	# Mais gomos, vão menor; a direita fica reservada ao número "atual/máximo".
	var gap := 4.0 if n <= 10 else (3.0 if n <= 14 else 2.0)
	var label_w := minf(78.0, size.x * 0.16)
	var w := (size.x - label_w - gap * (n - 1)) / n
	var h := size.y
	var label_h := 30.0
	if vertical:
		label_w = 0.0
		if not show_label:
			label_h = 0.0
		w = size.x
		h = (size.y - label_h - gap * (n - 1)) / n
		if not show_label and n > 12:
			# Máximo alto (relíquias de elixir): duas fileiras lado a lado, para o gomo não virar um ponto.
			var rows := int(ceil(n / 2.0))
			w = (size.x - gap) * 0.5
			h = (size.y - gap * (rows - 1)) / rows
	var font := ThemeDB.fallback_font
	var txt := "%d / %d" % [int(value), n]
	var fs := clampi(int(h * 0.85), 12, 22)
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tp := Vector2(size.x - label_w + (label_w - tw) * 0.5 + 4.0, h * 0.5 + fs * 0.35)
	if vertical:
		fs = 16
		tw = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		tp = Vector2((size.x - tw) * 0.5, 20.0)
	if not show_label:
		pass
	elif vertical:
		var pf := UiParch.font("bold")
		var pw := pf.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs + 2).x
		draw_string(pf, Vector2((size.x - pw) * 0.5, tp.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs + 2, UiParch.ELIXIR_DEEP)
	else:
		# Na bandeja de papel: número a tinta, na letra da interface (13/11/2026).
		var pf := UiParch.font("bold")
		var pw := pf.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs + 2).x
		draw_string(pf, Vector2(size.x - label_w + (label_w - pw) * 0.5 + 4.0, tp.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs + 2, UiParch.ELIXIR_DEEP)
	for i in n:
		var r := Rect2(i * (w + gap), 0, w, h)
		if vertical and not show_label and n > 12:
			# Enche de baixo para cima, alternando esquerda e direita em cada andar.
			var row := i / 2
			r = Rect2((i % 2) * (w + gap), size.y - (row + 1) * h - row * gap, w, h)
		elif vertical:
			r = Rect2(0, size.y - (i + 1) * h - i * gap, w, h)
		var f := clampf(value - i, 0.0, 1.0)
		UiDiario.draw_pip(self, r, f, UiKit.ELIXIR, t)
		if cost > 0 and i >= int(value) - cost and i < int(value):
			draw_arc(r.get_center() + Vector2(0, r.size.y * 0.08), r.size.y * 0.62, 0, TAU, 20, Color(0.6, 0.08, 0.05, 0.45 + 0.35 * sin(t * 6.0)), 2.0, true)
		elif cost > 0 and int(value) < cost and i >= int(value) and i < cost:
			draw_line(r.position + Vector2(2, 2), r.end - Vector2(2, 2), Color(0.6, 0.08, 0.05, 0.85), 2.0, true)
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
