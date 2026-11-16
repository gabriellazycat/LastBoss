# Converte o áudio CC0 baixado para assets/audio/*.ogg (Vorbis) e grava o manifesto (origem, autor, uso).
# Uso: python -I build_audio.py <dl> <dl2> <saida assets/audio> <pasta de trabalho> [arquivo1.ogg,arquivo2.ogg]
# (a lista opcional refaz só esses arquivos e atualiza o manifesto que já existe na pasta de trabalho)
# Músicas: ganho estático para ~-16 LUFS (sem loudnorm dinâmico, para não estragar a emenda do loop).
# Ambientes: ~-20 LUFS. Efeitos: silêncio aparado, mono, RMS ~-20 dBFS com pico <= -1 dBFS.
import json, os, re, subprocess, sys

DL, DL2, OUT, WORK = sys.argv[1:5]
ONLY = set(sys.argv[5].split(",")) if len(sys.argv) > 5 else set()
os.makedirs(OUT, exist_ok=True)
os.makedirs(WORK, exist_ok=True)

OGA = "https://opengameart.org/content/"
SRC = {
    "k_rpg": ("Kenney", "50 RPG sound effects", OGA + "50-rpg-sound-effects"),
    "k_iface": ("Kenney", "Interface Sounds", OGA + "interface-sounds"),
    "k_casino": ("Kenney", "54 Casino sound effects (cards, dice, chips)", OGA + "54-casino-sound-effects-cards-dice-chips"),
    "k_jingle": ("Kenney", "85 Short music jingles", OGA + "85-short-music-jingles"),
    "juhani": ("Juhani Junkala (SubspaceAudio)", "Boss Battle Music", OGA + "boss-battle-music"),
    "nene": ("nene", "Evil Approach", OGA + "evil-approach"),
    "cynic": ("cynicmusic", "Sinister Boss Appears!", OGA + "sinister-boss-appears"),
    "joseph": ("josepharaoh99", "Ancient Power Of Serpents", OGA + "ancient-power-of-serpents"),
    "tad": ("TAD", "Once Upon a Time (loop)", OGA + "once-upon-a-time-loop"),
    "emma": ("Emma_MA", "Determined Pursuit (epic orchestra loop)", OGA + "determined-pursuit-epic-orchestra-loop"),
    "rm_vic": ("RandomMind", "Medieval: Victory Theme", OGA + "medieval-victory-theme"),
    "rm_def": ("RandomMind", "Medieval: Defeat Theme", OGA + "medieval-defeat-theme"),
    "rd_rpg": ("rubberduck", "80 CC0 RPG SFX", OGA + "80-cc0-rpg-sfx"),
    "rd_bfh": ("rubberduck", "75 CC0 breaking / falling / hit sfx", OGA + "75-cc0-breaking-falling-hit-sfx"),
    "rd_bang": ("rubberduck", "25 CC0 bang / firework SFX", OGA + "25-cc0-bang-firework-sfx"),
    "rd_100": ("rubberduck", "100 CC0 SFX", OGA + "100-cc0-sfx"),
    "ninjas": ("StarNinjas", "10 Impact/Shield Blocks", OGA + "10-impactshield-blocks"),
    "jag_magic": ("JaggedStone", "Magic Spell SFX", OGA + "magic-spell-sfx"),
    "jag_dungeon": ("JaggedStone", "Loopable Dungeon Ambience", OGA + "loopable-dungeon-ambience"),
    "qubodup": ("qubodup", "3 dark magic spells", OGA + "3-dark-magic-spells"),
    "ogrebane": ("Ogrebane", "Teleport Spell", OGA + "teleport-spell"),
    "kres_morning": ("Kresiek The Furry", "AMB Morning Sounds (Perfect Loop)", OGA + "amb-morning-sounds-perfect-loop"),
    "kres_out": ("Kresiek The Furry", "AMB Outside 1", OGA + "amb-outside-1"),
    "thimras": ("Thimras", "Park ambiences", OGA + "park-ambiences"),
    "bashar": ("Bashar3A", "Mild Wind Background Noise", OGA + "mild-wind-background-noise"),
}

