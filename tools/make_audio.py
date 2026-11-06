"""Sintetiza os efeitos sonoros e a trilha provisória em assets/audio/*.wav (numpy, determinístico).

Uso: python -I tools/make_audio.py
"""
import os
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
SR = 22050
rng = np.random.default_rng(7)


def t_(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, r=None, shape=4.0):
    x = np.linspace(0, 1, n)
    e = np.exp(-shape * x) if r is None else np.clip(1 - x / r, 0, 1)
    att = int(SR * a)
    if att > 0:
        e[:att] *= np.linspace(0, 1, att)
    return e


def lowpass(x, k):
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += k * (x[i] - acc)
        y[i] = acc
    return y


def lp_fast(x, k):
    # Filtro de um polo vetorizado aproximado (média móvel exponencial por blocos).
    n = max(1, int(1 / k))
    return np.convolve(x, np.ones(n) / n, mode="same")


def tone(f, d, kind="sine", decay=4.0, harm=None):
    t = t_(d)
    if kind == "sine":
        s = np.sin(2 * np.pi * f * t)
    elif kind == "tri":
        s = 2 / np.pi * np.arcsin(np.sin(2 * np.pi * f * t))
    elif kind == "saw":
        s = 2 * (t * f - np.floor(0.5 + t * f))
    elif kind == "square":
        s = np.sign(np.sin(2 * np.pi * f * t))
    if harm:
        for h, a in harm:
            s += a * np.sin(2 * np.pi * f * h * t)
    return s * env(len(t), shape=decay)


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def place(buf, x, at):
    i = int(at * SR)
    j = min(len(buf), i + len(x))
    buf[i:j] += x[: j - i]


def save(name, x, vol=0.8):
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) or 1.0
    x = np.clip(x / peak * vol, -1, 1)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def note(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def sfx():
    # Carta jogada: sopro com varredura.
    d = 0.3
    n = noise(d)
    sweep = np.sin(2 * np.pi * np.cumsum(np.linspace(300, 1500, len(n))) / SR)
    save("card_play", lp_fast(n, 0.2) * env(len(n), shape=6) * 0.7 + sweep * env(len(n), shape=10) * 0.3, 0.55)
    # Golpe do herói / acerto.
    save("hit", mix(lp_fast(noise(0.09), 0.3) * env(int(SR * 0.09), shape=18), tone(110, 0.12, decay=20) * 0.9), 0.6)
    # Dano no herói: metal.
    save("hero_hit", mix(*[tone(f, 0.35, decay=9) * a for f, a in [(523, 1), (1187, 0.6), (1773, 0.4), (2610, 0.25)]], lp_fast(noise(0.05), 0.5) * 0.6), 0.5)
    # Escudo quebra: vidro.
    save("shield_break", mix(*[tone(f, 0.5, decay=6) * 0.4 for f in (1850, 2470, 3120, 3950)], noise(0.2) * env(int(SR * 0.2), shape=12) * 0.5), 0.6)
    # Explosão.
    d = 0.9
    n = lp_fast(noise(d), 0.03) * env(int(SR * d), shape=4)
    boom = np.sin(2 * np.pi * np.cumsum(np.linspace(120, 35, int(SR * d))) / SR) * env(int(SR * d), shape=5)
    save("explosion", n * 1.5 + boom, 0.9)
    # Morte de monstro: guincho que cai.
    d = 0.18
    f = np.linspace(1400, 500, int(SR * d))
    save("death", np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(f), shape=8) * 0.6 + lp_fast(noise(d), 0.3) * env(len(f), shape=20) * 0.3, 0.4)
    # Feitiço: brilho mágico.
    out = np.zeros(int(SR * 0.7))
    for i, m in enumerate([74, 77, 81, 86]):
        place(out, tone(note(m), 0.5, "sine", decay=5, harm=[(2, 0.3)]) * 0.5, i * 0.05)
    save("spell", out, 0.55)
    # Herói sobe de nível: fanfarra maior.
    out = np.zeros(int(SR * 1.1))
    for i, m in enumerate([67, 71, 74, 79]):
        place(out, tone(note(m), 0.6, "tri", decay=3) * 0.6, i * 0.09)
    save("level_hero", out, 0.6)
    # Jogador sobe de nível: sinos sombrios.
    out = np.zeros(int(SR * 1.2))
    for i, m in enumerate([62, 65, 69, 74, 77]):
        place(out, tone(note(m), 0.8, "sine", decay=3, harm=[(2.76, 0.4), (5.4, 0.2)]) * 0.5, i * 0.08)
    save("level_player", out, 0.65)
    # Santuário / contrato cumprido.
    out = np.zeros(int(SR * 1.0))
    for i, m in enumerate([72, 76, 79, 84]):
        place(out, tone(note(m), 0.6, "sine", decay=4, harm=[(3, 0.2)]) * 0.5, i * 0.07)
    save("reward", out, 0.6)
    # Contrato novo: trompa.
    d = 0.6
    s = tone(note(50), d, "saw", decay=1.5) + tone(note(57), d, "saw", decay=1.5) * 0.7
    save("contract", lp_fast(s, 0.08) * env(int(SR * d), a=0.06, shape=2), 0.5)
    # Teleporte.
    d = 0.6
    f = np.linspace(200, 1800, int(SR * d))
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.linspace(0, np.pi, len(f)))
    save("teleport", s * 0.6 + lp_fast(noise(d), 0.1) * np.sin(np.linspace(0, np.pi, len(f))) * 0.4, 0.55)
    # Parte do chefe destruída.
    d = 1.4
    n = lp_fast(noise(d), 0.02) * env(int(SR * d), shape=3)
    boom = np.sin(2 * np.pi * np.cumsum(np.linspace(90, 25, int(SR * d))) / SR) * env(int(SR * d), shape=3)
    save("part_destroyed", n * 2 + boom * 1.2 + tone(note(38), d, "saw", decay=3) * 0.3, 0.95)
    # Clique de interface.
    save("ui_click", mix(tone(1200, 0.05, "sine", decay=30), tone(1800, 0.04, decay=40) * 0.5), 0.35)
    # Vitória e derrota.
    out = np.zeros(int(SR * 3.0))
    for i, ch in enumerate([[62, 66, 69], [64, 67, 71], [66, 69, 74], [62, 66, 69, 74]]):
        for m in ch:
            place(out, tone(note(m), 1.2 if i < 3 else 2.0, "tri", decay=2) * 0.4, i * 0.35)
    save("victory", out, 0.7)
    out = np.zeros(int(SR * 3.0))
    for i, ch in enumerate([[62, 65, 69], [60, 63, 67], [58, 62, 65], [50, 57, 62]]):
        for m in ch:
            place(out, tone(note(m), 1.2 if i < 3 else 2.2, "saw", decay=2) * 0.25, i * 0.45)
    save("defeat", lp_fast(out, 0.15), 0.7)


