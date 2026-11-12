class_name HandFan
extends Control
## Mão em leque (cartas compactas num arco; a carta sob o mouse sobe ampliada, com o texto) e, dos lados, os dois
## montes: compra (à esquerda) e descarte (à direita). A ordem da compra é secreta: clicar num monte abre a lista
## das cartas dele ordenada por custo e nome.
## O controle recebe a entrada do leque inteiro: a carta sob o mouse é a fatia do arco onde ele está.

signal card_pressed(i: int)
signal card_dropped(i: int, screen_pos: Vector2)

const CARD := Vector2(124, 158)
const STEP := 114.0                # distância entre os centros das cartas
const ANGLE := 3.5                 # inclinação por carta, em graus
const DROOP := 5.0                 # quanto as pontas do arco descem
const LIFT := 30.0                 # carta selecionada
const QUEUE_W := 214.0             # largura reservada à esteira (dos dois lados, para o leque ficar no centro)
const DECK_BACK := Vector2(66, 86)       # cartas de costas empilhadas embaixo dela
const DECK_LAYERS := 7                   # quantas costas a pilha desenha no máximo
const DRAW_TIME := 0.42                  # a carta comprada voa do baralho até a mão
const PREVIEW_W := 204.0
const TIP_HOLD := 0.6              # parado na carta por este tempo: abrem as caixas ao lado

var sim: Sim
var selected := -1
var pad := false                   # o jogador está no controle (o balão fica visível)
var hover := -1
var panels := {}                   # uid -> carta compacta
var panel_sig := {}                # uid -> "mods" (refaz a carta quando ganha modificador)
var locale := ""
var preview: PanelContainer
var preview_key := ""
var balloon: PanelContainer
var balloon_key := ""
var deck_pile: Control                   # monte de compra (costas empilhadas, desenhado)
var disc_pile: Control                   # monte de descarte
var deck_count: Label
var disc_count: Label
var deck_head: Label
var disc_head: Label
var deck_pos := Vector2()                # canto da carta do topo da compra (local)
var disc_pos := Vector2()                # idem, descarte
var pile_open := ""                      # "", "draw" ou "discard": painel da lista aberto
var pile_panel: PanelContainer
var pile_sig := ""
var last_shuffles := 0
var last_discard := 0
var press_i := -1
var t := 0.0
var mouse_override = null          # posição local fixa do mouse (só no teste da entrada real)
var tip_uid := -1                  # carta sob o mouse e há quanto tempo (caixas ao lado)
var tip_t := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(QUEUE_W * 2.0 + STEP * 5 + CARD.x + 24, CARD.y + 30 + DROOP * 6.25)
	mouse_filter = Control.MOUSE_FILTER_STOP
	deck_pile = _make_pile("draw", Color(0.42, 0.18, 0.14))
	disc_pile = _make_pile("discard", Color(0.2, 0.22, 0.34))
	deck_head = _pile_head("UI_PILE_DRAW")
	disc_head = _pile_head("UI_PILE_DISCARD")
	deck_count = _pile_count(deck_pile)
	disc_count = _pile_count(disc_pile)


func bind(s: Sim) -> void:
	sim = s
	_clear_all()


func _clear_all() -> void:
	for uid in panels:
		panels[uid].queue_free()
	panels.clear()
	panel_sig.clear()
	_close_pile()
	if sim:
		last_shuffles = int(sim.stats.get("shuffles", 0))
		last_discard = sim.discard.size()
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


