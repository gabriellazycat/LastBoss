class_name WorldView
extends Node3D
## Desenha o estado do Sim. Só lê; nunca altera a simulação.
## Unidades: uma MultiMesh por tipo, preenchida por buffer (transform + cor + dados do shader).
## Game feel: hit-stop, trauma de câmera, flash de tela, recuo, investida, partículas em camadas.

const UP := Vector3.UP
const FX2 := preload("res://game/art/fx2.gd")   # efeitos do mundo (pintados e brilhantes)
var fx2: Node3D = null
var presence: HeroPresence = null   # anel, sombra e aura dos heróis
var gol: Golpes = null              # golpes dos monstros com peso (game/art/golpes.gd)
const STRIDE := 20
const LOC_COLORS := {
	"shop": Color(0.95, 0.75, 0.35), "tavern": Color(0.9, 0.55, 0.25), "fountain": Color(0.35, 0.75, 1.0),
	"ritual": Color(0.8, 0.25, 1.0), "shrine": Color(0.3, 1.0, 0.6), "bridge": Color(0.65, 0.6, 0.55),
	"event": Color(0.95, 0.9, 0.55), "helper": Color(1.0, 0.82, 0.25),
}
const PART_OFFSETS := {"core": Vector3(0, 0, 0), "head": Vector3(0, 4.3, 0), "left_arm": Vector3(-1.6, 2.4, 0), "right_arm": Vector3(1.6, 2.4, 0)}
var boss_offs: Dictionary = PART_OFFSETS   # partes do chefe da run (BossModels.part_offsets)
const UNIT_COLORS := {
	"rat_horde": Color(0.55, 0.45, 0.42), "rat": Color(0.55, 0.45, 0.42), "bat": Color(0.55, 0.3, 0.75), "rat_king": Color(0.9, 0.7, 0.25),
	"skeleton_archers": Color(0.9, 0.86, 0.74), "skeleton": Color(0.9, 0.86, 0.74), "goblin_dynamiter": Color(0.45, 0.75, 0.28),
	"slime": Color(0.3, 0.95, 0.55), "cultists": Color(0.6, 0.15, 0.4), "ogre": Color(0.55, 0.62, 0.34), "ghost": Color(0.7, 0.88, 1.0),
	"spectre": Color(0.35, 1.0, 0.85), "werewolf": Color(0.4, 0.32, 0.28), "scrap_golem": Color(0.62, 0.4, 0.24),
}

# Cor de destaque de cada tipo de monstro: o anel no chão que identifica o tipo de longe.
const ACCENT := {
	"rat_horde": Color(0.95, 0.72, 0.42), "rat": Color(0.95, 0.72, 0.42), "rat_king": Color(1.0, 0.85, 0.3),
	"bat": Color(0.78, 0.45, 1.0), "bat_nest": Color(0.78, 0.45, 1.0),
	"skeleton": Color(0.9, 0.93, 1.0), "skeleton_archers": Color(0.9, 0.93, 1.0), "bone_totem": Color(0.9, 0.93, 1.0),
	"goblin_dynamiter": Color(0.6, 1.0, 0.3), "slime": Color(0.3, 1.0, 0.72), "cultists": Color(1.0, 0.3, 0.62),
	"ogre": Color(1.0, 0.55, 0.25), "mimic": Color(1.0, 0.8, 0.35), "ghost": Color(0.6, 0.85, 1.0),
	"spectre": Color(0.3, 1.0, 0.95), "gargoyle_tower": Color(0.75, 0.7, 1.0), "werewolf": Color(0.9, 0.6, 0.4),
	"scrap_golem": Color(1.0, 0.62, 0.2),
	"ash_salamander": Color(1.0, 0.45, 0.15), "drakeling": Color(1.0, 0.4, 0.25), "brown_bear": Color(0.8, 0.55, 0.35),
	"spitting_viper": Color(0.6, 1.0, 0.3), "ash_phoenix": Color(1.0, 0.6, 0.2), "bone_dragon": Color(0.6, 1.0, 0.9), "magma_golem": Color(1.0, 0.5, 0.15),
}
# Câmera: distância base, quanto ela afasta por unidade em campo (até 300) e o extra na arena.
const CAM_DIST := 44.0 # também é o mínimo: o zoom só afasta (main.gd limita zoom a >= 0)
const CAM_PER_UNIT := 0.02
const CAM_ARENA := 6.0
## Figuras maiores na tela (13/11/2026): só o desenho, o raio do jogo não muda.
## Perto das cartas, herói e monstros minúsculos pareciam de outro jogo.
const FIG_SCALE := 1.2
const HERO_SCALE := 1.55
# O chão (terreno, estrada, grama) fica na camada 2: a contraluz não o ilumina.
const GROUND_LAYER := 2

var sim: Sim
var cam: Camera3D
var look_off := Vector3.ZERO      # deslize da câmera para o lado do mouse (metros no chão)
var look_hold := false            # cena que manda na câmera (morte do herói): sem deslize
const LOOK_MAX := 9.0             # quanto a câmera anda até a borda da tela
const LOOK_DEAD := 0.22           # zona morta no meio da tela (fração da meia-tela)
const LOOK_DOWN_FROM := 0.6        # a partir desta altura da tela (0 a 1) o deslize para baixo ganha reforço
const LOOK_DOWN_BOOST := 0.8       # reforço extra na borda de baixo (0.8 = 1,8x o deslize normal)
var look_freeze := false           # mouse sobre uma carta da mão: a câmera fica onde está (main.gd liga a cada quadro)
## Morte do herói (rodada 09/11/2026): câmera lenta no corpo caindo, depois a câmera recua até o herói novo.
## Só apresentação: a simulação já trocou o herói e espera a recompensa; o HUD segura a oferta até acabar.
var cine_enabled := true
var cine_t := -1.0                # tempo real desde a queda; < 0 sem cena
var cine_from := Vector3.ZERO
var corpse: Node3D
var corpse_spare: Node3D
var corpse_tw: Tween
var fall_party := -1               # party em campo na última queda vista (queda longa só quando a party inteira cai)
var short_falls: Array = []        # membros que caem com a party de pé: {"n": Node3D, "t": s}
var ally_nodes: Array = []         # vultos dos aliados dos poderes (rato / cão de guerra), um por sim.power_state["allies"]
const FALL_SHORT_S := 0.7
const POWER_COLORS := {"fire_burst": Color(1, 0.5, 0.15), "whirlwind": Color(0.8, 0.9, 1.0), "holy_nova": Color(1, 0.92, 0.5),
	"shockwave": Color(0.75, 0.6, 0.4), "war_cry": Color(1, 0.4, 0.3), "chain_lightning": Color(0.6, 0.8, 1.0),
	"smite": Color(1, 0.9, 0.5), "slay_next": Color(1, 0.35, 0.3), "titan_blow": Color(1, 0.55, 0.3),
	"soul_drain": Color(0.7, 1.0, 0.9), "structure_breaker": Color(0.9, 0.7, 0.4), "spell_ward": Color(0.7, 0.5, 1.0),
	"purify": Color(0.7, 0.95, 1.0), "second_wind": Color(0.5, 1.0, 0.6), "iron_will": Color(0.8, 0.85, 0.95),
	"fire_ward": Color(1, 0.6, 0.25), "arrow_wall": Color(0.85, 0.8, 0.6), "retaliation": Color(1, 0.6, 0.3),
	"field_medic": Color(0.5, 1.0, 0.6)}
const CINE_FOCUS := 1.6           # no corpo, em câmera lenta
const CINE_TRAVEL := 1.2          # recuando até o herói novo
const CINE_SLOW := 0.3            # Engine.time_scale no foco
## Cena do local (15/11/2026): no fim de uma disputa, e ao chegar na loja ou na encruzilhada, o mundo desacelera
## como na queda, a câmera vai até o local e um efeito próprio dele mostra o resultado (completa, parcial ou
## falha). A recompensa (e depois o mapa) só abre quando a cena acaba; um clique ou espaço depois de 1 s pula.
## Só apresentação: a simulação já resolveu tudo; bots e testes sem janela não têm cena (cine_enabled).
const SCENE_END := 3.0             # fim de disputa, em tempo real
const SCENE_ARRIVE := 1.5          # chegada na loja e na encruzilhada
const SCENE_BACK := 0.6            # últimos segundos: a câmera volta ao herói e o mundo à velocidade normal
const SCENE_SKIP_AFTER := 1.0
## {"li", "type", "tier" (-1 chegada, 0 falha, 1 parcial, 2 completa), "won_n", "marks", "hard", "t", "dur",
## "pos", "beat"}; vazio sem cena.
var scene: Dictionary = {}
var scene_helper: Node3D = null    # o Herói Ajudante da disputa que acabou (tomba ou some na cena)
var mm_by_def: Dictionary = {}
var flash := PackedFloat32Array()
var kx := PackedFloat32Array()
var ky := PackedFloat32Array()
var hero_root: Node3D
var hero_rig_node: Node3D = null    # rig da classe do herói da vez (troca quando a classe muda)
var rig_cls := "escudeiro"
var follower_nodes: Dictionary = {} # SimHero -> Node3D (fase de grupo)
var helper_node: Node3D = null      # Herói Ajudante em disputa (rig da classe dele)
var helper_of: SimHero = null
var body: Node3D
var hero_mat: ShaderMaterial
var leg_l: Node3D
var leg_r: Node3D
var arm_s: Node3D
var arm_h: Node3D
var cape: Node3D
var head: Node3D
var walk_phase := 0.0
var swing_t := 0.0
var hero_flash := 0.0
var level_jump := 0.0
var slash: MeshInstance3D
var slash_mat: StandardMaterial3D
var hero_light: OmniLight3D
var road_meshes: Array = []
# Estrada em campo único (looks de chão): uma malha só, com a máscara de distância do ato; road_piece_of[li][b] = id do trecho.
var road_field: MeshInstance3D
var road_piece_of: Array = []
var road_state_img: Image
var road_state_tex: ImageTexture
var road_state_last := PackedByteArray()
const ROAD_TEXEL := 0.5      # metros por pixel da máscara
const ROAD_DMAX := 4.0       # distância máxima guardada (m): além disso não há estrada
const ROAD_TILE := 16.0      # lado dos ladrilhos da malha (só os que têm estrada)
var barricades: Array = []      # [nó 3D, ligação]: barreira na entrada de cada ramo, aparece quando o ramo é fechado
var loc_nodes: Array = []
var surf_fields: Array = []         # alturas do chão sob ponte e rio: [{o: Vector2, n: int, h: PackedFloat32Array}]
const SURF_STEP := 0.5
const SURF_MAX := 0.6               # acima disso é corrimão ou pedra da margem: não serve de piso
var lanterns: Array = []
var lantern_lights: Array = []
var zone_pool: Array = []
var number_pool: Array = []
var number_i := 0
var burst_pool: Array = []
var burst_i := 0
var shot_pool: Array = []
var shot_i := 0
var hshot_pool: Array = []   # projéteis dos heróis à distância (flecha / orbe), voando da arma até o alvo
var hshot_i := 0
var orb_pool: Array = []
var orb_i := 0
var decal_pool: Array = []
var decal_i := 0
var fx: Dictionary = {}
var fireflies: GPUParticles3D
var ring_nodes: Array = []   # um círculo vermelho por herói da party (o raio é o dele)
var ring_rad: Array = []
var ghost: MeshInstance3D
var ghost_mat: ShaderMaterial
var arena_root: Node3D
var part_nodes: Array = []
var part_flash: Array = []
var falling: Array = []
var altar_nodes: Array = []
var pillar_nodes: Array = []
var boss_face: MeshInstance3D
var cam_pos := Vector3.ZERO
## Distância extra inicial da câmera (21/11/2026: começa mais atrás). É também o mínimo: a roda não aproxima além disso.
const ZOOM_START := 8.0
var zoom := ZOOM_START
## Só capturas (--camlair, rodada de modelos 20/11/2026): a câmera mira o covil em vez do herói.
var cam_lair := false
var lair_pos := Vector3.ZERO
var lair_node: Node3D
const CAM_LOOK_Z := 0.0     # para onde a câmera mira em relação ao herói (+ = para trás, sobe o herói na tela)
var arrive_pull := 0.0   # recuo da câmera por ~3 s quando chega um herói novo
var trauma := 0.0
var hitstop := 0.0
var screen_flash := Color(1, 1, 1, 0)
var flash_light: OmniLight3D
var flash_t := 0.0
var bar_mm: MultiMesh
var bar_buf := PackedFloat32Array()
var ring_mm: MultiMesh
var ring_buf := PackedFloat32Array()
# Dano no herói somado por ~0,3 s num número só (antes eram dezenas de números empilhados).
var dmg_acc := {"v": 0.0, "t": 0.0, "col": Color.WHITE, "p": Vector3.ZERO}
var bubble: Label3D
var bubble_t := 0.0
var tell_label: Label3D            # aviso de habilidade do herói, 1 s antes de disparar (rodada 09/11/2026)
var tell_t := 0.0
var house_nodes: Dictionary = {}    # "li:k" -> casa da Taverna em disputa
var bubble_on_boss := false
var soft_tex: GradientTexture2D
var frame := 0
# Orçamento de efeitos por quadro (com centenas de unidades, o excesso vira ruído e custo).
var budget := {"hit": 0, "death": 0, "num": 0}


