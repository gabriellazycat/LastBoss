class_name CardDef
extends RefCounted
## Definição imutável de uma carta (ou unidade auxiliar), lida do JSON.

var id: String
var idx: int
var category: String   # field, route, lair, finisher, aux
var type: String       # swarm, monster, spell, structure, route, lair, finisher
var tags: int = 0
var tag_names: Array = []
var arch: int = K.Arch.NONE
var rarity: int = 0
var cost: int = 0
var count: int = 1
var xp_parts: int = 1
var hp: float = 0.0
var dps: float = 0.0
var attack_interval: float = 1.0
var speed: float = 0.0
var range: float = 1.0
var fx: Dictionary = {}
var fly := false
var beast := false          # Fera (Praga): fx.beast; os ratos e morcegos são Bando, nunca Fera
var projectile := false
var is_unit := false
var is_spell := false
var is_structure := false
var radius := 0.4
var lvl: Array = []        # números que crescem com o nível: chaves de fx ou count, hp, dps, cost
var n3: Dictionary = {}    # efeito especial do nível 3
var growth := 0.25         # +25% por nível (rules.card_levels.growth)
var owner := "common"      # vilão dono da carta: plague, dragon, lich ou common (sim/cards/<dono>.gd)
var ops: Array = []        # efeito declarado em dados, rodado por CardFxLib ao jogar (docs/CARD_FX.md)
var on_death: Array = []   # ops rodadas por CardFxLib quando uma unidade desta carta morre
var on_death_any := false  # true: on_death roda em qualquer morte (sacrifício e expiração também), não só herói/sozinha
var ai: Dictionary = {}    # como os bots jogam a carta (docs/CARD_FX.md, "Vocabulário de ai")
var ai_keys: Array = []    # ai.keys: rótulos que outras cartas procuram (combos)


static func from_dict(d: Dictionary, i: int, cat_override := "") -> CardDef:
	var c := CardDef.new()
	c.id = d["id"]
	c.idx = i
	c.category = cat_override if cat_override != "" else str(d.get("category", "field"))
	c.type = str(d.get("type", "monster"))
	c.tag_names = d.get("tags", [])
	for t in c.tag_names:
		c.tags |= int(K.TAG_BY_NAME.get(t, 0))
	c.arch = int(K.ARCH_BY_NAME.get(str(d.get("archetype", "")), K.Arch.NONE))
	c.rarity = maxi(0, K.RARITIES.find(str(d.get("rarity", "common"))))
	c.cost = int(d.get("cost", 0))
	c.count = int(d.get("count", 1))
	c.xp_parts = maxi(1, int(d.get("xp_parts", c.count)))
	c.hp = float(d.get("hp", 0))
	c.dps = float(d.get("dps", 0))
	c.attack_interval = float(d.get("attack_interval", 1.0))
	c.speed = float(d.get("speed", 0))
	c.range = float(d.get("range", 1))
	c.fx = d.get("fx", {})
	c.lvl = d.get("lvl", [])
	c.n3 = d.get("n3", {})
	c.owner = str(d.get("owner", "common"))
	c.ops = d.get("ops", [])
	c.on_death = d.get("on_death", [])
	c.on_death_any = bool(d.get("on_death_any", false))
	c.ai = d.get("ai", {})
	c.ai_keys = c.ai.get("keys", [])
	c.fly = bool(d.get("fly", false))
	c.beast = bool(c.fx.get("beast", false))
	c.projectile = bool(c.fx.get("projectile", false))
	c.is_spell = c.type == "spell"
	c.is_structure = c.type == "structure"
	c.is_unit = c.arch != K.Arch.NONE
	if c.is_structure:
		c.radius = 0.9
	elif c.arch == K.Arch.TANK:
		c.radius = 0.8
	elif c.arch == K.Arch.SWARM:
		c.radius = 0.25
	return c


func is_field() -> bool:
	return category == "field"


## Multiplicador do nível: 1, 1 + g, 1 + 2g.
func mult(level: int) -> float:
	return 1.0 + growth * (level - 1)


func scales(key: String) -> bool:
	return lvl.has(key)


## Número de fx no nível dado (o especial do N3 sobrepõe a mesma chave).
func fxv(key: String, level: int, default := 0.0) -> float:
	if level >= 3 and n3.has(key):
		return float(n3[key])
	var v := float(fx.get(key, default))
	return v * mult(level) if scales(key) else v


func count_at(level: int) -> int:
	return int(round(count * mult(level))) if scales("count") else count


func hp_at(level: int) -> float:
	return hp * mult(level) if scales("hp") else hp


func dps_at(level: int) -> float:
	return dps * mult(level) if scales("dps") else dps


## Cartas sem número para crescer ficam 1 mais baratas por nível (mínimo 1).
func cost_at(level: int) -> int:
	return maxi(1, cost - (level - 1)) if scales("cost") else cost


func has_n3(level: int, key: String) -> bool:
	return level >= 3 and n3.has(key)