M = DL + "/music/"
J = DL + "/jingleSounds_Kenney/x/OGG/"
# (arquivo de saída, chave da origem, arquivo de origem, tipo, parâmetros, onde toca)
ITEMS = [
    # ---- músicas
    ("music_menu.ogg", "tad", M + "once_upon_a_time_loop.wav", "music_loop", {}, "Menu, mapa da campanha e telas fora da run (loop perfeito)."),
    ("music_road_plague.ogg", "nene", M + "Evil_Approach.wav", "music_xfade", {"x": 4.0}, "Estrada com a Rainha da Praga (deck plague); loop com emenda cruzada de 4 s."),
    ("music_road_dragon.ogg", "joseph", M + "Ancient_Power_Of_Serpents_0.ogg", "music_xfade", {"x": 4.0}, "Estrada com o Dragão Avarento (deck dragon); loop com emenda cruzada de 4 s."),
    ("music_road_lich.ogg", "cynic", M + "Sinister_Boss_Appears.wav", "music_xfade", {"x": 3.0}, "Estrada com o Lich (deck lich); loop com emenda cruzada de 3 s."),
    ("music_road.ogg", "emma", M + "determined_pursuit_loop.wav", "music_loop", {}, "Estrada de reserva (vilão sem trilha própria) e apelido do antigo \"music_road\"."),
    ("music_arena.ogg", "juhani", M + "Juhani_Junkala_-_Epic_Boss_Battle_Seamlessly_Looping.wav", "music_loop", {}, "Arena contra o chefe (todos os vilões), loop perfeito."),
    ("music_victory.ogg", "rm_vic", M + "victory.wav", "music_once", {}, "Fim da run com vitória (toca uma vez)."),
    ("music_defeat.ogg", "rm_def", M + "defeat.wav", "music_once", {}, "Fim da run com derrota (toca uma vez)."),
    # ---- ambientes
    ("amb_field.ogg", "kres_morning", DL2 + "/morning/amb_morning_0.ogg", "amb_loop", {}, "Ambiente da estrada na Fazenda (fase 0) e reserva: pássaros de manhã."),
    ("amb_village.ogg", "kres_out", DL2 + "/outdoor/amb_outdoor1_loop.ogg", "amb_loop", {}, "Ambiente da estrada na Vila (fase 1) e na Capital (fase 6)."),
    ("amb_river.ogg", "thimras", DL2 + "/park_river/park_ambience_river.wav", "amb_xfade", {"s0": 90.0, "len": 60.0, "x": 4.0}, "Ambiente da estrada na Floresta (fase 2): riacho com pássaros; trecho de 60 s em loop."),
    ("amb_wind.ogg", "bashar", DL2 + "/mildwind/wind_background_noise_2.wav", "amb_xfade", {"s0": 0.0, "len": 38.0, "x": 4.0}, "Ambiente da estrada no Mosteiro, Forte e Torre (fases 3 a 5): vento."),
    ("amb_dungeon.ogg", "jag_dungeon", DL2 + "/dungeon_amb/dungeon_ambient_1_0.ogg", "amb_loop", {}, "Ambiente da arena (covil): vento grave e gotas."),
    # ---- efeitos
    ("sfx_card_1.ogg", "k_casino", DL + "/kenney_casino-audio/x/Audio/card-place-1.ogg", "sfx", {}, "card_play: carta de campo jogada, rota escolhida, carta na oferta."),
    ("sfx_card_2.ogg", "k_casino", DL + "/kenney_casino-audio/x/Audio/card-place-2.ogg", "sfx", {}, "card_play (variação)."),
    ("sfx_card_3.ogg", "k_casino", DL + "/kenney_casino-audio/x/Audio/card-place-3.ogg", "sfx", {}, "card_play (variação)."),
    ("sfx_card_4.ogg", "k_casino", DL + "/kenney_casino-audio/x/Audio/card-place-4.ogg", "sfx", {}, "card_play (variação)."),
    ("sfx_spell_1.ogg", "jag_magic", DL2 + "/magic7/magical_1_0.ogg", "sfx", {}, "spell: feitiço jogado."),
    ("sfx_spell_2.ogg", "jag_magic", DL2 + "/magic7/magical_3.ogg", "sfx", {}, "spell (variação)."),
    ("sfx_spell_3.ogg", "jag_magic", DL2 + "/magic7/magical_5.ogg", "sfx", {}, "spell (variação)."),
    ("sfx_spell_fire_1.ogg", "rd_rpg", DL2 + "/rpg80/x/spell_fire_01.ogg", "sfx", {}, "spell_fire: feitiço com a marca Fogo (Dragão)."),
    ("sfx_spell_fire_2.ogg", "rd_rpg", DL2 + "/rpg80/x/spell_fire_03.ogg", "sfx", {"max": 1.4}, "spell_fire (variação)."),
    ("sfx_spell_dark_1.ogg", "qubodup", DL2 + "/darkmagic/x/dark_magic/fout-01.flac", "sfx", {"max": 1.6}, "spell_dark: feitiço Morto-vivo/Sombra (Lich) e maldição no herói."),
    ("sfx_spell_dark_2.ogg", "qubodup", DL2 + "/darkmagic/x/dark_magic/fout-02.flac", "sfx", {}, "spell_dark (variação)."),
    ("sfx_hit_flesh_1.ogg", "k_rpg", DL + "/RPGsounds_Kenney/x/OGG/chop.ogg", "sfx", {}, "hit: o herói acerta um monstro (carne/couro)."),
    ("sfx_hit_flesh_2.ogg", "k_rpg", DL + "/RPGsounds_Kenney/x/OGG/dropLeather.ogg", "sfx", {}, "hit (variação)."),
    ("sfx_hit_flesh_3.ogg", "rd_100", DL2 + "/sfx100/x/hit_01.ogg", "sfx", {}, "hit (variação)."),
    ("sfx_hit_hard_1.ogg", "rd_bfh", DL2 + "/hit75/x/bfh1_wood_hit_01.ogg", "sfx", {}, "hit_hard: o herói acerta estrutura, constructo ou morto-vivo (madeira/osso)."),
    ("sfx_hit_hard_2.ogg", "rd_bfh", DL2 + "/hit75/x/bfh1_wood_hit_02.ogg", "sfx", {}, "hit_hard (variação)."),
    ("sfx_hero_hit_1.ogg", "rd_bfh", DL2 + "/hit75/x/bfh1_metal_hit_01.ogg", "sfx", {}, "hero_hit: um monstro acerta o herói (armadura de metal)."),
    ("sfx_hero_hit_2.ogg", "rd_bfh", DL2 + "/hit75/x/bfh1_metal_hit_02.ogg", "sfx", {}, "hero_hit (variação)."),
    ("sfx_hero_hit_3.ogg", "rd_bfh", DL2 + "/hit75/x/bfh1_metal_hit_03.ogg", "sfx", {}, "hero_hit (variação)."),
    ("sfx_boss_hit_1.ogg", "ninjas", DL2 + "/shield10/x/impact.1.ogg", "sfx", {"max": 0.6}, "boss_hit: o herói acerta uma parte do chefe na arena."),
    ("sfx_boss_hit_2.ogg", "ninjas", DL2 + "/shield10/x/impact.2.ogg", "sfx", {"max": 0.6}, "boss_hit (variação)."),
    ("sfx_impact_heavy.ogg", "ninjas", DL2 + "/shield10/x/impact.5.ogg", "sfx", {}, "part_destroyed: letreiro grande batendo na tela e parte do chefe destruída."),
    ("sfx_shield_break.ogg", "k_rpg", DL + "/RPGsounds_Kenney/x/OGG/metalPot1.ogg", "sfx", {"max": 1.0}, "shield_break: escudo do herói quebra ou reflete."),
    ("sfx_explosion_1.ogg", "rd_bang", DL2 + "/bang25/x/bang_01.ogg", "sfx", {}, "explosion: explosões de cartas e do herói."),
    ("sfx_explosion_2.ogg", "rd_bang", DL2 + "/bang25/x/bang_03.ogg", "sfx", {}, "explosion (variação)."),
    ("sfx_explosion_3.ogg", "rd_bang", DL2 + "/bang25/x/cannon_01.ogg", "sfx", {}, "explosion (variação)."),
    ("sfx_death_1.ogg", "rd_rpg", DL2 + "/rpg80/x/creature_die_01.ogg", "sfx", {}, "death: um monstro seu morre."),
    ("sfx_death_2.ogg", "rd_rpg", DL2 + "/rpg80/x/creature_hurt_01.ogg", "sfx", {}, "death (variação)."),
    ("sfx_death_3.ogg", "rd_rpg", DL2 + "/rpg80/x/creature_hurt_02.ogg", "sfx", {}, "death (variação)."),
    ("sfx_death_bone_1.ogg", "rd_bfh", DL2 + "/hit75/x/bfh1_wood_breaking_01.ogg", "sfx", {}, "death_bone: morre um morto-vivo (ossos)."),
    ("sfx_death_bone_2.ogg", "rd_bfh", DL2 + "/hit75/x/bfh1_wood_breaking_02.ogg", "sfx", {}, "death_bone (variação)."),
    ("sfx_death_stone.ogg", "rd_bfh", DL2 + "/hit75/x/bfh1_rock_breaking_02.ogg", "sfx", {}, "death_stone: estrutura ou constructo destruído; parte do chefe destruída."),
    ("sfx_hero_fall.ogg", "rd_bfh", DL2 + "/hit75/x/bfh1_metal_falling_01.ogg", "sfx", {"max": 1.2}, "hero_fall: um herói da party cai (armadura no chão)."),
    ("sfx_teleport.ogg", "ogrebane", DL2 + "/teleport/teleport.wav", "sfx", {}, "teleport: o chefe teleporta o herói na arena."),
    ("sfx_relic.ogg", "rd_rpg", DL2 + "/rpg80/x/item_gem_01.ogg", "sfx", {}, "relic: relíquia ganha."),
    ("sfx_heal.ogg", "jag_magic", DL2 + "/magic7/magical_6_0.ogg", "sfx", {}, "heal: herói ou ajudante se cura."),
    ("sfx_fear.ogg", "rd_rpg", DL2 + "/rpg80/x/creature_roar_01.ogg", "sfx", {"max": 1.2}, "fear: o herói (ou um monstro) espalha medo."),
    ("sfx_ability_tell.ogg", "k_rpg", DL + "/RPGsounds_Kenney/x/OGG/drawKnife1.ogg", "sfx", {}, "ability_tell: o herói prepara uma habilidade (aviso)."),
    ("sfx_ui_click_1.ogg", "k_iface", DL + "/kenney_interfaceSounds/x/Audio/scratch_001.ogg", "sfx", {}, "ui_click: cliques e passar o mouse na loja/livro (papel)."),
    ("sfx_ui_click_2.ogg", "k_iface", DL + "/kenney_interfaceSounds/x/Audio/scratch_002.ogg", "sfx", {}, "ui_click (variação)."),
    # ---- jingles (avisos grandes)
    ("jingle_contest_start.ogg", "k_jingle", J + "jingles_STEEL/jingles_STEEL13.ogg", "jingle", {}, "contest_start: o herói chega num local e a disputa começa (letreiro do objetivo)."),
    ("jingle_mark.ogg", "k_jingle", J + "jingles_STEEL/jingles_STEEL05.ogg", "jingle", {}, "contest_mark: marco da disputa alcançado."),
    ("jingle_won.ogg", "k_jingle", J + "jingles_STEEL/jingles_STEEL10.ogg", "jingle", {}, "contest_won: disputa vencida; também o id antigo \"victory\"."),
    ("jingle_partial.ogg", "k_jingle", J + "jingles_STEEL/jingles_STEEL04.ogg", "jingle", {}, "contest_partial: disputa vencida em parte."),
    ("jingle_lost.ogg", "k_jingle", J + "jingles_STEEL/jingles_STEEL11.ogg", "jingle", {}, "contest_lost: disputa perdida."),
    ("jingle_defeat.ogg", "k_jingle", J + "jingles_STEEL/jingles_STEEL14.ogg", "jingle", {}, "defeat: id antigo \"defeat\" (a derrota de verdade usa music_defeat)."),
    ("jingle_act_start.ogg", "k_jingle", J + "jingles_STEEL/jingles_STEEL00.ogg", "jingle", {}, "act_start: começa um ato (letreiro \"Ato N de M\")."),
    ("jingle_act_end.ogg", "k_jingle", J + "jingles_STEEL/jingles_STEEL15.ogg", "jingle", {}, "act_end: o herói fecha um ato (vem a oferta de carta e relíquia)."),
    ("jingle_arena.ogg", "k_jingle", J + "jingles_HIT/jingles_HIT11.ogg", "jingle", {}, "arena: o herói chega no covil."),
    ("jingle_level_hero.ogg", "k_jingle", J + "jingles_HIT/jingles_HIT01.ogg", "jingle", {}, "level_hero: o herói sobe de nível (ameaça)."),
    ("jingle_level_player.ogg", "k_jingle", J + "jingles_HIT/jingles_HIT13.ogg", "jingle", {}, "level_player: carta especial na oferta (escadinha de tons), compra na loja; curto (0,3 s)."),
    ("jingle_reward.ogg", "k_jingle", J + "jingles_STEEL/jingles_STEEL08.ogg", "jingle", {}, "reward: oferta de cartas aparece, livro da loja abre."),
]


