# Decisões — Last Boss

Registro das decisões tomadas fora do GDD. O conteúdo das cartas e os 12 problemas resolvidos estão em `Revisao do conteudo - Last Boss.xlsx` (abas Leia-me e Problemas).

## Projeto (06/11/2026)

- Escopo: o MVP inteiro do GDD. Ficam de fora meta-progressão, outros chefes e heróis, níveis de dificuldade e Steam.
- Ordem: a run completa (estrada → arena) fica jogável cedo, com peças cinzas. A arte do Blender é feita em paralelo e vai substituindo essas peças. Você joga a cada marco.
- Godot 4.7.2 nesta pasta, com git local. GitHub depois.
- Downloads de ferramentas e assets estão liberados. Os scripts de terceiros são lidos antes de rodar.

## Bot de balanceamento (06/11/2026)

1. **Meta:** as metas do GDD, juntas numa nota única (a distância até elas):
   - perfil heurístico vence 50–65% das runs;
   - perfil aleatório vence menos de 10%;
   - chegada à arena em 11–13 min;
   - herói chega à arena no nível 12–16;
   - os decks ficam a menos de 5 pontos percentuais entre si;
   - nenhuma carta aparece em mais de 70% das vitórias;
   - elixir desperdiçado abaixo de 10% da run.
2. **Velocidade:** a simulação fica separada do visual desde o primeiro dia. Ela é lógica pura, com passo fixo, determinística por semente, e roda várias runs em paralelo (uma por núcleo da CPU). Meta: 15 min de jogo em menos de 5 s. O visual só desenha o estado da simulação.
3. **Personalidades:** cada uma é um arquivo de parâmetros (agressividade, economia, gosto por enxame, risco, quanto guarda elixir...). Criar um bot é criar um arquivo. Começam pelos 5 perfis do GDD. Os **exploradores** evoluem sozinhos procurando estratégias que quebram o jogo; quando acham uma, ela vira uma personalidade nova.
4. **Ajuste de números (script, sem supervisão):**
   - pode mudar vida, dano, XP e tempos em até ±30% por ciclo;
   - o custo de elixir muda só ±1, no máximo uma vez por carta a cada 10 ciclos;
   - há uma lista de valores travados que o script nunca toca (ex.: 2,8 s de elixir, mão de 5).
   - Roda quando você mandar, ou numa tarefa agendada.
5. **Mudanças de regra (sessão do Claude):** o Claude lê os relatórios acumulados e aplica as mudanças de regra que os números não resolvem. Pode reescrever efeitos de cartas, upgrades e contratos. Nunca toca nos 4 pilares do GDD e nunca tira cartas do jogo.
6. **Histórico:** um commit por ciclo, com o relatório, na branch `balance`. Um pacote só entra na `main` depois de você jogar pelo menos uma run com ele.
7. **Ordem:** a simulação separada e os bots Aleatório e Guloso entram no marco 1. O ajustador e os exploradores entram logo que a run completa existir.
