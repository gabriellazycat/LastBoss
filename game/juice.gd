class_name Juice
extends RefCounted
## Impacto da interface (rodada 09/11/2026, "recompensas estilo Vampire Survivors"): cartas que entram voando e
## batem na mesa, faíscas, raios de luz girando atrás da oferta, título que bate. Tudo só visual.
## Peles de papel (16/11/2026): as faíscas viram respingos de tinta (sem clarear até o branco) e o clarão vira um
## anel de tinta; os raios ficam no ouro claro do papel.


static func paper() -> bool:
	return true


## A carta entra girando de longe, cresce além do tamanho e assenta; `special` (carta upada) ganha um clarão.
## `on_land` é chamado no impacto (som, faíscas).
static func card_in(c: Control, delay: float, special: bool, on_land: Callable) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(0.25, 0.25)
	c.rotation = randf_range(-0.5, 0.5)
	var tw := c.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): c.pivot_offset = c.size * 0.5)
	tw.set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, 0.12)
	tw.tween_property(c, "scale", Vector2(1.14, 1.14), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_callback(func(): if on_land.is_valid(): on_land.call())
	tw.tween_property(c, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if special:
		# Clarão: a carta estoura de luz e volta (o visual do upgrade "pinta" por cima).
		tw.tween_property(c, "modulate", Color(2.2, 2.0, 1.4, 1.0), 0.08)
		tw.tween_property(c, "modulate", Color(1, 1, 1, 1), 0.35)


## O título bate: entra grande e assenta com tranco.
static func slam(l: Control, delay := 0.0) -> void:
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func():
		l.pivot_offset = l.size * 0.5
		l.scale = Vector2(2.2, 2.2))
	tw.set_parallel(true)
	tw.tween_property(l, "modulate:a", 1.0, 0.1)
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Faíscas que explodem de um ponto (coordenadas do `parent`) e somem. Os Burst são reaproveitados (pool): nada de um
## Control novo por chamada.
static var _pool: Array = []
const POOL_MAX := 12


static func burst(parent: Control, at: Vector2, col: Color, n := 18, power := 1.0) -> void:
	var b: Burst = null
	for i in range(_pool.size() - 1, -1, -1):
		var c = _pool[i]
		if not is_instance_valid(c) or (c as Node).is_queued_for_deletion():
			_pool.remove_at(i)   # o pai foi liberado junto
		elif not c.active and b == null:
			b = c
	if b == null:
		b = Burst.new()
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _pool.size() < POOL_MAX:
			_pool.append(b)
		else:
			b.pooled = false
	b.ink = paper()
	b.col = col.lerp(UiParch.INK, 0.35) if b.ink else col
	b.power = power
	b.position = at
	b.t = 0.0
	b.parts.clear()
	for i in n:
		var a := randf() * TAU
		var sp := randf_range(160.0, 420.0) * power
		b.parts.append([Vector2.ZERO, Vector2(cos(a), sin(a)) * sp, randf_range(2.0, 5.0) * power])
	if b.get_parent() != parent:
		if b.get_parent() != null:
			b.get_parent().remove_child(b)
		parent.add_child(b)
	b.start()


class Burst extends Control:
	var parts: Array = []
	var col := Color.WHITE
	var power := 1.0
	var t := 0.0
	var ink := false
	var active := false
	var pooled := true
	const LIFE := 0.7

	func start() -> void:
		active = true
		visible = true
		set_process(true)
		queue_redraw()

	func _process(delta: float) -> void:
		t += delta
		if t >= LIFE:
			active = false
			if pooled:
				visible = false
				set_process(false)
			else:
				queue_free()
			return
		for p in parts:
			p[0] += p[1] * delta
			p[1] *= 1.0 - delta * 3.5
			p[1].y += 380.0 * delta
		queue_redraw()

	func _draw() -> void:
		var k := t / LIFE
		for p in parts:
			var c := col if ink else col.lerp(Color.WHITE, 0.4 * (1.0 - k))
			c.a = 1.0 - k
			draw_circle(p[0], p[2] * (1.0 - k * 0.6), c)
		if k < 0.25:
			if ink:
				draw_arc(Vector2.ZERO, 60.0 * power * k / 0.25, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.7 * (1.0 - k / 0.25)), 3.0, true)
			else:
				draw_circle(Vector2.ZERO, 60.0 * power * k / 0.25, Color(col.r, col.g, col.b, 0.35 * (1.0 - k / 0.25)))


## Raios de luz girando atrás da oferta (como o baú do Vampire Survivors). Fica atrás das cartas.
class Rays extends Control:
	var col := Color(1.0, 0.85, 0.4)
	var t := 0.0
	var power := 0.0     # sobe ao abrir e assenta num brilho fraco

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if Juice.paper():
			col = UiParch.GOLD_LIGHT

	func kick() -> void:
		power = 1.0

	func _process(delta: float) -> void:
		t += delta
		power = lerpf(power, 0.35, clampf(delta * 1.5, 0.0, 1.0))
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := maxf(size.x, size.y) * 0.75
		var n := 14
		for i in n:
			var a := t * 0.25 + TAU * i / n
			var w := 0.09
			var pts := PackedVector2Array([c, c + Vector2(cos(a - w), sin(a - w)) * r, c + Vector2(cos(a + w), sin(a + w)) * r])
			var cs := PackedColorArray([Color(col.r, col.g, col.b, 0.22 * power), Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, 0.0)])
			draw_polygon(pts, cs)
		draw_circle(c, r * 0.18, Color(col.r, col.g, col.b, 0.12 * power))
