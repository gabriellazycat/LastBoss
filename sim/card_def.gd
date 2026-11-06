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
var projectile := false
var is_unit := false
var is_spell := false
var is_structure := false
var radius := 0.4


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
	c.fly = bool(d.get("fly", false))
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
