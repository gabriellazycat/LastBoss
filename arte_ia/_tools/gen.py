"""Drive a local ComfyUI (127.0.0.1:8188) over its HTTP API to make card art.

Usage examples:
  python gen.py t2i  --card rat_king --style gouache --seeds 8919 101 202
  python gen.py i2i  --card rat_king --style gouache --seeds 8919 --denoise 0.5 0.6
Outputs go to arte_ia/<card>/<model>__<style>__<mode>__s<seed>.png and index.json.
"""
import argparse, json, os, sys, time, uuid, urllib.request, urllib.parse
import numpy as np

HOST = "http://127.0.0.1:8188"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))   # arte_ia/
GAME = os.path.dirname(ROOT)

MODELS = {
    "qwen21t": dict(kind="qwen21", unet="qwen-image-2.1-turbo-Q6_K.gguf",
                    clip="qwen3vl_8b_w4a8.safetensors", clip_type="qwen_image",
                    vae="qwen_image_2.1_vae_bf16.safetensors",
                    sigmas=[1.0, 0.978453, 0.95418, 0.926626, 0.89508, 0.845148, 0.704534, 0.414568, 0.0]),
    # Krea 2 Anime-tuned Turbo (ricecake, gated): 8 steps, euler/simple, cfg 1, shift 1.15 (ComfyUI's Krea 2 default).
    "krea2anime": dict(kind="krea2", unet="krea2_anime_tuned_turbo_int8_convrot.safetensors",
                       clip="qwen3vl_4b_int8_convrot.safetensors", clip_type="krea2",
                       vae="qwen_image_vae.safetensors", steps=8),
}

# Fixed texture block: keep identical across the deck.
TEXTURE = ("Thick chalky opaque gouache laid on with a dry bristle brush, streaky visible brushstrokes and "
           "uneven patchy coverage where the paper grain shows through, soft fuzzy edges where colors meet, "
           "edges that dissolve softly into neighboring colors, forms built purely from color and value, "
           "slightly blurry low-resolution scan, muted dusty colors, quiet somber mood, naturalistic proportions.")
MEDIUM = "A textured gouache painting on rough cold-press paper, scanned from an old sketchbook: "
# Shorter block from the designer's favourite (12 Nov): fewer adjectives, paper showing everywhere.
TEXTURE2 = ("Thick chalky opaque gouache with streaky dry-brush strokes and patchy coverage, paper grain showing "
            "through everywhere, soft fuzzy edges where shapes melt together, muted dusty colors, "
            "slightly blurry low-resolution scan.")
# Art-guide candidates (12 Nov): same subject text, only medium + texture change.
MEDIUM_POSTER = "A flat gouache poster painting on rough cold-press paper, scanned from an old sketchbook: "
TEXTURE_POSTER = ("Bold flat shapes of opaque gouache in a small palette of five colors, crisp edges between large "
                  "color areas, simple two-tone shading with light from the upper left, dry-brush texture inside each "
                  "shape, paper grain showing through, muted dusty colors, slightly blurry low-resolution scan.")
MEDIUM_INK = "A brush-ink and gouache illustration on rough cold-press paper, scanned from an old sketchbook: "
TEXTURE_INK = ("One confident black brush-ink outline around each figure, swelling thick and thin, with a few interior "
               "lines for eyes, mouth and folds, loose gouache washes laid inside and slightly off the lines, pigment "
               "pooling at the wash edges, bare paper left on the lit side, light from the upper left, muted dusty "
               "colors, slightly blurry low-resolution scan.")
# DECK = the chosen deck style (12 Nov): B, a little darker. Never edit per card; see .claude/skills/cartas-ia.
MEDIUM_DECK = MEDIUM_POSTER
TEXTURE_DECK = TEXTURE_POSTER        # designer chose the original B block (12 Nov); the darker variant was rejected
STYLES = {"gouache": (MEDIUM, TEXTURE), "gouache2": (MEDIUM, TEXTURE2), "deck": (MEDIUM_DECK, TEXTURE_DECK),
          "poster": (MEDIUM_POSTER, TEXTURE_POSTER), "inkwash": (MEDIUM_INK, TEXTURE_INK)}


