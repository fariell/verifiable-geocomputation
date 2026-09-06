"""Manim scene: four DEM sizes, same fill-then-basin algorithm.

Render:

    PCOMP1_MULTIRES_MANIM=1 python experiments/phase2/p_comp_1_multires.py

or:

    manim -ql experiments/phase2/p_comp_1_multires_manim.py FillThenWatershedMultiresStencil
"""
from __future__ import annotations

import os

from manim import *

HERE = os.path.dirname(os.path.abspath(__file__))
PANEL_SLUGS = (
    ("PLANE", "plane-5m  5x5  5m"),
    ("TERRAIN_A", "terrain-A  256^2  5m"),
    ("SRTM_30M", "SRTM-30m  3601^2  30m"),
    ("LIDAR", "LiDAR-down  256^2"),
)


def panel_png(slug: str) -> str:
    return os.path.join(HERE, "results", "gpb024", "%s_panel.png" % slug)


class FillThenWatershedMultiresStencil(Scene):
    def construct(self):
        title = Text("P-COMP-1  multi-res fill then basin   GPB-024", font_size=26)
        title.to_edge(UP, buff=0.18)
        self.play(FadeIn(title))

        positions = [
            LEFT * 3.35 + UP * 0.85,
            RIGHT * 3.35 + UP * 0.85,
            LEFT * 3.35 + DOWN * 1.55,
            RIGHT * 3.35 + DOWN * 1.55,
        ]
        group = VGroup()
        for (slug, cap), pos in zip(PANEL_SLUGS, positions):
            png = panel_png(slug)
            if os.path.isfile(png):
                img = ImageMobject(png)
                img.set_height(2.35)
                img.move_to(pos)
                label = Text(cap, font_size=16)
                label.next_to(img, DOWN, buff=0.08)
                self.add(img)
                group.add(label)
            else:
                box = Square(side_length=2.2)
                box.move_to(pos)
                box.set_fill(BLUE_E, opacity=0.45)
                box.set_stroke(WHITE, 1.5)
                label = Text(cap, font_size=16)
                label.next_to(box, DOWN, buff=0.08)
                group.add(box, label)
        self.play(LaggedStart(*[FadeIn(m) for m in group], lag_ratio=0.08))
        for (slug, cap), pos in zip(PANEL_SLUGS, positions):
            png = panel_png(slug)
            if os.path.isfile(png):
                ring = SurroundingRectangle(Dot(pos), color=YELLOW, buff=1.15)
                self.play(Create(ring), run_time=0.25)
                self.play(FadeOut(ring), run_time=0.2)
        note = MathTex(
            r"\mathrm{fill}\Rightarrow\mathrm{descent}\Rightarrow\exists!\ \mathrm{outlet}"
            r"\quad(\mathrm{lemmas\ independent\ of}\ n)",
            font_size=24,
        )
        note.to_edge(DOWN, buff=0.16)
        self.play(Write(note))
        self.wait(1.8)
