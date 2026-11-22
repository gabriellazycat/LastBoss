class_name SimHero
extends RefCounted
## O Escudeiro: atributos, IA por pontuação (rota, movimento, perigo, alvo, upgrades) e escudo frontal.

const DMG_PIERCE := 1     # ignora o escudo
const DMG_SPELL := 2
const DMG_PROJECTILE := 4
const DMG_AREA := 8       # vem de cima / do chão: o escudo não cobre
const TGT_NONE := 0
const TGT_UNIT := 1
const TGT_LOC := 2
const TGT_PART := 3
const TGT_ALTAR := 4
const TGT_PILLAR := 5
const HELPER_PIDX := 99    # índice do Herói Ajudante (chaves por herói, como a Peste, não colidem com a fila)
const HELPER_ENGAGE := 7.0 # Herói Ajudante: raio em que ele escolhe monstros (= a folga da coleira de Sim._follow)
const LEASH_MAX := 18.0   # a coleira estica até aqui enquanto persegue um alvo

var sim: Sim
var H: Dictionary
var AI: Dictionary
var x := 0.0
var y := 0.0
var ox := 0.0
var oy := 0.0
var face_x := 0.0
var face_y := -1.0
var radius := 0.6
var level := 1
var pidx := 0                   # índice deste herói na fila do grupo
var follower := false           # fase de grupo: anda junto do herói da vez, levantado por quem chegou
var is_helper := false          # Herói Ajudante (11/11/2026): briga junto do herói da vez, fora do grupo; some no fim da disputa
# Bônus do Herói Ajudante quando o jogador falha (valem até o fim do ato; herói novo não herda).
var ward := 0.0                 # escudo extra: absorve qualquer dano antes da vida
var bonus_dmg := 0.0            # +dano (fração)
var bonus_regen := 0.0          # +regeneração por s (fração da vida máx)
var bonus_splash := 0.0         # golpe em área (raio em m; 0 = nenhum)
var bonus_splash_mult := 0.0
var xp := 0.0
var hp := 0.0
var base_hp := 0.0
var curses := 0
var shield_hp := 0.0
var shield_max := 0.0
var shield_cos := 0.0
var shield_t := 0.0
var atk_t := 0.0
var upgrades: Dictionary = {}
var upgrade_order: Array = []
var slow_t := 0.0
var fear_t := 0.0
var fear_x := 0.0
var fear_y := 0.0
var root_t := 0.0
var petrify_t := 0.0
var soaked_t := 0.0
var burn_t := 0.0               # seguidor em chamas (Tocha no seguidor encharcado); o da vez usa Sim.burn_t
var burn_dps := 0.0
var tavern_t := 0.0
var drink_t := 0.0              # Fonte: ajoelhado bebendo (não anda nem ataca)
var hold := false               # disputa de local em andamento: fica perto de (hold_x, hold_y)
var hold_x := 0.0
var hold_y := 0.0
var tell: Dictionary = {}       # habilidade -> segundos até disparar (aviso de 1 s sobre o herói)
var kb_x := 0.0
var kb_y := 0.0
var kb_t := 0.0
var s := 0.0
var s_max := 0.0
var seg := 0
var road_dist := 0.0
var target := -1
var target_kind := TGT_NONE
var attacking := false
var near_count := 0
var fury_count := 0                # inimigos no raio da Fúria do Herói
var lure_on := false
var lure_x := 0.0
var lure_y := 0.0
var lure_unit := -1             # Mímico que está puxando o herói agora (-1 = isca de ouro ou nada)
var lure_time := 0.0            # segundos seguidos puxado pelo mesmo Mímico
var stall_t := 0.0              # segundos da janela de avanço atual (fora de disputa)
var prog_mark := 0.0            # ponto da estrada no começo da janela de avanço
var push_t := 0.0               # impaciência: segundos forçando a passagem (sem iscas, só briga de perto)
var spin_t := 0.0
var dash_t := 0.0
var dash_left := 0.0
var dash_x := 0.0
var dash_y := 0.0
var cry_t := 0.0
var ward_cd := 0.0     # recarga do escudo conjurado da Clériga
var strike_t := 0.0
var reflect_t := 0.0
var absorb_t := 0.0   # recarga do "Absorver Almas"
var second_used := false
var share := 1.0   # fração da força da party que é deste herói (1 = sozinho)
var taken: Dictionary = {}
var taken_total := 0.0
var leash_mult := 1.0
var last_hit_t := -100.0
var last_absorbed := 0.0
var danger := PackedFloat32Array()
var dn := 16
var dcell := 2.0
var d_x0 := 0.0
var d_y0 := 0.0
var tmp := PackedInt32Array()


func setup(s_: Sim) -> void:
	sim = s_
	H = sim.data.hero_of(sim.party_class(0), sim.phase_hp_mult, sim.phase_dmg_mult)
	AI = H["ai"]
	share = _party_share(0)
	base_hp = float(H["hp"]) * float(sim.R.get("hero_hp_mult", 1.0)) * share
	hp = base_hp
	radius = H["radius"]
	shield_max = H["shield"]["hp"]
	shield_hp = shield_max
	shield_cos = cos(deg_to_rad(float(H["shield"]["cone"]) * 0.5))
	dn = int(AI["danger_size"])
	dcell = AI["danger_cell"]
	danger.resize(dn * dn)
	var p: Vector2 = sim.road.route[0]
	x = p.x
	y = p.y
	ox = x
	oy = y


