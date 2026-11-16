"""Serve a tela de escolha dos modelos em guache e guarda a escolha.
python tools/art/escolher_g.py [porta]   ->   http://localhost:8769/escolher.html
A escolha vai para docs/modelos_guache/escolha.json (POST /escolher), que o jogo e as sessões podem ler."""
import json, os, sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "docs", "modelos_guache")
FILE = os.path.join(ROOT, "escolha.json")


class H(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=ROOT, **k)

    def do_GET(self):
        if self.path.split("?")[0] == "/escolha":
            if not os.path.exists(FILE):
                self.send_response(404); self.end_headers(); return
            data = open(FILE, "rb").read()
            self.send_response(200); self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data); return
        return super().do_GET()

    def do_POST(self):
        if self.path != "/escolher":
            self.send_response(404); self.end_headers(); return
        n = int(self.headers.get("Content-Length", 0))
        try:
            d = json.loads(self.rfile.read(n))
            out = {"escolhida": d.get("escolhida"), "comentarios": str(d.get("comentarios", ""))[:5000], "quando": d.get("quando")}
            json.dump(out, open(FILE, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
            self.send_response(204)
        except Exception:
            self.send_response(400)
        self.end_headers()

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8769
    print("http://localhost:%d/escolher.html" % port, flush=True)
    ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
