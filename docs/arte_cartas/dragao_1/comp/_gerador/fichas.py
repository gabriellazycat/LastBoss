"""Fichas novas do lote dragao_1: goblin, diabrete, kobold, dragao. Uso: python fichas.py [goblin] [diabrete] [kobold] [dragao]"""
import base  # noqa: F401
from base import FICH
from geom import *
from fichas_lib import txt, pose_g, swatches
from render import shot


def svg_wrap(W, H, parts):
    body = "\n  ".join(parts)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">\n  <rect width="{W}" height="{H}" fill="#f6efe0"/>\n  {body}\n</svg>\n'


def ruler(x, y, unit, n, c1, c2, label):
    out = [f'<rect x="{x + i * unit}" y="{y}" width="{unit}" height="6" fill="{c1 if i % 2 == 0 else c2}" stroke="#2b1a10" stroke-width=".5"/>' for i in range(n)]
    out.append(txt(x, y + 18, label, 9))
    return "\n  ".join(out)


def goblin_svg():
    W, H = 1000, 560
    import goblin as g
    P = [txt(20, 30, "FICHA · GOBLIN (Dragão, Fogo) — verde, cabeçudo, orelhas longas para trás, nariz adunco, bocarra; túnica de couro e bandoleira de dinamite", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 22 u. Altura parado ≈ 3,4 cabeças (75 u); quadril a 1,2; pescoço a 2,3; coxa 0,6 / canela 0,6 / pé 0,4; braço 0,55 / antebraço 0,5; mãos grandes (0,3) de 3 dedos + polegar.", 10),
         txt(20, 62, "IK de dois ossos (joelho para a frente, cotovelo para trás). Barriga redonda para a frente, ombros estreitos, pés descalços com garras creme. Brinco de ouro na orelha de perto.", 10),
         txt(20, 76, "data-fig: goblin_corpo (tronco, túnica, braços, mãos, pernas, pés), goblin_cabeca (crânio+orelhas+nariz+queixo), goblin_dinamite. Olhos, boca, dentes, sobrancelhas, cinto, bandoleira = inner.", 10),
         ruler(40, 92, 22 * 2, 4, "#87ae4c", "#5f8a3a", "1 cabeça = 22 u (régua ×2)")]
    P.append(pose_g("cabeca_perfil", g.head(T(0, 0)), (90, 200, 2.6), "goblin", label="cabeça · 3/4 perfil", ly=50))
    P.append(pose_g("cabeca_frente", g.head_front(T(0, 0)), (90, 360, 2.4), "goblin", label="cabeça · frente", ly=46))
    P.append(pose_g("correr", g.pose("correr"), (285, 470, 3.0), "goblin", g.GUIDE["correr"], "correr · dinamite acesa", "tronco 30° à frente, joelho alto", ly=26))
    P.append(pose_g("arremessar", g.pose("arremessar"), (515, 470, 3.0), "goblin", g.GUIDE["arremessar"], "arremessar · armando", "torção para trás, braço de longe mira", ly=26))
    P.append(pose_g("saltar", g.pose("saltar"), (690, 520, 3.0), "goblin", g.GUIDE["saltar"], "saltar · no ar", "pernas encolhidas, braços acima", ly=14))
    P.append(pose_g("ameaca", g.pose("ameaca"), (850, 470, 3.0), "goblin", g.GUIDE["ameaca"], "ameaça · agachado", "garras abertas, sorriso", ly=26))
    P.append(swatches(820, 110, [(k, g.PAL[k]) for k in ("skin_l", "skin", "skin_d", "tunic", "band", "tnt", "eye", "iris", "mouth", "claw", "gold")]))
    return svg_wrap(W, H, P), (W, H)


def diabrete_svg():
    W, H = 1000, 560
    import diabrete as m
    P = [txt(20, 30, "FICHA · DIABRETE DE FOGO (Dragão, Fogo) — pequeno, voador, laranja-brasa, asas de morcego, chifrinhos, cauda de ponta de seta, chama na cabeça", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 16 u. Corpo ≈ 3 cabeças (48 u, sem a cauda); envergadura ≈ 6 cabeças. Barriga amarela; mãos e pés de 3 garras; cauda = 1,5 corpo.", 10),
         txt(20, 62, "Asas: braço + 3 dedos + polegar com garra; membrana recortada entre as pontas (bordô escuro). Chama no topo da cabeça e na ponta da cauda = brilho próprio.", 10),
         txt(20, 76, "data-fig: diabrete_corpo (tronco, braços, pernas, cauda), diabrete_cabeca (cabeça+chifres+orelhas+chama), diabrete_asa_l, diabrete_asa_r. Olhos, boca, varetas = inner.", 10),
         ruler(40, 92, 16 * 2, 4, "#f07a2a", "#c8501e", "1 cabeça = 16 u (régua ×2)")]
    P.append(pose_g("cabeca_perfil", m.head(T(0, 0)), (80, 200, 3.0), "diabrete", label="cabeça · 3/4", ly=40))
    P.append(pose_g("cabeca_frente", m.head_front(T(0, 0)), (80, 350, 3.0), "diabrete", label="cabeça · frente", ly=40))
    for i, (nm, lab, sub) in enumerate([("mergulho", "mergulho · garras à frente", "diagonal, asas para trás"),
                                        ("voar", "voar · batida para cima", "asas erguidas, pernas soltas"),
                                        ("atacar", "atacar · bola de fogo", "braço armado, asas abertas"),
                                        ("ameaca", "ameaça · pairando", "corpo em C, garras abertas")]):
        x = 300 + i * 175
        P.append(pose_g(nm, m.pose(nm), (x, 330 if i % 2 == 0 else 360, 2.4), "diabrete", m.GUIDE[nm], lab, sub, ly=120))
    P.append(swatches(820, 110, [(k, m.PAL[k]) for k in ("skin", "skin_d", "belly", "wing", "wing_d", "horn", "eye", "flame", "flame_c")]))
    return svg_wrap(W, H, P), (W, H)


def kobold_svg():
    W, H = 1000, 560
    import kobold as k
    P = [txt(20, 30, "FICHA · KOBOLD (Dragão) — reptiliano baixinho, focinho de lagarto, chifrinhos, cauda grossa; ferrugem com barriga creme; saco de pilhagem e picareta", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 18 u. Altura parado ≈ 3,6 cabeças (65 u), curvado para a frente; pernas digitígradas (coxa 0,7 / canela 0,7 / metatarso 0,4); cauda ≈ 1 corpo, quase no chão.", 10),
         txt(20, 62, "Lenço vermelho no pescoço, colete de trapo marrom. Olho amarelo de pupila em fenda. IK de dois ossos; o joelho da perna digitígrada dobra para a frente, o calcanhar fica alto.", 10),
         txt(20, 76, "data-fig: kobold_corpo (tronco, cauda, braços, mãos, pernas, pés), kobold_cabeca (cabeça+chifres+crista), kobold_saco, kobold_picareta. Olho, boca, escamas, listras = inner.", 10),
         ruler(40, 92, 18 * 2, 4, "#b8643a", "#8a4428", "1 cabeça = 18 u (régua ×2)")]
    P.append(pose_g("cabeca_perfil", k.head(T(0, 0)), (90, 200, 2.6), "kobold", label="cabeça · perfil", ly=42))
    P.append(pose_g("cabeca_frente", k.head_front(T(0, 0)), (90, 350, 2.6), "kobold", label="cabeça · frente", ly=44))
    for i, (nm, lab, sub) in enumerate([("correr", "correr · com o saco", "saco nas costas, tronco baixo"),
                                        ("atacar", "atacar · picareta", "golpe de cima, passo largo"),
                                        ("saltar", "saltar · mergulho no tesouro", "no ar, cauda de leme"),
                                        ("ameaca", "ameaça · agachado", "sibilando, picareta em guarda")]):
        x = [300, 470, 640, 820][i]
        P.append(pose_g(nm, k.pose(nm), (x, 470 if nm != "saltar" else 330, 2.3), "kobold", k.GUIDE[nm], lab, sub, ly=26 if nm != "saltar" else 40))
    P.append(swatches(830, 110, [(n, k.PAL[n]) for n in ("scale", "scale_d", "belly", "horn", "scarf", "vest", "sack", "eye", "pick")]))
    return svg_wrap(W, H, P), (W, H)


def dragao_svg():
    W, H = 1100, 620
    import dragon as d
    P = [txt(20, 30, "FICHA · DRAGÃO ANCIÃO (vilão Dragão) — vermelho, chifres creme, placas douradas na barriga e no pescoço, asas de membrana vermelha, olhos amarelos", 14, "bold"),
         txt(20, 48, "Unidade: cabeça = 30 u (focinho→nuca). Corpo (peito→quadril) ≈ 3 cabeças; pescoço ≈ 2,5 em S; cauda ≈ 6 cabeças afinando com espinhos dourados; envergadura ≈ 12 cabeças.", 10),
         txt(20, 62, "Asa: braço (ombro→cotovelo→pulso) + 4 dedos longos + polegar-garra; membrana recortada em arcos. Patas da frente com 4 garras creme; patas de trás digitígradas. Poses sempre em 3/4 ou perfil — nunca de frente parado.", 10),
         txt(20, 76, "data-fig: dragao_corpo (tronco, pescoço, cauda, patas), dragao_cabeca (crânio, chifres, mandíbula, espinhos da face), dragao_asa_l (longe), dragao_asa_r (perto). Placas, olhos, dentes, boca, varetas = inner.", 10),
         ruler(40, 92, 30 * 1.2, 5, "#7a1c18", "#d9a04a", "1 cabeça = 30 u (régua ×1,2)")]
    P.append(pose_g("cabeca_perfil", d.head(T(0, 0), open_=0), (100, 220, 2.0), "dragao", label="cabeça · perfil (fechada)", ly=46))
    P.append(pose_g("cabeca_sopro", d.head(T(0, 0), open_=28), (100, 360, 2.0), "dragao", label="cabeça · perfil (sopro)", ly=56))
    P.append(pose_g("cabeca_34", d.head34(T(0, 0)), (90, 500, 1.6), "dragao", label="cabeça · 3/4 frente", ly=58))
    for nm, (x, y, s), lab, sub in [("mergulho", (300, 330, 0.8), "mergulho · garras à frente", "diagonal 35°, asas fechando"),
                                    ("sopro", (610, 480, 0.8), "sopro · pescoço em S", "peso nas patas de trás, fogo em leque"),
                                    ("rugido", (900, 520, 0.72), "rugido · empinado 3/4", "asas abertas, peito para a câmera"),
                                    ("sobrevoo", (640, 190, 0.55), "sobrevoo · perfil", "asas em batida; silhueta para o céu")]:
        P.append(pose_g(nm, d.pose(nm), (x, y, s), "dragao", d.GUIDE[nm], lab, sub, ly=int(80 * s)))
    P.append(swatches(960, 110, [(k, d.PAL[k]) for k in ("body", "body_d", "body_l", "plate", "horn", "wing", "wing_d", "eye", "mouth", "fire")]))
    return svg_wrap(W, H, P), (W, H)


def heroi_append():
    """Acrescenta as poses novas do lote dragao_1 à ficha heroi.svg existente, sem tocar no que já está lá."""
    import re, hero_d1
    path = f"{FICH}/heroi.svg"
    s = open(path, encoding="utf-8").read()
    old = re.search(r"<!-- dragao_1 h0=(\d+) -->", s)
    s = re.sub(r"\n  <!-- dragao_1.*<!-- /dragao_1 -->", "", s, flags=re.S)
    m = re.search(r'viewBox="0 0 (\d+) (\d+)"', s); W, Hc = int(m.group(1)), int(m.group(2))
    H0 = int(old.group(1)) if old else Hc
    H = H0 + 720
    s = s.replace(f'viewBox="0 0 {W} {Hc}"', f'viewBox="0 0 {W} {H0}"', 1).replace(f'<rect width="{W}" height="{Hc}"', f'<rect width="{W}" height="{H0}"', 1)
    s = s.replace(f'viewBox="0 0 {W} {H0}"', f'viewBox="0 0 {W} {H}"', 1).replace(f'<rect width="{W}" height="{H0}"', f'<rect width="{W}" height="{H}"', 1)
    P = [txt(20, H0 + 24, "POSES NOVAS (lote dragao_1) — reações aos feitiços de Fogo; escudo redondo = heroi_escudo; 'de costas' = capa por cima do tronco, sem viseira", 12, "bold")]
    items = [("escorregar", False, "escorregar", "pé no alto, caindo para trás no óleo"),
             ("costas_recuo", True, "de costas · recuo", "atingido pelas costas, calcanhar escorrega"),
             ("capa_fogo", False, "capa em fogo", "gira para fugir, bate na capa"),
             ("choque", False, "choque", "faísca acerta: arqueado, braços abertos"),
             ("recuo", False, "recuo agachado", "tropeça para trás, espada apontada"),
             ("correr_escudo", False, "correr com escudo", "escudo sobre a cabeça, perna de trás no ar")]
    for i, (nm, back, lab, sub) in enumerate(items):
        x = 160 + (i % 3) * 290; y = H0 + 270 + (i // 3) * 330
        P.append(pose_g(nm, hero_d1.pose(nm, back), (x, y, 1.15), "heroi", hero_d1.GUIDE[nm], lab, sub, ly=22))
    block = f"\n  <!-- dragao_1 h0={H0} -->\n  " + "\n  ".join(P) + "\n  <!-- /dragao_1 -->"
    s = s.replace("</svg>", block + "\n</svg>", 1)
    open(path, "w", encoding="utf-8").write(s)
    shot(s, f"{FICH}/heroi.png", (0, 0, W, H), W, H, guide=True, inkw=2.2)
    print("heroi", W, H)


if __name__ == "__main__":
    import sys
    todo = dict(goblin=goblin_svg, diabrete=diabrete_svg, kobold=kobold_svg, dragao=dragao_svg)
    if sys.argv[1:] == ["heroi"]:
        heroi_append(); sys.exit()
    for nm in (sys.argv[1:] or todo):
        s, wh = todo[nm]()
        open(f"{FICH}/{nm}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{FICH}/{nm}.png", (0, 0) + wh, *wh, guide=True, inkw=2.2)
        print(nm, len(s))