## Fase de grupo: um herói que anda junto do da vez (chegou ou foi levantado), na posição de `lead`.
func init_follower(s_: Sim, i: int, lead: SimHero, hp_frac: float) -> void:
	setup(s_)
	next_hero(i)
	follower = true
	hp = base_hp * hp_frac
	upgrades = lead.upgrades.duplicate(true)
	upgrade_order = lead.upgrade_order.duplicate()
	_refresh_shield()
	var a := float(i) * 2.4
	x = lead.x + cos(a) * 1.6
	y = lead.y + sin(a) * 1.6
	ox = x
	oy = y
	s = lead.s
	s_max = lead.s_max
	seg = lead.seg


## Herói Ajudante: outro herói da classe `cls`, parado em `p` com `hp_` de vida; bate como o herói da vez (nível `lv`).
func init_helper(s_: Sim, cls: String, hp_: float, p: Vector2, lv: int, seg_: int) -> void:
	setup(s_)
	is_helper = true
	pidx = HELPER_PIDX
	H = sim.data.hero_of(cls, sim.phase_hp_mult, sim.phase_dmg_mult)
	AI = H["ai"]
	radius = H["radius"]
	shield_max = H["shield"]["hp"]
	shield_hp = shield_max
	shield_cos = cos(deg_to_rad(float(H["shield"]["cone"]) * 0.5))
	level = lv
	base_hp = hp_
	hp = hp_
	x = p.x
	y = p.y
	ox = x
	oy = y
	hold = true
	hold_x = p.x
	hold_y = p.y
	seg = seg_
	s = sim.hero.s
	s_max = sim.hero.s_max


## Fim do ato: os bônus do Herói Ajudante acabam.
func clear_act_bonus() -> void:
	ward = 0.0
	bonus_dmg = 0.0
	bonus_regen = 0.0
	bonus_splash = 0.0
	bonus_splash_mult = 0.0


## Copia o estado de outro herói (o seguidor que vira o herói da vez quando a fila acaba).
func take_over(f: SimHero) -> void:
	next_hero(f.pidx)
	second_used = f.second_used
	hp = f.hp
	upgrades = f.upgrades.duplicate(true)
	upgrade_order = f.upgrade_order.duplicate()
	_refresh_shield()
	x = f.x
	y = f.y
	ox = x
	oy = y
	s = f.s
	s_max = f.s_max
	seg = f.seg


func has(id: String) -> bool:
	return upgrades.has(id)


func max_hp() -> float:
	var R: Dictionary = sim.data.rules["curse"]
	return base_hp * (1.0 - curses * float(R["hp_per_stack"]))


func damage() -> float:
	var m := 1.0 + sim.overtime() * float(sim.data.rules["arena"].get("overtime_hero_dmg", 0.0))
	# Fila cheia na arena (protótipo 10/11/2026, desligado com 0): cada herói que ainda falta na fila deixa o
	# golpe na arena mais forte. Chegar à arena sem ter derrubado heróis na estrada passa a custar caro.
	if sim.phase == K.Phase.ARENA:
		m *= 1.0 + float(sim.data.rules["arena"].get("queue_dmg", 0.0)) * maxi(0, sim.party_size() - 1 - sim.party_idx)
	return float(H["damage"]) * pow(float(sim.data.rules["party"]["step"]), level - 1) * m * (1.0 + bonus_dmg) * share * HeroPowers.dmg_mult(sim)


## Parte da força da party que cabe a este membro: a party soma a força de um herói só, dividida entre os membros
## (expoente em rules.party.share_exp; 1 = divide igual).
func _party_share(i: int) -> float:
	var n := sim.party_n_of(i)
	return 1.0 if n <= 1 else 1.0 / pow(float(n), float(sim.data.rules["party"].get("share_exp", 1.0)))


## Herói seguinte da fila: um nível acima, vida e dano ×step, tudo cheio. Habilidades e dano recebido ficam (são do grupo).
func next_hero(i: int) -> void:
	pidx = i
	H = sim.data.hero_of(sim.party_class(i), sim.phase_hp_mult, sim.phase_dmg_mult)
	shield_max = H["shield"]["hp"]
	shield_cos = cos(deg_to_rad(float(H["shield"]["cone"]) * 0.5))
	level = sim.party_number(i) + 1
	share = _party_share(i)
	base_hp = float(H["hp"]) * pow(float(sim.data.rules["party"]["step"]), sim.party_number(i)) * float(sim.R.get("hero_hp_mult", 1.0)) * share
	curses = 0
	hp = base_hp
	shield_hp = shield_max
	shield_t = 0.0
	_refresh_shield()   # o Escudo de Torre é do grupo: o herói seguinte (se tem escudo) o mantém
	slow_t = 0.0
	fear_t = 0.0
	root_t = 0.0
	petrify_t = 0.0
	soaked_t = 0.0
	tavern_t = 0.0
	drink_t = 0.0
	tell = {}
	kb_t = 0.0
	dash_left = 0.0
	spin_t = 0.0
	second_used = false
	target = -1
	target_kind = TGT_NONE
	last_hit_t = -100.0
	clear_act_bonus()


func xp_needed() -> float:
	var X: Dictionary = sim.data.rules["hero_xp"]
	return float(X["level2"]) * pow(1.0 + float(X["growth"]), level - 1)


func cls() -> String:
	return str(H.get("class", "escudeiro"))


func hp_frac() -> float:
	return hp / max_hp()


# ---------------------------------------------------------------- tick