def run(args):
    r = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        raise SystemExit("ffmpeg falhou: %s\n%s" % (" ".join(args), r.stderr[-2000:]))
    return r.stderr


def dur(p):
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", p],
                                capture_output=True, text=True).stdout.strip())


def loud(p):
    e = run(["ffmpeg", "-hide_banner", "-nostats", "-i", p, "-af", "loudnorm=print_format=json", "-f", "null", "-"])
    js = json.loads(e[e.rfind("{"):e.rfind("}") + 1])
    return float(js["input_i"]), float(js["input_tp"])


def vol(p):
    e = run(["ffmpeg", "-hide_banner", "-nostats", "-i", p, "-af", "volumedetect", "-f", "null", "-"])
    mean = float(re.search(r"mean_volume: (-?[\d.]+)", e).group(1))
    peak = float(re.search(r"max_volume: (-?[\d.]+)", e).group(1))
    return mean, peak


TRIM_END = "areverse,silenceremove=start_periods=1:start_threshold=-55dB:start_silence=0.02,areverse"
TRIM_START = "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.004"

manifest = []
old = {}
if ONLY and os.path.isfile(os.path.join(WORK, "manifest.json")):
    old = {m["file"]: m for m in json.load(open(os.path.join(WORK, "manifest.json"), encoding="utf-8"))}
