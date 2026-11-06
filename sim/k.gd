class_name K
extends RefCounted
## Constantes compartilhadas pela simulação e pelo visual.

enum Arch { SWARM, SHOOTER, KAMIKAZE, TANK, CHASER, STRUCTURE, SUPPORT, NONE }
const ARCH_BY_NAME := {
	"swarm": Arch.SWARM, "shooter": Arch.SHOOTER, "kamikaze": Arch.KAMIKAZE, "tank": Arch.TANK,
	"chaser": Arch.CHASER, "structure": Arch.STRUCTURE, "support": Arch.SUPPORT,
}

const TAG_PACK := 1
const TAG_UNDEAD := 2
const TAG_FIRE := 4
const TAG_SHADOW := 8
const TAG_CONSTRUCT := 16
const TAG_BY_NAME := {"pack": TAG_PACK, "undead": TAG_UNDEAD, "fire": TAG_FIRE, "shadow": TAG_SHADOW, "construct": TAG_CONSTRUCT}

# Flags de unidade.
const F_FLY := 1
const F_NO_XP := 2        # Sombrio, Alma (ressuscitada), espectro
const F_REVIVED := 4      # já voltou uma vez (Totem)
const F_EXPLOSIVE := 8
const F_CURSED := 16
const F_PROJECTILE := 32
const F_STONE := 64       # Gárgula petrificada: imune
const F_BITTEN := 128     # Mímico já mordeu
const F_DEFEND := 256     # invocada perto do chefe: defende
const F_ABSORBED := 512

# Modificadores de carta (bitmask na instância).
const M_VETERAN := 1
const M_CHEAP := 2
const M_EXPLOSIVE := 4
const M_CURSED := 8
const M_SHADOWY := 16
const MOD_BY_ID := {"veteran": M_VETERAN, "cheap": M_CHEAP, "explosive": M_EXPLOSIVE, "cursed": M_CURSED, "shadowy": M_SHADOWY}
const MOD_IDS := ["veteran", "cheap", "explosive", "cursed", "shadowy"]

enum Phase { ROAD, ARENA, OVER }
enum Result { NONE, WIN_EARLY, WIN, LOSS, TIMEOUT }
const RESULT_NAMES := ["none", "win_early", "win", "loss", "timeout"]

const RARITIES := ["common", "uncommon", "rare", "legendary"]

# Causas de morte de unidade.
enum Death { HERO, SELF, SACRIFICE, EXPIRE }

# Por que uma carta não pode ser jogada agora.
enum Block { OK, NO_ELIXIR, WRONG_PHASE, CONDITION, BAD_TARGET, STACK_LIMIT, OFFER_PENDING, OVER }

# Eventos (para o visual): [tipo, x, y, valor, extra]
enum Ev { DAMAGE_HERO, DAMAGE_UNIT, DEATH, SPAWN, EXPLOSION, SHOT, HERO_LEVEL, PLAYER_LEVEL, SHIELD_BREAK,
	SPELL, SHRINE, CONTRACT, PART_DESTROYED, TELEPORT, ARENA, HEAL, CURSE, FEAR, SPIN, LOCATION }
