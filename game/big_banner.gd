class_name BigBanner
extends Control
## Letreiro grande no meio da tela (rodada 09/11/2026, "impacto"): objetivo do local ao chegar ("CAUSE 400 DE
## DANO"), resultado da disputa, início de ato. Entra batendo (escala 2,4 → 1 com quique, tremor de câmera e som
## no impacto), segura e encolhe voando até `dock` (o painel da disputa no topo vira o lembrete). Não pausa o jogo
## e não pega o mouse.

const IN := 0.2
const HOLD := 1.05
const OUT := 0.55

## Chamado no impacto (força 0..1): a cena liga tremor de câmera e som.
var on_slam: Callable
var t := -1.0
var dock := Vector2(-1, -1)
var col := Color.WHITE
var box: VBoxContainer
var title: Label
var sub: Label
var slammed := false
var strength := 1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title = UiKit.title(78, UiKit.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	title.add_theme_constant_override("outline_size", 14)
	sub = UiKit.label(24, Color(1, 0.95, 0.85), 6)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(sub)
	add_child(box)
	visible = false


## Mostra o letreiro (substitui o que estiver na tela). `dock` < 0: some no lugar em vez de voar.
func show_banner(head: String, line := "", color := UiKit.GOLD, to := Vector2(-1, -1), power := 1.0) -> void:
	title.text = head.to_upper()
	sub.text = line
	sub.visible = line != ""
	col = color
	title.add_theme_color_override("font_color", color)
	dock = to
	strength = power
	t = 0.0
	slammed = false
	visible = true
	box.reset_size()


func _process(delta: float) -> void:
	if t < 0.0:
		return
	t += delta
	var vs := get_viewport_rect().size
	var bs := box.get_combined_minimum_size()
	box.size = bs
	box.pivot_offset = bs * 0.5
	var center := Vector2(vs.x * 0.5, vs.y * 0.36)
	var pos := center
	var s := 1.0
	var a := 1.0
	if t < IN:
		var k := t / IN
		s = lerpf(2.4, 1.0, _back(k))
		a = k
	elif t < IN + HOLD:
		if not slammed:
			slammed = true
			if on_slam.is_valid():
				on_slam.call(strength)
		var k := (t - IN) / HOLD
		# Tranco do impacto que assenta, depois respira de leve.
		s = 1.0 + 0.08 * exp(-k * 9.0) * cos(k * 40.0) + 0.012 * sin(t * 5.0)
	elif t < IN + HOLD + OUT:
		var k := (t - IN - HOLD) / OUT
		var e := k * k
		if dock.x >= 0.0:
			pos = center.lerp(dock, e)
			s = lerpf(1.0, 0.3, e)
		else:
			s = lerpf(1.0, 0.85, e)
		a = 1.0 - e
	else:
		t = -1.0
		visible = false
		return
	box.position = pos - bs * 0.5
	box.scale = Vector2.ONE * s
	box.modulate.a = a
	queue_redraw()


func _draw() -> void:
	if t < 0.0 or t >= IN + HOLD:
		return
	# Faixa escura atrás do texto, atravessando a tela, que abre no impacto.
	var vs := get_viewport_rect().size
	var k := clampf(t / IN, 0.0, 1.0)
	var h := box.get_combined_minimum_size().y * 1.15 * k
	var y := vs.y * 0.36
	draw_rect(Rect2(0, y - h * 0.5, vs.x, h), Color(0.04, 0.02, 0.03, 0.55 * k))
	draw_rect(Rect2(0, y - h * 0.5, vs.x, 3), Color(col.r, col.g, col.b, 0.8 * k))
	draw_rect(Rect2(0, y + h * 0.5 - 3, vs.x, 3), Color(col.r, col.g, col.b, 0.8 * k))


static func _back(k: float) -> float:
	var c := 1.9
	return 1.0 + (c + 1.0) * pow(k - 1.0, 3.0) + c * pow(k - 1.0, 2.0)
