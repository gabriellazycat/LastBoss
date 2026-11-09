class_name HandFan
extends Control
## Mão em leque (cartas compactas num arco; a carta sob o mouse sobe ampliada, com o texto) e, à esquerda,
## a esteira do ciclo: as próximas cartas da fila, da que entra na próxima jogada às mais distantes.
## O controle recebe a entrada do leque inteiro: a carta sob o mouse é a fatia do arco onde ele está.

signal card_pressed(i: int)
signal card_sacrificed(i: int)
signal card_dropped(i: int, screen_pos: Vector2)

const CARD := Vector2(124, 158)
const STEP := 114.0                # distância entre os centros das cartas
const ANGLE := 3.5                 # inclinação por carta, em graus
const DROOP := 5.0                 # quanto as pontas do arco descem
const LIFT := 30.0                 # carta selecionada
const QUEUE_W := 214.0             # largura reservada à esteira (dos dois lados, para o leque ficar no centro)
const QUEUE_SIZES := [Vector2(66, 86), Vector2(48, 62), Vector2(42, 54), Vector2(36, 46)]
const PREVIEW_W := 204.0
const TIP_HOLD := 0.6              # parado na carta por este tempo: abrem as caixas ao lado

var sim: Sim
var selected := -1
var pad := false                   # o jogador está no controle (o balão fica visível)
var sac_rect := Rect2()            # retângulo global do botão Sacrificar
var hover := -1
var panels := {}                   # uid -> carta compacta
var panel_sig := {}                # uid -> "mods" (refaz a carta quando ganha modificador)
var locale := ""
var preview: PanelContainer
var preview_key := ""
var balloon: PanelContainer
var balloon_key := ""
var queue_panels: Array = []
var queue_sig := ""
var queue_more: Label
var queue_head: Label
var press_i := -1
var t := 0.0
var mouse_override = null          # posição local fixa do mouse (só no teste da entrada real)
var tip_uid := -1                  # carta sob o mouse e há quanto tempo (caixas ao lado)
var tip_t := 0.0
var tip_sticky := false            # a carta só continua ampliada porque o mouse está nas caixas dela


func _init() -> void:
	custom_minimum_size = Vector2(QUEUE_W * 2.0 + STEP * 5 + CARD.x + 24, CARD.y + 30 + DROOP * 6.25)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_head = UiKit.label(13, UiKit.MUTED, 3)
	queue_head.text = "UI_NEXT"
	add_child(queue_head)
	queue_more = UiKit.label(15, UiKit.MUTED, 3)
	add_child(queue_more)


func bind(s: Sim) -> void:
	sim = s
	_clear_all()


func _clear_all() -> void:
	for uid in panels:
		panels[uid].queue_free()
	panels.clear()
	panel_sig.clear()
	for q in queue_panels:
		q.queue_free()
	queue_panels.clear()
	queue_sig = ""
	_drop_preview()
	_drop_balloon()
	hover = -1
	press_i = -1


# ---------------------------------------------------------------- geometria

func _fan_left() -> float:
	return (size.x - _fan_width(sim.hand.size() if sim else 5)) * 0.5


func _fan_width(n: int) -> float:
	return STEP * maxi(n - 1, 0) + CARD.x


## Retângulo do leque (local), onde o controle aceita cliques.
func fan_rect() -> Rect2:
	var n := sim.hand.size() if sim else 5
	return Rect2(Vector2(_fan_left() - 6.0, 0), Vector2(_fan_width(n) + 12.0, size.y))


func _has_point(p: Vector2) -> bool:
	return sim != null and (fan_rect().has_point(p) or _on_preview(p))


## O mouse está sobre a carta ampliada (ela sobe acima do leque): o clique vale para ela (rodada 09/11/2026).
func _on_preview(p: Vector2) -> bool:
	if preview == null or hover < 0:
		return false
	# Só a parte da carta acima do leque: dentro do leque vale a carta sob o mouse, como antes.
	var ps := preview.get_combined_minimum_size()
	return p.y < 0.0 and Rect2(preview.position, ps).has_point(p)


## Centro e rotação de repouso da carta k numa mão de n cartas.
func _rest(k: int, n: int) -> Array:
	var mid := (n - 1) * 0.5
	var d := k - mid
	# As pontas descem até a base do controle; antes desciam além dela e a barra de elixir cobria o nome.
	var c := Vector2(_fan_left() + CARD.x * 0.5 + STEP * k, size.y - CARD.y * 0.5 - 6.0 - DROOP * (mid * mid - d * d))
	return [c, deg_to_rad(ANGLE * d)]


