class_name Arvores
extends RefCounted
## Árvores refeitas à mão no Blender (rodada do cenário com propósito, 21/11/2026): 3 estilos para escolher.
## VAR = 0: as árvores de antes. 1 tufos redondos (livro ilustrado), 2 alta/oval + pinheiro em camadas,
## 3 carvalho largo e torto, 4 misto escolhido em 21/11/2026: cada bosque é do estilo 2 ou do 3 (um por bosque).
## --arvores=N em game/main.gd.
## Malhas em assets/models/arv<N>/<id>_a<ato>.res com o atlas <id>_a<ato>.png ao lado (fontes em
## tools/art/blender_arvores/). ids: "tree" e "tree_round" (duas silhuetas por estilo); ato 0 primavera,
## 1 outono, 2 terra amaldiçoada.

static var VAR := 4   # padrão aprovado em 21/11/2026 (0 = árvores de antes)

const NAMES := ["Antigas", "Tufos redondos", "Alta + pinheiro", "Carvalho torto", "Pinheiro ou carvalho por bosque"]

static var _mesh: Dictionary = {}


## Estilos em uso: [0] = só as antigas; VAR 4 = [2, 3] (cada bosque sorteia um).
static func styles() -> Array:
	if VAR <= 0:
		return [0]
	return [2, 3] if VAR == 4 else [VAR]


## Malha do estilo (padrão: o escolhido) para o id e o ato, ou null (usa a antiga).
static func mesh(id: String, act: int, style := -1) -> Mesh:
	var st: int = style if style >= 0 else int(styles()[0])
	if st <= 0 or not id in ["tree", "tree_round"]:
		return null
	var key := "%d/%s/%d" % [st, id, act]
	if _mesh.has(key):
		return _mesh[key]
	var base := "res://assets/models/arv%d/%s_a%d" % [st, id, clampi(act, 0, 2)]
	var m: Mesh = load(base + ".res") if ResourceLoader.exists(base + ".res") else null
	if m:
		if not m.has_meta("gtex") and ResourceLoader.exists(base + ".png"):
			m.set_meta("gtex", load(base + ".png"))
		m.set_meta("gink", 0.0)
	_mesh[key] = m
	return m
