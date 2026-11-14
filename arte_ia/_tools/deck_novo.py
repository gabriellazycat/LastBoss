"""Gerador do baralho no estilo de 13/11/2026 (ver estilo.py e .claude/skills/cartas-ia/SKILL.md). Sem tokens: só fila.

python deck_novo.py lote plague|dragon|lich|common|base|<ids...> [--dir final_novo] [--den 0.62] [--force]
python deck_novo.py refazer <id> [<id>...]       semente +1, mesmo estilo
python deck_novo.py prancha <lote>               refaz só a prancha
Um passo só, no tamanho da carta: 560x544 -> recorte 556x534, grão 0,9. Carta que já tem arte no baralho antigo
é repintada a partir dela (mesma pose, base simplificada pela mediana); carta nova sai do texto.
Saída: arte_ia/final_novo/<id>.png; estado em deck_novo_state.json; pranchas em arte_ia/pranchas/novo_<lote>.png
"""
import argparse, json, os, subprocess, sys, tempfile, time, urllib.error, urllib.request, zlib
from PIL import Image, ImageOps

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen, grain as gm, estilo
import deck

T = os.path.dirname(os.path.abspath(__file__))
ROOT = gen.ROOT
MODEL, W, H, FW, FH, GRAIN = "krea2anime", 560, 544, 556, 534, 0.9
STATE = os.path.join(T, "deck_novo_state.json")
OLD = os.path.join(T, "deck_state.json")
TMP = os.path.join(tempfile.gettempdir(), "lastboss_base_novo.png")


COMFY = r"C:\AI\ComfyUI"


def servidor_ok():
    try:
        urllib.request.urlopen(gen.HOST + "/system_stats", timeout=3)
        return True
    except Exception:
        return False


def subir_servidor():
    """O ComfyUI (--lowvram) encerra sozinho depois de poucos prompts, sem erro (13/11): sobe de novo, solto do script."""
    print("servidor fora do ar: subindo o ComfyUI", flush=True)
    log = open(os.path.join(tempfile.gettempdir(), "comfyui_deck_novo.log"), "ab")
    subprocess.Popen([os.path.join(COMFY, "venv", "Scripts", "python.exe"), "main.py", "--listen", "127.0.0.1",
                      "--port", "8188", "--lowvram"], cwd=COMFY, stdout=log, stderr=log,
                     creationflags=0x00000008 | 0x00000200)          # DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP
    for _ in range(60):
        if servidor_ok():
            return
        time.sleep(3)
    raise RuntimeError("ComfyUI não subiu em 3 min")


def com_retentativa(fn, *a):
    for tentativa in range(5):
        try:
            if not servidor_ok():
                subir_servidor()
            return fn(*a)
        except (urllib.error.URLError, ConnectionError, OSError) as e:
            print(f"falha de conexão ({e}); tentativa {tentativa + 1}/5", flush=True)
            time.sleep(5)
    raise RuntimeError("ComfyUI continua fora do ar")


def load(p):
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else {}


def base_path(card):
    f = load(OLD).get(card, {}).get("file")
    for name in ([f.replace("__grain90", ""), f] if f else []):
        p = os.path.join(ROOT, card, name)
        if os.path.exists(p):
            return p
    return None


def make(card, seed, den, final_dir, texto=False, base_arq=None):
    e = gen.load_subjects()[card]
    subj, bg = (e["subject"], e["bg"]) if isinstance(e, dict) else (e, "lilac")
    prompt = estilo.build_prompt(subj, bg)
    # texto=True: muda a composição, então não parte da arte antiga; base_arq: repinta uma imagem escolhida (mantém a pose)
    base = base_arq or (None if texto else base_path(card))
    t = time.time()
    if base:
        estilo.simplificar(ImageOps.fit(Image.open(base).convert("RGB"), (W, H), Image.LANCZOS)).save(TMP)
        g, _ = gen.workflow(MODEL, prompt, seed, W, H, init_image=gen.upload_image(TMP), denoise=den)
    else:
        g, _ = gen.workflow(MODEL, prompt, seed, W, H)
    img = Image.open(__import__("io").BytesIO(gen.run(g))).convert("RGB")
    img = gm.grain(img, seed=zlib.crc32(f"{card}{seed}".encode()), strength=GRAIN)
    out = os.path.join(ROOT, final_dir, f"{card}.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    ImageOps.fit(img, (FW, FH), Image.LANCZOS).save(out)
    print(f"{card} s{seed} {'repinta' if base else 'texto'} {time.time() - t:.0f}s", flush=True)
    return prompt


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["lote", "refazer", "prancha"])
    ap.add_argument("args", nargs="+")
    ap.add_argument("--dir", default="final_novo")
    ap.add_argument("--den", type=float, default=0.62)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--base", default=None, help="caminho de uma imagem para repintar (mantém a pose dela)")
    ap.add_argument("--texto", action="store_true", help="sem arte-base: a composição sai só do assunto (cena nova)")
    a = ap.parse_args()
    st = load(STATE)
    subjects = gen.load_subjects()
    ids = [c for l in a.args for c in deck.cards_of(l)]
    if a.cmd == "prancha":
        deck.prancha("novo_" + a.args[0], ids, a.dir)
        return
    for c in ids:
        if c not in subjects:
            print(f"{c}: sem assunto, pulada", flush=True)
            continue
        # pula qualquer carta que já tenha arquivo (não depende do estado: um lote regenerou o Rei dos Ratos aprovado em 13/11)
        if a.cmd == "lote" and not a.force and os.path.exists(os.path.join(ROOT, a.dir, f"{c}.png")):
            continue
        seed = st[c]["seed"] + 1 if (a.cmd == "refazer" and c in st) else 1000
        st[c] = {"seed": seed, "den": a.den, "dir": a.dir}
        com_retentativa(make, c, seed, a.den, a.dir, a.texto, a.base)
        json.dump(st, open(STATE, "w", encoding="utf-8"), indent=1)
    if a.cmd == "lote" and len(a.args) == 1:
        deck.prancha("novo_" + a.args[0], deck.cards_of(a.args[0]), a.dir)


if __name__ == "__main__":
    main()