## O mouse chega mesmo à mão: nada por cima dela o pega (mapa em tela cheia, ofertas, pausa). O leque lê a posição
## do mouse a cada quadro; sem isto, as cartas atrás do mapa acendiam e abriam as caixas.
func _mouse_reaches_me() -> bool:
	if mouse_override != null:
		return true
	var h := get_viewport().gui_get_hovered_control()
	return h != null and (h == self or is_ancestor_of(h))


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
		# Clique direito na carta não faz nada (o sacrifício da mão saiu na rodada de 11/11/2026).
		accept_event()
	elif not e.pressed and e.button_index == MOUSE_BUTTON_LEFT and press_i >= 0:
		# Arrastar e soltar: fora do leque = posicionar.
		var gp: Vector2 = get_global_transform() * e.position
		var fr := fan_rect().grow(8.0)
		var i := press_i
		press_i = -1
		if not Rect2(global_position + fr.position, fr.size).has_point(gp):
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
	hover = _slot_at(m) if press_i < 0 and not pad and _mouse_reaches_me() else -1
	if hover >= 0 and sim.hand[hover] == null:
		hover = -1
	_refresh_piles(delta)
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
			var from: Vector2 = deck_pos + DECK_BACK * 0.5
			p.position = from - CARD * 0.5
			p.scale = Vector2(0.5, 0.5)
			p.rotation = -0.5
			p.set_meta("fly", 0.0)
			p.set_meta("fly_from", from)
			panels[ci.uid] = p
		panel_sig[ci.uid] = sig
	var to_discard := sim.discard.size() > last_discard
	last_discard = sim.discard.size()
	for uid in panels.keys():
		if not seen.has(uid):
			_discard(panels[uid], to_discard)
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
		if p.has_meta("fly"):
			# Compra: sai do baralho girando, faz um arco por cima e chega na mão com um leve exagero de escala.
			var f := minf(float(p.get_meta("fly")) + delta / DRAW_TIME, 1.0)
			p.set_meta("fly", f)
			var e := 1.0 - pow(1.0 - f, 3.0)
			var from: Vector2 = p.get_meta("fly_from")
			var to := c
			var mid := (from + to) * 0.5 + Vector2(0, -150.0)
			var q := from.lerp(mid, e).lerp(mid.lerp(to, e), e)
			p.position = q - CARD * 0.5
			p.rotation = lerp_angle(-0.5 - TAU, rot, e) if motion > 0.0 else rot
			p.scale = Vector2.ONE * (0.5 + 0.5 * e + 0.18 * sin(e * PI))
			if f >= 1.0:
				p.remove_meta("fly")
		else:
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
	# Segura só com o mouse na carta; as caixas são só de leitura (não pegam o mouse) e somem junto com ela.
	if ci == null or tip_t < TIP_HOLD or preview == null:
		return
	var d := ci.def
	var mids := UiKit.mod_ids(ci)
	var lv := ci.level
	Tips.hold("hand:%d" % uid, preview.get_global_rect(), func(): return Tips.card_entries(d, mids, false, lv), true)


func _make_card(ci: Sim.CardInst, k: int) -> PanelContainer:
	var p := UiKit.mini_card(ci.def, sim.card_cost(ci), UiKit.mod_names(ci), str(k + 1), CARD.x, CARD.y, true, ci.level)
	add_child(p)
	return p


## A carta jogada voa ao monte de descarte (ou, se não foi para lá, sobe e some).
func _discard(p: Control, to_pile := false) -> void:
	var tw := create_tween().set_parallel(true)
	if to_pile:
		p.z_index = 3
		var to := disc_pos + DECK_BACK * 0.5 - CARD * 0.5
		tw.tween_property(p, "position", to, 0.34).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(p, "scale", Vector2(0.5, 0.5), 0.34)
		tw.tween_property(p, "rotation", p.rotation + 0.6, 0.34)
		tw.tween_property(p, "modulate:a", 0.0, 0.12).set_delay(0.24)
		tw.chain().tween_callback(p.queue_free)
		return
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


# ---------------------------------------------------------------- montes de compra e descarte

func _make_pile(which: String, tint: Color) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	c.set_meta("tint", tint)
	c.set_meta("n", 0)
	c.draw.connect(func(): _draw_pile(c))
	c.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if pile_open == which:
				_close_pile()
			else:
				_open_pile(which)
			c.accept_event())
	add_child(c)
	return c


