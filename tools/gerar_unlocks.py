"""Converte tools/desbloqueios.json (escolha do jogador no editor) em:
  data/unlocks.json            cartas liberadas desde o início + desafio estruturado de cada carta bloqueada
  locale/strings.csv           linhas UNLOCK_<id> (pt, en) com o texto do desafio
Uso (na raiz do projeto): python tools/gerar_unlocks.py
Rode de novo depois de mudar os desafios no editor (tools/escolher_base.html -> Copiar JSON -> atualizar desbloqueios.json)."""
import json, os, re, csv, io, sys

R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (regex do texto em português, tipo, parâmetros (grupos -> chaves), texto em inglês com {1} {2}...)
FAM = {  # nome da família no texto -> chave usada pelo jogo
    "monstros seus": "monster", "monstros": "monster", "ratos": "rat", "morcegos": "bat", "esqueletos": "skeleton",
    "mortos-vivos": "undead", "monstros de Fogo": "fire_monster", "bichos de Bando": "pack", "Feras": "beast",
    "estruturas": "structure", "feitiços": "spell", "feitiços de Fogo": "fire_spell", "feitiços de Sombra": "shadow_spell",
    "cartas de Bando": "pack_card", "cartas Temporárias": "lair", "cartas": "any",
}
PATTERNS = [
    (r"Tenha (\d+) (monstros seus|monstros de Fogo|ratos|morcegos|esqueletos|mortos-vivos|estruturas|bichos de Bando) em campo ao mesmo tempo",
     "peak", lambda m: {"fam": FAM[m[2]], "n": int(m[1])}, "Have {1} {F2} on the field at once"),
    (r"Tenha (\d+) Feras e (\d+) ratos em campo ao mesmo tempo", "peak_multi",
     lambda m: {"reqs": {"beast": int(m[1]), "rat": int(m[2])}}, "Have {1} Beasts and {2} rats on the field at once"),
    (r"Tenha (\d+) bichos de Bando em campo ao jogar um feitiço", "peak_on_spell",
     lambda m: {"fam": "pack", "n": int(m[1])}, "Have {1} Pack creatures on the field when you play a spell"),
    (r"Jogue (\d+) (monstros|estruturas|Feras|feitiços de Fogo|feitiços de Sombra|feitiços|cartas de Bando|cartas Temporárias|cartas) numa mesma fase",
     "plays", lambda m: {"fam": FAM[m[2]], "n": int(m[1])}, "Play {1} {F2} in a single phase"),
    (r"Use a mesma carta de monstro (\d+) vezes numa mesma fase", "plays_same", lambda m: {"n": int(m[1])},
     "Play the same monster card {1} times in a single phase"),
    (r"Jogue (\d+) (cartas|feitiços de Sombra|feitiços) em (\d+) segundos", "plays_window",
     lambda m: {"fam": FAM[m[2]], "n": int(m[1]), "s": float(m[3])}, "Play {1} {F2} within {3} seconds"),
    (r"Cause (\d+) de dano ao herói em menos de (\d+) segundos", "burst", lambda m: {"n": int(m[1]), "s": float(m[2])},
     "Deal {1} damage to the hero in under {2} seconds"),
    (r"Encharque o herói e incendeie-o em até (\d+) segundos?", "soak_ignite", lambda m: {"s": float(m[1])},
     "Soak the hero and set them on fire within {1} second(s)"),
    (r"Vença a primeira fase", "win_phase", lambda m: {"phase": 1}, "Win the first phase"),
    (r"Vença a segunda fase", "win_phase", lambda m: {"phase": 2}, "Win the second phase"),
    (r"Vença (\d+) fases com este vilão", "wins", lambda m: {"n": int(m[1])}, "Win {1} phases with this villain"),
    (r"Derrote (\d+) heróis no total", "heroes", lambda m: {"n": int(m[1]), "total": True}, "Defeat {1} heroes in total"),
    (r"Vença (\d+) fases sem jogar estruturas", "win_without", lambda m: {"fam": "structure", "runs": int(m[1])},
     "Win {1} phases without playing structures"),
    (r"Termine (\d+) fases com (\d+) de ouro", "gold_end", lambda m: {"n": int(m[2]), "runs": int(m[1])},
     "Finish {1} phases with {2} gold"),
    (r"Vença uma fase sem jogar estruturas", "win_without", lambda m: {"fam": "structure"}, "Win a phase without playing structures"),
    (r"Vença uma fase jogando só (\d+) feitiços", "win_max", lambda m: {"fam": "spell", "n": int(m[1])},
     "Win a phase playing only {1} spells"),
    (r"Derrote um herói perdendo no máximo (\d+) monstros", "loss_max", lambda m: {"n": int(m[1])},
     "Defeat a hero while losing at most {1} monsters"),
    (r"Derrote o herói sem perder nenhum monstro", "no_loss", lambda m: {}, "Defeat a hero without losing a single monster"),
    (r"Faça (\d+) (ratos|dos seus monstros) morrerem numa mesma fase", "died",
     lambda m: {"fam": "rat" if m[2] == "ratos" else "monster", "n": int(m[1])},
     "Have {1} of your {F2} die in a single phase"),
    (r"Aplique (\d+) acúmulos de Peste no herói ao mesmo tempo", "peste", lambda m: {"n": int(m[1])},
     "Stack {1} Plague on the hero at once"),
    (r"Aplique (\d+) Maldições no herói numa mesma fase", "curses", lambda m: {"n": int(m[1])},
     "Put {1} Curses on the hero in a single phase"),
    (r"Termine uma fase com (\d+) de ouro", "gold_end", lambda m: {"n": int(m[1])}, "Finish a phase with {1} gold"),
    (r"Gaste (\d+) de ouro numa mesma fase", "gold_spent", lambda m: {"n": int(m[1])}, "Spend {1} gold in a single phase"),
    (r"Ganhe (\d+) de ouro numa mesma fase", "gold_earned", lambda m: {"n": int(m[1])}, "Earn {1} gold in a single phase"),
    (r"Gaste (\d+) de Elixir numa mesma fase", "elixir_spent", lambda m: {"n": int(m[1])}, "Spend {1} Elixir in a single phase"),
    (r"Tenha (\d+) de Elixir máximo", "elixir_max", lambda m: {"n": int(m[1])}, "Reach {1} maximum Elixir"),
    (r"Mantenha o herói Encharcado por (\d+) segundos numa mesma fase", "soaked_time", lambda m: {"s": float(m[1])},
     "Keep the hero Soaked for {1} seconds in a single phase"),
    (r"Queime o herói por (\d+) segundos numa mesma fase", "burn_time", lambda m: {"s": float(m[1])},
     "Burn the hero for {1} seconds in a single phase"),
    (r"Faça o herói parar nas Moedas Malditas (\d+) vezes numa mesma fase", "coins", lambda m: {"n": int(m[1])},
     "Make the hero stop at the Cursed Coins {1} times in a single phase"),
    (r"Acerte o herói com (\d+) feitiços diferentes numa mesma fase", "spells_distinct", lambda m: {"n": int(m[1])},
     "Hit the hero with {1} different spells in a single phase"),
]
EN_FAM = {"monster": "monsters", "rat": "rats", "bat": "bats", "skeleton": "skeletons", "undead": "undead", "fire_monster": "Fire monsters",
          "pack": "Pack creatures", "beast": "Beasts", "structure": "structures", "spell": "spells", "fire_spell": "Fire spells",
          "shadow_spell": "Shadow spells", "pack_card": "Pack cards", "lair": "Temporary cards", "any": "cards"}