func _unshaded(c: Color, emit := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m


func _mi(mesh: Mesh, pos: Vector3, mat: Material = null, rot_y := 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = Looks.g_material(mesh, mat if mat else Models.material())
	m.position = pos
	m.rotation.y = rot_y
	return m


func _light(pos: Vector3, col: Color, energy: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_m
	l.position = pos
	l.light_volumetric_fog_energy = 0.2
	return l


func build_empty() -> void:
	for c in get_children():
		c.queue_free()
	old_acts.clear()
	sim = null


## Cenário do ato montado (filhos 0..static_count-1: chão, estrada, rios, cenário, locais, covil); o resto são unidades, herói, pools.
var static_nodes: Array = []
var ground_nodes: Array = []
## Cenários dos atos anteriores (C17, 25/11/2026): ficam no mapa para sempre, sem fade, estáticos (sem luz, partícula nem animação)
## e com visibility_range para não pesar. Cada um é um nó "OldAct".
var old_acts: Array = []
const OLD_RANGE := 300.0   # m: além disso o cenário velho (pedaços pequenos) não é desenhado


## `append` (C17, 19/11/2026): troca de ato contínua. O cenário do ato anterior fica no lugar (estático) e o ato novo é
## montado ao lado; a câmera não é teleportada e unidades, herói e pools não são recriados.
func build(s: Sim, camera: Camera3D, append := false) -> void:
	# Run nova ou ato novo: nenhuma cena de queda pela metade (o mundo volta à velocidade normal).
	cine_t = -1.0
	_end_scene()
	look_hold = false
	Engine.time_scale = 1.0
	var keep_cam := cam_pos
	var keep_pre := pre_root
	pre_root = null   # a pré-montagem do ato seguinte (se houver) é descartada junto com o resto
	if keep_pre != null and is_instance_valid(keep_pre):
		keep_pre.queue_free()
	_pre_reset()
	var cont := append and s == sim and sim != null and not static_nodes.is_empty()
	if cont:
		_retire_old_act()
	else:
		build_empty()
	sim = s
	cam = camera
	road_field = null
	road_piece_of.clear()
	road_state_last = PackedByteArray()
	if cont:
		for a in [road_meshes, barricades, loc_nodes, lanterns, lantern_lights]:
			a.clear()
		surf_fields.clear()
		house_nodes.clear()
	else:
		for a in [road_meshes, barricades, loc_nodes, lanterns, lantern_lights, zone_pool, number_pool, burst_pool, shot_pool, hshot_pool, orb_pool, decal_pool, part_nodes, part_flash, falling, altar_nodes, pillar_nodes]:
			a.clear()
		mm_by_def.clear()
		surf_fields.clear()
		house_nodes.clear()
		# Círculos dos heróis: os nós foram liberados com o resto (build_empty); sem limpar, _update_rings usava nós
		# mortos a cada quadro depois da troca de ato ("previously freed instance").
		ring_nodes.clear()
		ring_rad.clear()
		fx.clear()
		follower_nodes.clear()
		ally_nodes.clear()
		short_falls.clear()
		helper_node = null
		helper_of = null
		arena_root = null
		flash.resize(sim.units.cap)
		flash.fill(0.0)
		kx.resize(sim.units.cap)
		kx.fill(0.0)
		ky.resize(sim.units.cap)
		ky.fill(0.0)
		soft_tex = GradientTexture2D.new()
		var gr := Gradient.new()
		gr.offsets = PackedFloat32Array([0.0, 1.0])
		gr.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		soft_tex.gradient = gr
		soft_tex.fill = GradientTexture2D.FILL_RADIAL
		soft_tex.fill_from = Vector2(0.5, 0.5)
		soft_tex.fill_to = Vector2(0.5, 0.0)
		soft_tex.width = 64
		soft_tex.height = 64
	fall_party = sim.cur_party
	var before := get_children()
	_build_ground()
	ground_nodes = get_children().filter(func(c): return not before.has(c))
	_build_road()
	_build_rivers()
	_build_scatter()
	_build_locations()
	_build_lair()
	static_nodes = get_children().filter(func(c): return not before.has(c))
	_ensure_lair_visible()
	if not cont:
		_build_units()
		_build_hero()
		_build_pools()
		_build_bars()
	cam_pos = keep_cam if cont else Vector3(sim.hero.x, 0, sim.hero.y)


## O covil (castelo) fica inteiro e visível desde o começo do último ato, sem limite de distância.
func _ensure_lair_visible() -> void:
	if lair_node != null and is_instance_valid(lair_node):
		lair_node.visible = true
		if lair_node is GeometryInstance3D:
			(lair_node as GeometryInstance3D).transparency = 0.0
			(lair_node as GeometryInstance3D).visibility_range_end = 0.0


## Tira o cenário do ato anterior da cena viva: vai para um nó à parte (OldAct), um pouco abaixo, e fica ali parado
## para sempre. Unidades, herói e pools continuam onde estão.
func _retire_old_act(_static_only := true) -> void:
	var old := Node3D.new()
	old.name = "OldAct"
	old.position = Vector3(0, -0.02, 0)
	var skip: Array = ground_nodes.duplicate()
	skip.append_array(road_meshes)
	var keep: Array = static_nodes.filter(func(c): return is_instance_valid(c) and c.get_parent() == self)
	for o in old_acts:
		if is_instance_valid(o):
			(o as Node3D).position.y -= 0.02   # o mais novo fica por cima: sem brigar com o anterior no chão
	add_child(old)
	for c in keep:
		c.reparent(old, true)
	# Casas da Taverna criadas durante o ato: as de pé ficam no cenário velho, as outras saem.
	for key in house_nodes:
		var hn: Node3D = house_nodes[key]
		if not is_instance_valid(hn):
			continue
		if hn.visible and hn.get_parent() == self:
			hn.reparent(old, true)
		elif hn.get_parent() == self:
			hn.queue_free()
	_freeze_act(old, skip)
	old_acts.append(old)


## Deixa o cenário velho estático: sem luz, partícula nem animação, e os pedaços pequenos com visibility_range.
func _freeze_act(root: Node3D, skip: Array) -> void:
	root.process_mode = Node.PROCESS_MODE_DISABLED
	for n in root.find_children("*", "", true, false):
		if n is Light3D:
			(n as Light3D).visible = false
		elif n is GPUParticles3D:
			(n as GPUParticles3D).emitting = false
		elif n is CPUParticles3D:
			(n as CPUParticles3D).emitting = false
		elif n is AnimationPlayer:
			(n as AnimationPlayer).stop()
		elif n is GeometryInstance3D and not skip.has(n):
			var g := n as GeometryInstance3D
			var bb := g.get_aabb().size
			if maxf(bb.x, bb.z) < 100.0:
				g.visibility_range_end = OLD_RANGE
				g.visibility_range_end_margin = 20.0


# ---------------------------------------------------------------- mapa contínuo (21/11/2026)
# O ato seguinte é montado ANTES do fim do ato, uma etapa por quadro (sem travar), por cima do mesmo mundo, e aparece no
# chão aos poucos conforme o herói chega perto do portão. Na troca de ato só se adota o que já está pronto.

const ACT_STATE := ["road_meshes", "road_field", "road_piece_of", "road_state_img", "road_state_tex", "road_state_last",
	"barricades", "loc_nodes", "surf_fields", "lanterns", "lantern_lights", "house_nodes", "lair_pos", "lair_node",
	"ground_nodes", "static_nodes"]
const PRE_STAGES := ["_build_ground", "_build_road", "_build_rivers", "_scatter_sample", "k:tree", "k:tree_round", "k:dead_tree", "k:rock",
	"k:grass", "k:mushroom", "k:bush", "k:flowers", "k:gravestone", "k:road_stone", "k:lantern", "_scatter_mundo", "_scatter_lights", "_build_locations", "_build_lair"]
const PRE_START_D := 320.0    # m do portão em que começa a montagem
const PRE_SHOW_D := 110.0     # m do portão em que o chão novo começa a aparecer
const PRE_FULL_D := 35.0      # m do portão em que ele já está inteiro
var pre_stage := -1           # -1 não começou; 0..5 etapa seguinte; 6 pronto
var pre_state: Dictionary = {}
var pre_root: Node3D = null
var pre_road: SimRoad = null
## Estrada do ato vivo enquanto o seguinte é montado (Cenario não põe nada em cima dela durante o crossfade).
var other_road: SimRoad = null
var pre_act := -1
var pre_alpha := 1.0
var pre_lights: Array = []    # [luz, energia]
var pre_log: bool = OS.get_cmdline_user_args().has("--prelog")


func _act_state() -> Dictionary:
	var d := {}
	for v in ACT_STATE:
		d[v] = get(v)
	return d


func _act_state_put(d: Dictionary) -> void:
	for v in ACT_STATE:
		set(v, d[v])


func _act_state_blank() -> Dictionary:
	return {"road_meshes": [], "road_field": null, "road_piece_of": [], "road_state_img": null, "road_state_tex": null,
		"road_state_last": PackedByteArray(), "barricades": [], "loc_nodes": [], "surf_fields": [], "lanterns": [],
		"lantern_lights": [], "house_nodes": {}, "lair_pos": Vector3.ZERO, "lair_node": null, "ground_nodes": [], "static_nodes": []}


func _pre_reset() -> void:
	if pre_root != null and is_instance_valid(pre_root):
		pre_root.queue_free()
	pre_root = null
	pre_stage = -1
	pre_state = {}
	pre_road = null
	pre_act = -1
	pre_lights.clear()
	pre_alpha = 1.0


## Distância do herói ao portão de fim do ato.
func _gate_dist() -> float:
	return Vector2(sim.hero.x, sim.hero.y).distance_to(sim.road.lair)


## Uma etapa da montagem do ato seguinte. O estado do ato vivo (nós e vetores) sai de cena durante a etapa e volta depois.
func _pre_run_stage() -> void:
	var t0 := Time.get_ticks_usec()
	var cur := _act_state()
	var real_road := sim.road
	var real_act := sim.act
	var real_look := GroundLooks.act_look
	_act_state_put(pre_state)
	sim.road = pre_road
	other_road = real_road
	sim.act = pre_act
	var A: Array = sim.R.get("acts", [])
	GroundLooks.act_look = int(A[pre_act].get("ground_look", -1)) if pre_act < A.size() else -1
	var before := get_children()
	var st: String = PRE_STAGES[pre_stage]
	if st.begins_with("k:"):
		_scatter_kind(st.substr(2))
	else:
		call(st)
	var added := get_children().filter(func(c): return not before.has(c))
	for c in added:
		c.reparent(pre_root, false)
	if pre_stage == 0:
		ground_nodes = added
	static_nodes.append_array(added)
	pre_state = _act_state()
	_act_state_put(cur)
	sim.road = real_road
	other_road = null
	sim.act = real_act
	GroundLooks.act_look = real_look
	for c in added:
		for l in c.find_children("*", "OmniLight3D", true, false) + ([c] if c is OmniLight3D else []):
			pre_lights.append([l, (l as OmniLight3D).light_energy])
		_fade_tree(c, 1.0)
	pre_stage += 1
	if pre_log:
		print("pre-etapa %s: %.1f ms" % [PRE_STAGES[pre_stage - 1], (Time.get_ticks_usec() - t0) / 1000.0])


func _pre_begin() -> void:
	pre_act = sim.act + 1
	pre_road = sim.next_road()
	pre_state = _act_state_blank()
	pre_root = Node3D.new()
	pre_root.name = "NextAct"
	pre_root.position = Vector3(0, 0.02, 0)   # um pouco acima do chão do ato vivo: sem brigar com ele
	pre_root.visible = false
	add_child(pre_root)
	pre_stage = 0


## Todo quadro (de draw): monta uma etapa e ajusta o quanto do chão novo já aparece.
func _pre_tick() -> void:
	if sim == null or sim.phase != K.Phase.ROAD or sim.act_pending or sim.act + 1 >= sim.acts():
		return
	if DisplayServer.get_name() == "headless":
		return   # testes sem janela não montam nada
	var d := _gate_dist()
	if pre_stage < 0 and d < PRE_START_D and cine_t < 0.0:
		_pre_begin()
	if pre_stage >= 0 and pre_stage < PRE_STAGES.size():
		_pre_run_stage()
	if pre_stage >= PRE_STAGES.size():
		var v := clampf((PRE_SHOW_D - d) / (PRE_SHOW_D - PRE_FULL_D), 0.0, 1.0)
		v = v * v * (3.0 - 2.0 * v)
		var a := 1.0 - v
		if absf(a - pre_alpha) >= 0.03 or (a == 0.0 and pre_alpha != 0.0) or (a == 1.0 and pre_alpha != 1.0):
			_pre_apply_alpha(a)


func _pre_apply_alpha(a: float) -> void:
	pre_alpha = a
	pre_root.visible = a < 0.999
	for c in pre_state["static_nodes"]:
		_fade_tree(c, a)
	for e in pre_lights:
		if is_instance_valid(e[0]):
			(e[0] as OmniLight3D).light_energy = float(e[1]) * (1.0 - a)


## O ato seguinte já foi montado para a estrada atual (`sim.road`)? Então dá para adotá-lo sem montar nada.
func pre_ready() -> bool:
	return pre_stage >= 0 and pre_road != null and pre_road == sim.road


## Troca de ato com o cenário pronto: termina o que faltar, o cenário velho some aos poucos e o novo passa a ser o do ato.
func commit_next() -> void:
	cine_t = -1.0
	_end_scene()
	# O que faltar da montagem sai de uma vez só (o herói chegou antes do previsto).
	while pre_stage < PRE_STAGES.size():
		_pre_run_stage()
	_pre_apply_alpha(0.0)
	_retire_old_act()
	_act_state_put(pre_state)
	_ensure_lair_visible()
	for c in static_nodes:
		if is_instance_valid(c) and c.get_parent() == pre_root:
			c.reparent(self, false)
	pre_root.queue_free()
	pre_root = null
	pre_state = {}
	pre_stage = -1
	pre_road = null
	pre_lights.clear()
	pre_alpha = 1.0


func _fade_tree(n: Node, v: float) -> void:
	if not is_instance_valid(n):
		return
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).transparency = v
	for c in n.find_children("*", "GeometryInstance3D", true, false):
		(c as GeometryInstance3D).transparency = v


# ---------------------------------------------------------------- terreno e estrada

func _road_bounds() -> Rect2:
	var r := Rect2(sim.road.route[0], Vector2.ZERO)
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for p in pts:
				r = r.expand(p)
	return r.grow(120.0)


func _build_ground() -> void:
	_build_ground_look()


## Chão do ato (GroundLooks): plano com o shader pintado + grama com vento perto da estrada.
func _build_ground_look() -> void:
	var b := _road_bounds()
	var pm := PlaneMesh.new()
	pm.size = b.size
	# Subdividido: com só dois triângulos enormes, a interpolação por vértice marcava a diagonal.
	pm.subdivide_width = int(b.size.x / 12.0)
	pm.subdivide_depth = int(b.size.y / 12.0)
	var gmat := GroundLooks.ground_material()
	gmat.set_shader_parameter("mundo", MundoVivo.ground_amount())
	var g := _mi(pm, Vector3(b.get_center().x, -0.03, b.get_center().y), gmat)
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.layers = GROUND_LAYER
	add_child(g)
	var dens: float = GroundLooks.preset()["grass"]
	if dens <= 0.0:
		return
	# Pontos da estrada numa grade de 4 m, para saber a distância até ela.
	var near := {}
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for p in pts:
				var k := Vector2i(int(floor(p.x / 4.0)), int(floor(p.y / 4.0)))
				if not near.has(k):
					near[k] = []
				near[k].append(p)
	var rng := RandomNumberGenerator.new()
	rng.seed = sim.run_seed + 131
	var chunks := {}
	var tones := {}   # tom de cada tufo por pedaço
	# Teto por célula de 6 m: onde as faixas de duas estradas se sobrepõem (a rede tem ~50 ligações lado a lado),
	# a grama não dobra. O teto é a densidade de uma estrada sozinha.
	var per_cell := {}
	var cap := maxi(1, ceili(36.0 * 0.12 * dens))
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for i in range(0, pts.size(), 2):
				var c: Vector2 = pts[i]
				for j in int(70 * dens):
					var a := rng.randf() * TAU
					var r := rng.randf_range(2.4, 26.0)
					var p := c + Vector2(cos(a), sin(a)) * r
					var kk := Vector2i(int(floor(p.x / 4.0)), int(floor(p.y / 4.0)))
					var ok := true
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							for q in near.get(kk + Vector2i(dx, dy), []):
								if p.distance_squared_to(q) < 9.0:
									ok = false
									break
					if not ok or sim.terra().is_water(p.x, p.y):
						continue
					var cell := Vector2i(int(floor(p.x / 6.0)), int(floor(p.y / 6.0)))
					if int(per_cell.get(cell, 0)) >= cap:
						continue
					per_cell[cell] = int(per_cell.get(cell, 0)) + 1
					var s := rng.randf_range(0.9, 1.9) * (1.0 + clampf((r - 8.0) / 18.0, 0.0, 1.0) * 0.4)
					var tf: Array = MundoVivo.tuft(rng)   # 3 tamanhos e 3 tons
					s *= float(tf[0])
					var tone: Color = tf[1]
					var ck := Vector2i(int(floor(p.x / 64.0)), int(floor(p.y / 64.0)))
					if not chunks.has(ck):
						chunks[ck] = []
					chunks[ck].append(Transform3D(Basis(UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s)), Vector3(p.x, -0.02, p.y)))
					if not tones.has(ck):
						tones[ck] = []
					tones[ck].append(tone)
	var mesh := GroundLooks.grass_mesh()
	var mat := GroundLooks.grass_material()
	mat.set_shader_parameter("gusts", 1.0)   # o mesmo vento com rajadas das flores
	for ck in chunks:
		var xf: Array = chunks[ck]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = xf.size()
		for i in xf.size():
			mm.set_instance_transform(i, xf[i])
			var v := rng.randf_range(0.8, 1.2)
			var tc := Color(v, v * rng.randf_range(0.92, 1.08), v * 0.95)
			mm.set_instance_color(i, tc * (tones[ck][i] as Color))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.layers = GROUND_LAYER
		add_child(mmi)


## Máscara da estrada do ato: distância (m) ao eixo mais próximo entre todos os trechos (R8, 0..ROAD_DMAX) e o id do
## trecho mais próximo (RG8). Gerada uma vez por ato. Devolve também os ladrilhos que têm estrada.
func _road_field_images(b: Rect2) -> Array:
	var w := int(ceil(b.size.x / ROAD_TEXEL))
	var h := int(ceil(b.size.y / ROAD_TEXEL))
	var dist := PackedFloat32Array()
	dist.resize(w * h)
	dist.fill(ROAD_DMAX)
	var ids := PackedByteArray()
	ids.resize(w * h * 2)
	var tiles := {}
	var piece := 0
	road_piece_of.clear()
	for li in sim.road.legs.size():
		var row := []
		for br in sim.road.legs[li]["pts"].size():
			row.append(piece)
			var pts: PackedVector2Array = sim.road.legs[li]["pts"][br]
			var lo := piece & 255
			var hi := piece >> 8
			for k in pts.size() - 1:
				var a: Vector2 = pts[k]
				var e: Vector2 = pts[k + 1]
				var ab := e - a
				var l2 := maxf(ab.length_squared(), 0.0001)
				var x0 := maxi(int(floor((minf(a.x, e.x) - ROAD_DMAX - b.position.x) / ROAD_TEXEL)), 0)
				var x1 := mini(int(ceil((maxf(a.x, e.x) + ROAD_DMAX - b.position.x) / ROAD_TEXEL)), w - 1)
				var y0 := maxi(int(floor((minf(a.y, e.y) - ROAD_DMAX - b.position.y) / ROAD_TEXEL)), 0)
				var y1 := mini(int(ceil((maxf(a.y, e.y) + ROAD_DMAX - b.position.y) / ROAD_TEXEL)), h - 1)
				for ty in range(y0, y1 + 1):
					var py := b.position.y + (ty + 0.5) * ROAD_TEXEL
					for tx in range(x0, x1 + 1):
						var px := b.position.x + (tx + 0.5) * ROAD_TEXEL
						var t := clampf(((px - a.x) * ab.x + (py - a.y) * ab.y) / l2, 0.0, 1.0)
						var dx := a.x + ab.x * t - px
						var dy := a.y + ab.y * t - py
						var d := sqrt(dx * dx + dy * dy)
						var ix := ty * w + tx
						if d < dist[ix]:
							dist[ix] = d
							ids[ix * 2] = lo
							ids[ix * 2 + 1] = hi
				for q in [a, e]:
					tiles[Vector2i(int(floor(q.x / ROAD_TILE)), int(floor(q.y / ROAD_TILE)))] = true
			piece += 1
		road_piece_of.append(row)
	var bytes := PackedByteArray()
	bytes.resize(w * h)
	for i in w * h:
		bytes[i] = int(clampf(dist[i] / ROAD_DMAX, 0.0, 1.0) * 255.0 + 0.5)
	return [Image.create_from_data(w, h, false, Image.FORMAT_R8, bytes), Image.create_from_data(w, h, false, Image.FORMAT_RG8, ids), tiles, piece]


## A estrada inteira do ato numa malha de ladrilhos de 16 m com o shader de campo.
func _build_road_field() -> void:
	var b := _road_bounds()
	b = Rect2(b.position.snapped(Vector2.ONE * ROAD_TEXEL), b.size)
	var res := _road_field_images(b)
	var mask := ImageTexture.create_from_image(res[0])
	var ids := ImageTexture.create_from_image(res[1])
	road_state_img = Image.create(maxi(int(res[3]), 1), 1, false, Image.FORMAT_RGBA8)
	road_state_tex = ImageTexture.create_from_image(road_state_img)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := {}
	# Cada ladrilho com estrada leva a vizinhança de 1 (a borda passa de 3,7 m e os trechos cruzam ladrilhos).
	for k in res[2]:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				cells[Vector2i(k.x + dx, k.y + dy)] = true
	for k in cells:
		var x0: float = k.x * ROAD_TILE
		var z0: float = k.y * ROAD_TILE
		var q := [Vector3(x0, 0, z0), Vector3(x0 + ROAD_TILE, 0, z0), Vector3(x0, 0, z0 + ROAD_TILE), Vector3(x0 + ROAD_TILE, 0, z0 + ROAD_TILE)]
		for v in [q[0], q[1], q[2], q[2], q[1], q[3]]:
			st.set_normal(Vector3.UP)
			st.set_tangent(Plane(1, 0, 0, 1))
			st.add_vertex(v)
	var mesh := st.commit()
	var mat := GroundLooks.road_field_material(mask, ids, road_state_tex, b, ROAD_DMAX)
	road_field = _mi(mesh, Vector3(0, 0.02, 0), mat)
	road_field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	road_field.layers = GROUND_LAYER
	add_child(road_field)
	_update_road_state()


## Estado por trecho na textura pequena: R = escurecido (ramo fechado), G = brilho (ramo planejado).
func _update_road_state() -> void:
	var buf := PackedByteArray()
	buf.resize(road_state_img.get_width() * 4)
	for li in sim.road.legs.size():
		var leg: Dictionary = sim.road.legs[li]
		for br in leg["pts"].size():
			var dim: bool = leg["closed"] == br
			var glow: bool = not dim and leg["chosen"] < 0 and sim.road.plan.get(leg["a"], -1) == li
			var o: int = int(road_piece_of[li][br]) * 4
			buf[o] = 255 if dim else 0
			buf[o + 1] = 255 if glow else 0
			buf[o + 3] = 255
	if buf == road_state_last:
		return
	road_state_last = buf
	road_state_img.set_data(road_state_img.get_width(), 1, false, Image.FORMAT_RGBA8, buf)
	road_state_tex.update(road_state_img)


func _build_road() -> void:
	_build_road_field()   # a estrada é uma malha só, com campo
	for li in sim.road.legs.size():
		var leg: Dictionary = sim.road.legs[li]
		# Barreira na entrada do ramo: só os que saem de uma bifurcação podem ser fechados pela escolha.
		if sim.road.nodes[leg["a"]]["out"].size() > 1:
			# Perto do nó os ramos ainda se sobrepõem: a barreira vai onde este ramo já se afastou dos irmãos.
			var pts: PackedVector2Array = leg["pts"][0]
			var at := 9.0
			while at < 70.0:
				var c := SimRoad._point_on(pts, at)
				var near := INF
				for e2 in sim.road.nodes[leg["a"]]["out"]:
					if e2 != li:
						for p2 in sim.road.legs[e2]["pts"][0]:
							near = minf(near, c.distance_to(p2))
				if near > 9.0:
					break
				at += 2.0
			var q := SimRoad._point_on(pts, at)
			var dir := (SimRoad._point_on(pts, at + 2.0) - q).normalized()
			var yaw := atan2(-dir.x, -dir.y)
			var side := Vector3(dir.orthogonal().x, 0, dir.orthogonal().y)
			var bn := Node3D.new()
			bn.position = Vector3(q.x, 0, q.y)
			bn.add_child(_mi(Models.prop("fence"), side * 1.1, null, yaw + PI * 0.5))
			bn.add_child(_mi(Models.prop("fence"), -side * 1.1, null, yaw + PI * 0.5))
			bn.add_child(_mi(Models.prop("rock"), side * 2.6, null, yaw))
			bn.add_child(_mi(Models.prop("rock"), -side * 2.4 + Vector3(dir.x, 0, dir.y) * 0.8, null, yaw + 1.0))
			bn.add_child(_mi(Models.prop("dead_tree"), Vector3(dir.x, 0, dir.y) * 1.6, null, yaw + 0.6))
			bn.visible = false
			add_child(bn)
			barricades.append([bn, li])


## Rios do ato (16/11/2026): uma fita por rio com o shader de água pintada (água + margens de terra).
const RIVER_HW := 5.0          # meia largura da água (a mesma da simulação, rules.road.river.half_width)
const RIVER_BANK := 1.8        # margem de terra de cada lado


## Ponte no eixo da estrada, do tamanho do tabuleiro da simulação (comprimento = rio + cabeceiras; largura de
## uma carroça), seja qual for o modelo: o eixo comprido do modelo vai na direção da estrada.
func _bridge_mesh(yaw: float) -> MeshInstance3D:
	var RV: Dictionary = sim.data.rules["road"].get("river", {})
	var length := 2.0 * (float(RV.get("half_width", RIVER_HW)) + float(RV.get("deck_overhang", 2.5)))
	var width := 2.0 * float(RV.get("deck_half_width", 2.6))
	var mesh: Mesh = Models.prop("bridge")
	var ab := mesh.get_aabb()
	var long_x := ab.size.x > ab.size.z
	var sl := length / maxf(ab.size.x if long_x else ab.size.z, 0.01)
	var sw := width / maxf(ab.size.z if long_x else ab.size.x, 0.01)
	var sc := Vector3(sl, sw, sw) if long_x else Vector3(sw, sw, sl)
	var basis := Basis(UP, yaw + (PI * 0.5 if long_x else 0.0)).scaled_local(sc)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Looks.g_material(mesh, Models.material())
	var c := ab.position + ab.size * 0.5
	mi.transform = Transform3D(basis, -(basis * Vector3(c.x, 0.0, c.z)))
	return mi


func _build_rivers() -> void:
	var hw := float(sim.data.rules["road"].get("river", {}).get("half_width", RIVER_HW))
	for rv in sim.road.rivers:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://game/art/river_paint.gdshader")
		mat.set_shader_parameter("water_frac", hw / (hw + RIVER_BANK))
		var mi := MeshInstance3D.new()
		mi.mesh = _river_ribbon(rv["pts"], hw + RIVER_BANK)
		mi.material_override = mat
		mi.position = Vector3(0, 0.035, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.layers = GROUND_LAYER
		add_child(mi)


## Fita do rio com UV: x de -1 a 1 através, y em metros ao longo.
func _river_ribbon(pts: PackedVector2Array, half: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var L: Array = []
	var R: Array = []
	var acc := PackedFloat32Array()
	var s := 0.0
	for i in n:
		var d := Vector2.ZERO
		if i > 0:
			d += (pts[i] - pts[i - 1]).normalized()
			s += pts[i].distance_to(pts[i - 1])
		if i < n - 1:
			d += (pts[i + 1] - pts[i]).normalized()
		var o := d.normalized().orthogonal()
		L.append(pts[i] + o * half)
		R.append(pts[i] - o * half)
		acc.append(s)
	for i in n - 1:
		var quad := [[L[i], -1.0, acc[i]], [L[i + 1], -1.0, acc[i + 1]], [R[i], 1.0, acc[i]], [R[i], 1.0, acc[i]], [L[i + 1], -1.0, acc[i + 1]], [R[i + 1], 1.0, acc[i + 1]]]
		for v in quad:
			var p: Vector2 = v[0]
			st.set_normal(UP)
			st.set_uv(Vector2(v[1], v[2]))
			st.add_vertex(Vector3(p.x, 0.0, p.y))
	return st.commit()


## Ponto a menos de `margin` m da água (para o cenário não nascer dentro do rio).
func _near_water(p: Vector2, margin: float) -> bool:
	var T := sim.terra()
	if not T.ok:
		return false
	if T.is_water(p.x, p.y):
		return true
	for k in 8:
		var a := TAU * k / 8.0
		if T.is_water(p.x + cos(a) * margin, p.y + sin(a) * margin):
			return true
	return false


func _road_cells() -> Dictionary:
	var cells := {}
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			for p in pts:
				var cx := int(floor(p.x / 6.0))
				var cy := int(floor(p.y / 6.0))
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						cells[Vector2i(cx + dx, cy + dy)] = true
	for loc in sim.road.locations:
		var p: Vector2 = loc["pos"]
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				cells[Vector2i(int(floor(p.x / 6.0)) + dx, int(floor(p.y / 6.0)) + dy)] = true
	var lp := sim.road.lair + sim.road.lair_dir * 16.0
	for dy in range(-7, 8):
		for dx in range(-7, 8):
			cells[Vector2i(int(floor(lp.x / 6.0)) + dx, int(floor(lp.y / 6.0)) + dy)] = true
	return cells


func _scatter_mm(mesh: Mesh, xforms: Array, mat: Material, shadow: bool, tint := false) -> void:
	if xforms.is_empty():
		return
	var trng := RandomNumberGenerator.new()
	trng.seed = xforms.size()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, GroundLooks.foliage_tint(trng) if tint else Color.WHITE)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _build_scatter() -> void:
	_scatter_sample()
	for k in _sc_sets:
		_scatter_kind(k)
	_scatter_tail()


var _sc_sets: Dictionary = {}


## Sorteia onde fica cada coisa do cenário (só contas; os nós vêm depois, um tipo por vez).
func _scatter_sample() -> void:
	var cells := _road_cells()
	var b := _road_bounds()
	var rng := RandomNumberGenerator.new()
	rng.seed = sim.run_seed + 77
	var sets := {"tree": [], "tree_round": [], "dead_tree": [], "rock": [], "grass": [], "mushroom": [], "bush": [], "flowers": [], "gravestone": [], "road_stone": [], "lantern": []}
	# Lanternas a cada ~56 m, alternando os lados (a rede tem muitas ligações).
	for leg in sim.road.legs:
		for pts in leg["pts"]:
			var acc := 0.0
			var side := 1.0
			for i in range(1, pts.size()):
				var d: Vector2 = pts[i] - pts[i - 1]
				acc += d.length()
				var o := d.normalized().orthogonal()
				rng.randf()   # (sorteio antigo das pedras da beira; mantido para não mudar o resto do cenário)
				if acc > 56.0:
					acc = 0.0
					side = -side
					var q2: Vector2 = pts[i] + o * 4.4 * side
					var yaw := atan2(-o.x * side, -o.y * side) + PI * 0.5
					sets["lantern"].append(Transform3D(Basis(UP, yaw), Vector3(q2.x, 0, q2.y)))
					lanterns.append(Vector3(q2.x, 0, q2.y) + Basis(UP, yaw) * Vector3(0.5, 2.15, 0))
	# Beira do rio: pedras, arbustos e flores soltos na margem (longe das pontes e da estrada).
	for rv in sim.road.rivers:
		var rp: PackedVector2Array = rv["pts"]
		for i in range(1, rp.size() - 1, 2):
			if rng.randf() > 0.4:
				continue
			var o := (rp[i + 1] - rp[i - 1]).normalized().orthogonal() * (1.0 if rng.randf() < 0.5 else -1.0)
			var q: Vector2 = rp[i] + o * (RIVER_HW + rng.randf_range(0.6, 2.2))
			if cells.has(Vector2i(int(floor(q.x / 6.0)), int(floor(q.y / 6.0)))) or sim.terra().is_water(q.x, q.y):
				continue
			var r2 := rng.randf()
			var kk := "rock" if r2 < 0.45 else ("bush" if r2 < 0.7 else ("flowers" if r2 < 0.85 else "grass"))
			var sc := rng.randf_range(0.6, 1.2)
			sets[kk].append(Transform3D(Basis(UP, rng.randf() * TAU).scaled(Vector3.ONE * sc), Vector3(q.x, 0, q.y)))
	_sc_sets = sets


func _scatter_kind(k: String) -> void:
	var sets := _sc_sets
	var mat: Material = Models.material()
	var mesh: Mesh = Models.prop(k)
	var look_mesh := GroundLooks.prop_mesh(k)
	if look_mesh:
		mesh = look_mesh
		mat = GroundLooks.prop_material(k in ["tree", "tree_round", "bush"])
	elif k == "grass":
		return
	elif k in ["tree", "tree_round", "bush", "grass", "flowers"]:
		var sm := Models.glow_material(0.0)
		Looks.set_param(sm, "sway", 1.0)
		mat = sm
	mat = Looks.g_material(mesh, mat)
	_scatter_mm(mesh, sets[k], mat, k in ["tree", "tree_round", "dead_tree", "rock", "gravestone", "lantern"], k in ["tree", "tree_round", "dead_tree"] )


func _scatter_tail() -> void:
	_sc_sets = {}
	_scatter_mundo()
	_scatter_lights()


func _scatter_mundo() -> void:
	Cenario.build(self, sim)   # regiões com tema, margem florida, nada na pista


func _scatter_lights() -> void:
	for i in 6:
		var l := _light(Vector3.ZERO, Color(1.0, 0.7, 0.35), 1.6, 9.0)
		add_child(l)
		lantern_lights.append(l)


# ---------------------------------------------------------------- locais e covil

func _road_dir_at(loc: Dictionary) -> Vector2:
	var pts: PackedVector2Array = sim.road.legs[loc["leg"]]["pts"][loc["branch"]]
	var p: Vector2 = loc["pos"]
	var best := 0
	var bd := INF
	for i in pts.size():
		var d := p.distance_squared_to(pts[i])
		if d < bd:
			bd = d
			best = i
	return (pts[mini(best + 1, pts.size() - 1)] - pts[maxi(best - 1, 0)]).normalized()


func _build_locations() -> void:
	for li in sim.road.locations.size():
		var loc: Dictionary = sim.road.locations[li]
		var t: String = loc["type"]
		var p: Vector2 = loc["pos"]
		var dir := _road_dir_at(loc)
		var side := dir.orthogonal()
		var yaw := atan2(-dir.x, -dir.y)
		var n := Node3D.new()
		n.position = Vector3(p.x, 0, p.y)
		add_child(n)
		var col: Color = LOC_COLORS[t]
		var off := Vector3(side.x, 0, side.y)
		var fwd := Vector3(dir.x, 0, dir.y)
		match t:
			"shop":
				# Loja: uma casa, a banca com o ouro à mostra e lanternas.
				n.add_child(_mi(Models.prop("house"), off * 7.0, null, yaw + PI * 0.5))
				n.add_child(_mi(Models.prop("fence"), off * 4.2 - fwd * 2.5, null, yaw))
				n.add_child(_mi(Models.prop("coins"), off * 4.6 + fwd * 1.2 + Vector3(0, 0.6, 0)))
				n.add_child(_mi(Models.prop("lantern"), off * 4.0 + fwd * 3.5, null, yaw))
			"tavern":
				# Diorama: a frente da taverna (porta, placa, barris) vira para a estrada e para a câmera (+z).
				var tf := (-off).lerp(Vector3(0, 0, 1), 0.55).normalized()
				n.add_child(_mi(Models.prop("tavern"), off * 7.0, null, atan2(tf.x, tf.z)))
				n.add_child(_mi(Models.prop("fence"), off * 4.0 + fwd * 4.0, null, yaw))
			"fountain":
				n.add_child(_mi(Models.prop("fountain"), off * 5.0))
			"ritual":
				n.add_child(_mi(Models.prop("ritual"), Vector3.ZERO))
				for i in 3:
					n.add_child(_mi(Models.prop("gravestone"), off * (7.0 + i) + fwd * (i * 3.0 - 3.0), null, yaw + 0.3 * i))
			"shrine":
				n.add_child(_mi(Models.prop("shrine"), off * 3.5))
			"bridge":
				# A água é o rio de verdade (_build_rivers); aqui só a ponte, no eixo da estrada.
				var bmi := _bridge_mesh(yaw)
				n.add_child(bmi)
				_add_surface(p, [bmi])
			"event":
				# Encruzilhada "?": placa, pedras e lanterna.
				n.add_child(_mi(Models.prop("fence"), off * 3.5, null, yaw))
				n.add_child(_mi(Models.prop("gravestone"), off * 4.5 + fwd * 1.5, null, yaw + 0.4))
				n.add_child(_mi(Models.prop("lantern"), off * 3.0 - fwd * 2.0, null, yaw))
			"helper":
				# Herói Ajudante: acampamento atrás de onde ele fica (cerca, braseiro, lanterna e um estandarte dourado).
				var hs: Vector2 = sim.helper_spot(li) - p
				var hv := Vector3(hs.x, 0, hs.y)
				var back := hv.normalized()
				n.add_child(_mi(Models.prop("fence"), hv + back * 3.0, null, yaw))
				n.add_child(_mi(Models.prop("brazier"), hv + back * 2.2 + fwd * 2.4))
				n.add_child(_mi(Models.prop("lantern"), hv + back * 2.0 - fwd * 2.4, null, yaw))
				var pole := MeshInstance3D.new()
				var pm := CylinderMesh.new()
				pm.top_radius = 0.06
				pm.bottom_radius = 0.08
				pm.height = 3.6
				pole.mesh = pm
				pole.material_override = _unshaded(Color(0.35, 0.24, 0.14), 0.6)
				pole.position = hv + back * 1.6 + Vector3(0, 1.8, 0)
				n.add_child(pole)
				var flag := MeshInstance3D.new()
				var fm := BoxMesh.new()
				fm.size = Vector3(0.05, 0.9, 1.2)
				flag.mesh = fm
				flag.material_override = _unshaded(col, 1.2)
				flag.position = hv + back * 1.6 + Vector3(0, 3.1, 0) + fwd * 0.6
				flag.rotation.y = yaw
				n.add_child(flag)
				# Exclamação dourada sobre o acampamento (o ícone do mapa).
				var ex := Label3D.new()
				ex.text = "!"
				ex.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				ex.font_size = 120
				ex.outline_size = 18
				ex.modulate = col
				ex.position = hv + Vector3(0, 4.4, 0)
				n.add_child(ex)
				n.set_meta("bang", ex)
		if t in ["shrine", "ritual", "fountain", "tavern", "bridge", "helper"]:
			var ring := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = float(loc["r"]) - 0.12
			tm.outer_radius = float(loc["r"])
			tm.rings = 48
			tm.ring_segments = 3
			ring.mesh = tm
			ring.material_override = _unshaded(Color(col.r, col.g, col.b, 0.5), 1.3)
			ring.scale = Vector3(1, 0.2, 1)
			ring.position.y = 0.05
			n.add_child(ring)
			n.set_meta("ring", ring)
		n.add_child(_light(Vector3(0, 3.5, 0) + off * 2.0, col, 2.4, 15.0))
		var lab := Label3D.new()
		lab.text = tr("LOC_" + t)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.font_size = 56
		lab.outline_size = 14
		lab.modulate = col.lightened(0.35)
		lab.position = Vector3(0, 6.0, 0)
		lab.no_depth_test = true
		n.add_child(lab)
		n.set_meta("lab", lab)
		loc_nodes.append(n)


func _build_lair() -> void:
	# Só o último ato termina no covil; nos outros o fim da estrada é um portão de passagem.
	if sim.act + 1 < sim.acts():
		var gp := sim.road.lair + sim.road.lair_dir * 8.0
		var gyaw := atan2(-sim.road.lair_dir.x, -sim.road.lair_dir.y)
		var gate := _mi(Models.prop("gate"), Vector3(gp.x, 0, gp.y), Models.glow_material(0.05), gyaw + PI)
		add_child(gate)
		add_child(_light(Vector3(gp.x, 5, gp.y), Color(1.0, 0.7, 0.35), 3.0, 22.0))
		return
	var lp := sim.road.lair + sim.road.lair_dir * 34.0
	var yaw := atan2(-sim.road.lair_dir.x, -sim.road.lair_dir.y)
	lair_pos = Vector3(lp.x, 0, lp.y)
	var castle := _mi(Models.prop("castle"), Vector3(lp.x, 0, lp.y), Models.glow_material(0.05), yaw + PI)
	# Peça de fundo: a sombra dela cobria a arena inteira com uma cunha de borda reta.
	castle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lair_node = castle
	add_child(castle)
	add_child(_light(Vector3(lp.x, 8, lp.y), Color(0.8, 0.3, 1.0), 4.0, 40.0))


# ---------------------------------------------------------------- unidades e herói

func _build_units() -> void:
	for c in sim.data.cards:
		if not c.is_unit:
			continue
		var cap := 320 if c.arch == K.Arch.SWARM or c.id in ["skeleton", "spectre", "slime", "rat"] else 96
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = Looks.unit_mesh(c.id)
		mm.instance_count = cap
		mm.visible_instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		var mat := Looks.unit_material(0.3 if c.id in ["ghost", "spectre"] else 0.0, true)
		if c.fly:
			Looks.set_param(mat, "flap", 1.0)
		mmi.material_override = mat
		mmi.custom_aabb = AABB(Vector3(-3000, -10, -3000), Vector3(6000, 40, 6000))
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if cap > 96 or c.radius < 0.5 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mmi)
		var buf := PackedFloat32Array()
		buf.resize(cap * STRIDE)
		var hop := 1.0 if c.arch == K.Arch.SWARM else (0.5 if c.arch != K.Arch.STRUCTURE else 0.0)
		if c.id == "slime":
			hop = 1.2
		if c.fly:
			hop = 0.0
		var acc: Color = ACCENT.get(c.id, Color(0.8, 0.6, 1.0))
		acc.a = 0.35 if c.arch == K.Arch.SWARM else 0.55
		mm_by_def[c.idx] = {"mm": mm, "buf": buf, "cap": cap, "hop": hop, "fly": c.fly, "struct": c.arch == K.Arch.STRUCTURE,
			"rad": maxf(c.radius, 0.35) * 1.35, "acc": acc, "scl": Looks.scale_of(c.id) * FIG_SCALE}
	ring_mm = MultiMesh.new()
	ring_mm.transform_format = MultiMesh.TRANSFORM_3D
	ring_mm.use_colors = true
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	ring_mm.mesh = pm
	ring_mm.instance_count = sim.units.cap
	ring_mm.visible_instance_count = 0
	ring_buf.resize(sim.units.cap * 16)
	var rmi := MultiMeshInstance3D.new()
	rmi.multimesh = ring_mm
	rmi.material_override = ring_material(Color.WHITE, 0.14, 0.06)
	rmi.custom_aabb = AABB(Vector3(-3000, -10, -3000), Vector3(6000, 40, 6000))
	rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rmi)


