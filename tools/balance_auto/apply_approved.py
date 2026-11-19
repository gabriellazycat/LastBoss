"""Aplica o JSON de mudanças aprovadas em data/ (etapa 12). Uso: python -I tools/balance_auto/apply_approved.py aprovados.json [--dry]
Para cada mudança confere que o caminho existe exatamente uma vez e que o valor 'antes' ainda é o atual; senão vai para conflito
(sem sobrescrever). Imprime antes → depois e lembra de conferir n3/lvl e textos do locale."""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def walk(obj, path):
    cur = obj
    for p in path:
        if isinstance(p, dict):
            m = [x for x in cur if all(str(x.get(k)) == str(v) for k, v in p.items())]
            if len(m) != 1:
                raise KeyError(f"seletor {p} achou {len(m)}")
            cur = m[0]
        else:
            cur = cur[p]
    return cur


sys.stdout.reconfigure(encoding="utf-8")


def main():
    items = json.load(open(sys.argv[1], encoding="utf-8"))
    dry = "--dry" in sys.argv
    files, conflicts, done = {}, [], []
    for it in items:
        fp = os.path.join(ROOT, "data", it["file"])
        if it["file"] not in files:
            files[it["file"]] = json.load(open(fp, encoding="utf-8"))
        try:
            parent = walk(files[it["file"]], it["path"][:-1])
            cur = parent[it["path"][-1]]
        except (KeyError, IndexError, TypeError) as e:
            conflicts.append((it, f"caminho inválido: {e}"))
            continue
        if cur != it["from"]:
            conflicts.append((it, f"valor atual {cur} ≠ antes {it['from']}"))
            continue
        parent[it["path"][-1]] = it["to"]
        done.append(it)
        print(f"{it['kind']:9} {str(it['id']):28} {'.'.join(str(p) if not isinstance(p, dict) else '@' + str(p.get('id')) for p in it['path'])}: {it['from']} → {it['to']}")
    for it, why in conflicts:
        print("CONFLITO:", it["id"], why)
    if dry:
        print("(dry-run: nada gravado)")
        return
    for fn, d in files.items():
        with open(os.path.join(ROOT, "data", fn), "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, indent=1)
    print(f"{len(done)} aplicadas, {len(conflicts)} em conflito.")
    print("Confira: n3, lvl e textos do locale que arredondam estes números; depois rode tests.tscn e um lote final.")


main()
