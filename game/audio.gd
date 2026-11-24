class_name GameAudio
extends Node
## Áudio do jogo, todo CC0 (autores e links em assets/audio/LICENSES.txt).
## Efeitos com pool e recarga por som (centenas de unidades não viram ruído), jingles nos avisos grandes,
## música por contexto com troca suave (dois players) e som ambiente leve em loop.

const DIR := "res://assets/audio/"

## id → arquivos (sem .ogg; uma variação é sorteada a cada toque), volume em dB, recarga em s e se é jingle
## (jingle toca nos players próprios e não é cortado por golpes). Os ids antigos continuam valendo.
const SFX := {
	"card_play": {"f": ["sfx_card_1", "sfx_card_2", "sfx_card_3", "sfx_card_4"], "db": -3.0, "cd": 0.05},
	"spell": {"f": ["sfx_spell_1", "sfx_spell_2", "sfx_spell_3"], "db": -6.0, "cd": 0.08},
	"spell_fire": {"f": ["sfx_spell_fire_1", "sfx_spell_fire_2"], "db": -6.0, "cd": 0.08},
	"spell_dark": {"f": ["sfx_spell_dark_1", "sfx_spell_dark_2"], "db": -6.0, "cd": 0.08},
	"hit": {"f": ["sfx_hit_flesh_1", "sfx_hit_flesh_2", "sfx_hit_flesh_3"], "db": -13.0, "cd": 0.07},
	"hit_hard": {"f": ["sfx_hit_hard_1", "sfx_hit_hard_2"], "db": -13.0, "cd": 0.07},
	"hero_hit": {"f": ["sfx_hero_hit_1", "sfx_hero_hit_2", "sfx_hero_hit_3"], "db": -12.0, "cd": 0.09},
	"boss_hit": {"f": ["sfx_boss_hit_1", "sfx_boss_hit_2"], "db": -9.0, "cd": 0.1},
	"shield_break": {"f": ["sfx_shield_break"], "db": -6.0, "cd": 0.15},
	"explosion": {"f": ["sfx_explosion_1", "sfx_explosion_2", "sfx_explosion_3"], "db": -6.0, "cd": 0.06},
	"death": {"f": ["sfx_death_1", "sfx_death_2", "sfx_death_3"], "db": -13.0, "cd": 0.06},
	"death_bone": {"f": ["sfx_death_bone_1", "sfx_death_bone_2"], "db": -12.0, "cd": 0.06},
	"death_stone": {"f": ["sfx_death_stone"], "db": -9.0, "cd": 0.1},
	"hero_fall": {"f": ["sfx_hero_fall"], "db": -5.0, "cd": 0.2},
	"part_destroyed": {"f": ["sfx_impact_heavy"], "db": -5.0, "cd": 0.12},
	"teleport": {"f": ["sfx_teleport"], "db": -6.0, "cd": 0.2},
	"relic": {"f": ["sfx_relic"], "db": -6.0, "cd": 0.2},
	"heal": {"f": ["sfx_heal"], "db": -13.0, "cd": 0.6},
	"curse": {"f": ["sfx_spell_dark_2"], "db": -11.0, "cd": 0.5},
	"fear": {"f": ["sfx_fear"], "db": -9.0, "cd": 0.8},
	"ability_tell": {"f": ["sfx_ability_tell"], "db": -6.0, "cd": 0.3},
	"ui_click": {"f": ["sfx_ui_click_1", "sfx_ui_click_2"], "db": -12.0, "cd": 0.03},
	# Jingles: avisos grandes (disputa, ato, arena), nível, recompensa.
	"contest_start": {"f": ["jingle_contest_start"], "db": -7.0, "cd": 0.3, "j": true},
	"contest_mark": {"f": ["jingle_mark"], "db": -7.0, "cd": 0.2, "j": true},
	"contest_won": {"f": ["jingle_won"], "db": -5.0, "cd": 0.3, "j": true},
	"contest_partial": {"f": ["jingle_partial"], "db": -6.0, "cd": 0.3, "j": true},
	"contest_lost": {"f": ["jingle_lost"], "db": -6.0, "cd": 0.3, "j": true},
	"act_start": {"f": ["jingle_act_start"], "db": -6.0, "cd": 0.5, "j": true},
	"act_end": {"f": ["jingle_act_end"], "db": -6.0, "cd": 0.5, "j": true},
	"arena": {"f": ["jingle_arena"], "db": -5.0, "cd": 1.0, "j": true},
	"level_hero": {"f": ["jingle_level_hero"], "db": -7.0, "cd": 0.3, "j": true},
	"level_player": {"f": ["jingle_level_player"], "db": -8.0, "cd": 0.08},   # curto: aguenta a escadinha de tons da oferta
	"reward": {"f": ["jingle_reward"], "db": -7.0, "cd": 0.2, "j": true},
	"victory": {"f": ["jingle_won"], "db": -5.0, "cd": 0.5, "j": true},
	"defeat": {"f": ["jingle_defeat"], "db": -5.0, "cd": 0.5, "j": true},
}