func ring_material(col: Color, edge: float, fill: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://game/art/ring.gdshader")
	m.set_shader_parameter("tint", col)
	m.set_shader_parameter("edge", edge)
	m.set_shader_parameter("fill", fill)
	return m


func _part(parent: Node3D, id: String, pos: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	var mi := MeshInstance3D.new()
	mi.mesh = Looks.hero_mesh(id)
	mi.material_override = hero_mat
	pivot.add_child(mi)
	return pivot


func _build_hero() -> void:
	hero_root = Node3D.new()
	hero_root.scale = Vector3.ONE * HERO_SCALE * HeroPresence.scale_mult()
	add_child(hero_root)
	hero_mat = Looks.hero_material(0.05)
	body = Node3D.new()
	hero_root.add_child(body)
	leg_l = _part(body, "leg", Vector3(-0.16, 0.72, 0))
	leg_r = _part(body, "leg", Vector3(0.16, 0.72, 0))
	_part(body, "torso", Vector3(0, 0.75, 0))
	head = _part(body, "head", Vector3(0, 1.4, 0))
	arm_s = _part(body, "arm_sword", Vector3(0.48, 1.33, 0))
	arm_h = _part(body, "arm_shield", Vector3(-0.48, 1.33, 0))
	cape = _part(body, "cape", Vector3(0, 1.4, 0.24))
	# Look com esqueleto (Looks.hero_rig): as peças acima ficam vazias e o rig se anima sozinho.
	rig_cls = sim.hero.cls() if sim else "escudeiro"
	var rig := Looks.hero_rig(hero_mat, rig_cls)
	hero_rig_node = rig
	if rig:
		body.add_child(rig)
	hero_light = _light(Vector3(0, 3.0, 0), Color(1.0, 0.72, 0.42), 1.1, 11.0)
	hero_root.add_child(hero_light)
	slash = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.2
	tm.outer_radius = 1.9
	tm.rings = 24
	tm.ring_segments = 3
	slash.mesh = tm
	slash_mat = _unshaded(Color(0.85, 0.92, 1.0, 0.0), 2.5)
	slash_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	slash.material_override = slash_mat
	slash.scale = Vector3(1, 0.05, 1)
	slash.position = Vector3(0, 1.1, -0.4)
	hero_root.add_child(slash)
	ghost = MeshInstance3D.new()
	var gm := PlaneMesh.new()
	gm.size = Vector2(2, 2)
	ghost.mesh = gm
	ghost_mat = ring_material(Color(0.4, 1, 0.5, 0.9), 0.1, 0.22)
	ghost_mat.set_shader_parameter("pulse", 0.6)
	ghost_mat.set_shader_parameter("glow", 1.6)
	ghost.material_override = ghost_mat
	add_child(ghost)
	show_placement(false, Vector3.ZERO, true, 1.0)
	flash_light = _light(Vector3.ZERO, Color(1, 0.6, 0.3), 0.0, 16.0)
	add_child(flash_light)
	bubble = Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.font_size = 64
	bubble.outline_size = 16
	bubble.outline_modulate = Color(0.1, 0.05, 0.15)
	bubble.visible = false
	add_child(bubble)
	tell_label = Label3D.new()
	tell_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tell_label.no_depth_test = true
	tell_label.font_size = 72
	tell_label.outline_size = 18
	tell_label.outline_modulate = Color(0.25, 0.02, 0.02)
	tell_label.modulate = Color(1.0, 0.85, 0.3)
	tell_label.visible = false
	add_child(tell_label)


func _circle(r: float, col: Color, half_w := 0.07, energy := 1.2) -> MeshInstance3D:
	var tm := TorusMesh.new()
	tm.inner_radius = r - half_w
	tm.outer_radius = r + half_w
	tm.rings = 72
	tm.ring_segments = 4
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = _unshaded(col, energy)
	return mi


# ---------------------------------------------------------------- partículas

func _ramp(cols: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	for i in cols.size():
		offs.append(float(i) / (cols.size() - 1))
	g.offsets = offs
	g.colors = PackedColorArray(cols)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _emitter(d: Dictionary) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = d["amount"]
	p.lifetime = d["life"]
	p.one_shot = true
	p.explosiveness = d.get("expl", 0.95)
	p.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = d["speed"][0]
	pm.initial_velocity_max = d["speed"][1]
	pm.gravity = Vector3(0, -float(d.get("grav", 0.0)), 0)
	pm.damping_min = d.get("damp", 0.0)
	pm.damping_max = d.get("damp", 0.0)
	pm.scale_min = d["size"][0]
	pm.scale_max = d["size"][1]
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = d.get("radius", 0.3)
	pm.color_ramp = _ramp(d["ramp"])
	var cv := Curve.new()
	if d.get("grow", false):
		cv.add_point(Vector2(0, 0.4))
		cv.add_point(Vector2(1, 1.0))
	else:
		cv.add_point(Vector2(0, 1))
		cv.add_point(Vector2(0.6, 0.8))
		cv.add_point(Vector2(1, 0))
	var ct := CurveTexture.new()
	ct.curve = cv
	pm.scale_curve = ct
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.5)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = soft_tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if d.get("add", true):
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	q.material = m
	p.draw_pass_1 = q
	p.visibility_aabb = AABB(Vector3(-12, -3, -12), Vector3(24, 16, 24))
	return p


func _build_pools() -> void:
	var W := Color(1, 1, 1, 1)
	var Z := Color(1, 1, 1, 0)
	var defs := {
		"spark": {"amount": 20, "life": 0.45, "speed": [6.0, 13.0], "grav": 16.0, "size": [0.25, 0.5], "ramp": [Color(1, 1, 0.9), Color(1, 0.7, 0.3), Color(1, 0.3, 0.1, 0)], "n": 10},
		"hit": {"amount": 8, "life": 0.3, "speed": [3.0, 7.0], "grav": 10.0, "size": [0.25, 0.45], "ramp": [W, Color(1, 0.9, 0.7), Z], "n": 16},
		"fire": {"amount": 34, "life": 0.75, "speed": [2.0, 6.0], "grav": -4.0, "damp": 3.0, "size": [1.4, 2.6], "radius": 0.8, "ramp": [Color(1, 0.95, 0.6), Color(1, 0.55, 0.15), Color(0.8, 0.15, 0.05), Color(0.3, 0.05, 0.02, 0)], "n": 10},
		"smoke": {"amount": 16, "life": 1.6, "speed": [1.0, 3.0], "grav": -1.6, "damp": 1.0, "size": [1.6, 3.0], "radius": 0.9, "grow": true, "add": false, "ramp": [Color(0.25, 0.2, 0.25, 0.7), Color(0.18, 0.15, 0.2, 0.4), Color(0.1, 0.1, 0.12, 0)], "n": 8},
		"death": {"amount": 14, "life": 0.6, "speed": [2.0, 5.0], "grav": 8.0, "size": [0.35, 0.7], "add": false, "ramp": [W, Color(1, 1, 1, 0.8), Z], "n": 18},
		"soul": {"amount": 6, "life": 1.1, "speed": [0.5, 1.5], "grav": -3.0, "size": [0.5, 0.9], "ramp": [Color(0.5, 1, 0.85), Color(0.3, 0.9, 1.0, 0.6), Color(0.2, 0.5, 1.0, 0)], "n": 16},
		"level": {"amount": 70, "life": 1.3, "speed": [3.0, 8.0], "grav": -3.0, "damp": 1.5, "size": [0.4, 0.9], "radius": 1.2, "ramp": [Color(1, 1, 0.8), Color(1, 0.85, 0.3), Color(1, 0.5, 0.1, 0)], "n": 4},
		"magic": {"amount": 36, "life": 0.8, "speed": [2.0, 6.0], "grav": -1.0, "damp": 2.0, "size": [0.5, 1.1], "radius": 0.8, "ramp": [Color(1, 0.8, 1), Color(0.75, 0.3, 1.0), Color(0.3, 0.1, 0.6, 0)], "n": 8},
		"shield": {"amount": 26, "life": 0.6, "speed": [5.0, 10.0], "grav": 12.0, "size": [0.3, 0.6], "ramp": [W, Color(0.6, 0.85, 1.0), Color(0.3, 0.5, 1.0, 0)], "n": 4},
		"heal": {"amount": 22, "life": 1.1, "speed": [1.0, 3.0], "grav": -3.5, "size": [0.4, 0.8], "radius": 0.8, "ramp": [Color(0.8, 1, 0.8), Color(0.4, 1.0, 0.5), Color(0.2, 0.8, 0.3, 0)], "n": 4},
	}
	for k in defs:
		var d: Dictionary = defs[k]
		var list: Array = []
		for i in int(d["n"]):
			var p := _emitter(d)
			add_child(p)
			list.append(p)
		fx[k] = {"list": list, "i": 0}
	# Vaga-lumes: partículas ambientes que acompanham o herói.
	fireflies = _emitter({"amount": 140, "life": 7.0, "speed": [0.2, 0.6], "grav": 0.0, "size": [0.08, 0.16], "radius": 1.0,
		"ramp": [Color(0.6, 1.0, 0.5, 0), Color(0.75, 1.0, 0.45, 1), Color(0.6, 1.0, 0.5, 0)], "expl": 0.0})
	fireflies.one_shot = false
	var fpm: ParticleProcessMaterial = fireflies.process_material
	fpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	fpm.emission_box_extents = Vector3(40, 3, 40)
	fpm.turbulence_enabled = true
	fpm.turbulence_noise_strength = 1.5
	fireflies.visibility_aabb = AABB(Vector3(-60, -5, -60), Vector3(120, 20, 120))
	fireflies.emitting = true
	add_child(fireflies)
	var dtex := GradientTexture2D.new()
	var dg := Gradient.new()
	dg.offsets = PackedFloat32Array([0.0, 1.0])
	dg.colors = PackedColorArray([Color(0.05, 0.03, 0.03, 0.85), Color(0.05, 0.03, 0.03, 0.0)])
	dtex.gradient = dg
	dtex.fill = GradientTexture2D.FILL_RADIAL
	dtex.fill_from = Vector2(0.5, 0.5)
	dtex.fill_to = Vector2(0.5, 0.0)
	for i in 12:
		var dc := Decal.new()
		dc.texture_albedo = dtex
		dc.size = Vector3(4, 2, 4)
		dc.visible = false
		add_child(dc)
		decal_pool.append({"n": dc, "t": 0.0})
	for i in 24:
		var z := MeshInstance3D.new()
		var cm := PlaneMesh.new()
		cm.size = Vector2(2, 2)
		z.mesh = cm
		z.material_override = ring_material(Color.WHITE, 0.08, 0.2)
		z.visible = false
		add_child(z)
		var coins := _mi(Models.prop("coins"), Vector3.ZERO, Models.glow_material(0.6))
		coins.visible = false
		add_child(coins)
		zone_pool.append({"disc": z, "coins": coins})
	for i in 64:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.font_size = 52
		l.outline_size = 18
		l.outline_modulate = Color(0.06, 0.02, 0.08)
		# Números e avisos no mundo na fonte dos títulos da interface (pele Covil).
		l.visible = false
		add_child(l)
		number_pool.append({"n": l, "t": 0.0, "v": Vector3.ZERO})
	for i in 16:
		var e := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.85
		tm.outer_radius = 1.0
		tm.rings = 32
		tm.ring_segments = 4
		e.mesh = tm
		var bm := _unshaded(Color(1, 0.6, 0.2, 0.8), 2.5)
		bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		e.material_override = bm
		e.visible = false
		add_child(e)
		burst_pool.append({"n": e, "t": 0.0, "r": 1.0})
	for i in 32:
		var s := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(0.08, 0.08, 1.0)
		s.mesh = bx
		s.material_override = _unshaded(Color(1, 0.95, 0.7), 3.0)
		s.visible = false
		add_child(s)
		shot_pool.append({"n": s, "t": 0.0})
	for i in 16:
		var hn := Node3D.new()
		var arrow := MeshInstance3D.new()
		var ab := BoxMesh.new()
		ab.size = Vector3(0.07, 0.07, 0.75)
		arrow.mesh = ab
		arrow.material_override = _unshaded(Color(1.0, 0.93, 0.7), 2.5)
		hn.add_child(arrow)
		var orbm := MeshInstance3D.new()
		var osph := SphereMesh.new()
		osph.radius = 0.24
		osph.height = 0.48
		osph.radial_segments = 10
		osph.rings = 5
		orbm.mesh = osph
		orbm.material_override = _unshaded(Color(0.65, 0.5, 1.0), 4.0)
		hn.add_child(orbm)
		hn.visible = false
		add_child(hn)
		hshot_pool.append({"n": hn, "arrow": arrow, "orb": orbm, "t": 0.0, "T": 0.1, "a": Vector3.ZERO, "b": Vector3.ZERO})
	var om := SphereMesh.new()
	om.radius = 0.16
	om.height = 0.32
	om.radial_segments = 8
	om.rings = 4
	for i in 48:
		var o := MeshInstance3D.new()
		o.mesh = om
		o.material_override = _unshaded(Color(0.6, 1.0, 0.85), 4.0)
		o.visible = false
		add_child(o)
		orb_pool.append({"n": o, "t": 0.0, "from": Vector3.ZERO})
	_build_fx2()


## Presença dos heróis, golpes e efeitos do mundo (FX2).
func _build_fx2() -> void:
	presence = HeroPresence.new()
	add_child(presence)
	if gol != null:
		gol.queue_free()
	gol = Golpes.new()
	add_child(gol)
	gol.setup(self)
	fx2 = FX2.new()
	add_child(fx2)
	fx2.setup()
	for e in zone_pool:
		(e["disc"] as MeshInstance3D).material_override = fx2.ground_material(6)
	for e in decal_pool:
		(e["n"] as Decal).texture_albedo = fx2.scorch_tex
	var streak: Material = fx2.streak_material()
	for e in shot_pool:
		var s: MeshInstance3D = e["n"]
		var q := QuadMesh.new()
		q.size = Vector2(1, 1)
		s.mesh = q
		s.material_override = streak
		s.extra_cull_margin = 16.0   # o quad é esticado no shader ao longo do tiro; a caixa dele não vê isso
	for e in hshot_pool:
		var hn: Node3D = e["n"]
		for c in hn.get_children():
			c.queue_free()
		var arrow: Node3D = fx2.make_arrow()
		var orbn: Node3D = fx2.make_orb()
		hn.add_child(arrow)
		hn.add_child(orbn)
		e["arrow"] = arrow
		e["orb"] = orbn


func _build_bars() -> void:
	bar_mm = MultiMesh.new()
	bar_mm.transform_format = MultiMesh.TRANSFORM_3D
	bar_mm.use_colors = true
	var q := QuadMesh.new()
	q.size = Vector2(1.4, 0.16)
	bar_mm.mesh = q
	bar_mm.instance_count = 384     # 3 quadros por barra (aro dourado, trilho, vida): até 128 barras
	bar_mm.visible_instance_count = 0
	bar_buf.resize(384 * 16)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = bar_mm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = true
	m.render_priority = 2
	mmi.material_override = m
	mmi.custom_aabb = AABB(Vector3(-3000, -10, -3000), Vector3(6000, 40, 6000))
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func build_arena() -> void:
	arena_root = Node3D.new()
	add_child(arena_root)
	var A := sim.arena
	var c := Vector3(A.cx, 0, A.cy)
	var r: float = sim.data.rules["arena"]["radius"]
	if Models.has_dir_prop("arena"):
		# Piso de lajes da direção (raio 1 m no arquivo): escala pelo raio da regra.
		var fl := _mi(Models.prop("arena"), c)
		fl.scale = Vector3(r + 1.0, 1.0, r + 1.0)
		arena_root.add_child(fl)
	var k := Models.Kit.new()
	k.add(Models.cyl(r + 1.0, r + 1.2, 0.3, 40), Vector3(0, -0.12, 0), Color(0.18, 0.14, 0.22))
	if not Models.has_dir_prop("arena"):
		arena_root.add_child(_mi(k.done(), c))
	var n := 10
	var braziers: Array = []
	for i in n:
		var a := TAU * i / n
		var pp := c + Vector3(cos(a), 0, sin(a)) * (r + 2.5)
		arena_root.add_child(_mi(Models.prop("pillar" if i % 2 == 0 else "brazier"), pp))
		if i % 2 == 1:
			braziers.append(pp)
			arena_root.add_child(_light(pp + Vector3(0, 2.5, 0), ArenaLook.flame_color(), 3.0, 14.0))
	var cl: Array = ArenaLook.center_light()
	arena_root.add_child(_light(c + Vector3(0, 7, 0), cl[0], cl[1], 26.0))
	ArenaLook.build(arena_root, c, r, braziers)
	# Chefe do vilão da run (Etapa D, 11/11/2026): modelo e posições das partes de BossModels.
	boss_offs = BossModels.part_offsets(sim.deck_id)
	if BossModels.has_model(sim.deck_id):
		for ex in BossModels.EXTRAS.get(sim.deck_id, []):
			var em := _mi(BossModels.part(sim.deck_id, ex), Vector3(A.bx, 0, A.by), Models.glow_material(0.15))
			arena_root.add_child(em)
	for id in A.part_ids:
		var p := _mi(BossModels.part(sim.deck_id, id), Vector3(A.bx, 0, A.by) + boss_offs[id], Models.glow_material(0.15))
		arena_root.add_child(p)
		part_nodes.append(p)
		part_flash.append(0.0)
	for i in A.altar_pos.size():
		var ap: Vector2 = A.altar_pos[i]
		var a2 := _mi(Models.prop("altar"), Vector3(ap.x, 0, ap.y))
		var lab := Label3D.new()
		lab.text = str(i + 1)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.font_size = 80
		lab.outline_size = 16
		lab.modulate = Color(0.85, 0.7, 1.0)
		lab.position = Vector3(0, 2.2, 0)
		lab.no_depth_test = true
		a2.add_child(lab)
		arena_root.add_child(a2)
		altar_nodes.append(a2)
	for i in A.pillar_pos.size():
		var pp2: Vector2 = A.pillar_pos[i]
		var pn := _mi(Models.prop("pillar"), Vector3(pp2.x, 0, pp2.y))
		pn.scale = Vector3(1.1, 0.75, 1.1)
		arena_root.add_child(pn)
		pillar_nodes.append(pn)
	boss_face = MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.25, 0.05, 6.0)
	boss_face.mesh = fm
	boss_face.material_override = _unshaded(Color(1, 0.3, 0.3, 0.45), 1.5)
	arena_root.add_child(boss_face)


## Um círculo proibido por herói: 3 m, ou o alcance de ataque nos heróis à distância.
func _update_rings(on: bool) -> void:
	var hs: Array = sim.ring_heroes() if sim != null else []
	while ring_nodes.size() < hs.size():
		var n := _circle(3.0, Color(1.0, 0.25, 0.2, 1.0), 0.11, 0.8)
		add_child(n)
		ring_nodes.append(n)
		ring_rad.append(3.0)
	for i in ring_nodes.size():
		var n: MeshInstance3D = ring_nodes[i]
		n.visible = on and i < hs.size()
		if i >= hs.size():
			continue
		var h: SimHero = hs[i]
		var r: float = sim.ring_of(h)
		if not is_equal_approx(float(ring_rad[i]), r):
			var tm := n.mesh as TorusMesh
			tm.inner_radius = r - 0.11
			tm.outer_radius = r + 0.11
			ring_rad[i] = r
		n.position = Vector3(lerpf(h.ox, h.x, 1.0), 0.06, lerpf(h.oy, h.y, 1.0))
		n.position.y += surface_y(n.position.x, n.position.z)


func show_placement(on: bool, pos: Vector3, valid: bool, radius: float) -> void:
	_update_rings(on)
	ghost.visible = on
	if not on:
		return
	ghost.position = pos + Vector3(0, 0.05 + surface_y(pos.x, pos.z), 0)
	ghost.scale = Vector3(radius, 1, radius)
	var c := Color(0.4, 1, 0.5, 0.9) if valid else Color(1, 0.3, 0.3, 0.9)
	ghost_mat.set_shader_parameter("tint", c)


# ---------------------------------------------------------------- desenho

func draw(alpha: float, delta: float) -> void:
	_pre_tick()
	if sim == null:
		return
	frame += 1
	budget = {"hit": 6, "death": 6, "num": 10}
	_draw_units(alpha, delta)
	_draw_bars(alpha)
	_draw_hero(alpha, delta)
	_draw_road_state()
	_draw_zones()
	_draw_arena(delta)
	_tick_pools(delta, alpha)
	_lanterns()
	_camera(alpha, delta)
	screen_flash.a = maxf(0.0, screen_flash.a - delta * 2.5)


func _draw_units(alpha: float, delta: float) -> void:
	var U := sim.units
	var lists := {}
	for k in mm_by_def:
		lists[k] = []
	var decay := exp(-delta * 9.0)
	for i in U.hi:
		if U.alive[i] == 1 and lists.has(U.def[i]):
			lists[U.def[i]].append(i)
		if flash[i] > 0.0:
			flash[i] = maxf(0.0, flash[i] - delta * 6.0)
		kx[i] *= decay
		ky[i] *= decay
	var hx := sim.hero.x
	var hy := sim.hero.y
	if gol != null:
		gol.begin(sim.t, alpha, sim.dt, U.cap, delta)
	var rb := ring_buf
	ring_buf = PackedFloat32Array()
	var rn := 0
	for k in mm_by_def:
		var e: Dictionary = mm_by_def[k]
		var mm: MultiMesh = e["mm"]
		var ids: Array = lists[k]
		var n := mini(ids.size(), int(e["cap"]))
		mm.visible_instance_count = n
		if n == 0:
			continue
		var buf: PackedFloat32Array = e["buf"]
		e["buf"] = PackedFloat32Array()
		var hop: float = e["hop"]
		var fly: bool = e["fly"]
		var is_struct: bool = e["struct"]
		for q in n:
			var i: int = ids[q]
			var s: float = e["scl"]
			if U.gen[i] > 0:
				s *= 0.72 if U.gen[i] == 1 else 0.5
			# Surgir com "pop": passa um pouco do tamanho e volta (back-out).
			var age := U.timer[i]
			if age < 0.3:
				var t := age / 0.3 - 1.0
				s *= maxf(0.05, 1.0 + 2.70158 * t * t * t + 1.70158 * t * t)
			var x := lerpf(U.ox[i], U.px[i], alpha) + kx[i]
			var z := lerpf(U.oy[i], U.py[i], alpha) + ky[i]
			var vx := U.px[i] - U.ox[i]
			var vz := U.py[i] - U.oy[i]
			var moving := clampf(sqrt(vx * vx + vz * vz) / (sim.dt * 1.5), 0.0, 1.0)
			var fx_ := hx - x
			var fz := hy - z
			if U.fear_t[i] > 0.0:
				fx_ = -fx_
				fz = -fz
			var a := atan2(-fx_, -fz)
			var ca := cos(a) * s
			var sa := sin(a) * s
			var col := Color.WHITE
			if U.flags[i] & K.F_STONE:
				col = Color(0.55, 0.55, 0.6)
			elif U.fear_t[i] > 0.0:
				col = Color(0.8, 0.6, 1.0)
			elif U.flags[i] & K.F_LEECH:
				col = Color(1.0, 0.74, 0.78)   # Rouba-vida: pele avermelhada; o anel no chão é carmim
			elif U.sh[i] > 0.0:
				col = Color(0.8, 0.84, 1.0)    # Sombrio com escudo: tom frio; o anel no chão é azul-violeta
			var gy := surface_y(x, z) if not surf_fields.is_empty() else 0.0
			var y := gy
			if fly:
				y = gy + 1.6 + sin(sim.t * 7.0 + i) * 0.25
			var lunge := 0.0
			if not is_struct and U.atk_int[i] > 0.0:
				lunge = clampf((U.atk_t[i] - (U.atk_int[i] - 0.2)) / 0.2, 0.0, 1.0)
			var sy := s
			if gol != null and not is_struct:
				# --golpes=1: ataque no tempo do dano (preparo, golpe, impacto), avanço e agacha-e-estica. Estruturas
				# ficam como antes (sem ataque): não deu para conferir a torre em vídeo nesta rodada.
				lunge = gol.unit(U, i, x, z, hx - x, hy - z, gy, float(e["rad"]) * s, moving, e["acc"])
				x += gol.ox
				z += gol.oz
				sy = s * gol.sy
				ca *= gol.sxz
				sa *= gol.sxz
			var o := q * STRIDE
			buf[o] = ca; buf[o + 1] = 0.0; buf[o + 2] = sa; buf[o + 3] = x
			buf[o + 4] = 0.0; buf[o + 5] = sy; buf[o + 6] = 0.0; buf[o + 7] = y
			buf[o + 8] = -sa; buf[o + 9] = 0.0; buf[o + 10] = ca; buf[o + 11] = z
			buf[o + 12] = col.r; buf[o + 13] = col.g; buf[o + 14] = col.b; buf[o + 15] = 1.0
			buf[o + 16] = flash[i]; buf[o + 17] = hop * maxf(moving, 0.25 if hop > 0.0 else 0.0); buf[o + 18] = float(i) * 1.7; buf[o + 19] = lunge
			var rr: float = e["rad"] * s
			var acc: Color = e["acc"]
			if U.sh[i] > 0.0:
				# Escudo de vida do Sombrio: anel azul-violeta que pulsa (some quando o escudo quebra).
				acc = Color(0.5, 0.55, 1.0, 0.75 + 0.2 * sin(sim.t * 5.0 + i))
				rr *= 1.12
			elif U.flags[i] & K.F_LEECH:
				acc = Color(0.9, 0.1, 0.22, 0.9)   # Rouba-vida: anel carmim
			var ro := rn * 16
			rb[ro] = rr; rb[ro + 1] = 0.0; rb[ro + 2] = 0.0; rb[ro + 3] = x
			rb[ro + 4] = 0.0; rb[ro + 5] = 1.0; rb[ro + 6] = 0.0; rb[ro + 7] = 0.055 + gy
			rb[ro + 8] = 0.0; rb[ro + 9] = 0.0; rb[ro + 10] = rr; rb[ro + 11] = z
			rb[ro + 12] = acc.r; rb[ro + 13] = acc.g; rb[ro + 14] = acc.b; rb[ro + 15] = acc.a
			rn += 1
		mm.buffer = buf
		e["buf"] = buf
	ring_mm.visible_instance_count = rn
	if rn > 0:
		ring_mm.buffer = rb
	ring_buf = rb


func _draw_bars(alpha: float) -> void:
	var U := sim.units
	var n := 0
	var buf := bar_buf
	bar_buf = PackedFloat32Array()
	for i in U.hi:
		if n >= 381:
			break
		if U.alive[i] == 0 or U.max_hp[i] < 300.0 or U.hp[i] >= U.max_hp[i]:
			continue
		var f := clampf(U.hp[i] / U.max_hp[i], 0.0, 1.0)
		var x := lerpf(U.ox[i], U.px[i], alpha)
		var z := lerpf(U.oy[i], U.py[i], alpha)
		var y := 3.0 if U.arch[i] != K.Arch.STRUCTURE else 3.9
		# Rodada de UI 13/11/2026: o mesmo desenho das barras da interface (aro dourado, trilho escuro, vida do
		# vermelho-sangue ao verde-musgo da paleta do pergaminho), no lugar do vermelho→verde neon.
		for pass_ in 3:
			var o := n * 16
			var sx: float = [1.07, 1.0, maxf(f, 0.02)][pass_]
			var sy: float = [1.5, 1.0, 0.62][pass_]
			var c: Color = [Color(0.8, 0.58, 0.2, 0.95), Color(0.12, 0.08, 0.05, 0.92),
				Color(0.62, 0.1, 0.07).lerp(Color(0.42, 0.66, 0.26), f)][pass_]
			buf[o] = sx; buf[o + 1] = 0.0; buf[o + 2] = 0.0; buf[o + 3] = x
			buf[o + 4] = 0.0; buf[o + 5] = sy; buf[o + 6] = 0.0; buf[o + 7] = y
			buf[o + 8] = 0.0; buf[o + 9] = 0.0; buf[o + 10] = 1.0; buf[o + 11] = z
			buf[o + 12] = c.r; buf[o + 13] = c.g; buf[o + 14] = c.b; buf[o + 15] = c.a
			n += 1
	bar_mm.visible_instance_count = n
	if n > 0:
		bar_mm.buffer = buf
	bar_buf = buf


## Ponte e rio ficam acima do chão (o tabuleiro a ~0,4 m, a água a ~0,1 m): sem isto o círculo de mira, as
## unidades e o herói eram desenhados por baixo deles e pareciam não poder ir ali.
func _add_surface(center: Vector2, mis: Array) -> void:
	var half := 18.0
	var n := int(half * 2.0 / SURF_STEP)
	var o := center - Vector2(half, half)
	var h := PackedFloat32Array()
	h.resize(n * n)
	h.fill(0.0)
	for mi in mis:
		var mesh: Mesh = mi.mesh
		if mesh == null:
			continue
		var xf := Transform3D(mi.transform.basis, Vector3(center.x, 0.0, center.y) + mi.position)
		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var tri_n := idx.size() / 3 if idx.size() > 0 else v.size() / 3
			for t in tri_n:
				var a := xf * v[idx[t * 3] if idx.size() > 0 else t * 3]
				var b := xf * v[idx[t * 3 + 1] if idx.size() > 0 else t * 3 + 1]
				var c := xf * v[idx[t * 3 + 2] if idx.size() > 0 else t * 3 + 2]
				if maxf(a.y, maxf(b.y, c.y)) > SURF_MAX + 0.2:
					continue
				var den := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
				if absf(den) < 1e-5:
					continue
				var i0 := clampi(int((minf(a.x, minf(b.x, c.x)) - o.x) / SURF_STEP), 0, n - 1)
				var i1 := clampi(int((maxf(a.x, maxf(b.x, c.x)) - o.x) / SURF_STEP) + 1, 0, n - 1)
				var j0 := clampi(int((minf(a.z, minf(b.z, c.z)) - o.y) / SURF_STEP), 0, n - 1)
				var j1 := clampi(int((maxf(a.z, maxf(b.z, c.z)) - o.y) / SURF_STEP) + 1, 0, n - 1)
				for j in range(j0, j1 + 1):
					var pz := o.y + (j + 0.5) * SURF_STEP
					for i in range(i0, i1 + 1):
						var px := o.x + (i + 0.5) * SURF_STEP
						var w0 := ((b.z - c.z) * (px - c.x) + (c.x - b.x) * (pz - c.z)) / den
						var w1 := ((c.z - a.z) * (px - c.x) + (a.x - c.x) * (pz - c.z)) / den
						var w2 := 1.0 - w0 - w1
						if w0 < -0.01 or w1 < -0.01 or w2 < -0.01:
							continue
						var y := minf(SURF_MAX, w0 * a.y + w1 * b.y + w2 * c.y)
						if y > h[j * n + i]:
							h[j * n + i] = y
	surf_fields.append({"o": o, "n": n, "h": h})


## Altura do piso em (x, z): 0 no chão comum, o tabuleiro da ponte ou a água onde houver.
func surface_y(x: float, z: float) -> float:
	for f in surf_fields:
		var o: Vector2 = f["o"]
		var n: int = f["n"]
		var i := int((x - o.x) / SURF_STEP)
		var j := int((z - o.y) / SURF_STEP)
		if i >= 0 and j >= 0 and i < n and j < n:
			return f["h"][j * n + i]
	return 0.0


func hero_pos(alpha: float) -> Vector3:
	var h := sim.hero
	return Vector3(lerpf(h.ox, h.x, alpha), 0.0, lerpf(h.oy, h.y, alpha))


## Herói Ajudante: rig da classe dele, parado no local enquanto a disputa dura; some quando ela acaba.
func _draw_helper(alpha: float, delta: float) -> void:
	var hh: SimHero = sim.helper
	if helper_node != null and hh != helper_of:
		emit_fx("smoke", helper_node.position + Vector3(0, 1, 0), 1.2)
		helper_node.queue_free()
		helper_node = null
		helper_of = null
	if hh == null:
		return
	if helper_node == null:
		helper_node = Node3D.new()
		helper_node.scale = Vector3.ONE * HERO_SCALE * HeroPresence.scale_mult()
		add_child(helper_node)
		var rig := Looks.hero_rig(hero_mat, hh.cls())
		if rig:
			rig.hero_ref = hh
			helper_node.add_child(rig)
		helper_of = hh
		emit_fx("heal", Vector3(hh.x, 1.0, hh.y), 1.2)
	helper_node.position = Vector3(lerpf(hh.ox, hh.x, alpha), 0.0, lerpf(hh.oy, hh.y, alpha))
	helper_node.position.y = surface_y(helper_node.position.x, helper_node.position.z)
	var fv := Vector3(hh.face_x, 0, hh.face_y)
	if fv.length() > 0.01:
		helper_node.rotation.y = lerp_angle(helper_node.rotation.y, atan2(-fv.x, -fv.z), clampf(delta * 14.0, 0.0, 1.0))


## Fase de grupo: os seguidores andam com rig próprio; quem cai some, quem chega aparece.
func _draw_followers(alpha: float, delta: float) -> void:
	for f in follower_nodes.keys():
		if not sim.followers.has(f):
			(follower_nodes[f] as Node3D).queue_free()
			follower_nodes.erase(f)
	for f in sim.followers:
		if not follower_nodes.has(f):
			var root := Node3D.new()
			root.scale = Vector3.ONE * HERO_SCALE * HeroPresence.scale_mult()
			add_child(root)
			var rig := Looks.hero_rig(hero_mat, f.cls())
			if rig:
				rig.hero_ref = f
				root.add_child(rig)
			follower_nodes[f] = root
			emit_fx("heal", Vector3(f.x, 1.0, f.y), 1.2)
		var n: Node3D = follower_nodes[f]
		n.position = Vector3(lerpf(f.ox, f.x, alpha), 0.0, lerpf(f.oy, f.y, alpha))
		n.position.y = surface_y(n.position.x, n.position.z)
		var fv := Vector3(f.face_x, 0, f.face_y)
		if fv.length() > 0.01:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(-fv.x, -fv.z), clampf(delta * 14.0, 0.0, 1.0))


