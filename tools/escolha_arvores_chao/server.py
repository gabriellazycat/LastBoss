"""Página local para escolher as árvores e o chão da rodada de 22/11/2026 (docs/ARVORES_E_CHAO.md).

Uso (na raiz do projeto): python -I tools/escolha_arvores_chao/server.py  ->  http://127.0.0.1:8771
Serve index.html e img/ desta pasta; GET/POST /api/escolha lê e grava escolha.json aqui mesmo
({arvores, chao, nota, atualizado}). Só escuta em 127.0.0.1.
"""
import json
import os
import sys
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.path.join(HERE, "escolha.json")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8771
LOCK = threading.Lock()
KEYS = {"arvores", "chao", "nota", "atualizado"}


class H(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=HERE, **k)

    def _json(self, code, obj):
        b = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(b)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        if self.path.split("?")[0] == "/api/escolha":
            with LOCK:
                try:
                    with open(STATE, encoding="utf-8") as f:
                        return self._json(200, json.load(f))
                except (OSError, ValueError):
                    return self._json(200, {})
        if self.path.split("?")[0] in ("/escolha.json", "/server.py"):
            return self.send_error(404)
        return super().do_GET()

    def do_POST(self):
        if self.path.split("?")[0] != "/api/escolha":
            return self.send_error(404)
        n = int(self.headers.get("Content-Length") or 0)
        if n <= 0 or n > 20000:
            return self.send_error(400)
        try:
            d = json.loads(self.rfile.read(n).decode("utf-8"))
            assert isinstance(d, dict)
        except (ValueError, AssertionError):
            return self.send_error(400)
        d = {k: v for k, v in d.items() if k in KEYS}
        with LOCK:
            tmp = STATE + ".tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(d, f, ensure_ascii=False, indent=1)
            os.replace(tmp, STATE)
        print("escolha gravada:", json.dumps(d, ensure_ascii=False), flush=True)
        return self._json(200, {"ok": True})

    def log_message(self, fmt, *args):
        if self.command == "POST":
            super().log_message(fmt, *args)


if __name__ == "__main__":
    print("http://127.0.0.1:%d" % PORT, flush=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
