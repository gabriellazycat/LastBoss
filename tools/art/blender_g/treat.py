"""Atlas de pintura de cada modelo (numpy puro, roda dentro do Blender).
raster(): preenche o atlas com a cor, a posição e a normal de cada ponto da malha (assim a pincelada é do espaço do
modelo e atravessa as costuras da UV). treat(): pinta a pincelada de um dos 5 tratamentos em cima da cor.
Regras do designer (13/11): pincel largo, nada de detalhe fino, nada escuro salpicado: a pincelada clareia mais que escurece."""
import json, os
import numpy as np

S = 512
HERE = os.path.dirname(os.path.abspath(__file__))
try:
    PALS = json.load(open(os.path.join(HERE, "palettes.json")))
except Exception:
    PALS = {}


# ------------------------------------------------------------------ cor: graduação pela paleta da carta

def lum(c):
    return 0.3 * c[..., 0] + 0.59 * c[..., 1] + 0.11 * c[..., 2]


def pal_key(i):
    """Paleta da carta do modelo i (None = cenário)."""
    if i in PALS:
        return i
    if i.startswith("boss_"):
        v = "villain_" + i.split("_")[1]
        return v if v in PALS else "scenery"
    return "scenery"


def make_grade(key, lift=0.14, pull=0.3, sat=1.22, gain=1.0):
    """Devolve grade(c): sobe os pretos (as cartas não têm preto puro), puxa o valor para a paleta da carta, satura."""
    pal = PALS.get(key)

    def grade(c):
        c = np.array(c, dtype=np.float64)
        L = float(lum(c))
        if pal:
            xs = [p[0] for p in pal]
            tgt = np.array([np.interp(L, xs, [p[1][k] for p in pal]) for k in range(3)])
            c = c * (1 - pull) + tgt * pull
        # pretos levantados: o valor mínimo sobe para `lift`
        L2 = float(lum(c))
        c = c + (lift * (1.0 - L2)) * (0.6 + 0.4 * (1.0 - L2))
        L3 = float(lum(c))
        c = L3 + (c - L3) * sat
        c = c * gain  # a luz do jogo (sol 2,1 + guache) estoura tudo o que passa de ~0,6
        return tuple(float(x) for x in np.clip(c, 0.0, 1.0))
    return grade


# ------------------------------------------------------------------ rasterização do atlas

def raster(d, size=S):
    uv, pos, nrm, col, idx = d["uv"], d["pos"], d["nrm"], d["col"], d["idx"]
    C = np.zeros((size, size, 3)); P = np.zeros((size, size, 3)); N = np.zeros((size, size, 3))
    A = np.ones((size, size)); M = np.zeros((size, size), bool)
    px = uv * size
    for tri in idx:
        t = px[tri]
        x0 = max(int(np.floor(t[:, 0].min())) - 1, 0); x1 = min(int(np.ceil(t[:, 0].max())) + 1, size - 1)
        y0 = max(int(np.floor(t[:, 1].min())) - 1, 0); y1 = min(int(np.ceil(t[:, 1].max())) + 1, size - 1)
        if x1 < x0 or y1 < y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        a, b, c = t
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-9:
            continue
        w0 = ((b[1] - c[1]) * (gx - c[0]) + (c[0] - b[0]) * (gy - c[1])) / den
        w1 = ((c[1] - a[1]) * (gx - c[0]) + (a[0] - c[0]) * (gy - c[1])) / den
        w2 = 1 - w0 - w1
        m = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        if not m.any():
            continue
        ys, xs = np.nonzero(m)
        W = np.stack([w0[m], w1[m], w2[m]], axis=1)
        yy, xx = ys + y0, xs + x0
        C[yy, xx] = W @ col[tri][:, :3]
        P[yy, xx] = W @ pos[tri]
        N[yy, xx] = W @ nrm[tri]
        M[yy, xx] = True
    for _ in range(6):  # alarga 6 px: a mipmap e o filtro não puxam preto da borda
        for arr in (C, P, N):
            pass
        grow = ~M
        acc = np.zeros_like(C); accP = np.zeros_like(P); accN = np.zeros_like(N); cnt = np.zeros((size, size))
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            sh = np.roll(np.roll(M, dy, 0), dx, 1)
            acc += np.roll(np.roll(C * M[..., None], dy, 0), dx, 1)
            accP += np.roll(np.roll(P * M[..., None], dy, 0), dx, 1)
            accN += np.roll(np.roll(N * M[..., None], dy, 0), dx, 1)
            cnt += sh
        f = grow & (cnt > 0)
        C[f] = acc[f] / cnt[f][:, None]; P[f] = accP[f] / cnt[f][:, None]; N[f] = accN[f] / cnt[f][:, None]
        M = M | f
    nn = np.linalg.norm(N, axis=2, keepdims=True)
    N = N / np.maximum(nn, 1e-6)
    return C, P, N, M


# ------------------------------------------------------------------ ruído 3D vetorizado

def _h(i, seed):
    x = (i[..., 0] * 374761393 + i[..., 1] * 668265263 + i[..., 2] * 2147483647 + seed * 1274126177).astype(np.int64)
    x = (x ^ (x >> 13)) * 1274126177
    x = x ^ (x >> 16)
    return (x & 0xFFFFFF).astype(np.float64) / float(0x1000000)


