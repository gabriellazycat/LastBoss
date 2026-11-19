class_name CardFxV
extends RefCounted
## Três propostas visuais para os upgrades de carta (Settings `card_fx_variant` 1..3; a 0 é o CardFx de hoje).
## Regra comum: o NÍVEL e o MODIFICADOR usam canais diferentes, para a combinação continuar legível.
##  1 "Encadernação":  nível = lombada e cantos de couro (N2) / cantoneiras de ouro + fita marcadora (N3);
##                     modificador = lacre de cera grande e colorido com símbolo em relevo.
##  2 "Tinta viva":    nível = moldura de nanquim (N2) / iluminura de ouro com folhas e rosetas (N3);
##                     modificador = mancha de tinta da cor dele ao redor do custo, escorrendo, e vinheta no pé.
##  3 "Carimbos e condecorações": nível = medalhas penduradas no pé (N2 uma de prata, N3 prata e ouro);
##                     modificador = carimbo grande em diagonal, na cor dele, com o nome.
##  4 "Carimbo + material": o NÍVEL e o modificador (no N1) trocam o material do fundo no shader (paper.gdshader,
##                     mat_id: N2 ferro rebitado, N3 ouro com brilho; Sombrio obsidiana, Amaldiçoado pedra rachada,
##                     Explosivo ferro em brasa, Barato madeira, Veterano aço gravado). Nível e modificador com
##                     materiais diferentes: o nível manda e o modificador fica só com o carimbo da 3, sem medalhas.
## Tudo é desenhado no _draw do CardFx (`n`), sem tocar no papel da carta.

const INK := Color(0.1, 0.08, 0.07)
const CREAM := Color(0.95, 0.9, 0.8)
const GOLD := Color(0.98, 0.76, 0.27)
const GOLD_D := Color(0.55, 0.34, 0.08)
const GOLD_L := Color(1.0, 0.95, 0.65)
const LEATHER := Color(0.55, 0.3, 0.13)
const LEATHER_D := Color(0.2, 0.1, 0.05)
const WINE := Color(0.46, 0.09, 0.13)
const SILVER := Color(0.82, 0.86, 0.91)
const SILVER_D := Color(0.4, 0.45, 0.52)
## Cera / tinta / carimbo de cada modificador (mais saturados que o MOD_COLOR dos selos antigos).
const MOD := {
	"cheap": Color(0.04, 0.6, 0.64),
	"veteran": Color(0.18, 0.4, 0.82),
	"explosive": Color(0.95, 0.4, 0.06),
	"cursed": Color(0.55, 0.14, 0.74),
	"shadowy": Color(0.15, 0.14, 0.2),
	"leech": Color(0.75, 0.06, 0.16),
}


static func draw(n: CardFx, r: Rect2, mo: float) -> void:
	match CardFx.variant():
		1: _v1(n, r, mo)
		2: _v2(n, r, mo)
		3: _v3(n, r, mo)
		4: _v4(n, r, mo)


# ---------------------------------------------------------------- utilidades

static func rn(i: float, s := 0.0) -> float:
	return fposmod(sin(i * 12.9898 + s * 78.233) * 43758.5453, 1.0)


static func _dk(c: Color, f: float) -> Color:
	return Color(c.r * f, c.g * f, c.b * f, c.a)


static func _lt(c: Color, f: float) -> Color:
	return c.lerp(Color.WHITE, f)


static func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


