"""Editor dos desafios que liberam cartas (só na máquina local).

Uso (na raiz do projeto): python -I tools/desafios_editor/server.py   ->  http://127.0.0.1:8768

- Mostra cada carta bloqueada com o desafio dela, se é "entre runs" ou "numa run", e a proporção total.
- "Salvar" grava o texto em tools/desbloqueios.json (nos três vilões, se a carta for comum) e roda
  tools/gerar_unlocks.py, que atualiza data/unlocks.json e as linhas UNLOCK_<id> de locale/strings.csv.
- Texto que o jogo ainda não entende pode ser guardado como pedido em balance_reports/pedidos_desafios.json
  para o Claude implementar depois (nada muda no jogo até lá).
"""
import contextlib
import csv
import datetime
import io
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import gerar_unlocks as G  # noqa: E402

SRC = os.path.join(ROOT, "tools", "desbloqueios.json")
REQUESTS = os.path.join(ROOT, "balance_reports", "pedidos_desafios.json")
ART = os.path.join(ROOT, "assets", "cards")
PORT = 8768
VILLAINS = ("plague", "dragon", "lich")
CARD_FILES = ["cards", "cards_common", "cards_plague", "cards_dragon", "cards_lich"]


def _strings():
    out = {}
    with open(os.path.join(ROOT, "locale", "strings.csv"), encoding="utf-8", newline="") as f:
        for row in csv.reader(f):
            if len(row) >= 2:
                out[row[0]] = row[1]
    return out


def _load_src():
    with open(SRC, encoding="utf-8") as f:
        return json.load(f)


def _save_src(obj):
    tmp = SRC + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)
    os.replace(tmp, SRC)


def _requests():
    if not os.path.exists(REQUESTS):
        return []
    with open(REQUESTS, encoding="utf-8") as f:
        return json.load(f).get("pedidos", [])


def _save_requests(items):
    os.makedirs(os.path.dirname(REQUESTS), exist_ok=True)
    with open(REQUESTS, "w", encoding="utf-8", newline="\n") as f:
        json.dump({"_doc": "Pedidos de desafio feitos no editor (tools/desafios_editor). O Claude implementa e "
                           "marca feito.", "pedidos": items}, f, ensure_ascii=False, indent=1)


def _info(text):
    spec, en = G.parse(text)
    if spec is None:
        return {"ok": False}
    return {"ok": True, "cross": G.cross_run(spec), "en": en, "spec": spec}


def _payload():
    src = _load_src()
    s = _strings()
    cards = {}
    for fn in CARD_FILES:
        with open(os.path.join(ROOT, "data", fn + ".json"), encoding="utf-8") as f:
            for c in json.load(f)["cards"]:
                cards[c["id"]] = {"id": c["id"], "name": s.get("CARD_" + c["id"], c["id"]),
                                  "owner": c.get("owner", "common"), "rarity": c.get("rarity", "common"),
                                  "type": c.get("type", ""), "cost": c.get("cost", 0),
                                  "art": os.path.exists(os.path.join(ART, c["id"] + ".png"))}
    rows = {}
    for v in VILLAINS:
        base = set(src[v]["start_deck"])
        for cid, x in src[v]["unlocks"].items():
            r = rows.setdefault(cid, dict(cards.get(cid, {"id": cid, "name": cid, "owner": "?", "rarity": "common"}),
                                          villains=[], state="F", text=""))
            r["villains"].append(v)
            if x != "F":
                r["state"] = "L"
                r["text"] = x[2:]
                r.update({"info": _info(x[2:])})
        for cid in base:
            if cid in cards and cid not in rows:
                rows[cid] = dict(cards[cid], villains=[v], state="B", text="")
    # reliquias (plano 21/11/2026): linhas com id "r:<id>", grupo "relic"
    with open(os.path.join(ROOT, "data", "relics.json"), encoding="utf-8") as f:
        for rel in json.load(f)["relics"]:
            x = src.get("relics", {}).get(rel["id"], "F")
            row = {"id": "r:" + rel["id"], "name": s.get("REL_" + rel["id"], rel["id"]), "owner": "relic",
                   "rarity": rel.get("rarity", "common"), "type": "relic", "cost": 0, "art": False,
                   "villains": [], "state": "F" if x == "F" else "L", "text": "" if x == "F" else x[2:],
                   "relic_owner": rel.get("owner", "common")}
            if x != "F":
                row["info"] = _info(x[2:])
            rows[row["id"]] = row
    return {"rows": sorted(rows.values(), key=lambda r: (r["owner"], r["name"])),
            "names": {"plague": s.get("DECK_plague", "Praga"), "dragon": s.get("DECK_dragon", "Dragão"),
                      "lich": s.get("DECK_lich", "Lich"), "common": "Comuns", "relic": "Relíquias"},
            "requests": _requests()}


