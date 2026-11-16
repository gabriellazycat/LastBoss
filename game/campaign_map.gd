class_name CampaignMap
extends PanelContainer
## Mapa da campanha (16/11/2026, docs/CAMPANHA_MAPA.md): o covil fica no centro de um pergaminho do reino e cada
## fase é uma região de onde sai uma party. Em cima, as setas trocam de fase (a câmera volta pelo covil e segue a
## estrada da região nova); no meio, o mapa; embaixo, o que é o lugar, quem vem (silhuetas "?" para as classes que
## o jogador ainda não enfrentou, MetaSave.heroes_seen), o prêmio e o botão Defender.
## Regiões vencidas ficam escuras (a terra do covil) com um selo; as trancadas, sob névoa, sem os heróis.
## Coordenadas no papel de 1640x960 (data/campaign.json, "map" de cada fase). Fundo:
## o reino é desenhado só em traço, como o mapa da run (game/campaign_art.gd).

signal chosen(phase: int)
signal back

const MAP_ICONS := "res://assets/ui/map/"
## Fundo: o reino só em traço (CampaignArt), desenhado uma vez no dobro do tamanho do papel.
const BAKE := 2.0
const CAM_TIME := 1.5

var data: GameData
var meta: MetaSave
var parch := true             # peles Diário e Mapa aberto: papel e tinta; as outras, o painel escuro do UiKit
var phase := 0                # fase em foco
var view: Control             # o mapa (desenha em _draw_map)
var bg: Texture2D
var puff: Texture2D
var fog_col := Minimap.BG
var lair_icon: Texture2D
var title_l: Label
var sub_l: Label
var dots: Control
var prev_b: Button
var next_b: Button
var desc_l: RichTextLabel
var reward_box: VBoxContainer
var count_l: Label
var parties_box: HFlowContainer
var go_b: Button
var back_b: Button

# câmera (no papel)
var cam_c := Vector2(820, 500)
var cam_z := 1.0
var cam_path: PackedVector2Array = PackedVector2Array()
var cam_t := 1.0
var cam_z0 := 1.0
var pulse := 0.0


func setup(d: GameData, m: MetaSave) -> void:
	data = d
	meta = m


func _ready() -> void:
	parch = UiSkins.diario()
	lair_icon = load(MAP_ICONS + "node_m-lair_hot.svg")
	if parch:
		add_theme_stylebox_override("panel", UiParch.box("gold", 26.0))
		set_meta("paper", true)
	else:
		UiKit.panel_style(self, UiKit.BG, UiKit.EDGE, 18)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	# --- em cima: ◀ nome da fase ▶ e as bolinhas
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 28)
	root.add_child(top)
	prev_b = _arrow("◀", "UI_CAMPAIGN_PREV", -1)
	top.add_child(prev_b)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.custom_minimum_size = Vector2(760, 0)
	top.add_child(tv)
	title_l = _label("", "title", 36, _blood())
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(title_l)
	sub_l = _label("", "italic", 20, _soft())
	sub_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(sub_l)
	dots = Control.new()
	dots.custom_minimum_size = Vector2(0, 24)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.draw.connect(_draw_dots)
	tv.add_child(dots)
	next_b = _arrow("▶", "UI_CAMPAIGN_NEXT", 1)
	top.add_child(next_b)
	# --- o mapa
	view = Control.new()
	view.custom_minimum_size = Vector2(1440, 540)
	view.clip_contents = true
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	view.draw.connect(_draw_map)
	view.gui_input.connect(_view_input)
	# Trocar de fase muda o painel de baixo e pode mexer um pixel no mapa: não cortar a viagem da câmera por isso.
	view.resized.connect(func():
		if cam_t >= 1.0:
			_snap_camera())
	root.add_child(view)
	# --- embaixo: o lugar, quem vem, o prêmio, Defender
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 176)
	if parch:
		panel.add_theme_stylebox_override("panel", UiParch.box("ink", 14.0))
		panel.set_meta("paper", true)
	else:
		UiKit.panel_style(panel, UiKit.BG_SOFT, UiKit.EDGE, 12)
	root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.custom_minimum_size = Vector2(420, 0)
	row.add_child(left)
	desc_l = _rich("", 19, 420.0)
	left.add_child(desc_l)
	reward_box = VBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 2)
	left.add_child(reward_box)
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 14)
	mid.add_child(mh)
	mh.add_child(_label("UI_CAMPAIGN_FACE", "title", 22, _ink()))
	count_l = _label("", "italic", 18, _soft())
	count_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mh.add_child(count_l)
	parties_box = HFlowContainer.new()
	parties_box.add_theme_constant_override("h_separation", 10)
	parties_box.add_theme_constant_override("v_separation", 8)
	parties_box.custom_minimum_size = Vector2(640, 0)
	mid.add_child(parties_box)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
	go_b = Button.new()
	go_b.name = "Defend"
	go_b.text = "UI_CAMPAIGN_DEFEND"
	go_b.custom_minimum_size = Vector2(300, 64)
	if parch:
		UiParch.ribbon_button(go_b, "monster", 26)
	else:
		go_b.add_theme_font_size_override("font_size", 24)
	go_b.mouse_entered.connect(func(): go_b.grab_focus())
	go_b.pressed.connect(func():
		if meta.phase_open(phase):
			chosen.emit(phase))
	right.add_child(go_b)
	back_b = Button.new()
	back_b.text = "UI_BACK"
	back_b.custom_minimum_size = Vector2(300, 50)
	if parch:
		UiParch.paper_button(back_b, 21)
	back_b.mouse_entered.connect(func(): back_b.grab_focus())
	back_b.pressed.connect(func(): back.emit())
	right.add_child(back_b)