static func _blob(c: Vector2, rad: float, pts: int, wob: float, sd: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts:
		var a := TAU * i / pts
		out.append(c + Vector2(cos(a), sin(a)) * rad * (1.0 + wob * (rn(i, sd) - 0.5) * 2.0))
	return out


static func _bez(a: Vector2, b: Vector2, c: Vector2, steps := 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		out.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
	return out


static func _star(n: CardFx, c: Vector2, s: float, col: Color) -> void:
	n.draw_line(c - Vector2(s, 0), c + Vector2(s, 0), col, maxf(1.0, s * 0.18), true)
	n.draw_line(c - Vector2(0, s), c + Vector2(0, s), col, maxf(1.0, s * 0.18), true)
	n.draw_line(c - Vector2(s, s) * 0.5, c + Vector2(s, s) * 0.5, _a(col, col.a * 0.6), 1.0, true)
	n.draw_line(c - Vector2(s, -s) * 0.5, c + Vector2(s, -s) * 0.5, _a(col, col.a * 0.6), 1.0, true)


## Retângulo "à mão": polilinha fechada com tremido.
static func _wobble_rect(n: CardFx, rc: Rect2, col: Color, w: float, sd: float, amp: float) -> void:
	var pts := PackedVector2Array()
	var step := 7.0 * n.k
	var corners := [rc.position, Vector2(rc.end.x, rc.position.y), rc.end, Vector2(rc.position.x, rc.end.y)]
	var j := 0
	for e in 4:
		var a: Vector2 = corners[e]
		var b: Vector2 = corners[(e + 1) % 4]
		var cnt := maxi(2, int(a.distance_to(b) / step))
		var nrm := (b - a).orthogonal().normalized()
		for i in cnt:
			j += 1
			pts.append(a.lerp(b, float(i) / cnt) + nrm * (rn(j, sd) - 0.5) * 2.0 * amp)
	pts.append(pts[0])
	n.draw_polyline(pts, col, w, true)


## Centro e raio da gema de custo em coordenadas da camada.
static func _gem(n: CardFx, r: Rect2) -> Array:
	if n.gem and is_instance_valid(n.gem) and n.gem.size.x > 1.0:
		var gt := n.gem.get_global_transform()
		var c: Vector2 = n.get_global_transform().affine_inverse() * (gt * (n.gem.size * 0.5))
		var sc := gt.get_scale().x / maxf(0.001, n.get_global_transform().get_scale().x)
		return [c, n.gem.size.x * 0.5 * sc]
	return [Vector2(r.end.x - 14.0 * n.k, r.position.y + 14.0 * n.k), 11.0 * n.k]


# ---------------------------------------------------------------- V1 Encadernação

static func _v1(n: CardFx, r: Rect2, mo: float) -> void:
	var k := n.k
	if n.level >= 3:
		_bookmark(n, r, mo)
	if n.level >= 2:
		_spine(n, r, n.level >= 3)
		for c in 4:
			_corner(n, r, c, n.level >= 3, mo)
	var rad := 12.5 * k
	for i in n.mids.size():
		var c := Vector2(r.end.x - rad * 0.75 - i * rad * 1.5, r.end.y - rad * 0.05 - (3.0 * k if i % 2 == 1 else 0.0))
		_wax_seal(n, c, rad, n.mids[i], mo, i)


static func _spine(n: CardFx, r: Rect2, gold: bool) -> void:
	var k := n.k
	var w := 6.0 * k
	var base := WINE if gold else LEATHER
	var rc := Rect2(r.position, Vector2(w, r.size.y))
	n.draw_rect(rc, _dk(base, 0.55))
	n.draw_rect(Rect2(rc.position, Vector2(w * 0.78, rc.size.y)), base)
	n.draw_rect(Rect2(rc.position + Vector2(w * 0.12, 0), Vector2(w * 0.14, rc.size.y)), _a(Color.WHITE, 0.16))
	for f in [0.2, 0.5, 0.8]:   # nervuras da lombada
		var y: float = r.position.y + r.size.y * f
		var col := GOLD if gold else LEATHER_D
		n.draw_rect(Rect2(Vector2(r.position.x, y - 1.6 * k), Vector2(w, 3.2 * k)), _dk(col, 0.6) if gold else col)
		n.draw_rect(Rect2(Vector2(r.position.x, y - 1.2 * k), Vector2(w, 1.6 * k)), col if gold else _lt(base, 0.12))
	n.draw_line(Vector2(rc.end.x, rc.position.y), Vector2(rc.end.x, rc.end.y), _a(INK, 0.55), 1.0 * k)


static func _corner(n: CardFx, r: Rect2, idx: int, gold: bool, mo: float) -> void:
	var k := n.k
	var sx := 1.0 if idx % 2 == 0 else -1.0
	var sy := 1.0 if idx < 2 else -1.0
	var p := Vector2(r.position.x if sx > 0 else r.end.x, r.position.y if sy > 0 else r.end.y)
	var L := (27.0 if gold else 27.0) * k
	var ex := Vector2(sx, 0)
	var ey := Vector2(0, sy)
	var curve := _bez(p + ex * L, p + (ex + ey) * L * (0.2 if gold else 0.62), p + ey * L, 9)
	var poly := PackedVector2Array([p])
	poly.append_array(curve)
	if not gold:
		n._poly(_off(poly, Vector2(1.2, 1.6) * k), _a(Color.BLACK, 0.3))
		n._poly(poly, LEATHER)
		n._poly(_off(_scale(poly, p, 0.55), Vector2.ZERO), _a(Color.WHITE, 0.07))
		n.draw_polyline(curve, _a(INK, 0.9), 2.0 * k, true)
		n.draw_polyline(PackedVector2Array([p + ey * L, p, p + ex * L]), _a(INK, 0.75), 1.4 * k, true)
		n.draw_polyline(_off(curve, -(ex + ey) * 2.2 * k), _a(Color(0.85, 0.55, 0.3), 0.5), 1.0 * k, true)
		for i in 5:   # pontos de costura
			var d := 4.0 * k + i * (L - 11.0 * k) / 4.0
			n.draw_line(p + ex * d + ey * 3.0 * k, p + ex * (d + 2.6 * k) + ey * 3.0 * k, CREAM, 1.2 * k)
			n.draw_line(p + ey * d + ex * 3.0 * k, p + ey * (d + 2.6 * k) + ex * 3.0 * k, CREAM, 1.2 * k)
	else:
		n._poly(_off(poly, Vector2(1.2, 1.6) * k), _a(Color.BLACK, 0.35))
		n._poly(poly, GOLD_D)
		n._poly(_scale(poly, p + (ex + ey) * 1.0 * k, 0.88), GOLD)
		n._poly(_scale(poly, p + (ex + ey) * 1.2 * k, 0.52), _a(GOLD_L, 0.55))
		n.draw_polyline(curve, GOLD_L, 1.0 * k, true)
		var mid := curve[4]
		n.draw_circle(mid + (p - mid).normalized() * 1.5 * k, 1.5 * k, GOLD_D)   # filigrana
		n.draw_circle(p + (ex + ey) * 5.4 * k, 2.2 * k, GOLD_D)   # rebite
		n.draw_circle(p + (ex + ey) * 5.4 * k - Vector2(0.5, 0.5) * k, 1.3 * k, GOLD_L)
		var ph := fmod(n.t * 0.5 + idx * 0.25, 1.0)
		if mo > 0.0 and ph < 0.22:
			_star(n, p + (ex + ey) * 7.0 * k, 5.5 * k * sin(ph / 0.22 * PI), _a(Color.WHITE, 0.95))


static func _off(pts: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + d)
	return out


static func _scale(pts: PackedVector2Array, c: Vector2, f: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + (p - c) * f)
	return out


## Fita marcadora de seda carmim saindo do pé da carta.
static func _bookmark(n: CardFx, r: Rect2, mo: float) -> void:
	var k := n.k
	var x := r.position.x + r.size.x * 0.3
	var y0 := r.end.y - 12.0 * k
	var y1 := r.end.y + 26.0 * k
	var sw := sin(n.t * 1.7) * 1.6 * k * mo
	var w := 4.8 * k
	var pts := PackedVector2Array([Vector2(x - w, y0), Vector2(x + w, y0), Vector2(x + w + sw * 0.5, y1), Vector2(x + sw * 0.5, y1 - 7.0 * k), Vector2(x - w + sw * 0.5, y1)])
	n._poly(_off(pts, Vector2(1.4, 1.6) * k), _a(Color.BLACK, 0.3))
	n._poly(pts, Color(0.72, 0.09, 0.15))
	n._poly(PackedVector2Array([Vector2(x - w, y0), Vector2(x - w * 0.35, y0), Vector2(x - w * 0.35 + sw * 0.5, y1 - 3.0 * k), Vector2(x - w + sw * 0.5, y1)]), _a(Color.WHITE, 0.14))
	n.draw_line(Vector2(x, y0), Vector2(x + sw * 0.5, y1 - 8.0 * k), _a(GOLD, 0.9), 1.0 * k)
	n.draw_line(Vector2(x - w + 1.0 * k, y0), Vector2(x - w + 1.0 * k + sw * 0.5, y1 - 0.5 * k), _a(GOLD_D, 0.8), 0.9 * k)
	n.draw_line(Vector2(x + w - 1.0 * k, y0), Vector2(x + w - 1.0 * k + sw * 0.5, y1 - 0.5 * k), _a(GOLD_D, 0.8), 0.9 * k)


static func _wax_seal(n: CardFx, c: Vector2, rad: float, mid: String, mo: float, idx: int) -> void:
	var k := n.k
	var base: Color = MOD.get(mid, Color.GRAY)
	var sd := 3.0 + idx * 5.0 + mid.length()
	# sombra e pingos de cera
	n._poly(_blob(c + Vector2(1.4, 2.2) * k, rad * 1.04, 22, 0.1, sd), _a(Color.BLACK, 0.32))
	n.draw_circle(c + Vector2(rad * 0.5, rad * 0.88), rad * 0.3, _dk(base, 0.72))
	n.draw_circle(c + Vector2(-rad * 0.35, rad * 0.95), rad * 0.2, _dk(base, 0.72))
	var outer := _blob(c, rad, 22, 0.09, sd)
	n._poly(outer, _dk(base, 0.66))
	n._poly(_blob(c, rad * 0.9, 22, 0.05, sd + 1.0), base)
	n.draw_arc(c, rad * 0.66, 0, TAU, 24, _dk(base, 0.7), 1.3 * k, true)
	n.draw_arc(c + Vector2(-0.5, -0.5) * k, rad * 0.78, PI * 1.05, PI * 1.55, 8, _a(_lt(base, 0.55), 0.7), 1.5 * k, true)
	var s := rad * 0.46
	n._seal_icon(mid, c + Vector2(0.9, 0.9) * k, s, _dk(base, 0.5))
	n._seal_icon(mid, c + Vector2(-0.8, -0.8) * k, s, _lt(base, 0.5))
	n._seal_icon(mid, c, s, _lt(base, 0.18) if mid != "shadowy" else Color(0.32, 0.3, 0.4))
	if mo > 0.0:
		var ph := fmod(n.t * 0.45 + idx * 0.37, 1.0)
		if ph < 0.18:
			n.draw_circle(c + Vector2(-rad * 0.4, -rad * 0.45), rad * 0.16 * sin(ph / 0.18 * PI), _a(Color.WHITE, 0.8))


# ---------------------------------------------------------------- V2 Tinta viva

static func _v2(n: CardFx, r: Rect2, mo: float) -> void:
	var k := n.k
	if n.level == 2:
		_wobble_rect(n, r.grow(-3.2 * k), _a(INK, 0.95), 2.6 * k, 1.0, 0.5 * k)
		var by := (30.0 if n.big else 36.0) * k
		_wobble_rect(n, Rect2(r.position.x + 7.0 * k, r.position.y + by, r.size.x - 14.0 * k, r.size.y - by - 7.0 * k), _a(INK, 0.8), 1.2 * k, 2.0, 0.5 * k)
		for c in 2:
			_spiral(n, r, c + 2)
	elif n.level >= 3:
		_illumination(n, r, mo)
	_ink_mods(n, r, mo)


static func _corner_pt(r: Rect2, idx: int, inset: float) -> Array:
	var sx := 1.0 if idx % 2 == 0 else -1.0
	var sy := 1.0 if idx < 2 else -1.0
	return [Vector2(r.position.x if sx > 0 else r.end.x, r.position.y if sy > 0 else r.end.y) + Vector2(sx, sy) * inset, Vector2(sx, sy)]


static func _spiral(n: CardFx, r: Rect2, idx: int) -> void:
	var k := n.k
	var cp := _corner_pt(r, idx, 14.0 * k)
	var c: Vector2 = cp[0]
	var d: Vector2 = cp[1]
	var pts := PackedVector2Array()
	for i in 20:
		var a := 0.6 + i * 0.3
		var rr := (9.0 - i * 0.4) * k
		pts.append(c + Vector2(cos(a) * d.x, sin(a) * d.y) * rr)
	n.draw_polyline(pts, _a(INK, 0.95), 1.9 * k, true)
	n.draw_circle(pts[pts.size() - 1], 1.7 * k, INK)


static func _illumination(n: CardFx, r: Rect2, mo: float) -> void:
	var k := n.k
	var fr := r.grow(-2.9 * k)
	# banda de ouro-folha com contorno de nanquim
	n.draw_rect(fr, _a(GOLD, 0.2 + 0.1 * sin(n.t * 2.4) * mo), false, 8.0 * k)
	n.draw_rect(fr, _a(INK, 0.95), false, 5.4 * k)
	n.draw_rect(fr, GOLD, false, 3.8 * k)
	n.draw_rect(fr.grow(-0.9 * k), _a(GOLD_L, 0.8), false, 1.0 * k)
	n.draw_rect(fr.grow(0.9 * k), _a(GOLD_D, 0.85), false, 0.8 * k)
	# trepadeira com folhas e bagas pelas quatro bordas
	var ins := fr.grow(-5.8 * k)
	var by := r.position.y + (31.0 if n.big else 37.0) * k   # a vinha começa abaixo da faixa do nome
	var tl := Vector2(ins.position.x, by)
	var tr := Vector2(ins.end.x, by)
	var edges := [[tr, ins.end], [ins.end, Vector2(ins.position.x, ins.end.y)], [Vector2(ins.position.x, ins.end.y), tl], [tl, tr]]
	var cnt := 0
	for e in 4:
		var a: Vector2 = edges[e][0]
		var b: Vector2 = edges[e][1]
		var dir := (b - a).normalized()
		var nrm := dir.orthogonal()
		var len := a.distance_to(b)
		var pts := PackedVector2Array()
		var seg := 24
		for i in seg + 1:
			var f := float(i) / seg
			var env := clampf(minf(f, 1.0 - f) * len / (12.0 * k), 0.0, 1.0)
			pts.append(a + dir * len * f + nrm * sin(f * len / (6.5 * k)) * 1.2 * k * env)
		n.draw_polyline(pts, _a(INK, 0.8), 2.0 * k, true)
		n.draw_polyline(pts, GOLD, 1.2 * k, true)
		var leaves := maxi(2, int(len / (13.0 * k)))
		for i in leaves:
			var f := (i + 0.5) / leaves
			if f < 0.08 or f > 0.92:
				continue
			var side := 1.0 if i % 2 == 0 else -1.0
			var p0 := a + dir * len * f + nrm * sin(f * len / (6.5 * k)) * 1.2 * k
			var tip := p0 + nrm * side * 5.0 * k + dir * 3.0 * k
			var mid := (p0 + tip) * 0.5 + dir.orthogonal() * side * 1.5 * k
			var mid2 := (p0 + tip) * 0.5 - dir.orthogonal() * side * 1.5 * k
			n._poly(PackedVector2Array([p0, mid, tip, mid2]), GOLD)
			n.draw_polyline(PackedVector2Array([p0, mid, tip, mid2, p0]), _a(INK, 0.7), 0.7 * k, true)
			n.draw_line(p0, tip, _a(GOLD_D, 0.9), 0.7 * k, true)
			if i % 3 == 1:
				n.draw_circle(p0 - nrm * side * 1.6 * k, 1.35 * k, Color(0.72, 0.1, 0.16))
			cnt += 1
	# rosetas nos cantos
	for c in 4:
		var cp := _corner_pt(r, c, 6.4 * k if c >= 2 else 6.0 * k)
		var cc: Vector2 = cp[0]
		if c < 2:   # no topo ficam só rebites: a faixa do nome e a gema de custo não podem ser cobertas
			n.draw_circle(cc, 3.2 * k, _a(INK, 0.95))
			n.draw_circle(cc, 2.4 * k, GOLD)
			continue
		n.draw_circle(cc, 7.8 * k, _a(INK, 0.95))
		n.draw_circle(cc, 6.6 * k, GOLD_D)
		for i in 8:
			var a := TAU * i / 8.0
			n.draw_circle(cc + Vector2(cos(a), sin(a)) * 4.2 * k, 2.3 * k, GOLD)
		n.draw_circle(cc, 3.0 * k, Color(0.72, 0.1, 0.16))
		n.draw_circle(cc - Vector2(0.5, 0.5) * k, 0.9 * k, _a(Color.WHITE, 0.7))
	# brilho de ouro-folha: estrelinhas que piscam
	if mo > 0.0:
		for i in 6:
			var ph := fmod(n.t * 0.6 + rn(i, 7.0) * 3.0, 1.0)
			if ph < 0.25:
				var f := rn(i, 3.0)
				var pos := Vector2(r.position.x + r.size.x * (0.1 + 0.8 * f), r.position.y + 3.6 * k) if i % 2 == 0 else Vector2(r.position.x + 3.6 * k, r.position.y + r.size.y * (0.1 + 0.8 * f))
				_star(n, pos, 4.6 * k * sin(ph / 0.25 * PI), _a(Color.WHITE, 0.95))


static func _ink_mods(n: CardFx, r: Rect2, mo: float) -> void:
	var k := n.k
	if n.mids.is_empty():
		return
	var g := _gem(n, r)
	var gc: Vector2 = g[0]
	var gr: float = g[1]
	for i in n.mids.size():
		var mid: String = n.mids[i]
		var col: Color = MOD.get(mid, Color.GRAY)
		if i == 0:
			_splash(n, gc, gr, mid, col, mo, false)
			n.draw_circle(gc, gr, _a(col, 0.4))
		else:   # os outros modificadores pingam mais abaixo, na margem direita
			_splash(n, Vector2(gc.x - gr * 0.1, gc.y + gr * (2.7 + (i - 1) * 2.1)), gr * 0.82, mid, col, mo, true)
	# marginália: o símbolo de cada modificador no pé, em nanquim sobre um toque da cor
	for i in n.mids.size():
		var mid: String = n.mids[i]
		var col: Color = MOD.get(mid, Color.GRAY)
		var c := Vector2(r.end.x - 11.0 * k - i * 19.5 * k, r.end.y - 11.0 * k)
		n.draw_circle(c, 8.4 * k, _a(col, 0.28))
		n.draw_arc(c, 8.4 * k, 0, TAU, 20, _a(col, 0.95), 1.5 * k, true)
		n._seal_icon(mid, c, 5.2 * k, _dk(col, 0.62) if mid != "shadowy" else INK)


static func _splash(n: CardFx, c: Vector2, gr: float, mid: String, col: Color, mo: float, filled: bool) -> void:
	var k := n.k
	var steps := 36
	var sd := float(mid.length()) * 3.1
	for j in 4:   # halo suave de tinta absorvida pelo papel
		n.draw_circle(c, gr * (2.6 - j * 0.45), _a(col, 0.045))
	var outer := PackedVector2Array()
	for i in steps:
		var a := TAU * i / steps
		var f := 1.3
		match mid:
			"explosive":
				f = 1.95 if i % 3 == 0 else 1.2
			"cheap":
				f = 1.3 + (0.12 if i % 4 < 2 else -0.04)
			"veteran":
				f = 1.3
			"cursed":
				f = 1.32 + (rn(i, sd) - 0.5) * 0.5
			"shadowy":
				f = 1.35 + (rn(i, sd) - 0.5) * 0.35 + 0.25 * sin(a * 3.0 + n.t * 0.8 * mo)
		outer.append(c + Vector2(cos(a), sin(a)) * gr * f)
	var inner_r := 0.0 if filled else gr * 0.9
	if filled:
		n._poly(outer, _a(col, 0.92))
	else:
		for i in steps:
			var a0 := TAU * i / steps
			var a1 := TAU * (i + 1) / steps
			var q := PackedVector2Array([c + Vector2(cos(a0), sin(a0)) * inner_r, outer[i], outer[(i + 1) % steps], c + Vector2(cos(a1), sin(a1)) * inner_r])
			n._poly(q, _a(col, 0.92))
	if mid == "veteran":
		n.draw_arc(c, gr * 1.55, 0, TAU, 30, _a(col, 0.75), 1.2 * k, true)
	# respingos
	for i in 7:
		var a := rn(i, sd + 2.0) * TAU
		var d := gr * (1.65 + rn(i, sd + 4.0) * 0.8)
		n.draw_circle(c + Vector2(cos(a), sin(a)) * d, gr * (0.07 + rn(i, sd + 6.0) * 0.14), _a(col, 0.9))
	if mid == "shadowy":
		for i in 3:
			var pts := PackedVector2Array()
			var a := -0.6 + i * 0.9 + sin(n.t * 0.7 + i) * 0.15 * mo
			for j in 10:
				var rr := gr * (1.5 + j * 0.18)
				var aa := a + sin(j * 0.7 + i * 2.0) * 0.18
				pts.append(c + Vector2(cos(aa), sin(aa)) * rr)
			n.draw_polyline(pts, _a(col, 0.55), 1.4 * k, true)
	# escorrido
	var drips := 4 if mid == "cursed" else 3
	for d in drips:
		var x := c.x + (d - (drips - 1) * 0.5) * gr * 0.72 + (rn(d, sd) - 0.5) * gr * 0.3
		var y0 := c.y + gr * 1.0
		var base_len := (11.0 + 26.0 * rn(d, sd + 9.0)) * k * (1.5 if mid == "cursed" else 1.0)
		var len := base_len * (0.9 + 0.1 * sin(n.t * 0.8 + d * 1.9) * mo)
		var w := (2.3 + rn(d, sd + 11.0) * 1.3) * k
		n.draw_rect(Rect2(x - w * 0.5, y0, w, len), _a(col, 0.93))
		n.draw_circle(Vector2(x, y0 + len), w * 0.8, _a(col, 0.93))
		n.draw_line(Vector2(x - w * 0.18, y0 + 1.0 * k), Vector2(x - w * 0.18, y0 + len), _a(Color.WHITE, 0.25), maxf(0.8, w * 0.22))


# ---------------------------------------------------------------- V3 Carimbos e condecorações

static func _v3(n: CardFx, r: Rect2, mo: float) -> void:
	var k := n.k
	if n.level == 2:
		n.draw_rect(r, _a(SILVER, 0.95), false, 2.0 * k)
	if n.level >= 3:
		n.draw_rect(r.grow(2.0 * k), _a(GOLD, 0.25 + 0.15 * sin(n.t * 3.0) * mo), false, 6.0 * k)
		n.draw_rect(r, GOLD, false, 2.8 * k)
		n.draw_rect(r.grow(-2.8 * k), _a(GOLD_L, 0.7), false, 1.0 * k)
	# carimbos primeiro, medalhas por cima (penduradas para fora do pé)
	for i in n.mids.size():
		_stamp(n, r, n.mids[i], i)
	if n.level >= 2:
		_medal_pair(n, r, mo)


static func _medal_pair(n: CardFx, r: Rect2, mo: float) -> void:
	var k := n.k
	var gold := n.level >= 3
	var p0 := Vector2(r.position.x + 13.0 * k, r.end.y - 13.0 * k)
	_medal(n, p0, 10.5 * k, false, Color(0.2, 0.36, 0.7), mo, 0.0)
	if gold:
		var p1 := Vector2(r.position.x + 41.0 * k, r.end.y - 13.0 * k)
		_medal(n, p1, 13.2 * k, true, Color(0.72, 0.09, 0.15), mo, 1.7)


static func _medal(n: CardFx, pin: Vector2, rad: float, gold: bool, rib: Color, mo: float, ph: float) -> void:
	var k := n.k
	var sw := sin(n.t * 1.5 + ph) * 1.3 * k * mo
	var c := pin + Vector2(sw, 24.0 * k + (3.0 * k if gold else 0.0))
	var top := c + Vector2(0, -rad * 0.85)
	for sx in [-1.0, 1.0]:   # fita em V
		var a := pin + Vector2(sx * 4.6 * k, 0)
		var b := top + Vector2(sx * 1.4 * k, 0)
		n.draw_line(a + Vector2(0.8, 1.2) * k, b + Vector2(0.8, 1.2) * k, _a(Color.BLACK, 0.3), 7.0 * k)
		n.draw_line(a, b, rib, 6.4 * k)
		n.draw_line(a + Vector2(-1.2 * k * sx, 0), b + Vector2(-1.2 * k * sx, 0), _lt(rib, 0.28), 1.1 * k)
	var metal := GOLD if gold else SILVER
	var rim := GOLD_D if gold else SILVER_D
	n.draw_circle(c + Vector2(1.2, 1.8) * k, rad, _a(Color.BLACK, 0.35))
	n.draw_circle(c, rad, rim)
	n.draw_circle(c, rad * 0.84, metal)
	n.draw_circle(c + Vector2(-rad * 0.2, -rad * 0.24), rad * 0.5, _a(Color.WHITE, 0.32))
	n.draw_arc(c, rad * 0.64, 0, TAU, 20, _a(rim, 0.9), 1.0 * k, true)
	if gold:
		var st := PackedVector2Array()
		for i in 10:
			var a := -PI * 0.5 + TAU * i / 10.0
			st.append(c + Vector2(cos(a), sin(a)) * rad * (0.56 if i % 2 == 0 else 0.24))
		n._poly(st, GOLD_D)
		n.draw_arc(c, rad * 1.0, PI * 0.55, PI * 0.95, 6, GOLD_L, 1.0 * k, true)
		var s := fmod(n.t * 0.5 + 0.3, 1.0)
		if mo > 0.0 and s < 0.2:
			_star(n, c + Vector2(-rad * 0.45, -rad * 0.5), 6.0 * k * sin(s / 0.2 * PI), _a(Color.WHITE, 0.95))
	else:
		n.draw_circle(c, rad * 0.22, rim)
	n.draw_circle(pin, 2.2 * k, _a(INK, 0.9))   # alfinete
	n.draw_circle(pin - Vector2(0.4, 0.4) * k, 1.4 * k, GOLD)


static func _stamp(n: CardFx, r: Rect2, mid: String, idx: int) -> void:
	var k := n.k
	var col: Color = MOD.get(mid, Color.GRAY)
	var txt := TranslationServer.translate("MOD_" + mid).to_upper()
	var font := UiDiario.font("marker")
	var fs := int(roundf(19.0 * k))
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	while tw > r.size.x * 0.8 and fs > 7:
		fs -= 1
		tw = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var hh := fs * 0.62 + 4.5 * k
	var ww := tw * 0.5 + 6.0 * k
	var cy := r.position.y + r.size.y * (0.36 if n.big else 0.5) + idx * (hh * 1.9) - (hh * 0.9 if n.mids.size() > 1 else 0.0)
	var c := Vector2(r.position.x + r.size.x * 0.5 + (idx % 2) * 3.0 * k, cy)
	var rot := (-0.3 if idx % 2 == 0 else 0.22)
	n.draw_set_transform(c, rot, Vector2.ONE)
	var rect := Rect2(-ww, -hh, ww * 2.0, hh * 2.0)
	# manchinha de tinta fora do carimbo (vazou)
	n.draw_rect(rect, _a(CREAM, 0.62 if CardFx.variant() >= 4 else 0.42))
	n.draw_rect(rect.grow(1.6 * k), _a(col, 0.14), false, 3.0 * k)
	n.draw_rect(rect, _a(col, 0.88), false, 2.4 * k)
	n.draw_rect(rect.grow(-3.6 * k), _a(col, 0.8), false, 0.9 * k)
	n.draw_string(font, Vector2(-tw * 0.5, fs * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _a(col, 0.97))
	n.draw_string(font, Vector2(-tw * 0.5 + 0.5 * k, fs * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _a(col, 0.97))
	# falhas do carimbo: pontinhos de papel
	for i in 18:
		var p := Vector2(rect.position.x + rn(i, 2.0 + idx) * rect.size.x, rect.position.y + rn(i, 5.0 + idx) * rect.size.y)
		n.draw_circle(p, (0.3 + rn(i, 9.0) * 0.5) * k, _a(CREAM, 0.8))
	n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- V4 Carimbo + material do fundo

static func _v4(n: CardFx, r: Rect2, mo: float) -> void:
	var k := n.k
	# O material (shader) já diz o nível; aqui só um filete de contorno para a carta pequena não se perder no fundo.
	if n.level == 2:
		n.draw_rect(r, _a(Color(0.78, 0.84, 0.92), 0.9), false, 1.6 * k)
	elif n.level >= 3:
		n.draw_rect(r.grow(2.0 * k), _a(GOLD, 0.2 + 0.12 * sin(n.t * 3.0) * mo), false, 5.0 * k)
		n.draw_rect(r, GOLD_L, false, 1.8 * k)
	for i in n.mids.size():
		_stamp(n, r, n.mids[i], i)
