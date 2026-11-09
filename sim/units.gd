class_name SimUnits
extends RefCounted
## Monstros do jogador como arrays paralelos (sem nó por unidade) com lista livre: pooling total.

var sim: Sim
var cap := 0
var hi := 0
var count := 0

var alive := PackedByteArray()
var def := PackedInt32Array()
var arch := PackedByteArray()
var gen := PackedByteArray()
var px := PackedFloat32Array()
var py := PackedFloat32Array()
var ox := PackedFloat32Array()
var oy := PackedFloat32Array()
var ax := PackedFloat32Array()
var ay := PackedFloat32Array()
var hp := PackedFloat32Array()
var max_hp := PackedFloat32Array()
var dmg := PackedFloat32Array()
var atk_int := PackedFloat32Array()
var atk_t := PackedFloat32Array()
var spd := PackedFloat32Array()
var rng := PackedFloat32Array()
var rad := PackedFloat32Array()
var xp := PackedFloat32Array()
var cost_share := PackedFloat32Array()
var timer := PackedFloat32Array()
var timer2 := PackedFloat32Array()
var curse_t := PackedFloat32Array()
var buff := PackedFloat32Array()
var fear_t := PackedFloat32Array()
var slot := PackedFloat32Array()
var tags := PackedInt32Array()
var flags := PackedInt32Array()
var uid := PackedInt32Array()
var lvl := PackedByteArray()   # nível da carta que gerou a unidade (1 a 3)

var free := PackedInt32Array()
var free_n := 0
var dmg_mult := 1.0
var proj_mult := 1.0

# Contagens do último tick.
var n_pack := 0
var n_struct := 0
var n_cultists := 0
var n_kings := 0

# Índices de definição usados no laço (evita comparar strings).
var d_nest := -1
var d_totem := -1
var d_mimic := -1
var d_tower := -1
var d_king := -1
var d_cultist := -1
var d_werewolf := -1
var d_ghost := -1
var d_ogre := -1
var d_goblin := -1
var d_golem := -1

# Grade espacial: janela fixa centrada no herói, reconstruída por contagem.
const GN := 32
const CELL := 2.0
var g_x0 := 0.0
var g_y0 := 0.0
var g_start := PackedInt32Array()
var g_items := PackedInt32Array()
var g_cell := PackedInt32Array()


func setup(s: Sim, capacity: int) -> void:
	sim = s
	cap = capacity
	alive.resize(cap); arch.resize(cap); gen.resize(cap); lvl.resize(cap)
	def.resize(cap); tags.resize(cap); flags.resize(cap); uid.resize(cap); g_cell.resize(cap)
	px.resize(cap); py.resize(cap); ox.resize(cap); oy.resize(cap); ax.resize(cap); ay.resize(cap)
	hp.resize(cap); max_hp.resize(cap); dmg.resize(cap); atk_int.resize(cap); atk_t.resize(cap)
	spd.resize(cap); rng.resize(cap); rad.resize(cap); xp.resize(cap); cost_share.resize(cap)
	timer.resize(cap); timer2.resize(cap); curse_t.resize(cap); buff.resize(cap); fear_t.resize(cap); slot.resize(cap)
	free.resize(cap)
	for i in cap:
		free[i] = cap - 1 - i
	free_n = cap
	g_start.resize(GN * GN + 1)
	g_items.resize(cap)
	var D := sim.data
	dmg_mult = float(D.rules.get("units", {}).get("damage_mult", 1.0))
	proj_mult = float(D.rules.get("units", {}).get("projectile_damage_mult", dmg_mult))
	d_nest = _di(D, "bat_nest"); d_totem = _di(D, "bone_totem"); d_mimic = _di(D, "mimic")
	d_tower = _di(D, "gargoyle_tower"); d_king = _di(D, "rat_king"); d_cultist = _di(D, "cultists")
	d_werewolf = _di(D, "werewolf"); d_ghost = _di(D, "ghost"); d_ogre = _di(D, "ogre")
	d_goblin = _di(D, "goblin_dynamiter"); d_golem = _di(D, "scrap_golem")


func _di(D: GameData, id: String) -> int:
	var c := D.card(id)
	return c.idx if c else -1