def vnoise(p, seed=0):
    i = np.floor(p).astype(np.int64)
    f = p - i
    f = f * f * (3 - 2 * f)
    out = 0.0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[..., 0] if dx else 1 - f[..., 0]) * (f[..., 1] if dy else 1 - f[..., 1]) * (f[..., 2] if dz else 1 - f[..., 2])
                out = out + w * _h(i + np.array([dx, dy, dz]), seed)
    return out


def fbm(p, seed=0, oct=3):
    t, a, n = 0.0, 0.5, 0.0
    for o in range(oct):
        t = t + a * vnoise(p * (2 ** o), seed + o * 11)
        n += a
        a *= 0.5
    return t / n


def cells(p, seed=0):
    """Distância ao ponto mais próximo e um valor 0..1 por célula (dabs de pincel chato, cada um com a sua cor)."""
    ip = np.floor(p).astype(np.int64)
    best = np.full(p.shape[:2], 9.0)
    val = np.zeros(p.shape[:2])
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                c = ip + np.array([dx, dy, dz])
                f = c + np.stack([_h(c, seed + 1), _h(c, seed + 2), _h(c, seed + 3)], axis=-1)
                d = np.linalg.norm(p - f, axis=-1)
                m = d < best
                best = np.where(m, d, best)
                val = np.where(m, _h(c, seed + 9), val)
    return best, val


def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


# ------------------------------------------------------------------ os 5 tratamentos

def treat(kind, C, P, N, H, cool):
    """C: cor graduada (sRGB, H x W x 3). P: posição (coordenadas do jogo). H: altura do modelo. cool: cor da sombra fria."""
    Pn = P / max(H, 1e-6)
    out = C.copy()
    L = lum(out)[..., None]
    if kind == "dabs":
        # Dabs de pincel chato: células de ~0,17 H, cada uma uma cor um pouco diferente; borda dura; mancha grande por cima.
        dist, val = cells(Pn * 5.8, 3)
        v = (val - 0.5) * 2
        amp = np.where(v > 0, 0.20, 0.12)
        out = out * (1 + (v * amp)[..., None]) + (v > 0)[..., None] * (v[..., None] * np.array([0.035, 0.012, -0.03]))
        d2, v2 = cells(Pn * 2.1, 17)
        v2 = (v2 - 0.5) * 2
        out = out * (1 + (v2 * np.where(v2 > 0, 0.14, 0.06))[..., None])
        under = ss(0.1, -0.7, N[..., 1])[..., None]          # barriga e baixos: uma mancha grande de sombra fria
        out = out * (1 - under * 0.28) + np.array(cool) * under * 0.28
        edge = ss(0.18, 0.0, dist - 0.0)[..., None] * 0.0
    elif kind == "wash":
        # Aguado: lavagem larga e suave, cor mais clara e menos saturada, borda molhada onde a lavagem muda.
        f1 = fbm(Pn * 2.6, 5)
        out = out * (0.86 + 0.34 * f1[..., None])
        out = L + (out - L) * 0.86
        out = out * 0.9 + np.array([0.95, 0.92, 0.85]) * 0.1
        pool = np.exp(-((f1 - 0.52) / 0.03) ** 2)[..., None]
        out = out * (1 - 0.1 * pool)
        under = ss(0.0, -0.8, N[..., 1])[..., None]
        out = out * (1 - under * 0.2) + np.array(cool) * under * 0.2
        out = out + (vnoise(Pn * 110, 4)[..., None] - 0.5) * 0.02
    elif kind == "dry":
        # Pincel seco: veios compridos no sentido vertical, quebrados; só clareia.
        q = np.stack([Pn[..., 0] * 9.0, Pn[..., 1] * 2.0, Pn[..., 2] * 9.0], axis=-1)
        n1 = fbm(q, 8, 3)
        streak = ss(0.52, 0.72, n1)[..., None]
        out = out * (1 + streak * 0.24)
        dist, val = cells(Pn * 3.2, 5)
        out = out * (1 + ((val - 0.5) * np.where(val > 0.5, 0.2, 0.1))[..., None])
        under = ss(0.0, -0.8, N[..., 1])[..., None]
        out = out * (1 - under * 0.24) + np.array(cool) * under * 0.24
    elif kind == "flat":
        # Cor chapada: poucas cores, sem textura; o contorno de tinta vem do shader.
        out = np.round(out * 5.0) / 5.0
        dist, val = cells(Pn * 2.4, 21)
        out = out * (1 + ((val - 0.5) * 0.08)[..., None])
        under = ss(0.0, -0.8, N[..., 1])[..., None]
        out = out * (1 - under * 0.2) + np.array(cool) * under * 0.2
    return np.clip(out, 0.0, 1.0)


def save_png(img, path):
    import bpy
    h, w, _ = img.shape
    im = bpy.data.images.new("atlas", w, h, alpha=False)
    im.colorspace_settings.name = 'Non-Color'
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = img
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = path
    im.file_format = 'PNG'
    im.save()
    bpy.data.images.remove(im)
