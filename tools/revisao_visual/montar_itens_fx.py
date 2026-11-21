"""Monta docs/rodada_visual/fx/itens.json (efeitos, heróis e arena) a partir das capturas de tools/capture_fx_all.sh.

Uso (na raiz do projeto): python -I tools/revisao_visual/montar_itens_fx.py
Para cada captura <pasta>/<nome>.png com <nome>.pos, grava <pasta>/<nome>_det.png: um recorte de 960x600 em volta
do herói (o detalhe que a captura inteira deixa pequeno). Só lista na página o que existe no disco.
"""
import json
import os

from PIL import Image

BASE = os.path.join("docs", "rodada_visual", "fx")


def det(pasta, nome):
    png = os.path.join(BASE, pasta, nome + ".png")
    pos = os.path.join(BASE, pasta, nome + ".pos")
    out = os.path.join(BASE, pasta, nome + "_det.png")
    if not os.path.isfile(png):
        return None
    try:
        x, y = [float(v) for v in open(pos, encoding="utf-8").read().split()]
    except (OSError, ValueError):
        x, y = 0.5, 0.45
    im = Image.open(png)
    w, h = im.size
    cw, ch = 960, 600
    cx = min(max(int(x * w), cw // 2), w - cw // 2)
    cy = min(max(int(y * h), ch // 2), h - ch // 2)
    im.crop((cx - cw // 2, cy - ch // 2, cx + cw // 2, cy + ch // 2)).save(out)
    return out


def rel(p):
    return p.replace("\\", "/") if p else None


def item(iid, frente, titulo, desc, flag, pref, nome, nomes_var, completo=True):
    antes = []
    a = det(pref + "0", nome)
    if a:
        antes = [rel(a)] + ([rel(os.path.join(BASE, pref + "0", nome + ".png"))] if completo else [])
    var = {}
    for i, vn in enumerate(nomes_var, start=1):
        d = det(pref + str(i), nome)
        if d:
            var[vn] = [rel(d)] + ([rel(os.path.join(BASE, pref + str(i), nome + ".png"))] if completo else [])
    if not antes and not var:
        return None
    return {"id": iid, "frente": frente, "titulo": titulo, "descricao": desc, "flag": flag, "antes": antes, "variacoes": var}


FX = ["E1 pintado", "E2 brilhante"]
itens = [
    item("fx_fogo", "Efeitos", "Fogo (Tocha)", "Chamas pintadas por shader (ruído rolando + máscara + gradiente), brasas subindo, fumaça por cima, luz que treme e marca queimada no chão.", "--fx=1 / --fx=2", "e", "fogo", FX),
    item("fx_teia", "Efeitos", "Teia", "Teia desenhada de verdade no chão (raios e espiral irregulares) e fios de seda soltos, no lugar do anel genérico.", "--fx=1 / --fx=2", "e", "teia", FX),
    item("fx_oleo", "Efeitos", "Óleo fervente", "Poça escura com reflexo e borbulhas, com chamas lambendo a borda.", "--fx=1 / --fx=2", "e", "oleo", FX),
    item("fx_oleo_respingo", "Efeitos", "Respingo de óleo", "Respingo com gotas e a mesma poça do óleo.", "--fx=1 / --fx=2", "e", "oleo_respingo", FX),
    item("fx_sombra", "Efeitos", "Raio sombrio", "Impacto com clarão em estrela, faíscas alongadas e onda de choque pintada no chão.", "--fx=1 / --fx=2", "e", "sombra", FX),
    item("fx_corpo", "Efeitos", "Explosão de cadáver", "Estouro com lascas que giram e caem, fumaça e onda no chão.", "--fx=1 / --fx=2", "e", "corpo", FX),
    item("fx_arcano", "Efeitos", "Centelha arcana", "Estrelas e partículas que sobem, clarão e círculo de feitiço girando no chão.", "--fx=1 / --fx=2", "e", "arcano", FX),
    item("fx_projeteis", "Efeitos", "Projéteis e disputa", "Flecha modelada (haste, ponta, penas) com rastro, orbe com núcleo, halo e rastro de centelhas; tiros das unidades viram traço de luz; casas que caem soltam entulho, poeira e fogo.", "--fx=1 / --fx=2", "e", "disputa", FX),
    item("herois_estrada", "Heróis", "Presença dos heróis (estrada)", "Os modelos KayKit ficam. Por cima: sombra de contato, anel pintado na cor da classe sob cada herói (o da vez mais forte), aura de partículas por classe e heróis 15% maiores (8% no discreto).", "--herois=1 / --herois=2", "h", "estrada", ["H1 anel, aura e sombra", "H2 só anel e sombra"]),
    item("herois_disputa", "Heróis", "Presença dos heróis (disputa, outras classes)", "Mesma mudança com Bárbaro, Arqueira, Escudeiro e Besteiro.", "--herois=1 / --herois=2", "h", "disputa", ["H1 anel, aura e sombra", "H2 só anel e sombra"]),
    item("arena", "Arena", "Arena do chefe", "Círculo de runas pintado (anéis de pincel, 24 runas, estrela) no lugar dos anéis roxos, borda de lajes, chamas nos braseiros e luz central menos chapada.", "--arena=1 / --arena=2", "a", "arena", ["A1 pedra e brasa", "A2 cripta de runas"]),
]
itens = [i for i in itens if i]
with open(os.path.join(BASE, "itens.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump(itens, f, ensure_ascii=False, indent=1)
print("itens:", len(itens))
