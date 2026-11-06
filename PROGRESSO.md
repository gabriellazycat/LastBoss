# Progresso — Marco 1 (run completa jogável, feia)

## Estado (06/11/2026)

Tudo do marco 1 está implementado e testado. A arte é feita de peças cinzas e o balanceamento ainda não foi ajustado.

| Item do marco 1 | Estado |
|---|---|
| Estrada gerada com 2–3 bifurcações, os 6 locais e minimapa | ✓ |
| Escudeiro com IA por pontuação (rota, movimento, mapa de perigo, alvo, upgrades) e escudo frontal | ✓ |
| Elixir, mão (5, ou 6 na Horda), deck único, sacrifício, anel de 3–12 m | ✓ |
| As 18 cartas de campo com os 7 arquétipos; 4 de rota; 4 de covil; 5 modificadores | ✓ |
| XP e level-up do herói (15 upgrades), do jogador (ofertas por raridade), santuários, 8 contratos | ✓ |
| Arena: corpo em 4 partes, 5 altares, teleporte, 6 cartas de finalização | ✓ |
| Bots Aleatório e Guloso headless em lote paralelo, JSON e relatório | ✓ (360 runs em 68 s) |
| Pooling e MultiMesh: 500 unidades | ✓ 166 FPS em média, 122 no mínimo (RTX 2060) |
| Simulação: 15 min de jogo em < 5 s | ✓ ~1,5–2 s por run |
| Texto pt/en pela tradução da Godot | ✓ |
| Testes, teste da entrada real, executável exportado | ✓ |

## Como rodar

O executável fica em `C:\Users\gabri\AppData\Local\Microsoft\WinGet\Packages\GodotEngine...\Godot_v4.7.2-stable_win64_console.exe` (abaixo, `godot`).

- Jogar: abra o projeto na Godot e aperte F5, ou rode `export/LastBoss.exe` depois de exportar.
- Testes: `godot --headless --path . res://tests/tests.tscn` (sai com o número de falhas).
- Teste da entrada real (precisa de janela): `godot --path . -- --uitest=1`
- Ver o bot jogando: `godot --path . -- --autoplay=greedy --deck=ruin --speed=4`. Também aceita `--skip=600` (pula direto para perto da arena), `--quit=60` e `--shots=10,30 --out=<pasta>` (capturas de tela).
- Estresse: `godot --path . --disable-vsync -- --autoplay=random --stress=500 --quit=25`
- Lote de balanceamento: `python -I tools/run_batch.py --runs 60` grava `reports/<data>/report.md`, `summary.json` e `runs.json`.
- Reconverter a planilha (sobrescreve `data/`): `python -I tools/xlsx_to_json.py`
- Exportar: `godot --headless --path . --export-release "Windows Desktop" export/LastBoss.exe`

Controles: teclas 1–6 escolhem a carta e o clique posiciona; X+número ou clique direito na carta sacrifica; M amplia o minimapa (clique nele para usar cartas de rota); Q/E trocam de altar na arena; Espaço pausa; F muda a velocidade. No controle: L1/R1 escolhem, o analógico direito move o cursor, A confirma, segurar B sacrifica, Select abre o minimapa, o direcional troca de altar.

## Último lote (60 runs por combinação)

| bot | deck | vitória | chegada à arena | herói na arena |
|---|---|---|---|---|
| Guloso | Horda | 0% | 674 s | nv 16,8 |
| Guloso | Ruína | 77% | 551 s | nv 3,8 |
| Guloso | Tesouro | 0% | 616 s | nv 13,0 |
| Aleatório | Horda | 5% | 631 s | nv 11,7 |
| Aleatório | Ruína | 73% | 556 s | nv 6,1 |
| Aleatório | Tesouro | 2% | 719 s | nv 14,7 |

Leitura: a chegada à arena (550–720 s) e o nível do herói já estão perto das metas. O problema principal é o deck Ruína. Feitiços não dão XP, então o herói chega à arena fraco, e o próprio P8 da planilha já pedia para medir isso. Horda e Tesouro levam o herói a níveis altos demais. Esse é o trabalho do ajustador automático.

## Próximos passos (depois do marco 1, como no DECISOES.md)

1. Ajustador automático na branch `balance`: edita o JSON dentro dos limites (±30%, custo ±1 a cada 10 ciclos, `data/locked.json`) e faz um commit por ciclo com o relatório.
2. Bots Heurístico, Economista e Enxame, e os exploradores.
3. Arte do Blender no lugar das peças cinzas; efeitos, áudio, menu 3D no covil.
4. Pilares da arena, salvamento no meio da run, tutorial.
5. O lote não roda pelo executável exportado (builds de release não aceitam caminho de cena); ele roda pelo binário do editor.
