class_name Looks
extends RefCounted
## Variações de arte (looks 1..6) dos monstros e do herói. O look 0 é a arte antiga (Models).
## 1..4: malhas geradas por tools/art/build_models.py (Blender) e convertidas por tools/art/import_models.gd.
## 5: modelos CC0 (KayKit, Quaternius) convertidos por tools/art/import_cc0.gd, com animação em textura (VAT)
##    e herói com esqueleto (HeroRig). 6: modelos próprios refeitos (build_models.py --looks 6). Ver docs/ESTUDO_DE_ARTE.md.

const NAMES := ["Atual", "Argila", "Cartum", "Pintado", "Sombrio", "Aventura (CC0)", "Própria refinada"]
# Pasta de malhas de cada look (o padrão é assets/models/look<N>/).
const DIRS := {5: "cc0"}
# Shader de cada look (o padrão é game/art/look<N>.gdshader): o 6 divide a luz do 5.
const SHADER_OF := {6: 5}

static var _mesh: Dictionary = {}
static var _shader: Dictionary = {}
static var _empty: ArrayMesh
# Última malha de unidade pedida: unit_material() usa a animação (VAT) e a textura dela, porque quem chama
# (WorldView._build_units, CardArt) pede a malha e o material em seguida, sem repetir o id.
static var _last_unit := ""


static func enemies() -> int:
	return int(Settings.v.get("look_enemies", 0))


static func hero() -> int:
	return int(Settings.v.get("look_hero", 0))


## Malha do look (ou null se não existir: aí vale a arte antiga).
static func mesh(look: int, id: String) -> Mesh:
	var key := "%d/%s" % [look, id]
	if not _mesh.has(key):
		var p := "res://assets/models/%s/%s.res" % [DIRS.get(look, "look%d" % look), id]
		_mesh[key] = load(p) if ResourceLoader.exists(p) else null
	return _mesh[key]


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

static func unit_mesh(id: String) -> Mesh:
	var lk := enemies()
	var m := mesh(lk, id) if lk > 0 else null
	_last_unit = id if m else ""
	return m if m else Models.unit(id)


static func unit_material(emit: float, multimesh: bool, id := "") -> ShaderMaterial:
	if id == "":
		id = _last_unit
	var own := enemies()
	var src: Mesh = mesh(own, id) if own > 0 and id != "" else null
	var lk := GroundLooks.world_shader_look()
	if lk == 0 or (src and src.has_meta("vat")):
		# A malha animada por textura só anda com o shader que lê a textura: o do próprio look.
		lk = own
	return material(lk, emit, multimesh, src) if lk > 0 else Models.glow_material(emit)


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
	return m


## Herói com esqueleto do look escolhido (ou null: as peças de sempre).
static func hero_rig(mat: Material) -> HeroRig:
	var lk := hero()
	return HeroRig.make(lk, mat) if HeroRig.has_rig(lk) else null
