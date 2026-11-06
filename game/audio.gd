class_name GameAudio
extends Node
## Efeitos com pool e recarga por som (centenas de unidades não viram ruído) e música em camadas.

const SFX := ["card_play", "hit", "hero_hit", "shield_break", "explosion", "death", "spell", "level_hero",
	"level_player", "reward", "contract", "teleport", "part_destroyed", "ui_click", "victory", "defeat"]
const COOLDOWN := {"hit": 0.06, "death": 0.05, "hero_hit": 0.08, "card_play": 0.05}
const VOLUME := {"hit": -10.0, "death": -12.0, "hero_hit": -9.0, "card_play": -6.0, "explosion": -3.0}

var streams: Dictionary = {}
var pool: Array = []
var pool_i := 0
var last: Dictionary = {}
var music_base: AudioStreamPlayer
var music_layer: AudioStreamPlayer
var current_music := ""
var layer_target := -40.0


func _ready() -> void:
	for id in SFX:
		streams[id] = load("res://assets/audio/%s.wav" % id)
	for i in 16:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music_base = AudioStreamPlayer.new()
	music_layer = AudioStreamPlayer.new()
	add_child(music_base)
	add_child(music_layer)


func play(id: String, pitch_var := 0.08) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(last.get(id, -10.0)) < float(COOLDOWN.get(id, 0.0)):
		return
	last[id] = now
	var p: AudioStreamPlayer = pool[pool_i]
	pool_i = (pool_i + 1) % pool.size()
	p.stream = streams[id]
	p.volume_db = VOLUME.get(id, -4.0)
	p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	p.play()


func music(name: String) -> void:
	if current_music == name:
		return
	current_music = name
	if name == "":
		music_base.stop()
		music_layer.stop()
		return
	var b: AudioStreamWAV = load("res://assets/audio/%s_base.wav" % name)
	var l: AudioStreamWAV = load("res://assets/audio/%s_layer.wav" % name)
	for s in [b, l]:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2
	music_base.stream = b
	music_layer.stream = l
	music_base.volume_db = -8.0
	music_layer.volume_db = -40.0
	music_base.play()
	music_layer.play()


## Intensidade 0..1: a camada de percussão e melodia cresce conforme o herói se aproxima do covil.
func set_intensity(k: float) -> void:
	layer_target = lerpf(-30.0, -8.0, clampf(k, 0.0, 1.0))


func _process(delta: float) -> void:
	if music_layer.playing:
		music_layer.volume_db = move_toward(music_layer.volume_db, layer_target, delta * 6.0)


func handle_events(evs: Array, sim: Sim) -> void:
	for ev in evs:
		match int(ev[0]):
			K.Ev.DAMAGE_HERO:
				play("hero_hit")
			K.Ev.DAMAGE_UNIT:
				play("hit")
			K.Ev.DEATH:
				play("death", 0.2)
			K.Ev.EXPLOSION:
				play("explosion")
			K.Ev.SHIELD_BREAK:
				play("shield_break")
			K.Ev.HERO_LEVEL:
				play("level_hero", 0.0)
			K.Ev.PLAYER_LEVEL:
				play("level_player", 0.0)
			K.Ev.SHRINE:
				play("reward" if float(ev[3]) > 0.0 else "explosion", 0.0)
			K.Ev.CONTRACT:
				var v := float(ev[3])
				if v == 0.0:
					play("contract", 0.0)
				elif v > 0.0:
					play("reward", 0.0)
			K.Ev.TELEPORT:
				play("teleport", 0.0)
			K.Ev.PART_DESTROYED:
				play("part_destroyed", 0.0)
			K.Ev.SPELL:
				var di := int(ev[3])
				if di < 0:
					play("ui_click")
				elif di < sim.data.cards.size() and (sim.data.cards[di].is_spell or sim.data.cards[di].category != "field"):
					play("spell")
				else:
					play("card_play")
			K.Ev.ARENA:
				music("music_arena")
				set_intensity(0.5)
