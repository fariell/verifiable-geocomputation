#!/usr/bin/env python3
"""Publication figures for the Scientific Data Descriptor (600 dpi PNG + vector PDF)."""
from __future__ import annotations

import os
import sys

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Rectangle

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
PHASE2 = os.path.join(ROOT, "experiments", "phase2")
PHASE1 = os.path.join(ROOT, "experiments", "phase1")
for p in (PHASE2, PHASE1):
    if p not in sys.path:
        sys.path.insert(0, p)

from p005_d8 import plane_grid  # noqa: E402
from p_comp_1_multires import (  # noqa: E402
    coarsen_mean,
    make_lidar_down,
    make_srtm,
    make_terrain_a,
)
from p_comp_3 import GRID_A, GRID_B, W, grid_quad  # noqa: E402
from p003_curvature import numeric_zt  # noqa: E402
from p004_consistency import horn_dzdx  # noqa: E402

OUT = HERE
DPI = 600
mpl.rcParams.update(
    {
        "font.family": "sans-serif",
        "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
        "font.size": 9,
        "axes.titlesize": 10,
        "axes.labelsize": 9,
        "figure.facecolor": "white",
        "savefig.facecolor": "white",
        "axes.facecolor": "white",
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "axes.unicode_minus": False,
        "text.antialiased": True,
        "lines.antialiased": True,
    }
)
PANEL = dict(fontweight="bold", fontsize=12, color="#111111")
INK = "#222222"


def hillshade(z: np.ndarray, azimuth: float = 315.0, altitude: float = 45.0) -> np.ndarray:
    z = np.asarray(z, dtype=float)
    dy, dx = np.gradient(z)
    slope = np.pi / 2.0 - np.arctan(np.hypot(dx, dy))
    aspect = np.arctan2(-dx, dy)
    az = np.radians(azimuth)
    alt = np.radians(altitude)
    hs = np.sin(alt) * np.sin(slope) + np.cos(alt) * np.cos(slope) * np.cos(az - aspect)
    lo, hi = float(hs.min()), float(hs.max())
    return (hs - lo) / (hi - lo + 1e-12)


