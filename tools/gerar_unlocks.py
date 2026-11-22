"""Converte tools/desbloqueios.json (escolha do jogador no editor) em:
  data/unlocks.json            cartas liberadas desde o início + desafio estruturado de cada carta bloqueada
  data/relics.json             campos "free" (reliquia livre) e "challenge" (desafio estruturado) de cada reliquia
  locale/strings.csv           linhas UNLOCK_<id> e UNLOCK_relic_<id> (pt, en) com o texto do desafio (trocadas no lugar)
Uso (na raiz do projeto): python tools/gerar_unlocks.py
Rode de novo depois de mudar os desafios no editor (tools/desafios_editor).
Plano 21/11/2026: a fase virou a RUN inteira (15 parties). Textos: "numa mesma run", "em N runs diferentes",
"Derrote a party N"."""
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
    (r"Jogue (\d+) (monstros|estruturas|Feras|feitiços de Fogo|feitiços de Sombra|feitiços|cartas de Bando|cartas Temporárias|cartas) numa mesma run",
     "plays", lambda m: {"fam": FAM[m[2]], "n": int(m[1])}, "Play {1} {F2} in a single run"),
    (r"Use a mesma carta de monstro (\d+) vezes numa mesma run", "plays_same", lambda m: {"n": int(m[1])},
     "Play the same monster card {1} times in a single run"),
    (r"Jogue (\d+) (cartas|feitiços de Sombra|feitiços) em (\d+) segundos", "plays_window",
     lambda m: {"fam": FAM[m[2]], "n": int(m[1]), "s": float(m[3])}, "Play {1} {F2} within {3} seconds"),
    (r"Cause (\d+) de dano ao herói em menos de (\d+) segundos", "burst", lambda m: {"n": int(m[1]), "s": float(m[2])},
     "Deal {1} damage to the hero in under {2} seconds"),
    (r"Encharque o herói e incendeie-o em até (\d+) segundos?", "soak_ignite", lambda m: {"s": float(m[1])},
     "Soak the hero and set them on fire within {1} second(s)"),
    # Parties (plano 21/11/2026): o recorde de parties derrubadas numa run (com `mine`: com o vilão jogado).
    (r"Derrote a party (\d+) com este vilão", "party", lambda m: {"party": int(m[1]), "mine": True},
     "Defeat party {1} with this villain"),
    (r"Derrote a party (\d+) sem jogar estruturas", "party_without", lambda m: {"fam": "structure", "party": int(m[1])},
     "Defeat party {1} without playing structures"),
    (r"Derrote a party (\d+) jogando só (\d+) feitiços", "party_max",
     lambda m: {"fam": "spell", "party": int(m[1]), "n": int(m[2])}, "Defeat party {1} playing only {2} spells"),
    (r"Derrote a party (\d+)", "party", lambda m: {"party": int(m[1])}, "Defeat party {1}"),
    (r"Derrote (\d+) heróis no total", "heroes", lambda m: {"n": int(m[1]), "total": True}, "Defeat {1} heroes in total"),
    (r"Termine (\d+) runs com (\d+) de ouro", "gold_end", lambda m: {"n": int(m[2]), "runs": int(m[1])},
     "Finish {1} runs with {2} gold"),
    (r"Derrote um herói perdendo no máximo (\d+) monstros", "loss_max", lambda m: {"n": int(m[1])},
     "Defeat a hero while losing at most {1} monsters"),
    (r"Derrote o herói sem perder nenhum monstro", "no_loss", lambda m: {}, "Defeat a hero without losing a single monster"),
    (r"Faça (\d+) (ratos|dos seus monstros) morrerem numa mesma run", "died",
     lambda m: {"fam": "rat" if m[2] == "ratos" else "monster", "n": int(m[1])},
     "Have {1} of your {F2} die in a single run"),
    (r"Aplique (\d+) acúmulos de Peste no herói ao mesmo tempo", "peste", lambda m: {"n": int(m[1])},
     "Stack {1} Plague on the hero at once"),
    (r"Aplique (\d+) Maldições no herói numa mesma run", "curses", lambda m: {"n": int(m[1])},
     "Put {1} Curses on the hero in a single run"),
    (r"Termine uma run com (\d+) de ouro", "gold_end", lambda m: {"n": int(m[1])}, "Finish a run with {1} gold"),
    (r"Gaste (\d+) de ouro numa mesma run", "gold_spent", lambda m: {"n": int(m[1])}, "Spend {1} gold in a single run"),
    (r"Ganhe (\d+) de ouro numa mesma run", "gold_earned", lambda m: {"n": int(m[1])}, "Earn {1} gold in a single run"),
    (r"Gaste (\d+) de Elixir numa mesma run", "elixir_spent", lambda m: {"n": int(m[1])}, "Spend {1} Elixir in a single run"),
    (r"Tenha (\d+) de Elixir máximo", "elixir_max", lambda m: {"n": int(m[1])}, "Reach {1} maximum Elixir"),
    (r"Mantenha o herói Encharcado por (\d+) segundos numa mesma run", "soaked_time", lambda m: {"s": float(m[1])},
     "Keep the hero Soaked for {1} seconds in a single run"),
    (r"Queime o herói por (\d+) segundos numa mesma run", "burn_time", lambda m: {"s": float(m[1])},
     "Burn the hero for {1} seconds in a single run"),
    (r"Faça o herói parar nas Moedas Malditas (\d+) vezes numa mesma run", "coins", lambda m: {"n": int(m[1])},
     "Make the hero stop at the Cursed Coins {1} times in a single run"),
    (r"Acerte o herói com (\d+) feitiços diferentes numa mesma run", "spells_distinct", lambda m: {"n": int(m[1])},
     "Hit the hero with {1} different spells in a single run"),
]
EN_FAM = {"monster": "monsters", "rat": "rats", "bat": "bats", "skeleton": "skeletons", "undead": "undead", "fire_monster": "Fire monsters",
          "pack": "Pack creatures", "beast": "Beasts", "structure": "structures", "spell": "spells", "fire_spell": "Fire spells",
          "shadow_spell": "Shadow spells", "pack_card": "Pack cards", "lair": "Temporary cards", "any": "cards"}

