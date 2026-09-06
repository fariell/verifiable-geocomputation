"""Manim scene: planar D8 basins (left) vs flat 4-ring (right).

Render:

    P006_MANIM=1 python experiments/phase1/p006_watershed.py

or:

    manim -ql experiments/phase1/p006_manim.py WatershedStencil
"""
from manim import *

RING = [(0, 0), (0, 1), (1, 1), (1, 0)]


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


class WatershedStencil(Scene):
    def construct(self):
        title = Text("P-006  watershed   GPB-015", font_size=28)
        title.to_edge(UP)
        self.play(FadeIn(title))

        n = 5
        fills = []
        for r in range(n):
            for c in range(n):
                fills.append(interpolate_color(BLUE_E, GOLD, c / (n - 1)))
        left, side = make_grid(LEFT * 5.6 + UP * 0.6, n, n, fills)
        capL = Text("plane → unique outlet / row", font_size=18)
        capL.next_to(left, DOWN, buff=0.2)

        self.play(LaggedStart(*[Create(s) for s in left], lag_ratio=0.02))
        arrows = VGroup()
        for r in range(n):
            for c in range(1, n):
                src = left[r * n + c]
                dst = left[r * n + (c - 1)]
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
        self.play(Write(capL))

        ring_fills = [GREY_BROWN, GREY_BROWN, GREY_BROWN, GREY_BROWN]
        right, rside = make_grid(RIGHT * 1.6 + UP * 0.15, 2, 2, ring_fills, side=1.05)
        capR = Text("P-006b flat ring (no terminate)", font_size=18)
        capR.next_to(right, DOWN, buff=0.25)
        self.play(LaggedStart(*[Create(s) for s in right], lag_ratio=0.08))
        self.play(Write(capR))

        order = [0, 1, 3, 2]
        ring_arrows = []
        for i, idx in enumerate(order):
            nxt = order[(i + 1) % 4]
            ring_arrows.append(
                Arrow(
                    right[idx].get_center(),
                    right[nxt].get_center(),
                    buff=0.12,
                    color=RED,
                    stroke_width=4,
                )
            )
        for ar in ring_arrows:
            self.play(GrowArrow(ar), run_time=0.35)
            self.play(Indicate(ar, color=WHITE), run_time=0.25)

        note = MathTex(
            r"\mathrm{succ}\ \mathrm{function}\ \Rightarrow\ \exists!\ \mathrm{outlet}\mid\mathrm{terminates}",
            font_size=26,
        )
        note.to_edge(DOWN, buff=0.28)
        self.play(Write(note))
        self.wait(0.6)
