class_name Looks
extends RefCounted
## Modelos e materiais das unidades, do cenário e dos heróis. Ordem de procura de uma malha de monstro/estrutura:
##  1. modelo refeito à mão (21/11/2026): assets/models/m2_a/<id>.res + atlas assets/models/g_tex/m2/<id>.png;
##  2. miniatura pintada em pincel seco (15/11/2026): assets/models/g_n_a/<id>.res + atlas g_tex/dry_n/<id>.png;
##  3. Blender v2 (look 7): assets/models/v2/<id>.res, com animação em textura (VAT);
##  4. a peça procedural antiga de Models.
## Heróis: modelos CC0 KayKit (look 5, assets/models/cc0) com esqueleto (HeroRig).
## Tudo usa o shader game/art/look5.gdshader (lê VAT e atlas).

## Look dos heróis (5 = CC0 KayKit) e dos monstros (7 = Blender v2).
const HERO_LOOK := 5
const ENEMY_LOOK := 7
# Pasta de malhas de cada look.
const DIRS := {5: "cc0", 7: "v2"}
const SHADER := preload("res://game/art/look5.gdshader")

static var _mesh: Dictionary = {}
## Modelos refeitos à mão (tools/art/blender_m2 e afins) passam na frente.
## Formato esperado em assets/models/m2_a/<id>.res: ArrayMesh gravado pelo tools/art/import_g.gd na variante "_a"
## (o mesmo dos g_n_a: vértices brancos com alfa = 1 - brilho, UV = atlas, UV2.x = índice do vértice; se animada,
## metas "vat" (ImageTexture RGBAH: posição e normal por quadro), "walk" e "atk", como o vat_g.export grava).
## Atlas em assets/models/g_tex/m2/<id>.png. <id> = id da carta (unidades e estruturas: unit_mesh) ou da peça
## (cenário: Models.prop). Altura, origem e frente iguais às do g_n_a; sem a tinta e a escala do VARIANTS.
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
	return ENEMY_LOOK


static func hero() -> int:
	return HERO_LOOK


## Malha do look (ou null se não existir: aí vale a arte antiga).
static func mesh(look: int, id: String) -> Mesh:
	if look == ENEMY_LOOK:
		var gm := g_mesh(id)
		if gm:
			return gm
	var key := "%d/%s" % [look, id]
	if not _mesh.has(key):
		var p := "res://assets/models/%s/%s.res" % [DIRS[look], id]
		_mesh[key] = load(p) if ResourceLoader.exists(p) else null
	return _mesh[key]


## Malha refeita à mão (ou null). Leva o atlas em meta "gtex" (Looks.material liga o atlas).
static func m2_mesh(id: String) -> Mesh:
	if id == "":
		return null
	var key := "m2/" + id
	if _mesh.has(key):
		return _mesh[key]
	var p := "res://assets/models/m2_a/%s.res" % id
	var m: Mesh = load(p) if ResourceLoader.exists(p) else null
	if m:
		var tp := "res://assets/models/g_tex/m2/%s.png" % id
		if not m.has_meta("gtex") and ResourceLoader.exists(tp):
			m.set_meta("gtex", atlas_tex(tp))
		m.set_meta("gink", 0.0)
	_mesh[key] = m
	return m


## Id refeito (m2) da carta: o dela, senão o do modelo que ela usa (CardModel); "" se não houver.
static func m2_unit_id(card: String) -> String:
	if m2_mesh(card):
		return card
	var base := CardModel.of(card)
	return base if base != card and m2_mesh(base) else ""


# ---------------------------------------------------------------- miniaturas pintadas em pincel seco (15/11/2026)

## Miniatura pintada do id (ou null se o id não faz parte do conjunto). Leva o atlas em meta "gtex".
static func g_mesh(id: String) -> Mesh:
	var key := "g/" + id
	if _mesh.has(key):
		return _mesh[key]
	var p := "res://assets/models/g_n_a/%s.res" % id
	var m: Mesh = load(p) if ResourceLoader.exists(p) else null
	if m:
		var tp := "res://assets/models/g_tex/dry_n/%s.png" % id
		if m.has_meta("gtex") == false and ResourceLoader.exists(tp):
			m.set_meta("gtex", atlas_tex(tp))
		m.set_meta("gink", 0.0)
	_mesh[key] = m
	return m