func _pile_head(key: String) -> Label:
	var l := UiKit.label(13, UiKit.MUTED, 3)
	l.text = key
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _pile_count(pile: Control) -> Label:
	var l := UiKit.label(24, Color(1, 0.95, 0.85), 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pile.add_child(l)
	return l


func _pile_cards(which: String) -> Array:
	return sim.queue if which == "draw" else sim.discard


func _refresh_piles(_delta: float) -> void:
	var nd := sim.queue.size()
	var nx := sim.discard.size()
	var half := _fan_width(maxi(sim.hand.size(), 5)) * 0.5 + 34.0
	var cx := size.x * 0.5
	var by := size.y - DECK_BACK.y - 12.0
	var ld := mini(maxi(nd - 1, 0), DECK_LAYERS)
	var lx := mini(maxi(nx - 1, 0), DECK_LAYERS)
	deck_pos = Vector2(cx - half - DECK_BACK.x, by) - Vector2(ld, ld) * 2.4
	disc_pos = Vector2(cx + half, by) - Vector2(lx, lx) * 2.4
	for pr in [[deck_pile, nd, deck_pos, ld, deck_count], [disc_pile, nx, disc_pos, lx, disc_count]]:
		var pile: Control = pr[0]
		pile.position = pr[2]
		pile.size = DECK_BACK + Vector2(pr[3], pr[3]) * 2.4
		if int(pile.get_meta("n")) != int(pr[1]):
			pile.set_meta("n", pr[1])
			pile.queue_redraw()
		var cl: Label = pr[4]
		cl.text = str(pr[1])
		cl.position = Vector2(0, DECK_BACK.y - 30.0)
		cl.size = Vector2(DECK_BACK.x, 26.0)
	deck_head.position = Vector2(deck_pos.x, deck_pos.y - 22.0)
	disc_head.position = Vector2(disc_pos.x, disc_pos.y - 22.0)
	# Embaralhou: as cartas do descarte voltam voando para a compra.
	var sh := int(sim.stats.get("shuffles", 0))
	if sh > last_shuffles:
		_fly_shuffle()
	last_shuffles = sh
	if pile_open != "" and _pile_sig(pile_open) != pile_sig:
		_open_pile(pile_open)


func _fly_shuffle() -> void:
	var from := disc_pos
	var to := deck_pos
	for i in 6:
		var b := Control.new()
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.size = DECK_BACK
		b.draw.connect(func(): _draw_back(b, Rect2(Vector2.ZERO, DECK_BACK), Color(0.42, 0.18, 0.14)))
		b.position = from
		b.z_index = 3
		b.modulate.a = 0.0
		add_child(b)
		var tw := create_tween()
		tw.tween_interval(0.05 * i)
		tw.tween_property(b, "modulate:a", 1.0, 0.04)
		var mid := (from + to) * 0.5 + Vector2(0, -90.0 - 8.0 * i)
		tw.tween_method(func(f: float): b.position = from.lerp(mid, f).lerp(mid.lerp(to, f), f), 0.0, 1.0, 0.45)
		tw.tween_property(b, "modulate:a", 0.0, 0.08)
		tw.tween_callback(b.queue_free)


## Costas das cartas do monte, da de baixo para a de cima (subindo para a esquerda e para cima).
func _draw_pile(pile: Control) -> void:
	var n: int = pile.get_meta("n", 0)
	var tint: Color = pile.get_meta("tint")
	var layers := mini(maxi(n - 1, 0), DECK_LAYERS)
	var base := Vector2(layers, layers) * 2.4
	if n == 0:
		var r := Rect2(base, DECK_BACK)
		pile.draw_rect(r, Color(0, 0, 0, 0.18))
		pile.draw_rect(r.grow(-2.0), Color(0.85, 0.7, 0.45, 0.35), false, 1.5)
		return
	for i in layers + 1:
		_draw_back(pile, Rect2(base - Vector2(i, i) * 2.4, DECK_BACK), tint)


func _draw_back(ci: CanvasItem, r: Rect2, tint: Color) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.25))
	ci.draw_rect(r, tint.darkened(0.3))
	ci.draw_rect(r.grow(-4.0), tint)
	ci.draw_rect(r.grow(-4.0), Color(0.85, 0.7, 0.45, 0.8), false, 1.2)
	var c := r.get_center()
	var s := 11.0
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.7, 0), c + Vector2(0, s), c + Vector2(-s * 0.7, 0)]), Color(0.85, 0.7, 0.45, 0.85))
	ci.draw_rect(r, Color(0.1, 0.05, 0.04), false, 1.0)