# Entre runs. "... no total": soma o valor de todas as runs (só tipos que somam).
# "... em N runs diferentes": o feito de uma run, cumprido em N runs.
ADDITIVE = {"plays", "died", "gold_spent", "gold_earned", "elixir_spent", "soaked_time", "burn_time", "coins"}
NO_RUNS = {"heroes", "party"}


def parse(text):
    """Texto do desafio -> (spec, texto em inglês), ou (None, None) se nenhum padrão casa."""
    spec, en = _parse_base(text)
    if spec:
        return spec, en
    m = re.fullmatch(r"(.+?) no total", text)
    if m:
        spec, en = _parse_base(m[1] + " numa mesma run")
        if spec and spec["kind"] in ADDITIVE:
            spec["total"] = True
            return spec, en.replace(" in a single run", " in total")
    m = re.fullmatch(r"(.+?),? em (\d+) runs diferentes", text)
    if m:
        spec, en = _parse_base(m[1])
        if spec and spec["kind"] not in NO_RUNS and int(m[2]) >= 2:
            spec["runs"] = int(m[2])
            return spec, en + ", in %s different runs" % m[2]
    return None, None


def cross_run(spec):
    """Desafio entre runs (impossível numa run só)?"""
    return bool(spec.get("total") or spec.get("runs"))


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
            return dict({"kind": kind}, **p), e
    return None, None


def load_src():
    return json.load(open(os.path.join(R, "tools", "desbloqueios.json"), encoding="utf8"))


def main():
    SRC = load_src()
    free, ch, texts, bad = set(), {}, {}, []
    for vid in ("plague", "dragon", "lich"):
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

    # reliquias
    relics_path = os.path.join(R, "data", "relics.json")
    relics = json.load(open(relics_path, encoding="utf8"))
    rel_src = SRC.get("relics", {})
    r_free, r_ch, r_texts = set(), {}, {}
    ids = [r["id"] for r in relics["relics"]]
    for rid in ids:
        x = rel_src.get(rid)
        if x is None:
            bad.append(("relics", rid, "reliquia sem estado em desbloqueios.json")); continue
        if x == "F":
            r_free.add(rid)
        else:
            spec, en = parse(x[2:])
            if spec is None:
                bad.append(("relics", rid, x[2:])); continue
            r_ch[rid] = spec; r_texts["relic_" + rid] = (x[2:], en)
    for rid in rel_src:
        if rid not in ids:
            bad.append(("relics", rid, "id que nao existe em data/relics.json"))
    if bad:
        for b in bad: print("ERRO", *b)
        return 1

    out = {"_doc": "Gerado por tools/gerar_unlocks.py a partir de tools/desbloqueios.json. free = cartas liberadas desde o início "
                   "(podem ser sorteadas nas ofertas); challenges = desafio que libera cada carta bloqueada (texto em UNLOCK_<id>). "
                   "Run = uma partida inteira (15 parties); contadores 'numa mesma run' zeram a cada run. total = soma entre runs (carta de vilão: "
                   "só as runs com ele; comum: todas); runs = em quantas runs diferentes o feito aconteceu; party = recorde de parties derrubadas. "
                   "As reliquias guardam free/challenge no proprio data/relics.json (texto em UNLOCK_relic_<id>).",
           "free": sorted(free), "challenges": {k: ch[k] for k in sorted(ch)}}
    json.dump(out, open(os.path.join(R, "data", "unlocks.json"), "w", encoding="utf8", newline="\n"), ensure_ascii=False, indent=1)

    for r in relics["relics"]:
        r.pop("free", None); r.pop("challenge", None)
        if r["id"] in r_free:
            r["free"] = True
        else:
            r["challenge"] = r_ch[r["id"]]
    json.dump(relics, open(relics_path, "w", encoding="utf8", newline="\n"), ensure_ascii=False, indent=1)

    # strings.csv: troca as linhas UNLOCK_* NO LUGAR (nao empurra para o fim do arquivo, atras dos blocos das outras frentes)
    texts.update(r_texts)
    p = os.path.join(R, "locale", "strings.csv")
    raw = open(p, encoding="utf8", newline="").read()
    eol = "\r\n" if "\r\n" in raw else "\n"
    lines = raw.split(eol)
    while lines and lines[-1] == "": lines.pop()
    new_rows = []
    for cid in sorted(texts):
        pt, en = texts[cid]
        row = io.StringIO(); csv.writer(row, lineterminator="").writerow(["UNLOCK_" + cid, pt, en])
        new_rows.append(row.getvalue())
    first = next((i for i, l in enumerate(lines) if l.startswith("UNLOCK_")), None)
    kept = [l for l in lines if not l.startswith("UNLOCK_")]
    if first is None:
        kept += new_rows
    else:
        before = len([l for l in lines[:first] if not l.startswith("UNLOCK_")])
        kept[before:before] = new_rows
    open(p, "w", encoding="utf8", newline="").write(eol.join(kept) + eol)
    print("ok:", len(free), "livres,", len(ch), "desafios;", len(r_free), "reliquias livres,", len(r_ch), "desafios de reliquia;", len(texts), "textos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
