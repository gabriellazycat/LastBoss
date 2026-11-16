"""Gera assets/textures/paint/papel.png, o grão de papel do C (docs/MUNDO_COMO_CARTAS.md).

Dente de papel de aquarela (cold press): ruído branco filtrado por FFT numa faixa de frequências (manchas macias de
~8-20 px na folha de 1024), sem costura nenhuma porque a FFT é circular. Puxado para "calombos claros com vãos
estreitos", como o papel das cartas (o shader clareia mais do que escurece).
A versão de 15/11 era o passa-alta de 1 px do céu das cartas: lia como ruído digital.
Uso: py -I tools/art/make_papel.py"""
import numpy as np
from PIL import Image

N = 1024
rng = np.random.default_rng(7)
fy = np.fft.fftfreq(N)[:, None]
fx = np.fft.fftfreq(N)[None, :]
f = np.hypot(fx * 1.0, fy * 1.25)          # leve direção, como o papel das cartas (fibras na diagonal ficam do shader)
lo, hi = 1 / 22.0, 1 / 7.0                 # manchas entre ~7 e ~22 px
band = np.exp(-((np.log(f + 1e-9) - np.log(np.sqrt(lo * hi))) ** 2) / (2 * 0.38 ** 2))
band[0, 0] = 0.0


def layer(seed_scale=1.0):
    w = rng.standard_normal((N, N))
    return np.real(np.fft.ifft2(np.fft.fft2(w) * band))


t = layer() + 0.35 * np.real(np.fft.ifft2(np.fft.fft2(rng.standard_normal((N, N))) * np.roll(band, 0) ** 0.5 * (f > hi)))
t = (t - t.mean()) / t.std()
t = np.sign(t) * np.abs(t) ** 0.85        # calombos um pouco mais cheios
t = np.where(t > 0, t, t * 0.7)           # vãos mais estreitos que os calombos
t = (t - t.mean()) / t.std()
Image.fromarray(np.clip(128 + t * 30, 0, 255).astype(np.uint8)).save("assets/textures/paint/papel.png")
print("ok", N)
