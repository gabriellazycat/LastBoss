class_name CardDrop
extends Node3D
## Carta jogada no mundo (26/11/2026): a própria carta sai da mão, gira no ar e cai deitada no feltro, grande
## como um tapete; os monstros saltam de dentro dela e as estruturas crescem dela. Só visual: o sim já criou as
## unidades no `play`, e aqui elas ficam escondidas até a carta pousar. O tempo é o do jogo (`sim.t`), então
## acelera com a velocidade e para na pausa. Feitiço voa mais rápido e o efeito dele sai da carta ao pousar.
## A carta vai inteira (com o texto); ao pousar, a face vira uma imagem fixa, guardada por carta (id, nível,
## modificadores, custo), e a carta fica no chão, com a arte, enquanto vale. Um fade só (26/11/2026): a carta some
## por completo quando morre o último monstro dela (todos com o uid dela: filhos, revividos e crias contam), a
## estrutura quebra e acaba o efeito que dura (carta em vigor em `sim.held`, zonas que ela criou, a "duration"
## declarada nos dados, o herói queimando por ela). Feitiço sem nada que dure some logo depois de pousar.
## Timer (27/11/2026): carta com tempo (em vigor em `sim.held`, "duration" nos dados ou estrutura que some pelo tempo,
## Units.life_s) mostra na carta do mundo um véu branco transparente esvaziando no sentido horário, como o da tela,
## sem o número de segundos.

const FACE_W := 560.0                # face renderizada (UiKit.card: largura × 1,4); grande para o texto ficar nítido
const SIZE := Vector2(4.6, 6.44)     # carta pousada, em metros (tapete: lê-se da câmera alta da estrada)
const LAND := 0.45                   # voo da carta de criatura/estrutura
const LAND_SPELL := 0.22             # voo do feitiço (o dano já saiu no sim)
const JUMP := 0.34                   # cada monstro saltando da carta até o lugar dele
const STAGGER := 0.36                # o enxame inteiro sai dentro deste tempo
## Brilho da carta no mundo: o papel claro passava do limiar do glow (0,75 com exposição 1,12) e ganhava um halo que
## borrava o texto; abaixo dele a carta fica nítida.
const TINT := 0.62
const REST := 0.6                    # depois de os monstros saírem, a carta assenta e vira imagem fixa

static var faces := {}               # chave da carta -> ImageTexture da face
const PUFF := Color(0.95, 0.92, 0.85)   # sopro de papel quando a carta some
const TIMER_SHADER := preload("res://game/art/card_timer.gdshader")
const CHECK := 0.25                  # s de jogo entre as conferências de "algum monstro da carta vivo?"
const FADE := 1.2                    # s de jogo em que a carta some do chão

var wv: WorldView
var drops: Array = []                # {t0, land, start, end, q0, q1, s0, mi, mat, sv, key, spell, landed, held, ats}
var resting := 0                     # cartas já jogadas nesta run (cada nova fica um fio acima)
var alive_cards: Array = []          # cartas no chão com monstro vivo ou efeito durando: {mi, cuid, huid, zones, until, burn, end}
var next_check := 0.0
var fading: Array = []               # cartas sumindo do chão: {mi, mat, t0}
var units := {}                      # índice da unidade -> {at, cx, cz, birth, struct}


func setup(w: WorldView) -> void:
	wv = w


func clear() -> void:
	for c in get_children():
		c.queue_free()
	drops.clear()
	units.clear()
	alive_cards.clear()
	fading.clear()
	resting = 0


## Chave da face: a mesma carta (id, nível, modificadores, custo, idioma) reaproveita a imagem e o material.
static func face_key(ci: Sim.CardInst, cost: int) -> String:
	return "%s/%d/%d/%d/%s" % [ci.def.id, ci.level, ci.mods, cost, TranslationServer.get_locale()]


