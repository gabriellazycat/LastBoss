#!/usr/bin/env python3
"""Exporta as cartas dos viloes (docs/decisoes_2026-11-10/CARTAS_VILOES.md)
para a aba "Vilões 10-11 - Cartas" da planilha "Revisao do conteudo - Last Boss.xlsx".

Uso (na raiz do projeto):
    python -I tools/export_cards_xlsx.py

Outras abas nao sao alteradas. Se a planilha estiver aberta no Excel, o script
avisa e sai com codigo 1, sem criar outro arquivo.
"""
import re
import sys
from pathlib import Path

from openpyxl import load_workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

ROOT = Path(__file__).resolve().parent.parent
MD_PATH = ROOT / "docs" / "decisoes_2026-11-10" / "CARTAS_VILOES.md"
XLSX_PATH = ROOT / "Revisao do conteudo - Last Boss.xlsx"
SHEET_TITLE = "Vilões 10-11 - Cartas"

EXPECTED = {"Rainha da Praga": 24, "Dragão Avarento": 24, "Lich": 24, "Comum": 12}
SECTION_PREFIX = {
    "## 1.": "Rainha da Praga",
    "## 2.": "Dragão Avarento",
    "## 3.": "Lich",
    "## 4.": "Comum",
}
RARITY = {"C": "Comum", "U": "Incomum", "R": "Rara", "L": "Lendária"}
HEADERS = [
    "Vilão", "#", "Carta", "Nova?", "Custo antigo", "Custo novo", "Raridade",
    "Tipo", "Efeito", "Papel no combo", "Modelo 3D próprio?",
    "Decisão (fica / muda / sai)", "Seu comentário",
]
WIDTHS = [18, 5, 28, 9, 13, 12, 12, 16, 70, 28, 16, 22, 40]
WRAP_COLS = {3, 8, 9, 10, 13}  # C, H, I, J, M (1-based)

FILL_HEADER = PatternFill("solid", fgColor="D9D9D9")
FILL_NEW = PatternFill("solid", fgColor="E2EFDA")
FILL_EDIT = PatternFill("solid", fgColor="FFF2CC")
EMOJI_BONE = "\U0001F9B4"  # 🦴


def clean(text):
    """Remove marcacoes markdown e espacos extras."""
    text = text.replace("**", "").replace("*", "")
    return re.sub(r"\s+", " ", text).strip()


def parse_cost(raw, carta):
    """Retorna (nova, custo_antigo, custo_novo)."""
    m = re.fullmatch(r"\*\*N\*\*\s*(\d+)", raw.strip())
    if m:
        return True, None, int(m.group(1))
    m = re.fullmatch(r"(\d+)\s*→\s*(\d+)", raw.strip())
    if m:
        return False, int(m.group(1)), int(m.group(2))
    raise ValueError(f"custo nao reconhecido na carta '{carta}': {raw!r}")


def read_cards():
    text = MD_PATH.read_text(encoding="utf-8")
    cards = []
    section = None
    for line in text.splitlines():
        if line.startswith("## "):
            section = None
            for prefix, vilao in SECTION_PREFIX.items():
                if line.startswith(prefix):
                    section = vilao
            continue
        if section is None or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not cells or not cells[0].isdigit():
            continue  # cabecalho ou separador
        if section == "Comum":
            if len(cells) != 6:
                raise ValueError(f"linha Comuns com {len(cells)} colunas: {line}")
            num, nome, custo, rar, tipo, efeito = cells
            papel = ""
        else:
            if len(cells) != 7:
                raise ValueError(f"linha {section} com {len(cells)} colunas: {line}")
            num, nome, custo, rar, tipo, efeito, papel = cells
        bone = EMOJI_BONE in nome
        nome_limpo = clean(nome.replace(EMOJI_BONE, ""))
        nova, antigo, novo = parse_cost(custo, nome_limpo)
        if rar not in RARITY:
            raise ValueError(f"raridade desconhecida '{rar}' em '{nome_limpo}'")
        cards.append({
            "vilao": section,
            "num": int(num),
            "nome": nome_limpo,
            "nova": nova,
            "antigo": antigo,
            "novo": novo,
            "raridade": RARITY[rar],
            "tipo": clean(tipo),
            "efeito": clean(efeito),
            "papel": clean(papel),
            "bone": bone,
        })
    return cards


def check_counts(cards):
    counts = {v: 0 for v in EXPECTED}
    for c in cards:
        counts[c["vilao"]] += 1
    for vilao, esperado in EXPECTED.items():
        if counts[vilao] != esperado:
            print(f"AVISO: {vilao} tem {counts[vilao]} cartas (esperado {esperado})")
    total = len(cards)
    if total != 84:
        print(f"AVISO: total de cartas {total} (esperado 84)")
    return counts


def build_sheet(wb, cards):
    if SHEET_TITLE in wb.sheetnames:
        del wb[SHEET_TITLE]
    ws = wb.create_sheet(SHEET_TITLE)

    for col, header in enumerate(HEADERS, start=1):
        cell = ws.cell(row=1, column=col, value=header)
        cell.font = Font(bold=True)
        cell.fill = FILL_HEADER
        cell.alignment = Alignment(vertical="center", wrap_text=True)
    for col, width in enumerate(WIDTHS, start=1):
        ws.column_dimensions[get_column_letter(col)].width = width

    for row_idx, c in enumerate(cards, start=2):
        values = [
            c["vilao"], c["num"], c["nome"],
            "sim" if c["nova"] else "não",
            c["antigo"], c["novo"], c["raridade"], c["tipo"], c["efeito"],
            c["papel"] or None,
            "sim" if c["bone"] else "não",
            None, None,
        ]
        for col, value in enumerate(values, start=1):
            cell = ws.cell(row=row_idx, column=col, value=value)
            cell.alignment = Alignment(
                vertical="top", wrap_text=col in WRAP_COLS
            )
            if c["nova"] and col <= 11:
                cell.fill = FILL_NEW
        if c["antigo"] is not None and c["antigo"] != c["novo"]:
            ws.cell(row=row_idx, column=6).font = Font(bold=True)
        if c["nova"]:
            ws.cell(row=row_idx, column=6).font = Font(bold=True)
        ws.cell(row=row_idx, column=12).fill = FILL_EDIT
        ws.cell(row=row_idx, column=13).fill = FILL_EDIT

    last_row = len(cards) + 1
    ws.freeze_panes = "A2"
    ws.auto_filter.ref = f"A1:{get_column_letter(len(HEADERS))}{last_row}"
    return ws


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass

    cards = read_cards()
    check_counts(cards)
    print(f"Cartas lidas do .md: {len(cards)}")

    wb = load_workbook(XLSX_PATH)
    abas_antes = len(wb.sheetnames)
    ja_existia = SHEET_TITLE in wb.sheetnames
    build_sheet(wb, cards)

    try:
        wb.save(XLSX_PATH)
    except PermissionError:
        print(
            "ERRO: nao foi possivel salvar a planilha (PermissionError).\n"
            f"Feche '{XLSX_PATH.name}' no Excel e rode o script de novo.\n"
            "Nenhum arquivo foi criado.",
            file=sys.stderr,
        )
        sys.exit(1)

    abas_depois = len(wb.sheetnames)
    print(f"Aba '{SHEET_TITLE}' {'recriada' if ja_existia else 'criada'}.")
    print(f"Abas antes: {abas_antes}, depois: {abas_depois}")
    print(f"Salvo em: {XLSX_PATH}")


if __name__ == "__main__":
    main()