func update(dt: float) -> void:
	ox = x
	oy = y
	slow_t = maxf(0.0, slow_t - dt)
	fear_t = maxf(0.0, fear_t - dt)
	root_t = maxf(0.0, root_t - dt)
	petrify_t = maxf(0.0, petrify_t - dt)
	soaked_t = maxf(0.0, soaked_t - dt)
	tavern_t = maxf(0.0, tavern_t - dt)
	drink_t = maxf(0.0, drink_t - dt)
	for k in tell:
		tell[k] = float(tell[k]) - dt
	spin_t -= dt
	dash_t -= dt
	cry_t -= dt
	strike_t -= dt
	reflect_t -= dt
	absorb_t -= dt
	if shield_hp <= 0.0:
		shield_t -= dt
		if shield_t <= 0.0:
			shield_hp = shield_max
	var regen: float = H.get("regen", 0.0) + bonus_regen
	if regen > 0.0 and petrify_t <= 0.0 and hp > 0.0 and sim.overtime() <= 0.0:
		hp = minf(max_hp(), hp + max_hp() * regen * dt)
	_cast_ward(dt)
	if sim.tick % sim.ai_period == 0:
		_choose_target()
		_rebuild_danger()
	_validate_target()
	_move(dt)
	if is_helper:
		# Herói Ajudante (15/11/2026): anda e briga ao lado do herói da vez. O ponto de espera (hold) acompanha o
		# herói e a coleira fica em Sim._follow; sem a lógica de estrada (progresso, impaciência) do herói da vez.
		_attack(dt)
		return
	if sim.phase == K.Phase.ROAD:
		# O progresso só recua um pouco: senão a projeção escorrega para trás e a coleira o arrasta.
		var pr := sim.road.project(Vector2(x, y), seg, s_max - float(sim.data.rules["road"]["max_backtrack"]))
		s = pr.x
		# Impaciência (10/11/2026): sem avançar na estrada por stall_s s (fora de disputa), ele força a
		# passagem por push_s s: ignora iscas e só briga com o que está colado nele. Sem isso, Isca de Ouro e
		# Mímico fora do alcance seguravam o herói até o tempo da run acabar.
		if s < prog_mark - 30.0:
			prog_mark = s   # estrada nova (ato seguinte) ou herói novo
		if hold or follower:
			prog_mark = s
			stall_t = 0.0
		else:
			# A cada stall_s s, conta quanto andou; menos que stall_min m é travado.
			stall_t += dt
			if stall_t > float(AI.get("stall_s", 20.0)):
				if s - prog_mark < float(AI.get("stall_min", 10.0)):
					push_t = float(AI.get("push_s", 15.0))
				stall_t = 0.0
				prog_mark = s
		# Ato longo demais (act_soft s): impaciente até o fim do ato, para nenhuma run parar na estrada.
		var acts_done: Array = sim.stats.get("act_t", [])
		var act_t0: float = acts_done[-1] if acts_done.size() > 0 else 0.0
		if sim.t - act_t0 > float(AI.get("act_soft", 600.0)):
			push_t = maxf(push_t, 1.0)
		push_t = maxf(0.0, push_t - dt)
		s_max = maxf(s_max, s)
		seg = int(pr.y)
		road_dist = pr.z
		var leash: float = float(sim.data.rules["road"]["leash"]) * leash_mult
		# Perseguindo: o alvo está a no máximo LEASH_MAX - 3 m da estrada (_choose_target), então sempre dá para alcançá-lo.
		if target_kind == TGT_UNIT and leash_mult >= 1.0:
			leash = LEASH_MAX
		if road_dist > leash:
			# Volta para a coleira andando rápido, sem tranco; só o limite máximo é rígido.
			var excess := road_dist - leash
			var pull := minf(excess, maxf(road_dist - LEASH_MAX, float(H["speed"]) * 2.0 * dt))
			var q := sim.road.point_at(s)
			var k := pull / road_dist
			x += (q.x - x) * k
			y += (q.y - y) * k
	else:
		var ar := sim.arena
		var v := Vector2(x - ar.cx, y - ar.cy)
		var lim: float = float(sim.data.rules["arena"]["radius"]) - radius
		if v.length() > lim:
			v = v.normalized() * lim
			x = ar.cx + v.x
			y = ar.cy + v.y
	_attack(dt)
	_abilities()