## Abre na fase dada (a próxima a vencer, em geral), com a câmera já enquadrando a região.
func open(k: int) -> void:
	phase = clampi(k, _first(), _last())
	_snap_camera()
	refresh()
	go_b.grab_focus.call_deferred()


func refresh() -> void:
	_fill_info()
	dots.queue_redraw()
	view.queue_redraw()


## Troca de fase: a câmera sai da região atual, passa pelo covil e segue a estrada da nova.
func select(k: int) -> void:
	k = clampi(k, _first(), _last())
	if k == phase:
		return
	var a := phase
	phase = k
	var path := PackedVector2Array()
	path.append(cam_c)
	var ra := _road(a)
	for i in range(ra.size() - 1, -1, -1):
		path.append(ra[i])
	var rb := _road(k)
	for i in rb.size():
		path.append(rb[i])
	path.append(_frame_center(k))
	cam_path = _smooth(path, 10)
	cam_t = 0.0
	cam_z0 = cam_z
	_fill_info()
	dots.queue_redraw()


func step(dir: int) -> void:
	select(phase + dir)


func animating() -> bool:
	return cam_t < 1.0


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	pulse += delta
	if cam_t < 1.0:
		cam_t = minf(cam_t + delta / CAM_TIME, 1.0)
		var s := smoothstep(0.0, 1.0, cam_t)
		cam_c = _along(cam_path, s)
		var zf := _zoom_frame()
		var zm := _zoom_fit()
		# Abre no meio do caminho (dá para ver o covil e as duas regiões) e fecha de novo na chegada.
		var base := lerpf(cam_z0, zf, s)
		cam_z = lerpf(base, minf(base, zm), sin(PI * s))
		cam_c = _clamp_center(cam_c, cam_z)
	view.queue_redraw()


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e.is_action_pressed("ui_left") and not e.is_echo():
		step(-1)
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("ui_right") and not e.is_echo():
		step(1)
		get_viewport().set_input_as_handled()


func _view_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p := _to_paper(e.position)
		var best := -1
		var bd := INF
		for ph in data.phases:
			var m: Dictionary = ph.get("map", {})
			if m.is_empty():
				continue
			var c := _v(m["pos"])
			var d := ((p - c) / Vector2(float(m["rx"]), float(m["ry"]))).length()
			if d < 1.1 and d < bd:
				bd = d
				best = int(ph["id"])
		if best >= 0:
			select(best)


# ------------------------------------------------------------------ informações

