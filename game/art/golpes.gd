class_name Golpes
extends Node3D
## Golpes dos monstros com mais peso (rodada visual 20/11/2026, docs/rodada_visual/golpes). Só com --golpes=1;
## --golpes=0 (padrão) = o jogo de hoje: o world_view nem cria este nó.
##
## O que muda (tudo no desenho, nada na simulação):
##  - o ataque do VAT toca para a frente e no tempo certo: preparo devagar, golpe rápido (ease-in forte) que chega
##    ao quadro de impacto no tick em que a sim aplica o dano, segura ~2 quadros e volta suave. Antes o ataque
##    tocava de trás para a frente depois do dano. Monstros que batem 4x por segundo dão um golpe visual a cada N
##    acertos (o tempo de um golpe inteiro não cabe em 0,25 s);
##  - o corpo recua um pouco no preparo e avança para o alvo no golpe (lunge), com agacha-e-estica (squash/stretch);
##  - arco de corte (golpe_slash.gdshader) na direção do golpe para quem bate corpo a corpo; pesados batem de cima,
##    o lobisomem risca em X;
##  - pesados levantam poeira no impacto e ao pisar (camada "gdust" do fx2) e tremem a câmera de leve;
##  - o herói é empurrado para trás pelo golpe; hit-stop curto proporcional ao dano (com recarga);
##  - quem leva golpe do herói amassa e volta (mola).
## Relógio: o tempo da sim (sim.t + alpha), então pausa, velocidade e o próprio hit-stop congelam as poses.
## A detecção do golpe é pelo salto de atk_t (o evento DAMAGE_HERO não diz quem bateu). Variações por hash do
## índice da unidade: nada de randf().

static var VAR := 1   # padrão aprovado em 21/11/2026 (0 = como era antes; --golpes=0)


static func _static_init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--golpes="):
			VAR = clampi(int(a.substr(9)), 0, 1)


const IMPACT := 0.62      # t do quadro de impacto nas curvas de ataque (smash 0,4–0,65; bote 0,35–0,55)
const WIND_END := 0.40    # t do fim do preparo (braço no alto / corpo agachado)
const MIN_PERIOD := 0.7   # um golpe visual inteiro dura pelo menos isto (s)
const SLASH_T := 0.3      # vida do arco (s de sim)
const SLASH_N := 14
const SHAPE_DIAG := 0
const SHAPE_SMASH := 1
const SHAPE_X := 2

const SH_SLASH := preload("res://game/art/golpe_slash.gdshader")

var wv: Node3D            # o WorldView (sem tipo: evita dependência circular)
var now := 0.0
var dnow := 0.0
var _last := -1.0
var _clock := 0.0         # tempo de quadro (delta), que anda mesmo no hit-stop (a sim fica parada nele)
var _stop_at := -9.0      # _clock do último hit-stop (recarga)
var _pend_f := 0.0        # maior fração de vida tirada do herói no último tick com dano
var _pend_t := -9.0

# Por unidade (índice da sim).
var prev_atk := PackedFloat32Array()
var last_chg := PackedFloat32Array()
var strike_t := PackedFloat32Array()
var hurt_t := PackedFloat32Array()
var age_prev := PackedFloat32Array()
var step_ph := PackedFloat32Array()
var cnt := PackedInt32Array()

# Saída de unit() (sem alocar por unidade).
var ox := 0.0
var oz := 0.0
var sy := 1.0
var sxz := 1.0

var hero_off := Vector3.ZERO
var _kick := Vector3.ZERO

var slashes: Array = []   # {"n": MeshInstance3D, "m": ShaderMaterial, "t": float}
var slash_i := 0
var _bud_slash := 0
var _bud_dust := 0
var _bud_shake := 0
var _shape := {}          # def -> forma do arco (-1 = sem arco)


func setup(world: Node3D) -> void:
	wv = world
	var mesh := _arc_mesh()
	for k in SLASH_N:
		var n := MeshInstance3D.new()
		n.mesh = mesh
		var m := ShaderMaterial.new()
		m.shader = SH_SLASH
		n.material_override = m
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.extra_cull_margin = 4.0
		n.visible = false
		add_child(n)
		slashes.append({"n": n, "m": m, "t": 9.0})


