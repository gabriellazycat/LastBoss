"""Acabamento comum do lote praga_1 (e de qualquer composição no formato do BRIEF_AGENTES):
lê docs/arte_cartas/<lote>/comp/<id>.svg, aplica as transformações dos grupos, junta as peças de cada
data-fig numa silhueta (nanquim: um contorno contínuo por figura) e monta as aguadas por regiões visíveis
(ordem de pintura) para não haver emenda nem camada dupla dentro do corpo.

uso (design_<id>.py):
    from praga_common import build
    build("rat_king", "praga_1", cfg)      # cfg: ver abaixo; grava o JSON em sys.argv[1]

cfg (todas as chaves são opcionais):
  ink_bg   {regex_de_id: largura}   elementos do cenário que levam nanquim (a partir do primeiro, todo o
                                     cenário seguinte vira camada própria, na ordem de pintura)
  figs     {"fig_x": dict(dark=0..1, detail=True/False, order=[data-fig...], split={novo: [prefixos de id]},
                          w=largura do contorno)}
  enx_w    largura do traço do enxame (0 = sem nanquim)
  fx_alpha multiplicador do alfa das aguadas de efeito grandes (padrão 0.7; fogo/óleo pedem ~1.3)
  fx_lift  True: aguadas de efeito grandes cobrem o fundo (guache: fogo/óleo sobre fundo escuro)
  bg_lift  [regex de id]: peças do cenário (na parte com camada própria) em guache
  figs[..]['lift'] = [data-fig...]: figuras/partes em guache
  fx_hold  True: o nanquim do cenário some atrás das aguadas grandes de efeito (explosão sobre o vulcão)
  fx_dark  True para não converter efeitos em riscos (deixa tudo como aguada)
"""
import sys, os, re, math
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
import contourpy
from matplotlib.path import Path as MPath
from lib import *
from svgpath import sample, rdp, SC

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
PAD = 40
CW, CH = int((278 + 2 * PAD) * SC), int((267 + 2 * PAD) * SC)


# ---------------------------------------------------------------- cor
def rgb(c):
    c = c.lstrip("#")
    return np.array([int(c[i:i + 2], 16) for i in (0, 2, 4)], float)


def hexs(v):
    v = np.clip(np.round(v), 0, 255).astype(int)
    return "#%02x%02x%02x" % tuple(v)


def lum(c):
    r, g, b = rgb(c) / 255.0
    return 0.299 * r + 0.587 * g + 0.114 * b


def mixc(c, c2, t):
    return hexs(rgb(c) * (1 - t) + rgb(c2) * t)


# ---------------------------------------------------------------- SVG
def _matrix(tr):
    M = np.eye(3)
    for op, args in re.findall(r"(\w+)\(([^)]*)\)", tr or ""):
        a = [float(x) for x in re.split(r"[ ,]+", args.strip()) if x]
        T = np.eye(3)
        if op == "translate":
            T[0, 2], T[1, 2] = a[0], (a[1] if len(a) > 1 else 0)
        elif op == "rotate":
            r = math.radians(a[0]); T[:2, :2] = [[math.cos(r), -math.sin(r)], [math.sin(r), math.cos(r)]]
        elif op == "scale":
            T[0, 0], T[1, 1] = a[0], (a[1] if len(a) > 1 else a[0])
        M = M @ T
    return M


def _xf(M, P):
    P = np.asarray(P, float)
    return (P @ M[:2, :2].T + M[:2, 2]) - 11.0          # carta -> janela da moldura A


class Piece:
    pass


def load(svg):
    import xml.etree.ElementTree as ET
    txt = open(svg, encoding="utf-8").read().replace(' xmlns="http://www.w3.org/2000/svg"', "")
    root = ET.fromstring(txt)
    groups = []
    for g in root.findall("g"):
        gid = g.get("id")
        M = _matrix(g.get("transform"))
        scale = math.sqrt(abs(np.linalg.det(M[:2, :2])))
        pcs = []
        for e in g.iter("path"):
            if "guide" in (e.get("class") or ""):
                continue
            p = Piece()
            p.id = e.get("id"); p.fig = e.get("data-fig") or p.id
            fill = e.get("fill"); p.fill = None if fill in (None, "none") else fill
            p.op = float(e.get("opacity", 1)); p.stroke = e.get("stroke")
            p.sw = float(e.get("stroke-width", 1)) * scale
            p.inner = "inner" in (e.get("class") or "")
            subs = sample(e.get("d"))
            p.polys = [_xf(M, s) for s in subs if len(s) >= 3] if p.fill else []
            p.lines = [_xf(M, s) for s in subs if len(s) >= 2] if (p.stroke and not p.fill) else []
            pcs.append(p)
        groups.append((gid, scale, pcs))
    return groups