func _move(dt: float) -> void:
	attacking = false
	if petrify_t > 0.0 or root_t > 0.0:
		return
	if drink_t > 0.0 and fear_t <= 0.0 and kb_t <= 0.0:
		return
	var speed: float = H["speed"] * sim.hero_speed_mult(self)   # Piche (relíquia)
	if slow_t > 0.0:
		var sl: float = sim.data.rules["status"]["slow"]
		if has("steady_boots"):
			sl *= float(upgrades["steady_boots"]["slow_mult"])
		speed *= 1.0 - sl
	var mv := Vector2.ZERO
	if kb_t > 0.0:
		kb_t -= dt
		x += kb_x * dt
		y += kb_y * dt
		return
	if dash_left > 0.0:
		var st := minf(dash_left, 25.0 * dt)
		dash_left -= st
		x += dash_x * st
		y += dash_y * st
		return
	if fear_t > 0.0:
		mv = Vector2(fear_x, fear_y)
		x += mv.x * speed * dt
		y += mv.y * speed * dt
		return
	var tpos := _target_pos()
	var reach := attack_reach()
	var tdist := INF
	# closing: no alcance, mas o alvo está escapando pela borda; continua perseguindo a toda.
	var closing := false
	if target_kind != TGT_NONE:
		tdist = Vector2(x, y).distance_to(tpos)
		if tdist <= reach:
			attacking = true
			closing = target_kind == TGT_UNIT and tdist > reach * 0.7
	# Seguir a estrada (ou, na arena, ir até o chefe).
	var road_dir := Vector2.ZERO
	if sim.phase == K.Phase.ROAD:
		if hold:
			# Disputa de local: fica no local (anda até ele e espera lá).
			var to := Vector2(hold_x - x, hold_y - y)
			if to.length() > float(sim.data.rules["locations"].get("hold_radius", 2.5)):
				road_dir = to.normalized()
		else:
			road_dir = (sim.road.point_at(s + 5.0) - Vector2(x, y)).normalized()
	else:
		road_dir = (Vector2(sim.arena.bx, sim.arena.by) - Vector2(x, y)).normalized()
	# Disputa da Ponte (16/11/2026): ele fica no tabuleiro mesmo brigando (a briga é na ponte).
	var firm := hold and sim.contest.size() > 0 and str(sim.contest.get("type", "")) == "bridge" 		and bool(sim.data.rules["road"].get("river", {}).get("enabled", true))
	mv += road_dir * float(AI["road_weight"]) * (0.25 if attacking and not firm else 1.0)
	if target_kind != TGT_NONE and (closing or not attacking):
		mv += (tpos - Vector2(x, y)).normalized() * float(AI["target_weight"])
	if lure_on:
		mv += (Vector2(lure_x, lure_y) - Vector2(x, y)).normalized() * 2.2
	# Fugir do perigo: gradiente do mapa.
	var cx := int((x - d_x0) / dcell)
	var cy := int((y - d_y0) / dcell)
	if cx > 0 and cy > 0 and cx < dn - 1 and cy < dn - 1:
		var here := danger[cy * dn + cx]
		if here > 0.5:
			var g := Vector2(danger[cy * dn + cx + 1] - danger[cy * dn + cx - 1], danger[(cy + 1) * dn + cx] - danger[(cy - 1) * dn + cx])
			if g.length() > 0.01:
				var k := clampf(here / 60.0, 0.0, 1.0) * (1.5 if hp_frac() < float(AI["low_hp"]) else 0.5) / float(AI["aggression"])
				mv -= g.normalized() * float(AI["flee_weight"]) * k
	if mv.length() > 0.01:
		mv = mv.normalized()
		var sp := speed * (float(H["attack_move_mult"]) if attacking and not closing else 1.0)
		x += mv.x * sp * dt
		y += mv.y * sp * dt
	# Encarar o alvo (o escudo fica na frente) ou a direção do movimento.
	var f := Vector2.ZERO
	if target_kind != TGT_NONE and tdist < 6.0:
		f = tpos - Vector2(x, y)
	elif mv.length() > 0.01:
		f = mv
	if f.length() > 0.01:
		f = Vector2(face_x, face_y).lerp(f.normalized(), 0.35).normalized()
		face_x = f.x
		face_y = f.y


func attack_reach() -> float:
	var r: float = H["attack_range"] + radius * 0.5
	match target_kind:
		TGT_UNIT:
			if target >= 0:
				r += sim.units.rad[target]
		TGT_LOC:
			r += 1.5
		TGT_PART:
			r += 0.9
		TGT_ALTAR:
			r += 0.8
		TGT_PILLAR:
			r += sim.arena.pillar_r
	return r


func _target_pos() -> Vector2:
	match target_kind:
		TGT_UNIT:
			return Vector2(sim.units.px[target], sim.units.py[target])
		TGT_LOC:
			return sim.road.locations[target]["pos"]
		TGT_PART:
			return sim.arena.part_pos(target)
		TGT_ALTAR:
			return sim.arena.altar_pos[target]
		TGT_PILLAR:
			return sim.arena.pillar_pos[target]
	return Vector2(x, y)


func _validate_target() -> void:
	match target_kind:
		TGT_UNIT:
			if target < 0 or sim.units.alive[target] == 0 or (sim.units.flags[target] & K.F_STONE):
				target_kind = TGT_NONE
		TGT_LOC:
			if sim.road.locations[target]["state"] != SimRoad.LocState.ACTIVE:
				target_kind = TGT_NONE
		TGT_PART:
			if not sim.arena.part_attackable(target):
				target_kind = TGT_NONE
		TGT_ALTAR:
			if not sim.arena.altar_alive[target]:
				target_kind = TGT_NONE
		TGT_PILLAR:
			if not sim.arena.pillar_alive(target):
				target_kind = TGT_NONE


func _attack(dt: float) -> void:
	if petrify_t > 0.0 or target_kind == TGT_NONE or drink_t > 0.0:
		return
	var m := 1.0
	if tavern_t > 0.0:
		m += float(sim.data.rules["locations"]["bridge"]["attack_speed"])
	if slow_t > 0.0:
		var sl: float = sim.data.rules["status"]["slow"]
		if has("steady_boots"):
			sl *= float(upgrades["steady_boots"]["slow_mult"])
		m *= 1.0 - sl
	if has("hero_fury"):
		var u: Dictionary = upgrades["hero_fury"]
		m *= 1.0 + minf(float(u["cap"]), fury_count * float(u["per_unit"]))
	atk_t -= dt * m
	if atk_t > 0.0:
		return
	if Vector2(x, y).distance_to(_target_pos()) > attack_reach():
		atk_t = 0.0
		return
	atk_t = H["attack_interval"]
	var dmg := damage()
	if has("purifying_blade") and curses > 0:
		curses = maxi(0, curses - int(upgrades["purifying_blade"]["remove"]))
	# Herói à distância: sai um projétil da arma até o alvo (só visual; o dano é imediato).
	var pk := str(H.get("projectile", ""))
	if pk != "":
		var tp := _target_pos()
		sim.emit(K.Ev.HERO_SHOT, x, y, tp.x, (int(tp.y * 100.0) << 2) | (1 if pk == "orb" else 0))
	match target_kind:
		TGT_UNIT:
			var tx := sim.units.px[target]
			var ty := sim.units.py[target]
			sim.hero_hits_unit(target, _unit_mult(target, dmg, true))
			_cleave(tx, ty, dmg)
			_splash(tx, ty, dmg)
		TGT_PART:
			sim.arena.damage_part(target, dmg * _strike(true))
		TGT_ALTAR:
			sim.arena.damage_altar(target, dmg * _hammer())
		TGT_PILLAR:
			sim.arena.damage_pillar(target, dmg * _hammer())


