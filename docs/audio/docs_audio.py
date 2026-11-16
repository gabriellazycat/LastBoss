# Gera assets/audio/LICENSES.txt, docs/audio/index.html e a tabela de docs/AUDIO.md a partir do manifesto
# da conversão e do dicionário SFX/MUSIC de game/audio.gd. Também confere: todo .ogg novo está no manifesto
# e todo arquivo citado em audio.gd existe.
# Uso: python -I docs_audio.py <manifest.json> <raiz do projeto>
import html, json, os, re, sys

MAN, ROOT = sys.argv[1:3]
man = json.load(open(MAN, encoding="utf-8"))
by_file = {m["file"]: m for m in man}
gd = open(os.path.join(ROOT, "game", "audio.gd"), encoding="utf-8").read()
adir = os.path.join(ROOT, "assets", "audio")

# ---- ids de efeito: "id": {"f": ["a", "b"], "db": -3.0, ...}
sfx_ids = []
for m in re.finditer(r'^\t"(\w+)": \{"f": \[([^\]]*)\], "db": (-?[\d.]+), "cd": ([\d.]+)(, "j": true)?\}', gd, re.M):
    files = [f.strip().strip('"') + ".ogg" for f in m.group(2).split(",")]
    sfx_ids.append((m.group(1), files, float(m.group(3)), float(m.group(4)), bool(m.group(5))))
music_ids = [(m.group(1), m.group(2) + ".ogg", m.group(3) == "true")
             for m in re.finditer(r'^\t"(music_\w+)": \["(\w+)", (true|false)\]', gd, re.M)]
amb_files = sorted(set(re.findall(r'"(amb_\w+)"', gd)))

# ---- conferência
errors = []
used = set()
for i, files, *_ in sfx_ids:
    for f in files:
        used.add(f)
        if f not in by_file or not os.path.isfile(os.path.join(adir, f)):
            errors.append("efeito %s: arquivo %s ausente" % (i, f))
for i, f, _ in music_ids:
    used.add(f)
    if f not in by_file or not os.path.isfile(os.path.join(adir, f)):
        errors.append("música %s: arquivo %s ausente" % (i, f))
for a in amb_files:
    used.add(a + ".ogg")
    if a + ".ogg" not in by_file:
        errors.append("ambiente %s ausente" % a)
for f in os.listdir(adir):
    if f.endswith(".ogg") and f not in by_file:
        errors.append("ogg fora do manifesto: " + f)
for f in by_file:
    if f not in used:
        errors.append("arquivo do manifesto sem uso no código: " + f)
print("ids de efeito:", len(sfx_ids), "| músicas:", len(music_ids), "| ambientes:", len(amb_files), "| arquivos:", len(man))
if errors:
    print("\n".join(errors))
    sys.exit(1)

CRLF = "\r\n"
# Ids que usam o arquivo de outro id (a descrição do manifesto é a do dono do arquivo).
ID_WHERE = {
    "curse": "o herói recebe uma maldição (Ev.CURSE); reaproveita a 2ª variação de spell_dark.",
    "victory": "id antigo \"victory\"; o fim da run agora toca music_victory (result_music).",
}
def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text.replace("\r\n", "\n").replace("\n", CRLF))

# ---- LICENSES.txt
lines = ["Áudio do Last Boss: licenças", "=" * 30, "",
         "Todos os arquivos .ogg desta pasta vêm do OpenGameArt.org com licença CC0 1.0 (domínio público,",
         "https://creativecommons.org/publicdomain/zero/1.0/), conferida na página de origem em 16/11/2026.",
         "Foram convertidos para Ogg Vorbis (ffmpeg): ganho estático, efeitos aparados e em mono, alguns loops",
         "com emenda cruzada. Crédito não é obrigatório pela CC0, mas fica registrado aqui.",
         "Os .wav antigos (sintetizados por tools/make_audio.py) ficam como reserva e não têm terceiros.", ""]
groups = {}
for m in man:
    groups.setdefault((m["author"], m["title"], m["url"]), []).append(m)
for (a, t, u), ms in groups.items():
    lines.append("%s (%s)" % (t, a))
    lines.append("  Origem: " + u)
    lines.append("  Licença: CC0 1.0")
    for m in ms:
        lines.append("  - %s  <- %s" % (m["file"], m["source_file"]))
    lines.append("")
write(os.path.join(adir, "LICENSES.txt"), "\n".join(lines))

# ---- tabela para docs/AUDIO.md
def src_md(m):
    return "[%s](%s) (%s)" % (m["title"].replace("|", "/"), m["url"], m["author"])
md = ["| Contexto | Arquivo | Quando toca | Origem |", "|---|---|---|---|"]
for i, f, loop in music_ids:
    m = by_file[f]
    md.append("| `%s`%s | `%s` | %s | %s |" % (i, "" if loop else " (uma vez)", f, m["where"], src_md(m)))
for a in amb_files:
    m = by_file[a + ".ogg"]
    md.append("| ambiente | `%s.ogg` | %s | %s |" % (a, m["where"], src_md(m)))
