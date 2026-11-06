"""Conversão única: 'Revisao do conteudo - Last Boss.xlsx' -> data/*.json.

Depois desta conversão o JSON é a fonte da verdade (o ajustador edita o JSON).
Rodar de novo sobrescreve data/. Uso: python -I tools/xlsx_to_json.py
Os números saem da planilha; os parâmetros de efeito escritos em prosa na
planilha estão transcritos em FX abaixo (com os mesmos números).
"""
import json
import os
import sys

import openpyxl

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
XLSX = os.path.join(ROOT, "Revisao do conteudo - Last Boss.xlsx")
OUT = os.path.join(ROOT, "data")

RARITY = {"Comum": "common", "Incomum": "uncommon", "Raro": "rare", "Lendário": "legendary"}
TYPE = {"Enxame": "swarm", "Monstro": "monster", "Feitiço": "spell", "Estrutura": "structure"}
TAG = {"Bando": "pack", "Morto-vivo": "undead", "Fogo": "fire", "Sombra": "shadow", "Construção": "construct"}
ARCH = {"Enxame": "swarm", "Atirador": "shooter", "Kamikaze": "kamikaze", "Tanque": "tank",
        "Perseguidor": "chaser", "Estrutura": "structure", "Suporte": "support"}

FIELD_IDS = {
    "Horda de Ratos": "rat_horde", "Esqueletos Arqueiros": "skeleton_archers",
    "Goblin Dinamiteiro": "goblin_dynamiter", "Slime": "slime", "Raio Sombrio": "shadow_bolt",
    "Ninho de Morcegos": "bat_nest", "Rei dos Ratos": "rat_king", "Totem de Ossos": "bone_totem",
    "Cultistas": "cultists", "Ogro": "ogre", "Teia": "web", "Mímico": "mimic",
    "Óleo Fervente": "boiling_oil", "Fantasma": "ghost", "Torre de Gárgula": "gargoyle_tower",
    "Lobisomem": "werewolf", "Golem de Sucata": "scrap_golem", "Banquete de Almas": "soul_feast",
}
ROUTE_IDS = {
    "Ponte Quebrada": "broken_bridge", "Placa Falsa": "false_sign", "Isca de Ouro": "gold_bait",
    "Queimar Vila": "burn_village", "Coletor de Almas": "soul_collector",
    "Biblioteca Proibida": "forbidden_library", "Forja Sombria": "dark_forge",
    "Muralhas do Covil": "lair_walls",
}
FIN_IDS = {
    "Raio Cósmico do Chefão Final": "cosmic_ray", "Prisão de Ossos": "bone_prison",
    "Olhar Petrificante": "petrifying_gaze", "Exército dos Condenados": "damned_army",
    "Fúria Sombria": "dark_fury", "Pacto Sombrio": "dark_pact",
}

