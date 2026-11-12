"""Asa de membrana (diabrete, dragão): braço ombro→cotovelo→pulso, dedos do pulso às pontas, membrana recortada em arcos
entre as pontas e da última ponta até a raiz no corpo. Tudo em coordenadas da pose (absolutas)."""
import base  # noqa: F401
import math
import numpy as np
from geom import *


def _q(a, b, m, k):
    return [(1 - t) ** 2 * a + 2 * (1 - t) * t * m + t * t * b for t in [i / k for i in range(1, k)]]


def wing(fig, S, E, W, tips, root, fill, bone, claw, arm_w=(5, 3.2), curl=0.3, thumb=6.0, arm_fill=None, finger_w=1.0):
    S, E, W, root = A(S), A(E), A(W), A(root)
    T_ = [A(t) for t in tips]
    up = E - S; n0 = np.array([up[1], -up[0]]) / (np.linalg.norm(up) + 1e-9)
    pts = [S, (S + E) / 2 + n0 * 0.6, E, (E + W) / 2, W, T_[0]]
    for a, b in zip(T_[:-1], T_[1:]):
        m = (a + b) / 2; m = m + (W - m) * curl
        pts += _q(a, b, m, 5) + [b]
    m = (T_[-1] + root) / 2; m = m + (W - m) * curl * 0.8
    pts += _q(T_[-1], root, m, 6) + [root]
    pcs = [Pc(fig, fig, fill, pts, mode="poly")]
    pcs.append(Pc(fig + "_braco", fig, arm_fill or bone, brush([S, E, W], arm_w[0], arm_w[1], per=3)))
    for i, tp in enumerate(T_):
        d = tp - W; nn = np.array([-d[1], d[0]]) / (np.linalg.norm(d) + 1e-9)
        mid = W + d * 0.5 + nn * np.linalg.norm(d) * 0.04
        pcs.append(Pc(f"{fig}_dedo{i}", fig, bone, [W, mid, tp], closed=False, cls="inner", sw=finger_w * (1.4 - i * 0.1)))
    d = E - W; d = d / (np.linalg.norm(d) + 1e-9)
    nn = np.array([-d[1], d[0]])
    if np.dot(nn, A(T_[0]) - W) > 0:
        nn = -nn
    th = W + nn * thumb * 0.8 - d * thumb * 0.2
    pcs.append(Pc(fig + "_polegar", fig, claw, brush([W + nn * 1.0, th], thumb * 0.42, 0.2, per=2)))
    return pcs