func _draw_hero(alpha: float, delta: float) -> void:
	var h := sim.hero
	if h.cls() != rig_cls and hero_rig_node != null:
		# Herói da vez de outra classe: troca o rig.
		rig_cls = h.cls()
		var parent_ := hero_rig_node.get_parent()
		hero_rig_node.queue_free()
		hero_rig_node = Looks.hero_rig(hero_mat, rig_cls)
		if hero_rig_node:
			parent_.add_child(hero_rig_node)
	_draw_followers(alpha, delta)
	_draw_allies(alpha, delta)
	_tick_short_falls(delta)
	_draw_helper(alpha, delta)
	var p := hero_pos(alpha)
	var speed := 0.0 if sim.waiting_choice() else Vector2(h.x - h.ox, h.y - h.oy).length() / sim.dt
	var walk := clampf(speed / 3.0, 0.0, 1.0)
	var frozen := h.petrify_t > 0.0 or h.root_t > 0.0 or h.drink_t > 0.0
	hero_root.position = p
	hero_root.position.y += surface_y(p.x, p.z)
	if gol != null:
		hero_root.position += gol.hero_off   # --golpes=1: o golpe empurra o herói (volta sozinho)
	# Fonte: ajoelhado bebendo.
	if h.drink_t > 0.0:
		hero_root.position.y -= 0.35
	var f := Vector3(h.face_x, 0, h.face_y)
	if f.length() > 0.01:
		hero_root.rotation.y = lerp_angle(hero_root.rotation.y, atan2(-f.x, -f.z), clampf(delta * 14.0, 0.0, 1.0))
	if not frozen:
		walk_phase += delta * (4.0 + speed * 2.6) * maxf(walk, 0.2)
	var sp := sin(walk_phase)
	leg_l.rotation.x = sp * 0.7 * walk
	leg_r.rotation.x = -sp * 0.7 * walk
	level_jump = maxf(0.0, level_jump - delta)
	var jump := sin(clampf(level_jump / 0.6, 0.0, 1.0) * PI) * 0.8
	body.position.y = absf(sp) * 0.1 * walk + jump
	body.rotation.x = -0.12 * walk - hero_flash * 0.08
	head.rotation.x = sin(walk_phase * 2.0) * 0.04
	# Golpe: preparo e corte com rastro.
	swing_t = maxf(0.0, swing_t - delta)
	if swing_t > 0.0:
		var k := 1.0 - swing_t / 0.26
		var e := 1.0 - pow(1.0 - k, 3)
		arm_s.rotation = Vector3(lerpf(2.4, -0.3, e), lerpf(0.9, -0.9, e), sin(k * PI) * -0.4)
		slash_mat.albedo_color.a = sin(k * PI) * 0.75
		slash.rotation = Vector3(0, lerpf(0.8, -0.8, e), 0)
	else:
		arm_s.rotation = Vector3(-sp * 0.5 * walk + 0.3, 0, 0)
		slash_mat.albedo_color.a = 0.0
	# Escudo erguido enquanto existe.
	var up := 1.2 if h.shield_hp > 0.0 else 0.2
	arm_h.rotation = Vector3(lerpf(arm_h.rotation.x, up + sp * 0.15 * walk, clampf(delta * 10.0, 0.0, 1.0)), 0.35, 0)
	arm_h.scale = Vector3(1.6, 1.3, 1.3) if h.shield_cos < 0.6 else Vector3.ONE
	cape.rotation.x = 0.15 + walk * 0.5 + sin(sim.t * 3.0) * 0.06
	hero_flash = maxf(0.0, hero_flash - delta * 7.0)
	var glow := 0.02 + h.level * 0.012
	# O flash de dano é só um toque (17/11/2026): antes ia a 100% e, com golpes seguidos, o herói ficava branco.
	var fl := hero_flash * 0.28
	var mats: Array = [hero_mat]
	if hero_rig_node != null and hero_rig_node.has_meta("mat"):
		mats.append(hero_rig_node.get_meta("mat"))
	for hm in mats:
		hm.set_shader_parameter("emission_boost", 0.0 if h.petrify_t > 0.0 else glow)
		hm.set_shader_parameter("flash", fl)
	hero_light.light_energy = 1.0 + h.level * 0.06
	fireflies.position = p
	if presence != null:
		presence.track(hero_root, h.cls(), true)
		for fh in follower_nodes:
			presence.track(follower_nodes[fh], (fh as SimHero).cls(), false)
		if helper_node != null and helper_of != null:
			presence.track(helper_node, helper_of.cls(), false)
		presence.end_frame()


