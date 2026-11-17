class_name Looks
extends RefCounted
## Variações de arte (looks 1..6) dos monstros e do herói. O look 0 é a arte antiga (Models).
## 1..4: malhas geradas por tools/art/build_models.py (Blender) e convertidas por tools/art/import_models.gd.
## 5: modelos CC0 (KayKit, Quaternius) convertidos por tools/art/import_cc0.gd, com animação em textura (VAT)
##    e herói com esqueleto (HeroRig). 6: modelos próprios refeitos (build_models.py --looks 6). Ver docs/ESTUDO_DE_ARTE.md.
## 7: monstros e estruturas refeitos no Blender (tools/art/blender_v2, import_v2.gd), com VAT como o 5. Ver docs/ARTE_BLENDER.md.

const NAMES := ["Atual", "Argila", "Cartum", "Pintado", "Sombrio", "Aventura (CC0)", "Própria refinada", "Blender v2"]
# Pasta de malhas de cada look (o padrão é assets/models/look<N>/).
const DIRS := {5: "cc0", 7: "v2"}
# Shader de cada look (o padrão é game/art/look<N>.gdshader): o 6 divide a luz do 5.
const SHADER_OF := {6: 5, 7: 5}

static var _mesh: Dictionary = {}
static var _shader: Dictionary = {}
static var _empty: ArrayMesh
# Última malha de unidade pedida: unit_material() usa a animação (VAT) e a textura dela, porque quem chama
# (WorldView._build_units, CardArt) pede a malha e o material em seguida, sem repetir o id.
static var _last_unit := ""
static var _last_card := ""

## Variantes (etapa D): carta -> modelo base do look 7 + escala + tinta (multiplica a cor do modelo).
## Só mudam o mapa; o desenho da carta é o png próprio (assets/cards/<id>.png).
const VARIANTS := {
	"rat_brute": {"base": "rat", "scale": 1.55, "tint": Color(0.82, 0.7, 0.6)},
	"bat_cloud": {"base": "bat", "scale": 0.8, "tint": Color(0.7, 0.85, 0.55)},
	"rat_trap": {"base": "bone_totem", "scale": 0.7, "tint": Color(1.0, 0.8, 0.55)},
	"brood_mother": {"base": "rat", "scale": 1.6, "tint": Color(1.0, 0.8, 0.85)},
	"corrupt_piper": {"base": "cultists", "scale": 0.95, "tint": Color(0.75, 1.0, 0.5)},
	"sewer_flood": {"base": "bat_nest", "scale": 0.6, "tint": Color(0.5, 0.95, 0.9)},
	"kobold_scavengers": {"base": "goblin_dynamiter", "scale": 0.7, "tint": Color(1.0, 0.65, 0.45)},
	"trap_chest": {"base": "mimic", "scale": 0.85, "tint": Color(1.0, 0.88, 0.45)},
	"furnace": {"base": "bone_totem", "scale": 1.25, "tint": Color(1.0, 0.5, 0.3)},
	"raised_servant": {"base": "skeleton", "scale": 1.15, "tint": Color(0.7, 0.9, 1.0)},
	"barricade": {"base": "gargoyle_tower", "scale": 0.5, "tint": Color(0.85, 0.65, 0.45)},
	"war_banner": {"base": "gargoyle_tower", "scale": 0.9, "tint": Color(1.0, 0.45, 0.4)},
	"rat_burrow": {"base": "bat_nest", "scale": 0.75, "tint": Color(0.85, 0.65, 0.5)},
	"ghoul": {"base": "werewolf", "scale": 0.8, "tint": Color(0.7, 0.95, 0.65)},
	"fire_imp": {"base": "bat", "scale": 1.0, "tint": Color(1.0, 0.45, 0.25)},
	# O modelo foi feito com 4,2 m (vitrine contra 2,3 m do Ogro): 0,71 o deixa com ~3 m, porte de criatura grande.
	"elder_dragon": {"base": "elder_dragon", "scale": 0.71, "tint": Color(1, 1, 1)},
}
# Modelo antigo (look 0 e looks sem a malha própria): o que essas cartas usavam emprestado.
const LEGACY := {
	"wolf_pack": "werewolf", "war_boar": "werewolf", "alpha_beast": "werewolf", "treasure_guard": "ogre",
	"elder_dragon": "bat", "cave_troll": "ogre", "death_knight": "ogre", "bone_colossus": "scrap_golem",
	"ruin_titan": "ogre", "rat_brute": "rat_horde", "bat_cloud": "bat_nest", "rat_trap": "bat_nest",
	"brood_mother": "rat_horde", "corrupt_piper": "rat_king", "sewer_flood": "bat_nest", "kobold_scavengers": "rat_horde",
	"trap_chest": "mimic", "furnace": "bone_totem", "raised_servant": "skeleton", "barricade": "gargoyle_tower",
	"war_banner": "gargoyle_tower", "rat_burrow": "bat_nest", "ghoul": "skeleton", "fire_imp": "bat",
	"ash_salamander": "ogre", "drakeling": "bat", "magma_golem": "scrap_golem", "ash_phoenix": "bat", "brown_bear": "ogre",
	"spitting_viper": "rat_horde", "bone_dragon": "bat",   # 17/11/2026: modelos próprios em g_n (creatures_new.py)
}