# ---------------------------------------------------------------- máscaras e contornos
NONZERO = False     # opcional (cfg nonzero_fill): preenche como o SVG (regra nonzero); padrao = PIL (par-impar)


def _mask_nz(polys):
    from matplotlib.path import Path as MPath
    out = np.zeros((CH, CW), bool)
    for p in polys:
        q = (np.asarray(p) + PAD) * SC
        if len(q) < 3:
            continue
        x0, y0 = np.floor(q.min(0)).astype(int); x1, y1 = np.ceil(q.max(0)).astype(int)
        x0, y0 = max(x0, 0), max(y0, 0); x1, y1 = min(x1 + 1, CW), min(y1 + 1, CH)
        if x1 <= x0 or y1 <= y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
        ins = MPath(q).contains_points(np.c_[gx.ravel(), gy.ravel()]).reshape(gx.shape)
        out[y0:y1, x0:x1] |= ins
    return out


def mask(polys):
    if NONZERO:
        return _mask_nz(polys)
    im = Image.new("L", (CW, CH), 0)
    dr = ImageDraw.Draw(im)
    for p in polys:
        q = (np.asarray(p) + PAD) * SC
        if len(q) >= 3:
            dr.polygon([tuple(x) for x in q], fill=255)
    return np.asarray(im) > 0


def _area(P):
    return 0.5 * np.sum(P[:-1, 0] * P[1:, 1] - P[1:, 0] * P[:-1, 1])


def contours(m, smooth=3, eps=0.25, minarea=0.8):
    """máscara -> (anéis externos, buracos) em coordenadas de arte, simplificados."""
    if not m.any():
        return [], []
    a = np.pad(ndi.gaussian_filter(m.astype(float), 0.9), 1)
    gen = contourpy.contour_generator(z=a)
    rings = []
    for seg in gen.lines(0.5):
        if len(seg) < 12:
            continue
        P = (seg - 1) / SC - PAD
        if smooth > 1:
            k = np.ones(smooth) / smooth
            Pp = np.vstack([P[-smooth:], P, P[:smooth]])
            P = np.c_[np.convolve(Pp[:, 0], k, "same"), np.convolve(Pp[:, 1], k, "same")][smooth:-smooth]
        P = rdp(P, eps)
        if abs(_area(P)) >= minarea:
            rings.append(P)
    if not rings:
        return [], []
    rings.sort(key=lambda r: -abs(_area(r)))
    sg = np.sign(_area(rings[0]))
    return [r for r in rings if np.sign(_area(r)) == sg], [r for r in rings if np.sign(_area(r)) != sg]


def ctr(S, L, P, **kw):
    P = np.asarray(P, float)
    if np.sum(np.linalg.norm(np.diff(P, axis=0), axis=1)) < 8:
        return
    S.contour(L, P, **kw)


def breaks_for(P):
    per = np.sum(np.linalg.norm(np.diff(P, axis=0), axis=1))
    n = int(np.clip(per / 55, 2, 5))
    return tuple(np.linspace(0, 1, n, endpoint=False) + 0.0)


def cluster_color(c, known, tol=14):
    v = rgb(c)
    for k in known:
        if np.max(np.abs(rgb(k) - v)) <= tol:
            return k
    known.append(c)
    return c


def alpha_for(color, op):
    L = lum(color)
    return float(np.clip(op * (0.9 - 0.35 * max(0.0, L - 0.55) / 0.45), 0.2, 0.92))


def is_opaque(color, op):
    return op >= 0.85 or lum(color) > 0.8