func spawn(d: CardDef, x: float, y: float, xp_val: float, share: float, uflags: int, card_uid: int, hp_mult := 1.0) -> int:
	if free_n == 0:
		return -1
	free_n -= 1
	var i := free[free_n]
	alive[i] = 1
	def[i] = d.idx
	arch[i] = d.arch
	gen[i] = 0
	lvl[i] = 1
	px[i] = x; py[i] = y; ox[i] = x; oy[i] = y; ax[i] = x; ay[i] = y
	hp[i] = d.hp * hp_mult
	max_hp[i] = hp[i]
	atk_int[i] = d.attack_interval
	dmg[i] = d.dps * d.attack_interval * (proj_mult if d.projectile else dmg_mult)
	atk_t[i] = d.attack_interval * fmod(i * 0.618034, 1.0)
	spd[i] = d.speed
	rng[i] = d.range
	rad[i] = d.radius
	xp[i] = xp_val
	cost_share[i] = share
	timer[i] = 0.0
	timer2[i] = float(d.fx.get("spawn_interval", 0.0))
	curse_t[i] = 0.0
	buff[i] = 0.0
	fear_t[i] = 0.0
	slot[i] = fmod(i * 2.399963, TAU)
	tags[i] = d.tags
	var f := uflags
	if d.fly:
		f |= K.F_FLY
	if d.projectile:
		f |= K.F_PROJECTILE
	flags[i] = f
	uid[i] = card_uid
	count += 1
	if i >= hi:
		hi = i + 1
	sim.emit(K.Ev.SPAWN, x, y, d.idx, i)
	return i


func release(i: int) -> void:
	alive[i] = 0
	count -= 1
	free[free_n] = i
	free_n += 1
	while hi > 0 and alive[hi - 1] == 0:
		hi -= 1


func update(dt: float) -> void:
	var hero := sim.hero
	var hx := hero.x
	var hy := hero.y
	var hr := hero.radius
	var on_road := sim.phase == K.Phase.ROAD
	var despawn: float = sim.data.rules["sim"]["despawn_distance"]
	var arena := sim.arena
	var hero_far_from_boss := false
	var bx := 0.0
	var by := 0.0
	if not on_road:
		bx = arena.bx
		by = arena.by
		hero_far_from_boss = Vector2(hx - bx, hy - by).length() > 9.0
	var fdx := hero.face_x
	var fdy := hero.face_y
	var hero_frac := hero.hp / hero.max_hp()
	var nose := hero.has("treasure_nose")
	var retreat_mult: float = sim.data.rules["units"]["retreat_speed"]
	n_pack = 0; n_struct = 0; n_cultists = 0; n_kings = 0
	for i in hi:
		if alive[i] == 0:
			continue
		ox[i] = px[i]
		oy[i] = py[i]
		var dx := hx - px[i]
		var dy := hy - py[i]
		var d := sqrt(dx * dx + dy * dy)
		if d < 0.0001:
			d = 0.0001
		var a := arch[i]
		var di := def[i]
		if on_road and d > despawn:
			sim.kill_unit(i, K.Death.EXPIRE)
			continue
		if tags[i] & K.TAG_PACK:
			n_pack += 1
		if di == d_cultist:
			n_cultists += 1
		elif di == d_king:
			n_kings += 1
		timer[i] += dt
		if a == K.Arch.STRUCTURE:
			n_struct += 1
			_structure(i, di, d, dt, nose)
			continue
		var reach := rng[i] + hr + rad[i] * 0.5
		if fear_t[i] > 0.0:
			fear_t[i] -= dt
			_step(i, px[i] - dx / d * 5.0, py[i] - dy / d * 5.0, spd[i], dt)
			continue
		var speed := spd[i]
		var attack := false
		if (flags[i] & K.F_DEFEND) and hero_far_from_boss:
			_step(i, bx + cos(slot[i]) * 3.0, by + sin(slot[i]) * 3.0, speed, dt)
		else:
			match a:
				K.Arch.SWARM:
					var rr := hr + rad[i] + rng[i] * 0.7
					_step(i, hx + cos(slot[i]) * rr, hy + sin(slot[i]) * rr, speed, dt)
					attack = d <= reach + 0.3
				K.Arch.CHASER:
					if di == d_werewolf:
						var th: float = sim.data.cards[di].fx.get("hp_threshold", 0.5)
						var bonus: float = sim.data.cards[di].fx.get("speed_bonus", 1.0)
						speed *= 1.0 + bonus * clampf((th - hero_frac) / th, 0.0, 1.0)
					if d > reach:
						_step(i, hx, hy, speed, dt)
					else:
						attack = true
						if di == d_ghost and timer2[i] <= 0.0:
							sim.hero_fear(px[i], py[i], float(sim.data.cards[di].fx.get("fear", -1.0)))
							timer2[i] = float(sim.data.cards[di].fx.get("fear_cooldown", 6.0))
					if timer2[i] > 0.0:
						timer2[i] -= dt
				K.Arch.SHOOTER:
					var retreat: float = sim.data.cards[di].fx.get("retreat", rng[i] * 0.4)
					if d < retreat:
						_step(i, px[i] - dx / d * 4.0, py[i] - dy / d * 4.0, speed * retreat_mult, dt)
					elif d > rng[i] * 0.85:
						_step(i, hx, hy, speed, dt)
					attack = d <= rng[i] + hr
				K.Arch.KAMIKAZE:
					if d > reach:
						_step(i, hx, hy, speed, dt)
					else:
						sim.kamikaze(i)
						continue
				K.Arch.TANK:
					if d > 4.0:
						_step(i, hx + fdx * 2.2, hy + fdy * 2.2, speed, dt)
					elif d > reach:
						_step(i, hx, hy, speed, dt)
					attack = d <= reach + 0.2
				K.Arch.SUPPORT:
					if (sim.tick + i) % 5 == 0:
						_support_target(i)
					# timer2 = tamanho do bando que ele segue. Sozinho não tem atrás de quem se esconder: vai para cima.
					if timer2[i] <= 0.0:
						if d > reach:
							_step(i, hx, hy, speed, dt)
					elif d < 5.0:
						_step(i, px[i] - dx / d * 4.0, py[i] - dy / d * 4.0, speed * retreat_mult, dt)
					else:
						# Ir ao ponto de apoio afastando-se do herói também é recuar: senão ninguém o alcança.
						var away := (ax[i] - px[i]) * -dx + (ay[i] - py[i]) * -dy > 0.0
						_step(i, ax[i], ay[i], speed * (retreat_mult if away else 1.0), dt)
					attack = d <= reach
		if attack:
			atk_t[i] -= dt
			if atk_t[i] <= 0.0:
				atk_t[i] += atk_int[i]
				sim.unit_hits_hero(i)
				if alive[i] == 0:
					continue
		if curse_t[i] > 0.0:
			curse_t[i] -= dt
		# Ninguém atravessa o herói; tanques e estruturas empurram o herói.
		if not (flags[i] & K.F_FLY):
			dx = hx - px[i]
			dy = hy - py[i]
			d = sqrt(dx * dx + dy * dy)
			var minr := hr + rad[i]
			if d < minr and d > 0.0001:
				var push := (minr - d)
				if a == K.Arch.TANK:
					hero.x += dx / d * push * 0.6
					hero.y += dy / d * push * 0.6
					px[i] -= dx / d * push * 0.4
					py[i] -= dy / d * push * 0.4
				else:
					px[i] -= dx / d * push
					py[i] -= dy / d * push