static func enemies() -> int:
	return int(Settings.v.get("look_enemies", 0))


static func hero() -> int:
	return int(Settings.v.get("look_hero", 0))


## Malha do look (ou null se não existir: aí vale a arte antiga).
static func mesh(look: int, id: String) -> Mesh:
	if look == 7 and g_on():
		var gm := g_mesh(id)
		if gm:
			return gm
	var key := "%d/%s" % [look, id]
	if not _mesh.has(key):
		var p := "res://assets/models/%s/%s.res" % [DIRS.get(look, "look%d" % look), id]
		_mesh[key] = load(p) if ResourceLoader.exists(p) else null
	return _mesh[key]


# ---------------------------------------------------------------- miniaturas pintadas (Settings "model_g")
# 1..7 = V1..V7: [geometria (n normal, c gorducha, f facetada), tratamento]. V1 = cor por vértice (controle).
const G_SETS := {1: ["n", "vc"], 2: ["n", "dabs"], 3: ["n", "wash"], 4: ["n", "dry"], 5: ["n", "flat"], 6: ["c", "dabs"], 7: ["f", "dabs"]}


const G_NAMES := ["Desligado (modelos v2)", "V1 · Cor por vértice", "V2 · Dabs", "V3 · Aguado", "V4 · Pincel seco",
	"V5 · Chapado + contorno", "V6 · Gordinha", "V7 · Facetada"]


static func g_on() -> bool:
	return int(Settings.v.get("model_g", 0)) > 0


## Malha da versão escolhida (ou null se o id não faz parte da amostra). Leva o atlas em meta "gtex".
static func g_mesh(id: String) -> Mesh:
	var sel: Array = G_SETS.get(int(Settings.v.get("model_g", 0)), [])
	if sel.is_empty():
		return null
	var key := "g/%d/%s" % [int(Settings.v.get("model_g", 0)), id]
	if _mesh.has(key):
		return _mesh[key]
	var geom: String = sel[0]
	var tex: String = sel[1]
	var sfx := "" if tex == "vc" else "_a"
	var p := "res://assets/models/g_%s%s/%s.res" % [geom, sfx, id]
	if not ResourceLoader.exists(p):
		geom = "n"
		p = "res://assets/models/g_n%s/%s.res" % [sfx, id]
	var m: Mesh = load(p) if ResourceLoader.exists(p) else null
	if m and tex != "vc":
		var tp := "res://assets/models/g_tex/%s_%s/%s.png" % [tex, geom, id]
		if m.has_meta("gtex") == false and ResourceLoader.exists(tp):
			m.set_meta("gtex", load(tp))
		m.set_meta("gink", 0.85 if tex == "flat" else 0.0)
	_mesh[key] = m
	return m


## Material de uma malha com atlas (a base, se não tiver: parâmetros como o vento ficam).
static func g_material(m: Mesh, base: Material = null) -> Material:
	if m == null or not m.has_meta("gtex"):
		return base
	var mat := material(5, 0.0, false, m)
	if base is ShaderMaterial and (base as ShaderMaterial).shader == mat.shader:
		for k in ["sway", "emission_boost"]:
			var pv = (base as ShaderMaterial).get_shader_parameter(k)
			if pv != null:
				mat.set_shader_parameter(k, pv)
	return mat


static func shader(look: int) -> Shader:
	if not _shader.has(look):
		_shader[look] = load("res://game/art/look%d.gdshader" % int(SHADER_OF.get(look, look)))
	return _shader[look]


## Material do look com os mesmos parâmetros do toon (emission_boost, flap, sway, flash).
## multimesh = true só para as MultiMesh (unidades): é quando o shader pode ler INSTANCE_CUSTOM.
## src = malha cuja textura e animação (VAT, look 5) o material deve usar.
static func material(look: int, emit := 0.0, multimesh := false, src: Mesh = null) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader(look)
	m.set_shader_parameter("emission_boost", emit)
	m.set_shader_parameter("multimesh", multimesh)
	if look == 2:
		var o := ShaderMaterial.new()
		o.shader = load("res://game/art/look2_outline.gdshader")
		o.set_shader_parameter("multimesh", multimesh)
		m.next_pass = o
	if src and src.has_meta("vat"):
		m.set_shader_parameter("use_vat", true)
		m.set_shader_parameter("vat", src.get_meta("vat"))
		m.set_shader_parameter("walk_frames", int(src.get_meta("walk", 0)))
		m.set_shader_parameter("atk_frames", int(src.get_meta("atk", 0)))
		m.set_shader_parameter("pose_frame", 0.3)
	if src and src.has_meta("tex"):
		m.set_shader_parameter("use_tex", true)
		m.set_shader_parameter("albedo_tex", src.get_meta("tex"))
	if src and src.has_meta("gtex"):
		m.set_shader_parameter("use_tex", true)
		m.set_shader_parameter("albedo_tex", src.get_meta("gtex"))
		m.set_shader_parameter("atlas", true)
		m.set_shader_parameter("ink", float(src.get_meta("gink", 0.0)))
	return m


