#!/usr/bin/env python3
"""Monta fotos (PNG no pico) e clipes (WebM VP9) da rodada visual a partir dos .avi brutos gravados por
tools/capture_clip.sh. Uso: python tools/build_clips_fx.py [id ...]  (sem ids: todos).
Os .avi ficam em %TEMP%/clips_raw (RAW). Saída: docs/rodada_visual/<frente>/{antes,v1,v2}/<id>.png|.webm e itens.json."""
import json, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

FF = "/c/Users/gabri/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0.2-full_build/bin/ffmpeg"
FF = FF.replace("/c/", "C:/", 1)
RAW = os.path.expandvars(r"%TEMP%\clips_raw").replace("\\", "/")
ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "docs", "rodada_visual")
FPS = 30

# crop = (w, h, x, y) no quadro 1600x900; cast = quadro do disparo; pre/len = janela do clipe (quadros);
# peak = deslocamento do pico a partir do disparo; slow = fator de câmera lenta no clipe.
SPELL = (640, 360, 477, 249)
SMALL = (480, 270, 557, 275)
FX = [
    dict(id="tocha", t="Tocha", d="Feitiço de fogo jogado no herói: explosão de chamas, faíscas, onda de choque e marca queimada no chão (no estilo de antes era um círculo roxo de magia).", src="fx_{v}_magias", cast=297, peak=7, pre=10, len=100, crop=SPELL),
    dict(id="sombra", t="Raio de sombra", d="Feitiço de sombra (maldição): onda roxa e partículas escuras saindo do herói atingido.", src="fx_{v}_magias", cast=478, peak=10, pre=10, len=100, crop=SPELL),
    dict(id="arcano", t="Faísca arcana", d="Magia arcana: runas brilhando no chão e estrelas subindo.", src="fx_{v}_magias", cast=659, peak=10, pre=10, len=100, crop=SPELL),
    dict(id="corpo", t="Explosão de cadáver", d="Explosão de corpo: o efeito mais forte dos feitiços pequenos, com anel de choque e fumaça.", src="fx_{v}_magias", cast=839, peak=10, pre=10, len=110, crop=SPELL),
    dict(id="maldicao", t="Maldição da fraqueza", d="Maldição que enfraquece o herói: círculo escuro e fumaça arroxeada.", src="fx_{v}_magias", cast=1025, peak=8, pre=10, len=100, crop=SPELL),
    dict(id="teia", t="Teia", d="Teia no chão: prende e atrasa o herói. Veja o desenho da teia e os fios brilhando.", src="fx_{v}_magias", cast=1205, peak=60, pre=10, len=150, crop=SPELL),
    dict(id="oleo", t="Óleo fervendo", d="Poça de óleo fervendo que queima quem pisa: bolhas, chamas e brasas.", src="fx_{v}_magias", cast=1386, peak=50, pre=10, len=160, crop=SPELL),
    dict(id="golpe", t="Golpe (acerto)", d="Faísca de um golpe acertando. É bem rápida (câmera lenta no vídeo).", src="fx_{v}_magias", cast=1746, peak=2, pre=4, len=30, crop=SMALL, slow=4),
    dict(id="morte", t="Morte de unidade", d="Nuvem e pedaços quando uma criatura morre.", src="fx_{v}_magias", cast=1851, peak=8, pre=6, len=60, crop=SMALL, slow=2),
    dict(id="cura", t="Cura", d="Cruzes verdes subindo quando alguém é curado.", src="fx_{v}_magias", cast=1956, peak=14, pre=6, len=70, crop=SMALL, slow=2),
    dict(id="escudo", t="Quebra de escudo", d="Cacos de escudo voando quando a proteção se quebra.", src="fx_{v}_magias", cast=2061, peak=6, pre=4, len=40, crop=SMALL, slow=3),
    dict(id="nivel", t="Subir de nível", d="Coluna de luz e estrelas quando o herói sobe de nível.", src="fx_{v}_magias", cast=2166, peak=12, pre=6, len=70, crop=SMALL, slow=2),
    dict(id="taverna", t="Casa da taverna destruída", d="Uma casa desmorona na disputa da taverna: poeira, entulho e chamas.", src="fx_{v}_taverna", cast=304, peak=9, pre=14, len=140, crop=(640, 360, 297, 350)),
]
STYLES = [("antes", "v0"), ("v1", "v1"), ("v2", "v2")]


def run(args):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        print("ERRO", " ".join(args)[:200], r.stderr[-300:])
    return r.returncode == 0


def build(e):
    ok = True
    for pasta, v in STYLES:
        avi = "%s/%s.avi" % (RAW, e["src"].format(v=v))
        d = os.path.join(OUT, e["frente"], pasta)
        os.makedirs(d, exist_ok=True)
        w, h, x, y = e["crop"]
        scale = "scale=1280:-2:flags=lanczos"
        peak_t = (e["cast"] + e["peak"]) / FPS
        ok &= run([FF, "-v", "error", "-ss", "%.4f" % peak_t, "-i", avi, "-frames:v", "1", "-vf",
                   "crop=%d:%d:%d:%d,%s" % (w, h, x, y, scale), "-y", os.path.join(d, e["id"] + ".png")])
        start_t = (e["cast"] - e["pre"]) / FPS
        slow = e.get("slow", 1)
        vf = "crop=%d:%d:%d:%d,%s,setpts=%d*PTS" % (w, h, x, y, scale, slow)
        ok &= run([FF, "-v", "error", "-ss", "%.4f" % start_t, "-i", avi, "-frames:v", str(e["len"]), "-vf", vf, "-an",
                   "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "36", "-row-mt", "1", "-r", "30", "-pix_fmt", "yuv420p",
                   "-y", os.path.join(d, e["id"] + ".webm")])
    return e["id"], ok


def write_items(specs):
    by = {}
    for e in specs:
        by.setdefault(e["frente"], []).append(e)
    for frente, lst in by.items():
        items = []
        for e in lst:
            rel = lambda p: "docs/rodada_visual/%s/%s/%s" % (e["frente"], p, e["id"])
            items.append({
                "id": "%s_%s" % (e["frente"], e["id"]),
                "frente": e["fn"], "titulo": e["t"], "descricao": e["d"], "flag": e["flag"],
                "antes": [rel("antes") + ".png"],
                "variacoes": {"V1 pintado" if e["flag"].startswith("--fx") else "V1": [rel("v1") + ".png"],
                              "V2 brilhante" if e["flag"].startswith("--fx") else "V2": [rel("v2") + ".png"]},
                "videos": [rel("antes") + ".webm", rel("v1") + ".webm", rel("v2") + ".webm"],
            })
        with open(os.path.join(OUT, frente, "itens.json"), "w", encoding="utf-8") as f:
            json.dump(items, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    from clips_extra import EXTRA  # noqa: E402  (herois, arena, combate, projeteis)
    specs = FX + EXTRA
    for e in specs:
        e.setdefault("frente", "fx")
        e["fn"] = {"fx": "Efeitos", "herois": "Heróis", "arena": "Arena"}[e["frente"]]
        e["flag"] = {"fx": "--fx=N", "herois": "--herois=N", "arena": "--arena=N"}[e["frente"]]
    want = set(sys.argv[1:])
    todo = [e for e in specs if not want or e["id"] in want]
    with ThreadPoolExecutor(3) as ex:
        for i, ok in ex.map(build, todo):
            print(i, "ok" if ok else "FALHOU", flush=True)
    write_items(specs)