for out, sk, src, kind, par, where in ITEMS:
    if ONLY and out not in ONLY and out in old:
        manifest.append(old[out])
        continue
    if not os.path.isfile(src):
        raise SystemExit("origem não encontrada: " + src)
    tmp = os.path.join(WORK, out.replace(".ogg", ".wav"))
    dst = os.path.join(OUT, out)
    if kind in ("music_loop", "amb_loop"):
        run(["ffmpeg", "-y", "-v", "error", "-i", src, "-c:a", "pcm_f32le", tmp])
    elif kind == "music_once":
        run(["ffmpeg", "-y", "-v", "error", "-i", src, "-af", TRIM_END, "-c:a", "pcm_f32le", tmp])
    elif kind in ("music_xfade", "amb_xfade"):
        # Loop por emenda cruzada: o fim (X s) entra em potência constante sobre o começo.
        base = tmp.replace(".wav", "_src.wav")
        if kind == "music_xfade":
            run(["ffmpeg", "-y", "-v", "error", "-i", src, "-af", TRIM_END, "-c:a", "pcm_f32le", base])
            x = float(par["x"]); s0 = 0.0; L = dur(base) - x
        else:
            run(["ffmpeg", "-y", "-v", "error", "-i", src, "-c:a", "pcm_f32le", base])
            x = float(par["x"]); s0 = float(par["s0"]); L = float(par["len"])
        fc = ("[0:a]atrim=start={s0}:end={e},asetpts=PTS-STARTPTS,asplit=3[a][b][c];"
              "[a]atrim=0:{x},asetpts=PTS-STARTPTS,afade=t=in:st=0:d={x}:curve=qsin[h];"
              "[b]atrim={L}:{Lx},asetpts=PTS-STARTPTS,afade=t=out:st=0:d={x}:curve=qsin[t];"
              "[h][t]amix=inputs=2:normalize=0:duration=longest[hx];"
              "[c]atrim={x}:{L},asetpts=PTS-STARTPTS[body];"
              "[hx][body]concat=n=2:v=0:a=1[o]").format(s0=s0, e=s0 + L + x, x=x, L=L, Lx=L + x)
        run(["ffmpeg", "-y", "-v", "error", "-i", base, "-filter_complex", fc, "-map", "[o]", "-c:a", "pcm_f32le", tmp])
        os.remove(base)
    else:  # sfx, jingle
        af = TRIM_START + "," + TRIM_END
        if "max" in par:
            m = float(par["max"])
            af += ",atrim=0:{m},afade=t=out:st={s}:d=0.25".format(m=m, s=max(0.0, m - 0.25))
        run(["ffmpeg", "-y", "-v", "error", "-i", src, "-af", af, "-ac", "1", "-c:a", "pcm_f32le", tmp])
    if kind.startswith("music") or kind.startswith("amb"):
        target = -16.0 if kind.startswith("music") else -20.0
        i, tp = loud(tmp)
        g = min(target - i, -1.0 - tp)
        meas = {"lufs_in": i, "tp_in": tp}
        q = "5" if kind.startswith("music") else "4"
    else:
        mean, peak = vol(tmp)
        g = min(-20.0 - mean, -1.0 - peak)
        meas = {"mean_in": mean, "peak_in": peak}
        q = "4"
    run(["ffmpeg", "-y", "-v", "error", "-i", tmp, "-af", "volume=%.2fdB" % g, "-c:a", "libvorbis", "-q:a", q, dst])
    os.remove(tmp)
    a, t, u = SRC[sk]
    d = dur(dst)
    manifest.append({"file": out, "kind": kind, "where": where, "author": a, "title": t, "url": u,
                     "license": "CC0 1.0", "source_file": os.path.basename(src), "gain_db": round(g, 2),
                     "duration": round(d, 2), **{k: round(v, 2) for k, v in meas.items()}})
    print("%-28s %-12s %6.2fs ganho %+6.2f dB  <- %s" % (out, kind, d, g, os.path.basename(src)))

with open(os.path.join(WORK, "manifest.json"), "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=1)
print("ok:", len(manifest), "arquivos")
