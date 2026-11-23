"""Revisão visual da rodada (só na máquina local).

Uso (na raiz do projeto): python -I tools/revisao_visual/server.py   ->  http://127.0.0.1:8769

- Junta todos os docs/rodada_visual/*/itens.json (da raiz do projeto e das raízes extras listadas em
  tools/revisao_visual/fontes.json, uma lista de diretórios) e mostra cada item com antes/depois.
- Cada decisão (aprovar / rejeitar / comentário) grava na hora em tools/revisao_visual/aprovacoes.json.
- Opções para teste: --raiz <dir> (outra raiz do projeto; aprovacoes.json passa a ficar nela), --porta N.
"""
import argparse
import datetime
import glob
import json
import mimetypes
import os
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import quote, unquote

HERE = os.path.dirname(os.path.abspath(__file__))
PORT = 8769
ORDEM = ["Árvores e chão", "Cenário com propósito", "Modelos 3D", "Inimigos novos", "Estruturas novas", "Golpes e animações", "Efeitos", "Heróis", "Mundo vivo", "Luz e cor", "Arena", "Espaçamento da UI"]
EXT_OK = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".webm", ".mp4", ".ogv"}
LOCK = threading.Lock()
ROOTS = []          # diretórios raiz (reais)
STATE = HERE        # onde fica aprovacoes.json


def _real(p):
    return os.path.realpath(os.path.abspath(p))


def _fontes():
    fp = os.path.join(HERE, "fontes.json")
    extra = []
    if os.path.isfile(fp):
        try:
            with open(fp, encoding="utf-8") as f:
                extra = [str(x) for x in json.load(f)]
        except (ValueError, OSError):
            extra = []
    out = []
    for r in ROOTS + [_real(x) for x in extra]:
        if os.path.isdir(r) and r not in out:
            out.append(r)
    return out


def _inside(root, path):
    try:
        return os.path.commonpath([root, path]) == root
    except ValueError:
        return False


def _arquivos(root, idx, rels):
    """Resolve caminhos (aceita curinga) em URLs; devolve (urls, faltando)."""
    urls, falta = [], []
    for rel in rels or []:
        rel = str(rel).replace("\\", "/")
        if os.path.isabs(rel) or ".." in rel.split("/"):
            falta.append(rel)
            continue
        if any(c in rel for c in "*?["):
            hits = sorted(glob.glob(os.path.join(root, rel)))
        else:
            hits = [os.path.join(root, rel)]
        ok = [h for h in hits if os.path.isfile(h) and _inside(root, _real(h))
              and os.path.splitext(h)[1].lower() in EXT_OK]
        if not ok:
            falta.append(rel)
        for h in ok:
            r2 = os.path.relpath(_real(h), root).replace("\\", "/")
            urls.append("/f/%d/%s?m=%d" % (idx, quote(r2), int(os.path.getmtime(h))))
    return urls, falta


def _itens():
    itens, avisos = [], []
    for idx, root in enumerate(_fontes()):
        for fp in sorted(glob.glob(os.path.join(root, "docs", "rodada_visual", "*", "itens.json"))):
            try:
                with open(fp, encoding="utf-8") as f:
                    lista = json.load(f)
                assert isinstance(lista, list)
            except (ValueError, OSError, AssertionError) as e:
                avisos.append("%s: %s" % (fp, e))
                continue
            for it in lista:
                if not isinstance(it, dict) or not it.get("id"):
                    continue
                falta = []
                antes, f1 = _arquivos(root, idx, it.get("antes"))
                falta += f1
                var = {}
                for nome, lst in (it.get("variacoes") or {}).items():
                    u, f2 = _arquivos(root, idx, lst)
                    var[str(nome)] = u
                    falta += f2
                vid, f3 = _arquivos(root, idx, it.get("videos"))
                falta += f3
                m360, f4 = _arquivos(root, idx, it.get("modelo360"))
                falta += f4
                itens.append({"id": str(it["id"]), "frente": str(it.get("frente") or "Outros"),
                              "titulo": str(it.get("titulo") or it["id"]),
                              "descricao": str(it.get("descricao") or ""), "flag": str(it.get("flag") or ""),
                              "antes": antes, "variacoes": var, "videos": vid, "modelo360": m360,
                              "faltando": falta, "origem": os.path.basename(root)})
    frentes = sorted({i["frente"] for i in itens}, key=lambda f: (ORDEM.index(f) if f in ORDEM else 99, f))
    return {"itens": itens, "frentes": frentes, "avisos": avisos}


def _aprov_path():
    return os.path.join(STATE, "aprovacoes.json")