## Martelo Quebra-pedra também vale contra altares e pilares (pedra).
func _hammer() -> float:
	return float(upgrades["stone_hammer"]["mult"]) if has("stone_hammer") else 1.0


## Golpe em arco: atinge também quem está à frente, no alcance.
func _cleave(tx: float, ty: float, dmg: float) -> void:
	var arc: float = H.get("cleave_arc", 0.0)
	if arc <= 0.0:
		return
	var dir := Vector2(tx - x, ty - y).normalized()
	var c := cos(deg_to_rad(arc * 0.5))
	var r: float = H["attack_range"] + radius
	var U := sim.units
	U.within(x, y, r + 0.4, tmp)
	for i in tmp.duplicate():
		if i == target or U.alive[i] == 0 or (U.flags[i] & K.F_STONE):
			continue
		var v := Vector2(U.px[i] - x, U.py[i] - y)
		if v.length() < 0.01 or v.normalized().dot(dir) >= c:
			sim.hero_hits_unit(i, _unit_mult(i, dmg, false))


## Mago: o golpe explode no alvo e atinge todos em volta.
func _splash(tx: float, ty: float, dmg: float) -> void:
	var r: float = H.get("splash", 0.0)
	var sm := float(H.get("splash_mult", 0.7))
	if bonus_splash > r:
		r = bonus_splash
		sm = bonus_splash_mult
	if r <= 0.0:
		return
	var U := sim.units
	U.within(tx, ty, r, tmp)
	for i in tmp.duplicate():
		if i == target or U.alive[i] == 0 or (U.flags[i] & K.F_STONE):
			continue
		sim.hero_hits_unit(i, _unit_mult(i, dmg * sm, false))
	sim.emit(K.Ev.EXPLOSION, tx, ty, r, 2)


func _strike(big: bool) -> float:
	if has("heroic_strike") and big and strike_t <= 0.0:
		strike_t = upgrades["heroic_strike"]["interval"]
		sim.ability_fired("heroic_strike")
		return float(upgrades["heroic_strike"]["mult"])
	return 1.0


func _unit_mult(i: int, dmg: float, main_hit: bool) -> float:
	var t := sim.units.tags[i]
	if has("holy_water") and (t & (K.TAG_UNDEAD | K.TAG_SHADOW)):
		dmg *= float(upgrades["holy_water"]["mult"])
	if has("stone_hammer") and (t & K.TAG_CONSTRUCT):
		dmg *= float(upgrades["stone_hammer"]["mult"])
	if main_hit and has("heroic_strike"):
		dmg *= _strike(sim.units.max_hp[i] >= float(upgrades["heroic_strike"]["big_hp"]))
	return dmg


## Aviso de habilidade: a primeira chamada começa a preparação (1 s, evento ABILITY_TELL) e devolve false;
## devolve true quando a preparação acabou. Se a condição cai no meio, `_untell` cancela.
func _tell(id: String) -> bool:
	if not tell.has(id):
		tell[id] = float(H.get("ability_tell_s", 1.0))
		sim.emit(K.Ev.ABILITY_TELL, x, y, float(ability_index(id)), 0)
		return float(tell[id]) <= 0.0
	if float(tell[id]) > 0.0:
		return false
	tell.erase(id)
	sim.ability_fired(id)
	return true


func _untell(id: String) -> void:
	tell.erase(id)


func ability_index(id: String) -> int:
	var ups: Array = H["upgrades"]
	for k in ups.size():
		if ups[k]["id"] == id:
			return k
	return -1


## "Absorver Almas": cura quando um monstro morre, no máximo uma vez por recarga
## (sem ela o enxame torna o herói imortal).
func soul_absorb_on_kill() -> void:
	if not has("soul_absorb") or absorb_t > 0.0:
		return
	var p: Dictionary = upgrades["soul_absorb"]
	heal(max_hp() * float(p["heal"]))
	absorb_t = p["cooldown"]


## Clériga: a cada `cooldown` s conjura um escudo (ward) de `pct` da vida atual do alvo, em si mesma ou no amigo
## (herói da vez, seguidores, ajudante) mais ferido a até `range` m.
func _cast_ward(dt: float) -> void:
	var W: Dictionary = H.get("ward_cast", {})
	if W.is_empty():
		return
	ward_cd -= dt
	if ward_cd > 0.0 or hp <= 0.0 or petrify_t > 0.0 or drink_t > 0.0 or sim.overtime() > 0.0:
		return
	var best: SimHero = null
	var best_f := 2.0
	var r2 := float(W["range"]) * float(W["range"])
	for a in [sim.hero] + sim.followers + ([sim.helper] if sim.helper != null else []):
		if a.hp <= 0.0:
			continue
		if a != self and (a.x - x) * (a.x - x) + (a.y - y) * (a.y - y) > r2:
			continue
		var f: float = a.hp_frac()
		if f < best_f:
			best_f = f
			best = a
	if best == null:
		return
	best.ward += best.hp * float(W["pct"])
	ward_cd = float(W["cooldown"])


## Estado de uma habilidade para a HUD: (recarga que falta, recarga total, preparação que falta ou -1).
## Habilidades passivas devolvem recarga 0 e total 0.
func ability_state(id: String) -> Vector3:
	var tl := float(tell.get(id, -1.0))
	match id:
		"sword_spin":
			return Vector3(maxf(0.0, spin_t), float(upgrades[id]["interval"]), tl)
		"war_cry":
			return Vector3(maxf(0.0, cry_t), float(upgrades[id]["cooldown"]), tl)
		"dash":
			return Vector3(maxf(0.0, dash_t), float(upgrades[id]["cooldown"]), tl)
		"heroic_strike":
			return Vector3(maxf(0.0, strike_t), float(upgrades[id]["interval"]), -1.0)
		"reflect_shield":
			return Vector3(maxf(0.0, reflect_t), float(upgrades[id]["cooldown"]), -1.0)
		"soul_absorb":
			return Vector3(maxf(0.0, absorb_t), float(upgrades[id]["cooldown"]), -1.0)
		"second_wind":
			return Vector3(1.0 if second_used else 0.0, 1.0 if second_used else 0.0, -1.0)
	return Vector3(0.0, 0.0, -1.0)