## Retângulo global da carta k em repouso (para o teste da entrada real).
func card_rect(k: int) -> Rect2:
	var r: Array = _rest(k, sim.hand.size())
	return Rect2(global_position + r[0] - CARD * 0.5, CARD)


func _slot_at(m: Vector2) -> int:
	if sim.hand.is_empty():
		return -1
	if _on_preview(m) and hover < sim.hand.size():
		return hover
	if not fan_rect().has_point(m):
		return -1
	var k := int(floor((m.x - _fan_left() - CARD.x * 0.5 + STEP * 0.5) / STEP))
	return clampi(k, 0, sim.hand.size() - 1)


# ---------------------------------------------------------------- entrada

func _gui_input(e: InputEvent) -> void:
	if sim == null or not (e is InputEventMouseButton):
		return
	var k := _slot_at(e.position)
	if e.pressed and e.button_index == MOUSE_BUTTON_LEFT and k >= 0 and sim.hand[k] != null:
		press_i = k
		card_pressed.emit(k)
		accept_event()
	elif e.pressed and e.button_index == MOUSE_BUTTON_RIGHT and k >= 0 and sim.hand[k] != null:
		card_sacrificed.emit(k)
		accept_event()
	elif not e.pressed and e.button_index == MOUSE_BUTTON_LEFT and press_i >= 0:
		# Arrastar e soltar: fora do leque = posicionar; sobre o altar = sacrificar.
		var gp: Vector2 = get_global_transform() * e.position
		var fr := fan_rect().grow(8.0)
		var i := press_i
		press_i = -1
		if sac_rect.has_point(gp):
			card_sacrificed.emit(i)
		elif not Rect2(global_position + fr.position, fr.size).has_point(gp):
			card_dropped.emit(i, gp)
		accept_event()


# ---------------------------------------------------------------- atualização

func refresh(delta: float) -> void:
	if sim == null:
		return
	t += delta
	if TranslationServer.get_locale() != locale:
		locale = TranslationServer.get_locale()
		_clear_all()
	var motion := clampf(float(Settings.v["shake"]), 0.0, 1.0)
	var n := sim.hand.size()
	var m: Vector2 = get_local_mouse_position() if mouse_override == null else mouse_override
	hover = _slot_at(m) if press_i < 0 and not pad else -1
	if hover >= 0 and sim.hand[hover] == null:
		hover = -1
	# Lendo as caixas da carta (o mouse saiu do leque para dentro delas): a carta continua ampliada.
	tip_sticky = false
	if hover < 0 and press_i < 0 and not pad and Tips.is_open("hand:%d" % tip_uid):
		for k in n:
			if sim.hand[k] and sim.hand[k].uid == tip_uid:
				hover = k
				tip_sticky = true
	_refresh_queue(delta)
	# Cartas da mão: cria as novas (saindo da esteira), descarta as jogadas.
	var seen := {}
	for k in n:
		var ci: Sim.CardInst = sim.hand[k]
		if ci == null:
			continue
		seen[ci.uid] = true
		var sig := "%d/%d" % [ci.mods, ci.level]
		if panels.has(ci.uid) and panel_sig[ci.uid] != sig:
			var old: Control = panels[ci.uid]
			var p2 := _make_card(ci, k)
			p2.position = old.position
			p2.rotation = old.rotation
			old.queue_free()
			panels[ci.uid] = p2
		elif not panels.has(ci.uid):
			var p := _make_card(ci, k)
			var from: Vector2 = queue_panels[0].position + queue_panels[0].size * 0.5 if queue_panels.size() > 0 else Vector2(_fan_left(), size.y)
			p.position = from - CARD * 0.5
			p.scale = Vector2(0.5, 0.5)
			panels[ci.uid] = p
		panel_sig[ci.uid] = sig
	for uid in panels.keys():
		if not seen.has(uid):
			_discard(panels[uid])
			panels.erase(uid)
			panel_sig.erase(uid)
	var a := clampf(delta * 14.0, 0.0, 1.0)
	for k in n:
		var ci: Sim.CardInst = sim.hand[k]
		if ci == null:
			continue
		var p: PanelContainer = panels[ci.uid]
		var r: Array = _rest(k, n)
		var c: Vector2 = r[0]
		var rot: float = r[1]
		# Balanço leve em repouso (some com "tremor" em zero).
		rot += deg_to_rad(sin(t * 1.3 + k * 1.7) * 1.1) * motion
		c.y += sin(t * 1.7 + k * 0.9) * 2.0 * motion
		if k == selected:
			c.y -= LIFT
			rot *= 0.3
		p.pivot_offset = CARD * 0.5
		p.position = p.position.lerp(c - CARD * 0.5, a)
		p.rotation = lerp_angle(p.rotation, rot, a)
		p.scale = p.scale.lerp(Vector2.ONE, a)
		p.z_index = 2 if k == selected else 0
		var b := sim.can_play(k)
		(p.find_child("Cost", true, false) as Label).text = str(sim.card_cost(ci))
		var dim := Color(1, 1, 1) if b == K.Block.OK else Color(0.7, 0.7, 0.78)
		dim.a = 0.0 if k == hover else 1.0
		p.modulate = dim
		UiKit.card_state(p, k == selected, b == K.Block.OK)
	_refresh_preview(m, motion)
	_refresh_balloon(m)
	_refresh_tips(delta)


