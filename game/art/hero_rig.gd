class_name HeroRig
extends Node3D
## Herói com esqueleto e animações de verdade (looks com "rig", hoje o 5: Cavaleiro da KayKit, CC0).
## O WorldView continua montando as peças antigas (pivôs invisíveis: Looks.hero_mesh devolve malha vazia) e só
## pendura este nó no corpo. O rig lê o estado do herói sozinho a cada quadro: andar, golpe, escudo, parado.

const SCENES := {5: "res://assets/models/cc0/hero_knight.scn"}
# Peças que o pacote traz todas juntas; ficam só a espada de uma mão, o escudo redondo, o elmo e a capa.
const HIDE := ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "2H_Sword"]
const HEIGHT := 1.75

var ap: AnimationPlayer
var view: Node
var cur := ""
var swing_seen := 0.0


static func has_rig(look: int) -> bool:
	return SCENES.has(look) and ResourceLoader.exists(SCENES[look])


## Textura do pacote (para o material do herói, que o WorldView anima com flash e brilho).
static func texture(look: int) -> Texture2D:
	var ps: PackedScene = load(SCENES[look])
	var n := ps.instantiate()
	var t: Texture2D = null
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: Material = (mi as MeshInstance3D).get_active_material(0)
		if m is BaseMaterial3D and (m as BaseMaterial3D).albedo_texture:
			t = (m as BaseMaterial3D).albedo_texture
			break
	n.free()
	return t


static func make(look: int, mat: Material) -> HeroRig:
	var r := HeroRig.new()
	var ps: PackedScene = load(SCENES[look])
	var n: Node3D = ps.instantiate()
	r.add_child(n)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name) in HIDE:
			mi.visible = false
		else:
			(mi as MeshInstance3D).material_override = mat
	# O corpo antigo fica em escala 1.3 e com os pés em y = 0; o cavaleiro tem ~2,4 m no arquivo e olha para +Z.
	var aabb := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if not (mi as MeshInstance3D).visible:
			continue
		var xf := Transform3D.IDENTITY
		var q: Node = mi
		while q and q != n:
			if q is Node3D:
				xf = (q as Node3D).transform * xf
			q = q.get_parent()
		var b: AABB = xf * (mi as MeshInstance3D).get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	var s := HEIGHT / maxf(aabb.size.y, 0.1) if aabb.size.y > 0.5 else 1.0
	n.scale = Vector3.ONE * s
	n.rotation.y = PI
	var aps := n.find_children("*", "AnimationPlayer", true, false)
	r.ap = aps[0] if aps.size() > 0 else null
	return r


func _ready() -> void:
	var p := get_parent()
	while p and not ("swing_t" in p and "sim" in p):
		p = p.get_parent()
	view = p
	_play("Idle", 0.0)


func _play(a: String, blend := 0.18, speed := 1.0) -> void:
	if ap == null or not ap.has_animation(a):
		return
	ap.speed_scale = speed
	if a != cur:
		ap.play(a, blend)
		cur = a


func _process(_delta: float) -> void:
	if view == null or view.sim == null or ap == null:
		return
	var h = view.sim.hero
	var spd: float = Vector2(h.x - h.ox, h.y - h.oy).length() / view.sim.dt
	if h.petrify_t > 0.0 or h.root_t > 0.0:
		ap.speed_scale = 0.0 if h.petrify_t > 0.0 else 0.3
		return
	var sw: float = view.swing_t
	if sw > swing_seen + 0.01:
		# Golpe novo: recomeça a animação de ataque mesmo se já estava nela.
		cur = ""
		_play("1H_Melee_Attack_Slice_Diagonal", 0.05, 1.9)
	swing_seen = sw
	if sw > 0.0:
		return
	if h.shield_hp > 0.0 and spd < 0.4:
		_play("Blocking", 0.2)
	elif spd > 3.4:
		_play("Running_A", 0.2, clampf(spd / 5.0, 0.7, 1.5))
	elif spd > 0.4:
		_play("Walking_A", 0.2, clampf(spd / 2.2, 0.6, 1.6))
	else:
		_play("Idle", 0.3)