## Faixa em arco no plano XZ local, frente = -Z, raio 1: de -80° a +80° (UV.x), de dentro (0,45) para fora (UV.y).
func _arc_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 18
	var a0 := deg_to_rad(-80.0)
	var a1 := deg_to_rad(80.0)
	for k in seg:
		var u0 := float(k) / seg
		var u1 := float(k + 1) / seg
		var t0 := lerpf(a0, a1, u0)
		var t1 := lerpf(a0, a1, u1)
		var i0 := Vector3(sin(t0), 0, -cos(t0)) * 0.45
		var o0 := Vector3(sin(t0), 0, -cos(t0))
		var i1 := Vector3(sin(t1), 0, -cos(t1)) * 0.45
		var o1 := Vector3(sin(t1), 0, -cos(t1))
		for p in [[i0, Vector2(u0, 0)], [o0, Vector2(u0, 1)], [o1, Vector2(u1, 1)], [i0, Vector2(u0, 0)], [o1, Vector2(u1, 1)], [i1, Vector2(u1, 0)]]:
			st.set_uv(p[1])
			st.add_vertex(p[0])
	return st.commit()


func _ensure(cap: int) -> void:
	if prev_atk.size() >= cap:
		return
	prev_atk.resize(cap)
	last_chg.resize(cap)
	strike_t.resize(cap)
	hurt_t.resize(cap)
	age_prev.resize(cap)
	step_ph.resize(cap)
	cnt.resize(cap)
	last_chg.fill(-99.0)
	strike_t.fill(-99.0)
	hurt_t.fill(-99.0)
	age_prev.fill(1e9)
	prev_atk.fill(0.0)
	step_ph.fill(0.0)
	cnt.fill(0)


## Começo do quadro: relógio da sim e orçamentos.
func begin(sim_t: float, alpha: float, sim_dt: float, cap: int, delta: float) -> void:
	_ensure(cap)
	_clock += delta
	now = sim_t + alpha * sim_dt
	dnow = clampf(now - _last, 0.0, 0.1) if _last >= 0.0 else 0.0
	_last = now
	_bud_slash = 4
	_bud_dust = 3
	_bud_shake = 1
	for e in slashes:
		var n: MeshInstance3D = e["n"]
		if n.visible:
			e["t"] = float(e["t"]) + dnow
			var k := float(e["t"]) / SLASH_T
			(e["m"] as ShaderMaterial).set_shader_parameter("age", k)
			if k >= 1.0:
				n.visible = false
	_kick *= exp(-dnow * 9.0)
	hero_off = _kick


func _shape_of(U, i: int) -> int:
	var d: int = U.def[i]
	if _shape.has(d):
		return _shape[d]
	var sh := -1
	var c: CardDef = wv.sim.data.cards[d]
	if c.arch in [K.Arch.SWARM, K.Arch.TANK, K.Arch.CHASER, K.Arch.SUPPORT]:
		sh = SHAPE_DIAG
		if c.arch == K.Arch.TANK:
			sh = SHAPE_SMASH
		if c.id in ["werewolf", "alpha_beast", "dire_wolf"]:
			sh = SHAPE_X
	_shape[d] = sh
	return sh


