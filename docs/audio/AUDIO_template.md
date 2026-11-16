# Áudio do Last Boss

Todo o áudio do jogo é **CC0** (domínio público), baixado do OpenGameArt com a licença conferida na página de cada
pacote em 16/11/2026. Os efeitos sintetizados antigos (`assets/audio/*.wav`, de `tools/make_audio.py`) ficam no
repositório só como reserva.

- **Ouvir tudo:** abra `docs/audio/index.html` no navegador, direto do repositório. A página mostra cada som, onde
  ele toca, o autor e o link da origem.
- **Licenças:** `assets/audio/LICENSES.txt` traz autor, título, URL e arquivo de origem de cada `.ogg`.
- **Código:** `game/audio.gd` (`GameAudio`). O mapa id → arquivo fica nos dicionários `SFX` e `MUSIC` do começo
  do arquivo.

A escolha foi feita **sem ouvir**: por nome, duração, linha melódica (no caso dos jingles) e volume medido. Use a
página de escuta para trocar o que não servir (veja "Como trocar um som").

## Como funciona

**Ônibus.** As músicas tocam no ônibus `Music`; efeitos, jingles e o som ambiente tocam no `SFX`. O volume dos dois
fica nas Configurações (`game/settings.gd`). O `audio.gd` não mexe no volume dos ônibus: ele só põe um filtro
passa-baixa no `Music`, usado pela intensidade da estrada.

**Música por contexto** (troca com crossfade de 1,6 s em tempo real, com dois players, sem depender de
`Engine.time_scale`):

- **Menu e mapa da campanha.** `audio.music_menu()` toca `music_menu` e desliga o ambiente. O `main.gd` chama
  essa função ao abrir o jogo e ao voltar para o menu.
- **Início da run.** `audio.music_for_run(sim)` escolhe a estrada pelo vilão (`sim.deck_id`):
  - `plague` → `music_road_plague`;
  - `dragon` → `music_road_dragon`;
  - `lich` → `music_road_lich`;
  - outro vilão → `music_road`.

  O ambiente sai da fase da campanha (`sim.campaign_phase`). Se o save retomado já está na arena
  (`sim.phase == ARENA`), a função toca a arena direto. O `main.gd` chama `music_for_run` em `_begin`, que serve
  tanto para run nova quanto para "Continuar".
- **Arena.** O evento `Ev.ARENA` troca para `music_arena` e o ambiente para `amb_dungeon`, e toca o jingle `arena`.
  Se a run chegar na arena sem o evento (eventos desligados, como no `--skip=arena`), o `handle_events` percebe pela
  fase e troca do mesmo jeito.
- **Fim da run.** `audio.result_music(vitória)` toca `music_victory` ou `music_defeat` **uma vez** (sem loop) e
  some com o ambiente.

**Intensidade na estrada.** `set_intensity(k)` continua com a mesma interface. Na estrada, a trilha começa abafada
(passa-baixa em ~2,2 kHz) e 5 dB mais baixa, e abre conforme o herói anda. O `main.gd` passa no máximo 0,6 antes da
estrada fechar, então com `k ≥ 0,6` a trilha já está toda aberta. Fora da estrada (menu, arena, resultado), o
filtro fica desligado.

**Som ambiente** (loop, bem baixo, `AMB_DB = -13 dB`):

| Fase da campanha | Ambiente |
|---|---|
| 0 Fazenda | `amb_field` (pássaros de manhã) |
| 1 Vila e 6 Capital | `amb_village` |
| 2 Floresta | `amb_river` (riacho com pássaros) |
| 3 Mosteiro, 4 Forte e 5 Torre | `amb_wind` |
| Arena | `amb_dungeon` |

**Efeitos.**

- **Players.** Há um pool de 16 players (usa um livre e, se todos estiverem ocupados, corta o mais antigo) e três
  players só para jingles, que golpes não cortam. Assim um aviso não corta o outro: por exemplo, o `reward` da
  oferta não corta o `act_end`. O `level_player` é curto (0,3 s) e vai no pool comum, porque a oferta toca uma
  escadinha de tons, uma carta a cada 0,11 s.
- **Recarga e limite.** Cada id tem recarga própria (`cd`), e entram no máximo 8 efeitos novos por quadro, então
  centenas de unidades não viram ruído. Cada toque sorteia uma das variações.
- **Golpes por tipo** (`Ev.DAMAGE_UNIT`):
  - estrutura, constructo ou morto-vivo → `hit_hard` (madeira/osso);
  - parte do chefe na arena → `boss_hit`;
  - o resto → `hit` (carne/couro).

  Quando um monstro acerta o herói, toca `hero_hit` (armadura de metal).
- **Mortes por tipo** (`Ev.DEATH`): morto-vivo → `death_bone`; constructo ou estrutura → `death_stone`; o resto →
  `death`.
- **Feitiços pela marca da carta** (`Ev.SPELL`): Fogo → `spell_fire`; Morto-vivo ou Sombra → `spell_dark`; o resto
  → `spell`. Carta de campo → `card_play`.
