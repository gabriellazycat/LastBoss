class_name Sim
extends RefCounted
## Simulação completa de uma run. Lógica pura, passo fixo, determinística pela semente.
## Entrada só por comandos (play, choose, teleport); saída: estado + eventos + stats.

class CardInst:
	var def: CardDef
	var mods := 0
	var first_mod := 0      # bit do primeiro modificador ganho (dono do papel da carta)
	var uid := 0
	var level := 1
	var discount := 0       # desconto permanente desta cópia (relíquia Lima do Funileiro, quando já é Barata)

	func has_mod(m: int) -> bool:
		return (mods & m) != 0


var data: GameData
var R: Dictionary
var rng := RandomNumberGenerator.new()
var run_seed := 0
var dt := 0.05
var tick := 0
var t := 0.0
var ai_period := 4
var phase: int = K.Phase.ROAD
var result: int = K.Result.NONE
var units := SimUnits.new()
var hero := SimHero.new()
var followers: Array = []          # fase de grupo: heróis que andam junto do da vez
var helper: SimHero = null         # Herói Ajudante em disputa (11/11/2026): parado no local, fora do grupo
var revived: Array = []            # índices da fila já levantados uma vez
var hit_hero: SimHero = null       # herói que a unidade da vez acerta (null = o da vez)
var group_falls := 0
var party_of: Array = []            # número da party de cada herói da fila (parties de 1 a 4, 15/11/2026)
var cur_party := 0                  # party em campo
var road := SimRoad.new()
var arena := SimArena.new()
var zones: Array = []
var events: Array = []
var record_events := false
var pause_on_offer := true

var deck_id := ""
var deck_rules: Dictionary = {}
var elixir := 0.0
var elixir_max := 10.0
var hand: Array = []
## Recarga da vaga (15/11/2026): a carta jogada deixa a vaga vazia (null) por DRAW_DELAY s antes da compra.
## hand_wait[k] = segundos que faltam para a vaga k receber carta (paralelo a `hand`; null/0 = sem espera).
const DRAW_DELAY := 2.0
var hand_wait: Array = []
## Pilha de compra (o nome antigo ficou): a mão compra do começo dela. Baralho com descarte (passo C2, 10/11/2026):
## carta jogada vai para `discard`; quando a compra acaba, o descarte é embaralhado e vira a compra.
var queue: Array = []
var discard: Array = []
var benched: Array = []         # cartas de Rota fora do baralho durante a arena
var returned: Dictionary = {}   # uid -> true: carta "Retorna" que já voltou para a compra desde a última embaralhada
var cards: Array = []
var card_of_uid: Dictionary = {}
var hand_size := 5
## Teto da mão (as teclas vão de 1 a 9): compras extras (Pacto Sombrio, Biblioteca) param aqui (rodada 09/11/2026).
## Teto da mão (passo C4, 10/11/2026: 7). Mão base 5 para todos; cresce com relíquias e cartas Temporárias.
const HAND_MAX := 7
## Teto do elixir máximo (C4): a escada por ato e o que o jogador constrói nunca passam disto.
## Sem teto prático (11/11/2026): as relíquias de elixir empilham sem limite.
const ELIXIR_CAP := 999.0
var next_uid := 1
var party_idx := 0                 # herói da fila (0 a size-1); o nível dele é party_idx + 1
var campaign_phase := 1            # fase da campanha (data/campaign.json); 1 = a run clássica de 7 Escudeiros
var phase_cfg: Dictionary = {}
var party: Array = []              # classe de cada herói da fila
var phase_hp_mult := 1.0
var phase_dmg_mult := 1.0
var gate_pos := Vector2.ZERO       # portão da arena, onde o herói seguinte entra
var player_level := 1
var player_xp := 0.0
var offers: Array = []
var lair: Dictionary = {}       # id -> cópias jogadas (limite de stack)
var lair_val: Dictionary = {}   # id -> soma do efeito das cópias, já com o nível de cada uma
var unlocked: Array = []        # cartas que as ofertas podem sortear (vazio = todas)
var burn_t := 0.0               # Arqueiros N3: herói em chamas
var burn_dps := 0.0
var burn_src := "skeleton_archers"
# Famílias de cartas (rodada autônoma de 09/11/2026): estados dos combos.
var rally_until := -100.0       # Chamado do Bando: até quando o bando corre e bate mais
var rally_dmg := 0.0
var rally_spd := 0.0
var warcry_until := -100.0      # Grito de Guerra: todos os seus monstros correm e batem mais
var warcry_dmg := 0.0
var warcry_spd := 0.0
var harvest_until := -100.0     # Colheita de Almas: até quando cada morte sua devolve elixir
var harvest_elixir := 0.0
var mark_until := -100.0        # Marca Sombria: até quando feitiços machucam mais o herói
var mark_bonus := 0.0
var spell_times: Array = []     # instantes dos últimos feitiços jogados (Sequência)
var last_spell_id := ""         # Eco Sombrio repete este feitiço
var last_spell_lv := 1
## Disputa do local em andamento (rodada 09/11/2026): o herói para no local até ela acabar.
## {"li", "type", "t", "window", "progress", "goal"}; vazio = nenhuma.
var contest: Dictionary = {}
var act := 0                    # ato atual (0 a acts-1); a arena vem depois do último
var act_pending := false        # fim de ato: espera a escolha da relíquia para começar o próximo
var relics: Array = []          # relíquias do covil (ids)
var rfx: Dictionary = {}        # soma dos fx das relíquias (refeita ao ganhar e ao carregar)
var relic_deaths := 0           # mortes contadas para a Coroa de Ossos
var free_card_t := -100.0       # Olho Vigilante: até quando a próxima carta sai de graça
var next_hp_mult := 1.0         # eventos: vida do próximo herói
var next_extra_ability := false # eventos: o próximo herói chega com uma habilidade a mais
var boss_hp_mult := 1.0         # eventos: vida das partes do chefe na arena
var events_seen: Array = []     # eventos de texto já sorteados nesta run
var gold := 0.0                 # ouro da run (dano no herói e disputas vencidas); gasto nas lojas
var shop_removes := 0           # remoções compradas na run (cada uma encarece a próxima)
var route_wait := false         # o herói chegou a uma bifurcação sem ramo escolhido: o jogo espera a escolha
var auto_route := false         # sem escolha, segue o primeiro ramo em vez de esperar (testes que não jogam a rota)
var relic_max_gain := 0.0       # Marca da Vitória e Cofre Vivo: elixir máximo ganho na run (soma das duas)
var victory_gain := 0.0         # parte da Marca da Vitória (teto contest_max_cap)
var vault_gain := 0.0           # parte do Cofre Vivo (teto shop_max_cap)
var vault_spent := 0.0          # ouro gasto na loja ainda não convertido pelo Cofre Vivo
var tally_plays := 0            # Talha de Contagem: cartas jogadas desde a última grátis
var chain_times: Array = []     # Anel Encadeado: instantes das últimas cartas jogadas
var gambit_hero := -1          # Abertura: herói (pidx) contra quem a 1ª carta grátis já saiu
var phyl_hero := -1             # Filactério: herói (pidx) em que a volta já foi usada
var slow_hero := -1             # Piche: herói (pidx) mais lento até cair (-1 = nenhum)
var last_teleport_t := -100.0
var ritual_mult := 1.0
## Efeitos Temporários em andamento (C4: as antigas cartas de Covil): {"kind", "v", "until", "src"}.
## kind: elixir_regen (+fração de ganho), monster_hp (+fração de vida ao entrar), hand (+cartas), elixir_max (+máximo),
## gold_mult (+fração do ouro ganho). Cópias somam, cada uma com o seu tempo.
var temps: Array = []
var act_elixir_base := 10.0     # elixir máximo base do ato (piso por ato: rules.acts[].elixir.max; sem ele, rules.elixir.max)
var _elixir_act_seen := -1
## Estado livre das cartas por dono (C6): cada arquivo de sim/cards/ guarda o que precisar aqui, numa chave
## própria (ex.: cstate["plague"]). Vai no salvamento (só tipos simples: números, textos, Array, Dictionary).
var cstate: Dictionary = {}
var harvest_deaths := 0         # Lich (Colheita): mortes de criaturas suas desde o último feitiço grátis
var harvest_free := false       # Lich: o próximo feitiço custa 0
var cycle_spell := false        # Lich (Ciclo de feitiço): uma criatura sua morreu, o próximo feitiço custa 1 a menos
var cycle_mon := false          # Lich (Ciclo de feitiço): um feitiço saiu, a próxima criatura custa 1 a menos
var act_elixir_bonus := 0.0     # eventos: elixir máximo a mais até o fim do ato (Altar Profano)
var tax_cards := 0              # eventos: quantas das próximas cartas custam `tax_add` a mais
var tax_add := 0
var dead_by_def := PackedInt32Array()
var stats: Dictionary = {}
var track: UnlockTrack = UnlockTrack.new()   # desafios de desbloqueio (data/unlocks.json)
var tmp := PackedInt32Array()


## `deck` é o Pacto (regras); `card_list` é o deck montado na coleção (vazio = deck pronto do Pacto);
## `unlocked_` limita as ofertas às cartas desbloqueadas (vazio = todas).
func setup(d: GameData, seed_: int, deck: String, card_list: Array = [], unlocked_: Array = [], phase_n := 1) -> void:
	data = d
	R = d.rules
	campaign_phase = phase_n
	phase_cfg = d.phase(phase_n)
	# Fila de parties (15/11/2026): "parties" = lista de grupos de 1 a 4 heróis que entram juntos. Sem ela, cada
	# herói de "party" é uma party sozinha (comportamento antigo).
	party = []
	party_of = []
	var groups: Array = phase_cfg.get("parties", [])
	if groups.is_empty():
		for c in phase_cfg.get("party", []):
			groups.append([c])
	if groups.is_empty():
		for k in int(R["party"]["size"]):
			groups.append(["escudeiro"])
	for gi in groups.size():
		for c in groups[gi]:
			party.append(str(c))
			party_of.append(gi)
	phase_hp_mult = float(phase_cfg.get("hp_mult", 1.0))
	phase_dmg_mult = float(phase_cfg.get("damage_mult", 1.0))
	run_seed = seed_
	rng.seed = seed_
	dt = R["sim"]["dt"]
	ai_period = maxi(1, int(round(1.0 / dt / float(R["sim"]["danger_hz"]))))
	road.generate(rng, R, _act_cfg(0))
	units.setup(self, int(R["sim"]["max_units"]))
	var dk := d.deck(deck)
	deck_id = dk["id"]
	deck_rules = dk["rules"]
	gold = float(deck_rules.get("start_gold", 0.0))
	hero.setup(self)
	# A primeira party já entra inteira: os outros membros andam junto do primeiro.
	var first: Array = party_members(0)
	for k in range(1, first.size()):
		var nf := SimHero.new()
		nf.init_follower(self, int(first[k]), hero, 1.0)
		followers.append(nf)
	hand_size = int(deck_rules.get("hand_size", R["hand_size"]))
	elixir = float(deck_rules.get("elixir_start", R["elixir"]["start"]))
	act_elixir_base = float(R["elixir"]["max"])
	recalc_elixir_max()
	dead_by_def.resize(d.cards.size())
	stats = {"seed": run_seed, "deck": deck_id, "result": "none", "t_end": 0.0, "arena_t": -1.0,
		"heroes_fallen": 0, "hero_level_arena": 0, "player_level_arena": 0, "hero_level": 1, "player_level": 1,
		"waste_s": 0.0, "offered": {}, "picked": {}, "played": {}, "dmg_by_card": {}, "deck_final": [],
		"upgrades": [], "shrines_won": 0, "shrines_lost": 0,
		"parts_lost": 0, "kills": 0, "units_peak": 0, "teleports": 0, "shield_breaks": 0,
		"route_len": 0.0, "hero_hp_arena": 0.0, "locs_visited": 0, "locs_won": 0, "locs_lost": 0,
		"skipped": 0, "card_levels": 0, "gold_earned": 0.0, "gold_spent": 0, "shop_buys": 0, "route": {},
		"act_t": [], "relics": [], "event_picks": {}, "contests": {},
		"time_act": [], "spent_act": [], "plays_act": [], "max_cost": 0, "stuck_s": 0.0, "walk_s": 0.0, "contest_s": 0.0}
	unlocked = unlocked_.duplicate()
	track.setup(d)
	var list: Array = (card_list if card_list.size() > 0 else dk["cards"]).duplicate()
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmpc = list[i]
		list[i] = list[j]
		list[j] = tmpc
	for id in list:
		queue.append(_new_inst(d.card(id)))
	_refill_hand()


func acts() -> int:
	return int(phase_cfg.get("acts", R.get("run", {}).get("acts", 1)))


func party_size() -> int:
	return party.size()


func party_class(i: int) -> String:
	return str(party[clampi(i, 0, party.size() - 1)]) if party.size() > 0 else "escudeiro"


## Quantas parties tem a fila.
func party_count() -> int:
	return (int(party_of[party_of.size() - 1]) + 1) if party_of.size() > 0 else 1


## Número (0 a count-1) da party do herói i da fila.
func party_number(i: int) -> int:
	return int(party_of[clampi(i, 0, party_of.size() - 1)]) if party_of.size() > 0 else i


## Índices (na fila) dos heróis da party p.
func party_members(p: int) -> Array:
	var out: Array = []
	for i in party_of.size():
		if int(party_of[i]) == p:
			out.append(i)
	return out


## Tamanho da party do herói i.
func party_n_of(i: int) -> int:
	return maxi(1, party_members(party_number(i)).size())


## Alguma party tem mais de um herói: os membros andam juntos e as quedas contam uma a uma.
func party_mode() -> bool:
	return party.size() > party_count()


## Quantos heróis já caíram (qualquer modo).
func fallen_count() -> int:
	return group_falls if (party_mode() or group_mode()) else party_idx


func _act_cfg(k: int) -> Dictionary:
	var A: Array = R.get("acts", [])
	return A[mini(k, A.size() - 1)].get("road", {}) if A.size() > 0 else {}


func _new_inst(c: CardDef) -> CardInst:
	var ci := CardInst.new()
	ci.def = c
	ci.uid = next_uid
	next_uid += 1
	cards.append(ci)
	card_of_uid[ci.uid] = c.id
	return ci


func emit(k: int, x: float, y: float, v: float, e: int) -> void:
	if record_events:
		events.append([k, x, y, v, e])


# ================================================================ passo

## Água dos rios do ato (SimTerrain), refeita quando a estrada muda (novo ato ou save carregado).
var terrain := SimTerrain.new()
var _terrain_road: SimRoad = null


func terra() -> SimTerrain:
	if _terrain_road != road:
		_terrain_road = road
		terrain.build(road, R)
	return terrain


## Passo final da água (16/11/2026): herói, grupo e monstros de chão nunca terminam o passo dentro do rio.
## Quem entrou volta deslizando para a margem de onde veio (empurrões, separação, medo, nascimentos...).
func _water_pass(prev: Dictionary) -> void:
	if phase != K.Phase.ROAD:
		return
	var T := terra()
	if not T.ok:
		return
	for hh in [hero] + followers + ([helper] if helper != null else []):
		var pp: Vector2 = prev.get(hh, Vector2(hh.x, hh.y))
		var q := T.resolve(hh.x, hh.y, pp.x, pp.y)
		hh.x = q.x
		hh.y = q.y
	for i in units.hi:
		if units.alive[i] == 0 or (units.flags[i] & K.F_FLY):
			continue
		if T.is_water(units.px[i], units.py[i]):
			var q := T.resolve(units.px[i], units.py[i], units.ox[i], units.oy[i])
			units.px[i] = q.x
			units.py[i] = q.y


func step() -> void:
	_refill_hand()
	if phase == K.Phase.OVER:
		return
	if act_pending:
		# Fim de ato: o mundo para até a relíquia ser escolhida (também sem pausa, para os bots).
		if offers.is_empty():
			_next_act()
		return
	if pause_on_offer and (offers.size() > 0 or route_wait):
		return
	tick += 1
	t += dt
	_tick_draws()
	_meter()
	_temps()
	_release_held()
	_elixir()
	var prev := {hero: Vector2(hero.x, hero.y)}
	for f in followers:
		prev[f] = Vector2(f.x, f.y)
	if helper != null:
		prev[helper] = Vector2(helper.x, helper.y)
	hero.update(dt)
	for f in followers:
		f.update(dt)
		_follow(f)
	if helper != null:
		# Herói Ajudante (15/11/2026): até aqui ele nunca era atualizado (ficava parado e não batia).
		# Espera ao lado do herói da vez, vai nos monstros que chegam perto e a coleira de _follow o traz de volta.
		var ha := float(helper.pidx) * 2.4
		helper.hold_x = hero.x + cos(ha) * 3.6
		helper.hold_y = hero.y + sin(ha) * 3.6
		helper.update(dt)
		_follow(helper)
	if tick % 4 == 0:
		units.apply_auras()
	units.update(dt)
	CardsCommon.on_tick(self)
	CardsPlague.on_tick(self)
	CardsDragon.on_tick(self)
	CardsLich.on_tick(self)
	track.on_tick(self)
	if tick % 2 == 0:
		units.separate()
	if units.count > stats["units_peak"]:
		stats["units_peak"] = units.count
	_water_pass(prev)
	_zones()
	_burn()
	if phase == K.Phase.ROAD:
		_road()
	elif phase == K.Phase.ARENA:
		arena.update(dt)
	_check_end()


