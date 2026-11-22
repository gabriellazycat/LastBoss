class_name CovilDemo
extends Control
## Cena autônoma da tela do Covil (frente E): MetaSave temporário em user://covil_demo.save, Almas de sobra e uma árvore
## de mentira mais cheia que a de data/meta_tree.json (só na memória; a frente D troca pelos nós reais).
## Uso (Godot em segundo plano, janela fora da tela):
##   "$G" --position -6000,0 --path . res://game/covil_demo.tscn -- --shot=arquivo.png [--view=overview|zoom|detail|sealed|bought]
##   "$G" --position -6000,0 --path . res://game/covil_demo.tscn -- --shots=docs/metaprogressao/   (as cinco capturas e sai)
## Sem argumentos abre a tela para mexer (mouse: arrastar, roda).

const SAVE := "user://covil_demo.save"
const VIEWS := ["overview", "zoom", "detail", "sealed", "bought"]

var data: GameData
var meta: MetaSave
var screen: CovilScreen
var args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	Settings.load_all()
	TranslationServer.set_locale(str(Settings.v.get("language", "pt")))
	UiSkins.apply()
	theme = UiKit.make_theme()
	data = GameData.load_dir()
	use_fake_tree(data)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	meta = MetaSave.load_or_new(data, SAVE)
	meta.upgrades = {}
	meta.almas = 0
	meta.almas_earned = 0
	meta.add_almas(6000)
	var shooting := args.has("shot") or args.has("shots")
	if shooting:
		get_window().size = Vector2i(1920, 1080)
		get_window().mode = Window.MODE_WINDOWED
	_open_screen(1)
	if shooting:
		await _shoot()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
		get_tree().quit()


func _open_screen(act2: int) -> void:
	if screen:
		screen.queue_free()
	screen = CovilScreen.new()
	screen.act2_override = act2
	screen.setup(data, meta)
	add_child(screen)
	screen.open_library.connect(func(): print("covil_demo: Biblioteca"))
	screen.start_run.connect(func(): print("covil_demo: Começar run"))
	screen.back.connect(func(): print("covil_demo: Voltar"))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shoot() -> void:
	await _frames(6)
	if args.has("shots"):
		var dir := str(args["shots"])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		for v in VIEWS:
			await _scene(v)
			await _save("%scovil_%s.png" % [dir if dir.ends_with("/") else dir + "/", {"overview": "visao_geral", "zoom": "zoom_setor",
				"detail": "janela", "sealed": "troca_ato_trancado", "bought": "comprados"}[v]])
	else:
		await _scene(str(args.get("view", "overview")))
		await _save(str(args["shot"]))


func _save(path: String) -> void:
	await _frames(4)
	var img := get_viewport().get_texture().get_image()
	var out := path if (path.is_absolute_path() and not path.begins_with("res://") and not path.begins_with("user://")) else ProjectSettings.globalize_path(path if path.contains("://") else "res://" + path)
	img.save_png(out)
	print("covil_demo: salvo ", path, " ", img.get_size())


func _buy_chain(ids: Array) -> void:
	for id in ids:
		while screen.view.can_buy(id):
			screen.view.buy_node(id)


## Monta o estado de cada captura.
func _scene(v: String) -> void:
	meta.upgrades = {}
	meta.almas = 0
	meta.almas_earned = 0
	meta.add_almas(6000)
	_open_screen(0 if v == "sealed" else 1)
	await _frames(4)
	var view := screen.view
	view.fit()
	match v:
		"zoom":
			_buy_chain(["atr_elixir_max_1", "atr_elixir_max_2", "atr_regen_1"])
			view.focus_sector("atributos", 1.35)
		"detail":
			_buy_chain(["atr_elixir_max_1", "atr_elixir_max_2", "atr_regen_1", "atr_mao_1"])
			view.focus_sector("atributos", 1.0)
			view.select("atr_elixir_max_3")
		"sealed":
			_buy_chain(["atr_elixir_max_1", "loc_ritual_1"])
			view.focus_sector("troca_ato", 0.95)
			view.select("ato_1")
		"bought":
			_buy_chain(["atr_elixir_max_1", "atr_elixir_max_2", "atr_elixir_max_3", "atr_regen_1", "atr_regen_2", "atr_mao_1",
				"atr_mao_2", "atr_recarga_1", "loc_ritual_1", "loc_ritual_2", "loc_ritual_3a", "loc_fonte_1", "loc_fonte_2",
				"loc_forja_1", "are_boss_hp_1", "are_boss_hp_2", "are_arm_1", "rel_slot_1", "rel_slot_2", "ger_offer_hero",
				"ger_gold_start_1", "ger_gold_start_2", "ger_almas_1"])
	await _frames(3)


