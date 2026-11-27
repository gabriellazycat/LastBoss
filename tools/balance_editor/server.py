"""Editor de balanceamento das cartas (só na máquina local).

Uso: python -I tools/balance_editor/server.py   ->  http://127.0.0.1:8767

- Lê as cartas de data/cards*.json e os textos de locale/strings.csv.
- "Salvar" grava custo, vida, DPS, unidades e os números de efeito de volta
  no MESMO arquivo de onde cada carta veio (formato idêntico ao original).
- Os pedidos de mudança de texto/efeito ficam em balance_reports/pedidos_cartas.json
  para o Claude aplicar depois (o servidor não muda regra nenhuma sozinho).
"""
import csv
import datetime
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, "data")
HERE = os.path.dirname(os.path.abspath(__file__))
FILES = ["cards", "cards_common", "cards_plague", "cards_dragon", "cards_lich"]
REQUESTS = os.path.join(ROOT, "balance_reports", "pedidos_cartas.json")
# Propostas verificadas: duelo dos monstros (tools/duel_tune.py) e esquadrão dos feitiços (tools/spell_tune.py).
DUEL = [os.path.join(ROOT, "balance_reports", n) for n in ("pedidos_duelo.json", "pedidos_feiticos.json")]
DUEL_MD = [os.path.join(ROOT, "balance_reports", n) for n in ("duelo.md", "feiticos.md")]
ART = os.path.join(ROOT, "assets", "cards")
PORT = 8767
# Campos da carta que a página pode mudar; o resto do JSON fica intocado.
TOP_FIELDS = {"cost", "hp", "dps", "count", "attack_interval", "speed", "range"}


def _read_json(name):
    with open(os.path.join(DATA, name + ".json"), encoding="utf-8", newline="") as f:
        return json.loads(f.read())


def _write_json(name, obj):
    # Mesmo formato dos arquivos atuais: indent 1, UTF-8 cru, CRLF, sem quebra no fim.
    text = json.dumps(obj, indent=1, ensure_ascii=False).replace("\n", "\r\n")
    path = os.path.join(DATA, name + ".json")
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    os.replace(tmp, path)


def _strings():
    out = {}
    with open(os.path.join(ROOT, "locale", "strings.csv"), encoding="utf-8", newline="") as f:
        for row in csv.reader(f):
            if len(row) >= 2:
                out[row[0]] = row[1]
    return out


def _requests():
    if not os.path.exists(REQUESTS):
        return []
    with open(REQUESTS, encoding="utf-8") as f:
        return json.load(f).get("pedidos", [])


def _save_requests(items):
    os.makedirs(os.path.dirname(REQUESTS), exist_ok=True)
    with open(REQUESTS, "w", encoding="utf-8") as f:
        json.dump({"pedidos": items}, f, indent=1, ensure_ascii=False)


def _duel():
    out = []
    for path in DUEL:
        if os.path.exists(path):
            with open(path, encoding="utf-8") as f:
                out += json.load(f).get("pedidos", [])
    return out


def _num(v):
    x = float(v)
    return int(x) if x.is_integer() else x


def load_all():
    s = _strings()
    rules = json.load(open(os.path.join(DATA, "rules.json"), encoding="utf-8"))
    cards = []
    for fname in FILES:
        for d in _read_json(fname)["cards"]:
            cid = d["id"]
            cards.append({
                "file": fname,
                "card": d,
                "name": s.get("CARD_" + cid, cid),
                "desc": s.get("DESC_" + cid, ""),
                "n3": s.get("N3_" + cid, ""),
                "art": os.path.exists(os.path.join(ART, cid + ".png")),
            })
    kw = {k[3:]: v for k, v in s.items() if k.startswith("KW_")}
    decks = {k[5:]: v for k, v in s.items() if k.startswith("DECK_")}
    types = {k[5:]: v for k, v in s.items() if k.startswith("TYPE_")}
    rarity = {k[7:]: v for k, v in s.items() if k.startswith("RARITY_")}
    return {"cards": cards, "kw": kw, "decks": decks, "types": types, "rarity": rarity,
            "growth": rules.get("card_levels", {}).get("growth", 0.25),
            "requests": _requests(), "duel": _duel()}


def apply_changes(changes):
    """changes: {id: {"cost": 3, "fx.damage": 120, ...}} -> grava e devolve o resumo."""
    done = []
    for fname in FILES:
        obj = _read_json(fname)
        touched = False
        for d in obj["cards"]:
            ch = changes.get(d["id"])
            if not ch:
                continue
            for key, val in ch.items():
                if key.startswith("fx.") or key.startswith("n3."):
                    grp, k = key.split(".", 1)
                    tgt = d.get(grp)
                    if not isinstance(tgt, dict) or k not in tgt or isinstance(tgt[k], bool):
                        raise ValueError("%s: campo %s não existe" % (d["id"], key))
                    old = tgt[k]
                    tgt[k] = _num(val)
                elif key in TOP_FIELDS and key in d:
                    old = d[key]
                    new = _num(val)
                    # Mantém 4.0 como float se o original era float.
                    d[key] = float(new) if isinstance(old, float) else new
                else:
                    raise ValueError("%s: campo %s não pode ser editado" % (d["id"], key))
                if old != (tgt[k] if key.startswith(("fx.", "n3.")) else d[key]):
                    done.append("%s %s: %s → %s" % (d["id"], key, old, val))
                touched = True
        if touched:
            _write_json(fname, obj)
    return done