md2 = ["| id | Arquivo(s) | Volume / recarga | Quando toca | Origem |", "|---|---|---|---|---|"]
for i, files, db, cd, j in sfx_ids:
    m = by_file[files[0]]
    if m["where"].startswith(i + ":"):
        where = m["where"].split(":", 1)[1].strip()
    elif i in ID_WHERE:
        where = ID_WHERE[i]
    else:
        raise SystemExit("id sem descrição: " + i)
    srcs = sorted(set(src_md(by_file[f]) for f in files))
    md2.append("| `%s`%s | %s | %+.0f dB / %.2f s | %s | %s |" % (i, " (jingle)" if j else "", ", ".join("`%s`" % f for f in files), db, cd, where, "; ".join(srcs)))
tables = "### Músicas e ambientes\n\n" + "\n".join(md) + "\n\n### Efeitos e jingles\n\n" + "\n".join(md2)
tpl = os.path.join(os.path.dirname(os.path.abspath(__file__)), "AUDIO_template.md")
if os.path.isfile(tpl):
    write(os.path.join(ROOT, "docs", "AUDIO.md"), open(tpl, encoding="utf-8").read().replace("{{TABELAS}}", tables))
    # Scripts e manifesto da conversão ficam junto da página de escuta (referência para regenerar).
    for f in ("build_audio.py", "docs_audio.py", "AUDIO_template.md"):
        write(os.path.join(ROOT, "docs", "audio", f), open(os.path.join(os.path.dirname(tpl), f), encoding="utf-8").read())
    write(os.path.join(ROOT, "docs", "audio", "manifest.json"), json.dumps(man, ensure_ascii=False, indent=1) + "\n")

# ---- docs/audio/index.html (página de escuta, sem dependências)
def row(label, m, extra=""):
    return ("<tr><td><code>%s</code>%s</td><td><audio controls preload=\"none\" src=\"../../assets/audio/%s\"></audio>"
            "<div class=\"f\">%s · %.1f s</div></td><td>%s</td><td>%s<br><a href=\"%s\">%s</a><br><span class=\"l\">CC0</span></td></tr>") % (
        html.escape(label), extra, m["file"], m["file"], m["duration"], html.escape(m["where"]),
        html.escape(m["author"]), m["url"], html.escape(m["title"]))
rows_m = [row(i, by_file[f], "" if loop else " <span class=\"t\">uma vez</span>") for i, f, loop in music_ids]
rows_a = [row(a, by_file[a + ".ogg"]) for a in amb_files]
rows_s = []
for i, files, db, cd, j in sfx_ids:
    for k, f in enumerate(files):
        rows_s.append(row(i if k == 0 else i + " · variação %d" % (k + 1), by_file[f], " <span class=\"t\">jingle</span>" if j and k == 0 else ""))
page = """<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Áudio do Last Boss</title>
<style>
:root { --bg: #f4ecd8; --ink: #2b2118; --soft: #6b5a45; --line: #d6c7a6; --acc: #7a2e1d; --card: #fbf6ea; }
@media (prefers-color-scheme: dark) { :root { --bg: #1d1914; --ink: #eadfc8; --soft: #b3a286; --line: #3a3127; --acc: #e08a6a; --card: #26211a; } }
body { margin: 0; background: var(--bg); color: var(--ink); font: 15px/1.45 Georgia, "Times New Roman", serif; }
main { max-width: 1100px; margin: 0 auto; padding: 24px 16px 60px; }
h1 { font-size: 28px; margin: 0 0 4px; } h2 { margin: 32px 0 8px; border-bottom: 2px solid var(--line); padding-bottom: 4px; }
p { color: var(--soft); max-width: 75ch; }
table { width: 100%%; border-collapse: collapse; background: var(--card); }
td { border-top: 1px solid var(--line); padding: 8px; vertical-align: top; }
td:first-child { width: 17%%; } td:nth-child(2) { width: 30%%; }
audio { width: 100%%; max-width: 300px; height: 32px; }
.f { font-size: 12px; color: var(--soft); } .l { font-size: 12px; color: var(--acc); }
.t { font-size: 11px; color: var(--acc); border: 1px solid var(--acc); border-radius: 3px; padding: 0 3px; margin-left: 4px; }
a { color: var(--acc); }
@media (max-width: 700px) { table, tbody, tr, td { display: block; width: auto !important; } tr { border-top: 1px solid var(--line); padding: 6px 0; } td { border: 0; padding: 3px 8px; } }
</style>
</head>
<body>
<main>
<h1>Áudio do Last Boss</h1>
<p>Todos os sons e músicas do jogo, com onde tocam, autor e licença (todos CC0, do OpenGameArt). Os arquivos
ficam em <code>assets/audio/</code>; o mapa id → arquivo está em <code>game/audio.gd</code> e em
<code>docs/AUDIO.md</code>. A escolha foi feita sem ouvir (por nome, duração, altura e volume): use esta página
para ouvir e trocar o que não servir.</p>
<h2>Músicas</h2>
<table>%s</table>
<h2>Ambientes</h2>
<p>Em loop, bem baixo, por baixo da música (ônibus SFX).</p>
<table>%s</table>
<h2>Efeitos e jingles</h2>
<p>Cada id sorteia uma das variações a cada toque; a recarga por id evita que centenas de unidades virem ruído.</p>
<table>%s</table>
</main>
</body>
</html>
""" % ("\n".join(rows_m), "\n".join(rows_a), "\n".join(rows_s))
write(os.path.join(ROOT, "docs", "audio", "index.html"), page)
print("ok: LICENSES.txt, docs/audio/index.html, audio_tables.md")
