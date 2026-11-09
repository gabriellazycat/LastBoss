class_name UpgradeIcon
extends Control
## Medalhão de uma habilidade do herói: símbolo vetorial desenhado em código. Cor do aro pelo papel:
## ataque (vermelho), defesa (azul), utilidade (verde).

const ATTACK := ["sword_spin", "holy_water", "stone_hammer", "hero_fury", "heroic_strike", "purifying_blade"]
const DEFENSE := ["tower_shield", "fireproof", "reflect_shield", "second_wind", "soul_absorb"]
const RING := {"attack": Color(0.95, 0.4, 0.32), "defense": Color(0.4, 0.66, 1.0), "utility": Color(0.45, 0.9, 0.55)}
const INK := Color(0.98, 0.95, 0.88)

var id := ""
var pulse := 0.0                   # > 0: acabou de ganhar (o aro pulsa)


static func make(id_: String, s := 32.0) -> UpgradeIcon:
	var c := UpgradeIcon.new()
	c.id = id_
	c.custom_minimum_size = Vector2(s, s)
	c.size = c.custom_minimum_size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func role(id_: String) -> String:
	if ATTACK.has(id_):
		return "attack"
	if DEFENSE.has(id_):
		return "defense"
	return "utility"


## Parâmetros do texto: os números dos dados, inteiros quando redondos, e `<chave>_pct` em porcentagem.
static func params(u: Dictionary) -> Dictionary:
	var p := {}
	var src: Dictionary = u.get("p", {})
	for k in src:
		var x = src[k]
		p[k] = int(x) if typeof(x) == TYPE_FLOAT and is_equal_approx(x, round(x)) else x
		if typeof(x) == TYPE_FLOAT or typeof(x) == TYPE_INT:
			p[k + "_pct"] = int(round(float(x) * 100.0))
	return p


static func desc(data: GameData, id_: String) -> String:
	return TranslationServer.translate("UPGD_" + id_).format(params(data.upgrades.get(id_, {})))