func _fill_info() -> void:
	var ph: Dictionary = data.phase(phase)
	var m: Dictionary = ph.get("map", {})
	var region := tr("REGION_" + str(ph.get("region", "")))
	var head := tr("UI_PHASE_TUTORIAL") if ph.get("tutorial", false) else tr("UI_PHASE").format({"n": phase})
	title_l.text = head + " · " + region
	sub_l.text = tr(str(ph["key"]))
	var open_ := meta.phase_open(phase)
	var won: bool = meta.phases_won.has(phase)
	Tips.set_text(desc_l, tr("PHASED_%d" % phase))
	UiKit.clear(reward_box)
	var rewards: Array = []
	if str(ph.get("unlock_villain", "")) != "":
		rewards.append(tr("UI_PHASE_UNLOCKS_V").format({"p": tr("DECK_" + str(ph["unlock_villain"]))}))
	# Vencer libera a próxima região (as Almas saíram em 16/11/2026).
	var nxt: Dictionary = data.phase(phase + 1)
	if not ph.get("final", false) and str(nxt.get("region", "")) != "":
		rewards.append(tr("UI_PHASE_NEXT_REGION").format({"r": tr("REGION_" + str(nxt["region"]))}))
	if ph.get("final", false):
		rewards.append(tr("UI_CAMPAIGN_FINAL"))
	for t in rewards:
		reward_box.add_child(_label("★ " + t, "bold", 17, _gold_ink()))
	if won:
		reward_box.add_child(_label("✓ " + tr("UI_PHASE_WON"), "bold", 17, _good()))
	# Quem vem.
	var party: Array = ph.get("party", [])
	var of: Array = ph.get("party_of", [])
	var n_parties := (int(of[of.size() - 1]) + 1) if of.size() > 0 else party.size()
	count_l.text = tr("UI_CAMPAIGN_COUNT").format({"p": n_parties, "h": party.size()})
	UiKit.clear(parties_box)
	if not open_:
		parties_box.add_child(_rich(tr("UI_CAMPAIGN_MYSTERY"), 18, 640.0))
	else:
		var mult := float(data.rules.get("hero_hp_mult", 1.0)) * float(ph.get("hp_mult", 1.0))
		for p in n_parties:
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 2)
			box.add_child(_label(tr("UI_CAMPAIGN_PARTY").format({"n": p + 1}), "heavy", 15, _soft()))
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 4)
			box.add_child(hb)
			for i in party.size():
				var pi := int(of[i]) if i < of.size() else i
				if pi == p:
					hb.add_child(_hero_chip(ph, i, str(party[i]), mult))
			parties_box.add_child(box)
	go_b.disabled = not open_
	go_b.text = "UI_CAMPAIGN_DEFEND" if open_ else tr("UI_PHASE_LOCKED")
	prev_b.disabled = phase <= _first()
	next_b.disabled = phase >= _last()
	prev_b.queue_redraw()
	next_b.queue_redraw()
	if m.is_empty():
		push_warning("campanha: fase %d sem 'map' em data/campaign.json" % phase)