func _step(i: int, tx: float, ty: float, speed: float, dt: float) -> void:
	var vx := tx - px[i]
	var vy := ty - py[i]
	var l := sqrt(vx * vx + vy * vy)
	if l < 0.05:
		return
	var s := minf(speed * dt, l)
	px[i] += vx / l * s
	py[i] += vy / l * s


func _structure(i: int, di: int, d: float, dt: float, nose: bool) -> void:
	var c: CardDef = sim.data.cards[di]
	var hr := sim.hero.radius
	if di == d_nest:
		var dur := c.fxv("spawn_duration", lvl[i], 15.0)
		if timer[i] >= timer2[i] and timer2[i] <= dur + 0.001:
			timer2[i] += float(c.fx.get("spawn_interval", 3.0))
			var bat: CardDef = sim.data.card(str(c.fx.get("spawn", "bat")))
			var a := slot[i] + timer[i]
			sim.spawn_child(bat, px[i] + cos(a) * 1.2, py[i] + sin(a) * 1.2, i)
	elif di == d_totem:
		if timer[i] > c.fxv("duration", lvl[i], 20.0):
			sim.kill_unit(i, K.Death.EXPIRE)
	elif di == d_mimic:
		if not nose and not (flags[i] & K.F_BITTEN) and timer[i] >= timer2[i] and d <= hr + rad[i] + 0.5:
			flags[i] |= K.F_BITTEN
			sim.mimic_bite(i)
	elif di == d_tower:
		var stone: float = c.fx.get("stone_radius", 3.0)
		if d < stone + hr:
			flags[i] |= K.F_STONE
		else:
			flags[i] &= ~K.F_STONE
			if d <= rng[i] + hr:
				atk_t[i] -= dt
				if atk_t[i] <= 0.0:
					atk_t[i] += atk_int[i]
					sim.unit_hits_hero(i)