def duel_page():
    """balance_reports/duelo.md e feiticos.md como página: tabelas com cor pela razão valor/peso."""
    import html
    lines = []
    for path in DUEL_MD:
        if os.path.exists(path):
            lines += open(path, encoding="utf-8").read().splitlines() + [""]
    if not lines:
        return "<p>Sem duelo ainda: rode tools/duel_tune.py e tools/spell_tune.py.</p>"
    s = _strings()
    out, head = [], None
    for line in lines:
        if line.startswith("|---"):
            continue
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if head is None or cells[0] == "carta":
                if head is not None and not out[-1].endswith("</table>"):
                    out.append("</tbody></table>")
                head = cells
                out.append("<table><thead><tr>%s</tr></thead><tbody>" % "".join("<th>%s</th>" % html.escape(c) for c in cells))
                continue
            # Cor pela razão final: "razão depois" (tools/duel_tune.py) ou "razão" (tools/duel_report.py).
            rc = head.index("razão depois") if "razão depois" in head else head.index("razão")
            try:
                r = float(cells[rc])
            except ValueError:
                r = float(cells[rc - 1]) if rc and cells[rc - 1].replace(".", "", 1).isdigit() else 1.0
            cls = "ok" if 0.8 <= r <= 1.2 else ("hi" if r > 1.2 else "lo")
            cid = cells[0].split(" ")[0]
            cells[0] = "<b>%s</b><br><small>%s</small>" % (html.escape(s.get("CARD_" + cid, cid)), html.escape(cells[0]))
            out.append("<tr class='%s'>%s</tr>" % (cls, "".join(
                "<td%s>%s</td>" % (" class='r'" if k == rc else "", c if k == 0 else html.escape(c))
                for k, c in enumerate(cells))))
        else:
            if head is not None and not out[-1].endswith("</table>"):
                out.append("</tbody></table>")
                head = None
            if line.startswith("# "):
                out.append("<h1>%s</h1>" % html.escape(line[2:]))
            elif line.strip():
                out.append("<p>%s</p>" % html.escape(line))
    return """<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Duelo</title>
<style>body{font:14px system-ui;margin:20px;background:#f6f3ec;color:#222}table{border-collapse:collapse;width:100%%}
th,td{padding:5px 8px;border-bottom:1px solid #ddd;text-align:left;vertical-align:top}th{position:sticky;top:0;background:#e8e2d4}
tr.hi td.r{background:#f3c1b5;font-weight:bold}tr.lo td.r{background:#b9d3ef;font-weight:bold}
tr.ok td.r{background:#cfe8c4}small{color:#777}p{max-width:900px}a{color:#46c}</style>
<p><a href="/">← editor</a> · vermelho = forte demais, azul = fraca, verde = no ponto (razão 0,80–1,20)</p>%s</html>""" % "\n".join(out)


class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
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
        if p == "/api/cards":
            return self._send(200, load_all())
        if p == "/duelo":
            return self._send(200, duel_page(), "text/html; charset=utf-8")
        if p.startswith("/art/"):
            name = os.path.basename(p[5:])
            path = os.path.join(ART, name)
            if name.endswith(".png") and os.path.exists(path):
                with open(path, "rb") as f:
                    return self._send(200, f.read(), "image/png")
        return self._send(404, {"erro": "não achei"})

    def do_POST(self):
        # Só aceita a própria página (evita que outro site no navegador grave aqui).
        origin = self.headers.get("Origin", "")
        if origin and origin not in ("http://127.0.0.1:%d" % PORT, "http://localhost:%d" % PORT):
            return self._send(403, {"erro": "origem não permitida"})
        n = int(self.headers.get("Content-Length", "0"))
        try:
            body = json.loads(self.rfile.read(n) or b"{}")
            if self.path == "/api/save":
                return self._send(200, {"ok": True, "mudou": apply_changes(body.get("changes", {}))})
            if self.path == "/api/request":
                items = _requests()
                cid, text = body.get("id", ""), body.get("text", "").strip()
                items = [r for r in items if not (r["id"] == cid and r.get("status") == "pendente")]
                if text:
                    items.append({"id": cid, "texto": text, "status": "pendente",
                                  "data": datetime.datetime.now().strftime("%Y-%m-%d %H:%M")})
                _save_requests(items)
                return self._send(200, {"ok": True, "requests": items})
        except Exception as e:  # noqa: BLE001 - erro volta para a página
            return self._send(400, {"erro": str(e)})
        return self._send(404, {"erro": "não achei"})


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else PORT
    PORT = port
    print("Editor de cartas em http://127.0.0.1:%d" % port, flush=True)
    ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