- **Avisos grandes.** O letreiro que bate na tela (`hud.gd`/`big_banner.gd`) já chamava `part_destroyed` na
  batida. O jingle toca no próprio evento da simulação:
  - `Ev.CONTEST` com código `0` → `contest_start`;
  - códigos `3`, `4` e `5` → `contest_mark` (um tom acima a cada marco);
  - código `1` → `contest_won`;
  - código `11` ou maior → `contest_partial`;
  - código negativo → `contest_lost`;
  - `Ev.ACT_START` → `act_start`;
  - `Ev.ACT_END` → `act_end`.

  O `Ev.SHRINE` do Santuário sai junto com o `CONTEST` e ficou sem som próprio, para não tocar duas vezes.
- **Outros eventos:**
  - `HERO_LEVEL` → `level_hero`;
  - `HERO_FALL` → `hero_fall`;
  - `TELEPORT` → `teleport`;
  - `PART_DESTROYED` → `part_destroyed` + `death_stone`;
  - `RELIC` → `relic`;
  - `HEAL` → `heal`;
  - `CURSE` → `curse`;
  - `FEAR` → `fear`;
  - `ABILITY_TELL` → `ability_tell`;
  - `SHIELD_BREAK` → `shield_break`;
  - `EXPLOSION` → `explosion`.
- **Interface.** O `hud.sfx.call(id, tom)` e o livro da loja continuam usando `reward`, `level_player`,
  `card_play` e `ui_click`; agora esses ids tocam os arquivos novos.

**Reserva.** Uma variação que falta é só pulada. Se faltarem todos os `.ogg` de um id, ele cai no `.wav` antigo de
mesmo nome, que só existe para os 15 ids antigos (`hit.wav`, `death.wav`...). Se faltar uma música, ela cai em
`<nome>_base.wav`, que só existe para `music_road` e `music_arena`; as outras ficam em silêncio, com um aviso no
log. Um id desconhecido em `play()` ou `music()` não quebra nada.

## Mapa: contexto → arquivo → quando toca

Gerado de `game/audio.gd` e do manifesto da conversão (`docs/audio/manifest.json`).

{{TABELAS}}

## Como trocar um som

1. **Ache um substituto que seja CC0 de verdade.** Confira o campo "License(s)" na página de origem. Ouça antes em
   `docs/audio/index.html`.
2. **Converta para Ogg Vorbis.** Efeitos em mono, aparados, RMS perto de -20 dBFS e pico até -1 dBFS:
   `ffmpeg -i origem.wav -af "silenceremove=start_periods=1:start_threshold=-50dB" -ac 1 -c:a libvorbis -q:a 4 sfx_x.ogg`.
   Músicas ficam perto de -16 LUFS (ganho fixo, sem `loudnorm` dinâmico, que estraga a emenda do loop):
   `-c:a libvorbis -q:a 5`.
3. **Para trocar um arquivo, mantenha o nome** em `assets/audio/`. O Godot reimporta ao abrir o editor ou com
   `--headless --import`.
4. **Para mudar o mapa**, edite `game/audio.gd`:
   - `SFX`: `"f"` são as variações, `"db"` o volume, `"cd"` a recarga e `"j"` marca jingle;
   - `MUSIC`: arquivo e se faz loop;
   - `ROAD_BY_DECK`: música da estrada por vilão;
   - `AMB_BY_PHASE`: ambiente por fase;
   - `MUSIC_TRIM` e `AMB_TRIM`: ajuste fino de volume.
5. **Atualize as licenças e esta página.** Os scripts usados na conversão estão em `docs/audio/`:
   - `build_audio.py` converte a partir dos downloads e grava o manifesto. Os downloads não estão no repositório,
     então ele serve de referência dos parâmetros (origem, corte, emenda, ganho) ou para refazer tudo depois de
     baixar de novo os pacotes de `LICENSES.txt`;
   - `docs_audio.py` confere que todo id aponta para um arquivo existente e regenera `LICENSES.txt`,
     `docs/audio/index.html` e a tabela acima.

   Rode-os com `python -I`, porque os arquivos baixados não são confiáveis.

## O que ficou de fora

- **Rio por proximidade.** O riacho só toca na fase da Floresta. Dá para fazer uma camada de rio que sobe perto
  da água (`sim/rivers.gd`), mas ficou para depois.
- **Floresta.** A gravação "Forest bird sounds" (pauliuw, CC0) é 8 kHz mono e foi descartada; a Floresta usa o
  riacho do "Park ambiences".
- **Faixas baixadas sem uso.** Ficaram de fora "Medieval: Battle" e "Medieval: The Old Tower Inn" (RandomMind),
  "Dramatic Boss Encounter" (cynicmusic), "Dungeon Ambience" (yd) e o vento "windy ambient noise" (Some Weirdo, com
  notas soltas que brigariam com a música).
- **Depois da vitória ou derrota** a música toca uma vez e fica em silêncio até voltar ao menu.