def downsample(z: np.ndarray, max_n: int = 128) -> np.ndarray:
    """Block-mean downsample (anti-alias). Strided slicing is avoided: it keeps high-frequency sin terms and Moiré."""
    z = np.asarray(z, dtype=float)
    n = max(z.shape)
    if n <= max_n:
        return z
    factor = int(np.ceil(n / max_n))
    h, w = z.shape
    h2, w2 = (h // factor) * factor, (w // factor) * factor
    z = z[:h2, :w2]
    return z.reshape(h2 // factor, factor, w2 // factor, factor).mean(axis=(1, 3))


def save(fig: plt.Figure, name: str) -> None:
    png = os.path.join(OUT, name)
    pdf = os.path.splitext(png)[0] + ".pdf"
    kw = dict(bbox_inches="tight", pad_inches=0.02, facecolor="white")
    fig.savefig(png, dpi=DPI, **kw)
    fig.savefig(pdf, **kw)
    plt.close(fig)
    print("wrote", png, pdf)


def letter_title(ax, letter: str, title: str, y: float = 1.03) -> None:
    """Panel letter and title on one baseline, letter left of the title."""
    ax.text(0.00, y, letter, transform=ax.transAxes, ha="left", va="bottom", **PANEL)
    ax.text(0.12, y, title, transform=ax.transAxes, ha="left", va="bottom", fontsize=9, color=INK)


def _chain_box(ax, x, y, w, h, text, fc, ec, fontsize=7.6, fw="normal") -> None:
    ax.add_patch(
        FancyBboxPatch(
            (x, y),
            w,
            h,
            boxstyle="round,pad=0.006,rounding_size=0.016",
            facecolor=fc,
            edgecolor=ec,
            lw=0.95,
            transform=ax.transAxes,
            clip_on=False,
        )
    )
    ax.text(
        x + w / 2.0,
        y + h / 2.0,
        text,
        ha="center",
        va="center",
        fontsize=fontsize,
        fontweight=fw,
        color="#111111",
        transform=ax.transAxes,
        linespacing=1.12,
    )


def _chain_arrow(ax, x1, y1, x2, y2, color="#333333") -> None:
    ax.annotate(
        "",
        xy=(x2, y2),
        xytext=(x1, y1),
        xycoords="axes fraction",
        textcoords="axes fraction",
        arrowprops=dict(arrowstyle="-|>", color=color, lw=1.0, mutation_scale=8),
        annotation_clip=False,
    )


def _draw_lemma_chain(ax) -> None:
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    letter_title(ax, "c", "Five-lemma chain recorded by Dafny and Lean", y=1.02)

    _chain_box(ax, 0.02, 0.68, 0.20, 0.22, "skip fill\n(panel a)", "#fdecea", "#c0392b", 7.6)
    _chain_box(ax, 0.30, 0.68, 0.28, 0.22, "D8 cycle:\ndoes not terminate", "#fdecea", "#c0392b", 7.6)
    _chain_box(
        ax,
        0.66,
        0.68,
        0.32,
        0.22,
        "P-COMP-1b\nNEGATIVE-RESULT PASS",
        "#fdecea",
        "#c0392b",
        7.6,
        "bold",
    )
    _chain_arrow(ax, 0.22, 0.79, 0.295, 0.79, "#c0392b")
    _chain_arrow(ax, 0.58, 0.79, 0.655, 0.79, "#c0392b")

    row = [
        (0.02, 0.13, "P-002 fill\n(panel b)", "#e8f5e9", "#2e7d32", "normal"),
        (0.19, 0.13, "(i) min(nbr)\n" + r"$\leq$ cell", "#e3f2fd", "#1565c0", "normal"),
        (0.36, 0.13, "(ii) D8\ndescends", "#e3f2fd", "#1565c0", "normal"),
        (0.53, 0.13, "(iii) pigeonhole\n" + r"$\leq n\cdot m$", "#e3f2fd", "#1565c0", "normal"),
        (0.70, 0.13, "(iv) boundary\nNoFlow", "#e3f2fd", "#1565c0", "normal"),
        (0.87, 0.11, "(v) unique\nterminus", "#fff8e1", "#c9a227", "bold"),
    ]
    y, h = 0.20, 0.34
    for x, w, text, fc, ec, fw in row:
        _chain_box(ax, x, y, w, h, text, fc, ec, 7.3, fw)
        right = x + w
        nxt = None
        for xx, *_rest in row:
            if xx > x + 1e-9:
                nxt = xx
                break
        if nxt is not None:
            _chain_arrow(ax, right + 0.002, 0.37, nxt - 0.002, 0.37, "#333333")

    ax.text(
        0.50,
        0.06,
        "P-COMP-1   ·   Dafny verify PCOMP_1.dfy: 17 members / 0 errors"
        "   ·   Lean lake build: 0 errors",
        ha="center",
        va="center",
        fontsize=8.0,
        color="#111111",
        transform=ax.transAxes,
    )


def fig1() -> None:
    plane = plane_grid(1.0, 0.0, 12.0, n=5)
    fig = plt.figure(figsize=(7.4, 5.70))
    gs = fig.add_gridspec(
        2,
        2,
        height_ratios=[1.20, 1.00],
        hspace=0.48,
        wspace=0.38,
        left=0.04,
        right=0.98,
        top=0.90,
        bottom=0.05,
    )
    ax_a = fig.add_subplot(gs[0, 0])
    ax_b = fig.add_subplot(gs[0, 1])
    ax_c = fig.add_subplot(gs[1, :])

    ax = ax_a
    ax.set_xlim(-0.55, 2.55)
    ax.set_ylim(-0.85, 2.55)
    ax.set_aspect("equal")
    ax.axis("off")
    letter_title(ax, "a", "Unfilled four-cell ring", y=1.04)
    ax.add_patch(Rectangle((-0.12, -0.12), 2.24, 2.24, fill=False, edgecolor="#c0392b", lw=1.15, zorder=0))
    coords = [(0, 1), (1, 1), (1, 0), (0, 0)]
    for c, r in coords:
        ax.add_patch(Rectangle((c, r), 1, 1, facecolor="#d9d9d9", edgecolor="#333333", lw=1.1))
        ax.text(c + 0.5, r + 0.5, "flat", ha="center", va="center", fontsize=9, color="#444444")
    cycle = [(0.5, 1.5), (1.5, 1.5), (1.5, 0.5), (0.5, 0.5)]
    for i, (x, y) in enumerate(cycle):
        x2, y2 = cycle[(i + 1) % 4]
        ax.add_patch(
            FancyArrowPatch(
                (x, y),
                (x2, y2),
                arrowstyle="-|>",
                mutation_scale=11,
                lw=1.4,
                color="#c0392b",
                shrinkA=10,
                shrinkB=10,
            )
        )
    ax.text(
        1.0,
        -0.42,
        "NEGATIVE-RESULT PASS\ncondition boundary: D8 does not terminate",
        ha="center",
        va="top",
        fontsize=8,
        color="#c0392b",
        linespacing=1.2,
    )

    ax = ax_b
    im = ax.imshow(plane, cmap="YlGnBu", origin="upper")
    for r in range(5):
        for c in range(5):
            ax.text(c, r, "%.0f" % plane[r, c], ha="center", va="center", fontsize=9, color="#1a1a1a")
        for c in range(1, 5):
            ax.annotate(
                "",
                xy=(c - 0.46, r),
                xytext=(c + 0.12, r),
                arrowprops=dict(
                    arrowstyle="-|>",
                    color="#a85b00",
                    lw=1.7,
                    mutation_scale=10,
                ),
            )
    ax.set_xticks([])
    ax.set_yticks([])
    letter_title(ax, "b", r"Filled unit plane ($A{=}1$, base${=}12$)", y=1.04)
    for spine in ax.spines.values():
        spine.set_color("#2e7d32")
        spine.set_linewidth(1.15)
    cbar = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    cbar.set_label("Elevation", fontsize=8)
    cbar.ax.tick_params(labelsize=7)

    _draw_lemma_chain(ax_c)
    fig.suptitle("P-COMP-1 teaching stencil (not a product raster)", fontsize=10.5, y=0.98)
    save(fig, "fig1_fill_watershed.png")


def _panel_plane_grid(ax, plane: np.ndarray, title: str, metrics: str, letter: str) -> None:
    """5x5 teaching plane: labelled cells and D8 arrows, no hillshade."""
    n = int(plane.shape[0])
    ax.set_xlim(-0.55, n - 0.45)
    ax.set_ylim(n - 0.45, -0.55)
    ax.set_aspect("equal")
    ax.axis("off")
    vmin = float(plane.min())
    vmax = float(plane.max())
    for r in range(n):
        for c in range(n):
            t = (float(plane[r, c]) - vmin) / (vmax - vmin + 1e-12)
            fc = (0.97 - 0.42 * t, 0.94 - 0.18 * t, 0.82 + 0.08 * t)
            ax.add_patch(
                Rectangle(
                    (c - 0.5, r - 0.5),
                    1,
                    1,
                    facecolor=fc,
                    edgecolor="#333333",
                    lw=0.9,
                )
            )
            ax.text(c, r, "%.0f" % plane[r, c], ha="center", va="center", fontsize=9, color="#1a1a1a")
        for c in range(1, n):
            ax.annotate(
                "",
                xy=(c - 0.42, r),
                xytext=(c + 0.18, r),
                arrowprops=dict(arrowstyle="-|>", color="#a85b00", lw=1.6, mutation_scale=10),
            )
    letter_title(ax, letter, title, y=1.03)
    ax.text(
        0.5,
        -0.055,
        metrics,
        transform=ax.transAxes,
        ha="center",
        va="top",
        fontsize=8.0,
        color="#111111",
    )


def _panel_dem(
    ax,
    z,
    title,
    metrics: str,
    letter: str,
    max_n: int = 256,
    show_cbar: bool = True,
    two_line_metrics: bool = False,
    line2_prefix: str = "",
) -> None:
    view = downsample(z, max_n)
    hs = hillshade(view)
    ax.imshow(hs, cmap="gray", origin="upper")
    im = ax.imshow(view, cmap="terrain", origin="upper", alpha=0.55)
    ax.set_xticks([])
    ax.set_yticks([])
    letter_title(ax, letter, title, y=1.03)
    zmin, zmax = float(np.nanmin(view)), float(np.nanmax(view))
    z_txt = r"$z{=}%.0f$–$%.0f~\mathrm{m}$" % (zmin, zmax)
    kw = dict(transform=ax.transAxes, ha="center", va="top", color="#111111", clip_on=False)
    lines = [ln for ln in metrics.split("\n") if ln.strip()]
    if two_line_metrics:
        y0, dy = -0.055, -0.125
        stacked = lines + [z_txt]
        for i, ln in enumerate(stacked):
            ax.text(0.5, y0 + i * dy, ln, fontsize=7.0, **kw)
    else:
        ax.text(0.5, -0.055, "   ".join(lines) + r"   " + z_txt, fontsize=7.6, **kw)
    if show_cbar:
        cbar = ax.figure.colorbar(im, ax=ax, fraction=0.046, pad=0.03)
        cbar.set_label("z (m)", fontsize=7)
        cbar.ax.tick_params(labelsize=6)
    for spine in ax.spines.values():
        spine.set_linewidth(0.6)


def fig2() -> None:
    plane = plane_grid(1.0, 0.0, 12.0, n=5)
    terr, _ = make_terrain_a()
    srtm, _ = make_srtm()
    lidar, _ = make_lidar_down()
    fig, axes = plt.subplots(2, 2, figsize=(7.4, 7.15))
    _panel_plane_grid(
        axes[0, 0],
        plane,
        r"plane-5 m  ($5\times5$)",
        r"$n_\mathrm{pit}{=}0$, $n_\mathrm{out}{=}3$, longest${=}3$",
        "a",
    )
    _panel_dem(
        axes[0, 1],
        terr,
        r"terrain-A  ($256^{2}$, synthetic)",
        r"$n_\mathrm{pit}{=}53$, $n_\mathrm{out}{=}98$, longest${=}351$",
        "b",
        256,
    )
    _panel_dem(
        axes[1, 0],
        srtm,
        r"SRTM-scale stand-in  ($3601^{2}$)",
        r"$n_\mathrm{pit}{=}2{,}519{,}307$, $n_\mathrm{out}{=}6.03{\times}10^{6}$",
        "c",
        128,
    )
    _panel_dem(
        axes[1, 1],
        lidar,
        r"lidar-down stand-in  ($256^{2}$)",
        r"$n_\mathrm{pit}{=}1{,}782$, $n_\mathrm{out}{=}20{,}137$, longest${=}13$",
        "d",
        256,
    )
    note = (
        "Elevation colour is per panel (blue/green: lower; yellow/white: higher).  "
        "Panel c is a display-only block-mean of the deposited $3601^{2}$ raster.  "
        "c, d are synthetic stand-ins."
    )
    fig.subplots_adjust(left=0.04, right=0.96, top=0.92, bottom=0.09, wspace=0.28, hspace=0.34)
    fig.text(0.5, 0.012, note, ha="center", fontsize=8.0, color="#444444")
    save(fig, "fig2_multires.png")


def _center_hxx(h: np.ndarray, w: float) -> float:
    zt = numeric_zt(h, w, w)
    r = h.shape[0] // 2
    c = h.shape[1] // 2
    return float(zt[0][r, c])


def _center_dx(h: np.ndarray, w: float) -> float:
    r = h.shape[0] // 2
    c = h.shape[1] // 2
    a, b, cc = h[r - 1, c - 1], h[r - 1, c], h[r - 1, c + 1]
    d, f = h[r, c - 1], h[r, c + 1]
    g, hh, i = h[r + 1, c - 1], h[r + 1, c], h[r + 1, c + 1]
    return float(horn_dzdx(a, b, cc, d, f, g, hh, i, w))


def fig3() -> None:
    """Paper Fig. 4: ZT vs Horn (saved as fig4_zt_horn)."""
    ha = grid_quad(GRID_A["nx"], W, GRID_A["A"], GRID_A["D"])
    hb = grid_quad(GRID_B["nx"], W, GRID_B["A"], GRID_B["D"])
    fig = plt.figure(figsize=(7.4, 3.05))
    gs = fig.add_gridspec(
        2, 2, height_ratios=[1.0, 0.22], hspace=0.18, wspace=0.22,
        left=0.05, right=0.97, top=0.82, bottom=0.06,
    )
    axes = [fig.add_subplot(gs[0, 0]), fig.add_subplot(gs[0, 1])]
    foot = fig.add_subplot(gs[1, :])
    foot.axis("off")
    for ax, h, tag, lab in (
        (axes[0], ha, r"Grid A  ($A{=}0.21$, $D{=}0.00705$)", "a"),
        (axes[1], hb, r"Grid B  ($A{=}0.07$, $D{=}0.03485$)", "b"),
    ):
        im = ax.imshow(h, cmap="coolwarm", origin="upper")
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_box_aspect(1)
        letter_title(ax, lab, tag, y=1.04)
        hxx = _center_hxx(h, W)
        dx = _center_dx(h, W)
        ax.text(
            0.5,
            -0.08,
            r"centre $H_{xx}^{\mathrm{ZT}}{=}%.3g$,  Horn $D_x{=}%.2f$" % (hxx, dx),
            transform=ax.transAxes,
            ha="center",
            va="top",
            fontsize=8.5,
            color=INK,
        )
        for spine in ax.spines.values():
            spine.set_color("#c0392b")
            spine.set_linewidth(1.15)
        fig.colorbar(im, ax=ax, fraction=0.046, pad=0.03).set_label("z", fontsize=8)
    fig.suptitle(
        r"P-COMP-3: $H_{xx}^{\mathrm{ZT}}$ and Horn $D_x$ do not vanish together",
        fontsize=10.5,
        y=0.98,
    )
    foot.text(
        0.5,
        0.35,
        r"$H_{xx}$: ZT profile curvature.  $D_x$: Horn east–west second-order slope coefficient.  "
        "Existence witness, not a population claim.",
        ha="center",
        va="center",
        fontsize=8.0,
        color="#111111",
        transform=foot.transAxes,
    )
    save(fig, "fig4_zt_horn.png")


def _try_real_windows() -> dict[str, np.ndarray]:
    cache = os.path.join(ROOT, "data", "cache")
    out: dict[str, np.ndarray] = {}
    names = {
        "lidar": "gpb027_lidar.tif",
        "ifsar": "gpb027_ifsar.tif",
        "copernicus": "gpb027_copernicus.tif",
    }
    try:
        from osgeo import gdal
    except ImportError:
        return out
    for slug, fn in names.items():
        path = os.path.join(cache, fn)
        if not os.path.isfile(path):
            continue
        ds = gdal.Open(path)
        if ds is None:
            continue
        arr = np.array(ds.GetRasterBand(1).ReadAsArray(), dtype=float)
        ds = None
        if arr.size:
            out[slug] = arr
    return out


def fig4() -> None:
    """Paper Fig. 3: public windows (saved as fig3_realworld)."""
    rows = [
        ("lidar", "USGS 3DEP lidar  1 m", "Griffith Park", 88, 234, 0.125, 0.106),
        ("ifsar", "Alaska IFSAR  5 m", "Fairbanks window", 270, 253, 0.225, 0.0363),
        ("copernicus", "Copernicus GLO-30  28.4 m", "N32E110", 626, 4981, 0.318, 0.00685),
    ]
    rasters = _try_real_windows()
    fig = plt.figure(figsize=(7.4, 4.25))
    gs = fig.add_gridspec(
        2, 3, height_ratios=[1.0, 0.58], hspace=0.82, wspace=0.20,
        left=0.02, right=0.98, top=0.86, bottom=0.04,
    )
    axes = [fig.add_subplot(gs[0, i]) for i in range(3)]
    foot = fig.add_subplot(gs[1, :])
    foot.axis("off")
    for ax, (slug, title, place, npit, nout, ridge, dd), lab in zip(axes, rows, "abc"):
        ax.set_box_aspect(1)
        if slug in rasters:
            _panel_dem(
                ax,
                rasters[slug],
                title,
                "\n".join(
                    [
                        r"$n_\mathrm{pit}{=}%d$" % npit,
                        r"ridge${=}%.3f$" % ridge,
                        r"$D_d{=}%.3g~\mathrm{m}^{-1}$" % dd,
                    ]
                ),
                lab,
                256,
                False,
                True,
            )
        else:
            ax.set_xlim(0, 1)
            ax.set_ylim(0, 1)
            ax.axis("off")
            letter_title(ax, lab, title, y=1.04)
            ax.add_patch(
                FancyBboxPatch(
                    (0.04, 0.18),
                    0.92,
                    0.72,
                    boxstyle="round,pad=0.02,rounding_size=0.04",
                    facecolor="#f4f6f8",
                    edgecolor="#333333",
                    lw=0.8,
                )
            )
            body = (
                "%s\n\n"
                r"$n_{\mathrm{pit}}=%d$" "\n"
                r"$n_{\mathrm{out}}=%d$" "\n"
                r"ridge $=%.3f$" "\n"
                r"$D_d=%.3g\,\mathrm{m}^{-1}$"
            ) % (place, npit, nout, ridge, dd)
            ax.text(0.5, 0.54, body, ha="center", va="center", fontsize=8.5, linespacing=1.45, color=INK)
    fig.suptitle(r"Public $256^{2}$ windows: P-COMP-1 gates PASS", fontsize=10.5, y=0.98)
    foot.text(
        0.5,
        0.42,
        "Elevation colour is per panel (blue/green: lower; yellow/white: higher).\n"
        r"ridge $=$ interior D8 in-degree 0;   "
        r"$D_d=$ (interior in-degree $\geq 2$) / (interior cells $\times$ cell size).",
        ha="center",
        va="center",
        fontsize=8.0,
        color="#111111",
        transform=foot.transAxes,
        linespacing=1.35,
    )
    save(fig, "fig3_realworld.png")


if __name__ == "__main__":
    os.chdir(HERE)
    fig1()
    fig2()
    fig3()
    fig4()
    print("done")