## Músicas: nome → [arquivo, em loop]. Vitória e derrota tocam uma vez.
const MUSIC := {
	"music_menu": ["music_menu", true],
	"music_road": ["music_road", true],
	"music_road_plague": ["music_road_plague", true],
	"music_road_dragon": ["music_road_dragon", true],
	"music_road_lich": ["music_road_lich", true],
	"music_arena": ["music_arena", true],
	"music_victory": ["music_victory", false],
	"music_defeat": ["music_defeat", false],
}
const ROAD_BY_DECK := {"plague": "music_road_plague", "dragon": "music_road_dragon", "lich": "music_road_lich"}
## Ambiente da estrada por fase da campanha: 0 Fazenda, 1 Vila, 2 Floresta, 3 Mosteiro, 4 Forte, 5 Torre, 6 Capital.
const AMB_BY_PHASE := ["amb_field", "amb_village", "amb_river", "amb_wind", "amb_wind", "amb_wind", "amb_village"]
const AMB_ARENA := "amb_dungeon"

const MUSIC_DB := -6.0       # as músicas estão em ~-16 LUFS
## Ajuste fino por faixa (dB): estas ficaram ~2 dB abaixo do alvo porque o pico limitou o ganho na conversão.
const MUSIC_TRIM := {"music_menu": 2.0, "music_road_lich": 1.5}
const AMB_DB := -13.0        # os ambientes estão em ~-20 LUFS: bem baixo, por baixo da música
const AMB_TRIM := {"amb_wind": 6.0, "amb_dungeon": 4.0}   # vento e masmorra ficaram em ~-28 e ~-26 LUFS
const FADE := 1.6            # troca de música e de ambiente (s, tempo real)
const RESULT_FADE := 0.7
const MAX_PER_FRAME := 8     # efeitos novos por quadro (jingles não contam)
## Estrada: a trilha começa abafada e mais baixa e abre conforme o herói anda. main.gd passa no máximo 0.6
## antes da estrada fechar, então 0.6 já é quase tudo aberto.
const ROAD_OPEN_AT := 0.6
const CUT_CLOSED := 2200.0
const CUT_OPEN := 20000.0
const ROAD_QUIET_DB := -5.0

var streams: Dictionary = {}     # id → Array[AudioStream]
var pool: Array = []
var pool_i := 0
var last: Dictionary = {}
var frame_plays := 0
var jingles: Array = []        # 3 players só de jingle: um aviso não corta o outro
var jingle_i := 0
var mus: Fader
var amb: Fader
var current_music := ""
var current_amb := ""
var road_mode := false
var intensity := 0.0
var road_db := 0.0             # ajuste de volume da estrada, suavizado (não pula ao trocar de faixa)
var cutoff := CUT_OPEN
var lowpass: AudioEffectLowPassFilter
var lowpass_bus := -1
var lowpass_slot := -1
var t_prev := 0
var warned: Dictionary = {}