## Um herói da party: retrato e nome se a classe já foi enfrentada; senão, um "?".
func _hero_chip(ph: Dictionary, i: int, cls: String, mult: float) -> Control:
	var seen := meta.heroes_seen.has(cls)
	var c := PanelContainer.new()
	if parch:
		c.add_theme_stylebox_override("panel", UiParch.box("ink", 5.0))
		c.set_meta("paper", true)
	else:
		UiKit.panel_style(c, UiKit.BG, UiKit.EDGE, 5)
	c.custom_minimum_size = Vector2(84, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(v)
	if seen:
		var t := UiParch.portrait("hero_" + cls)
		if t == null:
			t = UiDiario.card_tex("hero_" + cls)
		var art := TextureRect.new()
		art.texture = t
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.custom_minimum_size = Vector2(74, 58)
		art.clip_contents = true
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(art)
		var nm := _label(tr("HERO_" + cls), "bold", 14, _ink())
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		var st := _stat(ph, i, cls, mult)
		Tips.attach(c, func(): return [Tips.entry(tr("HERO_" + cls), tr("HEROD_" + cls) + "\n" + tr("UI_GROUP_HP").format({"n": int(st["hp"])}) + " · " + tr("UI_GROUP_DMG").format({"n": int(st["dm"])}))])
	else:
		var q := _label("?", "title", 44, _soft())
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.custom_minimum_size = Vector2(74, 58)
		v.add_child(q)
		var nm := _label("???", "bold", 14, _soft())
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		Tips.attach(c, func(): return [Tips.entry("?", tr("UI_CAMPAIGN_UNSEEN"))])
	return c


## Vida e golpe do herói i da fila da fase (a força da party é dividida entre os membros), como a tela antiga.
func _stat(ph: Dictionary, i: int, cls: String, mult: float) -> Dictionary:
	var of: Array = ph.get("party_of", [])
	var pn := int(of[i]) if i < of.size() else i
	var members := 1
	if of.size() > 0:
		members = of.filter(func(x): return int(x) == pn).size()
	var P: Dictionary = data.rules["party"]
	var H := data.hero_of(cls)
	var share := 1.0 / pow(float(maxi(members, 1)), float(P.get("share_exp", 1.0)))
	return {"hp": int(round(float(H["hp"]) * pow(float(P["step"]), pn) * mult * share)),
		"dm": int(round(float(H["damage"]) * pow(float(P["step"]), pn) * float(ph.get("damage_mult", 1.0)) * share))}


# ------------------------------------------------------------------ desenho do mapa

func _draw_map() -> void:
	var vs := view.size
	if parch:
		view.draw_rect(Rect2(Vector2.ZERO, vs), UiParch.PARCH_DARK)
	else:
		view.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.08, 0.06, 0.1))
	var o := vs * 0.5 - cam_c * cam_z
	view.draw_set_transform(o, 0.0, Vector2.ONE * cam_z)
	var paper := _paper()
	var lw := 1.0 / cam_z   # 1 px de tela em unidades do papel
	if bg == null:
		_bake()
	view.draw_texture_rect(bg, Rect2(Vector2.ZERO, paper), false)
	var lair := _lair()
	# A terra do covil: as regiões vencidas numa aguada de tinta sépia e a estrada até elas em tinta vermelha,
	# como o caminho já feito no mapa da run.
	for k in meta.phases_won:
		if data.phase(int(k)).get("map", {}).is_empty():
			continue
		view.draw_colored_polygon(_blob(int(k), 1.08), Color(Minimap.INK, 0.32))
		view.draw_polyline(_closed(_blob(int(k), 1.08)), Color(Minimap.INK, 0.8), 2.0 * lw, true)
		view.draw_polyline(_smooth(_road(int(k)), 8), Color(Minimap.ACC, 0.6), 4.0, true)
	# Névoa nas trancadas.
	for ph in data.phases:
		var k := int(ph["id"])
		if meta.phase_open(k) or ph.get("map", {}).is_empty():
			continue
		_fog(k)
	_dashed(_smooth(_road(phase), 8), UiParch.BLOOD, 5.0 * lw + 2.0, 18.0, 10.0)
	# Nomes, selos e o ponto de saída.
	var f := UiParch.font("title")
	for ph in data.phases:
		var k := int(ph["id"])
		var m: Dictionary = ph.get("map", {})
		if m.is_empty():
			continue
		var c := _v(m["pos"])
		var name_ := tr("REGION_" + str(ph.get("region", "")))
		var fs := 34 if k == phase else 28
		var w := f.get_string_size(name_, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var at := c + Vector2(-w * 0.5, -float(m["ry"]) * 0.62)
		view.draw_string_outline(f, at, name_, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color(UiParch.PARCH, 0.92))
		view.draw_string(f, at, name_, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiParch.BLOOD if k == phase else UiParch.INK)
		if meta.phases_won.has(k):
			_seal(c + Vector2(float(m["rx"]) * 0.55, -float(m["ry"]) * 0.35))
	var ex := _v(data.phase(phase).get("map", {}).get("exit", [820, 500]))
	var pr := 12.0 + 4.0 * sin(pulse * 4.0)
	view.draw_circle(ex, pr + 8.0, Color(UiParch.BLOOD, 0.25))
	view.draw_circle(ex, 11.0, UiParch.BLOOD)
	view.draw_arc(ex, 16.0, 0.0, TAU, 32, UiParch.PARCH, 3.0, true)
	view.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not parch:
		# Nas peles escuras o papel ganha uma borda da cor do painel.
		view.draw_rect(Rect2(Vector2.ZERO, vs), UiKit.EDGE, false, 2.0)


func _fog(k: int) -> void:
	var m: Dictionary = data.phase(k)["map"]
	var c := _v(m["pos"])
	var rx := float(m["rx"])
	var ry := float(m["ry"])
	# Névoa de papel, como os atos futuros do mapa da run.
	if puff == null:
		puff = Minimap._puff_tex()
		fog_col = CampaignArt.paper_color(CampaignArt.VARIANT)
	for j in 16:
		var a := float(j) * 2.39996 + float(k)
		var r := sqrt(float(j) / 16.0)
		var p := c + Vector2(cos(a) * rx * 0.8 * r, sin(a) * ry * 0.75 * r)
		var s := lerpf(1.25, 0.8, r) * minf(rx, ry) * (1.0 + 0.06 * sin(pulse * 0.7 + j))
		view.draw_texture_rect(puff, Rect2(p - Vector2(s * 1.5, s), Vector2(s * 3.0, s * 2.0)), false, Color(fog_col.lightened(0.12), 0.8))


## O reino em traço numa SubViewport (só uma vez): vira a textura do fundo.
func _bake() -> void:
	bg = CampaignArt.bake(self, data, CampaignArt.VARIANT)


func _seal(p: Vector2) -> void:
	view.draw_circle(p, 28.0, UiParch.BLOOD)
	view.draw_arc(p, 23.0, 0.0, TAU, 40, Color(UiParch.PARCH, 0.75), 2.5, true)
	var f := UiParch.font("title")
	var s := f.get_string_size("✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 34)
	view.draw_string(f, p + Vector2(-s.x * 0.5, s.y * 0.32), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, UiParch.PARCH)


## Linha tracejada sobre uma polilinha (traço e espaço em unidades do papel).
func _dashed(pts: PackedVector2Array, col: Color, w: float, dash: float, gap: float) -> void:
	var on := true
	var left := dash
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		var t := 0.0
		while seg - t > 0.001:
			var d := minf(left, seg - t)
			var p0 := a.lerp(b, t / seg)
			var p1 := a.lerp(b, (t + d) / seg)
			if on:
				view.draw_line(p0, p1, col, w, true)
			t += d
			left -= d
			if left <= 0.001:
				on = not on
				left = dash if on else gap


## Mancha irregular da região (elipse com ondas fixas por fase).
func _blob(k: int, grow: float) -> PackedVector2Array:
	var m: Dictionary = data.phase(k)["map"]
	var c := _v(m["pos"])
	var rx := float(m["rx"]) * grow
	var ry := float(m["ry"]) * grow
	var pts := PackedVector2Array()
	var sd := float(k) * 1.7
	for j in 48:
		var a := TAU * float(j) / 48.0
		var r := 1.0 + 0.08 * sin(3.0 * a + sd) + 0.05 * sin(7.0 * a + sd * 2.3)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry) * r)
	return pts