# ---------------------------------------------------------------- aguadas por região visível
def regions(pieces):
    """pieces em ordem de pintura: dict(polys, color, alpha, opaque, shade). Devolve
    [(chave, anéis, buracos, pixels)] com a parte VISÍVEL de cada cor (as mesmas cores viram uma só mancha)."""
    cover = np.zeros((CH, CW), bool)
    groups, order = {}, []
    if any(p.get("mixunder") for p in pieces):
        ms = [mask(p["polys"]) for p in pieces]
        for i, p in enumerate(pieces):
            if not p.get("mixunder"):
                continue
            best, ba = None, 0
            for j in range(i):
                if not pieces[j]["opaque"] and not pieces[j].get("mixed"):
                    continue
                ov = int((ms[i] & ms[j]).sum())
                if ov >= ba:
                    best, ba = j, ov
            if best is not None and ba > 0:
                u = pieces[best]
                p["color"] = mixc(u["color"], p["color"], min(1.0, p["op"]))
                p["alpha"] = u["alpha"]
            p["opaque"] = True; p["mixed"] = True
    for p in reversed(pieces):
        m = mask(p["polys"])
        vis = m & ~cover
        if p["opaque"]:
            cover |= m
        if vis.any():
            key = (p["color"], round(p["alpha"], 2), p.get("shade", 0.0))
            if key not in groups:
                groups[key] = np.zeros((CH, CW), bool)
            groups[key] |= vis
            p["_k"] = key
    seq = []
    for i, p in enumerate(pieces):
        k = p.get("_k")
        if k is not None and k not in seq:
            seq.append(k)
    out = []
    for k in seq:
        m = groups[k]
        o, h = contours(m)
        out.append((k, o, h, int(m.sum())))
    return out


def emit_washes(S, regs, z0, base=None, mis_cap=1.0, spill=0.9, shade_dark=None, light_cut=0.0, edge=1.0, lift=False):
    z = z0
    for key, outers, holes, px in regs:
        color, alpha, shade = key
        for r in outers:
            ar = abs(_area(r))
            small = ar < 60
            lum_ok = lum(color) > 0.86 and ar < 40
            if lum_ok:
                continue          # claro e pequeno (dente, garra): papel reservado
            mis = float(np.clip(math.sqrt(ar) / 22, 0.15, mis_cap))
            kw = dict(alpha=alpha, z=z, shade=shade, spill=(0.35 if small else spill), mis=mis,
                      knock=[h for h in holes if abs(_area(h)) > 1.5] or None, ksoft=1.0,
                      gran=0.3 if small else 1.0, edge=0.6 * edge if small else edge, lift=lift)
            if base is not None and key == base:
                kw["light_cut"] = light_cut
            S.wash(r, color, **kw)
            z += 0.01


# ---------------------------------------------------------------- efeitos (fx)
def _poly_area(P):
    return abs(_area(np.vstack([P, P[:1]])))


def classify_fx(P):
    c = P.mean(axis=0)
    u, s, vt = np.linalg.svd(P - c, full_matrices=False)
    ax = vt[0]; nx = np.array([-ax[1], ax[0]])
    pr = (P - c) @ ax; pe = (P - c) @ nx
    L = pr.max() - pr.min(); Wd = max(pe.max() - pe.min(), 1e-6)
    ar = _poly_area(P)
    return c, ax, nx, pr, pe, L, Wd, ar