func _support_target(i: int) -> void:
	var sx := 0.0
	var sy := 0.0
	var n := 0
	for j in hi:
		if alive[j] == 0 or j == i or not (tags[j] & K.TAG_PACK):
			continue
		var dx := px[j] - px[i]
		var dy := py[j] - py[i]
		if dx * dx + dy * dy < 100.0:
			sx += px[j]
			sy += py[j]
			n += 1
	timer2[i] = n
	if n > 0:
		ax[i] = sx / n
		ay[i] = sy / n
	else:
		ax[i] = sim.hero.x + cos(slot[i]) * 7.0
		ay[i] = sim.hero.y + sin(slot[i]) * 7.0


## Aura do Rei dos Ratos: Bando a até 6 m causa +50%.
func apply_auras() -> void:
	for j in hi:
		buff[j] = 0.0
	if n_kings == 0 or d_king < 0:
		return
	var fx: Dictionary = sim.data.cards[d_king].fx
	var r2: float = pow(float(fx.get("aura_radius", 6.0)), 2)
	var b: float = fx.get("aura_pack_damage", 0.5)
	for i in hi:
		if alive[i] == 0 or def[i] != d_king:
			continue
		for j in hi:
			if alive[j] == 1 and (tags[j] & K.TAG_PACK) and j != i:
				var dx := px[j] - px[i]
				var dy := py[j] - py[i]
				if dx * dx + dy * dy <= r2:
					buff[j] = b


## Reconstrói a grade e separa unidades sobrepostas.
func separate() -> void:
	g_x0 = sim.hero.x - GN * CELL * 0.5
	g_y0 = sim.hero.y - GN * CELL * 0.5
	var nc := GN * GN
	for c in nc + 1:
		g_start[c] = 0
	for i in hi:
		g_cell[i] = -1
		if alive[i] == 0 or (flags[i] & K.F_FLY):
			continue
		var cx := int((px[i] - g_x0) / CELL)
		var cy := int((py[i] - g_y0) / CELL)
		if cx < 0 or cy < 0 or cx >= GN or cy >= GN:
			continue
		var c := cy * GN + cx
		g_cell[i] = c
		g_start[c + 1] += 1
	for c in nc:
		g_start[c + 1] += g_start[c]
	var fill := g_start.duplicate()
	for i in hi:
		var c := g_cell[i]
		if c >= 0:
			g_items[fill[c]] = i
			fill[c] += 1
	for i in hi:
		var c := g_cell[i]
		if c < 0 or arch[i] == K.Arch.STRUCTURE:
			continue
		var cx := c % GN
		var cy := c / GN
		for yy in range(maxi(cy - 1, 0), mini(cy + 2, GN)):
			for xx in range(maxi(cx - 1, 0), mini(cx + 2, GN)):
				var cc := yy * GN + xx
				for k in range(g_start[cc], g_start[cc + 1]):
					var j := g_items[k]
					if j <= i and arch[j] != K.Arch.STRUCTURE:
						continue
					var dx := px[j] - px[i]
					var dy := py[j] - py[i]
					var minr := rad[i] + rad[j]
					var d2 := dx * dx + dy * dy
					if d2 < minr * minr:
						var d := sqrt(d2)
						if d < 0.001:
							dx = cos(slot[i]); dy = sin(slot[i]); d = 1.0
						var push := (minr - d) * 0.5
						px[i] -= dx / d * push
						py[i] -= dy / d * push
						if arch[j] != K.Arch.STRUCTURE:
							px[j] += dx / d * push
							py[j] += dy / d * push
						else:
							px[i] -= dx / d * push
							py[i] -= dy / d * push


## Índices vivos a até r de (x, y). Força bruta: chamado por eventos ou a 5 Hz.
func within(x: float, y: float, r: float, out: PackedInt32Array) -> PackedInt32Array:
	out.clear()
	var r2 := r * r
	for i in hi:
		if alive[i] == 1:
			var dx := px[i] - x
			var dy := py[i] - y
			if dx * dx + dy * dy <= r2:
				out.append(i)
	return out


func any_within(x: float, y: float, r: float) -> bool:
	var r2 := r * r
	for i in hi:
		if alive[i] == 1:
			var dx := px[i] - x
			var dy := py[i] - y
			if dx * dx + dy * dy <= r2:
				return true
	return false