func _sorted_cards(which: String) -> Array:
	var a: Array = _pile_cards(which).duplicate()
	a.sort_custom(func(x: Sim.CardInst, y: Sim.CardInst):
		var cx := sim.card_cost(x)
		var cy := sim.card_cost(y)
		if cx != cy:
			return cx < cy
		var nx := UiKit.card_name(x.def, x.level)
		var ny := UiKit.card_name(y.def, y.level)
		if nx != ny:
			return nx < ny
		return x.level > y.level)
	return a


func _pile_sig(which: String) -> String:
	var ids: Array = []
	for ci: Sim.CardInst in _pile_cards(which):
		ids.append("%d/%d/%d" % [ci.uid, ci.mods, ci.level])
	# A ordem da compra não conta: o painel não se refaz (nem revela nada) quando só ela muda.
	ids.sort()
	return locale + which + ":".join(ids)


func _open_pile(which: String) -> void:
	_drop_pile_panel()
	pile_open = which
	pile_sig = _pile_sig(which)
	var cards := _sorted_cards(which)
	var pw := 84.0
	var ph := 110.0
	var cols := clampi(int(ceil(sqrt(maxf(cards.size(), 1) * 2.4))), 4, 9)
	var rows := int(ceil(float(cards.size()) / cols))
	pile_panel = UiKit.panel(Color(0.06, 0.04, 0.1, 0.97), UiKit.GOLD, 10)
	pile_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	pile_panel.z_index = 20
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var title := UiKit.label(16, UiKit.GOLD, 3)
	title.text = tr("UI_PILE_PANEL_DRAW" if which == "draw" else "UI_PILE_PANEL_DISCARD").format({"n": cards.size()})
	v.add_child(title)
	if cards.is_empty():
		var e := UiKit.label(14, UiKit.MUTED, 3)
		e.text = tr("UI_PILE_EMPTY")
		v.add_child(e)
	else:
		var grid := GridContainer.new()
		grid.columns = cols
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		for ci: Sim.CardInst in cards:
			var q := UiKit.mini_card(ci.def, sim.card_cost(ci), UiKit.mod_names(ci), "", pw, ph, true, ci.level)
			var qd := ci.def
			var qm := UiKit.mod_ids(ci)
			var ql := ci.level
			Tips.attach(q, func(): return Tips.card_entries(qd, qm, false, ql))
			grid.add_child(q)
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var avail := maxf(global_position.y - 90.0, 160.0)
		sc.custom_minimum_size = Vector2(cols * (pw + 6.0) + 12.0, minf(rows * (ph + 6.0) + 4.0, minf(avail, 360.0)))
		sc.add_child(grid)
		v.add_child(sc)
	if which == "draw" and sim.benched.size() > 0:
		var b := UiKit.label(13, UiKit.MUTED, 3)
		b.text = tr("UI_PILE_BENCHED").format({"n": sim.benched.size()})
		v.add_child(b)
	pile_panel.add_child(v)
	add_child(pile_panel)
	# Acima da mão, perto do monte clicado, sem sair da tela.
	var ps := pile_panel.get_combined_minimum_size()
	pile_panel.size = ps
	var vs := get_viewport_rect().size
	var anchor: Control = deck_pile if which == "draw" else disc_pile
	var gx := clampf(anchor.global_position.x + (0.0 if which == "draw" else anchor.size.x - ps.x), 8.0, vs.x - ps.x - 8.0)
	var gy := maxf(8.0, global_position.y - ps.y - 10.0)
	pile_panel.position = Vector2(gx, gy) - global_position


func _drop_pile_panel() -> void:
	if pile_panel:
		pile_panel.queue_free()
		pile_panel = null


func _close_pile() -> void:
	pile_open = ""
	pile_sig = ""
	_drop_pile_panel()


## Fecha o painel com Esc ou com um clique fora dele (o clique nos montes alterna por conta própria).
func _input(e: InputEvent) -> void:
	if pile_panel == null:
		return
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_close_pile()
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and e.pressed:
		var gp: Vector2 = e.global_position
		if pile_panel.get_global_rect().has_point(gp) or deck_pile.get_global_rect().has_point(gp) or disc_pile.get_global_rect().has_point(gp):
			return
		_close_pile()
