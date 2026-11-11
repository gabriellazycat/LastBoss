#!/usr/bin/env python3
"""Exporta as 84 cartas como estão no JSON (números finais, depois da calibração da Etapa E) para a aba
"Vilões - cartas (JSON)" da planilha "Revisao do conteudo - Last Boss.xlsx". Outras abas não mudam.
Uso (na raiz do projeto): python -I tools/export_cards_json_xlsx.py
Se a planilha estiver aberta no Excel, avisa e sai com código 1.
"""
import csv
import json
import sys
from pathlib import Path

from openpyxl import load_workbook
from openpyxl.styles import Alignment, Font, PatternFill

ROOT = Path(__file__).resolve().parent.parent
XLSX = ROOT / "Revisao do conteudo - Last Boss.xlsx"
SHEET = "Vilões - cartas (JSON)"
OWNERS = ["plague", "dragon", "lich", "common"]
OWNER_PT = {"plague": "Rainha da Praga", "dragon": "Dragão Avarento", "lich": "Lich", "common": "Comum"}
RAR = {"common": "C", "uncommon": "U", "rare": "R", "legendary": "L"}


def cards():
    out = []
    files = ["cards.json"] + ["cards_%s.json" % o for o in OWNERS]
    for f in files:
        p = ROOT / "data" / f
        if p.exists():
            for d in json.loads(p.read_text(encoding="utf-8"))["cards"]:
                d.setdefault("owner", f[6:-5] if f != "cards.json" else "common")
                out.append(d)
    return out


def texts():
    t = {}
    with open(ROOT / "locale" / "strings.csv", encoding="utf-8", newline="") as f:
        for row in csv.reader(f):
            if len(row) >= 2:
                t[row[0]] = row[1]
    return t


def main():
    tx = texts()
    rows = []
    for d in cards():
        fx = d.get("fx", {})
        rows.append([
            OWNER_PT.get(d["owner"], d["owner"]), d["id"], tx.get("CARD_" + d["id"], d["id"]),
            d.get("cost", ""), RAR.get(d.get("rarity", ""), d.get("rarity", "")), d.get("type", ""),
            d.get("hp", ""), d.get("dps", ""), d.get("count", ""),
            "sim" if fx.get("returns") else "", ", ".join(o.get("op", "") for o in d.get("ops", [])),
            json.dumps(fx, ensure_ascii=False)[:300], tx.get("DESC_" + d["id"], ""),
        ])
    rows.sort(key=lambda r: (["Rainha da Praga", "Dragão Avarento", "Lich", "Comum"].index(r[0]) if r[0] in OWNER_PT.values() else 9, r[3] if isinstance(r[3], int) else 99, r[1]))
    try:
        wb = load_workbook(XLSX)
    except PermissionError:
        print("A planilha está aberta no Excel: feche e rode de novo.")
        return 1
    if SHEET in wb.sheetnames:
        del wb[SHEET]
    ws = wb.create_sheet(SHEET)
    head = ["Dono", "id", "Carta", "Custo", "Rar.", "Tipo", "Vida", "Dano/s", "Qtd.", "Retorna", "ops", "fx (números)", "Texto (pt)"]
    ws.append(head)
    for c in ws[1]:
        c.font = Font(bold=True, color="FFFFFF")
        c.fill = PatternFill("solid", fgColor="5B3A29")
    for r in rows:
        ws.append(r)
    widths = [16, 18, 24, 7, 5, 10, 7, 7, 6, 8, 20, 60, 60]
    for i, w in enumerate(widths):
        ws.column_dimensions[chr(65 + i)].width = w
    for row in ws.iter_rows(min_row=2):
        for c in row:
            c.alignment = Alignment(vertical="top", wrap_text=c.column >= 11)
    ws.freeze_panes = "C2"
    try:
        wb.save(XLSX)
    except PermissionError:
        print("A planilha está aberta no Excel: feche e rode de novo.")
        return 1
    print("aba '%s': %d cartas" % (SHEET, len(rows)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