## `face` é a carta inteira com texto (UiKit.card, largura FACE_W), desenhada na carta 3D; `key` vem de face_key;
## `rect` é onde a carta estava na mão, na tela; `lasting` diz o que a mantém desenhada: {cuid: uid das unidades
## (-1 = nenhuma), huid: uid da carta em vigor (-1 = nenhuma), zones: zonas que ela criou, until: sim.t em que acaba
## a duração declarada nos dados, burn: id da carta, para o herói queimando por ela}.
func launch(face: Control, key: String, rect: Rect2, world: Vector2, new_units: Array, is_spell: bool, structs: Dictionary, lasting := {}) -> void:
	var cam := wv.cam
	if cam == null or face == null:
		if face != null:
			face.free()
		return
	var now := wv.sim.t
	var land := LAND_SPELL if is_spell else LAND
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_fog = true   # a neblina do anoitecer lavava o contraste da carta
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC   # deitada e vista de lado: sem isso o mipmap borra o texto
	var sv: SubViewport = null
	if faces.has(key):
		face.free()
		mat.albedo_texture = faces[key]
	else:
		# Face: a carta inteira desenhada num SubViewport transparente (vira imagem fixa quando a carta assenta).
		sv = SubViewport.new()
		sv.transparent_bg = true
		sv.disable_3d = true
		sv.size = Vector2i(int(FACE_W), int(roundf(FACE_W * 1.4)))
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		face.position = Vector2.ZERO
		face.modulate = Color.WHITE
		sv.add_child(face)
		add_child(sv)
		mat.albedo_texture = sv.get_texture()
	var qm := QuadMesh.new()
	qm.size = SIZE
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	# Começo: no plano da câmera, do tamanho exato da carta na tela, virada para a câmera.
	var vp := get_viewport().get_visible_rect().size
	var depth := 6.0
	var px_h := rect.size.y
	var world_h := depth * 2.0 * tan(deg_to_rad(cam.fov) * 0.5) * px_h / maxf(vp.y, 1.0)
	if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		world_h = cam.size * px_h / maxf(vp.y, 1.0)
	var start := cam.project_position(rect.get_center(), depth)
	var gy := _ground(world.x, world.y)
	var end := Vector3(world.x, gy + 0.07 + 0.004 * float(resting % 120), world.y)
	resting += 1
	var fwd := -cam.global_basis.z
	var yaw := atan2(-fwd.x, -fwd.z)
	var q1 := (Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI * 0.5)).get_rotation_quaternion()
	var d := {"t0": now, "land": land, "start": start, "end": end, "q0": cam.global_basis.get_rotation_quaternion(),
		"q1": q1, "s0": world_h / SIZE.y, "mi": mi, "mat": mat, "sv": sv, "key": key, "lasting": lasting, "spell": is_spell,
		"landed": false, "held": [], "ats": [], "from": wv.sim.t, "structs": []}
	var n := new_units.size()
	var step := minf(0.06, STAGGER / maxf(float(n), 1.0))
	var U := wv.sim.units
	for k in n:
		var i: int = new_units[k]
		var at := now + land + 0.04 + step * k
		d["ats"].append(at)
		units[i] = {"at": at, "cx": world.x, "cz": world.y, "birth": wv.sim.t - U.timer[i], "struct": structs.has(i)}
		if structs.has(i):
			d["structs"].append([i, wv.sim.t - U.timer[i]])
	drops.append(d)
	_pose(d, now)


## Feitiço: o efeito (evento SPELL) que saiu no `play` espera a carta pousar. Devolve true se guardou.
func hold_spell(ev: Array) -> bool:
	for d in drops:
		if d["spell"] and not d["landed"] and absf(wv.sim.t - float(d["t0"])) < 0.5:
			var e: Vector3 = d["end"]
			if Vector2(float(ev[1]) - e.x, float(ev[2]) - e.z).length() < 0.6:
				d["held"].append(ev)
				if not d.has("tele"):
					d["tele"] = wv.spell_telegraph(ev, float(d["t0"]) + float(d["land"]) - wv.sim.t)
				return true
	return false


