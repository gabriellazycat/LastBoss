# Progresso — Last Boss

## Estado (06/11/2026)

O MVP está jogável do começo ao fim, com arte, áudio e interface polidos. Os números estão sendo ajustados pelo bot na branch `balance`.

| Área | Estado |
|---|---|
| Simulação separada do visual (determinística, passo fixo, headless) | ✓ ~1,5–2 s por run de 12 min |
| Estrada com bifurcações, 6 locais com cenário próprio, minimapa | ✓ |
| Escudeiro: IA por pontuação, escudo frontal, 15 upgrades, falas | ✓ |
| 32 cartas, 7 arquétipos, 5 modificadores, 8 contratos, santuários | ✓ |
| Arena: chefe em 4 partes, 5 altares, teleporte, 6 finalizações | ✓ |
| Os 5 perfis de bot (Aleatório, Guloso, Heurístico, Economista, Enxame) | ✓ |
| Ajustador automático (branch `balance`, um commit por ciclo) | ✓ |
| Arte: shader de paleta única, modelos low-poly, cenário espalhado, covil, arena | ✓ peças por código, prontas para trocar por modelos do Blender |
| Efeitos: partículas, orbes de alma voando até o herói, tremor, flashes | ✓ |
| Interface: cartas com arte 3D, menu no covil 3D, pausa com deck e build, dicas na primeira vez | ✓ |
| Áudio: efeitos e trilha em camadas que cresce até o covil, trilha da arena | ✓ sintetizados (provisórios) |
| Controles: mouse (clique ou arrastar), teclado, controle | ✓ |
| pt/en pela tradução da Godot | ✓ |
| 500 unidades | ✓ 166 FPS em média (RTX 2060) |
| Testes, teste da entrada real, executável exportado | ✓ |

## Qual versão jogar

- `main`: tudo, com os números da planilha mais as mudanças de regra.
- `balance`: o mesmo, com os números do ajustador. Pelo DECISOES.md, ela só entra na `main` depois que você jogar uma run com ela. Para jogar: `git checkout balance`, abrir na Godot e apertar F5. Os relatórios de cada ciclo ficam em `balance_reports/`.

## Como rodar

O executável da Godot fica em `C:\Users\gabri\AppData\Local\Microsoft\WinGet\Packages\GodotEngine...\Godot_v4.7.2-stable_win64_console.exe` (abaixo, `godot`).

- Jogar: abra o projeto na Godot e aperte F5, ou rode `export/LastBoss.exe` depois de exportar.
- Testes: `godot --headless --path . res://tests/tests.tscn`
- Teste da entrada real (janela): `godot --path . -- --uitest=1`
- Ver um bot jogando: `godot --path . -- --autoplay=heuristic --deck=ruin --speed=2`. Também aceita `--skip=600`, `--quit=60` e `--shots=10,30 --out=<pasta>`.
- Estresse: `godot --path . --disable-vsync -- --autoplay=random --stress=500 --quit=25`
- Lote: `python -I tools/run_batch.py --bots heuristic,random,greedy --runs 60`
- Ajustador (na branch `balance`): `python -I tools/tuner.py --cycles 15 --runs 8`
- Regerar o áudio: `python -I tools/make_audio.py`
- Exportar: `godot --headless --path . --export-release "Windows Desktop" export/LastBoss.exe`

Controles: teclas 1–6 escolhem a carta e o clique posiciona, ou arraste a carta até o mapa. Clique direito, X+número ou arrastar até "Sacrificar" sacrifica. M amplia o minimapa (ele abre sozinho com cartas de rota). Q/E ou clique trocam de altar na arena. A roda do mouse dá zoom, Espaço/Esc pausa e F muda a velocidade. No controle: L1/R1 escolhem, o analógico direito move o cursor, A confirma, segurar B sacrifica, Select abre o minimapa, o direcional troca de altar e Start pausa.

## O que fica para depois

1. Modelos e animações do Blender (Quaternius/Kenney) no lugar das peças por código, começando pelo herói e pelo chefe.
2. Trilha e efeitos sonoros finais (os atuais são sintetizados).
3. Exploradores (bots que evoluem procurando estratégias que quebram o jogo).
4. Pilares quebráveis da arena, salvamento no meio da run, tutorial guiado.
5. Testes com pessoas: o bot mede equilíbrio, não diversão.
