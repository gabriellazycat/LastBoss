extends "res://tests/tests.gd"
## Roda só as funções t_* pedidas: godot --headless res://tests/dbg.tscn -- t_contests,t_helper
func _ready() -> void:
	data = GameData.load_dir()
	for n in OS.get_cmdline_user_args()[0].split(","):
		call(n)
	print("falhas: ", fails)
	get_tree().quit(fails)


func dbg_loc() -> void:
	for sd in range(1, 9):
		var s := _at_location("ritual", sd)
		print("seed ", sd, " contest=", s.contest.get("type", "-"), " hold=", s.hero.hold, " marks=", s.contest.get("marks", []).size(), " rivers=", s.road.has_method("river_count"))


func dbg_c() -> void:
	var s := _at_location("ritual")
	print("goal=", s.contest.get("goal"), " rm=", data.rules["locations"]["ritual"]["marks"], " type=", s.contest["type"], " hold=", s.hero.hold, " marks=", s.contest["marks"])


func dbg_lib() -> void:
	var s := _sim()
	var lib := Sim.CardInst.new()
	lib.def = data.card("forbidden_library")
	for k in 6:
		s._apply(lib, s.hero.x, s.hero.y)
	print("t0=", s.t, " hs=", s.hand_size, " phase=", s.phase)
	for k in int(45.0 / s.dt):
		s.step()
	print("t=", s.t, " hs=", s.hand_size, " phase=", s.phase, " contest=", s.contest.get("type", "-"), " hold=", s.hero.hold, " offers=", s.offers.size())
	var s2 := _sim(5, "dragon")
	var g0 := s2.gold
	for k in int(31.0 / s2.dt):
		s2.step()
	print("t2=", s2.t, " gold=", s2.gold - g0, " phase=", s2.phase, " contest=", s2.contest.get("type", "-"), " offers=", s2.offers.size())


func dbg_h() -> void:
	var t2 := _at_location("helper", 5)
	t2.contest["cls"] = "arqueira"
	t2.helper.base_hp = 1.0e7
	t2.helper.hp = 1.0e7
	_steps_free(t2, float(t2.contest["window"]) + 1.0)
	print("helper=", t2.helper, " contest=", t2.contest, " offers=", t2.offers.size(), " bonus=", t2.hero.bonus_dmg, " ward=", t2.hero.ward, " cls=", t2.hero.cls(), " party=", t2.party, " fol=", t2.followers.size(), " Hward=", t2.hero.H.has("ward_cast"), " pidx=", t2.hero.pidx, " pc=", t2.party_class(t2.hero.pidx))


func dbg_cross() -> void:
	var ground: CardDef = null
	for c in data.cards:
		if c.category == "field" and not c.is_spell and not c.fly and c.arch == K.Arch.CHASER:
			ground = c
			break
	for sd in range(1, 13):
		var s := _sim(sd)
		var T := s.terra()
		if not T.ok or T.bridges.is_empty():
			print("seed ", sd, " sem ponte")
			continue
		var res: Array = []
		for bi in T.bridges.size():
			var b: Dictionary = T.bridges[bi]
			var c: Vector2 = b["c"]
			var ea: Vector2 = b["a"]
			var eb: Vector2 = b["b"]
			var s2 := _sim(sd)
			var T2 := s2.terra()
			s2.offers.clear()
			s2.hero.base_hp = 1.0e6
			s2.hero.hp = 1.0e6
			var hp_ := ea + (ea - c).normalized() * 3.0
			s2.hero.x = hp_.x
			s2.hero.y = hp_.y
			s2.hero.hold = true
			s2.hero.hold_x = hp_.x
			s2.hero.hold_y = hp_.y
			var up := eb + (eb - c).normalized() * 3.0 + (eb - c).normalized().orthogonal() * 6.0
			if T2.is_water(up.x, up.y):
				up = T2.nearest_dry(up.x, up.y)
			var k := s2.units.spawn(ground, up.x, up.y, 0.0, 0.0, K.F_NO_XP, 0)
			var crossed := false
			for st in int(25.0 / s2.dt):
				s2.hero.x = hp_.x
				s2.hero.y = hp_.y
				if s2.offers.size() > 0:
					s2.choose(Sim.SKIP)
				s2.step()
				if s2.units.alive[k] == 0:
					break
				if T2.same_side(s2.units.px[k], s2.units.py[k], hp_.x, hp_.y) and T2.region_at(s2.units.px[k], s2.units.py[k]) != SimTerrain.ON_DECK:
					crossed = true
					break
			res.append(crossed)
		print("seed ", sd, " pontes ", res)