## Contadores de métrica (só stats, nenhuma regra): tempo, elixir gasto e cartas jogadas por ato; tempo andando
## × em disputa na estrada; tempo com a mão travada (nenhuma carta jogável e, ou o elixir está cheio, ou nenhuma
## está só esperando elixir).
func _act_slot() -> int:
	var a := mini(act, maxi(acts(), 1) - 1)
	var ta: Array = stats["time_act"]
	while ta.size() <= a:
		ta.append(0.0)
		stats["spent_act"].append(0.0)
		stats["plays_act"].append(0)
	return a


func _meter() -> void:
	var a := _act_slot()
	stats["time_act"][a] += dt
	if phase == K.Phase.ROAD:
		stats["contest_s" if contest.size() > 0 else "walk_s"] += dt
	if hand.is_empty() or offers.size() > 0:
		return
	var short := false
	for i in hand.size():
		if hand[i] == null:
			continue
		var b := can_play(i)
		if b == K.Block.OK:
			return
		if b == K.Block.NO_ELIXIR:
			short = true
	if not short or elixir >= elixir_max - 0.01:
		stats["stuck_s"] += dt


## Valor por ato (rules.acts[].elixir; hoje só max_cost: a escada de máximo e regen saiu em 11/11/2026).
func _act_elixir(k: String, fallback: float) -> float:
	var A: Array = R.get("acts", [])
	if A.is_empty():
		return fallback
	return float(A[mini(act, A.size() - 1)].get("elixir", {}).get(k, fallback))


## Custo máximo de carta que as ofertas deste ato podem trazer (loja inclusive). Sem a escada (11/11/2026) o
## máximo pode ficar em 10 no ato 3: a oferta nunca traz carta mais cara que o elixir máximo permanente (sem o
## sacrifício da mão, uma carta impagável travaria uma vaga da mão para sempre).
func max_offer_cost() -> int:
	return mini(int(_act_elixir("max_cost", 99.0)), int(floorf(perm_elixir_max())))


## Elixir máximo sem os efeitos passageiros (Temporários e eventos do ato).
func perm_elixir_max() -> float:
	return maxf(3.0, act_elixir_base + rv("elixir_max") + relic_max_gain)


## Segundos por ponto de elixir agora, sem ritual, arena e Temporários (métrica e texto da relíquia).
func seconds_per_elixir() -> float:
	return float(R["elixir"]["seconds_per_point"]) / maxf(0.1, 1.0 + rv("elixir_regen")) / maxf(0.1, _act_elixir("regen_mult", 1.0))


## Elixir máximo = base + relíquias + eventos do ato + Temporários, no mínimo 3 (sem teto prático).
func recalc_elixir_max() -> void:
	act_elixir_base = _act_elixir("max", float(R["elixir"]["max"]))   # piso do ato (13/11/2026)
	_elixir_act_seen = act
	elixir_max = clampf(act_elixir_base + rv("elixir_max") + relic_max_gain + act_elixir_bonus + temp_sum("elixir_max"), 3.0, ELIXIR_CAP)
	elixir = minf(elixir, elixir_max)


func temp_sum(kind: String) -> float:
	var s := 0.0
	for e in temps:
		if e["kind"] == kind:
			s += float(e["v"])
	return s


## Começa um efeito Temporário (op "temp" de CardFxLib).
func add_temp(kind: String, v: float, duration: float, src: String) -> void:
	note_linger(t + duration)
	temps.append({"kind": kind, "v": v, "until": t + duration, "src": src})
	match kind:
		"hand":
			hand_size += int(v)
			_refill_hand()
		"elixir_max":
			recalc_elixir_max()


## Cartas em vigor (16/11/2026): a carta jogada com efeito temporário (op temp/buff) sai da mão mas só vai ao descarte
## quando o efeito acaba. `held` guarda só {uid, from, until} (o save é de variáveis simples); a carta vem de `cards`.
var held: Array = []
var _linger_until := 0.0   # maior fim de efeito visto durante a carta que está sendo aplicada


func note_linger(until: float) -> void:
	_linger_until = maxf(_linger_until, until)


func held_card(e: Dictionary) -> CardInst:
	for ci in cards:
		if ci.uid == int(e["uid"]):
			return ci
	return null


## Depois de aplicar a carta: se o efeito dura, tira do descarte e segura até `until`.
func _hold_if_lingering(c: CardInst, t0: float) -> void:
	if _linger_until <= t + 0.05 or discard.is_empty() or discard.back() != c:
		return
	discard.pop_back()
	held.append({"uid": c.uid, "from": t, "until": _linger_until})


## Cartas em vigor que acabaram voltam ao descarte (ou à compra, se "retornam").
func _release_held() -> void:
	var i := held.size() - 1
	while i >= 0:
		if t >= float(held[i]["until"]):
			var c := held_card(held[i])
			held.remove_at(i)
			if c != null:
				_to_discard(c)
		i -= 1


## Temporários que acabaram: a mão extra só deixa de ser reposta (nenhuma carta é expulsa); o elixir acima do
## novo máximo é cortado.
func _temps() -> void:
	var i := temps.size() - 1
	var dirty := false
	while i >= 0:
		var e: Dictionary = temps[i]
		if t >= float(e["until"]):
			temps.remove_at(i)
			if e["kind"] == "hand":
				hand_size -= int(e["v"])
			elif e["kind"] == "elixir_max":
				dirty = true
		i -= 1
	if dirty:
		recalc_elixir_max()


func _elixir() -> void:
	if act != _elixir_act_seen:
		recalc_elixir_max()   # entrou em outro ato: muda o piso de máximo e de regeneração
	var rate := 1.0 / seconds_per_elixir()
	rate *= 1.0 + temp_sum("elixir_regen")
	rate *= ritual_mult
	rate *= float(deck_rules.get("elixir_mult", 1.0))
	if phase == K.Phase.ARENA and arena.part_alive("head"):
		rate *= float(R["arena"]["elixir_mult_head"])
	rate *= 1.0 + overtime() * float(R["arena"].get("overtime_elixir", 0.0))
	elixir += rate * dt
	if elixir >= elixir_max:
		elixir = elixir_max
		stats["waste_s"] += dt


func _road() -> void:
	ritual_mult = 1.0
	if not road.complete and hero.s >= road.length() - float(R["road"]["fork_decision_distance"]):
		var e := road.next_edge()
		if e < 0:
			# Bifurcação sem plano: a escolha vem depois do local do nó. Enquanto ele não acaba, o herói
			# anda até o fim da rota decidida (o próprio nó) e espera lá.
			if _head_busy():
				pass
			elif pause_on_offer and not auto_route:
				route_wait = true
				return
			else:
				e = road.nodes[road.head]["out"][0]
		if e >= 0:
			route_wait = false
			road.advance(e)
	if road.complete and hero.s >= road.length() - 1.5 and contest.is_empty():
		_end_act()
		return
	var hp_ := Vector2(hero.x, hero.y)
	if contest.is_empty():
		for li in road.locations.size():
			var loc: Dictionary = road.locations[li]
			if loc["state"] != SimRoad.LocState.ACTIVE or loc["entered"]:
				continue
			if hp_.distance_to(loc["pos"]) <= loc["r"] and road.is_on_route(loc):
				_arrive(li)
				break
	_contest_tick()


## O nó no fim da rota decidida ainda tem algo a resolver: o local, a disputa ou uma oferta aberta.
func _head_busy() -> bool:
	if contest.size() > 0 or offers.size() > 0:
		return true
	var li: int = road.nodes[road.head]["loc"]
	return li >= 0 and road.locations[li]["state"] == SimRoad.LocState.ACTIVE and road.is_on_route(road.locations[li])


## O herói chegou ao local li. Loja e evento abrem na hora; os outros começam uma disputa sustentada.
func _arrive(li: int) -> void:
	var loc: Dictionary = road.locations[li]
	var ty: String = loc["type"]
	loc["entered"] = true
	stats["locs_visited"] += 1
	var rt: Dictionary = stats["route"]
	rt[ty] = int(rt.get(ty, 0)) + 1
	emit(K.Ev.LOCATION, hero.x, hero.y, li, 0)
	var p: Vector2 = loc["pos"]
	# Incêndio: o local marcado pega fogo quando o herói chega.
	if loc.get("burn", false):
		var bf: Dictionary = data.card("burn_village").fx
		zones.append({"kind": "fire", "x": p.x, "y": p.y, "r": loc["r"] + 1.0, "t": float(loc["burn_s"]),
			"dps": float(loc["burn_dps"]), "src": "burn_village"})
		emit(K.Ev.EXPLOSION, p.x, p.y, float(bf.get("radius_fx", 4.0)), 1)
	var L: Dictionary = R["locations"]
	match ty:
		"shop":
			loc["state"] = SimRoad.LocState.USED
			if float(deck_rules.get("shop_gold", 0.0)) > 0.0:
				_dragon_shop()
			else:
				_open_shop()
			return
		"event":
			loc["state"] = SimRoad.LocState.USED
			_offer_event()
			return
		"helper":
			_start_helper(li)
			if rv("contest_enter_elixir") > 0.0:
				elixir = minf(elixir_max, elixir + rv("contest_enter_elixir"))   # Tambor de Guerra: o ajudante também é briga
			return
	var P: Dictionary = L[ty]
	contest = {"li": li, "type": ty, "marks": [1.0, 2.0, 3.0], "won": 0, "t": 0.0, "progress": 0.0, "goal": 3.0,
		"window": 15.0, "variant": "", "r": float(loc["r"])}
	if ty == "tavern":
		var n := int(P["houses"])
		var houses: Array = []
		var a0 := rng.randf() * TAU
		var hpa: Array = P.get("house_hp_act", [])
		for k in n:
			var a := a0 + TAU * k / n
			var hp0 := float(hpa[mini(act, hpa.size() - 1)]) if hpa.size() > 0 else float(P["house_hp"])
			houses.append({"x": p.x + cos(a) * float(P["house_ring"]), "y": p.y + sin(a) * float(P["house_ring"]), "hp": hp0, "max_hp": hp0})
		loc["houses"] = houses
	hero.hold = true
	hero.hold_x = p.x
	hero.hold_y = p.y
	if ty == "fountain":
		_spawn_fountain_guard(li)
	if rv("contest_enter_elixir") > 0.0:
		elixir = minf(elixir_max, elixir + rv("contest_enter_elixir"))   # Tambor de Guerra
	emit(K.Ev.CONTEST, p.x, p.y, li, 0)
	_start_bar()


## Guarda da Fonte (12/11/2026): enquanto o herói bebe indefeso, um outro herói (classe sorteada, diferente da do
## herói da vez) defende o local, parado ao lado dele, e bate nos monstros que chegam. Reaproveita o Herói Ajudante
## (puxa os monstros como ele). Matar o guarda não conta para a meta do gole; só tira a ameaça. Some com a disputa.
func _spawn_fountain_guard(li: int) -> void:
	var G: Dictionary = R["locations"]["fountain"].get("guard", {})
	if G.is_empty() or helper != null:
		return
	var pool: Array = []
	for c in R["locations"]["helper"]["classes"]:
		if str(c) != hero.cls():
			pool.append(str(c))
	var cls: String = pool[rng.randi_range(0, pool.size() - 1)]
	var hpa: Array = G["hp_act"]
	var hp0 := float(hpa[mini(act, hpa.size() - 1)])
	var stand := helper_spot(li)
	var p: Vector2 = road.locations[li]["pos"]
	helper = SimHero.new()
	helper.init_helper(self, cls, hp0, stand, party_idx + 1, hero.seg)
	var fv := (p - stand).normalized()
	helper.face_x = fv.x
	helper.face_y = fv.y


## Começa a barra da disputa (rodada 12/11/2026): uma janela e uma barra com 3 marcos (rules.locations.*.marks);
## cada marco alcançado vale uma recompensa. Metas escalam por ato (act_mult) e a variante do ato (stage3[ato])
## vale para a barra inteira.
func _start_bar() -> void:
	var ty: String = contest["type"]
	var P: Dictionary = R["locations"][ty]
	var loc: Dictionary = road.locations[int(contest["li"])]
	var p: Vector2 = loc["pos"]
	var v3: Array = P.get("stage3", [])
	var var_: String = str(v3[mini(act, v3.size() - 1)]) if v3.size() > 0 else ""
	var am: Array = P.get("act_mult", [])
	var mult := float(am[mini(act, am.size() - 1)]) if am.size() > 0 else 1.0
	if loc.get("hard", false):
		mult *= float(P.get("hard_goal_mult", R["locations"].get("hard_goal_mult", 1.0)))
	var marks: Array = []
	for m in P["marks"]:
		marks.append(maxf(1.0, roundf(float(m) * mult)))
	contest["marks"] = marks
	contest["goal"] = float(marks[marks.size() - 1])
	contest["variant"] = var_
	contest["t"] = 0.0
	contest["progress"] = 0.0
	contest["won"] = 0
	contest["window"] = float(P["window"]) * (1.0 + rv("contest_window"))
	contest["r"] = float(loc["r"])
	contest.erase("p2")
	contest["inside"] = {}
	match ty:
		"shrine":
			if var_ == "shrink":
				contest["r"] = float(loc["r"]) * float(P["shrink"])
			elif var_ == "two":
				var a := rng.randf() * TAU
				contest["p2"] = p + Vector2(cos(a), sin(a)) * float(P["two_offset"])
		"tavern":
			# Meta cumulativa: 1, 2 e 3 casas no chão.
			contest["progress"] = float(_houses_down(loc))
			if var_ == "guarded":
				for h in loc["houses"]:
					if float(h["hp"]) > 0.0:
						h["max_hp"] = float(h["max_hp"]) * float(P["guarded_hp"])
						h["hp"] = float(h["hp"]) * float(P["guarded_hp"])
		"bridge":
			hero.tavern_t = contest["window"]
		"fountain":
			if var_ == "quick":
				contest["window"] = float(contest["window"]) * float(P["quick_mult"])
			hero.drink_t = contest["window"]
	emit(K.Ev.CONTEST, p.x, p.y, int(contest["li"]), 2)


func _houses_down(loc: Dictionary) -> int:
	var down := 0
	for h in loc["houses"]:
		if float(h["hp"]) <= 0.0:
			down += 1
	return down


## Quantos marcos a barra já passou (0 a 3).
func marks_reached() -> int:
	var n := 0
	for m in contest["marks"]:
		if float(contest["progress"]) + 0.0001 >= float(m):
			n += 1
	return n


func _contest_tick() -> void:
	if contest.is_empty():
		return
	if str(contest["type"]) == "helper":
		_helper_tick()
		return
	var loc: Dictionary = road.locations[int(contest["li"])]
	var p: Vector2 = loc["pos"]
	var P: Dictionary = R["locations"][str(contest["type"])]
	var var_: String = contest["variant"]
	contest["t"] += dt
	match str(contest["type"]):
		"ritual":
			ritual_mult = float(P["elixir_mult"])
			if var_ == "expel":
				_expel(p, float(contest["r"]), float(P["expel_s"]))
		"shrine":
			var ok := units.any_fighter_within(p.x, p.y, float(contest["r"]))
			if contest.has("p2"):
				var p2: Vector2 = contest["p2"]
				ok = ok and units.any_fighter_within(p2.x, p2.y, float(contest["r"]))
			if ok:
				contest["progress"] += dt
		"tavern":
			if var_ == "repair":
				for h in loc["houses"]:
					if float(h["hp"]) > 0.0:
						h["hp"] = minf(float(h["max_hp"]), float(h["hp"]) + float(h["max_hp"]) * float(P["repair_per_s"]) * dt)
			contest["progress"] = float(_houses_down(loc))
		"bridge":
			if var_ == "heal":
				hero.heal(hero.max_hp() * float(P["heal_per_s"]) * dt)
		"fountain":
			# Medo, raiz, empurrão ou petrificação durante o gole interrompem na hora: a barra enche inteira.
			if hero.fear_t > 0.0 or hero.root_t > 0.0 or hero.kb_t > 0.0 or hero.petrify_t > 0.0:
				contest["progress"] = contest["goal"]
	var n := marks_reached()
	if n > int(contest["won"]):
		contest["won"] = n
		emit(K.Ev.CONTEST, p.x, p.y, int(contest["li"]), 1 + n)   # 2 = barra aberta; 3, 4 e 5 = marco 1, 2 e 3
	if n >= contest["marks"].size() or float(contest["t"]) >= float(contest["window"]):
		_resolve_contest(n)