def build_fx(S, fxpieces, silhouettes, no_convert=False):
    """riscos e pontinhos (raster opaco, sob o nanquim) para efeitos finos; o resto vira aguada."""
    sil = [MPath(s) for s in silhouettes]

    def inside(pts):
        pts = np.atleast_2d(pts)
        h = np.zeros(len(pts), bool)
        for sp in sil:
            h |= sp.contains_points(pts)
        return h

    lines, dots, big = {}, {}, []
    for p in fxpieces:
        if not p.polys:
            continue
        P = p.polys[0]
        c, ax, nx, pr, pe, L, Wd, ar = classify_fx(P)
        col = p.fill
        a = float(min(1.0, p.op + 0.1))
        if no_convert:
            big.append(p); continue
        if L / Wd >= 2.4 and ar < 700 and ar / (L * Wd) >= 0.33:
            # risco: parte do lado mais largo para a ponta
            lo = pr < pr.min() + 0.3 * L; hi = pr > pr.max() - 0.3 * L
            wlo = np.abs(pe[lo]).mean() if lo.any() else 0; whi = np.abs(pe[hi]).mean() if hi.any() else 0
            a0 = c + ax * pr.min(); a1 = c + ax * pr.max()
            if wlo < whi:
                a0, a1 = a1, a0
            r = max(min(Wd * 0.5, 4.0), 0.35)
            t = np.linspace(0, 1, 24)
            pts = a0[None, :] + (a1 - a0)[None, :] * t[:, None]
            vis = ~inside(pts)
            idx = np.flatnonzero(np.diff(np.r_[0, vis.astype(int), 0]))
            best = None
            for s0, s1 in zip(idx[::2], idx[1::2]):
                if best is None or s1 - s0 > best[1] - best[0]:
                    best = (s0, s1)
            if best is None or best[1] - best[0] < 4:
                continue
            t0, t1 = t[best[0]], t[min(best[1], len(t)) - 1]
            q0 = a0 + (a1 - a0) * t0; q1 = a0 + (a1 - a0) * t1
            lines.setdefault((col, round(a, 2)), []).append((q0[0], q0[1], q1[0], q1[1], r * (1 - 0.5 * t0)))
        elif ar < 6000 and ar / (L * Wd) < 0.2 and len(P) > 20 and np.median(np.linalg.norm(P[: len(P) // 2] - P[::-1][: len(P) // 2], axis=1)) < 14:
            Q = P[:-1] if np.allclose(P[0], P[-1]) else P
            h = len(Q) // 2
            cen = (Q[:h] + Q[::-1][:h]) / 2
            wid = np.linalg.norm(Q[:h] - Q[::-1][:h], axis=1)
            seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(cen, axis=0), axis=1))]
            nd = max(int(seg[-1] / 0.7), 4)
            tt = np.linspace(0, seg[-1], nd)
            q = np.c_[np.interp(tt, seg, cen[:, 0]), np.interp(tt, seg, cen[:, 1])]
            wr = np.interp(tt, seg, wid)
            wr = wr * ((ar / max(seg[-1], 1.0)) / max(wid.mean(), 1e-6))
            vis = ~inside(q)
            lst = dots.setdefault((col, round(a, 2)), [])
            for k in range(nd):
                if vis[k]:
                    lst.append((q[k, 0], q[k, 1], max(wr[k] * 0.5, 0.45)))
        elif L / Wd >= 1.8 and ar < 5000 and ar / (L * Wd) < 0.33:
            nb = 14
            edges = np.linspace(pr.min(), pr.max(), nb + 1)
            cen, wid = [], []
            for k in range(nb):
                sel = (pr >= edges[k]) & (pr <= edges[k + 1] + 1e-9)
                if sel.sum() < 2:
                    continue
                cen.append(P[sel].mean(axis=0)); wid.append(pe[sel].max() - pe[sel].min())
            cen = np.array(cen); wid = np.array(wid)
            seg = np.r_[0, np.cumsum(np.linalg.norm(np.diff(cen, axis=0), axis=1))]
            nd = max(int(seg[-1] / 0.7), 4)
            tt = np.linspace(0, seg[-1], nd)
            cx_ = np.interp(tt, seg, cen[:, 0]); cy_ = np.interp(tt, seg, cen[:, 1])
            th = ar / max(seg[-1], 1.0)
            fit = np.polyfit(seg[:len(wid)], wid, 1) if len(wid) > 2 else np.array([0.0, th])
            sl = np.clip(fit[0] * seg[-1] / max(th, 1e-6), -1.2, 1.2) * 0.35
            wr = th * (1 + sl * (tt / seg[-1] - 0.5) * 2)
            q = np.c_[cx_, cy_]
            vis = ~inside(q)
            lst = dots.setdefault((col, round(a, 2)), [])
            for k in range(nd):
                if vis[k]:
                    lst.append((q[k, 0], q[k, 1], max(wr[k] * 0.5, 0.45)))
        elif ar < 90 and L / Wd < 2.4:
            if inside(c)[0]:
                continue
            dots.setdefault((col, round(a, 2)), []).append((c[0], c[1], max(math.sqrt(ar / math.pi), 0.5)))
        else:
            big.append(p)
    for (col, a), pts in lines.items():
        S.fx.append({"t": "lines", "pts": pts, "color": col, "a": a})
    for (col, a), pts in dots.items():
        S.fx.append({"t": "dots", "pts": pts, "color": col, "a": a, "light": bool(lum(col) > 0.5)})
    return big