# Entre fases (15/11/2026). "... no total": soma o valor de todas as fases (só tipos que somam).
# "... em N fases diferentes": o feito de uma fase, cumprido em N fases.
ADDITIVE = {"plays", "died", "gold_spent", "gold_earned", "elixir_spent", "soaked_time", "burn_time", "coins"}
NO_RUNS = {"wins", "win_phase", "heroes"}


def parse(text):
    """Texto do desafio -> (spec, texto em inglês), ou (None, None) se nenhum padrão casa."""
    spec, en = _parse_base(text)
    if spec:
        return spec, en
    m = re.fullmatch(r"(.+?) no total", text)
    if m:
        spec, en = _parse_base(m[1] + " numa mesma fase")
        if spec and spec["kind"] in ADDITIVE:
            spec["total"] = True
            return spec, en.replace(" in a single phase", " in total")
    m = re.fullmatch(r"(.+?),? em (\d+) fases diferentes", text)
    if m:
        spec, en = _parse_base(m[1])
        if spec and spec["kind"] not in NO_RUNS and int(m[2]) >= 2:
            spec["runs"] = int(m[2])
            return spec, en + ", in %s different phases" % m[2]
    return None, None


def cross_run(spec):
    """Desafio entre runs (impossível numa run só)?"""
    return bool(spec.get("total") or spec.get("runs") or spec["kind"] == "wins" and spec.get("n", 1) >= 2)