## Atlas pintado com mipmaps (versões D e E, 26/11/2026): o look5 lê o atlas num mipmap borrado (atlas_lod) para
## tirar as manchas de pincel da textura. Os .png vêm importados sem mipmap, então eles são gerados aqui.
static func atlas_tex(path: String) -> Texture2D:
	var t: Texture2D = load(path)
	var img := t.get_image() if t else null
	if img == null:
		return t
	if img.is_compressed():
		img.decompress()
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Material de uma malha com atlas (a base, se não tiver: parâmetros como o vento ficam).
static func g_material(m: Mesh, base: Material = null) -> Material:
	if m == null or not m.has_meta("gtex"):
		return base
	var mat := material(5, 0.0, false, m)
	if base is ShaderMaterial and (base as ShaderMaterial).shader == mat.shader:
		for k in ["sway", "emission_boost", "wind_amt"]:
			var pv = (base as ShaderMaterial).get_shader_parameter(k)
			if pv != null:
				mat.set_shader_parameter(k, pv)
	return mat


## Material do look com os mesmos parâmetros do toon (emission_boost, flap, sway, flash).
## multimesh = true só para as MultiMesh (unidades): é quando o shader pode ler INSTANCE_CUSTOM.
## src = malha cuja textura e animação (VAT, look 5) o material deve usar.
static func material(look: int, emit := 0.0, multimesh := false, src: Mesh = null) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("emission_boost", emit)
	m.set_shader_parameter("multimesh", multimesh)
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


## Põe um parâmetro do material (com o ajuste do voo para malhas animadas).
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
	if m2_unit_id(id) != "" or Diorama.unit_id(id) != "":
		return 1.0
	return float(VARIANTS[id]["scale"]) if VARIANTS.has(id) and enemies() > 0 else 1.0


static func unit_mesh(id: String) -> Mesh:
	_last_card = id
	var dio := Diorama.unit_id(id)
	if dio != "":
		_last_unit = "dio:" + dio
		return Diorama.mesh(dio)
	var m2 := m2_unit_id(id)
	if m2 != "":
		_last_unit = "m2:" + m2
		return m2_mesh(m2)
	var legacy: String = LEGACY.get(id, id)
	id = CardModel.of(id)
	var lk := enemies()
	var base: String = VARIANTS[id]["base"] if VARIANTS.has(id) else id
	var m := mesh(lk, base) if lk > 0 else null
	_last_unit = base if m else ""
	return m if m else Models.unit(CardModel.of(legacy) if legacy != id else id)


static func unit_material(emit: float, multimesh: bool, id := "") -> ShaderMaterial:
	var card := id if id != "" else _last_card
	var dio := Diorama.unit_id(card) if id != "" else (_last_unit.trim_prefix("dio:") if _last_unit.begins_with("dio:") else "")
	if dio != "":
		return material(7, emit, multimesh, Diorama.mesh(dio))
	var m2 := m2_unit_id(card) if id != "" else (_last_unit.trim_prefix("m2:") if _last_unit.begins_with("m2:") else "")
	if m2 != "":
		# Modelo refeito: shader do look 7 (lê VAT e atlas), sem a tinta do VARIANTS.
		var src2 := m2_mesh(m2)
		var lk2 := GroundLooks.world_shader_look()
		if lk2 == 0 or src2.has_meta("vat"):
			lk2 = 7
		return material(lk2, emit, multimesh, src2)
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
	if HeroRig.has_rig(own) and not ResourceLoader.exists(Diorama.HERO_SCENE):
		var t := HeroRig.texture(own)
		if t:
			m.set_shader_parameter("use_tex", true)
			m.set_shader_parameter("albedo_tex", t)
	# Mundo pintado: aço azulado do cavaleiro das cartas (o modelo KayKit é quase branco e some no guache claro).
	m.set_shader_parameter("tint", Diorama.HERO_TINT)
	return m


## Herói com esqueleto do look escolhido (ou null: as peças de sempre).
static func hero_rig(mat: Material, cls := "escudeiro") -> HeroRig:
	var lk := hero()
	if not HeroRig.has_rig(lk):
		return null
	# Heróis: o jogador preferiu o modelo antigo (KayKit) ao refeito em guache (15/11); todas as classes usam o HeroRig.
	return HeroRig.make(lk, mat, cls)