func _lanterns() -> void:
	if frame % 10 != 0 or lanterns.is_empty():
		return
	var p := hero_pos(1.0)
	var best: Array = []
	for l in lanterns:
		var d: float = (l as Vector3).distance_squared_to(p)
		if d < 2500.0:
			best.append([d, l])
	best.sort_custom(func(a, b): return a[0] < b[0])
	for i in lantern_lights.size():
		var L: OmniLight3D = lantern_lights[i]
		L.visible = i < best.size()
		if L.visible:
			L.position = best[i][1]


func _draw_road_state() -> void:
	if sim.phase != K.Phase.ROAD:
		return
	if road_field:
		_update_road_state()
	for r in road_meshes:
		var leg: Dictionary = sim.road.legs[r.get_meta("leg")]
		var b: int = r.get_meta("branch")
		var em := 0.0
		var dim: bool = leg["closed"] == b
		# Ramo já planejado pelo jogador e ainda não percorrido: brilha de leve.
		if not dim and leg["chosen"] < 0 and sim.road.plan.get(leg["a"], -1) == r.get_meta("leg"):
			em = 0.35
		var m: ShaderMaterial = r.material_override
		m.set_shader_parameter("emission_boost", em)
		r.transparency = 0.6 if dim else 0.0
	for bk in barricades:
		var g: Dictionary = sim.road.legs[bk[1]]
		bk[0].visible = g["closed"] == 0 and sim.road.path.has(g["a"])
	for li in loc_nodes.size():
		var loc: Dictionary = sim.road.locations[li]
		var n: Node3D = loc_nodes[li]
		var lab: Label3D = n.get_meta("lab")
		var st: int = loc["state"]
		var txt := tr("LOC_" + str(loc["type"]))
		if loc["type"] == "shrine" and loc["entered"] and st == SimRoad.LocState.ACTIVE:
			txt = "%s  %d" % [txt, ceili(float(loc["t"]))]
			var ring: MeshInstance3D = n.get_meta("ring")
			var s := 1.0 + 0.05 * sin(sim.t * 12.0)
			ring.scale = Vector3(s, 0.2, s)
		elif loc["type"] == "helper":
			if n.has_meta("bang"):
				(n.get_meta("bang") as Label3D).visible = st == SimRoad.LocState.ACTIVE and not loc["entered"]
			if sim.helper != null and sim.contest.get("li", -1) == li:
				txt = "%s  %d%%" % [txt, ceili(100.0 * sim.helper.hp / maxf(sim.helper.base_hp, 1.0))]
		elif loc["type"] == "ritual" and st == SimRoad.LocState.ACTIVE and loc["hp"] < loc["max_hp"]:
			txt = "%s  %d%%" % [txt, int(100.0 * loc["hp"] / loc["max_hp"])]
		lab.text = txt
		lab.modulate.a = 0.35 if st != SimRoad.LocState.ACTIVE else 1.0
		if st == SimRoad.LocState.DESTROYED and loc["type"] != "shrine" and n.visible:
			n.visible = false
			if fx2 != null:
				fx2.emit("collapse", n.position + Vector3(0, 0.5, 0), 1.2)
				add_trauma(0.25)
			else:
				emit_fx("fire", n.position + Vector3(0, 1, 0), 1.5)
				emit_fx("smoke", n.position + Vector3(0, 1, 0), 1.5)
			scorch(n.position, 6.0)