def _ler_aprov():
    try:
        with open(_aprov_path(), encoding="utf-8") as f:
            d = json.load(f)
        return d if isinstance(d, dict) else {}
    except (OSError, ValueError):
        return {}


def _gravar_aprov(d):
    tmp = _aprov_path() + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(d, f, ensure_ascii=False, indent=1)
    os.replace(tmp, _aprov_path())


def _decidir(body):
    iid = str(body.get("id", "")).strip()
    if not iid:
        return 400, {"error": "id ausente"}
    dec = body.get("decisao")
    with LOCK:
        d = _ler_aprov()
        if dec in (None, "", "pendente"):
            d.pop(iid, None)
        elif dec in ("aprovado", "rejeitado"):
            var = body.get("variacao")
            d[iid] = {"decisao": dec, "variacao": str(var) if var else None,
                      "comentario": str(body.get("comentario", ""))[:4000],
                      "quando": datetime.datetime.now().astimezone().isoformat(timespec="seconds")}
        else:
            return 400, {"error": "decisão inválida"}
        _gravar_aprov(d)
    return 200, {"ok": True, "aprovacoes": d}


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code, body, ctype="application/json; charset=utf-8", extra=None):
        if isinstance(body, (dict, list)):
            body = json.dumps(body, ensure_ascii=False).encode("utf-8")
        elif isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        try:
            self.wfile.write(body)
        except (ConnectionError, OSError):
            pass

    def _arquivo(self, p):
        partes = p[3:].split("/", 1)
        try:
            idx = int(partes[0])
            rel = unquote(partes[1])
        except (ValueError, IndexError):
            return self._send(404, {"error": "não encontrado"})
        fontes = _fontes()
        if idx < 0 or idx >= len(fontes) or "\\" in rel or "\x00" in rel or ".." in rel.split("/") \
                or os.path.isabs(rel) or rel.startswith("/"):
            return self._send(404, {"error": "não encontrado"})
        root = fontes[idx]
        fp = _real(os.path.join(root, rel))
        if not _inside(root, fp) or not os.path.isfile(fp) or os.path.splitext(fp)[1].lower() not in EXT_OK:
            return self._send(404, {"error": "não encontrado"})
        ctype = mimetypes.guess_type(fp)[0] or "application/octet-stream"
        size = os.path.getsize(fp)
        rng = self.headers.get("Range")
        start, end, code = 0, size - 1, 200
        if rng and rng.startswith("bytes="):
            try:
                a, b = rng[6:].split("-", 1)
                start = int(a) if a else max(0, size - int(b))
                end = min(int(b), size - 1) if (a and b) else size - 1
                if start > end:
                    raise ValueError
                code = 206
            except ValueError:
                return self._send(416, {"error": "faixa inválida"})
        with open(fp, "rb") as f:
            f.seek(start)
            data = f.read(end - start + 1)
        extra = {"Accept-Ranges": "bytes"}
        if code == 206:
            extra["Content-Range"] = "bytes %d-%d/%d" % (start, end, size)
        self._send(code, data, ctype, extra)

    def do_GET(self):
        p = self.path.split("?")[0]
        if p in ("/vitrine", "/vitrine.html"):
            with open(os.path.join(HERE, "vitrine.html"), "rb") as f:
                return self._send(200, f.read(), "text/html; charset=utf-8")
        if p in ("/", "/index.html"):
            with open(os.path.join(HERE, "index.html"), "rb") as f:
                return self._send(200, f.read(), "text/html; charset=utf-8")
        if p == "/api/itens":
            return self._send(200, _itens())
        if p == "/api/aprovacoes":
            return self._send(200, _ler_aprov())
        if p.startswith("/f/"):
            return self._arquivo(p)
        self._send(404, {"error": "não encontrado"})

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(n) or b"{}")
            assert isinstance(body, dict)
        except (ValueError, AssertionError):
            return self._send(400, {"error": "JSON inválido"})
        if self.path == "/api/decidir":
            code, out = _decidir(body)
            return self._send(code, out)
        self._send(404, {"error": "não encontrado"})


def main():
    global STATE, PORT
    padrao = os.path.dirname(os.path.dirname(HERE))
    ap = argparse.ArgumentParser()
    ap.add_argument("--raiz", default=padrao)
    ap.add_argument("--porta", type=int, default=PORT)
    a = ap.parse_args()
    PORT = a.porta
    ROOTS.append(_real(a.raiz))
    if _real(a.raiz) != _real(padrao):
        STATE = ROOTS[0]
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), H)
    print("Revisão visual em http://127.0.0.1:%d  (Ctrl+C para sair)" % PORT)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