# Parâmetros dos efeitos (transcritos da coluna "Efeito" da planilha).
# count = unidades que nascem ao jogar; xp_parts = divisor do XP da carta.
FX = {
    "rat_horde": {},
    "skeleton_archers": {"retreat": 4.0, "projectile": True},
    "goblin_dynamiter": {"explode_damage": 180, "explode_radius": 2.5},
    "slime": {"count": 1, "split": [{"hp": 110, "dps": 6, "n": 2}, {"hp": 50, "dps": 3, "n": 2}]},
    "shadow_bolt": {"damage": 140, "length": 10.0, "width": 1.5, "pierce_shield": True},
    "bat_nest": {"count": 1, "spawn": "bat", "spawn_interval": 3.0, "spawn_duration": 15.0},
    "rat_king": {"count": 1, "aura_radius": 6.0, "aura_pack_damage": 0.5, "death_spawn": "rat", "death_spawn_n": 6},
    "bone_totem": {"duration": 20.0, "radius": 6.0, "revive": "skeleton"},
    "cultists": {"spell_discount": 1, "spell_min_cost": 1, "projectile": True},
    "ogre": {"knockback": 4.0},
    "web": {"radius": 3.0, "duration": 4.0, "slow": 0.5},
    "mimic": {"lure_radius": 10.0, "bite": 120, "curses": 2},
    "boiling_oil": {"radius": 3.0, "duration": 8.0, "dps": 10, "soaked": 6.0},
    "ghost": {"phase": True, "fear": 1.5, "fear_cooldown": 6.0},
    "gargoyle_tower": {"stone_radius": 3.0, "projectile": True},
    "werewolf": {"speed_bonus": 1.0, "hp_threshold": 0.5},
    "scrap_golem": {"absorb_radius": 5.0, "absorb_hp": 40, "hp_cap": 1500},
    "soul_feast": {"radius": 4.0, "bonus_per_card": 1},
    "broken_bridge": {"target": "branch"},
    "false_sign": {"target": "branch"},
    "gold_bait": {"target": "point", "xp": 40, "max_detour": 30.0},
    "burn_village": {"target": "location", "location": "village"},
    "soul_collector": {"elixir_regen": 0.10, "stack": 3},
    "forbidden_library": {"hand": 1, "stack": 1},
    "dark_forge": {"monster_hp": 0.10, "stack": 3},
    "lair_walls": {"hero_hp_loss": 0.10, "stack": 1},
    "cosmic_ray": {"cond": "front", "cone": 45.0, "range": 12.0, "damage": 1200, "width": 2.0, "pierce_shield": True},
    "bone_prison": {"cond": "after_teleport", "window": 3.0, "root": 3.0},
    "petrifying_gaze": {"cond": "front", "cone": 45.0, "range": 12.0, "petrify": 2.0},
    "damned_army": {"cond": "hero_low", "threshold": 0.30, "max": 40, "hp": 40, "dps": 10, "duration": 5.0},
    "dark_fury": {"cond": "part_destroyed", "heal": 0.20, "damage": 0.50, "duration": 10.0},
    "dark_pact": {"cond": "none", "draw": 2},
}
# Ataques com intervalo diferente de 1 s (golpe = dps * intervalo).
ATTACK_INTERVAL = {"ogre": 2.0}

# Unidades auxiliares que não são cartas (decisões em ARQUITETURA.md).
AUX = [
    {"id": "bat", "archetype": "swarm", "tags": ["pack"], "hp": 30, "dps": 5, "speed": 5.0, "range": 0.8, "fly": True},
    {"id": "rat", "archetype": "swarm", "tags": ["pack"], "hp": 25, "dps": 4, "speed": 5.5, "range": 0.8},
    {"id": "skeleton", "archetype": "chaser", "tags": ["undead"], "hp": 60, "dps": 6, "speed": 3.0, "range": 1.0},
    {"id": "spectre", "archetype": "chaser", "tags": ["undead", "shadow"], "hp": 40, "dps": 10, "speed": 4.5, "range": 1.0},
]


def rows(ws):
    it = ws.iter_rows(values_only=True)
    head = next(it)
    for r in it:
        if r[0] is not None:
            yield dict(zip(head, r))


def tags(s):
    if not s or s == "—":
        return []
    return [TAG[t.strip()] for t in str(s).split(",")]


def num(v):
    if isinstance(v, float) and v.is_integer():
        return int(v)
    return v