## Repassa um parâmetro também para o contorno (look 2), que anima igual.
static func set_param(m: ShaderMaterial, k: String, val: Variant) -> void:
	m.set_shader_parameter(k, val)
	if k == "flap" and m.get_shader_parameter("use_vat"):
		# Com animação de verdade as asas já batem: o voador anima parado no mesmo ritmo de quando anda.
		m.set_shader_parameter("flap", 0.0)
		m.set_shader_parameter("idle_rate", 1.4)
		m.set_shader_parameter("walk_rate", 1.4)
	if m.next_pass is ShaderMaterial and k in ["flap", "sway", "hop_height", "multimesh"]:
		(m.next_pass as ShaderMaterial).set_shader_parameter(k, val)


# ---------------------------------------------------------------- atalhos usados pelo jogo

static func scale_of(id: String) -> float:
	return float(VARIANTS[id]["scale"]) if VARIANTS.has(id) and enemies() > 0 else 1.0


static func unit_mesh(id: String) -> Mesh:
	_last_card = id
	var legacy: String = LEGACY.get(id, id)
	id = CardModel.of(id)
	var lk := enemies()
	var base: String = VARIANTS[id]["base"] if VARIANTS.has(id) else id
	var m := mesh(lk, base) if lk > 0 else null
	_last_unit = base if m else ""
	return m if m else Models.unit(CardModel.of(legacy) if legacy != id else id)


static func unit_material(emit: float, multimesh: bool, id := "") -> ShaderMaterial:
	var card := id if id != "" else _last_card
	if id != "":
		id = VARIANTS[id]["base"] if VARIANTS.has(id) else CardModel.of(id)
	if id == "":
		id = _last_unit
	var own := enemies()
	var src: Mesh = mesh(own, id) if own > 0 and id != "" else null
	var lk := GroundLooks.world_shader_look()
	if lk == 0 or (src and src.has_meta("vat")):
		# A malha animada por textura só anda com o shader que lê a textura: o do próprio look.
		lk = own
	if lk <= 0:
		return Models.glow_material(emit)
	var mat := material(lk, emit, multimesh, src)
	if VARIANTS.has(card) and src:
		mat.set_shader_parameter("tint", VARIANTS[card]["tint"])
	return mat


static func hero_mesh(part: String) -> Mesh:
	var lk := hero()
	if HeroRig.has_rig(lk):
		# O corpo é o HeroRig; as peças antigas ficam como pivôs vazios (a animação do WorldView gira o nada).
		if _empty == null:
			_empty = ArrayMesh.new()
		return _empty
	var m := mesh(lk, "hero_" + part) if lk > 0 else null
	return m if m else Models.hero_part(part)


## Na direção de arte única o herói usa o shader dela, com o desenho (malha) do look escolhido.
static func hero_material(emit: float) -> ShaderMaterial:
	var own := hero()
	var lk := GroundLooks.world_shader_look()
	if lk == 0 or HeroRig.has_rig(own):
		lk = own
	var m := material(lk, emit) if lk > 0 else Models.glow_material(emit)
	if HeroRig.has_rig(own):
		var t := HeroRig.texture(own)
		if t:
			m.set_shader_parameter("use_tex", true)
			m.set_shader_parameter("albedo_tex", t)
	# Mundo pintado: aço azulado do cavaleiro das cartas (o modelo KayKit é quase branco e some no guache claro).
	if int(Settings.v.get("paint_look", 0)) > 0:
		m.set_shader_parameter("tint", Color(0.66, 0.72, 0.86))
	return m


## Herói com esqueleto do look escolhido (ou null: as peças de sempre).
static func hero_rig(mat: Material, cls := "escudeiro") -> HeroRig:
	var lk := hero()
	if not HeroRig.has_rig(lk):
		return null
	# Heróis: o jogador preferiu o modelo antigo (KayKit) ao refeito em guache (15/11); todas as classes usam o HeroRig.
	# O HeroVat e os modelos g_*/escudeiro etc. continuam no repositório, desligados.
	return HeroRig.make(lk, mat, cls)