## Ritual, 3ª etapa do ato 3: quem fica mais de `secs` s no círculo é jogado para fora pelo herói.
func _expel(p: Vector2, r: float, secs: float) -> void:
	var inside: Dictionary = contest["inside"]
	for i in units.hi:
		if units.alive[i] == 0 or units.arch[i] == K.Arch.STRUCTURE:
			continue
		var v := Vector2(units.px[i] - p.x, units.py[i] - p.y)
		var u := int(units.uid[i]) * 4096 + i
		if v.length() > r:
			inside.erase(u)
			continue
		inside[u] = float(inside.get(u, 0.0)) + dt
		if float(inside[u]) > secs:
			inside.erase(u)
			var d := v.normalized() if v.length() > 0.01 else Vector2(1, 0)
			var q := p + d * (r + 1.5)
			units.px[i] = q.x
			units.py[i] = q.y
			units.ox[i] = q.x
			units.oy[i] = q.y


## Fim da disputa (12/11/2026): 0 marcos = nada; cada marco alcançado = 1 recompensa do local (ver _offer_marks);
## os 3 = local vencido (ouro, elixir, Marca da Vitória e, na disputa difícil, uma relíquia).
func _resolve_contest(won_n: int) -> void:
	var c := contest
	contest = {}
	var won := won_n >= 3
	var li := int(c["li"])
	var loc: Dictionary = road.locations[li]
	var ty: String = c["type"]
	var p: Vector2 = loc["pos"]
	loc["state"] = SimRoad.LocState.WON if won else SimRoad.LocState.USED
	hero.hold = false
	hero.drink_t = 0.0
	hero.tavern_t = 0.0
	_remove_helper()   # o guarda da Fonte vai embora com a disputa
	var cs: Dictionary = stats["contests"]
	var row: Array = cs.get(ty, [0, 0])
	row[0 if won else 1] += 1
	cs[ty] = row
	var sw: Dictionary = stats.get("stages_won", {})
	sw[str(won_n)] = int(sw.get(str(won_n), 0)) + 1
	stats["stages_won"] = sw
	if ty == "shrine":
		stats["shrines_won" if won else "shrines_lost"] += 1
		emit(K.Ev.SHRINE, p.x, p.y, 1 if won else 0, li)
	emit(K.Ev.CONTEST, p.x, p.y, li, 1 if won else (-1 if won_n <= 0 else 10 + won_n))
	if won_n <= 0:
		stats["locs_lost"] += 1
		if ty == "fountain":
			hero.heal(hero.max_hp() * float(R["locations"]["fountain"]["heal"]))   # terminou o gole sem ser interrompido
		return
	_offer_marks(ty, won_n)
	if not won:
		stats["locs_lost"] += 1
		return
	elixir = minf(elixir_max, elixir + rv("contest_elixir"))
	if rv("contest_max_gain") > 0.0 and victory_gain < rv("contest_max_cap"):
		var g := minf(rv("contest_max_gain"), rv("contest_max_cap") - victory_gain)
		victory_gain += g
		relic_max_gain += g
		recalc_elixir_max()
	# Disputa difícil (caveira no mapa): os 3 marcos dão também 1 de 3 relíquias, depois das recompensas.
	if loc.get("hard", false):
		stats["hard_won"] = int(stats.get("hard_won", 0)) + 1
		offer_relic_choice("hard")


# ---------------------------------------------------------------- Herói Ajudante (11/11/2026, rascunho D)

## Chegou ao Herói Ajudante: outro herói (classe sorteada, diferente da do herói da vez) já está parado no
## local. O herói da vez para e briga ali; o jogador tem `window` s para matar o ajudante.
func _start_helper(li: int) -> void:
	var loc: Dictionary = road.locations[li]
	var P: Dictionary = R["locations"]["helper"]
	var pool: Array = []
	for c in P["classes"]:
		if str(c) != hero.cls():
			pool.append(str(c))
	if pool.is_empty():
		pool = P["classes"].duplicate()
	var cls: String = pool[rng.randi_range(0, pool.size() - 1)]
	var hpa: Array = P["hp_act"]
	var hp0 := float(hpa[mini(act, hpa.size() - 1)])
	var p: Vector2 = loc["pos"]
	var stand := helper_spot(li)
	helper = SimHero.new()
	helper.init_helper(self, cls, hp0, stand, party_idx + 1, hero.seg)
	var fv := (p - stand).normalized()
	helper.face_x = fv.x
	helper.face_y = fv.y
	contest = {"li": li, "type": "helper", "marks": [hp0], "won": 0, "t": 0.0, "progress": 0.0, "goal": hp0,
		"window": float(P["window"]) * (1.0 + rv("contest_window")), "variant": "", "r": float(loc["r"]), "cls": cls}
	hero.hold = true
	hero.hold_x = p.x
	hero.hold_y = p.y
	emit(K.Ev.CONTEST, p.x, p.y, li, 0)


## Onde o Herói Ajudante fica: ao lado da estrada, a `stand_offset` m do centro do local (o lado do acampamento).
func helper_spot(li: int) -> Vector2:
	var loc: Dictionary = road.locations[li]
	var pts: PackedVector2Array = road.legs[int(loc["leg"])]["pts"][0]
	var dir := (pts[pts.size() - 1] - pts[maxi(0, pts.size() - 3)]).normalized()
	if dir.length() < 0.1:
		dir = Vector2(0, -1)
	return Vector2(loc["pos"]) - dir.orthogonal() * float(R["locations"]["helper"].get("stand_offset", 5.5))


func _helper_tick() -> void:
	contest["t"] += dt
	if helper == null:
		_resolve_helper(false)   # run carregada sem o ajudante: conta como falha
		return
	contest["progress"] = clampf(float(contest["goal"]) - helper.hp, 0.0, float(contest["goal"]))
	if helper.hp <= 0.0:
		_resolve_helper(true)
	elif float(contest["t"]) >= float(contest["window"]):
		_resolve_helper(false)


## Fim da disputa do ajudante. Matou: 1 de 3 relíquias. Falhou: bônus da classe ao herói da vez e ele vai embora.
## Nunca conta como herói do grupo caído (sem queda, sem nível, sem cena).
func _resolve_helper(won: bool) -> void:
	var c := contest
	contest = {}
	var li := int(c["li"])
	var loc: Dictionary = road.locations[li]
	var p: Vector2 = loc["pos"]
	loc["state"] = SimRoad.LocState.WON if won else SimRoad.LocState.USED
	loc["helper_cls"] = str(c.get("cls", ""))
	hero.hold = false
	var cs: Dictionary = stats["contests"]
	var row: Array = cs.get("helper", [0, 0])
	row[0 if won else 1] += 1
	cs["helper"] = row
	stats["locs_won" if won else "locs_lost"] += 1
	_remove_helper()
	emit(K.Ev.CONTEST, p.x, p.y, li, 1 if won else -1)
	if not won:
		return   # 12/11/2026: sem bônus de classe; o ajudante só dá algo se você o matar
	elixir = minf(elixir_max, elixir + rv("contest_elixir"))
	var n0 := offers.size()
	offer_relic_choice("helper")
	if offers.size() > n0:
		offers[-1]["from"] = "helper"


func _remove_helper() -> void:
	if helper == null:
		return
	if cstate.has("plague") and cstate["plague"].has("peste"):
		cstate["plague"]["peste"].erase(str(helper.pidx))
	if hit_hero == helper:
		hit_hero = null
	helper = null


## Santuário em disputa: o herói está abençoado (não leva dano) e bate mais forte em quem está no círculo.
func hero_blessed() -> bool:
	return not contest.is_empty() and str(contest.get("type", "")) == "shrine"


## O ponto (x, y) está dentro de um círculo do Santuário em disputa.
func in_shrine_circle(x: float, y: float) -> bool:
	if not hero_blessed() or not contest.has("li"):
		return false
	var r := float(contest["r"])
	var p: Vector2 = road.locations[int(contest["li"])]["pos"]
	if Vector2(x, y).distance_to(p) <= r:
		return true
	return contest.has("p2") and Vector2(x, y).distance_to(contest["p2"]) <= r


func _burn() -> void:
	for f in (followers + [helper] if helper else followers):
		if f.burn_t > 0.0:
			f.burn_t -= dt
			hit_hero = f
			damage_hero(f.burn_dps * dt, f.x, f.y, K.TAG_FIRE, SimHero.DMG_AREA, "torch")
			hit_hero = null
	if burn_t <= 0.0:
		return
	burn_t -= dt
	damage_hero(burn_dps * dt, hero.x, hero.y, K.TAG_FIRE, SimHero.DMG_AREA, burn_src)


func _own_units_near(x: float, y: float, r: float) -> bool:
	return units.any_within(x, y, r)


## Monstro seu acertou a casa k da Taverna em disputa.
func damage_house(k: int, dmg: float) -> void:
	if contest.is_empty() or contest["type"] != "tavern":
		return
	var loc: Dictionary = road.locations[int(contest["li"])]
	var h: Dictionary = loc["houses"][k]
	if float(h["hp"]) <= 0.0:
		return
	h["hp"] = float(h["hp"]) - dmg
	if float(h["hp"]) <= 0.0:
		h["hp"] = 0.0
		emit(K.Ev.EXPLOSION, h["x"], h["y"], 3.0, 2)


## Casas vivas da Taverna em disputa (para as unidades e o herói); vazio fora dela.
func live_houses() -> Array:
	if contest.is_empty() or contest["type"] != "tavern":
		return []
	var out: Array = []
	var hs: Array = road.locations[int(contest["li"])]["houses"]
	for k in hs.size():
		if float(hs[k]["hp"]) > 0.0:
			out.append(k)
	return out


func house_pos(k: int) -> Vector2:
	var h: Dictionary = road.locations[int(contest["li"])]["houses"][k]
	return Vector2(h["x"], h["y"])


# ================================================================ atos

## O herói chegou ao fim do ato: uma carta (3 opções, mais chance de rara e de já melhorada), a relíquia e, depois delas, o próximo ato (ou a arena).
func _end_act() -> void:
	act_pending = true
	route_wait = false
	stats["act_t"].append(t)
	hero.hold = false
	hero.target_kind = SimHero.TGT_NONE
	if act + 1 < acts():
		for i in units.hi:
			if units.alive[i] == 1:
				kill_unit(i, K.Death.EXPIRE)
		zones.clear()
	emit(K.Ev.ACT_END, hero.x, hero.y, act, 0)
	_offer_act_card()
	offer_relic_choice("act")


func _next_act() -> void:
	act_pending = false
	if rv("act_full_elixir") > 0.0:
		elixir = elixir_max
	if act + 1 >= acts():
		enter_arena()
		return
	act += 1
	recalc_elixir_max()   # piso de elixir do novo ato (maior máximo e regen)
	act_elixir_bonus = 0.0
	hero.clear_act_bonus()   # bônus do Herói Ajudante valem só o ato
	recalc_elixir_max()
	if rv("act_gold") > 0.0:
		_earn_gold(rv("act_gold"))   # Tesouro de Ato
	stats["route_len"] = float(stats.get("route_len", 0.0)) + road.length()
	road = SimRoad.new()
	road.generate(rng, R, _act_cfg(act))
	var p0: Vector2 = road.route[0]
	hero.x = p0.x
	hero.y = p0.y
	hero.ox = p0.x
	hero.oy = p0.y
	hero.s = 0.0
	hero.s_max = 0.0
	hero.seg = 0
	hero.face_x = 0.0
	hero.face_y = -1.0
	regroup()
	emit(K.Ev.ACT_START, p0.x, p0.y, act, 0)


# ================================================================ relíquias

func rv(key: String) -> float:
	return float(rfx.get(key, 0.0))


func rebuild_rfx() -> void:
	rfx = {}
	for id in relics:
		var r: Dictionary = data.relics.get(id, {})
		for k in r.get("fx", {}):
			rfx[k] = float(rfx.get(k, 0.0)) + float(r["fx"][k])


## Ganha a relíquia. Relíquias empilham (11/11/2026): a mesma pode vir de novo e os efeitos somam, menos as
## marcadas "unique" em data/relics.json (efeitos que não fazem sentido em dobro). Efeitos "ao pegar" rodam aqui.
func gain_relic(id: String) -> void:
	if not data.relics.has(id) or (relics.has(id) and data.relics[id].get("unique", false)):
		return
	relics.append(id)
	stats["relics"].append(id)
	var fx: Dictionary = data.relics[id].get("fx", {})
	hand_size = clampi(hand_size + int(fx.get("hand", 0)), 1, HAND_MAX)
	rebuild_rfx()
	recalc_elixir_max()
	_refill_hand()
	_relic_pickup(fx)
	emit(K.Ev.RELIC, hero.x, hero.y, data.relic_ids.find(id), 0)


## Efeitos de uma vez, na hora em que a relíquia é pega (Martelo da Forja, Lima do Funileiro, Dízimo de
## Sangue, Piche, Tinta de Carimbo).
func _relic_pickup(fx: Dictionary) -> void:
	var mx := int(R["card_levels"]["max"])
	for k in int(fx.get("pickup_upgrade", 0)):
		var cand: Array = cards.filter(func(ci): return ci.level < mx)
		if cand.is_empty():
			break
		cand[rng.randi_range(0, cand.size() - 1)].level += 1
	var picked: Array = []
	for k in int(fx.get("pickup_discount", 0)):
		# Nunca uma carta de custo 0. Usa o modificador Barata quando a carta ainda não tem e cai de custo com
		# ele (custo 2+); senão, desconto permanente de 1 na cópia.
		var cand: Array = cards.filter(func(ci): return not picked.has(ci) and ci.def.cost_at(ci.level) - ci.discount > 0)
		if cand.is_empty():
			break
		var ci: CardInst = cand[rng.randi_range(0, cand.size() - 1)]
		picked.append(ci)
		if not ci.has_mod(K.M_CHEAP) and ci.def.cost_at(ci.level) >= 1:
			if ci.mods == 0:
				ci.first_mod = K.M_CHEAP
			ci.mods |= K.M_CHEAP
		else:
			ci.discount += 1
	if float(fx.get("pickup_hero_dmg", 0.0)) > 0.0 and phase != K.Phase.OVER:
		hero.hp = maxf(1.0, hero.hp - hero.max_hp() * float(fx["pickup_hero_dmg"]))
		emit(K.Ev.DAMAGE_HERO, hero.x, hero.y, hero.max_hp() * float(fx["pickup_hero_dmg"]), 0)
	if float(fx.get("hero_slow", 0.0)) > 0.0:
		slow_hero = hero.pidx
	var ex: Array = []
	for k in int(fx.get("pickup_mods", 0)):
		var m := _mod_option(ex)
		if m.is_empty():
			break
		ex.append(str(m["uid"]) + str(m["mod"]))
		_apply_option(m)


## Piche: o herói marcado anda mais devagar até cair (o seguinte vem normal).
func hero_speed_mult(h: SimHero) -> float:
	var m := 1.0
	if slow_hero >= 0 and h.pidx == slow_hero:
		m = maxf(0.1, 1.0 - rv("hero_slow"))
	return maxf(0.1, m * (1.0 - temp_sum("hero_slow")))   # Fosso Inundado (Temporário): todos os heróis mais lentos


func _relic_pool() -> Array:
	var pool: Array = []
	for id in data.relic_ids:
		var r: Dictionary = data.relics[id]
		if _owner_ok(r) and float(r.get("weight", 1.0)) > 0.0 and not (relics.has(id) and r.get("unique", false)):
			pool.append(id)
	return pool


## Relíquia ou evento deste vilão ou comum.
func _owner_ok(x: Dictionary) -> bool:
	var o := str(x.get("owner", "common"))
	return o == "common" or o == deck_id