func _draw_zones() -> void:
	var k := 0
	for z in sim.zones:
		if k >= zone_pool.size():
			break
		var kind: String = z["kind"]
		if kind == "army":
			continue
		var e: Dictionary = zone_pool[k]
		var disc: MeshInstance3D = e["disc"]
		var coins: MeshInstance3D = e["coins"]
		var pos := Vector3(z["x"], 0.05, z["y"])
		coins.visible = kind == "bait"
		disc.visible = kind != "bait"
		if kind == "bait":
			coins.position = pos
			coins.rotation.y = sim.t * 2.0
		else:
			disc.position = pos
			var r := float(z["r"])
			disc.scale = Vector3(r, 1, r)
			var mat: ShaderMaterial = disc.material_override
			if fx2 != null:
				fx2.zone_params(mat, kind)
				fx2.zone_tick(kind, pos, r, k)
				k += 1
				continue
			var web := kind == "web"
			var spring := kind == "spring"
			var tint := Color(0.82, 0.85, 0.95, 0.75) if web else Color(1.0, 0.5, 0.12, 0.95)
			if spring:
				tint = Color(0.35, 0.8, 1.0, 0.7)
			mat.set_shader_parameter("tint", tint)
			mat.set_shader_parameter("pattern", 1.0 if web else 0.0)
			mat.set_shader_parameter("pulse", 0.0 if web else 0.8)
			mat.set_shader_parameter("fill", 0.08 if web else 0.3)
			mat.set_shader_parameter("glow", 1.0 if web else 2.2)
			if (kind == "oil" or (kind == "fire" and z.get("src", "") == "burn_village")) and frame % 20 == 0:
				emit_fx("fire", pos + Vector3(randf_range(-1, 1), 0.2, randf_range(-1, 1)) * (r * 0.6 if kind == "fire" else 1.0), 0.35)
		k += 1
	for i in range(k, zone_pool.size()):
		zone_pool[i]["disc"].visible = false
		zone_pool[i]["coins"].visible = false


func _draw_arena(delta: float) -> void:
	if arena_root == null or not sim.arena.active:
		return
	var A := sim.arena
	var yaw := atan2(-A.face.x, -A.face.y)
	for k in part_nodes.size():
		var n: MeshInstance3D = part_nodes[k]
		if n.has_meta("dead"):
			continue
		var id: String = A.part_ids[k]
		var off: Vector3 = boss_offs[id]
		# Respiração e balanço: o chefe está vivo.
		var idle := Vector3.ZERO
		match id:
			"head":
				idle = Vector3(0, sin(sim.t * 1.6) * 0.12, 0)
			"left_arm":
				idle = Vector3(sin(sim.t * 1.3) * 0.08, sin(sim.t * 1.8) * 0.15, 0)
			"right_arm":
				idle = Vector3(-sin(sim.t * 1.3 + 1.0) * 0.08, sin(sim.t * 1.8 + 1.0) * 0.15, 0)
		var target := Vector3(A.bx, 0, A.by) + (off + idle).rotated(UP, yaw)
		n.position = n.position.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
		n.rotation.y = yaw
		if id == "core":
			n.scale = Vector3(1, 1.0 + sin(sim.t * 2.0) * 0.02, 1)
		part_flash[k] = maxf(0.0, float(part_flash[k]) - delta * 5.0)
		var m: ShaderMaterial = n.material_override
		m.set_shader_parameter("emission_boost", 0.9 if A.fury_t > 0.0 else (0.25 if A.part_attackable(k) else 0.05))
		m.set_shader_parameter("flash", part_flash[k])
		if A.part_hp[k] <= 0.0:
			# A parte destruída despenca girando.
			n.set_meta("dead", true)
			falling.append({"n": n, "t": 1.4, "v": Vector3(randf_range(-2, 2), 6, randf_range(-2, 2)), "r": Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4))})
	for e in falling.duplicate():
		var n: MeshInstance3D = e["n"]
		e["t"] -= delta
		e["v"] += Vector3(0, -16, 0) * delta
		n.position += e["v"] * delta
		n.rotation += e["r"] * delta
		if n.position.y < -1.0 or e["t"] <= 0.0:
			n.visible = false
			falling.erase(e)
	for k in altar_nodes.size():
		altar_nodes[k].visible = A.altar_alive[k]
	for k in pillar_nodes.size():
		if pillar_nodes[k].visible and not A.pillar_alive(k):
			pillar_nodes[k].visible = false
			emit_fx("smoke", pillar_nodes[k].position + Vector3(0, 1.5, 0), 1.2)
			emit_fx("spark", pillar_nodes[k].position + Vector3(0, 1.5, 0), 1.0)
	boss_face.position = Vector3(A.bx, 0.08, A.by) + Vector3(A.face.x, 0, A.face.y) * 4.5
	boss_face.look_at(boss_face.position + Vector3(A.face.x, 0, A.face.y), UP)


func _tick_pools(delta: float, alpha: float) -> void:
	if dmg_acc["v"] > 0.0:
		dmg_acc["t"] -= delta
		if dmg_acc["t"] <= 0.0:
			var v: float = dmg_acc["v"]
			if v >= 3.0:
				number(dmg_acc["p"], str(int(v)), dmg_acc["col"], 72 if v < 100.0 else (100 if v < 500.0 else 128))
			dmg_acc["v"] = 0.0
	for e in number_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var l: Label3D = e["n"]
			e["v"] += Vector3(0, -9.0, 0) * delta
			l.position += e["v"] * delta
			var life: float = e["t"]
			l.modulate.a = clampf(life / 0.3, 0.0, 1.0)
			l.scale = Vector3.ONE * (1.0 + clampf((life - 0.65) / 0.15, 0.0, 1.0) * 0.7)
			if life <= 0.0:
				l.visible = false
	for e in burst_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var n: MeshInstance3D = e["n"]
			var dur_b: float = float(e.get("T", 0.4))
			var k: float = 1.0 - float(e["t"]) / dur_b
			var r: float = float(e["r"]) * (0.3 + 1.0 * (1.0 - pow(1.0 - k, 3)))
			if e.get("exact", false):
				r = float(e["r"]) * (0.92 + 0.08 * (1.0 - pow(1.0 - minf(k * 4.0, 1.0), 3)))   # o anel é o raio, sem crescer além
			n.scale = Vector3(r, 0.3, r)
			var m: StandardMaterial3D = n.material_override
			m.albedo_color.a = 0.9 * (1.0 - k)
			if e["t"] <= 0.0:
				n.visible = false
	for e in shot_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			if e["t"] <= 0.0:
				e["n"].visible = false
	for e in hshot_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var hn: Node3D = e["n"]
			if e["t"] <= 0.0:
				hn.visible = false
			else:
				hn.position = (e["a"] as Vector3).lerp(e["b"], 1.0 - float(e["t"]) / float(e["T"]))
	for e in decal_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var dc: Decal = e["n"]
			dc.modulate.a = clampf(float(e["t"]) / 2.0, 0.0, 1.0)
			if e["t"] <= 0.0:
				dc.visible = false
	var hp := hero_pos(alpha) + Vector3(0, 1.2, 0)
	for e in orb_pool:
		if e["t"] > 0.0:
			e["t"] -= delta
			var k: float = clampf(1.0 - float(e["t"]) / 0.6, 0.0, 1.0)
			var from: Vector3 = e["from"]
			var pos := from.lerp(hp, k * k)
			pos.y += sin(k * PI) * 2.0
			e["n"].position = pos
			if e["t"] <= 0.0:
				e["n"].visible = false
	if tell_t > 0.0:
		tell_t -= delta
		tell_label.position = hp + Vector3(0, 3.6 + (1.0 - clampf(tell_t, 0.0, 1.0)) * 0.6, 0)
		tell_label.modulate.a = clampf(tell_t / 0.25, 0.0, 1.0)
		tell_label.scale = Vector3.ONE * (1.0 + 0.15 * sin(tell_t * 25.0))
		tell_label.visible = tell_t > 0.0
	_draw_houses()
	if bubble_t > 0.0:
		bubble_t -= delta
		var bp := hp + Vector3(0, 2.6, 0)
		if bubble_on_boss and sim.arena.active:
			bp = Vector3(sim.arena.bx, 7.5, sim.arena.by)
		bubble.position = bp
		bubble.modulate.a = clampf(bubble_t / 0.4, 0.0, 1.0)
		bubble.visible = bubble_t > 0.0
	if flash_t > 0.0:
		flash_t -= delta
		flash_light.light_energy = maxf(0.0, flash_t / 0.3) * 8.0


## A party inteira caiu? e = 1: um seguidor caiu (a party segue); e = 0 pode ser o líder substituído (party segue) ou
## a party toda (a party em campo mudou, ou a run acabou). Fora da fila de parties a queda sempre é a longa.
func _party_fell(e: int) -> bool:
	if sim == null:
		return true
	var cp := sim.cur_party
	var changed := cp != fall_party
	fall_party = cp
	if e == 1:
		return false
	if not sim.party_mode():
		return true
	return changed or sim.phase == K.Phase.OVER or (sim.hero.hp <= 0.0 and sim.followers.is_empty())


## Queda curta: o corpo do membro tomba de lado em ~0,7 s e some; o mundo não desacelera nem a câmera para.
func short_fall(p: Vector3) -> void:
	var src: Node3D = null
	for f in follower_nodes.keys():
		if not sim.followers.has(f):
			src = follower_nodes[f]
			follower_nodes.erase(f)   # o corpo fica com o nó (senão _draw_followers o apaga no quadro seguinte)
			break
	if src == null:
		src = hero_root.duplicate() as Node3D
		add_child(src)
	src.position = Vector3(p.x, surface_y(p.x, p.z), p.z)
	short_falls.append({"n": src, "t": 0.0})


func _tick_short_falls(delta: float) -> void:
	for e in short_falls.duplicate():
		var n: Node3D = e["n"]
		if not is_instance_valid(n):
			short_falls.erase(e)
			continue
		e["t"] = float(e["t"]) + delta
		var k := clampf(float(e["t"]) / FALL_SHORT_S, 0.0, 1.0)
		var ease_k := k * k * (3.0 - 2.0 * k)
		n.rotation.z = PI * 0.5 * ease_k
		if k >= 0.6:
			n.scale = n.scale.lerp(Vector3.ONE * 0.01, clampf(delta * 7.0, 0.0, 1.0))
		if float(e["t"]) >= FALL_SHORT_S + 0.5:
			n.queue_free()
			short_falls.erase(e)


## Um poder disparou: anel + brilho na cor dele, no raio do poder (quando o nível tem `radius`).
func _power_fx(p: Vector3, idx: int) -> void:
	var list := sim.party_powers()
	var id := ""
	var r := 3.0
	if idx >= 0 and idx < list.size():
		id = str(list[idx]["id"])
		var d: Dictionary = sim.data.hero_powers.get(id, {})
		if not d.is_empty():
			var lv: Array = d["lv"]
			r = float(lv[clampi(int(list[idx]["level"]), 1, lv.size()) - 1].get("radius", 3.0))
	var col: Color = POWER_COLORS.get(id, Color(1, 0.9, 0.5))
	ring_burst(p, clampf(r, 2.0, 9.0), col)
	emit_fx("spark", p + Vector3(0, 1.0, 0), 1.0, col)
	light_flash(p, col)
	add_trauma(0.15)


## Aliados dos poderes (ratos e cães de guerra; sim.power_state["allies"]): os mesmos modelos 3D dos monstros rato e
## lobo (wolf_pack), no tamanho normal de unidade, com um tom da cor da classe do herói.
func _draw_allies(_alpha: float, delta: float) -> void:
	var al: Array = sim.power_state.get("allies", [])
	while ally_nodes.size() > al.size():
		var dead: Node3D = ally_nodes.pop_back()
		if is_instance_valid(dead):
			dead.queue_free()
	var cl := sim.hero.cls()
	var hc: Color = HeroPresence.CLS[cl][0] if HeroPresence.CLS.has(cl) else Color(0.85, 0.72, 0.35)
	var tint := Color.WHITE.lerp(hc, 0.45)
	while ally_nodes.size() < al.size():
		var is_hound: bool = str(al[ally_nodes.size()].get("id", "")) == "war_hound"
		var uid := "wolf_pack" if is_hound else "rat"
		var root := Node3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = Looks.unit_mesh(uid)
		mm.instance_count = 1
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Looks.unit_material(0.0, true, uid)
		mmi.custom_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 8, 8))
		root.add_child(mmi)
		root.set_meta("mm", mm)
		root.set_meta("scl", Looks.scale_of(uid) * FIG_SCALE)
		root.set_meta("hop", 0.5 if is_hound else 1.0)
		add_child(root)
		ally_nodes.append(root)
	for i in al.size():
		var a: Dictionary = al[i]
		var n: Node3D = ally_nodes[i]
		var target := Vector3(float(a["x"]), 0.0, float(a["y"]))
		target.y = surface_y(target.x, target.z)
		var d := target - n.position
		if d.length() > 6.0:
			n.position = target
		else:
			n.position = n.position.lerp(target, clampf(delta * 12.0, 0.0, 1.0))
		var dh := Vector2(d.x, d.z).length()
		if dh > 0.05:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(-d.x, -d.z), clampf(delta * 10.0, 0.0, 1.0))
		var sc: float = n.get_meta("scl")
		var hop: float = n.get_meta("hop")
		var moving := clampf(dh / 0.4, 0.0, 1.0)
		var buf := PackedFloat32Array()
		buf.resize(STRIDE)
		buf[0] = sc; buf[3] = 0.0
		buf[5] = sc; buf[7] = 0.0
		buf[10] = sc; buf[11] = 0.0
		buf[12] = tint.r; buf[13] = tint.g; buf[14] = tint.b; buf[15] = 1.0
		buf[16] = 0.0; buf[17] = hop * maxf(moving, 0.25); buf[18] = float(i) * 1.7; buf[19] = 0.0
		(n.get_meta("mm") as MultiMesh).buffer = buf


func cine_active() -> bool:
	return cine_t >= 0.0 or not scene.is_empty()


