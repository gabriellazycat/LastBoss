class_name ArtDirections
extends RefCounted
## Direções de arte completas (chão + herói + monstros juntos), para comparar a tela inteira e não camada
## por camada (docs/ESTUDO_DE_ARTE.md). Configurações → Visual → "Direção de arte" grava as três chaves.

const LIST := [
	{"name": "C · Escolha de 07/11 (padrão)", "look_ground": 2, "look_hero": 4, "look_enemies": 3},
	{"name": "A · Pintado em tudo", "look_ground": 5, "look_hero": 4, "look_enemies": 3},
	{"name": "B · Cartum com contorno", "look_ground": 6, "look_hero": 2, "look_enemies": 2},
	{"name": "D · Aventura, dia (RoR2, CC0)", "look_ground": 7, "look_hero": 5, "look_enemies": 5},
	{"name": "E · Aventura, noite (Soulstone, CC0)", "look_ground": 8, "look_hero": 5, "look_enemies": 5},
	{"name": "F · Própria refinada", "look_ground": 9, "look_hero": 6, "look_enemies": 6},
	{"name": "Antiga (tudo 0)", "look_ground": 0, "look_hero": 0, "look_enemies": 0},
]
const KEYS := ["look_ground", "look_hero", "look_enemies"]


## Índice da direção que bate com as configurações atuais, ou -1 (mistura personalizada).
static func current() -> int:
	for i in LIST.size():
		var ok := true
		for k in KEYS:
			ok = ok and int(Settings.v.get(k, 0)) == int(LIST[i][k])
		if ok:
			return i
	return -1


static func apply(i: int) -> void:
	for k in KEYS:
		Settings.v[k] = LIST[i][k]


## Texto do --set= de cada direção (para capturas e para o doc).
static func set_arg(i: int) -> String:
	return ",".join(KEYS.map(func(k): return "%s:%d" % [k, LIST[i][k]]))
