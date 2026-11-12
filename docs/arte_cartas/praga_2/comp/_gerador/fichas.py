"""Fichas novas do lote praga_2: morcego, lobo (comum / pestilento / Besta Alfa), lobisomem, javali de guerra."""
import base  # noqa: F401
from geom import *
import bat, wolf, werewolf, boar
from fichas_lib import txt, pose_g, swatches
from render import shot

FICH = "C:/Users/gabri/Desktop/LastBoss/tools/art/card_blender/fichas"


def svg_wrap(W, H, parts):
    body = "\n  ".join(parts)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">\n  <rect width="{W}" height="{H}" fill="#f6efe0"/>\n  {body}\n</svg>\n'


def ruler(x, y, unit, n, c1, c2, label):
    out = [f'<rect x="{x + i * unit}" y="{y}" width="{unit}" height="6" fill="{c1 if i % 2 == 0 else c2}" stroke="#2b1a10" stroke-width=".5"/>' for i in range(n)]
    out.append(txt(x, y + 18, label, 9))
    return "\n  ".join(out)


def morcego_svg():
    W, H = 1000, 560
    P = [txt(20, 30, "FICHA · MORCEGO (Praga) — Nuvem de Morcegos, Ninho de Morcegos", 16, "bold"),
         txt(20, 48, "Vista de FRENTE (escorço para a câmera). Unidade: cabeça = 16 u (queixo→topo do crânio); orelhas +1 cabeça; tronco ≈ 1,2 cabeças; envergadura ≈ 9–10 cabeças.", 10),
         txt(20, 62, "Asa = braço (13 u) + antebraço (22 u) + 3 dedos (34/30/23 u) e o 2º dedo curto na borda de ataque; membrana recortada entre as pontas, borda de fuga até o pé. Polegar com garra no punho.", 10),
         txt(20, 76, "data-fig: morcego_corpo (tronco+pernas+garras), morcego_cabeca (cabeça+orelhas), morcego_asa e morcego_asa_l (cada asa = 1 silhueta). Braço e dedos = class=inner (varetas).", 10),
         ruler(40, 92, 16 * 1.6, 6, "#5c4436", "#7e6250", "1 cabeça = 16 u (régua na escala das poses ×1,6)")]
    P.append(pose_g("cabeca_frente", bat.head_front(T(0, 15)), (90, 220, 3.6), "morcego", label="cabeça · frente", ly=46))
    P.append(pose_g("cabeca_perfil", bat.head_side(T(0, 0)), (225, 210, 3.6), "morcego", label="cabeça · perfil", ly=44))
    P.append(pose_g("voar_cima", bat.pose("voar_cima"), (470, 230, 2.6), "morcego", bat.GUIDE["voar_cima"], "voar · asas no alto", "punhos acima da cabeça, dedos em leque", ly=70))
    P.append(pose_g("voar_baixo", bat.pose("voar_baixo"), (720, 190, 2.6), "morcego", bat.GUIDE["voar_baixo"], "voar · batida para baixo", "asas em concha, pontas abaixo dos pés", ly=100))
    P.append(pose_g("atacar", bat.pose("atacar"), (300, 430, 2.6), "morcego", bat.GUIDE["atacar"], "atacar · planando com garras à frente", "asa de longe encurtada (escorço ×0,78), boca aberta", ly=70))
    P.append(pose_g("mergulho", bat.pose("mergulho"), (600, 450, 2.6), "morcego", bat.GUIDE["mergulho"], "mergulho · asas recolhidas", "vem para a câmera; silhueta estreita e alta", ly=60))
    P.append(pose_g("pendurado", bat.pose("pendurado"), (800, 330, 2.6), "morcego", None, "pendurado · casulo", "pés no apoio (origem), asas enroladas", ly=150))
    P.append(swatches(30, 300, [("pelo", bat.PAL["fur"]), ("pelo sombra", bat.PAL["fur_d"]), ("peito", bat.PAL["chest"]),
                                ("membrana", bat.PAL["wing"]), ("varetas", bat.PAL["bone"]), ("orelha dentro", bat.PAL["ear_in"]),
                                ("olho", bat.PAL["eye"]), ("garra/presa", bat.PAL["claw"])]))
    return svg_wrap(W, H, P), (W, H)