## Sorteio de uma relíquia do pool pelo peso (data/relics.json "weight", padrão 1).
func _pick_relic(pool: Array) -> String:
	var tot := 0.0
	for id in pool:
		tot += float(data.relics[id].get("weight", 1.0))
	var r := rng.randf() * tot
	for id in pool:
		r -= float(data.relics[id].get("weight", 1.0))
		if r <= 0.0:
			return id
	return pool[pool.size() - 1]


## Oferta de 1 entre N relíquias (fim de ato, disputa difícil, herói ajudante...). `source` só vai para a
## oferta e as métricas (stats.relic_src). Ponto de entrada para outras fontes de relíquia.
func offer_relic_choice(source := "relic") -> void:
	var src: Dictionary = stats.get("relic_src", {})
	src[source] = int(src.get(source, 0)) + 1
	stats["relic_src"] = src
	_offer_relics(source)


func _offer_relics(source := "act") -> void:
	var pool := _relic_pool()
	var opts: Array = []
	var want := int(R.get("relics", {}).get("options", 3)) + int(rv("relic_options"))
	# Raridade única por oferta (10/11/2026): a raridade vem de uma relíquia sorteada do que resta; se ela não
	# tem opções suficientes, a oferta inteira vai para a raridade com mais opções (a mais próxima no empate).
	if pool.size() > 0:
		var by := {}
		for id in pool:
			var rr := K.RARITIES.find(str(data.relics[id].get("rarity", "common")))
			if not by.has(rr):
				by[rr] = []
			by[rr].append(id)
		var r0 := K.RARITIES.find(str(data.relics[_pick_relic(pool)].get("rarity", "common")))
		var best: int = r0
		if by[r0].size() < want:
			for dr in [-1, 1, -2, 2, -3, 3]:
				var r2: int = r0 + dr
				if by.has(r2) and by[r2].size() > by[best].size():
					best = r2
		pool = by[best]
		if source == "act":
			# Uma oferta de fim de ato sempre traz relíquia de elixir (13/11/2026), na raridade sorteada.
			# Só as que DÃO elixir (15/11/2026): Grimório Pesado, Mão do Enforcado e Lasca de Gelo tiram e não contam.
			var elx: Array = pool.filter(func(rid): return float(data.relics[rid]["fx"].get("elixir_max", 0.0)) > 0.0 or float(data.relics[rid]["fx"].get("elixir_regen", 0.0)) > 0.0)
			if elx.size() > 0:
				var pick := _pick_relic(elx)
				pool.erase(pick)
				opts.append({"kind": "relic", "id": pick})
				want -= 1
	for k in want:
		if pool.is_empty():
			break
		var id := _pick_relic(pool)
		pool.erase(id)
		opts.append({"kind": "relic", "id": id})
	_push_offer("relic", opts, {"act": act, "relic_src": source})


## Uma relíquia sorteada direto (eventos de texto).
func random_relic() -> void:
	var pool := _relic_pool()
	if pool.size() > 0:
		var src: Dictionary = stats.get("relic_src", {})
		src["event"] = int(src.get("event", 0)) + 1
		stats["relic_src"] = src
		gain_relic(_pick_relic(pool))


func teleport_cost() -> float:
	return maxf(0.0, float(R["arena"]["teleport_cost"]) + rv("teleport_cost"))


func cc_mult() -> float:
	return 1.0 + rv("cc")


## Uma habilidade do herói disparou (aviso no visual); Olho Vigilante: a próxima carta em até N s sai de graça.
func ability_fired(id: String) -> void:
	emit(K.Ev.ABILITY, hero.x, hero.y, float(hero.ability_index(id)), 0)
	if rv("free_after_ability") > 0.0:
		free_card_t = t + rv("free_after_ability")


func free_card_active() -> bool:
	return t <= free_card_t


## Dragão (Tesouro do Dragão): +X% de dano de fogo a cada `hoard_step` de ouro guardado, até o teto.
func hoard_fire() -> float:
	var step_ := float(deck_rules.get("hoard_step", 0.0))
	if step_ <= 0.0:
		return 0.0
	return minf(float(deck_rules.get("hoard_fire_max", 0.0)), floorf(gold / step_) * float(deck_rules.get("hoard_fire", 0.0)))


# ================================================================ eventos de texto

func _offer_event() -> void:
	var pool: Array = []
	for id in data.event_ids:
		if not events_seen.has(id) and _owner_ok(data.events_def[id]):
			pool.append(id)
	if pool.is_empty():
		pool = data.event_ids.filter(func(e): return _owner_ok(data.events_def[e]))
	if pool.is_empty():
		return
	var id: String = pool[rng.randi_range(0, pool.size() - 1)]
	if force_event != "" and data.events_def.has(force_event):
		id = force_event
	events_seen.append(id)
	var opts: Array = []
	var ev: Dictionary = data.events_def[id]
	for k in ev["options"].size():
		opts.append({"kind": "event_opt", "event": id, "opt": k})
	_push_offer("event", opts, {"event": id})


func event_option_ok(op: Dictionary) -> bool:
	var o: Dictionary = data.events_def[op["event"]]["options"][int(op["opt"])]
	return gold + 0.0001 >= float(o.get("requires", {}).get("gold", 0))


func enter_arena() -> void:
	phase = K.Phase.ARENA
	stats["arena_t"] = t
	stats["hero_level_arena"] = hero.level
	stats["player_level_arena"] = player_level
	# Métrica da calibração de 11/11/2026: poder de elixir ao fim do ato 3 (meta 18 de máximo e 1,5 s por ponto).
	stats["elixir_max_arena"] = perm_elixir_max()
	stats["spp_arena"] = seconds_per_elixir()
	stats["route_len"] = float(stats.get("route_len", 0.0)) + road.length()
	var A: Dictionary = R["arena"]
	var dir := road.lair_dir
	var gate := Vector2(hero.x, hero.y)
	gate_pos = gate
	var center := gate + dir * (float(A["radius"]) - 1.5)
	arena.setup(self, center, dir)
	if boss_hp_mult != 1.0:
		for k in arena.part_hp.size():
			arena.part_max[k] *= boss_hp_mult
			arena.part_hp[k] = arena.part_max[k]
	# Monstros vivos perto do herói entram junto; o resto fica para trás.
	for i in units.hi:
		if units.alive[i] == 0:
			continue
		var v := Vector2(units.px[i] - gate.x, units.py[i] - gate.y)
		if v.length() > 25.0 or units.arch[i] == K.Arch.STRUCTURE:
			kill_unit(i, K.Death.EXPIRE)
			continue
		var p := gate + dir * 3.0 + v.limit_length(10.0)
		units.px[i] = p.x
		units.py[i] = p.y
		units.ox[i] = p.x
		units.oy[i] = p.y
	zones.clear()
	_bench_route_cards()
	hero.target_kind = SimHero.TGT_NONE
	stats["hero_hp_arena"] = hero.hp_frac()
	emit(K.Ev.ARENA, center.x, center.y, 0, 0)


## Cartas de Rota não servem na arena: saem da mão, da compra e do descarte até o fim da run. A mão repõe com o
## que sobrar (baralho menor que a mão = mão menor).
func _bench_route_cards() -> void:
	for arr in [queue, discard]:
		for ci in arr.duplicate():
			if ci.def.category == "route":
				arr.erase(ci)
				benched.append(ci)
	for i in range(hand.size() - 1, -1, -1):
		if hand[i] and hand[i].def.category == "route":
			benched.append(hand[i])
			_hand_remove(i)
	_refill_hand()


## Prorrogação da arena (10/11/2026): minutos passados de overtime_s na arena (0 antes). Na prorrogação a
## cura do herói para, o golpe dele cresce e o elixir do covil vem mais rápido: um empate na arena acaba.
func overtime() -> float:
	if phase != K.Phase.ARENA or float(stats.get("arena_t", -1.0)) < 0.0:
		return 0.0
	return maxf(0.0, (t - float(stats["arena_t"]) - float(R["arena"].get("overtime_s", 1e9))) / 60.0)


func core_destroyed() -> void:
	_finish(K.Result.LOSS)


func _check_end() -> void:
	if phase == K.Phase.OVER:
		return
	if group_mode():
		_group_check()
		return
	if party_mode():
		_party_check()
		return
	if hero.hp <= 0.0:
		if party_idx < party_size() - 1:
			_hero_fell()
		else:
			stats["heroes_fallen"] = party_idx + 1
			_finish(K.Result.WIN_EARLY if phase == K.Phase.ROAD else K.Result.WIN)
	elif t >= float(R["sim"]["max_run_seconds"]):
		_finish(K.Result.TIMEOUT)


func group_mode() -> bool:
	return bool(phase_cfg.get("group", false))


## Fase de grupo: cada queda traz o próximo da fila, que levanta o caído (uma vez por herói, com revive_hp da vida).
func _group_check() -> void:
	var k := followers.size() - 1
	while k >= 0:
		var f: SimHero = followers[k]
		if f.hp <= 0.0:
			followers.remove_at(k)
			group_falls += 1
			stats["heroes_fallen"] = group_falls
			emit(K.Ev.HERO_FALL, f.x, f.y, f.pidx + 1, 1)
			if party_idx < party_size() - 1:
				party_idx += 1
				var nf := SimHero.new()
				nf.init_follower(self, party_idx, hero, 1.0)
				followers.append(nf)
				_revive(f)
				emit(K.Ev.HERO_LEVEL, nf.x, nf.y, nf.level, 1)
				_offer_level()
		k -= 1
	if hero.hp > 0.0:
		if t >= float(R["sim"]["max_run_seconds"]):
			_finish(K.Result.TIMEOUT)
		return
	var fallen := SimHero.new()
	fallen.init_follower(self, hero.pidx, hero, 0.0)
	fallen.x = hero.x
	fallen.y = hero.y
	group_falls += 1
	if party_idx < party_size() - 1:
		_hero_fell()
		stats["heroes_fallen"] = group_falls
		_revive(fallen)
	elif followers.size() > 0:
		stats["heroes_fallen"] = group_falls
		emit(K.Ev.HERO_FALL, hero.x, hero.y, hero.pidx + 1, 0)
		var f: SimHero = followers.pop_front()
		hero.take_over(f)
		emit(K.Ev.HERO_LEVEL, hero.x, hero.y, hero.level, 0)
	else:
		stats["heroes_fallen"] = group_falls
		_finish(K.Result.WIN_EARLY if phase == K.Phase.ROAD else K.Result.WIN)


## Fila de parties (15/11/2026): os membros da party andam juntos; cada um que cai conta como uma queda
## (recompensa e habilidade nova para quem ficou). Quando o último cai, a party seguinte chega inteira.
func _party_check() -> void:
	var k := followers.size() - 1
	while k >= 0:
		var f: SimHero = followers[k]
		if f.hp <= 0.0:
			followers.remove_at(k)
			_member_down(f.pidx, f.x, f.y, 1)
		k -= 1
	if hero.hp <= 0.0:
		if followers.size() > 0:
			# O líder caiu: o membro seguinte assume o lugar dele, com a vida que tinha.
			var fx := hero.x
			var fy := hero.y
			var fp := hero.pidx
			var f: SimHero = followers.pop_front()
			hero.take_over(f)
			_member_down(fp, fx, fy, 0)
		elif cur_party < party_count() - 1:
			_hero_fell()   # party inteira no chão: chega a seguinte (inclui a recompensa da última queda)
		else:
			group_falls += 1
			stats["heroes_fallen"] = group_falls
			emit(K.Ev.HERO_FALL, hero.x, hero.y, group_falls, 0)
			_finish(K.Result.WIN_EARLY if phase == K.Phase.ROAD else K.Result.WIN)
	elif t >= float(R["sim"]["max_run_seconds"]):
		_finish(K.Result.TIMEOUT)


## Um membro da party caiu e ainda sobra gente: conta a queda, a bênção da Clériga vai para a party seguinte
## e quem ficou aprende uma habilidade e escolhe uma recompensa.
func _member_down(pidx_: int, x_: float, y_: float, e: int) -> void:
	track.on_hero_fall(self)
	group_falls += 1
	stats["heroes_fallen"] = group_falls
	if pidx_ == slow_hero:
		slow_hero = -1
	var cls_ := party_class(pidx_)
	var bless: float = float(data.hero_classes.get(cls_, {}).get("bless_next", 0.0))
	if bless > 0.0:
		next_hp_mult *= 1.0 + bless
	emit(K.Ev.HERO_FALL, x_, y_, group_falls, e)
	_learn_ability()
	emit(K.Ev.HERO_LEVEL, hero.x, hero.y, hero.level, 0)
	_offer_level()
	if rv("fall_mod_offer") > 0.0:
		var mo: Array = []
		var ex: Array = []
		for j in int(R["offers"]["options"]):
			var m := _mod_option(ex)
			if m.size() > 0:
				ex.append(str(m["uid"]) + str(m["mod"]))
				mo.append(m)
		_push_offer("level", mo)


## Habilidade nova do grupo: 3 sorteadas, vale a que melhor responde ao que mais feriu; todos de pé a recebem.
func _learn_ability() -> void:
	for extra in (2 if next_extra_ability else 1):
		var opts := _upgrade_options(3)
		if opts.size() > 0:
			var id := hero.choose_upgrade(opts)
			for hh in [hero] + followers:
				hh.apply_upgrade(id)
	next_extra_ability = false


func _revive(fallen: SimHero) -> void:
	if revived.has(fallen.pidx):
		return
	revived.append(fallen.pidx)
	var r := SimHero.new()
	r.init_follower(self, fallen.pidx, hero, float(phase_cfg.get("revive_hp", 0.5)))
	r.x = fallen.x
	r.y = fallen.y
	r.ox = r.x
	r.oy = r.y
	followers.append(r)
	emit(K.Ev.HEAL, r.x, r.y, r.hp, 1)


## Seguidor fica perto do herói da vez: pode sair para bater num monstro, mas volta para o lugar dele no grupo.
func _follow(f: SimHero) -> void:
	var a := float(f.pidx) * 2.4
	var goal := Vector2(hero.x + cos(a) * 3.6, hero.y + sin(a) * 3.6)
	var p := Vector2(f.x, f.y)
	var d := p.distance_to(goal)
	var free_r := 7.0 if f.target_kind == SimHero.TGT_UNIT else 2.5
	# Preso (teia, piche, prisão, petrificado) não anda; na teia anda devagar (10/11/2026).
	var stuck := f.root_t > 0.0 or f.petrify_t > 0.0
	if d > free_r and (not stuck or d > 25.0):
		var step_ := minf(d - free_r * 0.5, float(f.H["speed"]) * 1.6 * dt * (0.5 if f.slow_t > 0.0 else 1.0))
		if d > 25.0:
			step_ = d - 2.0   # muito longe (troca de ato, portão da arena): reaparece junto do grupo
		var v := (goal - p).normalized() * step_
		f.x += v.x
		f.y += v.y
		f.face_x = v.normalized().x
		f.face_y = v.normalized().y
	f.s = hero.s
	f.s_max = hero.s_max
	f.seg = hero.seg


## Põe os seguidores em volta do herói da vez (ato novo, arena).
func regroup() -> void:
	for f in followers:
		var a := float(f.pidx) * 2.4
		f.x = hero.x + cos(a) * 3.6
		f.y = hero.y + sin(a) * 3.6
		f.ox = f.x
		f.oy = f.y


## Heróis de pé a até r m de (x, y), contando o raio do corpo, do mais perto ao mais longe.
func heroes_near(x: float, y: float, r: float) -> Array:
	var out: Array = []
	for hh in all_heroes():
		if Vector2(hh.x - x, hh.y - y).length() <= r + hh.radius:
			out.append(hh)
	out.sort_custom(func(a, b): return Vector2(a.x - x, a.y - y).length_squared() < Vector2(b.x - x, b.y - y).length_squared())
	return out


## Feitiço de área no grupo: dano inteiro no herói mais perto, metade nos outros.
func splash_mult(k: int) -> float:
	return 1.0 if k == 0 else float(R.get("group_spell_splash", 0.5))


## Mais de um herói em campo (fase de grupo ou Herói Ajudante): feitiços de "o mais perto" escolhem o alvo.
func multi_heroes() -> bool:
	return group_mode() or party_mode() or helper != null


## Todos os heróis de pé (o da vez primeiro).
func all_heroes() -> Array:
	return [hero] + followers + ([helper] if helper else [])