## Pose de ataque da unidade i neste quadro. Devolve o "lunge" do shader (t do ataque 0..1; 0 = sem ataque) e deixa
## em ox/oz o deslocamento no chão e em sy/sxz a escala vertical/horizontal relativa.
## (dx, dz) = do monstro para o herói; rad = raio visual; moving = 0..1.
func unit(U, i: int, x: float, z: float, dx: float, dz: float, gy: float, rad: float, moving: float, acc: Color) -> float:
	ox = 0.0
	oz = 0.0
	sy = 1.0
	sxz = 1.0
	var age: float = U.timer[i]
	if age < age_prev[i] - 0.001:
		# Vaga reaproveitada (unidade nova): zera o estado.
		prev_atk[i] = U.atk_t[i]
		last_chg[i] = -99.0
		strike_t[i] = -99.0
		hurt_t[i] = -99.0
		cnt[i] = 0
	age_prev[i] = age
	var ai: float = maxf(U.atk_int[i], 0.05)
	var at: float = U.atk_t[i]
	var arch: int = U.arch[i]
	var dl := sqrt(dx * dx + dz * dz)
	var fx := dx / dl if dl > 0.001 else 0.0
	var fz := dz / dl if dl > 0.001 else 0.0
	var fear: bool = U.fear_t[i] > 0.0
	var shooter: bool = arch == K.Arch.SHOOTER or (U.flags[i] & K.F_PROJECTILE) != 0
	var m := maxi(1, ceili(MIN_PERIOD / ai - 0.001))
	var stru := arch == K.Arch.STRUCTURE
	var big := not stru and (arch == K.Arch.TANK or rad >= 1.6)
	if at != prev_atk[i]:
		# atk_t só sobe quando o golpe sai (+= atk_int): qualquer subida é um acerto, mesmo com vários ticks por quadro.
		if at > prev_atk[i] + 0.0001:
			cnt[i] += 1
			if cnt[i] >= m:
				cnt[i] = 0
				strike_t[i] = wv.sim.t
				if not fear and arch != K.Arch.KAMIKAZE:
					_on_strike(U, i, x, z, fx, fz, gy, rad, big, shooter, acc)
		last_chg[i] = now
		prev_atk[i] = at
	var lunge := 0.0
	if arch == K.Arch.KAMIKAZE:
		return 0.0
	var P := m * ai
	var W := minf(0.42, P * 0.6)
	var R := minf(0.38, P * 0.42)
	var L := 0.0 if stru else clampf(rad * 0.3, 0.12, 0.6) * (-0.5 if shooter else 1.0)
	var since := now - strike_t[i]
	var attacking := now - last_chg[i] < 0.16 and not fear
	if since >= 0.0 and since < R:
		# Impacto: segura ~2 quadros no quadro do golpe e volta suave.
		var H := minf(0.07, R * 0.25)
		var k := 0.0 if since < H else (since - H) / (R - H)
		var e := k * k * (3.0 - 2.0 * k)
		lunge = IMPACT + (0.97 - IMPACT) * e
		var off := L * (1.0 - e)
		ox = fx * off
		oz = fz * off
		var d := exp(-since * 11.0) * cos(since * 26.0)
		sy = 1.0 - 0.16 * d
		sxz = 1.0 + 0.1 * d
	elif attacking:
		var atr := maxf(at - (now - wv.sim.t), 0.0)
		var tts := atr + float(m - 1 - cnt[i]) * ai
		if tts < W:
			var u := 1.0 - tts / W
			if u < 0.72:
				# Preparo: ergue/agacha devagar e recua um pouco (antecipação).
				var a := u / 0.72
				a = a * a * (3.0 - 2.0 * a)
				lunge = WIND_END * a
				var off := -0.3 * L * a
				ox = fx * off
				oz = fz * off
				sy = 1.0 - 0.08 * a
				sxz = 1.0 + 0.05 * a
			else:
				# Golpe: ease-in forte até o impacto, esticando para a frente.
				var k := (u - 0.72) / 0.28
				var e := k * k * k
				lunge = lerpf(WIND_END, IMPACT, e)
				var off := lerpf(-0.3 * L, L, e)
				ox = fx * off
				oz = fz * off
				sy = lerpf(0.92, 1.1, e)
				sxz = lerpf(1.05, 0.94, e)
	# Levou golpe do herói: amassa e volta.
	var sh := now - hurt_t[i]
	if sh >= 0.0 and sh < 0.35:
		var d := exp(-sh * 12.0) * cos(sh * 30.0)
		sy *= 1.0 - 0.17 * d
		sxz *= 1.0 + 0.1 * d
	# Pisada pesada: poeira a cada passo dos grandes andando.
	if big and moving > 0.5 and not (U.flags[i] & K.F_FLY):
		step_ph[i] += dnow * 2.2 * moving
		if step_ph[i] >= 1.0:
			step_ph[i] -= 1.0
			if _bud_dust > 0:
				_bud_dust -= 1
				_dust(Vector3(x, gy + 0.05, z), clampf(rad * 0.35, 0.35, 0.8))
	return lunge


func hurt(i: int) -> void:
	if i >= 0 and i < hurt_t.size():
		hurt_t[i] = now


