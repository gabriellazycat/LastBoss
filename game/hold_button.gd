class_name HoldButton
extends Button
## Botão de segurar: um anel de progresso enche enquanto o mouse (ou Enter/Espaço/A do controle com o foco aqui)
## fica pressionado; ao completar `hold_time` s, emite `held` uma vez. Soltar antes cancela.
## Evita apertar "Nova run" ou "Menu" sem querer logo depois de um clique na tela de vitória.

signal held

@export var hold_time := 1.0
var progress := 0.0
var _mouse_down := false
var _fired := false


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	set_process(true)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_mouse_down = e.pressed
		if not e.pressed:
			_cancel()
		accept_event()


func _holding() -> bool:
	if disabled or not is_visible_in_tree():
		return false
	if _mouse_down and get_global_rect().has_point(get_global_mouse_position()):
		return true
	if has_focus():
		for a in ["ui_accept", "pad_confirm"]:
			if InputMap.has_action(a) and Input.is_action_pressed(a):
				return true
	return false


func _cancel() -> void:
	progress = 0.0
	_fired = false
	queue_redraw()


func _process(dt: float) -> void:
	if _holding():
		if not _fired:
			progress = minf(1.0, progress + dt / hold_time)
			if progress >= 1.0:
				_fired = true
				_mouse_down = false
				held.emit()
		queue_redraw()
	elif progress > 0.0 or _fired:
		_cancel()


func _draw() -> void:
	if progress <= 0.0:
		return
	var c := Vector2(size.x - 26.0, size.y * 0.5)
	draw_arc(c, 13.0, 0.0, TAU, 32, Color(0, 0, 0, 0.35), 4.0, true)
	draw_arc(c, 13.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Color(1.0, 0.85, 0.35), 4.0, true)
	draw_rect(Rect2(0, size.y - 4.0, size.x * progress, 4.0), Color(1.0, 0.85, 0.35, 0.8))
