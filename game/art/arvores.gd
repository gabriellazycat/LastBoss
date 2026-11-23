class_name Arvores
extends RefCounted
## Árvores refeitas à mão no Blender (rodada do cenário com propósito, 21/11/2026): 3 estilos para escolher.
## VAR = 0: as árvores de antes. 1 tufos redondos (livro ilustrado), 2 alta/oval + pinheiro em camadas,
## 3 carvalho largo e torto, 4 misto escolhido em 21/11/2026: cada bosque é do estilo 2 ou do 3 (um por bosque).
## 5 carvalho em pinceladas, 6 pinheiro + álamo em pinceladas, 7 (padrão desde 22/11/2026) = cada bosque é do 5 ou do 6:
## as copas de antes pareciam massinha (elipsoides fundidos e alisados); as novas são miolos escuros cobertos de placas
## angulosas de cor chapada, como pinceladas de guache (tools/art/blender_arvores/build_pinceladas.py, docs/ARVORES_E_CHAO.md).
## Com 5 a 7 os arbustos também são os novos (arv5/bush_a<ato>), já com a cor de cada ato (sem tinta por instância).
## --arvores=N em game/main.gd.
## Malhas em assets/models/arv<N>/<id>_a<ato>.res com o atlas <id>_a<ato>.png ao lado (fontes em
## tools/art/blender_arvores/). ids: "tree" e "tree_round" (duas silhuetas por estilo); ato 0 primavera,
## 1 outono, 2 terra amaldiçoada.

static var VAR := 7   # padrão desde 22/11/2026 (4 = as de 21/11; 0 = árvores de antes)

const NAMES := ["Antigas", "Tufos redondos", "Alta + pinheiro", "Carvalho torto", "Pinheiro ou carvalho por bosque",
	"Pinceladas · carvalho", "Pinceladas · pinheiro + álamo", "Pinceladas · carvalho ou pinheiro por bosque"]

static var _mesh: Dictionary = {}


## Estilos em uso: [0] = só as antigas; VAR 4 = [2, 3], VAR 7 = [5, 6] (cada bosque sorteia um).
static func styles() -> Array:
	if VAR <= 0:
		return [0]
	if VAR == 4:
		return [2, 3]
	return [5, 6] if VAR == 7 else [VAR]


## Arbustos novos (estilos 5 a 7)?
static func bush_on() -> bool:
	return VAR >= 5


## Arbusto em pinceladas do ato (0 primavera, 1 outono, 2 terra amaldiçoada), ou null (usa o de antes).
static func bush_mesh(act: int) -> Mesh:
	if not bush_on():
		return null
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