## Dois players que trocam de faixa com crossfade (ganho linear de amplitude, tempo real).
class Fader:
	var players: Array = []
	var gain: Array = [0.0, 0.0]
	var target: Array = [0.0, 0.0]
	var level: Array = [0.0, 0.0]
	var cur := 0
	var fade := 1.5

	func _init(parent: Node, bus: String) -> void:
		for i in 2:
			var p := AudioStreamPlayer.new()
			p.bus = bus
			p.volume_db = -80.0
			parent.add_child(p)
			players.append(p)

	func to(stream: AudioStream, db: float, t: float) -> void:
		fade = maxf(t, 0.05)
		target[cur] = 0.0
		if stream == null:
			return
		cur = 1 - cur
		var p: AudioStreamPlayer = players[cur]
		p.stream = stream
		gain[cur] = 0.0
		target[cur] = 1.0
		level[cur] = db
		p.volume_db = -80.0
		p.play()

	func step(dt: float, extra_db: float) -> void:
		for i in 2:
			gain[i] = move_toward(gain[i], target[i], dt / fade)
			var p: AudioStreamPlayer = players[i]
			if gain[i] <= 0.0 and target[i] <= 0.0:
				if p.playing:
					p.stop()
				continue
			p.volume_db = level[i] + extra_db + linear_to_db(maxf(gain[i], 0.0001))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in SFX:
		var list: Array = []
		for f in SFX[id]["f"]:
			var s := _load(DIR + f + ".ogg")
			if s:
				list.append(s)
		if list.is_empty():
			var old := _load(DIR + id + ".wav")   # reserva: o efeito sintetizado antigo
			if old:
				list.append(old)
		streams[id] = list
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		pool.append(p)
	for i in 3:
		var j := AudioStreamPlayer.new()
		j.bus = "SFX"
		add_child(j)
		jingles.append(j)
	mus = Fader.new(self, "Music")
	amb = Fader.new(self, "SFX")
	_setup_lowpass()
	t_prev = Time.get_ticks_usec()