def lobo_svg():
    W, H = 1000, 640
    P = [txt(20, 30, "FICHA · LOBO (Praga) — lobo comum, lobo pestilento (Matilha), Besta Alfa", 16, "bold"),
         txt(20, 48, "Perfil olhando para +x, chão em y=0. Unidade: cabeça = 37 u (nuca→ponta do nariz). Tronco (garupa→cernelha) ≈ 2 cabeças; cernelha ≈ 2 cabeças do chão; cauda ≈ 1,6; peito fundo, cintura recolhida.", 10),
         txt(20, 62, "Patas digitígradas: dianteira = ombro→cotovelo (para trás)→punho→pata; traseira = quadril→joelho (para a frente)→jarrete (para trás)→pata. Coxa larga, canela fina.", 10),
         txt(20, 76, "data-fig: lobo_corpo (tronco+pescoço+patas+cauda = 1 silhueta), lobo_cabeca (cabeça+orelhas+mandíbula = 1). Dorso, barriga, peito, bochecha, olhos, boca = class=inner.", 10),
         txt(20, 90, "Variações por proporção: pestilento = ×0,95, pelo eriçado no pescoço, olho verde-peste; Besta Alfa = larguras ×1,35, cabeça ×1,18, juba eriçada, espinhos de osso no dorso, carvão, olho vermelho, cicatriz.", 10),
         ruler(40, 104, 37 * 1.2, 5, "#8d8478", "#e2d6c0", "1 cabeça = 37 u (régua ×1,2)")]
    P.append(pose_g("cabeca_perfil", wolf.head_side(wolf.PAL["comum"], T(0, 0), 0), (60, 190, 2.2), "lobo", label="cabeça · perfil", ly=40))
    P.append(pose_g("cabeca_perfil_aberta", wolf.head_side(wolf.PAL["comum"], T(0, 0), 30, True), (200, 190, 2.2), "lobo", label="perfil · rosnando", ly=40))
    P.append(pose_g("cabeca_frente", wolf.head_front(wolf.PAL["comum"], T(0, 0)), (340, 190, 2.0), "lobo", label="cabeça · frente", ly=72))
    P.append(pose_g("correr", wolf.pose("correr"), (520, 260, 1.5), "lobo", wolf.GUIDE["correr"], "correr · galope em suspensão", "dianteiras alcançam, traseiras empurram", ly=20))
    P.append(pose_g("atacar", wolf.pose("atacar"), (800, 300, 1.5), "lobo", wolf.GUIDE["atacar"], "atacar · bote em diagonal", "garras à frente, boca aberta", ly=20))
    P.append(pose_g("uivar", wolf.pose("uivar"), (120, 470, 1.5), "lobo", wolf.GUIDE["uivar"], "uivar · sentado", "peito alto, focinho para o céu", ly=20))
    P.append(pose_g("ameaca", wolf.pose("ameaca"), (330, 470, 1.5), "lobo", wolf.GUIDE["ameaca"], "ameaça · rosnando", "cabeça baixa, peso atrás", ly=20))
    P.append(pose_g("peste_correr", wolf.pose("correr", "peste"), (560, 600, 1.4), "lobo", wolf.GUIDE["correr"], "lobo pestilento · correr", "olho verde, pescoço eriçado", ly=20))
    P.append(pose_g("alfa_uivar", wolf.pose("uivar", "alfa"), (840, 600, 1.3), "lobo", wolf.GUIDE["uivar"], "Besta Alfa · uivo (Chamado)", "×1,35, juba, espinhos de osso", ly=20))
    P.append(swatches(30, 520, [("pelo", wolf.PAL["comum"]["fur"]), ("dorso", wolf.PAL["comum"]["back"]), ("barriga/peito", wolf.PAL["comum"]["belly"]),
                                ("olho", wolf.PAL["comum"]["eye"]), ("peste olho", wolf.PAL["peste"]["eye"]), ("alfa pelo", wolf.PAL["alfa"]["fur"]),
                                ("alfa olho", wolf.PAL["alfa"]["eye"])]))
    return svg_wrap(W, H, P), (W, H)