def _regenerate():
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = G.main()
    return code == 0, buf.getvalue().strip()


def _set_text(cid, text):
    info = _info(text)
    if not info["ok"]:
        return {"ok": False, "error": "O jogo ainda não entende esse texto. Use um modelo ou salve como pedido."}
    src = _load_src()
    old = {}
    hit = False
    if cid.startswith("r:"):
        rid = cid[2:]
        if rid not in src.get("relics", {}):
            return {"ok": False, "error": "Relíquia %s não está em desbloqueios.json." % rid}
        prev = src["relics"][rid]
        src["relics"][rid] = "L|" + text
        _save_src(src)
        ok, out = _regenerate()
        if not ok:
            src["relics"][rid] = prev
            _save_src(src)
            _regenerate()
            return {"ok": False, "error": "O gerador recusou: " + out}
        return {"ok": True, "msg": out, "info": info}
    for v in VILLAINS:
        u = src[v]["unlocks"]
        if cid in u:
            old[v] = u[cid]
            u[cid] = "L|" + text
            hit = True
    if not hit:
        return {"ok": False, "error": "Carta %s não está em nenhuma lista de desbloqueio." % cid}
    _save_src(src)
    ok, out = _regenerate()
    if not ok:  # volta ao que era
        for v, x in old.items():
            src[v]["unlocks"][cid] = x
        _save_src(src)
        _regenerate()
        return {"ok": False, "error": "O gerador recusou: " + out}
    return {"ok": True, "msg": out, "info": info}


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code, body, ctype="application/json; charset=utf-8"):
        if isinstance(body, (dict, list)):
            body = json.dumps(body, ensure_ascii=False).encode("utf-8")
        elif isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        p = self.path.split("?")[0]
        if p in ("/", "/index.html"):
            with open(os.path.join(HERE, "index.html"), "rb") as f:
                return self._send(200, f.read(), "text/html; charset=utf-8")
        if p == "/api/data":
            return self._send(200, _payload())
        if p.startswith("/art/") and p.endswith(".png"):
            name = os.path.basename(p[5:])
            fp = os.path.join(ART, name)
            if os.path.isfile(fp):
                with open(fp, "rb") as f:
                    return self._send(200, f.read(), "image/png")
        self._send(404, {"error": "não encontrado"})

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(n) or b"{}")
        except ValueError:
            return self._send(400, {"error": "JSON inválido"})
        if self.path == "/api/parse":
            return self._send(200, _info(str(body.get("text", "")).strip()))
        if self.path == "/api/save":
            return self._send(200, _set_text(str(body.get("id", "")), str(body.get("text", "")).strip()))
        if self.path == "/api/request":
            items = _requests()
            items.append({"id": str(body.get("id", "")), "texto": str(body.get("text", "")).strip(),
                          "nota": str(body.get("note", "")).strip(), "feito": False,
                          "quando": datetime.datetime.now().strftime("%Y-%m-%d %H:%M")})
            _save_requests(items)
            return self._send(200, {"ok": True, "requests": items})
        if self.path == "/api/request_delete":
            items = _requests()
            i = int(body.get("index", -1))
            if 0 <= i < len(items):
                items.pop(i)
                _save_requests(items)
            return self._send(200, {"ok": True, "requests": items})
        self._send(404, {"error": "não encontrado"})


if __name__ == "__main__":
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), H)
    print("Editor de desafios em http://127.0.0.1:%d  (Ctrl+C para sair)" % PORT)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