func tick(now: float) -> void:
	for c in alive_cards:
		if c["veil"] != null:
			_update_timer(c)
	if not alive_cards.is_empty() and wv.sim.t >= next_check:
		next_check = wv.sim.t + CHECK
		_check_alive()
	var fi := 0
	while fi < fading.size():
		var fd: Dictionary = fading[fi]
		var a := 1.0 - clampf((wv.sim.t - float(fd["t0"])) / FADE, 0.0, 1.0)
		if not is_instance_valid(fd["mi"]) or a <= 0.0:
			if is_instance_valid(fd["mi"]):
				(fd["mi"] as Node).queue_free()
			fading.remove_at(fi)
			continue
		(fd["mat"] as StandardMaterial3D).albedo_color.a = a * a * (3.0 - 2.0 * a)
		fi += 1
	var i := 0
	while i < drops.size():
		var d: Dictionary = drops[i]
		if _pose(d, now):
			_settle(d)
			drops.remove_at(i)
		else:
			i += 1


## Pose da unidade i (ainda presa na carta ou saltando dela): [x, z, y extra, escala]; vazio = desenho normal.
func unit_pose(i: int, x: float, z: float, now: float) -> Array:
	var e: Dictionary = units[i]
	var U := wv.sim.units
	if U.alive[i] == 0 or absf(wv.sim.t - U.timer[i] - float(e["birth"])) > 0.1:
		units.erase(i)
		return []
	var u := now - float(e["at"])
	if u >= JUMP:
		units.erase(i)
		return []
	if u < 0.0:
		return [float(e["cx"]), float(e["cz"]), -0.5, 0.0001]
	var k := u / JUMP
	var bo := k - 1.0
	var s := maxf(0.02, 1.0 + 2.70158 * bo * bo * bo + 1.70158 * bo * bo)   # passa do tamanho e volta
	if e["struct"]:
		return [x, z, 0.0, s]
	var m := k * k * (3.0 - 2.0 * k)
	return [lerpf(float(e["cx"]), x, m), lerpf(float(e["cz"]), z, m), 4.0 * 1.4 * k * (1.0 - k), s]


# ---------------------------------------------------------------- interno

## Posiciona a carta no instante `now`; devolve true quando ela já assentou de vez.
func _pose(d: Dictionary, now: float) -> bool:
	var mi: MeshInstance3D = d["mi"]
	var mat: StandardMaterial3D = d["mat"]
	var land: float = d["land"]
	var u := now - float(d["t0"])
	var end: Vector3 = d["end"]
	if u < land:
		var k := clampf(u / land, 0.0, 1.0)
		var kp := k * k                                  # cai acelerando
		var ko := 1.0 - pow(1.0 - k, 3.0)                # gira e assenta cedo
		var a: Vector3 = d["start"]
		var mid := a.lerp(end, 0.5) + Vector3(0, 2.5 if d["spell"] else 4.0, 0)
		var p := a.lerp(mid, kp).lerp(mid.lerp(end, kp), kp)
		var q: Quaternion = (d["q0"] as Quaternion).slerp(d["q1"], ko)
		var spin := Basis(Vector3.UP, TAU * ko)
		var s := lerpf(float(d["s0"]), 1.0, ko)
		mi.transform = Transform3D(spin * Basis(q).scaled(Vector3(s, s, s)), p)
		mat.albedo_color = Color(TINT, TINT, TINT)
		return false
	if not d["landed"]:
		d["landed"] = true
		_on_land(d)
	var v := u - land
	# Pousou: um tranco (passa um pouco do tamanho) e brilha enquanto os monstros saem; depois fica no chão.
	var bump := 1.0 + 0.1 * exp(-v * 14.0) * cos(v * 30.0)
	var hold := _out_end(d) - float(d["t0"]) - land
	var f := clampf((v - hold) / REST, 0.0, 1.0)
	mi.transform = Transform3D(Basis(d["q1"]).scaled(Vector3(bump, bump, bump)), end)
	var glow := (0.35 * exp(-v * 6.0) + 0.12 * maxf(0.0, sin(v * 9.0))) * (1.0 - f)
	mat.albedo_color = Color(TINT * (1.0 + glow), TINT * (1.0 + glow * 0.9), TINT * (1.0 + glow * 0.6))
	return f >= 1.0


