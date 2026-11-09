class_name Looks
extends RefCounted
## Variações de arte (looks 1..4) dos monstros e do herói. O look 0 é a arte antiga (Models).
## Malhas geradas por tools/art/build_models.py (Blender) e convertidas por tools/art/import_models.gd.

const NAMES := ["Atual", "Argila", "Cartum", "Pintado", "Sombrio"]

static var _mesh: Dictionary = {}
static var _shader: Dictionary = {}


static func enemies() -> int:
	return int(Settings.v.get("look_enemies", 0))


static func hero() -> int:
	return int(Settings.v.get("look_hero", 0))


## Malha do look (ou null se não existir: aí vale a arte antiga).
static func mesh(look: int, id: String) -> Mesh:
	var key := "%d/%s" % [look, id]
	if not _mesh.has(key):
		var p := "res://assets/models/look%d/%s.res" % [look, id]
		_mesh[key] = load(p) if ResourceLoader.exists(p) else null
	return _mesh[key]


static func shader(look: int) -> Shader:
	if not _shader.has(look):
		_shader[look] = load("res://game/art/look%d.gdshader" % look)
	return _shader[look]


## Material do look com os mesmos parâmetros do toon (emission_boost, flap, sway, flash).
## multimesh = true só para as MultiMesh (unidades): é quando o shader pode ler INSTANCE_CUSTOM.
static func material(look: int, emit := 0.0, multimesh := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader(look)
	m.set_shader_parameter("emission_boost", emit)
	m.set_shader_parameter("multimesh", multimesh)
	if look == 2:
		var o := ShaderMaterial.new()
		o.shader = load("res://game/art/look2_outline.gdshader")
		o.set_shader_parameter("multimesh", multimesh)
		m.next_pass = o
	return m


## Repassa um parâmetro também para o contorno (look 2), que anima igual.
static func set_param(m: ShaderMaterial, k: String, val: Variant) -> void:
	m.set_shader_parameter(k, val)
	if m.next_pass is ShaderMaterial and k in ["flap", "sway", "hop_height", "multimesh"]:
		(m.next_pass as ShaderMaterial).set_shader_parameter(k, val)


# ---------------------------------------------------------------- atalhos usados pelo jogo

static func unit_mesh(id: String) -> Mesh:
	var lk := enemies()
	var m := mesh(lk, id) if lk > 0 else null
	return m if m else Models.unit(id)


static func unit_material(emit: float, multimesh: bool) -> ShaderMaterial:
	var lk := GroundLooks.world_shader_look()
	if lk == 0:
		lk = enemies()
	return material(lk, emit, multimesh) if lk > 0 else Models.glow_material(emit)


static func hero_mesh(part: String) -> Mesh:
	var lk := hero()
	var m := mesh(lk, "hero_" + part) if lk > 0 else null
	return m if m else Models.hero_part(part)


## Na direção de arte única o herói usa o shader dela, com o desenho (malha) do look escolhido.
static func hero_material(emit: float) -> ShaderMaterial:
	var lk := GroundLooks.world_shader_look()
	if lk == 0:
		lk = hero()
	return material(lk, emit) if lk > 0 else Models.glow_material(emit)
