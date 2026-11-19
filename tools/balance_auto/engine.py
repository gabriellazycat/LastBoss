"""Motor do ajustador automático: variantes de data/ por patches, execução em paralelo com cache por run,
A/B pareado por semente. Importa tools/run_batch.py (um processo Godot por chunk)."""
import concurrent.futures as cf
import copy
import glob
import hashlib
import json
import math
import os
import random
import shutil
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import run_batch as rb  # noqa: E402

WORK = os.path.join(ROOT, "balance_reports", "auto")
CACHE = os.path.join(WORK, "runs_cache.jsonl")
os.makedirs(WORK, exist_ok=True)
WORKERS = int(os.environ.get("BA_WORKERS", os.cpu_count() or 4))
CHUNK = 6
_lock = threading.Lock()
_store = {}
_ver = {}   # chave da variante -> pasta res://


def jload(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return json.load(f)


def load_store():
    if os.path.exists(CACHE):
        with open(CACHE, encoding="utf-8") as f:
            for line in f:
                try:
                    k, v = json.loads(line)
                    _store[k] = v
                except Exception:
                    pass


# ---------- patches ----------
def _walk(obj, path):
    cur = obj
    for p in path:
        if isinstance(p, dict):
            m = [x for x in cur if all(str(x.get(k)) == str(v) for k, v in p.items())]
            assert len(m) == 1, f"seletor {p} achou {len(m)}"
            cur = m[0]
        else:
            cur = cur[p]
    return cur


def get_value(file, path, base=None):
    d = base if base is not None else jload("data/" + file)
    return _walk(d, path)


def apply_patches(dst, patches):
    files = {}
    for file, path, val in patches:
        if file not in files:
            with open(os.path.join(dst, file), encoding="utf-8") as f:
                files[file] = json.load(f)
        parent = _walk(files[file], path[:-1])
        assert path[-1] in parent, f"caminho inexistente {file} {path}"
        parent[path[-1]] = val
    for file, d in files.items():
        with open(os.path.join(dst, file), "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, indent=1)


def vkey(patches):
    if not patches:
        return "base"
    return hashlib.sha1(json.dumps(sorted(patches, key=lambda p: json.dumps(p)), sort_keys=True).encode()).hexdigest()[:12]


def variant_dir(patches):
    k = vkey(patches)
    if k == "base":
        return "res://data"
    if k not in _ver:
        dst = os.path.join(ROOT, "data_exp", "ba_" + k)
        if not os.path.isdir(dst):
            shutil.copytree(os.path.join(ROOT, "data"), dst)
            apply_patches(dst, patches)
        _ver[k] = f"res://data_exp/ba_{k}"
    return _ver[k]


def data_hash():
    h = hashlib.sha1()
    for p in sorted(glob.glob(os.path.join(ROOT, "data", "*.json"))):
        h.update(open(p, "rb").read())
    return h.hexdigest()[:10]


_BASE_HASH = None


def slim(r):
    return {"seed": r["seed"], "win": rb.is_win(r), "hp_frac": r.get("hp_frac", 0.0), "fallen": r.get("heroes_fallen", 0),
            "t": r["t_end"], "waste": r.get("waste_s", 0.0), "dmg": r.get("dmg_by_card", {}), "played": r.get("played", {}),
            "res": r["result"], "ms": r.get("wall_ms", 0.0)}


def _key(vk, bot, cell, extra, seed):
    global _BASE_HASH
    if _BASE_HASH is None:
        _BASE_HASH = data_hash()
    return f"{_BASE_HASH}|{vk}|{bot}|{cell}|{json.dumps(extra, sort_keys=True)}|{seed}"


def seeds_str(seeds):
    return ",".join(str(s) for s in seeds)


def measure_many(reqs):
    """reqs: lista de dicts {patches, bot, cell, extra, seeds}. Preenche req['runs'] (ordem das sementes)."""
    jobs = []
    for r in reqs:
        r.setdefault("patches", [])
        r.setdefault("extra", {})
        vk = vkey(r["patches"])
        r["_vk"] = vk
        miss = [s for s in r["seeds"] if _key(vk, r["bot"], r["cell"], r["extra"], s) not in _store]
        for i in range(0, len(miss), CHUNK):
            jobs.append((r, miss[i:i + CHUNK]))
    if jobs:
        random.Random(1).shuffle(jobs)
        for r in {id(j[0]): j[0] for j in jobs}.values():
            variant_dir(r["patches"])

        def work(job):
            r, seeds = job
            out = os.path.join(WORK, "parts", f"{r['_vk']}_{r['bot']}_{r['cell'].replace('@', '_')}_{seeds[0]}_{os.getpid()}_{threading.get_ident()}.json")
            os.makedirs(os.path.dirname(out), exist_ok=True)
            for attempt in range(2):
                try:
                    runs, errs = rb.run_chunk(r["bot"], r["cell"], seeds_str(seeds), out, variant_dir(r["patches"]), "full", r["extra"])
                    break
                except Exception as e:  # um chunk que falha não derruba a rodada
                    print("chunk falhou:", str(e)[:200], flush=True)
                    runs, errs = [], []
            if errs:
                print("ERRO DE SCRIPT:", errs[:2], flush=True)
            with _lock:
                with open(CACHE, "a", encoding="utf-8") as f:
                    for x in runs:
                        s = slim(x)
                        k = _key(r["_vk"], r["bot"], r["cell"], r["extra"], s["seed"])
                        _store[k] = s
                        f.write(json.dumps([k, s]) + "\n")
            try:
                os.remove(out)
            except OSError:
                pass

        with cf.ThreadPoolExecutor(max_workers=WORKERS) as ex:
            list(ex.map(work, jobs))
    for r in reqs:
        r["runs"] = [_store[k] for s in r["seeds"] if (k := _key(r["_vk"], r["bot"], r["cell"], r["extra"], s)) in _store]
    return reqs


# ---------- estatística ----------
def mean(xs):
    return sum(xs) / len(xs) if xs else float("nan")


def paired(a, b, key="hp_frac", n_boot=400):
    """Δ = b − a pareado por semente. Retorna (média, ep, lo, hi, n)."""
    da = {r["seed"]: r for r in a}
    d = [float(r[key]) - float(da[r["seed"]][key]) for r in b if r["seed"] in da]
    n = len(d)
    if n < 2:
        return (float("nan"),) * 4 + (n,)
    m = mean(d)
    sd = math.sqrt(sum((x - m) ** 2 for x in d) / (n - 1))
    rnd = random.Random(7)
    bs = sorted(mean([d[rnd.randrange(n)] for _ in range(n)]) for _ in range(n_boot))
    return m, sd / math.sqrt(n), bs[int(0.025 * n_boot)], bs[int(0.975 * n_boot)], n


def winrate(runs):
    return mean([1.0 if r["win"] else 0.0 for r in runs])


def save_json(path, obj):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)
    os.replace(tmp, path)
