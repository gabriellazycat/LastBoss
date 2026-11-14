class_name StatusOverlay
extends Control
## Buffs e debuffs à vista (rodada 11/11/2026): ícones com anel de tempo sobre o herói, seta nos monstros que
## recebem aura (Rei Rato), marca da fera que devorou, círculo da aura e, com um feitiço na mão, anel em quem
## ele vai atingir. Só lê a simulação; desenha por cima do mundo e por baixo dos painéis do HUD.

const R := 11.0                       # raio do selo
const C_SLOW := Color(0.45, 0.75, 1.0)
const C_FEAR := Color(0.78, 0.55, 1.0)
const C_ROOT := Color(0.45, 0.85, 0.35)
const C_STONE := Color(0.75, 0.75, 0.8)
const C_SOAK := Color(0.35, 0.9, 1.0)
const C_BURN := Color(1.0, 0.55, 0.2)
const C_SHIELD := Color(1.0, 0.85, 0.35)
const C_WEAK := Color(0.85, 0.4, 1.0)
const C_MARK := Color(0.95, 0.3, 0.55)
const C_BUBO := Color(0.6, 0.85, 0.25)
const C_CURSE := Color(0.85, 0.2, 0.25)
const C_PESTE := Color(0.5, 0.95, 0.5)
const C_BLESS := Color(1.0, 0.95, 0.7)
const C_BUFF := Color(1.0, 0.65, 0.2)
const C_DEVOUR := Color(0.95, 0.25, 0.2)
const C_TARGET := Color(1.0, 0.95, 0.45)

var sim: Sim
var world: WorldView
var cam: Camera3D
var peak := {}                        # maior duração vista por efeito ativo (o anel esvazia a partir dela)
var preview_card: Sim.CardInst = null
var preview_pos := Vector3.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func setup(s: Sim, w: WorldView, c: Camera3D) -> void:
	sim = s
	world = w
	cam = c
	peak.clear()
	preview_card = null


## Carta selecionada e ponto do ponteiro no chão (null = sem prévia).
func set_preview(ci: Sim.CardInst, pos: Vector3) -> void:
	preview_card = ci
	preview_pos = pos


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if sim == null or cam == null or world == null or world.hero_root == null or sim.phase == K.Phase.OVER:
		return
	_draw_auras()
	_draw_preview()
	_draw_unit_marks()
	_draw_hero_badges()


# ---------------------------------------------------------------- herói

## [chave, cor, segundos restantes (<0 = sem tempo), número no selo]
func hero_effects() -> Array:
	var h := sim.hero
	var out: Array = []
	var add := func(k: String, col: Color, left: float, num := -1):
		out.append([k, col, left, num])
	if h.petrify_t > 0.0: add.call("stone", C_STONE, h.petrify_t)
	if h.root_t > 0.0: add.call("root", C_ROOT, h.root_t)
	if h.fear_t > 0.0: add.call("fear", C_FEAR, h.fear_t)
	if h.slow_t > 0.0: add.call("slow", C_SLOW, h.slow_t)
	if h.soaked_t > 0.0: add.call("soak", C_SOAK, h.soaked_t)
	if sim.burn_t > 0.0: add.call("burn", C_BURN, sim.burn_t)
	if h.shield_t > 0.0 and h.shield_hp > 0.0: add.call("shield", C_SHIELD, h.shield_t)
	var cs: Dictionary = sim.cstate
	if cs.has("common") and sim.t < float(cs["common"].get("weak_until", -1.0)):
		add.call("weak", C_WEAK, float(cs["common"]["weak_until"]) - sim.t)
	if sim.t < sim.mark_until: add.call("mark", C_MARK, sim.mark_until - sim.t)
	if cs.has("plague") and sim.t < float(cs["plague"].get("bubo_t", -1.0)):
		add.call("bubo", C_BUBO, float(cs["plague"]["bubo_t"]) - sim.t)
	var pst := CardsPlague.peste_of(sim, h)
	if pst > 0: add.call("peste", C_PESTE, -1.0, pst)
	if sim.has_method("hero_blessed") and sim.call("hero_blessed"): add.call("bless", C_BLESS, -1.0)
	if h.curses > 0: add.call("curse", C_CURSE, -1.0, h.curses)
	return out