def main():
    wb = openpyxl.load_workbook(XLSX, data_only=False)
    base = {r["Parâmetro"]: r["Valor"] for r in rows(wb["Base"])}
    B = lambda k: num(base[k])

    cards = []
    for r in rows(wb["Cartas de campo"]):
        cid = FIELD_IDS[r["Carta"]]
        fx = dict(FX[cid])
        units = num(r["Unidades"])
        count = fx.pop("count", units)
        c = {
            "id": cid, "category": "field", "type": TYPE[r["Tipo"]], "tags": tags(r["Tag"]),
            "archetype": ARCH.get(r["Arquétipo"], "") if r["Arquétipo"] != "—" else "",
            "rarity": RARITY[r["Raridade"]], "cost": num(r["Elixir"]), "count": count,
            "xp_parts": units, "hp": num(r["Vida/unid."]), "dps": num(r["DPS/unid."]),
            "attack_interval": ATTACK_INTERVAL.get(cid, 1.0), "speed": num(r["Vel. (m/s)"]),
            "range": num(r["Alcance (m)"]), "fx": fx,
        }
        cards.append(c)
    for r in rows(wb["Rota e Covil"]):
        cid = ROUTE_IDS[r["Carta"]]
        cat = "route" if r["Categoria"] == "Rota" else "lair"
        cards.append({"id": cid, "category": cat, "type": cat, "tags": [], "rarity": RARITY[r["Raridade"]],
                      "cost": num(r["Elixir"]), "fx": FX[cid]})
    for r in rows(wb["Finalização"]):
        cid = FIN_IDS[r["Carta"]]
        cards.append({"id": cid, "category": "finisher", "type": "finisher", "tags": [],
                      "rarity": RARITY[r["Raridade"]], "cost": num(r["Elixir"]), "fx": FX[cid]})

    rar = {}
    for r in rows(wb["Raridade"]):
        if r["Momento"] in ("0 a 4 min", "4 a 8 min", "8 min em diante"):
            rar[r["Momento"]] = [num(r[k]) for k in ("Comum", "Incomum", "Rara", "Lendária")]

    rules = {
        "sim": {"dt": 0.05, "danger_hz": 5, "target_hz": 5, "max_units": 1024, "despawn_distance": 50.0,
                "max_run_seconds": 1500},
        "elixir": {"seconds_per_point": B("Elixir: segundos por ponto"), "max": B("Elixir máximo"),
                   "start": B("Elixir inicial")},
        "hand_size": 5,
        "ring": {"min": 3.0, "max": 12.0, "spells_ignore_min": True},
        "sacrifice_elixir": 1,
        "hero_xp": {"per_elixir": B("XP do herói por ponto de elixir que morre"),
                    "level2": B("XP do herói para o nível 2"),
                    "growth": B("Crescimento do XP por nível do herói")},
        "player_xp": {"first_level": 900, "growth": B("Crescimento do dano necessário por nível do jogador"),
                      "_note": "first_level = ROUND(dano total estimado * g / ((1+g)^10 - 1), -1) da aba Base"},
        "phase1_target_s": B("Duração da fase 1 (s)"),
        "rarity_by_time": {"breaks_s": [240, 480], "weights": [rar["0 a 4 min"], rar["4 a 8 min"], rar["8 min em diante"]],
                           "order": ["common", "uncommon", "rare", "legendary"]},
        "offers": {"options": 3, "new_card_weight": 0.7, "modifier_weight": 0.3,
                   "shrine_options": 3, "shrine_min_rarity": "rare", "contract_options": 2},
        "contracts": {"first_at": [90, 150], "interval": [120, 180]},
        "road": {"target_length": 1500.0, "forks": [2, 3], "fork_spread": 45.0, "long_branch_extra": [0.35, 0.6],
                 "wiggle": 18.0, "point_step": 6.0, "fork_decision_distance": 25.0, "leash": 8.0,
                 "route_locations": [8, 10], "shrines": [2, 4],
                 "location_weights": {"village": 3, "tavern": 2, "fountain": 2, "ritual": 2, "bridge": 2},
                 "min_location_gap": 60.0},
        "locations": {
            "village": {"radius": 7.0, "heal_seconds": 10.0, "heal_per_s": 0.03, "interrupt_radius": 6.0},
            "tavern": {"radius": 6.0, "duration": 15.0, "attack_speed": -0.4},
            "fountain": {"radius": 5.0, "heal": 0.40},
            "ritual": {"radius": 6.0, "elixir_mult": 2.0, "hp": 300},
            "shrine": {"radius": 7.0, "countdown": 10.0, "hero_xp": 80},
            "bridge": {"radius": 10.0, "leash": 1.5, "pack_damage": 0.5},
        },
        "arena": {"radius": 15.0, "altars": 5, "altar_ring": 10.0, "altar_hp": 300, "teleport_cooldown": 8.0,
                  "teleport_cost": 0, "elixir_mult_head": 2.0, "spell_extra_cost_no_left_arm": 2,
                  "arm_aura_radius": 3.0, "entry_distance": 14.0},
        "curse": {"hp_per_stack": 0.03, "max_stacks": 10, "cursed_mod_cooldown": 5.0},
        "status": {"fear": 1.5, "slow": 0.5, "soaked": 6.0},
        "fire_vs_soaked": 2.0,
        "goals": {"heuristic_win": [0.50, 0.65], "random_win_max": 0.10, "arena_arrival_s": [660, 780],
                  "hero_level_arena": [12, 16], "deck_spread_max": 0.05, "card_in_wins_max": 0.70,
                  "elixir_waste_max": 0.10},
    }

    hero = {
        "id": "escudeiro",
        "hp": B("Vida do Escudeiro no nível 1"), "hp_growth": B("Crescimento da vida do herói por nível"),
        "damage": B("Dano do golpe do Escudeiro (nível 1)"), "damage_growth": 0.08,
        "attack_interval": 1.0, "attack_range": 1.8, "speed": B("Velocidade do Escudeiro (m/s)"),
        "radius": 0.6, "attack_move_mult": 0.35,
        "shield": {"hp": B("Escudo frontal: vida do escudo"), "cone": 60.0,
                   "regen_seconds": B("Escudo frontal: segundos para regenerar após quebrar")},
        "ai": {"reaction": 0.2, "aggression": 1.0, "flee_weight": 1.2, "road_weight": 1.0, "target_weight": 1.4,
               "engage_radius": 7.0, "low_hp": 0.5, "danger_cell": 2.0, "danger_size": 16,
               "upgrade_counter_gain": 3.0, "strategic": {"ritual": 3.0, "bat_nest": 2.5, "bone_totem": 2.0,
                                                           "gargoyle_tower": 1.5, "altar": 1.0}},
        "upgrades": [],
    }
    UPG = {
        "Giro de Espada": ("sword_spin", {"radius": 2.5, "interval": 4.0, "mult": 0.6}, ["pack"]),
        "Escudo Torre": ("tower_shield", {"hp_mult": 2.0, "cone": 120.0}, ["projectile"]),
        "Investida": ("dash", {"distance": 5.0, "cooldown": 8.0, "surround": 5}, ["slow", "surround"]),
        "Grito de Guerra": ("war_cry", {"radius": 5.0, "max_hp": 100, "cooldown": 12.0}, ["pack"]),
        "Armadura Ignífuga": ("fireproof", {"fire_mult": 0.5}, ["fire"]),
        "Água Benta": ("holy_water", {"mult": 2.0}, ["undead", "shadow"]),
        "Faro de Tesouro": ("treasure_nose", {}, ["mimic", "bait"]),
        "Martelo Quebra-pedra": ("stone_hammer", {"mult": 2.0}, ["construct"]),
        "Botas Firmes": ("steady_boots", {"slow_mult": 0.5}, ["knockback", "slow"]),
        "Lâmina Purificadora": ("purifying_blade", {"remove": 1}, ["curse"]),
        "Escudo Refletor": ("reflect_shield", {"cooldown": 10.0}, ["spell"]),
        "Fúria do Herói": ("hero_fury", {"per_unit": 0.05, "radius": 4.0, "cap": 0.5}, ["swarm"]),
        "Absorver Almas": ("soul_absorb", {"heal": 0.01}, ["swarm"]),
        "Segundo Fôlego": ("second_wind", {"below": 0.25, "heal": 0.30}, ["burst"]),
        "Golpe Heroico": ("heroic_strike", {"interval": 5.0, "mult": 3.0, "big_hp": 500}, ["big"]),
    }
    for r in rows(wb["Upgrades"]):
        uid, p, counters = UPG[r["Upgrade do Escudeiro"]]
        hero["upgrades"].append({"id": uid, "weight": 1.0, "counters": counters, "p": p})

    parts = {"Braço esquerdo": "left_arm", "Braço direito": "right_arm", "Cabeça": "head", "Núcleo": "core"}
    offs = {"left_arm": [-1.6, 0.0], "right_arm": [1.6, 0.0], "head": [0.0, -1.2], "core": [0.0, 0.4]}
    boss = {"id": "dark_lord", "parts": [], "right_arm_dps": 40, "decks": []}
    for r in rows(wb["Chefe"]):
        pid = parts[r["Parte (Lorde das Trevas)"]]
        boss["parts"].append({"id": pid, "hp": num(r["Vida"]), "offset": offs[pid], "radius": 0.9})
    deck_ids = {"Horda": "horde", "Ruína": "ruin", "Tesouro": "treasure"}
    deck_rules = {
        "horde": {"hand_size": 6, "hero_xp_mult": 1.10},
        "ruin": {"spell_damage_mult": 1.15, "monster_cost_add": 1},
        "treasure": {"elixir_start": 8, "offer_options": 2},
    }
    name_to_id = {**FIELD_IDS, **ROUTE_IDS, **FIN_IDS}
    for r in rows(wb["Decks"]):
        did = deck_ids[r["Deck"]]
        lst = []
        for part in str(r["6 cartas iniciais"]).split(","):
            part = part.strip()
            n = 1
            if "×" in part:
                part, k = part.split("×")
                part, n = part.strip(), int(k)
            lst += [name_to_id[part]] * n
        assert len(lst) == 6, (did, lst)
        boss["decks"].append({"id": did, "cards": lst, "rules": deck_rules[did]})

    CON = {
        "Fogo Cruzado": ("crossfire", {"kind": "tag_damage", "tag": "fire", "amount": 300},
                         {"kind": "card", "tag": "fire", "min_rarity": "rare"}),
        "Tempestade de Ratos": ("rat_storm", {"kind": "alive_tag", "tag": "pack", "amount": 30},
                                {"kind": "card", "tag": "pack", "min_rarity": "rare"}),
        "Sem Testemunhas": ("no_witnesses", {"kind": "damage_no_xp", "amount": 200},
                            {"kind": "card", "category": "finisher"}),
        "Emboscada": ("ambush", {"kind": "burst", "amount": 150, "window": 5.0}, {"kind": "modifier"}),
        "Mão Vazia": ("empty_hand", {"kind": "sacrifice", "amount": 3}, {"kind": "card", "category": "lair"}),
        "Arquitetura do Mal": ("evil_architecture", {"kind": "structures", "amount": 3},
                               {"kind": "card", "tag": "construct", "min_rarity": "rare"}),
        "Caçada": ("hunt", {"kind": "cc", "amount": 4}, {"kind": "card", "tag": "shadow", "min_rarity": "rare"}),
        "Ritual Interrompido": ("ritual_interrupted", {"kind": "ritual_time", "amount": 8.0},
                                {"kind": "remove", "elixir": 3}),
    }
    contracts = []
    for r in rows(wb["Contratos"]):
        cid, goal, reward = CON[r["Contrato"]]
        dl = r["Prazo (s)"]
        contracts.append({"id": cid, "goal": goal, "reward": reward,
                          "deadline": num(dl) if isinstance(dl, (int, float)) else -1})

    modifiers = [
        {"id": "veteran", "p": {"extra_units": 1}, "applies": ["monster", "swarm"]},
        {"id": "cheap", "p": {"cost": -1, "min_cost": 1}, "applies": ["any"]},
        {"id": "explosive", "p": {"damage": 40, "radius": 2.0}, "applies": ["monster", "swarm", "structure"]},
        {"id": "cursed", "p": {"curses": 1}, "applies": ["monster", "swarm", "structure"]},
        {"id": "shadowy", "p": {"no_xp": True}, "applies": ["monster", "swarm", "structure"]},
    ]
    locked = {"paths": ["rules.elixir.seconds_per_point", "rules.elixir.max", "rules.hand_size", "rules.ring.min",
                        "rules.ring.max", "rules.sim.dt", "rules.phase1_target_s", "rules.goals"]}
    bots = {
        "random": {"id": "random", "kind": "random", "think_interval": 0.5, "play_chance": 0.6,
                   "sacrifice_unusable": 0.3},
        "greedy": {"id": "greedy", "kind": "greedy", "think_interval": 0.25, "reserve": 0,
                   "place_distance": 6.0, "sacrifice_unusable": 1.0, "teleport_distance": 4.0},
    }

    os.makedirs(os.path.join(OUT, "bots"), exist_ok=True)

    def dump(name, obj):
        with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
            json.dump(obj, f, ensure_ascii=False, indent=1)
            f.write("\n")

    dump("rules.json", rules)
    dump("cards.json", {"cards": cards, "aux_units": AUX})
    dump("hero_escudeiro.json", hero)
    dump("boss_lorde.json", boss)
    dump("contracts.json", {"contracts": contracts})
    dump("modifiers.json", {"modifiers": modifiers})
    dump("locked.json", locked)
    for k, v in bots.items():
        dump(os.path.join("bots", k + ".json"), v)
    print("ok:", len(cards), "cartas,", len(hero["upgrades"]), "upgrades,", len(contracts), "contratos")


if __name__ == "__main__":
    sys.exit(main())
