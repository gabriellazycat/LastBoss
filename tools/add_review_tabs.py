# Adiciona à planilha de revisão as abas "Run - ..." da rodada de 09/11/2026
# (3 atos, relíquias, eventos, disputas novas, arena, ofertas).
# Uso: python -I tools/add_review_tabs.py   (feche o Excel antes; faz backup ao lado)
# Só acrescenta/substitui as abas "Run - "; não toca nas outras.
import shutil, sys, datetime, pathlib
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment

ROOT = pathlib.Path(__file__).resolve().parent.parent
XLSX = ROOT / "Revisao do conteudo - Last Boss.xlsx"

HEAD_FILL = PatternFill("solid", fgColor="3B2A5C")
DONE_FILL = PatternFill("solid", fgColor="C8E6C9")
HEAD_FONT = Font(name="Arial", bold=True, color="FFFFFF")
BODY_FONT = Font(name="Arial")
NUM_FONT = Font(name="Arial", color="0000FF")
WRAP = Alignment(wrap_text=True, vertical="top")

D = "Decidido 09/11"   # linhas decididas com você no grilling (fundo verde)


def sheet(wb, name, headers, widths, rows):
    if name in wb.sheetnames:
        del wb[name]
    ws = wb.create_sheet(name)
    for i, h in enumerate(headers, 1):
        c = ws.cell(row=1, column=i, value=h)
        c.font, c.fill, c.alignment = HEAD_FONT, HEAD_FILL, WRAP
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[openpyxl.utils.get_column_letter(i)].width = w
    for r, row in enumerate(rows, 2):
        decided = any(isinstance(v, str) and v.startswith(D) for v in row)
        for i, v in enumerate(row, 1):
            c = ws.cell(row=r, column=i, value=v)
            c.alignment = WRAP
            c.font = NUM_FONT if isinstance(v, (int, float)) and not decided else BODY_FONT
            if decided:
                c.fill = DONE_FILL
    ws.freeze_panes = "B2"
    return ws