func _draw_hero_badges() -> void:
	var top: Vector3 = world.hero_root.global_position + Vector3(0, 3.3, 0)
	if cam.is_position_behind(top):
		return
	var effs := hero_effects()
	var live := {}
	for e in effs:
		live[e[0]] = true
		var left: float = e[2]
		if left >= 0.0 and left > float(peak.get(e[0], 0.0)):
			peak[e[0]] = left
	for k in peak.keys():
		if not live.has(k):
			peak.erase(k)
	if effs.is_empty():
		return
	var c := cam.unproject_position(top)
	var gap := R * 2.0 + 8.0
	var x0 := c.x - gap * (effs.size() - 1) * 0.5
	for i in effs.size():
		var e: Array = effs[i]
		var left: float = e[2]
		var frac := -1.0
		if left >= 0.0:
			frac = clampf(left / maxf(float(peak.get(e[0], left)), 0.01), 0.0, 1.0)
		var p := Vector2(x0 + gap * i, c.y)
		badge(self, p, e[0], e[1], frac, R)
		var font := get_theme_default_font()
		var txt := ""
		if left >= 0.0:
			txt = str(ceili(left))
		elif int(e[3]) > 0:
			txt = "×%d" % int(e[3])
		if txt != "":
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
			draw_string_outline(font, p + Vector2(-w * 0.5, R + 16), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.85))
			draw_string(font, p + Vector2(-w * 0.5, R + 16), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1))


## Selo redondo: fundo escuro, borda e anel de tempo na cor do efeito, desenho no meio. frac < 0 = sem tempo.
static func badge(ci: CanvasItem, p: Vector2, kind: String, col: Color, frac: float, r: float) -> void:
	ci.draw_circle(p, r + 1.5, Color(0, 0, 0, 0.7))
	ci.draw_circle(p, r, col.darkened(0.65))
	if frac >= 0.0:
		ci.draw_arc(p, r + 3.0, 0.0, TAU, 32, Color(0, 0, 0, 0.55), 3.0, true)
		ci.draw_arc(p, r + 3.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 32, col, 3.0, true)
	else:
		ci.draw_arc(p, r + 3.0, 0.0, TAU, 32, col, 2.0, true)
	glyph(ci, p, kind, col, r * 0.62)


static func glyph(ci: CanvasItem, p: Vector2, kind: String, col: Color, s: float) -> void:
	var w := maxf(2.0, s * 0.28)
	match kind:
		"slow":
			for dx in [-0.35, 0.35]:
				ci.draw_polyline([p + Vector2(s * (dx + 0.3), -s * 0.6), p + Vector2(s * (dx - 0.3), 0), p + Vector2(s * (dx + 0.3), s * 0.6)], col, w, true)
		"fear":
			ci.draw_line(p + Vector2(0, -s * 0.85), p + Vector2(0, s * 0.25), col, w * 1.2, true)
			ci.draw_circle(p + Vector2(0, s * 0.7), w * 0.75, col)
		"root":
			for dx in [-0.5, 0.0, 0.5]:
				ci.draw_polyline([p + Vector2(s * dx, -s * 0.8), p + Vector2(s * (dx + 0.18), -s * 0.2), p + Vector2(s * (dx - 0.18), s * 0.3), p + Vector2(s * dx, s * 0.85)], col, w * 0.8, true)
		"stone":
			ci.draw_rect(Rect2(p - Vector2(s, s) * 0.65, Vector2(s, s) * 1.3), col)
		"soak":
			ci.draw_circle(p + Vector2(0, s * 0.25), s * 0.5, col)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 0.9), p + Vector2(s * 0.48, s * 0.1), p + Vector2(-s * 0.48, s * 0.1)]), col)
		"burn":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 0.95), p + Vector2(s * 0.6, s * 0.2), p + Vector2(s * 0.35, s * 0.8), p + Vector2(-s * 0.35, s * 0.8), p + Vector2(-s * 0.6, s * 0.2)]), col)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 0.1), p + Vector2(s * 0.25, s * 0.45), p + Vector2(0, s * 0.75), p + Vector2(-s * 0.25, s * 0.45)]), Color(1, 0.95, 0.6))
		"shield":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.7, -s * 0.7), p + Vector2(s * 0.7, -s * 0.7), p + Vector2(s * 0.6, s * 0.2), p + Vector2(0, s * 0.9), p + Vector2(-s * 0.6, s * 0.2)]), col)
		"weak":
			ci.draw_line(p + Vector2(0, -s * 0.85), p + Vector2(0, s * 0.5), col, w * 1.1, true)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.6, s * 0.2), p + Vector2(s * 0.6, s * 0.2), p + Vector2(0, s * 0.95)]), col)
		"buff":
			ci.draw_line(p + Vector2(0, s * 0.85), p + Vector2(0, -s * 0.5), col, w * 1.1, true)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.6, -s * 0.2), p + Vector2(s * 0.6, -s * 0.2), p + Vector2(0, -s * 0.95)]), col)
		"mark":
			ci.draw_arc(p, s * 0.6, 0.0, TAU, 20, col, w * 0.8, true)
			ci.draw_line(p + Vector2(-s, 0), p + Vector2(s, 0), col, w * 0.7, true)
			ci.draw_line(p + Vector2(0, -s), p + Vector2(0, s), col, w * 0.7, true)
		"bubo":
			for a in 3:
				ci.draw_circle(p + Vector2.from_angle(TAU * a / 3.0 - PI * 0.5) * s * 0.5, s * 0.32, col)
		"peste":
			# Gota de pus com duas manchas: acúmulos de Peste (o número vai embaixo do selo).
			ci.draw_circle(p + Vector2(0, s * 0.25), s * 0.55, col)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 0.95), p + Vector2(s * 0.5, s * 0.05), p + Vector2(-s * 0.5, s * 0.05)]), col)
			ci.draw_circle(p + Vector2(-s * 0.18, s * 0.2), s * 0.14, col.darkened(0.6))
			ci.draw_circle(p + Vector2(s * 0.2, s * 0.45), s * 0.1, col.darkened(0.6))
		"curse":
			ci.draw_line(p + Vector2(-s, -s) * 0.6, p + Vector2(s, s) * 0.6, col.lightened(0.3), w, true)
			ci.draw_line(p + Vector2(s, -s) * 0.6, p + Vector2(-s, s) * 0.6, col.lightened(0.3), w, true)
		"bless":
			var pts := PackedVector2Array()
			for i in 10:
				pts.append(p + Vector2.from_angle(-PI * 0.5 + TAU * i / 10.0) * (s if i % 2 == 0 else s * 0.42))
			ci.draw_colored_polygon(pts, col)
		"devour":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.7, -s * 0.5), p + Vector2(-s * 0.1, -s * 0.5), p + Vector2(-s * 0.4, s * 0.8)]), col.lightened(0.4))
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(s * 0.1, -s * 0.5), p + Vector2(s * 0.7, -s * 0.5), p + Vector2(s * 0.4, s * 0.8)]), col.lightened(0.4))