func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var q := p.duplicate()
	q.append(p[0])
	return q


func _draw_dots() -> void:
	var n := _last() - _first() + 1
	var gap := 26.0
	var x0 := dots.size.x * 0.5 - gap * (n - 1) * 0.5
	for j in n:
		var k := _first() + j
		var p := Vector2(x0 + gap * j, dots.size.y * 0.5)
		var ink := _ink()
		if meta.phases_won.has(k):
			dots.draw_circle(p, 7.0, Color(0.22, 0.08, 0.26) if parch else UiKit.POWER)
		elif meta.phase_open(k):
			dots.draw_circle(p, 7.0, Color(ink, 0.35))
		else:
			dots.draw_arc(p, 6.0, 0.0, TAU, 24, Color(ink, 0.45), 1.5, true)
		if k == phase:
			dots.draw_arc(p, 11.0, 0.0, TAU, 28, _blood(), 2.5, true)


# ------------------------------------------------------------------ câmera

func _paper() -> Vector2:
	var p: Array = data.campaign_map.get("paper", [1640, 960])
	return Vector2(float(p[0]), float(p[1]))


func _lair() -> Vector2:
	var l: Array = data.campaign_map.get("lair", [820, 500])
	return Vector2(float(l[0]), float(l[1]))


func _zoom_fit() -> float:
	var vs := view.size if view.size.x > 1.0 else view.custom_minimum_size
	var p := _paper()
	return maxf(vs.x / p.x, vs.y / p.y)


func _zoom_frame() -> float:
	return _zoom_fit() * 1.12


