"""Gera assets/textures/paint/lut_escuro.png: LUT 3D (33^3, fatias de azul lado a lado) para o B · escuros
(docs/MUNDO_COMO_CARTAS.md). Estica só o valor (L do Lab) como a simulação de 15/11, sombra puxada para lilás,
croma intacto. Uso: py -I tools/art/make_lut_escuro.py"""
import numpy as np
from PIL import Image
N = 33
M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
WP = np.array([0.9505, 1.0, 1.089])
def to_lab(s):
    a = np.where(s <= 0.04045, s / 12.92, ((s + 0.055) / 1.055) ** 2.4)
    xyz = a @ M.T / WP
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)
def from_lab(lab):
    fy = (lab[..., 0] + 16) / 116; f = np.stack([fy + lab[..., 1] / 500, fy, fy - lab[..., 2] / 200], -1)
    xyz = np.where(f ** 3 > 0.008856, f ** 3, (f - 16 / 116) / 7.787) * WP
    lin = np.clip(xyz @ np.linalg.inv(M).T, 0, 1)
    return np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)
r, g, b = np.meshgrid(np.linspace(0, 1, N), np.linspace(0, 1, N), np.linspace(0, 1, N), indexing="xy")
s = np.stack([r, g, b], -1)            # [g, r, b] por causa do indexing xy: linha = verde, coluna = vermelho
lab = to_lab(s)
L = lab[..., 0]
# 0..50 -> 0..30 · 50..80 -> 30..82 · 80..100 -> 82..100 (a névoa do jogo deixa o mundo entre ~50 e ~80)
Ln = np.interp(L, [0, 50, 80, 100], [0, 30, 82, 100])
w = np.clip((52 - Ln) / 22, 0, 1)
lab2 = np.stack([Ln, lab[..., 1] + 4 * w, lab[..., 2] - 7 * w], -1)
out = from_lab(lab2)
img = np.zeros((N, N * N, 3))
for k in range(N):                      # fatia k = azul k
    img[:, k * N:(k + 1) * N] = out[:, :, k]
Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)).save("assets/textures/paint/lut_escuro.png")
print("ok", img.shape)