func _abilities() -> void:
	if petrify_t > 0.0 or drink_t > 0.0:
		return
	var U := sim.units
	if has("sword_spin") and spin_t <= 0.0:
		var p: Dictionary = upgrades["sword_spin"]
		U.within(x, y, float(p["radius"]) + 0.5, tmp)
		if tmp.is_empty():
			_untell("sword_spin")
		elif _tell("sword_spin"):
			spin_t = p["interval"]
			sim.emit(K.Ev.SPIN, x, y, float(p["radius"]), 0)
			var hit := tmp.duplicate()
			for i in hit:
				if U.alive[i] == 1 and not (U.flags[i] & K.F_STONE):
					sim.hero_hits_unit(i, _unit_mult(i, damage() * float(p["mult"]), false))
	if has("war_cry") and cry_t <= 0.0:
		var p: Dictionary = upgrades["war_cry"]
		U.within(x, y, p["radius"], tmp)
		var small := 0
		for i in tmp:
			if U.max_hp[i] < float(p["max_hp"]) and U.arch[i] != K.Arch.STRUCTURE:
				small += 1
		if small < 3:
			_untell("war_cry")
		elif _tell("war_cry"):
			cry_t = p["cooldown"]
			for i in tmp:
				if U.max_hp[i] < float(p["max_hp"]) and U.arch[i] != K.Arch.STRUCTURE:
					U.fear_t[i] = sim.data.rules["status"]["fear"]
			sim.emit(K.Ev.FEAR, x, y, float(p["radius"]), 1)
	if has("dash") and dash_t <= 0.0 and sim.phase == K.Phase.ROAD:
		var p: Dictionary = upgrades["dash"]
		if not (near_count >= int(p["surround"]) or slow_t > 0.0):
			_untell("dash")
		elif _tell("dash"):
			dash_t = p["cooldown"]
			var dir := (sim.road.point_at(s + 8.0) - Vector2(x, y)).normalized()
			dash_x = dir.x
			dash_y = dir.y
			dash_left = p["distance"]
			slow_t = 0.0
	if hp > 0.0 and hp < max_hp() and (sim.phase == K.Phase.ROAD or H.get("regen_in_arena", true)):
		var rg: float = H.get("regen_combat", 0.0)
		if near_count == 0 and sim.t - last_hit_t > float(H.get("regen_delay", 3.0)):
			rg = H.get("regen_per_s", 0.0)
		if rg > 0.0:
			hp = minf(max_hp(), hp + max_hp() * rg * sim.dt)
	if has("second_wind") and not second_used:
		var p: Dictionary = upgrades["second_wind"]
		if hp_frac() < float(p["below"]):
			second_used = true
			sim.ability_fired("second_wind")
			heal(max_hp() * float(p["heal"]))


# ---------------------------------------------------------------- IA

func _rebuild_danger() -> void:
	danger.fill(0.0)
	d_x0 = x - dn * dcell * 0.5
	d_y0 = y - dn * dcell * 0.5
	var U := sim.units
	near_count = 0
	fury_count = 0
	var fr := float(upgrades["hero_fury"]["radius"]) if has("hero_fury") else 0.0
	for i in U.hi:
		if U.alive[i] == 0:
			continue
		var dx := U.px[i] - x
		var dy := U.py[i] - y
		if dx * dx + dy * dy < 16.0:
			near_count += 1
		if dx * dx + dy * dy < fr * fr:
			fury_count += 1
		# O alvo atual não espanta o herói: senão ele recua de quem está tentando acertar.
		if target_kind == TGT_UNIT and i == target:
			continue
		var cx := int((U.px[i] - d_x0) / dcell)
		var cy := int((U.py[i] - d_y0) / dcell)
		if cx < 1 or cy < 1 or cx >= dn - 1 or cy >= dn - 1:
			continue
		var th := U.dmg[i] / maxf(U.atk_int[i], 0.1)
		if U.arch[i] == K.Arch.KAMIKAZE:
			th += 60.0
		_splat(cx, cy, th)
	for z in sim.zones:
		if z["kind"] == "web" or z["kind"] == "oil":
			var cx := int((z["x"] - d_x0) / dcell)
			var cy := int((z["y"] - d_y0) / dcell)
			if cx >= 1 and cy >= 1 and cx < dn - 1 and cy < dn - 1:
				_splat(cx, cy, 25.0)


func _splat(cx: int, cy: int, v: float) -> void:
	var c := cy * dn + cx
	danger[c] += v
	danger[c - 1] += v * 0.5
	danger[c + 1] += v * 0.5
	danger[c - dn] += v * 0.5
	danger[c + dn] += v * 0.5


