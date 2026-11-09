class_name Settings
extends RefCounted
## Configurações do jogador (user://settings.cfg). Estado estático: o visual lê `Settings.v` direto.

const PATH := "user://settings.cfg"
const FPS_CAPS := [0, 30, 60, 120, 144, 240]

static var v := defaults()
# Chaves trocadas só nesta execução (--set=...), com o valor que estava salvo: save() grava o salvo, não o da execução.
static var session := {}


static func defaults() -> Dictionary:
	return {
		"master": 0.8, "music": 0.7, "sfx": 0.8,
		"fullscreen": false, "vsync": true, "max_fps": 0, "quality": 2, "ui_scale": 1.0,
		"language": "pt",
		"shake": 1.0, "flash": true, "damage_numbers": true, "hints": true,
		"show_help": true, "show_fps": false, "pad_speed": 1.0,
		# Variações de arte (0 = a antiga; 1..4 = as novas). Padrão = a escolha de 07/11/2026: Bosque enluarado,
		# herói Sombrio, monstros Pintado. Na HUD, 0 = Covil (08/11/2026, docs/REVISAO_VISUAL.md) e 5 = a antiga.
		"look_hud": 0, "look_ground": 2, "look_hero": 4, "look_enemies": 3,
	}


static func load_all() -> void:
	v = defaults()
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for k in v:
		if cf.has_section_key("s", k):
			var x = cf.get_value("s", k)
			if typeof(x) == typeof(v[k]) or (typeof(v[k]) == TYPE_FLOAT and typeof(x) == TYPE_INT):
				v[k] = x


static func save() -> void:
	var cf := ConfigFile.new()
	for k in v:
		cf.set_value("s", k, session[k] if session.has(k) else v[k])
	cf.save(PATH)


## Aplica o que não é lido ao vivo: áudio, janela, escala da interface, idioma.
static func apply(tree: SceneTree) -> void:
	_bus("Music")
	_bus("SFX")
	_vol("Master", v["master"])
	_vol("Music", v["music"])
	_vol("SFX", v["sfx"])
	TranslationServer.set_locale(v["language"])
	Engine.max_fps = int(v["max_fps"])
	tree.root.content_scale_factor = clampf(float(v["ui_scale"]), 0.8, 1.15)
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if v["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v["vsync"] else DisplayServer.VSYNC_DISABLED)


## Qualidade gráfica: 0 baixa, 1 média, 2 alta.
static func apply_quality(env: Environment, sun: DirectionalLight3D, vp: Viewport) -> void:
	var q := int(v["quality"])
	env.ssao_enabled = q >= 2
	env.volumetric_fog_enabled = q >= 1
	env.glow_enabled = q >= 1
	sun.shadow_enabled = q >= 1
	vp.msaa_3d = Viewport.MSAA_2X if q >= 2 else Viewport.MSAA_DISABLED


static func _bus(name: String) -> void:
	if AudioServer.get_bus_index(name) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, name)
	AudioServer.set_bus_send(i, "Master")


static func _vol(bus: String, lin: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(i, lin <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(lin, 0.001)))
