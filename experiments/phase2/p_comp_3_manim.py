"""Manim scene: ZT curvature heatmap (left) vs Horn fitted slope (right).

Render:

    PCOMP3_MANIM=1 python experiments/phase2/p_comp_3.py

or:

    manim -ql experiments/phase2/p_comp_3_manim.py ZTNotHornStencil
"""
from manim import *


def make_grid(origin, rows, cols, fills, side=0.48):
    cells = VGroup()
    for r in range(rows):
        for c in range(cols):
            sq = Square(side_length=side)
            sq.move_to(origin + RIGHT * c * side + DOWN * r * side)
            sq.set_fill(fills[r * cols + c], opacity=0.72)
            sq.set_stroke(WHITE, 1.2)
            cells.add(sq)
    return cells


class ZTNotHornStencil(Scene):
    def construct(self):
        title = Text("P-COMP-3  ZT  =/=>  Horn   GPB-023", font_size=28)
        title.to_edge(UP)
        self.play(FadeIn(title))

        n = 7
        fills_zt = []
        fills_horn = []
        half = n // 2
        for r in range(n):
            for c in range(n):
                x = (c - half) / half
                # ZT Hxx is constant-ish (curvature); encode by |x|
                fills_zt.append(interpolate_color(BLUE_E, RED, abs(x)))
                # Horn slope grows with x (first derivative family)
                fills_horn.append(interpolate_color(GREEN_E, YELLOW, (x + 1) / 2))

        left = make_grid(LEFT * 6.0 + UP * 0.35, n, n, fills_zt)
        right = make_grid(RIGHT * 0.15 + UP * 0.35, n, n, fills_horn)
        capL = Text("ZT curvature heatmap", font_size=18)
        capR = Text("Horn quadratic-fit slope", font_size=18)
        capL.next_to(left, DOWN, buff=0.22)
        capR.next_to(right, DOWN, buff=0.22)

        self.play(LaggedStart(*[Create(s) for s in left], lag_ratio=0.02))
        self.play(Write(capL))
        self.play(LaggedStart(*[Create(s) for s in right], lag_ratio=0.02))
        self.play(Write(capR))

        ar = Arrow(
            left.get_right() + RIGHT * 0.15,
            right.get_left() + LEFT * 0.15,
            buff=0.08,
            color=RED,
            stroke_width=6,
        )
        ban = Text("not mutually entailed", font_size=20, color=RED)
        ban.next_to(ar, UP, buff=0.12)
        cross = Line(ar.get_start() + UP * 0.18, ar.get_end() + DOWN * 0.18, color=RED, stroke_width=5)
        self.play(GrowArrow(ar), Write(ban))
        self.play(Create(cross))

        note = MathTex(
            r"H_{xx}^{\mathrm{ZT}}=0 \;\not\Rightarrow\; D_x^{\mathrm{Horn}}=0",
            font_size=30,
        )
        note.to_edge(DOWN, buff=0.28)
        self.play(Write(note))
        self.wait(0.6)