def main():
    if not XLSX.exists():
        sys.exit("planilha não encontrada: %s" % XLSX)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = XLSX.with_name(XLSX.stem + " (backup %s).xlsx" % stamp)
    shutil.copy2(XLSX, backup)
    wb = openpyxl.load_workbook(XLSX)

    P = ["Parâmetro", "Valor", "Origem / nota", "Seu comentário"]
    W = [52, 14, 70, 40]

    sheet(wb, "Run - Atos", P, W, [
        ["Atos até a arena", 3, D + ": 3 terrenos, cada um com seu mapa; a arena vem depois do 3º", None],
        ["Locais por rota em cada ato: mínimo", 7, D + ": 20 a 24 locais na run inteira", None],
        ["Locais por rota em cada ato: máximo", 8, D, None],
        ["Comprimento de cada ato (m)", 600, "Proposta: trechos entre locais mais curtos (hoje a estrada única tem 1400 m para 8 a 10 locais). Ajustado pelo lote para dar uns 7 min por ato", None],
        ["Duração alvo da run até o fim da arena (min)", 25, D, None],
        ["Limite de segurança da simulação (s)", 2400, "Técnico: hoje é 1500 s e cortaria a run de 25 min", None],
        ["Heróis na fila (run inteira)", 7, D + ": 6 a 7 heróis com menos vida, numa fila só; proponho 7", None],
        ["Herói 1: vida", 1150, "Proposta (hoje 1700). Ajustada pelo lote", None],
        ["Herói 1: golpe", 40, "Proposta (hoje 44)", None],
        ["Passo de força por herói (×)", 1.2, "Proposta (hoje 1,26). Com 7 heróis, 1,26 deixaria o 7º com 4× a vida do 1º; 1,2 deixa com 3×", None],
        ["Herói vivo entre atos", "mantém a vida", D + ": se um herói sobrevive ao ato, segue no próximo; proponho sem cura na troca", None],
        ["Chão do ato 1 / 2 / 3", "2 / 3 / 4", "Provisório, com os chãos que já existem: Bosque enluarado, Outono, Terra amaldiçoada (fica mais sombrio até o covil). O estudo de arte substitui", None],
        ["Raridade das cartas no ato 1 (comum/incomum/rara/lendária)", "65/25/9/1", "Proposta: troca a tabela por tempo (feita para 12 min) por uma por ato", None],
        ["Raridade no ato 2", "50/30/16/4", "Proposta", None],
        ["Raridade no ato 3", "40/30/22/8", "Proposta", None],
        ["Relíquias: quando", "fim de cada ato", D + ": escolher 1 entre 3 ao terminar cada ato (3 por run)", None],
        ["Lojas por rota em cada ato", 1, D + ": toda rota de cada ato passa por exatamente 1 Loja", None],
        ["Ouro visível na HUD", "sim", D, None],
        ["Contratos: intervalo (s)", "180 a 240", "Proposta (hoje 120 a 180): numa run de 25 min, o ritmo antigo daria uns 10 contratos", None],
        ["Almas por local", 1, "Proposta (hoje 2): com 20 a 24 locais, as Almas dobrariam", None],
    ])

    L = ["Local", "Peso no mapa", "O que acontece", "Como vencer a disputa", "Venceu", "Perdeu", "Status", "Seu comentário"]
    LW = [16, 12, 45, 45, 26, 18, 30, 36]
    sheet(wb, "Run - Locais v2", L, LW, [
        ["Todos (exceto Loja e ?)", "-", "O herói PARA no local enquanto a disputa dura e só segue quando ela acaba. Se houver bifurcação logo depois, você escolhe o ramo nessa hora", "Precisa de ação sustentada; nunca basta uma unidade estar perto por um instante", "3 opções", "nada", D, None],
        ["Círculo de Ritual", 2, "Sacrifício. Seu elixir rende ×2 dentro do círculo. Janela de 25 s", "10 monstros seus morrerem dentro do círculo (raio 6 m) durante a janela", "Sobe 1 entre 3 cartas", "nada", D + " (10 mortes); janela de 25 s é proposta", None],
        ["Santuário", 2, "Janela de 20 s. Torre de Gárgula e Mímico não contam", "Ter monstros seus dentro do círculo (raio 7 m) por 6 s somados", "1 entre 3 cartas raras+", "nada", D + " (6 s); janela de 20 s é proposta", None],
        ["Taverna", 2, "3 casas de 400 de vida em volta. Seus monstros a até 10 m vão nas casas; o herói defende quem as ataca. Janela de 25 s", "Destruir as 3 casas na janela", "1 entre 3 modificadores", "nada", D + " (casas); números são proposta", None],
        ["Ponte", 2, "A disputa que era da Taverna: o herói ataca 40% mais devagar por 15 s. A coleira de 1,5 m e o bônus dos bandos saem", "Causar 150 de dano nesses 15 s", "Escolhe o tipo, depois 1 entre 3 desse tipo", "nada", D + " (troca com a Taverna); tirar coleira e bônus é proposta", None],
        ["Fonte", 2, "O herói se ajoelha e bebe por 4 s, com aviso na tela", "Causar 120 de dano ou aplicar medo, raiz, empurrão ou petrificação durante o gole", "Remove 1 carta à escolha", "nada; e o herói cura 15% da vida", D + " (cura 15% é exceção escolhida por você)", None],
        ["Loja", "1 por rota", "Sem disputa e sem desconto: o herói passa e a Loja abre", "-", "Compra com ouro", "-", D, None],
        ["? (novo)", 2, "Um evento de texto sorteado (aba Run - Eventos), com 2 ou 3 escolhas", "-", "Conforme a escolha", "-", D + " (local novo)", None],
    ])

    R = ["Relíquia", "Raridade", "Efeito", "Números", "Por que", "Status", "Seu comentário"]
    RW = [24, 12, 55, 18, 45, 14, 36]
    sheet(wb, "Run - Relíquias", R, RW, [
        ["Coroa de Ossos", "comum", "A cada 10 monstros seus mortos, +1 de elixir", "10 mortes = +1", "Recompensa o enxame e combina com o Ritual", "Proposta", None],
        ["Altar Portátil", "comum", "Recarga do sacrifício cai pela metade", "8 s → 4 s", "Ciclar o deck mais rápido", "Proposta", None],
        ["Dízimo do Covil", "comum", "Ouro ganho com dano no herói ×1,3", "×1,3", "Mais Loja", "Proposta", None],
        ["Argamassa Negra", "comum", "Estruturas têm +50% de vida e duram +50%", "+50%", "Ninho, Totem e Torre viram plano de jogo", "Proposta", None],
        ["Trombeta da Vitória", "comum", "Vencer uma disputa dá +2 de elixir na hora", "+2", "Ganhar o local já ajuda a próxima luta", "Proposta", None],
        ["Ampulheta Rachada", "incomum", "Janelas das disputas duram 30% mais", "+30%", "Facilita os locais", "Proposta", None],
        ["Correntes do Carcereiro", "incomum", "Medo e raiz duram 50% mais", "+50%", "Valoriza controle (Teia, Fantasma)", "Proposta", None],
        ["Olho Vigilante", "incomum", "A primeira carta jogada até 3 s depois de uma habilidade do herói disparar custa 0 (uma vez por disparo)", "3 s, custo 0", "Premia jogar no momento certo (recargas visíveis)", "Proposta", None],
        ["Uivo da Matilha", "incomum", "Com 5 ou mais unidades de bando vivas, os bandos causam +25% de dano", "5+, +25%", "Sinergia de bando", "Proposta", None],
        ["Bolsa do Mercador", "incomum", "A Loja tem 1 carta a mais e tudo custa 15% menos", "+1, −15%", "Mais escolha na Loja", "Proposta", None],
        ["Cálice Transbordante", "rara", "Cada ato e a arena começam com o elixir cheio", "10", "Começo forte", "Proposta", None],
        ["Pedra de Passagem", "rara", "Teleporte custa 0 e recarrega 4 s mais rápido", "0 elixir, 12 → 8 s", "Desfaz o custo novo do teleporte para quem investe nele", "Proposta", None],
        ["Terra Profana", "rara", "Monstro seu que morre dentro do círculo de um local tem 25% de chance de levantar como 1 Arqueiro Esqueleto", "25%", "Combina com Ritual e Santuário", "Proposta", None],
        ["Sangue Ruim", "rara", "Cada queda de herói dá também 1 entre 3 modificadores", "+1 oferta", "Mais poder ao longo da run", "Proposta", None],
        ["Grimório Pesado", "rara", "Mão +1 carta, elixir máximo −1", "+1 / −1", "Troca: mais opções, menos teto", "Proposta", None],
    ])

    E = ["Evento", "Texto", "Opção", "Resultado", "Status", "Seu comentário"]
    EW = [20, 50, 26, 55, 12, 36]
    sheet(wb, "Run - Eventos", E, EW, [
        ["Mercador Encapuzado", "Um vulto oferece mercadoria roubada de um templo.", "Comprar (60 de ouro)", "Escolhe 1 entre 3 cartas raras+", "Proposta", None],
        [None, None, "Roubar", "50%: 1 carta rara+ sorteada. 50%: o próximo herói chega com +10% de vida", "Proposta", None],
        [None, None, "Seguir", "Nada", "Proposta", None],
        ["Altar Profano", "Um altar pede uma oferenda.", "Oferecer uma carta", "Remove 1 carta à escolha e sobe outra à escolha 1 nível", "Proposta", None],
        [None, None, "Oferecer sangue", "Ganha 1 relíquia sorteada; o chefe começa a arena com 15% menos vida em cada parte", "Proposta", None],
        [None, None, "Seguir", "Nada", "Proposta", None],
        ["Prisioneiro", "Um aventureiro preso na sua masmorra implora.", "Torturar", "O herói atual recebe 2 maldições; você ganha 1 entre 3 modificadores", "Proposta", None],
        [None, None, "Recrutar", "1 entre 3 cartas incomuns", "Proposta", None],
        [None, None, "Soltar", "+40 de ouro", "Proposta", None],
        ["Poço dos Desejos", "Moedas brilham no fundo.", "Jogar 30 de ouro", "60%: sobe 1 carta sorteada. 40%: nada", "Proposta", None],
        [None, None, "Jogar 80 de ouro", "Sobe 1 entre 3 cartas", "Proposta", None],
        [None, None, "Seguir", "Nada", "Proposta", None],
        ["Bibliotecário", "Um velho cataloga grimórios esquecidos.", "Reescrever", "Transforma 1 carta à escolha numa carta sorteada de raridade acima", "Proposta", None],
        [None, None, "Copiar", "Duplica 1 carta à escolha (respeita o limite de 2 cópias)", "Proposta", None],
        [None, None, "Seguir", "Nada", "Proposta", None],
        ["Banquete dos Heróis", "A mesa da próxima estalagem está posta.", "Envenenar", "O próximo herói chega com 20% menos vida, mas o herói atual cura 20%", "Proposta", None],
        [None, None, "Saquear", "+60 de ouro; o herói atual cura 10%", "Proposta", None],
        [None, None, "Seguir", "Nada", "Proposta", None],
        ["Ferreiro Sombrio", "Uma forja que nunca apaga.", "Forjar às pressas", "Sobe 2 cartas sorteadas; remove 1 carta sorteada", "Proposta", None],
        [None, None, "Encomendar (50 de ouro)", "Sobe 1 carta à escolha", "Proposta", None],
        [None, None, "Seguir", "Nada", "Proposta", None],
        ["Tumba Esquecida", "Uma laje rachada esconde algo.", "Abrir", "50%: 1 relíquia sorteada. 50%: o próximo herói chega com uma habilidade a mais", "Proposta", None],
        [None, None, "Saquear com cuidado", "1 carta comum sorteada", "Proposta", None],
        [None, None, "Seguir", "Nada", "Proposta", None],
    ])

    sheet(wb, "Run - Arena", P, W, [
        ["Raio em que o herói caça atiradores e estruturas na arena (m)", 10, D + " (hoje 3 m para tudo; os outros monstros seguem em 3 m)", None],
        ["Torre de Gárgula na arena", "não é mais ignorada", D, None],
        ["Torre: tempo em pedra (s)", 3, D + ": vira pedra por 3 s quando o herói chega a 3 m", None],
        ["Torre: tempo vulnerável depois da pedra (s)", 5, D, None],
        ["Teleporte: custo (elixir)", 2, D + " (hoje 0)", None],
        ["Teleporte: recarga (s)", 12, D + " (hoje 8)", None],
    ])

    sheet(wb, "Run - Ofertas", P, W, [
        ["Uma oferta mistura tipos?", "nunca", D + ": cada oferta é só de cartas, ou só de modificadores, ou só de níveis", None],
        ["Queda de herói: chance de a oferta ser de cartas", 0.7, "Proposta: sorteia o tipo uma vez (70% cartas, 30% modificadores) e as 3 opções são desse tipo", None],
        ["Ponte vencida", "escolhe o tipo", "Mantido: primeiro você escolhe o tipo, depois 1 entre 3 do tipo escolhido", None],
        ["Disputa perdida", "nada", D, None],
        ["Recargas das habilidades do herói", "HUD + aviso", D + ": ícones com recarga radial na HUD; o ícone aparece sobre o herói 1 s antes de a habilidade disparar", None],
    ])

    try:
        wb.save(XLSX)
    except PermissionError:
        sys.exit("não consegui salvar: a planilha está aberta no Excel? (backup em %s)" % backup)
    print("ok: abas Run - salvas; backup em", backup.name)


if __name__ == "__main__":
    main()