# Fixed background tones for the deck style (pick the one that contrasts with the creature's natural color).
BACKGROUNDS = {"lilac": "dusty lilac", "teal": "pale dusty teal", "ochre": "dusty ochre", "sand": "warm sand",
               "slate": "grey-blue slate", "rose": "faded old rose"}
# Fixed tone sentence (12 Nov): grounded, never cartoony; whole, coherent anatomy and objects.
TONE = ("Grounded serious fantasy book illustration with believable anatomy and natural proportions, "
        "every limb, hand and object whole, solid and clearly readable.")
COMPOSITION = "A plain flat {bg} sky behind."   # only the background tone is fixed; the composition sentence was rejected


def load_subjects():
    """subjects.json plus one file per batch in subjects/ (each writer owns its own file, so batches can be written in parallel)."""
    d = os.path.join(ROOT, "_tools")
    out = json.load(open(os.path.join(d, "subjects.json"), encoding="utf-8"))
    sd = os.path.join(d, "subjects")
    for f in sorted(os.listdir(sd)) if os.path.isdir(sd) else []:
        if f.endswith(".json"):
            out.update(json.load(open(os.path.join(sd, f), encoding="utf-8")))
    return out


def build_prompt(card, style):
    e = load_subjects()[card]
    subj, bg = (e, None) if isinstance(e, str) else (e["subject"], e.get("bg"))
    medium, texture = STYLES[style]
    comp = " " + COMPOSITION.format(bg=BACKGROUNDS[bg]) if (style == "deck" and bg) else ""
    tone = " " + TONE if style == "deck" else ""
    return medium + subj.strip() + comp + tone + " " + texture


def post(path, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(HOST + path, data=data, headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=60).read())


def upload_image(path):
    boundary = uuid.uuid4().hex
    body = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{os.path.basename(path)}\"\r\n"
            f"Content-Type: image/png\r\n\r\n").encode() + open(path, "rb").read() + \
           f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue\r\n--{boundary}--\r\n".encode()
    req = urllib.request.Request(HOST + "/upload/image", data=body,
                                 headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
    return json.loads(urllib.request.urlopen(req).read())["name"]


def i2i_sigmas(full, denoise, steps):
    """Sample the turbo schedule from the point where sigma == denoise down to 0."""
    full = np.array(full)
    idx = np.arange(len(full))
    start = np.interp(denoise, full[::-1], idx[::-1])         # fractional index where sigma = denoise
    pts = np.linspace(start, len(full) - 1, steps + 1)
    return [float(np.interp(p, idx, full)) for p in pts]


def workflow_krea2(M, prompt, seed, w, h, init_image=None, denoise=1.0):
    """Official template image_krea2_turbo_t2i, without the prompt-expansion subgraph."""
    g = {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": M["unet"], "weight_dtype": "default"}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": M["clip"], "type": M["clip_type"], "device": "default"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": M["vae"]}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": prompt}},
        "6": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["5", 0]}},
        "11": {"class_type": "KSampler", "inputs": {"model": ["1", 0], "positive": ["5", 0], "negative": ["6", 0],
                                                    "latent_image": ["10", 0], "seed": seed, "steps": M["steps"], "cfg": 1.0,
                                                    "sampler_name": "euler", "scheduler": "simple", "denoise": denoise}},
        "12": {"class_type": "VAEDecode", "inputs": {"samples": ["11", 0], "vae": ["3", 0]}},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["12", 0], "filename_prefix": "arte_ia_tmp"}},
    }
    _latent(g, w, h, init_image)
    return g, None


