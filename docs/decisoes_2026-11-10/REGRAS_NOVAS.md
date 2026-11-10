# Regras novas — proposta para aprovação (10/11/2026)

Esta é a última checagem antes do trabalho corrido. Tudo aqui já foi decidido em linhas gerais na nossa conversa; o que está abaixo são os **detalhes que eu preenchi**. Marque ✔, ✎ ou ✘ em cada bloco. Os números são ponto de partida e serão calibrados com os bots.

## 1. A escada de poder por ato

| | Ato 1 | Ato 2 | Ato 3 e arena |
|---|---|---|---|
| Elixir máximo (base) | 10 | 13 | 16 |
| 1 de elixir a cada | 2,8 s | 2,3 s | 1,9 s |
| Custo máximo em ofertas | 7 | 9 | 12 |
| Mão (base) | 5 | 5 | 5 |
| Teto com cartas e relíquias | elixir 20, mão 7 | idem | idem |

- O que sobe além da base vem de você: cartas Temporárias (Coletor de Almas, Cálice Profundo, Biblioteca), relíquias e recompensas de local.
- **Sacrifício** de carta rende 10% do elixir máximo (hoje é +1 fixo), com a mesma recarga de 8 s.
- Meta de sensação: no ato 3 você gasta ao menos o dobro de elixir por minuto do ato 1.

## 2. Baralho

- Pilha de compra → mão → descarte. Quando a compra acaba, o descarte é embaralhado e vira a nova compra.
- Na tela: dois montes com contador; clicar mostra as cartas de cada um, sem a ordem.
- **Retorna**: a carta volta para a compra em posição aleatória, no máximo uma vez por embaralhada (na segunda, vai ao descarte). Isso impede o laço de custo 0.
- **Temporário**: a carta faz efeito por um tempo e vai ao descarte normalmente. Se o efeito acabar com a mão maior que o novo limite, nenhuma carta é expulsa; a vaga só deixa de ser reposta.
- Cartas de **Rota** (Isca de Ouro, Incêndio) ficam fora do baralho só durante a arena.
- Reembolsos de elixir têm teto por uso (Banquete de Almas: até 8).

## 3. Vilões

| Vilão | Passiva | Libera em |
|---|---|---|
| Rainha da Praga | **Infestação**: criatura de Bando que morre tem 20% de chance de deixar um rato | início |
| Dragão Avarento | **Tesouro do Dragão**: começa com 30 de ouro; cada 50 de ouro guardado dá +5% de fogo (até +30%) | vitória na fase 1 |
| Lich | **Colheita**: a cada 8 mortes de criaturas suas, o próximo feitiço custa 0 | vitória na fase 2 |

- Liberar um vilão entrega todas as comuns e incomuns dele e 3 raras. As outras raras e as lendárias custam Almas.
- As fases 3 e 4 da campanha pagam Almas e uma rara à escolha.
- Relíquias, contratos e eventos passam a ter dono: os ligados a Bando só aparecem para a Praga, e assim por diante.
- Saves antigos: Horda vira Praga; Ruína e Tesouro viram Dragão; Cripta e Culto viram Lich. Suas Almas ficam. Uma run em andamento da versão antiga é descartada.

## 4. Ritmo: estrada curta, disputas em 3 momentos

- Estrada de 300 m por ato (era 600), com os mesmos 7 a 8 locais: cerca de 12 s de caminhada entre paradas.
- Cada local é uma disputa de 40 a 50 s em 3 etapas que apertam.
- **Recompensa por degraus:** 0 etapas vencidas = nada; 1 ou 2 = ouro (15 e 30); as 3 = a recompensa cheia do local. Nenhuma etapa dá vantagem ao herói.
- A 3ª etapa muda por ato, para os ~24 locais da run não se repetirem.

| Local | Hoje | Etapas 1 · 2 · 3 | Variação da 3ª etapa (ato 2 · ato 3) |
|---|---|---|---|
| Círculo de Ritual | 10 mortes no círculo em 25 s | 6 · 10 · 14 mortes, 15 s cada | as mortes precisam ser de monstros de custo 3 ou mais · o herói expulsa do círculo quem fica mais de 3 s |
| Santuário | 6 s com monstros no círculo, em 20 s | segurar 6 · 8 · 10 s | o círculo encolhe · dois círculos ao mesmo tempo |
| Taverna | destruir as casas | 1 · 2 · 3 casas, 15 s cada | moradores reparam a casa · um herói defende cada casa |
| Ponte | causar dano enquanto ele atravessa | 150 · 250 · 400 de dano, 15 s cada | o herói recua para se curar · a ponte tem escudo frontal |
| Fonte Sagrada | interromper 1 gole de 4 s | interromper 3 goles; cada gole precisa de mais dano | gole mais curto (3 s) · dois heróis bebem |
| Loja | sem disputa | continua sem disputa: é a pausa do ato | — |
| Encruzilhada ? | evento de texto | continua evento de texto | — |

## 5. Ofertas

- Recompensas e escolhas: uma raridade só por oferta. Se o pool não tem opções suficientes daquela raridade, a oferta inteira cai para a vizinha.
- A loja fica de fora: raridades e preços variados.
- Custo liberado por ato vale para toda oferta, inclusive a loja.

## 6. Arena final

- Mesmas regras de hoje; muda o corpo do chefe (um por vilão, 4 partes com as mesmas funções).
- Sem Finalizações: o clímax passa a ser as cartas de custo 10 a 12, que só chegam no ato 3.
- Recompensas trocadas: a relíquia Pedra da Passagem vira **Pedra do Atalho** (a primeira carta de cada disputa custa 2 a menos); o contrato "Sem Testemunhas" passa a pagar uma rara do seu vilão; a opção "sangue" do Altar Profano passa a dar +2 de elixir máximo pelo resto do ato em troca de 2 maldições… em você: suas próximas 3 cartas custam 1 a mais.

## 7. O que ainda vai mudar com a calibração

Vida dos heróis por vilão e fase, duração exata de cada etapa, custo e números de cada carta. As ideias, os papéis e as regras deste documento não mudam sem te avisar no relatório final.