# ---------------------------------------------------------------- montagem
def build(name, lote, cfg=None):
    cfg = cfg or {}
    global NONZERO
    NONZERO = bool(cfg.get("nonzero_fill", False))
    S = Scene(name)
    svg = os.path.join(ROOT, "docs", "arte_cartas", lote, "comp", name + ".svg")
    groups = load(svg)
    for _g in groups:            # opcional: recolor {regex de id: cor} troca o fill de peças (só acrescenta; padrão inalterado)
        for _p in _g[2]:
            for _rx, _c in cfg.get("recolor", {}).items():
                if re.fullmatch(_rx, _p.id):
                    _p.fill = _c
    inkpat = [(re.compile(k), v) for k, v in cfg.get("ink_bg", {}).items()]

    def ink_w(pid):
        for rx, w in inkpat:
            if rx.fullmatch(pid):
                return w * 1.6
        return None

    G = {g[0]: g for g in groups}
    figgroups = [g for g in groups if g[0].startswith("fig_")]

    # ---- silhuetas de todas as figuras (para recortar riscos de efeito)
    fig_layers = []     # (gid, scale, [(figname, pieces)])
    all_sil = []
    for gid, scale, pcs in figgroups:
        fc = cfg.get("figs", {}).get(gid, {})
        split = fc.get("split", {})
        for p in pcs:
            for nf, pref in split.items():
                if any(p.id.startswith(x) for x in pref):
                    p.fig = nf
        order = []
        for p in pcs:
            if p.fig not in order:
                order.append(p.fig)
        if fc.get("order"):
            order = [o for o in fc["order"] if o in order] + [o for o in order if o not in fc["order"]]
        layers = []
        for fn in order:
            pp = [p for p in pcs if p.fig == fn]
            sp = [q for p in pp if p.fill and (not p.inner or re.search(r"boca|dente", p.id)) for q in p.polys]
            o, h = contours(mask(sp))
            all_sil += o
            layers.append((fn, pp, o, h))
        fig_layers.append((gid, scale, fc, layers))

    # ---------------- cenário
    bg_eff = []
    bg = G.get("bg")
    if bg:
        pcs = bg[2]
        tail = None
        for i, p in enumerate(pcs):
            if ink_w(p.id) is not None:
                tail = i; break
        base_pcs = pcs if tail is None else pcs[:tail]
        tail_pcs = [] if tail is None else pcs[tail:]
        # cor efetiva de cada peça do cenário (tinta translúcida = mistura com o que está embaixo, como no SVG)
        eff = []          # (cor, alpha, mask)
        for p in pcs:
            if not p.polys or p.op <= 0.02:
                eff.append(None); continue
            m = mask(p.polys)
            col, al = p.fill, alpha_for(p.fill, p.op if p.op >= 0.85 else 1.0)
            if p.op < 0.85:
                best, ba = None, 0
                for e in eff:
                    if e is None:
                        continue
                    ov = int((m & e[2]).sum())
                    if ov >= ba:
                        best, ba = e, ov
                if best is not None and ba > 0:
                    col, al = mixc(best[0], p.fill, p.op), best[1]
                else:
                    al = alpha_for(p.fill, p.op)
            eff.append((col, al, m))
        bg_eff = eff
        Lb = S.layer("bg")
        known = []
        pl = []
        for p, e in zip(base_pcs, eff):
            if p.lines:
                for ln in p.lines:
                    S.stroke(Lb, ln, w=max(0.3, min(1.0, p.sw * 0.55)), tin=0.25, tout=0.3, over=0, op=min(0.95, p.op + 0.15), shade=0.3)
                continue
            if e is None:
                continue
            col = cluster_color(e[0], known, 10)
            pl.append(dict(polys=p.polys, color=col, alpha=e[1], opaque=True, shade=0.0))
        emit_washes(S, regions(pl), 3.0, spill=1.8, mis_cap=0.6, edge=0.1)
        z = 3.5
        for p, e in zip(tail_pcs, eff[len(base_pcs):]):
            w = ink_w(p.id)
            if p.lines:
                L = S.layer("bgl_" + p.id)
                for ln in p.lines:
                    S.stroke(L, ln, w=max(0.3, min(1.0, p.sw * 0.55)), tin=0.25, tout=0.3, over=0, op=min(0.95, p.op + 0.15), shade=0.3)
                continue
            if e is None:
                continue
            o, h = contours(mask(p.polys))
            L = S.layer("bg_" + p.id, holdout=o if o else None)
            if w is not None:
                for r in o + h:
                    ctr(S, L, r, w=w, breaks=breaks_for(r), lin=True)
            tiny = sum(abs(_area(r)) for r in o) < 40
            if not (lum(e[0]) > 0.86 and tiny):
                for r in o:
                    S.wash(r, e[0], alpha=e[1], z=z, shade=(0.35 if w is not None else 0.0),
                           spill=0.5 if tiny else 1.0, mis=0.3 if tiny else 0.8, knock=[x for x in h if abs(_area(x)) > 1.5] or None,
                           gran=0.4 if tiny else 1.0, edge=0.7 if tiny else 1.0,
                           lift=any(re.fullmatch(x, p.id) for x in cfg.get("bg_lift", [])))
                z += 0.01

    # ---------------- enxame (um indivíduo por camada, na ordem do SVG); enxame_frente vem depois das figuras
    enx_sil = []

    def do_enx(enx, z0):
        ew = cfg.get("enx_w", 0.7)
        ew_by = cfg.get("enx_w_by", {})
        rim = cfg.get("enx_rim")
        names = []
        for p in enx[2]:
            if p.fig not in names:
                names.append(p.fig)
        known = []
        for fn in names:
            pp = [p for p in enx[2] if p.fig == fn]
            sp = [q for p in pp if p.fill and not p.inner for q in p.polys]
            m0 = mask(sp)
            o, h = contours(m0)
            if not o:
                continue
            hold, ring = o, None
            enx_sil.extend(o)
            if rim:
                ys, xs = np.nonzero(m0)
                cy, cx = int(ys.mean()), int(xs.mean())
                under = None
                for e in reversed(bg_eff):
                    if e is not None and e[2][cy, cx]:
                        under = e; break
                if under is not None and lum(under[0]) < rim.get("dark", 0.3):
                    mg = ndi.binary_dilation(m0, iterations=int(rim.get("grow", 1.6) * SC))
                    hold, _ = contours(mg)
                    ring = hold
            L = S.layer(fn, holdout=hold)
            wv = ew_by.get(fn, ew)
            if wv > 0:
                for r in o:
                    ctr(S, L, r, w=wv, breaks=breaks_for(r), lin=True, op=0.9)
            if ring:
                for r in ring:
                    S.wash(r, rim.get("color", "#f3dcb8"), alpha=0.55, z=z0 - 0.5, shade=0.0, spill=0.2, mis=0.2,
                           knock=o, ksoft=0.6, gran=0.3, edge=0.3)
            pl = []
            for p in pp:
                if not p.polys:
                    continue
                col = cluster_color(p.fill, known, 10)
                if ring and lum(col) < 0.35:
                    col = mixc(col, rim.get("warm", "#a8684a"), 0.35)
                pl.append(dict(polys=p.polys, color=col, alpha=alpha_for(col, p.op), opaque=is_opaque(col, p.op), shade=0.25 if not p.inner else 0.0))
            emit_washes(S, regions(pl), z0, spill=0.8, mis_cap=0.8)

    if G.get("enxame"):
        do_enx(G["enxame"], 5.0)

    # ---------------- efeitos
    fxg = G.get("fx")
    if fxg:
        big = build_fx(S, fxg[2], all_sil + enx_sil, cfg.get("fx_dark", False))
        hold_fx = None
        if cfg.get("fx_hold"):      # efeito grande opaco esconde o nanquim do cenário atrás dele
            hold_fx, _ = contours(mask([q for p in big for q in p.polys]))
        L = S.layer("fx", holdout=hold_fx or None)
        for p in big:
            for r in p.polys:
                if any(re.fullmatch(x, p.id or "") for x in cfg.get("fx_keep_op", [])):   # fantasma: mantém a opacidade da composição
                    _al = min(0.97, alpha_for(p.fill, p.op))
                else:
                    _al = min(0.97, alpha_for(p.fill, p.op if not cfg.get("fx_alpha") else max(p.op, 0.9)) * cfg.get("fx_alpha", 0.7))
                S.wash(r, p.fill, alpha=_al, lift=bool(cfg.get("fx_lift")), z=6.0, shade=0.0, spill=0.8, mis=0.6, edge=0.6)

    # ---------------- figuras
    zb = 10.0
    for gid, scale, fc, layers in fig_layers:
        dark = fc.get("dark", 0.0)
        detail = fc.get("detail", scale > 0.6)
        w = max(1.3, 1.6 * fc["w"]) if "w" in fc else 1.45 + 0.35 * min(scale, 1.7) / 1.7
        known = []
        for fn, pp, outers, holes in layers:
            L = S.layer(fn, holdout=outers, holes=[x for x in holes if abs(_area(x)) > 1.5] if cfg.get("holes_open") else None)
            for r in outers + holes:
                ctr(S, L, r, w=w, breaks=breaks_for(r), lin=True)
            # linhas internas com função (dedos, costelas, bigode, sobrancelha)
            if detail and not dark:
                for i, p in enumerate(pp):
                    if not p.lines:
                        continue
                    later = [q for q in pp[i + 1:] if q.fill and not q.inner for q in [q] for _ in [0]]
                    cov = mask([x for q in pp[i + 1:] if q.fill and not q.inner for x in q.polys]) if i + 1 < len(pp) else None
                    for ln in p.lines:
                        pts = resample(ln, 0.6)
                        if cov is not None:
                            ij = ((pts + PAD) * SC).astype(int)
                            ij[:, 0] = np.clip(ij[:, 0], 0, CW - 1); ij[:, 1] = np.clip(ij[:, 1], 0, CH - 1)
                            vis = ~cov[ij[:, 1], ij[:, 0]]
                            idx = np.flatnonzero(np.diff(np.r_[0, vis.astype(int), 0]))
                            segs = [pts[a:b] for a, b in zip(idx[::2], idx[1::2]) if b - a >= 3]
                        else:
                            segs = [pts]
                        lw = float(np.clip(p.sw / 1.2, 0.5, 1.5))
                        for sg in segs:
                            S.stroke(L, sg, w=lw, tin=0.25, tout=0.3, over=0, op=0.85, shade=0.3)
                # contornos finos de boca, olho, dente
                for p in pp:
                    if p.fill and p.inner and re.search(r"boca|olho|dente|nariz", p.id):
                        ww = 0.85 if "boca" in p.id else (0.4 if "dente" in p.id else 0.55)
                        for q in p.polys:
                            if _poly_area(q) > 0.5:
                                ctr(S, L, rdp(resample(q, 0.5), 0.15), w=ww, breaks=(0.0, 0.5), lin=True, shade=0.3)
            # aguadas
            pl = []
            for p in pp:
                if not p.polys:
                    continue
                col = cluster_color(p.fill, known, 14)
                if dark:
                    col = mixc(col, fc.get("dark_color", "#1c2438"), dark)
                pl.append(dict(polys=p.polys, color=col, alpha=alpha_for(col, p.op) * 0.9, opaque=True, shade=0.3 if not p.inner else 0.0))
            regs = regions(pl)
            # a cor de maior área é a base: sombra de forma mais forte e papel reservado na luz
            if regs:
                bk = max(regs, key=lambda r: r[3])[0]
                regs = [(k if k != bk else (k[0], k[1], 0.5), o, h, px) for (k, o, h, px) in regs]
                bk = (bk[0], bk[1], 0.5)
            else:
                bk = None
            emit_washes(S, regs, zb, base=bk, light_cut=fc.get("light_cut", 0.15 if scale > 0.6 else 0.0), lift=fn in fc.get("lift", []))
            if fn in fc.get("solid", []):
                emit_washes(S, [((k[0], min(0.95, k[1] + 0.1), 0.0), o, h, px) for (k, o, h, px) in regs], zb + 0.5, spill=0.4)
            rim = fc.get("rim")     # luz de recorte: faixa fina de guache dentro do contorno, do lado da luz
            if rim and outers:
                m0 = mask(outers)
                m1 = ndi.binary_erosion(m0, iterations=max(1, int(rim.get("in", 1.2) * SC)))
                bandm = np.zeros_like(m1)
                for dx, dy in rim["dirs"]:
                    d = int(round(rim.get("w", 1.8) * SC))
                    bandm |= m1 & ~np.roll(np.roll(m1, -int(round(dx * d)), axis=1), -int(round(dy * d)), axis=0)
                bandm = ndi.binary_opening(bandm, iterations=1)
                bo, _bh = contours(bandm)
                for r in bo:
                    S.wash(r, rim.get("color", "#c9a0f0"), alpha=rim.get("alpha", 0.75), lift=True, z=zb + 0.8,
                           shade=0.0, spill=0.1, mis=0.2, gran=0.4, edge=0.3)
            zb += 1.0

    if G.get("enxame_frente"):
        do_enx(G["enxame_frente"], zb + 1.0)

    S.save(sys.argv[1] if len(sys.argv) > 1 else name + ".json")
    return S
