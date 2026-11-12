import os
from geom import *
import rat, hero
from render import shot, SCR

FICH = "C:/Users/gabri/Desktop/LastBoss/tools/art/card_blender/fichas"
INK = "#2b1a10"


def txt(x, y, s, size=11, w="normal", anchor="start"):
    return f'<text x="{x}" y="{y}" font-family="Georgia,serif" font-size="{size}" font-weight="{w}" fill="{INK}" text-anchor="{anchor}">{s}</text>'


def pose_g(name, pcs, place, prefix, guide=None, label=None, sub=None):
    tx, ty, s = place
    body = "\n      ".join(p.svg(prefix, name + "_") for p in pcs)
    g = f'  <g transform="{tstr(tx, ty, 0, s)}">\n    <g id="pose_{name}">\n      {body}\n    </g>\n'
    if guide:
        g += f'    <path id="{name}_acao" class="guide" d="{cr_path(guide, False)}" fill="none" stroke="#d0402a" stroke-width="1.4" stroke-dasharray="4 3"/>\n'
    g += "  </g>"
    if label:
        g += "\n  " + txt(tx, ty + 18 * 1, label, 11, "bold", "middle")
    if sub:
        g += "\n  " + txt(tx, ty + 32, sub, 9.5, "normal", "middle")
    return g


def swatches(x, y, items):
    out = []
    for i, (nm, c) in enumerate(items):
        yy = y + i * 16
        out.append(f'<rect x="{x}" y="{yy}" width="22" height="12" fill="{c}" stroke="{INK}" stroke-width=".6"/>')
        out.append(txt(x + 28, yy + 10, f"{nm} {c}", 9.5))
    return "\n  ".join(out)


def rato_svg():
    W, H = 1000, 700
    parts = [txt(20, 30, "FICHA · RATO (Praga) — comum, ratazana gorda, rato raivoso, Rei dos Ratos", 16, "bold"),
             txt(20, 48, "Unidade: cabeça = 32 u (focinho→nuca). Corpo (garupa→pescoço) ≈ 2,2 cabeças; altura na cernelha ≈ 0,9; cauda ≈ 3; patas curtas ≈ 0,6; pés traseiros longos.", 10),
             txt(20, 62, "Cada pose: uma path por peça; data-fig rato_corpo (tronco+patas+cauda = 1 silhueta) e rato_cabeca (cabeça+orelhas = 1). class=inner = linhas/manchas internas. Linha de ação tracejada (guide).", 10),
             txt(20, 76, "Variações só por proporção: gorda = larguras ×1,5, cabeça ×1,12, cor mais parda; raivoso = ×0,86, pelo eriçado no dorso, costelas, boca aberta, olho vermelho.", 10)]
    # proporção em cabeças
    for i in range(5):
        parts.append(f'<rect x="{40 + i * 32}" y="94" width="32" height="6" fill="{"#cfc4b6" if i % 2 else "#8b8580"}" stroke="{INK}" stroke-width=".5"/>')
    parts.append(txt(40, 112, "1 cabeça = 32 u", 9))
    # cabeças
    hp = rat.head_side(rat.PAL["comum"], tmat(0, 0, 0, 1), 0)
    parts.append(pose_g("cabeca_perfil", hp, (70, 170, 2.0), "rato", label=None))
    parts.append(txt(100, 222, "cabeça · perfil", 10, "bold", "middle"))
    hf = [p for p in rat.pose_saltar() if p.fig == "cabeca"]
    parts.append(pose_g("cabeca_frente", hf, (290, 175, 0.62), "rato"))
    parts.append(txt(290, 222, "cabeça · frente (do salto da v2)", 10, "bold", "middle"))
    # poses comuns
    G = {"correr": [(-90, -18), (-40, -22), (10, -28), (60, -28), (98, -12)],
         "atacar": [(-70, -36), (-20, -32), (20, -34), (60, -24), (92, -2)],
         "ameaca": [(-30, -2), (2, -22), (12, -50), (28, -74), (58, -98)],
         "andar_pesado": [(-76, -12), (-30, -22), (20, -34), (60, -26), (100, -10)]}
    parts.append(pose_g("correr", rat.pose("correr"), (560, 190, 1.35), "rato", [(x, y) for x, y in G["correr"]], "correr (galope estendido)", "patas da frente alcançam, traseiras empurram"))
    parts.append(pose_g("atacar", rat.pose("atacar"), (830, 190, 1.35), "rato", G["atacar"], "atacar (bote)", "cabeça desce, boca aberta, garras à frente"))
    sal = rat.pose_saltar()
    parts.append(pose_g("saltar", sal, (120, 400, 0.62), "rato", [(120, -130), (40, -60), (0, 0), (-10, 60)], None))
    parts.append(txt(120, 480, "saltar (escorço para a câmera)", 11, "bold", "middle"))
    parts.append(pose_g("ameaca", rat.pose("ameaca"), (330, 480, 1.35), "rato", G["ameaca"], "ameaça (empinado, chiando)", "peso na garupa e nos pés traseiros"))
    parts.append(pose_g("gorda_andar", rat.pose("andar_pesado", "gorda"), (560, 470, 1.25), "rato", G["andar_pesado"], "ratazana gorda · andar pesado", "larguras ×1,5, patas curtas"))
    parts.append(pose_g("gorda_atacar", rat.pose("atacar", "gorda"), (830, 470, 1.25), "rato", G["atacar"], "ratazana gorda · morder", ""))
    parts.append(pose_g("raivoso_atacar", rat.pose("atacar", "raivoso"), (560, 650, 1.25), "rato", G["atacar"], "rato raivoso · bote", "magro, dorso eriçado, costelas"))
    parts.append(pose_g("rei", rat.pose_rei(), (830, 655, 1.15), "rato", [(-10, -6), (6, -40), (18, -80), (50, -110), (92, -126)], "Rei dos Ratos · comando", "inclinado, cetro aponta, manto ao vento"))
    parts.append(swatches(30, 540, [("pelo", "#8b8580"), ("pelo (lado longe)", "#6c6661"), ("barriga", "#cfc4b6"), ("orelha", "#c4928a"),
                                    ("cauda", "#c9988e"), ("olho", "#ff4a1e"), ("gorda pelo", "#7a6f66"), ("raivoso pelo", "#7d7873"),
                                    ("rei manto", "#5a3a8c"), ("rei coroa", "#e2a93a")]))
    body = "\n  ".join(parts)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">\n  <rect width="{W}" height="{H}" fill="#f6efe0"/>\n  {body}\n</svg>\n'