def workflow_krea2_ref(M, prompt, seed, w, h, ref_image, lora_strength=1.0):
    g = {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": M["unet"], "weight_dtype": "default"}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": M["clip"], "type": M["clip_type"], "device": "default"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": M["vae"]}},
        "4": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0], "lora_name": "krea2_style_reference.safetensors",
                                                              "strength_model": lora_strength}},
        "7": {"class_type": "ModelSamplingFlux", "inputs": {"model": ["4", 0], "max_shift": 1.15, "base_shift": 0.5,
                                                            "width": w, "height": h}},
        "20": {"class_type": "LoadImage", "inputs": {"image": ref_image}},
        "5": {"class_type": "TextEncodeQwenImageEditPlus", "inputs": {"clip": ["2", 0], "vae": ["3", 0], "image1": ["20", 0],
                                                                     "prompt": prompt}},
        "8": {"class_type": "FluxKontextMultiReferenceLatentMethod", "inputs": {"conditioning": ["5", 0],
                                                                                "reference_latents_method": "index_timestep_zero"}},
        "6": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["8", 0]}},
        "9": {"class_type": "CFGGuider", "inputs": {"model": ["7", 0], "positive": ["8", 0], "negative": ["6", 0], "cfg": 1.0}},
        "14": {"class_type": "KSamplerSelect", "inputs": {"sampler_name": "euler"}},
        "15": {"class_type": "BasicScheduler", "inputs": {"model": ["7", 0], "scheduler": "simple", "steps": M["steps"], "denoise": 1.0}},
        "16": {"class_type": "RandomNoise", "inputs": {"noise_seed": seed}},
        "10": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "11": {"class_type": "SamplerCustomAdvanced", "inputs": {"noise": ["16", 0], "guider": ["9", 0], "sampler": ["14", 0],
                                                                 "sigmas": ["15", 0], "latent_image": ["10", 0]}},
        "12": {"class_type": "VAEDecode", "inputs": {"samples": ["11", 0], "vae": ["3", 0]}},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["12", 0], "filename_prefix": "arte_ia_tmp"}},
    }
    return g, None


def _latent(g, w, h, init_image):
    if init_image is None:
        g["10"] = {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}}
    else:
        g["20"] = {"class_type": "LoadImage", "inputs": {"image": init_image}}
        g["21"] = {"class_type": "ImageScale", "inputs": {"image": ["20", 0], "upscale_method": "lanczos",
                                                          "width": w, "height": h, "crop": "center"}}
        g["10"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["21", 0], "vae": ["3", 0]}}


def workflow(m, prompt, seed, w, h, init_image=None, denoise=1.0, steps=None):
    M = MODELS[m]
    if M["kind"] == "krea2":
        return workflow_krea2(M, prompt, seed, w, h, init_image, denoise)
    sig = M["sigmas"] if init_image is None else i2i_sigmas(M["sigmas"], denoise, steps or 5)
    g = {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": M["unet"]}},
        "2": ({"class_type": "CLIPLoaderGGUF", "inputs": {"clip_name": M["clip"], "type": M["clip_type"]}} if M["clip"].endswith(".gguf")
              else {"class_type": "CLIPLoader", "inputs": {"clip_name": M["clip"], "type": M["clip_type"], "device": "default"}}),
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": M["vae"]}},
        "4": {"class_type": "QwenImage21Cache", "inputs": {"model": ["1", 0], "device": "auto", "dtype": "default"}},
        "5": {"class_type": "TextEncodeQwenImage21", "inputs": {"clip": ["2", 0], "prompt": prompt,
                                                                "negative_prompt": "", "resolution": 1024}},
        "6": {"class_type": "CFGGuider", "inputs": {"model": ["4", 0], "positive": ["5", 0], "negative": ["5", 1], "cfg": 1.0}},
        "7": {"class_type": "ManualSigmas", "inputs": {"sigmas": ", ".join(f"{s:.6f}" for s in sig)}},
        "8": {"class_type": "KSamplerSelect", "inputs": {"sampler_name": "euler"}},
        "9": {"class_type": "RandomNoise", "inputs": {"noise_seed": seed}},
        "11": {"class_type": "SamplerCustomAdvanced", "inputs": {"noise": ["9", 0], "guider": ["6", 0], "sampler": ["8", 0],
                                                                 "sigmas": ["7", 0], "latent_image": ["10", 0]}},
        "12": {"class_type": "VAEDecode", "inputs": {"samples": ["11", 0], "vae": ["3", 0]}},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["12", 0], "filename_prefix": "arte_ia_tmp"}},
    }
    _latent(g, w, h, init_image)
    return g, sig