## Caixas das palavras-chave ao lado da carta: só depois de TIP_HOLD s com o mouse parado nela (passar rápido não
## abre nem pausa). No controle não abrem: selecionar uma carta pausaria o jogo; o balão já mostra o texto.
func _refresh_tips(delta: float) -> void:
	var ci: Sim.CardInst = sim.hand[hover] if hover >= 0 else null
	var uid := ci.uid if ci else -1
	if uid != tip_uid:
		tip_uid = uid
		tip_t = 0.0
	elif uid >= 0:
		tip_t += delta
	# Segura só com o mouse na carta; nas caixas, quem as mantém abertas é o próprio Tips.
	if ci == null or tip_t < TIP_HOLD or preview == null or tip_sticky:
		return
	var d := ci.def
	var mids := UiKit.mod_ids(ci)
	var lv := ci.level
	Tips.hold("hand:%d" % uid, preview.get_global_rect(), func(): return Tips.card_entries(d, mids, false, lv))


func _make_card(ci: Sim.CardInst, k: int) -> PanelContainer:
	var p := UiKit.mini_card(ci.def, sim.card_cost(ci), UiKit.mod_names(ci), str(k + 1), CARD.x, CARD.y, true, ci.level)
	add_child(p)
	return p


## A carta jogada sobe e some.
func _discard(p: Control) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "position:y", p.position.y - 110.0, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(p, "scale", Vector2(1.15, 1.15), 0.28)
	tw.tween_property(p, "modulate:a", 0.0, 0.28)
	tw.chain().tween_callback(p.queue_free)


# ---------------------------------------------------------------- carta ampliada e balão

func _refresh_preview(m: Vector2, motion: float) -> void:
	if hover < 0:
		_drop_preview()
		return
	var ci: Sim.CardInst = sim.hand[hover]
	var key := "%d/%d/%d" % [ci.uid, ci.mods, ci.level]
	if key != preview_key:
		_drop_preview()
		preview_key = key
		preview = UiKit.card(ci.def, sim.card_cost(ci), UiKit.mod_names(ci), str(hover + 1), PREVIEW_W, ci.level)
		UiKit.ignore_mouse(preview)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.z_index = 10
		preview.scale = Vector2(0.75, 0.75)
		add_child(preview)
	var ps := preview.get_combined_minimum_size()
	var c: Vector2 = _rest(hover, sim.hand.size())[0]
	var vx := get_viewport_rect().size.x
	var gx := clampf(global_position.x + c.x - ps.x * 0.5, 8.0, vx - ps.x - 8.0)
	preview.position = Vector2(gx - global_position.x, size.y + 4.0 - ps.y - (LIFT if hover == selected else 0.0) - (16.0 if UiSkins.covil() else 0.0))
	preview.pivot_offset = Vector2(ps.x * 0.5, ps.y)
	preview.scale = preview.scale.lerp(Vector2.ONE, 0.35)
	# Inclina de leve para o lado do mouse.
	preview.rotation = deg_to_rad(clampf((m.x - c.x) / CARD.x, -1.0, 1.0) * 3.0) * motion
	(preview.find_child("Cost", true, false) as Label).text = str(sim.card_cost(ci))
	preview.modulate = Color(1, 1, 1) if sim.can_play(hover) == K.Block.OK else Color(0.7, 0.7, 0.76)


func _drop_preview() -> void:
	if preview:
		preview.queue_free()
		preview = null
	preview_key = ""