## Centro que enquadra a região da fase k (entre o meio da mancha e o ponto de saída).
func _frame_center(k: int) -> Vector2:
	var m: Dictionary = data.phase(k).get("map", {})
	if m.is_empty():
		return _lair()
	return _v(m["pos"]).lerp(_lair(), 0.3)


func _clamp_center(c: Vector2, z: float) -> Vector2:
	var vs := view.size if view.size.x > 1.0 else view.custom_minimum_size
	var half := vs * 0.5 / z
	var p := _paper()
	return Vector2(clampf(c.x, half.x, maxf(half.x, p.x - half.x)), clampf(c.y, half.y, maxf(half.y, p.y - half.y)))


func _snap_camera() -> void:
	cam_t = 1.0
	cam_z = _zoom_frame()
	cam_c = _clamp_center(_frame_center(phase), cam_z)
	if view:
		view.queue_redraw()


func _road(k: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in data.phase(k).get("map", {}).get("road", []):
		out.append(_v(p))
	if out.is_empty():
		out.append(_lair())
	return out


## Catmull-Rom: n pontos por trecho.
func _smooth(pts: PackedVector2Array, n: int) -> PackedVector2Array:
	if pts.size() < 3:
		return pts
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var p0 := pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var p3 := pts[mini(i + 2, pts.size() - 1)]
		for j in n:
			var t := float(j) / n
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[pts.size() - 1])
	return out


## Ponto a uma fração s do comprimento da polilinha.
func _along(pts: PackedVector2Array, s: float) -> Vector2:
	if pts.size() == 0:
		return cam_c
	if pts.size() == 1:
		return pts[0]
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var want := total * clampf(s, 0.0, 1.0)
	for i in pts.size() - 1:
		var d := pts[i].distance_to(pts[i + 1])
		if want <= d or i == pts.size() - 2:
			return pts[i].lerp(pts[i + 1], clampf(want / maxf(d, 0.001), 0.0, 1.0))
		want -= d
	return pts[pts.size() - 1]


func _to_paper(screen_p: Vector2) -> Vector2:
	return (screen_p - view.size * 0.5) / cam_z + cam_c


# ------------------------------------------------------------------ peças

func _first() -> int:
	return int(data.phases[0]["id"]) if data.phases.size() > 0 else 0


func _last() -> int:
	return int(data.phases[data.phases.size() - 1]["id"]) if data.phases.size() > 0 else 0


func _v(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func _arrow(glyph: String, tip: String, dir: int) -> Button:
	var b := Button.new()
	b.text = ""
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(76, 60)
	if parch:
		UiParch.paper_button(b, 30)
	else:
		b.add_theme_font_size_override("font_size", 28)
	b.focus_mode = Control.FOCUS_NONE   # as setas do teclado trocam a fase; o foco fica no Defender
	b.pressed.connect(func(): step(dir))
	# A seta é desenhada (a fonte dos títulos não tem ◀ ▶).
	b.draw.connect(func():
		var c := b.size * 0.5
		var w := 13.0 * float(dir)
		var col := Color(_blood(), 0.35) if b.disabled else _blood()
		b.draw_colored_polygon(PackedVector2Array([c + Vector2(w, 0), c + Vector2(-w, -16), c + Vector2(-w, 16)]), col))
	return b


func _label(text: String, kind: String, size: int, col: Color) -> Label:
	if parch:
		return UiParch.label(text, kind, size, col)
	var l := UiKit.title(size, col) if kind == "title" else UiKit.label(size, col)
	l.text = text
	return l


func _rich(text: String, size: int, w: float) -> RichTextLabel:
	var l := Tips.label(text, size, _ink(), w)
	if parch:
		UiParch.style_label(l, "body", size, UiParch.INK)
		l.add_theme_font_override("bold_font", UiParch.font("bold"))
		l.add_theme_font_size_override("bold_font_size", size)
	return l


func _ink() -> Color:
	return UiParch.INK if parch else UiKit.TEXT


func _soft() -> Color:
	return UiParch.INK_SOFT if parch else UiKit.MUTED


func _blood() -> Color:
	return UiParch.BLOOD if parch else UiKit.GOLD


func _gold_ink() -> Color:
	return UiParch.INK if parch else UiKit.GOLD


func _good() -> Color:
	return UiParch.GOOD if parch else UiKit.GOOD
