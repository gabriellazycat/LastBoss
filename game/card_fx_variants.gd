class_name CardFxV
extends RefCounted
## Desenho dos upgrades de carta (o "Carimbo + material", escolhido em 13/11/2026): o NÍVEL e o modificador (no N1)
## trocam o material do fundo no shader (paper.gdshader, mat_id: N2 ferro rebitado, N3 ouro com brilho; Sombrio
## obsidiana, Amaldiçoado pedra rachada, Explosivo ferro em brasa, Barato madeira, Veterano aço gravado). O nível manda
## no material; o modificador ganha um carimbo grande em diagonal, na cor dele, com o nome.
## Tudo é desenhado no _draw do CardFx (`n`), sem tocar no papel da carta.

const CREAM := Color(0.95, 0.9, 0.8)
const GOLD := Color(0.98, 0.76, 0.27)
const GOLD_L := Color(1.0, 0.95, 0.65)
## Cor do carimbo de cada modificador.
const MOD := {
	"cheap": Color(0.04, 0.6, 0.64),
	"veteran": Color(0.18, 0.4, 0.82),
	"explosive": Color(0.95, 0.4, 0.06),
	"cursed": Color(0.55, 0.14, 0.74),
	"shadowy": Color(0.15, 0.14, 0.2),
	"leech": Color(0.75, 0.06, 0.16),
}


static func draw(n: CardFx, r: Rect2, mo: float) -> void:
	_v4(n, r, mo)


# ---------------------------------------------------------------- utilidades

static func rn(i: float, s := 0.0) -> float:
	return fposmod(sin(i * 12.9898 + s * 78.233) * 43758.5453, 1.0)


static func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


# ---------------------------------------------------------------- V1 Encadernação


# ---------------------------------------------------------------- V2 Tinta viva


# ---------------------------------------------------------------- V3 Carimbos e condecorações


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
	n.draw_rect(rect, _a(CREAM, 0.62))
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
