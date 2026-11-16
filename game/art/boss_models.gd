class_name BossModels
## Modelos dos 3 chefes finais (Rainha da Praga, Dragão Avarento, Lich), gerados por
## tools/art/blender_v2/bosses_final.py -> import_v2.gd -> assets/models/v2/boss_<vilão>_<parte>.res.
## Cada parte tem a própria origem (ombro, pescoço, chão do núcleo); part_offsets() diz onde ela fica em
## relação ao centro do chefe no chão (Godot: frente = -Z, esquerdo do chefe = -X, como Models.boss_full()).
## Sem o arquivo de alguma parte, cai no chefe atual (Models.boss_part / Models.boss_full).

const PARTS := ["core", "head", "left_arm", "right_arm"]
const DIR := "res://assets/models/v2/"

## Offsets = PART_OFFSETS de bosses_final.py vezes o FIT de cada chefe, convertidos (x, y, z) -> (-x, z, y).
const OFFSETS := {
	"plague": {"core": Vector3(0, 0, 0), "head": Vector3(0, 3.784, -0.088), "left_arm": Vector3(-1.232, 2.728, 0), "right_arm": Vector3(1.232, 2.728, 0)},
	"dragon": {"core": Vector3(0, 0, 0), "head": Vector3(0, 3.74, -0.85), "left_arm": Vector3(-0.765, 2.21, 0.51), "right_arm": Vector3(0.85, 1.955, -0.17)},
	"lich": {"core": Vector3(0, 0, 0), "head": Vector3(0, 4.18, -0.048), "left_arm": Vector3(-1.14, 3.23, 0), "right_arm": Vector3(1.14, 3.23, 0)},
}
## Offsets do chefe atual (os de Models.boss_full()).
const CURRENT := {"core": Vector3(0, 0, 0), "head": Vector3(0, 4.4, 0), "left_arm": Vector3(-1.7, 2.4, 0), "right_arm": Vector3(1.7, 2.4, 0)}
## Peças de cenário que acompanham o chefe mas não são partes (não levam dano, não somem).
const EXTRAS := {"lich": ["circle"]}


## O vilão tem os 4 arquivos de partes?
static func has_model(villain: String) -> bool:
	if not OFFSETS.has(villain):
		return false
	for id in PARTS:
		if not ResourceLoader.exists(_path(villain, id)):
			return false
	return true


## Offsets das partes ("core", "head", "left_arm", "right_arm") do vilão; os do chefe atual se ele não tiver modelo.
static func part_offsets(villain: String) -> Dictionary:
	return OFFSETS[villain] if has_model(villain) else CURRENT


## Malha de uma parte; a do chefe atual se faltar o arquivo.
static func part(villain: String, id: String) -> ArrayMesh:
	if has_model(villain):
		return _mesh(villain, id) as ArrayMesh
	return Models.boss_part(id)


## Malha (e material) de uma parte do vilão: a das miniaturas pintadas, se a versão escolhida a tiver.
static func _mesh(villain: String, id: String) -> Mesh:
	if Looks.g_on():
		var gm := Looks.g_mesh("boss_%s_%s" % [villain, id])
		if gm:
			return gm
	return load(_path(villain, id))


## O chefe inteiro, com as partes como filhos chamados pelo id (core, head, left_arm, right_arm) e, no Lich,
## o círculo ritual ("circle", cenário). Origem no chão, no centro do chefe.
static func boss_full(villain: String) -> Node3D:
	if not has_model(villain):
		return Models.boss_full()
	var n := Node3D.new()
	n.name = "boss_" + villain
	var offs: Dictionary = OFFSETS[villain]
	for id in PARTS:
		var mi := MeshInstance3D.new()
		mi.name = id
		mi.mesh = _mesh(villain, id)
		mi.material_override = Looks.g_material(mi.mesh, Models.material())
		mi.position = offs[id]
		n.add_child(mi)
	for id in EXTRAS.get(villain, []):
		if ResourceLoader.exists(_path(villain, id)):
			var mi := MeshInstance3D.new()
			mi.name = id
			mi.mesh = _mesh(villain, id)
			mi.material_override = Looks.g_material(mi.mesh, Models.material())
			n.add_child(mi)
	return n


static func _path(villain: String, id: String) -> String:
	return DIR + "boss_%s_%s.res" % [villain, id]