def lobisomem_svg():
    W, H = 1000, 480
    P = [txt(20, 30, "FICHA · LOBISOMEM (Praga) — bípede digitígrado, cabeça da ficha do lobo", 16, "bold"),
         txt(20, 48, "Unidade: cabeça = 37 u (a do lobo, escala 1,0). Altura de pé ≈ 3,3 cabeças (sem as orelhas); ombros ≈ 1,3 cabeça de largura; braços longos (a mão passa do joelho).", 10),
         txt(20, 62, "Perna: quadril→joelho (para a frente)→jarrete (para trás)→dedos com garras. Tronco curvado, peito largo, cintura fina; juba eriçada na nuca; calça azul rasgada = o que sobrou do humano.", 10),
         txt(20, 76, "data-fig: lobisomem_corpo (tronco, juba, braços, mãos, pernas, calça, cauda = 1 silhueta), lobisomem_cabeca (cabeça do lobo = 1). Peito, olhos, boca = inner.", 10)]
    P.append(pose_g("cabeca_perfil", wolf.head_side(wolf.PAL["lobisomem"], T(0, 0), 30, True), (110, 170, 2.2), "lobisomem", label="cabeça · perfil (rosnando)", ly=40))
    P.append(pose_g("cabeca_frente", wolf.head_front(wolf.PAL["lobisomem"], T(0, 0)), (90, 320, 2.0), "lobisomem", label="cabeça · frente", ly=72))
    P.append(pose_g("saltar", werewolf.pose("saltar"), (330, 420, 2.0), "lobisomem", werewolf.GUIDE["saltar"], "saltar · garras", "perna de perto empurra; garra de longe armada no alto", ly=26))
    P.append(pose_g("uivar", werewolf.pose("uivar"), (600, 430, 2.0), "lobisomem", werewolf.GUIDE["uivar"], "uivar · de pé", "costas arqueadas, braços abertos", ly=26))
    P.append(pose_g("espreitar", werewolf.pose("espreitar"), (780, 430, 2.0), "lobisomem", werewolf.GUIDE["espreitar"], "espreitar · agachado", "mão no chão, a outra armada", ly=26))
    P.append(swatches(840, 90, [("pelo", werewolf.PAL["fur"]), ("pelo longe", werewolf.PAL["far"]), ("peito", werewolf.PAL["belly"]),
                                ("calça", werewolf.PAL["pants"]), ("olho", werewolf.PAL["eye"]), ("garra", werewolf.PAL["claw"])]))
    return svg_wrap(W, H, P), (W, H)


def javali_svg():
    W, H = 1000, 520
    P = [txt(20, 30, "FICHA · JAVALI DE GUERRA (Praga) — barril com corcova, presas, barda de ferro", 16, "bold"),
         txt(20, 48, "Perfil olhando para +x, chão em y=0. Unidade: cabeça = 44 u (nuca→disco do focinho). Tronco ≈ 1,5 cabeça; cernelha ≈ 1,3 cabeça do chão (corcova nos ombros); patas curtas e finas, cascos fendidos.", 10),
         txt(20, 62, "Cabeça em cunha baixa, presas curvas para cima saindo da boca, orelha pequena; crina de cerdas no dorso. Barda: placa de ferro com 3 espigões sobre a corcova, cilha de couro, testeira com chifre.", 10),
         txt(20, 76, "data-fig: javali_corpo (tronco+patas+cauda+cerdas), javali_cabeca (cabeça+orelhas+presa), javali_armadura (barda+cilha+testeira). Barriga, bochecha, olho, narinas = inner.", 10),
         ruler(40, 90, 44 * 1.2, 4, "#5e4636", "#836652", "1 cabeça = 44 u (régua ×1,2)")]
    P.append(pose_g("cabeca_perfil", boar.head(T(0, 0)), (60, 190, 2.2), "javali", label="cabeça · perfil", ly=50))
    P.append(pose_g("cabeca_frente", boar.head_front(T(0, 0)), (240, 190, 2.2), "javali", label="cabeça · frente", ly=70))
    P.append(pose_g("investida", boar.pose("investida"), (430, 250, 2.0), "javali", boar.GUIDE["investida"], "investida · galope baixo", "presas à frente, peso no peito", ly=24))
    P.append(pose_g("lancar", boar.pose("lancar"), (760, 250, 2.0), "javali", boar.GUIDE["lancar"], "lançar · golpe de presas", "cabeça sobe, dianteiras fincadas, traseiras empurram", ly=24))
    P.append(pose_g("ameaca", boar.pose("ameaca"), (430, 460, 2.0), "javali", boar.GUIDE["ameaca"], "ameaça · cava o chão", "pata dianteira raspa, cabeça baixa", ly=24))
    P.append(pose_g("trote", boar.pose("trote"), (760, 460, 2.0), "javali", boar.GUIDE["trote"], "trote", "", ly=24))
    P.append(swatches(30, 300, [("pelo", boar.PAL["fur"]), ("pelo longe", boar.PAL["far"]), ("barriga", boar.PAL["belly"]), ("crina", boar.PAL["mane"]),
                                ("focinho", boar.PAL["snout"]), ("presa", boar.PAL["tusk"]), ("ferro", boar.PAL["iron"]), ("ferrugem", boar.PAL["rust"]),
                                ("couro", boar.PAL["leather"]), ("olho", boar.PAL["eye"])]))
    return svg_wrap(W, H, P), (W, H)


if __name__ == "__main__":
    import sys
    todo = dict(morcego=morcego_svg, lobo=lobo_svg, lobisomem=lobisomem_svg, javali=javali_svg)
    for nm in (sys.argv[1:] or todo):
        s, wh = todo[nm]()
        open(f"{FICH}/{nm}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{FICH}/{nm}.png", (0, 0) + wh, *wh, guide=True, inkw=2.2)
        print(nm, len(s))