## Balão da carta selecionada: some quando o mouse sai do leque para mirar (no controle, fica).
func _refresh_balloon(m: Vector2) -> void:
	var ci: Sim.CardInst = sim.hand[selected] if selected >= 0 and selected < sim.hand.size() else null
	var show := ci != null and hover < 0 and press_i < 0 and (pad or fan_rect().grow(20.0).has_point(m))
	if not show:
		if balloon:
			balloon.visible = false
		return
	var key := "%d/%d/%d/%s" % [ci.uid, ci.mods, ci.level, locale]
	if key != balloon_key:
		_drop_balloon()
		balloon_key = key
		balloon = _make_balloon(ci)
		add_child(balloon)
	balloon.visible = true
	var bs := balloon.get_combined_minimum_size()
	var c: Vector2 = _rest(selected, sim.hand.size())[0]
	var vx := get_viewport_rect().size.x
	var gx := clampf(global_position.x + c.x - bs.x * 0.5, 8.0, vx - bs.x - 8.0)
	balloon.position = Vector2(gx - global_position.x, c.y - LIFT - CARD.y * 0.5 - bs.y - 10.0)


func _make_balloon(ci: Sim.CardInst) -> PanelContainer:
	var d := ci.def
	var b := UiKit.panel(Color(0.06, 0.04, 0.1, 0.96), UiKit.GOLD, 10)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var nl := UiKit.label(16, UiKit.RARITY_COLORS[d.rarity].lightened(0.5), 3)
	nl.text = UiKit.card_name(d, ci.level)
	var tl := UiKit.label(12, UiKit.MUTED, 3)
	tl.text = UiKit.type_line(d)
	v.add_child(nl)
	v.add_child(tl)
	var mods := UiKit.mod_names(ci)
	if mods.size() > 0:
		var ml := UiKit.label(13, UiKit.GOLD, 3)
		ml.text = "★ " + "  ★ ".join(mods)
		v.add_child(ml)
	v.add_child(UiKit.card_rich(d, 14, Color(0.92, 0.9, 0.98), 250.0, false, ci.level))
	b.add_child(v)
	UiKit.ignore_mouse(b)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.z_index = 10
	return b


func _drop_balloon() -> void:
	if balloon:
		balloon.queue_free()
		balloon = null
	balloon_key = ""


# ---------------------------------------------------------------- esteira do ciclo

func _refresh_queue(delta: float) -> void:
	var sig := locale
	for i in mini(sim.queue.size(), QUEUE_SIZES.size()):
		var ci: Sim.CardInst = sim.queue[i]
		sig += ":%d/%d/%d" % [ci.uid, ci.mods, ci.level]
	sig += "+%d" % sim.queue.size()
	if sig != queue_sig:
		queue_sig = sig
		var old := {}
		for q in queue_panels:
			old[q.get_meta("uid")] = q
		queue_panels.clear()
		for i in mini(sim.queue.size(), QUEUE_SIZES.size()):
			var ci: Sim.CardInst = sim.queue[i]
			var sz: Vector2 = QUEUE_SIZES[i]
			var q := UiKit.mini_card(ci.def, sim.card_cost(ci), UiKit.mod_names(ci), "", sz.x, sz.y, false, ci.level)
			q.set_meta("uid", ci.uid)
			var qd := ci.def
			var qm := UiKit.mod_ids(ci)
			var ql := ci.level
			Tips.attach(q, func(): return Tips.card_entries(qd, qm, true, ql))
			# Quem já estava na esteira desliza da posição antiga.
			if old.has(ci.uid):
				q.position = old[ci.uid].position
				old.erase(ci.uid)
			else:
				q.position = Vector2(_fan_left() - 16.0 - sz.x, size.y - sz.y - 6.0)
			add_child(q)
			queue_panels.append(q)
		for q in old.values():
			q.queue_free()
		var more := sim.queue.size() - QUEUE_SIZES.size()
		queue_more.text = "+%d" % more if more > 0 else ""
	# Da direita (perto do leque) para a esquerda, encolhendo e apagando.
	var x := _fan_left() - 16.0
	var a := clampf(delta * 10.0, 0.0, 1.0)
	for i in queue_panels.size():
		var q: Control = queue_panels[i]
		var sz: Vector2 = QUEUE_SIZES[i]
		x -= sz.x + 6.0
		q.position = q.position.lerp(Vector2(x, size.y - sz.y - 10.0), a)
		q.modulate = Color(1, 1, 1, 1.0 - 0.17 * i)
	queue_head.position = Vector2(_fan_left() - 22.0 - QUEUE_SIZES[0].x, size.y - QUEUE_SIZES[0].y - 32.0)
	queue_head.visible = queue_panels.size() > 0
	queue_more.position = Vector2(x - 30.0, size.y - 40.0)
