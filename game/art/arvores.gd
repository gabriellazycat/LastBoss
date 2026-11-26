class_name Arvores
extends RefCounted
## Árvores e arbustos em pinceladas (22/11/2026): miolos escuros cobertos de placas angulosas de cor chapada, como
## pinceladas de guache (fontes em tools/art/blender_arvores/build_pinceladas.py). Cada bosque sorteia um estilo:
## 5 = carvalho, 6 = pinheiro + álamo. Os arbustos (arv5/bush_a<ato>) já vêm com a cor de cada ato.
## Malhas em assets/models/arv<N>/<id>_a<ato>.res com o atlas <id>_a<ato>.png ao lado. ids: "tree" e "tree_round"
## (duas silhuetas por estilo); ato 0 primavera, 1 outono, 2 terra amaldiçoada.

## Estilos por bosque (cada bosque sorteia um).
const STYLES := [5, 6]

static var _mesh: Dictionary = {}


## Arbusto em pinceladas do ato (0 primavera, 1 outono, 2 terra amaldiçoada).
static func bush_mesh(act: int) -> Mesh:
	if act == 0 and Diorama.mesh("bush"):
		return Diorama.mesh("bush")
	var key := "bush/%d" % act
	if _mesh.has(key):
		return _mesh[key]
	var base := "res://assets/models/arv5/bush_a%d" % clampi(act, 0, 2)
	var m: Mesh = load(base + ".res") if ResourceLoader.exists(base + ".res") else null
	if m:
		if not m.has_meta("gtex") and ResourceLoader.exists(base + ".png"):
			m.set_meta("gtex", load(base + ".png"))
		m.set_meta("gink", 0.0)
	_mesh[key] = m
	return m


## Malha do estilo (padrão: o primeiro) para o id e o ato, ou null se o id não é árvore.
static func mesh(id: String, act: int, style := -1) -> Mesh:
	var st: int = style if style >= 0 else int(STYLES[0])
	if not id in ["tree", "tree_round"]:
		return null
	if act == 0 and Diorama.mesh("%s_s%d" % [id, st]):
		return Diorama.mesh("%s_s%d" % [id, st])
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
