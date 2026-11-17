class_name Settings
extends RefCounted
## Configurações do jogador (user://settings.cfg). Estado estático: o visual lê `Settings.v` direto.

const PATH := "user://settings.cfg"
const FPS_CAPS := [0, 30, 60, 120, 144, 240]

## 1: direção D vira o padrão (09/11/2026). 2: a interface Diário (papel e fita) vira a padrão.
## 4: o mundo pintado em guache S1 (guache chapado) vira o padrão (13/11/2026).
## 5: a interface "Mapa aberto" (look_hud 7) vira a padrão (13/11/2026).
## 6: as miniaturas pintadas em pincel seco (model_g 4, docs/MODELOS_GUACHE.md) viram o padrão (15/11/2026).
const ART_REV := 8

static var v := defaults()
# Chaves trocadas só nesta execução (--set=...), com o valor que estava salvo: save() grava o salvo, não o da execução.
static var session := {}


static func defaults() -> Dictionary:
	return {
		"master": 0.8, "music": 0.7, "sfx": 0.8,
		"fullscreen": false, "vsync": true, "max_fps": 0, "quality": 2, "ui_scale": 1.0,
		"language": "pt",
		"shake": 1.0, "flash": true, "damage_numbers": true, "hints": true,
		"card_fx_variant": 4,   # visual dos upgrades de carta: 0 = o de hoje, 1-4 = propostas (a 4 é a escolhida) (game/card_fx_variants.gd)
		"show_help": true, "show_fps": false, "pad_speed": 1.0,
		# Variações de arte. Padrão = direção D, "Aventura, dia" (escolhida em 09/11/2026, docs/ESTUDO_DE_ARTE.md):
		# chão 7, herói e monstros 5 (modelos CC0 KayKit/Quaternius, luz estilo RoR2). Na HUD, 6 = Diário, 0 = Covil, 5 = a antiga.
		# Desde a rodada autônoma de 09/11/2026 o padrão é a direção G · Blender v2 (monstros, chefe e cenário
		# do Blender, heróis KayKit; docs/ARTE_BLENDER.md). A D continua em Configurações → Visual.
		# HUD 7 = "Mapa aberto" (13/11/2026, docs/UI_PROPOSTAS.md); 6 = Diário continua em Configurações.
		"look_hud": 7, "look_ground": 10, "look_hero": 5, "look_enemies": 7,
		# Mundo pintado em guache nos materiais (13/11/2026, docs/MUNDO_PINTADO.md): 0 = desligado, 1..9 = variações
		# S1-S3, T1-T3, C1-C3 (game/art/paint_look.gd). Escolhida pelo designer em 13/11: S1, guache chapado.
		"paint_look": 1,
		# Mundo como as cartas (15/11/2026, docs/MUNDO_COMO_CARTAS.md): A cor, B escuros, C papel; F6/F7/F8 no jogo.
		"mundo_cor": false, "mundo_escuro": true, "mundo_papel": false,
		# Miniaturas pintadas (15/11/2026, docs/MODELOS_GUACHE.md): 0 = desligado, 1..7 = versões V1..V7.
		"model_g": 4,
		# Versão do padrão de arte: quando sobe, quem já tinha configuração salva recebe a direção nova uma vez.
		"art_rev": ART_REV,
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
	# Configuração salva antes da direção nova: troca o visual uma vez (o resto do que a pessoa escolheu fica).
	var rev := int(cf.get_value("s", "art_rev", 0))
	if rev < ART_REV:
		var d := defaults()
		var keys: Array = ["look_hud"]
		if rev < 3:
			keys += ["look_ground", "look_hero", "look_enemies"]
		if rev < 4:
			keys += ["paint_look"]
		if rev < 6:
			keys += ["model_g"]
		if rev < 7:
			keys += ["mundo_cor"]  # 17/11/2026: ele prefere a cor viva (A desligada)
		if rev < 8:
			keys += ["mundo_escuro", "mundo_papel"]  # 17/11/2026: F7 ligado, F8 (grão) desligado
		for k in keys:
			v[k] = d[k]
		v["art_rev"] = ART_REV
		save()


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
	var factor := clampf(float(v["ui_scale"]), 0.8, 1.15)
	var headless := DisplayServer.get_name() == "headless"
	if not is_equal_approx(tree.root.content_scale_factor, factor):
		# Mudar a escala da interface não pode redimensionar a janela (17/11): guarda o tamanho e devolve depois.
		var windowed := not headless and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
		var keep := DisplayServer.window_get_size() if windowed else Vector2i.ZERO
		tree.root.content_scale_factor = factor
		if windowed and not Settings.v["fullscreen"]:
			var restore := func():
				if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED \
						and DisplayServer.window_get_size() != keep:
					DisplayServer.window_set_size(keep)
			restore.call()
			tree.process_frame.connect(restore, CONNECT_ONE_SHOT)
	if headless:
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
	# Sombra pontilhada (15/11): o filtro suave do sol usa poucas amostras com ruído e, sem TAA, a borda vira pontos.
	# Mais amostras na qualidade alta; a penumbra por ângulo (PCSS) saiu dos chãos (ground_looks.gd).
	RenderingServer.directional_soft_shadow_filter_set_quality(
		RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM if q >= 2 else RenderingServer.SHADOW_QUALITY_SOFT_LOW)


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
