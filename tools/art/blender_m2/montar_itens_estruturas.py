"""Monta docs/rodada_visual/estruturas/itens.json (página tools/revisao_visual) com o que existir em disco.
python -I tools/art/blender_m2/montar_itens_estruturas.py [ids que ficaram, separados por vírgula]"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
D = "docs/rodada_visual/estruturas"

INFO = {
    "rat_burrow": ("Toca de Ratos", "Monte de terra com a boca de um cano velho de pedra; olhos vermelhos piscam no escuro, um rato espia e volta, dois farejam na encosta. Antes: ninho de morcego recolorido."),
    "barricade": ("Barricada", "Estacas apontadas inclinadas para o inimigo, duas toras com cinta de ferro, escoras atrás e a roda de carroça encostada, como na carta. Range devagar. Antes: torre da gárgula reduzida."),
    "war_banner": ("Estandarte de Guerra", "Mastro com caveira de boi e chifres, flâmula vermelha de rabo de andorinha que tremula sem parar, lança fincada e monte de pedras na base. Antes: torre da gárgula avermelhada."),
    "trap_chest": ("Baú Armadilha", "Baú de madeira com cantoneiras de ferro escuro e tampa abaulada, moedas de isca no chão. A tampa estremece e abre uma fresta: brasa laranja dentro (é uma bomba) e uma serrilha de dentes de ferro na borda. Antes: o mímico amarelado."),
    "furnace": ("Fornalha", "Base de pedra, cúpula de ferro e chaminé; três línguas de fogo tremem na boca, brasas sobem pela chaminé, carvão e atiçador ao lado. Antes: totem de ossos alaranjado."),
    "rat_trap": ("Ratoeira", "Caixa de ferro enferrujado sobre uma tábua, porta pesada erguida com gancho, mola e queijo de isca; dois ratos rondando. A porta estremece no laço; no ataque ela despenca. Antes: totem de ossos."),
    "sewer_flood": ("Inundação de Esgoto", "Parede de tijolo com arco de pedra e grade de ferro; água verde jorra da boca e corre na poça, gotas tóxicas brilham, fumaça verde sobe e dois ratos nadam. Antes: ninho de morcego esverdeado."),
    "gold_mine": ("Mina de Ouro", "Rocha facetada com a boca escorada por madeira, ouro derramando e um carrinho cheio; brilhos de quatro pontas acendem e apagam. Antes: o mímico."),
    "spike_trap": ("Armadilha de Espinhos", "Chão de terra mexida numa moldura de tábuas; as estacas descem, esperam, encolhem e saltam de volta. Antes: torre da gárgula."),
    "pack_den": ("Covil da Matilha", "Cúpula de pedras empilhadas com árvore seca no topo; olhos piscam no escuro e um filhote de lobo espia da boca. Antes: ninho de morcego."),
}


def ex(rel):
    return os.path.isfile(os.path.join(ROOT, rel))


def main():
    ids = sys.argv[1].split(",") if len(sys.argv) > 1 else list(INFO)
    itens = []
    for i in ids:
        t, desc = INFO[i]
        antes = [p for p in ("%s/antes/%s_perto.png" % (D, i), "%s/antes/%s.png" % (D, i)) if ex(p)]
        depois = [p for p in ("%s/depois/%s_perto.png" % (D, i), "%s/depois/%s.png" % (D, i), "%s/depois/%s_giro.png" % (D, i)) if ex(p)]
        vids = [p for p in ("%s/clipes/%s.webm" % (D, i),) if ex(p)]
        it = {"id": "estrutura_" + i, "frente": "Estruturas novas", "titulo": t, "descricao": desc, "flag": "--modelos=1",
              "antes": antes, "variacoes": {"V1 nova": depois}, "videos": vids,
              "modelo360": ["%s/giro/%s_*.png" % (D, i)]}
        itens.append(it)
    with open(os.path.join(ROOT, D, "itens.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(itens, f, ensure_ascii=False, indent=1)
    print("%d itens" % len(itens))


main()