## Começa a cena da queda: um corpo do herói fica no lugar e tomba; o mundo desacelera.
func fall_cinematic(p: Vector3) -> void:
	_end_scene()   # a queda manda: a cena do local que estiver rodando acaba aqui
	if corpse_tw != null and corpse_tw.is_valid():
		corpse_tw.kill()
	corpse_tw = null
	# Um corpo só, reaproveitado a cada queda (copia a pose atual do herói em vez de duplicar a árvore de novo).
	if corpse_spare == null or not is_instance_valid(corpse_spare) or corpse_spare.is_queued_for_deletion():
		corpse_spare = hero_root.duplicate() as Node3D
		add_child(corpse_spare)
	else:
		_copy_pose(hero_root, corpse_spare)
	corpse = corpse_spare
	corpse.visible = true
	corpse.scale = hero_root.scale
	corpse.position = Vector3(p.x, 0.0, p.z)
	corpse.rotation = hero_root.rotation
	cine_from = Vector3(p.x, 0.0, p.z)
	cine_t = 0.0
	look_hold = true
	look_off = Vector3.ZERO
	Engine.time_scale = CINE_SLOW


func _cine(delta: float) -> void:
	# delta já vem desacelerado pelo time_scale: a cena conta em tempo real.
	cine_t += delta / maxf(Engine.time_scale, 0.01)
	var k := clampf(cine_t / CINE_FOCUS, 0.0, 1.0)
	if corpse and is_instance_valid(corpse):
		# Tomba de lado devagar (lê bem com a câmera de cima), com um quique pequeno no chão.
		var e := k * k * (3.0 - 2.0 * k)
		corpse.rotation.z = PI * 0.5 * e - sin(clampf((k - 0.8) / 0.2, 0.0, 1.0) * PI) * 0.1
		corpse.position.y = 0.3 * e
	if cine_t >= CINE_FOCUS:
		var j := clampf((cine_t - CINE_FOCUS) / CINE_TRAVEL, 0.0, 1.0)
		Engine.time_scale = lerpf(CINE_SLOW, 1.0, j)
	if cine_t >= CINE_FOCUS + CINE_TRAVEL:
		cine_t = -1.0
		look_hold = false
		Engine.time_scale = 1.0
		if corpse and is_instance_valid(corpse):
			var c := corpse
			corpse = null
			corpse_tw = c.create_tween()
			corpse_tw.tween_interval(1.5)
			corpse_tw.tween_property(c, "scale", Vector3.ONE * 0.01, 0.6)
			corpse_tw.tween_callback(c.hide)   # fica guardado para a próxima queda


## Copia a pose (posição, rotação, escala, visibilidade) de uma árvore de Node3D para outra de mesma forma.
func _copy_pose(src: Node, dst: Node) -> void:
	if src is Node3D and dst is Node3D:
		(dst as Node3D).transform = (src as Node3D).transform
		(dst as Node3D).visible = (src as Node3D).visible
	var n := mini(src.get_child_count(), dst.get_child_count())
	for i in n:
		_copy_pose(src.get_child(i), dst.get_child(i))


## Começa a cena do local li. code: o do Ev.CONTEST no fim da disputa (1 completa, 10+n parcial, -1 falha);
## 0 = chegada (loja, encruzilhada).
func start_scene(li: int, code: int) -> void:
	if not cine_enabled or cine_t >= 0.0 or li < 0 or li >= sim.road.locations.size():
		return
	_end_scene()
	var loc: Dictionary = sim.road.locations[li]
	var ty := str(loc["type"])
	var tier := -1
	var won_n := 0
	if code == 1:
		tier = 2
		won_n = 1 if ty == "helper" else 3
	elif code >= 11:
		tier = 1
		won_n = code - 10
	elif code < 0:
		tier = 0
	var p: Vector2 = loc["pos"]
	scene = {"li": li, "type": ty, "tier": tier, "won_n": won_n, "marks": 1 if ty == "helper" else 3,
		"hard": bool(loc.get("hard", false)) and ty != "helper", "t": 0.0,
		"dur": SCENE_END if tier >= 0 else SCENE_ARRIVE, "pos": Vector3(p.x, 0.0, p.y), "beat": 0}
	if ty == "helper" and helper_node != null:
		# O ajudante já saiu da simulação: o nó fica com a cena (tomba ou some nela).
		scene_helper = helper_node
		helper_node = null
		helper_of = null
	look_hold = true
	look_off = Vector3.ZERO
	Engine.time_scale = CINE_SLOW
	_scene_beat(0)


func scene_skippable() -> bool:
	return not scene.is_empty() and float(scene["t"]) >= SCENE_SKIP_AFTER


func skip_scene() -> void:
	if scene_skippable():
		_end_scene()


