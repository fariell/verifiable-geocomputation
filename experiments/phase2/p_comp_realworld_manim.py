"""Manim scene: three real public DEMs, ridgeline / drainage / sink captions.

Render:

    GPB027_MANIM=1 python experiments/phase2/p_comp_realworld.py

or:

    manim -ql experiments/phase2/p_comp_realworld_manim.py RealWorldDiversity
"""
from __future__ import annotations

import os

from manim import *

HERE = os.path.dirname(os.path.abspath(__file__))
PANEL_SLUGS = (
    ("lidar", "USGS 3DEP LiDAR 1 m"),
    ("ifsar", "Alaska IFSAR 5 m"),
    ("copernicus", "Copernicus GLO-30"),
)


def panel_png(slug: str) -> str:
    root = os.environ.get(
        "GPB027_OUT", os.path.join(HERE, "results", "gpb027_realworld")
    )
    nested = os.path.join(root, slug, "panel.png")
    flat = os.path.join(root, "%s_panel.png" % slug)
    if os.path.isfile(nested):
        return nested
    return flat


class RealWorldDiversity(Scene):
    def construct(self):
        title = Text("P-COMP-1  real DEM diversity   GPB-027", font_size=26)
        title.to_edge(UP, buff=0.16)
        self.play(FadeIn(title))

        positions = [LEFT * 4.15, ORIGIN, RIGHT * 4.15]
        group = VGroup()
        for (slug, cap), pos in zip(PANEL_SLUGS, positions):
            png = panel_png(slug)
            if os.path.isfile(png):
                img = ImageMobject(png)
                img.set_height(3.35)
                img.move_to(pos + DOWN * 0.15)
                label = Text(cap, font_size=16)
                label.next_to(img, DOWN, buff=0.06)
                self.add(img)
                group.add(label)
            else:
                box = Square(side_length=3.0)
                box.move_to(pos + DOWN * 0.15)
                box.set_fill(BLUE_E, opacity=0.45)
                box.set_stroke(WHITE, 1.5)
                label = Text(cap, font_size=16)
                label.next_to(box, DOWN, buff=0.06)
                group.add(box, label)
        self.play(LaggedStart(*[FadeIn(m) for m in group], lag_ratio=0.1))
        note = Text(
            "ridgeline  /  drainage density  /  sink count   ·   paper §7.7",
            font_size=18,
        )
        note.to_edge(DOWN, buff=0.12)
        self.play(Write(note))
        self.wait(1.8)
