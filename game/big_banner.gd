class_name BigBanner
extends Control
## Letreiro grande no meio da tela (rodada 09/11/2026, "impacto"): objetivo do local ao chegar ("CAUSE 400 DE
## DANO"), resultado da disputa, início de ato. Entra batendo (escala 2,4 → 1 com quique, tremor de câmera e som
## no impacto), segura e encolhe voando até `dock` (o painel da disputa no topo vira o lembrete). Não pausa o jogo
## e não pega o mouse.
## Peles de papel (Diário e Mapa aberto, 16/11/2026): faixa de papel com fio duplo de tinta e letras de tinta; as cores
## de quem chama viram tinta (ver `ink`). A pele Covil fica com a faixa escura.

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
var paper := false


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
	paper = UiSkins.diario() or UiSkins.mapa()
	if paper:
		title.add_theme_color_override("font_outline_color", UiParch.PARCH)
		title.add_theme_constant_override("outline_size", 10)
		sub.add_theme_color_override("font_color", UiParch.INK_SOFT)
		sub.add_theme_color_override("font_outline_color", UiParch.PARCH)
		sub.add_theme_constant_override("outline_size", 6)
		if UiSkins.title_font():
			title.add_theme_font_override("font", UiSkins.title_font())


## Mostra o letreiro (substitui o que estiver na tela). `dock` < 0: some no lugar em vez de voar.
func show_banner(head: String, line := "", color := UiKit.GOLD, to := Vector2(-1, -1), power := 1.0) -> void:
	title.text = head.to_upper()
	sub.text = line
	sub.visible = line != ""
	col = ink(color) if paper else color
	title.add_theme_color_override("font_color", col)
	dock = to
	strength = power
	t = 0.0
	slammed = false
	visible = true
	box.reset_size()


func _process(delta: float) -> void:
	if t < 0.0:
		return
	# Tempo real: nas cenas em câmera lenta (queda, fim de disputa) o letreiro não se arrasta.
	t += delta / maxf(Engine.time_scale, 0.01)
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
	if paper:
		# Faixa de papel com fio duplo de tinta em cima e embaixo (como as molduras do mapa).
		var ink_c := Color(UiParch.INK, 0.9 * k)
		draw_rect(Rect2(0, y - h * 0.5, vs.x, h), Color(UiParch.PARCH, 0.93 * k))
		for e in [y - h * 0.5, y + h * 0.5]:
			draw_rect(Rect2(0, e - 1.5, vs.x, 3), ink_c)
		draw_rect(Rect2(0, y - h * 0.5 + 6, vs.x, 1.5), Color(col, 0.75 * k))
		draw_rect(Rect2(0, y + h * 0.5 - 7.5, vs.x, 1.5), Color(col, 0.75 * k))
		return
	draw_rect(Rect2(0, y - h * 0.5, vs.x, h), Color(0.04, 0.02, 0.03, 0.55 * k))
	draw_rect(Rect2(0, y - h * 0.5, vs.x, 3), Color(col.r, col.g, col.b, 0.8 * k))
	draw_rect(Rect2(0, y + h * 0.5 - 3, vs.x, 3), Color(col.r, col.g, col.b, 0.8 * k))


## Cor de quem chama → tinta (peles de papel): verde (marco, vitória) vira tinta verde, vermelho (disputa perdida)
## vira tinta preta, e o resto (ouro dos objetivos e dos atos) vira a tinta vermelha dos títulos.
static func ink(c: Color) -> Color:
	if c.g > c.r + 0.15 and c.g > c.b:
		return UiParch.GOOD
	if c.r > 0.85 and c.g < 0.6:
		return UiParch.INK
	return UiParch.BLOOD


static func _back(k: float) -> float:
	var c := 1.9
	return 1.0 + (c + 1.0) * pow(k - 1.0, 3.0) + c * pow(k - 1.0, 2.0)