## Quando o último monstro termina de sair da carta (no feitiço, logo depois de pousar).
func _out_end(d: Dictionary) -> float:
	var ats: Array = d["ats"]
	if ats.is_empty():
		return float(d["t0"]) + float(d["land"]) + 0.1
	return float(ats.back()) + JUMP


func _on_land(d: Dictionary) -> void:
	var e: Vector3 = d["end"]
	wv.add_trauma(0.12 if d["spell"] else 0.18)
	if wv.fx2 != null:
		wv.fx2.telegraph_end(int(d.get("tele", -1)))
		wv.emit_fx("passo", e, 2.2)
		if not d["spell"]:   # feitiço: o impacto da família (fx2.impact) já sai daqui, com a onda no raio certo
			wv.emit_fx("death", e + Vector3(0, 0.2, 0), 0.9, Color(1.0, 0.93, 0.8))
	else:
		wv.emit_fx("smoke", e, 0.8)
	if not d["spell"] or wv.fx2 == null:
		wv.ring_burst(e, 3.6, Color(1.0, 0.86, 0.55))
	# A face vira imagem fixa (uma por chave), sem sombra.
	var key: String = d["key"]
	var sv: SubViewport = d["sv"]
	if not faces.has(key) and sv != null:
		var img := sv.get_texture().get_image()
		if img != null and not img.is_empty():
			img.generate_mipmaps()
			faces[key] = ImageTexture.create_from_image(img)
	if faces.has(key):
		(d["mat"] as StandardMaterial3D).albedo_texture = faces[key]
		if sv != null:
			sv.queue_free()
			d["sv"] = null
	(d["mi"] as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var held: Array = d["held"]
	d["held"] = []
	if not held.is_empty():
		wv.handle_events(held, true)


## Os monstros já saíram: a carta fica no chão enquanto vale (ou some logo, se nada dura).
func _settle(d: Dictionary) -> void:
	var sv: SubViewport = d["sv"]
	if sv != null:
		sv.queue_free()
	var mi: MeshInstance3D = d["mi"]
	mi.transform = Transform3D(Basis(d["q1"]), d["end"])
	var ls: Dictionary = d["lasting"]
	var c := {"mi": mi, "cuid": int(ls.get("cuid", -1)), "huid": int(ls.get("huid", -1)), "zones": ls.get("zones", []),
		"until": float(ls.get("until", 0.0)), "burn": str(ls.get("burn", "")), "end": d["end"],
		"from": float(d["from"]), "structs": d["structs"], "veil": null}
	if _still_on(c, _live_uids()):
		alive_cards.append(c)
		_add_timer(c, d["mat"])
	else:
		_vanish(mi, d["end"], false)


## Timer da carta: [falta, total] em s de jogo, ou [] se ela não tem tempo agora. Ordem: a carta em vigor
## (sim.held), a estrutura que some pelo tempo e a "duration" declarada nos dados.
func _time_left(c: Dictionary) -> Array:
	var sim := wv.sim
	var huid := int(c["huid"])
	if huid >= 0:
		for e in sim.held:
			if int(e["uid"]) == huid:
				return [float(e["until"]) - sim.t, float(e["until"]) - float(e["from"])]
	var U := sim.units
	for st in c["structs"]:
		var i: int = st[0]
		if _struct_alive(st) and U.life_s(i) > 0.0:
			var life := U.life_s(i)
			return [life - U.timer[i], life]
	if float(c["until"]) > sim.t:
		return [float(c["until"]) - sim.t, float(c["until"]) - float(c["from"])]
	return []


## Véu por cima da carta (filhos dela: acompanham e somem com ela), só se a carta tem tempo.
func _add_timer(c: Dictionary, mat: StandardMaterial3D) -> void:
	if _time_left(c).is_empty() or mat.albedo_texture == null:
		return
	var mi: MeshInstance3D = c["mi"]
	var veil := MeshInstance3D.new()
	veil.mesh = mi.mesh
	var sm := ShaderMaterial.new()
	sm.shader = TIMER_SHADER
	sm.set_shader_parameter("mask", mat.albedo_texture)
	sm.render_priority = 1   # véu, depois o contorno e o número por cima (senão o véu lavava o contorno)
	veil.material_override = sm
	veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	veil.position = Vector3(0, 0, 0.006)
	mi.add_child(veil)
	c["veil"] = veil
	_update_timer(c)


func _update_timer(c: Dictionary) -> void:
	var veil: MeshInstance3D = c["veil"]
	if not is_instance_valid(veil):
		c["veil"] = null
		return
	var tl := _time_left(c)
	if tl.is_empty() or float(tl[0]) <= 0.0:
		veil.visible = false
		return
	var frac := clampf(float(tl[0]) / maxf(float(tl[1]), 0.01), 0.0, 1.0)
	(veil.material_override as ShaderMaterial).set_shader_parameter("frac", frac)


## Cartas sem monstro vivo nem efeito durando somem do chão.
func _check_alive() -> void:
	var live := _live_uids()
	var i := 0
	while i < alive_cards.size():
		var c: Dictionary = alive_cards[i]
		if _still_on(c, live):
			i += 1
			continue
		_vanish(c["mi"], c["end"], true)
		if c["veil"] != null and is_instance_valid(c["veil"]):
			(c["veil"] as Node).queue_free()
		alive_cards.remove_at(i)


func _live_uids() -> Dictionary:
	var U := wv.sim.units
	var live := {}
	for j in U.hi:
		if U.alive[j] == 1:
			live[U.uid[j]] = true
	return live


## A carta ainda vale: tem monstro vivo, está em vigor (sim.held) ou alguma zona dela continua no chão.
func _still_on(c: Dictionary, live: Dictionary) -> bool:
	var structs: Array = c["structs"]
	if not structs.is_empty():
		# Carta de estrutura (27/11/2026): vale enquanto a própria estrutura está de pé. As crias dela (morcegos,
		# ratos) herdam o uid e a "duration" dos dados não conta a relíquia nem a quebra: nenhuma das duas segura a carta.
		for st in structs:
			if _struct_alive(st):
				return true
		return false
	if wv.sim.t < float(c["until"]):
		return true
	if wv.sim.burn_t > 0.0 and wv.sim.burn_src == str(c["burn"]):
		return true
	if int(c["cuid"]) >= 0 and live.has(int(c["cuid"])):
		return true
	var huid := int(c["huid"])
	if huid >= 0:
		for e in wv.sim.held:
			if int(e["uid"]) == huid:
				return true
	for z in c["zones"]:
		for z2 in wv.sim.zones:
			if is_same(z, z2):
				return true
	return false


## A estrutura [índice, nascimento] ainda é a mesma e está viva (o índice pode ter sido reusado por outra unidade).
func _struct_alive(st: Array) -> bool:
	var U := wv.sim.units
	var i: int = st[0]
	return U.alive[i] == 1 and absf(wv.sim.t - U.timer[i] - float(st[1])) < 0.1


## A carta some do chão num fade de FADE s (com um sopro de papel quando o último monstro dela cai).
func _vanish(mi: MeshInstance3D, at: Vector3, puff: bool) -> void:
	if not is_instance_valid(mi):
		return
	var fm := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.albedo_color = Color(TINT, TINT, TINT)
	mi.material_override = fm
	fading.append({"mi": mi, "mat": fm, "t0": wv.sim.t})
	if puff:
		wv.emit_fx("death", at + Vector3(0, 0.2, 0), 1.1, PUFF)


func _ground(x: float, z: float) -> float:
	return wv.surface_y(x, z) if not wv.surf_fields.is_empty() else 0.0