func _finish(r: int) -> void:
	if phase == K.Phase.OVER:
		return
	result = r
	phase = K.Phase.OVER
	stats["result"] = K.RESULT_NAMES[r]
	stats["t_end"] = t
	stats["gold_end"] = gold
	stats["hero_level"] = hero.level
	stats["player_level"] = player_level
	stats["upgrades"] = hero.upgrade_order.duplicate()
	stats["waste_frac"] = stats["waste_s"] / maxf(t, 1.0)
	var fin: Array = []
	var lv := 0
	for c in cards:
		fin.append(c.def.id)
		lv += c.level - 1
	stats["deck_final"] = fin
	stats["card_levels"] = lv
	stats["ticks"] = tick


# ================================================================ dano e mortes

func damage_hero(amount: float, sx: float, sy: float, tags: int, kind: int, card_id: String) -> float:
	if hero_blessed():
		return 0.0   # herói abençoado no Santuário: sem dano (a graça é o herói defender, não ficar apanhando)
	if tags & K.TAG_FIRE:
		amount *= 1.0 + hoard_fire()
	var hh0: SimHero = hit_hero if hit_hero else hero
	amount *= 1.0 + CardsCommon.hero_damage_bonus(self, hh0, tags, kind) + CardsPlague.hero_damage_bonus(self, hh0, tags, kind) \
		+ CardsDragon.hero_damage_bonus(self, hh0, tags, kind) + CardsLich.hero_damage_bonus(self, hh0, tags, kind)
	if (kind & SimHero.DMG_SPELL) and t < mark_until:
		amount *= 1.0 + mark_bonus
	var hh: SimHero = hit_hero if hit_hero else hero
	var real := hh.take_damage(amount, sx, sy, tags, kind)
	var gain := real
	gain += hh.last_absorbed
	if gain <= 0.0:
		return 0.0
	if real > 0.0:
		emit(K.Ev.DAMAGE_HERO, hh.x, hh.y, real, tags)
	if hh == helper:
		return real   # Herói Ajudante: o dano só conta para a disputa (sem ouro nem estatística de carta)
	if contest.size() > 0 and contest["type"] in ["bridge", "fountain"]:
		var pm := float(R["locations"]["bridge"]["shield_mult"]) if contest.get("variant", "") == "shield" else 1.0
		contest["progress"] += real * pm
	track.on_hero_damage(self, real)
	_earn_gold(gain / float(R["gold"]["damage_per_gold"]) * (1.0 + rv("gold")))
	var dbc: Dictionary = stats["dmg_by_card"]
	dbc[card_id] = float(dbc.get(card_id, 0.0)) + gain
	return real


func _player_next() -> float:
	return 1.0   # sem XP do jogador (09/11/2026); resto de compatibilidade com a HUD antiga


func unit_hits_hero(i: int) -> void:
	var di := units.def[i]
	var c: CardDef = data.cards[di]
	var amount := units.dmg[i] * (1.0 + units.buff[i] + units.rage[i])
	if (units.tags[i] & K.TAG_PACK) and rv("pack_min") > 0.0 and units.n_pack >= int(rv("pack_min")):
		amount *= 1.0 + rv("pack_dmg")
	amount *= 1.0 + rv("unit_dmg")   # Estandarte Rasgado
	if c.fx.has("pack_bonus"):
		# Bando: mais forte quanto mais bicho de bando seu há em campo.
		amount *= 1.0 + minf(float(c.fx.get("pack_cap", 1.0)), float(c.fx["pack_bonus"]) * units.n_pack)
	if (units.tags[i] & K.TAG_PACK) and t < rally_until:
		amount *= 1.0 + rally_dmg
	if t < warcry_until:
		amount *= 1.0 + warcry_dmg
	if c.fx.has("alcateia"):
		# Alcateia (Selvagens): mais forte quanto mais Fera sua há em campo (só Fera; Bando não conta).
		amount *= 1.0 + minf(c.fxv("alcateia_cap", int(units.lvl[i]), 0.45), c.fx["alcateia"] * maxi(0, units.n_beast - 1))
	if c.fx.has("own_bonus"):
		# Besta Primordial: +X% por criatura sua em campo (Bando e Fera), até o teto.
		amount *= 1.0 + minf(c.fxv("own_cap", int(units.lvl[i]), 1.5), c.fxv("own_bonus", int(units.lvl[i])) * maxi(0, units.n_own - 1))
	if c.fx.has("death_stack"):
		amount *= 1.0 + float(c.fx["death_stack"]) * units.gen[i]
	var kind := 0
	var lv := int(units.lvl[i])
	var tg := units.tags[i]
	if units.flags[i] & K.F_PROJECTILE:
		kind = SimHero.DMG_PROJECTILE
		emit(K.Ev.SHOT, units.px[i], units.py[i], hero.x, int(hero.y * 100.0))
	if c.has_n3(lv, "pierce"):
		kind |= SimHero.DMG_PIERCE
	# Golpe no Herói Ajudante: empurrão, fogo e maldição vão nele, não no herói da vez.
	var on_helper := helper != null and hit_hero == helper
	if c.fx.has("burn_hit"):
		# Cão do Inferno: toda mordida queima (Encharcado dobra, como todo fogo).
		tg |= K.TAG_FIRE
		var bdps := c.fxv("burn_hit", lv)
		var bs := c.fxv("burn_s", lv, 3.0)
		if on_helper:
			helper.burn_t = maxf(helper.burn_t, bs)
			helper.burn_dps = maxf(helper.burn_dps, bdps)
		else:
			burn_t = maxf(burn_t, bs)
			burn_dps = maxf(burn_dps, bdps)
			burn_src = c.id
	if c.has_n3(lv, "burn_dps"):
		tg |= K.TAG_FIRE
		if on_helper:
			helper.burn_t = float(c.n3["burn_s"])
			helper.burn_dps = float(c.n3["burn_dps"])
		else:
			burn_t = float(c.n3["burn_s"])
			burn_dps = float(c.n3["burn_dps"])
			burn_src = "skeleton_archers"
	var src := str(card_of_uid.get(units.uid[i], c.id))
	amount *= CardsCommon.unit_hit_mult(self, i) * CardsPlague.unit_hit_mult(self, i) * CardsDragon.unit_hit_mult(self, i) * CardsLich.unit_hit_mult(self, i)
	var real := damage_hero(amount, units.px[i], units.py[i], tg, kind, src)
	CardsCommon.on_unit_hit(self, i, real)
	CardsPlague.on_unit_hit(self, i, real)
	CardsDragon.on_unit_hit(self, i, real)
	CardsLich.on_unit_hit(self, i, real)
	# Contadores das habilidades do herói: Enxame (unidade de uma carta de enxame) e alvos grandes.
	var oc: CardDef = data.card(src)
	if (oc if oc else c).type == "swarm":
		hero.note("swarm", real)
	if units.max_hp[i] >= float(data.upgrades["heroic_strike"]["p"]["big_hp"]):
		hero.note("big", real)
	var hk: SimHero = helper if on_helper else hero
	if di == units.d_ogre:
		hk.knockback(units.px[i], units.py[i], float(c.fx.get("knockback", 4.0)))
		if c.has_n3(lv, "root"):
			hk.root_t = maxf(hk.root_t, float(c.n3["root"]) * cc_mult())
	if (units.flags[i] & K.F_CURSED) and units.curse_t[i] <= 0.0:
		hk.add_curse(1)
		units.curse_t[i] = R["curse"]["cursed_mod_cooldown"]


func hero_hits_unit(i: int, dmg: float) -> void:
	if units.alive[i] == 0:
		return
	dmg *= CardsCommon.hero_out_mult(self) * CardsPlague.hero_out_mult(self) * CardsDragon.hero_out_mult(self) * CardsLich.hero_out_mult(self)
	if hero_blessed() and in_shrine_circle(units.px[i], units.py[i]):
		dmg *= 1.0 + float(R["locations"]["shrine"]["blessed_dmg"])
	if units.flags[i] & K.F_STONE:
		# Gárgula N3: em pedra, devolve parte do golpe.
		var gc: CardDef = data.cards[units.def[i]]
		if gc.has_n3(int(units.lvl[i]), "reflect"):
			damage_hero(dmg * float(gc.n3["reflect"]), units.px[i], units.py[i], gc.tags, SimHero.DMG_AREA, gc.id)
		return
	var rc: CardDef = data.cards[units.def[i]]
	if rc.fx.has("reflect"):
		# Armadura Vazia: devolve parte do golpe ao herói.
		damage_hero(dmg * rc.fxv("reflect", int(units.lvl[i])), units.px[i], units.py[i], rc.tags, SimHero.DMG_AREA, rc.id)
	units.hp[i] -= dmg
	emit(K.Ev.DAMAGE_UNIT, units.px[i], units.py[i], dmg, i)
	if units.hp[i] <= 0.0:
		kill_unit(i, K.Death.HERO)


func kill_unit(i: int, cause: int) -> void:
	if units.alive[i] == 0:
		return
	var di := units.def[i]
	var c: CardDef = data.cards[di]
	var x := units.px[i]
	var y := units.py[i]
	var f := units.flags[i]
	track.on_unit_death(self, i, cause)
	CardsCommon.on_unit_death(self, i, cause)
	CardsPlague.on_unit_death(self, i, cause)
	CardsDragon.on_unit_death(self, i, cause)
	CardsLich.on_unit_death(self, i, cause)
	if cause == K.Death.HERO or cause == K.Death.SELF:
		if cause == K.Death.HERO:
			stats["kills"] += 1
		if not (f & K.F_NO_XP):
			hero_gain_xp(units.xp[i])
		hero.soul_absorb_on_kill()
		if not (f & K.F_REVIVED) and c.id != "spectre":
			dead_by_def[di] += 1
		_death_in_contest(x, y, c, f)
	if cause != K.Death.EXPIRE and c.arch != K.Arch.STRUCTURE:
		_death_payoffs(i, x, y)
		_villain_on_death(c, x, y, f)
	if cause == K.Death.HERO or cause == K.Death.SELF:
		if f & K.F_EXPLOSIVE:
			var M: Dictionary = data.modifiers["explosive"]["p"]
			if Vector2(hero.x - x, hero.y - y).length() <= float(M["radius"]) + hero.radius:
				damage_hero(M["damage"], x, y, 0, 0, str(card_of_uid.get(units.uid[i], c.id)))
			emit(K.Ev.EXPLOSION, x, y, M["radius"], 0)
	if cause == K.Death.HERO:
		var split: Array = c.fx.get("split", [])
		var g := int(units.gen[i])
		if g < split.size():
			var s: Dictionary = split[g]
			var lv := int(units.lvl[i])
			var n := int(s["n"])
			if g == 0 and c.has_n3(lv, "first_split"):
				n = int(c.n3["first_split"])
			for k in n:
				var a := units.slot[i] + k * TAU / n
				var j := spawn_child(c, x + cos(a) * 0.6, y + sin(a) * 0.6, i)
				if j >= 0:
					units.gen[j] = g + 1
					units.hp[j] = float(s["hp"]) * _forge() * (c.mult(lv) if c.scales("hp") else 1.0)
					units.max_hp[j] = units.hp[j]
					units.dmg[j] = float(s["dps"]) * units.atk_int[j] * units.dmg_mult * (c.mult(lv) if c.scales("dps") else 1.0)
					units.rad[j] = c.radius * (0.75 if g == 0 else 0.55)
		if c.fx.has("death_spawn"):
			var sd: CardDef = data.card(str(c.fx["death_spawn"]))
			for k in int(c.fx.get("death_spawn_n", 0)):
				var a := TAU * k / float(c.fx["death_spawn_n"])
				spawn_child(sd, x + cos(a) * 1.0, y + sin(a) * 1.0, i)
		if c.arch != K.Arch.STRUCTURE and not (f & K.F_REVIVED):
			if not _golem_absorb(i, x, y) and not _relic_revive(i, x, y, c):
				_totem_revive(i, x, y)
	# Gatilho "ao morrer" declarado em dados (data/cards.json "on_death"; docs/CARD_FX.md).
	if not c.on_death.is_empty() and (cause == K.Death.HERO or cause == K.Death.SELF):
		CardFxLib.run(self, CardFxLib.unit_ctx(c, int(units.lvl[i]), units.uid[i]), c.on_death, x, y)
	emit(K.Ev.DEATH, x, y, di, i)
	units.release(i)


## Família Morte: Colheita de Almas devolve elixir; Carniçais por perto ficam mais fortes.
func _death_payoffs(i: int, x: float, y: float) -> void:
	if t < harvest_until:
		elixir = minf(elixir_max, elixir + harvest_elixir)
	for j in units.hi:
		if j == i or units.alive[j] == 0:
			continue
		var gc: CardDef = data.cards[units.def[j]]
		if gc.fx.has("death_stack") and units.gen[j] < int(gc.fx.get("stack_max", 10)):
			if Vector2(units.px[j] - x, units.py[j] - y).length_squared() <= pow(float(gc.fx.get("stack_radius", 6.0)), 2):
				units.gen[j] += 1


## Morte de um monstro seu (pelo herói ou explodindo): Ritual, Terra Profana e Coroa de Ossos.
## Passivas de morte dos vilões: Praga (Infestação) e Lich (Colheita).
func _villain_on_death(c: CardDef, x: float, y: float, uf := 0) -> void:
	var inf := float(deck_rules.get("infestation", 0.0))
	# Infestação (15/11/2026): qualquer monstro que morre tem `infestation` de chance de deixar um rato;
	# o rato deixado pela passiva (F_INFESTED) não gera outro.
	if inf > 0.0 and not (uf & K.F_INFESTED) and rng.randf() < inf:
		units.spawn(data.card("rat"), x, y, 0.0, 0.0, K.F_INFESTED, 0)
	if c.beast and deck_rules.has("wild_infestation"):
		# (legado) Fera que morre faz a próxima Fera custar menos; o Sangue acelera as hienas.
		CardsPlague.on_beast_death(self, c)
	if int(deck_rules.get("cycle", 0)) > 0 and c.arch != K.Arch.STRUCTURE:
		cycle_spell = true   # Ciclo de feitiço: criatura morta barateia o próximo feitiço
	var every := int(deck_rules.get("harvest_every", 0))
	if every > 0 and not harvest_free:
		harvest_deaths += 1
		if harvest_deaths >= every:
			harvest_deaths = 0
			harvest_free = true


func _death_in_contest(x: float, y: float, c: CardDef, f: int) -> void:
	if c.arch == K.Arch.STRUCTURE:
		return
	relic_deaths += 1
	var every := int(rv("death_elixir_every"))
	if every > 0 and relic_deaths % every == 0:
		elixir = minf(elixir_max, elixir + 1.0)
	if contest.is_empty():
		return
	var loc: Dictionary = road.locations[int(contest["li"])]
	var p: Vector2 = loc["pos"]
	if Vector2(x - p.x, y - p.y).length() > float(contest.get("r", loc["r"])):
		return
	if contest["type"] == "ritual":
		if contest.get("variant", "") != "cost3" or c.cost >= int(R["locations"]["ritual"]["cost3_min"]):
			contest["progress"] += 1.0
	if rv("loc_raise") > 0.0 and not (f & K.F_REVIVED) and rng.randf() < rv("loc_raise"):
		var sk: CardDef = data.card("skeleton_archers")
		units.spawn(sk, x, y, 0.0, 0.0, K.F_NO_XP | K.F_REVIVED, 0, _forge())


func _golem_absorb(i: int, x: float, y: float) -> bool:
	if units.d_golem < 0:
		return false
	var gd: CardDef = data.cards[units.d_golem]
	var fx: Dictionary = gd.fx
	var r2: float = pow(float(fx["absorb_radius"]), 2)
	for j in units.hi:
		if units.alive[j] == 1 and j != i and units.def[j] == units.d_golem:
			if Vector2(units.px[j] - x, units.py[j] - y).length_squared() <= r2:
				var cap := gd.fxv("hp_cap", int(units.lvl[j]))
				units.max_hp[j] = minf(cap, units.max_hp[j] + float(fx["absorb_hp"]))
				units.hp[j] = minf(units.max_hp[j], units.hp[j] + float(fx["absorb_hp"]))
				return true
	return false


## Relíquias de volta (11/11/2026). Filactério: o 1º monstro seu morto pelo herói da vez volta com a vida cheia
## (uma vez por herói). Chamado da Cova: chance de voltar como Esqueleto (só vida e dano; nunca volta de novo).
## Quem volta ganha F_REVIVED e não volta outra vez. Devolve true se voltou.
func _relic_revive(i: int, x: float, y: float, c: CardDef) -> bool:
	if rv("revive_once") > 0.0 and phyl_hero != hero.pidx:
		phyl_hero = hero.pidx
		var j := units.spawn(c, x, y, 0.0, 0.0, K.F_NO_XP | K.F_REVIVED, units.uid[i], 1.0)
		if j >= 0:
			units.lvl[j] = units.lvl[i]
			units.max_hp[j] = units.max_hp[i]
			units.hp[j] = units.max_hp[i]
			units.dmg[j] = units.dmg[i]
			return true
	if rv("skeleton_return") > 0.0 and c.id != "skeleton" and rng.randf() < rv("skeleton_return"):
		units.spawn(data.card("skeleton"), x, y, 0.0, 0.0, K.F_NO_XP | K.F_REVIVED, units.uid[i], _forge())
		stats["skeletons_back"] = int(stats.get("skeletons_back", 0)) + 1
		return true
	return false