def run(g):
    pid = post("/prompt", {"prompt": g, "client_id": "arte_ia"})["prompt_id"]
    while True:
        time.sleep(1.0)
        h = post(f"/history/{pid}")
        if pid in h:
            st = h[pid].get("status", {})
            if st.get("status_str") == "error":
                raise RuntimeError(json.dumps(st.get("messages"))[:2000])
            for out in h[pid]["outputs"].values():
                for im in out.get("images", []):
                    q = urllib.parse.urlencode({"filename": im["filename"], "subfolder": im["subfolder"], "type": im["type"]})
                    return urllib.request.urlopen(f"{HOST}/view?{q}").read()
            raise RuntimeError("no image in outputs")


def save(card, name, png, meta):
    d = os.path.join(ROOT, card)
    os.makedirs(d, exist_ok=True)
    open(os.path.join(d, name), "wb").write(png)
    ip = os.path.join(d, "index.json")
    idx = json.load(open(ip, encoding="utf-8")) if os.path.exists(ip) else {"card": card, "images": []}
    idx["images"] = [e for e in idx["images"] if e["file"] != name] + [dict(file=name, **meta)]
    json.dump(idx, open(ip, "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["t2i", "i2i"])
    ap.add_argument("--card", required=True, nargs="+")
    ap.add_argument("--model", default="qwen21t")
    ap.add_argument("--style", default="gouache")
    ap.add_argument("--seeds", type=int, nargs="+", default=[8919])
    ap.add_argument("--denoise", type=float, nargs="+", default=[0.55])
    ap.add_argument("--steps", type=int, default=5)
    ap.add_argument("--w", type=int, default=1056)
    ap.add_argument("--h", type=int, default=1024)
    ap.add_argument("--src", help="i2i source inside arte_ia/<card>/ (refine a favourite) instead of the code art")
    a = ap.parse_args()
    for card in a.card:
        prompt = build_prompt(card, a.style)
        init = None
        if a.mode == "i2i":
            src = os.path.join(ROOT, card, a.src) if a.src else os.path.join(GAME, "assets", "cards", f"{card}.png")
            init = upload_image(src)
        for seed in a.seeds:
            for dn in (a.denoise if a.mode == "i2i" else [1.0]):
                g, sig = workflow(a.model, prompt, seed, a.w, a.h, init, dn, a.steps)
                t = time.time()
                png = run(g)
                dt = time.time() - t
                kind = "ref" if a.src else "i2i"
                mode = "t2i" if a.mode == "t2i" else f"{kind}{int(round(dn * 100))}"
                name = f"{a.model}__{a.style}__{mode}__s{seed}.png"
                save(card, name, png, dict(model=a.model, unet=MODELS[a.model]["unet"], style=a.style, mode=a.mode,
                                           seed=seed, denoise=dn, sigmas=[round(s, 4) for s in sig] if sig else "simple",
                                           src=(a.src or "assets/cards") if a.mode == "i2i" else "", w=a.w, h=a.h,
                                           seconds=round(dt, 1), prompt=prompt,
                                           created=time.strftime("%Y-%m-%d %H:%M:%S")))
                print(f"{card} {name} {dt:.1f}s", flush=True)


if __name__ == "__main__":
    main()