def _parse_base(text):
    for rx, kind, f, en in PATTERNS:
        m = re.fullmatch(rx, text)
        if m:
            g = (None,) + m.groups()
            p = f(g)
            e = en
            for i in range(1, len(g)):
                e = e.replace("{%d}" % i, str(g[i]))
            e = e.replace("{F2}", EN_FAM.get(p.get("fam", ""), str(g[2]) if len(g) > 2 else ""))
            if kind == "died": e = e.replace("of your monsters", "of your monsters")
            return dict({"kind": kind}, **p), e
    return None, None

def load_src():
    return json.load(open(os.path.join(R, "tools", "desbloqueios.json"), encoding="utf8"))


def main():
    SRC = load_src()
    # cartas e donos
    owner = {}
    for f in ["cards", "cards_common", "cards_plague", "cards_dragon", "cards_lich"]:
        for c in json.load(open(os.path.join(R, "data", f + ".json"), encoding="utf8"))["cards"]:
            owner[c["id"]] = c["owner"]

    free, ch, texts, bad = set(), {}, {}, []
    for vid in ("plague", "dragon", "lich"):
        base = set(SRC[vid]["start_deck"])
        for cid, x in SRC[vid]["unlocks"].items():
            if x == "F":
                free.add(cid)
            else:
                t = x[2:]
                spec, en = parse(t)
                if spec is None:
                    bad.append((vid, cid, t)); continue
                if cid in ch and texts[cid][0] != t:
                    bad.append((vid, cid, "texto diferente entre classes: %r x %r" % (texts[cid][0], t)))
                ch[cid] = spec; texts[cid] = (t, en)
    # carta comum: mesmo estado nas três classes
    for cid in list(ch):
        if cid in free: bad.append(("-", cid, "livre e bloqueada ao mesmo tempo"))
    if bad:
        for b in bad: print("ERRO", *b)
        return 1

    base_all = sorted({c for v in ("plague", "dragon", "lich") for c in SRC[v]["start_deck"]})
    out = {"_doc": "Gerado por tools/gerar_unlocks.py a partir de tools/desbloqueios.json. free = cartas liberadas desde o início "
                   "(podem ser sorteadas nas ofertas); challenges = desafio que libera cada carta bloqueada (texto em UNLOCK_<id>). "
                   "Fase = uma run inteira; contadores 'numa mesma fase' zeram a cada fase. total = soma entre fases (carta de vilão: "
                   "só as fases com ele; comum: todas); runs = em quantas fases diferentes o feito aconteceu.",
           "free": sorted(free), "challenges": {k: ch[k] for k in sorted(ch)}}
    json.dump(out, open(os.path.join(R, "data", "unlocks.json"), "w", encoding="utf8", newline="\n"), ensure_ascii=False, indent=1)

    # strings.csv: troca as linhas UNLOCK_*
    p = os.path.join(R, "locale", "strings.csv")
    raw = open(p, encoding="utf8", newline="").read()
    eol = "\r\n" if "\r\n" in raw else "\n"
    lines = [l for l in raw.split(eol) if not l.startswith("UNLOCK_")]
    while lines and lines[-1] == "": lines.pop()
    for cid in sorted(texts):
        pt, en = texts[cid]
        row = io.StringIO(); csv.writer(row, lineterminator="").writerow(["UNLOCK_" + cid, pt, en])
        lines.append(row.getvalue())
    open(p, "w", encoding="utf8", newline="").write(eol.join(lines) + eol)
    print("ok:", len(free), "livres,", len(ch), "desafios;", len(texts), "textos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