def kick(d=0.25):
    f = np.linspace(110, 40, int(SR * d))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(f), shape=9)


def snare(d=0.18):
    return lp_fast(noise(d), 0.5) * env(int(SR * d), shape=14) * 0.6 + tone(190, d, decay=20) * 0.3


def hat(d=0.05):
    n = noise(d)
    return (n - lp_fast(n, 0.3)) * env(len(n), shape=30) * 0.35


def pluck(f, d):
    return tone(f, d, "tri", decay=7, harm=[(2, 0.25), (3, 0.1)])


def pad(fs, d):
    t = t_(d)
    s = np.zeros(len(t))
    for f in fs:
        for det in (-0.6, 0.6):
            ff = f + det
            s += 2 * (t * ff - np.floor(0.5 + t * ff))
    s = lp_fast(s, 0.05)
    e = np.minimum(1, np.minimum(t / 0.3, (d - t) / 0.4))
    return s * np.clip(e, 0, 1) * 0.12


def music(name, bpm, bars, chords, bass_pat, mel, intense):
    beat = 60.0 / bpm
    total = bars * 4 * beat
    base = np.zeros(int(SR * total) + SR)
    layer = np.zeros_like(base)
    for b in range(bars):
        ch = chords[b % len(chords)]
        t0 = b * 4 * beat
        place(base, pad([note(m) for m in ch], 4 * beat), t0)
        for i, step in enumerate(bass_pat):
            if step is not None:
                place(base, pluck(note(ch[0] - 12 + step), beat * 0.45) * 0.55, t0 + i * beat * 0.5)
        for i in range(8):
            place(layer, hat(), t0 + i * beat * 0.5)
        for i in (0, 2):
            place(layer, kick() * 0.8, t0 + i * beat)
        for i in (1, 3):
            place(layer, snare(), t0 + i * beat)
        if intense:
            for i in (1.5, 3.5):
                place(layer, kick() * 0.5, t0 + i * beat)
        m = mel[b % len(mel)]
        for i, n in enumerate(m):
            if n is not None:
                place(layer, tone(note(n), beat * 0.4, "square", decay=5) * 0.12, t0 + i * beat * 0.5)
    n = int(SR * total)
    base, layer = base[:n], layer[:n]
    save(name + "_base", base, 0.55)
    save(name + "_layer", layer, 0.5)


def main():
    sfx()
    # D menor, vilão de desenho animado: i – VI – iv – V.
    chords = [[62, 65, 69], [58, 62, 65], [55, 58, 62], [57, 61, 64]]
    bass = [0, None, 7, None, 0, 3, 7, 5]
    mel = [[74, None, 77, 76, 74, None, 69, None], [70, None, 74, 72, 70, None, 65, None],
           [67, 70, 74, None, 72, 70, 67, None], [69, None, 73, None, 76, 73, 69, None]]
    music("music_road", 104, 16, chords, bass, mel, False)
    music("music_arena", 138, 16, chords, [0, 0, 7, 0, 3, 0, 7, 5], mel, True)
    print("áudio gerado em", OUT)


if __name__ == "__main__":
    main()
