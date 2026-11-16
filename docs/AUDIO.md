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

### Músicas e ambientes

| Contexto | Arquivo | Quando toca | Origem |
|---|---|---|---|
| `music_menu` | `music_menu.ogg` | Menu, mapa da campanha e telas fora da run (loop perfeito). | [Once Upon a Time (loop)](https://opengameart.org/content/once-upon-a-time-loop) (TAD) |
| `music_road` | `music_road.ogg` | Estrada de reserva (vilão sem trilha própria) e apelido do antigo "music_road". | [Determined Pursuit (epic orchestra loop)](https://opengameart.org/content/determined-pursuit-epic-orchestra-loop) (Emma_MA) |
| `music_road_plague` | `music_road_plague.ogg` | Estrada com a Rainha da Praga (deck plague); loop com emenda cruzada de 4 s. | [Evil Approach](https://opengameart.org/content/evil-approach) (nene) |
| `music_road_dragon` | `music_road_dragon.ogg` | Estrada com o Dragão Avarento (deck dragon); loop com emenda cruzada de 4 s. | [Ancient Power Of Serpents](https://opengameart.org/content/ancient-power-of-serpents) (josepharaoh99) |
| `music_road_lich` | `music_road_lich.ogg` | Estrada com o Lich (deck lich); loop com emenda cruzada de 3 s. | [Sinister Boss Appears!](https://opengameart.org/content/sinister-boss-appears) (cynicmusic) |
| `music_arena` | `music_arena.ogg` | Arena contra o chefe (todos os vilões), loop perfeito. | [Boss Battle Music](https://opengameart.org/content/boss-battle-music) (Juhani Junkala (SubspaceAudio)) |
| `music_victory` (uma vez) | `music_victory.ogg` | Fim da run com vitória (toca uma vez). | [Medieval: Victory Theme](https://opengameart.org/content/medieval-victory-theme) (RandomMind) |
| `music_defeat` (uma vez) | `music_defeat.ogg` | Fim da run com derrota (toca uma vez). | [Medieval: Defeat Theme](https://opengameart.org/content/medieval-defeat-theme) (RandomMind) |
| ambiente | `amb_dungeon.ogg` | Ambiente da arena (covil): vento grave e gotas. | [Loopable Dungeon Ambience](https://opengameart.org/content/loopable-dungeon-ambience) (JaggedStone) |
| ambiente | `amb_field.ogg` | Ambiente da estrada na Fazenda (fase 0) e reserva: pássaros de manhã. | [AMB Morning Sounds (Perfect Loop)](https://opengameart.org/content/amb-morning-sounds-perfect-loop) (Kresiek The Furry) |
| ambiente | `amb_river.ogg` | Ambiente da estrada na Floresta (fase 2): riacho com pássaros; trecho de 60 s em loop. | [Park ambiences](https://opengameart.org/content/park-ambiences) (Thimras) |
| ambiente | `amb_village.ogg` | Ambiente da estrada na Vila (fase 1) e na Capital (fase 6). | [AMB Outside 1](https://opengameart.org/content/amb-outside-1) (Kresiek The Furry) |
| ambiente | `amb_wind.ogg` | Ambiente da estrada no Mosteiro, Forte e Torre (fases 3 a 5): vento. | [Mild Wind Background Noise](https://opengameart.org/content/mild-wind-background-noise) (Bashar3A) |

### Efeitos e jingles

| id | Arquivo(s) | Volume / recarga | Quando toca | Origem |
|---|---|---|---|---|
| `card_play` | `sfx_card_1.ogg`, `sfx_card_2.ogg`, `sfx_card_3.ogg`, `sfx_card_4.ogg` | -3 dB / 0.05 s | carta de campo jogada, rota escolhida, carta na oferta. | [54 Casino sound effects (cards, dice, chips)](https://opengameart.org/content/54-casino-sound-effects-cards-dice-chips) (Kenney) |
| `spell` | `sfx_spell_1.ogg`, `sfx_spell_2.ogg`, `sfx_spell_3.ogg` | -6 dB / 0.08 s | feitiço jogado. | [Magic Spell SFX](https://opengameart.org/content/magic-spell-sfx) (JaggedStone) |
| `spell_fire` | `sfx_spell_fire_1.ogg`, `sfx_spell_fire_2.ogg` | -6 dB / 0.08 s | feitiço com a marca Fogo (Dragão). | [80 CC0 RPG SFX](https://opengameart.org/content/80-cc0-rpg-sfx) (rubberduck) |
| `spell_dark` | `sfx_spell_dark_1.ogg`, `sfx_spell_dark_2.ogg` | -6 dB / 0.08 s | feitiço Morto-vivo/Sombra (Lich) e maldição no herói. | [3 dark magic spells](https://opengameart.org/content/3-dark-magic-spells) (qubodup) |
| `hit` | `sfx_hit_flesh_1.ogg`, `sfx_hit_flesh_2.ogg`, `sfx_hit_flesh_3.ogg` | -13 dB / 0.07 s | o herói acerta um monstro (carne/couro). | [100 CC0 SFX](https://opengameart.org/content/100-cc0-sfx) (rubberduck); [50 RPG sound effects](https://opengameart.org/content/50-rpg-sound-effects) (Kenney) |
| `hit_hard` | `sfx_hit_hard_1.ogg`, `sfx_hit_hard_2.ogg` | -13 dB / 0.07 s | o herói acerta estrutura, constructo ou morto-vivo (madeira/osso). | [75 CC0 breaking / falling / hit sfx](https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx) (rubberduck) |
| `hero_hit` | `sfx_hero_hit_1.ogg`, `sfx_hero_hit_2.ogg`, `sfx_hero_hit_3.ogg` | -12 dB / 0.09 s | um monstro acerta o herói (armadura de metal). | [75 CC0 breaking / falling / hit sfx](https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx) (rubberduck) |
| `boss_hit` | `sfx_boss_hit_1.ogg`, `sfx_boss_hit_2.ogg` | -9 dB / 0.10 s | o herói acerta uma parte do chefe na arena. | [10 Impact/Shield Blocks](https://opengameart.org/content/10-impactshield-blocks) (StarNinjas) |
| `shield_break` | `sfx_shield_break.ogg` | -6 dB / 0.15 s | escudo do herói quebra ou reflete. | [50 RPG sound effects](https://opengameart.org/content/50-rpg-sound-effects) (Kenney) |
| `explosion` | `sfx_explosion_1.ogg`, `sfx_explosion_2.ogg`, `sfx_explosion_3.ogg` | -6 dB / 0.06 s | explosões de cartas e do herói. | [25 CC0 bang / firework SFX](https://opengameart.org/content/25-cc0-bang-firework-sfx) (rubberduck) |
| `death` | `sfx_death_1.ogg`, `sfx_death_2.ogg`, `sfx_death_3.ogg` | -13 dB / 0.06 s | um monstro seu morre. | [80 CC0 RPG SFX](https://opengameart.org/content/80-cc0-rpg-sfx) (rubberduck) |
| `death_bone` | `sfx_death_bone_1.ogg`, `sfx_death_bone_2.ogg` | -12 dB / 0.06 s | morre um morto-vivo (ossos). | [75 CC0 breaking / falling / hit sfx](https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx) (rubberduck) |
| `death_stone` | `sfx_death_stone.ogg` | -9 dB / 0.10 s | estrutura ou constructo destruído; parte do chefe destruída. | [75 CC0 breaking / falling / hit sfx](https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx) (rubberduck) |
| `hero_fall` | `sfx_hero_fall.ogg` | -5 dB / 0.20 s | um herói da party cai (armadura no chão). | [75 CC0 breaking / falling / hit sfx](https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx) (rubberduck) |
| `part_destroyed` | `sfx_impact_heavy.ogg` | -5 dB / 0.12 s | letreiro grande batendo na tela e parte do chefe destruída. | [10 Impact/Shield Blocks](https://opengameart.org/content/10-impactshield-blocks) (StarNinjas) |
| `teleport` | `sfx_teleport.ogg` | -6 dB / 0.20 s | o chefe teleporta o herói na arena. | [Teleport Spell](https://opengameart.org/content/teleport-spell) (Ogrebane) |
| `relic` | `sfx_relic.ogg` | -6 dB / 0.20 s | relíquia ganha. | [80 CC0 RPG SFX](https://opengameart.org/content/80-cc0-rpg-sfx) (rubberduck) |
| `heal` | `sfx_heal.ogg` | -13 dB / 0.60 s | herói ou ajudante se cura. | [Magic Spell SFX](https://opengameart.org/content/magic-spell-sfx) (JaggedStone) |
| `curse` | `sfx_spell_dark_2.ogg` | -11 dB / 0.50 s | o herói recebe uma maldição (Ev.CURSE); reaproveita a 2ª variação de spell_dark. | [3 dark magic spells](https://opengameart.org/content/3-dark-magic-spells) (qubodup) |
| `fear` | `sfx_fear.ogg` | -9 dB / 0.80 s | o herói (ou um monstro) espalha medo. | [80 CC0 RPG SFX](https://opengameart.org/content/80-cc0-rpg-sfx) (rubberduck) |
| `ability_tell` | `sfx_ability_tell.ogg` | -6 dB / 0.30 s | o herói prepara uma habilidade (aviso). | [50 RPG sound effects](https://opengameart.org/content/50-rpg-sound-effects) (Kenney) |
| `ui_click` | `sfx_ui_click_1.ogg`, `sfx_ui_click_2.ogg` | -12 dB / 0.03 s | cliques e passar o mouse na loja/livro (papel). | [Interface Sounds](https://opengameart.org/content/interface-sounds) (Kenney) |
| `contest_start` (jingle) | `jingle_contest_start.ogg` | -7 dB / 0.30 s | o herói chega num local e a disputa começa (letreiro do objetivo). | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `contest_mark` (jingle) | `jingle_mark.ogg` | -7 dB / 0.20 s | marco da disputa alcançado. | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `contest_won` (jingle) | `jingle_won.ogg` | -5 dB / 0.30 s | disputa vencida; também o id antigo "victory". | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `contest_partial` (jingle) | `jingle_partial.ogg` | -6 dB / 0.30 s | disputa vencida em parte. | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `contest_lost` (jingle) | `jingle_lost.ogg` | -6 dB / 0.30 s | disputa perdida. | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `act_start` (jingle) | `jingle_act_start.ogg` | -6 dB / 0.50 s | começa um ato (letreiro "Ato N de M"). | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `act_end` (jingle) | `jingle_act_end.ogg` | -6 dB / 0.50 s | o herói fecha um ato (vem a oferta de carta e relíquia). | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `arena` (jingle) | `jingle_arena.ogg` | -5 dB / 1.00 s | o herói chega no covil. | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `level_hero` (jingle) | `jingle_level_hero.ogg` | -7 dB / 0.30 s | o herói sobe de nível (ameaça). | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `level_player` | `jingle_level_player.ogg` | -8 dB / 0.08 s | carta especial na oferta (escadinha de tons), compra na loja; curto (0,3 s). | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `reward` (jingle) | `jingle_reward.ogg` | -7 dB / 0.20 s | oferta de cartas aparece, livro da loja abre. | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `victory` (jingle) | `jingle_won.ogg` | -5 dB / 0.50 s | id antigo "victory"; o fim da run agora toca music_victory (result_music). | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |
| `defeat` (jingle) | `jingle_defeat.ogg` | -5 dB / 0.50 s | id antigo "defeat" (a derrota de verdade usa music_defeat). | [85 Short music jingles](https://opengameart.org/content/85-short-music-jingles) (Kenney) |

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