func _totem_revive(i: int, x: float, y: float) -> void:
	if units.d_totem < 0:
		return
	var fx: Dictionary = data.cards[units.d_totem].fx
	var r2: float = pow(float(fx["radius"]), 2)
	for j in units.hi:
		if units.alive[j] == 1 and units.def[j] == units.d_totem:
			if Vector2(units.px[j] - x, units.py[j] - y).length_squared() <= r2:
				var sk: CardDef = data.card(str(fx["revive"]))
				units.spawn(sk, x, y, 0.0, 0.0, K.F_NO_XP | K.F_REVIVED, units.uid[i], _forge())
				return


func spawn_child(c: CardDef, x: float, y: float, parent: int) -> int:
	var inherit := units.flags[parent] & (K.F_NO_XP | K.F_CURSED | K.F_DEFEND)
	var j := units.spawn(c, x, y, units.xp[parent], units.cost_share[parent], inherit, units.uid[parent], _forge())
	if j >= 0:
		units.lvl[j] = units.lvl[parent]
	return j


func kamikaze(i: int) -> void:
	var c: CardDef = data.cards[units.def[i]]
	var lv := int(units.lvl[i])
	var r: float = c.fx.get("explode_radius", 2.5)
	var x := units.px[i]
	var y := units.py[i]
	var src := str(card_of_uid.get(units.uid[i], c.id))
	var near_k := heroes_near(x, y, r)
	for k in near_k.size():
		hit_hero = near_k[k]
		damage_hero(c.fxv("explode_damage", lv) * splash_mult(k), x, y, units.tags[i], 0, src)
	hit_hero = null
	if c.fx.has("peste_boom"):
		for hh in near_k:
			CardsPlague.add_peste(self, hh, c.fxv("peste_boom", lv))
	# Goblin N3: a explosão deixa fogo no chão.
	if c.has_n3(lv, "fire_dps"):
		zones.append({"kind": "fire", "x": x, "y": y, "r": c.n3["fire_r"], "t": c.n3["fire_s"], "dps": c.n3["fire_dps"], "src": src})
	emit(K.Ev.EXPLOSION, x, y, r, 1)
	kill_unit(i, K.Death.SELF)


func mimic_bite(i: int) -> void:
	var c: CardDef = data.cards[units.def[i]]
	var lv := int(units.lvl[i])
	var bite := c.fxv("bite", lv)
	for z in zones:
		if z["kind"] == "bait" and Vector2(units.px[i] - z["x"], units.py[i] - z["y"]).length() <= float(c.fx.get("bait_r", 5.0)):
			bite *= float(c.fx.get("bait_mult", 2.0))
			break
	damage_hero(bite, units.px[i], units.py[i], units.tags[i], SimHero.DMG_PIERCE, c.id)
	hero.add_curse(int(c.fx.get("curses", 0)))
	hero.note("mimic", 120.0)
	# Mímico N3: morde de novo depois de uma pausa (gen conta as mordidas).
	units.gen[i] += 1
	if c.has_n3(lv, "bites") and units.gen[i] < int(c.n3["bites"]):
		units.flags[i] &= ~K.F_BITTEN
		units.timer2[i] = units.timer[i] + 3.0


func hero_fear(x: float, y: float, dur := -1.0) -> void:
	if dur <= 0.0:
		dur = float(R["status"]["fear"])
	hero.fear(x, y, dur * cc_mult())
	emit(K.Ev.FEAR, hero.x, hero.y, 0, 0)


func on_shield_break() -> void:
	stats["shield_breaks"] += 1
	emit(K.Ev.SHIELD_BREAK, hero.x, hero.y, 0, 0)


## Sem XP (09/11/2026): o herói só evolui quando um herói cai (`_hero_fell`). Mantida vazia para as chamadas antigas.
func hero_gain_xp(_v: float) -> void:
	pass


## O herói da vez caiu: vem o próximo, um nível acima e com uma habilidade a mais, andando de trás.
func _hero_fell() -> void:
	track.on_hero_fall(self)
	var fell := party_idx + 1
	if party_mode():
		group_falls += 1
		fell = group_falls
	stats["heroes_fallen"] = fell
	if hero.pidx == slow_hero:
		slow_hero = -1   # Piche: vale até o herói cair
	var bless: float = hero.H.get("bless_next", 0.0)
	if bless > 0.0:
		# Clériga: a bênção dela fica para o próximo herói.
		next_hp_mult *= 1.0 + bless
	emit(K.Ev.HERO_FALL, hero.x, hero.y, fell, 0)
	var arriving: Array = [party_idx + 1]   # quem chega (fila de parties: a party seguinte inteira)
	if party_mode():
		cur_party += 1
		arriving = party_members(cur_party)
	party_idx = int(arriving[0])
	var back := float(R["party"]["arrive_s"]) * float(hero.H["speed"])
	hero.next_hero(party_idx)
	var bless_mult := next_hp_mult
	if bless_mult != 1.0:
		hero.base_hp *= bless_mult
		hero.hp = hero.base_hp
		next_hp_mult = 1.0
	# Caiu no meio da disputa: o local fica perdido (sem recompensa).
	if contest.size() > 0:
		road.locations[int(contest["li"])]["state"] = SimRoad.LocState.USED
		stats["locs_lost"] += 1
	contest = {}
	_remove_helper()   # o Herói Ajudante vai embora junto com a disputa perdida
	hero.hold = false
	if phase == K.Phase.ROAD:
		var s0 := maxf(0.0, hero.s_max - back)
		var p := road.point_at(s0)
		hero.x = p.x
		hero.y = p.y
		hero.s = s0
		hero.s_max = s0
		hero.seg = road.seg_at(s0)
	else:
		hero.x = gate_pos.x
		hero.y = gate_pos.y
	hero.ox = hero.x
	hero.oy = hero.y
	_learn_ability()
	# A party seguinte chega junta: os outros membros nascem atrás do primeiro, com as habilidades do grupo.
	followers.clear()
	for k in range(1, arriving.size()):
		var nf := SimHero.new()
		nf.init_follower(self, int(arriving[k]), hero, 1.0)
		if bless_mult != 1.0:
			nf.base_hp *= bless_mult
			nf.hp = nf.base_hp
		followers.append(nf)
	emit(K.Ev.HERO_LEVEL, hero.x, hero.y, hero.level, 0)
	_offer_level()
	if rv("fall_mod_offer") > 0.0:
		var mo: Array = []
		var ex: Array = []
		for k in int(R["offers"]["options"]):
			var m := _mod_option(ex)
			if m.size() > 0:
				ex.append(str(m["uid"]) + str(m["mod"]))
				mo.append(m)
		_push_offer("level", mo)


## O herói aprende uma habilidade a cada `upgrade_every` níveis, até `upgrade_max` (poucas, para o jogador acompanhar).
func _hero_learns() -> bool:
	var X: Dictionary = R["hero_xp"]
	var every := int(X.get("upgrade_every", 1))
	return hero.level % every == 0 and hero.upgrade_order.size() < int(X.get("upgrade_max", 99))


func _upgrade_options(n: int) -> Array:
	var pool: Array = []
	for u in data.hero["upgrades"]:
		if not hero.has(u["id"]):
			pool.append(u)
	var out: Array = []
	while out.size() < n and pool.size() > 0:
		var tot := 0.0
		for u in pool:
			tot += float(u["weight"])
		var r := rng.randf() * tot
		for k in pool.size():
			r -= float(pool[k]["weight"])
			if r <= 0.0 or k == pool.size() - 1:
				out.append(pool[k]["id"])
				pool.remove_at(k)
				break
	return out


func _forge() -> float:
	return 1.0 + temp_sum("monster_hp")


# ================================================================ zonas

## Heróis de pé dentro da zona z (o da vez primeiro). Fase de grupo (10/11/2026): zonas pegam o grupo todo.
func _in_zone(z: Dictionary) -> Array:
	var out: Array = []
	for hh in all_heroes():
		if Vector2(hh.x - float(z["x"]), hh.y - float(z["y"])).length() <= float(z["r"]) + hh.radius:
			out.append(hh)
	return out


func _zones() -> void:
	var h := Vector2(hero.x, hero.y)
	var i := zones.size() - 1
	while i >= 0:
		var z: Dictionary = zones[i]
		z["t"] -= dt
		var inside: bool = h.distance_to(Vector2(z["x"], z["y"])) <= float(z["r"]) + hero.radius
		match str(z["kind"]):
			"web":
				# "applied" guarda os heróis (pidx) já presos por esta teia: cada um prende uma vez.
				if not (z["applied"] is Array):
					z["applied"] = [hero.pidx] if z["applied"] else []
				for hh in _in_zone(z):
					hh.slow_t = maxf(hh.slow_t, 0.15)
					hh.note("slow", 2.0)
					if not z["applied"].has(hh.pidx):
						z["applied"].append(hh.pidx)
						hh.root_t = maxf(hh.root_t, float(z.get("root", 0.0)) * cc_mult())
						hh.add_curse(int(z.get("curse", 0)))
						if float(z.get("soak", 0.0)) > 0.0:
							hh.soaked_t = maxf(hh.soaked_t, float(z["soak"]))
			"oil":
				var ins: Array = _in_zone(z)
				for k in ins.size():
					var hh: SimHero = ins[k]
					hh.soaked_t = z["soaked"]
					hit_hero = hh if hh != hero else null
					damage_hero(float(z["dps"]) * dt, z["x"], z["y"], K.TAG_FIRE, SimHero.DMG_AREA, str(z.get("src", "boiling_oil")))
					if z.get("curse", 0) > 0:
						hh.add_curse(int(z["curse"]))
						z["curse"] = 0
				hit_hero = null
			"fire":
				for hh in _in_zone(z):
					hit_hero = hh if hh != hero else null
					damage_hero(float(z["dps"]) * dt, z["x"], z["y"], K.TAG_FIRE, SimHero.DMG_AREA, z["src"])
				hit_hero = null
			"spring":
				# Fonte: cura as suas unidades no raio (estruturas também).
				if tick % 4 == 0:
					for j in units.within(z["x"], z["y"], z["r"], tmp):
						if units.alive[j] == 1:
							units.hp[j] = minf(units.max_hp[j], units.hp[j] + units.max_hp[j] * float(z["heal"]) * dt * 4.0)
			"bait":
				if hero.has("treasure_nose"):
					z["t"] = 0.0
				elif h.distance_to(Vector2(z["x"], z["y"])) <= 1.5:
					hero_gain_xp(z["xp"])
					hero.note("bait", 60.0)
					z["t"] = 0.0
			"coins":
				# Quem pisar primeiro (o da vez ou um seguidor) para para catar as moedas.
				var ins_c: Array = _in_zone(z)
				if ins_c.size() > 0 and not z["applied"]:
					var hc: SimHero = ins_c[0]
					z["applied"] = true
					track.on_coins()
					hc.root_t = maxf(hc.root_t, float(z["stop"]))
					hc.add_curse(int(z["curses"]))
					_earn_gold(float(z["gold"]))
					z["t"] = 0.0
			"army":
				if z["t"] <= 0.0:
					for j in z["ids"]:
						if units.alive[j] == 1 and data.cards[units.def[j]].id == "spectre":
							kill_unit(j, K.Death.EXPIRE)
		if z["t"] <= 0.0:
			zones.remove_at(i)
		i -= 1


# ================================================================ cartas

func card_cost(c: CardInst) -> int:
	if free_card_active() or gambit_ready():
		return 0
	var d := c.def
	var cost := d.cost_at(c.level)
	if c.has_mod(K.M_CHEAP):
		cost = maxi(0, cost - 1)
	cost -= c.discount
	if d.category == "field" and (d.type == "monster" or d.type == "swarm"):
		cost += int(deck_rules.get("monster_cost_add", 0))
	if d.is_spell and harvest_free:
		return 0
	if d.is_spell:
		if units.n_cultists > 0:
			var cf: Dictionary = data.card("cultists").fx
			cost = maxi(int(cf["spell_min_cost"]), cost - int(cf["spell_discount"]))
		if phase == K.Phase.ARENA and not arena.part_alive("left_arm"):
			cost += int(R["arena"]["spell_extra_cost_no_left_arm"])
	if tax_cards > 0:
		cost += tax_add
	cost += CardsCommon.card_cost_add(self, c) + CardsPlague.card_cost_add(self, c) + CardsDragon.card_cost_add(self, c) + CardsLich.card_cost_add(self, c)
	# Balança do Gigante: cartas de custo base 6+ saem mais baratas.
	if rv("big_discount") > 0.0 and d.cost_at(c.level) >= 6:
		cost -= int(rv("big_discount"))
	# Tinta Arcana: feitiços mais baratos, sem descer abaixo de 1 (um feitiço que já custava 0 continua 0).
	if d.is_spell and rv("spell_discount") > 0.0 and cost > 0:
		cost = maxi(1, cost - int(rv("spell_discount")))
	cost = maxi(0, cost)
	# Pedra do Atalho: a primeira carta de cada disputa sai mais barata.
	if contest.size() > 0 and not contest.get("first", false):
		cost = maxi(0, cost - int(rv("contest_first_discount")))
	return cost


## Carta de criatura (monstro ou enxame; estrutura e feitiço não).
func cycle_is_creature(d: CardDef) -> bool:
	return d.category == "field" and (d.type == "monster" or d.type == "swarm")


## Ciclo de feitiço: o desconto de 1 está armado para esta carta agora? (a mão destaca a carta)
func cycle_applies(c: CardInst) -> bool:
	if int(deck_rules.get("cycle", 0)) <= 0:
		return false
	if c.def.is_spell:
		return cycle_spell
	return cycle_mon and cycle_is_creature(c.def)


## Abertura: a 1ª carta contra o herói da vez ainda não saiu (sai de graça).
func gambit_ready() -> bool:
	return rv("hero_first_free") > 0.0 and gambit_hero != hero.pidx and phase != K.Phase.OVER


func can_play(hi_: int) -> int:
	if phase == K.Phase.OVER:
		return K.Block.OVER
	if offers.size() > 0:
		return K.Block.OFFER_PENDING
	if hi_ < 0 or hi_ >= hand.size() or hand[hi_] == null:
		return K.Block.BAD_TARGET
	var c: CardInst = hand[hi_]
	var d := c.def
	match d.category:
		"route":
			if phase != K.Phase.ROAD:
				return K.Block.WRONG_PHASE
			if d.id == "burn_village" and _burn_targets().is_empty():
				return K.Block.CONDITION
	if d.fx.has("gold_cost") and gold + 0.0001 < float(d.fx["gold_cost"]):
		return K.Block.CONDITION
	if d.id == "shadow_echo" and last_spell_id == "":
		return K.Block.CONDITION
	if elixir + 0.0001 < card_cost(c):
		return K.Block.NO_ELIXIR
	return K.Block.OK


## Raio do círculo em que não se solta monstro, um por herói da party (15/11/2026): 3 m; o herói à distância
## (Arqueira, Mago, Besteiro) usa o alcance de ataque dele.
func ring_of(h: SimHero) -> float:
	var m := float(R["ring"]["min"])
	if bool(h.H.get("ranged", false)):
		return maxf(m, float(h.H.get("attack_range", m)))
	return m


## Heróis que têm círculo: o líder e os outros membros da party (o Herói Ajudante, parado no local, não).
func ring_heroes() -> Array:
	return [hero] + followers


## (x, y) cai dentro do círculo de algum herói?
func in_any_ring(x: float, y: float) -> bool:
	for hh: SimHero in ring_heroes():
		if Vector2(x - hh.x, y - hh.y).length() < ring_of(hh):
			return true
	return false


## Empurra (x, y) para fora de todos os círculos, para a mira dos bots.
func clear_of_rings(p: Vector2) -> Vector2:
	for _k in 4:
		var moved := false
		for hh: SimHero in ring_heroes():
			var v := p - Vector2(hh.x, hh.y)
			var r := ring_of(hh)
			if v.length() < r:
				v = v.normalized() if v.length() > 0.05 else Vector2(1, 0)
				p = Vector2(hh.x, hh.y) + v * (r + 0.3)
				moved = true
		# Rio (16/11/2026): a mira dos bots também sai da água (para a margem mais perto).
		if phase == K.Phase.ROAD and terra().is_water(p.x, p.y):
			p = terrain.nearest_dry(p.x, p.y)
			moved = true
		if not moved:
			break
	return p