func _load(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


## Filtro passa-baixa no ônibus Music (idempotente). O volume do ônibus é das Configurações; aqui só o corte.
func _setup_lowpass() -> void:
	var b := AudioServer.get_bus_index("Music")
	if b < 0:
		return
	for i in AudioServer.get_bus_effect_count(b):
		var e := AudioServer.get_bus_effect(b, i)
		if e is AudioEffectLowPassFilter:
			lowpass = e as AudioEffectLowPassFilter
			lowpass_slot = i
	if lowpass == null:
		lowpass = AudioEffectLowPassFilter.new()
		lowpass.db = AudioEffectFilter.FILTER_12DB
		AudioServer.add_bus_effect(b, lowpass)
		lowpass_slot = AudioServer.get_bus_effect_count(b) - 1
	lowpass_bus = b
	lowpass.cutoff_hz = CUT_OPEN
	AudioServer.set_bus_effect_enabled(b, lowpass_slot, false)


func play(id: String, pitch_var := 0.08, pitch := 1.0) -> void:
	var e: Dictionary = SFX.get(id, {})
	var list: Array = streams.get(id, [])
	if e.is_empty() or list.is_empty():
		return
	var jingle: bool = e.get("j", false)
	if not jingle and frame_plays >= MAX_PER_FRAME:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(last.get(id, -10.0)) < float(e["cd"]):
		return
	last[id] = now
	var p: AudioStreamPlayer = _free_jingle() if jingle else _free_player()
	if not jingle:
		frame_plays += 1
	p.stream = list[randi() % list.size()]
	p.volume_db = float(e["db"])
	p.pitch_scale = maxf(0.05, pitch * randf_range(1.0 - pitch_var, 1.0 + pitch_var))
	p.play()


## Um player livre; se todos tocam, o mais antigo da roda é cortado.
func _free_player() -> AudioStreamPlayer:
	for k in pool.size():
		var p: AudioStreamPlayer = pool[(pool_i + k) % pool.size()]
		if not p.playing:
			pool_i = (pool_i + k + 1) % pool.size()
			return p
	var q: AudioStreamPlayer = pool[pool_i]
	pool_i = (pool_i + 1) % pool.size()
	return q


## Um player de jingle livre; se os três tocam, corta o mais antigo.
func _free_jingle() -> AudioStreamPlayer:
	for k in jingles.size():
		var p: AudioStreamPlayer = jingles[(jingle_i + k) % jingles.size()]
		if not p.playing:
			jingle_i = (jingle_i + k + 1) % jingles.size()
			return p
	var q: AudioStreamPlayer = jingles[jingle_i]
	jingle_i = (jingle_i + 1) % jingles.size()
	return q


## Troca a música com crossfade. "" para tudo. Nomes em MUSIC ("music_road" é a trilha de reserva da estrada).
func music(name: String, fade := FADE) -> void:
	if current_music == name:
		return
	current_music = name
	road_mode = name.begins_with("music_road")
	if name == "":
		mus.to(null, 0.0, fade)
		return
	var st := _music_stream(name)
	if st == null:
		_warn("música sem arquivo: " + name)
	mus.to(st, MUSIC_DB + float(MUSIC_TRIM.get(name, 0.0)), fade)


func _music_stream(name: String) -> AudioStream:
	var m: Array = MUSIC.get(name, [name, true])
	var s := _load(DIR + str(m[0]) + ".ogg")
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = bool(m[1])
		return s
	# Reserva: a trilha sintetizada antiga (só existe para music_road e music_arena).
	var w := _load(DIR + name + "_base.wav") as AudioStreamWAV
	if w:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = w.data.size() / 4 if w.stereo else w.data.size() / 2
	return w


## Som ambiente em loop (ônibus SFX, bem baixo). "" para.
func ambience(name: String) -> void:
	if current_amb == name:
		return
	current_amb = name
	if name == "":
		amb.to(null, 0.0, FADE)
		return
	var s := _load(DIR + name + ".ogg")
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	else:
		_warn("ambiente sem arquivo: " + name)
		s = null
	amb.to(s, AMB_DB + float(AMB_TRIM.get(name, 0.0)), FADE * 1.5)


## Menu, mapa da campanha e telas fora da run.
func music_menu() -> void:
	music("music_menu")
	ambience("")


## Música e ambiente da run: estrada pelo vilão (sim.deck_id) e pela fase da campanha; arena se o save
## retomado já está nela.
func music_for_run(sim: Sim) -> void:
	if sim == null:
		music_menu()
		return
	if sim.phase == K.Phase.ARENA:
		music("music_arena")
		ambience(AMB_ARENA)
	elif sim.phase == K.Phase.OVER:
		music("")
		ambience("")
	else:
		music(ROAD_BY_DECK.get(sim.deck_id, "music_road"))
		ambience(AMB_BY_PHASE[clampi(sim.campaign_phase, 0, AMB_BY_PHASE.size() - 1)])
	set_intensity(0.0)


## Fim da run: a música de vitória ou derrota toca uma vez; o ambiente some.
func result_music(win: bool) -> void:
	ambience("")
	music("music_victory" if win else "music_defeat", RESULT_FADE)


## Intensidade 0..1 na estrada: a trilha começa abafada e mais baixa e abre conforme o herói se aproxima do covil.
func set_intensity(k: float) -> void:
	intensity = clampf(k, 0.0, 1.0)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt := clampf((now - t_prev) / 1000000.0, 0.0, 0.25)   # tempo real: Engine.time_scale muda na run
	t_prev = now
	frame_plays = 0
	var open := clampf(intensity / ROAD_OPEN_AT, 0.0, 1.0) if road_mode else 1.0
	road_db = lerpf(road_db, lerpf(ROAD_QUIET_DB, 0.0, open), 1.0 - exp(-dt * 3.0))
	mus.step(dt, road_db)
	amb.step(dt, 0.0)
	if lowpass:
		var want := CUT_CLOSED * pow(CUT_OPEN / CUT_CLOSED, open)
		cutoff = lerpf(cutoff, want, 1.0 - exp(-dt * 3.0))
		lowpass.cutoff_hz = cutoff
		var on := cutoff < CUT_OPEN * 0.95
		if AudioServer.is_bus_effect_enabled(lowpass_bus, lowpass_slot) != on:
			AudioServer.set_bus_effect_enabled(lowpass_bus, lowpass_slot, on)


func handle_events(evs: Array, sim: Sim) -> void:
	# Arena sem o evento ARENA (eventos desligados, como no --skip=arena): troca do mesmo jeito.
	if road_mode and sim.phase == K.Phase.ARENA:
		music("music_arena")
		ambience(AMB_ARENA)
	for ev in evs:
		match int(ev[0]):
			K.Ev.DAMAGE_HERO:
				play("hero_hit")
			K.Ev.DAMAGE_UNIT:
				var ui := int(ev[4])
				if ui < 0:
					play("boss_hit")   # parte do chefe na arena
				else:
					play("hit_hard" if _hard_unit(sim, ui) else "hit")
			K.Ev.DEATH:
				play(_death_id(sim, int(ev[3])), 0.15)
			K.Ev.EXPLOSION:
				play("explosion")
			K.Ev.SHIELD_BREAK:
				play("shield_break")
			K.Ev.HERO_LEVEL:
				play("level_hero", 0.0)
			K.Ev.HERO_FALL:
				play("hero_fall", 0.04)
			K.Ev.TELEPORT:
				play("teleport", 0.0)
			K.Ev.PART_DESTROYED:
				play("part_destroyed", 0.0)
				play("death_stone", 0.05)
			K.Ev.SPELL:
				var di := int(ev[3])
				if di < 0:
					play("ui_click")
				elif di < sim.data.cards.size():
					var c: CardDef = sim.data.cards[di]
					if c.is_spell or c.category != "field":
						play(_spell_id(c))
					else:
						play("card_play")
			K.Ev.CONTEST:
				# A disputa vem com o letreiro grande (hud.gd); o SHRINE do Santuário sai junto e fica sem som.
				var code := int(ev[4])
				if code == 0:
					play("contest_start", 0.0)
				elif code >= 3 and code <= 5:
					play("contest_mark", 0.0, 1.0 + 0.06 * (code - 3))
				elif code == 1:
					play("contest_won", 0.0)
				elif code >= 11:
					play("contest_partial", 0.0)
				elif code < 0:
					play("contest_lost", 0.0)
			K.Ev.ACT_START:
				play("act_start", 0.0)
			K.Ev.ACT_END:
				play("act_end", 0.0)
			K.Ev.RELIC:
				play("relic", 0.0)
			K.Ev.HEAL:
				play("heal")
			K.Ev.CURSE:
				play("curse")
			K.Ev.FEAR:
				play("fear")
			K.Ev.ABILITY_TELL:
				play("ability_tell", 0.05)
			K.Ev.ARENA:
				music("music_arena")
				ambience(AMB_ARENA)
				play("arena", 0.0)


## Golpe "duro" (madeira/osso) em estrutura, constructo ou morto-vivo; carne/couro no resto. O índice pode
## ter sido reciclado no mesmo passo: é só uma dica de timbre.
func _hard_unit(sim: Sim, i: int) -> bool:
	var u: SimUnits = sim.units
	if i >= u.tags.size() or i >= u.arch.size():
		return false
	return (u.tags[i] & (K.TAG_CONSTRUCT | K.TAG_UNDEAD)) != 0 or u.arch[i] == K.Arch.STRUCTURE


func _death_id(sim: Sim, di: int) -> String:
	if di < 0 or di >= sim.data.cards.size():
		return "death"
	var c: CardDef = sim.data.cards[di]
	if c.tags & K.TAG_UNDEAD:
		return "death_bone"
	if c.tags & K.TAG_CONSTRUCT or c.is_structure:
		return "death_stone"
	return "death"


func _spell_id(c: CardDef) -> String:
	if c.tags & K.TAG_FIRE:
		return "spell_fire"
	if c.tags & (K.TAG_UNDEAD | K.TAG_SHADOW):
		return "spell_dark"
	return "spell"


func _warn(msg: String) -> void:
	if warned.has(msg):
		return
	warned[msg] = true
	push_warning("GameAudio: " + msg)
