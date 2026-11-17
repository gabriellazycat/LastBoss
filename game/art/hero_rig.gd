class_name HeroRig
extends Node3D
## Herói com esqueleto e animações de verdade (looks com "rig", hoje o 5: Cavaleiro da KayKit, CC0).
## O WorldView continua montando as peças antigas (pivôs invisíveis: Looks.hero_mesh devolve malha vazia) e só
## pendura este nó no corpo. O rig lê o estado do herói sozinho a cada quadro: andar, golpe, escudo, parado.

const SCENES := {5: "res://assets/models/cc0/hero_knight.scn"}
# Peças que o pacote traz todas juntas; ficam só a espada de uma mão, o escudo redondo, o elmo e a capa.
const HIDE := ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "2H_Sword"]
const HEIGHT := 1.75
# Classes da campanha (rodada autônoma de 09/11/2026): cena, peças escondidas, ataque e tom de cada uma.
const CLASS_SCENE := {"escudeiro": "hero_knight", "arqueira": "hero_rogue_hooded", "mago": "hero_mage", "cleriga": "hero_mage",
	"assassino": "hero_rogue_hooded", "barbaro": "hero_knight", "besteiro": "hero_rogue_hooded", "guardiao": "hero_knight"}
const CLASS_HIDE := {
	"escudeiro": ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "2H_Sword"],
	"arqueira": ["Knife_Offhand", "2H_Crossbow", "Knife", "Throwable"],
	"mago": ["Spellbook", "Spellbook_open", "1H_Wand"],
	"cleriga": ["Spellbook", "1H_Wand", "2H_Staff"],
	# Mesmos pacotes das outras classes, com outras peças à mostra (15/11/2026).
	"assassino": ["2H_Crossbow", "1H_Crossbow", "Throwable"],
	"barbaro": ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Spike_Shield", "Round_Shield", "1H_Sword"],
	"besteiro": ["Knife_Offhand", "Knife", "1H_Crossbow", "Throwable"],
	"guardiao": ["1H_Sword_Offhand", "Badge_Shield", "Spike_Shield", "2H_Sword"],
}
const CLASS_ATTACK := {"escudeiro": "1H_Melee_Attack_Slice_Diagonal", "arqueira": "1H_Ranged_Shoot", "mago": "Spellcast_Shoot", "cleriga": "Spellcast_Shoot",
	"assassino": "1H_Melee_Attack_Slice_Diagonal", "barbaro": "1H_Melee_Attack_Slice_Diagonal", "besteiro": "1H_Ranged_Shoot", "guardiao": "1H_Melee_Attack_Slice_Diagonal"}
# Tom de cada classe tirado da arte da carta dela (16/11/2026), para achar cada herói na party: Arqueira de capa
# verde, Clériga de branco, Mago de azul fundo, Assassino de roxo, Bárbaro de pele e couro, Besteiro de chapéu e
# couro marrom, Guardião de aço frio. O Escudeiro fica com o aço azulado do material do herói (Looks.hero_material).
const CLASS_TINT := {"arqueira": Color(0.7, 0.95, 0.58), "cleriga": Color(1.0, 0.97, 0.86), "mago": Color(0.55, 0.62, 1.0),
	"assassino": Color(0.86, 0.5, 1.0), "barbaro": Color(1.0, 0.7, 0.52), "besteiro": Color(0.95, 0.8, 0.56),
	"guardiao": Color(0.8, 0.85, 0.92)}

var ap: AnimationPlayer
var view: Node
var cur := ""
var swing_seen := 0.0
var cls := "escudeiro"
var hero_ref = null          # SimHero desenhado (null = o herói da vez)
var atk_seen := 0.0


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


static func scene_path(look: int, cls_: String) -> String:
	if cls_ == "escudeiro" or not CLASS_SCENE.has(cls_):
		return SCENES[look]
	return "res://assets/models/cc0/%s.scn" % CLASS_SCENE[cls_]


static func make(look: int, mat: Material, cls_ := "escudeiro") -> HeroRig:
	var r := HeroRig.new()
	r.cls = cls_ if CLASS_SCENE.has(cls_) else "escudeiro"
	var path := scene_path(look, r.cls)
	if not ResourceLoader.exists(path):
		path = SCENES[look]
		r.cls = "escudeiro"
	var ps: PackedScene = load(path)
	var n: Node3D = ps.instantiate()
	r.add_child(n)
	if mat is ShaderMaterial:
		# Cada rig tem o seu material (17/11/2026): antes o flash de dano do líder acendia também seguidores e ajudante.
		mat = (mat as ShaderMaterial).duplicate()
	if r.cls != "escudeiro" and mat is ShaderMaterial:
		# Cada pacote tem a sua textura: o material do herói (flash, brilho) fica com a textura certa.
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m0: Material = (mi as MeshInstance3D).get_active_material(0)
			if m0 is BaseMaterial3D and (m0 as BaseMaterial3D).albedo_texture:
				(mat as ShaderMaterial).set_shader_parameter("albedo_tex", (m0 as BaseMaterial3D).albedo_texture)
				(mat as ShaderMaterial).set_shader_parameter("use_tex", true)
				break
		if CLASS_TINT.has(r.cls):
			(mat as ShaderMaterial).set_shader_parameter("tint", CLASS_TINT[r.cls])
	r.set_meta("mat", mat)
	var hide: Array = CLASS_HIDE.get(r.cls, HIDE)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name) in hide:
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
	var h = hero_ref if hero_ref != null else view.sim.hero
	var spd: float = Vector2(h.x - h.ox, h.y - h.oy).length() / view.sim.dt
	if view.sim.waiting_choice():
		spd = 0.0   # parado esperando escolha: sem correr no lugar
	if h.petrify_t > 0.0 or h.root_t > 0.0:
		ap.speed_scale = 0.0 if h.petrify_t > 0.0 else 0.3
		return
	var atk: String = CLASS_ATTACK.get(cls, "1H_Melee_Attack_Slice_Diagonal")
	if hero_ref != null:
		# Seguidor (fase de grupo): o golpe é a recarga do ataque que recomeça.
		if h.atk_t > atk_seen + 0.05:
			cur = ""
			_play(atk, 0.05, 1.9)
		atk_seen = h.atk_t
		if cur == atk and ap.is_playing() and ap.current_animation_position < ap.current_animation_length * 0.8:
			return
	else:
		var sw: float = view.swing_t
		if sw > swing_seen + 0.01:
			# Golpe novo: recomeça a animação de ataque mesmo se já estava nela.
			cur = ""
			_play(atk, 0.05, 1.9)
		swing_seen = sw
		if sw > 0.0:
			return
	if h.shield_hp > 0.0 and spd < 0.4:
		_play("Blocking", 0.2)
	elif spd > (3.0 if cur == "Running_A" else 3.4):
		_play("Running_A", 0.2, clampf(spd / 5.0, 0.7, 1.5))
	elif spd > (0.25 if cur == "Walking_A" or cur == "Running_A" else 0.4):   # histerese: sem alternar a cada passo
		_play("Walking_A", 0.2, clampf(spd / 2.2, 0.6, 1.6))
	else:
		_play("Idle", 0.3)
