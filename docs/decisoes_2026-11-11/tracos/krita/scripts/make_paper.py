# cold-press paper texture -> raw BGRA bytes for Krita setPixelData (and a PNG to look at)
import sys, numpy as np
from PIL import Image, ImageFilter
W, H = 1112, 1068
rng = np.random.default_rng(7)
def blur_noise(scale, sigma):
    n = rng.standard_normal((H // scale + 2, W // scale + 2)).astype(np.float32)
    im = Image.fromarray(((n - n.min()) / (np.ptp(n) + 1e-6) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
    im = im.filter(ImageFilter.GaussianBlur(sigma))
    a = np.asarray(im).astype(np.float32) / 255.0
    return (a - a.mean()) / (a.std() + 1e-6)
tooth = blur_noise(2, 1.2) * 0.6 + blur_noise(5, 2.0) * 0.4
cloud = blur_noise(60, 30)
fib = rng.standard_normal((H, W)).astype(np.float32)
fib = np.asarray(Image.fromarray(((fib - fib.min()) / np.ptp(fib) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))).astype(np.float32) / 255 - 0.5
base = np.array([243, 234, 216], np.float32)  # warm cream
v = 1.0 + tooth[..., None] * 0.022 + cloud[..., None] * 0.018 + fib[..., None] * 0.05
rgb = np.clip(base * v, 0, 255).astype(np.uint8)
Image.fromarray(rgb).save(sys.argv[1] + ".png")
bgra = np.dstack([rgb[..., 2], rgb[..., 1], rgb[..., 0], np.full((H, W), 255, np.uint8)])
open(sys.argv[1] + ".bgra", "wb").write(bgra.tobytes())
