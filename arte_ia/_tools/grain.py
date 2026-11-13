"""Non-AI paper/gouache grain pass. Sharp: adds texture, never blurs the image.

python grain.py [--strength=0.9] <in.png> [...]  ->  writes <in>__grain.png (or __grain90.png) next to each
Layers: paper relief shading, dry-brush skips (paper cream on relief peaks),
soft large coverage blotches, fine pigment grain.
"""
import sys, os, zlib
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, zoom

PAPER = np.array([0.93, 0.89, 0.80])   # cream


def noise(h, w, scale, rng):
    """Smooth value noise at a given feature scale (in px)."""
    sh, sw = max(2, int(h / scale) + 2), max(2, int(w / scale) + 2)
    n = zoom(rng.standard_normal((sh, sw)), (h / (sh - 1), w / (sw - 1)), order=3)[:h, :w]
    return (n - n.mean()) / (n.std() + 1e-6)


def grain(img, seed=0, strength=1.0):
    rng = np.random.default_rng(seed)
    a = np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0
    h, w, _ = a.shape
    k = w / 1024.0                                    # keep the texture size stable across resolutions

    # cold-press paper height field: mid tooth + fine tooth
    hf = 0.65 * noise(h, w, 6 * k, rng) + 0.35 * noise(h, w, 2.2 * k, rng)
    gy, gx = np.gradient(hf)
    relief = -(gx * 0.7 + gy * 0.7)                   # light from the top-left
    relief = relief / (np.abs(relief).std() + 1e-6)

    # 1) relief shading
    out = a * (1.0 + 0.045 * relief[..., None])

    # 2) dry-brush skips: paper shows on the highest peaks, more along horizontal-ish streaks
    streak = gaussian_filter(rng.standard_normal((h, w)), (1.2 * k, 14 * k))
    streak = streak / (streak.std() + 1e-6)
    lum = a.mean(axis=2)
    skip = (hf + 0.8 * streak) - 2.3
    skip = np.clip(skip * 1.6, 0, 1) * np.clip(1.15 - lum, 0.2, 1.0)   # dark paint skips are the visible ones
    out = out * (1 - skip[..., None] * 0.85) + PAPER * (skip[..., None] * 0.85)

    # 3) soft large coverage blotches: paint thinner/thicker in big patches
    blot = noise(h, w, 140 * k, rng) * 0.6 + noise(h, w, 45 * k, rng) * 0.4
    thin = np.clip(blot, -1.5, 1.5) * 0.06
    out = out + (PAPER - out) * np.clip(thin, 0, None)[..., None] - out * np.clip(-thin, 0, None)[..., None] * 0.6

    # 4) fine pigment grain (per channel, slight color variance)
    g = rng.standard_normal((h, w, 1)) * 0.022 + rng.standard_normal((h, w, 3)) * 0.008
    out = out + g

    out = a + (out - a) * strength                   # strength 1.0 = the original pass
    return Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8))


if __name__ == "__main__":
    args, strength = sys.argv[1:], 1.0
    if args and args[0].startswith("--strength="):
        strength = float(args.pop(0).split("=")[1])
    for p in args:
        if "__grain" in p:
            continue
        tag = "" if strength == 1.0 else str(int(round(strength * 100)))
        o = os.path.splitext(p)[0] + "__grain" + tag + ".png"
        grain(Image.open(p), seed=zlib.crc32(os.path.basename(p).encode()), strength=strength).save(o)
        print(o)