def heroi_svg():
    W, H = 900, 420
    parts = [txt(20, 30, "FICHA · HERÓI GENÉRICO — armadura, tabardo azul, capa, espada (alvo dos feitiços, visto do lado do vilão)", 15, "bold"),
             txt(20, 48, "Unidade: cabeça (elmo) = 22 u; altura ≈ 7 cabeças (154 u, pés em y=0). Rosto sempre coberto pelo elmo (anônimo).", 10),
             txt(20, 62, "data-fig: heroi_corpo (tronco, saia, braços, pernas, mãos), heroi_cabeca (elmo), heroi_espada, heroi_capa. Viseira e respiro = inner.", 10)]
    G = {"avancar": [(-14, -2), (-10, -40), (0, -90), (20, -140), (60, -230)],
         "preso": [(-18, 0), (-14, -40), (2, -80), (30, -130), (56, -200)],
         "defesa": [(-40, 0), (-24, -40), (-2, -80), (-10, -130), (-20, -150)],
         "guarda": [(0, 0), (0, -60), (2, -100), (14, -140), (30, -190)]}
    parts.append(pose_g("avancar", hero.pose("avancar"), (130, 360, 1.25), "heroi", G["avancar"], "avançar", "golpe vindo por cima"))
    parts.append(pose_g("preso", hero.pose("preso"), (340, 360, 1.25), "heroi", G["preso"], "preso", "pé esquerdo travado, puxando o outro"))
    parts.append(pose_g("defesa", hero.pose("defesa"), (540, 360, 1.25), "heroi", G["defesa"], "defesa", "antebraço na frente do rosto"))
    parts.append(pose_g("guarda", hero.pose("guarda"), (720, 360, 1.25), "heroi", G["guarda"], "guarda (contraluz)", "espada à frente com as duas mãos"))
    parts.append(swatches(790, 80, [("aço", "#a7b0ba"), ("aço sombra", "#7c8590"), ("tabardo", "#33557d"), ("capa", "#2c4468"),
                                    ("couro", "#6b4a30"), ("lâmina", "#d8dee6"), ("ouro", "#c8a040")]))
    body = "\n  ".join(parts)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">\n  <rect width="{W}" height="{H}" fill="#f6efe0"/>\n  {body}\n</svg>\n'


if __name__ == "__main__":
    for nm, fn, wh in (("rato", rato_svg, (1000, 700)), ("heroi", heroi_svg, (900, 420))):
        s = fn()
        open(f"{FICH}/{nm}.svg", "w", encoding="utf-8").write(s)
        shot(s, f"{FICH}/{nm}.png", (0, 0) + wh, *wh, guide=True, inkw=2.2)
        print(nm, len(s))