## Onde a carta pode ser solta. Devolve true se (x, y) é válido.
func valid_target(c: CardInst, x: float, y: float) -> bool:
	var d := c.def
	if d.category == "field":
		# Rio (16/11/2026): monstro de chão não nasce na água (voadores e feitiços podem).
		if phase == K.Phase.ROAD and not d.is_spell and not d.fly and terra().is_water(x, y):
			return false
		var ring: Dictionary = R["ring"]
		# Sem alcance máximo: vale qualquer ponto que o jogador enxerga na tela.
		if d.is_spell and ring["spells_ignore_min"]:
			return true
		if not in_any_ring(x, y):
			return true
		return phase == K.Phase.ARENA and Vector2(x - arena.bx, y - arena.by).length() <= 6.0
	if d.id == "gold_bait":
		return Vector2(x - hero.x, y - hero.y).length() <= float(d.fx["max_detour"]) + 10.0
	if d.id == "burn_village":
		return _burn_near(x, y) >= 0
	return true


func play(hi_: int, x: float, y: float) -> int:
	var b := can_play(hi_)
	if b != K.Block.OK:
		return b
	var c: CardInst = hand[hi_]
	if not valid_target(c, x, y):
		return K.Block.BAD_TARGET
	var paid := card_cost(c)
	if gambit_ready():
		gambit_hero = hero.pidx
	# Moeda da Sorte: chance de a carta não gastar o elixir.
	if paid > 0 and rv("free_play_chance") > 0.0 and rng.randf() < rv("free_play_chance"):
		paid = 0
		stats["lucky_free"] = int(stats.get("lucky_free", 0)) + 1
	# Talha de Contagem: a cada N cartas jogadas, a N-ésima não gasta elixir.
	if rv("nth_free") > 0.0:
		tally_plays += 1
		if tally_plays >= int(rv("nth_free")):
			tally_plays = 0
			paid = 0
	elixir -= paid
	# Anel Encadeado: 3 cartas em 4 s devolvem elixir (a corrente recomeça depois).
	if rv("chain_elixir") > 0.0:
		chain_times.append(t)
		while chain_times.size() > 0 and t - float(chain_times[0]) > 4.0:
			chain_times.pop_front()
		if chain_times.size() >= 3:
			chain_times.clear()
			elixir = minf(elixir_max, elixir + rv("chain_elixir"))
	var slot := _act_slot()
	stats["spent_act"][slot] += paid
	stats["plays_act"][slot] += 1
	if paid > int(stats["max_cost"]):
		stats["max_cost"] = paid
	free_card_t = -100.0
	if tax_cards > 0:
		tax_cards -= 1
	if c.def.is_spell and harvest_free:
		harvest_free = false
	if int(deck_rules.get("cycle", 0)) > 0:
		# Ciclo de feitiço (Lich): gasta o desconto que a carta usou e arma o da outra metade do baralho.
		if c.def.is_spell:
			cycle_spell = false
			cycle_mon = true
		elif cycle_is_creature(c.def):
			cycle_mon = false
	if contest.size() > 0:
		contest["first"] = true
	_cycle(hi_)
	var pl: Dictionary = stats["played"]
	pl[c.def.id] = int(pl.get(c.def.id, 0)) + 1
	_linger_until = 0.0
	_apply(c, x, y)
	_hold_if_lingering(c, t)
	if c.def.is_spell:
		_after_spell(c)
	CardsCommon.on_card_played(self, c, x, y)
	CardsPlague.on_card_played(self, c, x, y)
	CardsDragon.on_card_played(self, c, x, y)
	CardsLich.on_card_played(self, c, x, y)
	track.on_play(self, c)
	return K.Block.OK


## Família Sequência: guarda o feitiço (Eco Sombrio, Faísca Arcana) e faz os Acólitos atirarem junto.
func _after_spell(c: CardInst) -> void:
	spell_times.append(t)
	if c.def.id != "shadow_echo" and not c.def.fx.has("gold_cost"):
		last_spell_id = c.def.id
		last_spell_lv = c.level
	for j in units.hi:
		if units.alive[j] == 1 and data.cards[units.def[j]].fx.has("echo_shot"):
			if Vector2(units.px[j] - hero.x, units.py[j] - hero.y).length() <= units.rng[j] + hero.radius + 2.0:
				unit_hits_hero(j)


## Feitiços jogados nos últimos `window` segundos (sem contar o atual).
func recent_spells(window: float) -> int:
	while spell_times.size() > 0 and t - float(spell_times[0]) > window:
		spell_times.pop_front()
	return spell_times.size()


## Carta saiu da mão (jogada): vai ao descarte e a vaga compra outra. Mão acima do tamanho (efeito
## que acabou) não repõe a vaga; nenhuma carta é expulsa.
func _cycle(hi_: int) -> void:
	var c: CardInst = hand[hi_]
	_to_discard(c)
	if hand.size() > mini(hand_size, HAND_MAX):
		_hand_remove(hi_)
	else:
		# A vaga fica vazia por DRAW_DELAY s (a mão mostra o tracejado enchendo); _tick_draws compra depois.
		hand[hi_] = null
		_set_wait(hi_, draw_delay())
	_refill_hand()


## Vagas vazias da mão: descontam a espera e, ao zerar, compram (sem carta fora da mão, a vaga sai).
func _tick_draws() -> void:
	var i := 0
	while i < hand.size():
		if hand[i] == null:
			stats["empty_s"] = float(stats.get("empty_s", 0.0)) + dt   # segundos-vaga vazios (métrica da recarga)
			var left := wait_left(i) - dt
			if left > 0.0:
				_set_wait(i, left)
			else:
				var nc := draw_card()
				if nc == null:
					_hand_remove(i)
					continue
				hand[i] = nc
				_set_wait(i, 0.0)
				if rv("refill_elixir") > 0.0:
					elixir = minf(elixir_max, elixir + rv("refill_elixir"))   # Sino de Bronze
		i += 1


## Recarga da vaga com relíquias (Areia Fina, Mochila do Saqueador): DRAW_DELAY × (1 + soma de "draw_delay").
func draw_delay() -> float:
	return DRAW_DELAY * draw_delay_mult * maxf(0.15, 1.0 + rv("draw_delay"))


## Experimentos de balanceamento (headless/batch.gd): multiplicador da recarga e evento forçado. Só o lote mexe.
var draw_delay_mult := 1.0
var force_event := ""        # id do evento que sempre sai nos locais de evento ("" = sorteio normal)
var force_event_opt := -1    # índice da opção que o bot escolhe nesse evento (-1 = escolha normal)


## Segundos que faltam para a vaga i da mão receber carta (0 = sem espera).
func wait_left(i: int) -> float:
	if i < 0 or i >= hand_wait.size() or hand_wait[i] == null:
		return 0.0
	return float(hand_wait[i])


func _set_wait(i: int, v: float) -> void:
	if hand_wait.size() < hand.size():
		hand_wait.resize(hand.size())
	hand_wait[i] = v


func _hand_remove(i: int) -> void:
	hand.remove_at(i)
	if i < hand_wait.size():
		hand_wait.remove_at(i)


## "Retorna": volta para a compra em posição aleatória, uma vez por embaralhada; nas outras vezes, descarte.
func _to_discard(c: CardInst) -> void:
	if c.def.fx.get("returns", false) and not returned.has(c.uid):
		returned[c.uid] = true
		queue.insert(rng.randi_range(0, queue.size()), c)
	else:
		discard.push_back(c)


## Compra uma carta (embaralha o descarte se a compra acabou). null = não há carta fora da mão.
func draw_card() -> CardInst:
	if queue.is_empty() and discard.size() > 0:
		_reshuffle()
	return queue.pop_front() if queue.size() > 0 else null


func _reshuffle() -> void:
	var list := discard
	discard = []
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmpc = list[i]
		list[i] = list[j]
		list[j] = tmpc
	queue.append_array(list)
	returned.clear()
	stats["shuffles"] = int(stats.get("shuffles", 0)) + 1
	for q in int(rv("draw_on_shuffle")):
		if hand.size() < HAND_MAX and queue.size() > 0:
			hand.append(queue.pop_front())


## Mão menor que o tamanho (Biblioteca, carta removida, baralho curto): completa enquanto houver carta.
func _refill_hand() -> void:
	while hand.size() < mini(hand_size, HAND_MAX):
		var c := draw_card()
		if c == null:
			break
		if hand.size() >= mini(hand_size, HAND_MAX):
			queue.push_front(c)   # a embaralhada no meio da compra ("compra ao embaralhar") já encheu a mão
			break
		hand.append(c)


## Aplica o efeito de uma carta jogada. Unidades: CardFxLib.spawn_card_units. Depois as "ops" declaradas em
## data/cards.json (CardFxLib) e, por fim, o código por id no arquivo do dono (sim/cards/<owner>.gd).
func _apply(c: CardInst, x: float, y: float) -> void:
	var d := c.def
	var k := CardFxLib.ctx(self, c)
	emit(K.Ev.SPELL, x, y, d.idx, 0)
	if d.is_unit:
		CardFxLib.spawn_card_units(self, k, x, y)
		if not d.ops.is_empty():
			CardFxLib.run(self, k, d.ops, x, y)
		return
	if not d.ops.is_empty():
		CardFxLib.run(self, k, d.ops, x, y)
	match d.owner:
		"plague":
			if CardsPlague.apply(self, k, x, y):
				return
		"dragon":
			if CardsDragon.apply(self, k, x, y):
				return
		"lich":
			if CardsLich.apply(self, k, x, y):
				return
		_:
			if CardsCommon.apply(self, k, x, y):
				return
	if d.ops.is_empty():
		push_error("carta sem efeito: %s (owner %s)" % [d.id, d.owner])


## Locais que o Incêndio pode marcar (sim/cards/dragon.gd).
func _burn_targets() -> Array:
	return CardsDragon.burn_targets(self)


func _burn_near(x: float, y: float) -> int:
	return CardsDragon.burn_near(self, x, y)


func teleport(k: int) -> bool:
	if phase != K.Phase.ARENA:
		return false
	return arena.teleport(k)


# ================================================================ ofertas

func _roll_rarity(rare_mult := 1.0) -> int:
	var w: Array
	var A: Array = R.get("acts", [])
	if A.size() > 0:
		w = A[mini(act, A.size() - 1)]["rarity"]
	else:
		var RT: Dictionary = R["rarity_by_time"]
		var row := 0
		for b in RT["breaks_s"]:
			if t >= float(b):
				row += 1
		w = RT["weights"][row]
	if rare_mult != 1.0:
		# Fim de ato: rara e lendária pesam mais; os pesos são renormalizados.
		w = w.duplicate()
		var tot := 0.0
		for k in w.size():
			if k >= 2:
				w[k] = float(w[k]) * rare_mult
			tot += float(w[k])
		for k in w.size():
			w[k] = float(w[k]) / maxf(tot, 0.0001)
	var r := rng.randf()
	for k in w.size():
		r -= float(w[k])
		if r <= 0.0:
			return k
	return w.size() - 1


## Progresso da run em [0, 1]: 0 no começo do ato 1, 1 no fim do ato 3 (ato + fração da estrada já andada).
func run_progress() -> float:
	var f := 1.0
	if phase == K.Phase.ROAD and not act_pending:
		var L := road.length()
		f = clampf(hero.s / L, 0.0, 1.0) if L > 0.0 else 0.0
	return clampf((float(act) + f) / float(maxi(acts(), 1)), 0.0, 1.0)


## Nível das cartas de UMA oferta (10/11: uma sorteada por oferta, igual a raridade única): 1, 2 ou 3.
## Chance de 2+ = p*lv2_end; de 3 = p*lv3_end. `end_act`: fim de ato dobra as chances (nível 3 com teto próprio).
func roll_offer_level(end_act := false, p := -1.0) -> int:
	var mx := int(R["card_levels"]["max"])
	if mx < 2:
		return 1
	if p < 0.0:
		p = run_progress()
	var U: Dictionary = R["offer_upgrades"]
	var m := float(U["act_end_mult"]) if end_act else 1.0
	var c2 := clampf(p * float(U["lv2_end"]) * m, 0.0, 1.0)
	var c3 := minf(p * float(U["lv3_end"]) * m, c2)
	if end_act:
		c3 = minf(c3, float(U["act_end_lv3_cap"]))
	var u := rng.randf()
	if mx >= 3 and u < c3:
		return 3
	if u < c2:
		return 2
	return 1


func _card_ok(c: CardDef) -> bool:
	if not data.in_pool(c, deck_id):
		return false
	if unlocked.size() > 0 and not unlocked.has(c.id):
		return false
	if c.cost > max_offer_cost():
		return false
	return true


func _deck_count(id: String) -> int:
	var n := 0
	for ci in cards:
		if ci.def.id == id:
			n += 1
	return n


func _pick_card(filter: Callable, exclude: Array) -> CardDef:
	var cand: Array = []
	for c in data.pool:
		if filter.call(c) and _card_ok(c) and not exclude.has(c.id):
			cand.append(c)
	if cand.is_empty():
		return null
	# Peso por dono (13/11/2026): carta do vilão pesa mais que carta comum, para o baralho ter a cara dele.
	var ow: Dictionary = R["offers"].get("owner_weight", {})
	var wt_own := float(ow.get("villain", 1.0))
	var wt_com := float(ow.get("common", 1.0))
	var tot := 0.0
	for c in cand:
		tot += wt_com if c.owner == "common" else wt_own
	var r := rng.randf() * tot
	for c in cand:
		r -= wt_com if c.owner == "common" else wt_own
		if r <= 0.0:
			return c
	return cand[cand.size() - 1]


func _mod_option(exclude: Array) -> Dictionary:
	var cand: Array = []
	for ci in cards:
		if ci.def.category != "field":
			continue
		for mid in K.MOD_IDS:
			var m: Dictionary = data.modifiers[mid]
			var ok: bool = (m["applies"].has("any") or m["applies"].has(ci.def.type)) and not m.get("exclude", []).has(ci.def.id)
			if ok and not ci.has_mod(K.MOD_BY_ID[mid]) and not exclude.has(str(ci.uid) + mid):
				cand.append([ci, mid])
	if cand.is_empty():
		return {}
	var p: Array = cand[rng.randi_range(0, cand.size() - 1)]
	return {"kind": "mod", "uid": p[0].uid, "card": p[0].def.id, "mod": p[1]}


func _push_offer(source: String, opts: Array, extra := {}) -> void:
	if opts.is_empty():
		return
	var of: Dictionary = stats["offered"]
	for o in opts:
		var key := _opt_key(o)
		of[key] = int(of.get(key, 0)) + 1
	var o := {"source": source, "options": opts}
	o.merge(extra)
	offers.append(o)


func _opt_key(o: Dictionary) -> String:
	match str(o["kind"]):
		"card":
			return o["id"]
		"mod":
			return "mod:" + str(o["mod"])
		"upgrade":
			return "up:" + str(o["card"])
		"pick":
			return "pick:" + str(o["what"])
		"buy":
			return "buy:" + _opt_key(o["item"])
		"relic":
			return "relic:" + str(o["id"])
		"event_opt":
			return "ev:%s:%d" % [o["event"], int(o["opt"])]
		"transform", "copy":
			return str(o["kind"]) + ":" + str(o["card"])
	return "remove"


