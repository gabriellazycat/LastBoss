"""Fichas do carniçal, cavaleiro da morte e colosso de ossos (chamadas por fichas_l1.py)."""
import base  # noqa: F401
from geom import *
from fichas_lib import txt, pose_g, swatches


def _wrap():
    from fichas_l1 import svg_wrap, ruler, ground_line
    return svg_wrap, ruler, ground_line


def carnical_svg():
    svg_wrap, ruler, ground_line = _wrap()
    W, H = 1280, 560
    import carnical as g
    P = [txt(20, 30, "FICHA · CARNIÇAL (Lich, Morte) — comedor de cadáveres: magro, corcunda, pele cinza-esverdeada, braços longos, mãos de 3 garras, olhos amarelos", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 20 u. Curvado ≈ 5 cabeças (100 u); coxa 1,5 / canela 1,5 / metatarso 0,7 (anda na ponta dos pés); braço 1,5 / antebraço 1,5; mão 0,9 + garras 0,5.", 10),
         txt(20, 62, "IK: joelho para a frente, cotovelo para trás. Costelas e vértebras aparecendo sob a pele; orelhas pontudas para trás; bocarra de dentes finos. Olhos amarelos = brilho próprio (foco).", 10),
         txt(20, 76, "data-fig: carnical_corpo (tronco, trapo, braços, mãos, garras, pernas, pés), carnical_cabeca (crânio, orelhas, mandíbula). Costelas, vértebras, olhos, dentes, boca = inner.", 10),
         ruler(40, 92, 20 * 2, 4, "#a3ad8c", "#6e7a5e", "1 cabeça = 20 u (régua ×2)")]
    P.append(pose_g("cabeca_perfil", g.head(T(0, 0), "p", 3), (90, 190, 2.6), "carnical", label="cabeça · perfil", ly=50))
    P.append(pose_g("cabeca_frente", g.head(T(0, 0), "f", 5), (90, 350, 2.6), "carnical", label="cabeça · frente, boca aberta", ly=62))
    for i, (nm, lab, sub) in enumerate([("espreitar", "espreitar · agachado", "dorso arqueado, nós no chão"),
                                        ("saltar", "saltar · bote", "diagonal, garras à frente"),
                                        ("atacar", "atacar · frente-3/4", "garra erguida, bocarra"),
                                        ("uivar", "uivar · sorve as mortes", "cabeça para trás, braços abertos")]):
        x = 300 + i * 225; y = 500
        P.append(ground_line(x, y, 170))
        P.append(pose_g(nm, g.pose(nm), (x, y, 1.75), "carnical", g.GUIDE[nm], lab, sub, ly=24))
    P.append(swatches(1150, 110, [(k, g.PAL[k]) for k in ("skin", "skin_d", "skin_l", "claw", "eye", "mouth", "teeth", "rag")]))
    return svg_wrap(W, H, P), (W, H)


EXTRA = dict(carnical=carnical_svg)
try:
    import cavaleiro

    def cavaleiro_svg():
        svg_wrap, ruler, ground_line = _wrap()
        return cavaleiro.ficha(svg_wrap, ruler, ground_line)
    EXTRA["cavaleiro_morte"] = cavaleiro_svg
except ImportError:
    pass
try:
    import colosso

    def colosso_svg():
        svg_wrap, ruler, ground_line = _wrap()
        return colosso.ficha(svg_wrap, ruler, ground_line)
    EXTRA["colosso_ossos"] = colosso_svg
except ImportError:
    pass