# ---------------------------------------------------------------- unidades

func _unit_pos(i: int, h := 0.0) -> Vector3:
	var U := sim.units
	return Vector3(U.px[i], world.surface_y(U.px[i], U.py[i]) + h, U.py[i])


## Anel no chão projetado na tela (perspectiva certa); some se cair atrás da câmera.
func ground_ring(c: Vector3, r: float, col: Color, width := 2.0, seg := 36) -> void:
	var pts := PackedVector2Array()
	for k in seg + 1:
		var a := TAU * k / seg
		var q := c + Vector3(cos(a) * r, 0.0, sin(a) * r)
		if cam.is_position_behind(q):
			return
		pts.append(cam.unproject_position(q))
	draw_polyline(pts, col, width, true)


func _draw_auras() -> void:
	var U := sim.units
	for i in U.hi:
		if U.alive[i] == 0:
			continue
		var d: CardDef = sim.data.cards[U.def[i]]
		if d.fx.has("aura_radius"):
			var pulse := 0.25 + 0.1 * sin(sim.t * 3.0)
			ground_ring(_unit_pos(i, 0.06), float(d.fx["aura_radius"]), Color(C_BUFF, pulse), 2.5, 48)


func _draw_unit_marks() -> void:
	var U := sim.units
	var n := 0
	for i in U.hi:
		if U.alive[i] == 0:
			continue
		var buffed := U.buff[i] > 0.0
		var devoured := (U.flags[i] & K.F_DEVOURED) != 0
		if not buffed and not devoured:
			continue
		var d: CardDef = sim.data.cards[U.def[i]]
		var top := _unit_pos(i, 0.9 + d.radius * 1.6)
		if cam.is_position_behind(top):
			continue
		var p := cam.unproject_position(top)
		if devoured:
			badge(self, p + Vector2(0, -8), "devour", C_DEVOUR, -1.0, 9.0)
		elif buffed:
			glyph(self, p, "buff", Color(0, 0, 0, 0.75), 11.0)
			glyph(self, p + Vector2(0, -1), "buff", C_BUFF, 9.5)
		n += 1
		if n > 120:
			return


# ---------------------------------------------------------------- prévia do feitiço

func _draw_preview() -> void:
	if preview_card == null or not preview_card.def.is_spell:
		return
	var tg := spell_targets(sim, preview_card, preview_pos.x, preview_pos.z)
	var pulse := 0.75 + 0.25 * sin(sim.t * 8.0)
	for i in tg["units"]:
		var d: CardDef = sim.data.cards[sim.units.def[i]]
		ground_ring(_unit_pos(i, 0.08), d.radius + 0.35, Color(C_TARGET, pulse), 3.0, 20)
	for hh in tg["heroes"]:
		var hp := Vector3(hh.x, world.surface_y(hh.x, hh.y) + 0.08, hh.y)
		ground_ring(hp, hh.radius + 0.6, Color(1.0, 0.35, 0.3, pulse), 4.0, 32)