## Recompensa de um local: o tipo do local decide o que vem; vencer a disputa dá mais opções.
## Recompensas dos marcos (12/11/2026): `n` marcos alcançados (1 a 3). Taverna, Santuário e Ponte dão uma oferta por
## marco; Fonte e Ritual dão uma só, com mais cartas à escolha quanto mais alto o marco (rules.location_rewards.*.frac).
func _offer_marks(ty: String, n: int) -> void:
	var LR: Dictionary = R["location_rewards"][ty]
	var cnt := int(R["offers"]["location_win"])
	var won := n >= 3
	if won:
		stats["locs_won"] += 1
		_earn_gold(float(R["gold"]["per_contest"]))
	var ex: Array = []
	match str(LR["reward"]):
		"mod":
			for k in n:
				var opts: Array = []
				for j in cnt:
					var m := _mod_option(ex)
					if m.size() > 0:
						ex.append(str(m["uid"]) + str(m["mod"]))
						opts.append(m)
				_push_offer("location", opts, {"loc": ty, "won": won, "mark": k + 1})
		"card":
			var minr := K.RARITIES.find(str(LR["min_rarity"]))
			for k in n:
				_push_offer("location", _card_options(cnt, func(cd: CardDef): return cd.rarity >= minr), {"loc": ty, "won": won, "mark": k + 1})
		"cards":
			var rar: Array = LR["rarities"]
			for k in n:
				var r := K.RARITIES.find(str(rar[mini(k, rar.size() - 1)]))
				_push_offer("location", _card_options(cnt, func(cd: CardDef): return cd.rarity == r), {"loc": ty, "won": won, "mark": k + 1})
		"remove":
			var fr: Array = LR["frac"]
			var f := float(fr[mini(n, fr.size()) - 1])
			var pick := -1 if f >= 1.0 else maxi(1, roundi(cards.size() * f))
			if _can_remove():
				_push_offer("location", _pick_insts(cards.duplicate(), pick, "remove"), {"loc": ty, "won": won, "mark": n})
		"upgrade":
			var fr: Array = LR["frac"]
			var f := float(fr[mini(n, fr.size()) - 1])
			var elig := cards.filter(func(ci): return ci.level < int(R["card_levels"]["max"]))
			var pick := -1 if f >= 1.0 else maxi(1, roundi(elig.size() * f))
			_push_offer("location", _pick_insts(elig, pick, "upgrade"), {"loc": ty, "won": won, "mark": n})


func _earn_gold(v: float) -> void:
	v *= 1.0 + temp_sum("gold_mult")
	gold += v
	stats["gold_earned"] += v


## Loja: abre quando o herói chega; sem disputa e sem desconto (rodada 09/11/2026).
## Cada item é {"kind": "buy", "item": opção de oferta (ou um "pick" que abre a escolha da carta), "price"}.
func _open_shop() -> void:
	var S: Dictionary = R["shop"]
	var disc := -rv("shop_price")
	var price := func(v: float) -> int: return int(round(v * (1.0 - disc)))
	var items: Array = []
	var ex: Array = []
	var lv := roll_offer_level()   # nível único das cartas da loja
	for k in int(S["cards"]) + int(rv("shop_cards")):
		var r := _roll_rarity()
		var c: CardDef = null
		for dr in [0, -1, 1, -2, 2, -3, 3]:
			var rr: int = r + dr
			if rr < 0 or rr > 3:
				continue
			c = _pick_card(func(cd: CardDef): return cd.rarity == rr, ex)
			if c:
				break
		if c:
			ex.append(c.id)
			# Carta já melhorada custa o preço da raridade + o preço de subir nível por nível extra (assumido).
			var base := float(S["prices"][K.RARITIES[c.rarity]]) + float(S.get("card_upgrade", S["upgrade"])) * (lv - 1)
			items.append({"kind": "buy", "item": {"kind": "card", "id": c.id, "level": lv}, "price": price.call(base)})
	if not _level_up_options(1).is_empty():
		items.append({"kind": "buy", "item": {"kind": "pick", "what": "upgrade"}, "price": price.call(float(S["upgrade"]))})
	var m := _mod_option([])
	if m.size() > 0:
		items.append({"kind": "buy", "item": m, "price": price.call(float(S["mod"]))})
	if _can_remove():
		items.append({"kind": "buy", "item": {"kind": "pick", "what": "remove"},
			"price": price.call(float(S["remove"]) + float(S["remove_step"]) * shop_removes)})
	# 1 relíquia à venda por loja (11/11/2026), preço por raridade (rules.shop.relic_prices, a testar).
	var rpool := _relic_pool()
	for k in int(S.get("relics", 0)):
		if rpool.is_empty():
			break
		var rid := _pick_relic(rpool)
		rpool.erase(rid)
		var rp: Dictionary = S.get("relic_prices", {})
		items.append({"kind": "buy", "item": {"kind": "relic", "id": rid},
			"price": price.call(float(rp.get(str(data.relics[rid].get("rarity", "common")), 150)))})
	_push_offer("shop", items, {"won": true})


## Dragão Avarento (15/11/2026): não compra em loja. Cada loja que passa dá `shop_gold` de ouro e 3 cartas de
## raridade alta (rara ou lendária) sorteadas, das quais escolhe 1 (recusável, como as outras ofertas de carta).
func _dragon_shop() -> void:
	_earn_gold(float(deck_rules["shop_gold"]))
	var minr := K.RARITIES.find("rare")
	var cnt := int(R["offers"]["location_win"])
	_push_offer("location", _card_options(cnt, func(cd: CardDef): return cd.rarity >= minr), {"loc": "shop", "won": true, "mark": 3})


## Escolha do ramo pelo jogador: o herói vai passar pelo nó n (precisa estar à frente, no caminho).
func choose_route(n: int) -> bool:
	if phase != K.Phase.ROAD or not road.plan_to(n):
		return false
	if route_wait and road.next_edge() >= 0:
		route_wait = false
	return true


func _rarity_filter(names: Array) -> Callable:
	var rs: Array = names.map(func(r): return K.RARITIES.find(str(r)))
	return func(cd: CardDef): return rs.has(cd.rarity)


## Raridade única por oferta (10/11/2026): sorteia a raridade uma vez (peso do ato) e devolve a mais próxima que
## tem `n` cartas possíveis pelo filtro; sem nenhuma com `n`, aceita menos opções em vez de misturar raridades.
## -1 = o filtro não deixa carta nenhuma.
func _single_rarity(f: Callable, n: int, exclude: Array = [], rare_mult := 1.0) -> int:
	var cnt := [0, 0, 0, 0]
	for c in data.pool:
		if f.call(c) and _card_ok(c) and not exclude.has(c.id):
			cnt[c.rarity] += 1
	var r := _roll_rarity(rare_mult)
	for need in range(maxi(n, 1), 0, -1):
		for dr in [0, -1, 1, -2, 2, -3, 3]:
			var rr: int = r + dr
			if rr >= 0 and rr <= 3 and cnt[rr] >= need:
				return rr
	return -1


## Cartas da oferta: mesma raridade e mesmo nível (opção "level") para todas. `end_act`: carta de fim de ato.
func _card_options(n: int, f: Callable, end_act := false) -> Array:
	var opts: Array = []
	var ex: Array = []
	var one := _single_rarity(f, n, [], float(R["offer_upgrades"]["act_end_rare_mult"]) if end_act else 1.0)
	var f1 := func(cd: CardDef): return cd.rarity == one and f.call(cd)
	var lv := roll_offer_level(end_act)
	for k in n:
		var c := _pick_card(f1, ex)
		if c:
			ex.append(c.id)
			opts.append({"kind": "card", "id": c.id, "level": lv})
	return opts


## Fim de ato: 3 cartas quaisquer (mais chance de rara e de já melhoradas), recusável; vem antes da relíquia.
func _offer_act_card() -> void:
	var n := int(R["offer_upgrades"]["act_end_options"])
	_push_offer("act_card", _card_options(n, func(_cd: CardDef): return true, true), {"act": act})


## Até n cartas diferentes do deck que ainda podem subir de nível (-1 = todas).
func _level_up_options(n: int) -> Array:
	var pool: Array = []
	for ci in cards:
		if ci.level < int(R["card_levels"]["max"]):
			pool.append(ci)
	return _pick_insts(pool, n, "upgrade")


func _can_remove() -> bool:
	return cards.size() > int(R["deck"]["min_in_run"])


## Opções de remoção (n = -1: o deck inteiro, para escolher qualquer carta). Nunca abaixo do deck mínimo.
func _remove_options(n: int) -> Array:
	if not _can_remove():
		return []
	return _pick_insts(cards.duplicate(), n, "remove")


## Cópias iguais (mesma carta, nível e modificadores) aparecem uma vez só.
func _pick_insts(all: Array, n: int, kind: String) -> Array:
	var pool: Array = []
	var seen := {}
	for ci in all:
		var key := "%s/%d/%d" % [ci.def.id, ci.level, ci.mods]
		if not seen.has(key):
			seen[key] = true
			pool.append(ci)
	var opts: Array = []
	if n < 0:
		for ci in pool:
			opts.append({"kind": kind, "uid": ci.uid, "card": ci.def.id, "level": ci.level})
		return opts
	for k in n:
		if pool.is_empty():
			break
		var ci: CardInst = pool[rng.randi_range(0, pool.size() - 1)]
		pool.erase(ci)
		opts.append({"kind": kind, "uid": ci.uid, "card": ci.def.id, "level": ci.level})
	return opts


func _offer_level() -> void:
	var n := int(deck_rules.get("offer_options", R["offers"]["options"]))
	var opts: Array = []
	var ex: Array = []
	var tries := 0
	# Uma oferta nunca mistura tipos (rodada 09/11/2026): sorteia o tipo uma vez.
	var cards_first := rng.randf() < float(R["offers"]["new_card_weight"])
	var want_cards := cards_first
	var one := -2   # raridade única da oferta, sorteada na primeira carta
	var lv := roll_offer_level()   # nível único da oferta
	while opts.size() < n and tries < 20:
		tries += 1
		if tries == 11 and opts.is_empty():
			want_cards = not cards_first   # o tipo sorteado não tem opção: tenta o outro
		if want_cards:
			if one == -2:
				one = _single_rarity(func(_cd: CardDef): return true, n)
			var c := _pick_card(func(cd: CardDef): return cd.rarity == one, ex)
			if c:
				ex.append(c.id)
				opts.append({"kind": "card", "id": c.id, "level": lv})
		else:
			var m := _mod_option(ex)
			if m.size() > 0:
				ex.append(str(m["uid"]) + str(m["mod"]))
				opts.append(m)
	_push_offer("level", opts)


const SKIP := -1


## Escolhe a opção k da oferta atual; SKIP (-1) recusa (toda recompensa pode ser recusada).
func choose(k: int) -> bool:
	if offers.is_empty():
		return false
	var o: Dictionary = offers[0]
	var opts: Array = o["options"]
	if k == SKIP:
		# Na loja, recusar é sair (ou voltar da escolha da carta para a loja).
		if o["source"] != "shop" and o["source"] != "shop_pick":
			stats["skipped"] += 1
		offers.pop_front()
		return true
	if k < 0 or k >= opts.size():
		return false
	var op: Dictionary = opts[k]
	if o["source"] == "shop":
		return _buy(k)
	if op["kind"] == "event_opt":
		if not event_option_ok(op):
			return false
		var ep: Dictionary = stats["event_picks"]
		var ek := _opt_key(op)
		ep[ek] = int(ep.get(ek, 0)) + 1
		offers.pop_front()
		Effects.run(self, data.events_def[op["event"]]["options"][int(op["opt"])]["do"])
		return true
	var pk: Dictionary = stats["picked"]
	var key := _opt_key(op)
	pk[key] = int(pk.get(key, 0)) + 1
	if o["source"] == "shop_pick":
		# Escolheu a carta do item comprado: paga e tira o item da loja (que está logo atrás).
		_pay(int(o["price"]))
		_apply_option(op)
		offers.pop_front()
		if offers.size() > 0 and offers[0]["source"] == "shop":
			offers[0]["options"].remove_at(int(o["shop_k"]))
			if op["kind"] == "remove":
				shop_removes += 1
			if offers[0]["options"].is_empty():
				offers.pop_front()
		return true
	var follow := _apply_option(op)
	if o.has("elixir"):
		elixir = minf(elixir_max, elixir + float(o["elixir"]))
	offers.pop_front()
	if follow.size() > 0:
		_push_offer("location", follow, {"loc": "bridge", "won": true})
		offers.push_front(offers.pop_back())
	return true


## Compra o item k da loja aberta. Carta e modificador saem na hora; nível e remoção abrem a escolha da carta.
func _buy(k: int) -> bool:
	var o: Dictionary = offers[0]
	var op: Dictionary = o["options"][k]
	if gold + 0.0001 < float(op["price"]):
		return false
	var item: Dictionary = op["item"]
	if item["kind"] == "pick":
		var pickopts := _level_up_options(-1) if item["what"] == "upgrade" else _remove_options(-1)
		if pickopts.is_empty():
			return false
		_push_offer("shop_pick", pickopts, {"price": op["price"], "shop_k": k, "what": item["what"]})
		offers.push_front(offers.pop_back())
		return true
	var pk: Dictionary = stats["picked"]
	var key := _opt_key(op)
	pk[key] = int(pk.get(key, 0)) + 1
	_pay(int(op["price"]))
	if item["kind"] == "relic":
		var src: Dictionary = stats.get("relic_src", {})
		src["shop"] = int(src.get("shop", 0)) + 1
		stats["relic_src"] = src
	_apply_option(item)
	o["options"].remove_at(k)
	if o["options"].is_empty():
		offers.pop_front()
	return true


func _pay(p: int) -> void:
	gold = maxf(0.0, gold - p)
	stats["gold_spent"] += p
	stats["shop_buys"] += 1
	# Cofre Vivo: cada `shop_max_gain` de ouro gasto na loja vira +1 de elixir máximo (até shop_max_cap).
	var step_ := rv("shop_max_gain")
	if step_ > 0.0 and vault_gain < rv("shop_max_cap"):
		vault_spent += p
		while vault_spent >= step_ and vault_gain < rv("shop_max_cap"):
			vault_spent -= step_
			vault_gain += 1.0
			relic_max_gain += 1.0
		recalc_elixir_max()


func can_afford(op: Dictionary) -> bool:
	return gold + 0.0001 >= float(op.get("price", 0))


## Aplica uma opção de oferta ao deck. Devolve a escolha seguinte (Ponte vencida: o tipo escolhido abre as opções).
func _apply_option(op: Dictionary) -> Array:
	var follow: Array = []
	match str(op["kind"]):
		"card":
			var ci := _new_inst(data.card(op["id"]))
			ci.level = clampi(int(op.get("level", 1)), 1, int(R["card_levels"]["max"]))
			queue.push_front(ci)
			_refill()
		"mod":
			for ci in cards:
				if ci.uid == op["uid"]:
					if ci.mods == 0:
						ci.first_mod = int(K.MOD_BY_ID[op["mod"]])
					ci.mods |= int(K.MOD_BY_ID[op["mod"]])
		"upgrade":
			for ci in cards:
				if ci.uid == op["uid"]:
					ci.level = mini(ci.level + 1, int(R["card_levels"]["max"]))
		"remove":
			_remove_uid(op["uid"])
		"pick":
			# Ponte vencida: escolheu o tipo, agora escolhe a recompensa (como num local vencido).
			var n := int(R["offers"]["location_win"])
			match str(op["what"]):
				"card":
					follow = _card_options(n, _rarity_filter(R["location_rewards"]["bridge"]["rarities"]))
				"upgrade":
					follow = _level_up_options(n)
				"remove":
					follow = _remove_options(-1)
		"relic":
			gain_relic(str(op["id"]))
		"transform":
			# Bibliotecário: a carta vira outra sorteada de raridade acima (ou igual, se já é lendária).
			for ci in cards:
				if ci.uid == op["uid"]:
					var want := mini(ci.def.rarity + 1, 3)
					var nc := _pick_card(func(cd: CardDef): return cd.rarity == want and cd.id != ci.def.id, [])
					if nc == null:
						nc = _pick_card(func(cd: CardDef): return cd.rarity >= ci.def.rarity and cd.id != ci.def.id, [])
					if nc:
						ci.def = nc
						card_of_uid[ci.uid] = nc.id
		"copy":
			for ci in cards.duplicate():
				if ci.uid == op["uid"]:
					var cp := _new_inst(ci.def)
					cp.level = ci.level
					cp.mods = ci.mods
					cp.first_mod = ci.first_mod
					queue.push_front(cp)
					_refill()
	return follow


func _refill() -> void:
	for i in hand.size():
		if hand[i] == null:
			hand[i] = draw_card()


func _remove_uid(u: int) -> void:
	for ci in cards.duplicate():
		if ci.uid == u:
			cards.erase(ci)
			queue.erase(ci)
			discard.erase(ci)
			benched.erase(ci)
			returned.erase(ci.uid)
			var hi_ := hand.find(ci)
			if hi_ >= 0:
				hand[hi_] = draw_card()


# ================================================================ consultas

func hand_card(i: int) -> CardInst:
	if i < 0 or i >= hand.size():
		return null
	return hand[i]


## Hash do estado, para o teste de determinismo.
func state_hash() -> int:
	var h := hash([tick, hero.x, hero.y, hero.hp, hero.level, elixir, player_level, units.count])
	for i in units.hi:
		if units.alive[i] == 1:
			h = hash([h, units.px[i], units.py[i], units.hp[i]])
	return h
