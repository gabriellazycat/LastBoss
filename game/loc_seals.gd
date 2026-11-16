class_name LocSeals
extends Control
## Selos dos marcos na cena do fim da disputa (15/11/2026): abaixo do letreiro "Vitória!" / "2 de 3 marcos" /
## "Falhou!", um selo por marco acende de cada vez (ouro = ganho, apagado = perdido) e a linha de baixo diz o
## que vem: quantas recompensas, a relíquia da caveira, ou nada. Responde "ganhei?" e "quanto?" antes da
## escolha abrir. Lê o estado de WorldView.scene a cada quadro (main.gd); não pega o mouse.

const FIRST := 0.35      # s (reais) até o primeiro selo
const STEP := 0.3        # entre um selo e o próximo
const R := 30.0
const LIT := Color(1.0, 0.8, 0.32)       # selo ganho (cor fixa: a pele Diário troca o UiKit.GOLD por tinta)
const LOST := Color(0.85, 0.25, 0.2)
const OK := Color(0.55, 1.0, 0.55)

var scene: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_scene(s: Dictionary) -> void:
	var on := not s.is_empty() and int(s["tier"]) >= 0
	visible = on
	if on:
		scene = s
		queue_redraw()


func _seal_count() -> int:
	return int(scene["marks"]) + (1 if bool(scene["hard"]) else 0)


func _draw() -> void:
	if scene.is_empty():
		return
	var vs := get_viewport_rect().size
	var u := clampf(vs.y / 1080.0, 0.6, 2.0)
	var t := float(scene["t"])
	var n := _seal_count()
	var won_n := int(scene["won_n"])
	var tier := int(scene["tier"])
	var gap := 84.0 * u
	var cy := vs.y * 0.36 + 120.0 * u
	var x0 := vs.x * 0.5 - gap * (n - 1) * 0.5
	var font := UiKit.title_font()
	var a := clampf(t / 0.2, 0.0, 1.0) * clampf((float(scene["dur"]) - t) / 0.3, 0.0, 1.0)
	for i in n:
		var c := Vector2(x0 + gap * i, cy)
		var skull := bool(scene["hard"]) and i == n - 1
		var lit := (won_n >= 3 if skull else i < won_n)
		var t_on := FIRST + STEP * i
		var k := clampf((t - t_on) / 0.18, 0.0, 1.0)
		var rr := R * u
		if lit and k > 0.0:
			rr *= 1.0 + 0.45 * sin(k * PI)   # estala ao acender
		var fill := Color(0.12, 0.09, 0.07, 0.85 * a)
		var ring := Color(0.55, 0.45, 0.35, a)
		if lit and k > 0.0:
			fill = (Color(0.95, 0.85, 0.75) if skull else LIT).lerp(Color.WHITE, 0.35 * (1.0 - k))
			fill.a = a
			ring = Color(0.3, 0.16, 0.04, a)
		elif not lit and t >= t_on:
			ring = Color(LOST, a * 0.9)
		draw_circle(c + Vector2(3, 5) * u, rr, Color(0, 0, 0, 0.35 * a))
		draw_circle(c, rr, fill)
		draw_arc(c, rr, 0.0, TAU, 40, ring, 4.0 * u, true)
		var glyph := "☠" if skull else str(i + 1)
		if not skull and int(scene["marks"]) == 1:
			glyph = "★"
		var gc := Color(0.25, 0.13, 0.03, a) if lit and k > 0.0 else Color(0.75, 0.68, 0.6, a * 0.8)
		var fs := int(30 * u)
		var gw := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(font, c + Vector2(-gw * 0.5, fs * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, gc)
		if not lit and t >= t_on:
			# Marco perdido: um risco por cima.
			draw_line(c + Vector2(-rr, rr) * 0.6, c + Vector2(rr, -rr) * 0.6, Color(LOST, a), 4.0 * u, true)
	# O que vem depois, quando o último selo já acendeu.
	var t_txt := FIRST + STEP * n
	if t < t_txt:
		return
	var line := tr("UI_SCENE_NONE")
	if str(scene["type"]) == "helper":
		line = tr("UI_SCENE_RELIC") if tier == 2 else tr("UI_SCENE_NONE")
	elif won_n > 0:
		line = tr("UI_SCENE_REWARDS").format({"n": won_n})
		if bool(scene["hard"]) and won_n >= 3:
			line += "  ·  " + tr("UI_SCENE_RELIC")
	var b := clampf((t - t_txt) / 0.25, 0.0, 1.0) * a
	var fs2 := int(26 * u)
	var lw := font.get_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, -1, fs2).x
	var lp := Vector2(vs.x * 0.5 - lw * 0.5, cy + R * u + 52.0 * u)
	for o in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		draw_string(font, lp + o * u, line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(0.05, 0.03, 0.02, b))
	draw_string(font, lp, line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(OK if won_n > 0 or tier == 2 else LOST, b))
	if float(scene["t"]) >= 1.0:
		var hint := tr("UI_SCENE_SKIP")
		var fs3 := int(17 * u)
		var hw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_CENTER, -1, fs3).x
		draw_string(font, Vector2(vs.x * 0.5 - hw * 0.5, lp.y + 40.0 * u), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs3, Color(1, 1, 1, 0.55 * b))