## Dano no herói (DAMAGE_HERO): guarda a maior fração da vida tirada neste tick. O hit-stop só sai quando um golpe de
## monstro é visto no mesmo tick (_on_strike): feitiço do jogador, zona de fogo ou óleo não pausam o jogo.
func note_damage(v: float, max_hp: float) -> void:
	var f := v / maxf(max_hp, 1.0)
	if wv.sim.t - _pend_t > 0.001:
		_pend_f = 0.0
	_pend_t = wv.sim.t
	_pend_f = maxf(_pend_f, f)


## Hit-stop proporcional à fração da vida tirada, com recarga (rato batendo 4x/s não trava).
func _try_stop() -> void:
	if wv.sim.t - _pend_t > 0.16 or _pend_f < 0.025:
		return
	if _clock - _stop_at < 0.6:
		return
	_stop_at = _clock
	var gs := clampf(0.03 + _pend_f * 0.5, 0.03, 0.09)
	_pend_f = 0.0
	wv._stop(gs)
	wv.add_trauma(clampf(gs * 2.0, 0.06, 0.2))


func _dust(p: Vector3, s: float) -> void:
	var fx2 = wv.fx2
	if fx2 != null:
		fx2.emit("passo", p, s)


func _on_strike(U, i: int, x: float, z: float, fx: float, fz: float, gy: float, rad: float, big: bool, shooter: bool, acc: Color) -> void:
	_try_stop()
	# Herói empurrado para trás pelo golpe.
	var push := (0.1 + minf(rad, 2.5) * 0.09) * (0.4 if shooter else 1.0)
	if _kick.length() < 0.5:
		_kick += Vector3(fx, 0, fz) * push
	if shooter:
		return
	var sh := _shape_of(U, i)
	if sh < 0:
		return
	var hp := Vector3(x + fx * rad * 0.9, gy, z + fz * rad * 0.9)
	if big:
		if _bud_dust > 0:
			_bud_dust -= 1
			_dust(hp, clampf(rad * 0.5, 0.6, 1.4))
		if _bud_shake > 0:
			_bud_shake -= 1
			wv.add_trauma(0.12)
			wv.ring_burst(hp, clampf(rad * 0.9, 1.2, 2.4), Color(0.85, 0.75, 0.6))
	# Os grandes têm prioridade no orçamento de arcos (o enxame só pega o que sobra).
	if _bud_slash <= 0 or (not big and _bud_slash <= 1):
		return
	_bud_slash -= 1
	var h := gy + clampf(rad * 0.75, 0.45, 1.8)
	var c := Vector3(x + fx * rad * 0.25, h, z + fz * rad * 0.25)
	var r := clampf(rad * 1.15 + 0.35, 0.8, 3.4)
	var tint := Color(1.0, 0.5, 0.22).lerp(Color(acc.r, acc.g, acc.b), 0.25)
	var flip := (i * 7 + cnt[i] + int(strike_t[i] * 10.0)) % 2 == 0
	match sh:
		SHAPE_SMASH:
			_slash(c, fx, fz, -1.15, r, tint, 1.4)
		SHAPE_X:
			_slash(c, fx, fz, -0.65, r, tint, 1.0)
			_slash(c, fx, fz, -(PI - 0.65), r, tint, 1.0)
		_:
			_slash(c, fx, fz, -0.55 if flip else -(PI - 0.55), r, tint, 1.0 if rad > 0.9 else 0.8)


func _slash(c: Vector3, fx: float, fz: float, roll: float, r: float, tint: Color, fat: float) -> void:
	var e: Dictionary = slashes[slash_i]
	slash_i = (slash_i + 1) % slashes.size()
	var n: MeshInstance3D = e["n"]
	var f := Vector3(fx, 0, fz)
	if f.length() < 0.01:
		f = Vector3(0, 0, -1)
	var b := Basis.looking_at(f, Vector3.UP) * Basis(Vector3(0, 0, 1), roll)
	n.transform = Transform3D(b.scaled(Vector3.ONE * r), c)
	var m: ShaderMaterial = e["m"]
	m.set_shader_parameter("age", 0.0)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("fat", fat)
	e["t"] = 0.0
	n.visible = true