func _scene_tick(real_dt: float) -> void:
	scene["t"] = float(scene["t"]) + real_dt
	var st := float(scene["t"])
	var dur := float(scene["dur"])
	# Batidas do efeito: 0 na largada, 1 e 2 ao longo da cena (a chegada só tem a 0 e a 1).
	var beats := [0.0, 0.55, 1.2] if int(scene["tier"]) >= 0 else [0.0, 0.5]
	while int(scene["beat"]) + 1 < beats.size() and st >= float(beats[int(scene["beat"]) + 1]):
		scene["beat"] = int(scene["beat"]) + 1
		_scene_beat(int(scene["beat"]))
	var tier := int(scene["tier"])
	var k := clampf((st - 0.25) / 1.6, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	# Taverna vencida: as casas que sobraram afundam tortas.
	if str(scene["type"]) == "tavern" and tier >= 1:
		var pre := "%d:" % int(scene["li"])
		for key in house_nodes:
			if str(key).begins_with(pre):
				var hn: MeshInstance3D = house_nodes[key]
				if hn.visible and not hn.has_meta("y0"):
					hn.set_meta("y0", hn.position.y)
				if hn.has_meta("y0"):
					hn.position.y = float(hn.get_meta("y0")) - 1.3 * e
					hn.rotation.z = 0.18 + 0.25 * e
	# Ajudante: vencido, tomba de lado como o herói caído; falha, encolhe e some num brilho.
	if scene_helper and is_instance_valid(scene_helper):
		if tier == 2:
			scene_helper.rotation.z = PI * 0.5 * e - sin(clampf((k - 0.8) / 0.2, 0.0, 1.0) * PI) * 0.1
			scene_helper.position.y = 0.3 * e
		else:
			scene_helper.scale = Vector3.ONE * HERO_SCALE * maxf(0.01, 1.0 - clampf((st - 0.6) / 0.6, 0.0, 1.0))
	if st >= dur - SCENE_BACK:
		Engine.time_scale = lerpf(CINE_SLOW, 1.0, clampf((st - (dur - SCENE_BACK)) / SCENE_BACK, 0.0, 1.0))
	if st >= dur:
		_end_scene()


## Termina a cena do local (no fim, no pulo, na queda do herói ou numa run nova).
func _end_scene() -> void:
	if scene.is_empty():
		return
	var ty := str(scene["type"])
	var li := int(scene["li"])
	var sc_tier := int(scene.get("tier", -1))
	scene = {}
	look_hold = false
	if cine_t < 0.0:
		Engine.time_scale = 1.0
	if ty == "tavern":
		var pre := "%d:" % li
		for key in house_nodes:
			if str(key).begins_with(pre):
				var hn: Node3D = house_nodes[key]
				if sc_tier == 0 and _house_standing(str(key)):
					hn.set_meta("stand", true)   # taverna perdida: as casas que ainda estão de pé continuam no mapa
					hn.visible = true
				else:
					hn.visible = false
	if scene_helper and is_instance_valid(scene_helper):
		var c := scene_helper
		var tw := c.create_tween()
		tw.tween_interval(1.0)
		tw.tween_property(c, "scale", Vector3.ONE * 0.01, 0.5)
		tw.tween_callback(c.queue_free)
	scene_helper = null


## Um momento do efeito do local.
func _scene_beat(b: int) -> void:
	var ty := str(scene["type"])
	var tier := int(scene["tier"])
	var p: Vector3 = scene["pos"]
	var hp := hero_pos(1.0)
	var big := 1.0 if tier == 2 else 0.6     # parcial: o mesmo efeito, menor
	var r := float(sim.road.locations[int(scene["li"])].get("r", 4.0))
	if tier < 0:
		match ty:
			"shop":
				if b == 0:
					light_flash(p, Color(1, 0.85, 0.4))
					emit_fx("level", p + Vector3(0, 0.8, 0), 1.3)
					ring_burst(p, 3.0, Color(1, 0.8, 0.3))
				else:
					emit_fx("spark", p + Vector3(0, 1.4, 0), 1.6)
					emit_fx("level", p + Vector3(0, 1.6, 0), 0.8)
			_:
				# Encruzilhada: névoa e um brilho de pergaminho no local.
				if b == 0:
					emit_fx("smoke", p + Vector3(0, 0.6, 0), 2.2)
					emit_fx("magic", p + Vector3(0, 1.6, 0), 1.2)
					light_flash(p, Color(0.8, 0.7, 1.0))
				else:
					emit_fx("smoke", p + Vector3(1.2, 0.4, 0.6), 1.6)
					emit_fx("magic", p + Vector3(0, 2.4, 0), 0.8)
					ring_burst(p, 2.6, Color(0.85, 0.75, 1.0))
		return
	if tier == 0:
		# Falha: o local se volta para o herói.
		match ty:
			"tavern":
				if b == 0:
					light_flash(p, Color(1, 0.8, 0.4))
				emit_fx("level", hp + Vector3(0, 0.8, 0), 0.9)
				if b == 1:
					emit_fx("heal", hp + Vector3(0, 0.8, 0), 1.4)
			"fountain":
				if b == 0:
					emit_fx("shield", p + Vector3(0, 0.5, 0), 2.0)
					light_flash(p, Color(0.5, 0.75, 1.0))
				elif b == 1:
					emit_fx("shield", p + Vector3(0, 2.0, 0), 1.6)
				else:
					emit_fx("heal", hp + Vector3(0, 0.8, 0), 1.4)
			"ritual":
				emit_fx("smoke", p + Vector3(0, 0.4, 0), 1.6 + 0.5 * b)
				if b == 0:
					ring_burst(p, r, Color(0.35, 0.3, 0.4))
			"shrine":
				if b == 0:
					light_flash(p, Color(1, 0.95, 0.7))
					screen_flash = Color(1, 0.95, 0.7, 0.25)
				emit_fx("level", p + Vector3(0, 0.5 + 1.5 * b, 0), 1.4)
			"bridge":
				emit_fx("level", hp + Vector3(0, 0.8, 0), 0.9)
				if b == 0:
					light_flash(hp, Color(1, 0.9, 0.6))
			"helper":
				if scene_helper and is_instance_valid(scene_helper):
					emit_fx("level", scene_helper.position + Vector3(0, 1.0, 0), 1.0)
					if b == 2:
						emit_fx("smoke", scene_helper.position + Vector3(0, 1.0, 0), 1.2)
		return
	# Completa ou parcial: o local desaba a favor do vilão.
	match ty:
		"tavern":
			var pre := "%d:" % int(scene["li"])
			for key in house_nodes:
				if str(key).begins_with(pre) and house_nodes[key].visible:
					var hpos: Vector3 = house_nodes[key].position
					emit_fx("fire", Vector3(hpos.x, 1.0, hpos.z), 1.3 * big)
					emit_fx("smoke", Vector3(hpos.x, 1.4, hpos.z), 1.3 * big)
			if b == 0:
				add_trauma(0.3 * big)
		"fountain":
			emit_fx("smoke", p + Vector3(0, 0.8 + 0.6 * b, 0), 1.6 * big)
			emit_fx("magic", p + Vector3(0, 0.6, 0), 1.4 * big)
			if b == 0:
				ring_burst(p, 3.0, Color(0.5, 0.2, 0.7))
		"ritual":
			if b == 0:
				ring_burst(p, r, Color(0.75, 0.35, 1.0))
				light_flash(p, Color(0.75, 0.35, 1.0))
			emit_fx("magic", p + Vector3(0, 0.6 + 1.8 * b, 0), 1.8 * big)
		"shrine":
			emit_fx("fire", p + Vector3(0, 1.0, 0), 1.5 * big)
			emit_fx("smoke", p + Vector3(0, 1.6, 0), 1.5 * big)
			if b == 0:
				add_trauma(0.25 * big)
		"bridge":
			emit_fx("spark", p + Vector3(0, 1.0, 0), 1.8 * big)
			emit_fx("death", p + Vector3(0, 1.2, 0), 1.6 * big)
			emit_fx("smoke", p + Vector3(0, 0.8, 0), 1.4 * big)
			if b == 0:
				add_trauma(0.35 * big)
		"helper":
			if scene_helper and is_instance_valid(scene_helper) and b <= 1:
				ring_burst(scene_helper.position, 3.0, Color(1, 0.8, 0.3))
				emit_fx("hit", scene_helper.position + Vector3(0, 1.0, 0), 1.5)
	if b == 2 and tier == 2:
		emit_fx("level", p + Vector3(0, 1.5, 0), 1.2)


func _camera(alpha: float, delta: float) -> void:
	var target := hero_pos(alpha)
	if sim.phase == K.Phase.ARENA:
		target = target.lerp(Vector3(sim.arena.bx, 0, sim.arena.by), 0.4)
	if cam_lair:
		target = lair_pos
	var close := 0.0
	if cine_t >= 0.0:
		_cine(delta)
	if not scene.is_empty():
		_scene_tick(delta / maxf(Engine.time_scale, 0.01))
	if not scene.is_empty():
		# Vai até o local (0,35 s), fica nele e volta para o herói no fim.
		var st := float(scene["t"])
		var w := smoothstep(0.0, 0.35, st) * (1.0 - smoothstep(float(scene["dur"]) - SCENE_BACK, float(scene["dur"]), st))
		# O local fica um pouco abaixo do meio da tela: o letreiro e os selos ficam acima dele, sem cobrir o efeito.
		var focus: Vector3 = target.lerp(scene["pos"] + Vector3(0, 0, -3.0), w)
		close = w * (4.0 if int(scene["tier"]) >= 0 else 2.5)
		cam_pos = cam_pos.lerp(focus, clampf(delta / Engine.time_scale * 6.0, 0.0, 1.0))
	elif cine_t >= 0.0:
		# Foco no corpo (aproxima), depois recua deslizando até o herói novo.
		var j := clampf((cine_t - CINE_FOCUS) / CINE_TRAVEL, 0.0, 1.0)
		var e := j * j * (3.0 - 2.0 * j)
		var focus := cine_from.lerp(target, e)
		close = (1.0 - e) * 6.0
		cam_pos = cam_pos.lerp(focus, clampf(delta / Engine.time_scale * 6.0, 0.0, 1.0))
	else:
		cam_pos = cam_pos.lerp(target, clampf(delta * 5.0, 0.0, 1.0))
	look_off = look_off.lerp(_look_target(), clampf(delta * 3.0, 0.0, 1.0))
	target = cam_pos + look_off
	var dist := CAM_DIST + zoom + minf(float(sim.units.count), 300.0) * CAM_PER_UNIT - close
	if sim.phase == K.Phase.ARENA:
		dist += CAM_ARENA
	arrive_pull = maxf(0.0, arrive_pull - delta)
	dist += 5.0 * sin(clampf(arrive_pull / 3.0, 0.0, 1.0) * PI)
	var off := Diorama.cam_offset(dist)
	trauma = maxf(0.0, trauma - delta * 1.6)
	var sh := trauma * trauma
	var t := Time.get_ticks_msec() / 1000.0
	var shake := Vector3(sin(t * 47.0) + sin(t * 23.0) * 0.5, sin(t * 39.0 + 1.0) + sin(t * 17.0) * 0.5, 0) * sh * 0.9
	cam.position = target + off + shake
	# A câmera mira um pouco atrás do herói (10/11/2026; antes, 2 m à frente): o herói sobe na tela e o chão
	# atrás dele sai de baixo do leque de cartas (era 8 a 12% das jogadas pensadas no --humantest).
	cam.look_at(target + Vector3(0, 0, CAM_LOOK_Z) + shake * 0.3, UP)
	cam.rotation.z += sin(t * 31.0) * sh * 0.03
	Diorama.focus(cam, off.length())


## Para onde o mouse puxa a câmera: fora da zona morta do meio, até LOOK_MAX metros na direção dele. Fora da
## janela ela volta para o herói. Sobre uma carta da mão (`look_freeze`) ela fica parada onde está; na metade
## de baixo o deslize para baixo é reforçado (até 1 + LOOK_DOWN_BOOST), para chegar logo abaixo da mão.
func _look_target() -> Vector3:
	if look_hold or not get_window().has_focus():
		return Vector3.ZERO
	if look_freeze:
		return look_off
	var vp := get_viewport()
	var vs := vp.get_visible_rect().size
	var m := vp.get_mouse_position()
	if not Rect2(Vector2.ZERO, vs).has_point(m):
		return Vector3.ZERO
	var n := (m - vs * 0.5) / (vs * 0.5)
	var l := n.length()
	if l <= LOOK_DEAD:
		return Vector3.ZERO
	var k := smoothstep(LOOK_DEAD, 1.0, minf(l, 1.0))
	var dir := n / l
	if dir.y > 0.0:
		dir.y *= 1.0 + LOOK_DOWN_BOOST * smoothstep(LOOK_DOWN_FROM, 1.0, m.y / vs.y)
	return Vector3(dir.x, 0, dir.y) * LOOK_MAX * k


# ---------------------------------------------------------------- efeitos

func add_trauma(v: float) -> void:
	trauma = minf(1.0, trauma + v * float(Settings.v["shake"]))


func emit_fx(kind: String, pos: Vector3, scale_ := 1.0, col := Color.WHITE) -> void:
	if fx2 != null and fx2.emit(kind, pos, scale_, col):
		return
	var d: Dictionary = fx[kind]
	var list: Array = d["list"]
	var p: GPUParticles3D = list[d["i"]]
	d["i"] = (int(d["i"]) + 1) % list.size()
	p.position = pos
	p.scale = Vector3.ONE * scale_
	var pm: ParticleProcessMaterial = p.process_material
	pm.color = col
	p.restart()
	p.emitting = true


func scorch(pos: Vector3, size: float) -> void:
	var e: Dictionary = decal_pool[decal_i]
	decal_i = (decal_i + 1) % decal_pool.size()
	var dc: Decal = e["n"]
	dc.position = pos + Vector3(0, 0.5, 0)
	dc.size = Vector3(size, 2.0, size)
	dc.rotation.y = randf() * TAU
	dc.modulate.a = 1.0
	dc.visible = true
	e["t"] = 7.0


func number(pos: Vector3, txt: String, col: Color, size := 52) -> void:
	var e: Dictionary = number_pool[number_i]
	number_i = (number_i + 1) % number_pool.size()
	var l: Label3D = e["n"]
	l.text = txt
	l.modulate = col
	l.font_size = size
	l.position = pos + Vector3(randf_range(-0.4, 0.4), 2.2, randf_range(-0.2, 0.2))
	l.visible = true
	e["v"] = Vector3(randf_range(-1.6, 1.6), 5.5, 0)
	e["t"] = 0.8


func ring_burst(pos: Vector3, r: float, col: Color) -> void:
	if fx2 != null:
		fx2.ring(pos, r, col)
		return
	var e: Dictionary = burst_pool[burst_i]
	burst_i = (burst_i + 1) % burst_pool.size()
	var n: MeshInstance3D = e["n"]
	n.position = pos + Vector3(0, 0.2, 0)
	var m: StandardMaterial3D = n.material_override
	m.albedo_color = col
	m.emission = Color(col.r, col.g, col.b)
	n.visible = true
	e["t"] = 0.4
	e["T"] = 0.4
	e["exact"] = false
	e["r"] = r


## Explosivo: anel no chão EXATAMENTE do tamanho do raio (borda externa = raio) e um clarão. Usa o pool dos anéis.
func explosive_boom(pos: Vector3, r: float) -> void:
	if burst_pool.is_empty():
		return
	var e: Dictionary = burst_pool[burst_i]
	burst_i = (burst_i + 1) % burst_pool.size()
	var n: MeshInstance3D = e["n"]
	n.position = Vector3(pos.x, 0.08 + surface_y(pos.x, pos.z), pos.z)
	var m: StandardMaterial3D = n.material_override
	var col := Color(1, 0.5, 0.12)
	m.albedo_color = col
	m.emission = Color(col.r, col.g, col.b)
	n.scale = Vector3(r, 0.3, r)
	n.visible = true
	e["t"] = 0.7
	e["T"] = 0.7
	e["exact"] = true
	e["r"] = r
	light_flash(pos, Color(1, 0.7, 0.3))
	emit_fx("spark", pos + Vector3(0, 0.6, 0), clampf(r / 2.5, 0.6, 3.0))
	emit_fx("fire", pos + Vector3(0, 0.6, 0), clampf(r / 3.0, 0.6, 2.5))


func shot(a: Vector3, b: Vector3) -> void:
	var e: Dictionary = shot_pool[shot_i]
	shot_i = (shot_i + 1) % shot_pool.size()
	var n: MeshInstance3D = e["n"]
	var l := a.distance_to(b)
	if l < 0.1:
		return
	n.position = (a + b) * 0.5 + Vector3(0, 1.1, 0)
	n.look_at(b + Vector3(0, 1.1, 0), UP)
	n.scale = Vector3(1, 1, l)
	n.visible = true
	e["t"] = 0.08


## Projétil do herói à distância: nasce na mão/arma (um passo à frente, na altura do peito) e voa até o alvo.
## kind 0 = flecha (aponta para o alvo), 1 = orbe mágico.
func hero_shot(from: Vector3, to: Vector3, kind: int) -> void:
	var dir := to - from
	dir.y = 0.0
	if dir.length() < 0.3:
		return
	var a := from + dir.normalized() * 0.5 + Vector3(0, 1.25, 0)
	var b := to + Vector3(0, 0.9, 0)
	var e: Dictionary = hshot_pool[hshot_i]
	hshot_i = (hshot_i + 1) % hshot_pool.size()
	var n: Node3D = e["n"]
	n.position = a
	n.look_at_from_position(a, b, UP)
	(e["arrow"] as Node3D).visible = kind == 0
	(e["orb"] as Node3D).visible = kind == 1
	n.visible = true
	e["a"] = a
	e["b"] = b
	e["T"] = clampf(a.distance_to(b) / 32.0, 0.06, 0.25)
	e["t"] = e["T"]


func orb(from: Vector3) -> void:
	var e: Dictionary = orb_pool[orb_i]
	orb_i = (orb_i + 1) % orb_pool.size()
	e["from"] = from + Vector3(0, 0.6, 0)
	e["t"] = 0.6
	e["n"].visible = true


## A casa "li:k" da Taverna ainda tem vida?
func _house_standing(key: String) -> bool:
	var parts := key.split(":")
	if parts.size() != 2:
		return false
	var li := int(parts[0])
	var k := int(parts[1])
	if li < 0 or li >= sim.road.locations.size():
		return false
	var hs: Array = sim.road.locations[li].get("houses", [])
	return k >= 0 and k < hs.size() and float(hs[k]["hp"]) > 0.0


## Casas da Taverna em disputa: aparecem na chegada do herói, afundam e somem quando quebram.
func _draw_houses() -> void:
	if sim.contest.is_empty() or sim.contest["type"] != "tavern":
		# Na cena do fim da taverna as casas dela ficam (afundam ou ficam de pé) até a cena acabar.
		var keep := "%d:" % int(scene["li"]) if scene.get("type", "") == "tavern" else "-"
		for k in house_nodes:
			if not str(k).begins_with(keep) and not house_nodes[k].has_meta("stand"):
				house_nodes[k].visible = false
		return
	var li := int(sim.contest["li"])
	var hs: Array = sim.road.locations[li]["houses"]
	for k in hs.size():
		var key := "%d:%d" % [li, k]
		var h: Dictionary = hs[k]
		if not house_nodes.has(key):
			# Diorama: duas casas diferentes, de frente para a câmera (com um giro pequeno).
			var hid := "house_b" if k % 2 == 1 and Diorama.mesh("house_b") else "house"
			var n := _mi(Models.prop(hid), Vector3(h["x"], 0, h["y"]), null, randf_range(-0.7, 0.7))
			n.scale = Vector3.ONE * 0.75
			add_child(n)
			house_nodes[key] = n
		var hn: MeshInstance3D = house_nodes[key]
		var f := clampf(float(h["hp"]) / float(h["max_hp"]), 0.0, 1.0)
		hn.visible = f > 0.0
		hn.position.y = -(1.0 - f) * 1.2
		hn.rotation.z = (1.0 - f) * 0.18


## Aviso da habilidade sobre o herói (o nome dela, 1 s antes de disparar).
func ability_tell(idx: int) -> void:
	var ups: Array = sim.data.hero["upgrades"]
	if idx < 0 or idx >= ups.size():
		return
	tell_label.text = tr("UPG_" + str(ups[idx]["id"])) + "!"
	tell_t = 1.0
	tell_label.visible = true


func light_flash(pos: Vector3, col: Color) -> void:
	flash_light.position = pos + Vector3(0, 2, 0)
	flash_light.light_color = col
	flash_t = 0.3


func say(key_prefix: String, n: int, on_boss: bool, col: Color) -> void:
	if bubble_t > 0.5:
		return
	bubble.text = tr("%s_%d" % [key_prefix, randi_range(1, n)])
	bubble.modulate = col
	bubble_on_boss = on_boss
	bubble.visible = true
	bubble_t = 2.6


func _spend(k: String) -> bool:
	if budget[k] <= 0:
		return false
	budget[k] -= 1
	return true


func _stop(t: float) -> void:
	hitstop = maxf(hitstop, t)


## Estilo dos efeitos novos por evento (modo misto, aprovado em 20/11/2026 na página de revisão): 1 pintado,
## 2 brilhante, -1 = o padrão do tipo (Fx2.KIND_STYLE).
func _fx_ctx(k: int, ev: Array) -> int:
	match k:
		K.Ev.DAMAGE_UNIT, K.Ev.HERO_LEVEL, K.Ev.SPIN, K.Ev.HERO_FALL, K.Ev.SHRINE:
			return 1
		K.Ev.EXPLOSION, K.Ev.DEATH, K.Ev.HEAL, K.Ev.LEECH, K.Ev.SHIELD_BREAK, K.Ev.UNIT_SHIELD_BREAK, 				K.Ev.CURSE, K.Ev.PART_DESTROYED, K.Ev.TELEPORT, K.Ev.FEAR:
			return 2
		K.Ev.SPELL:
			var di := int(ev[3])
			if di >= 0 and di < sim.data.cards.size():
				var c: CardDef = sim.data.cards[di]
				# Tocha (fogo) e Explosão de Cadáver: pintados; sombra, arcano, maldição e o resto: brilhantes.
				if c.is_spell and ((c.tags & K.TAG_FIRE) or c.id == "corpse_blast"):
					return 1
			return 2
	return -1


func handle_events(evs: Array) -> void:
	var U := sim.units
	# Evento do Explosivo (x, y, raio): o nome ainda pode não existir no K.Ev (outro agente o cria); sem ele, fica inerte.
	var boom_ev: int = int(K.Ev.get("EXPLOSIVE_BOOM", -1))
	for ev in evs:
		var k: int = ev[0]
		var p := Vector3(ev[1], 0, ev[2])
		if boom_ev >= 0 and k == boom_ev:
			explosive_boom(p, float(ev[3]))
			continue
		if fx2 != null:
			fx2.ctx = _fx_ctx(k, ev)
		match k:
			K.Ev.ABILITY_TELL:
				ability_tell(int(ev[3]))
			K.Ev.DAMAGE_HERO:
				var v := float(ev[3])
				var tags := int(ev[4])
				var col := Color(1, 0.35, 0.3)
				if tags & K.TAG_FIRE:
					col = Color(1, 0.6, 0.15)
				elif tags & K.TAG_SHADOW:
					col = Color(0.8, 0.45, 1.0)
				if Settings.v["damage_numbers"]:
					if dmg_acc["v"] <= 0.0:
						dmg_acc["t"] = 0.3
						dmg_acc["col"] = col
					dmg_acc["v"] += v
					dmg_acc["p"] = p
				if hero_flash < 0.15:   # sem empilhar: golpes seguidos não prendem o brilho
					hero_flash = clampf(v / 80.0, 0.5, 1.0)
				if v >= 100.0:
					add_trauma(0.35)
					_stop(0.06)
				if gol != null:
					gol.note_damage(v, sim.hero.max_hp())   # --golpes=1: hit-stop se veio de golpe de monstro
			K.Ev.DAMAGE_UNIT:
				var i: int = ev[4]
				swing_t = 0.26
				if i >= 0 and i < flash.size():
					flash[i] = 1.0
					var d := Vector2(U.px[i] - sim.hero.x, U.py[i] - sim.hero.y).normalized() * 0.45
					kx[i] = d.x
					ky[i] = d.y
					if gol != null:
						gol.hurt(i)
					if _spend("hit"):
						emit_fx("hit", p + Vector3(0, 0.8, 0), 0.8)
				else:
					var part_i := -1 - i
					if part_i >= 0 and part_i < part_flash.size():
						part_flash[part_i] = 1.0
					emit_fx("spark", p + Vector3(0, 2.0, 0), 1.0)
					add_trauma(0.08)
				if Settings.v["damage_numbers"] and float(ev[3]) >= 20.0 and _spend("num"):
					number(p, str(int(ev[3])), Color(1, 1, 1, 0.9), 50)
			K.Ev.DEATH:
				var i: int = ev[4]
				if i >= 0 and i < U.cap and _spend("death"):
					var cid: String = sim.data.cards[int(ev[3])].id
					emit_fx("death", p + Vector3(0, 0.5, 0), 0.9, UNIT_COLORS.get(cid, Color(0.7, 0.6, 0.8)))
					if not (U.flags[i] & K.F_NO_XP) and U.xp[i] > 0.0:
						orb(p)
						emit_fx("soul", p + Vector3(0, 0.6, 0), 0.8)
			K.Ev.EXPLOSION:
				var r := float(ev[3])
				emit_fx("fire", p + Vector3(0, 0.6, 0), r / 2.2)
				emit_fx("smoke", p + Vector3(0, 0.8, 0), r / 2.2)
				emit_fx("spark", p + Vector3(0, 0.6, 0), r / 2.5)
				ring_burst(p, r, Color(1, 0.55, 0.15))
				light_flash(p, Color(1, 0.6, 0.25))
				scorch(p, r * 1.8)
				add_trauma(0.45)
				_stop(0.05)
			K.Ev.SHOT:
				shot(p, Vector3(ev[3], 0, float(ev[4]) / 100.0))
			K.Ev.HERO_SHOT:
				hero_shot(p, Vector3(ev[3], 0, float(int(ev[4]) >> 2) / 100.0), int(ev[4]) & 3)
			K.Ev.SPIN:
				ring_burst(p, float(ev[3]), Color(0.7, 0.85, 1.0))
				emit_fx("spark", p + Vector3(0, 1.0, 0), 0.8)
				swing_t = 0.26
			K.Ev.HERO_LEVEL:
				emit_fx("level", p + Vector3(0, 0.5, 0), 1.0)
				ring_burst(p, 3.5, Color(1, 0.9, 0.4))
				light_flash(p, Color(1, 0.9, 0.5))
				level_jump = 0.6
				arrive_pull = 3.0
				number(p + Vector3(0, 1.5, 0), tr("UI_HERO_ARRIVING"), Color(1, 0.88, 0.35), 80)
				if int(ev[3]) % 3 == 0:
					say("SAY_HERO", 4, false, Color(0.75, 0.88, 1.0))
			K.Ev.HERO_FALL:
				# Queda curta por membro que cai com a party de pé; longa (a cena toda) só quando a party inteira cai.
				var party_fell := _party_fell(int(ev[4]))
				if party_fell:
					if cine_enabled:
						fall_cinematic(p)
					number(p + Vector3(0, 2.5, 0), tr("UI_HERO_FALLEN").format({"n": int(ev[3])}), Color(1, 0.82, 0.25), 80)
					ring_burst(p, 5.5, Color(1, 0.8, 0.3))
					light_flash(p, Color(1, 0.85, 0.4))
					add_trauma(0.4)
					screen_flash = Color(1, 0.9, 0.6, 0.4)
				else:
					short_fall(p)
					number(p + Vector3(0, 2.0, 0), tr("UI_HERO_FALLEN").format({"n": int(ev[3])}), Color(1, 0.82, 0.25), 56)
					ring_burst(p, 2.2, Color(1, 0.8, 0.3))
					add_trauma(0.12)
			K.Ev.POWER_GAINED:
				ring_burst(p, 5.0, Color(1, 0.9, 0.4))
				emit_fx("level", p + Vector3(0, 0.5, 0), 1.0)
				light_flash(p, Color(1, 0.9, 0.5))
			K.Ev.POWER_TRIGGER:
				_power_fx(p, int(ev[3]))
			K.Ev.SHIELD_BREAK:
				emit_fx("shield", p + Vector3(0, 1.2, 0), 1.0)
				add_trauma(0.2)
				_stop(0.04)
			K.Ev.HEAL:
				if float(ev[3]) >= 20.0:
					number(p, "+" + str(int(ev[3])), Color(0.45, 1, 0.55))
					emit_fx("heal", p + Vector3(0, 0.5, 0), 0.9)
			K.Ev.PART_DESTROYED:
				var big := float(ev[3]) >= 0.0
				emit_fx("fire", p + Vector3(0, 2.0, 0), 2.6 if big else 1.2)
				emit_fx("smoke", p + Vector3(0, 2.0, 0), 2.6 if big else 1.2)
				emit_fx("magic", p + Vector3(0, 2.0, 0), 2.0 if big else 1.0)
				ring_burst(p, 6.0 if big else 3.0, Color(0.9, 0.3, 1.0))
				light_flash(p, Color(0.9, 0.4, 1.0))
				add_trauma(0.8 if big else 0.3)
				if big:
					_stop(0.14)
					screen_flash = Color(1, 0.85, 1, 0.5)
					say("SAY_BOSS_PART", 3, true, Color(1.0, 0.6, 0.9))
			K.Ev.TELEPORT:
				emit_fx("magic", p + Vector3(0, 1.0, 0), 1.6)
				emit_fx("magic", Vector3(sim.arena.bx, 1.0, sim.arena.by), 1.6)
				ring_burst(Vector3(sim.arena.bx, 0, sim.arena.by), 3.0, Color(0.6, 0.3, 1.0))
				say("SAY_BOSS_TP", 2, true, Color(1.0, 0.6, 0.9))
			K.Ev.SPELL:
				var di := int(ev[3])
				if di >= 0 and di < sim.data.cards.size():
					var c: CardDef = sim.data.cards[di]
					if c.category == "finisher":
						say("SAY_BOSS_FIN", 2, true, Color(1.0, 0.85, 0.4))
						screen_flash = Color(1, 0.9, 0.5, 0.4)
						add_trauma(0.5)
					if fx2 != null and c.is_spell and (c.tags & K.TAG_FIRE):
						# Efeitos novos: feitiço de fogo explode em chamas, não no círculo roxo de magia.
						var rr := float(c.fx.get("radius", 2.0))
						emit_fx("fire", p + Vector3(0, 0.3, 0), clampf(rr / 2.0, 1.0, 2.5))
						emit_fx("spark", p + Vector3(0, 0.6, 0), 1.0)
						ring_burst(p, rr, Color(1.0, 0.55, 0.15))
						scorch(p, rr * 1.6)
					elif c.is_spell or c.category == "finisher":
						emit_fx("magic", p + Vector3(0, 0.5, 0), 1.3)
						ring_burst(p, float(c.fx.get("radius", 2.0)), Color(0.75, 0.35, 1.0))
					elif c.is_unit:
						ring_burst(p, 1.6, Color(0.6, 0.4, 1.0))
						emit_fx("magic", p + Vector3(0, 0.3, 0), 0.5)
			K.Ev.CURSE:
				emit_fx("magic", p + Vector3(0, 1.4, 0), 0.6)
			K.Ev.LEECH:
				# Rouba-vida: gotas carmim sobem da unidade que se curou.
				if _spend("hit"):
					emit_fx("heal", p + Vector3(0, 0.6, 0), 0.55, Color(1.0, 0.2, 0.3))
				if Settings.v["damage_numbers"] and float(ev[3]) >= 8.0 and _spend("num"):
					number(p, "+" + str(int(ev[3])), Color(1.0, 0.3, 0.4), 40)
			K.Ev.UNIT_SHIELD_BREAK:
				emit_fx("shield", p + Vector3(0, 0.9, 0), 0.9)
				ring_burst(p, 1.5, Color(0.55, 0.6, 1.0))
			K.Ev.CONTEST:
				var cc := int(ev[4])
				if cc == 1 or cc == -1 or cc >= 11:
					start_scene(int(ev[3]), cc)
			K.Ev.LOCATION:
				var lli := int(ev[3])
				if lli >= 0 and lli < sim.road.locations.size() and str(sim.road.locations[lli]["type"]) in ["shop", "event"]:
					start_scene(lli, 0)
			K.Ev.SHRINE:
				if cine_enabled:
					pass   # a cena do local mostra o resultado do santuário
				elif float(ev[3]) > 0.0:
					emit_fx("level", p + Vector3(0, 1.0, 0), 1.5)
					screen_flash = Color(0.4, 1, 0.6, 0.3)
				else:
					emit_fx("fire", p + Vector3(0, 1.0, 0), 1.5)
					emit_fx("smoke", p + Vector3(0, 1.0, 0), 1.5)
			K.Ev.FEAR:
				ring_burst(p, 2.0, Color(0.6, 0.3, 1.0))
	if fx2 != null:
		fx2.ctx = -1
