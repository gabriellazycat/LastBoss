"""Matiz da carta por modelo (revisão de modelos 3D, 27/11/2026).
Muitos modelos do v2 foram pintados em cinzas-violeta para a luz de dia antiga; na hora azul eles viram roxos e
fogem da carta (Lobisomem cinza-marrom, Cultistas vinho...). wrap(i, grade) devolve uma graduação que, antes da
graduação de sempre, gira o matiz das cores de uma faixa para o matiz da carta.
Os cinzas ficam neutros de propósito: um cinza "quente" que lesse cinza na hora azul (ato 1) vira caramelo no pôr do
sol do ato 2 (teste de 27/11/2026). Regra: (h_de, h_ate, h_novo, sat, val) em graus HSV; a cor com matiz na faixa vai para h_novo, com a saturação e o
valor multiplicados. Cores fora das faixas (olhos, brilhos, detalhes) ficam como estão."""
import colorsys

# Receita da revisão de 27/11/2026 (aplicada só nestes ids; os outros continuam com a graduação de 15/11):
#   g_n_a: LBG_GAIN=0.6 LBG_PULL=0.0 build_g_all.py (build / plague / dragon / lich)
#   m2_a estruturas: LBM2_GAIN=0.6 build_structures_m2.py;  m2_a inimigos: LBG_GAIN=0.6 LBG_PULL=0.2 build_inimigos.py
REGRADED = ["cultists", "bone_totem", "skeleton", "skeleton_archers", "ogre", "death_knight", "bone_colossus", "werewolf",
            "ruin_titan", "cave_troll", "wolf_pack", "alpha_beast", "gargoyle_tower", "scrap_golem",
            "raised_servant", "ghoul", "brood_mother", "corrupt_piper", "gold_mine", "furnace", "sewer_flood"]
# Modelos cuja cor desenhada é violeta e a carta não: (h_de, h_ate, h_novo, sat, val).
RECOLOR = {
    "alpha_beast": [(220, 310, 30, 0.08, 1.15)],      # lobo cinza da carta (cinza neutro: a luz do ato dá o tom)
    "cultists": [(260, 335, 352, 1.0, 1.0)],          # mantos vinho
    "death_knight": [(220, 300, 225, 0.35, 1.0)],     # aço escuro, não roxo
    "cave_troll": [(170, 230, 120, 0.45, 1.05)],     # pele cinza-esverdeada
}


def _in(h, lo, hi):
    return lo <= h <= hi if lo <= hi else (h >= lo or h <= hi)


def apply(i, c):
    rules = RECOLOR.get(i)
    if not rules:
        return c
    r, g, b = c[0], c[1], c[2]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    hd = h * 360.0
    for lo, hi, hn, sm, vm in rules:
        if s > 0.03 and _in(hd, lo, hi):
            r, g, b = colorsys.hsv_to_rgb((hn % 360.0) / 360.0, min(1.0, s * sm), min(1.0, v * vm))
            break
    return (r, g, b) + tuple(c[3:])


def wrap(i, grade):
    if i not in RECOLOR:
        return grade
    return lambda c: grade(apply(i, c))