# ---------------------------------------------------------------- árvore de mentira (só memória)

static func _n(id: String, sector: String, parent: String, branch: String, icon: String, name: String, desc: String,
		costs: Array, fx: Dictionary) -> Dictionary:
	return {"id": id, "sector": sector, "parent": parent, "branch": branch, "icon": icon, "name": name, "desc": desc,
		"costs": costs, "fx": fx}


## Árvore com ~50 nós nos seis setores, para ver a roda cheia (sobrescreve data.meta_tree e data.meta_nodes na memória).
static func fake_tree(base: Dictionary) -> Dictionary:
	var nodes: Array = []
	# Atributos: quatro faixas.
	nodes.append(_n("atr_elixir_max_1", "atributos", "", "elixir", "elixir", "Elixir máximo I", "Guarda mais elixir.", [30, 60, 100], {"elixir.max": [1.0, 2.0, 3.0]}))
	nodes.append(_n("atr_elixir_max_2", "atributos", "atr_elixir_max_1", "elixir", "elixir", "Elixir máximo II", "Guarda ainda mais.", [80, 140], {"elixir.max": [1.0, 2.0]}))
	nodes.append(_n("atr_elixir_max_3", "atributos", "atr_elixir_max_2", "elixir", "elixir", "Elixir máximo III", "O limite final do cálice.", [200, 320], {"elixir.max": [1.0, 2.0]}))
	nodes.append(_n("atr_regen_1", "atributos", "atr_elixir_max_1", "elixir", "regen", "Fluxo de elixir", "O elixir enche mais rápido.", [50, 90], {"elixir.regen_mult": [0.05, 0.10]}))
	nodes.append(_n("atr_regen_2", "atributos", "atr_regen_1", "elixir", "regen", "Fluxo II", "Mais rápido ainda.", [140, 220], {"elixir.regen_mult": [0.05, 0.10]}))
	nodes.append(_n("atr_mao_1", "atributos", "", "mao", "hand", "Mão inicial", "Começa a run com mais uma carta.", [90], {"mao.inicial": [1.0]}))
	nodes.append(_n("atr_mao_2", "atributos", "atr_mao_1", "mao", "hand", "Mão ampla", "Mais uma carta na mão inicial.", [260], {"mao.inicial": [1.0]}))
	nodes.append(_n("atr_recarga_1", "atributos", "", "recarga", "recarga", "Recarga da carta", "Cartas voltam mais rápido.", [60, 110, 180], {"recarga.mult": [-0.05, -0.1, -0.15]}))
	nodes.append(_n("atr_inicio_1", "atributos", "atr_recarga_1", "recarga", "inicio", "Elixir inicial", "Começa com elixir de sobra.", [70, 130], {"elixir.inicial": [1.0, 2.0]}))
	# Locais: um ramo por local, recompensa/facilidade.
	var locais := [["ritual", "Ritual", "ritual"], ["fonte", "Fonte", "loc"], ["forja", "Forja", "loc"], ["mercado", "Mercado", "gold"],
		["santuario", "Santuário", "loc"], ["tesouro", "Tesouro", "gold"]]
	for l in locais:
		var b: String = l[0]
		nodes.append(_n("loc_%s_1" % b, "locais", "", b, l[2], l[1], "Melhora o local %s." % l[1], [60, 120], {"locais.%s.mult" % b: [0.25, 0.5]}))
		nodes.append(_n("loc_%s_2" % b, "locais", "loc_%s_1" % b, b, l[2], l[1] + ": rendimento", "Mais recompensa.", [110, 200], {"locais.%s.rec" % b: [0.2, 0.4]}))
		if b == "ritual" or b == "fonte":
			nodes.append(_n("loc_%s_3a" % b, "locais", "loc_%s_2" % b, b, l[2], l[1] + ": duração", "Dura mais tempo.", [160], {"locais.%s.dur" % b: [0.5]}))
			nodes.append(_n("loc_%s_3b" % b, "locais", "loc_%s_2" % b, b, l[2], l[1] + ": facilidade", "Fica mais fácil.", [160], {"locais.%s.fac" % b: [0.5]}))
	nodes.append(_n("loc_ritual_3", "locais", "loc_ritual_2", "ritual", "ritual", "Ritual triplo", "O elixir do ritual triplica.", [300], {"locais.ritual.elixir_mult": [2.0]}))
	# Arena.
	nodes.append(_n("are_boss_hp_1", "arena", "", "chefe", "boss", "Corpo do chefe I", "Partes do chefe com mais vida.", [50, 100], {"arena.boss_hp_mult": [0.1, 0.2]}))
	nodes.append(_n("are_boss_hp_2", "arena", "are_boss_hp_1", "chefe", "boss", "Corpo do chefe II", "Ainda mais vida.", [180, 300], {"arena.boss_hp_mult": [0.1, 0.2]}))
	nodes.append(_n("are_arm_1", "arena", "", "braco", "arm", "Braço do chefe", "O golpe do braço machuca mais.", [70, 130, 220], {"arena.arm_dmg_mult": [0.15, 0.3, 0.45]}))
	nodes.append(_n("are_struct_1", "arena", "", "estruturas", "struct", "Estruturas", "Estruturas mais fortes.", [60, 120], {"arena.struct_hp_mult": [0.2, 0.4]}))
	nodes.append(_n("are_struct_2", "arena", "are_struct_1", "estruturas", "struct", "Estruturas II", "Reforço extra.", [150], {"arena.struct_dmg_mult": [0.2]}))
	# Relíquias.
	nodes.append(_n("rel_slot_1", "reliquias", "", "", "relic", "Vitrine de relíquias", "Uma opção a mais.", [80], {"reliquias.extra_options": [1.0]}))
	nodes.append(_n("rel_slot_2", "reliquias", "rel_slot_1", "", "relic", "Vitrine ampla", "Mais uma opção.", [220], {"reliquias.extra_options": [1.0]}))
	nodes.append(_n("rel_nivel_1", "reliquias", "", "nivel", "relic", "Relíquias lapidadas", "Relíquias sobem de nível.", [100, 200], {"reliquias.nivel": [1.0, 2.0]}))
	# Troca de ato.
	nodes.append(_n("ato_1", "troca_ato", "", "", "act", "Fôlego da travessia", "Ao trocar de ato o elixir volta em parte.", [70, 140], {"ato.elixir_refill": [0.5, 1.0]}))
	nodes.append(_n("ato_2", "troca_ato", "ato_1", "", "act", "Estrada firme", "A estrada do próximo ato começa mais curta.", [160], {"ato.estrada": [-0.1]}))
	nodes.append(_n("ato_3", "troca_ato", "ato_2", "", "act", "Chegada triunfal", "Um poder surge ao trocar de ato.", [320], {"ato.poder": [1.0]}))
	# Geral.
	nodes.append(_n("ger_offer_hero", "geral", "", "oferta", "offer", "Oferta por herói", "Oferta de carta a cada herói derrotado.", [120], {"oferta_por_heroi": [1.0]}))
	nodes.append(_n("ger_gold_start_1", "geral", "ger_offer_hero", "oferta", "gold", "Cofre inicial", "Mais ouro no começo.", [40, 80], {"geral.ouro_inicial": [10.0, 25.0]}))
	nodes.append(_n("ger_gold_start_2", "geral", "ger_gold_start_1", "oferta", "gold", "Cofre cheio", "Ainda mais ouro.", [150], {"geral.ouro_inicial": [25.0]}))
	nodes.append(_n("ger_almas_1", "geral", "", "almas", "souls", "Colheita de Almas", "Ganha mais Almas por run.", [100, 220, 400], {"geral.almas_mult": [0.05, 0.1, 0.15]}))
	var t := base.duplicate(true)
	t["nodes"] = nodes
	return t


static func use_fake_tree(d: GameData) -> void:
	d.meta_tree = fake_tree(d.meta_tree)
	d.meta_nodes = {}
	for n in d.meta_tree["nodes"]:
		d.meta_nodes[n["id"]] = n
