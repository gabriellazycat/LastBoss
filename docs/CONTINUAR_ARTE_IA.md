# Arte das cartas por IA — onde parou e como continuar

Atualizado em 12/11/2026 (noite). O designer está fora e deu autonomia total ("faça tudo sem perguntar, coloque
tudo no jogo, eu testo depois; se acabarem os tokens, continue sozinho quando resetar").
Skill: `.claude/skills/cartas-ia/SKILL.md`. Notas técnicas: `arte_ia/NOTES.md`.

## Estado (marque ao concluir)

**Concluído em 13/11, 11:20.** As 84 cartas estão no jogo na branch `arte-ia` (worktree
`C:\Users\gabri\Desktop\LastBoss-arte-ia`, commits `6a14326`, `1e37802`, `b0b434e`; sem push, main intacta).
Relatório: `LastBoss-arte-ia\docs\ARTE_IA_RELATORIO.md`. Build: `LastBoss-arte-ia\export\LastBoss.exe`.

- [x] Estilo decidido (B, sem referência, 768×736, grão 0,9), assuntos das 84 cartas em `arte_ia/_tools/subjects/`.
- [x] Baralho gerado: 84 em `arte_ia/final/`, pranchas em `arte_ia/pranchas/`.
- [x] Backup das artes antigas em `arte_ia/_backup_assets_cards/` e cópia para `assets/cards/` (na worktree).
- [x] `data/card_art.json`: 84 cartas `painted` (na worktree).
- [x] `--import` do Godot e testes com falhas: 0 (na worktree).
- [x] Export em `LastBoss-arte-ia\export\LastBoss.exe`.
- [x] Commit na branch `arte-ia` e relatório.

**13/11 11:26: mesclado na main** (pedido do Gabriel: todas as mudanças e branches na main). Build atual: `LastBoss\export\LastBoss.exe` (o anterior ficou em `export/_anterior_2026-11-13/`). A worktree `LastBoss-arte-ia` ficou obsoleta. Falta só o Gabriel jogar, revisar as pranchas e pedir refações.

## Como continuar (comandos)

1. ComfyUI no ar? `curl -s http://127.0.0.1:8188/system_stats`. Se não:
   `C:\AI\ComfyUI\venv\Scripts\python main.py --listen 127.0.0.1 --port 8188 --lowvram` (em segundo plano, cwd `C:\AI\ComfyUI`).
2. Gerar o que faltar (pula as prontas): `cd arte_ia/_tools && for v in plague dragon lich common base; do python -I deck.py lote $v; done; python -I build_gallery.py`
3. Integrar: `python -I arte_ia/_tools/integrar.py` (backup + cópia + card_art.json; idempotente).
4. Godot: `G=".../Godot_v4.7.2-stable_win64_console.exe"` (caminho em `docs/CONTINUAR.md`);
   `"$G" --headless --path . --import`; `timeout 900 "$G" --headless --path . res://tests/tests.tscn > /tmp/t.txt 2>&1; tail -3 /tmp/t.txt`.
5. Export: `"$G" --headless --path . --export-release "Windows Desktop" export/LastBoss.exe` (com timeout, saída em arquivo).
6. Commit na branch `arte-ia` e relatório.