func _choose_target() -> void:
	var U := sim.units
	var engage: float = AI["engage_radius"]
	var strat: Dictionary = AI["strategic"]
	var best := -1
	var best_kind := TGT_NONE
	var best_score := -INF
	var arena := sim.phase == K.Phase.ARENA
	var unit_r := 3.0 if arena else engage
	if is_helper:
		unit_r = minf(unit_r, HELPER_ENGAGE)   # vai atrás do que chega perto do grupo, sem se afastar do herói
	if push_t > 0.0 and not arena:
		unit_r = minf(unit_r, 2.5)   # impaciência: só o que está colado nele
	# Prorrogação longa (10/11/2026): depois de 2 min dela, o herói vai no chefe e só briga com o que está
	# colado nele. Com o elixir da prorrogação o covil enchia a arena e ele nunca chegava ao chefe.
	var charge := arena and sim.overtime() > 2.0
	# Na arena ele caça atiradores e estruturas mais longe (rodada 09/11/2026); o resto, só de perto.
	var hunt_r := float(sim.data.rules["arena"].get("hunt_radius", 3.0)) if arena else engage
	var houses: Array = sim.live_houses()
	var defend := float(sim.data.rules["locations"]["tavern"].get("defend", 0.0))
	var was_lured := lure_unit
	lure_on = false
	lure_unit = -1
	var nose := has("treasure_nose") or push_t > 0.0
	var lure_d := INF
	# Rio (16/11/2026): alvo do outro lado da água é ignorado (o herói não corre até a ponte por um monstro).
	var water: SimTerrain = sim.terra() if not arena else null
	for i in U.hi:
		if U.alive[i] == 0:
			continue
		if water != null and water.ok and not water.same_side(x, y, U.px[i], U.py[i]):
			continue
		var dx := U.px[i] - x
		var dy := U.py[i] - y
		var d := sqrt(dx * dx + dy * dy)
		var di := U.def[i]
		if di == U.d_mimic and not nose and not (U.flags[i] & (K.F_BITTEN | K.F_SNUBBED)):
			var lr: float = sim.data.cards[di].fx.get("lure_radius", 10.0)
			if d < lr and d < lure_d:
				lure_d = d
				lure_on = true
				lure_x = U.px[i]
				lure_y = U.py[i]
				lure_unit = i
			continue
		var far_ok := arena and (U.arch[i] == K.Arch.SHOOTER or U.arch[i] == K.Arch.STRUCTURE) and not charge
		if d > (hunt_r if far_ok else (1.2 if charge else unit_r)) or (U.flags[i] & K.F_STONE) or (di == U.d_tower and not arena):
			continue
		var th := U.dmg[i] / maxf(U.atk_int[i], 0.1)
		var sc := th * 0.05 + (1.0 - U.hp[i] / U.max_hp[i]) + float(strat.get(sim.data.cards[di].id, 0.0)) - d * (0.12 if far_ok else 0.35)
		if arena:
			sc += 2.0
		# Taverna em disputa: quem está atacando uma casa vira prioridade.
		for k in houses:
			if sim.house_pos(k).distance_to(Vector2(U.px[i], U.py[i])) < 3.0:
				sc += defend
				break
		# Longe demais da estrada: a coleira não deixa alcançar, então nem tenta (senão fica parado olhando).
		# O alvo atual tem folga, para não trocar de ideia na borda.
		if not arena and sc > best_score:
			var lim := LEASH_MAX - (0.5 if target_kind == TGT_UNIT and i == target else 3.0)
			if sim.road.project(Vector2(U.px[i], U.py[i]), seg).z > lim:
				continue
		if sc > best_score:
			best_score = sc
			best = i
			best_kind = TGT_UNIT
	if not nose:
		for z in sim.zones:
			if z["kind"] == "bait":
				var d := Vector2(x, y).distance_to(Vector2(z["x"], z["y"]))
				if d < lure_d:
					lure_d = d
					lure_on = true
					lure_x = z["x"]
					lure_y = z["y"]
	if arena:
		var ar := sim.arena
		if best_kind == TGT_NONE:
			for k in ar.part_hp.size():
				if not ar.part_attackable(k):
					continue
				var d := Vector2(x, y).distance_to(ar.part_pos(k))
				var sc := float(ar.part_value[k]) * 2.0 + (1.0 - ar.part_hp[k] / ar.part_max[k]) - d * 0.05
				if sc > best_score:
					best_score = sc
					best = k
					best_kind = TGT_PART
			# Pilar no caminho até o chefe: quebrar.
			var to_boss := Vector2(ar.bx - x, ar.by - y).normalized()
			for k in ar.pillar_pos.size():
				if not ar.pillar_alive(k):
					continue
				var pv: Vector2 = ar.pillar_pos[k] - Vector2(x, y)
				if pv.length() < 2.6 and pv.normalized().dot(to_boss) > 0.75:
					var sc := 4.0 - pv.length()
					if sc > best_score:
						best_score = sc
						best = k
						best_kind = TGT_PILLAR
			for k in ar.altar_pos.size():
				if not ar.altar_alive[k] or k == ar.altar:
					continue
				var d := Vector2(x, y).distance_to(ar.altar_pos[k])
				if d < 5.0:
					var sc := float(strat.get("altar", 1.0)) * 3.0 - d * 0.1
					if sc > best_score:
						best_score = sc
						best = k
						best_kind = TGT_ALTAR
	# Isca que não se alcança (Mímico longe da estrada, no meio de monstros): depois de lure_giveup s puxado
	# pelo mesmo Mímico sem chegar, o herói desiste dele. Sem isso a run travava até o tempo acabar (10/11/2026).
	if lure_unit >= 0 and lure_unit == was_lured:
		lure_time += sim.dt * float(sim.ai_period)
		if lure_time > float(AI.get("lure_giveup", 8.0)):
			U.flags[lure_unit] |= K.F_SNUBBED
			lure_on = false
			lure_unit = -1
			lure_time = 0.0
	elif lure_unit != was_lured:
		lure_time = 0.0
	target = best
	target_kind = best_kind


func choose_upgrade(options: Array) -> String:
	var best := ""
	var best_w := -1.0
	for id in options:
		var w := upgrade_weight(id)
		if w > best_w:
			best_w = w
			best = id
	return best


