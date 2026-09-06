"""Manim scene: unfilled flat ring (left) vs filled/planar unique outlet (right).

Render:

    PCOMP1_MANIM=1 python experiments/phase2/p_comp_1.py

or:

    manim -ql experiments/phase2/p_comp_1_manim.py FillThenWatershedStencil
"""
from manim import *


def make_grid(origin, rows, cols, fills, side=0.55):
    cells = VGroup()
    for r in range(rows):
        for c in range(cols):
            sq = Square(side_length=side)
            sq.move_to(origin + RIGHT * c * side + DOWN * r * side)
            sq.set_fill(fills[r * cols + c], opacity=0.5)
            sq.set_stroke(WHITE, 1.5)
            cells.add(sq)
    return cells, side


class FillThenWatershedStencil(Scene):
    def construct(self):
        title = Text("P-COMP-1  fill then basin   GPB-021", font_size=28)
        title.to_edge(UP)
        self.play(FadeIn(title))

        ring_fills = [GREY_BROWN, GREY_BROWN, GREY_BROWN, GREY_BROWN]
        left, _rside = make_grid(LEFT * 5.4 + UP * 0.15, 2, 2, ring_fills, side=1.05)
        capL = Text("unfilled flat ring (no terminate)", font_size=18)
        capL.next_to(left, DOWN, buff=0.25)
        self.play(LaggedStart(*[Create(s) for s in left], lag_ratio=0.08))
        self.play(Write(capL))

        order = [0, 1, 3, 2]
        for i, idx in enumerate(order):
            nxt = order[(i + 1) % 4]
            ar = Arrow(
                left[idx].get_center(),
                left[nxt].get_center(),
                buff=0.12,
                color=RED,
                stroke_width=4,
            )
            self.play(GrowArrow(ar), run_time=0.35)
            self.play(Indicate(ar, color=WHITE), run_time=0.25)

        n = 5
        fills = []
        for r in range(n):
            for c in range(n):
                fills.append(interpolate_color(BLUE_E, GOLD, c / (n - 1)))
        right, side = make_grid(RIGHT * 0.4 + UP * 0.55, n, n, fills)
        capR = Text("after fill / plane → unique outlet", font_size=18)
        capR.next_to(right, DOWN, buff=0.2)
        self.play(LaggedStart(*[Create(s) for s in right], lag_ratio=0.02))
        arrows = VGroup()
        for r in range(n):
            for c in range(1, n):
                src = right[r * n + c]
                dst = right[r * n + (c - 1)]
                arrows.add(
                    Arrow(
                        src.get_center(),
                        dst.get_center(),
                        buff=0.08,
                        color=YELLOW,
                        stroke_width=2,
                        max_tip_length_to_length_ratio=0.25,
                    )
                )
        self.play(LaggedStart(*[GrowArrow(a) for a in arrows], lag_ratio=0.03))
        self.play(Write(capR))

        note = MathTex(
            r"\mathrm{fill}\ \Rightarrow\ \mathrm{strict\ descent}\ \Rightarrow\ \exists!\ \mathrm{outlet}",
            font_size=26,
        )
        note.to_edge(DOWN, buff=0.28)
        self.play(Write(note))
        self.wait(0.6)