## Quem o feitiço vai atingir se for solto em (x, y): {"heroes": [SimHero], "units": [índices]}. Espelha a mira
## de cada carta em sim/cards/*.gd e nas ops (raio em volta do ponto); feitiço sem alvo de área pega o herói.
static func spell_targets(s: Sim, ci: Sim.CardInst, x: float, y: float) -> Dictionary:
	var d := ci.def
	var lv := ci.level
	var U := s.units
	var heroes: Array = []
	var units: Array = []
	var p := Vector2(x, y)
	var in_r := func(r: float) -> void:
		for hh in s.all_heroes():
			if Vector2(hh.x, hh.y).distance_to(p) <= r + hh.radius:
				heroes.append(hh)
	var own := func(j: int) -> bool:
		return U.alive[j] == 1 and U.arch[j] != K.Arch.STRUCTURE
	match d.id:
		"shadow_bolt":
			var dir := Vector2(s.hero.x - x, s.hero.y - y)
			dir = dir.normalized() if dir.length() > 0.1 else Vector2(s.hero.face_x, s.hero.face_y)
			for hh in s.all_heroes():
				var rel := Vector2(hh.x - x, hh.y - y)
				if rel.dot(dir) >= -0.5 and rel.dot(dir) <= float(d.fx["length"]) and absf(rel.dot(Vector2(-dir.y, dir.x))) <= float(d.fx["width"]) * 0.5 + hh.radius:
					heroes.append(hh)
		"devour":
			var beast := -1
			var bd := INF
			for i in U.hi:
				if U.alive[i] == 1 and CardsPlague.is_beast(s.data.cards[U.def[i]]):
					var dd := Vector2(U.px[i] - x, U.py[i] - y).length_squared()
					if dd < bd:
						bd = dd
						beast = i
			if beast >= 0:
				units.append(beast)
				var rats: Array = []
				for i in U.hi:
					if U.alive[i] == 1 and (U.tags[i] & K.TAG_PACK) and U.arch[i] == K.Arch.SWARM and not (U.flags[i] & K.F_FLY):
						rats.append([Vector2(U.px[i] - U.px[beast], U.py[i] - U.py[beast]).length_squared(), i])
				rats.sort()
				for r in mini(maxi(1, int(d.fxv("sacrifice", lv))), rats.size()):
					units.append(int(rats[r][1]))
		"corpse_blast", "profane_ritual":
			var best := -1
			var bd := pow(float(d.fx["pick_radius"]), 2)
			for j in U.hi:
				if own.call(j):
					var dd := Vector2(U.px[j] - x, U.py[j] - y).length_squared()
					if dd <= bd:
						bd = dd
						best = j
			if best >= 0:
				units.append(best)
				if d.id == "corpse_blast":
					var c := Vector2(U.px[best], U.py[best])
					for hh in s.all_heroes():
						if Vector2(hh.x, hh.y).distance_to(c) <= d.fxv("radius", lv) + hh.radius:
							heroes.append(hh)
		"dark_sacrifice":
			var best := -1
			var bv := -1.0
			var pr2 := pow(float(d.fx["pick_radius"]), 2)
			for j in U.hi:
				if own.call(j) and Vector2(U.px[j] - x, U.py[j] - y).length_squared() <= pr2 and U.cost_share[j] > bv:
					bv = U.cost_share[j]
					best = j
			if best >= 0:
				units.append(best)
		"soul_feast":
			for j in U.hi:
				if own.call(j) and Vector2(U.px[j] - x, U.py[j] - y).length() <= d.fxv("radius", lv):
					units.append(j)
		"life_drain":
			in_r.call(d.fxv("radius", lv))
			for j in U.hi:
				if own.call(j) and (U.tags[j] & K.TAG_UNDEAD) and Vector2(U.px[j] - x, U.py[j] - y).length() <= d.fxv("heal_radius", lv):
					units.append(j)
		"pack_call", "hunt_instinct", "endless_swarm":
			for j in U.hi:
				if own.call(j) and (U.tags[j] & K.TAG_PACK):
					units.append(j)
		"toll", "soul_harvest", "blood_tax", "arcane_apocalypse", "shadow_echo", "open_grave":
			pass
		_:
			if d.fx.has("radius"):
				in_r.call(d.fxv("radius", lv))
			else:
				heroes.append(s.hero)
	return {"heroes": heroes, "units": units}