## Peso do upgrade: peso da classe × resposta ao que mais machucou o herói.
func upgrade_weight(id: String) -> float:
	var u: Dictionary = sim.data.upgrades[id]
	var share := 0.0
	if taken_total > 0.0:
		for c in u["counters"]:
			share += float(taken.get(c, 0.0)) / taken_total
	return float(u["weight"]) * (1.0 + float(AI["upgrade_counter_gain"]) * share)


func apply_upgrade(id: String) -> void:
	var u: Dictionary = sim.data.upgrades[id]
	upgrades[id] = u["p"]
	upgrade_order.append(id)
	if id == "tower_shield":
		_refresh_shield()


## Escudo da classe; com o Escudo de Torre (habilidade do grupo), vida e cone maiores para quem tem escudo.
func _refresh_shield() -> void:
	shield_max = float(H["shield"]["hp"])
	shield_cos = cos(deg_to_rad(float(H["shield"]["cone"]) * 0.5))
	if has("tower_shield") and shield_max > 0.0:
		var p: Dictionary = upgrades["tower_shield"]
		shield_max *= float(p["hp_mult"])
		shield_cos = cos(deg_to_rad(float(p["cone"]) * 0.5))
	shield_hp = shield_max


func level_up() -> void:
	var before := max_hp()
	level += 1
	base_hp *= 1.0 + float(H["hp_growth"])
	hp += max_hp() - before


# ---------------------------------------------------------------- dano

func note(key: String, v: float) -> void:
	taken[key] = float(taken.get(key, 0.0)) + v
	taken_total += v
	if self != sim.helper:
		HeroPowers.note(sim, key, v)   # dano da party toda: estilo do jogador no sorteio dos poderes


## Aplica dano vindo de (sx, sy). Devolve o dano que chegou à vida.
func take_damage(amount: float, sx: float, sy: float, src_tags: int, kind: int) -> float:
	last_absorbed = 0.0
	if amount <= 0.0 or hp <= 0.0:
		return 0.0
	if src_tags & K.TAG_FIRE:
		if soaked_t > 0.0:
			amount *= float(sim.data.rules["fire_vs_soaked"])
		if has("fireproof"):
			amount *= float(upgrades["fireproof"]["fire_mult"])
		amount *= HeroPowers.fire_mult(sim)   # poder fire_ward
	if (kind & DMG_SPELL) and self != sim.helper and HeroPowers.spell_hit(sim):
		return 0.0   # poder spell_ward: o feitiço é anulado
	if (kind & DMG_SPELL) and has("reflect_shield") and reflect_t <= 0.0:
		reflect_t = upgrades["reflect_shield"]["cooldown"]
		sim.emit(K.Ev.SHIELD_BREAK, x, y, 0.0, 1)
		sim.ability_fired("reflect_shield")
		return 0.0
	if ward > 0.0:
		# Escudo do Herói Ajudante (Escudeiro): absorve qualquer dano antes do escudo frontal e da vida.
		var wb := minf(ward, amount)
		ward -= wb
		amount -= wb
		last_absorbed += wb
		if amount <= 0.0:
			return 0.0
	var pierce := (kind & (DMG_PIERCE | DMG_AREA)) != 0 or (src_tags & K.TAG_SHADOW) != 0
	if not pierce and shield_hp > 0.0:
		var to := Vector2(sx - x, sy - y)
		if to.length() > 0.01:
			to = to.normalized()
			if to.x * face_x + to.y * face_y >= shield_cos:
				var ab := minf(shield_hp, amount)
				last_absorbed += ab
				shield_hp -= ab
				amount -= ab
				if shield_hp <= 0.0:
					shield_hp = 0.0
					shield_t = H["shield"]["regen_seconds"]
					sim.on_shield_break()
	if amount <= 0.0:
		return 0.0
	amount = minf(amount, hp)
	hp -= amount
	last_hit_t = sim.t
	if src_tags & K.TAG_PACK: note("pack", amount)
	if src_tags & K.TAG_UNDEAD: note("undead", amount)
	if src_tags & K.TAG_SHADOW: note("shadow", amount)
	if src_tags & K.TAG_FIRE: note("fire", amount)
	if src_tags & K.TAG_CONSTRUCT: note("construct", amount)
	if kind & DMG_PROJECTILE: note("projectile", amount)
	if kind & DMG_SPELL: note("spell", amount)
	if amount >= 100.0: note("burst", amount)
	if near_count >= int(sim.data.upgrades["dash"]["p"]["surround"]): note("surround", amount)
	return amount


func heal(v: float) -> void:
	if v <= 0.0:
		return
	var m := max_hp()
	var real := minf(v, m - hp)
	if real > 0.0:
		hp += real
		sim.emit(K.Ev.HEAL, x, y, real, 0)


func add_curse(n: int) -> void:
	var cap: int = sim.data.rules["curse"]["max_stacks"]
	var before := curses
	curses = mini(cap, curses + n)
	if curses > before:
		note("curse", 60.0 * (curses - before))
		hp = minf(hp, max_hp())
		sim.emit(K.Ev.CURSE, x, y, curses, 0)


func knockback(from_x: float, from_y: float, dist: float) -> void:
	if has("steady_boots"):
		return
	var v := Vector2(x - from_x, y - from_y)
	if v.length() < 0.01:
		v = Vector2(-face_x, -face_y)
	v = v.normalized() * dist * float(sim.data.rules.get("hero", {}).get("knockback_mult", 1.0)) / 0.25
	kb_x = v.x
	kb_y = v.y
	kb_t = 0.25
	note("knockback", 40.0)


func fear(from_x: float, from_y: float, dur := -1.0) -> void:
	var v := Vector2(x - from_x, y - from_y)
	if v.length() < 0.01:
		v = Vector2(0, 1)
	v = v.normalized()
	fear_x = v.x
	fear_y = v.y
	fear_t = dur if dur > 0.0 else float(sim.data.rules["status"]["fear"])