func _process(delta: float) -> void:
	if pulse > 0.0:
		pulse = maxf(pulse - delta, 0.0)
		queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := Vector2(s, s) * 0.5
	var r := s * 0.5
	var rc: Color = RING[role(id)]
	var glow := 0.5 + 0.5 * sin(pulse * 9.0) if pulse > 0.0 else 0.0
	if glow > 0.0:
		draw_circle(c, r, Color(rc.r, rc.g, rc.b, 0.35 * glow))
	draw_circle(c, r * 0.92, Color(0.07, 0.05, 0.1))
	draw_circle(c, r * 0.8, rc.darkened(0.72))
	draw_arc(c, r * 0.9, 0.0, TAU, 32, rc.lightened(0.25 * glow), maxf(1.5, s * 0.07), true)
	# Símbolo num quadrado unitário centrado: q(x, y) com x, y em [-1, 1].
	var k := r * 0.55
	var q := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * k
	var w := maxf(1.5, s * 0.075)
	match id:
		"sword_spin":
			_sword(q, w, -0.6, 0.6, 0.6, -0.6)
			draw_arc(c, k * 0.95, PI * 0.9, PI * 1.9, 14, INK, w * 0.7, true)
			draw_line(q.call(0.62, -0.85), q.call(0.95, -0.2), INK, w * 0.7, true)
		"tower_shield":
			_shield(q, w, 1.0)
		"dash":
			draw_line(q.call(-0.7, 0.0), q.call(0.75, 0.0), INK, w * 1.2, true)
			draw_colored_polygon(PackedVector2Array([q.call(0.95, 0.0), q.call(0.45, -0.45), q.call(0.45, 0.45)]), INK)
			for yy in [-0.55, 0.55]:
				draw_line(q.call(-0.9, yy), q.call(-0.1, yy), INK, w * 0.6, true)
		"war_cry":
			draw_colored_polygon(PackedVector2Array([q.call(-0.9, -0.3), q.call(-0.4, -0.3), q.call(0.1, -0.75), q.call(0.1, 0.75), q.call(-0.4, 0.3), q.call(-0.9, 0.3)]), INK)
			for rr in [0.45, 0.8]:
				draw_arc(q.call(0.0, 0.0), k * rr + k * 0.2, -0.7, 0.7, 10, INK, w * 0.7, true)
		"fireproof":
			_shield(q, w, 0.95)
			_flame(q, 0.0, 0.05, 0.42, Color(0.07, 0.05, 0.1))
		"holy_water":
			draw_rect(Rect2(q.call(-0.18, -0.95), Vector2(0.36, 0.3) * k), INK)
			draw_colored_polygon(PackedVector2Array([q.call(-0.3, -0.62), q.call(0.3, -0.62), q.call(0.7, 0.1), q.call(0.6, 0.85), q.call(-0.6, 0.85), q.call(-0.7, 0.1)]), INK)
			draw_line(q.call(0.0, -0.1), q.call(0.0, 0.6), rc.darkened(0.6), w, true)
			draw_line(q.call(-0.25, 0.15), q.call(0.25, 0.15), rc.darkened(0.6), w, true)
		"treasure_nose":
			draw_rect(Rect2(q.call(-0.8, -0.1), Vector2(1.6, 0.9) * k), INK)
			draw_arc(q.call(0.0, -0.1), k * 0.8, PI, TAU, 12, INK, w, true)
			draw_rect(Rect2(q.call(-0.15, 0.05), Vector2(0.3, 0.3) * k), rc.darkened(0.6))
			draw_line(q.call(-0.95, -0.95), q.call(0.95, 0.95), Color(1, 0.4, 0.35), w, true)
		"stone_hammer":
			draw_line(q.call(-0.65, 0.85), q.call(0.25, -0.15), INK, w * 1.1, true)
			draw_colored_polygon(PackedVector2Array([q.call(-0.15, -0.75), q.call(0.35, -0.95), q.call(0.95, -0.15), q.call(0.45, 0.05)]), INK)
		"steady_boots":
			draw_colored_polygon(PackedVector2Array([q.call(-0.55, -0.9), q.call(0.1, -0.9), q.call(0.1, 0.25), q.call(0.9, 0.45), q.call(0.9, 0.85), q.call(-0.55, 0.85)]), INK)
			draw_line(q.call(-0.75, 0.95), q.call(0.95, 0.95), INK, w, true)
		"purifying_blade":
			_sword(q, w, -0.7, 0.7, 0.5, -0.5)
			_star(q.call(0.55, -0.55), k * 0.42, INK)
		"reflect_shield":
			draw_circle(q.call(-0.15, 0.0), k * 0.75, INK)
			draw_circle(q.call(-0.15, 0.0), k * 0.4, rc.darkened(0.6))
			draw_line(q.call(0.95, -0.85), q.call(0.45, -0.25), INK, w * 0.8, true)
			draw_line(q.call(0.45, -0.25), q.call(0.95, 0.35), INK, w * 0.8, true)
		"hero_fury":
			draw_colored_polygon(PackedVector2Array([q.call(0.15, -0.95), q.call(-0.55, 0.1), q.call(-0.05, 0.1), q.call(-0.2, 0.95), q.call(0.55, -0.15), q.call(0.05, -0.15)]), INK)
		"soul_absorb":
			_heart(q, 0.0, 0.25, 0.55, INK)
			for a in [-2.4, -1.57, -0.74]:
				var d := Vector2(cos(a), sin(a))
				draw_line(c + d * k * 0.95, c + d * k * 0.55, INK, w * 0.6, true)
		"second_wind":
			_heart(q, 0.0, 0.1, 0.85, INK)
			var dk := rc.darkened(0.6)
			draw_line(q.call(0.0, -0.25), q.call(0.0, 0.35), dk, w, true)
			draw_line(q.call(-0.3, 0.05), q.call(0.3, 0.05), dk, w, true)
		"heroic_strike":
			_sword(q, w, -0.75, 0.75, 0.35, -0.35)
			_star(q.call(0.55, -0.55), k * 0.55, Color(1.0, 0.85, 0.4))
		_:
			draw_circle(c, k * 0.3, INK)


func _sword(q: Callable, w: float, x0: float, y0: float, x1: float, y1: float) -> void:
	draw_line(q.call(x0, y0), q.call(x1, y1), INK, w * 1.2, true)
	var mx := x0 + (x1 - x0) * 0.22
	var my := y0 + (y1 - y0) * 0.22
	draw_line(q.call(mx - 0.3, my - 0.3), q.call(mx + 0.3, my + 0.3), INK, w, true)


func _shield(q: Callable, _w: float, sc: float) -> void:
	draw_colored_polygon(PackedVector2Array([q.call(-0.75 * sc, -0.85 * sc), q.call(0.75 * sc, -0.85 * sc), q.call(0.75 * sc, 0.1 * sc),
		q.call(0.0, 0.95 * sc), q.call(-0.75 * sc, 0.1 * sc)]), INK)


func _flame(q: Callable, x: float, y: float, s: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([q.call(x, y - s * 1.6), q.call(x + s * 0.9, y + s * 0.2), q.call(x + s * 0.5, y + s),
		q.call(x - s * 0.5, y + s), q.call(x - s * 0.9, y + s * 0.2)]), col)


func _heart(q: Callable, x: float, y: float, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		var hx := 16.0 * pow(sin(t), 3)
		var hy := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(q.call(x + hx / 17.0 * s, y + hy / 17.0 * s))
	draw_colored_polygon(pts, col)


func _star(p: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI * 0.5
		pts.append(p + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.35))
	draw_colored_polygon(pts, col)
